
CREATE PROCEDURE [act].[sp_machinealarm_alarminfo_transition_v3] (
	@package_group_id INT = NULL
	,@package_id INT = NULL
	,@process_id INT = NULL
	,@job_id INT = NULL
	,@device_id INT = NULL
	,@device_name VARCHAR(20) = NULL
	,@date_from DATETIME
	,@date_to DATETIME
	,@machine_id_list NVARCHAR(max) = NULL
	,@alarm_level INT = NULL
	,@alarm_level_alarm INT = 0
	,@alarm_level_warning INT = 0
	,@alarm_level_caution INT = 0
	,@alarm_id_list NVARCHAR(max) = NULL
	,@top_num INT = 5
	,@unit_type_duration BIT = 0
	,@include_selected_alarm BIT = 1
	,@lot_id INT = NULL
	,@process_job_id INT = NULL
	,@time_offset INT = 0
	,@id_from BIGINT = 0
	,@id_to BIGINT = 0
	)
AS
BEGIN
	--DECLARE @package_group_id INT = NULL
	--DECLARE @package_id INT = NULL
	--DECLARE @process_id INT = NULL
	--DECLARE @job_id INT = NULL
	--DECLARE @device_id INT = NULL
	--DECLARE @device_name VARCHAR(20) = NULL
	--DECLARE @machine_id_list NVARCHAR(max) = '473'
	--DECLARE @date_from DATETIME = '2022-09-27 00:00:00'
	--DECLARE @date_to DATETIME = '2022-09-29 00:00:00'
	--DECLARE @alarm_level INT = NULL
	--DECLARE @alarm_id_list NVARCHAR(max) = NULL
	--DECLARE @top_num INT = 5
	--DECLARE @unit_type_duration BIT = 1
	--DECLARE @alarm_level_alarm INT = 1
	--DECLARE @alarm_level_warning INT = 0
	--DECLARE @alarm_level_caution INT = 0
	--DECLARE @time_offset INT = 8
	--DECLARE @id_from BIGINT = 0
	--DECLARE @id_to BIGINT = 0
	--DECLARE @include_selected_alarm BIT = 1
	--DECLARE @lot_id INT = NULL
	--DECLARE @process_job_id INT = NULL
	--
	DECLARE @local_date_from DATETIME = dateadd(hour, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = dateadd(hour, @time_offset, @date_to)
	DECLARE @top_alarm_ids NVARCHAR(max) = ''

	SET @alarm_level = @alarm_level_alarm + @alarm_level_warning + @alarm_level_caution;

	IF @unit_type_duration = 0
	BEGIN
		SET @top_alarm_ids = (
				SELECT string_agg(fn.alarm_id_cnt, ',') within
				GROUP (
						ORDER BY fn.alarm_id_cnt
						) AS alarm_ids
				FROM [act].fnc_machinealarm_alarm_top_rank_v2(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @local_date_from, @local_date_to, @machine_id_list, @alarm_level, @alarm_level_alarm, @alarm_level_warning, @alarm_level_caution, @alarm_id_list, @top_num, @unit_type_duration, @include_selected_alarm, @lot_id, @process_job_id, @id_from, @id_to) AS fn
				);
	END
	ELSE
	BEGIN
		SET @top_alarm_ids = (
				SELECT string_agg(fn.alarm_id_duration, ',') within
				GROUP (
						ORDER BY fn.alarm_id_duration
						) AS alarm_ids
				FROM [act].fnc_machinealarm_alarm_top_rank_v2(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @local_date_from, @local_date_to, @machine_id_list, @alarm_level, @alarm_level_alarm, @alarm_level_warning, @alarm_level_caution, @alarm_id_list, @top_num, @unit_type_duration, @include_selected_alarm, @lot_id, @process_job_id, @id_from, @id_to) AS fn
				);
	END

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

	IF OBJECT_ID(N'tempdb..#data_table', N'U') IS NOT NULL
		DROP TABLE #data_table;

	SELECT t1.id
		,t1.updated_at
		,t1.machine_id
		,t1.machine_name
		,t1.machine_model_id AS machine_model_id
		,t1.machine_model_name AS machine_model_name
		,t1.model_alarm_id
		,t1.new_alarm_on_at
		,t1.new_alarm_off_at
		,t1.new_started_at
		,CASE 
			WHEN new_alarm_on <> new_alarm_off
				THEN 1
			ELSE 0
			END AS change_day_flag
		,CASE 
			WHEN new_alarm_on <> new_alarm_off
				THEN DATEADD(DAY, DATEDIFF(DAY, 0, t1.new_alarm_off_at), 0)
			ELSE NULL
			END AS std_datetime_at
		,alarm_code AS alarm_code
		,alarm_text_id AS alarm_text_id
		,selected_alarm AS selected_alarm
	INTO #data_table
	FROM (
		SELECT mar.id
			,mar.updated_at
			,mar.machine_id
			,dm.name AS machine_name
			,mar.model_alarm_id
			,dm.machine_model_id AS machine_model_id
			,mm.name AS machine_model_name
			,DATEadd(HOUR, - @time_offset, mar.alarm_on_at) AS new_alarm_on_at
			,convert(DATE, DATEadd(HOUR, - @time_offset, mar.alarm_on_at)) AS new_alarm_on
			,DATEadd(HOUR, - @time_offset, mar.alarm_off_at) AS new_alarm_off_at
			,convert(DATE, DATEadd(HOUR, - @time_offset, mar.alarm_off_at)) AS new_alarm_off
			,DATEadd(HOUR, - @time_offset, mar.started_at) AS new_started_at
			,ac.alarm_code AS alarm_code
			,ac.alarm_text_id
			,CASE 
				WHEN (
						(@top_alarm_ids IS NOT NULL)
						OR (@top_alarm_ids <> '')
						)
					AND (',' + @top_alarm_ids + ',' LIKE '%,' + cast(ac.id AS VARCHAR) + ',%')
					THEN 1
				WHEN (
						(@top_alarm_ids IS NULL)
						OR (@top_alarm_ids = '')
						)
					THEN 1
				ELSE 0
				END AS selected_alarm
		FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
		INNER JOIN APCSProDB.mc.machines AS dm WITH (NOLOCK) ON dm.id = mar.machine_id
		LEFT OUTER JOIN APCSProDB.mc.models AS mm WITH (NOLOCK) ON mm.id = dm.machine_model_id
		LEFT OUTER JOIN APCSProDB.mc.model_alarms AS ac WITH (NOLOCK) ON ac.id = mar.model_alarm_id
		LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_levels AS al WITH (NOLOCK) ON al.code = ac.alarm_level
		LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_texts AS atx WITH (NOLOCK) ON atx.id = ac.alarm_text_id
		WHERE mar.machine_id IN (
				SELECT value
				FROM STRING_SPLIT(@machine_id_list, ',')
				)
			AND (
				@local_date_from <= mar.alarm_on_at
				AND mar.alarm_on_at <= @local_date_to
				)
			AND (
				(
					@alarm_level > 0
					AND (
						(
							@alarm_level_alarm > 0
							AND ac.alarm_level = 0
							)
						OR (
							@alarm_level_warning > 0
							AND ac.alarm_level = 1
							)
						OR (
							@alarm_level_caution > 0
							AND ac.alarm_level = 2
							)
						)
					)
				OR (
					@alarm_level = 0
					AND ac.alarm_level >= 0
					)
				)
		) AS t1

	--------------------------------------------
	SELECT row_number() OVER (
			PARTITION BY t4.day_id ORDER BY t4.model_alarm_id
			) AS pid_day
		,t4.*
		,DATEADD(DAY, 1 - DATEPART(WEEKDAY, t4.date_value), CAST(t4.date_value AS DATE)) AS week_start_day
	FROM (
		SELECT t3.*
		FROM (
			SELECT t2.day_id
				,t2.date_value AS date_value
				,t2.y AS y
				,t2.m AS m
				,t2.d AS d
				,t2.quarter_no AS quarter_no
				,t2.week_no AS week_no
				,t2.model_alarm_id AS model_alarm_id
				,t2.alarm_text_id AS alarm_text_id
				,t2.selected_alarm AS selected_alarm
				,message_text AS message_text
				--day
				,ROW_NUMBER() OVER (
					PARTITION BY t2.day_id
					,t2.model_alarm_id ORDER BY t2.model_alarm_id
					) AS day_rank
				,sum(1 * isnull(t2.selected_alarm, 0)) OVER (
					PARTITION BY t2.day_id
					,t2.model_alarm_id
					) AS day_alarm_cnt
				,sum(1 * CASE 
						WHEN t2.selected_alarm = 0
							THEN 1
						ELSE 0
						END) OVER (PARTITION BY t2.day_id) AS not_selected_day_alarm_cnt
				,sum(t2.alarm_duration * isnull(t2.selected_alarm, 0)) OVER (
					PARTITION BY t2.day_id
					,t2.model_alarm_id
					) AS day_alarm_duration
				,sum(t2.alarm_duration * CASE 
						WHEN t2.selected_alarm = 0
							THEN 1
						ELSE 0
						END) OVER (PARTITION BY t2.day_id) AS not_selected_day_alarm_duration
				,sum(t2.alarm_duration) OVER (PARTITION BY t2.day_id) AS day_all_alarm_duration
				,
				--week
				ROW_NUMBER() OVER (
					PARTITION BY t2.y
					,t2.week_no
					,t2.model_alarm_id ORDER BY t2.model_alarm_id
					) AS week_rank
				,sum(1 * isnull(t2.selected_alarm, 0)) OVER (
					PARTITION BY t2.y
					,t2.week_no
					,t2.model_alarm_id
					) AS week_alarm_cnt
				,sum(1 * CASE 
						WHEN t2.selected_alarm = 0
							THEN 1
						ELSE 0
						END) OVER (
					PARTITION BY t2.y
					,t2.week_no
					) AS not_selected_week_alarm_cnt
				,sum(t2.alarm_duration * isnull(t2.selected_alarm, 0)) OVER (
					PARTITION BY t2.y
					,t2.week_no
					,t2.model_alarm_id
					) AS week_alarm_duration
				,sum(t2.alarm_duration * CASE 
						WHEN t2.selected_alarm = 0
							THEN 1
						ELSE 0
						END) OVER (
					PARTITION BY t2.y
					,t2.week_no
					) AS not_selected_week_alarm_duration
				,sum(t2.alarm_duration) OVER (
					PARTITION BY t2.y
					,t2.week_no
					) AS week_all_alarm_duration
				,
				--month
				ROW_NUMBER() OVER (
					PARTITION BY t2.y
					,t2.m
					,t2.model_alarm_id ORDER BY t2.model_alarm_id
					) AS month_rank
				,sum(1 * isnull(t2.selected_alarm, 0)) OVER (
					PARTITION BY t2.y
					,t2.m
					,t2.model_alarm_id
					) AS month_alarm_cnt
				,sum(1 * CASE 
						WHEN t2.selected_alarm = 0
							THEN 1
						ELSE 0
						END) OVER (
					PARTITION BY t2.y
					,t2.m
					) AS not_selected_month_alarm_cnt
				,sum(t2.alarm_duration * isnull(t2.selected_alarm, 0)) OVER (
					PARTITION BY t2.y
					,t2.m
					,t2.model_alarm_id
					) AS month_alarm_duration
				,sum(t2.alarm_duration * CASE 
						WHEN t2.selected_alarm = 0
							THEN 1
						ELSE 0
						END) OVER (
					PARTITION BY t2.y
					,t2.m
					) AS not_selected_month_alarm_duration
				,sum(t2.alarm_duration) OVER (
					PARTITION BY t2.y
					,t2.m
					) AS month_all_alarm_duration
			FROM (
				SELECT dd.id AS day_id
					,dd.date_value AS date_value
					,dd.y AS y
					,dd.m AS m
					,dd.d AS d
					,dd.quarter_no AS quarter_no
					,dd.week_no AS week_no
					,alm2.machine_id AS machine_id
					,alm2.machine_name
					,alm2.machine_model_id
					,alm2.machine_model_name
					,alm2.model_alarm_id AS model_alarm_id
					,alm2.alarm_text_id AS alarm_text_id
					,CASE 
						WHEN atx.message_text = ''
							THEN alm2.machine_model_name + '*' + alm2.alarm_code
						ELSE atx.message_text
						END AS message_text
					,alm2.alarm_duration AS alarm_duration
					,alm2.alarm_on_at AS alarm_on_at
					,alm2.alarm_off_at AS alarm_off_at
					,alm2.selected_alarm AS selected_alarm
				FROM (
					SELECT *
					FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
					WHERE @from <= id
						AND id < @to
					) AS dd
				LEFT JOIN (
					SELECT alm.machine_id
						,alm.machine_name
						,alm.machine_model_id
						,alm.machine_model_name
						,alm.model_alarm_id
						,convert(DATE, alm.alarm_on_at) AS alarm_on
						,alm.alarm_on_at
						,alm.alarm_off_at
						,alm.alarm_code AS alarm_code
						,alm.alarm_text_id AS alarm_text_id
						,alm.selected_alarm AS selected_alarm
						,isnull(convert(DECIMAL(18, 1), datediff_big(SECOND, alm.alarm_on_at, alm.alarm_off_at)) / 60 / 60, NULL) AS alarm_duration
					FROM (
						SELECT dt1.machine_id
							,dt1.machine_name
							,dt1.machine_model_id
							,dt1.machine_model_name
							,dt1.model_alarm_id
							,dt1.new_alarm_on_at AS alarm_on_at
							,CASE 
								WHEN dt1.change_day_flag = 1
									THEN dt1.std_datetime_at
								ELSE dt1.new_alarm_off_at
								END AS alarm_off_at
							,dt1.alarm_code AS alarm_code
							,dt1.alarm_text_id AS alarm_text_id
							,dt1.selected_alarm
						FROM #data_table AS dt1
						
						UNION ALL
						
						SELECT dt2.machine_id
							,dt2.machine_name
							,dt2.machine_model_id
							,dt2.machine_model_name
							,dt2.model_alarm_id
							,CASE 
								WHEN dt2.change_day_flag = 1
									THEN dt2.std_datetime_at
								ELSE dt2.new_alarm_on_at
								END AS alarm_on_at
							,dt2.new_alarm_off_at AS alarm_off_at
							,dt2.alarm_code AS alarm_code
							,dt2.alarm_text_id AS alarm_text_id
							,dt2.selected_alarm
						FROM #data_table AS dt2
						WHERE change_day_flag = 1
						) AS alm
					) AS alm2 ON alm2.alarm_on = dd.date_value
				LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_texts AS atx WITH (NOLOCK) ON atx.id = alm2.alarm_text_id
				) AS t2
			) AS t3
		WHERE t3.day_rank = 1
		) AS t4
	ORDER BY date_value
END
