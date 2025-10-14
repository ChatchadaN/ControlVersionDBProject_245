-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_package_groups]
	-- Add the parameters for the stored procedure here
	@value varchar(50) ='',
	@searchBy varchar(50)=''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@searchBy = 'lot_no')
		BEGIN
			SELECT DISTINCT PKG.id as pkg_id , PKG.name as pkg_name
			FROM APCSProDB.method.device_names as DVName
			INNER JOIN APCSProDB.trans.lots as lots on lots.act_device_name_id = DVName.id
			INNER JOIN APCSProDB.method.package_groups as PKG on PKG.id = DVName.alias_package_group_id
			Where lots.lot_no = @value
		END
	ELSE IF(@searchBy = 'lot_id')
		BEGIN
			SELECT DISTINCT PKG.id as pkg_id , PKG.name as pkg_name
			FROM APCSProDB.method.device_names as DVName
			INNER JOIN APCSProDB.trans.lots as lots on lots.act_device_name_id = DVName.id
			INNER JOIN APCSProDB.method.package_groups as PKG on PKG.id = DVName.alias_package_group_id
			Where lots.id = @value
		END
	ELSE IF(@searchBy = 'device_name')
		BEGIN
			SELECT DISTINCT PKG.id as pkg_id, PKG.name as pkg_name
			FROM APCSProDB.method.device_names as DVName
			INNER JOIN APCSProDB.method.package_groups as PKG on PKG.id = DVName.alias_package_group_id
			Where DVName.name = @value
		END
	ELSE IF(@searchBy = 'assy_name')
		BEGIN
			SELECT DISTINCT PKG.id as pkg_id, PKG.name as pkg_name
			FROM APCSProDB.method.device_names as DVName
			INNER JOIN APCSProDB.method.package_groups as PKG on PKG.id = DVName.alias_package_group_id
			Where DVName.assy_name = @value
		END
	ELSE IF(@searchBy = 'ft_name')
		BEGIN
			SELECT DISTINCT PKG.id as pkg_id, PKG.name as pkg_name
			FROM APCSProDB.method.device_names as DVName
			INNER JOIN APCSProDB.method.package_groups as PKG on PKG.id = DVName.alias_package_group_id
			Where DVName.ft_name = @value
		END
	ELSE 
		BEGIN
			SELECT 'parameter searchBy is Wrong (lot_no,lot_id,device_name,assy_name,ft_name)' as ErrorMgs
		END
END
