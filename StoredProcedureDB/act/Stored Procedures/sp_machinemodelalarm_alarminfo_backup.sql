
CREATE PROCEDURE [act].[sp_machinemodelalarm_alarminfo_backup] (
	@package_id INT
	,@machine_model_id_list NVARCHAR(max)
	,@machine_id_list NVARCHAR(max)
	,@device_name VARCHAR(20) = NULL
	,@date_from DATETIME
	,@date_to DATETIME
	,@time_offset INT = 0
	,@alarm_level_alarm INT = 0
	,@alarm_level_warning INT = 0
	,@alarm_level_caution INT = 0
	,@alarm_id_list NVARCHAR(max) = NULL
	,@top_num INT = 5
	,@unit_type_duration BIT = 0
	,@include_selected_alarm BIT = 1
	)
AS
BEGIN
	--DECLARE @package_group_id INT = NULL
	--DECLARE @package_id INT = 242
	--DECLARE @process_id INT = NULL
	--DECLARE @job_id INT = 106
	--DECLARE @device_name CHAR(20) = NULL
	--DECLARE @date_from DATETIME = '2023-01-01 00:00:00'
	--DECLARE @date_to DATETIME = '2023-01-30 00:00:00'
	--DECLARE @time_offset INT = 8
	--DECLARE @machine_model_id_list NVARCHAR(max) = '21,53'
	--DECLARE @machine_id_list NVARCHAR(max) = '18,19,1305'
	--------------
	--DECLARE @alarm_level INT = 0
	--DECLARE @alarm_level_alarm INT = 0
	--DECLARE @alarm_level_warning INT = 0
	--DECLARE @alarm_level_caution INT = 0
	--DECLARE @alarm_id_list NVARCHAR(max) = '1571,1620,1207,1736,1605,8766'
	--DECLARE @top_num INT = 5
	--DECLARE @unit_type_duration BIT = 0
	--DECLARE @include_selected_alarm BIT = 1
	DECLARE @local_date_from DATETIME = dateadd(hour, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = dateadd(hour, @time_offset, @date_to)
	DECLARE @from INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = CONVERT(DATE, @date_from)
			);
	DECLARE @to INT = (
			SELECT id
			FROM APCSProDWH.dwh.dim_days
			WHERE date_value = CONVERT(DATE, @date_to)
			);
	DECLARE @alarm_level INT = @alarm_level_alarm + @alarm_level_warning + @alarm_level_caution
	DECLARE @max_seq_id_cnt INT
	DECLARE @max_seq_id_duration INT

	IF OBJECT_ID(N'tempdb..#alarm_cnt_table', N'U') IS NOT NULL
		DROP TABLE #alarm_cnt_table;

	IF OBJECT_ID(N'tempdb..#alarm_cnt_pareto', N'U') IS NOT NULL
		DROP TABLE #alarm_cnt_pareto;

	IF OBJECT_ID(N'tempdb..#alarm_duration_table', N'U') IS NOT NULL
		DROP TABLE #alarm_duration_table;

	IF OBJECT_ID(N'tempdb..#alarm_duration_pareto', N'U') IS NOT NULL
		DROP TABLE #alarm_duration_pareto;

	IF @unit_type_duration = 0
	BEGIN
		SELECT *
			,sum(target_alarm) OVER () AS num_target_alarm
		INTO #alarm_cnt_table
		FROM (
			SELECT ROW_NUMBER() OVER (
					ORDER BY target_alarm DESC
						,sum_alarm_cnt DESC
					) AS seq_id
				,t6.*
				,sum(t6.sum_alarm_cnt) OVER (PARTITION BY t6.target_alarm) AS target_alarm_cnt
				,sum(t6.sum_alarm_cnt) OVER () AS all_alarm_cnt
			FROM (
				SELECT t5.*
					,CASE 
						WHEN t5.rank_sum_alarm_cnt <= @top_num
							OR (
								@include_selected_alarm = 1
								AND t5.selected_alarm = 1
								)
							THEN 1
						ELSE 0
						END AS target_alarm
				FROM (
					SELECT t4.alarm_text
						,t4.selected_alarm
						,t4.new_sum_alarm_cnt AS sum_alarm_cnt
						,t4.new_alarm_text
						,dense_rank() OVER (
							ORDER BY t4.new_sum_alarm_cnt DESC
							) AS rank_sum_alarm_cnt
					FROM (
						SELECT t3.*
							,row_number() OVER (
								PARTITION BY t3.alarm_text ORDER BY tmp_rk DESC
								) AS rk
							,CASE 
								WHEN tmp_rk = 1
									THEN t3.machine_model_name + N'_' + t3.alarm_text
								ELSE FORMAT(tmp_rk, '0') + N'models_' + t3.alarm_text
								END AS new_alarm_text
						FROM (
							SELECT t2.*
								,dense_rank() OVER (
									PARTITION BY t2.alarm_text ORDER BY t2.machine_model_id
									) AS tmp_rk
								,sum(t2.sum_alarm_cnt) OVER (PARTITION BY t2.alarm_text) AS new_sum_alarm_cnt
							FROM (
								SELECT t1.model_alarm_id
									,t1.alarm_text
									,t1.selected_alarm
									,t1.machine_model_id
									,t1.machine_model_name
									,sum(1) AS sum_alarm_cnt
								FROM (
									SELECT mar.[id]
										,mar.[updated_at]
										,mar.alarm_on_at
										,mar.alarm_off_at
										,mm.machine_model_id
										,m.name AS machine_model_name
										,mar.[model_alarm_id]
										,CASE 
											WHEN @include_selected_alarm = 1
												THEN isnull(selected_alarm, 0)
											ELSE 0
											END AS selected_alarm
										,at.alarm_text
									FROM [APCSProDB].[trans].[machine_alarm_records] AS mar WITH (NOLOCK)
									INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
									INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = mar.machine_id
									INNER JOIN APCSProDB.mc.models AS m WITH (NOLOCK) ON m.id = mm.machine_model_id
									INNER JOIN APCSProDB.trans.alarm_lot_records AS alr WITH (NOLOCK) ON alr.id = mar.id
									INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = alr.lot_id
									INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
									LEFT JOIN APCSProDB.mc.alarm_texts AS at WITH (NOLOCK) ON at.alarm_text_id = ma.alarm_text_id
									LEFT JOIN (
										SELECT convert(INT, value) AS v
											,1 AS selected_alarm
										FROM STRING_SPLIT(@alarm_id_list, ',')
										) AS sa ON sa.v = mar.model_alarm_id
									WHERE alarm_on_at BETWEEN @local_date_from
											AND @local_date_to
										AND mm.machine_model_id IN (
											SELECT value
											FROM string_split(@machine_model_id_list, ',')
											)
										AND tl.act_package_id = @package_id
										AND (
											(
												@alarm_level > 0
												AND (
													(
														@alarm_level_alarm > 0
														AND ma.alarm_level = 0
														)
													OR (
														@alarm_level_warning > 0
														AND ma.alarm_level = 1
														)
													OR (
														@alarm_level_caution > 0
														AND ma.alarm_level = 2
														)
													)
												)
											OR (
												@alarm_level = 0
												AND ma.alarm_level >= 0
												)
											)
										AND isnull(ma.is_disabled, 0) = 0
										AND (
											(
												@device_name IS NOT NULL
												AND dn.name = @device_name
												)
											OR (@device_name IS NULL)
											)
									) AS t1
								GROUP BY t1.model_alarm_id
									,t1.alarm_text
									,t1.selected_alarm
									,t1.machine_model_id
									,t1.machine_model_name
								) AS t2
							) AS t3
						) AS t4
					WHERE t4.rk = 1
					) AS t5
				) AS t6
			) AS t7

		SET @max_seq_id_cnt = (
				SELECT TOP 1 t1.num_target_alarm + 1
				FROM #alarm_cnt_table AS t1
				WHERE t1.target_alarm = 0
				)

		SELECT t2.seq_id
			,t2.selected_alarm
			,t2.sum_alarm_cnt
			,convert(DECIMAL(18, 3), sum(t2.sum_alarm_cnt) OVER (
					ORDER BY t2.seq_id
					) * 100) / ((nullif(t2.all_alarm_cnt, 0))) AS percent_alarm_cnt_chart
			,t2.target_alarm
			,t2.new_alarm_text AS alarm_text
			,t2.alarm_text AS org_alarm_text
		INTO #alarm_cnt_pareto
		FROM (
			SELECT *
			FROM #alarm_cnt_table
			WHERE target_alarm = 1
			
			UNION
			
			SELECT TOP 1 @max_seq_id_cnt AS seq_id
				,'Others'
				,0
				,t1.target_alarm_cnt
				,'Others'
				,NULL
				,1
				,t1.target_alarm_cnt
				,t1.all_alarm_cnt
				,t1.num_target_alarm
			FROM #alarm_cnt_table AS t1
			WHERE t1.target_alarm = 0
			) AS t2
	END
	ELSE
	BEGIN
		SELECT *
			,sum(target_alarm) OVER () AS num_target_alarm
		INTO #alarm_duration_table
		FROM (
			SELECT ROW_NUMBER() OVER (
					ORDER BY target_alarm DESC
						,sum_alarm_duration DESC
					) AS seq_id
				,t6.*
				,sum(t6.sum_alarm_duration) OVER (PARTITION BY t6.target_alarm) AS target_alarm_duration
				,sum(t6.sum_alarm_duration) OVER () AS all_alarm_duration
			FROM (
				SELECT t5.*
					,CASE 
						WHEN t5.rank_sum_alarm_duration <= @top_num
							OR (
								@include_selected_alarm = 1
								AND t5.selected_alarm = 1
								)
							THEN 1
						ELSE 0
						END AS target_alarm
				FROM (
					SELECT t4.alarm_text
						,t4.selected_alarm
						,t4.new_sum_alarm_duration AS sum_alarm_duration
						,t4.new_alarm_text
						,dense_rank() OVER (
							ORDER BY t4.new_sum_alarm_duration DESC
							) AS rank_sum_alarm_duration
					FROM (
						SELECT t3.*
							,row_number() OVER (
								PARTITION BY t3.alarm_text ORDER BY tmp_rk DESC
								) AS rk
							,CASE 
								WHEN tmp_rk = 1
									THEN t3.machine_model_name + N'_' + t3.alarm_text
								ELSE FORMAT(tmp_rk, '0') + N'models_' + t3.alarm_text
								END AS new_alarm_text
						FROM (
							SELECT t2.*
								,dense_rank() OVER (
									PARTITION BY t2.alarm_text ORDER BY t2.machine_model_id
									) AS tmp_rk
								,sum(t2.sum_alarm_duration) OVER (PARTITION BY t2.alarm_text) AS new_sum_alarm_duration
							FROM (
								SELECT t1.model_alarm_id
									,t1.alarm_text
									,t1.selected_alarm
									,t1.machine_model_id
									,t1.machine_model_name
									,sum(t1.alarm_duration) AS sum_alarm_duration
								FROM (
									SELECT mar.[id]
										,mar.[updated_at]
										,mar.alarm_on_at
										,mar.alarm_off_at
										,mm.machine_model_id
										,m.name AS machine_model_name
										,mar.[model_alarm_id]
										,isnull(convert(DECIMAL(18, 1), datediff_big(SECOND, mar.alarm_on_at, CASE 
														WHEN mar.alarm_off_at > @local_date_to
															THEN @local_date_to
														ELSE
															--1900/01/01 00:00:00対策
															CASE 
																WHEN mar.alarm_on_at < mar.alarm_off_at
																	THEN mar.alarm_off_at
																WHEN mar.alarm_on_at < mar.started_at
																	THEN mar.started_at
																ELSE mar.updated_at
																END
														END)) / 60 / 60, NULL) AS alarm_duration
										,CASE 
											WHEN @include_selected_alarm = 1
												THEN isnull(selected_alarm, 0)
											ELSE 0
											END AS selected_alarm
										,at.alarm_text
									FROM [APCSProDB].[trans].[machine_alarm_records] AS mar WITH (NOLOCK)
									INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
									INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = mar.machine_id
									INNER JOIN APCSProDB.mc.models AS m WITH (NOLOCK) ON m.id = mm.machine_model_id
									INNER JOIN APCSProDB.trans.alarm_lot_records AS alr WITH (NOLOCK) ON alr.id = mar.id
									INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = alr.lot_id
									INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
									LEFT JOIN APCSProDB.mc.alarm_texts AS at WITH (NOLOCK) ON at.alarm_text_id = ma.alarm_text_id
									LEFT JOIN (
										SELECT convert(INT, value) AS v
											,1 AS selected_alarm
										FROM STRING_SPLIT(@alarm_id_list, ',')
										) AS sa ON sa.v = mar.model_alarm_id
									WHERE alarm_on_at BETWEEN @local_date_from
											AND @local_date_to
										AND mm.machine_model_id IN (
											SELECT value
											FROM string_split(@machine_model_id_list, ',')
											)
										AND tl.act_package_id = @package_id
										AND (
											(
												@alarm_level > 0
												AND (
													(
														@alarm_level_alarm > 0
														AND ma.alarm_level = 0
														)
													OR (
														@alarm_level_warning > 0
														AND ma.alarm_level = 1
														)
													OR (
														@alarm_level_caution > 0
														AND ma.alarm_level = 2
														)
													)
												)
											OR (
												@alarm_level = 0
												AND ma.alarm_level >= 0
												)
											)
										AND isnull(ma.is_disabled, 0) = 0
										AND (
											(
												@device_name IS NOT NULL
												AND dn.name = @device_name
												)
											OR (@device_name IS NULL)
											)
									) AS t1
								GROUP BY t1.model_alarm_id
									,t1.alarm_text
									,t1.selected_alarm
									,t1.machine_model_id
									,t1.machine_model_name
								) AS t2
							) AS t3
						) AS t4
					WHERE t4.rk = 1
					) AS t5
				) AS t6
			) AS t7

		SET @max_seq_id_duration = (
				SELECT TOP 1 t1.num_target_alarm + 1
				FROM #alarm_duration_table AS t1
				WHERE t1.target_alarm = 0
				)

		--------- pareto chart ----------------
		SELECT t2.seq_id
			,t2.selected_alarm
			,t2.sum_alarm_duration
			,convert(DECIMAL(18, 3), sum(t2.sum_alarm_duration) OVER (
					ORDER BY t2.seq_id
					) * 100) / ((nullif(t2.all_alarm_duration, 0))) AS percent_alarm_duration_chart
			,t2.target_alarm
			,t2.new_alarm_text AS alarm_text
			,t2.alarm_text AS org_alarm_text
		INTO #alarm_duration_pareto
		FROM (
			SELECT *
			FROM #alarm_duration_table
			WHERE target_alarm = 1
			
			UNION
			
			SELECT TOP 1 @max_seq_id_duration AS seq_id
				,'Others'
				,0
				,t1.target_alarm_duration
				,'Others'
				,NULL
				,1
				,t1.target_alarm_duration
				,t1.all_alarm_duration
				,t1.num_target_alarm
			FROM #alarm_duration_table AS t1
			WHERE t1.target_alarm = 0
			) AS t2
	END

	--------- pareto chart ----------------
	IF @unit_type_duration = 0
	BEGIN
		SELECT *
		FROM #alarm_cnt_pareto
		ORDER BY seq_id
	END
	ELSE
	BEGIN
		SELECT *
		FROM #alarm_duration_pareto
		ORDER BY seq_id
	END

	---------------- transition count------------------------
	IF @unit_type_duration = 0
	BEGIN
		SELECT t3.seq_id
			,t3.day_id
			,t3.date_value
			,t3.y
			,t3.m
			,t3.d
			,t3.week_no
			,isnull(t3.selected_alarm, 0) AS selected_alarm
			,t3.target_alarm
			,isnull(t3.alarm_text, N'Others') AS alarm_text
			,t3.day_rank
			,t3.day_alarm_cnt
			,t3.day_all_alarm_cnt
			,ROW_NUMBER() OVER (
				PARTITION BY t3.y
				,t3.week_no
				,t3.seq_id ORDER BY t3.seq_id
				) AS week_rank
			,t3.week_alarm_cnt
			,t3.week_all_alarm_cnt
			,ROW_NUMBER() OVER (
				PARTITION BY t3.y
				,t3.m
				,t3.seq_id ORDER BY t3.seq_id
				) AS month_rank
			,t3.month_alarm_cnt
			,t3.month_all_alarm_cnt
			--,t3.alarm_text
			,DATEADD(DAY, 1 - DATEPART(WEEKDAY, t3.date_value), CAST(t3.date_value AS DATE)) AS week_start_day
		FROM (
			SELECT isnull(t2.seq_id, @max_seq_id_cnt) AS seq_id
				,t2.day_id
				,t2.date_value
				,t2.y
				,t2.m
				,t2.d
				,t2.week_no
				,t2.selected_alarm
				,t2.target_alarm
				,t2.alarm_text
				,t2.day_rank
				,t2.day_alarm_cnt
				,t2.day_all_alarm_cnt
				,t2.week_alarm_cnt
				,t2.week_all_alarm_cnt
				,t2.month_alarm_cnt
				,t2.month_all_alarm_cnt
			FROM (
				SELECT t1.seq_id
					,t1.day_id
					,t1.date_value AS date_value
					,t1.y AS y
					,t1.m AS m
					,t1.d AS d
					,t1.quarter_no AS quarter_no
					,t1.week_no AS week_no
					,t1.selected_alarm AS selected_alarm
					,isnull(t1.target_alarm, 0) AS target_alarm
					,t1.alarm_text
					--day
					,ROW_NUMBER() OVER (
						PARTITION BY t1.day_id
						,t1.seq_id ORDER BY t1.seq_id
						) AS day_rank
					,sum(1) OVER (
						PARTITION BY t1.day_id
						,t1.seq_id
						,t1.target_alarm
						) AS day_alarm_cnt
					,sum(1) OVER (
						PARTITION BY t1.day_id
						,t1.target_alarm
						) AS day_all_alarm_cnt
					--week
					,sum(1) OVER (
						PARTITION BY t1.y
						,t1.week_no
						,t1.seq_id
						,t1.target_alarm
						) AS week_alarm_cnt
					,sum(1) OVER (
						PARTITION BY t1.y
						,t1.week_no
						,t1.target_alarm
						) AS week_all_alarm_cnt
					--month
					,sum(1) OVER (
						PARTITION BY t1.y
						,t1.m
						,t1.seq_id
						) AS month_alarm_cnt
					,sum(1) OVER (
						PARTITION BY t1.y
						,t1.m
						,t1.target_alarm
						) AS month_all_alarm_cnt
				FROM (
					SELECT dd.id AS day_id
						,dd.date_value AS date_value
						,dd.y AS y
						,dd.m AS m
						,dd.d AS d
						,dd.quarter_no AS quarter_no
						,dd.week_no AS week_no
						,alm.*
					FROM (
						SELECT *
						FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
						WHERE @from <= id
							AND id < @to
						) AS dd
					LEFT JOIN (
						SELECT mar.[id]
							,mar.[alarm_on_at]
							,CONVERT(DATE, dateadd(hour, - @time_offset, mar.[alarm_on_at])) AS alarm_on_day
							,alr.lot_id
							,ac.selected_alarm AS selected_alarm
							,ac.target_alarm
							,ac.seq_id
							,ac.alarm_text
						FROM [APCSProDB].[trans].[machine_alarm_records] AS mar WITH (NOLOCK)
						INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
						LEFT JOIN APCSProDB.mc.alarm_texts AS at WITH (NOLOCK) ON at.alarm_text_id = ma.alarm_text_id
						INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = mar.machine_id
						INNER JOIN APCSProDB.mc.models AS m WITH (NOLOCK) ON m.id = mm.machine_model_id
						INNER JOIN APCSProDB.trans.alarm_lot_records AS alr WITH (NOLOCK) ON alr.id = mar.id
						INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = alr.lot_id
						INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
						LEFT JOIN #alarm_cnt_pareto AS ac ON ac.org_alarm_text = at.alarm_text
						WHERE alarm_on_at BETWEEN @local_date_from
								AND @local_date_to
							AND mm.machine_model_id IN (
								SELECT value
								FROM string_split(@machine_model_id_list, ',')
								)
							AND tl.act_package_id = @package_id
							AND (
								(
									@alarm_level > 0
									AND (
										(
											@alarm_level_alarm > 0
											AND ma.alarm_level = 0
											)
										OR (
											@alarm_level_warning > 0
											AND ma.alarm_level = 1
											)
										OR (
											@alarm_level_caution > 0
											AND ma.alarm_level = 2
											)
										)
									)
								OR (
									@alarm_level = 0
									AND ma.alarm_level >= 0
									)
								)
							AND isnull(ma.is_disabled, 0) = 0
							AND (
								(
									@device_name IS NOT NULL
									AND dn.name = @device_name
									)
								OR (@device_name IS NULL)
								)
						) AS alm ON alm.alarm_on_day = dd.date_value
					) AS t1
				) AS t2
			WHERE t2.day_rank = 1
			) AS t3
		ORDER BY date_value
			,seq_id
	END
	ELSE
	BEGIN
		---------------- transition duration------------------------
		SELECT t3.seq_id
			,t3.day_id
			,t3.date_value
			,t3.y
			,t3.m
			,t3.d
			,t3.week_no
			,isnull(t3.selected_alarm, 0) AS selected_alarm
			,t3.target_alarm
			,isnull(t3.alarm_text, N'Others') AS alarm_text
			,t3.day_rank
			,t3.day_alarm_duration
			,t3.day_all_alarm_duration
			,ROW_NUMBER() OVER (
				PARTITION BY t3.y
				,t3.week_no
				,t3.seq_id ORDER BY t3.seq_id
				) AS week_rank
			,t3.week_alarm_duration
			,t3.week_all_alarm_duration
			,ROW_NUMBER() OVER (
				PARTITION BY t3.y
				,t3.m
				,t3.seq_id ORDER BY t3.seq_id
				) AS month_rank
			,t3.month_alarm_duration
			,t3.month_all_alarm_duration
			,DATEADD(DAY, 1 - DATEPART(WEEKDAY, t3.date_value), CAST(t3.date_value AS DATE)) AS week_start_day
		FROM (
			SELECT isnull(t2.seq_id, @max_seq_id_duration) AS seq_id
				,t2.day_id
				,t2.date_value
				,t2.y
				,t2.m
				,t2.d
				,t2.week_no
				,t2.selected_alarm
				,t2.target_alarm
				,t2.alarm_text
				,t2.day_rank
				,t2.day_alarm_duration
				,t2.day_all_alarm_duration
				,t2.week_alarm_duration
				,t2.week_all_alarm_duration
				,t2.month_alarm_duration
				,t2.month_all_alarm_duration
			FROM (
				SELECT t1.seq_id
					,t1.day_id
					,t1.date_value AS date_value
					,t1.y AS y
					,t1.m AS m
					,t1.d AS d
					,t1.quarter_no AS quarter_no
					,t1.week_no AS week_no
					,t1.selected_alarm AS selected_alarm
					,isnull(t1.target_alarm, 0) AS target_alarm
					,t1.alarm_text
					--day
					,ROW_NUMBER() OVER (
						PARTITION BY t1.day_id
						,t1.seq_id ORDER BY t1.seq_id
						) AS day_rank
					,sum(t1.alarm_duration) OVER (
						PARTITION BY t1.day_id
						,t1.seq_id
						,t1.target_alarm
						) AS day_alarm_duration
					,sum(t1.alarm_duration) OVER (
						PARTITION BY t1.day_id
						,t1.target_alarm
						) AS day_all_alarm_duration
					--week
					,sum(t1.alarm_duration) OVER (
						PARTITION BY t1.y
						,t1.week_no
						,t1.seq_id
						,t1.target_alarm
						) AS week_alarm_duration
					,sum(alarm_duration) OVER (
						PARTITION BY t1.y
						,t1.week_no
						,t1.target_alarm
						) AS week_all_alarm_duration
					--month
					,sum(t1.alarm_duration) OVER (
						PARTITION BY t1.y
						,t1.m
						,t1.seq_id
						) AS month_alarm_duration
					,sum(t1.alarm_duration) OVER (
						PARTITION BY t1.y
						,t1.m
						,t1.target_alarm
						) AS month_all_alarm_duration
				FROM (
					SELECT dd.id AS day_id
						,dd.date_value AS date_value
						,dd.y AS y
						,dd.m AS m
						,dd.d AS d
						,dd.quarter_no AS quarter_no
						,dd.week_no AS week_no
						,alm.*
					FROM (
						SELECT *
						FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
						WHERE @from <= id
							AND id < @to
						) AS dd
					LEFT JOIN (
						SELECT mar.[id]
							,mar.[alarm_on_at]
							,CONVERT(DATE, dateadd(hour, - @time_offset, mar.[alarm_on_at])) AS alarm_on_day
							,isnull(convert(DECIMAL(18, 1), datediff_big(SECOND, mar.alarm_on_at, CASE 
											WHEN mar.alarm_off_at > @local_date_to
												THEN @local_date_to
											ELSE
												--1900/01/01 00:00:00対策
												CASE 
													WHEN mar.alarm_on_at < mar.alarm_off_at
														THEN mar.alarm_off_at
													WHEN mar.alarm_on_at < mar.started_at
														THEN mar.started_at
													ELSE mar.updated_at
													END
											END)) / 60 / 60, NULL) AS alarm_duration
							,alr.lot_id
							,ac.selected_alarm AS selected_alarm
							,ac.target_alarm
							,ac.seq_id
							,ac.alarm_text
						FROM [APCSProDB].[trans].[machine_alarm_records] AS mar WITH (NOLOCK)
						INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
						LEFT JOIN APCSProDB.mc.alarm_texts AS at WITH (NOLOCK) ON at.alarm_text_id = ma.alarm_text_id
						INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = mar.machine_id
						INNER JOIN APCSProDB.mc.models AS m WITH (NOLOCK) ON m.id = mm.machine_model_id
						INNER JOIN APCSProDB.trans.alarm_lot_records AS alr WITH (NOLOCK) ON alr.id = mar.id
						INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = alr.lot_id
						INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
						LEFT JOIN #alarm_duration_pareto AS ac ON ac.org_alarm_text = at.alarm_text
						WHERE alarm_on_at BETWEEN @local_date_from
								AND @local_date_to
							AND mm.machine_model_id IN (
								SELECT value
								FROM string_split(@machine_model_id_list, ',')
								)
							AND tl.act_package_id = @package_id
							AND (
								(
									@alarm_level > 0
									AND (
										(
											@alarm_level_alarm > 0
											AND ma.alarm_level = 0
											)
										OR (
											@alarm_level_warning > 0
											AND ma.alarm_level = 1
											)
										OR (
											@alarm_level_caution > 0
											AND ma.alarm_level = 2
											)
										)
									)
								OR (
									@alarm_level = 0
									AND ma.alarm_level >= 0
									)
								)
							AND isnull(ma.is_disabled, 0) = 0
							AND (
								(
									@device_name IS NOT NULL
									AND dn.name = @device_name
									)
								OR (@device_name IS NULL)
								)
						) AS alm ON alm.alarm_on_day = dd.date_value
					) AS t1
				) AS t2
			WHERE t2.day_rank = 1
			) AS t3
		ORDER BY date_value
			,seq_id
	END
END
