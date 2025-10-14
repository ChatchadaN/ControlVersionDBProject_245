-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_setupchecksheet_confirmftreport]
	-- Add the parameters for the stored procedure here
	@MCNo varchar(30), @LotNo varchar(10), @PackageName varchar(10), @DeviceName varchar(20), @SetupStatus varchar(10), @SetupConfirmDate datetime
AS										   
BEGIN									   
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

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
		,'EXEC [dbo].[sp_set_setupchecksheet_confirmftreport] @MCNo = '''+ @MCNo + ''', @LotNo = ''' + @LotNo + ''', @PackageName = ''' + @PackageName + ''', @DeviceName = ''' + @DeviceName + ''', @SetupStatus = ''' + @SetupStatus + ''', @SetupConfirmDate = ''' + CONVERT (varchar (255), @SetupConfirmDate) + ''''

	UPDATE [DBx].[dbo].[FTSetupReport]              
	SET [LotNo] = @LotNo,
		[PackageName] = @PackageName,
		[DeviceName] = @DeviceName,
		[SetupStatus] = @SetupStatus,
		[SetupConfirmDate] = @SetupConfirmDate  
	WHERE MCNo = @MCNo

END
