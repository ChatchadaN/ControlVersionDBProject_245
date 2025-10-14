-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_user_data]
	-- Add the parameters for the stored procedure here
	@emp_num varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	insert into [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		[record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text]
	  , [lot_no]
	)
	select 
		GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [man].[sp_get_user_data] @emp_num = '''+ @emp_num + ''''
		, '1'

	SELECT [users].[id]
		, [users].[name]
		, [users].[emp_num]
		--, [users].[full_name]
		--, [users].[picture_data]	
	FROM [APCSProDB].[man].[users]
    WHERE [users].[emp_num] = @emp_num

END
