-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_hasuu_stock_qty]
	-- Add the parameters for the stored procedure here
		 @lotno varchar(10)
		,@hasuu_stock_qty int
		,@emp_no char(6) = ''
		,@comment_val int = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from

	--Call Store Version2 Use 2023/01/12  --รออัพเดตตอนอัพระบบ Update Date : 2023/01/31 Time : 09.14
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_hasuu_stock_qty_ver2] @lotno = @lotno
	,@hasuu_stock_qty = @hasuu_stock_qty
	,@emp_no = @emp_no
	,@comment_val = @comment_val

	-- interfering with SELECT statements.
	--SET NOCOUNT ON;
	--DECLARE @LOTNO_ID INT
	--DECLARE @Empno_int int = 0

	----SEARCH LOT_ID DATA
	--select @LOTNO_ID = lot_id from APCSProDB.trans.surpluses where serial_no = @lotno
 --   -- Insert statements for procedure here

	----update log 2022/08/19 time : 16.33
	--INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--([record_at]
 --     , [record_class]
 --     , [login_name]
 --     , [hostname]
 --     , [appname]
 --     , [command_text]
	--  , [lot_no])
	--SELECT GETDATE()
	--	,'4'
	--	,ORIGINAL_LOGIN()
	--	,HOST_NAME()
	--	,APP_NAME()
	--	,'EXEC [dbo].[tg_sp_set_hasuu_stock_qty] @lotno = ''' + @lotno + ''',@hasuu_stock_qty = ''' + CONVERT (varchar (10), @hasuu_stock_qty) + ''',@emp_no = ''' + @emp_no + ''''
	--	,@lotno

	--select @Empno_int = CONVERT(INT, @emp_no)

	----UPDATE QTY TABEL SURPLUSES
	--UPDATE [APCSProDB].[trans].[surpluses]
	--SET pcs = @hasuu_stock_qty
	--,updated_at = GETDATE()
	--,updated_by = @Empno_int
	--WHERE serial_no = @lotno

	---- INSERT RECORD CLASS TO TABLE tg_sp_set_surpluse_records create data : 2021/12/14 time : 09.56
	--BEGIN TRY
	--	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno
	--	,@sataus_record_class = 2
	--	,@emp_no_int = @Empno_int
	--END TRY
	--BEGIN CATCH 
	--	SELECT 'FALSE' AS Status ,'INSERT DATA SURPLUSE_RECORDS ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
	--RETURN
	--END CATCH

END
