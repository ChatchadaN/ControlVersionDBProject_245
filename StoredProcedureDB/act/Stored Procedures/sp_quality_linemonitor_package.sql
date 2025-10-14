
CREATE PROCEDURE [act].[sp_quality_linemonitor_package] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@date_from DATE
	,@date_to DATE
	,@range INT = 4
	)
AS
BEGIN
	--DECLARE @package_group_id INT = NULL
	--DECLARE @package_id INT = 242
	--DECLARE @process_id INT = NULL
	--DECLARE @range INT = 4
	--DECLARE @date_from DATETIME = '2020-04-01 00:00:00'
	--DECLARE @date_to DATETIME = '2020-04-02 00:00:00'
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

	--process指定のクエリ用
	IF OBJECT_ID(N'tempdb..#p_table', N'U') IS NOT NULL
		DROP TABLE #p_table;

	IF @process_id IS NULL
	BEGIN
		SELECT t5.line_flow_order AS line_flow_order
			,t5.package_id AS package_id
			,t5.package_name AS package_name
			,t5.assy_name_id AS assy_name_id
			,t5.assy_device_rank AS assy_device_rank
			,t5.assy_device_name AS assy_device_name
			,t5.lot_id AS lot_id
			,t5.lot_no AS lot_no
			,t5.process_id AS process_id
			,t5.process_name AS process_name
			,t5.job_id AS job_id
			,t5.job_name AS job_name
			,t5.machine_id AS machine_id
			,t5.machine_name AS machine_name
			,t5.x1 AS x1
			,t5.y1 AS y1
			,t5.x2 AS x2
			,t5.y2 AS y2
			,t5.started_at AS started_at
			,t5.finished_at AS finished_at
			,t5.next_process_id AS next_process_id
			,t5.next_job_id AS next_job_id
			,t5.line_max_minutes AS line_max_minutes
			,@date_to AS date_to
			,max(t5.assy_device_rank) OVER () AS assy_device_num
			--lead time data
			,convert(DECIMAL, t5.lead_time) / 24 / 60 AS lead_time
			,convert(DECIMAL, t5.wait_time) / 24 / 60 AS wait_time
			,convert(DECIMAL, t5.process_time) / 24 / 60 AS process_time
			,convert(DECIMAL, t5.normal_leadtime_minutes) * @N / 24 / 60 AS target_leadtime
			,convert(DECIMAL, t5.lead_time) / convert(DECIMAL, t5.max_lead_time) AS normalized_lead_time
			,convert(DECIMAL, t5.wait_time) / convert(DECIMAL, t5.max_lead_time) AS normalized_wait_time
			,convert(DECIMAL, t5.process_time) / convert(DECIMAL, t5.max_lead_time) AS normalized_process_time
			,convert(DECIMAL, t5.normal_leadtime_minutes) * @N / convert(DECIMAL, t5.max_lead_time) AS normalized_target_leadtime
		FROM (
			SELECT t4.line_flow_order AS line_flow_order
				,t4.package_id AS package_id
				,t4.package_name AS package_name
				,t4.device_id AS device_id
				,dense_rank() OVER (
					ORDER BY t4.device_id
					) AS device_rank
				,t4.assy_name_id AS assy_name_id
				,dense_rank() OVER (
					ORDER BY t4.assy_name_id
					) AS assy_device_rank
				,t4.assy_device_name AS assy_device_name
				,t4.lot_id AS lot_id
				,t4.lot_no AS lot_no
				,t4.process_id AS process_id
				,t4.process_name AS process_name
				,t4.job_id AS job_id
				,t4.job_name AS job_name
				,t4.machine_id AS machine_id
				,t4.machine_name AS machine_name
				,t4.x1 AS x1
				,t4.line_max_minutes - t4.y1 AS y1
				,t4.x2 AS x2
				,t4.line_max_minutes - t4.y2 AS y2
				,t4.started_at AS started_at
				,t4.finished_at AS finished_at
				,t4.next_process_id AS next_process_id
				,t4.next_job_id AS next_job_id
				,t4.line_max_minutes AS line_max_minutes
				--lead time data
				,t4.lead_time AS lead_time
				,t4.wait_time AS wait_time
				,t4.process_time AS process_time
				,max(t4.lead_time) OVER () AS max_lead_time
				,t4.normal_leadtime_minutes AS normal_leadtime_minutes
			FROM (
				SELECT t3.line_flow_order AS line_flow_order
					,t3.package_id AS package_id
					,dp.name AS package_name
					,t3.device_id AS device_id
					,t3.assy_name_id AS assy_name_id
					,dd.name AS assy_device_name
					,t3.lot_id AS lot_id
					,t3.lot_no AS lot_no
					,t3.process_id AS process_id
					,dr.name AS process_name
					,t3.job_id AS job_id
					,dj.name AS job_name
					,t3.machine_id AS machine_id
					,dm.name AS machine_name
					--line coordinate of polyline
					,datediff(MINUTE, @date_from, @date_to) AS line_max_minutes
					,lag(t3.line_flow_order, 1, t3.line_flow_order) OVER (
						PARTITION BY t3.lot_id ORDER BY t3.line_flow_order
							,t3.started_at
						) AS x1
					,lag(t3.line_finished_minutes, 1, t3.line_finished_minutes) OVER (
						PARTITION BY t3.lot_id ORDER BY
							--t3.line_flow_order
							--	,t3.started_at
							--important!
							t3.started_at
							,t3.line_flow_order
						) AS y1
					,t3.line_flow_order AS x2
					,t3.line_finished_minutes AS y2
					,t3.started_at AS started_at
					,t3.finished_at AS finished_at
					,t3.next_process_id AS next_process_id
					,t3.next_job_id AS next_job_id
					--lead time data
					,t3.lead_time AS lead_time
					,t3.process_time AS process_time
					,t3.wait_time AS wait_time
					,t3.normal_leadtime_minutes AS normal_leadtime_minutes
				FROM (
					SELECT t2.line_flow_order AS line_flow_order
						,t2.package_id AS package_id
						,t2.device_id AS device_id
						,t2.assy_name_id AS assy_name_id
						,t2.lot_id AS lot_id
						,t2.lot_no AS lot_no
						,t2.process_id AS process_id
						,t2.job_id AS job_id
						,t2.machine_id AS machine_id
						,t2.started_at AS started_at
						,t2.finished_at AS finished_at
						,t2.next_process_id AS next_process_id
						,t2.next_job_id AS next_job_id
						,DATEDIFF(MINUTE, @date_from, t2.finished_at) AS line_finished_minutes
						--lead time data
						,t2.lead_time AS lead_time
						,t2.process_time AS process_time
						,t2.wait_time AS wait_time
						,t2.normal_leadtime_minutes AS normal_leadtime_minutes
					FROM (
						SELECT tf.line_flow_order AS line_flow_order
							,t1.package_id AS package_id
							,t1.device_id AS device_id
							,t1.assy_name_id AS assy_name_id
							,t1.lot_id AS lot_id
							,tl.lot_no AS lot_no
							,t1.process_id AS process_id
							,t1.job_id AS job_id
							,t1.code AS code
							,t1.machine_id AS machine_id
							--,t1.process_time AS process_time
							--,t1.wait_time AS wait_time
							,t1.started_at AS started_at
							,DATEADD(MINUTE, t1.process_time, t1.started_at) AS finished_at
							,t1.next_process_id AS next_process_id
							,t1.next_job_id AS next_job_id
							--lead time data
							,CASE 
								WHEN tf.line_flow_order = tf.last_line_num
									THEN fs.lead_time
								ELSE NULL
								END AS lead_time
							,CASE 
								WHEN tf.line_flow_order = tf.last_line_num
									THEN fs.wait_time
								ELSE NULL
								END AS wait_time
							,CASE 
								WHEN tf.line_flow_order = tf.last_line_num
									THEN fs.process_time
								ELSE NULL
								END AS process_time
							,CASE 
								WHEN tf.line_flow_order = tf.last_line_num
									THEN ds.normal_leadtime_minutes
								ELSE NULL
								END AS normal_leadtime_minutes
						FROM (
							SELECT fe.package_id AS package_id
								,fe.device_id AS device_id
								,fe.assy_name_id AS assy_name_id
								,fe.lot_id AS lot_id
								,fe.process_id AS process_id
								,fe.job_id AS job_id
								,fe.code AS code
								,fe.machine_id AS machine_id
								,fe.process_time AS process_time
								--,fe.wait_time AS wait_time
								,fe.started_at AS started_at
								,fe.next_process_id AS next_process_id
								,fe.next_job_id AS next_job_id
							FROM (
								SELECT f3.*
								FROM (
									SELECT f2.package_id AS package_id
										,f2.flag
										,ROW_NUMBER() OVER (
											PARTITION BY f2.lot_id
											,f2.flag ORDER BY f2.started_at DESC
											) AS day_rank
										,f2.device_id AS device_id
										,f2.assy_name_id AS assy_name_id
										,f2.lot_id AS lot_id
										,f2.process_id AS process_id
										,f2.job_id AS job_id
										,f2.code AS code
										,f2.machine_id AS machine_id
										,f2.process_time AS process_time
										--,f2.wait_time AS wait_time
										,f2.started_at AS started_at
										,f2.next_process_id AS next_process_id
										,f2.next_job_id AS next_job_id
									FROM (
										SELECT day_id AS day_id
											,CASE 
												WHEN day_id < @from
													THEN 1
												ELSE 0
												END AS flag
											,package_id AS package_id
											,device_id AS device_id
											,assy_name_id AS assy_name_id
											,lot_id AS lot_id
											,process_id AS process_id
											,job_id AS job_id
											,code AS code
											,machine_id AS machine_id
											,process_time AS process_time
											--,wait_time AS wait_time
											,started_at AS started_at
											,next_process_id AS next_process_id
											,next_job_id AS next_job_id
										FROM APCSProDWH.dwh.fact_end WITH (NOLOCK)
										) AS f2
									INNER JOIN (
										SELECT lot_id AS lot_id
										FROM APCSProDWH.dwh.fact_end AS fe WITH (NOLOCK)
										WHERE fe.package_id = @package_id
											AND fe.day_id >= @from
											AND fe.day_id <= @to
											AND code = 2
										GROUP BY lot_id
										) AS f ON f.lot_id = f2.lot_id
									WHERE f2.package_id = @package_id
										--AND fe.day_id >= @from
										AND f2.day_id <= @to
										--AND code = 2
									) AS f3
								WHERE (
										f3.flag = 0
										OR (
											f3.flag = 1
											AND f3.day_rank = 1
											)
										)
								) AS fe
							) AS t1
						INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = t1.lot_id
						INNER JOIN APCSProDB.method.device_slips AS ds WITH (NOLOCK) ON ds.device_slip_id = tl.device_slip_id
						LEFT OUTER JOIN (
							SELECT dp2.*
								,max(dp2.line_flow_order) OVER () AS last_line_num
							FROM (
								SELECT row_number() OVER (
										ORDER BY dp.process_no
										) AS line_flow_order
									,dp.package_id AS package_id
									,dp.process_id AS process_id
									,dp.process_no AS process_no
									,dp.process_name AS process_name
								FROM APCSProDWH.dwh.dim_package_processes AS dp WITH (NOLOCK)
								WHERE dp.package_id = @package_id
								) AS dp2
							) AS tf ON tf.process_id = t1.process_id
						LEFT OUTER JOIN APCSProDWH.dwh.fact_shipment AS fs WITH (NOLOCK) ON fs.lot_id = t1.lot_id
						) AS t2
					WHERE substring(t2.lot_no, 5, 1) <> 'D'
					) AS t3
				INNER JOIN APCSProDWH.dwh.dim_packages AS dp WITH (NOLOCK) ON dp.id = t3.package_id
				INNER JOIN APCSProDWH.dwh.dim_processes AS dr WITH (NOLOCK) ON dr.id = t3.process_id
				INNER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = t3.job_id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_assy_device_names AS dd WITH (NOLOCK) ON dd.id = t3.assy_name_id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t3.machine_id
				) AS t4
			) AS t5
		ORDER BY lot_id
			,line_flow_order
	END
	ELSE
	BEGIN
		SELECT *
		INTO #p_table
		FROM (
			SELECT pp.package_id AS package_id
				,pp.process_id AS process_id
				,pp.process_no AS process_no
				,pp.process_name AS process_name
				,pj.job_id AS job_id
				,pj.job_no AS job_no
				,pj.job_name AS job_name
				,pj.is_skipped AS is_skipped
				,dense_rank() OVER (
					ORDER BY pp.process_no
					) AS p_rank
			FROM APCSProDWH.dwh.dim_package_processes AS pp WITH (NOLOCK)
			LEFT OUTER JOIN APCSProDWH.dwh.dim_package_jobs AS pj WITH (NOLOCK) ON pj.package_id = pp.package_id
				AND pj.process_id = pp.process_id
				AND pj.process_no = pp.process_no
			WHERE pp.package_id = @package_id
				AND isnull(pj.is_skipped, 0) = 0
			) AS p

		DECLARE @target_process_rank INT = (
				SELECT min(p_rank)
				FROM #p_table
				WHERE process_id = @process_id
				)

		SELECT t5.line_flow_order AS line_flow_order
			,t5.package_id AS package_id
			,t5.package_name AS package_name
			,t5.assy_name_id AS assy_name_id
			,t5.assy_device_rank AS assy_device_rank
			,t5.assy_device_name AS assy_device_name
			,t5.lot_id AS lot_id
			,t5.lot_no AS lot_no
			,t5.process_id AS process_id
			,t5.process_name AS process_name
			,t5.job_id AS job_id
			,t5.job_name AS job_name
			,t5.machine_id AS machine_id
			,t5.machine_name AS machine_name
			,t5.x1 AS x1
			,t5.y1 AS y1
			,t5.x2 AS x2
			,t5.y2 AS y2
			,t5.started_at AS started_at
			,t5.finished_at AS finished_at
			,t5.next_process_id AS next_process_id
			,t5.next_job_id AS next_job_id
			,t5.line_max_minutes AS line_max_minutes
			,@date_to AS date_to
			,max(t5.assy_device_rank) OVER () AS assy_device_num
			--lead time data (dummy)
			,NULL AS lead_time
			,NULL AS wait_time
			,NULL AS process_time
			,NULL AS target_leadtime
			,NULL AS normalized_lead_time
			,NULL AS normalized_wait_time
			,NULL AS normalized_process_time
			,NULL AS normalized_target_leadtime
		FROM (
			SELECT t4.line_flow_order AS line_flow_order
				,t4.package_id AS package_id
				,t4.package_name AS package_name
				,t4.device_id AS device_id
				,dense_rank() OVER (
					ORDER BY t4.device_id
					) AS device_rank
				,t4.assy_name_id AS assy_name_id
				,dense_rank() OVER (
					ORDER BY t4.assy_name_id
					) AS assy_device_rank
				,t4.assy_device_name AS assy_device_name
				,t4.lot_id AS lot_id
				,t4.lot_no AS lot_no
				,t4.process_id AS process_id
				,t4.process_name AS process_name
				,t4.job_id AS job_id
				,t4.job_name AS job_name
				,t4.machine_id AS machine_id
				,t4.machine_name AS machine_name
				,t4.x1 AS x1
				,t4.line_max_minutes - t4.y1 AS y1
				,t4.x2 AS x2
				,t4.line_max_minutes - t4.y2 AS y2
				,t4.started_at AS started_at
				,t4.finished_at AS finished_at
				,t4.next_process_id AS next_process_id
				,t4.next_job_id AS next_job_id
				,t4.line_max_minutes AS line_max_minutes
			FROM (
				SELECT t3.line_flow_order AS line_flow_order
					,t3.package_id AS package_id
					,dp.name AS package_name
					,t3.device_id AS device_id
					,t3.assy_name_id AS assy_name_id
					,dd.name AS assy_device_name
					,t3.lot_id AS lot_id
					,t3.lot_no AS lot_no
					,t3.process_id AS process_id
					,dr.name AS process_name
					,t3.job_id AS job_id
					,dj.name AS job_name
					,t3.machine_id AS machine_id
					,dm.name AS machine_name
					--line coordinate of polyline
					,datediff(MINUTE, @date_from, @date_to) AS line_max_minutes
					,lag(t3.line_flow_order, 1, t3.line_flow_order) OVER (
						PARTITION BY t3.lot_id ORDER BY t3.line_flow_order
							,t3.started_at
						) AS x1
					,lag(t3.line_finished_minutes, 1, t3.line_finished_minutes) OVER (
						PARTITION BY t3.lot_id ORDER BY
							--t3.line_flow_order
							--	,t3.started_at
							--important!
							t3.started_at
							,t3.line_flow_order
						) AS y1
					,t3.line_flow_order AS x2
					,t3.line_finished_minutes AS y2
					,t3.process_time AS process_time
					,t3.wait_time AS wait_time
					,t3.started_at AS started_at
					,t3.finished_at AS finished_at
					,t3.next_process_id AS next_process_id
					,t3.next_job_id AS next_job_id
				FROM (
					SELECT t2.line_flow_order AS line_flow_order
						,t2.package_id AS package_id
						,t2.device_id AS device_id
						,t2.assy_name_id AS assy_name_id
						,t2.lot_id AS lot_id
						,t2.lot_no AS lot_no
						,t2.process_id AS process_id
						,t2.job_id AS job_id
						,t2.machine_id AS machine_id
						,t2.process_time AS process_time
						,t2.wait_time AS wait_time
						,t2.started_at AS started_at
						,t2.finished_at AS finished_at
						,t2.next_process_id AS next_process_id
						,t2.next_job_id AS next_job_id
						,DATEDIFF(MINUTE, @date_from, t2.finished_at) AS line_finished_minutes
					FROM (
						SELECT tf.line_flow_order AS line_flow_order
							,t1.package_id AS package_id
							,t1.device_id AS device_id
							,t1.assy_name_id AS assy_name_id
							,t1.lot_id AS lot_id
							,tl.lot_no AS lot_no
							,t1.process_id AS process_id
							,t1.job_id AS job_id
							,t1.code AS code
							,t1.machine_id AS machine_id
							,t1.process_time AS process_time
							,t1.wait_time AS wait_time
							,t1.started_at AS started_at
							,DATEADD(MINUTE, t1.process_time, t1.started_at) AS finished_at
							,t1.next_process_id AS next_process_id
							,t1.next_job_id AS next_job_id
						FROM (
							SELECT fe.package_id AS package_id
								,fe.device_id AS device_id
								,fe.assy_name_id AS assy_name_id
								,fe.lot_id AS lot_id
								,fe.process_id AS process_id
								,fe.job_id AS job_id
								,fe.code AS code
								,fe.machine_id AS machine_id
								,fe.process_time AS process_time
								,fe.wait_time AS wait_time
								,fe.started_at AS started_at
								,fe.next_process_id AS next_process_id
								,fe.next_job_id AS next_job_id
							FROM (
								SELECT f3.*
								FROM (
									SELECT f2.package_id AS package_id
										,f2.flag
										,ROW_NUMBER() OVER (
											PARTITION BY f2.lot_id
											,f2.flag ORDER BY f2.started_at DESC
											) AS day_rank
										,f2.device_id AS device_id
										,f2.assy_name_id AS assy_name_id
										,f2.lot_id AS lot_id
										,f2.process_id AS process_id
										,f2.job_id AS job_id
										,f2.code AS code
										,f2.machine_id AS machine_id
										,f2.process_time AS process_time
										,f2.wait_time AS wait_time
										,f2.started_at AS started_at
										,f2.next_process_id AS next_process_id
										,f2.next_job_id AS next_job_id
									FROM (
										SELECT day_id AS day_id
											,CASE 
												WHEN day_id < @from
													THEN 1
												ELSE 0
												END AS flag
											,package_id AS package_id
											,device_id AS device_id
											,assy_name_id AS assy_name_id
											,lot_id AS lot_id
											,process_id AS process_id
											,job_id AS job_id
											,code AS code
											,machine_id AS machine_id
											,process_time AS process_time
											,wait_time AS wait_time
											,started_at AS started_at
											,next_process_id AS next_process_id
											,next_job_id AS next_job_id
										FROM APCSProDWH.dwh.fact_end WITH (NOLOCK)
										) AS f2
									INNER JOIN (
										SELECT lot_id AS lot_id
										FROM APCSProDWH.dwh.fact_end AS fe WITH (NOLOCK)
										WHERE fe.package_id = @package_id
											AND fe.day_id >= @from
											AND fe.day_id <= @to
										GROUP BY lot_id
										) AS f ON f.lot_id = f2.lot_id
									INNER JOIN #p_table AS pt ON pt.process_id = f2.process_id
										AND pt.job_id = f2.job_id
									WHERE f2.package_id = @package_id
										AND f2.day_id <= @to
									) AS f3
								WHERE (
										f3.flag = 0
										OR (
											f3.flag = 1
											AND f3.day_rank = 1
											)
										)
								) AS fe
							) AS t1
						INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = t1.lot_id
						LEFT OUTER JOIN (
							SELECT row_number() OVER (
									ORDER BY pt3.process_no
										,pt3.job_no
									) AS line_flow_order
								,pt3.package_id AS package_id
								,pt3.process_id AS process_id
								,pt3.process_no AS process_no
								,pt3.process_name AS process_name
								,pt3.job_id AS job_id
								,pt3.job_no AS job_no
								,isnull(pt3.job_name, pt3.process_name) AS job_name
								,pt3.p_rank_group AS p_rank_group
								,pt3.pre_order AS pre_order
								,pt3.pst_order AS pst_order
							FROM (
								SELECT *
									,ROW_NUMBER() OVER (
										PARTITION BY pt2.p_rank_group ORDER BY pt2.process_no DESC
											,pt2.job_no DESC
										) AS pre_order
									,ROW_NUMBER() OVER (
										PARTITION BY pt2.p_rank_group ORDER BY pt2.process_no
											,pt2.job_no
										) AS pst_order
								FROM (
									SELECT pt.*
										,CASE 
											WHEN @target_process_rank > pt.p_rank
												THEN - 1
											WHEN @target_process_rank = pt.p_rank
												THEN 0
											WHEN @target_process_rank < pt.p_rank
												THEN 1
											END AS p_rank_group
									FROM #p_table AS pt
									) AS pt2
								) AS pt3
							WHERE (pt3.p_rank_group = 0)
								OR (
									pt3.p_rank_group = - 1
									AND pt3.pre_order < @range
									)
								OR (
									pt3.p_rank_group = 1
									AND pt3.pst_order < @range
									)
							) AS tf ON tf.process_id = t1.process_id
							AND tf.job_id = t1.job_id
						) AS t2
					WHERE substring(t2.lot_no, 5, 1) <> 'D'
					) AS t3
				INNER JOIN APCSProDWH.dwh.dim_packages AS dp WITH (NOLOCK) ON dp.id = t3.package_id
				INNER JOIN APCSProDWH.dwh.dim_processes AS dr WITH (NOLOCK) ON dr.id = t3.process_id
				INNER JOIN APCSProDWH.dwh.dim_jobs AS dj WITH (NOLOCK) ON dj.id = t3.job_id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_assy_device_names AS dd WITH (NOLOCK) ON dd.id = t3.assy_name_id
				LEFT OUTER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = t3.machine_id
				) AS t4
			) AS t5
		WHERE line_flow_order IS NOT NULL
		ORDER BY lot_id
			,line_flow_order
	END
END
