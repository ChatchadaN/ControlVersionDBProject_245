-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_user_organization]
	-- Add the parameters for the stored procedure here
	@OPNo varchar(10) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	SELECT id, CASE WHEN DIV1 IS NULL THEN RIGHT(DIV2,2) ELSE RIGHT(DIV1,2) END AS DivName, name
	FROM (
		SELECT TOP (1) [APCSProDB].man.users.id
		--, [APCSProDB].man.organizations.*
		,sections.department_id
		,CASE WHEN sections.department_id IS NOT NULL THEN (SELECT divisions.short_name FROM [APCSProDB].man.departments INNER JOIN [APCSProDB].man.divisions ON divisions.id = departments.division_id WHERE departments.id = sections.department_id) END AS DIV1
		,departments.division_id
		,CASE WHEN departments.division_id IS NOT NULL THEN (SELECT divisions.short_name FROM [APCSProDB].man.divisions WHERE id = departments.division_id) END AS DIV2
		--,[APCSProDB].man.departments.*
		--, RIGHT([APCSProDB].man.divisions.short_name,2) AS DivName 
		,sections.name
		FROM [APCSProDB].man.users 
		INNER JOIN [APCSProDB].man.user_organizations ON [APCSProDB].man.users.id = [APCSProDB].man.user_organizations.user_id 
		INNER JOIN [APCSProDB].man.organizations ON [APCSProDB].man.user_organizations.organization_id = [APCSProDB].man.organizations.id 

		LEFT JOIN [APCSProDB].man.sections ON [APCSProDB].man.organizations.section_id = [APCSProDB].man.sections.id 
		LEFT JOIN [APCSProDB].man.departments ON [APCSProDB].man.organizations.department_id = [APCSProDB].man.departments.id 
		LEFT JOIN [APCSProDB].man.divisions ON [APCSProDB].man.organizations.division_id = [APCSProDB].man.divisions.id 
		WHERE [APCSProDB].man.users.emp_num = @OPNo
	) AS A
END
