-- =============================================
-- Author:		<Kittitat P.>
-- Create date: <2023/02/16>
-- Description:	<Create recall_lot (D lot) in trans.surpluses>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_recall_surpluses_002]
	-- Add the parameters for the stored procedure here
	@new_lotno VARCHAR(10)
	, @original_lotno VARCHAR(10)
	, @empid INT
	, @qty INT
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
		, ISNULL('EXEC [atom].[sp_set_recall_surpluses_002] @new_lotno = ''' + @new_lotno + '''','EXEC [atom].[sp_set_recall_surpluses_002] @new_lotno = NULL')
			+ ISNULL(', @original_lotno = ''' + @original_lotno + '''',', @original_lotno = NULL')
			+ ISNULL(', @empid = ' + CAST(@empid AS VARCHAR),', @empid = NULL')
			+ ISNULL(', @qty = ' + CAST(@qty AS VARCHAR),', @qty = NULL')
		, @new_lotno;
	----------------------------------------------------------------------------
	----- # create lot in trans.surpluses
	----------------------------------------------------------------------------
	DECLARE @trans_lots_id INT = (SELECT [id] FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) WHERE [lot_no] = @new_lotno);
	DECLARE @trans_lots_original_id INT = (SELECT [id] FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) WHERE [lot_no] = @original_lotno);
	DECLARE @date_mix DATETIME = GETDATE();

	BEGIN TRANSACTION
	BEGIN TRY
		----------- surpluses ----------- 
		IF NOT EXISTS (SELECT [serial_no] FROM [APCSProDB].[trans].[surpluses] WITH (NOLOCK) WHERE [serial_no] = @new_lotno)
		BEGIN
			-------- get surpluses.id --------  
			DECLARE @trans_surpluses_id INT
			SELECT @trans_surpluses_id = [numbers].[id] + 1 
			FROM [APCSProDB].[trans].[numbers] WITH (NOLOCK)
			WHERE [numbers].[name] = 'surpluses.id';

			-------- set surpluses.id --------  
			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = @trans_surpluses_id
			WHERE [numbers].[name] = 'surpluses.id';

			INSERT INTO [APCSProDB].[trans].[surpluses]
			(
				[id]
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
				, [comment]
			)
			SELECT @trans_surpluses_id AS [id]
				, @trans_lots_id AS [lot_id]
				, @qty AS [pcs]
				, @new_lotno AS [serial_no]
				, 2 AS [in_stock]
				, NULL AS [location_id]
				, NULL AS [acc_location_id]
				, @date_mix AS [created_at]
				, @empid AS [created_by]
				, @date_mix AS [updated_at]
				, @empid AS [updated_by]
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
			FROM [APCSProDB].[trans].[surpluses] WITH (NOLOCK) 
			INNER JOIN [APCSProDB].[trans].[lots] WITH (NOLOCK) ON [surpluses].[lot_id] = [lots].[id]
			WHERE [surpluses].[lot_id]  = @trans_lots_original_id;
		END
		ELSE
		BEGIN
			ROLLBACK TRANSACTION;
			SELECT 'FALSE' AS [Is_Pass] 
				, 'have data in surpluses !!' AS [Error_Message_ENG]
				, N'มีข้อมูลใน surpluses แล้ว' AS [Error_Message_THA] 
				, N'กรุณาติดต่อ system' AS [Handling];
			RETURN;
		END

		----------- surpluse_records ----------- 
		INSERT INTO [APCSProDB].[trans].[surpluse_records]
		(
			[recorded_at]
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
			, [comment]
		)
		SELECT @date_mix AS [recorded_at]
			, @empid AS [operated_by]
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
		FROM [APCSProDB].[trans].[surpluses] WITH (NOLOCK) 
		WHERE [surpluses].[lot_id]  = @trans_lots_id;
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
		ROLLBACK TRANSACTION;
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Insert data surpluses error !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล surpluses ไม่สำเร็จ !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END CATCH
END
