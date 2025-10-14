-- =============================================
-- =============================================
CREATE PROCEDURE [atom].[sp_set_data_by_lot_and_stepno]
	-- Add the parameters for the stored procedure here
	@lot_id int
	, @step_no int
	, @updated_by int
	, @qty_p_nashi int
	, @qty_pass_step_sum int
	, @qty_fail_step_sum int
	, @qty_front_ng int
	, @qty_marker int
	, @qty_combined int
	, @qty_hasuu int
	, @qty_out int
	, @qty_frame_pass int
	, @qty_frame_fail int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @record_class int = 2
		, @record_max_id int = NULL
		, @max_step_no int = NULL

	----------------(log before trans.lot_process_records)----------------
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	(
	    [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [atom].[sp_set_data_by_lot_and_stepno] [trans.lot_process_records before]'
			+ ' @lot_id = ' + ISNULL(CAST([lot_id] AS varchar),'')
			+ ' ,@step_no = ' + ISNULL(CAST([step_no] AS varchar),'')
			+ ' ,@qty_p_nashi = ' + ISNULL(CAST([qty_p_nashi] AS varchar),'')
			+ ' ,@qty_pass_step_sum = ' + ISNULL(CAST([qty_pass_step_sum] AS varchar),'')
			+ ' ,@qty_fail_step_sum = ' + ISNULL(CAST([qty_fail_step_sum] AS varchar),'')
			+ ' ,@qty_front_ng = ' + ISNULL(CAST([qty_front_ng] AS varchar),'')
			+ ' ,@qty_marker = ' + ISNULL(CAST([qty_marker] AS varchar),'')
			+ ' ,@qty_combined = ' + ISNULL(CAST([qty_combined] AS varchar),'')
			+ ' ,@qty_hasuu = ' + ISNULL(CAST([qty_hasuu] AS varchar),'')
			+ ' ,@qty_out = ' + ISNULL(CAST([qty_out] AS varchar),'')
			+ ' ,@qty_frame_pass = ' + ISNULL(CAST([qty_frame_pass] AS varchar),'')
			+ ' ,@qty_frame_fail = ' + ISNULL(CAST([qty_frame_fail] AS varchar),'')
			+ ' ,@updated_by = ' + ISNULL(CAST([updated_by] AS varchar),'')
		, (select cast(lot_no as varchar) from [APCSProDB].[trans].[lots] where id = lot_id)
	from APCSProDB.trans.lot_process_records
	where lot_id = @lot_id
		and step_no = @step_no
		and record_class = @record_class
	----------------(log before trans.lot_process_records)----------------

	----------------(update trans.lot_process_records)----------------
	update [APCSProDB].[trans].[lot_process_records] 
	set [qty_p_nashi] = @qty_p_nashi
		, [qty_pass_step_sum] = @qty_pass_step_sum
		, [qty_fail_step_sum] = @qty_fail_step_sum
		, [qty_front_ng] = @qty_front_ng
		, [qty_marker] = @qty_marker
		, [qty_combined] = @qty_combined
		, [qty_hasuu] = @qty_hasuu
		, [qty_out] = @qty_out
		, [qty_frame_pass] = @qty_frame_pass
		, [qty_frame_fail] = @qty_frame_fail
		, [updated_by] = @updated_by
	where [lot_process_records].[lot_id] = @lot_id
		and [lot_process_records].[step_no] = @step_no
		and [lot_process_records].record_class = @record_class
	----------------(update trans.lot_process_records)----------------

	DECLARE @r INT = 0;
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
		, [qty_fail_details] )
	SELECT TOP 1 [nu].[id] + row_number() over (order by [lot_process_records].[id] DESC)
		, [days].[id] AS [day_id]
		, GETDATE() AS [recorded_at]
		, @updated_by AS [operated_by]
		, 20 AS [record_class]
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
		, NULL AS [machine_id]
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
		, [qty_fail_details]
	FROM [APCSProDB].[trans].[lot_process_records] 
	INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
	INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'lot_process_records.id'
	WHERE [lot_id] = @lot_id
		AND [step_no] = @step_no
		AND [record_class] = @record_class
	ORDER BY [lot_process_records].[id] DESC;

	SET @r = @@ROWCOUNT
	UPDATE [APCSProDB].[trans].[numbers]
	SET [id] = [id] + @r
	WHERE [name] = 'lot_process_records.id';

	----------------(log after trans.lot_process_records)----------------
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	(
	    [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [atom].[sp_set_data_by_lot_and_stepno] [trans.lot_process_records after]'
			+ ' @lot_id = ' + ISNULL(CAST([lot_id] AS varchar),'')
			+ ' ,@step_no = ' + ISNULL(CAST([step_no] AS varchar),'')
			+ ' ,@qty_p_nashi = ' + ISNULL(CAST([qty_p_nashi] AS varchar),'')
			+ ' ,@qty_pass_step_sum = ' + ISNULL(CAST([qty_pass_step_sum] AS varchar),'')
			+ ' ,@qty_fail_step_sum = ' + ISNULL(CAST([qty_fail_step_sum] AS varchar),'')
			+ ' ,@qty_front_ng = ' + ISNULL(CAST([qty_front_ng] AS varchar),'')
			+ ' ,@qty_marker = ' + ISNULL(CAST([qty_marker] AS varchar),'')
			+ ' ,@qty_combined = ' + ISNULL(CAST([qty_combined] AS varchar),'')
			+ ' ,@qty_hasuu = ' + ISNULL(CAST([qty_hasuu] AS varchar),'')
			+ ' ,@qty_out = ' + ISNULL(CAST([qty_out] AS varchar),'')
			+ ' ,@qty_frame_pass = ' + ISNULL(CAST([qty_frame_pass] AS varchar),'')
			+ ' ,@qty_frame_fail = ' + ISNULL(CAST([qty_frame_fail] AS varchar),'')
			+ ' ,@updated_by = ' + ISNULL(CAST([updated_by] AS varchar),'')
		, (select cast(lot_no as varchar) from [APCSProDB].[trans].[lots] where id = lot_id)
	from APCSProDB.trans.lot_process_records
	where lot_id = @lot_id
		and step_no = @step_no
		and record_class = @record_class
	----------------(log after trans.lot_process_records)----------------
	print('update trans.lot_process_records success')
	
	----------------(check last step no)----------------
	SET @record_max_id = (select max([id]) from [APCSProDB].[trans].[lot_process_records] where [lot_id] = @lot_id and [record_class] = @record_class)
	SET @max_step_no = (select [step_no] from [APCSProDB].[trans].[lot_process_records] where [id] = @record_max_id)
	----------------(check last step no)----------------

	----------------(check update trans.lots)----------------
	IF (@step_no = @max_step_no)
	BEGIN
		----------------(log before trans.lots)----------------
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		(
			[record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no]
		)
		SELECT GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, 'EXEC [atom].[sp_set_data_by_lot_and_stepno] [trans.lots before]'
				+ ' @lot_id = ' + ISNULL(CAST([id] AS varchar),'')
				+ ' ,@step_no = ' + ISNULL(CAST([step_no] AS varchar),'')
				+ ' ,@qty_p_nashi = ' + ISNULL(CAST([qty_p_nashi] AS varchar),'')
				+ ' ,@qty_pass = ' + ISNULL(CAST([qty_pass] AS varchar),'')
				+ ' ,@qty_fail = ' + ISNULL(CAST([qty_fail] AS varchar),'')
				+ ' ,@qty_front_ng = ' + ISNULL(CAST([qty_front_ng] AS varchar),'')
				+ ' ,@qty_marker = ' + ISNULL(CAST([qty_marker] AS varchar),'')
				+ ' ,@qty_combined = ' + ISNULL(CAST([qty_combined] AS varchar),'')
				+ ' ,@qty_hasuu = ' + ISNULL(CAST([qty_hasuu] AS varchar),'')
				+ ' ,@qty_out = ' + ISNULL(CAST([qty_out] AS varchar),'')
				+ ' ,@qty_frame_pass = ' + ISNULL(CAST([qty_frame_pass] AS varchar),'')
				+ ' ,@qty_frame_fail = ' + ISNULL(CAST([qty_frame_fail] AS varchar),'')
				+ ' ,@updated_by = ' + ISNULL(CAST([updated_by] AS varchar),'')
			, lot_no
		from APCSProDB.trans.lots
		where [id] = @lot_id
		----------------(log before trans.lots)----------------

		----------------(update trans.lots)----------------
		update [APCSProDB].[trans].[lots] 
		set [qty_p_nashi] = @qty_p_nashi
			, [qty_pass] = (@qty_pass_step_sum - (@qty_front_ng + @qty_marker))
			, [qty_fail] = ([lots].[qty_fail] + @qty_fail_step_sum + @qty_front_ng + @qty_marker)
			, [qty_front_ng] = @qty_front_ng
			, [qty_marker] = @qty_marker
			, [qty_combined] = @qty_combined
			, [qty_hasuu] = @qty_hasuu
			, [qty_out] = @qty_out
			, [qty_frame_pass] = @qty_frame_pass
			, [qty_frame_fail] = @qty_frame_fail
			, [updated_by] = @updated_by
		where [lots].[id] = @lot_id
		----------------(update trans.lots)----------------



		----------------(log after trans.lots)----------------
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		(
			[record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no]
		)
		SELECT GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, 'EXEC [atom].[sp_set_data_by_lot_and_stepno] [trans.lots after]'
				+ ' @lot_id = ' + ISNULL(CAST([id] AS varchar),'')
				+ ' ,@step_no = ' + ISNULL(CAST([step_no] AS varchar),'')
				+ ' ,@qty_p_nashi = ' + ISNULL(CAST([qty_p_nashi] AS varchar),'')
				+ ' ,@qty_pass = ' + ISNULL(CAST([qty_pass] AS varchar),'')
				+ ' ,@qty_fail = ' + ISNULL(CAST([qty_fail] AS varchar),'')
				+ ' ,@qty_front_ng = ' + ISNULL(CAST([qty_front_ng] AS varchar),'')
				+ ' ,@qty_marker = ' + ISNULL(CAST([qty_marker] AS varchar),'')
				+ ' ,@qty_combined = ' + ISNULL(CAST([qty_combined] AS varchar),'')
				+ ' ,@qty_hasuu = ' + ISNULL(CAST([qty_hasuu] AS varchar),'')
				+ ' ,@qty_out = ' + ISNULL(CAST([qty_out] AS varchar),'')
				+ ' ,@qty_frame_pass = ' + ISNULL(CAST([qty_frame_pass] AS varchar),'')
				+ ' ,@qty_frame_fail = ' + ISNULL(CAST([qty_frame_fail] AS varchar),'')
				+ ' ,@updated_by = ' + ISNULL(CAST([updated_by] AS varchar),'')
			, lot_no
		from APCSProDB.trans.lots
		where [id] = @lot_id
		----------------(log after trans.lots)----------------

		print('update trans.lot success')
	END
	------------------(check update trans.lots)----------------
END
