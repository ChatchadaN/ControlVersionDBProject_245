
CREATE PROCEDURE [act].[sp_quality_linemonitor] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@date_from DATE
	,@date_to DATE
	)
AS
BEGIN
	--DECLARE @package_group_id INT = NULL
	--DECLARE @package_id INT = 242
	----DECLARE @device_id INT = 5316
	--DECLARE @device_id INT = NULL
	--DECLARE @date_from DATETIME = '2020-04-01 00:00:00'
	--DECLARE @date_to DATETIME = '2020-04-02 00:00:00'
	--DECLARE @device_name VARCHAR(20) = NULL
	DECLARE @from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_from
			)
	DECLARE @to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @date_to
			)
	--リードタイム係数
	DECLARE @N DECIMAL(2, 1) = 1.5

	IF OBJECT_ID(N'tempdb..#t_lot', N'U') IS NOT NULL
		DROP TABLE #t_lot;

	IF OBJECT_ID(N'tempdb..#t_flow', N'U') IS NOT NULL
		DROP TABLE #t_flow;

	----ロット一覧
	SELECT t3.lot_id AS lot_id
		,t3.lot_no AS lot_no
		,t3.device_slip_id AS device_slip_id
		,t3.version_num AS version_num
		,t3.act_package_id AS act_package_id
		,t3.device_name_id AS device_name_id
		,t3.normal_leadtime_minutes AS normal_leadtime_minutes
		--
		,fs.lead_time AS lead_time
		,fs.wait_time AS wait_time
		,fs.process_time AS process_time
		,max(fs.lead_time) OVER () AS max_lead_time
	INTO #t_lot
	FROM (
		SELECT t2.lot_id AS lot_id
			,t2.lot_no AS lot_no
			,t2.device_slip_id AS device_slip_id
			,t2.version_num AS version_num
			,t2.act_package_id AS act_package_id
			,t2.device_name_id AS device_name_id
			,t2.normal_leadtime_minutes AS normal_leadtime_minutes
		FROM (
			SELECT lpr.lot_id
			FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
			WHERE lpr.day_id >= @from
				AND lpr.day_id <= @to
			) AS t1
		INNER JOIN (
			SELECT tl.id AS lot_id
				,tl.lot_no AS lot_no
				,tl.device_slip_id AS device_slip_id
				,ds.version_num AS version_num
				,ds.normal_leadtime_minutes AS normal_leadtime_minutes
				,tl.act_package_id AS act_package_id
				,tl.act_device_name_id AS device_name_id
			FROM APCSProDB.trans.lots AS tl WITH (NOLOCK)
			INNER JOIN APCSProDB.method.device_slips AS ds WITH (NOLOCK) ON ds.device_slip_id = tl.device_slip_id
			LEFT OUTER JOIN APCSProDB.trans.lot_multi_chips AS m WITH (NOLOCK) ON m.child_lot_id = tl.id
			INNER JOIN APCSProDWH.dwh.dim_packages AS dp WITH (NOLOCK) ON dp.id = tl.act_package_id
			INNER JOIN APCSProDWH.dwh.dim_package_groups AS dg WITH (NOLOCK) ON dg.id = dp.package_group_id
			LEFT OUTER JOIN APCSProDWH.dwh.dim_devices AS dd WITH (NOLOCK) ON dd.id = tl.act_device_name_id
			WHERE (
					(
						@package_id IS NOT NULL
						AND tl.act_package_id = @package_id
						)
					OR (
						@package_id IS NULL
						AND @package_group_id IS NOT NULL
						AND dp.package_group_id = @package_group_id
						)
					OR (
						@package_id IS NULL
						AND @package_group_id IS NULL
						AND dp.id > 0
						)
					)
				AND (
					(
						@device_name IS NOT NULL
						AND dd.name = @device_name
						)
					OR (@device_name IS NULL)
					)
				AND m.child_lot_id IS NULL
			) AS t2 ON t2.lot_id = t1.lot_id
		GROUP BY t2.lot_id
			,t2.lot_no
			,t2.act_package_id
			,t2.device_name_id
			,t2.device_slip_id
			,t2.version_num
			,t2.normal_leadtime_minutes
		) AS t3
	LEFT OUTER JOIN APCSProDWH.dwh.fact_shipment AS fs WITH (NOLOCK) ON fs.lot_id = t3.lot_id

	SELECT max(line_flow_order) OVER () AS last_line_num
		,t3.*
	INTO #t_flow
	FROM (
		SELECT ROW_NUMBER() OVER (
				PARTITION BY t2.device_slip_id ORDER BY t2.step_no
				) AS line_flow_order
			,t2.*
		FROM (
			SELECT t1.*
			FROM (
				SELECT df.device_slip_id AS device_slip_id
					,df.step_no AS step_no
					,df.act_process_id AS process_id
					,df.job_id AS job_id
					,isnull(df.is_skipped, 0) AS is_skipped
					,s.version_num AS version_num
				FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
				INNER JOIN (
					SELECT device_slip_id
						,version_num
					FROM #t_lot
					GROUP BY device_slip_id
						,version_num
					) AS s ON s.device_slip_id = df.device_slip_id
				) AS t1
			WHERE t1.is_skipped = 0
			) AS t2
		) AS t3
	ORDER BY t3.device_slip_id
		,t3.step_no

	------version_num flow
	SELECT tf.line_flow_order
		,tf.step_no
		,tf.version_num
		,tf.process_id
		,dp.name AS process_name
		,tf.job_id
		,dj.name AS job_name
	FROM #t_flow AS tf
	INNER JOIN APCSProDWH.dwh.dim_processes AS dp WITH (NOLOCK) ON dp.id = tf.process_id
	INNER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = tf.job_id
	--group by tf.device_slip_id,tf.version_num 
	ORDER BY tf.device_slip_id

	----MAIN QUERY----
	SELECT t6.lot_rank AS lot_rank
		,t6.d_lot AS d_lot
		,t6.lot_id AS lot_id
		,t6.lot_no AS lot_no
		,t6.special_flow_flag AS special_flow_flag
		,t6.diff_sum AS input_group_num
		,t6.version_num AS version_num
		,t6.package_id AS package_id
		,t6.package_name AS package_name
		,t6.device_name_id AS device_name_id
		,t6.step_no AS step_no
		,t6.line_flow_order AS line_flow_order
		,t6.process_id AS process_id
		,t6.process_name AS process_name
		,t6.job_id AS job_id
		,t6.job_name AS job_name
		,t6.machine_id AS machine_id
		,t6.machine_name AS machine_name
		,t6.started_at AS started_at
		,t6.finished_at AS finished_at
		,t6.temp_finished_at_flag AS temp_finished_at_flag
		,t6.x1 AS x1
		,t6.y1 AS y1
		--
		,t6.x2 AS x2
		,t6.y2 AS y2
		,isnull(t6.dy2_from_pre, 0) AS dy2_from_pre
		,t6.pre_lot_no AS pre_lot_no
		,rank() OVER (
			PARTITION BY t6.version_num
			,t6.line_flow_order
			,t6.diff_sum ORDER BY t6.dy2_from_pre DESC
			) AS dy2_from_pre_rank
		,t6.line_max_minutes AS line_max_minutes
		--,t6.date_to AS date_to
		,@date_to AS date_to
		--lead time data
		,convert(DECIMAL, t6.lead_time) / 24 / 60 AS lead_time
		,convert(DECIMAL, t6.wait_time) / 24 / 60 AS wait_time
		,convert(DECIMAL, t6.process_time) / 24 / 60 AS process_time
		,convert(DECIMAL, t6.normal_leadtime_minutes) / 24 / 60 * @N AS target_leadtime
		,convert(DECIMAL, t6.lead_time) / convert(DECIMAL, t6.max_lead_time) AS normalized_lead_time
		,convert(DECIMAL, t6.wait_time) / convert(DECIMAL, t6.max_lead_time) AS normalized_wait_time
		,convert(DECIMAL, t6.process_time) / convert(DECIMAL, t6.max_lead_time) AS normalized_process_time
		,convert(DECIMAL, t6.normal_leadtime_minutes) * @N / convert(DECIMAL, t6.max_lead_time) AS normalized_target_leadtime
	FROM (
		SELECT t5.lot_rank AS lot_rank
			,t5.d_lot AS d_lot
			,t5.lot_id AS lot_id
			,t5.lot_no AS lot_no
			,t5.special_flow_flag AS special_flow_flag
			,t5.diff_sum AS diff_sum
			,t5.version_num AS version_num
			,t5.package_id AS package_id
			,t5.package_name AS package_name
			,t5.device_name_id AS device_name_id
			,t5.step_no AS step_no
			,t5.line_flow_order AS line_flow_order
			,t5.process_id AS process_id
			,t5.process_name AS process_name
			,t5.job_id AS job_id
			,t5.job_name AS job_name
			,t5.machine_id AS machine_id
			,t5.machine_name AS machine_name
			,t5.started_at AS started_at
			,t5.finished_at AS finished_at
			,t5.temp_finished_at_flag AS temp_finished_at_flag
			,t5.x1 AS x1
			,t5.y1 AS y1
			--
			,t5.x2 AS x2
			,t5.y2 AS y2
			,lag(t5.y2, 1) OVER (
				PARTITION BY t5.version_num
				,t5.line_flow_order
				,t5.diff_sum ORDER BY t5.finished_at
				) - t5.y2 AS dy2_from_pre
			,lag(t5.lot_no, 1) OVER (
				PARTITION BY t5.version_num
				,t5.line_flow_order
				,t5.diff_sum ORDER BY t5.finished_at
				) AS pre_lot_no
			,t5.line_max_minutes AS line_max_minutes
			--,t5.date_to AS date_to
			--lead time data
			,t5.lead_time AS lead_time
			,t5.wait_time AS wait_time
			,t5.process_time AS process_time
			,t5.max_lead_time AS max_lead_time
			,t5.normal_leadtime_minutes AS normal_leadtime_minutes
		FROM (
			SELECT t4.lot_rank AS lot_rank
				,t4.d_lot AS d_lot
				,t4.lot_id AS lot_id
				,t4.lot_no AS lot_no
				,t4.special_flow_flag AS special_flow_flag
				,sum(t4.diff_flag) OVER (
					PARTITION BY t4.d_lot ORDER BY t4.lot_id
						,t4.line_flow_order
						,t4.started_at
					) AS diff_sum
				,t4.version_num AS version_num
				,t4.package_id AS package_id
				,t4.package_name AS package_name
				,t4.device_name_id AS device_name_id
				,t4.step_no AS step_no
				,t4.line_flow_order AS line_flow_order
				,t4.process_id AS process_id
				,NULL AS process_no
				,t4.process_name AS process_name
				,t4.job_id AS job_id
				,NULL AS job_no
				,t4.job_name AS job_name
				,t4.machine_id AS machine_id
				,t4.machine_name AS machine_name
				,t4.started_at AS started_at
				,t4.finished_at AS finished_at
				,t4.temp_finished_at_flag AS temp_finished_at_flag
				--previous job coordinate
				,t4.x1 AS x1
				,line_max_minutes - t4.y1 AS y1
				--
				,t4.x2 AS x2
				,line_max_minutes - t4.y2 AS y2
				,t4.line_max_minutes AS line_max_minutes
				--,t4.date_to AS date_to
				--lead time data
				,t4.lead_time AS lead_time
				,t4.wait_time AS wait_time
				,t4.process_time AS process_time
				,t4.max_lead_time AS max_lead_time
				,t4.normal_leadtime_minutes AS normal_leadtime_minutes
			FROM (
				SELECT t3.lot_rank AS lot_rank
					,t3.d_lot AS d_lot
					,t3.lot_id AS lot_id
					,t3.lot_no AS lot_no
					,t3.special_flow_flag AS special_flow_flag
					,CASE 
						WHEN t3.diff2 > 2
							THEN 1
						ELSE 0
						END AS diff_flag
					,t3.version_num AS version_num
					,t3.package_id AS package_id
					,dp.name AS package_name
					,t3.device_name_id AS device_name_id
					,t3.step_no AS step_no
					,t3.line_flow_order AS line_flow_order
					,t3.process_id AS process_id
					,dr.name AS process_name
					,t3.job_id AS job_id
					,dj.name AS job_name
					,t3.machine_id AS machine_id
					,dm.name AS machine_name
					,t3.started_at AS started_at
					,t3.finished_at AS finished_at
					,t3.temp_finished_at_flag AS temp_finished_at_flag
					--line coordinate of polyline
					,lag(t3.line_flow_order, 1, t3.line_flow_order) OVER (
						PARTITION BY t3.lot_rank ORDER BY t3.line_flow_order
							,t3.started_at
						) AS x1
					,lag(t3.line_finished_minutes, 1, t3.line_finished_minutes) OVER (
						PARTITION BY t3.lot_rank ORDER BY
							--t3.line_flow_order
							--	,t3.started_at
							--important!
							t3.started_at
							,t3.line_flow_order
						) AS y1
					,t3.line_flow_order AS x2
					,t3.line_finished_minutes AS y2
					,t3.line_max_minutes AS line_max_minutes
					--,t3.date_to AS date_to
					--lead time data
					,t3.lead_time AS lead_time
					,t3.wait_time AS wait_time
					,t3.process_time AS process_time
					,t3.max_lead_time AS max_lead_time
					,t3.normal_leadtime_minutes AS normal_leadtime_minutes
				FROM (
					SELECT t2.lot_rank AS lot_rank
						,t2.d_lot AS d_lot
						,t2.lot_id AS lot_id
						,t2.lot_no AS lot_no
						,t2.special_flow_flag AS special_flow_flag
						,t2.diff - lag(t2.diff, 1, 0) OVER (
							ORDER BY t2.d_lot
								,t2.lot_rank
								,t2.started_at
							) AS diff2
						,t2.version_num AS version_num
						,t2.package_id AS package_id
						,t2.device_name_id AS device_name_id
						,t2.step_no AS step_no
						,t2.line_flow_order AS line_flow_order
						,t2.process_id AS process_id
						,t2.job_id AS job_id
						,t2.machine_id AS machine_id
						,t2.started_at AS started_at
						,t2.finished_at AS finished_at
						,t2.temp_finished_at_flag AS temp_finished_at_flag
						--line
						,t2.line_started_minutes AS line_started_minutes
						,t2.line_finished_minutes AS line_finished_minutes
						,t2.line_max_minutes AS line_max_minutes
						--,t2.date_to AS date_to
						--lead time data
						,t2.lead_time AS lead_time
						,t2.wait_time AS wait_time
						,t2.process_time AS process_time
						,t2.max_lead_time AS max_lead_time
						,t2.normal_leadtime_minutes AS normal_leadtime_minutes
					FROM (
						SELECT dense_rank() OVER (
								ORDER BY t1.lot_id
								) AS lot_rank
							,CASE 
								WHEN substring(t1.lot_no, 5, 1) = 'D'
									THEN 1
								ELSE 0
								END AS d_lot
							,t1.lot_id AS lot_id
							,t1.lot_no AS lot_no
							,t1.special_flow_flag AS special_flow_flag
							,t1.in_date_id AS in_date_id
							,t1.in_date_id - min(t1.in_date_id) OVER () AS diff
							,t1.version_num AS version_num
							,t1.package_id AS package_id
							,t1.device_name_id AS device_name_id
							,t1.step_no AS step_no
							,t1.line_flow_order AS line_flow_order
							,t1.process_id AS process_id
							,t1.job_id AS job_id
							,t1.machine_id AS machine_id
							,t1.started_at AS started_at
							,t1.finished_at AS finished_at
							,t1.temp_finished_at_flag AS temp_finished_at_flag
							--yAxisはversion numに無関係に統一
							,DATEDIFF(MINUTE, @date_from, t1.started_at) AS line_started_minutes
							,DATEDIFF(MINUTE, @date_from, t1.finished_at) AS line_finished_minutes
							,datediff(MINUTE, @date_from, @date_to) AS line_max_minutes
							--yAxisをversion_num毎に設定する
							--,DATEDIFF(MINUTE, t1.date_from, t1.started_at) AS line_started_minutes
							--,DATEDIFF(MINUTE, t1.date_from, t1.finished_at) AS line_finished_minutes
							--,datediff(MINUTE, t1.date_from, t1.date_to) AS line_max_minutes
							--,t1.date_from AS date_from
							--,t1.date_to AS date_to
							--
							--lead time data
							,t1.lead_time AS lead_time
							,t1.wait_time AS wait_time
							,t1.process_time AS process_time
							,t1.max_lead_time AS max_lead_time
							,t1.normal_leadtime_minutes AS normal_leadtime_minutes
						FROM (
							SELECT s4.lot_id AS lot_id
								,s4.lot_no AS lot_no
								,s4.special_flow_flag AS special_flow_flag
								,s4.in_date_id AS in_date_id
								,s4.version_num AS version_num
								,s4.device_name_id AS device_name_id
								,s4.step_no AS step_no
								,s4.line_flow_order AS line_flow_order
								,s4.package_id AS package_id
								,s4.process_id AS process_id
								,s4.job_id AS job_id
								,s4.machine_id AS machine_id
								,s4.started_at AS started_at
								,s4.finished_at AS finished_at
								,s4.temp_finished_at_flag AS temp_finished_at_flag
								--,max(s4.finished_at) OVER (PARTITION BY s4.version_num) AS date_to
								--,min(s4.started_at) OVER (PARTITION BY s4.version_num) AS date_from
								--lead time data
								,s4.lead_time AS lead_time
								,s4.wait_time AS wait_time
								,s4.process_time AS process_time
								,s4.max_lead_time AS max_lead_time
								,s4.normal_leadtime_minutes AS normal_leadtime_minutes
							FROM (
								SELECT s3.*
									,ROW_NUMBER() OVER (
										PARTITION BY s3.lot_id
										,s3.temp_finished_at_flag
										,s3.diff_num ORDER BY s3.lot_id
											,s3.line_flow_order
										) AS offset
								FROM (
									SELECT s2.*
										,ROW_NUMBER() OVER (
											PARTITION BY s2.lot_id ORDER BY s2.line_flow_order
												,s2.started_at
											) - row_number() OVER (
											PARTITION BY s2.lot_id
											,s2.temp_finished_at_flag ORDER BY s2.line_flow_order
											) AS diff_num
									FROM (
										SELECT s1.lot_id AS lot_id
											,s1.lot_no AS lot_no
											,s1.special_flow_flag AS special_flow_flag
											,s1.in_date_id AS in_date_id
											,s1.version_num AS version_num
											,s1.device_name_id AS device_name_id
											,s1.step_no AS step_no
											,s1.line_flow_order AS line_flow_order
											,s1.act_package_id AS package_id
											,s1.process_id AS process_id
											,s1.job_id AS job_id
											,s1.machine_id AS machine_id
											,s1.started_at AS started_at
											--,s1.finished_at AS finished_at
											,CASE 
												WHEN s1.finished_at IS NULL
													THEN CASE 
															WHEN s1.started_at IS NOT NULL
																THEN s1.started_at
															ELSE NULL
															END
												ELSE s1.finished_at
												END AS finished_at
											,CASE 
												WHEN s1.finished_at IS NULL
													THEN CASE 
															WHEN s1.started_at IS NULL
																THEN - 1
															ELSE 1
															END
												ELSE 0
												END AS temp_finished_at_flag
											--lead time data
											,CASE 
												WHEN s1.line_flow_order = s1.last_line_num
													THEN s1.lead_time
												ELSE NULL
												END AS lead_time
											,CASE 
												WHEN s1.line_flow_order = s1.last_line_num
													THEN s1.wait_time
												ELSE NULL
												END AS wait_time
											,CASE 
												WHEN s1.line_flow_order = s1.last_line_num
													THEN s1.process_time
												ELSE NULL
												END AS process_time
											,s1.max_lead_time AS max_lead_time
											,CASE 
												WHEN s1.line_flow_order = s1.last_line_num
													THEN s1.normal_leadtime_minutes
												ELSE NULL
												END AS normal_leadtime_minutes
										FROM (
											SELECT f.*
												,tl.in_date_id AS in_date_id
												,isnull(s.special_flow_flag, 0) AS special_flow_flag
												,s.recorded_at AS started_at
												,r.recorded_at AS finished_at
												,r.machine_id AS machine_id
											FROM (
												SELECT a.line_flow_order
													,a.device_slip_id AS device_slip_id
													,a.step_no AS step_no
													,a.process_id AS process_id
													,a.job_id AS job_id
													,a.version_num AS version_num
													,a.last_line_num AS last_line_num
													,x.lot_id
													,x.lot_no
													,x.device_name_id
													,x.act_package_id
													,x.lead_time AS lead_time
													,x.wait_time AS wait_time
													,x.process_time AS process_time
													,x.max_lead_time AS max_lead_time
													,x.normal_leadtime_minutes AS normal_leadtime_minutes
												FROM #t_flow AS a
												CROSS JOIN (
													SELECT *
													FROM #t_lot
													) AS x
												) AS f
											LEFT OUTER JOIN (
												SELECT lpr.process_job_id AS process_job_id
													,lpr.lot_id AS lot_id
													,(lpr.step_no / 100) * 100 AS new_step_no
													,CASE 
														WHEN lpr.step_no % 100 > 0
															THEN 1
														ELSE 0
														END AS special_flow_flag
													,lpr.process_id AS process_id
													,lpr.job_id AS job_id
													,lpr.machine_id AS machine_id
													,lpr.record_class AS record_class
													,lpr.recorded_at
												FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
												INNER JOIN (
													SELECT *
													FROM #t_lot
													) AS t ON t.lot_id = lpr.lot_id
												) AS s ON s.record_class = 1
												AND s.lot_id = f.lot_id
												AND s.new_step_no = f.step_no
											--special flow countermesure
											--AND s.process_id = f.process_id
											--AND s.job_id = f.job_id
											LEFT OUTER JOIN (
												SELECT lpr2.process_job_id AS process_job_id
													,lpr2.lot_id AS lot_id
													,(lpr2.step_no / 100) * 100 AS new_step_no
													,CASE 
														WHEN lpr2.step_no % 100 > 0
															THEN 1
														ELSE 0
														END AS special_flow_flag
													,lpr2.process_id AS process_id
													,lpr2.job_id AS job_id
													,lpr2.machine_id AS machine_id
													,lpr2.record_class AS record_class
													,lpr2.recorded_at AS recorded_at
												FROM APCSProDB.trans.lot_process_records AS lpr2 WITH (NOLOCK)
												INNER JOIN (
													SELECT *
													FROM #t_lot
													) AS t ON t.lot_id = lpr2.lot_id
												) AS r ON r.record_class = 2
												AND r.lot_id = f.lot_id
												AND r.new_step_no = f.step_no
												--special flow countermesure
												--AND r.process_id = f.process_id
												--AND r.job_id = f.job_id
												AND r.process_job_id = s.process_job_id
											INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = f.lot_id
												AND tl.device_slip_id = f.device_slip_id
											) AS s1
										) AS s2
									) AS s3
								) AS s4
							WHERE temp_finished_at_flag >= 0
							) AS t1
						) AS t2
					) AS t3
				INNER JOIN APCSProDWH.dwh.dim_packages AS dp WITH (NOLOCK) ON dp.id = t3.package_id
				INNER JOIN APCSProDWH.dwh.dim_processes AS dr WITH (NOLOCK) ON dr.id = t3.process_id
				INNER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = t3.job_id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t3.machine_id
				) AS t4
			) AS t5
		) AS t6
	ORDER BY t6.lot_id
		,t6.line_flow_order
		,t6.started_at
END
