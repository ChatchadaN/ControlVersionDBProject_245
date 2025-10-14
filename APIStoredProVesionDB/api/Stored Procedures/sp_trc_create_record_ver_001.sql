-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_trc_create_record_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
	,	@is_held int
	,	@insp_type int
	,	@abnormal_mode_id1 int
	,	@abnormal_mode_id2 int
	,	@abnormal_mode_id3 int
	,	@insp_item int
	,	@ng_random int
	,	@qty_insp int
	,	@comment varchar(MAX)
	,	@image varchar(MAX)
	,	@machine_id int
	,	@process_id int
	,	@aqi_no varchar(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @user_id INT;
	DECLARE @lot_id INT;
	DECLARE @lot_step_no INT;
	DECLARE @lot_job_id INT;
	DECLARE @lot_day_id INT;
	DECLARE @lot_process_record_id INT;
	DECLARE @trc_id INT;
	DECLARE @trc_record_id INT;

	BEGIN TRY
		SELECT @user_id = [id]
		FROM [APCSProDB].[man].[users]
		WHERE [users].[emp_num] = @username

		SELECT @lot_id = [id]
		, @lot_step_no = [step_no]
		, @lot_job_id = [act_job_id]
		FROM [APCSProDB].[trans].[lots]
		WHERE [lots].[lot_no] = @lot_no

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
		, 52
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
		, @machine_id
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

		SELECT @trc_id = [id] + 1
		FROM [APCSProDB].[trans].[numbers]
		WHERE [name] = 'trc_controls.id';

		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = @trc_id
		WHERE [name] = 'trc_controls.id'
	
		INSERT INTO [APCSProDB].[trans].[trc_controls]
		([id]
		, [lot_id]
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
		, [machine_id]
		, [process_id]
		, [aqi_no])
		VALUES(@trc_id
		, @lot_id
		, @is_held
		, @insp_type
		, @abnormal_mode_id1
		, @abnormal_mode_id2
		, @abnormal_mode_id3
		, @insp_item
		, @ng_random
		, @qty_insp
		, @comment
		, GETDATE()
		, @user_id
		, GETDATE()
		, @user_id
		, @machine_id
		, @process_id
		, @aqi_no);

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
		, [updated_by]
		, [machine_id]
		, [process_id]
		, [aqi_no])
		VALUES(@trc_record_id
		, @trc_id
		, @lot_id
		, @lot_process_record_id
		, @is_held
		, @insp_type
		, @abnormal_mode_id1
		, @abnormal_mode_id2
		, @abnormal_mode_id3
		, @insp_item
		, @ng_random
		, @qty_insp
		, @comment
		, GETDATE()
		, @user_id
		, GETDATE()
		, @user_id
		, @machine_id
		, @process_id
		, @aqi_no)

		INSERT INTO [APCSProDBFile].[trans].[trc_picture]
		([trc_id]
		, [picture_data]
		, [picture_url]
		, [created_at]
		, [created_by]
		, [updated_at]
		, [updated_by])
		VALUES(@trc_id
		, CAST(N'' AS xml).value('xs:base64Binary(sql:variable("@image"))', 'varbinary(max)')
		, ''
		, GETDATE()
		, @user_id
		, GETDATE()
		, @user_id)

		SELECT CAST(1 AS BIT) AS [status]
		, @trc_id AS trc_id
	END TRY
	BEGIN CATCH
		SELECT CAST(0 AS BIT) AS [status]
		, 0 AS trc_id
	END CATCH
END
