-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_manual_recall_clear_data]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here
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
		, ISNULL('EXEC [trans].[sp_set_manual_recall_clear_data] @lot_no = ''' + @lot_no + ''''
			,'EXEC [trans].[sp_set_manual_recall_clear_data] @lot_no = NULL')
		, @lot_no;

	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @trans_lots_id INT = (SELECT [id] FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) WHERE [lot_no] = @lot_no);
		----------------------------------------------------------------------------
		----- # clear trans.surpluses
		----------------------------------------------------------------------------
		IF EXISTS(SELECT [lot_id] FROM [APCSProDB].[trans].[surpluses] WITH (NOLOCK) WHERE [lot_id] = @trans_lots_id)
		BEGIN
			DELETE FROM [APCSProDB].[trans].[surpluses] 
			WHERE [lot_id] = @trans_lots_id;
		END
		----------------------------------------------------------------------------
		----- # clear trans.lot_combine
		----------------------------------------------------------------------------
		IF EXISTS(SELECT [lot_id] FROM [APCSProDB].[trans].[lot_combine] WITH (NOLOCK) WHERE [lot_id] = @trans_lots_id)
		BEGIN
			DELETE FROM [APCSProDB].[trans].[lot_combine] 
			WHERE [lot_id] = @trans_lots_id;
		END
		----------------------------------------------------------------------------
		----- # clear trans.label_issue_records
		----------------------------------------------------------------------------
		IF EXISTS(SELECT [lot_no] FROM [APCSProDB].[trans].[label_issue_records] WITH (NOLOCK) WHERE [lot_no] = @lot_no)
		BEGIN
			DELETE FROM [APCSProDB].[trans].[label_issue_records] 
			WHERE [lot_no] = @lot_no;
		END
		-----------------------------------------------------------------------------
		COMMIT TRANSACTION;
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
		-----------------------------------------------------------------------------
	END TRY
	BEGIN CATCH
		-----------------------------------------------------------------------------
		ROLLBACK TRANSACTION;
		SELECT 'FALSE' AS [Is_Pass] 
			, 'delete data error !!' AS [Error_Message_ENG]
			, N'ลบข้อมูลไม่สำเร็จ !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
		-----------------------------------------------------------------------------
	END CATCH
END
