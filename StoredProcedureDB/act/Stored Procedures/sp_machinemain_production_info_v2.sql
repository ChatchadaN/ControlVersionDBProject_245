
CREATE PROCEDURE [act].[sp_machinemain_production_info_v2] (
	@date_from DATETIME
	,@date_to DATETIME
	,@machine_id INT
	,@time_offset INT = 0
	)
AS
BEGIN
	--DECLARE @machine_id INT = 299
	--DECLARE @date_from DATETIME = '2020-05-30 00:00:00'
	--DECLARE @date_to DATETIME = '2020-07-05 23:59:00'
	--DECLARE @time_offset INT = 0
	DECLARE @local_date_from DATETIME = DATEADD(HOUR, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = CASE 
			WHEN getdate() < DATEADD(HOUR, @time_offset, @date_to)
				THEN format(dateadd(day, 1, GETDATE()), 'yyyy-MM-dd 00:00:00')
			ELSE DATEADD(HOUR, @time_offset, @date_to)
			END
	DECLARE @fr_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
			WHERE date_value = convert(DATE, @date_from)
			)

	--IF OBJECT_ID(N'tempdb..#state_table', N'U') IS NOT NULL
	--	DROP TABLE #state_table;
	SELECT t3.started_at AS started_at
		,t3.end_at AS ended_at
		,t3.machine_id AS machine_id
		,CASE 
			WHEN t3.record_flag = 0
				AND t3.run_state = 1
				--execute
				THEN 4
			WHEN t3.record_flag = 0
				AND t3.run_state = 2
				AND t3.oor_flag = 1
				--期間外(oor_flag=1)LotEndの場合は、直近Stateにする
				THEN run_state_overwrite
			WHEN t3.record_flag = 0
				AND t3.run_state = 12
				--lot end
				THEN 199
			ELSE t3.run_state
			END AS run_state
	INTO #state_table
	FROM (
		SELECT t2.updated_at AS started_at
			,lead(t2.updated_at, 1, CASE 
					WHEN @local_date_to >= GETDATE()
						THEN getdate()
					ELSE @local_date_to
					END) OVER (
				ORDER BY t2.machine_id
					,t2.updated_at
				) AS end_at
			,t2.machine_id AS machine_id
			,t2.online_state AS online_state
			,t2.record_flag AS record_flag
			,t2.run_state AS run_state
			,t2.oor_flag AS oor_flag
			--,t2.lotend_flag AS lotend_flag
			,t2.run_state_overwrite AS run_state_overwrite
		FROM (
			SELECT t1.*
				,ROW_NUMBER() OVER (
					PARTITION BY t1.oor_flag ORDER BY t1.updated_at DESC
					) AS latest_stat_rank
				,CASE 
					WHEN t1.record_flag = 0 and　t1.run_state = 2
						THEN 2
					WHEN t1.record_flag = 0
						AND t1.run_state = 1
						THEN 1
					ELSE 0
					END AS lotend_flag
				--期間外lot_process_recordの場合は、その直近レコードのstateを用いる
				,lag(t1.run_state, 1) OVER (
					PARTITION BY t1.oor_flag ORDER BY t1.updated_at
					) AS run_state_overwrite
			FROM (
				----machine_state_records とmachine_alarm_recordsとlot_process_recordsをUNION
				--machine state
				SELECT top1.updated_at
					,top1.machine_id
					,top1.online_state
					,1 AS record_flag
					,top1.run_state
					,1 AS oor_flag --out of range flag
				FROM (
					SELECT msr.updated_at
						,msr.machine_id
						,msr.online_state
						,msr.run_state
						,ROW_NUMBER() OVER (
							PARTITION BY msr.machine_id ORDER BY msr.updated_at DESC
							) AS up_rank
					--,msr.qc_state
					FROM APCSProDB.trans.machine_state_records AS msr WITH (NOLOCK)
					WHERE machine_id = @machine_id
						AND updated_at < @local_date_from
					) AS top1
				WHERE up_rank <= 1
				
				UNION ALL
				
				SELECT msr.updated_at
					,msr.machine_id
					,msr.online_state
					,1 AS record_flag
					,msr.run_state
					,0 AS oor_flag --out of range flag
				FROM APCSProDB.trans.machine_state_records AS msr WITH (NOLOCK)
				WHERE machine_id = @machine_id
					AND updated_at >= @local_date_from
					AND updated_at <= @local_date_to
				
				UNION ALL
				
				--alarm record
				SELECT top1.alarm_on_at
					,top1.machine_id
					,NULL AS online_state
					,2 AS record_flag
					,99 AS run_state
					,1 AS oor_flag --out of range flag
				FROM (
					SELECT mar.alarm_on_at
						,mar.machine_id
						,ROW_NUMBER() OVER (
							PARTITION BY mar.machine_id ORDER BY mar.alarm_on_at DESC
							) AS up_rank
					FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
					WHERE machine_id = @machine_id
						AND alarm_on_at < @local_date_from
					) AS top1
				WHERE top1.up_rank <= 1
				
				UNION ALL
				
				SELECT mar.alarm_on_at
					,mar.machine_id
					,NULL AS online_state
					,2 AS record_flag
					,99 AS run_state
					,0 AS oor_flag --out of range flag
				FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
				WHERE machine_id = @machine_id
					AND alarm_on_at >= @local_date_from
					AND alarm_on_at <= @local_date_to
				
				UNION ALL
				
				--lot process 
				SELECT top1.recorded_at
					,top1.machine_id
					,NULL AS online_state
					,0 AS record_flag
					,top1.run_state AS run_state
					,1 AS oor_flag --out of range flag
				FROM (
					SELECT lpr.recorded_at
						,lpr.machine_id
						,record_class AS run_state
						,ROW_NUMBER() OVER (
							PARTITION BY lpr.machine_id ORDER BY lpr.recorded_at DESC
							) AS up_rank
					FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
					WHERE machine_id = @machine_id
						AND
						--高速化の為一日前までのデータから絞り込む
						(
							lpr.day_id <= @fr_date
							AND lpr.day_id >= @fr_date - 1
							)
						AND lpr.record_class IN (
							1
							--,11
							,2
							,12
							)
						AND recorded_at < @local_date_from
					) AS top1
				WHERE top1.up_rank <= 1
				
				UNION ALL
				
				SELECT lpr.recorded_at
					,lpr.machine_id
					,NULL AS online_state
					,0 AS record_flag
					,record_class AS run_state
					,0 AS oor_flag --out of range flag
				FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
				WHERE machine_id = @machine_id
					AND lpr.record_class IN (
						1
						--,11
						,2
						,12
						)
					AND recorded_at >= @local_date_from
					AND recorded_at <= @local_date_to
				) AS t1
			) AS t2
		WHERE t2.oor_flag = 0
			OR t2.latest_stat_rank <= 1
		) AS t3

	SELECT v3.pid
		,v3.lot_rank AS lot_rank
		,v3.cancel_flag AS cancel_flag
		,v3.process_job_id AS process_job_id
		,v3.machine_id AS machine_id
		,v3.lot_id AS lot_id
		,v3.lot_no AS lot_no
		,v3.started_at AS started_at
		,v3.finished_at AS finished_at
		,mus.english_name AS started_by_name
		,muf.english_name AS finished_by_name
		,v3.qty_in AS qty_in
		,v3.qty_pass AS qty_pass
		,v3.qty_fail AS qty_fail
		,v3.process_time AS process_time
		,CASE 
			WHEN v3.is_special_flow = 0
				THEN v3.uph_act
			ELSE NULL
			END AS uph_act
		,v3.yield AS yield
		,v3.state_rank AS state_rank
		,v3.state_started_at AS state_started_at
		,v3.state_ended_at AS state_ended_at
		,v3.run_state AS code
		--,il.label_eng AS code_name
		,v3.sum_diff_h AS sum_diff_h
		,v3.sum_diff_h * 100 / v3.process_time AS percent_sum_diff_h
		,v3.other_sum_diff_h AS other_diff_h
		,v3.other_sum_diff_h * 100 / v3.process_time AS percent_other_diff_h
		,v3.process_id
		,p.name AS process_name
		,v3.job_id
		,j.name AS job_name
		,v3.is_special_flow
		--use for tooltips
		,CASE 
			WHEN v3.is_special_flow = 0
				THEN v3.lot_no
			ELSE v3.lot_no + '(special_flow)'
			END AS lot_no_ex
	FROM (
		SELECT row_number() OVER (
				ORDER BY v2.started_at
					,v2.state_started_at
				) AS pid
			,v2.*
			,sum(v2.diff_h) OVER (
				PARTITION BY v2.lot_id
				,v2.process_job_id
				,v2.run_state
				) AS sum_diff_h
			,v2.process_time - sum(v2.diff_h) OVER (
				PARTITION BY v2.lot_id
				,v2.process_job_id
				) AS other_sum_diff_h
		FROM (
			SELECT ROW_NUMBER() OVER (
					PARTITION BY v1.lot_id
					,v1.process_job_id ORDER BY v1.started_at
						,v1.state_started_at
					) AS lot_rank
				,v1.cancel_flag AS cancel_flag
				,v1.process_job_id AS process_job_id
				,v1.machine_id AS machine_id
				,v1.lot_id AS lot_id
				,v1.lot_no AS lot_no
				,v1.started_at AS started_at
				,v1.finished_at AS finished_at
				,v1.started_by AS started_by
				,v1.finished_by AS finished_by
				,v1.qty_in AS qty_in
				,v1.qty_pass AS qty_pass
				,v1.qty_fail AS qty_fail
				,v1.process_time AS process_time
				,v1.uph_act AS uph_act
				,v1.yield AS yield
				,
				--
				ROW_NUMBER() OVER (
					PARTITION BY v1.lot_id
					,v1.process_job_id
					,v1.run_state ORDER BY v1.started_at
						,v1.state_started_at
					) AS state_rank
				,v1.state_started_at AS state_started_at
				,v1.state_ended_at AS state_ended_at
				,
				--diff_h:1sec以下は0.0
				convert(DECIMAL(9, 1), DATEDIFF(second, v1.state_started_at, v1.state_ended_at)) / 60 / 60 AS diff_h
				,v1.run_state AS run_state
				,v1.process_id
				,v1.job_id
				,v1.is_special_flow
			FROM (
				SELECT u2.process_job_id AS process_job_id
					,u2.machine_id AS machine_id
					,u2.lot_id AS lot_id
					,u2.lot_no AS lot_no
					,u2.started_at AS started_at
					,u2.finished_at AS finished_at
					,u2.started_by AS started_by
					,u2.finished_by AS finished_by
					,u2.qty_in AS qty_in
					,u2.qty_pass AS qty_pass
					,u2.qty_fail AS qty_fail
					,u2.process_time AS process_time
					,u2.qty_pass / nullif(process_time, 0) AS uph_act
					,convert(DECIMAL(9, 1), u2.qty_pass) / nullif((u2.qty_in), 0) * 100 AS yield
					,u2.cancel_flag AS cancel_flag
					,CASE 
						WHEN u2.started_at > t4.started_at
							THEN u2.started_at
						ELSE t4.started_at
						END AS state_started_at
					,CASE 
						WHEN u2.finished_at < t4.ended_at
							THEN u2.finished_at
						ELSE t4.ended_at
						END AS state_ended_at
					,t4.run_state AS run_state
					,u2.process_id
					,u2.job_id
					,u2.is_special_flow
				FROM (
					SELECT u1.process_job_id AS process_job_id
						,u1.record_class AS record_class
						,u1.lotend_flag AS lotend_flag
						,u1.machine_id AS machine_id
						,u1.lot_id AS lot_id
						,u1.lot_no AS lot_no
						,u1.started_at AS started_at
						,u1.finished_at AS finished_at
						,convert(DECIMAL(9, 1), DATEDIFF(SECOND, u1.started_at, u1.finished_at)) / 60 / 60 AS process_time
						,u1.operated_by AS started_by
						,u1.operated_by AS finished_by
						,CASE 
							WHEN u1.lotend_flag = 1
								THEN u1.qty_pass_step_sum + u1.qty_fail_step_sum
							ELSE u1.qty_pass
							END AS qty_in
						,u1.qty_pass_step_sum AS qty_pass
						,u1.qty_fail_step_sum AS qty_fail
						,cancel_flag AS cancel_flag
						,u1.process_id
						,u1.job_id
						,u1.is_special_flow
					FROM (
						SELECT lpr.process_job_id AS process_job_id
							,lpr.operated_by AS operated_by
							,lpr.started_at AS started_at
							,lpr.finished_at AS finished_at
							,cancel_flag AS cancel_flag
							,lpr.lotend_flag AS lotend_flag
							,lpr.machine_id AS machine_id
							,lpr.lot_id AS lot_id
							,tl.lot_no AS lot_no
							,lpr.record_class AS record_class
							,lpr.qty_in AS qty_in
							,lpr.qty_pass AS qty_pass
							,lpr.qty_fail AS qty_fail
							,lpr.qty_pass_step_sum AS qty_pass_step_sum
							,lpr.qty_fail_step_sum AS qty_fail_step_sum
							,lpr.process_id
							,lpr.job_id
							,lpr.is_special_flow
						FROM (
							SELECT t3.finished_record_class_rank AS finished_record_class_rank
								,t3.record_class AS record_class
								,t3.lotend_flag AS lotend_flag
								,t3.cancel_flag AS cancel_flag
								,t3.process_job_id AS process_job_id
								,t3.machine_id AS machine_id
								,t3.started_at AS started_at
								,t3.finished_at AS finished_at
								,t3.operated_by AS operated_by
								,t3.lot_id AS lot_id
								,t3.qty_in AS qty_in
								,t3.qty_pass AS qty_pass
								,t3.qty_fail AS qty_fail
								,t3.qty_pass_step_sum AS qty_pass_step_sum
								,t3.qty_fail_step_sum AS qty_fail_step_sum
								,t3.process_id
								,t3.job_id
								,t3.is_special_flow
							FROM (
								SELECT ROW_NUMBER() OVER (
										PARTITION BY t2.process_job_id
										,t2.lot_id ORDER BY t2.lotend_flag DESC
											,t2.recorded_at DESC
										) AS finished_record_class_rank
									,t2.record_class AS record_class
									,t2.lotend_flag AS lotend_flag
									,max(t2.cancel_flag) OVER (
										PARTITION BY t2.lot_id
										,t2.process_job_id
										) AS cancel_flag
									,t2.process_job_id AS process_job_id
									,t2.machine_id AS machine_id
									,t2.started_at AS started_at
									,CASE 
										WHEN t2.finished_at IS NULL
											THEN latest_recorded_at
										ELSE t2.finished_at
										END AS finished_at
									,t2.operated_by AS operated_by
									,t2.lot_id AS lot_id
									,t2.qty_in AS qty_in
									,t2.qty_pass AS qty_pass
									,t2.qty_fail AS qty_fail
									,t2.qty_pass_step_sum AS qty_pass_step_sum
									,t2.qty_fail_step_sum AS qty_fail_step_sum
									,t2.process_id
									,t2.job_id
									,t2.is_special_flow
								FROM (
									SELECT t1.*
										,rec.recorded_at AS recorded_at
										,rec.operated_by AS operated_by
										,rec.record_class AS record_class
										,CASE 
											WHEN rec.record_class = 2
												THEN 1
											ELSE 0
											END AS lotend_flag
										,CASE 
											WHEN rec.record_class = 6
												THEN 1
											ELSE 0
											END AS cancel_flag
										,rec.qty_in AS qty_in
										,rec.qty_pass AS qty_pass
										,rec.qty_fail AS qty_fail
										,rec.qty_pass_step_sum AS qty_pass_step_sum
										,rec.qty_fail_step_sum AS qty_fail_step_sum
										,rec.process_id
										,rec.job_id
										,rec.is_special_flow
										,max(rec.recorded_at) OVER (
											PARTITION BY rec.lot_id
											,rec.process_job_id
											) AS latest_recorded_at
									FROM (
										SELECT pl.pj_id AS process_job_id
											,pj.machine_id AS machine_id
											,pj.started_at AS started_at
											,pj.finished_at AS finished_at
											,pl.lot_id AS lot_id
										FROM APCSProDWH.dwh.view_fact_pjs AS pj WITH (NOLOCK)
										INNER JOIN APCSProDWH.dwh.view_fact_pj_lots AS pl WITH (NOLOCK) ON pl.pj_id = pj.id
										WHERE pj.machine_id = @machine_id
											AND (
												(
													NOT (pj.finished_at < @local_date_from)
													AND NOT (@local_date_to < pj.started_at)
													)
												OR (
													pj.started_at BETWEEN @local_date_from
														AND @local_date_to
													AND pj.finished_at IS NULL
													)
												)
										) AS t1
									LEFT OUTER JOIN apcsprodb.trans.lot_process_records AS rec WITH (NOLOCK) ON rec.lot_id = t1.lot_id
										AND rec.process_job_id = t1.process_job_id
									) AS t2
								) AS t3
							WHERE t3.finished_record_class_rank = 1
							) AS lpr
						INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = lpr.lot_id
						) AS u1
					) AS u2
				LEFT OUTER JOIN #state_table AS t4 ON (u2.started_at <= t4.ended_at)
					AND (t4.started_at <= u2.finished_at)
				) AS v1
			) AS v2
		) AS v3
	LEFT OUTER JOIN APCSProDB.man.users AS mus WITH (NOLOCK) ON mus.id = v3.started_by
	LEFT OUTER JOIN APCSProDB.man.users AS muf WITH (NOLOCK) ON muf.id = v3.finished_by
	LEFT OUTER JOIN APCSProDB.method.processes AS p WITH (NOLOCK) ON p.id = v3.process_id
	LEFT OUTER JOIN APCSProDB.method.jobs AS j WITH (NOLOCK) ON j.id = v3.job_id
	WHERE v3.state_rank = 1
	--AND lot_rank = 1
	ORDER BY v3.started_at
		,v3.state_started_at
END
