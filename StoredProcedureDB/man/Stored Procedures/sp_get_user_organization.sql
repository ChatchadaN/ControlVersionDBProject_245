-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [man].[sp_get_user_organization]
	-- Add the parameters for the stored procedure here
	@emp_num VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	 SELECT [users].[id]
		, [emp_num]
		, [full_name]
		, [english_name]
		, [factories].[id] AS [FactoryID]
		, [factories].[name] AS [Factory]
		, [divisions].[id] AS [DivisionID]
		, [divisions].[name] AS [Division]
		, [departments].[id] AS [DepartmentID]
		, [departments].[name] AS [Department]
		, [sections].[id] AS [SectionID]
		, [sections].[name] AS [Section]
	FROM [APCSProDB].[man].[users]
	LEFT JOIN [APCSProDB].[man].[user_organizations] ON [users].[id] = [user_organizations].[user_id]
	LEFT JOIN [APCSProDB].[man].[organizations] ON [user_organizations].[organization_id] = [organizations].[id]
	LEFT JOIN [APCSProDB].[man].[headquarters] ON [organizations].[headquarter_id] = [headquarters].[id]
	LEFT JOIN [APCSProDB].[man].[factories] ON [headquarters].[factory_id] = [factories].[id]
	LEFT JOIN [APCSProDB].[man].[sections] ON [organizations].[section_id] = [sections].[id]
	LEFT JOIN [APCSProDB].[man].[departments] ON ([sections].[department_id] = [departments].[id] OR [organizations].[department_id] = [departments].[id])
	LEFT JOIN [APCSProDB].[man].[divisions] ON ([departments].[division_id] = [divisions].[id] OR [organizations].[division_id] = [divisions].[id])
	WHERE [users].[emp_num] = @emp_num;
END
