-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [req].[sp_get_user_authentication]
	-- Add the parameters for the stored procedure here
	@emp_num NVARCHAR(10),
	@password NVARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS(SELECT [emp_num] FROM [APCSProDWR].[req].[users] WHERE [emp_num] = @emp_num)
	BEGIN
		---- # have data in [APCSProDWR].[req].[users]
		IF EXISTS(SELECT [emp_num] FROM [APCSProDWR].[req].[users] WHERE [emp_num] = @emp_num AND [password] = @password)
		BEGIN
			SELECT 'PASS' AS [status]
				, 'Login Successful' AS [Error_Message_ENG]
				, N'Login สำเร็จ' AS [Error_Message_THA]
				, N'' AS [Handling];
			RETURN;
		END
		ELSE
		BEGIN
			SELECT 'FAIL' AS [status]
				, 'Invalid username/password' AS [Error_Message_ENG]
				, N'username/password ไม่ถูกต้อง' AS [Error_Message_THA]
				, N'กรุณาตรวจสอบข้อมูล !!' AS [Handling];
			RETURN;
		END
		---- # have data in [APCSProDWR].[req].[users]
	END
	ELSE
	BEGIN
		---- # not have data in [APCSProDWR].[req].[users]
		IF EXISTS(SELECT [CODEMPID] FROM [TECDB].[TEC_E_Learning].[dbo].[vew_HRMS_Employee] WHERE [CODEMPID] = @emp_num)
		BEGIN
			---------------------------------------------------
			INSERT INTO [APCSProDWR].[req].[users] 
				( [emp_num]
				, [password]
				, [name]
				, [full_name]
				, [full_name_eng]
				, [headquarter]
				, [division]
				, [department]
				, [section]
				, [is_permission] )
			SELECT [CODEMPID]
				, [CODEMPID]
				, [NICKNAME]
				, [NAMEMPT]
				, [NAMEMPE]
				, [SECTION]
				, [DEPARTMENT]
				, [DEPARTMENT2]
				, [DEPARTMENT3]
				, 0
			FROM [TECDB].[TEC_E_Learning].[dbo].[vew_HRMS_Employee] 
			WHERE [CODEMPID] = @emp_num;

			IF (@@ROWCOUNT > 0)
			BEGIN
				SELECT 'PASS' AS [status]
					, 'Login Successful' AS [Error_Message_ENG]
					, N'Login สำเร็จ' AS [Error_Message_THA]
					, N'' AS [Handling];
				RETURN;
			END
			ELSE
			BEGIN
				SELECT 'FAIL' AS [status]
					, 'Invalid username/password' AS [Error_Message_ENG]
					, N'username/password ไม่ถูกต้อง' AS [Error_Message_THA]
					, N'กรุณาตรวจสอบข้อมูล !!' AS [Handling];
				RETURN;
			END
			---------------------------------------------------
		END
		ELSE
		BEGIN
			SELECT 'FAIL' AS [status]
				, 'not found employee ID' AS [Error_Message_ENG]
				, N'ไม่พบรหัสพนักงาน' AS [Error_Message_THA]
				, N'กรุณาตรวจสอบข้อมูล !!' AS [Handling];
			RETURN;
		END
		---- # not have data in [APCSProDWR].[req].[users]
	END
END