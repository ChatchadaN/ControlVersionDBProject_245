
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_lots]
	-- Add the parameters for the stored procedure here
	@lot_id int
	, @lot_no char(20)
	, @product_family_id int
	, @act_package_id int
	, @act_device_name_id int
	, @device_slip_id int
	, @order_id int
	, @step_no int
	, @act_process_id int
	, @act_job_id int
	, @qty_in int
	, @qty_pass int
	, @qty_fail int
	, @qty_last_pass int
	, @qty_last_fail int
	, @qty_pass_step_sum int
	, @qty_fail_step_sum int
	, @qty_divided int
	, @qty_hasuu int
	, @qty_out int
	, @is_exist_work tinyint
	, @in_plan_date_id int
	, @out_plan_date_id int
	, @master_lot_id int
	, @depth smallint
	, @sequence smallint
	, @wip_state tinyint
	, @process_state tinyint
	, @quality_state tinyint
	, @first_ins_state tinyint
	, @final_ins_state tinyint
	, @is_special_flow tinyint
	, @special_flow_id int
	, @is_temp_devided tinyint
	, @temp_devided_count tinyint
	, @product_class_id tinyint
	, @priority tinyint
	, @finish_date_id int
	, @finished_at varchar(50)
	, @in_date_id int
	, @in_at varchar(50)
	, @ship_date_id int
	, @ship_at varchar(50)
	, @modify_out_plan_date_id int
	, @modified_at varchar(50)
	, @modified_by int
	, @location_id int
	, @acc_location_id int
	, @machine_id int
	, @container_no varchar(20)
	, @std_time_sum int
	, @start_step_no int
	, @m_no varchar(50)
	, @qc_comment_id int
	, @qc_memo_id int
	, @pass_plan_time varchar(50)
	, @pass_plan_time_up varchar(50)
	, @process_job_id int
	, @origin_material_id int
	, @carried_at varchar(50)
	, @is_imported tinyint
	, @is_label_issued tinyint
	, @held_at varchar(50)
	, @held_minutes_current int
	, @created_at varchar(50)
	, @created_by int
	, @updated_at varchar(50)
	, @updated_by int
	, @limit_time_state tinyint
	, @map_edit_state tinyint
	, @qty_frame_in int
	, @qty_frame_pass int
	, @qty_frame_fail int
	, @qty_frame_last_pass int
	, @qty_frame_last_fail int
	, @qty_frame_pass_step_sum int
	, @qty_frame_fail_step_sum int
	, @carrier_no varchar(20)
	, @next_carrier_no varchar(20)
	, @production_category tinyint
	, @partition_no int
	, @using_material_spec varchar(20)
	, @start_manufacturing_at varchar(50)
	, @plan_input_chip int
	, @qty_combined int
	, @reprint_count smallint
	, @external_lot_no varchar(50)
	, @is_3h tinyint
	, @qty_p_nashi int
	, @qty_front_ng int
	, @qty_marker int
	, @qty_cut_frame int
	, @is_temp_divided tinyint
	, @temp_divided_count tinyint
	, @next_sideway_step_no int
	, @guarantee_lot_id int
	, @e_slip_id varchar(50)
	, @pc_instruction_code int
	, @qty_fail_details varchar(255)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--IF (@lot_id = 2)
	--BEGIN
	--	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--	( [record_at]
	--	, [record_class]
	--	, [login_name]
	--	, [hostname]
	--	, [appname]
	--	, [command_text]
	--	, [lot_no] )
	--SELECT GETDATE()
	--	, '4'
	--	, ORIGINAL_LOGIN()
	--	, HOST_NAME()
	--	, APP_NAME()
	--	, 'EXEC [atom].[sp_set_trans_lots] @lot_id = ''' + ISNULL( CAST( @lot_id AS VARCHAR ), '' ) + '''' 
	--		+ ', @finished_at = ''' + ISNULL( @finished_at, '' ) + ''''
	--		+ ', @in_at = ''' + ISNULL( @in_at, '' ) + ''''
	--		+ ', @ship_at = ''' + ISNULL( @ship_at, '' ) + ''''
	--		+ ', @carried_at = ''' + ISNULL( @carried_at, '' ) + ''''
	--		+ ', @held_at = ''' + ISNULL( @held_at, '' ) + ''''
	--		+ ', @modified_at = ''' + ISNULL( @modified_at, '' ) + ''''
	--		+ ', @created_at = ''' + ISNULL( @created_at, '' ) + ''''
	--		+ ', @updated_at = ''' + ISNULL( @updated_at, '' ) + ''''
	--	, ( SELECT CAST( [lot_no] AS VARCHAR ) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id );
	--END

	DECLARE @r INT = 0;
	declare @dayid_shipdate  int = 0;

	select @dayid_shipdate = id from [APCSProDB].[trans].[days] where date_value = convert(varchar, getdate(), 10)

    -- Insert statements for procedure here

	IF(@wip_state = 100 or @wip_state = 101)
		BEGIN
			UPDATE [APCSProDB].[trans].[lots]
			SET [product_family_id] = case when (CONVERT(varchar(50),@product_family_id) = '') then NULL else @product_family_id end
				,[act_package_id] = case when (CONVERT(varchar(50),@act_package_id) = '') then NULL else @act_package_id end
				,[act_device_name_id] = case when (CONVERT(varchar(50),@act_device_name_id) = '') then NULL else @act_device_name_id end
				,[device_slip_id] = case when (CONVERT(varchar(50),@device_slip_id) = '') then NULL else @device_slip_id end
				,[order_id] = case when (CONVERT(varchar(50),@order_id) = '') then NULL else @order_id end
				,[step_no] = case when (CONVERT(varchar(50),@step_no) = '') then NULL else @step_no end
				,[act_process_id] = case when (CONVERT(varchar(50),@act_process_id) = '') then NULL else @act_process_id end
				,[act_job_id] = case when (CONVERT(varchar(50),@act_job_id) = '') then NULL else @act_job_id end
				,[qty_in] = case when (CONVERT(varchar(50),@qty_in) = '') then NULL else @qty_in end
				,[qty_pass] = case when (CONVERT(varchar(50),@qty_pass) = '') then NULL else @qty_pass end
				,[qty_fail] = case when (CONVERT(varchar(50),@qty_fail) = '') then NULL else @qty_fail end
				,[qty_last_pass] = case when (CONVERT(varchar(50),@qty_last_pass) = '') then NULL else @qty_last_pass end
				,[qty_last_fail] = case when (CONVERT(varchar(50),@qty_last_fail) = '') then NULL else @qty_last_fail end
				,[qty_pass_step_sum] = case when (CONVERT(varchar(50),@qty_pass_step_sum) = '') then NULL else @qty_pass_step_sum end
				,[qty_fail_step_sum] = case when (CONVERT(varchar(50),@qty_fail_step_sum) = '') then NULL else @qty_fail_step_sum end
				,[qty_divided] = case when (CONVERT(varchar(50),@qty_divided) = '') then NULL else @qty_divided end
				,[qty_hasuu] = case when (CONVERT(varchar(50),@qty_hasuu) = '') then NULL else @qty_hasuu end
				,[qty_out] = case when (CONVERT(varchar(50),@qty_out) = '') then NULL else @qty_out end
				,[is_exist_work] = case when (CONVERT(varchar(50),@is_exist_work) = '') then NULL else @is_exist_work end
				,[in_plan_date_id] = case when (CONVERT(varchar(50),@in_plan_date_id) = '') then NULL else @in_plan_date_id end
				,[out_plan_date_id] = case when (CONVERT(varchar(50),@out_plan_date_id) = '') then NULL else @out_plan_date_id end
				,[master_lot_id] = case when (CONVERT(varchar(50),@master_lot_id) = '') then NULL else @master_lot_id end
				,[depth] = case when (CONVERT(varchar(50),@depth) = '') then NULL else @depth end
				,[sequence] = case when (CONVERT(varchar(50),@sequence) = '') then NULL else @sequence end
				,[wip_state] = case when (CONVERT(varchar(50),@wip_state) = '') then NULL else @wip_state end
				,[process_state] = case when (CONVERT(varchar(50),@process_state) = '') then NULL else @process_state end
				,[quality_state] = case when (CONVERT(varchar(50),@quality_state) = '') then NULL else @quality_state end
				,[first_ins_state] = case when (CONVERT(varchar(50),@first_ins_state) = '') then NULL else @first_ins_state end
				,[final_ins_state] = case when (CONVERT(varchar(50),@final_ins_state) = '') then NULL else @final_ins_state end
				,[is_special_flow] = case when (CONVERT(varchar(50),@is_special_flow) = '') then NULL else @is_special_flow end
				,[special_flow_id] = case when (CONVERT(varchar(50),@special_flow_id) = '') then NULL else @special_flow_id end
				,[is_temp_devided] = case when (CONVERT(varchar(50),@is_temp_devided) = '') then NULL else @is_temp_devided end
				,[temp_devided_count] = case when (CONVERT(varchar(50),@temp_devided_count) = '') then NULL else @temp_devided_count end
				,[product_class_id] = case when (CONVERT(varchar(50),@product_class_id) = '') then NULL else @product_class_id end
				,[priority] = case when (CONVERT(varchar(50),@priority) = '') then NULL else @priority end
				,[finish_date_id] = case when (CONVERT(varchar(50),@finish_date_id) = '') then NULL else @finish_date_id end
				,[finished_at] = case when (@finished_at = '') then NULL else CONVERT(DATETIME, @finished_at) end
				,[in_date_id] = case when (CONVERT(varchar(50),@in_date_id) = '') then NULL else @in_date_id end
				,[in_at] = case when (@in_at = '') then NULL else CONVERT(DATETIME, @in_at) end
				--,[ship_date_id] = case when (CONVERT(varchar(50),@ship_date_id) = '') then NULL else @ship_date_id end
				,[ship_date_id] = @dayid_shipdate
				--,[ship_at] = case when (@ship_at = '') then NULL else CONVERT(DATETIME, @ship_at) end
				,[ship_at] = GETDATE()
				,[modify_out_plan_date_id] = case when (CONVERT(varchar(50),@modify_out_plan_date_id) = '') then NULL else @modify_out_plan_date_id end
				,[modified_at] = case when (@modified_at = '') then NULL else CONVERT(DATETIME, @modified_at) end
				,[modified_by] = case when (CONVERT(varchar(50),@modified_by) = '') then NULL else @modified_by end
				--,[location_id] = case when (CONVERT(varchar(50),@location_id) = '') then NULL else @location_id end
				,[acc_location_id] = case when (CONVERT(varchar(50),@acc_location_id) = '') then NULL else @acc_location_id end
				,[machine_id] = case when (CONVERT(varchar(50),@machine_id) = '') then NULL else @machine_id end
				,[container_no] = case when (@container_no = '') then NULL else @container_no end
				,[std_time_sum] = case when (CONVERT(varchar(50),@std_time_sum) = '') then NULL else @std_time_sum end
				,[start_step_no] = case when (CONVERT(varchar(50),@start_step_no) = '') then NULL else @start_step_no end
				,[m_no] = case when (@m_no = '') then NULL else @m_no end
				,[qc_comment_id] = case when (CONVERT(varchar(50),@qc_comment_id) = '') then NULL else @qc_comment_id end
				,[qc_memo_id] = case when (CONVERT(varchar(50),@qc_memo_id) = '') then NULL else @qc_memo_id end
				,[pass_plan_time] = case when (@pass_plan_time = '') then NULL else CONVERT(DATETIME, @pass_plan_time) end
				,[pass_plan_time_up] = case when (@pass_plan_time_up = '') then NULL else CONVERT(DATETIME, @pass_plan_time_up) end
				,[process_job_id] = case when (CONVERT(varchar(50),@process_job_id) = '') then NULL else @process_job_id end
				,[origin_material_id] = case when (CONVERT(varchar(50),@origin_material_id) = '') then NULL else @origin_material_id end
				,[carried_at] = case when (@carried_at = '') then NULL else CONVERT(DATETIME, @carried_at) end
				,[is_imported] = case when (CONVERT(varchar(50),@is_imported) = '') then NULL else @is_imported end
				,[is_label_issued] = case when (CONVERT(varchar(50),@is_label_issued) = '') then NULL else @is_label_issued end
				,[held_at] = case when (CONVERT(varchar(50),@held_at) = '') then NULL else @held_at end
				,[held_minutes_current] = case when (CONVERT(varchar(50),@held_minutes_current) = '') then NULL else @held_minutes_current end
				,[created_at] = case when (@created_at = '') then NULL else CONVERT(DATETIME, @created_at) end
				,[created_by] = case when (CONVERT(varchar(50),@created_by) = '') then NULL else @created_by end
				--,[updated_at] = case when (@updated_at = '') then NULL else CONVERT(DATETIME, @updated_at) end
				,[updated_at] = CONVERT(DATETIME, GETDATE())
				,[updated_by] = case when (CONVERT(varchar(50),@updated_by) = '') then NULL else @updated_by end				
				,[limit_time_state] = case when (CONVERT(varchar(50),@limit_time_state) = '') then NULL else @limit_time_state end
				,[map_edit_state] = case when (CONVERT(varchar(50),@map_edit_state) = '') then NULL else @map_edit_state end
				,[qty_frame_in] = case when (CONVERT(varchar(50),@qty_frame_in) = '') then NULL else @qty_frame_in end
				,[qty_frame_pass] = case when (CONVERT(varchar(50),@qty_frame_pass) = '') then NULL else @qty_frame_pass end
				,[qty_frame_fail] = case when (CONVERT(varchar(50),@qty_frame_fail) = '') then NULL else @qty_frame_fail end
				,[qty_frame_last_pass] = case when (CONVERT(varchar(50),@qty_frame_last_pass) = '') then NULL else @qty_frame_last_pass end
				,[qty_frame_last_fail] = case when (CONVERT(varchar(50),@qty_frame_last_fail) = '') then NULL else @qty_frame_last_fail end
				,[qty_frame_pass_step_sum] = case when (CONVERT(varchar(50),@qty_frame_pass_step_sum) = '') then NULL else @qty_frame_pass_step_sum end
				,[qty_frame_fail_step_sum] = case when (CONVERT(varchar(50),@qty_frame_fail_step_sum) = '') then NULL else @qty_frame_fail_step_sum end
				,[carrier_no] = case when (CONVERT(varchar(50),@carrier_no) = '') then NULL else @carrier_no end
				,[next_carrier_no] = case when (CONVERT(varchar(50),@next_carrier_no) = '') then NULL else @next_carrier_no end
				,[production_category] = case when (CONVERT(varchar(50),@production_category) = '') then NULL else @production_category end
				,[partition_no] = case when (CONVERT(varchar(50),@partition_no) = '') then NULL else @partition_no end
				,[using_material_spec] = case when (CONVERT(varchar(50),@using_material_spec) = '') then NULL else @using_material_spec end
				,[start_manufacturing_at] = case when (CONVERT(varchar(50),@start_manufacturing_at) = '') then NULL else @start_manufacturing_at end
				,[plan_input_chip] = case when (CONVERT(varchar(50),@plan_input_chip) = '') then NULL else @plan_input_chip end
				,[qty_combined] = case when (CONVERT(varchar(50),@qty_combined) = '') then NULL else @qty_combined end
				,[reprint_count] = case when (CONVERT(varchar(50),@reprint_count) = '') then NULL else @reprint_count end
				,[external_lot_no] = case when (CONVERT(varchar(50),@external_lot_no) = '') then NULL else @external_lot_no end
				,[is_3h] = case when (CONVERT(varchar(50),@is_3h) = '') then NULL else @is_3h end
				,[qty_p_nashi] = case when (CONVERT(varchar(50),@qty_p_nashi) = '') then NULL else @qty_p_nashi end
				,[qty_front_ng] = case when (CONVERT(varchar(50),@qty_front_ng) = '') then NULL else @qty_front_ng end
				,[qty_marker] = case when (CONVERT(varchar(50),@qty_marker) = '') then NULL else @qty_marker end
				,[qty_cut_frame] = case when (CONVERT(varchar(50),@qty_cut_frame) = '') then NULL else @qty_cut_frame end
				,[is_temp_divided] = case when (CONVERT(varchar(50),@is_temp_divided) = '') then NULL else @is_temp_divided end
				,[temp_divided_count] = case when (CONVERT(varchar(50),@temp_divided_count) = '') then NULL else @temp_divided_count end
				,[next_sideway_step_no] = case when (CONVERT(varchar(50),@next_sideway_step_no) = '') then NULL else @next_sideway_step_no end
				,[guarantee_lot_id] = case when (CONVERT(varchar(50),@guarantee_lot_id) = '') then NULL else @guarantee_lot_id end
				,[e_slip_id] = case when (CONVERT(varchar(50),@e_slip_id) = '') then NULL else @e_slip_id end
				,[pc_instruction_code] = case when (CONVERT(varchar(50),@pc_instruction_code) = '') then NULL else @pc_instruction_code end
				,[qty_fail_details] = case when (CONVERT(varchar(50),@qty_fail_details) = '') then NULL else @qty_fail_details end
			WHERE [id] = @lot_id
		END
	ELSE
		BEGIN
			UPDATE [APCSProDB].[trans].[lots]
			SET [product_family_id] = case when (CONVERT(varchar(50),@product_family_id) = '') then NULL else @product_family_id end
				,[act_package_id] = case when (CONVERT(varchar(50),@act_package_id) = '') then NULL else @act_package_id end
				,[act_device_name_id] = case when (CONVERT(varchar(50),@act_device_name_id) = '') then NULL else @act_device_name_id end
				,[device_slip_id] = case when (CONVERT(varchar(50),@device_slip_id) = '') then NULL else @device_slip_id end
				,[order_id] = case when (CONVERT(varchar(50),@order_id) = '') then NULL else @order_id end
				,[step_no] = case when (CONVERT(varchar(50),@step_no) = '') then NULL else @step_no end
				,[act_process_id] = case when (CONVERT(varchar(50),@act_process_id) = '') then NULL else @act_process_id end
				,[act_job_id] = case when (CONVERT(varchar(50),@act_job_id) = '') then NULL else @act_job_id end
				,[qty_in] = case when (CONVERT(varchar(50),@qty_in) = '') then NULL else @qty_in end
				,[qty_pass] = case when (CONVERT(varchar(50),@qty_pass) = '') then NULL else @qty_pass end
				,[qty_fail] = case when (CONVERT(varchar(50),@qty_fail) = '') then NULL else @qty_fail end
				,[qty_last_pass] = case when (CONVERT(varchar(50),@qty_last_pass) = '') then NULL else @qty_last_pass end
				,[qty_last_fail] = case when (CONVERT(varchar(50),@qty_last_fail) = '') then NULL else @qty_last_fail end
				,[qty_pass_step_sum] = case when (CONVERT(varchar(50),@qty_pass_step_sum) = '') then NULL else @qty_pass_step_sum end
				,[qty_fail_step_sum] = case when (CONVERT(varchar(50),@qty_fail_step_sum) = '') then NULL else @qty_fail_step_sum end
				,[qty_divided] = case when (CONVERT(varchar(50),@qty_divided) = '') then NULL else @qty_divided end
				,[qty_hasuu] = case when (CONVERT(varchar(50),@qty_hasuu) = '') then NULL else @qty_hasuu end
				,[qty_out] = case when (CONVERT(varchar(50),@qty_out) = '') then NULL else @qty_out end
				,[is_exist_work] = case when (CONVERT(varchar(50),@is_exist_work) = '') then NULL else @is_exist_work end
				,[in_plan_date_id] = case when (CONVERT(varchar(50),@in_plan_date_id) = '') then NULL else @in_plan_date_id end
				,[out_plan_date_id] = case when (CONVERT(varchar(50),@out_plan_date_id) = '') then NULL else @out_plan_date_id end
				,[master_lot_id] = case when (CONVERT(varchar(50),@master_lot_id) = '') then NULL else @master_lot_id end
				,[depth] = case when (CONVERT(varchar(50),@depth) = '') then NULL else @depth end
				,[sequence] = case when (CONVERT(varchar(50),@sequence) = '') then NULL else @sequence end
				,[wip_state] = case when (CONVERT(varchar(50),@wip_state) = '') then NULL else @wip_state end
				,[process_state] = case when (CONVERT(varchar(50),@process_state) = '') then NULL else @process_state end
				,[quality_state] = case when (CONVERT(varchar(50),@quality_state) = '') then NULL else @quality_state end
				,[first_ins_state] = case when (CONVERT(varchar(50),@first_ins_state) = '') then NULL else @first_ins_state end
				,[final_ins_state] = case when (CONVERT(varchar(50),@final_ins_state) = '') then NULL else @final_ins_state end
				,[is_special_flow] = case when (CONVERT(varchar(50),@is_special_flow) = '') then NULL else @is_special_flow end
				,[special_flow_id] = case when (CONVERT(varchar(50),@special_flow_id) = '') then NULL else @special_flow_id end
				,[is_temp_devided] = case when (CONVERT(varchar(50),@is_temp_devided) = '') then NULL else @is_temp_devided end
				,[temp_devided_count] = case when (CONVERT(varchar(50),@temp_devided_count) = '') then NULL else @temp_devided_count end
				,[product_class_id] = case when (CONVERT(varchar(50),@product_class_id) = '') then NULL else @product_class_id end
				,[priority] = case when (CONVERT(varchar(50),@priority) = '') then NULL else @priority end
				,[finish_date_id] = case when (CONVERT(varchar(50),@finish_date_id) = '') then NULL else @finish_date_id end
				,[finished_at] = case when (@finished_at = '') then NULL else CONVERT(DATETIME, @finished_at) end
				,[in_date_id] = case when (CONVERT(varchar(50),@in_date_id) = '') then NULL else @in_date_id end
				,[in_at] = case when (@in_at = '') then NULL else CONVERT(DATETIME, @in_at) end
				--,[ship_date_id] = case when (CONVERT(varchar(50),@ship_date_id) = '') then NULL else @ship_date_id end
				,[ship_date_id] = @dayid_shipdate
				--,[ship_at] = case when (@ship_at = '') then NULL else CONVERT(DATETIME, @ship_at) end
				,[ship_at] = GETDATE()
				,[modify_out_plan_date_id] = case when (CONVERT(varchar(50),@modify_out_plan_date_id) = '') then NULL else @modify_out_plan_date_id end
				,[modified_at] = case when (@modified_at = '') then NULL else CONVERT(DATETIME, @modified_at) end
				,[modified_by] = case when (CONVERT(varchar(50),@modified_by) = '') then NULL else @modified_by end
				--,[location_id] = case when (CONVERT(varchar(50),@location_id) = '') then NULL else @location_id end
				,[acc_location_id] = case when (CONVERT(varchar(50),@acc_location_id) = '') then NULL else @acc_location_id end
				,[machine_id] = case when (CONVERT(varchar(50),@machine_id) = '') then NULL else @machine_id end
				,[container_no] = case when (@container_no = '') then NULL else @container_no end
				,[std_time_sum] = case when (CONVERT(varchar(50),@std_time_sum) = '') then NULL else @std_time_sum end
				,[start_step_no] = case when (CONVERT(varchar(50),@start_step_no) = '') then NULL else @start_step_no end
				,[m_no] = case when (@m_no = '') then NULL else @m_no end
				,[qc_comment_id] = case when (CONVERT(varchar(50),@qc_comment_id) = '') then NULL else @qc_comment_id end
				,[qc_memo_id] = case when (CONVERT(varchar(50),@qc_memo_id) = '') then NULL else @qc_memo_id end
				,[pass_plan_time] = case when (@pass_plan_time = '') then NULL else CONVERT(DATETIME, @pass_plan_time) end
				,[pass_plan_time_up] = case when (@pass_plan_time_up = '') then NULL else CONVERT(DATETIME, @pass_plan_time_up) end
				,[process_job_id] = case when (CONVERT(varchar(50),@process_job_id) = '') then NULL else @process_job_id end
				,[origin_material_id] = case when (CONVERT(varchar(50),@origin_material_id) = '') then NULL else @origin_material_id end
				,[carried_at] = case when (@carried_at = '') then NULL else CONVERT(DATETIME, @carried_at) end
				,[is_imported] = case when (CONVERT(varchar(50),@is_imported) = '') then NULL else @is_imported end
				,[is_label_issued] = case when (CONVERT(varchar(50),@is_label_issued) = '') then NULL else @is_label_issued end
				,[held_at] = case when (CONVERT(varchar(50),@held_at) = '') then NULL else @held_at end
				,[held_minutes_current] = case when (CONVERT(varchar(50),@held_minutes_current) = '') then NULL else @held_minutes_current end
				,[created_at] = case when (@created_at = '') then NULL else CONVERT(DATETIME, @created_at) end
				,[created_by] = case when (CONVERT(varchar(50),@created_by) = '') then NULL else @created_by end
				--,[updated_at] = case when (@updated_at = '') then NULL else CONVERT(DATETIME, @updated_at) end
				,[updated_at] = CONVERT(DATETIME, GETDATE())
				,[updated_by] = case when (CONVERT(varchar(50),@updated_by) = '') then NULL else @updated_by end				
				,[limit_time_state] = case when (CONVERT(varchar(50),@limit_time_state) = '') then NULL else @limit_time_state end
				,[map_edit_state] = case when (CONVERT(varchar(50),@map_edit_state) = '') then NULL else @map_edit_state end
				,[qty_frame_in] = case when (CONVERT(varchar(50),@qty_frame_in) = '') then NULL else @qty_frame_in end
				,[qty_frame_pass] = case when (CONVERT(varchar(50),@qty_frame_pass) = '') then NULL else @qty_frame_pass end
				,[qty_frame_fail] = case when (CONVERT(varchar(50),@qty_frame_fail) = '') then NULL else @qty_frame_fail end
				,[qty_frame_last_pass] = case when (CONVERT(varchar(50),@qty_frame_last_pass) = '') then NULL else @qty_frame_last_pass end
				,[qty_frame_last_fail] = case when (CONVERT(varchar(50),@qty_frame_last_fail) = '') then NULL else @qty_frame_last_fail end
				,[qty_frame_pass_step_sum] = case when (CONVERT(varchar(50),@qty_frame_pass_step_sum) = '') then NULL else @qty_frame_pass_step_sum end
				,[qty_frame_fail_step_sum] = case when (CONVERT(varchar(50),@qty_frame_fail_step_sum) = '') then NULL else @qty_frame_fail_step_sum end
				,[carrier_no] = case when (CONVERT(varchar(50),@carrier_no) = '') then NULL else @carrier_no end
				,[next_carrier_no] = case when (CONVERT(varchar(50),@next_carrier_no) = '') then NULL else @next_carrier_no end
				,[production_category] = case when (CONVERT(varchar(50),@production_category) = '') then NULL else @production_category end
				,[partition_no] = case when (CONVERT(varchar(50),@partition_no) = '') then NULL else @partition_no end
				,[using_material_spec] = case when (CONVERT(varchar(50),@using_material_spec) = '') then NULL else @using_material_spec end
				,[start_manufacturing_at] = case when (CONVERT(varchar(50),@start_manufacturing_at) = '') then NULL else @start_manufacturing_at end
				,[plan_input_chip] = case when (CONVERT(varchar(50),@plan_input_chip) = '') then NULL else @plan_input_chip end
				,[qty_combined] = case when (CONVERT(varchar(50),@qty_combined) = '') then NULL else @qty_combined end
				,[reprint_count] = case when (CONVERT(varchar(50),@reprint_count) = '') then NULL else @reprint_count end
				,[external_lot_no] = case when (CONVERT(varchar(50),@external_lot_no) = '') then NULL else @external_lot_no end
				,[is_3h] = case when (CONVERT(varchar(50),@is_3h) = '') then NULL else @is_3h end
				,[qty_p_nashi] = case when (CONVERT(varchar(50),@qty_p_nashi) = '') then NULL else @qty_p_nashi end
				,[qty_front_ng] = case when (CONVERT(varchar(50),@qty_front_ng) = '') then NULL else @qty_front_ng end
				,[qty_marker] = case when (CONVERT(varchar(50),@qty_marker) = '') then NULL else @qty_marker end
				,[qty_cut_frame] = case when (CONVERT(varchar(50),@qty_cut_frame) = '') then NULL else @qty_cut_frame end
				,[is_temp_divided] = case when (CONVERT(varchar(50),@is_temp_divided) = '') then NULL else @is_temp_divided end
				,[temp_divided_count] = case when (CONVERT(varchar(50),@temp_divided_count) = '') then NULL else @temp_divided_count end
				,[next_sideway_step_no] = case when (CONVERT(varchar(50),@next_sideway_step_no) = '') then NULL else @next_sideway_step_no end
				,[guarantee_lot_id] = case when (CONVERT(varchar(50),@guarantee_lot_id) = '') then NULL else @guarantee_lot_id end
				,[e_slip_id] = case when (CONVERT(varchar(50),@e_slip_id) = '') then NULL else @e_slip_id end
				,[pc_instruction_code] = case when (CONVERT(varchar(50),@pc_instruction_code) = '') then NULL else @pc_instruction_code end
				,[qty_fail_details] = case when (CONVERT(varchar(50),@qty_fail_details) = '') then NULL else @qty_fail_details end	
			WHERE [id] = @lot_id
		END

	INSERT INTO [APCSProDB].[trans].[lot_process_records]([id]
      ,[day_id]
      ,[recorded_at]
      ,[operated_by]
      ,[record_class]
      ,[lot_id]
      ,[process_id]
      ,[job_id]
      ,[step_no]
      ,[qty_in]
      ,[qty_pass]
      ,[qty_fail]
      ,[qty_last_pass]
      ,[qty_last_fail]
      ,[qty_pass_step_sum]
      ,[qty_fail_step_sum]
      ,[qty_divided]
      ,[qty_hasuu]
      ,[qty_out]
      ,[recipe]
      ,[recipe_version]
      ,[machine_id]
      ,[position_id]
      ,[process_job_id]
      ,[is_onlined]
      ,[dbx_id]
      ,[wip_state]
      ,[process_state]
      ,[quality_state]
      ,[first_ins_state]
      ,[final_ins_state]
      ,[is_special_flow]
      ,[special_flow_id]
      ,[is_temp_devided]
      ,[temp_devided_count]
      ,[container_no]
      ,[extend_data]
      ,[std_time_sum]
      ,[pass_plan_time]
      ,[pass_plan_time_up]
      ,[origin_material_id]
      ,[treatment_time]
      ,[wait_time]
      ,[qc_comment_id]
      ,[qc_memo_id]
      ,[created_at]
      ,[created_by]
      ,[updated_at]
      ,[updated_by])
		SELECT [nu].[id] + row_number() over (order by [lots].[id])
		, [days].[id] [day_id]
		, GETDATE() as [recorded_at]
		, 1 as [operated_by]
		, 20 as [record_class]
		, [lots].[id] as [lot_id]
		, [act_process_id] as [process_id]
		, [act_job_id] as [job_id]
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
		, NULL as [recipe]
		, 1 as [recipe_version]
		, [machine_id]
		, NULL as [position_id]
		, [process_job_id]
		, 0 as [is_onlined]
		, 0 as [dbx_id]
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
		, NULL as [extend_data]
		, [std_time_sum]
		, [pass_plan_time]
		, [pass_plan_time_up]
		, [origin_material_id]
		, NULL as [treatment_time]
		, NULL as [wait_time]
		, [qc_comment_id]
		, [qc_memo_id]
		, [created_at]
		, [created_by]
		, GETDATE() as [updated_at]
		, case when (CONVERT(varchar(50),@updated_by) = '') then 1 else @updated_by end as [updated_by]
		FROM [APCSProDB].[trans].[lots] 
		INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
		INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
		WHERE [lots].[id] = @lot_id

		SET @r = @@ROWCOUNT
		 UPDATE [APCSProDB].[trans].[numbers]
		 SET [id] = [id] + @r
		 WHERE [name] = 'lot_process_records.id'
END
