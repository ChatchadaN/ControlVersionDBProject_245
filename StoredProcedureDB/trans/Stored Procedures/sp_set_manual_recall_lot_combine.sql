-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_manual_recall_lot_combine]
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
		, ISNULL('EXEC [trans].[sp_set_manual_recall_lot_combine] @lot_no = ''' + @lot_no + ''''
			,'EXEC [trans].[sp_set_manual_recall_lot_combine] @lot_no = NULL')
		, @lot_no;

	DECLARE @user INT = 0;
	DECLARE @lot_no_0 VARCHAR(20) = '';

	SET @user = (
		SELECT [WH_OP_RECALL] FROM [APCSProDWH].[dbo].[PROCESS_RECALL_IF] 
		WHERE [NEWLOT] = @lot_no
	);

	IF EXISTS ( SELECT [serial_no] FROM [APCSProDB].[trans].[surpluses] WHERE [serial_no] = @lot_no )
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
			SET @lot_no_0 = (
				SELECT TOP 1 [LotNo] FROM [APCSProDWH].[dbo].[MIX_HIST_IF] 
				WHERE [HASUU_LotNo] = @lot_no
					AND [HASUU_LotNo] != [LotNo]
			);

			EXEC [StoredProcedureDB].[atom].[sp_set_mixing_tg] 
				@lotno0 = @lot_no_0
				, @master_lot_no = @lot_no
				, @emp_no_value = @user;

			COMMIT TRANSACTION;
			SELECT 'TRUE' AS Is_Pass 
				, '' AS Error_Message_ENG
				, N'' AS Error_Message_THA 
				, '' AS Handling;
			RETURN;
		END TRY
		BEGIN CATCH
			ROLLBACK TRANSACTION;
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Insert data error !!' AS [Error_Message_ENG]
				, N'เพิ่มข้อมูลไม่สำเร็จ !!' AS [Error_Message_THA] 
				, N'กรุณาติดต่อ system' AS [Handling];
			RETURN;
		END CATCH
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Is_Pass 
			, 'LotNo data not found' AS Error_Message_ENG
			, N'ไม่พบข้อมูล LotNo' AS Error_Message_THA 
			, '' AS Handling;
		RETURN;
	END
END
