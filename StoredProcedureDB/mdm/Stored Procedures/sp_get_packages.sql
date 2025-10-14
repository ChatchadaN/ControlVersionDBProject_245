

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_packages]
	-- Add the parameters for the stored procedure here
	@packagesid AS INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF (@packagesid = 0)
		BEGIN
			select id,name AS Packagesname FROM [APCSProDB].[method].[package_groups]
			WHERE (id LIKE '%' AND @packagesid = 0) OR (id = @packagesid AND @packagesid <> 0)
			ORDER BY id
		END
	ELSE IF (@packagesid <> 0 AND @packagesid > 0 )
		BEGIN
			select id,short_name,Package_group_id FROM [APCSProDB].[method].[packages] 
			where (Package_group_id LIKE '%' AND @packagesid = 0) OR (Package_group_id = @packagesid AND @packagesid <> 0)
			ORDER BY id
			--SELECT DISTINCT p.id , pg.Name AS Packagesname, p.short_name ,dn.name AS device_name ,p.Package_group_id
			--FROM [APCSProDB].[method].[packages] p
			--LEFT JOIN [APCSProDB].[method].[package_groups] pg ON p.package_group_id = pg.id
			--LEFT JOIN [APCSProDB].[method].[device_names] dn ON p.id = dn.package_id
			--WHERE (p.package_group_id LIKE '%' AND @packagesid = 0) OR (p.package_group_id = @packagesid AND @packagesid <> 0)
			--ORDER BY p.id;
	END
END
