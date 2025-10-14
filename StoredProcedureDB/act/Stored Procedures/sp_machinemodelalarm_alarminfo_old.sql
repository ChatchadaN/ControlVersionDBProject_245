
CREATE PROCEDURE [act].[sp_machinemodelalarm_alarminfo_old] (
	@package_id INT
	,@machine_model_id_list NVARCHAR(max)
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

	IF OBJECT_ID(N'tempdb..#alarm_cnt_table', N'U') IS NOT NULL
		DROP TABLE #alarm_cnt_table;

	IF OBJECT_ID(N'tempdb..#alarm_duration_table', N'U') IS NOT NULL
		DROP TABLE #alarm_duration_table;

	IF @unit_type_duration = 0
	BEGIN
		SELECT ROW_NUMBER() OVER (
				ORDER BY target_alarm DESC
					,sum_alarm_cnt DESC
					,model_alarm_id
				) AS seq_id
			,t5.*
			,convert(DECIMAL(18, 3), sum(t5.sum_alarm_cnt) OVER (
					ORDER BY t5.rank_sum_alarm_cnt
					) * 100) / ((nullif(t5.all_alarm_cnt, 0))) AS percent_alarm_cnt_chart
			,ma.machine_model_id
			,mm.name AS machine_model_name
			,ma.alarm_code
			,ma.alarm_text_id
			,mm.name + '*' + CASE 
				WHEN at.alarm_text <> ''
					THEN at.alarm_text
				ELSE ma.alarm_code
				END AS alarm_text
		INTO #alarm_cnt_table
		FROM (
			SELECT t4.*
				,sum(sum_alarm_cnt) OVER (PARTITION BY t4.target_alarm) AS target_alarm_cnt
				,sum(sum_alarm_cnt) OVER () AS all_alarm_cnt
			FROM (
				SELECT t3.*
					,CASE 
						WHEN t3.rank_sum_alarm_cnt <= @top_num
							OR (
								@include_selected_alarm = 1
								AND t3.selected_alarm = 1
								)
							THEN 1
						ELSE 0
						END AS target_alarm
				FROM (
					SELECT t2.*
						,dense_rank() OVER (
							ORDER BY t2.sum_alarm_cnt DESC
							) AS rank_sum_alarm_cnt
					FROM (
						SELECT t1.model_alarm_id
							,t1.selected_alarm
							,sum(1) AS sum_alarm_cnt
						FROM (
							SELECT mar.[id]
								,mar.[updated_at]
								,mm.machine_model_id
								,mar.[model_alarm_id]
								,CASE 
									WHEN @include_selected_alarm = 1
										THEN isnull(selected_alarm, 0)
									ELSE 0
									END AS selected_alarm
							FROM [APCSProDB].[trans].[machine_alarm_records] AS mar WITH (NOLOCK)
							INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
							INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = mar.machine_id
							INNER JOIN APCSProDB.mc.models AS m WITH (NOLOCK) ON m.id = mm.machine_model_id
							INNER JOIN APCSProDB.trans.alarm_lot_records AS alr WITH (NOLOCK) ON alr.id = mar.id
							INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = alr.lot_id
							INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
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
							,t1.selected_alarm
						) AS t2
					) AS t3
				) AS t4
			) AS t5
		LEFT JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = t5.model_alarm_id
		LEFT JOIN APCSProDB.mc.alarm_texts AS at WITH (NOLOCK) ON at.alarm_text_id = ma.alarm_text_id
		LEFT JOIN APCSProDB.mc.models AS mm WITH (NOLOCK) ON mm.id = ma.machine_model_id
		WHERE t5.target_alarm = 1
			--ORDER BY target_alarm DESC
			--	,sum_alarm_cnt DESC
	END
	ELSE
	BEGIN
		SELECT ROW_NUMBER() OVER (
				ORDER BY target_alarm DESC
					,sum_alarm_duration DESC
					,model_alarm_id
				) AS seq_id
			,t5.*
			,convert(DECIMAL(18, 3), sum(t5.sum_alarm_duration) OVER (
					ORDER BY t5.rank_sum_alarm_duration
					) * 100) / ((nullif(t5.all_alarm_duration, 0))) AS percent_alarm_duration_chart
			,ma.machine_model_id
			,mm.name AS machine_model_name
			,ma.alarm_code
			,ma.alarm_text_id
			,mm.name + '*' + CASE 
				WHEN at.alarm_text <> ''
					THEN at.alarm_text
				ELSE ma.alarm_code
				END AS alarm_text
		INTO #alarm_duration_table
		FROM (
			SELECT t4.*
				,sum(sum_alarm_duration) OVER (PARTITION BY t4.target_alarm) AS target_alarm_duration
				,sum(sum_alarm_duration) OVER () AS all_alarm_duration
			FROM (
				SELECT t3.*
					,CASE 
						WHEN t3.rank_sum_alarm_duration <= @top_num
							OR (
								@include_selected_alarm = 1
								AND t3.selected_alarm = 1
								)
							THEN 1
						ELSE 0
						END AS target_alarm
				FROM (
					SELECT t2.*
						,dense_rank() OVER (
							ORDER BY t2.sum_alarm_duration DESC
							) AS rank_sum_alarm_duration
					FROM (
						SELECT t1.model_alarm_id
							,t1.selected_alarm
							,sum(t1.alarm_duration) AS sum_alarm_duration
						FROM (
							SELECT mar.[id]
								,mar.[updated_at]
								,mm.machine_model_id
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
							FROM [APCSProDB].[trans].[machine_alarm_records] AS mar WITH (NOLOCK)
							INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
							INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = mar.machine_id
							INNER JOIN APCSProDB.mc.models AS m WITH (NOLOCK) ON m.id = mm.machine_model_id
							INNER JOIN APCSProDB.trans.alarm_lot_records AS alr WITH (NOLOCK) ON alr.id = mar.id
							INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = alr.lot_id
							INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
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
							,t1.selected_alarm
						) AS t2
					) AS t3
				) AS t4
			) AS t5
		LEFT JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = t5.model_alarm_id
		LEFT JOIN APCSProDB.mc.alarm_texts AS at WITH (NOLOCK) ON at.alarm_text_id = ma.alarm_text_id
		LEFT JOIN APCSProDB.mc.models AS mm WITH (NOLOCK) ON mm.id = ma.machine_model_id
		WHERE t5.target_alarm = 1
			--ORDER BY target_alarm DESC
			--	,sum_alarm_duration DESC
	END

	--------- pareto chart ----------------
	IF @unit_type_duration = 0
	BEGIN
		SELECT *
		FROM #alarm_cnt_table
		
		UNION
		
		SELECT TOP 1 max(t1.seq_id) OVER () + 1 AS seq_id
			,NULL
			,0
			,t1.all_alarm_cnt - t1.target_alarm_cnt
			,max(t1.rank_sum_alarm_cnt) OVER () + 1 AS rank_sum_alarm_cnt
			,0
			,t1.all_alarm_cnt - t1.target_alarm_cnt
			,t1.all_alarm_cnt
			,100 AS percent_alarm_cnt_chart
			,NULL
			,NULL
			,NULL
			,NULL
			,'Others'
		FROM #alarm_cnt_table AS t1
		ORDER BY seq_id
	END
	ELSE
	BEGIN
		SELECT *
		FROM #alarm_duration_table
		
		UNION
		
		SELECT TOP 1 max(t1.seq_id) OVER () + 1 AS seq_id
			,NULL
			,0
			,t1.all_alarm_duration - t1.target_alarm_duration
			,max(t1.rank_sum_alarm_duration) OVER () + 1 AS rank_sum_alarm_duration
			,0
			,t1.all_alarm_duration - t1.target_alarm_duration
			,t1.all_alarm_duration
			,100 AS percent_alarm_duration_chart
			,NULL
			,NULL
			,NULL
			,NULL
			,'Others'
		FROM #alarm_duration_table AS t1
		ORDER BY seq_id
	END

	---------------- transition count------------------------
	IF @unit_type_duration = 0
	BEGIN
		SELECT CASE 
				WHEN t3.seq_id IS NULL
					THEN t3.num_of_seq_id
				ELSE t3.seq_id
				END AS seq_id
			,t3.day_id
			,t3.date_value
			,t3.y
			,t3.m
			,t3.d
			,t3.quarter_no
			,t3.week_no
			,t3.model_alarm_id
			,t3.selected_alarm
			,t3.target_alarm
			,t3.day_rank
			,CASE 
				WHEN seq_id IS NULL
					THEN t3.day_all_alarm_cnt
				ELSE t3.day_alarm_cnt
				END AS day_alarm_cnt
			,t3.day_all_alarm_cnt
			,ROW_NUMBER() OVER (
				PARTITION BY t3.y
				,t3.week_no
				,t3.model_alarm_id ORDER BY t3.model_alarm_id
				) AS week_rank
			,CASE 
				WHEN seq_id IS NULL
					THEN t3.week_all_alarm_cnt
				ELSE t3.week_alarm_cnt
				END AS week_alarm_cnt
			,t3.week_all_alarm_cnt
			,ROW_NUMBER() OVER (
				PARTITION BY t3.y
				,t3.m
				,t3.model_alarm_id ORDER BY t3.model_alarm_id
				) AS month_rank
			,CASE 
				WHEN seq_id IS NULL
					THEN t3.month_all_alarm_cnt
				ELSE t3.month_alarm_cnt
				END AS month_alarm_cnt
			,t3.month_all_alarm_cnt
			,t3.machine_model_id
			,t3.machine_model_name
			,t3.alarm_code
			,t3.alarm_text_id
			,t3.alarm_text
			,CASE 
				WHEN seq_id IS NULL
					THEN t3.seq_other
				ELSE NULL
				END AS seq_other
			,DATEADD(DAY, 1 - DATEPART(WEEKDAY, t3.date_value), CAST(t3.date_value AS DATE)) AS week_start_day
		FROM (
			SELECT t2.*
				,CASE 
					WHEN t2.seq_id IS NOT NULL
						THEN max(t2.seq_id) OVER (PARTITION BY t2.day_id) + 1
					ELSE NULL
					END AS num_of_seq_id
				,RANK() OVER (
					PARTITION BY t2.day_id
					,t2.target_alarm
					,t2.day_rank ORDER BY t2.model_alarm_id
					) AS seq_other
			FROM (
				SELECT t1.seq_id
					,t1.day_id
					,t1.date_value AS date_value
					,t1.y AS y
					,t1.m AS m
					,t1.d AS d
					,t1.quarter_no AS quarter_no
					,t1.week_no AS week_no
					,t1.model_alarm_id AS model_alarm_id
					,t1.selected_alarm AS selected_alarm
					,isnull(t1.target_alarm, 0) AS target_alarm
					--day
					,ROW_NUMBER() OVER (
						PARTITION BY t1.day_id
						,t1.model_alarm_id ORDER BY t1.model_alarm_id
						) AS day_rank
					,sum(CASE 
							WHEN id IS NOT NULL
								THEN 1
							ELSE 0
							END) OVER (
						PARTITION BY t1.day_id
						,t1.model_alarm_id
						,t1.target_alarm
						) AS day_alarm_cnt
					,sum(CASE 
							WHEN id IS NOT NULL
								THEN 1
							ELSE 0
							END) OVER (
						PARTITION BY t1.day_id
						,t1.target_alarm
						) AS day_all_alarm_cnt
					--week
					--,ROW_NUMBER() OVER (
					--	PARTITION BY t1.y
					--	,t1.week_no
					--	,t1.model_alarm_id ORDER BY t1.model_alarm_id
					--	) AS week_rank
					,sum(CASE 
							WHEN id IS NOT NULL
								THEN 1
							ELSE 0
							END) OVER (
						PARTITION BY t1.y
						,t1.week_no
						,t1.model_alarm_id
						,t1.target_alarm
						) AS week_alarm_cnt
					,sum(CASE 
							WHEN id IS NOT NULL
								THEN 1
							ELSE 0
							END) OVER (
						PARTITION BY t1.y
						,t1.week_no
						,t1.target_alarm
						) AS week_all_alarm_cnt
					--month
					--,ROW_NUMBER() OVER (
					--	PARTITION BY t1.y
					--	,t1.m
					--	,t1.model_alarm_id ORDER BY t1.model_alarm_id
					--	) AS month_rank
					,sum(CASE 
							WHEN id IS NOT NULL
								THEN 1
							ELSE 0
							END) OVER (
						PARTITION BY t1.y
						,t1.m
						,t1.model_alarm_id
						) AS month_alarm_cnt
					,sum(CASE 
							WHEN id IS NOT NULL
								THEN 1
							ELSE 0
							END) OVER (
						PARTITION BY t1.y
						,t1.m
						,t1.target_alarm
						) AS month_all_alarm_cnt
					,t1.machine_model_id
					,t1.machine_model_name
					,t1.alarm_code
					,t1.alarm_text_id
					,t1.alarm_text
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
							--,mar.[updated_at]
							,act.machine_model_id
							--,m.name AS machine_model_name
							--,mar.[machine_id]
							--,mm.name AS machine_name
							,act.[model_alarm_id]
							,mar.[alarm_on_at]
							,CONVERT(DATE, dateadd(hour, - @time_offset, mar.[alarm_on_at])) AS alarm_on_day
							--,mar.[alarm_off_at]
							--,mar.[started_at]
							--,mar.[repeat_count]
							,alr.lot_id
							,act.selected_alarm AS selected_alarm
							,act.target_alarm
							,act.seq_id
							,act.machine_model_name
							,act.alarm_code
							,act.alarm_text_id
							,act.alarm_text
						FROM [APCSProDB].[trans].[machine_alarm_records] AS mar WITH (NOLOCK)
						INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
						INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = mar.machine_id
						INNER JOIN APCSProDB.mc.models AS m WITH (NOLOCK) ON m.id = mm.machine_model_id
						INNER JOIN APCSProDB.trans.alarm_lot_records AS alr WITH (NOLOCK) ON alr.id = mar.id
						INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = alr.lot_id
						INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
						LEFT JOIN #alarm_cnt_table AS act ON act.model_alarm_id = mar.model_alarm_id
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
		WHERE t3.seq_id IS NOT NULL
			OR (
				t3.seq_id IS NULL
				AND t3.seq_other = 1
				)
		ORDER BY date_value
			,seq_id
	END
	ELSE
	BEGIN
		---------------- transition duration------------------------
		SELECT CASE 
				WHEN t3.seq_id IS NULL
					THEN t3.num_of_seq_id
				ELSE t3.seq_id
				END AS seq_id
			,t3.day_id
			,t3.date_value
			,t3.y
			,t3.m
			,t3.d
			,t3.quarter_no
			,t3.week_no
			,t3.model_alarm_id
			,t3.selected_alarm
			,t3.target_alarm
			,t3.day_rank
			,CASE 
				WHEN seq_id IS NULL
					THEN t3.day_all_alarm_duration
				ELSE t3.day_alarm_duration
				END AS day_alarm_duration
			,t3.day_all_alarm_duration
			,ROW_NUMBER() OVER (
				PARTITION BY t3.y
				,t3.week_no
				,t3.model_alarm_id ORDER BY t3.model_alarm_id
				) AS week_rank
			,CASE 
				WHEN seq_id IS NULL
					THEN t3.week_all_alarm_duration
				ELSE t3.week_alarm_duration
				END AS week_alarm_duration
			,t3.week_all_alarm_duration
			,ROW_NUMBER() OVER (
				PARTITION BY t3.y
				,t3.m
				,t3.model_alarm_id ORDER BY t3.model_alarm_id
				) AS month_rank
			,CASE 
				WHEN seq_id IS NULL
					THEN t3.month_all_alarm_duration
				ELSE t3.month_alarm_duration
				END AS month_alarm_duration
			,t3.month_all_alarm_duration
			,t3.machine_model_id
			,t3.machine_model_name
			,t3.alarm_code
			,t3.alarm_text_id
			,t3.alarm_text
			,CASE 
				WHEN seq_id IS NULL
					THEN t3.seq_other
				ELSE NULL
				END AS seq_other
			,DATEADD(DAY, 1 - DATEPART(WEEKDAY, t3.date_value), CAST(t3.date_value AS DATE)) AS week_start_day
		FROM (
			SELECT t2.*
				,CASE 
					WHEN t2.seq_id IS NOT NULL
						THEN max(t2.seq_id) OVER (PARTITION BY t2.day_id) + 1
					ELSE NULL
					END AS num_of_seq_id
				,RANK() OVER (
					PARTITION BY t2.day_id
					,t2.target_alarm
					,t2.day_rank ORDER BY t2.model_alarm_id
					) AS seq_other
			FROM (
				SELECT t1.seq_id
					,t1.day_id
					,t1.date_value AS date_value
					,t1.y AS y
					,t1.m AS m
					,t1.d AS d
					,t1.quarter_no AS quarter_no
					,t1.week_no AS week_no
					,t1.model_alarm_id AS model_alarm_id
					--,t1.alarm_text_id AS alarm_text_id
					,t1.selected_alarm AS selected_alarm
					,isnull(t1.target_alarm, 0) AS target_alarm
					--,message_text AS message_text
					--day
					,ROW_NUMBER() OVER (
						PARTITION BY t1.day_id
						,t1.model_alarm_id ORDER BY t1.model_alarm_id
						) AS day_rank
					,sum(t1.alarm_duration) OVER (
						PARTITION BY t1.day_id
						,t1.model_alarm_id
						,t1.target_alarm
						) AS day_alarm_duration
					,sum(t1.alarm_duration) OVER (
						PARTITION BY t1.day_id
						,t1.target_alarm
						) AS day_all_alarm_duration
					--week
					--,ROW_NUMBER() OVER (
					--	PARTITION BY t1.y
					--	,t1.week_no
					--	,t1.model_alarm_id ORDER BY t1.model_alarm_id
					--	) AS week_rank
					,sum(t1.alarm_duration) OVER (
						PARTITION BY t1.y
						,t1.week_no
						,t1.model_alarm_id
						,t1.target_alarm
						) AS week_alarm_duration
					,sum(t1.alarm_duration) OVER (
						PARTITION BY t1.y
						,t1.week_no
						,t1.target_alarm
						) AS week_all_alarm_duration
					--month
					--,ROW_NUMBER() OVER (
					--	PARTITION BY t1.y
					--	,t1.m
					--	,t1.model_alarm_id ORDER BY t1.model_alarm_id
					--	) AS month_rank
					,sum(t1.alarm_duration) OVER (
						PARTITION BY t1.y
						,t1.m
						,t1.model_alarm_id
						,t1.target_alarm
						) AS month_alarm_duration
					,sum(t1.alarm_duration) OVER (
						PARTITION BY t1.y
						,t1.m
						,t1.target_alarm
						) AS month_all_alarm_duration
					,t1.machine_model_id
					,t1.machine_model_name
					,t1.alarm_code
					,t1.alarm_text_id
					,t1.alarm_text
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
							--,mar.[updated_at]
							,adt.machine_model_id
							,adt.[model_alarm_id]
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
							,adt.selected_alarm AS selected_alarm
							,adt.target_alarm
							,adt.seq_id AS seq_id
							,adt.machine_model_name
							,adt.alarm_code
							,adt.alarm_text_id
							,adt.alarm_text
						FROM [APCSProDB].[trans].[machine_alarm_records] AS mar WITH (NOLOCK)
						INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = mar.model_alarm_id
						INNER JOIN APCSProDB.mc.machines AS mm WITH (NOLOCK) ON mm.id = mar.machine_id
						INNER JOIN APCSProDB.mc.models AS m WITH (NOLOCK) ON m.id = mm.machine_model_id
						INNER JOIN APCSProDB.trans.alarm_lot_records AS alr WITH (NOLOCK) ON alr.id = mar.id
						INNER JOIN APCSProDB.trans.lots AS tl WITH (NOLOCK) ON tl.id = alr.lot_id
						INNER JOIN APCSProDB.method.device_names AS dn WITH (NOLOCK) ON dn.id = tl.act_device_name_id
						LEFT JOIN #alarm_duration_table AS adt ON adt.model_alarm_id = mar.model_alarm_id
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
			WHERE day_rank = 1
			) AS t3
		WHERE t3.seq_id IS NOT NULL
			OR (
				t3.seq_id IS NULL
				AND t3.seq_other = 1
				)
		ORDER BY date_value
			,seq_id
	END
END
