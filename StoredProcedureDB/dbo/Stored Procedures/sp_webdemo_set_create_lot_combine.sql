-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_webdemo_set_create_lot_combine]
	-- Add the parameters for the stored procedure here
	@new_lotno VARCHAR(10), 
	@original_lotno atom.trans_lots READONLY, 
	@empid INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [lot_no]
		, [command_text] )
	SELECT GETDATE() --AS [record_at]
		, 4 AS [record_class]
		, ORIGINAL_LOGIN() --AS [login_name]
		, HOST_NAME() --AS [hostname]
		, APP_NAME() --AS [appname]
		, @new_lotno --AS [lot_no]
		, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_create_lot_combine]' 
			+ ' @new_lotno = ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
			+ ' ,@original_lotno = ' + ISNULL( '''' + CAST( STUFF((SELECT CONCAT(',', [lot_no]) FROM @original_lotno FOR XML PATH ('')), 1, 1, '') AS VARCHAR(MAX) ) + '''', 'NULL' ) 
			+ ' ,@empid = ' + ISNULL( CAST( @empid AS VARCHAR(10) ), 'NULL' ); --AS [command_text]

	DECLARE @lot_id INT
	SET @lot_id = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @new_lotno);

	IF NOT EXISTS (SELECT [lot_id] FROM [APCSProDB].[trans].[lot_combine] WHERE [lot_id] = @lot_id)
	BEGIN
		---- # create trans.lot_combine	
		INSERT INTO [APCSProDB].[trans].[lot_combine]
			( [lot_id] 
			, [idx]
			, [member_lot_id] 
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by] )
		SELECT @lot_id AS [lot_id] 
			, [row] AS [idx]
			, [lot_mem].[id] AS [member_lot_id] 
			, GETDATE() AS [created_at]
			, @empid AS [created_by]
			, GETDATE()  AS [updated_at]
			, @empid AS [updated_by]
		FROM (
			SELECT [lot_no], (ROW_NUMBER() OVER(ORDER BY (SELECT 1)) - 1) AS [row]
			FROM @original_lotno AS [OldLotTable]
		) AS [table_lot]
		INNER JOIN [APCSProDB].[trans].[lots] AS [lot_mem] ON [table_lot].[lot_no] = [lot_mem].[lot_no]

		---- # create trans.lot_combine_records
		INSERT INTO [APCSProDB].[trans].[lot_combine_records]
			( [recorded_at]
			, [operated_by]
			, [record_class]
			, [lot_id] 
			, [idx]
			, [member_lot_id] 
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by] )
		SELECT GETDATE() AS [recorded_at]
			, @empid AS [operated_by]
			, 1 AS [record_class]
			, [lot_id] 
			, [idx]
			, [member_lot_id] 
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by]
		FROM [APCSProDB].[trans].[lot_combine]
		WHERE [lot_id] = @lot_id;
	END
	ELSE
	BEGIN
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [lot_no]
			, [command_text] )
		SELECT GETDATE() --AS [record_at]
			, 4 AS [record_class]
			, ORIGINAL_LOGIN() --AS [login_name]
			, HOST_NAME() --AS [hostname]
			, APP_NAME() --AS [appname]
			, @new_lotno --AS [lot_no]
			, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_create_lot_combine]' 
				+ ' LotNo : ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
				+ ' Error : trans.lot_combine has been created.'; --AS [command_text]

		SELECT 'FALSE' AS [Is_Pass] 
			, 'trans.lot_combine has been created !!' AS [Error_Message_ENG]
			, N'trans.lot_combine ถูกสร้างแล้ว !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END

	IF EXISTS (SELECT [lot_id] FROM [APCSProDB].[trans].[lot_combine] WHERE [lot_id] = @lot_id)
	BEGIN
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
END
