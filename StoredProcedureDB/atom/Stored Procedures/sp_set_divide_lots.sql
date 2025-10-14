-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_divide_lots] 
	-- Add the parameters for the stored procedure here
	@LotNoTable trans_lots READONLY,
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
		, 'EXEC [atom].[sp_set_divide_lots] @lot_no = ''' + (SELECT CAST(ISNULL( STUFF( ( SELECT CONCAT(', ', lot_no) FROM @LotNoTable FOR XML PATH ('')), 1, 2, '' ), 'NULL' ) AS VARCHAR(MAX) ) ) + ''''
			+ ',@user_id = ' + ISNULL(CAST(@user_id AS VARCHAR),'NULL')
		, 'dividelot';

    --becuase the task run every 5 minutes
	IF (FORMAT(GETDATE(),'HH:mm') BETWEEN '06:02' AND '06:08') 
		OR (FORMAT(GETDATE(),'HH:mm') BETWEEN '09:02' AND '09:08')
		--OR (FORMAT(GETDATE(),'HH:mm') BETWEEN '11:00' AND '11:10') --
		OR (FORMAT(GETDATE(),'HH:mm') BETWEEN '12:02' AND '12:08')
		OR (FORMAT(GETDATE(),'HH:mm') BETWEEN '15:02' AND '15:08')
		OR (FORMAT(GETDATE(),'HH:mm') BETWEEN '18:02' AND '18:08')
	BEGIN
		----# return
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Lot is sending, just a moment !!' AS [Error_Message_ENG]
			, N'Lot กำลังถูกส่ง, กรุณารอสักครู่ !!' AS [Error_Message_THA] 
			, N'กรุณารอสักครู่' AS [Handling];
		RETURN;
	END

	IF EXISTS (
		SELECT [lots].[lot_no]
		FROM @LotNoTable AS [table_lot]
		INNER JOIN [APCSProDB].[trans].[lots] ON [table_lot].[lot_no] = [lots].[lot_no]
		LEFT JOIN [APCSProDWH].[atom].[divided_lots] ON [lots].[id] = [divided_lots].[lot_id]
		WHERE [lots].[wip_state] IN (0,10,20)	
			AND [divided_lots].[lot_id] IS NULL
	)
	BEGIN
		----# insert into table divided_lots
		INSERT INTO [APCSProDWH].[atom].[divided_lots]
			( [lot_id]
			, [is_create_text]
			, [is_send_text]
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by] )
		SELECT [lots].[id] AS [lot_id]
			, 0 AS [is_create_text]
			, 0 AS [is_send_text]
			, GETDATE() AS [created_at]
			, @user_id AS [created_by]
			, NULL AS [updated_at]
			, NULL AS [updated_by]
		FROM @LotNoTable AS [table_lot]
		INNER JOIN [APCSProDB].[trans].[lots] ON [table_lot].[lot_no] = [lots].[lot_no]
		LEFT JOIN [APCSProDWH].[atom].[divided_lots] ON [lots].[id] = [divided_lots].[lot_id]
		WHERE [lots].[wip_state] IN (0,10,20)
			AND [divided_lots].[lot_id] IS NULL;

		----# return
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, '' AS [Error_Message_THA] 
			, '' AS [Handling];
		RETURN;
	END
	ELSE
	BEGIN
		----# return
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Data not found !!' AS [Error_Message_ENG]
			, N'ไม่พบข้อมูล' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END
END