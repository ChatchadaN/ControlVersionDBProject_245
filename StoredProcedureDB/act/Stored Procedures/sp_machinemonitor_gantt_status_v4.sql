
CREATE PROCEDURE [act].[sp_machinemonitor_gantt_status_v4] (
	@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@machine_id_list NVARCHAR(max) = NULL
	)
AS
BEGIN
	--DECLARE @date_from DATETIME = '2020-06-15 00:00:00'
	--DECLARE @date_to DATETIME = '2020-06-17 00:00:00'
	--DECLARE @machine_id_list NVARCHAR(max) = '19'
	--DECLARE @time_offset INT = 8
	--!!IMPORTANT!! Replace parameter to local variables 
	DECLARE @local_date_from DATETIME = DATEADD(HOUR, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = DATEADD(HOUR, @time_offset, @date_to)
	DECLARE @local_machine_id_list NVARCHAR(max) = @machine_id_list
	DECLARE @cur_date DATETIME = getdate()

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

	IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
		DROP TABLE #table;

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
		--setup_atの検索範囲を@local_date_from-1とする。一日前からマージンを持って絞り込む
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
					pj.setup_at BETWEEN @local_date_from - 1
						AND @local_date_to
					AND pj.finished_at IS NULL
					)
				)
		) AS t
	GROUP BY machine_id

	----v4
	DECLARE @min_day_id INT = (
			SELECT id - 3
			FROM APCSProDB.trans.days AS td WITH (NOLOCK)
			WHERE td.date_value = (
					SELECT CONVERT(VARCHAR, min(min_started_at), 23)
					FROM #date_table
					)
			)
	DECLARE @max_day_id INT = (
			SELECT id + 3
			FROM APCSProDB.trans.days AS td WITH (NOLOCK)
			WHERE td.date_value = (
					SELECT CONVERT(VARCHAR, Max(max_finished_at), 23)
					FROM #date_table
					)
			)

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
			FROM APCSProDB.trans.lot_process_records AS r WITH (NOLOCK)
			INNER JOIN (
				SELECT CONVERT(INT, value) AS value
				FROM STRING_SPLIT(@local_machine_id_list, ',')
				) AS v ON v.value = r.machine_id
			WHERE r.day_id BETWEEN @min_day_id
					AND @max_day_id
				AND r.record_class = 12
			) AS lpr
		INNER JOIN #date_table AS d ON d.machine_id = lpr.machine_id
			AND d.min_started_at <= lpr.recorded_at
			AND d.max_finished_at >= lpr.recorded_at
		) AS lpr2
	WHERE last_rec = 1

	SELECT sf.lot_id
		,sf.process_job_id
		,sf.machine_id
		,sf.started_at
		,CASE 
			WHEN oe.recorded_at IS NOT NULL
				THEN oe.recorded_at
			ELSE sf.finished_at
			END AS online_end_at
		,sf.finished_at
		,oe.online_state
		,oe.record_flag
		,oe.run_state
	INTO #lotend_table
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
		) AS sf
	LEFT JOIN #onlineend_rec AS oe ON oe.lot_id = sf.lot_id
		AND oe.machine_id = sf.machine_id
		AND oe.process_job_id = sf.process_job_id

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
		WHERE mar.machine_id IN (
				SELECT value
				FROM STRING_SPLIT(@local_machine_id_list, ',')
				)
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
			WHERE msr.machine_id IN (
					SELECT value
					FROM STRING_SPLIT(@local_machine_id_list, ',')
					)
			) AS st1
		LEFT JOIN #alarm_table AS alm ON alm.machine_id = st1.machine_id
			AND (alm.alarm_on_at <= st1.updated_at)
			--AND (st1.updated_at < alm.alarm_off_at)
			--小数点以下切り捨て処理(2021.12.09)
			AND (st1.updated_at < CONVERT(DATETIME, CONVERT(VARCHAR(24), alm.alarm_off_at, 20)))
		WHERE alm.machine_id IS NULL
		) AS st2
	LEFT JOIN #lotend_table AS le ON le.machine_id = st2.machine_id
		AND (le.online_end_at <= st2.updated_at)
		AND (st2.updated_at < le.finished_at)
	WHERE le.machine_id IS NULL

	SELECT rec1.machine_id
		--,rec1.started_at
		--,rec1.finished_at
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
		,CASE 
			WHEN @local_date_from BETWEEN rec1.started_at
					AND rec1.finished_at
				THEN 1
			ELSE 0
			END AS flag
	INTO #table
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
				--,1 AS run_state
				--Lot startは、run_state:executeとする。
				,4 AS run_state
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

	---------------------------------------------------------------------------
	SELECT dense_rank() OVER (
			ORDER BY x.value
			) AS machine_number
		,x.value AS machine_id
		,mc.name AS machine_name
		,mc.machine_model_id AS machine_model_id
		,tt.date_value AS date_value
		,tt.std_from AS std_from
		,tt.std_to AS std_to
		,isnull(tt.loop_index, 0) AS loop_index
		,tt.online_state AS online_state
		,tt.code AS code
		,tt.code_name AS code_name
		,tt.started_at AS started_at
		,tt.finished_at AS finished_at
		,isnull(tt.start_point, - 1) AS start_point
		,isnull(tt.end_diff, 0) AS end_diff
		,tt.original_started_at AS original_started_at
		,tt.original_finished_at AS original_finished_at
	FROM (
		SELECT CONVERT(INT, value) AS value
		FROM STRING_SPLIT(@local_machine_id_list, ',')
		) AS x
	LEFT OUTER JOIN (
		SELECT s4.machine_id AS machine_id
			,s4.date_value AS date_value
			,s4.std_from AS std_from
			,s4.std_to AS std_to
			,DATEDIFF(HOUR, @local_date_from, s4.new_started_at) / 24 AS loop_index
			,s4.online_state AS online_state
			,s4.run_state AS code
			,de.name AS code_name
			,s4.new_started_at AS started_at
			,s4.new_finished_at AS finished_at
			,s4.new_start_point AS start_point
			,s4.new_end_diff AS end_diff
			,s4.original_started_at AS original_started_at
			,s4.original_finished_at AS original_finished_at
		FROM (
			SELECT s3.date_value AS date_value
				,s3.std_from AS std_from
				,s3.std_to AS std_to
				,s3.machine_id AS machine_id
				,s3.online_state AS online_state
				,s3.run_state AS run_state
				,s3.new_started_at AS new_started_at
				,s3.new_finished_at AS new_finished_at
				,isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.std_from, s3.new_started_at)) / 60 / 60, NULL) AS new_start_point
				,isnull(convert(DECIMAL(9, 1), datediff(SECOND, s3.new_started_at, s3.new_finished_at)) / 60 / 60, NULL) AS new_end_diff
				,s3.original_started_at AS original_started_at
				,s3.original_finished_at AS original_finished_at
			FROM (
				SELECT s2.date_value AS date_value
					,s2.std_from AS std_from
					,s2.std_to AS std_to
					,s2.machine_id AS machine_id
					,s2.online_state AS online_state
					,s2.run_state AS run_state
					,CASE 
						WHEN s2.started_at < s2.std_from
							THEN s2.std_from
						WHEN s2.std_from <= s2.started_at
							AND s2.started_at <= s2.std_to
							THEN s2.started_at
						ELSE s2.std_to
						END AS new_started_at
					,CASE 
						WHEN s2.finished_at < s2.std_from
							THEN s2.std_from
						WHEN s2.std_from <= s2.finished_at
							AND s2.finished_at <= s2.std_to
							THEN s2.finished_at
						ELSE s2.std_to
						END AS new_finished_at
					,s2.started_at AS original_started_at
					,s2.finished_at AS original_finished_at
				FROM (
					SELECT s1.*
						,tt.*
					FROM (
						SELECT ddy.date_value AS date_value
							,CASE 
								WHEN @time_offset != 0
									THEN dateadd(hour, @time_offset, convert(DATETIME, ddy.date_value))
								ELSE DATEADD(day, ddy.id - (
											SELECT id
											FROM APCSProDWH.dwh.dim_days AS d WITH (NOLOCK)
											WHERE d.date_value = CONVERT(DATE, @local_date_from)
											), @local_date_from)
								END AS std_from
							,CASE 
								WHEN @time_offset != 0
									THEN dateadd(hour, @time_offset, convert(DATETIME, dateadd(day, 1, ddy.date_value)))
								ELSE DATEADD(day, ddy.id + 1 - (
											SELECT id
											FROM APCSProDWH.dwh.dim_days AS d WITH (NOLOCK)
											WHERE d.date_value = CONVERT(DATE, @local_date_from)
											), @local_date_from)
								END AS std_to
						FROM apcsprodwh.dwh.dim_days AS ddy WITH (NOLOCK)
						WHERE convert(DATE, @local_date_from) <= date_value
							AND date_value < convert(DATE, @local_date_to)
						) AS s1
					LEFT OUTER JOIN #table AS tt ON s1.std_from <= tt.finished_at
						AND tt.started_at <= s1.std_to
						--AND tt.run_state <> 199 --gantt_statusには表示しない->表示するように変更。
					) AS s2
				) AS s3
			) AS s4
		LEFT OUTER JOIN act.fnc_dim_efficiencies() AS de ON de.run_state = s4.run_state
		WHERE @local_date_from <= s4.std_from
			AND s4.std_to <= @local_date_to
		) AS tt ON tt.machine_id = x.value
	INNER JOIN apcsprodb.[mc].[machines] AS mc WITH (NOLOCK) ON mc.id = x.value
	ORDER BY machine_number
		,started_at;
END
