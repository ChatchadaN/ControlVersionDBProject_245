-- =============================================
-- Author:		<Author,,Name>
-- Create date: <03/03/2021,,>
-- Description:	<MDM ORGANIZATION,,>
-- =============================================
CREATE PROCEDURE [tg].[sp_get_organization_pc_request]
	-- Add the parameters for the stored procedure here
	 @table_name int = 0 --1 = department,2 = section
	,@department_id varchar(5) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	-- Start Check table name
	IF @table_name = 1
	BEGIN
		--department
		SELECT hq.factory_id AS factory_id
			,fac.name AS factory_name
			,di.headquarter_id AS headquarter_id
			,hq.name AS headquarter_name
			,hq.short_name AS headquarter_short_name
			,di.id AS division_id
			,di.name AS division_name
			,di.short_name AS division_short_name
			,di.created_at AS division_created_at
			,dept.id AS department_id
			,dept.name AS department_name
			,dept.short_name AS department_short_name
			,dept.created_at AS department_created_at
		FROM [APCSProDB].[man].[departments] AS dept with (NOLOCK)
			INNER JOIN [APCSProDB].[man].[divisions] AS di with (NOLOCK) on dept.division_id = di.id
			INNER JOIN [APCSProDB].[man].[headquarters] AS hq with (NOLOCK) on di.headquarter_id = hq.id
			INNER JOIN [APCSProDB].[man].[factories] AS fac with (NOLOCK) on hq.factory_id = fac.id
		WHERE hq.name = 'LSI HQ' AND fac.name = 'RIST'
		ORDER BY dept.name
		--department
	END
	ELSE IF @table_name = 2
	BEGIN
		--section
		SELECT hq.factory_id AS factory_id
			, fac.name AS factory_name
			, di.headquarter_id AS headquarter_id
			, hq.name AS headquarter_name
			, hq.short_name AS headquarter_short_name
			, di.id AS division_id
			, di.name AS division_name
			, di.short_name AS division_short_name
			, di.created_at AS division_created_at
			, dept.id AS department_id
			, dept.name AS department_name
			, dept.short_name AS department_short_name
			, dept.created_at AS department_created_at
			, sec.id AS section_id
			, sec.name AS section_name
			, sec.short_name AS section_short_name
			, sec.created_at AS section_created_at
		FROM [APCSProDB].[man].[sections] AS sec with (NOLOCK)
			INNER JOIN [APCSProDB].[man].[departments] AS dept with (NOLOCK) on sec.department_id = dept.id
			INNER JOIN [APCSProDB].[man].[divisions] AS di with (NOLOCK) on dept.division_id = di.id
			INNER JOIN [APCSProDB].[man].[headquarters] AS hq with (NOLOCK) on di.headquarter_id = hq.id
			INNER JOIN [APCSProDB].[man].[factories] AS fac with (NOLOCK) on hq.factory_id = fac.id
		WHERE dept.id like @department_id and hq.name = 'LSI HQ' AND fac.name = 'RIST'
			AND sec.id IN (72,99,15,16,17,73,94,93)
			/* Comment
				15 = F-3 (TP/LS) & FL SUPPORT,
				72 = F-6 (TP/LS) & FT SUPPORT,
				16 = F-4 (Shipping),
				73 = FT BANK & BACK PROCESS SUPPORT,
				17 = F-5 (MAP-X BACK PROC,
				99 = F-7(FL/FT/TP Process
			*/
		ORDER BY sec.name
		--section
	END
	-- End Check table name

END
