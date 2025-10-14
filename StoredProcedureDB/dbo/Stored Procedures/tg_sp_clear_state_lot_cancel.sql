-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_clear_state_lot_cancel]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lot_id int

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
		,'EXEC [dbo].[dbo].[tg_sp_clear_state_lot_cancel] @lotno = ''' + @lotno + ''''

	select @lot_id = id from APCSProDB.trans.lots where lot_no = @lotno

    -- Insert statements for procedure here
	IF @lotno != ''
	BEGIN
		--update wip state = 20 move is wip in process
		update APCSProDB.trans.lots
		set wip_state = 20
		where lot_no = @lotno

		BEGIN TRY
			--instock = 4 is cancel lot standard 
			UPDATE APCSProDB.trans.surpluses SET in_stock = 0
			FROM APCSProDB.trans.lot_combine
			INNER JOIN APCSProDB.trans.surpluses ON lot_combine.member_lot_id = surpluses.lot_id
			WHERE lot_combine.lot_id = @lot_id
		END TRY
		BEGIN CATCH 
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
					([record_at]
					, [record_class]
					, [login_name]
					, [hostname]
					, [appname]
					, [command_text])
				SELECT GETDATE()
					, '4'
					, ORIGINAL_LOGIN()
					, 'StoredProcedureDB'
					, 'TGSYSTEM'
					, 'EXEC [dbo].[dbo].[tg_sp_clear_state_lot_cancel] @lotno = ''' + @lotno + ''' ERROR UPDATE INSTOCK HASUU IS 0'
		END CATCH

		SELECT 'TRUE' AS Status ,'UPDATE WIP STATE SUCCESS !!' AS Error_Message_ENG,N'update wip state สำเร็จ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Status ,'UPDATE WIP STATE LOT CANCEL ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ update state ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END
	

END
