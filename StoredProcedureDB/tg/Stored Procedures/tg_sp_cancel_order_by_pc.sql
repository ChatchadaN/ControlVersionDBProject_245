-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [tg].[tg_sp_cancel_order_by_pc]
	-- Add the parameters for the stored procedure here
	 @auto_order_id int = null
	,@order_id int = null
	,@month_year varchar(6) = ''
	,@emp_no char(6) = ''
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @state_create_lot INT = null
	DECLARE @lot_id INT = null
	DECLARE @qty_last INT = 0
	DECLARE @emp_id INT = null
	DECLARE @lotno varchar(10) = ''
	DECLARE @in_stock_now INT = null
	DECLARE @qty_last_hasuu INT = null
	
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		 ([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[tg_sp_cancel_order_by_pc] @order_id = ''' + CONVERT(varchar(10),@order_id)
			+ ''',@month_year = ''' + @month_year 
			+ ''',@emp_no = ''' + @emp_no + ''''
		,CONVERT(varchar(10),@auto_order_id)

	--Get data of order pc
	SELECT  @state_create_lot = or_pc.is_state 
		   ,@lot_id = or_pc.lot_id
		   ,@qty_last = or_pc.qty_last
		   ,@lotno = lot.lot_no
		   ,@in_stock_now = sur.in_stock
	FROM APCSProDB.trans.pc_request_orders as or_pc
	LEFT JOIN APCSProDB.trans.lots as lot on or_pc.lot_id = lot.id
	LEFT JOIN APCSProDB.trans.surpluses as sur on lot.id = sur.lot_id
	where or_pc.id = @auto_order_id

	--Get data of empno
	SELECT @emp_id = id FROM APCSProDB.man.users where emp_num = @emp_no

	BEGIN TRY
		IF @auto_order_id is not null 
		BEGIN
			PRINT '@auto_order_id is not null'
			--condtion 1 (Create order but create new lot not yet)
			IF @state_create_lot = 0
			BEGIN
				PRINT 'condtion 1 @state_create_lot is null  --> delete order'
				DELETE APCSProDB.trans.pc_request_orders where id = @auto_order_id
			END

			--condtion 2 (Successfully created an order and created a new lot)
			IF @state_create_lot = 1 and @lot_id is not null
			BEGIN
				PRINT 'condtion 2 @state_create_lot is not null and @lot_id is not null'
				--delete order pc
				DELETE APCSProDB.trans.pc_request_orders where id = @auto_order_id
				
				IF @lot_id is not null
				BEGIN
					PRINT '@lot_id is not null'
					--update wip state is 70 of new lot in tran.lots table
					UPDATE APCSProDB.trans.lots
					SET  wip_state = 70
						,qty_out = 0
						,qty_hasuu = case when @in_stock_now = 2 then (qty_hasuu + @qty_last)
									 when @in_stock_now = 1 then qty_hasuu
									 when @in_stock_now = 0 then @qty_last
									 else qty_hasuu end  --add conditon check instock now #update date : 2024/06/28 time : 13.19
					WHERE id = @lot_id
		
					--update instock and qty in table tran.surpluses
					UPDATE APCSProDB.trans.surpluses
					SET  in_stock = case when @in_stock_now = 2 then 2
										 when @in_stock_now = 1 then 1
										 when @in_stock_now = 0 then 0
										 else in_stock end
						,pcs =  case when @in_stock_now = 2 then (pcs + @qty_last)
									 when @in_stock_now = 1 then pcs
									 when @in_stock_now = 0 then @qty_last
									 else pcs end
						,updated_at = GETDATE()
						,updated_by = @emp_id
					WHERE lot_id = @lot_id
		
					--insert data go to table surpluses record
					EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno
					,@sataus_record_class = 2
					,@emp_no_int = @emp_id

					select @qty_last_hasuu = pcs from APCSProDB.trans.surpluses where lot_id = @lot_id

					--update data in Is (table : interface)
					UPDATE APCSProDWH.dbo.H_STOCK_IF 
					SET HASU_Stock_QTY = @qty_last_hasuu  --open 2024/06/28 time : 13.19
					--SET HASU_Stock_QTY = (HASU_Stock_QTY + @qty_last)  --close 2024/06/28 time : 13.19 by Aomsin
					WHERE LotNo = @lotno

				END
			END

			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				 ([record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no])
			SELECT GETDATE()
				,'4'
				,ORIGINAL_LOGIN()
				,HOST_NAME()
				,APP_NAME()
				,'EXEC [dbo].[tg_sp_cancel_order_by_pc success] @order_id = ''' + CONVERT(varchar(10),@order_id)
					+ ''',@month_year = ''' + @month_year 
					+ ''',@emp_no = ''' + @emp_no + ''''
				,CONVERT(varchar(10),@auto_order_id)

			SELECT 'TRUE' AS Is_Pass 
			,'Delete order pc and update wipstate, qtyhasuu success !!' AS Error_Message_ENG
			,N'cancel order สำเร็จ !!' AS Error_Message_THA 
			,N'กรุณาติดต่อ System' AS Handling
			RETURN
		END
	END TRY
	BEGIN CATCH
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			 ([record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no])
		SELECT GETDATE()
			,'4'
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			,'EXEC [dbo].[tg_sp_cancel_order_by_pc fail] @order_id = ''' + CONVERT(varchar(10),@order_id)
				+ ''',@month_year = ''' + @month_year 
				+ ''',@emp_no = ''' + @emp_no + ''''
			,CONVERT(varchar(10),@auto_order_id)

		SELECT 'FALSE' AS Is_Pass 
		,'Can not delete order pc and update wipstate, qtyhasuu fail !!' AS Error_Message_ENG
		,N'ไม่สามารถ cancel order ได้ !!' AS Error_Message_THA 
		,N'กรุณาติดต่อ System' AS Handling
		RETURN

	END CATCH

END
