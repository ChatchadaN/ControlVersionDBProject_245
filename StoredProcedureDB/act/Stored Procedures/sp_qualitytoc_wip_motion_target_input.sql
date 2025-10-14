
CREATE PROCEDURE [act].[sp_qualitytoc_wip_motion_target_input] (
	@package_id INT
	,@date_from DATE
	,@date_to DATE
	,@target_flag INT = - 1
	,@target_date_from DATE
	,@target_date_to DATE
	)
AS
BEGIN
	--DECLARE @package_id INT = 242
	--DECLARE @date_from DATE = '2020-03-01'
	--DECLARE @date_to DATE = '2020-03-31'
	--declare @target_flag int = 1
	--DECLARE @target_date_from DATE = '2020-03-10'
	--DECLARE @target_date_to DATE = '2020-03-17'
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
	--
	DECLARE @target_from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @target_date_from
			)
	DECLARE @target_to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
			WHERE date_value = @target_date_to
			)

	IF OBJECT_ID(N'tempdb..#Table_lot', N'U') IS NOT NULL
		DROP TABLE #Table_lot;

	SELECT t2.id
		,t2.target_flag
	INTO #Table_lot
	FROM (
		SELECT t1.*
			,CASE 
				WHEN @target_from <= t1.in_date_id
					AND t1.in_date_id <= @target_to
					THEN 1
				ELSE 0
				END AS target_flag
		FROM (
			SELECT CONVERT(DATE, in_at) AS date_value
				,DATEPART(hour, in_at) AS h
				,tl.*
			FROM APCSProDB.trans.lots AS tl WITH (NOLOCK)
			INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
				AND dn.is_assy_only IN (
					0
					,1
					)
			INNER JOIN apcsprodwh.dwh.dim_devices AS dwh_dev WITH (NOLOCK) ON dwh_dev.id = dn.id
			INNER JOIN apcsprodwh.dwh.dim_assy_device_names AS dwh_assy WITH (NOLOCK) ON dwh_assy.id = dn.id
			INNER JOIN apcsprodwh.dwh.dim_packages AS dwh_pkg WITH (NOLOCK) ON dwh_pkg.id = tl.act_package_id
			WHERE tl.in_at IS NOT NULL
				AND @from <= tl.in_date_id
				AND tl.in_date_id <= @to
				AND tl.act_package_id = @package_id
			) AS t1
		INNER JOIN apcsprodwh.dwh.dim_days AS dwh_days WITH (NOLOCK) ON dwh_days.date_value = t1.date_value
		INNER JOIN apcsprodwh.dwh.dim_hours AS dwh_hours WITH (NOLOCK) ON dwh_hours.h = T1.h
		) AS t2

	--WHERE (
	--		@target_flag >= 0
	--		AND target_flag = @target_flag
	--		)
	--	OR (@target_flag < 0)
	SELECT p2.day_id AS day_id
		,p2.date_value AS date_value
		,p2.package_id AS package_id
		,p2.process_id AS process_id
		,p2.process_no AS process_no
		,p2.process_name AS process_name
		,p2.job_id AS job_id
		,p2.job_no AS job_no
		,p2.job_name AS job_name
		--,isnull(wip_lot_count, 0) AS wip_lot_count
		,isnull(t10.wip_kpcs, 0) AS wip_kpcs
		,isnull(t10.all_wip_kpcs, 0) AS all_wip_kpcs
	FROM (
		SELECT d.day_id AS day_id
			,d.date_value AS date_value
			,p1.package_id AS package_id
			,p1.process_id AS process_id
			,p1.process_no AS process_no
			,p1.process_name AS process_name
			,p1.job_id AS job_id
			,p1.job_no AS job_no
			,p1.job_name AS job_name
		FROM (
			SELECT dd.id AS day_id
				,dd.date_value AS date_value
			FROM APCSProDWH.dwh.dim_days AS dd
			WHERE @from <= dd.id
				AND dd.id <= @to
			) AS d
		CROSS JOIN (
			SELECT p.package_id AS package_id
				,p.job_id AS job_id
				,p.job_no AS job_no
				,p.job_name AS job_name
				,p.is_skipped AS is_skipped
				,p.process_id AS process_id
				,p.process_no AS process_no
				,p.process_name AS process_name
			FROM (
				SELECT pj.package_id AS package_id
					,pj.job_id AS job_id
					,pj.job_no AS job_no
					,pj.job_name AS job_name
					,isnull(pj.is_skipped, 0) AS is_skipped
					,pj.process_id AS process_id
					,pj.process_no AS process_no
					,pj.process_name AS process_name
				FROM APCSProDWH.dwh.dim_package_jobs AS pj WITH (NOLOCK)
				WHERE package_id = @package_id
				) AS p
			WHERE is_skipped = 0
			) AS p1
		) AS p2
	LEFT OUTER JOIN (
		SELECT t9.day_id AS day_id
			,t9.date_value AS date_value
			,t9.package_id AS package_id
			,t9.process_id AS process_id
			,t9.job_id AS job_id
			,sum(t9.wip_kpcs) AS wip_kpcs
			,sum(t9.wip_kpcs) + sum(t9.no_target_wip_kpcs) AS all_wip_kpcs
		FROM (
			SELECT t8.day_id AS day_id
				,t8.date_value AS date_value
				,t8.package_id AS package_id
				,t8.process_id AS process_id
				,t8.job_id AS job_id
				--,t8.wip_kpcs AS wip_kpcs
				,t8.target_flag AS target_flag
				,CASE 
					WHEN t8.target_flag = 1
						THEN t8.wip_kpcs
					ELSE 0
					END AS wip_kpcs
				,CASE 
					WHEN t8.target_flag = 0
						THEN t8.wip_kpcs
					ELSE 0
					END AS no_target_wip_kpcs
			FROM (
				SELECT t7.day_id AS day_id
					,t7.date_value AS date_value
					,@package_id AS package_id
					,t7.wip_process_id AS process_id
					,t7.wip_job_id AS job_id
					--,isnull(count(t7.lot_id), 0) AS wip_lot_count
					,isnull(convert(DECIMAL(16, 1), sum(t7.qty_pass)) / 1000, 0) AS wip_kpcs
					,t7.target_flag AS target_flag
				FROM (
					SELECT t6.target_flag AS target_flag
						,t6.lot_id AS lot_id
						,t6.day_id AS day_id
						,t6.date_value AS date_value
						,t6.recorded_at AS recorded_at
						,t6.record_class AS record_class
						,CASE 
							WHEN t6.record_class = 1
								THEN t6.process_id
							WHEN t6.record_class = 2
								THEN CASE 
										WHEN t6.process_id = 1
											THEN t6.start_process_id
										ELSE t6.next_process_id
										END
							END wip_process_id
						,CASE 
							WHEN t6.record_class = 1
								THEN t6.job_id
							WHEN t6.record_class = 2
								THEN CASE 
										WHEN t6.job_id = 3
											THEN t6.start_job_id
										ELSE t6.next_job_id
										END
							END wip_job_id
						,t6.qty_pass AS qty_pass
					FROM (
						SELECT t5.target_flag AS target_flag
							,t5.lot_id AS lot_id
							,t5.day_id AS day_id
							,t5.date_value AS date_value
							,t5.recorded_at AS recorded_at
							,CASE 
								WHEN t5.record_class IS NULL
									THEN lag(t5.record_class, t5.day_offset) OVER (
											ORDER BY t5.lot_id
												,t5.date_value
											)
								ELSE t5.record_class
								END AS record_class
							,CASE 
								WHEN t5.record_class IS NULL
									THEN lag(t5.process_id, t5.day_offset) OVER (
											PARTITION BY t5.lot_id ORDER BY t5.lot_id
												,t5.date_value
											)
								ELSE t5.process_id
								END AS process_id
							,CASE 
								WHEN t5.record_class IS NULL
									THEN lag(t5.job_id, t5.day_offset) OVER (
											PARTITION BY t5.lot_id ORDER BY t5.lot_id
												,t5.date_value
											)
								ELSE t5.job_id
								END AS job_id
							,CASE 
								WHEN t5.record_class IS NULL
									THEN lag(t5.step_no, t5.day_offset) OVER (
											PARTITION BY t5.lot_id ORDER BY t5.lot_id
												,t5.date_value
											)
								ELSE t5.step_no
								END AS step_no
							,CASE 
								WHEN t5.record_class IS NULL
									AND lag(t5.wip_state, t5.day_offset) OVER (
										ORDER BY t5.lot_id
											,t5.date_value
										) <> 100
									THEN lag(t5.qty_pass, t5.day_offset) OVER (
											PARTITION BY t5.lot_id ORDER BY t5.lot_id
												,t5.date_value
											)
								ELSE t5.qty_pass
								END AS qty_pass
							,CASE 
								WHEN t5.record_class IS NULL
									THEN lag(t5.machine_id, t5.day_offset) OVER (
											PARTITION BY t5.lot_id ORDER BY t5.lot_id
												,t5.date_value
											)
								ELSE t5.machine_id
								END AS machine_id
							,t5.wip_state AS wip_state
							,t5.process_state AS process_state
							,CASE 
								WHEN t5.record_class IS NULL
									THEN lag(t5.next_process_id, t5.day_offset) OVER (
											PARTITION BY t5.lot_id ORDER BY t5.lot_id
												,t5.date_value
											)
								ELSE t5.next_process_id
								END AS next_process_id
							,CASE 
								WHEN t5.record_class IS NULL
									THEN lag(t5.next_job_id, t5.day_offset) OVER (
											PARTITION BY t5.lot_id ORDER BY t5.lot_id
												,t5.date_value
											)
								ELSE t5.next_job_id
								END AS next_job_id
							,CASE 
								WHEN t5.record_class IS NULL
									THEN lag(t5.start_process_id, t5.day_offset) OVER (
											PARTITION BY t5.lot_id ORDER BY t5.lot_id
												,t5.date_value
											)
								ELSE t5.start_process_id
								END AS start_process_id
							,CASE 
								WHEN t5.record_class IS NULL
									THEN lag(t5.start_job_id, t5.day_offset) OVER (
											PARTITION BY t5.lot_id ORDER BY t5.lot_id
												,t5.date_value
											)
								ELSE t5.start_job_id
								END AS start_job_id
							,t5.current_wip_state AS current_wip_state
						FROM (
							SELECT t4.target_flag AS target_flag
								,t4.lot_id AS lot_id
								,t4.day_id AS day_id
								,t4.date_value AS date_value
								,t4.flag AS flag
								,t4.diff_num AS diff_num
								,ROW_NUMBER() OVER (
									PARTITION BY t4.lot_id
									,t4.flag
									,t4.diff_num ORDER BY t4.lot_id
										,t4.date_value
									) AS day_offset
								,t4.recorded_at AS recorded_at
								,t4.record_class AS record_class
								,t4.process_id AS process_id
								,t4.job_id AS job_id
								,t4.step_no AS step_no
								,t4.qty_pass AS qty_pass
								,t4.machine_id AS machine_id
								,t4.wip_state AS wip_state
								,t4.process_state AS process_state
								,t4.next_process_id AS next_process_id
								,t4.next_job_id AS next_job_id
								,t4.start_process_id AS start_process_id
								,t4.start_job_id AS start_job_id
								,t4.current_wip_state AS current_wip_state
							FROM (
								SELECT t3.target_flag AS target_flag
									,t3.lot_id AS lot_id
									,t3.day_id AS day_id
									,t3.date_value AS date_value
									,t3.flag AS flag
									,row_number() OVER (
										PARTITION BY t3.lot_id ORDER BY t3.date_value
										) - row_number() OVER (
										PARTITION BY t3.lot_id
										,t3.flag ORDER BY t3.date_value
										) AS diff_num
									,t3.recorded_at AS recorded_at
									,t3.record_class AS record_class
									,t3.process_id AS process_id
									,t3.job_id AS job_id
									,t3.step_no AS step_no
									,t3.qty_pass AS qty_pass
									,t3.machine_id AS machine_id
									,t3.wip_state AS wip_state
									,t3.process_state AS process_state
									,t3.next_process_id AS next_process_id
									,t3.next_job_id AS next_job_id
									,t3.start_process_id AS start_process_id
									,t3.start_job_id AS start_job_id
									,t3.current_wip_state AS current_wip_state
								FROM (
									SELECT t1.target_flag AS target_flag
										,t1.lot_id AS lot_id
										,t1.day_id AS day_id
										,t1.date_value AS date_value
										,isnull(t2.rank_day_last_record, 1) AS rank_day_last_record
										,CASE 
											WHEN t2.recorded_at IS NULL
												THEN 1
											ELSE 0
											END AS flag
										,t2.recorded_at AS recorded_at
										,t2.record_class AS record_class
										,t2.process_id AS process_id
										,t2.job_id AS job_id
										,t2.step_no AS step_no
										,t2.qty_pass AS qty_pass
										,t2.machine_id AS machine_id
										,t2.wip_state AS wip_state
										,t2.process_state AS process_state
										,t2.next_process_id AS next_process_id
										,t2.next_job_id AS next_job_id
										,t2.start_process_id AS start_process_id
										,t2.start_job_id AS start_job_id
										,t2.current_wip_state AS current_wip_state
									FROM (
										SELECT dd.id AS day_id
											,dd.date_value AS date_value
											,t_lot.id AS lot_id
											,t_lot.target_flag AS target_flag
										FROM APCSProDWH.dwh.dim_days AS dd
										CROSS JOIN #Table_lot AS t_lot
										WHERE @from <= dd.id
											AND dd.id <= @to
										) AS t1
									LEFT OUTER JOIN (
										SELECT ROW_NUMBER() OVER (
												PARTITION BY day_id
												,lot_id ORDER BY recorded_at DESC
												) AS rank_day_last_record
											,lpr.day_id AS day_id
											,lpr.recorded_at AS recorded_at
											,lpr.record_class AS record_class
											,lpr.lot_id AS lot_id
											,lpr.process_id AS process_id
											,lpr.job_id AS job_id
											,lpr.step_no AS step_no
											,lpr.qty_pass AS qty_pass
											,lpr.machine_id AS machine_id
											,lpr.wip_state AS wip_state
											,lpr.process_state AS process_state
											,dfn.act_process_id AS next_process_id
											,dfn.job_id AS next_job_id
											,dff.act_process_id AS start_process_id
											,dff.job_id AS start_job_id
											,tl.wip_state AS current_wip_state
										FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
										INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = lpr.lot_id
										LEFT OUTER JOIN apcsprodb.method.device_flows AS df WITH (NOLOCK) ON df.device_slip_id = tl.device_slip_id
											AND df.step_no = lpr.step_no
										LEFT OUTER JOIN apcsprodb.method.device_flows AS dfn WITH (NOLOCK) ON dfn.device_slip_id = df.device_slip_id
											AND dfn.step_no = df.next_step_no
										LEFT OUTER JOIN apcsprodb.method.device_flows AS dff WITH (NOLOCK) ON dff.device_slip_id = tl.device_slip_id
											AND dff.step_no = tl.start_step_no
										INNER JOIN #Table_lot AS tt ON tt.id = lpr.lot_id
										WHERE lpr.record_class IN (
												1
												,2
												)
										) AS t2 ON t2.day_id = t1.day_id
										AND t2.lot_id = t1.lot_id
									) AS t3
								WHERE t3.rank_day_last_record = 1
								) AS t4
							) AS t5
						) AS t6
					) AS t7
				GROUP BY t7.day_id
					,t7.date_value
					,t7.wip_process_id
					,t7.wip_job_id
					,t7.target_flag
				) AS t8
			) AS t9
		GROUP BY t9.day_id
			,t9.date_value
			,t9.package_id
			,t9.process_id
			,t9.job_id
		) AS t10 ON t10.day_id = p2.day_id
		AND t10.process_id = p2.process_id
		AND t10.job_id = p2.job_id
	ORDER BY day_id
		,process_no
		,job_no
END
