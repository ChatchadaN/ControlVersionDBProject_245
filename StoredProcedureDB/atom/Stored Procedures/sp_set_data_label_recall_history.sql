-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_data_label_recall_history]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
	----------------------------------------------------------------------------
	----- # log exec stored procedure
	----------------------------------------------------------------------------
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
		, ISNULL('EXEC [atom].[sp_set_data_label_recall_history] @lot_no = ''' + @lot_no + '''','EXEC [atom].[sp_set_data_label_recall_history] @lot_no = NULL')
		, @lot_no;

	----------------------------------------------------------------------------
	----- # create lot in trans.label_issue_records
	----------------------------------------------------------------------------
	BEGIN TRANSACTION
	BEGIN TRY
		-----------------------------------------------------------------------------
		EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3]
			@lot_no_value = @lot_no
			, @process_name = 'TP';
		-----------------------------------------------------------------------------
		COMMIT TRANSACTION;
	END TRY
	BEGIN CATCH
		-----------------------------------------------------------------------------
		ROLLBACK TRANSACTION;
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Insert data trans.lot_combine error !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล trans.lot_combine ไม่สำเร็จ !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
		-----------------------------------------------------------------------------
	END CATCH
	----------------------------------------------------------------------------
	----- # check data in trans.label_issue_records
	----------------------------------------------------------------------------
	IF EXISTS (SELECT [lot_no] from [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no)
	BEGIN
		-----------------------------------------------------------------------------
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
		-----------------------------------------------------------------------------
	END
	ELSE
	BEGIN
		-----------------------------------------------------------------------------
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Insert data label error !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล label ไม่สำเร็จ !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
		-----------------------------------------------------------------------------
	END
END
