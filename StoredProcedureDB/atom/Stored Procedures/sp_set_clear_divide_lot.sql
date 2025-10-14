-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_clear_divide_lot] 
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10),
	@user_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	----# Log stored
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
		, 'EXEC [atom].[sp_set_clear_divide_lot] @lot_no = ''' + @lot_no + ''''
			+ ',@user_id = ' + ISNULL(CAST(@user_id AS VARCHAR),'NULL')
		, @lot_no

	IF EXISTS(SELECT [LOT_NO] FROM [ISDB].[DBLSISHT].[dbo].[LOT_DIVIDE] WHERE [LOT_NO] = @lot_no)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Lot is send, Can''t delete !!' AS [Error_Message_ENG]
			, N'Lot ถูกส่งแล้ว, ไม่สามารถลบได้ !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END

	DECLARE @lot_id INT = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no); 

	DELETE FROM [APCSProDWH].[atom].[divided_lots]
	WHERE [lot_id] = @lot_id;

	IF (@@ROWCOUNT > 0)
	BEGIN
		----# return
		SELECT 'TRUE' AS Is_Pass 
			, '' AS Error_Message_ENG
			, '' AS Error_Message_THA 
			, '' AS Handling;
		RETURN;
	END
	ELSE
	BEGIN
		----# return
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Can not cancel divide lot !!' AS [Error_Message_ENG]
			, N'ไม่สามารถ Cancel ข้อมูลการแบ่ง lot ได้ !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END
END