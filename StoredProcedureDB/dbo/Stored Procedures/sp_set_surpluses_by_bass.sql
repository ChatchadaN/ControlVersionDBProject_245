-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_surpluses_by_bass] 
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10), 
	@qty INT = NULL,
	@empno INT,
	@in_stock INT = NULL,
	@is_ability INT = NULL,
	@mode INT = 0 --- 0:update qty, 1:update in_stock, 2:update is_ability
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
		, 'EXEC [dbo].[sp_set_surpluse_by_bass]'
			+ ' @lot_no = ''' + (CASE WHEN @lot_no IS NOT NULL THEN CAST(@lot_no AS VARCHAR(10)) ELSE 'NULL' END) + ''''
			+ ' ,@qty = ' + (CASE WHEN @qty IS NOT NULL THEN CAST(@qty AS VARCHAR(10)) ELSE 'NULL' END)
			+ ' ,@empno = ' + (CASE WHEN @empno IS NOT NULL THEN CAST(@empno AS VARCHAR(6)) ELSE 'NULL' END)
			+ ' ,@in_stock = ' + (CASE WHEN @in_stock IS NOT NULL THEN CAST(@in_stock AS VARCHAR(1)) ELSE 'NULL' END)
			+ ' ,@is_ability = ' + (CASE WHEN @is_ability IS NOT NULL THEN CAST(@is_ability AS VARCHAR(2)) ELSE 'NULL' END)
			+ ' ,@mode = ' + (CASE WHEN @mode IS NOT NULL THEN CAST(@mode AS VARCHAR(2)) ELSE 'NULL' END)
		, (CASE WHEN @lot_no IS NOT NULL THEN CAST(@lot_no AS VARCHAR(10)) ELSE 'NULL' END);

	IF (@mode = 0)
	BEGIN
		-- Update surpluses
		UPDATE [APCSProDB].[trans].[surpluses]
		SET [pcs] = ISNULL(@qty, [pcs])
			, [updated_at] = GETDATE()
			, [updated_by] = @empno
		WHERE [serial_no] = @lot_no;

		-- Insert surpluse records
		EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lot_no
			, @sataus_record_class = 2
			, @emp_no_int = @empno;

		-- Update Hstock
		UPDATE [APCSProDWH].[dbo].[H_STOCK_IF]
		SET [HASU_Stock_QTY] = ISNULL(@qty, [HASU_Stock_QTY])
		WHERE [LotNo] = @lot_no;
	END
	ELSE IF (@mode = 1)
	BEGIN
		-- Update surpluses
		UPDATE [APCSProDB].[trans].[surpluses]
		SET [in_stock] = ISNULL(@in_stock, [in_stock])
			, [updated_at] = GETDATE()
			, [updated_by] = @empno
		WHERE [serial_no] = @lot_no;

		-- Insert surpluse records
		EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lot_no
			, @sataus_record_class = 2
			, @emp_no_int = @empno;

		-- Update Hstock
		UPDATE [APCSProDWH].[dbo].[H_STOCK_IF]
		SET [DMY_OUT_Flag] = (CASE WHEN @in_stock IS NULL THEN [DMY_OUT_Flag] ELSE IIF(CAST(@in_stock AS VARCHAR(10)) IN ('0','9'), '1', '') END)
		WHERE [LotNo] = @lot_no;
	END
	ELSE IF (@mode = 2)
	BEGIN
		UPDATE [APCSProDB].[trans].[surpluses]
		SET [is_ability] = ISNULL(@is_ability, [is_ability])
			, [updated_at] = GETDATE()
			, [updated_by] = @empno
		WHERE [serial_no] = @lot_no;

		-- Insert surpluse records
		EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lot_no
			, @sataus_record_class = 2
			, @emp_no_int = @empno;
	END
END
