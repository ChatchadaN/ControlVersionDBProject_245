-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_pkgndev]
	-- Add the parameters for the stored procedure here
	@PkgName varchar(20)--, @DevName varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	If(@PkgName = '%')
	BEGIN
		SELECT packages.name AS PackageName
		     , packages.id AS PackageId
			 , N'Please select Package' AS DeviceName
			 , '0' AS DeviceId
		FROM APCSProDB.method.packages
		WHERE packages.name like @PkgName
		ORDER BY packages.name
	END
	Else
	BEGIN
		SELECT dev.name AS DeviceName
		     , STRING_AGG(dev.id, ',') AS DeviceId
			 , pkg.name AS PackageName
			 , pkg.id AS PackageId
		FROM APCSProDB.method.device_names AS dev
		JOIN APCSProDB.method.packages AS pkg ON dev.package_id = pkg.id
		WHERE pkg.name like @PkgName --AND dev.name NOT LIKE '-FX%' --AND dev.name like @DevName
		GROUP BY dev.name, pkg.name, pkg.id
		ORDER BY dev.name
	END
END
