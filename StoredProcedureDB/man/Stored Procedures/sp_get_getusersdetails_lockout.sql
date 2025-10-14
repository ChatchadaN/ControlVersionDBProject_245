
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [man].[sp_get_getusersdetails_lockout]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	--SELECT	  users.id,[full_name]
	--		, [english_name]
	--		, [emp_num]
	--		, factories.name		as Factory
	--		, divisions.name		as Division
	--		, departments.name		as Department
	--		, sections.name			as Section
	--		, mail_address			as Email 
	--FROM [APCSProDB].[man].[users]
	-- LEFT JOIN  APCSProDB.man.user_organizations 
	-- ON users.id = user_organizations.user_id
	-- LEFT JOIN  APCSProDB.man.organizations 
	-- ON user_organizations.organization_id = organizations.id
	-- LEFT JOIN  APCSProDB.man.headquarters 
	-- ON organizations.headquarter_id = headquarters.id
	-- LEFT JOIN  APCSProDB.man.sections 
	-- ON organizations.section_id = sections.id
	-- LEFT JOIN  APCSProDB.man.departments 
	-- ON sections.department_id = departments.id OR organizations.department_id = departments.id
	-- LEFT JOIN APCSProDB.man.divisions 
	-- ON departments.division_id = divisions.id OR organizations.division_id = divisions.id
	-- LEFT JOIN APCSProDB.man.factories 
	-- ON headquarters.factory_id = factories.id
	-- WHERE  headquarters.name IS NULL 
	-- AND (factories.factory_code = 64646 OR  factories.name IS NULL) 
	-- AND users.lockout = 0 

	 SELECT users.id
			,[full_name]
			,[english_name]
			,[emp_num]
			,factories.name			as Factory
			,divisions.name			as Division
			,departments.name		as Department
			,sections.name			as Section
			,mail_address			as Email 
	FROM [APCSProDB].[man].[users]
	 LEFT JOIN [APCSProDB].man.user_organizations 
	 ON users.id = user_organizations.user_id
	 LEFT JOIN  [APCSProDB].man.organizations 
	 ON user_organizations.organization_id = organizations.id
	 LEFT JOIN  [APCSProDB].man.headquarters 
	 ON organizations.headquarter_id = headquarters.id
	 LEFT JOIN [APCSProDB].man.sections 
	 ON organizations.section_id = sections.id
	 LEFT JOIN [APCSProDB].man.departments 
	 ON sections.department_id = departments.id OR organizations.department_id = departments.id
	 LEFT JOIN [APCSProDB].man.divisions 
	 ON departments.division_id = divisions.id OR organizations.division_id = divisions.id
	 LEFT JOIN [APCSProDB].man.factories 
	 ON headquarters.factory_id = factories.id
	 WHERE(headquarters.name = 'LSI HQ' OR headquarters.name IS NULL) AND
	 (factories.name = 'RIST' OR  factories.name IS NULL) AND
	 users.lockout = 1

END
