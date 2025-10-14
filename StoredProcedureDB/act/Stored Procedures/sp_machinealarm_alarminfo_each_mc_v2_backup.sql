
CREATE PROCEDURE [act].[sp_machinealarm_alarminfo_each_mc_v2_backup] (
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
	--DECLARE @include_selected_alarm BIT = 1
	--DECLARE @time_offset int = 0
	--DECLARE @alarm_level_alarm INT = 1
	--DECLARE @alarm_level_warning INT = 1
	--DECLARE @alarm_level_caution INT = 1
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
						ORDER BY fn.rank_percent_alarm_cnt
						) AS alarm_ids
				FROM [act].fnc_machinealarm_alarm_top_rank_v2(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @local_date_from, @local_date_to, @machine_id_list, @alarm_level, @alarm_level_alarm, @alarm_level_warning, @alarm_level_caution, @alarm_id_list, @top_num, @unit_type_duration, @include_selected_alarm, @lot_id, @process_job_id) AS fn
				);
	END
	ELSE
	BEGIN
		SET @top_alarm_ids = (
				SELECT string_agg(fn.alarm_id_duration, ',') within
				GROUP (
						ORDER BY fn.rank_percent_alarm_duration
						) AS alarm_ids
				FROM [act].fnc_machinealarm_alarm_top_rank_v2(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @local_date_from, @local_date_to, @machine_id_list, @alarm_level, @alarm_level_alarm, @alarm_level_warning, @alarm_level_caution, @alarm_id_list, @top_num, @unit_type_duration, @include_selected_alarm, @lot_id, @process_job_id) AS fn
				);
	END

	SELECT row_number() OVER (
			ORDER BY t.all_alarm_cnt_per_mc DESC
				,t.machine_id
				,t.model_alarm_id
			) AS pid
		,CASE 
			WHEN @unit_type_duration = 0
				THEN tai.rank_percent_alarm_cnt
			ELSE tai2.rank_percent_alarm_duration
			END AS pid_mc
		,@top_alarm_ids AS top_alarm_ids
		,t.alarm_code AS alarm_code
		,t.alarm_text_id AS alarm_text_id
		,t.alarm_level AS alarm_level
		,t.machine_id AS machine_id
		,t.machine_name AS machine_name
		,t.machine_model_id as machine_model_id
		,t.message_text AS message_text
		,t.sum_alarm_cnt_per_mc AS sum_alarm_cnt_per_mc
		,t.sum_alarm_duration_per_mc AS sum_alarm_duration_per_mc
		,t.all_alarm_cnt_per_mc AS all_alarm_cnt_per_mc
		,t.all_alarm_duration_per_mc AS all_alarm_duration_per_mc
		,t.not_selected_alarm_cnt_per_mc AS not_selected_alarm_cnt_per_mc
		,t.not_selected_alarm_duration_per_mc AS not_selected_alarm_duration_per_mc
		,max(t.all_alarm_duration_per_mc) OVER () AS max_alarm_duration_all
	FROM (
		SELECT series.machine_id AS machine_id
			,series.machine_name AS machine_name
			,series.machine_model_id AS machine_model_id
			,series.machine_model_name AS machine_model_name
			,series.selected_alarm AS selected_alarm
			,series.alarm_id_cnt AS model_alarm_id
			,series.alarm_code AS alarm_code
			,series.alarm_level AS alarm_level
			,series.alarm_text_id AS alarm_text_id
			,CASE 
				WHEN series.message_text = ''
					THEN series.machine_model_name + '*' + series.alarm_code
				ELSE series.message_text
				END AS message_text
			,a_data.id
			,isnull(a_data.sum_alarm_cnt_per_mc, 0) AS sum_alarm_cnt_per_mc
			,isnull(a_data.sum_alarm_duration_per_mc, 0) AS sum_alarm_duration_per_mc
			,max(isnull(a_data.all_alarm_cnt_per_mc, 0)) OVER (PARTITION BY series.machine_id) AS all_alarm_cnt_per_mc
			,max(isnull(a_data.all_alarm_duration_per_mc, 0)) OVER (PARTITION BY series.machine_id) AS all_alarm_duration_per_mc
			,max(isnull(a_data.not_selected_alarm_cnt_per_mc, 0)) OVER (PARTITION BY series.machine_id) AS not_selected_alarm_cnt_per_mc
			,max(isnull(a_data.not_selected_alarm_duration_per_mc, 0)) OVER (PARTITION BY series.machine_id) AS not_selected_alarm_duration_per_mc
		FROM (
			SELECT fn.alarm_id_cnt
				,fn.selected_alarm
				,v.machine_id
				,dm.name AS machine_name
				,dm.machine_model_id AS machine_model_id
				,mm.name AS machine_model_name
				,ma.alarm_code AS alarm_code
				,ma.alarm_level AS alarm_level
				,ma.alarm_text_id AS alarm_text_id
				,atx.message_text AS message_text
			FROM [act].fnc_machinealarm_alarm_top_rank_v2(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @local_date_from, @local_date_to, @machine_id_list, @alarm_level, @alarm_level_alarm, @alarm_level_warning, @alarm_level_caution, @alarm_id_list, @top_num, @unit_type_duration, @include_selected_alarm, @lot_id, @process_job_id) AS fn
			CROSS JOIN (
				SELECT convert(INT, value) AS machine_id
				FROM STRING_SPLIT(@machine_id_list, ',')
				) AS v
			INNER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = v.machine_id
			INNER JOIN APCSProDWH.dwh.dim_machine_models AS mm WITH (NOLOCK) ON mm.id = dm.machine_model_id
			INNER JOIN APCSProDB.mc.model_alarms AS ma WITH (NOLOCK) ON ma.id = fn.alarm_id_cnt
			LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_texts AS atx WITH (NOLOCK) ON atx.id = ma.alarm_text_id
			) AS series
		LEFT OUTER JOIN (
			SELECT t4.*
			FROM (
				SELECT t3.id
					,t3.machine_id
					,t3.machine_name
					,t3.model_alarm_id
					--,t3.alarm_text_id
					,t3.selected_alarm
					,t3.sum_alarm_cnt_per_mc
					,t3.sum_alarm_duration_per_mc
					,t3.all_alarm_cnt_per_mc
					,t3.all_alarm_duration_per_mc
					,sum((
							CASE 
								WHEN t3.selected_alarm = 1
									THEN 0
								ELSE 1
								END
							) * t3.sum_alarm_cnt_per_mc) OVER (PARTITION BY t3.machine_id) AS not_selected_alarm_cnt_per_mc
					,sum((
							CASE 
								WHEN t3.selected_alarm = 1
									THEN 0
								ELSE 1
								END
							) * t3.sum_alarm_duration_per_mc) OVER (PARTITION BY t3.machine_id) AS not_selected_alarm_duration_per_mc
				FROM (
					SELECT t2.*
						,CASE 
							WHEN (
									(@top_alarm_ids IS NOT NULL)
									OR (@top_alarm_ids <> '')
									)
								AND (',' + @top_alarm_ids + ',' LIKE '%,' + cast(t2.model_alarm_id AS VARCHAR) + ',%')
								THEN 1
							WHEN (
									(@top_alarm_ids IS NULL)
									OR (@top_alarm_ids = '')
									)
								THEN 1
							ELSE 0
							END AS selected_alarm
					FROM (
						SELECT t1.*
							,ROW_NUMBER() OVER (
								PARTITION BY t1.machine_id
								,t1.model_alarm_id ORDER BY t1.id
								) AS rank_machine_alarm
							,count(1) OVER (
								PARTITION BY t1.machine_id
								,t1.model_alarm_id
								) AS sum_alarm_cnt_per_mc
							,count(1) OVER (PARTITION BY t1.machine_id) AS all_alarm_cnt_per_mc
							,sum(t1.alarm_duration) OVER (
								PARTITION BY t1.machine_id
								,t1.model_alarm_id
								) AS sum_alarm_duration_per_mc
							,sum(t1.alarm_duration) OVER (PARTITION BY t1.machine_id) AS all_alarm_duration_per_mc
						FROM (
							SELECT mar.*
								,dm.name AS machine_name
								,isnull(convert(DECIMAL(18, 1), datediff_big(SECOND, mar.alarm_on_at, CASE 
												WHEN mar.alarm_off_at > @local_date_to
													THEN @local_date_to
												ELSE CASE 
														--1900/01/01 00:00:00対策
														WHEN mar.alarm_on_at < mar.alarm_off_at
															THEN mar.alarm_off_at
														WHEN mar.alarm_on_at < mar.started_at
															THEN mar.started_at
														ELSE mar.updated_at
														END
												END)) / 60 / 60, NULL) AS alarm_duration
							FROM APCSProDB.trans.machine_alarm_records AS mar WITH (NOLOCK)
							--LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_codes AS ac WITH (NOLOCK) ON ac.id = mar.model_alarm_id
							INNER JOIN APCSProDWH.dwh.dim_machines AS dm WITH (NOLOCK) ON dm.id = mar.machine_id
							LEFT OUTER JOIN APCSProDWH.dwh.dim_machine_models AS mm WITH (NOLOCK) ON mm.id = dm.machine_model_id
							LEFT OUTER JOIN APCSProDB.mc.model_alarms AS ac WITH (NOLOCK) ON ac.id = mar.model_alarm_id
							LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_texts AS ax WITH (NOLOCK) ON ax.id = ac.alarm_text_id
							LEFT OUTER JOIN APCSProDWH.dwh.dim_alarm_levels AS al WITH (NOLOCK) ON al.code = ac.alarm_level
							INNER JOIN APCSProDB.trans.alarm_lot_records AS alr WITH (NOLOCK) ON alr.id = mar.id
							WHERE (
									@local_date_from <= mar.alarm_on_at
									AND mar.alarm_on_at <= @local_date_to
									)
								AND machine_id IN (
									SELECT value
									FROM STRING_SPLIT(@machine_id_list, ',')
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
						) AS t2
					WHERE rank_machine_alarm = 1
					) AS t3
				) AS t4
			WHERE selected_alarm = 1
			) AS a_data ON a_data.model_alarm_id = series.alarm_id_cnt
			AND a_data.machine_id = series.machine_id
		) AS t
	LEFT OUTER JOIN [act].fnc_machinealarm_alarm_top_rank_v2(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @local_date_from, @local_date_to, @machine_id_list, @alarm_level, @alarm_level_alarm, @alarm_level_warning, @alarm_level_caution, @alarm_id_list, @top_num, @unit_type_duration, @include_selected_alarm, @lot_id, @process_job_id) AS tai ON tai.alarm_id_cnt = t.model_alarm_id
		AND @unit_type_duration = 0
	LEFT OUTER JOIN [act].fnc_machinealarm_alarm_top_rank_v2(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @local_date_from, @local_date_to, @machine_id_list, @alarm_level, @alarm_level_alarm, @alarm_level_warning, @alarm_level_caution, @alarm_id_list, @top_num, @unit_type_duration, @include_selected_alarm, @lot_id, @process_job_id) AS tai2 ON tai2.alarm_id_duration = t.model_alarm_id
		AND @unit_type_duration = 1
	ORDER BY pid
END
