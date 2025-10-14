-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_record_class_lot_process_records]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10) = ''
	, @opno VARCHAR(6) = ''
	, @record_class INT = 0  --46 = TG
	, @mcno AS VARCHAR(50) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	DECLARE @r INT = 0;
	DECLARE @process_id INT = NULL
	DECLARE @job_id INT = NULL
	DECLARE @step_no INT = NULL
	DECLARE @user_id INT = (SELECT top 1 id FROM [APCSProDB].[man].[users] WHERE [users].[emp_num] = RIGHT('000000'+ CONVERT(VARCHAR,TRIM(@opno)),6))
	DECLARE @lot_id INT = (SELECT top 1 id FROM [APCSProDB].[trans].[lots] WHERE [lots].[lot_no] = @lot_no)
	DECLARE @mc_id INT = (SELECT top 1 id FROM [APCSProDB].[mc].[machines] WHERE [machines].[name] = @mcno)

	-----------<<< log exec
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no])
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [trans].[sp_set_record_class_lot_process_records] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') + ''', @opno = ''' + ISNULL(CAST(@opno AS varchar),'') + ''', @@record_class = ''' 
			+ ISNULL(CAST(@record_class AS varchar),'') +  ''', @mcno = ''' + ISNULL(CAST(@mcno AS varchar),'') +''''
		, @lot_no
	----------->>> log exec

	IF @user_id IS NOT NULL AND @lot_id IS NOT NULL
	BEGIN

		IF @record_class = 46 or @record_class = 47
		BEGIN
			-----46 SurplusCombined
			SELECT @step_no = [device_flows].[step_no],@job_id = [jobs].[id],@process_id = [jobs].[process_id]
			FROM [APCSProDB].[method].[device_flows]
			INNER JOIN [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
			WHERE [device_flows].[device_slip_id] = (SELECT device_slip_id FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)
				AND [jobs].[name] = 'TSUGITASHI';

			INSERT INTO [APCSProDB].[trans].[lot_process_records]
			(
				[id]
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
				,[updated_by]
				,[act_device_name_id]
				,[device_slip_id]
				,[order_id]
				,[abc_judgement]
				,[held_at]
				,[held_minutes_current]
				,[limit_time_state]
				,[map_edit_state]
				,[qty_frame_in]
				,[qty_frame_pass]
				,[qty_frame_fail]
				,[qty_frame_last_pass]
				,[qty_frame_last_fail]
				,[qty_frame_pass_step_sum]
				,[qty_frame_fail_step_sum]
				,[carrier_no]
				,[next_carrier_no]
				,[production_category]
				,[partition_no]
				,[using_material_spec]
				,[qty_combined]
				,[reprint_count]
				,[is_3h]
				,[running_special_flow_id]
				,[qty_p_nashi]
				,[qty_front_ng]
				,[qty_marker]
				,[qty_cut_frame]
				,[is_temp_divided]
				,[temp_divided_count]
				,[next_sideway_step_no]
				,[e_slip_id]
				,[pc_instruction_code]
				,[qty_fail_details]
			)
			SELECT 
				[nu].[id] + row_number() over (order by [lots].[id]) as [id]
				,[days].[id] as [day_id]
				,GETDATE() as [recorded_at]
				,@user_id as [operated_by]
				,@record_class as [record_class]
				,[lots].[id] as [lot_id]
				,IIF(@process_id is not null,@process_id,[lots].[act_process_id]) as [process_id]
				,IIF(@job_id is not null,@job_id,[lots].[act_job_id]) as [job_id]
				,IIF(@step_no is not null,@step_no,[lots].[step_no]) as [step_no]
				,[lots].[qty_pass] as [qty_in]
				,[lots].[qty_pass] as [qty_pass]
				,[lots].[qty_fail] as [qty_fail] 
				,IIF([lots].[qty_last_pass] = 0 or [lots].[qty_last_pass] is null,[lots].[qty_pass],[lots].[qty_last_pass]) as [qty_last_pass]  --update 2023/08/15 time : 14.10 by Aomsin
				,[lots].[qty_last_fail] as [qty_last_fail]
				,IIF([lots].[qty_pass_step_sum] = 0 or [lots].[qty_pass_step_sum] is null,[lots].[qty_pass],[lots].[qty_pass_step_sum]) as [qty_pass_step_sum]  ---Good --update 2023/08/15 time : 14.19 by Aomsin
				,[lots].[qty_fail_step_sum] as [qty_fail_step_sum]  ---NG
				,0 as [qty_divided]
				,[lots].[qty_hasuu] as [qty_hasuu]  ---Surplus
				,[lots].[qty_out] as [qty_out]  ---Shipment
				,NULL as [recipe]
				,1 as [recipe_version]
				,ISNULL(@mc_id,1381) as [machine_id]
				,NULL as [position_id]
				,NULL as [process_job_id]
				,0 as [is_onlined]
				,0 as [dbx_id]
				,20 as [wip_state]
				,0 as [process_state]
				,0 as [quality_state]
				,0 as [first_ins_state]
				,0 as [final_ins_state]
				,0 as [is_special_flow]
				,NULL as [special_flow_id]
				,0 as [is_temp_devided]
				,NULL as [temp_devided_count]
				,[lots].[container_no] as [container_no]
				,NULL as [extend_data]
				,NULL as [std_time_sum]
				,NULL as [pass_plan_time]
				,NULL as [pass_plan_time_up]
				,NULL as [origin_material_id]
				,NULL as [treatment_time]
				,NULL as [wait_time]
				,[lots].[qc_comment_id] as [qc_comment_id]
				,[lots].[qc_memo_id] as [qc_memo_id]
				,[lots].[created_at] as [created_at]
				,[lots].[created_by] as [created_by]
				,GETDATE() as [updated_at]
				,@user_id as [updated_by]
				,NULL as [act_device_name_id]
				,NULL as [device_slip_id]
				,NULL as [order_id]
				,NULL as [abc_judgement]
				,NULL as [held_at]
				,NULL as [held_minutes_current]
				,NULL as  [limit_time_state]
				,NULL as [map_edit_state]
				,[lots].[qty_frame_pass] as [qty_frame_in]
				,[lots].[qty_frame_pass] as [qty_frame_pass]  ---FramesGood
				,[lots].[qty_frame_fail] as [qty_frame_fail]  ---FramesNG
				,NULL as [qty_frame_last_pass]
				,NULL as [qty_frame_last_fail]
				,NULL as [qty_frame_pass_step_sum]
				,NULL as [qty_frame_fail_step_sum]
				,IIF(@record_class = 46,NULL,[lots].[carrier_no]) as [carrier_no]  ---CarrierNo
				,NULL as [next_carrier_no]
				,[lots].[production_category] as [production_category]
				,[lots].[partition_no] as [partition_no]
				,[lots].[using_material_spec] as [using_material_spec]
				,IIF(@record_class = 46,[lots].[qty_combined],NULL) as [qty_combined]  ---Combined
				,NULL as [reprint_count]
				,NULL as [is_3h]
				,NULL as [running_special_flow_id]
				,[lots].[qty_p_nashi] as [qty_p_nashi]  ---PNashi
				,[lots].[qty_front_ng] as [qty_front_ng]  ---FrontNG
				,[lots].[qty_marker] as [qty_marker]  ---Marker
				,[lots].[qty_cut_frame] as [qty_cut_frame]
				,NULL as [is_temp_divided]
				,NULL as [temp_divided_count]
				,NULL as [next_sideway_step_no]
				,NULL as [e_slip_id]
				,NULL as [pc_instruction_code]
				,NULL as [qty_fail_details]
			FROM [APCSProDB].[trans].[lots] 
			INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
			INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
			WHERE [lots].[id] = @lot_id;

			SET @r = @@ROWCOUNT
			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = [id] + @r
			WHERE [name] = 'lot_process_records.id';

		END
		ELSE
		BEGIN
			INSERT INTO [APCSProDB].[trans].[lot_process_records]
			(
				[id]
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
				,[updated_by]
				,[act_device_name_id]
				,[device_slip_id]
				,[order_id]
				,[abc_judgement]
				,[held_at]
				,[held_minutes_current]
				,[limit_time_state]
				,[map_edit_state]
				,[qty_frame_in]
				,[qty_frame_pass]
				,[qty_frame_fail]
				,[qty_frame_last_pass]
				,[qty_frame_last_fail]
				,[qty_frame_pass_step_sum]
				,[qty_frame_fail_step_sum]
				,[carrier_no]
				,[next_carrier_no]
				,[production_category]
				,[partition_no]
				,[using_material_spec]
				,[qty_combined]
				,[reprint_count]
				,[is_3h]
				,[running_special_flow_id]
				,[qty_p_nashi]
				,[qty_front_ng]
				,[qty_marker]
				,[qty_cut_frame]
				,[is_temp_divided]
				,[temp_divided_count]
				,[next_sideway_step_no]
				,[e_slip_id]
				,[pc_instruction_code]
				,[qty_fail_details]
			)
			SELECT 
				[nu].[id] + row_number() over (order by [lots].[id]) as [id]
				,[days].[id] as [day_id]
				,GETDATE() as [recorded_at]
				,@user_id as [operated_by]
				,@record_class as [record_class]
				,[lots].[id] as [lot_id]
				,[lots].[act_process_id] as [process_id]
				,[lots].[act_job_id] as [job_id]
				,[lots].[step_no] as [step_no]
				,[lots].[qty_pass] as [qty_in]
				,[lots].[qty_pass] as [qty_pass]
				,[lots].[qty_fail] as [qty_fail] 
				,[lots].[qty_last_pass] as [qty_last_pass]
				,[lots].[qty_last_fail] as [qty_last_fail]
				,[lots].[qty_pass_step_sum] as [qty_pass_step_sum]  ---Good
				,[lots].[qty_fail_step_sum] as [qty_fail_step_sum]  ---NG
				,[lots].[qty_divided] as [qty_divided]
				,[lots].[qty_hasuu] as [qty_hasuu]  ---Surplus
				,[lots].[qty_out] as [qty_out]  ---Shipment
				,NULL as [recipe]
				,1 as [recipe_version]
				,[lots].[machine_id] as [machine_id]
				,NULL as [position_id]
				,NULL as [process_job_id]
				,0 as [is_onlined]
				,0 as [dbx_id]
				,[lots].[wip_state] as [wip_state]
				,[lots].[process_state] as [process_state]
				,[lots].[quality_state] as [quality_state]
				,[lots].[first_ins_state] as [first_ins_state]
				,[lots].[final_ins_state] as [final_ins_state]
				,[lots].[is_special_flow] as [is_special_flow]
				,[lots].[special_flow_id] as [special_flow_id]
				,[lots].[is_temp_devided] as [is_temp_devided]
				,[lots].[temp_devided_count] as [temp_devided_count]
				,[lots].[container_no] as [container_no]
				,NULL as [extend_data]
				,[lots].[std_time_sum] as [std_time_sum]
				,[lots].[pass_plan_time] as [pass_plan_time]
				,[lots].[pass_plan_time_up] as [pass_plan_time_up]
				,[lots].[origin_material_id] as [origin_material_id]
				,NULL as [treatment_time]
				,NULL as [wait_time]
				,[lots].[qc_comment_id] as [qc_comment_id]
				,[lots].[qc_memo_id] as [qc_memo_id]
				,[lots].[created_at] as [created_at]
				,[lots].[created_by] as [created_by]
				,GETDATE() as [updated_at]
				,@user_id as [updated_by]
				,[lots].[act_device_name_id] as [act_device_name_id]
				,[lots].[device_slip_id] as [device_slip_id]
				,[lots].[order_id] as [order_id]
				,NULL as [abc_judgement]
				,[lots].[held_at] as [held_at]
				,[lots].[held_minutes_current] as [held_minutes_current]
				,[lots].[limit_time_state] as  [limit_time_state]
				,[lots].[map_edit_state] as [map_edit_state]
				,[lots].[qty_frame_pass] as [qty_frame_in]
				,[lots].[qty_frame_pass] as [qty_frame_pass]  ---FramesGood
				,[lots].[qty_frame_fail] as [qty_frame_fail]  ---FramesNG
				,[lots].[qty_frame_last_pass] as [qty_frame_last_pass]
				,[lots].[qty_frame_last_fail] as [qty_frame_last_fail]
				,[lots].[qty_frame_pass_step_sum] as [qty_frame_pass_step_sum]
				,[lots].[qty_frame_fail_step_sum] as [qty_frame_fail_step_sum]
				,[lots].[carrier_no] as [carrier_no]  ---CarrierNo
				,[lots].[next_carrier_no] as [next_carrier_no]
				,[lots].[production_category] as [production_category]
				,[lots].[partition_no] as [partition_no]
				,[lots].[using_material_spec] as [using_material_spec]
				,[lots].[qty_combined] as [qty_combined]  ---Combined
				,[lots].[reprint_count] as [reprint_count]
				,[lots].[is_3h] as [is_3h]
				,NULL as [running_special_flow_id]
				,[lots].[qty_p_nashi] as [qty_p_nashi]  ---PNashi
				,[lots].[qty_front_ng] as [qty_front_ng]  ---FrontNG
				,[lots].[qty_marker] as [qty_marker]  ---Marker
				,[lots].[qty_cut_frame] as [qty_cut_frame]
				,[lots].[is_temp_divided] as [is_temp_divided]
				,[lots].[temp_divided_count] as [temp_divided_count]
				,[lots].[next_sideway_step_no] as [next_sideway_step_no]
				,[lots].[e_slip_id] as [e_slip_id]
				,[lots].[pc_instruction_code] as [pc_instruction_code]
				,[lots].[qty_fail_details] as [qty_fail_details]
			FROM [APCSProDB].[trans].[lots] 
			INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
			INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
			WHERE [lots].[id] = @lot_id;

			SET @r = @@ROWCOUNT
			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = [id] + @r
			WHERE [name] = 'lot_process_records.id';
		END

		

		--SELECT 'TRUE' as [Is_Pass]
	END
	--ELSE BEGIN
	--	--SELECT 'FALSE' as [Is_Pass]
	--END
	
END
