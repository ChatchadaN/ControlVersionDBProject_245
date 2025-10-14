-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [man].[sp_get_user_authorization_001]
	-- Add the parameters for the stored procedure here
	@emp_num varchar(10)
	,	@app_name varchar(50)
	,	@function_name varchar(50)
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
		,'EXEC [man].[sp_get_user_authorization] @emp_num = '''+@emp_num +''', @app_name = ''' + @app_name +''', @function_name = ''' + @function_name + ''''

	IF EXISTS(SELECT [users].[id]
	FROM [APCSProDB].[man].[users]
	INNER JOIN [APCSProDB].[man].[user_roles] ON [user_roles].[user_id] = [users].[id]
	INNER JOIN [APCSProDB].[man].[roles] ON [roles].[id] = [user_roles].[role_id]
	INNER JOIN [APCSProDB].[man].[role_permissions] ON [role_permissions].[role_id] = [roles].[id]
	INNER JOIN [APCSProDB].[man].[permissions] ON [permissions].[id] = [role_permissions].[permission_id]
	INNER JOIN [APCSProDB].[man].[permission_operations] ON [permission_operations].[permission_id] = [permissions].[id]
	INNER JOIN [APCSProDB].[man].[operations] ON [operations].[id] = [permission_operations].[operation_id]
	WHERE ([users].[emp_num] = @emp_num
	AND [operations].[app_name] = @app_name
	AND [operations].[function_name] = @function_name)
	OR ([users].[emp_num] = @emp_num
	AND [users].[is_admin] = 1))
	BEGIN
			SELECT 'TRUE' as Is_Pass
			, 'Authentication Successful' AS Error_Message_ENG
			, N'Authentication สำเร็จ' AS Error_Message_THA
			, N'' AS Handling 
	END
	ELSE
	BEGIN
			SELECT 'FALSE' as Is_Pass
			, 'Authentication failed! Try again.' AS Error_Message_ENG
			, N'Authentication ไม่ถูกต้อง' AS Error_Message_THA
			, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
	END



END
