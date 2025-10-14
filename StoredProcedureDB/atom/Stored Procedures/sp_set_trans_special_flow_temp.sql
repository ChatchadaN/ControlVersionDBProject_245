-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_special_flow_temp]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @r INT = 0;
	DECLARE @special_flow_id INT;
	DECLARE @lot_id INT = NULL;
	DECLARE @step_no INT = NULL;
	DECLARE @back_step_no INT;
	DECLARE @user_id INT = 1;
	DECLARE @flow_pattern_id INT = 1267;
	DECLARE @is_special_flow INT = 1;
	DECLARE @device_slip_id INT;

	select @lot_id = id, @back_step_no = step_no, @device_slip_id = device_slip_id from [APCSProDB].[trans].[lots] where [lot_no] = @lot_no and process_state = 0 and quality_state != 4
	SELECT @step_no = [step_no] FROM [APCSProDB].[method].[device_flows] where device_slip_id  = @device_slip_id and next_step_no = @back_step_no and is_skipped = '0'
    
	IF (@lot_id is not null)
	BEGIN
		-- Insert statements for procedure here
		INSERT INTO [APCSProDB].[trans].[special_flows]
		([id]
      ,[lot_id]
      ,[step_no]
      ,[back_step_no]
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
      ,[is_exist_work]
      ,[wip_state]
      ,[process_state]
      ,[quality_state]
      ,[first_ins_state]
      ,[final_ins_state]
      ,[priority]
      ,[finish_date_id]
      ,[finished_at]
      ,[machine_id]
      ,[container_no]
      ,[qc_comment_id]
      ,[qc_memo_id]
      ,[process_job_id]
      ,[carried_at]
      ,[is_special_flow]
      ,[special_flow_id]
      ,[instruction_reason_id]
      ,[start_special_message_id]
      ,[finish_special_message_id]
      ,[holded_at]
      ,[created_at]
      ,[created_by]
      ,[updated_at]
      ,[updated_by]
      ,[limit_time_state]
      ,[map_edit_state]
		)
		SELECT [nu].[id] + row_number() over (order by [lots].[id])
		, [lots].[id]
		, @step_no + 1
		, @back_step_no
		, [lots].[qty_pass]
		, [lots].[qty_pass]
		, 0 as [qty_fail]
		, NULL as [qty_last_pass]
		, NULL as [qty_last_fail]
		, NULL as [qty_pass_step_sum]
		, NULL as [qty_fail_step_sum]
		, NULL as [qty_divided]
		, NULL as [qty_hasuu]
		, NULL as [qty_out]
		, 0 as [is_exist_work]
		, 20 as [wip_state]
		, 0 as [process_state]
		, 0 as [quality_state]
		, 0 as [first_ins_state]
		, 0 as [final_ins_state]
		, [lots].[priority]
		, [lots].[finish_date_id]
		, [lots].[finished_at]
		, -1 as [machine_id]
		, [lots].[container_no]
		, NULL as [qc_comment_id]
		, NULL as [qc_memo_id]
		, NULL as [process_job_id]
		, [lots].[carried_at]
		, 0 as [is_special_flow_id]
		, NULL as [special_flow_id]
		, NULL as [instruction_reason_id]
		, NULL as [start_special_message_id]
		, NULL as [finish_special_message_id]
		, NULL as [holded_at]
		, GETDATE() as [created_at]
		, @user_id as [created_by]
		, NULL as [updated_at]
		, NULL as [updated_by]
		, NULL as [limit_time_state]
		, NULL as [map_edit_state]
		FROM [APCSProDB].[trans].[lots] 
		INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'special_flows.id'
		WHERE [lots].[id] = @lot_id

		SET @r = @@ROWCOUNT
		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = [id] + @r
		, @special_flow_id = [id] + @r
		WHERE [name] = 'special_flows.id'

		INSERT INTO [APCSProDB].[trans].[lot_special_flows]
		([id]
      ,[special_flow_id]
      ,[step_no]
      ,[next_step_no]
      ,[act_process_id]
      ,[job_id]
      ,[act_package_flow_id]
      ,[permitted_machine_id]
      ,[process_minutes]
      ,[sum_process_minutes]
      ,[recipe]
      ,[ng_retest_permitted]
      ,[is_skipped]
      ,[material_set_id]
      ,[jig_set_id]
      ,[data_collection_id]
      ,[yield_lcl]
      ,[ng_category_cnt]
      ,[label_issue_id]
		)
		SELECT [nu].[id] + row_number() over (order by [flow_details].[flow_pattern_id])
		, @special_flow_id
		, @step_no + row_number() over (order by [flow_details].[flow_pattern_id])
		, @step_no + row_number() over (order by [flow_details].[flow_pattern_id]) + 1
		, [jobs].[process_id]
		, [jobs].[id]
		, [lots].[act_package_id] AS [act_package_flow_id]
		, 0 AS [permitted_machine_id]
		, 0 AS [process_minutes]
		, 0 AS [sum_process_minutes]
		, NULL AS [recipe]
		, 0 AS [ng_retest_permitted]
		, 0 AS [is_skipped]
		, NULL AS [material_set_id]
		, NULL AS [jig_set_id]
		, NULL AS [data_collection_id]
		, NULL AS [yield_lcl]
		, NULL AS [ng_category_cnt]
		, 0 AS [issue_label_type]
		FROM [APCSProDB].[method].[flow_details] 
		INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_special_flows.id'
		INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
		INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = @lot_id
		WHERE [flow_details].[flow_pattern_id] = @flow_pattern_id

		SET @r = @@ROWCOUNT
		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = [id] + @r
		WHERE [name] = 'lot_special_flows.id'

		UPDATE [APCSProDB].[trans].[lot_special_flows]
		SET [next_step_no] = @step_no + @r
		WHERE [special_flow_id] = @special_flow_id AND [next_step_no] = @step_no + @r + 1

		IF (@is_special_flow = 1)
			UPDATE [APCSProDB].[trans].[lots]
			SET [quality_state] = 4
			, [is_special_flow] = 1
			, [special_flow_id] = @special_flow_id
			, [updated_at] = GETDATE()
			, [updated_by] = @user_id
			WHERE [lots].[id] = @lot_id;
		ELSE
			UPDATE [APCSProDB].[trans].[lots]
			SET [special_flow_id] = @special_flow_id
			, [updated_at] = GETDATE()
			, [updated_by] = @user_id
			WHERE [lots].[id] = @lot_id;
		

		INSERT INTO [APCSProDB].[trans].[lot_process_records]
		([id]
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
      ,[map_edit_state])
		SELECT [nu].[id] + row_number() over (order by [lots].[id])
		, [days].[id] [day_id]
		, GETDATE() as [recorded_at]
		, @user_id as [operated_by]
		, 25 as [record_class]
		, [lots].[id] as [lot_id]
		, [act_process_id] as [process_id]
		, [act_job_id] as [job_id]
		, [step_no]
		, [qty_pass] as [qty_in]
		, [qty_pass]
		, 0 as [qty_fail]
		, NULL as [qty_last_pass]
		, NULL as [qty_last_fail]
		, NULL as [qty_pass_step_sum]
		, NULL as [qty_fail_step_sum]
		, NULL as [qty_divided]
		, NULL as [qty_hasuu]
		, NULL as [qty_out]
		, NULL as [recipe]
		, 1 as [recipe_version]
		, -1 as [machine_id]
		, NULL as [position_id]
		, NULL as [process_job_id]
		, 0 as [is_onlined]
		, 0 as [dbx_id]
		, 20 as [wip_state]
		, 0 as [process_state]
		, 4 as [quality_state]
		, 0 as [first_ins_state]
		, 0 as [final_ins_state]
		, 1 as [is_special_flow]
		, @special_flow_id as [special_flow_id]
		, 0 as [is_temp_devided]
		, NULL as [temp_devided_count]
		, NULL as [container_no]
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
		, @user_id as [updated_by]
		, NULL as [act_device_name_id]
		, NULL as [device_slip_id]
		, NULL as [order_id]
		, NULL as [abc_judgement]
		, NULL as [held_at]
		, NULL as [held_minutes_current]
		, NULL as [limit_time_state]
		, NULL as [map_edit_state]
		FROM [APCSProDB].[trans].[lots] 
		INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
		INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
		WHERE [lots].[id] = @lot_id

		SET @r = @@ROWCOUNT
		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = [id] + @r
		WHERE [name] = 'lot_process_records.id'

	END

	SELECT [special_flow_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id
END
