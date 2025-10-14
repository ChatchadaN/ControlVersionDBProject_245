-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create 20210731,,>
-- Description:	<Description,,Stop Lot>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_stop_lot_ver_002] 
	-- Add the parameters for the stored procedure here
	@lot_id varchar(10)
	,@job_step int
	,@comment_id int
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
		, 'exec [atom].[sp_set_stop_lot_ver_002] @lot_id = ''' + ISNULL(CAST(@lot_id AS varchar),'') 
			+ ''', @job_step = ''' + ISNULL(CAST(@job_step AS varchar),'') + ''
			+ ''', @comment_id = ''' + ISNULL(CAST(@comment_id AS varchar),'') + ''
			+ ''', @update_by = ''' + ISNULL(CAST(@update_by AS varchar),'') + ''''
		, (select cast(lot_no as varchar) from [APCSProDB].[trans].[lots] where id = @lot_id)
	-----------------------------------------------------------------
	DECLARE @update_at VARCHAR(50)
		, @system_name VARCHAR(30) = 'lot stop instruction'
		, @current_step INT
		, @member_lot INT
		, @device_slip_id INT
		, @process_id INT
		, @job_id INT
		, @r INT = 0
		, @id INT = 0
		, @num INT = 0;
	--set date now  for transition
	SET @update_at = GETDATE();

	-- Find process id and job id by lot_id,device_slip_id and step_no
	SELECT @device_slip_id = [lots].[device_slip_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id
	
	SELECT @process_id = [processes].[id]
		, @job_id = [device_flows].[job_id]
	FROM [APCSProDB].method.device_flows
	INNER JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [device_flows].[act_process_id]
	INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[id] = [device_flows].[job_id]
	WHERE [device_flows].[device_slip_id] = @device_slip_id
		AND [device_flows].[step_no] = @job_step

	-- check lot_id have member_lot or not
	-- check jobid is current or not
	SELECT @current_step = [lots].[step_no] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] =  @lot_id;
	BEGIN TRANSACTION
	BEGIN TRY
		IF(@current_step = @job_step)
		BEGIN 
			-----------------------------------------------------------------
			-- (1) stop now (current)
			-----------------------------------------------------------------
			--stop at current job
			--update quality_state = 1 
			UPDATE [APCSProDB].[trans].[lots] 
			SET [lots].quality_state = 1 
			WHERE [lots].[id] = @lot_id; 
			--update lot_process_recodes
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
			SELECT [nu].[id] + ROW_NUMBER() OVER (ORDER BY [lots].[id])
				, [days].[id] [day_id]
				, @update_at AS [recorded_at]
				, @update_by AS [operated_by]
				, 48 AS [record_class]
				, [lots].[id] AS [lot_id]
				, [act_process_id] AS [process_id]
				, [act_job_id] AS [job_id]
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
			INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
			WHERE [lots].[id] = @lot_id;

			SET @r = @@ROWCOUNT
			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = [id] + @r
			WHERE [name] = 'lot_process_records.id';

			--check lot_id and system_name table trans.lot_hold_controls 
			SELECT @num = COUNT([lot_hold_controls].[id]) FROM [APCSProDB].[trans].[lot_hold_controls] 
			WHERE [lot_hold_controls].[lot_id] = @lot_id
				AND [lot_hold_controls].[system_name] = @system_name;
			--if @num > 0 then update table trans.lot_hold_controls else insert table trans.lot_hold_controls
			IF (@num > 0)
			BEGIN
				UPDATE [APCSProDB].[trans].[lot_hold_controls]
				SET is_held = 1
					, updated_at = @update_at
					, updated_by = @update_by
				WHERE [lot_hold_controls].lot_id = @lot_id
					AND [lot_hold_controls].system_name = @system_name; 
			END
			ELSE
			BEGIN
				--insert to table trans.lot_hold_controls
				SELECT TOP 1 @id = [lot_hold_controls].[id]
				FROM [APCSProDB].[trans].[lot_hold_controls] 
				ORDER BY [lot_hold_controls].id DESC;

				INSERT INTO [APCSProDB].[trans].[lot_hold_controls]
					([id]
					, [lot_id]
					, [system_name]
					, [is_held]
					, [updated_at]
					, [updated_by])
				VALUES
					(@id+1
					, @lot_id
					, @system_name 
					, 1 
					, @update_at
					, @update_by);
			END
		 
			SET @r = @@ROWCOUNT
			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = [id] + @r
			WHERE [name] = 'lot_hold_controls.id';

			--insert table [trans].[lot_hold_control_records]
			INSERT INTO [APCSProDB].[trans].[lot_hold_control_records]
				([id]
				,[hold_control_id]
				,[lot_id]
				,[system_name]
				,[updated_at]
				,[updated_by]
				,[is_held])
			SELECT [lot_process_records].[id] AS [id]
				, [lot_hold_controls].[id] AS [hold_control_id]
				, @lot_id AS [lot_id]
				, @system_name AS [system_name]
				, @update_at AS [updated_at]
				, @update_by AS [updated_by]
				, 1 AS [is_held]
			FROM [APCSProDB].[trans].lots 
			INNER JOIN [APCSProDB].[trans].[lot_process_records] on [lot_process_records].[lot_id] = [lots].[id]
			INNER JOIN [APCSProDB].[trans].[lot_hold_controls] on [lot_hold_controls].[lot_id] = [lots].[id]
			WHERE [lots].[id] = @lot_id
				AND [lot_process_records].[record_class] = 48
				AND [lot_process_records].[updated_at] = @update_at
				AND [lot_process_records].[updated_by] = @update_by
				AND [lot_hold_controls].[lot_id] = @lot_id
				AND [lot_hold_controls].[system_name] = @system_name
				AND [lot_hold_controls].[updated_at] = @update_at;

			--insert table [trans].[lot_stop_instructions]
			SELECT TOP 1 @id = [lot_stop_instructions].[stop_instruction_id]
			FROM [APCSProDB].[trans].[lot_stop_instructions]
			ORDER BY [lot_stop_instructions].stop_instruction_id DESC;

			INSERT INTO [APCSProDB].[trans].[lot_stop_instructions]
				([stop_instruction_id]
				, [device_slip_id]
				, [stop_step_no]
				, [display_message_id]
				, [is_finished]
				, [updated_at]
				, [updated_by]
				, [instruction_record_id]
				, [lot_id])
			SELECT @id+1 AS [stop_instruction_id]
				, lots.device_slip_id AS [device_slip_id]
				, @current_step AS [stop_step_no]
				, @comment_id AS [display_message_id]
				, 1 AS [is_finished]
				, @update_at AS [updated_at]
				, @update_by AS [updated_by]
				, [lot_process_records].[id] AS [instruction_record_id]
				, @lot_id AS [lot_id]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDB].[trans].[lot_process_records] ON [lot_process_records].[lot_id] = [lots].[id]
			WHERE [lots].[id] = @lot_id
				AND [lot_process_records].[record_class] = 48
				AND [lot_process_records].[updated_at] = @update_at
				AND [lot_process_records].[updated_by] = @update_by;

			SET @r = @@ROWCOUNT
			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = [id] + @r
			WHERE [name] = 'lot_stop_instructions.stop_instruction_id';
		END
		ELSE
		BEGIN
			-----------------------------------------------------------------
			-- (2) stop after (future)
			-----------------------------------------------------------------
			--stop at future job
			--update lot_process_recodes
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
				, [wip_state]
				, [process_state]
				, [quality_state]
				, [is_special_flow]
				, [is_temp_devided]
				, [updated_at]
				, [updated_by])
			SELECT [nu].[id] + ROW_NUMBER() OVER (ORDER BY [lots].[id])
				, [days].[id] AS [day_id]
				, @update_at AS [recorded_at]
				, @update_by AS [operated_by]
				, 48 AS [record_class]
				, [lots].[id] AS [lot_id]
				, @process_id AS [process_id]
				, @job_id as [job_id]
				--, @job_step AS [step_no]
				, @current_step AS [step_no]
				, [wip_state]
				, [process_state]
				, [quality_state]
				, [is_special_flow]
				, [is_temp_devided]
				, @update_at AS [updated_at]
				, @update_by AS [updated_by]
			FROM [APCSProDB].[trans].[lots] 
			INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
			INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
			WHERE [lots].[id] = @lot_id;

			SET @r = @@ROWCOUNT
			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = [id] + @r
			WHERE [name] = 'lot_process_records.id';

			INSERT INTO [APCSProDB].[trans].[lot_stop_instructions]
				([stop_instruction_id]
				, [device_slip_id]
				, [stop_step_no]
				, [display_message_id]
				, [is_finished]
				, [updated_at]
				, [updated_by]
				, [instruction_record_id]
				, [lot_id])
			SELECT [nu].[id] + ROW_NUMBER() OVER (ORDER BY [lots].[id])
				, lots.device_slip_id AS [device_slip_id]
				--, @current_step AS [stop_step_no]
				, @job_step AS [stop_step_no]
				, @comment_id AS [display_message_id]
				, 0 AS [is_finished]
				, @update_at AS [updated_at]
				, @update_by AS [updated_by]
				, lot_process_records.id AS [instruction_record_id]
				, @lot_id AS [lot_id]
			FROM [APCSProDB].[trans].lots
			INNER JOIN [APCSProDB].[trans].lot_process_records ON lot_process_records.lot_id = lots.id
			INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_stop_instructions.stop_instruction_id'
			WHERE lots.id = @lot_id
				AND [lot_process_records].record_class = 48
				AND lot_process_records.updated_at = @update_at
				AND lot_process_records.updated_by = @update_by;

			SET @r = @@ROWCOUNT
			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = [id] + @r
			WHERE [name] = 'lot_stop_instructions.stop_instruction_id';
		END;
		--SELECT '1' AS [status],'successfully' AS [message];
		COMMIT
	END TRY
	BEGIN CATCH
		ROLLBACK
		--SELECT '0' AS [status], ERROR_MESSAGE() AS [message];
	END CATCH
END
