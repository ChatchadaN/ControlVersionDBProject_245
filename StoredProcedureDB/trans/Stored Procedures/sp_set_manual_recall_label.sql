-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_manual_recall_label]
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
		, ISNULL('EXEC [trans].[sp_set_manual_recall_label] @lot_no = ''' + @lot_no + ''''
			,'EXEC [trans].[sp_set_manual_recall_label] @lot_no = NULL')
		, @lot_no;

	BEGIN TRANSACTION
	BEGIN TRY
		EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3]
			@lot_no_value = @lot_no
			, @process_name = 'TP';
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Insert data error !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูลไม่สำเร็จ !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END CATCH

	IF EXISTS (SELECT [lot_no] from [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no)
	BEGIN
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Insert data label error !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล label ไม่สำเร็จ !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END
END
