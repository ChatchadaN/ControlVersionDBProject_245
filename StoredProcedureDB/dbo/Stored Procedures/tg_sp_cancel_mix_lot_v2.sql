-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_cancel_mix_lot_v2]
	-- Add the parameters for the stored procedure here
	@lot_standard varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lot_id int
	DECLARE @check_wip_state tinyint = 0

    -- Insert statements for procedure here
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
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
		,'EXEC [dbo].[tg_sp_cancel_mix_lot_V2] @lot_standard = ''' + @lot_standard + ''''
		,@lot_standard


	select @lot_id = id from APCSProDB.trans.lots where lot_no = @lot_standard

	BEGIN TRY
		--update wip state = 200 is lot cancel
		update APCSProDB.trans.lots 
		set wip_state = 200
		where lot_no = @lot_standard

		select @check_wip_state = wip_state from APCSProDB.trans.lots where lot_no = @lot_standard

		--2022/08/24 time : 11.25
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
			,'EXEC [dbo].[tg_sp_cancel_mix_lot_V2] @lot_standard = ''' + @lot_standard + ''',@wip_State = ''' + CAST(@check_wip_state AS char(10)) + ''''
			,@lot_standard

	END TRY
	BEGIN CATCH 
		SELECT 'FALSE' AS Status ,'UPDATE WIP STATE CANCEL LOT ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ update state ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH

	BEGIN TRY
		--instock = 4 is cancel lot standard 
		UPDATE APCSProDB.trans.surpluses SET in_stock = 4
		FROM APCSProDB.trans.lot_combine
		INNER JOIN APCSProDB.trans.surpluses ON lot_combine.member_lot_id = surpluses.lot_id
		WHERE lot_combine.lot_id = @lot_id
	END TRY
	BEGIN CATCH 
		SELECT 'FALSE' AS Status ,'UPDATE INSTOCK ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ update instock hasuu ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH


END
