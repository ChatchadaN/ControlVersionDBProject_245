-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [req].[sp_get_user_identification_test]
	-- Add the parameters for the stored procedure here
	@emp_num NVARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [users].[id]
		, [users].[emp_num]
		, [users].[name]
		--, [users].[full_name]
		, [users].[is_permission]
		--, [users].[division]
		, [users].[department]
		--, [users].[section]
		,[inchanges].[category_id] 
	FROM [APCSProDWR].[req].[users]
	left join [APCSProDWR].[req].[inchanges] on [users].[id] = [inchanges].[inchange_by]
	left join [APCSProDWR].[req].[categories] on [inchanges].[category_id] = [categories].[id]
    WHERE [users].[emp_num] = @emp_num and [categories].[is_enable] = 1;
END
