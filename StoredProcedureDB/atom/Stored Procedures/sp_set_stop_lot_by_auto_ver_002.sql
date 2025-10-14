
CREATE PROCEDURE [atom].[sp_set_stop_lot_by_auto_ver_002] 
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lot_id INT = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no)
		, @is_held INT = 0
		, @quality_state INT;

	IF EXISTS (
		SELECT [l].[id] 
			, [l].[lot_no]
			, [l].[step_no] 
			, [l].[quality_state]
			, [lh].[is_held] 
			, [ls].[stop_instruction_id] 
		FROM [APCSProDB].[trans].[lots] AS [l] 
		LEFT JOIN [APCSProDB].[trans].[special_flows] AS [sp] ON [l].[is_special_flow] = 1
			AND [l].[special_flow_id] = [sp].[id]
			AND [l].[id] = [sp].[lot_id]
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] AS [lsp] ON [sp].[id] = [lsp].[special_flow_id]
			AND [sp].[step_no] = [lsp].[step_no]
		INNER JOIN [APCSProDB].[trans].[lot_hold_controls] AS [lh] ON [lh].[lot_id] = [l].[id] 
			AND [lh].[system_name] = 'lot stop instruction' 
		INNER JOIN [APCSProDB].[trans].[lot_process_records] AS [r] ON [r].[lot_id] = [l].[id] 
			AND [r].[record_class] = 48
		INNER JOIN [APCSProDB].[trans].[lot_stop_instructions] AS [ls] ON [ls].[instruction_record_id] = [r].[id] 
			AND [ls].[stop_step_no] = ISNULL([lsp].[step_no], [l].[step_no]) 
			AND [ls].[is_finished] = 0
		WHERE [l].[id] = @lot_id
	)
	BEGIN
		SELECT @is_held = [is_held]
		FROM [APCSProDB].[trans].[lot_hold_controls]
		WHERE [lot_id] = @lot_id
			AND [system_name] = 'lot stop instruction';

		IF (@is_held = 0)
		BEGIN
			UPDATE [APCSProDB].[trans].[lot_hold_controls] 
			SET [is_held] = 1 
			WHERE [lot_id] = @lot_id
				AND [system_name] = 'lot stop instruction';

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
				, 'EXEC [atom].[sp_set_stop_lot_by_auto_ver_002] update is_held = 1 (stop lot) lot_no = ' + CAST(@lot_no AS VARCHAR(20))
				, @lot_no;
		END

		SELECT @quality_state = [quality_state]
		FROM [APCSProDB].[trans].[lots]
		WHERE [id] = @lot_id

		IF (ISNULL(@quality_state,0) != 1)
		BEGIN
			UPDATE [APCSProDB].[trans].[lots] 
			SET [quality_state] = 1 
			WHERE [id] = @lot_id;

			UPDATE [APCSProDB].[trans].[lot_stop_instructions] 
			SET [is_finished] = 1
			WHERE [lot_id] = @lot_id
				AND [stop_step_no] = (SELECT [lots].[step_no] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)
				AND [is_finished] = 0;

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
				, 'EXEC [atom].[sp_set_stop_lot_by_auto_ver_002] update quality_state = 1 (stop lot) lot_no = ' + CAST(@lot_no AS VARCHAR(20))
				, @lot_no;
		END
	END
END
