
CREATE PROCEDURE [act].[sp_machinealarm_pareto_01_v2] (
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
	,@alarm_level_alarm INT = 1
	,@alarm_level_warning INT = 1
	,@alarm_level_caution INT = 1
	,@alarm_id_list NVARCHAR(max) = NULL
	,@top_num INT = 5
	,@unit_type_duration BIT = 0
	,@include_selected_alarm BIT = 0
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
	--DECLARE @machine_id_list NVARCHAR(max) = '13,18,19,303'
	--DECLARE @date_from DATETIME = '2019-09-01 00:00:00'
	--DECLARE @date_to DATETIME = '2019-09-30 00:00:00'
	--DECLARE @alarm_level INT = NULL
	--DECLARE @alarm_id_list NVARCHAR(max) = '1105,1106,1107,1109,1108,1110,1111,1112,1113,1114,1187,1578'
	--DECLARE @top_num INT = 9
	--DECLARE @unit_type_duration BIT = 1
	--declare @alarm_level_alarm int = 1
	--declare @alarm_level_warning int = 1
	--declare @alarm_level_caution int = 0
	--DECLARE @time_offset INT = 0
	--DECLARE @lot_id INT = 345711
	--DECLARE @process_job_id INT = NULL
	--DECLARE @include_selected_alarm INT = 0
	--DECLARE @id_from BIGINT = 27511002
	--DECLARE @id_to BIGINT = 27535448
	DECLARE @local_date_from DATETIME = dateadd(hour, @time_offset, @date_from)
	DECLARE @local_date_to DATETIME = dateadd(hour, @time_offset, @date_to)

	SET @alarm_level = @alarm_level_alarm + @alarm_level_warning + @alarm_level_caution;

	SELECT *
	FROM [act].fnc_machinealarm_alarm_top_rank_v2(@package_group_id, @package_id, @process_id, @job_id, @device_id, @device_name, @local_date_from, @local_date_to, @machine_id_list, @alarm_level, @alarm_level_alarm, @alarm_level_warning, @alarm_level_caution, @alarm_id_list, @top_num, @unit_type_duration, @include_selected_alarm, @lot_id, @process_job_id, @id_from, @id_to)
	ORDER BY CASE 
			WHEN @unit_type_duration = 0
				THEN rank_percent_alarm_cnt
			ELSE rank_percent_alarm_duration
			END
END
