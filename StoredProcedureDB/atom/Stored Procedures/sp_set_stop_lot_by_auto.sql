-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create 20210731,,>
-- Description:	<Description,,Stop Lot>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_stop_lot_by_auto] 
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
		SELECT DISTINCT [lots].[lot_no]
			, [lot_stop_instructions].[step_no]
		FROM [APCSProDB].[trans].[lots]
		CROSS APPLY (
			SELECT [lot_stop_instructions].[stop_instruction_id]
				, [lot_id] 
				, [stop_step_no] AS [step_no] 
				, [lot_stop_instructions].[is_finished]
			FROM [APCSProDB].[trans].[lot_stop_instructions]
			WHERE [lot_stop_instructions].[lot_id] = [lots].[id]
				AND [lot_stop_instructions].[stop_step_no] > [lots].[step_no]
		) AS [lot_stop_instructions]
		WHERE [lots].[wip_state] = 20
			AND [lots].[id] = @lot_id
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

			--IF (@@ROWCOUNT > 0)
			--BEGIN
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
					, 'EXEC [atom].[sp_set_stop_lot_by_auto] update is_held = 1 (stop lot) lot_no = ' + CAST(@lot_no AS VARCHAR(20))
					, @lot_no;
			--END
		END
	END

	IF EXISTS (
		SELECT [l].[id] 
			, [l].[lot_no]
			, [l].[step_no] 
			, [l].[quality_state]
			, [lh].[is_held] 
			, [ls].[stop_instruction_id] 
		FROM [APCSProDB].[trans].[lots] AS [l] 
		INNER JOIN [APCSProDB].[trans].[lot_hold_controls] AS [lh] ON [lh].[lot_id] = [l].[id] 
			AND [lh].[system_name] = 'lot stop instruction' 
		INNER JOIN [APCSProDB].[trans].[lot_process_records] AS [r] ON [r].[lot_id] = [l].[id] 
			AND [r].[record_class] = 48
			AND NOT EXISTS (
				SELECT [r2].[id] 
				FROM [APCSProDB].[trans].[lot_process_records] AS [r2]
				WHERE [r2].[lot_id] = [r].[lot_id] 
					AND [r2].[record_class] = 48 
					AND [r2].[id] > [r].[id]
			) 
		INNER JOIN [APCSProDB].[trans].[lot_stop_instructions] AS [ls] ON [ls].[instruction_record_id] = [r].[id] 
			AND [ls].[stop_step_no] = [l].[step_no] 
		WHERE [l].[id] = @lot_id
	)
	BEGIN
		SELECT @quality_state = [quality_state]
		FROM [APCSProDB].[trans].[lots]
		WHERE [id] = @lot_id

		IF (ISNULL(@quality_state,0) != 1)
		BEGIN
			UPDATE [APCSProDB].[trans].[lots] 
			SET [quality_state] = 1 
			WHERE [id] = @lot_id;

			--IF (@@ROWCOUNT > 0)
			--BEGIN
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
					, 'EXEC [atom].[sp_set_stop_lot_by_auto] update quality_state = 1 (stop lot) lot_no = ' + CAST(@lot_no AS VARCHAR(20))
					, @lot_no;
			--END
		END
	END
END
