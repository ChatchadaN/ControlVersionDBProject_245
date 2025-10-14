-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [dbo].[tg_sp_set_surpluse_records] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
	,@sataus_record_class int
	--add parameter date : 2021/12/07 time : 12.52
	,@emp_no_int int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
		SET NOCOUNT ON;
	--DECLARE @SURPLUSE_ID_CHECK INT
	DECLARE @LOTNO_HASUU VARCHAR(10) = ''
	DECLARE @RECORE_CLASS INT
	DECLARE @LOTNO_ID INT
	DECLARE @SURPLUSE_ID INT
	DECLARE @QTY_HASUU INT
	DECLARE @IN_STOCK INT
	DECLARE @LOCATION_ID INT
	DECLARE @LOTNO_ID_chk INT = 0

    -- Insert statements for procedure here
	select @LOTNO_HASUU = serial_no 
	,@SURPLUSE_ID = id
	,@LOTNO_ID = lot_id
	,@QTY_HASUU = pcs
	,@IN_STOCK = in_stock
	,@LOCATION_ID = location_id
	from APCSProDB.trans.surpluses 
	where serial_no = @lotno

	SELECT @LOTNO_ID_chk = lot_id FROM APCSProDB.trans.surpluse_records WHERE lot_id = @LOTNO_ID

	--RECORORD_CLASS STATUS 1 : REGISTER,2:UPDATE,3:CANCEL(DELETE)
	--UPDATE DATE 2022/03/01	TIME 13.50
 
			INSERT INTO APCSProDB.trans.surpluse_records --REGISTER
			(		  recorded_at
					, operated_by
					, record_class
					, surpluse_id
					, lot_id
					, pcs
					, serial_no
					, in_stock
					, location_id
					, acc_location_id
					, reprint_count
					, created_at
					, created_by
					, updated_at
					, updated_by
					, product_code
					, qc_instruction
					, mark_no
					, original_lot_id
					, machine_id
					, user_code
					, product_control_class
					, product_class
					, production_class
					, rank_no
					, hinsyu_class
					, label_class
					, transfer_flag
					, transfer_pcs
					, stock_class --add value data modify : 2022/03/10 time : 14.31
					, is_ability
					, comment --add value data modify : 2023/01/06 time : 11.04
			)
			SELECT   GETDATE()
					, @emp_no_int
					, @sataus_record_class
					, surpluses.id
					, surpluses.lot_id
					, surpluses.pcs
					, surpluses.serial_no
					, surpluses.in_stock
					, surpluses.location_id
					, NULL
					, 0
					,  GETDATE()
					, @emp_no_int
					,  GETDATE()
					, @emp_no_int
					, surpluses.pdcd
					, surpluses.qc_instruction
					, surpluses.mark_no
					, surpluses.original_lot_id
					, surpluses.machine_id
					, surpluses.user_code
					, surpluses.product_control_class
					, surpluses.product_class
					, surpluses.production_class
					, surpluses.rank_no
					, surpluses.hinsyu_class
					, surpluses.label_class
					, surpluses.transfer_flag
					, surpluses.transfer_pcs
					, surpluses.stock_class --add value data modify : 2022/03/10 time : 14.31
					, surpluses.is_ability  --add value data modify : 2024/11/26 time : 14.31
					, surpluses.comment --add value data modify : 2023/01/06 time : 11.04
			FROM APCSProDB.trans.surpluses 
			WHERE serial_no = @lotno


	--Create Date 2021/10/09  , Update Log by add parameter in_stock of lotno 2023/03/09 time : 13.51
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
		,'EXEC [dbo].[tg_sp_set_surpluse_records] @lotno = ''' + isnull(@lotno,'') + ''',@record_class = ''' + isnull(CONVERT (varchar (2), @sataus_record_class),'') + ''',@in_stock_current = ''' + isnull(CONVERT (varchar (2), @IN_STOCK),'') + ''''
		,@lotno




END
