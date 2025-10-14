-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[sp_set_surpluse_recall_v1] 
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10)
	, @qty_hasuu INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Log StoredProcedureDB
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
		, 'EXEC [dbo].[sp_set_surpluse_recall] @lotno = ''' + @lot_no + ''',@qty_hasuu = ''' + CAST(@qty_hasuu AS VARCHAR) + ''''
		, @lot_no;



	-- Update surpluses
	UPDATE [APCSProDB].[trans].[surpluses]
    SET [pcs] = @qty_hasuu
		, [updated_at] = GETDATE()
		, [updated_by] = 1
    WHERE serial_no = @lot_no;

	-- Insert surpluse_records
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
	SELECT GETDATE() AS [recorded_at]
		, 1 AS [operated_by]
		, 2 AS [record_class] -- RECORORD_CLASS STATUS 1 : REGISTER,2:UPDATE,3:CANCEL(DELETE)
		, [id] AS [surpluse_id]
		, [lot_id]
		, [pcs]
		, [serial_no]
		, [in_stock]
		, [location_id]
		, [acc_location_id]
		, [reprint_count]
		, [created_at]
		, [created_by]
		, GETDATE() AS [updated_at]
		, 1 AS [updated_by]
		, [pdcd] AS  [product_code]
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
	FROM [APCSProDB].[trans].[surpluses]
	WHERE [serial_no] = @lot_no;
END
