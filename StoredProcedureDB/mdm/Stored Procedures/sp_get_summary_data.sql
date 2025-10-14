------------------------------ Creater Rule ------------------------------
-- Project Name				: MDM
-- Author Name              : Chatchadaporn N
-- Written Date             : 2023/11/15
-- Procedure Name 	 		: [mdm].[sp_get_summary_data]
-- Filename					: mdm.sp_get_summary_data
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: method.device_slips
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [mdm].[sp_get_summary_data]	 
	@filter			int
	--	1: users_total 2: users_online	3: machine_total 4: machine_online
	--  5: PKG 6: Package 7: Device
					
AS
BEGIN
	 
	--SET NOCOUNT ON;	
	SET NOCOUNT ON;	

	IF(@filter = 1)
	BEGIN
		SELECT  COUNT([users].id) as total
		FROM [APCSProDB].[man].[users]
			INNER JOIN [APCSProDB].man.user_organizations ON users.id = user_organizations.user_id
			LEFT JOIN  [APCSProDB].man.organizations ON user_organizations.organization_id = organizations.id
			LEFT JOIN  [APCSProDB].man.headquarters ON organizations.headquarter_id = headquarters.id
			LEFT JOIN [APCSProDB].man.sections ON organizations.section_id = sections.id
			LEFT JOIN [APCSProDB].man.departments ON sections.department_id = departments.id OR organizations.department_id = departments.id
			LEFT JOIN [APCSProDB].man.divisions ON departments.division_id = divisions.id OR organizations.division_id = divisions.id
			LEFT JOIN [APCSProDB].man.factories ON headquarters.factory_id = factories.id
		WHERE(headquarters.name = 'LSI HQ' OR headquarters.name IS NULL) AND
		(factories.name = 'RIST' OR  factories.name IS NULL)
	END
	ELSE IF(@filter = 2)
	BEGIN
		SELECT  COUNT([users].id) as total
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
		users.lockout = 0
	END
	ELSE IF(@filter = 3)
	BEGIN
		SELECT count(id) as total FROM APCSProDB.mc.machines
	END
	ELSE IF(@filter = 4)
	BEGIN
		SELECT count(id) as total FROM APCSProDB.mc.machines
		WHERE is_disabled = 0
	END
	ELSE IF(@filter = 5)
	BEGIN
		SELECT COUNT(id) as total FROM APCSProDB.method.package_groups
	END
	ELSE IF(@filter = 6)
	BEGIN
		SELECT COUNT(id) as total FROM APCSProDB.method.packages
		WHERE is_enabled = 1
	END
	ELSE IF(@filter = 7)
	BEGIN
		SELECT COUNT(id) as total FROM APCSProDB.method.device_names
	END
END
