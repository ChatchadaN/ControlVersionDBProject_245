-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_andon_update_record_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
	,	@andon_control_id int
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

	DECLARE @quality_state INT = 0; -- 0:not update 1:update
	DECLARE @is_solved INT = 0; -- 0:not update 1:update

	SELECT @user_id = [id]
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @username

	SELECT @lot_id = [id]
	FROM [APCSProDB].[trans].[lots]
	WHERE [lots].[lot_no] = @lot_no

	SELECT @lot_day_id = [id]
	FROM [APCSProDB].[trans].[days]
	WHERE [date_value] = CONVERT(DATE,GETDATE());

	-----------------------------------------------------------------
	-- (1) lot_process_records
	-----------------------------------------------------------------
	SELECT @lot_process_record_id = [id] + 1
	FROM [APCSProDB].[trans].[numbers]
	WHERE [name] = 'lot_process_records.id';

	UPDATE [APCSProDB].[trans].[numbers]
	SET [id] = @lot_process_record_id
	WHERE [name] = 'lot_process_records.id';
	-----------------------------------------------------------------
	-- (2) andon
	-----------------------------------------------------------------
	UPDATE [DBx].[dbo].[ProblemsTransaction]
	SET [EndTime] = GETDATE()
		, [GroupLeaderCheck] = @username
		, [Status] = 1
	WHERE [TransactionID] = @andon_control_id

	UPDATE [APCSProDB].[trans].[andon_controls]
	SET [is_solved] = 1
		, [treat_state] = 1
		, [updated_at] = GETDATE()
		, [updated_by] = @user_id
	WHERE [id] = @andon_control_id
	-----------------------------------------------------------------
	-- (3) lot_hold_controls
	-----------------------------------------------------------------
	SET @is_solved = (SELECT status FROM [StoredProcedureDB].[dbo].[AndonCheckHoldControl] (@lot_no,'andon'))
	IF @is_solved = 1
	BEGIN
		-- Clear All Andon
		UPDATE [APCSProDB].[trans].[lot_hold_controls]
		SET [is_held] = 0
			, [updated_at] = GETDATE()
			, [updated_by] = @user_id
		WHERE [lot_id] = @lot_id
		AND [system_name] = 'andon'

		SELECT @lot_hold_control_id = [id]
		FROM [APCSProDB].[trans].[lot_hold_controls]
		WHERE [lot_id] = @lot_id
		AND [system_name] = 'andon'

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
			, 0)
	END
	-----------------------------------------------------------------
	-- (4) quality_state
	-----------------------------------------------------------------
	SET @quality_state = (SELECT status FROM [StoredProcedureDB].[dbo].[AndonCheckState] (@lot_no))
	IF @quality_state = 1
	BEGIN
		-- Update Quality State
		UPDATE [APCSProDB].[trans].[lots]
		SET [quality_state] = 0
		WHERE [lot_no] = @lot_no
		AND [quality_state] = 1;

		IF EXISTS(SELECT 1 FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no AND [is_special_flow] = 1)
		BEGIN
			UPDATE [APCSProDB].[trans].[special_flows] 
			SET [special_flows].[quality_state] = 0
			FROM [APCSProDB].[trans].[special_flows] 
			INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[is_special_flow] = 1
			AND [lots].[special_flow_id]  = [special_flows].[id]
			WHERE [lots].[lot_no] = @lot_no
			AND [special_flows].[quality_state] = 1;
		END
	End
	-----------------------------------------------------------------
	-- (1.1) lot_process_records
	-----------------------------------------------------------------
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
		, 43
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
END
