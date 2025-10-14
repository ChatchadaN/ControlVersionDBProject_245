-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_qtypass_tranlot]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
	,@qty_pass int
	--add parameter 2022/07/26 time : 12.03
	,@empno varchar(6) = ''
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
      , [command_text]
	  , [lot_no])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[tg_sp_set_qtypass_tranlot] @lotno = ''' + @lotno + ''',@qty_pass = ''' + CONVERT (varchar (10), @qty_pass)  +  ''',@empno = ''' + @empno +  ''''
		,@lotno

    -- Insert statements for procedure here
	IF @lotno != ''
	BEGIN
		UPDATE APCSProDB.trans.lots 
		SET qty_pass = @qty_pass
		WHERE lot_no = @lotno
	END
	

END
