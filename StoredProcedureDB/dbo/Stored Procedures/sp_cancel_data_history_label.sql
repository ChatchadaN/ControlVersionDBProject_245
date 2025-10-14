-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_cancel_data_history_label]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) 
AS
BEGIN

	SET NOCOUNT ON;
	DECLARE @incoming_id_value int = 0
	DECLARE @is_incoming int = 0 --is 1 : incoming,is 0 : not incoming
    -- Insert statements for procedure here

	--check is incoming
	select @is_incoming = dn.is_incoming from APCSProDB.trans.lots as lot
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	where lot_no = @lotno
	--get id incoming label
	--select @incoming_id_value = incoming_id from APCSProDB.trans.incoming_label_details where lot_no = @lotno

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
		,'EXEC [dbo].[sp_cancel_data_history_label] @lotno = ''' + @lotno + ''''


	IF @is_incoming = 1
	BEGIN
		--Add value delete label type tray = 6 and pc request hasuu at ogi 21 Create : 2021/03/18 time : 09.31
		DELETE  [APCSProDB].[trans].[label_issue_records] WHERE lot_no = @lotno and type_of_label in(4,5,6,21)
		--delete APCSProDB.trans.incoming_labels where id = @incoming_id_value --close 
		delete APCSProDB.trans.incoming_labels where id in (select incoming_id from APCSProDB.trans.incoming_label_details where lot_no = @lotno) --edit 2022/05/03 time : 13.01
		delete APCSProDB.trans.incoming_label_details where lot_no = @lotno
	END
	ELSE
	BEGIN
		--Add value delete label type tray = 6 and pc request hasuu at ogi 21 Create : 2021/10/29 time : 11.19
		DELETE  [APCSProDB].[trans].[label_issue_records] WHERE lot_no = @lotno and type_of_label in(4,5,6,21)
	END
	
END
