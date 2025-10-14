-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_packagegroup]
	-- Add the parameters for the stored procedure here
	
	@lotno varchar(30) 
AS
BEGIN
	IF((select COUNT(lots.lot_no) 
		from APCSProDB.trans.lots as lots
		INNer Join [APCSProDB] .[method].device_names on lots.act_device_name_id = [APCSProDB] .[method].device_names.id 
		inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
		where lot_no = @lotno) > 0)
		BEGIN
			--select	'true' as [is_gdic]
			select DISTINCT lots.id ,lots.lot_no,pk.name as Package ,pkg.name as PackageGroup
			from APCSProDB.trans.lots as lots
			INNer Join [APCSProDB] .[method].device_names on lots.act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.packages as pk on lots.act_package_id = pk.id
			inner join [APCSProDB].method.package_groups as pkg on pk.package_group_id = pkg.id
			where lots.lot_no = @lotno
		END
	ELSE
		BEGIN
			--select	'false' as [is_gdic]
			select DISTINCT lots.id ,lots.lot_no,pk.name as Package
			,case when pkg.id = 33 THEN 'non-GDIC'
			ELSE pkg.name
			END as [PackageGroup] 
			--,pkg.name
			from APCSProDB.trans.lots as lots
			INNer Join [APCSProDB] .[method].device_names on lots.act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.packages as pk on lots.act_package_id = pk.id
			inner join [APCSProDB].method.package_groups as pkg on pk.package_group_id = pkg.id
			where lots.lot_no = @lotno
		END
END
