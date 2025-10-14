-- =============================================
-- Author:		<Author,,Name>
-- Create date: <03/03/2021,,>
-- Description:	<MDM ORGANIZATION,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_organization_test]
	-- Add the parameters for the stored procedure here
	@table_name int = 0 --1 = division,2 = department,3 = section,4 = organization,5 = organization_list 
	--@division_id varchar(5) = '%',
	--@department_id varchar(5) = '%',
	--@section_id varchar(5) = '%',
	--@organization_id varchar(5) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	-- Start Check table name
	IF @table_name = 1
	BEGIN
		---division
		SELECT g.factory_id as factory_id
			,fac.name as factory_name
			,di.headquarter_id as headquarter_id
			,hq.name as headquarter_name
			,hq.short_name as headquarter_short_name
			,di.id as division_id
			,di.name as division_name
			,di.short_name as division_short_name
			,di.created_at as division_created_at
		FROM [DWH].[man].[divisions] as di with (NOLOCK)
			INNER JOIN [DWH].[man].[headquarters] as hq with (NOLOCK) on di.headquarter_id = hq.id
			INNER JOIN [DWH].[man].[groups] as g with (NOLOCK) on hq.group_id = g.id
			INNER JOIN [DWH].[man].[factories] as fac with (NOLOCK) on g.factory_id = fac.id
		--WHERE di.id like @division_id AND hq.name = 'LSI HQ' AND fac.name = 'RIST'
		--WHERE  di.id like @division_id AND hq.id = 1 AND fac.id = 1
		ORDER BY di.name
		---division
	END
	ELSE IF @table_name = 2
	BEGIN
		--department
		SELECT g.factory_id as factory_id
			,fac.name as factory_name
			,di.headquarter_id as headquarter_id
			,hq.name as headquarter_name
			,hq.short_name as headquarter_short_name
			,di.id as division_id
			,di.name as division_name
			,di.short_name as division_short_name
			,di.created_at as division_created_at
			,dept.id as department_id
			,dept.name as department_name
			,dept.short_name as department_short_name
			,dept.created_at as department_created_at
		FROM [DWH].[man].[departments] as dept with (NOLOCK)
			INNER JOIN [DWH].[man].[divisions] as di with (NOLOCK) on dept.division_id = di.id
			INNER JOIN [DWH].[man].[headquarters] as hq with (NOLOCK) on di.headquarter_id = hq.id
			INNER JOIN [DWH].[man].[groups] as g  with (NOLOCK) on hq.group_id = g.id
			INNER JOIN [DWH].[man].[factories] as fac with (NOLOCK) on g.factory_id = fac.id
		--WHERE dept.division_id like @division_id AND hq.id = 1 AND fac.id = 1
		--	and dept.id like @department_id
		ORDER BY dept.name
		--department
	END
	ELSE IF @table_name = 3
	BEGIN
		--section
		SELECT g.factory_id as factory_id
			,fac.name as factory_name
			,di.headquarter_id as headquarter_id
			,hq.name as headquarter_name
			,hq.short_name as headquarter_short_name
			,di.id as division_id
			,di.name as division_name
			,di.short_name as division_short_name
			,di.created_at as division_created_at
			,dept.id as department_id
			,dept.name as department_name
			,dept.short_name as department_short_name
			,dept.created_at as department_created_at
			,sec.id as section_id
			,sec.name as section_name
			,sec.short_name as section_short_name
			,sec.created_at as section_created_at
		FROM [DWH].[man].[sections] as sec with (NOLOCK)
			INNER JOIN [DWH].[man].[departments] as dept with (NOLOCK) on sec.department_id = dept.id
			INNER JOIN [DWH].[man].[divisions] as di with (NOLOCK) on dept.division_id = di.id
			INNER JOIN [DWH].[man].[headquarters] as hq with (NOLOCK) on di.headquarter_id = hq.id
			INNER JOIN [DWH].[man].[groups] as g  with (NOLOCK) on hq.group_id = g.id
			INNER JOIN [DWH].[man].[factories] as fac with (NOLOCK) on g.factory_id = fac.id
		--WHERE sec.department_id like @department_id  AND hq.id = 1 AND fac.id = 1
		--	and sec.id like @section_id
		ORDER BY sec.name
		--section
	END

	ELSE IF @table_name = 4
	BEGIN
			 --organizations
			SELECT organization_id, f.name , headquarter_name , division_name , department_name
			FROM (
			SELECT  [id] as organization_id
			--,users.id
			--,users.name as name
			,SUBSTRING([business_unit_code], 1,3) as factory_code
			--,f.name
			--,hq.id as headquarter_id
			,hq as headquarter_name
			--,org.division_id 
			,division as division_name
			--,org.department_id
			,department as department_name
			--,org.section_id
			,section as section_name
          FROM [DWH].[man].[organizations]
		  WHERE [id] is not null) AS TB
		  INNER JOIN [DWH].[man].[factories] f ON TB.factory_code = f.factory_bu_code
		  --inner join [DWH].[man].[factories] f on organizations.factory_name = f.factory_code

    --organizations
	END

	--ELSE IF @table_name = 4
	--BEGIN
	--	--organization
	--	SELECT org.id as organizatio_id
	--		--,users.id
	--		--,users.name as name
	--		,fac.name as factory_name
	--		--,hq.id as headquarter_id
	--		,hq.name as headquarter_name
	--		--,org.division_id 
	--		,di.name as division_name
	--		--,org.department_id
	--		,dept.name as department_name
	--		--,org.section_id
	--		,sec.name as section_name
	--	FROM [DWH].[man].[organizations] AS org with (NOLOCK)
	--		LEFT JOIN [DWH].[man].[headquarters] AS hq with (NOLOCK) ON hq.id = org.headquarter_id
	--		LEFT JOIN [DWH].[man].[factories] AS fac with (NOLOCK) ON fac.id = hq.factory_id
	--		LEFT JOIN [DWH].[man].[sections] AS sec with (NOLOCK) ON sec.id = org.section_id 
	--		LEFT JOIN [DWH].[man].[departments] AS dept with (NOLOCK) ON dept.id = sec.department_id 
	--			or dept.id = org.department_id 
	--		LEFT JOIN [DWH].[man].[divisions] AS di with (NOLOCK) ON di.id = dept.division_id 
	--			or di.id = org.division_id 
	--		--INNER JOIN [DWH].[man].[user_organizations] on org.id = user_organizations.organization_id
	--		--INNER JOIN [DWH].[man].[users] on user_organizations.user_id = users.id
	--	WHERE org.headquarter_id = 1 and org.id like @organization_id AND hq.name = 'LSI HQ' AND fac.name = 'RIST'
	--	--organization
	--END
	--ELSE IF @table_name = 5
	--BEGIN
	--	--organization_list
	--	SELECT org.id as organization_id
	--		,fac.name as factory_name
	--		,org.headquarter_id as headquarter_id
	--		,hq.name as headquarter_name
	--		,org.division_id as division_id
	--		,di.name as division_name
	--		,org.department_id as department_id
	--		,dept.name as department_name
	--		,org.section_id as section_id
	--		,sec.name as section_name
	--	FROM [DWH].[man].[organizations] AS org with (NOLOCK)
	--		LEFT JOIN [DWH].[man].[headquarters] AS hq with (NOLOCK) ON hq.id = org.headquarter_id
	--		LEFT JOIN [DWH].[man].[factories] AS fac with (NOLOCK) ON fac.id = hq.factory_id
	--		LEFT JOIN [DWH].[man].[sections] AS sec with (NOLOCK) ON sec.id = org.section_id 
	--		LEFT JOIN [DWH].[man].[departments] AS dept with (NOLOCK) ON dept.id = sec.department_id or dept.id = org.department_id 
	--		LEFT JOIN [DWH].[man].[divisions] AS di with (NOLOCK) ON di.id = dept.division_id or di.id = org.division_id
	--	WHERE org.headquarter_id = 1 AND hq.name = 'LSI HQ' AND fac.name = 'RIST'

	--	UNION

	--	SELECT '-1' as organization_id
	--		,fac.name as factory_name
	--		,di.headquarter_id as headquarter_id
	--		,hq.name as headquarter_name
	--		,di.id as division_id
	--		,di.name as division_name
	--		,NULL as department_id
	--		,'' as department_name
	--		,NULL as section_id
	--		,'' as section_name
	--	FROM [DWH].[man].[divisions] AS di with (NOLOCK) 
	--		LEFT JOIN [DWH].[man].[headquarters] AS hq with (NOLOCK) ON hq.id = di.headquarter_id
	--		LEFT JOIN [DWH].[man].[factories] AS fac with (NOLOCK) ON fac.id = hq.factory_id
	--		LEFT JOIN [DWH].[man].[organizations] AS org with (NOLOCK) ON di.id = org.division_id
	--	WHERE org.division_id is null and di.headquarter_id = 1 AND hq.name = 'LSI HQ' AND fac.name = 'RIST'

	--	UNION

	--	SELECT '-1' as organization_id
	--		,fac.name as factory_name
	--		,di.headquarter_id as headquarter_id
	--		,hq.name as headquarter_name
	--		,NULL as division_id
	--		,di.name as division_name
	--		,dept.id as department_id
	--		,dept.name as department_name
	--		,NULL as section_id
	--		,'' as section_name
	--	FROM [DWH].[man].[departments] AS dept with (NOLOCK) 
	--		LEFT JOIN [DWH].[man].[divisions] AS di with (NOLOCK) ON di.id = dept.division_id
	--		LEFT JOIN [DWH].[man].[headquarters] AS hq with (NOLOCK) ON hq.id = di.headquarter_id
	--		LEFT JOIN [DWH].[man].[factories] AS fac with (NOLOCK) ON fac.id = hq.factory_id
	--		LEFT JOIN [DWH].[man].[organizations] AS org with (NOLOCK) ON dept.id = org.department_id
	--	WHERE org.department_id is null and di.headquarter_id = 1 AND hq.name = 'LSI HQ' AND fac.name = 'RIST'

	--	UNION

	--	SELECT '-1' as organization_id
	--		,fac.name as factory_name
	--		,di.headquarter_id as headquarter_id
	--		,hq.name as headquarter_name
	--		,NULL as division_id
	--		,di.name  as division_name
	--		,NULL as department_id
	--		,dept.name  as department_name
	--		,sec.id as section_id
	--		,sec.name as section_name
	--	FROM APCSProDB.man.sections as sec with (NOLOCK) 
	--		LEFT JOIN [DWH].[man].[departments] AS dept with (NOLOCK) ON dept.id = sec.department_id 
	--		LEFT JOIN [DWH].[man].[divisions] AS di with (NOLOCK) ON di.id = dept.division_id
	--		LEFT JOIN [DWH].[man].[headquarters] AS hq with (NOLOCK) ON hq.id = di.headquarter_id
	--		LEFT JOIN [DWH].[man].[factories] AS fac with (NOLOCK) ON fac.id = hq.factory_id
	--		LEFT JOIN [DWH].[man].[organizations] AS org with (NOLOCK) ON sec.id = org.section_id
	--	WHERE org.section_id is null and di.headquarter_id = 1 AND hq.name = 'LSI HQ' AND fac.name = 'RIST'
	--	--organization_list
	--END
	-- End Check table name

END
