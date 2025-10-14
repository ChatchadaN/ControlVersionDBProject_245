-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_cancel_lot_ver_004_test]
	-- Add the parameters for the stored procedure here
	@lot_id VARCHAR(10),
	@update_by VARCHAR(20),
	@stop_step_no INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	---------------------------------------------------------------------------
	-- Log exec StoredProcedureDB
    ---------------------------------------------------------------------------	
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [atom].[sp_set_cancel_lot_ver_004_test] @lot_id = ' + ISNULL(CAST(@lot_id AS VARCHAR),'') 
			+ ', @update_by = ''' + ISNULL(CAST(@update_by AS VARCHAR),'') + ''''
			+ ', @stop_step_no = ' + ISNULL(CAST(@stop_step_no AS VARCHAR),'')
		, (SELECT CAST(lot_no AS VARCHAR) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id)
	-----------------------------------------------------------------
	-- DECLARE
	-----------------------------------------------------------------
	DECLARE @update_at VARCHAR(50)
		, @system_name VARCHAR(30) = 'lot stop instruction'
		, @device_slip_id INT
		, @lot_process_record_id INT;

	--set date now  for transition
	SET @update_at = GETDATE();
	-----------------------------------------------------------------
	-- (1) lot_process_records
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
		( [id]
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
		, [updated_by] )
	SELECT @lot_process_record_id
		, [days].[id] [day_id]
		, @update_at AS [recorded_at]
		, @update_by AS [operated_by]
		, 44 AS [record_class]
		, [lots].[id] AS [lot_id]
		, [lots].[act_process_id] AS [process_id]
		, [lots].[act_job_id] AS [job_id]
		, [lots].[step_no] AS [step_no]
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
	-- (2) lot_stop_instructions
	-----------------------------------------------------------------
	INSERT INTO [APCSProDWH].[atom].[lot_stop_instructions]
	SELECT *
	FROM [APCSProDB].[trans].[lot_stop_instructions] 
	WHERE [lot_id] = @lot_id
		AND [stop_step_no] = @stop_step_no;

	DELETE FROM [APCSProDB].[trans].[lot_stop_instructions] 
	WHERE [lot_id] = @lot_id
		AND [stop_step_no] = @stop_step_no;

	IF NOT EXISTS(
		SELECT [top].[stop_instruction_id]
			, [top].[lot_id] 
			, [top].[step_no] 
			, [top].[is_finished]
			, [top].[emp_num]
			, [top].[count_step]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) 
		CROSS APPLY (
			SELECT [stop_step_no]
			FROM [APCSProDB].[trans].[lot_stop_instructions] WITH (NOLOCK) 
			WHERE [lot_stop_instructions].[lot_id] = [lots].[id]
			GROUP BY [stop_step_no]
		) AS [lot_stop_instructions]
		CROSS APPLY (
			SELECT [lsi].[stop_instruction_id]
				, [lsi].[lot_id] 
				, [lsi].[stop_step_no] AS [step_no] 
				, [lsi].[is_finished]
				, [users].[emp_num]
				, ROW_NUMBER() OVER (PARTITION BY [lsi].[lot_id] ORDER BY [lsi].[stop_instruction_id] DESC) AS [count_step]
			FROM [APCSProDB].[trans].[lot_stop_instructions] AS [lsi] WITH (NOLOCK)
			LEFT JOIN [APCSProDB].[man].[users] WITH (NOLOCK) ON [users].[id] = [lsi].[updated_by]
			WHERE [lsi].[lot_id] = [lots].[id]
				AND [lsi].[stop_step_no] = [lot_stop_instructions].[stop_step_no] 
		) AS [top]
		WHERE [lots].[id] = @lot_id
			AND [lot_stop_instructions].[stop_step_no] > [lots].[step_no]
			AND [top].[count_step] = 1
	)
	BEGIN
		UPDATE [APCSProDB].[trans].[lot_hold_controls] 
		SET [is_held] = 0
			, [updated_at] = @update_at
			, [updated_by] = @update_by
		WHERE [lot_id] = @lot_id
			AND [system_name] = @system_name;
	END
END
