-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [man].[sp_get_user_authentication_001]
	-- Add the parameters for the stored procedure here
	@emp_num varchar(10)
	,	@password varchar(50) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [APIStoredProDB].[dbo].[exec_sp_history]
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
		,'EXEC [man].[sp_get_user_authentication_001] @emp_num = '''+@emp_num +''', @password = ''' + @password + ''''

	IF EXISTS(SELECT [users].[id]
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @emp_num
	AND [users].[password] = @password
	)
	BEGIN
			SELECT 'TRUE' as Is_Pass
			, 'Login Successful' AS Error_Message_ENG
			, N'Login สำเร็จ' AS Error_Message_THA
			, N'' AS Handling 
	END
	ELSE
	BEGIN
			SELECT 'FALSE' as Is_Pass
			, 'Invalid username/password' AS Error_Message_ENG
			, N'username/password ไม่ถูกต้อง' AS Error_Message_THA
			, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
	END



END
