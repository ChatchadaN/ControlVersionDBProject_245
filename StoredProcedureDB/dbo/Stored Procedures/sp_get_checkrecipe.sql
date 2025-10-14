-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_checkrecipe] 
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	SET NOCOUNT ON;

   SELECT  assy_name as ft_name,recipe,TBOIS.TestFlowName AS job_id,ProgramName AS ProgramOIS, TBOIS.Package1,device_slip_id
		,TBAPCSPRO.device_id,TBOIS.DeviceOIS,TBOIS.Flow AS FlowOIS,version_num,device,assy_name,job_id AS TestFlowId
		FROM (Select DISTINCT CASE WHEN value = '-' THEN DeviceName
		WHEN value <> '' THEN DeviceName + '-' + value
		END AS DeviceOIS, 
		CASE WHEN TRIM(TestFlowName) = 'AUTO(1)' AND ProcessName = 'FT' THEN  106
		WHEN TRIM(TestFlowName) = 'AUTO1' AND ProcessName = 'FT'  THEN  106
		WHEN TRIM(TestFlowName) = 'AUTO1' AND ProcessName = 'FL'  THEN  106
		WHEN TRIM(TestFlowName) = 'AUTO1' AND ProcessName = 'MAP'  THEN  106
		WHEN TRIM(TestFlowName) = 'AUTO1 INSPEC.' AND ProcessName = 'FT'  THEN  106
		WHEN TRIM(TestFlowName) = 'AUTO1 INSPEC.' AND ProcessName = 'FT'  THEN  106
		WHEN TRIM(TestFlowName) = 'AUTO2' AND ProcessName = 'FT'  THEN  108
		WHEN TRIM(TestFlowName) = 'AUTO2' AND ProcessName = 'MAP'  THEN  108
		WHEN TRIM(TestFlowName) = 'AUTO2 AFTER' AND ProcessName = 'FT'  THEN  371
		WHEN TRIM(TestFlowName) = 'AUTO2ASISAMPLE' AND ProcessName = 'FT'  THEN  342
		WHEN TRIM(TestFlowName) = 'AUTO3' AND ProcessName = 'FT'  THEN  110
		WHEN TRIM(TestFlowName) = 'AUTO3ASISAMPLE' AND ProcessName = 'FT'  THEN  370
		WHEN TRIM(TestFlowName) = 'AUTO4' AND ProcessName = 'FT'  THEN  119
		WHEN TRIM(TestFlowName) = 'AUTO5' AND ProcessName = 'FT'  THEN  263
		END AS Flow, ProgramName,Package1,TestFlowName
		FROM[DBx].[dbo].[OIS] CROSS APPLY STRING_SPLIT(InputRank, '/'))As TBOIS
		INNER JOIN
		(SELECT [device_flows].[recipe]
		, [device_slip_max].id AS device_id
		, [device_slip_max].[name] as [device]
		, [device_slip_max].[ft_name]
		, [device_slip_max].[assy_name]
		, [device_slips].[is_released]
		, [device_slips].[device_slip_id]
		, [device_versions].[version_num]
		, [device_flows].[job_id] AS job_id
		, CASE WHEN job_commons.id IS NOT NULL THEN
			job_commons.to_job_id 
			ELSE [device_flows].[job_id] END 
		  as [to_job_id]
		 ,CASE WHEN  TRIM(packages.short_name)  ='TO252' THEN 'TO252-3' 
		 ELSE packages.short_name END AS package
		 FROM (
		  SELECT [device_names].[id] as [id]
		  , [device_names].[name] as [name]
		  , [device_names].[ft_name] as [ft_name]
		  ,[device_names].assy_name
		  ,package_id
		  , MAX([device_slips].[version_num]) as [version_num]
		  FROM [APCSProDB].[method].[device_names] with (NOLOCK)
		  INNER JOIN [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_names].[id] = [device_versions].device_name_id
		  INNER JOIN [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		  WHERE [device_versions].[device_type] = 0 AND [device_slips].[is_released] = 1 
		  --AND device_flows.job_id <> 222
		  GROUP BY [device_names].[id],[device_names].[name],[device_names].[ft_name],[device_names].assy_name ,package_id
		   ) as [device_slip_max]

		INNER JOIN [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_slip_max].[id] = [device_versions].device_name_id 
			AND [device_versions].device_type = 0  
		INNER JOIN [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
			AND [device_slip_max].[version_num] = [device_slips].[version_num] AND [device_slips].[is_released] = 1
		INNER JOIN [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_slips].[device_slip_id] = [device_flows].[device_slip_id] AND [device_flows].[is_skipped] = 0
		LEFT JOIN APCSProDB.trans.job_commons with(NOLOCK) on job_commons.job_id = device_flows.job_id 
		INNER JOIN [APCSProDB].[method].[packages] with (NOLOCK) on packages.id = device_slip_max.package_id

		) As TBAPCSPRO ON TBOIS.DeviceOIS = TBAPCSPRO.ft_name AND TBOIS.Flow = TBAPCSPRO.to_job_id AND TBAPCSPRO.package = TBOIS.Package1

		--////////////// เช็ค Device และ Flow ที่มี 2 โปรแกรม
		INNER JOIN (SELECT * FROM (
		SELECT Package1,DeviceOIS,Flow,COUNT(ProgramName) AS countPro FROM (
		Select DISTINCT CASE WHEN value = '-' THEN DeviceName
		WHEN value <> '' THEN DeviceName + '-' + value
		END AS DeviceOIS, 
		CASE WHEN TRIM(TestFlowName) = 'AUTO(1)' AND ProcessName = 'FT'  THEN  106
		WHEN TRIM(TestFlowName) = 'AUTO1' AND ProcessName = 'FT'  THEN  106
		WHEN TRIM(TestFlowName) = 'AUTO1' AND ProcessName = 'FL'  THEN  106
		WHEN TRIM(TestFlowName) = 'AUTO1' AND ProcessName = 'MAP'  THEN  106
		WHEN TRIM(TestFlowName) = 'AUTO1 INSPEC.' AND ProcessName = 'FT'  THEN  106
		WHEN TRIM(TestFlowName) = 'AUTO1 INSPEC.' AND ProcessName = 'FT'  THEN  106
		WHEN TRIM(TestFlowName) = 'AUTO2' AND ProcessName = 'FT'  THEN  108
		WHEN TRIM(TestFlowName) = 'AUTO2' AND ProcessName = 'MAP'  THEN  108
		WHEN TRIM(TestFlowName) = 'AUTO2 AFTER' AND ProcessName = 'FT'  THEN  371
		WHEN TRIM(TestFlowName) = 'AUTO2ASISAMPLE' AND ProcessName = 'FT'  THEN  342
		WHEN TRIM(TestFlowName) = 'AUTO3' AND ProcessName = 'FT'  THEN  110
		WHEN TRIM(TestFlowName) = 'AUTO3ASISAMPLE' AND ProcessName = 'FT'  THEN  370
		WHEN TRIM(TestFlowName) = 'AUTO4' AND ProcessName = 'FT'  THEN  119
		WHEN TRIM(TestFlowName) = 'AUTO5' AND ProcessName = 'FT'  THEN  263
		END AS Flow, ProgramName,Package1

		FROM [DBx].[dbo].[OIS] CROSS APPLY STRING_SPLIT(InputRank, '/')) AS TB_OIS
		GROUP BY Package1,DeviceOIS,Flow) AS TB_OIS_Count
		WHERE countPro <= 1) AS OIS_Data ON OIS_Data.DeviceOIS = TBOIS.DeviceOIS AND OIS_Data.Flow = TBOIS.Flow AND OIS_Data.Package1 = TBOIS.Package1
		--///////////////////////////////////////////////////

		WHERE (recipe IS NULL OR recipe != ProgramName)  
		order by TBOIS.DeviceOIS
END
