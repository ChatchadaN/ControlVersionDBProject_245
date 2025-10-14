-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [req].[sp_get_user_identification]
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
	LEFT JOIN [APCSProDWR].[req].[inchanges] on [users].[id] = [inchanges].[inchange_by]
		AND [inchanges].[is_defult] = 1
    WHERE [users].[emp_num] = @emp_num
	--ORDER BY  --add condition 2025/01/29 Time : 00.06 by Aomsin
	--	CASE 
	--		WHEN is_defult = 1 THEN 0 ELSE 1 
	--	END,
	--	[inchanges].[category_id] ASC

END