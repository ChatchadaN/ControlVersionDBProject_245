
create PROCEDURE [act].[sp_quality_linemonitor_test] (
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
	--set @device_id = (select dd.id from APCSProDWH.dwh.dim_devices as dd where name = @device_name)
	DECLARE @from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = @date_from
			)
	DECLARE @to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = @date_to
			)

	IF OBJECT_ID(N'tempdb..#t_lot', N'U') IS NOT NULL
		DROP TABLE #t_lot;

	IF OBJECT_ID(N'tempdb..#t_flow', N'U') IS NOT NULL
		DROP TABLE #t_flow;

	------------------------------------------------------#t_lot
	SELECT t2.lot_id AS lot_id
		,t2.act_package_id AS act_package_id
		,t2.device_name_id AS device_name_id
	INTO #t_lot
	FROM (
		SELECT lpr.lot_id
		FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
		WHERE @from <= lpr.day_id
			AND lpr.day_id <= @to
		) AS t1
	INNER JOIN (
		SELECT tl.id AS lot_id
			,tl.act_package_id AS act_package_id
			,tl.act_device_name_id AS device_name_id
		FROM APCSProDB.trans.lots AS tl WITH (NOLOCK)
		LEFT OUTER JOIN APCSProDB.trans.lot_multi_chips AS m ON m.child_lot_id = tl.id
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
		,t2.act_package_id
		,t2.device_name_id

	------------------------------------------------------#t_flow
	DECLARE @oldest_rec DATETIME = (
			SELECT r.recorded_at
			FROM (
				SELECT rank() OVER (
						ORDER BY lpr.recorded_At
						) AS oldest_recorded_at
					,lpr.recorded_at AS recorded_at
					,lpr.lot_id AS lot_id
				FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
				INNER JOIN #t_lot AS tt ON lpr.record_class = 2
					AND tt.lot_id = lpr.lot_id
				) AS r
			WHERE r.oldest_recorded_at = 1
			)

	SELECT step_no
		,ROW_NUMBER() OVER (
			ORDER BY step_no
			) AS line_flow_order
		,process_id
		,job_id
	INTO #t_flow
	FROM (
		SELECT *
			,dense_rank() OVER (
				PARTITION BY t1.flag ORDER BY t1.version_num DESC
				) AS version_num_applied
		FROM (
			SELECT df.step_no AS step_no
				,df.next_step_no AS next_step_no
				,df.act_process_id AS process_id
				,df.job_id AS job_id
				,df.is_skipped AS is_skipped
				,ds.device_slip_id AS device_slip_id
				,ds.device_id AS device_id
				,ds.version_num AS version_num
				,ds.updated_at AS updated_at
				,CASE 
					WHEN ds.updated_at <= @oldest_rec
						THEN 0
					ELSE 1
					END AS flag
			FROM APCSProDB.method.device_flows AS df WITH (NOLOCK)
			INNER JOIN APCSProDB.method.device_slips AS ds WITH (NOLOCK) ON ds.device_slip_id = df.device_slip_id
				AND isnull(df.is_skipped, 0) = 0
			INNER JOIN APCSProDWH.dwh.dim_devices AS dd WITH (NOLOCK) ON dd.id = ds.device_id
			WHERE dd.name = @device_name
			) AS t1
		) AS t2
	WHERE version_num_applied = 1
	GROUP BY step_no
		,process_id
		,job_id
	ORDER BY step_no

	----------------------------------Main 
	SELECT t4.lot_rank AS lot_rank
		,CASE 
			WHEN substring(t4.lot_no, 5, 1) = 'D'
				THEN 1
			ELSE 0
			END AS d_lot
		,t4.lot_id AS lot_id
		,t4.lot_no AS lot_no
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
	FROM (
		SELECT t3.lot_rank AS lot_rank
			,t3.lot_id AS lot_id
			,t3.lot_no AS lot_no
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
				PARTITION BY t3.lot_rank ORDER BY t3.line_flow_order
					,t3.started_at
				) AS y1
			,t3.line_flow_order AS x2
			,t3.line_finished_minutes AS y2
			,t3.line_max_minutes AS line_max_minutes
		FROM (
			SELECT t2.lot_rank AS lot_rank
				,t2.lot_id AS lot_id
				,t2.lot_no AS lot_no
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
			FROM (
				SELECT dense_rank() OVER (
						ORDER BY t1.lot_id
						) AS lot_rank
					,t1.lot_id AS lot_id
					,t1.lot_no AS lot_no
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
					,DATEDIFF(MINUTE, @date_from, t1.started_at) AS line_started_minutes
					,DATEDIFF(MINUTE, @date_from, t1.finished_at) AS line_finished_minutes
					,datediff(MINUTE, @date_from, @date_to) AS line_max_minutes
				--
				FROM (
					SELECT s4.lot_id AS lot_id
						,s4.lot_no AS lot_no
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
									,s1.device_name_id AS device_name_id
									,s1.step_no AS step_no
									,s1.line_flow_order AS line_flow_order
									,s1.act_package_id AS package_id
									,s1.process_id AS process_id
									,s1.job_id AS job_id
									,s1.machine_id AS machine_id
									,s1.started_at AS started_at
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
								FROM (
									SELECT tl.lot_no AS lot_no
										,f.*
										,s.recorded_at AS started_at
										,r.recorded_at AS finished_at
										,r.machine_id AS machine_id
									FROM (
										SELECT *
										FROM #t_flow AS a
										CROSS JOIN (
											SELECT *
											FROM #t_lot
											) AS x
										) AS f
									LEFT OUTER JOIN (
										SELECT rank() OVER (
												PARTITION BY job_id
												,record_class ORDER BY recorded_at
												) AS record_class_rank
											,lpr.lot_id AS lot_id
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
										AND s.process_id = f.process_id
										AND s.job_id = f.job_id
									LEFT OUTER JOIN (
										SELECT rank() OVER (
												PARTITION BY job_id
												,record_class ORDER BY recorded_at
												) AS record_class_rank
											,lpr2.lot_id AS lot_id
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
										AND r.process_id = f.process_id
										AND r.job_id = f.job_id
										AND r.record_class_rank = s.record_class_rank
									INNER JOIN APCSProDB.trans.lots AS tl ON tl.id = f.lot_id
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
	ORDER BY t4.lot_id
		,t4.line_flow_order
		,t4.started_at
END
