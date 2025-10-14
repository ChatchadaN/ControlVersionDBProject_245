-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_get_user_identification]
	-- Add the parameters for the stored procedure here
	@emp_num NVARCHAR(10)

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
		,'EXEC [man].[sp_get_user_identification] @emp_num = '''+ @emp_num + ''''

	SELECT [id] AS [emp_id]
		,[emp_num] AS [emp_num]
		,[full_name] AS [name]
		,[english_name] AS [english_name]
	FROM [APCSProDB].[man].[users]
	WHERE [emp_num] = @emp_num

END
