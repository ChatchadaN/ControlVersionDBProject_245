-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_user_authentication]
	-- Add the parameters for the stored procedure here
	@emp_num varchar(10)
	,	@password varchar(50) = null
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
		,'EXEC [man].[sp_get_user_authentication] @emp_num = '''+@emp_num +''', @password = ''' + @password + ''''

	IF EXISTS(SELECT [users].[id]
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @emp_num
	AND [users].[password] = @password
	)
	BEGIN
		SELECT 'PASS' as [status]
	END
	ELSE
	BEGIN
		SELECT 'FAIL' as [status]
	END



END
