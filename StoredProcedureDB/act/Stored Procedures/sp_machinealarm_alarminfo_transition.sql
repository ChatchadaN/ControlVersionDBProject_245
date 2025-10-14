
CREATE PROCEDURE [act].[sp_machinealarm_alarminfo_transition] (
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
	)
AS
BEGIN
	--DECLARE @package_group_id INT = NULL
	--DECLARE @package_id INT = NULL
	--DECLARE @process_id INT = NULL
	--DECLARE @job_id INT = NULL
	--DECLARE @device_id INT = NULL
	--DECLARE @device_name VARCHAR(20) = NULL
	--DECLARE @machine_id_list NVARCHAR(max) = '13,18,19,303'
	--DECLARE @date_from DATETIME = '2019-09-01 00:00:00'
	--DECLARE @date_to DATETIME = '2019-09-02 00:00:00'
	--DECLARE @alarm_level INT = NULL
	--DECLARE @alarm_id_list NVARCHAR(max) = '1105,1106,1107,1109,1108,1110,1111,1112,1113,1114,1187,1578'
	--DECLARE @top_num INT = 5
	--DECLARE @unit_type_duration BIT = 0
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
				FROM [act].fnc_machinealarm_alarm_top_rank(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @local_date_from, @local_date_to, @machine_id_list, @alarm_level, @alarm_level_alarm, @alarm_level_warning, @alarm_level_caution, @alarm_id_list, @top_num, @unit_type_duration, @include_selected_alarm, @lot_id, @process_job_id) AS fn
				);
	END
	ELSE
	BEGIN
		SET @top_alarm_ids = (
				SELECT string_agg(fn.alarm_id_duration, ',') within
				GROUP (
						ORDER BY fn.alarm_id_duration
						) AS alarm_ids
				FROM [act].fnc_machinealarm_alarm_top_rank(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @local_date_from, @local_date_to, @machine_id_list, @alarm_level, @alarm_level_alarm, @alarm_level_warning, @alarm_level_caution, @alarm_id_list, @top_num, @unit_type_duration, @include_selected_alarm, @lot_id, @process_job_id) AS fn
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
				,t2.selected_alarm AS selected_alarm
				,message_text AS message_text
				,
				--t2.alarm_on_at AS alarm_on_at,
				--t2.alarm_off_at AS alarm_off_at,
				--t2.started_at AS started_at,
				--day
				ROW_NUMBER() OVER (
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
				,sum(t2.alarm_duration) OVER (
					PARTITION BY t2.day_id
					,t2.model_alarm_id
					) AS day_alarm_duration
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
						END) OVER (PARTITION BY t2.week_no) AS not_selected_week_alarm_cnt
				,sum(t2.alarm_duration) OVER (
					PARTITION BY t2.y
					,t2.week_no
					,t2.model_alarm_id
					) AS week_alarm_duration
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
				,sum(t2.alarm_duration) OVER (
					PARTITION BY t2.y
					,t2.m
					,t2.model_alarm_id
					) AS month_alarm_duration
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
					,t1.machine_id AS machine_id
					,t1.model_alarm_id AS model_alarm_id
					,atx.message_text AS message_text
					,t1.alarm_duration AS alarm_duration
					,t1.alarm_on_at AS alarm_on_at
					,t1.alarm_off_at AS alarm_off_at
					,t1.started_at AS started_at
					,t1.selected_alarm AS selected_alarm
				FROM (
					SELECT *
					FROM APCSProDWH.dwh.dim_days WITH (NOLOCK)
					WHERE @from <= id
						AND id <= @to
					) AS dd
				LEFT OUTER JOIN (
					SELECT t.*
						,isnull(convert(DECIMAL(18, 1), datediff_big(SECOND, t.alarm_on_at, CASE 
										WHEN t.alarm_off_at > @local_date_to
											THEN @local_date_to
										ELSE
											--1900/01/01 00:00:00対策
											CASE 
												WHEN t.alarm_on_at < t.alarm_off_at
													THEN t.alarm_off_at
												ELSE t.updated_at
												END
										END)) / 60 / 60, NULL) AS alarm_duration
						,CONVERT(DATE, t.alarm_on_at) AS alarm_on_at_day
					FROM (
						SELECT mar.id
							,mar.updated_at
							,mar.machine_id
							,mar.model_alarm_id
							,mar.alarm_on_at
							,mar.alarm_off_at
							,CASE 
								WHEN (
										mar.alarm_on_at IS NOT NULL
										AND mar.started_at IS NULL
										)
									THEN mar.updated_at
								ELSE mar.started_at
								END AS started_at
							,CASE 
								WHEN (
										(@top_alarm_ids IS NOT NULL)
										OR (@top_alarm_ids <> '')
										)
									AND (',' + @top_alarm_ids + ',' LIKE '%,' + cast(mar.model_alarm_id AS VARCHAR) + ',%')
									THEN 1
								WHEN (
										(@top_alarm_ids IS NULL)
										OR (@top_alarm_ids = '')
										)
									THEN 1
								ELSE 0
								END AS selected_alarm
						FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
						LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_codes AS ac WITH (NOLOCK) ON ac.id = mar.model_alarm_id
						WHERE mar.machine_id IN (
								SELECT value
								FROM STRING_SPLIT(@machine_id_list, ',')
								)
							AND (
								@local_date_from <= mar.alarm_on_at
								AND mar.alarm_on_at <= @date_to
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
						) AS t
					) AS t1 ON t1.alarm_on_at_day = dd.date_value
				LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_texts AS atx WITH (NOLOCK) ON atx.id = t1.model_alarm_id
				) AS t2
			) AS t3
		WHERE t3.day_rank = 1
		) AS t4
	ORDER BY date_value
END
