-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_webdemo_set_create_surpluses_master]
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
		, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_create_surpluses_master]' 
			+ ' @new_lotno = ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
			+ ' ,@original_lotno = ' + ISNULL( '''' + CAST( STUFF((SELECT CONCAT(',', [lot_no]) FROM @original_lotno FOR XML PATH ('')), 1, 1, '') AS VARCHAR(MAX) ) + '''', 'NULL' ) 
			+ ' ,@empid = ' + ISNULL( CAST( @empid AS VARCHAR(10) ), 'NULL' ); --AS [command_text]

	DECLARE @lot_id INT 
	SET @lot_id = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @new_lotno);

	---- # surpluses d lot
	IF NOT EXISTS (SELECT [serial_no] FROM [APCSProDB].[trans].[surpluses] WHERE [serial_no] = @new_lotno)
	BEGIN
		---- # create trans.surpluses
		DECLARE @trans_surpluses_id INT
		SELECT @trans_surpluses_id = [numbers].[id] + 1 
		FROM [APCSProDB].[trans].[numbers]
		WHERE [numbers].[name] = 'surpluses.id';

		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = @trans_surpluses_id
		WHERE [numbers].[name] = 'surpluses.id';

		INSERT INTO [APCSProDB].[trans].[surpluses]
			( [id]
			, [lot_id]
			, [pcs]
			, [serial_no]
			, [in_stock]
			, [location_id]
			, [acc_location_id]
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by]
			, [reprint_count]
			, [pdcd]
			, [qc_instruction]
			, [mark_no]
			, [original_lot_id]
			, [machine_id]
			, [user_code]
			, [product_control_class]
			, [product_class]
			, [production_class]
			, [rank_no]
			, [hinsyu_class]
			, [label_class]
			, [transfer_flag]
			, [transfer_pcs]
			, [stock_class]
			, [is_ability]
			, [comment] )
		SELECT @trans_surpluses_id AS [id]
			, [lots].[id] AS [lot_id]
			, [lots].[qty_hasuu] AS [pcs]
			, [lots].[lot_no] AS [serial_no]
			, 2 AS [in_stock]
			, NULL AS [location_id]
			, NULL AS [acc_location_id]
			, [lots].[created_at] AS [created_at]
			, [lots].[created_by] AS [created_by]
			, [lots].[updated_at] AS [updated_at]
			, [lots].[updated_by] AS [updated_by]
			, NULL AS [reprint_count]
			, ISNULL([surpluses].[pdcd], '') AS [pdcd]
			, ISNULL([surpluses].[qc_instruction], '') AS [qc_instruction]
			, ISNULL([surpluses].[mark_no], '') AS [mark_no]
			, NULL AS [original_lot_id]
			, NULL AS [machine_id]
			, ISNULL([surpluses].[user_code], '') AS [user_code]
			, ISNULL([surpluses].[product_control_class], '') AS [product_control_class]
			, ISNULL([surpluses].[product_class], '') AS [product_class]
			, ISNULL([surpluses].[production_class], '') AS [production_class]
			, ISNULL([surpluses].[rank_no], '') AS [rank_no]
			, ISNULL([surpluses].[hinsyu_class], '') AS [hinsyu_class]
			, ISNULL([surpluses].[label_class], '') AS [label_class]
			, 0 AS [transfer_flag]
			, 0 AS [transfer_pcs]
			, '01' AS [stock_class]
			, NULL AS [is_ability]
			, NULL AS [comment]
		FROM [APCSProDB].[trans].[lots] 
		OUTER APPLY (
			SELECT TOP 1 [OldLotTable].[lot_no]
				, ISNULL([allocat].[PDCD], [allocat_temp].[PDCD]) AS [pdcd]
				, ISNULL([allocat].[Tomson3], [allocat_temp].[Tomson3]) AS [qc_instruction]
				, ISNULL([allocat].[Mask], [allocat_temp].[Mask]) AS [mark_no]
				, ISNULL([allocat].[User_Code], [allocat_temp].[User_Code]) AS [user_code]
				, ISNULL([allocat].[Product_Control_Cl_1], [allocat_temp].[Product_Control_Cl_1]) AS [product_control_class]
				, ISNULL([allocat].[Product_Class], [allocat_temp].[Product_Class]) AS [product_class]
				, ISNULL([allocat].[Production_Class], [allocat_temp].[Production_Class]) AS [production_class]
				, ISNULL([allocat].[Rank_No], [allocat_temp].[Rank_No]) AS [rank_no]
				, ISNULL([allocat].[HINSYU_Class], [allocat_temp].[HINSYU_Class]) AS [hinsyu_class]
				, ISNULL([allocat].[Label_Class], [allocat_temp].[Label_Class]) AS [label_class]
			FROM @original_lotno AS [OldLotTable]
			LEFT JOIN [APCSProDB].[method].[allocat] ON [OldLotTable].[lot_no] = [allocat].[LotNo]
			LEFT JOIN [APCSProDB].[method].[allocat_temp] ON [OldLotTable].[lot_no] = [allocat_temp].[LotNo]
		) AS [surpluses]
		WHERE [lots].[id] = @lot_id;

		---- # create trans.surpluse_records
		INSERT INTO [APCSProDB].[trans].[surpluse_records]
			( [recorded_at]
			, [operated_by]
			, [record_class]
			, [surpluse_id]
			, [lot_id]
			, [pcs]
			, [serial_no]
			, [in_stock]
			, [location_id]
			, [acc_location_id]
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by]
			, [reprint_count]
			, [product_code]
			, [qc_instruction]
			, [mark_no]
			, [original_lot_id]
			, [machine_id]
			, [user_code]
			, [product_control_class]
			, [product_class]
			, [production_class]
			, [rank_no]
			, [hinsyu_class]
			, [label_class]
			, [transfer_flag]
			, [transfer_pcs]
			, [stock_class]
			, [is_ability]
			, [comment] )
		SELECT [surpluses].[created_at] AS [recorded_at]
			, [surpluses].[created_by] AS [operated_by]
			, 1 AS [record_class]
			, [surpluses].[id] AS [surpluse_id]
			, [surpluses].[lot_id]
			, [surpluses].[pcs]
			, [surpluses].[serial_no]
			, [surpluses].[in_stock]
			, [surpluses].[location_id]
			, [surpluses].[acc_location_id]
			, [surpluses].[created_at]
			, [surpluses].[created_by]
			, [surpluses].[updated_at]
			, [surpluses].[updated_by]
			, [surpluses].[reprint_count]
			, [surpluses].[pdcd] AS [product_code]
			, [surpluses].[qc_instruction]
			, [surpluses].[mark_no]
			, [surpluses].[original_lot_id]
			, [surpluses].[machine_id]
			, [surpluses].[user_code]
			, [surpluses].[product_control_class]
			, [surpluses].[product_class]
			, [surpluses].[production_class]
			, [surpluses].[rank_no]
			, [surpluses].[hinsyu_class]
			, [surpluses].[label_class]
			, [surpluses].[transfer_flag]
			, [surpluses].[transfer_pcs]
			, [surpluses].[stock_class]
			, [surpluses].[is_ability]
			, [surpluses].[comment]
		FROM [APCSProDB].[trans].[surpluses]
		WHERE [surpluses].[lot_id] = @lot_id;
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
			, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_create_surpluses_master]' 
				+ ' LotNo : ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
				+ ' Error : trans.surpluses new lot has been created.'; --AS [command_text]

		SELECT 'FALSE' AS [Is_Pass] 
			, 'trans.surpluses new lot has been created !!' AS [Error_Message_ENG]
			, N'trans.surpluses new lot ถูกสร้างแล้ว !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END

	IF EXISTS (SELECT [serial_no] FROM [APCSProDB].[trans].[surpluses] WHERE [serial_no] = @new_lotno)
	BEGIN
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
END
