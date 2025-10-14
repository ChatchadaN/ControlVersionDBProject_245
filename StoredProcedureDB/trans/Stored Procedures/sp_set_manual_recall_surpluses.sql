-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_manual_recall_surpluses]
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
		, ISNULL('EXEC [trans].[sp_set_manual_recall_surpluses] @lot_no = ''' + @lot_no + ''''
			,'EXEC [trans].[sp_set_manual_recall_surpluses] @lot_no = NULL')
		, @lot_no;

	DECLARE @r_surpluses INT = 0;
	DECLARE @user INT = 0;

	SET @user = (
		SELECT [WH_OP_RECALL] FROM [APCSProDWH].[dbo].[PROCESS_RECALL_IF] 
		WHERE [NEWLOT] = @lot_no
	);

	IF EXISTS ( SELECT [LotNo] FROM [APCSProDWH].[dbo].[H_STOCK_IF] WHERE [LotNo] = @lot_no )
	BEGIN
		BEGIN TRANSACTION
		BEGIN TRY
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
				, [stock_class] )
			SELECT [nu].[id] + row_number() OVER (ORDER BY (SELECT 0)) AS [id]
				, [lots].[id] AS [lot_id]
				, [lots].[qty_hasuu] AS [pcs]
				, [lots].[lot_no] AS [serial_no]
				, 2 AS [in_stock] 
				, NULL AS [location_id]
				, NULL AS [acc_location_id]
				, GETDATE() AS [created_at]
				, @user AS [created_by]
				, NULL AS [updated_at]
				, NULL AS [updated_by]
				, NULL AS [reprint_count] 
				, [H_STOCK_IF].[PDCD] AS [pdcd]
				, [H_STOCK_IF].[Tomson_Mark_3] AS [qc_instruction]
				, [H_STOCK_IF].[MNo] AS [mark_no]
				, NULL AS [original_lot_id]
				, NULL AS [machine_id]
				, [H_STOCK_IF].[User_Code] AS [user_code]
				, [H_STOCK_IF].[Product_Control_Clas] AS  [product_control_class]
				, [H_STOCK_IF].[Product_Class] AS [product_class]
				, [H_STOCK_IF].[Production_Class] AS [production_class]
				, [H_STOCK_IF].[Rank_No] AS [rank_no]
				, [H_STOCK_IF].[HINSYU_Class] AS [hinsyu_class]
				, [H_STOCK_IF].[Label_Class] AS [label_class]
				, [H_STOCK_IF].[Stock_Class]  AS [stock_class]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDWH].[dbo].[H_STOCK_IF] 
				ON [lots].[lot_no] = [H_STOCK_IF].[LotNo]
			INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] 
				ON [nu].[name] = 'surpluses.id'
			WHERE [lots].[lot_no] = @lot_no;

			SET @r_surpluses = @@ROWCOUNT;
			IF (@r_surpluses != 0)
			BEGIN
				UPDATE [APCSProDB].[trans].[numbers]
				SET [id] = [id] + @r_surpluses
				WHERE [name] = 'surpluses.id';
			END

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
				, [reprint_count]
				, [created_at]
				, [created_by]
				, [updated_at]
				, [updated_by]
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
				, [is_ability] )
			select GETDATE() AS [recorded_at]
				, 0 AS [operated_by]
				, 1 AS [record_class]
				, [surpluses].[id] AS [surpluse_id]
				, [surpluses].[lot_id]
				, [surpluses].[pcs]
				, [surpluses].[serial_no]
				, [surpluses].[in_stock]
				, [surpluses].[location_id]
				, [surpluses].[acc_location_id]
				, [surpluses].[reprint_count]
				, [surpluses].[created_at]
				, [surpluses].[created_by]
				, GETDATE() AS [updated_at]
				, 0 AS [updated_by]
				, [surpluses].[pdcd] AS  [product_code]
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
			FROM [APCSProDB].[trans].[surpluses]
			WHERE [surpluses].[serial_no] = @lot_no;

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
