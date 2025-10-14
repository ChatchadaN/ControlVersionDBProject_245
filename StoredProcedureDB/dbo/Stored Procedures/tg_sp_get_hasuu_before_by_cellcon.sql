-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date : 2023/02/10 Time : 08.00,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_hasuu_before_by_cellcon]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--DECLARE @lot_id int = 0

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
		,'EXEC [dbo].[tg_sp_get_hasuu_before_by_cellcon] @lotno = ''' + @lotno + ''''

	IF @lotno <> ''
	BEGIN
		IF (SUBSTRING(@lotno,5,1) IN ('A','F'))
		BEGIN
			---- A,F
			IF EXISTS (
				select sur.serial_no as lot_no
					, sur.pcs as qty
				from APCSProDB.trans.lot_combine as lot_cb
				inner join APCSProDB.trans.lots as lot_master on lot_cb.lot_id = lot_master.id
				inner join APCSProDB.trans.lots as lot_member on lot_cb.member_lot_id = lot_member.id
				inner join APCSProDB.trans.surpluses as sur on lot_member.id = sur.lot_id
				where lot_master.lot_no = @lotno
					and lot_master.id <> lot_member.id
			)
			BEGIN
				---- EXISTS
				select sur.serial_no as lot_no
					, sur.pcs as qty
				from APCSProDB.trans.lot_combine as lot_cb
				inner join APCSProDB.trans.lots as lot_master on lot_cb.lot_id = lot_master.id
				inner join APCSProDB.trans.lots as lot_member on lot_cb.member_lot_id = lot_member.id
				inner join APCSProDB.trans.surpluses as sur on lot_member.id = sur.lot_id
				where lot_master.lot_no = @lotno
					and lot_master.id <> lot_member.id;
			END
			ELSE
			BEGIN
				---- NOT EXISTS
				select '' as lot_no, 0 as qty;
			END
		END
		ELSE
		BEGIN
			select '' as lot_no, 0 as qty;
		END
	END
    
	
END
