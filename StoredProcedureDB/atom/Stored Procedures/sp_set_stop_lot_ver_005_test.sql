-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create 20210731,,>
-- Description:	<Description,,Stop Lot>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_stop_lot_ver_005_test] 
	-- Add the parameters for the stored procedure here
	@lot_id VARCHAR(10),
	@job_step INT,
	@comment_id INT,
	@update_by VARCHAR(20)
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
		, 'EXEC [atom].[sp_set_stop_lot_ver_005_test] @lot_id = ' + ISNULL(CAST(@lot_id AS VARCHAR),'') 
			+ ', @job_step = ' + ISNULL(CAST(@job_step AS VARCHAR),'NULL')
			+ ', @comment_id = ' + ISNULL(CAST(@comment_id AS VARCHAR),'NULL')
			+ ', @update_by = ''' + ISNULL(CAST(@update_by AS VARCHAR),'NULL') + ''''
		, (SELECT CAST([lot_no] AS VARCHAR) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id)
	-----------------------------------------------------------------
	DECLARE @update_at VARCHAR(50)
		, @system_name VARCHAR(30) = 'lot stop instruction'
		, @current_step INT
		, @lot_process_record_id INT
		, @lot_hold_control_id INT
		, @stop_instruction_id INT
		, @process_state INT
		, @device_slip_id INT
		, @next_step INT
		, @is_held INT = 1
		, @is_finished INT = 1
		, @state INT;
	--set date now  for transition
	SET @update_at = GETDATE();

	SELECT @current_step = [lots].[step_no]
		, @process_state = [lots].[process_state]
		, @device_slip_id = [lots].[device_slip_id]
		, @next_step = [device_flows].[next_step_no] 
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_flows] ON [lots].[device_slip_id] = [device_flows].[device_slip_id] 
		AND [lots].[step_no] = [device_flows].[step_no] 
	WHERE [lots].[id] =  @lot_id;

	BEGIN TRANSACTION
	BEGIN TRY
		-----------------------------------------------------------------
		-- (1) update quality_state
		-----------------------------------------------------------------
		IF (@current_step >= @job_step)
		BEGIN
			SET @state = 0;
			IF (ISNULL(@process_state, 0) NOT IN (2,102) OR @current_step > @job_step)
			BEGIN
				UPDATE [APCSProDB].[trans].[lots] 
				SET [quality_state] = 1 
				WHERE [id] = @lot_id; 
			END
		END
		ELSE
		BEGIN
			SET @state = 1;
		END

		IF (@current_step != @job_step)
		BEGIN
			SET @is_held = 0; 
		END
		-----------------------------------------------------------------
		-- (2) lot_process_records
		-----------------------------------------------------------------
		--get lot_process_record_id
		SELECT @lot_process_record_id = [id] + 1 
		FROM [APCSProDB].[trans].[numbers]
		WHERE [name] = 'lot_process_records.id'
		--update lot_process_record_id
		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = @lot_process_record_id
		WHERE [name] = 'lot_process_records.id';
		--insert lot_process_recodes
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
			, 48 AS [record_class]
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
		-- (3) lot_hold_controls
		-----------------------------------------------------------------
		--check exists trans.lot_hold_controls 
		IF EXISTS (SELECT [lot_hold_controls].[id] 
			FROM [APCSProDB].[trans].[lot_hold_controls] 
			WHERE [lot_hold_controls].[lot_id] = @lot_id
				AND [lot_hold_controls].[system_name] = @system_name
		)
		BEGIN
			--get lot_hold_control_id
			SELECT @lot_hold_control_id = [id] 
			FROM [APCSProDB].[trans].[lot_hold_controls] 
			WHERE [lot_id] = @lot_id
				AND [system_name] = @system_name;
			--update trans.lot_hold_controls 
			UPDATE [APCSProDB].[trans].[lot_hold_controls]
			SET [is_held] = @is_held
				, [updated_at] = @update_at
				, [updated_by] = @update_by
			WHERE [lot_id] = @lot_id
				AND [system_name] = @system_name;
		END
		ELSE
		BEGIN
			--get lot_hold_control_id
			SELECT @lot_hold_control_id = [id] + 1
			FROM [APCSProDB].[trans].[numbers]
			WHERE [name] = 'lot_hold_controls.id';
			--update lot_hold_control_id
			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = @lot_hold_control_id
			WHERE [name] = 'lot_hold_controls.id';
			--insert trans.lot_hold_controls
			INSERT INTO [APCSProDB].[trans].[lot_hold_controls]
				( [id]
				, [lot_id]
				, [system_name]
				, [is_held]
				, [updated_at]
				, [updated_by] )
			VALUES
				( @lot_hold_control_id
				, @lot_id
				, @system_name 
				, @is_held 
				, @update_at
				, @update_by );
		END
		-----------------------------------------------------------------
		-- (4) lot_hold_control_records
		-----------------------------------------------------------------
		--insert table trans.lot_hold_control_records
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
			, @is_held AS [is_held];
		-----------------------------------------------------------------
		-- (5) lot_stop_instructions
		-----------------------------------------------------------------
		--get stop_instruction_id
		SELECT @stop_instruction_id = [id] + 1
		FROM [APCSProDB].[trans].[numbers]
		WHERE [name] = 'lot_stop_instructions.stop_instruction_id';
		--update stop_instruction_id
		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = @stop_instruction_id
		WHERE [name] = 'lot_stop_instructions.stop_instruction_id';
		--insert table [trans].[lot_stop_instructions]
		INSERT INTO [APCSProDB].[trans].[lot_stop_instructions]
			( [stop_instruction_id]
			, [device_slip_id]
			, [stop_step_no]
			, [display_message_id]
			, [is_finished]
			, [updated_at]
			, [updated_by]
			, [instruction_record_id]
			, [lot_id] )
		SELECT @stop_instruction_id AS [stop_instruction_id]
			, @device_slip_id AS [device_slip_id]
			, IIF( @process_state = 0, @job_step, @next_step ) AS [stop_step_no]
			, @comment_id AS [display_message_id]
			, @is_finished AS [is_finished]
			, @update_at AS [updated_at]
			, @update_by AS [updated_by]
			, @lot_process_record_id AS [instruction_record_id]
			, @lot_id AS [lot_id];
		COMMIT
	END TRY
	BEGIN CATCH
		ROLLBACK
	END CATCH
END
