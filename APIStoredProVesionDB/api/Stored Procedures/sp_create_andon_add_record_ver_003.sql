-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_create_andon_add_record_ver_003]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
	,	@process_id int
	,	@machine_id int
	,	@comment_id int
	,	@line_no varchar(max)
	,	@equipment_no varchar(max)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @user_id INT;
	DECLARE @lot_id INT;
	DECLARE @lot_day_id INT;
	DECLARE @lot_process_record_id INT;
	DECLARE @lot_hold_control_id INT;
	DECLARE @andon_control_id INT;
	DECLARE @rohm_date_start datetime = convert(datetime,convert(varchar(10), GETDATE(), 120))
	DECLARE @rohm_date_end datetime = convert(datetime,convert(varchar(10), GETDATE(), 120) + ' 08:00:00')
	DECLARE @date_value_form datetime
	DECLARE @date_value_to datetime
	DECLARE @display_count int
	DECLARE @abnormal_count int
	DECLARE @process_name VARCHAR(MAX)
	DECLARE @machine_name VARCHAR(MAX)
	DECLARE @package_name VARCHAR(MAX)
	DECLARE @device_name VARCHAR(MAX)
	DECLARE @abnormal_mode VARCHAR(MAX)
	DECLARE @mode int = 0

	IF((GETDATE() >= @rohm_date_start) AND (GETDATE() < @rohm_date_end))
	BEGIN
		SET @date_value_form = convert(datetime,convert(varchar(10), GETDATE() - 1, 120) + ' 08:00:00')
		SET @date_value_to = convert(datetime,convert(varchar(10), GETDATE(), 120) + ' 08:00:00')
	END
	ELSE
	BEGIN
		SET @date_value_form = convert(datetime,convert(varchar(10), GETDATE(), 120) + ' 08:00:00')
		SET @date_value_to = convert(datetime,convert(varchar(10), GETDATE() + 1, 120) + ' 08:00:00')
	END

	SELECT @user_id = [id]
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @username

	SELECT @machine_name = [name]
	FROM [APCSProDB].[mc].[machines]
	WHERE [machines].[id] = @machine_id

	SELECT @process_name = [name]
	FROM [APCSProDB].[method].[processes]
	WHERE [processes].[id] = @process_id

	SELECT @lot_id = [lots].[id]
	, @package_name = [packages].[name]
	, @device_name = [device_names].[name]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
	WHERE [lots].[lot_no] = @lot_no

	SELECT @lot_day_id = [id]
	FROM [APCSProDB].[trans].[days]
	WHERE [date_value] = CONVERT(DATE,GETDATE());

	UPDATE [APCSProDB].[trans].[lots]
	SET [quality_state] = 1
	WHERE [lot_no] = @lot_no
	AND [quality_state] = 0;

	---- [sp_create_andon_add_record_ver_002]
	--- Start Update quality state special flow <kpanomsai> 2022-07-27
	IF EXISTS(SELECT 1 FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no AND [is_special_flow] = 1)
	BEGIN
		UPDATE [APCSProDB].[trans].[special_flows] 
		SET [special_flows].[quality_state] = 1
		FROM [APCSProDB].[trans].[special_flows] 
		INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[is_special_flow] = 1
		AND [lots].[special_flow_id]  = [special_flows].[id]
		WHERE [lots].[lot_no] = @lot_no
		AND [special_flows].[quality_state] = 0;
	END
	--- End Update quality state special flow <kpanomsai> 2022-07-27

	SELECT @lot_process_record_id = [id] + 1
	FROM [APCSProDB].[trans].[numbers]
	WHERE [name] = 'lot_process_records.id';

	UPDATE [APCSProDB].[trans].[numbers]
	SET [id] = @lot_process_record_id
	WHERE [name] = 'lot_process_records.id'

	INSERT INTO [APCSProDB].[trans].[lot_process_records]
	([id]
	, [day_id]
	, [recorded_at]
	, [operated_by]
	, [record_class]
	, [lot_id]
	, [process_id]
	, [job_id]
	, [step_no]
	, [qty_in]
	, [qty_pass]
	, [qty_fail]
	, [qty_last_pass]
	, [qty_last_fail]
	, [qty_pass_step_sum]
	, [qty_fail_step_sum]
	, [qty_divided]
	, [qty_hasuu]
	, [qty_out]
	, [recipe]
	, [recipe_version]
	, [machine_id]
	, [position_id]
	, [process_job_id]
	, [is_onlined]
	, [dbx_id]
	, [wip_state]
	, [process_state]
	, [quality_state]
	, [first_ins_state]
	, [final_ins_state]
	, [is_special_flow]
	, [special_flow_id]
	, [is_temp_devided]
	, [temp_devided_count]
	, [container_no]
	, [extend_data]
	, [std_time_sum]
	, [pass_plan_time]
	, [pass_plan_time_up]
	, [origin_material_id]
	, [treatment_time]
	, [wait_time]
	, [qc_comment_id]
	, [qc_memo_id]
	, [created_at]
	, [created_by]
	, [updated_at]
	, [updated_by]
	, [act_device_name_id]
	, [device_slip_id]
	, [order_id]
	, [abc_judgement]
	, [held_at]
	, [held_minutes_current]
	, [limit_time_state]
	, [map_edit_state]
	, [qty_frame_in]
	, [qty_frame_pass]
	, [qty_frame_fail]
	, [qty_frame_last_pass]
	, [qty_frame_last_fail]
	, [qty_frame_pass_step_sum]
	, [qty_frame_fail_step_sum]
	, [carrier_no]
	, [next_carrier_no]
	, [production_category]
	, [partition_no]
	, [using_material_spec]
	, [qty_combined]
	, [reprint_count]
	, [is_3h]
	, [running_special_flow_id]
	, [qty_p_nashi]
	, [qty_front_ng]
	, [qty_marker]
	, [qty_cut_frame]
	, [is_temp_divided]
	, [temp_divided_count]
	, [next_sideway_step_no]
	, [e_slip_id]
	, [pc_instruction_code]
	, [qty_fail_details])
	SELECT @lot_process_record_id
	, @lot_day_id
	, GETDATE()
	, @user_id
	, 42
	, [id]
	, [act_process_id]
	, [act_job_id]
	, [step_no]
	, [qty_in]
	, [qty_pass]
	, [qty_fail]
	, [qty_last_pass]
	, [qty_last_fail]
	, [qty_pass_step_sum]
	, [qty_fail_step_sum]
	, [qty_divided]
	, [qty_hasuu]
	, [qty_out]
	, NULL
	, NULL
	, [machine_id]
	, NULL
	, [process_job_id]
	, NULL
	, NULL
	, [wip_state]
	, [process_state]
	, [quality_state]
	, [first_ins_state]
	, [final_ins_state]
	, [is_special_flow]
	, [special_flow_id]
	, [is_temp_devided]
	, [temp_devided_count]
	, [container_no]
	, NULL
	, [std_time_sum]
	, [pass_plan_time]
	, [pass_plan_time_up]
	, [origin_material_id]
	, NULL
	, NULL
	, [qc_comment_id]
	, [qc_memo_id]
	, [created_at]
	, [created_by]
	, [updated_at]
	, [updated_by]
	, [act_device_name_id]
	, [device_slip_id]
	, [order_id]
	, NULL
	, [held_at]
	, [held_minutes_current]
	, [limit_time_state]
	, [map_edit_state]
	, [qty_frame_in]
	, [qty_frame_pass]
	, [qty_frame_fail]
	, [qty_frame_last_pass]
	, [qty_frame_last_fail]
	, [qty_frame_pass_step_sum]
	, [qty_frame_fail_step_sum]
	, [carrier_no]
	, [next_carrier_no]
	, [production_category]
	, [partition_no]
	, [using_material_spec]
	, [qty_combined]
	, [reprint_count]
	, [is_3h]
	, NULL
	, [qty_p_nashi]
	, [qty_front_ng]
	, [qty_marker]
	, [qty_cut_frame]
	, [is_temp_divided]
	, [temp_divided_count]
	, [next_sideway_step_no]
	, [e_slip_id]
	, [pc_instruction_code]
	, [qty_fail_details]
	FROM [APCSProDB].[trans].[lots]
	WHERE [lot_no] = @lot_no

	IF EXISTS(SELECT [id]
	FROM [APCSProDB].[trans].[lot_hold_controls]
	WHERE [lot_id] = @lot_id
	AND [system_name] = 'andon')
	BEGIN
		UPDATE [APCSProDB].[trans].[lot_hold_controls]
		SET [is_held] = 1
		, [updated_at] = GETDATE()
		, [updated_by] = @user_id
		WHERE [lot_id] = @lot_id
		AND [system_name] = 'andon'

		SELECT @lot_hold_control_id = [id]
		FROM [APCSProDB].[trans].[lot_hold_controls]
		WHERE [lot_id] = @lot_id
		AND [system_name] = 'andon'
	END
	ELSE
	BEGIN
		SELECT @lot_hold_control_id = [id] + 1
		FROM [APCSProDB].[trans].[numbers]
		WHERE [name] = 'lot_hold_controls.id';

		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = @lot_hold_control_id
		WHERE [name] = 'lot_hold_controls.id'
		
		INSERT INTO [APCSProDB].[trans].[lot_hold_controls]
		([id]
		, [lot_id]
		, [system_name]
		, [is_held]
		, [updated_at]
		, [updated_by])
		VALUES
		(@lot_hold_control_id
		, @lot_id
		, 'andon'
		, 1
		, GETDATE()
		, @user_id)
	END

	INSERT INTO [APCSProDB].[trans].[lot_hold_control_records]
	([id]
	, [hold_control_id]
	, [lot_id]
	, [system_name]
	, [updated_at]
	, [updated_by]
	, [is_held])
	VALUES
	(@lot_process_record_id
	, @lot_hold_control_id
	, @lot_id
	, 'andon'
	, GETDATE()
	, @user_id
	, 1)

	SET @mode = ( SELECT [abnormal_mode].[mode] 
		FROM [APCSProDB].[trans].[abnormal_detail]
		INNER JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
		WHERE [abnormal_detail].[id] = @comment_id )

	IF (@mode = 1)
	BEGIN
		SELECT @abnormal_mode = [abnormal_mode].[name] 
		FROM [APCSProDB].[trans].[abnormal_detail]
		INNER JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
		WHERE [abnormal_detail].[id] = @comment_id 

		SELECT @display_count = COUNT(TransactionID) + 1
		FROM [DBx].[dbo].[ProblemsTransaction]
		WHERE [StartTime] > @date_value_form
		AND [StartTime] < @date_value_to

		SELECT @abnormal_count = COUNT(TransactionID) + 1
		FROM [DBx].[dbo].[ProblemsTransaction]
		WHERE [StartTime] > @date_value_form
		AND [StartTime] < @date_value_to
		--AND [ProblemType] = 0
		AND ProcessName LIKE CONCAT(@process_name, '%')

		SELECT @andon_control_id = MAX([TransactionID]) + 1
		FROM [DBx].[dbo].[ProblemsTransaction]

		INSERT INTO [DBx].[dbo].[ProblemsTransaction]
		([TransactionID]
		, [DisplayID]
		, [ProcessName]
		, [MachineNo]
		, [OperatorNo]
		, [LineNo]
		, [PackageName]
		, [DeviceName]
		, [LotNo]
		, [StartTime]
		, [EndTime]
		, [Status]
		, [GroupLeaderCheck]
		, [ProblemType]
		, [ProblemVal1]
		, [ProblemVal2]
		, [ProblemVal3]
		, [ComName])
		SELECT @andon_control_id
		, CONCAT(DAY(@date_value_form)
			, '/'
			, @display_count)
		, @process_name
		, @machine_name
		, @username
		, @line_no
		, @package_name
		, @device_name
		, @lot_no
		, GETDATE()
		, NULL
		, 0
		, NULL
		, 0
		, @abnormal_mode
		, CONCAT(@process_name
			, '-'
			, RIGHT(YEAR(@date_value_form), 2)
			, '-'
			, MONTH(@date_value_form)
			, '-'
			, DAY(@date_value_form)
			, '-'
			, FORMAT(@abnormal_count, '000'))
		, @comment_id
		, @equipment_no
	END
	ELSE
	BEGIN
		SELECT @abnormal_mode = [abnormal_detail].[name] 
		FROM [APCSProDB].[trans].[abnormal_detail]
		INNER JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
		WHERE [abnormal_detail].[id] = @comment_id 

		SELECT @display_count = COUNT(TransactionID) + 1
		FROM [DBx].[dbo].[ProblemsTransaction]
		WHERE [StartTime] > @date_value_form
		AND [StartTime] < @date_value_to

		SELECT @andon_control_id = MAX([TransactionID]) + 1
		FROM [DBx].[dbo].[ProblemsTransaction]

		INSERT INTO [DBx].[dbo].[ProblemsTransaction]
		([TransactionID]
		, [DisplayID]
		, [ProcessName]
		, [MachineNo]
		, [OperatorNo]
		, [LineNo]
		, [PackageName]
		, [DeviceName]
		, [LotNo]
		, [StartTime]
		, [EndTime]
		, [Status]
		, [GroupLeaderCheck]
		, [ProblemType]
		, [ProblemVal1]
		, [ProblemVal2]
		, [ProblemVal3]
		, [ComName])
		SELECT @andon_control_id
		, CONCAT(DAY(@date_value_form)
			, '/'
			, @display_count)
		, @process_name
		, @machine_name
		, @username
		, @line_no
		, @package_name
		, @device_name
		, @lot_no
		, GETDATE()
		, NULL
		, 0
		, NULL
		, 1
		, @abnormal_mode
		, ''
		, NULL
		, @equipment_no
	END

	--SELECT @andon_control_id = [id] + 1
	--FROM [APCSProDB].[trans].[numbers]
	--WHERE [name] = 'andon_controls.id';

	SELECT @abnormal_count = COUNT(TransactionID) + 1
	FROM [DBx].[dbo].[ProblemsTransaction]
	WHERE [StartTime] > @date_value_form
	AND [StartTime] < @date_value_to
	AND ProcessName LIKE CONCAT(@process_name, '%')

	UPDATE [APCSProDB].[trans].[numbers]
	SET [id] = @andon_control_id
	WHERE [name] = 'andon_controls.id'

	INSERT INTO [APCSProDB].[trans].[andon_controls]
	([id]
	, [andon_control_no]
	, [comment_id_at_finding]
	, [is_solved]
	, [treat_state]
	, [treatment_result]
	, [updated_at]
	, [updated_by])
	VALUES
	(@andon_control_id
	, CONCAT(@process_name
			, '-'
			, RIGHT(YEAR(@date_value_form), 2)
			, '-'
			, MONTH(@date_value_form)
			, '-'
			, DAY(@date_value_form)
			, '-'
			, FORMAT(@abnormal_count, '000'))
	, @comment_id
	, NULL
	, NULL
	, NULL
	, GETDATE()
	, @user_id)

	INSERT INTO [APCSProDB].[trans].[lot_andon_records]
	([andon_control_id]
	, [lot_id]
	, [created_at]
	, [created_by])
	VALUES
	(@andon_control_id
	, @lot_id
	, GETDATE()
	, @user_id)

	SELECT CAST(1 AS BIT) AS [status]
	, @andon_control_id AS andon_control_id
END
