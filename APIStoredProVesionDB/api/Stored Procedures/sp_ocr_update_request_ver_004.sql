-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_ocr_update_request_ver_004]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@request_id int
	,	@lot_no varchar(10)
	,	@mark varchar(MAX)
	,	@image varchar(MAX)
	,	@is_pass int
	,	@recheck_count int
	,	@is_logo_pass int
	,	@request_status int
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
	DECLARE @image_id INT;
	DECLARE @lot_marking_id INT;
	DECLARE @lot_day_id INT;
	DECLARE @lot_process_record_id INT;

	UPDATE [APIStoredProDB].[dbo].[lot_request_ocr_records]
	SET [lot_request_ocr_records].[status] = @request_status
	WHERE [lot_request_ocr_records].[id] = @request_id

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

	IF(@is_pass > 0)
	BEGIN
		UPDATE [APCSProDB].[trans].[lots]
		SET [quality_state] = 0
		WHERE [lot_no] = @lot_no
		AND [quality_state] = 10;
	END

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
	, 131
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

	INSERT INTO [APCSProDBFile].[ocr].[lot_marking_verify_picure]
	([picture_data]
	, [created_at]
	, [created_by]
	, [updated_at]
	, [updated_by]
	, [record_class])
	VALUES
	(CAST(N'' AS xml).value('xs:base64Binary(sql:variable("@image"))', 'varbinary(max)')
	, GETDATE()
	, @user_id
	, GETDATE()
	, @user_id
	, 1);
	SELECT @image_id = SCOPE_IDENTITY();

	IF EXISTS(SELECT [lot_marking_verify].[id]
	FROM [APCSProDB].[trans].[lot_marking_verify]
	WHERE [lot_marking_verify].[lot_id] = @lot_id
	AND [lot_marking_verify].[step_no] = @lot_step_no)
	BEGIN
		UPDATE [APCSProDB].[trans].[lot_marking_verify]
		SET [is_pass] = @is_pass
		, [value] = @mark
		, [marking_picture_id] = @image_id
		, [created_at] = GETDATE()
		, [created_by] = @user_id
		, [updated_at] = GETDATE()
		, [updated_by] = @user_id
		, [job_id] = @lot_job_id
		, [lot_process_record_id] = @lot_process_record_id
		, [recheck_count] = @recheck_count
		, [step_no] = @lot_step_no
		, [is_logo_pass] = @is_logo_pass
		WHERE [lot_id] = @lot_id
		AND [step_no] = @lot_step_no;

		SELECT @lot_marking_id = [id]
		FROM [APCSProDB].[trans].[lot_marking_verify]
		WHERE [lot_id] = @lot_id
		AND [step_no] = @lot_step_no;

		INSERT INTO [APCSProDB].[trans].[lot_marking_verify_records]
		([lot_marking_id]
		, [lot_id]
		, [is_pass]
		, [value]
		, [marking_picture_id]
		, [created_at]
		, [created_by]
		, [updated_at]
		, [updated_by]
		, [job_id]
		, [lot_process_record_id]
		, [recheck_count]
		, [step_no]
		, [is_logo_pass])
		VALUES(@lot_marking_id
		, @lot_id
		, @is_pass
		, @mark
		, @image_id
		, GETDATE()
		, @user_id
		, GETDATE()
		, @user_id
		, @lot_job_id
		, @lot_process_record_id
		, @recheck_count
		, @lot_step_no
		, @is_logo_pass);
	END
	ELSE
	BEGIN
		INSERT INTO [APCSProDB].[trans].[lot_marking_verify]
		([lot_id]
		, [is_pass]
		, [value]
		, [marking_picture_id]
		, [created_at]
		, [created_by]
		, [updated_at]
		, [updated_by]
		, [job_id]
		, [lot_process_record_id]
		, [recheck_count]
		, [step_no]
		, [is_logo_pass])
		VALUES(@lot_id
		, @is_pass
		, @mark
		, @image_id
		, GETDATE()
		, @user_id
		, GETDATE()
		, @user_id
		, @lot_job_id
		, @lot_process_record_id
		, @recheck_count
		, @lot_step_no
		, @is_logo_pass);
		SELECT @lot_marking_id = SCOPE_IDENTITY();

		INSERT INTO [APCSProDB].[trans].[lot_marking_verify_records]
		([lot_marking_id]
		, [lot_id]
		, [is_pass]
		, [value]
		, [marking_picture_id]
		, [created_at]
		, [created_by]
		, [updated_at]
		, [updated_by]
		, [job_id]
		, [lot_process_record_id]
		, [recheck_count]
		, [step_no]
		, [is_logo_pass])
		VALUES(@lot_marking_id
		, @lot_id
		, @is_pass
		, @mark
		, @image_id
		, GETDATE()
		, @user_id
		, GETDATE()
		, @user_id
		, @lot_job_id
		, @lot_process_record_id
		, @recheck_count
		, @lot_step_no
		, @is_logo_pass);
	END
END
