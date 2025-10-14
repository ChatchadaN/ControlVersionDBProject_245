-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_update_state_surpluses] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Lot_id INT
    -- Insert statements for procedure here
	select @Lot_id = id from APCSProDB.trans.lots where lot_no = @lotno


	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[tg_sp_update_state_surpluses] @lotno = ''' + @lotno + ''''


	--update state column instock table surpluses
	--UPDATE APCSProDB.trans.surpluses
	--SET in_stock = '0'
	--WHERE serial_no = @lotno

	--update state column instock table surpluses_records
	--UPDATE APCSProDB.trans.surpluse_records
	--SET in_stock = '0'
	--WHERE lot_id = @Lot_id

END
