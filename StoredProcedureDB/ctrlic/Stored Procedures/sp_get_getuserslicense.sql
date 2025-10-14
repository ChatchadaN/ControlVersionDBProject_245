-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_get_getuserslicense]
	-- Add the parameters for the stored procedure here
	@state INT --0 = have license ,1 = not have license
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN
	 IF(@state = 0)
	 BEGIN
	 SELECT users.id
			,[users].[emp_num] 
			,users.full_name
			,users.english_name
			,divisions.name			as Division
			,departments.name		as Department
			,sections.name			as Section
			FROM [APCSProDB].[man].[users]
			LEFT JOIN [APCSProDB].[ctrlic].[user_lic] 
			ON [users].[id] = [user_lic].[user_id]
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
			users.lockout = 0 AND [user_lic].user_id IS NOT NULL
			group by users.id,[users].[emp_num],users.full_name,users.english_name,divisions.name,departments.name	,sections.name
			order by users.id
	 END
	 ELSE IF(@state = 1)
	 BEGIN
	 SELECT users.id
			,[users].[emp_num] 
			,users.full_name
			,users.english_name
			,divisions.name			as Division
			,departments.name		as Department
			,sections.name			as Section
			FROM [APCSProDB].[man].[users]
			LEFT JOIN [APCSProDB].[ctrlic].[user_lic] 
			ON [users].[id] = [user_lic].[user_id]
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
				 users.lockout = 0 AND [user_lic].user_id IS NULL
			group by users.id,[users].[emp_num],users.full_name,users.english_name,divisions.name,departments.name	,sections.name
			order by users.id
	 END
	END
		
END
