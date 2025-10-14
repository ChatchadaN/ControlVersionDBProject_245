-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_recipe_by_bass] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	SET NOCOUNT ON;

	--SELECT [TBAPCSPRO].[assy_name] AS [ft_name]
	--	, [TBAPCSPRO].[recipe]
	--	, [TBOIS].[TestFlowName] AS [job_id]
	--	, [TBOIS].[ProgramName] AS [ProgramOIS]
	--	, [TBOIS].[Package1]
	--	, [TBAPCSPRO].[device_slip_id]
	--	, [TBAPCSPRO].[device_id]
	--	, [TBOIS].[DeviceOIS]
	--	, [TBOIS].[Flow] AS [FlowOIS]
	--	, [TBAPCSPRO].[version_num]
	--	, [TBAPCSPRO].[device]
	--	, [TBAPCSPRO].[assy_name]
	--	, [TBAPCSPRO].[job_id] AS [TestFlowId]
	--FROM (
	--	SELECT DISTINCT 
	--		CASE 
	--			WHEN value = '-' THEN [DeviceName]
	--			WHEN value <> '' THEN [DeviceName] + '-' + value
	--		END AS [DeviceOIS]
	--		, CASE 
	--			WHEN TRIM([TestFlowName]) = 'AUTO(1)' AND [ProcessName] = 'FT' THEN  106
	--			WHEN TRIM([TestFlowName]) = 'AUTO1' AND [ProcessName] = 'FT'  THEN  106
	--			WHEN TRIM([TestFlowName]) = 'AUTO1' AND [ProcessName] = 'FL'  THEN  106
	--			WHEN TRIM([TestFlowName]) = 'AUTO1' AND [ProcessName] = 'MAP'  THEN  106
	--			WHEN TRIM([TestFlowName]) = 'AUTO1 INSPEC.' AND [ProcessName] = 'FT'  THEN  106
	--			WHEN TRIM([TestFlowName]) = 'AUTO1 INSPEC.' AND [ProcessName] = 'FT'  THEN  106
	--			WHEN TRIM([TestFlowName]) = 'AUTO2' AND [ProcessName] = 'FT'  THEN  108
	--			WHEN TRIM([TestFlowName]) = 'AUTO2' AND [ProcessName] = 'MAP'  THEN  108
	--			WHEN TRIM([TestFlowName]) = 'AUTO2 AFTER' AND [ProcessName] = 'FT'  THEN  371
	--			WHEN TRIM([TestFlowName]) = 'AUTO2ASISAMPLE' AND [ProcessName] = 'FT'  THEN  342
	--			WHEN TRIM([TestFlowName]) = 'AUTO3' AND [ProcessName] = 'FT'  THEN  110
	--			WHEN TRIM([TestFlowName]) = 'AUTO3ASISAMPLE' AND [ProcessName] = 'FT'  THEN  370
	--			WHEN TRIM([TestFlowName]) = 'AUTO4' AND [ProcessName] = 'FT'  THEN  119
	--			WHEN TRIM([TestFlowName]) = 'AUTO5' AND [ProcessName] = 'FT'  THEN  263
	--		END AS [Flow]
	--		, [ProgramName]
	--		, [Package1]
	--		, [TestFlowName]
	--	FROM [DBx].[dbo].[OIS] WITH (NOLOCK)
	--	CROSS APPLY STRING_SPLIT([InputRank], '/')
	--) AS [TBOIS]
	--INNER JOIN (
	--	SELECT [device_flows].[recipe]
	--		, [device_slip_max].[id] AS [device_id]
	--		, [device_slip_max].[name] AS [device]
	--		, [device_slip_max].[ft_name]
	--		, [device_slip_max].[assy_name]
	--		, [device_slip_max].[is_released]
	--		, [device_slip_max].[device_slip_id]
	--		, [device_slip_max].[version_num]
	--		, [device_flows].[job_id] AS [job_id]
	--		, CASE 
	--			WHEN [job_commons].[id] IS NOT NULL THEN [job_commons].[to_job_id]
	--			ELSE [device_flows].[job_id] 
	--		END AS [to_job_id]
	--		, CASE 
	--			WHEN TRIM([device_slip_max].short_name) = 'TO252' THEN 'TO252-3' 
	--			ELSE [device_slip_max].short_name 
	--		END AS [package]
	--		--, [device_slip_max].[short_name] AS [package]
	--	FROM (
	--		SELECT [device_names].[id] AS [id]
	--			, [device_names].[name] AS [name]
	--			, [device_names].[ft_name] AS [ft_name]
	--			, [device_names].[assy_name]
	--			, [device_names].[package_id]
	--			, [device_slips].[version_num]
	--			, [device_slips].[is_released]
	--			, [device_slips].[device_slip_id]
	--			, [packages].[short_name]
	--			, ROW_NUMBER() OVER (PARTITION BY [device_names].[id], [device_names].[name], [device_names].[ft_name], [device_names].[assy_name], [device_names].[package_id] ORDER BY [device_slips].[version_num] DESC) AS [rows]
	--		FROM [APCSProDB].[method].[device_names] WITH (NOLOCK)
	--		INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
	--			AND [device_versions].[device_type] = 0 
	--		INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
	--			AND [device_slips].[is_released] = 1
	--		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
	--	) AS [device_slip_max]
	--	INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_slip_max].[device_slip_id] = [device_flows].[device_slip_id]
	--	LEFT JOIN [APCSProDB].[trans].[job_commons] WITH(NOLOCK) ON [job_commons].[job_id] = [device_flows].[job_id]
	--		AND [device_flows].[job_id] != 222
	--	WHERE [device_slip_max].[rows] = 1
	--) As [TBAPCSPRO] ON [TBOIS].[DeviceOIS] = [TBAPCSPRO].[ft_name]
	--	AND [TBOIS].[Flow] = [TBAPCSPRO].[to_job_id] 
	--	AND [TBAPCSPRO].[package] = [TBOIS].[Package1]
	----- <<< เช็ค Device และ Flow ที่มี 2 โปรแกรม ----------
	--INNER JOIN (
	--	SELECT [Package1]
	--		, [DeviceOIS]
	--		, [Flow]
	--		, [countPro]
	--	FROM (
	--		SELECT [Package1]
	--			, [DeviceOIS]
	--			, [Flow]
	--			, COUNT([ProgramName]) AS [countPro]
	--		FROM (
	--			SELECT DISTINCT 
	--				CASE 
	--					WHEN value = '-' THEN [DeviceName]
	--					WHEN value <> '' THEN [DeviceName] + '-' + value
	--				END AS [DeviceOIS]
	--				, CASE 
	--					WHEN TRIM([TestFlowName]) = 'AUTO(1)' AND [ProcessName] = 'FT'  THEN  106
	--					WHEN TRIM([TestFlowName]) = 'AUTO1' AND [ProcessName] = 'FT'  THEN  106
	--					WHEN TRIM([TestFlowName]) = 'AUTO1' AND [ProcessName] = 'FL'  THEN  106
	--					WHEN TRIM([TestFlowName]) = 'AUTO1' AND [ProcessName] = 'MAP'  THEN  106
	--					WHEN TRIM([TestFlowName]) = 'AUTO1 INSPEC.' AND [ProcessName] = 'FT'  THEN  106
	--					WHEN TRIM([TestFlowName]) = 'AUTO1 INSPEC.' AND [ProcessName] = 'FT'  THEN  106
	--					WHEN TRIM([TestFlowName]) = 'AUTO2' AND [ProcessName] = 'FT'  THEN  108
	--					WHEN TRIM([TestFlowName]) = 'AUTO2' AND [ProcessName] = 'MAP'  THEN  108
	--					WHEN TRIM([TestFlowName]) = 'AUTO2 AFTER' AND [ProcessName] = 'FT'  THEN  371
	--					WHEN TRIM([TestFlowName]) = 'AUTO2ASISAMPLE' AND [ProcessName] = 'FT'  THEN  342
	--					WHEN TRIM([TestFlowName]) = 'AUTO3' AND [ProcessName] = 'FT'  THEN  110
	--					WHEN TRIM([TestFlowName]) = 'AUTO3ASISAMPLE' AND [ProcessName] = 'FT'  THEN  370
	--					WHEN TRIM([TestFlowName]) = 'AUTO4' AND [ProcessName] = 'FT'  THEN  119
	--					WHEN TRIM([TestFlowName]) = 'AUTO5' AND [ProcessName] = 'FT'  THEN  263
	--				END AS [Flow]
	--				, [ProgramName]
	--				, [Package1]
	--			FROM [DBx].[dbo].[OIS] WITH (NOLOCK) 
	--			CROSS APPLY STRING_SPLIT([InputRank], '/')
	--		) AS [TB_OIS]
	--		GROUP BY [Package1], [DeviceOIS], [Flow]
	--	) AS [TB_OIS_Count]
	--	WHERE [TB_OIS_Count].[countPro] <= 1
	--) AS [OIS_Data] ON [OIS_Data].[DeviceOIS] = [TBOIS].[DeviceOIS]
	--	AND [OIS_Data].[Flow] = [TBOIS].[Flow] 
	--	AND [OIS_Data].[Package1] = [TBOIS].[Package1]
	----- >>> เช็ค Device และ Flow ที่มี 2 โปรแกรม ----------
	--WHERE ([TBAPCSPRO].[recipe] IS NULL OR [TBAPCSPRO].[recipe] != [TBOIS].[ProgramName])  
	--ORDER BY [TBOIS].[DeviceOIS];

	SELECT [TBAPCSPRO].[assy_name] AS [ft_name]
		, ISNULL([TBAPCSPRO].[recipe],'') AS [recipe]
		--, [TBOIS].[TestFlowName] AS [job_id]
		, [TBAPCSPRO].[job_name] AS [job_id]
		, [TBOIS].[ProgramName] AS [ProgramOIS]
		, [TBOIS].[Package1]
		, [TBAPCSPRO].[device_slip_id]
		, [TBAPCSPRO].[device_id]
		, [TBOIS].[DeviceOIS]
		, [TBOIS].[Flow] AS [FlowOIS]
		, [TBAPCSPRO].[version_num]
		, [TBAPCSPRO].[device]
		, [TBAPCSPRO].[assy_name]
		, [TBAPCSPRO].[job_id] AS [TestFlowId]
		, [TBOIS].[TestTypeName]
		, [Package2]
		, [Package5]
		, [DateChanged]
	FROM (
		SELECT DISTINCT 
			CASE 
				WHEN value = '-' THEN [DeviceName]
				WHEN value <> '' THEN [DeviceName] + '-' + value
			END AS [DeviceOIS]
			, CASE 
				WHEN TRIM([TestFlowName]) = 'AUTO(1)' AND [ProcessName] = 'FT' THEN  106
				WHEN TRIM([TestFlowName]) = 'AUTO1 HV' AND [ProcessName] = 'FT'  THEN  106
				WHEN TRIM([TestFlowName]) = 'AUTO1' AND [ProcessName] = 'FT'  THEN  106
				WHEN TRIM([TestFlowName]) = 'AUTO1' AND [ProcessName] = 'FL'  THEN  106
				WHEN TRIM([TestFlowName]) = 'AUTO1' AND [ProcessName] = 'MAP'  THEN  106
				WHEN TRIM([TestFlowName]) = 'AUTO1 INSPEC.' AND [ProcessName] = 'FT'  THEN  106
				WHEN TRIM([TestFlowName]) = 'AUTO1 INSPEC.' AND [ProcessName] = 'FT'  THEN  106
				WHEN TRIM([TestFlowName]) = 'AUTO2' AND [ProcessName] = 'FT'  THEN  108
				WHEN TRIM([TestFlowName]) = 'AUTO2' AND [ProcessName] = 'MAP'  THEN  108
				WHEN TRIM([TestFlowName]) = 'AUTO2 AFTER' AND [ProcessName] = 'FT'  THEN  371
				WHEN TRIM([TestFlowName]) = 'AUTO2ASISAMPLE' AND [ProcessName] = 'FT'  THEN  342
				WHEN TRIM([TestFlowName]) = 'AUTO3' AND [ProcessName] = 'FT'  THEN  110
				WHEN TRIM([TestFlowName]) = 'AUTO3ASISAMPLE' AND [ProcessName] = 'FT'  THEN  370
				WHEN TRIM([TestFlowName]) = 'AUTO4' AND [ProcessName] = 'FT'  THEN  119
				WHEN TRIM([TestFlowName]) = 'AUTO5' AND [ProcessName] = 'FT'  THEN  263
			END AS [Flow]
			, [ProgramName]
			, [Package1]
			, [TestFlowName]
			, [Package2]
			, [TestTypeName]
			, [DateChanged]
			, [Package5]
		FROM [DBx].[dbo].[OIS] WITH (NOLOCK)
		CROSS APPLY STRING_SPLIT([InputRank], '/')
	) AS [TBOIS]
	INNER JOIN (
		SELECT [device_flows].[recipe]
			, [device_slip_max].[id] AS [device_id]
			, [device_slip_max].[name] AS [device]
			, [device_slip_max].[ft_name]
			, [device_slip_max].[assy_name]
			, [device_slip_max].[is_released]
			, [device_slip_max].[device_slip_id]
			, [device_slip_max].[version_num]
			, [jobs].[name] AS [job_name]
			, [device_flows].[job_id]
			, CASE 
				WHEN [job_commons].[id] IS NOT NULL THEN [job_commons].[to_job_id]
				ELSE [device_flows].[job_id] 
			END AS [to_job_id]
			, CASE 
				WHEN TRIM([device_slip_max].short_name) = 'TO252' THEN 'TO252-3' 
				ELSE [device_slip_max].short_name 
			END AS [package]
			--, [device_slip_max].[short_name] AS [package]
		FROM (
			SELECT [device_names].[id] AS [id]
				, [device_names].[name] AS [name]
				, [device_names].[ft_name] AS [ft_name]
				, [device_names].[assy_name]
				, [device_names].[package_id]
				, [device_slips].[version_num]
				, [device_slips].[is_released]
				, [device_slips].[device_slip_id]
				, [packages].[short_name]
				, ROW_NUMBER() OVER (PARTITION BY [device_names].[id], [device_names].[name], [device_names].[ft_name], [device_names].[assy_name], [device_names].[package_id] ORDER BY [device_slips].[version_num] DESC) AS [rows]
			FROM [APCSProDB].[method].[device_names] WITH (NOLOCK)
			INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
				AND [device_versions].[device_type] = 0 
			INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
				AND [device_slips].[is_released] = 1
			INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		) AS [device_slip_max]
		INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_slip_max].[device_slip_id] = [device_flows].[device_slip_id] AND [device_flows].[is_skipped] = 0
		INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [device_flows].[job_id] = [jobs].[id]
		LEFT JOIN [APCSProDB].[trans].[job_commons] WITH(NOLOCK) ON [job_commons].[job_id] = [device_flows].[job_id]
			--AND [device_flows].[job_id] != 222
		WHERE [device_slip_max].[rows] = 1
	) As [TBAPCSPRO] ON [TBOIS].[DeviceOIS] = [TBAPCSPRO].[ft_name]
		AND [TBOIS].[Flow] = [TBAPCSPRO].[to_job_id] 
		AND [TBAPCSPRO].[package] = [TBOIS].[Package1]
	--- <<< เช็ค Device และ Flow ที่มี 2 โปรแกรม ----------
	INNER JOIN (
		SELECT [Package1]
			, [DeviceOIS]
			, [Flow]
			, [countPro]
		FROM (
			SELECT [Package1]
				, [DeviceOIS]
				, [Flow]
				, COUNT([ProgramName]) AS [countPro]
			FROM (
				SELECT DISTINCT 
					CASE 
						WHEN value = '-' THEN [DeviceName]
						WHEN value <> '' THEN [DeviceName] + '-' + value
					END AS [DeviceOIS]
					, CASE 
						WHEN TRIM([TestFlowName]) = 'AUTO(1)' AND [ProcessName] = 'FT'  THEN  106
						WHEN TRIM([TestFlowName]) = 'AUTO1 HV' AND [ProcessName] = 'FT'  THEN  106
						WHEN TRIM([TestFlowName]) = 'AUTO1' AND [ProcessName] = 'FT'  THEN  106
						WHEN TRIM([TestFlowName]) = 'AUTO1' AND [ProcessName] = 'FL'  THEN  106
						WHEN TRIM([TestFlowName]) = 'AUTO1' AND [ProcessName] = 'MAP'  THEN  106
						WHEN TRIM([TestFlowName]) = 'AUTO1 INSPEC.' AND [ProcessName] = 'FT'  THEN  106
						WHEN TRIM([TestFlowName]) = 'AUTO1 INSPEC.' AND [ProcessName] = 'FT'  THEN  106
						WHEN TRIM([TestFlowName]) = 'AUTO2' AND [ProcessName] = 'FT'  THEN  108
						WHEN TRIM([TestFlowName]) = 'AUTO2' AND [ProcessName] = 'MAP'  THEN  108
						WHEN TRIM([TestFlowName]) = 'AUTO2 AFTER' AND [ProcessName] = 'FT'  THEN  371
						WHEN TRIM([TestFlowName]) = 'AUTO2ASISAMPLE' AND [ProcessName] = 'FT'  THEN  342
						WHEN TRIM([TestFlowName]) = 'AUTO3' AND [ProcessName] = 'FT'  THEN  110
						WHEN TRIM([TestFlowName]) = 'AUTO3ASISAMPLE' AND [ProcessName] = 'FT'  THEN  370
						WHEN TRIM([TestFlowName]) = 'AUTO4' AND [ProcessName] = 'FT'  THEN  119
						WHEN TRIM([TestFlowName]) = 'AUTO5' AND [ProcessName] = 'FT'  THEN  263
					END AS [Flow]
					, [ProgramName]
					, [Package1]
				FROM [DBx].[dbo].[OIS] WITH (NOLOCK) 
				CROSS APPLY STRING_SPLIT([InputRank], '/')
			) AS [TB_OIS]
			GROUP BY [Package1], [DeviceOIS], [Flow]
		) AS [TB_OIS_Count]
		WHERE [TB_OIS_Count].[countPro] <= 1
	) AS [OIS_Data] ON [OIS_Data].[DeviceOIS] = [TBOIS].[DeviceOIS]
		AND [OIS_Data].[Flow] = [TBOIS].[Flow] 
		AND [OIS_Data].[Package1] = [TBOIS].[Package1]
	--- >>> เช็ค Device และ Flow ที่มี 2 โปรแกรม ----------
	WHERE ([TBAPCSPRO].[recipe] IS NULL OR [TBAPCSPRO].[recipe] != [TBOIS].[ProgramName])  
	ORDER BY [TBOIS].[DeviceOIS];
END
