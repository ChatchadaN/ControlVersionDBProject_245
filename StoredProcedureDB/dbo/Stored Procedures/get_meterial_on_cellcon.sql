-- =============================================
-- Author:		<Author,,Name : Vanatjaya P. 009131>
-- Create date: <Create Date,2022/08/02,Time : 15.51>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[get_meterial_on_cellcon]
	-- Add the parameters for the stored procedure here
	  @lotno varchar(10) = ''
	 ,@details_value nvarchar(255) = ''

AS
BEGIN
	
    -- Insert statements for procedure here
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
		,'EXEC [dbo].[get_meterial_on_cellcon --> Access Store] details_value = ''' + @details_value + ''''
		,@lotno

	select * from APCSProDB.material.productions where details = @details_value
END
