-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rans].[sp_get_scheduler_temp_mp_ver_temp] 
	-- Add the parameters for the stored procedure here
	@package_name VARCHAR(255) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	------ version 1
	--SELECT [machines].[name] AS [machine_name]
	--	,models.name AS machine_type
	--	,(CASE WHEN bm.CategoryID IS NOT NULL THEN IIF(bm.CategoryID = 1,'BM','PM') ELSE [status_state] END) AS [status_state]
	--	, CASE (CASE WHEN bm.CategoryID IS NOT NULL THEN IIF(bm.CategoryID = 1,'BM','PM') ELSE [status_state] END) 
	--		WHEN 'Wait' THEN '#FFFF00'
	--		WHEN 'Run' THEN '#7FFFD4'
	--		WHEN 'Ready' THEN '#BAF6AB'
	--		WHEN 'Setup' THEN '#BAF6AB'
	--		WHEN 'Limit' THEN '#C19494'
	--		WHEN 'BM' THEN '#FF0000'
	--		WHEN 'PM' THEN '#FFA500'
	--		ELSE '#FFFF00'
	--	END AS [color_status]
	--	,[lot_no_1]
	--	,[lot_no_2]
	--	,[lot_no_3]
	--	,[lot_no_4]
	--	,[lot_no_5]
	--	,[lot_no_6]
	--	,[lot_no_7]
	--	,[lot_no_8]
	--	,[lot_no_9]
	--	,[lot_no_10]
	--	,[device_name_1]
	--	,[device_name_2]
	--	,[device_name_3]
	--	,[device_name_4]
	--	,[device_name_5]
	--	,[device_name_6]
	--	,[device_name_7]
	--	,[device_name_8]
	--	,[device_name_9]
	--	,[device_name_10]
	--	,[lot_no_1_startdate]
	--	,[lot_no_1_enddate]
	--	,[locations].[name] AS [location_name]
	--	,[locations].[address] AS [location_address]
	--	,[lot_no_change]
	--	,[device_name_change]
	--	,[jobs].[name] AS [flow]
	--	,[lot_wip_plans_01].[created_at]
	--	,[lot_wip_plans_01].[created_by]
	--	,[lot_wip_plans_01].[updated_at]
	--	,[lot_wip_plans_01].[updated_by]
	--FROM [APCSProDWH].[rans].[lot_wip_plans_01] WITH (NOLOCK)
	--LEFT JOIN [APCSProDB].[mc].[machines] WITH (NOLOCK) ON [lot_wip_plans_01].[machine_id] = [machines].[id]
	--LEFT JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [lot_wip_plans_01].[job_id] = [jobs].[id]
	--LEFT JOIN [APCSProDB].[trans].[locations] WITH (NOLOCK) ON [lot_wip_plans_01].[location_id_lot_no_2] = [locations].[id]
	--LEFT JOIN [APCSProDB].[mc].[models] WITH (NOLOCK) ON [machines].[machine_model_id] = [models].[id]
	--LEFT JOIN (
	--	SELECT bm.LotNo AS LotNo
	--		, bm.MachineID AS MCName 
	--		, bm.ProcessID AS Process
	--		, MIN(bm.TimeRequest) AS TimeRequest
	--		, CASE bm.CategoryID
	--			WHEN 1 THEN MIN(bm.TimeRequest)
	--			WHEN 2 THEN MIN(bm.TimeStart)
	--			ELSE max( bm.TimeStart)
	--		END AS TimeStart
	--		, MIN(bm.TimeFinish) AS TimeFinish
	--		, bm.CategoryID 
	--	FROM [DBx].[dbo].[BMMaintenance] AS [bm] WITH (NOLOCK)
	--	WHERE [bm].[TimeFinish] IS NULL 
	--		AND [bm].[CategoryID] IN (1,2)
	--	GROUP BY bm.MachineID
	--		, bm.LotNo 
	--		, bm.CategoryID 
	--		, bm.ProcessID
	--) AS [bm] ON [machines].[name] = [bm].[MCName];
	------ version 2
	--SELECT [machines].[name] AS [machine_name]
	--	,models.name AS machine_type
	--	,(CASE WHEN bm.CategoryID IS NOT NULL THEN [bm_status] ELSE [status_state] END) AS [status_state]
	--	, CASE (CASE WHEN bm.CategoryID IS NOT NULL THEN [bm_status] ELSE [status_state] END) 
	--		WHEN 'Wait' THEN '#FFFF00'
	--		WHEN 'Run' THEN '#7FFFD4'
	--		WHEN 'Ready' THEN '#BAF6AB'
	--		WHEN 'Setup' THEN '#BAF6AB'
	--		WHEN 'Limit' THEN '#C19494'
	--		WHEN 'BM' THEN '#FF0000'
	--		WHEN 'PM' THEN '#FFA500'
	--		ELSE '#FFFF00'
	--	END AS [color_status]
	--	,ISNULL([jigs].[type_name],'') AS [kanagata]
	--	,[lot_no_1]
	--	,[lot_no_2]
	--	,[lot_no_3]
	--	,[lot_no_4]
	--	,[lot_no_5]
	--	,[lot_no_6]
	--	,[lot_no_7]
	--	,[lot_no_8]
	--	,[lot_no_9]
	--	,[lot_no_10]
	--	,[device_name_1]
	--	,[device_name_2]
	--	,[device_name_3]
	--	,[device_name_4]
	--	,[device_name_5]
	--	,[device_name_6]
	--	,[device_name_7]
	--	,[device_name_8]
	--	,[device_name_9]
	--	,[device_name_10]
	--	,[lot_no_1_startdate]
	--	,[lot_no_1_enddate]
	--	,[locations].[name] AS [location_name]
	--	,[locations].[address] AS [location_address]
	--	,[lot_no_change]
	--	,[device_name_change]
	--	,[jobs].[name] AS [flow]
	--	,[lot_wip_plans_01].[created_at]
	--	,[lot_wip_plans_01].[created_by]
	--	,[lot_wip_plans_01].[updated_at]
	--	,[lot_wip_plans_01].[updated_by]
	--	,CASE
	--		WHEN [lot_no_1] IS NOT NULL THEN FORMAT(DATEADD(S, DATEDIFF(S, [lot_no_1_startdate], [lot_no_1_enddate]), '1900-1-1'),'hh:mm')
	--		WHEN [bm].[TimeStart] IS NOT NULL THEN CONCAT(IIF(DATEDIFF(DAY, [bm].[TimeStart], GETDATE()) = 0,NULL,CAST(DATEDIFF(DAY, [bm].[TimeStart], GETDATE()) AS VARCHAR) + '.'),FORMAT(DATEADD(S, DATEDIFF(S, [bm].[TimeStart], GETDATE()), '1900-1-1'),'hh:mm'))
	--		WHEN [limits].[is_alarmed] = 1 THEN CONCAT(IIF(DATEDIFF(DAY, [limits].[LockStartTime], GETDATE()) = 0,NULL,CAST(DATEDIFF(DAY, [limits].[LockStartTime], GETDATE()) AS VARCHAR) + '.'),FORMAT(DATEADD(S, DATEDIFF(S, [limits].[LockStartTime], GETDATE()), '1900-1-1'),'hh:mm'))
	--		ELSE NULL 
	--	END AS [datetime_count]
	--FROM [APCSProDWH].[rans].[lot_wip_plans_01] WITH (NOLOCK)
	--LEFT JOIN [APCSProDB].[trans].[lots] WITH (NOLOCK) ON [lot_wip_plans_01].[lot_no_1] = [lots].[lot_no]
	--LEFT JOIN [APCSProDB].[mc].[machines] WITH (NOLOCK) ON [lot_wip_plans_01].[machine_id] = [machines].[id]
	--LEFT JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [lot_wip_plans_01].[job_id] = [jobs].[id]
	--LEFT JOIN [APCSProDB].[trans].[locations] WITH (NOLOCK) ON [lot_wip_plans_01].[location_id_lot_no_2] = [locations].[id]
	--LEFT JOIN [APCSProDB].[mc].[models] WITH (NOLOCK) ON [machines].[machine_model_id] = [models].[id]
	-----------------------------------------------------------------------------------------------------
	------ Find kanagata type
	--LEFT JOIN (
	--	SELECT [packages_id]
	--		, [machine_id]
	--		, CONCAT(IIF([1] IS NULL,NULL,[1]), IIF([2] IS NULL,NULL,',' + [2]), IIF([3] IS NULL,NULL,',' + [3]), IIF([4] IS NULL,NULL,',' + [4]), IIF([5] IS NULL,NULL,',' + [5])) AS [type_name]
	--	FROM (
	--		SELECT 	[packages].[id] AS [packages_id]
	--			, [packages].[name] AS [package_name] 
	--			, [machines].[id] AS [machine_id]
	--			, [machines].[name] AS [machine_name]
	--			, [productions].[name] AS [type_name]
	--			, ROW_NUMBER() OVER (PARTITION BY [machines].[id], [packages].[id] ORDER BY [machines].[id], [packages].[id]) AS [row]
	--		FROM [APCSProDB].[mc].[machines] 
	--		INNER JOIN [APCSProDB].[trans].[machine_jigs] WITH (NOLOCK) ON [machines].[id] = [machine_jigs].[machine_id]
	--		INNER JOIN [APCSProDB].[trans].[jigs] WITH (NOLOCK) ON [machine_jigs].[jig_id] = [jigs].[id]
	--		INNER JOIN [APCSProDB].[method].[jig_set_list] WITH (NOLOCK)  ON [jigs].[jig_production_id] = [jig_set_list].[jig_group_id]
	--		INNER JOIN [APCSProDB].[jig].[productions] WITH (NOLOCK) ON [jig_set_list].[jig_group_id] = [productions].[id]
	--		INNER JOIN [APCSProDB].[jig].[categories] WITH (NOLOCK) ON [productions].[category_id] = [categories].[id]
	--		INNER JOIN [APCSProDB].[method].[jig_sets] WITH (NOLOCK) ON [jig_set_list].[jig_set_id] = [jig_sets].[id]
	--		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[short_name] = [jig_sets].[name]
	--		WHERE [categories].[short_name] = 'Kanagata'
	--			AND [machines].[name] LIKE 'MP%'
	--		GROUP BY [machines].[id]
	--			, [machines].[name]
	--			, [packages].[id]
	--			, [packages].[name]
	--			, [productions].[name]
	--	) AS [data]
	--	PIVOT (
	--		MAX([data].[type_name]) FOR [row] IN ([1],[2],[3],[4],[5]) ---- group by [machines].[id], [packages].[id] and order by [machines].[id], [packages].[id]
	--	) AS [p1]
	--) AS [jigs] ON [machines].[id] = [jigs].[machine_id]
	--	AND [lots].[act_package_id] = [jigs].[packages_id]
	-----------------------------------------------------------------------------------------------------
	------ Find mc status BM,PM
	--LEFT JOIN (
	--	SELECT [bm].[LotNo] AS [LotNo]
	--		, [bm].[MachineID] AS [MCName] 
	--		, [bm].[ProcessID] AS [Process]
	--		, MIN([bm].[TimeRequest]) AS [TimeRequest]
	--		, CASE [bm].[CategoryID]
	--			WHEN 1 THEN MIN([bm].[TimeRequest])
	--			WHEN 2 THEN MIN([bm].[TimeStart])
	--			ELSE MAX([bm].[TimeStart])
	--		END AS [TimeStart]
	--		, MIN([bm].[TimeFinish]) AS [TimeFinish]
	--		, [bm].[CategoryID]
	--		, IIF([bm].[CategoryID] = 1,'BM','PM') AS [bm_status]
	--	FROM [DBx].[dbo].[BMMaintenance] AS [bm] WITH (NOLOCK)
	--	WHERE [bm].[TimeFinish] IS NULL 
	--		AND [bm].[CategoryID] IN (1,2)
	--	GROUP BY [bm].[MachineID]
	--		, [bm].[LotNo] 
	--		, [bm].[CategoryID]
	--		, [bm].[ProcessID]
	--) AS [bm] ON [machines].[name] = [bm].[MCName]
	-----------------------------------------------------------------------------------------------------
	------ Find limit flow by package
	--LEFT JOIN (
	--	SELECT [wip_control].[id]	
	--		, [pkg].[id] AS [package_id]
	--		, [pkg].[name] AS [package_name]
	--		, [wip_control].[name]
	--		, CASE 
	--			WHEN (SELECT CHARINDEX('[', [wip_control].[name])) < ((SELECT CHARINDEX('@', [wip_control].[name]))-1) 
	--			THEN SUBSTRING([wip_control].[name] ,(SELECT CHARINDEX('@', [wip_control].[name]))+1, ((SELECT LEN([wip_control].[name]))-(SELECT CHARINDEX('@', [wip_control].[name]))))
	--			ELSE SUBSTRING([wip_control].[name] ,(SELECT CHARINDEX('@', [wip_control].[name]))+1, ((SELECT CHARINDEX('[', [wip_control].[name]))-(SELECT CHARINDEX('@', [wip_control].[name]))-1))
	--		END AS [Flow] 
	--		, CASE 
	--			WHEN (SELECT CHARINDEX('[', [wip_control].[name])) < ((SELECT CHARINDEX('@', [wip_control].[name]))-1) 
	--			THEN SUBSTRING([wip_control].[name] ,(SELECT CHARINDEX('[', [wip_control].[name]))+1, ((SELECT CHARINDEX(']', [wip_control].[name]))-(SELECT CHARINDEX('[', [wip_control].[name])))) 
	--			ELSE SUBSTRING([wip_control].[name] ,(SELECT CHARINDEX('[', [wip_control].[name]))+1, ((SELECT CHARINDEX(']', [wip_control].[name]))-(SELECT CHARINDEX('[', [wip_control].[name]))-1)) 
	--		END AS [FlowControl]
	--		, CAST(ROUND([wip_control].[alarm_value],2) AS NUMERIC(8,2)) AS [limit_value]
	--		, CAST(ROUND([wip_control].[current_value],2) AS NUMERIC(8,2)) AS [current_value]
	--		, [wip_control].[is_alarmed]
	--		, CASE 
	--			WHEN (CAST(ROUND([wip_control].[alarm_value],2) AS NUMERIC(8,2)) != CAST(ROUND([wip_control].[warn_value],2 ) AS NUMERIC(8,2)) OR CAST(ROUND(alarm_value,2) AS NUMERIC(8,2)) != CAST(ROUND(target_value,2 ) AS NUMERIC(8,2))) THEN 1
	--			ELSE 0 
	--		END AS [Is_SameValue]
	--		, [wip_control].[control_unit_type] AS [unitType]
	--		, [wip_control].[occurred_at] AS [LockStartTime]
	--	FROM [APCSProDWH].[wip_control].[monitoring_items] AS [wip_control]
	--	INNER JOIN [APCSProDB].[method].[packages] AS [pkg] ON [wip_control].[package_id]  = [pkg].[id]
	--) AS [limits] ON [lots].[act_package_id] = [limits].[package_id]
	--	AND ([limits].[FlowControl] LIKE 'MP%')
	-----------------------------------------------------------------------------------------------------
	--ORDER BY [machines].[name];
	------ version 3
	DECLARE @table TABLE (package_name VARCHAR(MAX))

	INSERT INTO @table
	EXEC [StoredProcedureDB].[rans].[sp_get_package mp] @type_id = 2,@package_name = @package_name
	
	SELECT DISTINCT [machines].[name] AS [machine_name]
		,[models].[name] AS [machine_type]
		,[find_package_mc].[package_name]
		--,value
		,(CASE WHEN [bm].[CategoryID] IS NOT NULL THEN [bm_status] ELSE [status_state] END) AS [status_state]
		, CASE (CASE WHEN [bm].[CategoryID] IS NOT NULL THEN [bm_status] ELSE [status_state] END) 
			WHEN 'Wait' THEN '#FFFF00'
			WHEN 'Run' THEN '#7FFFD4'
			WHEN 'Ready' THEN '#BAF6AB'
			WHEN 'Setup' THEN '#BAF6AB'
			WHEN 'Limit' THEN '#C19494'
			WHEN 'BM' THEN '#FF0000'
			WHEN 'PM' THEN '#FFA500'
			ELSE '#FFFF00'
		END AS [color_status]
		,[jigs].[type_name] AS [kanagata]
		,[lot_no_1]
		,[lot_no_2]
		,[lot_no_3]
		,[lot_no_4]
		,[lot_no_5]
		,[lot_no_6]
		,[lot_no_7]
		,[lot_no_8]
		,[lot_no_9]
		,[lot_no_10]
		,[device_name_1]
		,[device_name_2]
		,[device_name_3]
		,[device_name_4]
		,[device_name_5]
		,[device_name_6]
		,[device_name_7]
		,[device_name_8]
		,[device_name_9]
		,[device_name_10]
		,[lot_no_1_startdate]
		,[lot_no_1_enddate]
		,[rack_controls].[name] AS [location_name]
		,[rack_addresses].[address] AS [location_address]
		,[lot_no_change]
		,[device_name_change]
		,[jobs].[name] AS [flow]
		,[lot_wip_plans_01].[created_at]
		,[lot_wip_plans_01].[created_by]
		,[lot_wip_plans_01].[updated_at]
		,[lot_wip_plans_01].[updated_by]
		,CASE
			WHEN [lot_no_1] IS NOT NULL THEN FORMAT(DATEADD(S, DATEDIFF(S, [lot_no_1_startdate], [lot_no_1_enddate]), '1900-1-1'),'hh:mm')
			WHEN [bm].[TimeStart] IS NOT NULL THEN CONCAT(IIF(DATEDIFF(DAY, [bm].[TimeStart], GETDATE()) = 0,NULL,CAST(DATEDIFF(DAY, [bm].[TimeStart], GETDATE()) AS VARCHAR) + '.'),FORMAT(DATEADD(S, DATEDIFF(S, [bm].[TimeStart], GETDATE()), '1900-1-1'),'hh:mm'))
			WHEN [limits].[is_alarmed] = 1 THEN CONCAT(IIF(DATEDIFF(DAY, [limits].[LockStartTime], GETDATE()) = 0,NULL,CAST(DATEDIFF(DAY, [limits].[LockStartTime], GETDATE()) AS VARCHAR) + '.'),FORMAT(DATEADD(S, DATEDIFF(S, [limits].[LockStartTime], GETDATE()), '1900-1-1'),'hh:mm'))
			ELSE NULL 
		END AS [datetime_count]
	FROM [APCSProDWH].[rans].[lot_wip_plans_01] WITH (NOLOCK)
	LEFT JOIN [APCSProDB].[trans].[lots] WITH (NOLOCK) ON [lot_wip_plans_01].[lot_no_1] = [lots].[lot_no]
	LEFT JOIN [APCSProDB].[mc].[machines] WITH (NOLOCK) ON [lot_wip_plans_01].[machine_id] = [machines].[id]
	LEFT JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [lot_wip_plans_01].[job_id] = [jobs].[id]
	LEFT JOIN [APCSProDB].[rcs].[rack_addresses] ON [lot_wip_plans_01].[location_id_lot_no_2]  = rack_addresses.id
	LEFT JOIN [APCSProDB].[rcs].[rack_controls] on rack_addresses.rack_control_id = rack_controls.id
	LEFT JOIN [APCSProDB].[mc].[models] WITH (NOLOCK) ON [machines].[machine_model_id] = [models].[id]
	---------------------------------------------------------------------------------------------------
	---- Find kanagata type
	LEFT JOIN (
		SELECT [machine_id]
			, CONCAT(IIF([1] IS NULL,NULL,[1]), IIF([2] IS NULL,NULL,',' + [2]), IIF([3] IS NULL,NULL,',' + [3]), IIF([4] IS NULL,NULL,',' + [4]), IIF([5] IS NULL,NULL,',' + [5])) AS [type_name]
		FROM (
			SELECT [machines].[id] AS [machine_id]
				, [machines].[name] AS [machine_name]
				, [productions].[name] AS [type_name]
				, ROW_NUMBER() OVER (PARTITION BY [machines].[id] ORDER BY [machines].[id]) AS [row]
			FROM [APCSProDB].[mc].[machines] 
			INNER JOIN [APCSProDB].[trans].[machine_jigs] WITH (NOLOCK) ON [machines].[id] = [machine_jigs].[machine_id]
			INNER JOIN [APCSProDB].[trans].[jigs] WITH (NOLOCK) ON [machine_jigs].[jig_id] = [jigs].[id]
			INNER JOIN [APCSProDB].[method].[jig_set_list] WITH (NOLOCK)  ON [jigs].[jig_production_id] = [jig_set_list].[jig_group_id]
			INNER JOIN [APCSProDB].[jig].[productions] WITH (NOLOCK) ON [jig_set_list].[jig_group_id] = [productions].[id]
			INNER JOIN [APCSProDB].[jig].[categories] WITH (NOLOCK) ON [productions].[category_id] = [categories].[id]
			INNER JOIN [APCSProDB].[method].[jig_sets] WITH (NOLOCK) ON [jig_set_list].[jig_set_id] = [jig_sets].[id]
			INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[short_name] = [jig_sets].[name]
			WHERE [categories].[short_name] = 'Kanagata'
				AND [machines].[name] LIKE 'MP%'
			GROUP BY [machines].[id]
				, [machines].[name]
				, [productions].[name]
		) AS [data]
		PIVOT (
			MAX([data].[type_name]) FOR [row] IN ([1],[2],[3],[4],[5]) ---- group by [machines].[id] and order by [machines].[id]
		) AS [p1]
	) AS [jigs] ON [machines].[id] = [jigs].[machine_id]
	---------------------------------------------------------------------------------------------------
	---- Find mc status BM,PM
	LEFT JOIN (
		SELECT [bm].[LotNo] AS [LotNo]
			, [bm].[MachineID] AS [MCName] 
			, [bm].[ProcessID] AS [Process]
			, MIN([bm].[TimeRequest]) AS [TimeRequest]
			, CASE [bm].[CategoryID]
				WHEN 1 THEN MIN([bm].[TimeRequest])
				WHEN 2 THEN MIN([bm].[TimeStart])
				ELSE MAX([bm].[TimeStart])
			END AS [TimeStart]
			, MIN([bm].[TimeFinish]) AS [TimeFinish]
			, [bm].[CategoryID]
			, IIF([bm].[CategoryID] = 1,'BM','PM') AS [bm_status]
		FROM [DBx].[dbo].[BMMaintenance] AS [bm] WITH (NOLOCK)
		WHERE [bm].[TimeFinish] IS NULL 
			AND [bm].[CategoryID] IN (1,2)
		GROUP BY [bm].[MachineID]
			, [bm].[LotNo] 
			, [bm].[CategoryID]
			, [bm].[ProcessID]
	) AS [bm] ON [machines].[name] = [bm].[MCName]
	---------------------------------------------------------------------------------------------------
	---- Find limit flow by package
	LEFT JOIN (
		SELECT [wip_control].[id]	
			, [pkg].[id] AS [package_id]
			, [pkg].[name] AS [package_name]
			, [wip_control].[name]
			, CASE 
				WHEN (SELECT CHARINDEX('[', [wip_control].[name])) < ((SELECT CHARINDEX('@', [wip_control].[name]))-1) 
				THEN SUBSTRING([wip_control].[name] ,(SELECT CHARINDEX('@', [wip_control].[name]))+1, ((SELECT LEN([wip_control].[name]))-(SELECT CHARINDEX('@', [wip_control].[name]))))
				ELSE SUBSTRING([wip_control].[name] ,(SELECT CHARINDEX('@', [wip_control].[name]))+1, ((SELECT CHARINDEX('[', [wip_control].[name]))-(SELECT CHARINDEX('@', [wip_control].[name]))-1))
			END AS [Flow] 
			, CASE 
				WHEN (SELECT CHARINDEX('[', [wip_control].[name])) < ((SELECT CHARINDEX('@', [wip_control].[name]))-1) 
				THEN SUBSTRING([wip_control].[name] ,(SELECT CHARINDEX('[', [wip_control].[name]))+1, ((SELECT CHARINDEX(']', [wip_control].[name]))-(SELECT CHARINDEX('[', [wip_control].[name])))) 
				ELSE SUBSTRING([wip_control].[name] ,(SELECT CHARINDEX('[', [wip_control].[name]))+1, ((SELECT CHARINDEX(']', [wip_control].[name]))-(SELECT CHARINDEX('[', [wip_control].[name]))-1)) 
			END AS [FlowControl]
			, CAST(ROUND([wip_control].[alarm_value],2) AS NUMERIC(8,2)) AS [limit_value]
			, CAST(ROUND([wip_control].[current_value],2) AS NUMERIC(8,2)) AS [current_value]
			, [wip_control].[is_alarmed]
			, CASE 
				WHEN (CAST(ROUND([wip_control].[alarm_value],2) AS NUMERIC(8,2)) != CAST(ROUND([wip_control].[warn_value],2 ) AS NUMERIC(8,2)) OR CAST(ROUND(alarm_value,2) AS NUMERIC(8,2)) != CAST(ROUND(target_value,2 ) AS NUMERIC(8,2))) THEN 1
				ELSE 0 
			END AS [Is_SameValue]
			, [wip_control].[control_unit_type] AS [unitType]
			, [wip_control].[occurred_at] AS [LockStartTime]
		FROM [APCSProDWH].[wip_control].[monitoring_items] AS [wip_control]
		INNER JOIN [APCSProDB].[method].[packages] AS [pkg] ON [wip_control].[package_id]  = [pkg].[id]
	) AS [limits] ON [lots].[act_package_id] = [limits].[package_id]
		AND ([limits].[FlowControl] LIKE 'MP%')
	---------------------------------------------------------------------------------------------------
	---- Find kanagata type package mc
	LEFT JOIN (
		SELECT [m_mc].[machine_id]
			, [package_name]
		FROM (
			SELECT [machine_id] FROM [APCSProDWH].[rans].[machine_location_settings]
			GROUP BY [machine_id]
		) AS [m_mc]
		INNER JOIN (
			SELECT [machine_id]
				, CONCAT(
					IIF([1] IS NULL,NULL,TRIM([1]))
					, IIF([2] IS NULL,NULL,',' + TRIM([2]))
					, IIF([3] IS NULL,NULL,',' + TRIM([3]))
					, IIF([4] IS NULL,NULL,',' + TRIM([4]))
					, IIF([5] IS NULL,NULL,',' + TRIM([5]))
					, IIF([6] IS NULL,NULL,',' + TRIM([6]))
					, IIF([7] IS NULL,NULL,',' + TRIM([7]))
					, IIF([8] IS NULL,NULL,',' + TRIM([8]))
					, IIF([9] IS NULL,NULL,',' + TRIM([9]))
					, IIF([10] IS NULL,NULL,',' + TRIM([10]))
				) AS [package_name]
			FROM (
				SELECT [packages].[name] AS [package_name] 
					, [machines].[id] AS [machine_id]
					--, [machines].[name] AS [machine_name]
					, ROW_NUMBER() OVER (PARTITION BY [machines].[id] ORDER BY [machines].[id], [packages].[id]) AS [row]
				FROM [APCSProDB].[mc].[machines] 
				INNER JOIN [APCSProDB].[trans].[machine_jigs] WITH (NOLOCK) ON [machines].[id] = [machine_jigs].[machine_id]
				INNER JOIN [APCSProDB].[trans].[jigs] WITH (NOLOCK) ON [machine_jigs].[jig_id] = [jigs].[id]
				INNER JOIN [APCSProDB].[method].[jig_set_list] WITH (NOLOCK)  ON [jigs].[jig_production_id] = [jig_set_list].[jig_group_id]
				INNER JOIN [APCSProDB].[jig].[productions] WITH (NOLOCK) ON [jig_set_list].[jig_group_id] = [productions].[id]
				INNER JOIN [APCSProDB].[jig].[categories] WITH (NOLOCK) ON [productions].[category_id] = [categories].[id]
				INNER JOIN [APCSProDB].[method].[jig_sets] WITH (NOLOCK) ON [jig_set_list].[jig_set_id] = [jig_sets].[id]
				INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[short_name] = [jig_sets].[name]
				WHERE [categories].[short_name] = 'Kanagata'
					AND [machines].[name] LIKE 'MP%'
				GROUP BY [machines].[id]
					, [machines].[name]
					, [packages].[id]
					, [packages].[name]
			) AS [data]
			PIVOT (
				MAX([data].[package_name]) FOR [row] IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
			) AS [p1]
		) AS [m_pkg] ON [m_mc].[machine_id] = [m_pkg].[machine_id]
	) AS [find_package_mc] ON [machines].[id] = [find_package_mc].[machine_id]
	---------------------------------------------------------------------------------------------------
	---- Split package name
	OUTER APPLY STRING_SPLIT([find_package_mc].[package_name], ',')
	WHERE value IN (SELECT value FROM STRING_SPLIT ((SELECT TOP 1 package_name FROM @table),','))
		AND [lot_wip_plans_01].[process] = 'MP'
	---------------------------------------------------------------------------------------------------
	ORDER BY [machines].[name], [find_package_mc].[package_name];

END
