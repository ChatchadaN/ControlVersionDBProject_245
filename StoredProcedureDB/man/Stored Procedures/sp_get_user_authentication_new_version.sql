-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_user_authentication_new_version]
	-- Add the parameters for the stored procedure here
	@emp_num VARCHAR(10),
	@password VARCHAR(20) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [man].[sp_get_user_authentication_new_version] @emp_num = ''' + @emp_num + ''''
			+ ', @password = ''' + @password + ''''

	----# check have data in table users
	IF NOT EXISTS (
		SELECT [users].[id]
		FROM [APCSProDB].[man].[users]
		WHERE [users].[emp_num] = @emp_num
	)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
			, 'No information found in the system !!' AS [Error_Message_ENG]
			, N'ไม่พบข้อมูลในระบบ !!' AS [Error_Message_THA]
			, N'กรุณาตรวจสอบข้อมูล !!' AS [Handling];
	END
	----# check lockout = 1
	ELSE IF EXISTS (
		SELECT [users].[id]
		FROM [APCSProDB].[man].[users]
		WHERE [users].[emp_num] = @emp_num
			AND [users].[lockout] = 1
	)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
			, 'Resigned status !!' AS [Error_Message_ENG]
			, N'สถานะลาออก !!' AS [Error_Message_THA]
			, N'กรุณาตรวจสอบข้อมูล !!' AS [Handling];
	END
	ELSE
	BEGIN
		----# check emp_num and password
		IF EXISTS (
			SELECT [users].[id]
			FROM [APCSProDB].[man].[users]
			WHERE [users].[emp_num] = @emp_num
				AND [users].[password] = @password
		)
		BEGIN
			----# found
			SELECT 'TRUE' AS [Is_Pass]
				, 'Login successful' AS [Error_Message_ENG]
				, N'เข้าสู่ระบบสำเร็จ' AS [Error_Message_THA]
				, N'' AS [Handling];
		END
		ELSE
		BEGIN
			----# not found
			SELECT 'FALSE' AS [Is_Pass]
				, 'Password is incorrect !!' AS [Error_Message_ENG]
				, N'รหัสผ่านไม่ถูกต้อง !!' AS [Error_Message_THA]
				, N'กรุณาตรวจสอบข้อมูล !!' AS [Handling];
		END
	END
END
