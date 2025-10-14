
CREATE PROCEDURE [act].[sp_machineefficiency_transition_v3_backup] (
	@date_from DATETIME
	,@date_to DATETIME
	,@machine_id_list NVARCHAR(max) = NULL
	,
	--version2
	@time_offset INT = 0
	,@in_process INT = 0
	)
AS
BEGIN
	--DECLARE @machine_id_list NVARCHAR(max) = '19'
	--DECLARE @date_from DATETIME = '2020-06-01'
	--DECLARE @date_to DATETIME = '2020-06-30'
	--DECLARE @time_offset INT = 0
	------DECLARE @time_offset INT = 8
	----@in_process=1:ロット処理中のみ
	--DECLARE @in_process INT = 0
	------------------------------------------------------------------------------------------------
	DECLARE @cur_date DATETIME = getdate()
	DECLARE @local_machine_id_list NVARCHAR(max) = @machine_id_list
	DECLARE @local_date_from DATETIME = DATEADD(HOUR, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = CASE 
			WHEN @cur_date < DATEADD(HOUR, @time_offset, @date_to)
				THEN format(dateadd(day, 1, @cur_date), 'yyyy-MM-dd 00:00:00')
			ELSE DATEADD(HOUR, @time_offset, @date_to)
			END
	DECLARE @from_to DECIMAL(9, 1) = isnull(convert(DECIMAL(9, 1), datediff(SECOND, @local_date_from, @local_date_to)) / 60 / 60, NULL);
	DECLARE @fr_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK)
			WHERE date_value = convert(DATE, @date_from)
			)
	DECLARE @to_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = convert(DATE, @date_to)
			);
	DECLARE @machines INT = (
			SELECT count(value)
			FROM STRING_SPLIT(@machine_id_list, ',')
			);

	--
	IF OBJECT_ID(N'tempdb..#date_table', N'U') IS NOT NULL
		DROP TABLE #date_table;

	IF OBJECT_ID(N'tempdb..#onlineend_rec', N'U') IS NOT NULL
		DROP TABLE #onlineend_rec;

	IF OBJECT_ID(N'tempdb..#lotend_table', N'U') IS NOT NULL
		DROP TABLE #lotend_table;

	IF OBJECT_ID(N'tempdb..#processtime_table', N'U') IS NOT NULL
		DROP TABLE #processtime_table;

	IF OBJECT_ID(N'tempdb..#state_table', N'U') IS NOT NULL
		DROP TABLE #state_table;

	IF OBJECT_ID(N'tempdb..#alarm_table', N'U') IS NOT NULL
		DROP TABLE #alarm_table;

	IF OBJECT_ID(N'tempdb..#summary_table', N'U') IS NOT NULL
		DROP TABLE #summary_table;

	IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
		DROP TABLE #table;

	IF OBJECT_ID(N'tempdb..#date_not_changed', N'U') IS NOT NULL
		DROP TABLE #date_not_changed;

	IF OBJECT_ID(N'tempdb..#date_changed', N'U') IS NOT NULL
		DROP TABLE #date_changed;

	IF OBJECT_ID(N'tempdb..#effic', N'U') IS NOT NULL
		DROP TABLE #effic;

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

	SELECT u4.*
		,count(u4.id) OVER (
			PARTITION BY u4.y
			,u4.week_no
			) AS days_of_week
		,count(u4.id) OVER (
			PARTITION BY u4.y
			,u4.m
			) AS days_of_month
	INTO #processtime_table
	FROM (
		SELECT u3.id
			,u3.y
			,u3.m
			,u3.week_no
			--,u3.df
			--,u3.dt
			,sum(u3.process_h) OVER (PARTITION BY u3.id) AS process_h_per_day
			,sum(u3.process_h) OVER (
				PARTITION BY u3.y
				,u3.week_no
				) AS process_h_per_week
			,sum(u3.process_h) OVER (
				PARTITION BY u3.y
				,u3.m
				) AS process_h_per_month
			,ROW_NUMBER() OVER (
				PARTITION BY u3.id ORDER BY u3.id
				) AS day_rk
		FROM (
			SELECT u2.id
				,u2.y
				,u2.m
				,u2.week_no
				,u2.df
				,u2.dt
				,u2.machine_id
				,u2.lot_id
				,u2.lot_no
				,u2.process_job_id
				,u2.new_started_at
				,u2.new_finished_at
				,convert(DECIMAL(9, 1), DATEDIFF(SECOND, u2.new_started_at, u2.new_finished_at)) / 60 / 60 AS process_h
			FROM (
				SELECT u1.*
					,CASE 
						WHEN u1.df <= u1.started_at
							THEN u1.started_at
						ELSE u1.df
						END AS new_started_at
					,CASE 
						WHEN u1.dt <= u1.finished_at
							THEN u1.dt
						ELSE u1.finished_at
						END AS new_finished_at
				FROM (
					SELECT t1.*
						,t2.machine_id
						,t2.lot_id
						,t2.lot_no
						,t2.process_job_id
						,t2.started_at
						,t2.finished_at
					FROM (
						SELECT dd.id
							,dd.y
							,dd.m
							,dd.week_no
							,DATEADD(HOUR, @time_offset, convert(DATETIME, dd.date_value)) AS df
							,DATEADD(HOUR, @time_offset + 24, convert(DATETIME, dd.date_value)) AS dt
						FROM APCSProDWH.dwh.dim_days AS dd
						WHERE date_value BETWEEN @date_from
								AND @date_to
						) AS t1
					LEFT JOIN (
						SELECT *
						FROM (
							SELECT lt.machine_id
								,lt.lot_id
								,lt.lot_no
								,lt.process_job_id
								,lt.std_started_at
								,lt.std_finished_at
								,lt.started_at
								,lt.online_end_at
								,lt.finished_at
								,ROW_NUMBER() OVER (
									PARTITION BY lt.process_job_id ORDER BY lt.lot_id
									) AS pj_rank
							FROM #lotend_table AS lt
							) AS lt2
						WHERE lt2.pj_rank = 1
						) AS t2 ON t1.df <= t2.std_finished_at
						AND t2.std_started_at <= t1.dt
					) AS u1
				) AS u2
			) AS u3
		) AS u4
	WHERE u4.day_rk = 1

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
			AND (st1.updated_at < alm.alarm_off_at)
		WHERE alm.machine_id IS NULL
		) AS st2
	LEFT JOIN #lotend_table AS le ON le.machine_id = st2.machine_id
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
			AND lt.online_end_at <= t1.started_at
			AND t1.finished_at <= lt.finished_at
		--プロセス中のフラグ作成
		LEFT JOIN #lotend_table AS lt2 ON lt2.machine_id = t1.machine_id
			AND lt2.started_at <= t1.started_at
			AND t1.finished_at <= lt2.finished_at
		) AS t2

	--**************************
	--** MachineEfficiency Main Query用
	--**************************
	SELECT *
		,DATEDIFF(day, t2.max_started_at, t2.ended_at) AS f
	INTO #table
	FROM (
		SELECT dd.id AS day_id
			,dh.code AS hour_code
			,t1.machine_id AS machine_id
			,t1.run_state AS code
			,t1.new_started_at AS started_at
			,t1.new_ended_at AS ended_at
			,max(t1.new_started_at) OVER (PARTITION BY dd.id) AS max_started_at
		FROM (
			SELECT *
				--シフト時間のoffset 
				,convert(DATE, dateadd(hour, - @time_offset, st.started_at)) AS new_date
				,datepart(HOUR, dateadd(hour, - @time_offset, st.started_at)) AS new_hour
				,dateadd(hour, - @time_offset, st.started_at) AS new_started_at
				,dateadd(hour, - @time_offset, st.finished_at) AS new_ended_at
			FROM #summary_table AS st
			WHERE (
					@in_process = 1
					AND st.process_flag = 1
					)
				OR (@in_process = 0)
			) AS t1
		INNER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.date_value = t1.new_date
		INNER JOIN APCSProDWH.dwh.dim_hours AS dh WITH (NOLOCK) ON dh.h = t1.new_hour
		) AS t2
	ORDER BY machine_id
		,started_at

	SELECT *
	INTO #date_not_changed
	FROM #table
	WHERE f = 0;

	--日付またぎレコードのみ抽出
	SELECT *
	INTO #date_changed
	FROM #table
	WHERE f > 0;

	DECLARE @cur CURSOR;DECLARE @error_flg INT = 0
		--
		DECLARE @day_id INT DECLARE @hour_code INT DECLARE @machine_id INT DECLARE @code INT DECLARE @started_at DATETIME DECLARE @ended_at DATETIME DECLARE @max_started_at DATETIME DECLARE @f INT
		--
		SET @cur = CURSOR
	FOR
	SELECT *
	FROM #date_changed

	OPEN @cur

	FETCH NEXT
	FROM @cur
	INTO @day_id
		,@hour_code
		,@machine_id
		,@code
		,@started_at
		,@ended_at
		,@max_started_at
		,@f;

	WHILE (@@FETCH_STATUS = 0)
	BEGIN
		--エラー処理
		SET @error_flg = @@ERROR

		IF @error_flg <> 0 --エラーが発生したら
		BEGIN
			CLOSE @cur

			--カーソルクローズ
			DEALLOCATE @cur

			--リソース開放
			RETURN
		END

		--
		DECLARE @temp_day_id INT
		DECLARE @temp_hour_code INT
		DECLARE @temp_machine_id INT
		DECLARE @temp_code INT
		DECLARE @temp_started_at DATETIME
		DECLARE @temp_ended_at DATETIME
		DECLARE @temp_max_started_at DATETIME
		DECLARE @temp_f INT = @f

		--@temp_f : またぎ日数
		WHILE (@temp_f > 0)
		BEGIN
			SET @temp_f = @temp_f - 1;
			SET @temp_day_id = @day_id;
			SET @temp_hour_code = @hour_code;
			SET @temp_machine_id = @machine_id;
			SET @temp_code = @code;
			SET @temp_started_at = @started_at;
			SET @temp_ended_at = FORMAT(dateadd(day, 1, @started_at), 'yyyy-MM-dd 00:00:00.000');
			SET @temp_max_started_at = @max_started_at;

			--日付またぎ前半部(次の日の00:00:00まで)
			INSERT INTO #date_not_changed (
				day_id
				,hour_code
				,machine_id
				,code
				,started_at
				,ended_at
				,max_started_at
				,f
				)
			VALUES (
				@temp_day_id
				,@temp_hour_code
				,@temp_machine_id
				,@temp_code
				,@temp_started_at
				,@temp_ended_at
				,@temp_max_started_at
				,0
				);

			--日付またぎ後半部(00:00:00~)
			SET @temp_day_id = @day_id + 1;
			SET @temp_hour_code = 1;
			SET @temp_machine_id = @machine_id;
			SET @temp_code = @code;
			SET @temp_started_at = FORMAT(dateadd(day, 1, @started_at), 'yyyy-MM-dd 00:00:00.000');
			SET @temp_ended_at = @ended_at;
			SET @temp_max_started_at = @max_started_at;

			IF @temp_f = 0
			BEGIN
				INSERT INTO #date_not_changed (
					day_id
					,hour_code
					,machine_id
					,code
					,started_at
					,ended_at
					,max_started_at
					,f
					)
				VALUES (
					@temp_day_id
					,@temp_hour_code
					,@temp_machine_id
					,@temp_code
					,@temp_started_at
					,@temp_ended_at
					,@temp_max_started_at
					,@temp_f
					);
			END

			--
			SET @day_id = @temp_day_id;
			SET @hour_code = @temp_hour_code;
			SET @machine_id = @temp_machine_id;
			SET @code = @temp_code;
			SET @started_at = @temp_started_at;
			SET @ended_at = @temp_ended_at;
			SET @max_started_at = @temp_max_started_at;
		END

		--次のレコードの取り出し
		FETCH NEXT
		FROM @cur
		INTO @day_id
			,@hour_code
			,@machine_id
			,@code
			,@started_at
			,@ended_at
			,@max_started_at
			,@f;
	END

	CLOSE @cur

	DEALLOCATE @cur

	SELECT day_id
		,hour_code
		,machine_id
		,code
		,started_at
		,ended_at
	INTO #effic
	FROM #date_not_changed
	WHERE day_id BETWEEN @fr_date
			AND @to_date
	ORDER BY day_id
		,hour_code
		,started_at;

	SELECT t6.*
	FROM (
		SELECT t5.day_id
			,t5.date_value
			,t5.y
			,t5.m
			,t5.week_no
			,DATEADD(DAY, 1 - DATEPART(WEEKDAY, t5.date_value), CAST(t5.date_value AS DATE)) AS week_start_day
			,t5.code
			-- --day
			,ROW_NUMBER() OVER (
				PARTITION BY t5.day_id ORDER BY t5.day_id
					,t5.code
				) AS day_id_rank
			,t5.day_duration_h / nullif(t5.day_std_time, 0) * 100 AS day_duration_percent
			,t5.new_day_duration_h_others / nullif(t5.day_std_time, 0) * 100 AS day_duration_percent_others
			-- --week
			,row_number() OVER (
				PARTITION BY t5.y
				,t5.week_no
				,t5.code ORDER BY t5.y
					,t5.week_no
				) AS week_rank
			,t5.week_duration_h / nullif(t5.week_std_time, 0) * 100 AS week_duration_percent
			,t5.new_week_duration_h_others / nullif(t5.week_std_time, 0) * 100 AS week_duration_percent_others
			-- --month
			,row_number() OVER (
				PARTITION BY t5.y
				,t5.m
				,t5.code ORDER BY t5.y
					,t5.m
					,t5.week_no
				) AS month_rank
			,t5.month_duration_h / nullif(t5.month_std_time, 0) * 100 AS month_duration_percent
			,t5.new_month_duration_h_others / nullif(t5.month_std_time, 0) * 100 AS month_duration_percent_others
		FROM (
			SELECT t4.*
				,max(CASE 
						WHEN t4.code = 255
							THEN t4.day_duration_h
						ELSE 0
						END) OVER (PARTITION BY t4.day_id) + t4.day_duration_h_others AS new_day_duration_h_others
				,max(CASE 
						WHEN t4.code = 255
							THEN t4.week_duration_h
						ELSE 0
						END) OVER (
					PARTITION BY t4.y
					,t4.week_no
					) + t4.week_duration_h_others AS new_week_duration_h_others
				,max(CASE 
						WHEN t4.code = 255
							THEN t4.month_duration_h
						ELSE 0
						END) OVER (
					PARTITION BY t4.y
					,t4.m
					) + t4.month_duration_h_others AS new_month_duration_h_others
			FROM (
				SELECT t3.*
					--codeが明確にわかっていない時間分
					,t3.day_std_time - sum(t3.day_duration_h) OVER (PARTITION BY t3.day_id) AS day_duration_h_others
					,t3.week_std_time - sum(t3.day_duration_h) OVER (
						PARTITION BY t3.y
						,t3.week_no
						) AS week_duration_h_others
					,t3.month_std_time - sum(t3.day_duration_h) OVER (
						PARTITION BY t3.y
						,t3.m
						) AS month_duration_h_others
				FROM (
					SELECT t2.*
						,sum(t2.day_duration_h) OVER (
							PARTITION BY t2.y
							,t2.week_no
							,t2.code
							) AS week_duration_h
						,sum(t2.day_duration_h) OVER (
							PARTITION BY t2.y
							,t2.m
							,t2.code
							) AS month_duration_h
						,CASE 
							WHEN @in_process = 0
								THEN 24 * @machines
							ELSE pt.process_h_per_day
							END day_std_time
						,CASE 
							WHEN @in_process = 0
								THEN 24 * pt.days_of_week * @machines
							ELSE pt.process_h_per_week
							END week_std_time
						,CASE 
							WHEN @in_process = 0
								THEN 24 * pt.days_of_month * @machines
							ELSE pt.process_h_per_month
							END month_std_time
					FROM (
						SELECT t1.day_id AS day_id
							,t1.y AS y
							,t1.m AS m
							,t1.d AS d
							,t1.week_no AS week_no
							,t1.date_value AS date_value
							,t1.code AS code
							,sum(t1.duration_h) AS day_duration_h
						FROM (
							SELECT d.day_id AS day_id
								,d.hour_code AS hour_code
								,d.y AS y
								,d.m AS m
								,d.week_no AS week_no
								,d.d AS d
								,d.date_value AS date_value
								,d.h AS h
								,ef.machine_id AS machine_id
								,ef.code AS code
								,ef.started_at AS started_at
								,ef.ended_at AS ended_at
								,convert(DECIMAL(9, 1), isnull(datediff(second, ef.started_at, ef.ended_at), 0)) / 60 / 60 AS duration_h
							FROM (
								SELECT ddy.id AS day_id
									,dh.code AS hour_code
									,ddy.date_value AS date_value
									,ddy.y AS y
									,ddy.m AS m
									,ddy.quarter_no AS quarter_no
									,ddy.week_no AS week_no
									,ddy.d
									,dh.h AS h
								FROM apcsprodwh.dwh.dim_days AS ddy
								CROSS JOIN apcsprodwh.dwh.dim_hours AS dh
								) AS d
							LEFT OUTER JOIN #effic AS ef ON ef.day_id = d.day_id
								AND ef.hour_code = d.hour_code
							WHERE d.day_id BETWEEN @fr_date
									AND @to_date
							) AS t1
						GROUP BY t1.day_id
							,t1.y
							,t1.m
							,t1.d
							,t1.week_no
							,t1.date_value
							,t1.code
						) AS t2
					LEFT JOIN #processtime_table AS pt ON pt.id = t2.day_id
					) AS t3
				) AS t4
			) AS t5
		) AS t6
	--WHERE week_rank = 1
	--where month_rank = 1
	ORDER BY day_id
		,code
END
