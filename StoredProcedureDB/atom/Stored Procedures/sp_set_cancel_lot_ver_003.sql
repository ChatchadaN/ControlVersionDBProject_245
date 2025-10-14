-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_cancel_lot_ver_003]
	-- Add the parameters for the stored procedure here
	@lot_id varchar(10)
	,@update_by varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	---------------------------------------------------------------------------
	-- Log exec StoredProcedureDB
    ---------------------------------------------------------------------------	
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
		, 'exec [atom].[sp_set_cancel_lot_ver_003] @lot_id = ''' + ISNULL(CAST(@lot_id AS varchar),'') 
			+ ''', @update_by = ''' + ISNULL(CAST(@update_by AS varchar),'') + ''''
		, (select cast(lot_no as varchar) from [APCSProDB].[trans].[lots] where id = @lot_id)
	-----------------------------------------------------------------
	-- DECLARE
	-----------------------------------------------------------------
	DECLARE @update_at VARCHAR(50)
		, @system_name VARCHAR(30) = 'lot stop instruction'
		, @r INT = 0
		, @id INT = 0
		, @num INT = 0
		, @device_slip_id INT
		, @process_id INT
		, @job_id INT
		, @job_step INT
		, @lot_process_record_id INT
		, @lot_hold_control_id INT;

	--set date now  for transition
	SET @update_at = GETDATE();
	-----------------------------------------------------------------
	-- (1) set parameter @device_slip_id,@job_step
	-----------------------------------------------------------------
	-- Find process id and job id by lot_id,device_slip_id and step_no
	SELECT @device_slip_id = [lot_stop_instructions].[device_slip_id]
		, @job_step = [lot_stop_instructions].[stop_step_no]
	FROM [APCSProDB].[trans].[lot_stop_instructions]
	WHERE [lot_stop_instructions].[lot_id] = @lot_id
		AND [lot_stop_instructions].[is_finished] = 0
	-----------------------------------------------------------------
	-- (2) set parameter @process_id,@job_id
	-----------------------------------------------------------------
	SELECT @process_id = processes.id
		, @job_id = job_id
	FROM [APCSProDB].[method].[device_flows]
	INNER JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [device_flows].[act_process_id]
	INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[id] = [device_flows].[job_id]
	WHERE [device_flows].[device_slip_id] = @device_slip_id
		AND [device_flows].[step_no] = @job_step
	-----------------------------------------------------------------
	-- (3) lot_process_records
	-----------------------------------------------------------------
	--get lot_process_record_id
	SELECT @lot_process_record_id = [id] + 1 
	FROM [APCSProDB].[trans].[numbers]
	WHERE [name] = 'lot_process_records.id';
	--update lot_process_record_id
	UPDATE [APCSProDB].[trans].[numbers]
	SET [id] = @lot_process_record_id
	WHERE [name] = 'lot_process_records.id';
	--insert table [trans].[lot_process_records]
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
		, [updated_by])
	SELECT @lot_process_record_id
		, [days].[id] [day_id]
		, @update_at AS [recorded_at]
		, @update_by AS [operated_by]
		, 44 AS [record_class]
		, [lots].[id] AS [lot_id]
		, @process_id AS [process_id]
		, @job_id AS [job_id]
		, @job_step AS [step_no]
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
		, NULL AS [recipe]
		, 1 AS [recipe_version]
		, [machine_id]
		, NULL AS [position_id]
		, [process_job_id]
		, 0 AS [is_onlined]
		, 0 AS [dbx_id]
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
		, NULL AS [extend_data]
		, [std_time_sum]
		, [pass_plan_time]
		, [pass_plan_time_up]
		, [origin_material_id]
		, NULL AS [treatment_time]
		, NULL AS [wait_time]
		, [qc_comment_id]
		, [qc_memo_id]
		, [created_at]
		, [created_by]
		, @update_at AS [updated_at]
		, @update_by AS [updated_by]
	FROM [APCSProDB].[trans].[lots] 
	INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
	WHERE [lots].[id] = @lot_id;
	-----------------------------------------------------------------
	-- (4) lot_stop_instructions
	-----------------------------------------------------------------
	UPDATE [APCSProDB].[trans].[lot_stop_instructions] 
	SET [lot_stop_instructions].[is_finished] = 2
		, [lot_stop_instructions].[updated_at] = @update_at
		, [lot_stop_instructions].[updated_by] = @update_by
	WHERE [lot_stop_instructions].[lot_id] = @lot_id
		AND [lot_stop_instructions].[is_finished] = 0;
END
