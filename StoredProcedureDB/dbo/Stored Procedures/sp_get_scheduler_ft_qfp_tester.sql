-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_ft_qfp_tester]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--SELECT packget.FullName as Package
 --     ,device.Name as Device
 --     ,tester.Name as TesterName
	--  ,case 
	--	when flow.Name like 'A1%' then 'AUTO1'
	--	when flow.Name like 'A2%' then 'AUTO2'
	--	when flow.Name like 'A3%' then 'AUTO3'
	--	when flow.Name like 'A4%' then 'AUTO4'
 --     else flow.Name
	--  end as flow
 -- FROM [DBx].[BOM].[FTBom] as bom
 -- inner join [DBx].[BOM].[Package] as packget on packget.id = bom.PackageID
 -- inner join [DBx].[BOM].[FTDevice] as device on device.id = bom.FTDeviceID
 -- inner join [DBx].[BOM].[BomTesterType] as tester on tester.ID = bom.TesterTypeID
 -- inner join [DBx].[BOM].[BomTestFlow] as flow on flow.ID = bom.TestFlowID
	SELECT DISTINCT  
		bom.id
		,packget.FullName as Package
      ,device.Name as Device
      ,CASE WHEN testname.Name = 'ICT1801' THEN 'ICT1800' ELSE testname.Name END as TesterName
	  ,tester.TesterTypeID
	  
	  ,case 
		when flow.Name like 'A1%' then 'AUTO1'
		when flow.Name like 'A2%' then 'AUTO2'
		when flow.Name like 'A3%' then 'AUTO3'
		when flow.Name like 'A4%' then 'AUTO4'
		when flow.Name  = 'OS+A1' then 'OS+AUTO1'
		when flow.Name  = 'O/S' then 'OS'
      else 
	  flow.Name
	  end as flow
	  ,bom.TestFlowID
  FROM [DBx].[BOM].[FTBom] as bom
  inner join [DBx].[BOM].[Package] as packget on packget.id = bom.PackageID
  inner join [DBx].[BOM].[FTDevice] as device on device.id = bom.FTDeviceID
  inner join [DBx].[BOM].[BomTesterType] as tester on tester.TesterTypeID = bom.TesterTypeID
  inner join [DBx].[BOM].[BomTestFlow] as flow on flow.TestFlowID = bom.TestFlowID
  inner join [DBx].[BOM].[FTBomTestEquipment] as map on map.FTBomID = bom.ID
  INNER JOIN DBX.dbo.TesterType as testname on testname.ID = bom.TesterTypeID
  --where device.Name = 'bu92rt82A-m'
  

END
