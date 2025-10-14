
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_employee_002]
	-- Add the parameters for the stored procedure here
	@emp_code varchar(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	

		SELECT 	[employees].[id]
		, [employees].[display_name]
		, [employees].[emp_code]
		, [employees].[full_name_eng]
		, [employees].[full_name_th]
		, CASE 
			WHEN PATINDEX('%[A-Z]%', [emp_code]) = 1  THEN 
				CASE 
					WHEN SUBSTRING([emp_code], 1, 2) = 'IN' THEN CAST(CAST(SUBSTRING([emp_code], PATINDEX('%[A-Z]%', [emp_code]) + 2,LEN([emp_code])) AS INT) AS VARCHAR)
					ELSE 
						CASE 
							WHEN SUBSTRING([emp_code], PATINDEX('%[A-Z]%',[emp_code]) + 1,LEN([emp_code])) LIKE '%[A-Z]%' THEN [emp_code]
							ELSE CAST(CAST(SUBSTRING([emp_code], PATINDEX('%[A-Z]%', [emp_code]) + 1,LEN([emp_code])) AS INT) AS VARCHAR)
						END
				END
			WHEN PATINDEX('%-%', [emp_code]) > 0 THEN SUBSTRING([emp_code], PATINDEX('%-%', [emp_code]) + 1,LEN([emp_code]))
			ELSE CAST(CAST([emp_code] AS INT) AS VARCHAR)
			END OPNo  
    , [picture_data]
 	, [employees].[display_name] AS [shortname]
	, SUBSTRING ([employees].[display_name], 0, LEN([employees].[display_name])  - 2 ) AS [namelabel]
	, [employees].is_admin
	, organizations.division AS divisions
	, divisions.id AS division_id	
	, divisions.division_code		
	, organizations.department AS departments
	, departments.id				 AS department_id		
	, departments.department_code	 AS department_code		
	, organizations.section AS sections
	, sections.id			AS section_id			 
	, sections.section_code AS section_code			 
	, organizations.hq   AS headquarters_name
	, headquarters.id		AS  headquarter_id		 
	, headquarters.hq_code		AS  headquarter_code		 
	, factories.id  AS factory_id
	, factories.short_name   AS  factories_name
	, factories.factory_code 
	, factories.short_name  AS factories_shortname
	, [employees].emp_code  AS emp_card
	, [employees].[default_language] 
	, [employees].resign_date  AS resign_date
	, IIF([employees].resign_date < GETDATE() ,1,0) AS is_resign
	, [employees].working_date
	, [employees].email 
	FROM [DWH].[man].[employees]
	 INNER JOIN [DWH].man.employee_organizations ON employees.id = employee_organizations.emp_id
	 INNER JOIN [DWH].man.organizations on employee_organizations.organization_id = organizations.id AND organizations.is_active = 1
	 INNER JOIN [DWH].man.groups ON  [DWH].man.organizations.[group] = [DWH].man.groups.[name] AND groups.is_active = 1
	 INNER JOIN [DWH].man.factories 
	 ON [DWH].man.groups.factory_id = [DWH].man.factories.id AND factories.is_active = 1
	 INNER JOIN [DWH].man.[headquarters] 
	 ON [DWH].man.organizations.hq = [DWH].man.[headquarters].[name]  AND [headquarters].is_active = 1
	 LEFT JOIN [DWH].man.divisions 
	 ON [DWH].man.divisions.name = [DWH].man.organizations.division AND divisions.is_active = 1
	 LEFT JOIN [DWH].man.departments 
	 ON [DWH].man.departments.name = [DWH].man.organizations.department AND departments.is_active = 1
	 LEFT JOIN [DWH].man.sections 
	 ON [DWH].man.sections.name = [DWH].man.organizations.section AND sections.is_active = 1
     WHERE [employees].[emp_code] = @emp_code
END
