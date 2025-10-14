-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_hasuulot_of_pcrequest]
	-- Add the parameters for the stored procedure here
	@lot_standard varchar(10) = ''
AS
BEGIN
	
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
		,'EXEC [dbo].[tg_sp_get_hasuulot_of_pcrequest] @lot_standard = ''' + @lot_standard + ''''
		,@lot_standard


		select lots_hasuu.lot_no as lot_member
			,sur.pcs as qty_hasuu
			,sur.in_stock
			,sur.location_id
		from APCSProDB.trans.lot_combine as lot_cb 
		inner join APCSProDB.trans.lots on lot_cb.lot_id = lots.id 
		inner join APCSProDB.trans.lots as lots_hasuu on lot_cb.member_lot_id = lots_hasuu.id 
		inner join APCSProDB.trans.surpluses as sur on lot_cb.member_lot_id = sur.lot_id 
		where lots.lot_no = @lot_standard

END
