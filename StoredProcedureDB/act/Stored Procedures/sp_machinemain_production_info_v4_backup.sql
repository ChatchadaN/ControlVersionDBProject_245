
CREATE PROCEDURE [act].[sp_machinemain_production_info_v4_backup] (
	@date_from DATETIME
	,@date_to DATETIME
	,@machine_id_list NVARCHAR(max) = NULL
	,@time_offset INT = 0
	)
AS
BEGIN
	--DECLARE @machine_id INT = 242
	--DECLARE @date_from DATETIME = '2021-02-03 00:00:00'
	--DECLARE @date_to DATETIME = '2021-03-05 00:00:00'
	--DECLARE @time_offset INT = 0
	------
	DECLARE @cur_date DATETIME = getdate()
	DECLARE @local_date_from DATETIME = DATEADD(HOUR, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = CASE 
			WHEN @cur_date < DATEADD(HOUR, @time_offset, @date_to)
				THEN format(dateadd(day, 1, @cur_date), 'yyyy-MM-dd 00:00:00')
			ELSE DATEADD(HOUR, @time_offset, @date_to)
			END
	DECLARE @local_machine_id_list NVARCHAR(max) = @machine_id_list
	DECLARE @from_to DECIMAL(9, 1) = isnull(convert(DECIMAL(9, 1), datediff(SECOND, @local_date_from, @local_date_to)) / 60 / 60, NULL);
	DECLARE @fr_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
			WHERE date_value = convert(DATE, @date_from)
			)

	--
	IF OBJECT_ID(N'tempdb..#date_table', N'U') IS NOT NULL
		DROP TABLE #date_table;

	IF OBJECT_ID(N'tempdb..#onlineend_rec', N'U') IS NOT NULL
		DROP TABLE #onlineend_rec;

	IF OBJECT_ID(N'tempdb..#lotend_table', N'U') IS NOT NULL
		DROP TABLE #lotend_table;

	IF OBJECT_ID(N'tempdb..#state_table', N'U') IS NOT NULL
		DROP TABLE #state_table;

	IF OBJECT_ID(N'tempdb..#alarm_table', N'U') IS NOT NULL
		DROP TABLE #alarm_table;

	IF OBJECT_ID(N'tempdb..#summary_table', N'U') IS NOT NULL
		DROP TABLE #summary_table;

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
	INTO #date_table
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
		INNER JOIN (
			SELECT CONVERT(INT, value) AS value
			FROM STRING_SPLIT(@local_machine_id_list, ',')
			) AS v ON v.value = pj.machine_id
		WHERE (
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

	SELECT *
	INTO #onlineend_rec
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
			FROM APCSProDB.trans.lot_process_records AS r
			INNER JOIN (
				SELECT CONVERT(INT, value) AS value
				FROM STRING_SPLIT(@local_machine_id_list, ',')
				) AS v ON v.value = r.machine_id
			WHERE r.record_class = 12
			) AS lpr
		INNER JOIN #date_table AS d ON d.machine_id = lpr.machine_id
			AND d.min_started_at <= lpr.recorded_at
			AND d.max_finished_at >= lpr.recorded_at
		) AS lpr2
	WHERE last_rec = 1

	SELECT u2.*
		,convert(DECIMAL(9, 1), DATEDIFF(SECOND, u2.std_started_at, u2.std_finished_at)) / 60 / 60 AS std_process_time
	INTO #lotend_table
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
									INNER JOIN (
										SELECT CONVERT(INT, value) AS value
										FROM STRING_SPLIT(@local_machine_id_list, ',')
										) AS v ON v.value = pj.machine_id
									INNER JOIN APCSProDWH.dwh.view_fact_pj_lots AS pl WITH (NOLOCK) ON pl.pj_id = pj.id
									WHERE (
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
		LEFT JOIN #onlineend_rec AS oe ON oe.lot_id = u1.lot_id
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
	INTO #alarm_table
	FROM (
		SELECT mar.*
		FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
		INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
			AND ma.alarm_level = 0
		INNER JOIN #date_table AS dt ON dt.machine_id = mar.machine_id
			AND (
				mar.updated_at BETWEEN dt.min_started_at
					AND dt.max_finished_at
				)
			AND (
				mar.alarm_on_at BETWEEN dt.min_started_at
					AND dt.max_finished_at
				)
			--WHERE mar.machine_id = @machine_id
			--	AND mar.updated_at BETWEEN @local_date_from
			--		AND @local_date_to
			--			--updated_atだけ更新されているdata対策
			--	AND mar.alarm_on_at BETWEEN @local_date_from
			--		AND @local_date_to
		) AS al
	LEFT JOIN #lotend_table AS le ON le.machine_id = al.machine_id
		AND (le.online_end_at <= al.alarm_on_at)
		AND (al.alarm_on_at < le.finished_at)
	WHERE le.machine_id IS NULL

	SELECT st2.machine_id
		,st2.updated_at AS started_at
		,NULL AS finished_at
		,st2.online_state AS online_state
		,st2.run_state AS run_state
		,st2.record_type AS record_type
	INTO #state_table
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
			INNER JOIN #date_table AS dt ON dt.machine_id = msr.machine_id
				AND msr.updated_at BETWEEN dt.min_started_at
					AND dt.max_finished_at
			) AS st1
		LEFT JOIN #alarm_table AS alm ON alm.machine_id = st1.machine_id
			AND (alm.alarm_on_at <= st1.updated_at)
			--AND (st1.updated_at < alm.alarm_off_at)
			--小数点以下切り捨て処理
			AND (st1.updated_at < CONVERT(DATETIME, CONVERT(VARCHAR(24), alm.alarm_off_at, 20)))
		WHERE alm.machine_id IS NULL
		) AS st2
	LEFT JOIN #lotend_table AS le ON le.machine_id = st2.machine_id
		AND (le.online_end_at <= st2.updated_at)
		AND (st2.updated_at < le.finished_at)
	WHERE le.machine_id IS NULL

	---------------------------------------------------------------------
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
	INTO #summary_table
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
				,rec1.started_at
				--,rec.finished_at
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
					FROM #alarm_table AS al
					
					UNION ALL
					
					--②Machine State
					SELECT st.machine_id
						,st.started_at AS started_at
						,NULL AS finished_at
						,st.online_state AS online_state
						,st.run_state AS run_state
						,st.record_type AS record_type
					FROM #state_table AS st
					
					UNION ALL
					
					--③Lot start
					SELECT lts.machine_id
						,lts.started_at
						,NULL AS finished_at
						,NULL AS online_state
						,1 AS run_state
						,'p' AS record_type
					FROM #lotend_table AS lts
					
					UNION ALL
					
					--④OnlineEnd ~ LotEnd
					SELECT le.machine_id
						,le.online_end_at AS started_at
						,le.finished_at AS finished_at
						,NULL AS online_state
						,199 AS run_state
						,'p' AS record_type
					FROM #lotend_table AS le
					) AS rec
				) AS rec1
			) AS t1
		--最終的にロットエンドステータスを上書きする
		LEFT JOIN #lotend_table AS lt ON lt.machine_id = t1.machine_id
			--AND lt.online_end_at <= t1.started_at
			--AND t1.started_at < lt.finished_at
			AND lt.online_end_at <= t1.started_at
			AND t1.finished_at < lt.finished_at
		--プロセス中のフラグ作成
		LEFT JOIN #lotend_table AS lt2 ON lt2.machine_id = t1.machine_id
			--AND lt2.started_at <= t1.finished_at
			--AND t1.finished_at < lt2.finished_at
			AND lt2.started_at <= t1.started_at
			AND t1.finished_at <= lt2.finished_at
		) AS t2
	WHERE t2.run_state <> 255 --後でまとめて集計するからここで255は削除
		--**************************
		--** MachineMain用
		--**************************

	SELECT ROW_NUMBER() OVER (
			PARTITION BY t1.machine_id
			,t1.lot_id
			,t1.process_job_id ORDER BY t1.run_state
			) AS lot_rank
		,t1.cancel_flag
		,t1.process_job_id
		,t1.machine_id
		,t1.lot_id
		,t1.lot_no
		,t1.started_at
		,t1.finished_at
		,mus.english_name AS started_by_name
		,muf.english_name AS finished_by_name
		,t1.qty_in
		,t1.qty_pass
		,t1.qty_fail
		,t1.process_time
		,t1.qty_pass / nullif(t1.process_time, 0) AS uph_act
		,convert(DECIMAL(9, 1), t1.qty_pass) / nullif((t1.qty_in), 0) * 100 AS yield
		,t1.run_state AS code
		,t1.sum_each_state_diff AS sum_diff_h
		,t1.sum_each_state_diff * 100 / nullif(t1.process_time, 0) AS percent_sum_diff_h
		,t1.other_state AS other_diff_h
		,t1.other_state * 100 / nullif(t1.process_time, 0) AS percent_other_diff_h
		,t1.process_id
		,p.name AS process_name
		,t1.job_id
		,j.name AS job_name
		,t1.is_special_flow
		,CASE 
			WHEN t1.is_special_flow = 0
				THEN t1.lot_no
			ELSE t1.lot_no + '(special_flow)'
			END AS lot_no_ex
	FROM (
		SELECT lt.*
			,s3.run_state
			,s3.sum_each_state_diff
			,s3.other_state
		FROM #lotend_table AS lt
		LEFT JOIN (
			SELECT s2.*
				,process_time - sum(sum_each_state_diff) OVER (
					PARTITION BY machine_id
					,lot_id
					,process_job_id
					) AS other_state
			FROM (
				SELECT machine_id
					,run_state
					,lot_id
					,process_job_id
					,process_time
					,sum(diff_h) AS sum_each_state_diff
				FROM #summary_table AS s1
				GROUP BY machine_id
					,lot_id
					,process_job_id
					,process_time
					,run_state
				) AS s2
			) AS s3 ON s3.machine_id = lt.machine_id
			AND s3.process_job_id = lt.process_job_id
			AND s3.lot_id = lt.lot_id
		) AS t1
	LEFT OUTER JOIN APCSProDB.man.users AS mus WITH (NOLOCK) ON mus.id = t1.started_by
	LEFT OUTER JOIN APCSProDB.man.users AS muf WITH (NOLOCK) ON muf.id = t1.finished_by
	LEFT OUTER JOIN APCSProDB.method.processes AS p WITH (NOLOCK) ON p.id = t1.process_id
	LEFT OUTER JOIN APCSProDB.method.jobs AS j WITH (NOLOCK) ON j.id = t1.job_id
	ORDER BY machine_id
		,started_at
		,lot_id
		,process_job_id
		,run_state
END
