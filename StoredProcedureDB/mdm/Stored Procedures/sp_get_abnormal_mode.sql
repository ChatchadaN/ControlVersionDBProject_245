-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_abnormal_mode]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [abnormal_mode].[id]
	, [abnormal_mode].[name]
	, [abnormal_mode].[created_at]
	, [user2].[emp_num]					AS created_by
	, [abnormal_mode].[updated_at]
	, [user1].[emp_num]					AS updated_by 
FROM [APCSProDB].[trans].[abnormal_mode] 
LEFT JOIN [APCSProDB].[man].[users] AS user1 ON [abnormal_mode].[updated_by] = [user1].[id] 
LEFT JOIN [APCSProDB].[man].[users] AS user2 ON [abnormal_mode].[created_by] = [user2].[id] 
END
