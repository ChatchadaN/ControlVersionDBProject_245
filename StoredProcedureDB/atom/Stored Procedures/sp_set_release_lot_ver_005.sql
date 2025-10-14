
CREATE PROCEDURE [atom].[sp_set_release_lot_ver_005]
	-- Add the parameters for the stored procedure here
	@lot_id INT,
	@update_by INT,
	@lotstoptype INT --# 0:Lot ที่เลือกมา 1:Lot จาก LotCombine
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
		, 'EXEC [atom].[sp_set_release_lot_ver_005] @lot_id = ' + ISNULL(CAST(@lot_id AS VARCHAR(20)),'') 
			+ ', @update_by = ''' + ISNULL(CAST(@update_by AS VARCHAR(20)),'') + ''''
			+ ', @lotstoptype = ' + ISNULL(CAST(@lotstoptype AS VARCHAR(20)),'')
		, (SELECT CAST([lot_no] AS VARCHAR) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id)
	
	--# Lot ลูก and wip_state != 20
	IF (@lotstoptype = 1)
	BEGIN
		DECLARE @chk_wip_state INT
			, @chk_in_stock INT
		SET @chk_wip_state = (SELECT [wip_state] FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id);

		IF (ISNULL(@chk_wip_state,0) != 20)
		BEGIN
			SET @chk_in_stock = (SELECT [in_stock] FROM [APCSProDB].[trans].[surpluses] WHERE [lot_id] = @lot_id);

			IF (@chk_in_stock = 3)
			BEGIN
				UPDATE [APCSProDB].[trans].[surpluses] 
				SET [in_stock] = 2
				WHERE [lot_id] = @lot_id;
			END

			SELECT 'TRUE' AS [Is_Pass]
				, '' AS [Error_Message_ENG]
				, N'' AS [Error_Message_THA] 
				, '' AS [Handling]
			RETURN;
		END

		IF NOT EXISTS (
			SELECT [lot_id] 
			FROM [APCSProDB].[trans].[lot_stop_instructions]
			WHERE [lot_id] = @lot_id
				AND [stop_step_no] = (SELECT [step_no] FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id)
				AND [is_finished] = 1
		)
		BEGIN
			SELECT 'TRUE' AS [Is_Pass]
				, '' AS [Error_Message_ENG]
				, N'' AS [Error_Message_THA] 
				, '' AS [Handling]
			RETURN;
		END
	END
	-----------------------------------------------------------------
	-- DECLARE
	-----------------------------------------------------------------
	DECLARE @update_at VARCHAR(50)
		, @system_name VARCHAR(30) = 'lot stop instruction'
		, @r INT = 0
		, @id INT = 0
		, @num INT = 0
		, @quality_state INT = 0 -- 0:not update 1:update
		, @lot_process_record_id BIGINT
		, @lot_hold_control_id INT;
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
		, [act_process_id] AS [process_id]
		, [act_job_id] AS [job_id]
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
	-- (2) lot_hold_controls
	-----------------------------------------------------------------
	--get lot_hold_control_id
	SELECT @lot_hold_control_id = [id] 
	FROM [APCSProDB].[trans].[lot_hold_controls] 
	WHERE [lot_id] = @lot_id
		AND [system_name] = @system_name;
	--update table [trans].[lot_hold_controls] 
	UPDATE [APCSProDB].[trans].[lot_hold_controls] 
	SET [is_held] = 0
		, [updated_at] = @update_at
		, [updated_by] = @update_by
	WHERE [lot_id] = @lot_id
		AND [system_name] = @system_name;
	--insert table [trans].[lot_hold_control_records]
	INSERT INTO [APCSProDB].[trans].[lot_hold_control_records]
		( [id]
		, [hold_control_id]
		, [lot_id]
		, [system_name]
		, [updated_at]
		, [updated_by]
		, [is_held] )
	SELECT @lot_process_record_id AS [id]
		, @lot_hold_control_id AS [hold_control_id]
		, @lot_id AS [lot_id]
		, @system_name AS [system_name]
		, @update_at AS [updated_at]
		, @update_by AS [updated_by]
		, 0 AS [is_held];
	-----------------------------------------------------------------
	-- (3) quality_state
	-----------------------------------------------------------------
	SET @quality_state = (SELECT status FROM [StoredProcedureDB].[dbo].[AndonCheckState] ((SELECT lot_no FROM APCSProDB.trans.lots WHERE id = @lot_id)))
	IF (@quality_state = 1)
	BEGIN
		--update quality_state = 0
		UPDATE [APCSProDB].[trans].[lots] 
		SET [quality_state] = 0 
		WHERE [lots].[id] = @lot_id;
	END

	SELECT 'TRUE' AS [Is_Pass]
		, '' AS [Error_Message_ENG]
		, N'' AS [Error_Message_THA] 
		, '' AS [Handling]
	RETURN;
END
