------------------------------ Creater Rule ------------------------------
-- Project Name				: MDM
-- Author Name              : Chatchadaporn N
-- Written Date             : 2023/11/17
-- Procedure Name 	 		: [mdm].[sp_get_chart_totalDivision]
-- Filename					: mdm.sp_get_chart_totalDivision
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: method.device_slips
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [mdm].[sp_get_chart_totalDivision]	 
					
AS
BEGIN
	 
	--SET NOCOUNT ON;	
	SET NOCOUNT ON;	

	SELECT 'LSI-PD' AS Name, COUNT(users.id) AS Value
	FROM [APCSProDB].[man].[users]
		INNER JOIN [APCSProDB].man.user_organizations ON users.id = user_organizations.user_id
		LEFT JOIN [APCSProDB].man.organizations ON user_organizations.organization_id = organizations.id
		LEFT JOIN [APCSProDB].man.headquarters ON organizations.headquarter_id = headquarters.id
		LEFT JOIN [APCSProDB].man.sections ON organizations.section_id = sections.id
		LEFT JOIN [APCSProDB].man.departments ON sections.department_id = departments.id OR organizations.department_id = departments.id
		LEFT JOIN [APCSProDB].man.divisions ON departments.division_id = divisions.id OR organizations.division_id = divisions.id
		LEFT JOIN [APCSProDB].man.factories ON headquarters.factory_id = factories.id
	WHERE (headquarters.name = 'LSI HQ' OR headquarters.name IS NULL) AND
	      (factories.name = 'RIST' OR factories.name IS NULL) AND
	      (divisions.id = 1 AND departments.id NOT IN (17,14,15)) AND
	      users.lockout = 0
	
	UNION ALL
	
	SELECT 'LSI-PM' AS Name, COUNT(users.id) AS Value
	FROM [APCSProDB].[man].[users]
		INNER JOIN [APCSProDB].man.user_organizations ON users.id = user_organizations.user_id
		LEFT JOIN [APCSProDB].man.organizations ON user_organizations.organization_id = organizations.id
		LEFT JOIN [APCSProDB].man.headquarters ON organizations.headquarter_id = headquarters.id
		LEFT JOIN [APCSProDB].man.sections ON organizations.section_id = sections.id
		LEFT JOIN [APCSProDB].man.departments ON sections.department_id = departments.id OR organizations.department_id = departments.id
		LEFT JOIN [APCSProDB].man.divisions ON departments.division_id = divisions.id OR organizations.division_id = divisions.id
		LEFT JOIN [APCSProDB].man.factories ON headquarters.factory_id = factories.id
	WHERE (headquarters.name = 'LSI HQ' OR headquarters.name IS NULL) AND
	      (factories.name = 'RIST' OR factories.name IS NULL) AND
	      (divisions.id = 2) AND
	      users.lockout = 0
	
	UNION ALL
	
	SELECT 'LSI-PE' AS Name,  COUNT(users.id) as Value
	FROM [APCSProDB].[man].[users]
		INNER JOIN [APCSProDB].man.user_organizations ON users.id = user_organizations.user_id
		LEFT JOIN  [APCSProDB].man.organizations ON user_organizations.organization_id = organizations.id
		LEFT JOIN  [APCSProDB].man.headquarters ON organizations.headquarter_id = headquarters.id
		LEFT JOIN [APCSProDB].man.sections ON organizations.section_id = sections.id
		LEFT JOIN [APCSProDB].man.departments ON sections.department_id = departments.id OR organizations.department_id = departments.id
		LEFT JOIN [APCSProDB].man.divisions ON departments.division_id = divisions.id OR organizations.division_id = divisions.id
		LEFT JOIN [APCSProDB].man.factories ON headquarters.factory_id = factories.id
	WHERE(headquarters.name = 'LSI HQ' OR headquarters.name IS NULL) AND
	(factories.name = 'RIST' OR  factories.name IS NULL) AND
	(divisions.id = 3) AND
	users.lockout = 0
	
	UNION ALL
	
	SELECT 'LSI-QC' AS Name, COUNT(users.id) as Value
	FROM [APCSProDB].[man].[users]
		INNER JOIN [APCSProDB].man.user_organizations ON users.id = user_organizations.user_id
		LEFT JOIN  [APCSProDB].man.organizations ON user_organizations.organization_id = organizations.id
		LEFT JOIN  [APCSProDB].man.headquarters ON organizations.headquarter_id = headquarters.id
		LEFT JOIN [APCSProDB].man.sections ON organizations.section_id = sections.id
		LEFT JOIN [APCSProDB].man.departments ON sections.department_id = departments.id OR organizations.department_id = departments.id
		LEFT JOIN [APCSProDB].man.divisions ON departments.division_id = divisions.id OR organizations.division_id = divisions.id
		LEFT JOIN [APCSProDB].man.factories ON headquarters.factory_id = factories.id
	WHERE(headquarters.name = 'LSI HQ' OR headquarters.name IS NULL) AND
	(factories.name = 'RIST' OR  factories.name IS NULL) AND
	(departments.id in (17,30) OR divisions.id = 14) AND
	users.lockout = 0
	
	UNION ALL
	
	SELECT 'LSI-PC' AS Name, COUNT(users.id) as Value
	FROM [APCSProDB].[man].[users]
		INNER JOIN [APCSProDB].man.user_organizations ON users.id = user_organizations.user_id
		LEFT JOIN  [APCSProDB].man.organizations ON user_organizations.organization_id = organizations.id
		LEFT JOIN  [APCSProDB].man.headquarters ON organizations.headquarter_id = headquarters.id
		LEFT JOIN [APCSProDB].man.sections ON organizations.section_id = sections.id
		LEFT JOIN [APCSProDB].man.departments ON sections.department_id = departments.id OR organizations.department_id = departments.id
		LEFT JOIN [APCSProDB].man.divisions ON departments.division_id = divisions.id OR organizations.division_id = divisions.id
		LEFT JOIN [APCSProDB].man.factories ON headquarters.factory_id = factories.id
	WHERE(headquarters.name = 'LSI HQ' OR headquarters.name IS NULL) AND
	(factories.name = 'RIST' OR  factories.name IS NULL) AND
	(departments.id in (14,15,28) OR divisions.id = 9) AND
	users.lockout = 0

END
