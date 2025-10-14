
CREATE PROCEDURE [act].[sp_machinemonitor_summary_status_v5] (
	@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@machine_id_list NVARCHAR(max) = NULL
	)
AS
BEGIN
	--DECLARE @machine_id_list NVARCHAR(max) = '308,242'
	--DECLARE @date_from DATETIME = '2020-06-04 00:00:00'
	--DECLARE @date_to DATETIME = '2020-06-05 00:00:00'
	--DECLARE @time_offset INT = 0
	------
	DECLARE @cur_date DATETIME = getdate()
	DECLARE @local_date_from DATETIME = DATEADD(HOUR, @time_offset, @date_from)
	--DECLARE @local_date_to DATETIME = CASE 
	--		WHEN @cur_date < DATEADD(HOUR, @time_offset, @date_to)
	--			THEN format(dateadd(day, 1, @cur_date), 'yyyy-MM-dd 00:00:00')
	--		ELSE DATEADD(HOUR, @time_offset, @date_to)
	--		END
	DECLARE @local_date_to DATETIME = DATEADD(HOUR, @time_offset, @date_to)
	DECLARE @local_machine_id_list NVARCHAR(max) = @machine_id_list

	IF OBJECT_ID(N'tempdb..#date_table_s', N'U') IS NOT NULL
		DROP TABLE #date_table_s;

	IF OBJECT_ID(N'tempdb..#onlineend_rec_s', N'U') IS NOT NULL
		DROP TABLE #onlineend_rec_s;

	IF OBJECT_ID(N'tempdb..#lotend_table_s', N'U') IS NOT NULL
		DROP TABLE #lotend_table_s;

	IF OBJECT_ID(N'tempdb..#state_table_s', N'U') IS NOT NULL
		DROP TABLE #state_table_s;

	IF OBJECT_ID(N'tempdb..#alarm_table_s', N'U') IS NOT NULL
		DROP TABLE #alarm_table_s;

	IF OBJECT_ID(N'tempdb..#summary_table_s', N'U') IS NOT NULL
		DROP TABLE #summary_table_s;

	SELECT t.machine_id
		,CASE 
			WHEN MIN(started_at) > @local_date_from
				THEN @local_date_from
			ELSE MIN(started_at)
			END AS min_started_at
		,CASE 
			WHEN MAX(finished_at) < @local_date_to
				THEN @local_date_to
			ELSE MAX(finished_at)
			END AS max_finished_at
	INTO #date_table_s
	FROM (
		SELECT machine_id
			--,started_at
			,isnull(setup_at, started_at) started_at
			,CASE 
				WHEN finished_at IS NULL
					THEN CASE 
							WHEN @local_date_to >= @cur_date
								THEN @cur_date
							ELSE @local_date_to
							END
				ELSE finished_at
				END AS finished_at
		FROM APCSProDWH.dwh.view_fact_pjs AS pj WITH (NOLOCK)
		--INNER JOIN (
		--	SELECT CONVERT(INT, value) AS value
		--	FROM STRING_SPLIT(@local_machine_id_list, ',')
		--	) AS v ON v.value = pj.machine_id
		WHERE pj.machine_id IN (
				SELECT value
				FROM STRING_SPLIT(@local_machine_id_list, ',')
				)
			AND (
				(
					(@local_date_from < pj.finished_at)
					AND (pj.started_at < @local_date_to)
					)
				OR (
					pj.started_at BETWEEN @local_date_from
						AND @local_date_to
					AND pj.finished_at IS NULL
					)
				)
		) AS t
	GROUP BY machine_id

	----v5
	DECLARE @min_day_id INT = (
			SELECT id - 3
			FROM APCSProDB.trans.days AS td WITH (NOLOCK)
			WHERE td.date_value = (
					SELECT CONVERT(VARCHAR, min(min_started_at), 23)
					FROM #date_table_s
					)
			)
	DECLARE @max_day_id INT = (
			SELECT id + 3
			FROM APCSProDB.trans.days AS td WITH (NOLOCK)
			WHERE td.date_value = (
					SELECT CONVERT(VARCHAR, Max(max_finished_at), 23)
					FROM #date_table_s
					)
			)

	SELECT *
	INTO #onlineend_rec_s
	FROM (
		SELECT lpr.recorded_at
			,lpr.machine_id
			,NULL AS online_state
			,0 AS record_flag
			,record_class AS run_state
			,lot_id
			,process_job_id
			,RANK() OVER (
				PARTITION BY lot_id
				,process_job_id ORDER BY recorded_at DESC
				) AS last_rec
		FROM (
			SELECT r.recorded_at
				,r.machine_id
				,r.record_class
				,r.lot_id
				,r.process_job_id
			FROM APCSProDB.trans.lot_process_records AS r WITH (NOLOCK)
			INNER JOIN (
				SELECT CONVERT(INT, value) AS value
				FROM STRING_SPLIT(@local_machine_id_list, ',')
				) AS v ON v.value = r.machine_id
			WHERE r.day_id BETWEEN @min_day_id
					AND @max_day_id
				AND r.record_class = 12
			) AS lpr
		INNER JOIN #date_table_s AS d ON d.machine_id = lpr.machine_id
			AND d.min_started_at <= lpr.recorded_at
			AND d.max_finished_at >= lpr.recorded_at
		) AS lpr2
	WHERE last_rec = 1

	SELECT u2.*
		,convert(DECIMAL(9, 1), DATEDIFF(SECOND, u2.std_started_at, u2.std_finished_at)) / 60 / 60 AS std_process_time
	INTO #lotend_table_s
	FROM (
		SELECT u1.process_job_id AS process_job_id
			,u1.record_class AS record_class
			,u1.lotend_flag AS lotend_flag
			,1 AS p_flag
			,u1.machine_id AS machine_id
			,u1.lot_id AS lot_id
			,u1.lot_no AS lot_no
			,@local_date_from AS d_from
			,@local_date_to AS d_to
			,CASE 
				WHEN @local_date_from <= u1.started_at
					THEN u1.started_at
				ELSE @local_date_from
				END AS std_started_at
			,CASE 
				WHEN u1.finished_at <= @local_date_to
					THEN u1.finished_at
				ELSE @local_date_to
				END AS std_finished_at
			----------------------------
			,u1.started_at AS started_at
			,CASE 
				WHEN oe.recorded_at IS NOT NULL
					THEN oe.recorded_at
				ELSE u1.finished_at
				END AS online_end_at
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
							PARTITION BY t2.machine_id
							,t2.process_job_id
							,t2.lot_id ORDER BY t2.lotend_flag DESC
								,t2.recorded_at DESC
							) AS finished_record_class_rank
						,t2.record_class AS record_class
						,t2.lotend_flag AS lotend_flag
						,max(t2.cancel_flag) OVER (
							PARTITION BY t2.machine_id
							,t2.lot_id
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
								PARTITION BY rec.machine_id
								,rec.lot_id
								,rec.process_job_id
								) AS latest_recorded_at
						FROM (
							SELECT pj1.pj_id AS process_job_id
								,machine_id
								--,started_at
								--setupからに変更
								,isnull(setup_at, started_at) AS started_at
								,CASE 
									WHEN finished_at IS NULL
										THEN CASE 
												WHEN @local_date_to >= @cur_date
													THEN @cur_date
												ELSE @local_date_to
												END
									ELSE finished_at
									END AS finished_at
								,pj1.lot_id AS lot_id
							FROM (
								SELECT *
								FROM (
									SELECT *
										,ROW_NUMBER() OVER (
											PARTITION BY machine_id
											,lot_id ORDER BY setup_at DESC
											) AS rk
									FROM APCSProDWH.dwh.view_fact_pjs AS pj WITH (NOLOCK)
									--INNER JOIN (
									--	SELECT CONVERT(INT, value) AS value
									--	FROM STRING_SPLIT(@local_machine_id_list, ',')
									--	) AS v ON v.value = pj.machine_id
									INNER JOIN APCSProDWH.dwh.view_fact_pj_lots AS pl WITH (NOLOCK) ON pl.pj_id = pj.id
									WHERE pj.machine_id IN (
											SELECT value
											FROM STRING_SPLIT(@local_machine_id_list, ',')
											)
										AND (
											(
												(@local_date_from < pj.finished_at)
												AND (pj.started_at < @local_date_to)
												)
											OR (
												pj.started_at BETWEEN @local_date_from
													AND @local_date_to
												AND pj.finished_at IS NULL
												)
											)
									) AS pj0
								--WHERE pj0.rk = 1
								--setupしたがキャンセルされたpjを省く為。
								WHERE (
										pj0.rk > 1
										AND finished_at IS NOT NULL
										)
									OR pj0.rk = 1
								) AS pj1
							) AS t1
						LEFT OUTER JOIN apcsprodb.trans.lot_process_records AS rec WITH (NOLOCK) ON rec.lot_id = t1.lot_id
							AND rec.process_job_id = t1.process_job_id
						) AS t2
					) AS t3
				WHERE t3.finished_record_class_rank = 1
				) AS lpr
			INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = lpr.lot_id
			) AS u1
		LEFT JOIN #onlineend_rec_s AS oe ON oe.lot_id = u1.lot_id
			AND oe.machine_id = u1.machine_id
			AND oe.process_job_id = u1.process_job_id
		) AS u2

	SELECT al.id
		,al.machine_id
		,al.updated_at
		,al.alarm_on_at
		--,al.alarm_off_at
		,CASE 
			WHEN al.alarm_off_at < al.started_at
				THEN al.alarm_off_at
			ELSE al.started_at
			END alarm_off_at
		,al.started_at
		,'a' AS record_type
	INTO #alarm_table_s
	FROM (
		SELECT mar.*
		FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
		INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
			AND ma.alarm_level = 0
		INNER JOIN #date_table_s AS dt ON dt.machine_id = mar.machine_id
			AND (
				mar.updated_at BETWEEN dt.min_started_at
					AND dt.max_finished_at
				)
			AND (
				mar.alarm_on_at BETWEEN dt.min_started_at
					AND dt.max_finished_at
				)
		WHERE mar.machine_id IN (
				SELECT value
				FROM STRING_SPLIT(@local_machine_id_list, ',')
				)
		) AS al
	LEFT JOIN #lotend_table_s AS le ON le.machine_id = al.machine_id
		AND (le.online_end_at <= al.alarm_on_at)
		AND (al.alarm_on_at < le.finished_at)
	WHERE le.machine_id IS NULL

	SELECT st2.machine_id
		,st2.updated_at AS started_at
		,NULL AS finished_at
		,st2.online_state AS online_state
		,st2.run_state AS run_state
		,st2.record_type AS record_type
	INTO #state_table_s
	FROM (
		SELECT st1.*
		FROM (
			SELECT msr.id
				,msr.machine_id
				,msr.updated_at
				,msr.online_state
				,msr.run_state
				,'s' AS record_type
			FROM APCSProDB.trans.machine_state_records AS msr WITH (NOLOCK)
			INNER JOIN #date_table_s AS dt ON dt.machine_id = msr.machine_id
				AND msr.updated_at BETWEEN dt.min_started_at
					AND dt.max_finished_at
			WHERE msr.machine_id IN (
					SELECT value
					FROM STRING_SPLIT(@local_machine_id_list, ',')
					)
			) AS st1
		LEFT JOIN #alarm_table_s AS alm ON alm.machine_id = st1.machine_id
			AND (alm.alarm_on_at <= st1.updated_at)
			--AND (st1.updated_at < alm.alarm_off_at)
			--小数点以下切り捨て処理(2021.12.09)
			AND (st1.updated_at < CONVERT(DATETIME, CONVERT(VARCHAR(24), alm.alarm_off_at, 20)))
		WHERE alm.machine_id IS NULL
		) AS st2
	LEFT JOIN #lotend_table_s AS le ON le.machine_id = st2.machine_id
		AND (le.online_end_at <= st2.updated_at)
		AND (st2.updated_at < le.finished_at)
	WHERE le.machine_id IS NULL

	SELECT t2.machine_id
		,t2.started_at
		,t2.finished_at
		,t2.diff_h
		,org_run_state
		,record_type
		,t2.run_state
		,t2.process_flag
		,t2.lot_id
		,t2.process_job_id
		,process_time
	INTO #summary_table_s
	FROM (
		SELECT t1.machine_id
			,t1.started_at
			,t1.finished_at
			,convert(DECIMAL(9, 1), DATEDIFF(SECOND, t1.started_at, t1.finished_at)) / 60 / 60 AS diff_h
			,t1.online_state
			,t1.run_state AS org_run_state
			--lotend_flag = 1の時は、すべて199(Lotendステータス)にする
			--LotStart(record_type = 'p'でrun_state=1) =>next_run_stateがexecuteなら4,それ以外ならunknown-->全部4にする。
			--LotEnd(record_type = 'p'でrun_state=2) =>next_run_stateがIdleなら1,それ以外ならunknown
			,CASE 
				WHEN t1.record_type = 'p'
					THEN CASE 
							WHEN t1.run_state = 199
								THEN 199
							WHEN t1.run_state = 1
								THEN 4
									--THEN CASE 
									--		WHEN next_run_state = 4
									--			THEN 4
									--		ELSE 255
									--		END
							WHEN t1.run_state = 2
								THEN CASE 
										WHEN next_run_state = 1
											THEN 1
										ELSE 255
										END
							END
				ELSE CASE 
						WHEN lt.p_flag = 1
							THEN 199
						ELSE t1.run_state
						END
				END AS run_state
			,t1.record_type
			,isnull(lt.p_flag, 0) AS lotend_flag
			,isnull(lt2.p_flag, 0) AS process_flag
			,lt2.lot_id AS lot_id
			,lt2.process_job_id
			,lt2.process_time
		FROM (
			SELECT rec1.machine_id
				--,rec1.started_at
				--,rec.finished_at
				,CASE 
					WHEN rec1.started_at <= @local_date_from
						THEN @local_date_from
					ELSE rec1.started_at
					END AS started_at
				,CASE 
					WHEN rec1.finished_at IS NULL
						THEN LEAD(rec1.started_at, 1, CASE 
									WHEN @local_date_to >= @cur_date
										THEN @cur_date
									ELSE @local_date_to
									END) OVER (
								PARTITION BY rec1.machine_id ORDER BY rec1.started_at
								)
					ELSE CASE 
							WHEN LEAD(rec1.started_at) OVER (
									PARTITION BY rec1.machine_id ORDER BY rec1.started_at
									) IS NOT NULL
								THEN CASE 
										WHEN rec1.finished_at < LEAD(rec1.started_at) OVER (
												PARTITION BY rec1.machine_id ORDER BY rec1.started_at
												)
											THEN rec1.finished_at
										ELSE LEAD(rec1.started_at) OVER (
												PARTITION BY rec1.machine_id ORDER BY rec1.started_at
												)
										END
							ELSE rec1.finished_at
							END
					END AS finished_at
				,rec1.online_state
				,rec1.run_state
				,LEAD(rec1.run_state) OVER (
					PARTITION BY rec1.machine_id ORDER BY rec1.started_at
					) AS next_run_state
				,rec1.record_type
			FROM (
				-------------UNION
				SELECT rec.machine_id
					,rec.finished_at AS org_finished_at
					,rec.started_at
					,CASE 
						WHEN rec.finished_at IS NULL
							THEN LEAD(rec.started_at, 1, CASE 
										WHEN @local_date_to >= @cur_date
											THEN @cur_date
										ELSE @local_date_to
										END) OVER (
									PARTITION BY rec.machine_id ORDER BY rec.started_at
									)
						ELSE rec.finished_at
						END AS finished_at
					,rec.online_state
					,rec.run_state
					,LEAD(rec.run_state) OVER (
						PARTITION BY rec.machine_id ORDER BY rec.started_at
						) AS next_run_state
					,rec.record_type
				FROM (
					--①alarm 
					SELECT al.machine_id
						,al.alarm_on_at AS started_at
						,al.alarm_off_at AS finished_at
						,NULL AS online_state
						,99 AS run_state
						,al.record_type
					FROM #alarm_table_s AS al
					
					UNION ALL
					
					--②Machine State
					SELECT st.machine_id
						,st.started_at AS started_at
						,NULL AS finished_at
						,st.online_state AS online_state
						,st.run_state AS run_state
						,st.record_type AS record_type
					FROM #state_table_s AS st
					
					UNION ALL
					
					--③Lot start
					SELECT lts.machine_id
						,lts.started_at
						,NULL AS finished_at
						,NULL AS online_state
						,1 AS run_state
						,'p' AS record_type
					FROM #lotend_table_s AS lts
					
					UNION ALL
					
					--④OnlineEnd ~ LotEnd
					SELECT le.machine_id
						,le.online_end_at AS started_at
						,le.finished_at AS finished_at
						,NULL AS online_state
						,199 AS run_state
						,'p' AS record_type
					FROM #lotend_table_s AS le
					) AS rec
				) AS rec1
			) AS t1
		--最終的にロットエンドステータスを上書きする
		LEFT JOIN #lotend_table_s AS lt ON lt.machine_id = t1.machine_id
			--AND lt.online_end_at <= t1.started_at
			--AND t1.started_at < lt.finished_at
			AND lt.online_end_at <= t1.started_at
			AND t1.finished_at <= lt.finished_at
		--プロセス中のフラグ作成
		LEFT JOIN #lotend_table_s AS lt2 ON lt2.machine_id = t1.machine_id
			--AND lt2.started_at <= t1.finished_at
			--AND t1.finished_at < lt2.finished_at
			AND lt2.started_at <= t1.started_at
			AND t1.finished_at <= lt2.finished_at
		) AS t2

	--WHERE t2.run_state <> 255 --後でまとめて集計するからここで255は削除(machine_main専用)
	-----------------------------------------------------------------------------------------------------
	--------------------------------------machine_monitor
	SELECT DENSE_RANK() OVER (
			ORDER BY x.value
			) AS machine_number
		,x.value AS machine_id
		,m.name AS machine_name
		,t6.process_flag
		,t6.run_state
		,t6.total_all_diff_h
		,DATEDIFF(SECOND, @local_date_from, @local_date_to) AS from_to_s
		,convert(INT, t6.total_all_diff_h * 60 * 60) AS span
		,t6.class_all_diff_h
		,convert(INT, t6.class_all_diff_h * 60 * 60) AS std_all_diff_s
		,t6.percent_effic_class
		,t6.new_percent_effic_class_others AS percent_others_effic_class
		,t6.percent_effic_total
		,t6.new_percent_effic_total_others AS percent_others_effic_total
		,t6.effic_total_rank
	FROM (
		SELECT CONVERT(INT, value) AS value
		FROM STRING_SPLIT(@local_machine_id_list, ',')
		) AS x
	INNER JOIN APCSProDB.mc.machines AS m WITH (NOLOCK) ON m.id = x.value
	LEFT JOIN (
		SELECT t5.*
			,max(CASE 
					WHEN t5.run_state = 255
						THEN t5.percent_effic_class
					ELSE 0
					END) OVER (PARTITION BY t5.machine_id) + t5.percent_effic_class_others AS new_percent_effic_class_others
			,max(CASE 
					WHEN t5.run_state = 255
						THEN t5.percent_effic_total
					ELSE 0
					END) OVER (PARTITION BY t5.machine_id) + t5.percent_effic_total_others AS new_percent_effic_total_others
		FROM (
			SELECT t4.*
				,CASE 
					WHEN t4.process_flag = 1
						THEN t4.class_diff_h / t4.sum_process_time * 100
					ELSE NULL
					END AS percent_effic_class
				,t4.total_diff_h / t4.from_to * 100 AS percent_effic_total
				--others of percent
				,t4.class_unknown / t4.sum_process_time * 100 AS percent_effic_class_others
				,t4.total_unknown / t4.from_to * 100 AS percent_effic_total_others
			FROM (
				SELECT t3.machine_id
					,t3.process_flag
					,t3.run_state
					,t3.from_to
					,t3.sum_process_time
					,t3.total_diff_h
					,t3.class_diff_h
					,t3.total_all_diff_h
					,t3.class_all_diff_h
					,t3.from_to - t3.total_all_diff_h AS total_unknown
					,CASE 
						WHEN t3.process_flag = 1
							THEN t3.sum_process_time - t3.class_all_diff_h
						ELSE NULL
						END AS class_unknown
					,t3.effic_total_rank
				FROM (
					SELECT t2.machine_id
						,t2.process_flag
						,t2.run_state
						,convert(DECIMAL(9, 1), DATEDIFF(SECOND, @local_date_from, @local_date_to)) / 3600 AS from_to
						,pt.sum_process_time
						,sum(t2.new_sum_diff_h) OVER (
							PARTITION BY t2.machine_id
							,t2.run_state
							) AS total_diff_h
						,t2.new_sum_diff_h AS class_diff_h
						,sum(t2.new_sum_diff_h) OVER (PARTITION BY t2.machine_id) AS total_all_diff_h
						,sum(t2.new_sum_diff_h) OVER (
							PARTITION BY t2.machine_id
							,t2.process_flag
							) AS class_all_diff_h
						,ROW_NUMBER() OVER (
							PARTITION BY t2.machine_id
							,t2.run_state ORDER BY t2.run_state
							) AS effic_total_rank
					FROM (
						SELECT t1.machine_id
							,t1.process_flag
							,t1.run_state
							--,sum(t1.diff_h) AS sum_diff_h
							--from,to期間内でのdiff_hで再計算
							,sum(convert(DECIMAL(9, 1), DATEDIFF(SECOND, t1.started_at, t1.finished_at)) / 60 / 60) AS new_sum_diff_h
						FROM (
							--バッチ処理対策にDISTINCT
							SELECT DISTINCT machine_id
								,started_at AS aa
								,CASE 
									WHEN started_at <= @local_date_from
										THEN @local_date_from
									ELSE started_at
									END AS started_at
								,CASE 
									WHEN finished_at <= @local_date_to
										THEN finished_at
									ELSE @local_date_to
									END AS finished_at
								--,diff_h
								--,org_run_state
								--,record_type
								,run_state
								,process_flag
							--,lot_id
							--,process_job_id
							--,process_time
							FROM (
								SELECT *
								FROM #summary_table_s
								WHERE @local_date_from <= finished_at
									AND started_at <= @local_date_to
								) AS t0
							) AS t1
						GROUP BY t1.machine_id
							,t1.process_flag
							,t1.run_state
						) AS t2
					LEFT JOIN (
						SELECT machine_id
							,SUM(std_process_time) AS sum_process_time
						FROM #lotend_table_s
						GROUP BY machine_id
						) AS pt ON pt.machine_id = t2.machine_id
					) AS t3
				) AS t4
			) AS t5
		) AS t6 ON t6.machine_id = x.value
	ORDER BY machine_number
END
