-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_webdemo_set_create_surpluses_member]
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
		, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_create_surpluses_member]' 
			+ ' @new_lotno = ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
			+ ' ,@original_lotno = ' + ISNULL( '''' + CAST( STUFF((SELECT CONCAT(',', [lot_no]) FROM @original_lotno FOR XML PATH ('')), 1, 1, '') AS VARCHAR(MAX) ) + '''', 'NULL' ) 
			+ ' ,@empid = ' + ISNULL( CAST( @empid AS VARCHAR(10) ), 'NULL' ); --AS [command_text]

	DECLARE @lot_id INT 
	DECLARE @trans_surpluses_id INT = 0;
	DECLARE @lot_table TABLE (
		[lot_no] VARCHAR(10)
	)

	SET @lot_id = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @new_lotno);

	---- # surpluses g lot
	IF EXISTS (
		SELECT [serial_no] 
		FROM @original_lotno AS [OldLotTable]
		LEFT JOIN [APCSProDB].[trans].[surpluses] ON [OldLotTable].[lot_no] = [surpluses].[serial_no]
		WHERE [surpluses].[serial_no] IS NULL
	)
	BEGIN
		INSERT INTO @lot_table
		SELECT [serial_no] 
		FROM @original_lotno AS [OldLotTable]
		LEFT JOIN [APCSProDB].[trans].[surpluses] ON [OldLotTable].[lot_no] = [surpluses].[serial_no]
		WHERE [surpluses].[serial_no] IS NULL;

		---- # create trans.surpluses
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
		SELECT [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [lots].[id] ) AS [id]
			, [lots].[id] AS [lot_id]
			, ISNULL([lots].[qty_hasuu], 0) AS [pcs]
			, [lots].[lot_no] AS [serial_no]
			, 0 AS [in_stock]
			, NULL AS [location_id]
			, NULL AS [acc_location_id]
			, GETDATE() AS [created_at]
			, @empid AS [created_by]
			, NULL AS [updated_at]
			, NULL AS [updated_by]
			, NULL AS [reprint_count]
			, ISNULL([lots].[pdcd], '') AS [pdcd]
			, ISNULL([lots].[qc_instruction], '') AS [qc_instruction]
			, ISNULL([lots].[mark_no], '') AS [mark_no]
			, NULL AS [original_lot_id]
			, NULL AS [machine_id]
			, ISNULL([lots].[user_code], '') AS [user_code]
			, ISNULL([lots].[product_control_class], '') AS [product_control_class]
			, ISNULL([lots].[product_class], '') AS [product_class]
			, ISNULL([lots].[production_class], '') AS [production_class]
			, ISNULL([lots].[rank_no], '') AS [rank_no]
			, ISNULL([lots].[hinsyu_class], '') AS [hinsyu_class]
			, ISNULL([lots].[label_class], '') AS [label_class]
			, 0 AS [transfer_flag]
			, 0 AS [transfer_pcs]
			, '01' AS [stock_class]
			, NULL AS [is_ability]
			, NULL AS [comment]
		FROM (
			SELECT [lots].[id]
				, [lots].[lot_no]
				, [lots].[qty_hasuu]
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
			FROM @lot_table AS [OldLotTable]
			INNER JOIN [APCSProDB].[trans].[lots] ON [OldLotTable].[lot_no] = [lots].[lot_no]
			LEFT JOIN [APCSProDB].[method].[allocat] ON [OldLotTable].[lot_no] = [allocat].[LotNo]
			LEFT JOIN [APCSProDB].[method].[allocat_temp] ON [OldLotTable].[lot_no] = [allocat_temp].[LotNo]
		) AS [lots]
		INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'surpluses.id';

		SELECT @trans_surpluses_id = [numbers].[id] + @@ROWCOUNT 
		FROM [APCSProDB].[trans].[numbers]
		WHERE [numbers].[name] = 'surpluses.id';

		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = @trans_surpluses_id
		WHERE [numbers].[name] = 'surpluses.id';

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
		INNER JOIN @lot_table AS [OldLotTable] ON [surpluses].[serial_no] = [OldLotTable].[lot_no];

		UPDATE [APCSProDB].[trans].[lots]
		SET [wip_state] = 100
		WHERE [lot_no] IN (SELECT [lot_no] FROM @original_lotno);

		IF EXISTS (
			SELECT [lots].[qty_pass]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN @original_lotno AS [lot_table] ON [lots].[lot_no] = [lot_table].[lot_no]
			WHERE [lots].[qty_pass] < 0
		)
		BEGIN
			INSERT INTO [APCSProDWH].[dbo].[ukebarai_errors]
				( [lot_no]
				, [process_no]
				, [date]
				, [time]
				, [good_qty]
				, [ng_qty]
				, [shipment_qty]
				, [mc_name] )
			SELECT [lots].[lot_no] AS [lot_no]
				, '01201' AS [process_no]
				, FORMAT(GETDATE(),'yyMMdd') AS [date]
				, FORMAT(GETDATE(),'HHmm') AS [time]
				, 0 AS [good_qty]
				, [lots].[qty_pass] AS [ng_qty]
				, 0 AS [shipment_qty]
				, 'GLot' AS [mc_name]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN @original_lotno AS [lot_table] ON [lots].[lot_no] = [lot_table].[lot_no]
			WHERE [lots].[qty_pass] < 0;
		END

		IF EXISTS (
			SELECT [lots].[qty_pass]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN @original_lotno AS [lot_table] ON [lots].[lot_no] = [lot_table].[lot_no]
			WHERE [lots].[qty_pass] >= 0
		)
		BEGIN
			INSERT INTO [APCSProDWH].[dbo].[ukebarais]
				( [lot_no]
				, [process_no]
				, [date]
				, [time]
				, [good_qty]
				, [ng_qty]
				, [shipment_qty]
				, [mc_name] )
			SELECT [lots].[lot_no] AS [lot_no]
				, '01201' AS [process_no]
				, FORMAT(GETDATE(),'yyMMdd') AS [date]
				, FORMAT(GETDATE(),'HHmm') AS [time]
				, 0 AS [good_qty]
				, [lots].[qty_pass] AS [ng_qty]
				, 0 AS [shipment_qty]
				, 'GLot' AS [mc_name]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN @original_lotno AS [lot_table] ON [lots].[lot_no] = [lot_table].[lot_no]
			WHERE [lots].[qty_pass] >= 0;
		END
	END
	
	IF NOT EXISTS (
		SELECT [serial_no] 
		FROM @original_lotno AS [OldLotTable]
		LEFT JOIN [APCSProDB].[trans].[surpluses] ON [OldLotTable].[lot_no] = [surpluses].[serial_no]
		WHERE [surpluses].[serial_no] IS NULL
	)
	BEGIN
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
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
			, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_create_surpluses_member]' 
				+ ' LotNo : ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
				+ ' Error : trans.surpluses g lot has been created.'; --AS [command_text]

		SELECT 'FALSE' AS [Is_Pass] 
			, 'trans.surpluses g lot has been created !!' AS [Error_Message_ENG]
			, N'trans.surpluses g lot ถูกสร้างแล้ว !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
END
