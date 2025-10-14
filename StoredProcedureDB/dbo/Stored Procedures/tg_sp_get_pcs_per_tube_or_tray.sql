-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date : 2023/02/06 Time : 15.35,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_pcs_per_tube_or_tray]
	-- Add the parameters for the stored procedure here
	 @lotno varchar(10) = '' --hasuu_lot
	,@package_name varchar(10) = ''--use shortname 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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
		,'EXEC [dbo].[tg_sp_get_pcs_per_tube_or_tray]'

	IF @lotno = ''
	BEGIN
		--Get Data
		select name as new_package_name
			,short_name as old_package_name
			,pk.pcs_per_tube_or_tray 
		from APCSProDB.trans.lots as lot
		inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
		where pk.short_name = @package_name
	END
	ELSE
	BEGIN
		--Get Data
		select name as new_package_name
			,short_name as old_package_name
			,pk.pcs_per_tube_or_tray 
		from APCSProDB.trans.lots as lot
		inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
		where lot.lot_no = @lotno
	END
	

END
