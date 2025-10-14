-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_update_hasuu_stock] 
	-- Add the parameters for the stored procedure here
	  @lot_no varchar(10)
	, @qty_hasuu int = 0
	, @in_stock_value tinyint = null
	, @op_num char(6) = ''
	, @is_function int = 0  --default = 0 is inventory page, if value = 1 is disable reel page on lsms website 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[tg_sp_set_update_hasuu_stock] @lotno = ''' + @lot_no + 
			''',@qty_hasuu = ''' + CONVERT (varchar (10), @qty_hasuu) +
			''',@in_stock_value  = ''' + CONVERT (varchar (2), @in_stock_value) + 
			''',@is_function  = ''' + CONVERT (varchar (1), @is_function) + 
			''',@op_num  = ''' + @op_num + ''''
		,@lot_no
		
	DECLARE @emp_id int 
	SET @emp_id = (select id from APCSProDB.man.users where emp_num = @op_num )

	IF @is_function = 1 --disable reel hasuu
	BEGIN
		--use update instock = 0 for support resurpluses to rework function on disable hasuu reel function  # 2023/11/01 time : 09.55 by aomsin #
		UPDATE APCSProDB.trans.surpluses
		SET in_stock = (case 
						when @in_stock_value is null Then [surpluses].[in_stock]
						else @in_stock_value
					end)
			, updated_at = GETDATE()
		    , updated_by = @emp_id
		WHERE serial_no = @lot_no 
	END
	ELSE
	BEGIN
		UPDATE APCSProDB.trans.surpluses
		SET pcs = @qty_hasuu  --edit 2022/08/30 time : 16.52
					--(case 
					--	when @qty_hasuu = 0 Then [surpluses].[pcs]  --close 2022/08/30 time : 16.52
					--	else @qty_hasuu 
					--end)
		    , in_stock = (case 
						when @in_stock_value is null Then [surpluses].[in_stock]
						else @in_stock_value
					end)
			, updated_at = GETDATE()
		    , updated_by = @emp_id
		WHERE serial_no = @lot_no 
	END

	--INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records 
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lot_no
		, @sataus_record_class = 2
		, @emp_no_int = @emp_id

	if (@in_stock_value in (0,9))
	begin
		UPDATE APCSProDWH.dbo.H_STOCK_IF
		SET DMY_OUT_Flag = '1'
			, HASU_Stock_QTY = @qty_hasuu
		WHERE LotNo = @lot_no

		-- Update qty_hasuu = 0
		UPDATE APCSProDB.trans.lots
		SET qty_hasuu = 0
			, updated_at = GETDATE()
			, updated_by = @emp_id
		WHERE lot_no = @lot_no
	end
	else
	begin
		UPDATE APCSProDWH.dbo.H_STOCK_IF
		SET HASU_Stock_QTY = @qty_hasuu
		WHERE LotNo = @lot_no
	end

END
