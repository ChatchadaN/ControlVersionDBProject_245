-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_update_trc_clear_record_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@trc_id int
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
	DECLARE @trc_record_id INT;

	SELECT @user_id = [id]
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @username

	SELECT @lot_id = [lot_id]
	FROM [APCSProDB].[trans].[trc_controls]
	WHERE [trc_controls].[id] = @trc_id

	SELECT @lot_day_id = [id]
	FROM [APCSProDB].[trans].[days]
	WHERE [date_value] = CONVERT(DATE,GETDATE());

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
	, 53
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
	WHERE [id] = @lot_id

	UPDATE [APCSProDB].[trans].[trc_controls]
	SET [is_held] = 0
	, [updated_at] = GETDATE()
	, [updated_by] = @user_id
	WHERE [id] = @trc_id
	
	SELECT @trc_record_id = [id] + 1
	FROM [APCSProDB].[trans].[numbers]
	WHERE [name] = 'trc_control_records.id';

	UPDATE [APCSProDB].[trans].[numbers]
	SET [id] = @trc_record_id
	WHERE [name] = 'trc_control_records.id'

	INSERT INTO [APCSProDB].[trans].[trc_control_records]
	([id]
	, [trc_id]
	, [lot_id]
	, [lot_process_record_id]
	, [is_held]
	, [insp_type]
	, [abnormal_mode_id1]
	, [abnormal_mode_id2]
	, [abnormal_mode_id3]
	, [insp_item]
	, [ng_random]
	, [qty_insp]
	, [comment]
	, [created_at]
	, [created_by]
	, [updated_at]
	, [updated_by])
	SELECT @trc_record_id
	, @trc_id
	, [lot_id]
	, @lot_process_record_id
	, [is_held]
	, [insp_type]
	, [abnormal_mode_id1]
	, [abnormal_mode_id2]
	, [abnormal_mode_id3]
	, [insp_item]
	, [ng_random]
	, [qty_insp]
	, [comment]
	, [created_at]
	, [created_by]
	, [updated_at]
	, [updated_by]
	FROM [APCSProDB].[trans].[trc_controls]
	WHERE [id] = @trc_id
END
