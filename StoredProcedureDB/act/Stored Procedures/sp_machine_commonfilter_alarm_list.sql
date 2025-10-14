
CREATE PROCEDURE [act].[sp_machine_commonfilter_alarm_list] @machine_id_list NVARCHAR(max) = NULL
	,@machine_model_id_list NVARCHAR(max) = NULL
	,@alarm_level_a INT = 1
	,@alarm_level_w INT = 1
	,@alarm_level_c INT = 1
AS
BEGIN
	SELECT ac.id AS alarm_id
		,ac.machine_model_id AS machine_model_id
		,mm.name AS machine_model_name
		,ac.alarm_level AS alarm_level
		,il.label_eng AS alarm_level_eng
		,il.label_jpn AS alarm_level_jpn
		,ac.code AS alarm_code
		,ax.alarm_text AS alarm_text
	FROM APCSProDWH.dwh.dim_alarm_codes AS ac WITH (NOLOCK)
	INNER JOIN APCSProDWH.dwh.dim_machine_models AS mm WITH (NOLOCK) ON mm.id = ac.machine_model_id
	LEFT OUTER JOIN APCSProDB.mc.alarm_texts AS ax WITH (NOLOCK) ON ac.alarm_text_id = ax.alarm_text_id
	LEFT OUTER JOIN APCSProDB.mc.item_labels AS il WITH (NOLOCK) ON il.name = 'model_alarms.alarm_level'
		AND il.val = ac.alarm_level
	WHERE (
			(
				(
					(@machine_model_id_list IS NOT NULL)
					OR (@machine_model_id_list <> '')
					)
				AND (',' + @machine_model_id_list + ',' LIKE '%,' + cast(ac.machine_model_id AS VARCHAR) + ',%')
				)
			OR (
				(@machine_model_id_list IS NULL)
				OR (@machine_model_id_list = '')
				)
			)
		AND (
			(
				@alarm_level_a = 1
				AND ac.alarm_level = 0
				)
			OR (
				@alarm_level_w = 1
				AND ac.alarm_level = 1
				)
			OR (
				@alarm_level_c = 1
				AND ac.alarm_level = 2
				)
			)
	ORDER BY machine_model_id
		,alarm_code
END
