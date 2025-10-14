-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [rans].[sp_get_scheduler_temp_wb_ver_temp] 
	-- Add the parameters for the stored procedure here
	--@package_name VARCHAR(255) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	------ version 1
	SELECT [machines].[name] AS [machine_name]
		, TRIM([packages].[short_name]) + IIF([packages_2].[short_name] IS NOT NULL,'/' + TRIM([packages_2].[short_name]),'') AS [package_name]
		--,value
		, (CASE WHEN [bm].[CategoryID] IS NOT NULL THEN [bm_status] 
		ELSE CASE [machines].[online_state] 
				WHEN 0 THEN 'Wait'
				ELSE [status_state] END
		END) AS [status_state]
		, CASE (CASE WHEN [bm].[CategoryID] IS NOT NULL THEN [bm_status] 
				ELSE CASE [machines].[online_state] 
						WHEN 0 THEN 'Wait'
						ELSE [status_state] END
				END)
			WHEN 'Wait' THEN '#FFFF00'
			WHEN 'Run' THEN '#7FFFD4'
			WHEN 'Ready' THEN '#BAF6AB'
			WHEN 'Setup' THEN '#BAF6AB'
			WHEN 'Limit' THEN '#C19494'
			WHEN 'BM' THEN '#FF0000'
			WHEN 'PM' THEN '#FFA500'
			ELSE '#FFFF00'
		END AS [color_status]
		,[lot_no_1] 
		,[lots].[lot_no] AS [lot_no_1_shear]
		,[lots_2].[lot_no]  AS [lot_no_1_pull]
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
		,[device_names].[name] AS [device_name_1_shear]
		,[device_names_2].[name] AS [device_name_1_pull]
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
		--,[locations].[name] AS [location_name]
		--,[locations].[address] AS [location_address]
		, [rack_controls].[name] AS [location_name]
		, [rack_addresses].[address] AS [location_address]
		,[lot_no_change]
		,[device_name_change]
		,NULL AS [flow]
		,[lot_wip_plans_01].[created_at]
		,[lot_wip_plans_01].[created_by]
		,[lot_wip_plans_01].[updated_at]
		,[lot_wip_plans_01].[updated_by]
	FROM [APCSProDWH].[rans].[lot_wip_plans_01] WITH (NOLOCK)
	LEFT JOIN [APCSProDWH].[rans].[machine_state_ps] AS [machines]  WITH (NOLOCK) ON [lot_wip_plans_01].[machine_id] = [machines].[id]
	LEFT JOIN [APCSProDB].[trans].[lots] WITH (NOLOCK) ON [machines].[lot_id] = [lots].[id]
	LEFT JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [lots].[act_package_id] = [packages].[id]
	LEFT JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [lots].[act_device_name_id] = [device_names].[id]
	LEFT JOIN [APCSProDB].[trans].[lots] AS [lots_2] WITH (NOLOCK) ON [machines].[lot_id2] = [lots_2].[id]
	LEFT JOIN [APCSProDB].[method].[packages] AS [packages_2] WITH (NOLOCK) ON [lots_2].[act_package_id] = [packages_2].[id]
	LEFT JOIN [APCSProDB].[method].[device_names] AS [device_names_2] WITH (NOLOCK) ON [lots_2].[act_device_name_id] = [device_names_2].[id]
	--LEFT JOIN [APCSProDB].[trans].[locations] WITH (NOLOCK) ON [lot_wip_plans_01].[location_id_lot_no_2] = [locations].[id]
	LEFT JOIN [APCSProDB].[rcs].[rack_addresses] WITH (NOLOCK) ON [lots].[location_id] = [rack_addresses].[id]
	LEFT JOIN [APCSProDB].[rcs].[rack_controls] WITH (NOLOCK) ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
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
	WHERE [lot_wip_plans_01].[process] = 'WB'
	ORDER BY [machines].[name] ASC;
END
