
CREATE PROCEDURE [act].[sp_machineefficiency_transition_v2] (
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
	DECLARE @local_date_from DATETIME = DATEADD(HOUR, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = dateadd(day, 1, DATEADD(HOUR, @time_offset, @date_to))
	DECLARE @local_machine_id_list NVARCHAR(max) = @machine_id_list
	DECLARE @fr_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = convert(DATE, @date_from)
			);
	DECLARE @to_date INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = convert(DATE, @date_to)
			);
	DECLARE @machines INT = (
			SELECT count(value)
			FROM STRING_SPLIT(@machine_id_list, ',')
			);

	----machine_state_records とmachine_alarm_recordsとlot_process_recordsをUNION
	IF OBJECT_ID(N'tempdb..#x', N'U') IS NOT NULL
		DROP TABLE #x;

	IF OBJECT_ID(N'tempdb..#table', N'U') IS NOT NULL
		DROP TABLE #table;

	IF OBJECT_ID(N'tempdb..#date_not_changed', N'U') IS NOT NULL
		DROP TABLE #date_not_changed;

	IF OBJECT_ID(N'tempdb..#date_changed', N'U') IS NOT NULL
		DROP TABLE #date_changed;

	IF OBJECT_ID(N'tempdb..#effic', N'U') IS NOT NULL
		DROP TABLE #effic;

	SELECT x5.*
	INTO #x
	FROM (
		SELECT dd.id AS day_id
			,dh.code AS hour_code
			,x4.started_at AS started_at
			,x4.ended_at AS ended_at
			,x4.machine_id AS machine_id
			,x4.online_state
			,x4.record_flag AS record_flag
			,x4.run_state
			,x4.oor_flag AS oor_flag
			--calc in-process range
			,x4.lotend_flag AS lotend_flag
			,CASE 
				WHEN x4.lotend_flag = 0
					THEN lag(x4.lotend_flag, x4._offset) OVER (
							PARTITION BY x4.machine_id ORDER BY x4.started_at
							)
				ELSE x4.lotend_flag
				END AS new_lotend_flag
		FROM (
			SELECT
				--x3.started_at
				--	,x3.ended_at
				x3.new_date AS new_date
				,x3.new_hour AS new_hour
				--シフトoffset加味データ
				,x3.new_started_at AS started_at
				,x3.new_ended_at AS ended_at
				,x3.machine_id AS machine_id
				,x3.online_state
				,x3.record_flag AS record_flag
				,x3.run_state
				,x3.oor_flag AS oor_flag
				--calc in-process range
				,x3.lotend_flag AS lotend_flag
				,row_number() OVER (
					PARTITION BY x3.machine_id
					,x3.lotend_flag
					,x3._diff_num ORDER BY x3.started_at
					) AS _offset
			--INTO #x
			FROM (
				SELECT x2.started_at
					,x2.ended_at
					--シフト時間のoffset 
					,convert(DATE, dateadd(hour, - @time_offset, x2.started_at)) AS new_date
					,datepart(HOUR, dateadd(hour, - @time_offset, x2.started_at)) AS new_hour
					,dateadd(hour, - @time_offset, x2.started_at) AS new_started_at
					,dateadd(hour, - @time_offset, x2.ended_at) AS new_ended_at
					,x2.machine_id AS machine_id
					,x2.online_state
					,x2.record_flag AS record_flag
					,x2.run_state
					,x2.oor_flag AS oor_flag
					--calc in-process range
					,x2.lotend_flag AS lotend_flag
					,ROW_NUMBER() OVER (
						PARTITION BY x2.machine_id ORDER BY x2.started_at
						) - ROW_NUMBER() OVER (
						PARTITION BY x2.machine_id
						,x2.lotend_flag ORDER BY x2.started_at
						) AS _diff_num
				FROM (
					SELECT
						--x.day_id
						--,x.hour_code
						x1.updated_at AS started_at
						,lag(x1.updated_at) OVER (
							PARTITION BY x1.machine_id ORDER BY x1.updated_at DESC
							) AS ended_at
						,x1.machine_id AS machine_id
						,x1.online_state
						,x1.record_flag AS record_flag
						,x1.run_state
						,x1.oor_flag AS oor_flag
						--calc in-process range
						,CASE 
							WHEN x1.record_flag = 0 and　x1.run_state = 2
								THEN 2
							WHEN x1.record_flag = 0
								AND x1.run_state = 1
								THEN 1
							ELSE 0
							END AS lotend_flag
					FROM (
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
							INNER JOIN (
								SELECT CONVERT(INT, value) AS value
								FROM STRING_SPLIT(@local_machine_id_list, ',')
								) AS v ON v.value = msr.machine_id
							WHERE
								--machine_id = @machine_id
								--	AND 
								updated_at < @local_date_from
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
						INNER JOIN (
							SELECT CONVERT(INT, value) AS value
							FROM STRING_SPLIT(@local_machine_id_list, ',')
							) AS v ON v.value = msr.machine_id
						WHERE updated_at >= @local_date_from
							AND updated_at <= @local_date_to
						
						UNION ALL
						
						--alarm record
						SELECT top1.alarm_on_at
							,top1.machine_id
							,NULL AS online_state
							,2 AS record_flag
							,- 1 AS run_state
							,1 AS oor_flag --out of range flag
						FROM (
							SELECT convert(DATE, mar.alarm_on_at) AS day_at
								,datepart(HOUR, mar.alarm_on_at) + 1 AS hour_code
								,mar.alarm_on_at
								,mar.machine_id
								,ROW_NUMBER() OVER (
									PARTITION BY mar.machine_id ORDER BY mar.alarm_on_at DESC
									) AS up_rank
							FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
							INNER JOIN (
								SELECT CONVERT(INT, value) AS value
								FROM STRING_SPLIT(@local_machine_id_list, ',')
								) AS v ON v.value = mar.machine_id
							WHERE updated_at < @local_date_from
							) AS top1
						WHERE top1.up_rank <= 1
						
						UNION ALL
						
						SELECT t.alarm_on_at
							,t.machine_id
							,t.online_state AS online_state
							,t.record_flag AS record_flag
							,t.run_state AS run_state
							,t.oor_flag AS oor_flag
						FROM (
							SELECT mar.alarm_on_at
								,mar.machine_id
								,NULL AS online_state
								,2 AS record_flag
								,- 1 AS run_state
								,0 AS oor_flag --out of range flag
							FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
							INNER JOIN (
								SELECT CONVERT(INT, value) AS value
								FROM STRING_SPLIT(@local_machine_id_list, ',')
								) AS v ON v.value = mar.machine_id
							WHERE alarm_on_at >= @local_date_from
								AND started_at <= @local_date_to
							) AS t
						
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
							INNER JOIN (
								SELECT CONVERT(INT, value) AS value
								FROM STRING_SPLIT(@local_machine_id_list, ',')
								) AS v ON v.value = lpr.machine_id
							WHERE
								--高速化の為一日前までのデータから絞り込む
								(lpr.day_id <= @fr_date
								AND lpr.day_id >= @fr_date - 1)
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
						INNER JOIN (
							SELECT CONVERT(INT, value) AS value
							FROM STRING_SPLIT(@local_machine_id_list, ',')
							) AS v ON v.value = lpr.machine_id
						WHERE lpr.record_class IN (
								1
								--,11
								,2
								,12
								)
							AND recorded_at >= @local_date_from
							AND recorded_at <= @local_date_to
						) AS x1
					) AS x2
				) AS x3
			) AS x4
		INNER JOIN APCSProDWH.dwh.dim_days AS dd WITH (NOLOCK) ON dd.date_value = x4.new_date
		INNER JOIN APCSProDWH.dwh.dim_hours AS dh WITH (NOLOCK) ON dh.h = x4.new_hour
		) AS x5
	WHERE (
			@in_process = 1
			AND x5.new_lotend_flag = 1
			)
		OR (@in_process <> 1)

	--ORDER BY updated_at ASC
	SELECT t3.*
	INTO #table
	FROM (
		SELECT t2.*
			,DATEDIFF(day, t2.max_started_at, t2.ended_at) AS f
		FROM (
			SELECT *
				,max(t1.started_at) OVER (PARTITION BY t1.day_id) AS max_started_at
			FROM (
				SELECT me.day_id
					,me.hour_code
					,me.machine_id AS machine_id
					--,me.online_state
					--,me.record_flag AS record_flag
					--,me.run_state AS code
					,me.new_run_state AS code
					,me.started_at AS started_at
					--,me.oor_flag AS oor_flag
					,me.ended_at AS ended_at
				FROM (
					SELECT ms.day_id
						,ms.hour_code
						,ms.machine_id AS machine_id
						--,ms.record_flag AS record_flag
						,ms.run_state AS run_state
						,CASE 
							WHEN ms.record_flag = 0
								AND ms.run_state = 1
								--execute
								THEN 4
							WHEN ms.record_flag = 0
								AND ms.run_state = 2
								--idle
								THEN 1
							WHEN ms.record_flag = 0
								AND ms.run_state = 12
								--lot end
								THEN 199
							WHEN ms.record_flag = 2
								AND ms.run_state = - 1
								--alarm on
								THEN 99
							ELSE ms.run_state
							END AS new_run_state
						,ms.started_at AS started_at
						,ms.ended_at AS ended_at
					FROM #x AS ms
					) AS me
					--WHERE (
					--		day_id BETWEEN @fr_date
					--			AND @to_date
					--		)
				) AS t1
			) AS t2
		) AS t3

	--ORDER BY started_at;
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

	SELECT t3.day_id AS day_id
		,t3.y AS y
		,t3.m AS m
		,t3.week_no AS week_no
		,DATEADD(DAY, 1 - DATEPART(WEEKDAY, t3.date_value), CAST(t3.date_value AS DATE)) AS week_start_day
		,t3.date_value AS date_value
		,t3.day_id_rank AS day_id_rank
		,t3.code AS code
		,de.name AS code_name
		,t3.day_duration_h AS day_duration_percent
		,t3.day_duration_h_others AS day_duration_percent_others
		,t3.week_rank AS week_rank
		,t3.week_duration AS week_duration_percent
		,t3.week_duration_others AS week_duration_percent_others
		,t3.month_rank AS month_rank
		,t3.month_duration AS month_duration_percent
		,t3.month_duration_others AS month_duration_percent_others
	FROM (
		SELECT t2.day_id AS day_id
			,t2.y AS y
			,t2.m AS m
			,t2.week_no AS week_no
			,t2.d AS d
			,t2.date_value AS date_value
			,t2.day_id_rank AS day_id_rank
			,t2.code AS code
			,t2.day_duration_h / (24.0 * @machines) * 100 AS day_duration_h
			,t2.day_duration_h_others / (24.0 * @machines) * 100 AS day_duration_h_others
			,
			--week
			row_number() OVER (
				PARTITION BY t2.y
				,t2.week_no
				,t2.code ORDER BY t2.y
					,t2.week_no
				) AS week_rank
			,sum(t2.day_duration_h) OVER (
				PARTITION BY t2.y
				,t2.week_no
				,t2.code
				) / (24.0 * @machines) / 7 * 100 AS week_duration
			,sum(CASE 
					WHEN t2.day_id_rank = 1
						THEN t2.day_duration_h_others
					ELSE 0
					END) OVER (
				PARTITION BY t2.y
				,t2.week_no
				) / (24.0 * @machines) / 7 * 100 AS week_duration_others
			,
			--month
			row_number() OVER (
				PARTITION BY t2.y
				,t2.m
				,t2.code ORDER BY t2.y
					,t2.m
					,t2.week_no
				) AS month_rank
			,sum(t2.day_duration_h) OVER (
				PARTITION BY t2.y
				,t2.m
				,t2.code
				) / (24.0 * @machines) / (
				SELECT DAY(EOMONTH(DATEFROMPARTS(t2.y, t2.m, t2.d)))
				) * 100 AS month_duration
			,sum(CASE 
					WHEN t2.day_id_rank = 1
						THEN t2.day_duration_h_others
					ELSE 0
					END) OVER (
				PARTITION BY t2.y
				,t2.m
				) / (24.0 * @machines) / (
				SELECT DAY(EOMONTH(DATEFROMPARTS(t2.y, t2.m, t2.d)))
				) * 100 AS month_duration_others
		FROM (
			SELECT t1.day_id AS day_id
				,t1.y AS y
				,t1.m AS m
				,t1.d AS d
				,t1.week_no AS week_no
				,t1.date_value AS date_value
				,ROW_NUMBER() OVER (
					PARTITION BY t1.day_id ORDER BY t1.day_id
					) AS day_id_rank
				,t1.code AS code
				,sum(t1.duration_h) AS day_duration_h
				,(24.0 * @machines) - sum(sum(t1.duration_h)) OVER (PARTITION BY t1.day_id) AS day_duration_h_others
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
		) AS t3
	LEFT OUTER JOIN act.fnc_dim_efficiencies() AS de ON de.run_state = t3.code
	--where week_rank=1
	--where month_rank = 1
	ORDER BY day_id
		,code
END
