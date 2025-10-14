-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rans].[sp_set_scheduler_temp_wb_ver_temp] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	------ version 1
	-------------------------------------------------------------------------------------------------------------------
	--PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> start <---- ');
	
	--DECLARE @count_mc INT

	--SELECT @count_mc = COUNT([id]) FROM [APCSProDWH].[rans].[machine_state_ps]
	--WHERE online_state = 1;

	---------------------------------------------------------------------
	--DECLARE @tb_lot_out TABLE(
	--	[lot_id] int
	--	, [number] int
	--)

	--INSERT INTO @tb_lot_out (lot_id, number)
	--SELECT [lot_id], 1
	--FROM [APCSProDWH].[rans].[machine_state_ps]
	--WHERE [online_state] = 1 AND [lot_id] IS NOT NULL;

	--INSERT INTO @tb_lot_out (lot_id, number)
	--SELECT [next_lot_id], 2 
	--FROM [APCSProDWH].[rans].[machine_state_ps] 
	--WHERE [online_state] = 1 AND [next_lot_id] IS NOT NULL;
	--PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> insert lot in station <---- ');

	--DECLARE @lot_run TABLE
	--(
	--	[lot_no] varchar(10)
	--	, [job_id] INT
	--	, [ft_device] VARCHAR(30)
	--	, [package_name] VARCHAR(30)
	--	--, [job_master] varchar(20)
	--	--, [job_special] varchar(20)
	--	, [location_id] int
	--	, [location_name] varchar(20)
	--	, [address] varchar(20)
	--	, [priority] int
	--	, [date_at] datetime
	--	, [machine_id] INT
	--	, [machine_name] varchar(20)
	--	, [number] int
	--)

	--INSERT INTO @lot_run
	--SELECT [data_total].[lot_no]
	--	, [data_total].[job_id]
	--	, [device_names].[ft_name] AS [ft_device]
	--	, [packages].[name] AS [package_name]
	--	--, [data_total].[job_master]
	--	--, [data_total].[job_special]
	--	, [data_total].[location_id]
	--	, [data_total].[location_name]
	--	, [data_total].[address]
	--	, [data_total].[priority]
	--	, [data_total].[date_at]
	--	, [machine].[machine_id]
	--	, [machine].[machine_name]
	--	, ROW_NUMBER() OVER (PARTITION BY [machine].[machine_name] ORDER BY [data_total].[machine_id] ASC, [data_total].[priority] DESC, [data_total].[date_at] ASC) AS [number]
	--FROM (
	--	SELECT [data_2].[id]
	--		, [data_2].[lot_no]
	--		, [data_2].[job_id]
	--		--, [data_2].[job_master]
	--		--, [data_2].[job_special]
	--		, [data_2].[location_id]
	--		, [data_2].[location_name]
	--		, [data_2].[address]
	--		, [data_2].[priority]
	--		, [data_2].[date_at]
	--		, [data_2].[row]
	--		, LAG([data_2].[row],1,0) OVER (ORDER BY [priority] DESC, [data_2].[date_at] ASC) + 1  AS [machine_id]
	--	FROM (
	--		SELECT [id]
	--			, [lot_no]
	--			, [job_id]
	--			--, [job_master]
	--			--, [job_special]
	--			, [location_id]
	--			, [location_name]
	--			, [address]
	--			, [priority]
	--			, [date_at]
	--			, [machine_id]
	--			, (ROW_NUMBER() OVER (ORDER BY [priority] DESC, [date_at]) % @count_mc) AS [row]
	--		FROM (
	--			SELECT [lots].[id]
	--				, [lots].[lot_no]
	--				, IIF([lots].[is_special_flow] = 1,[job2].[id],[jobs].[id]) AS [job_id]
	--				, IIF([lots].[is_special_flow] = 1,[job2].[name],[jobs].[name]) AS [job_name]
	--				--, [jobs].[name] AS [job_master]
	--				--, [job2].[name] AS [job_special]
	--				, [lots].[process_state]
	--				, [lots].[location_id]
	--				, [locations].[name] AS [location_name] 
	--				, [locations].[address]
	--				, [lots].[priority]
	--				, [rcs_current_locations].[updated_at] AS [date_at] 
	--				--, IIF([lots].[lot_no]='2308A3490V',100,[lots].[priority]) AS [priority]
	--				, NULL AS [machine_id]
	--			FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) 
	--			INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--			INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
	--			INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
	--			INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
	--			INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
	--			INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
	--				AND [device_flows].[step_no] = [lots].[step_no]
	--			INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
	--			INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
	--			LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lots].[special_flow_id] 
	--				AND [lots].[is_special_flow] = 1
	--			LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id] 
	--				AND  [special_flows].[step_no] = [lot_special_flows].[step_no]
	--			LEFT JOIN [APCSProDB].[method].[jobs] AS [job2] WITH (NOLOCK) ON [job2].[id] = [lot_special_flows].[job_id]
	--			LEFT JOIN [APCSProDB].[method].[processes] AS [processes2] WITH (NOLOCK) ON [processes2].[id] = [job2].[process_id]
	--			LEFT JOIN [APCSProDB].[trans].[locations] WITH (NOLOCK) ON [lots].[location_id] = [locations].[id]
	--			LEFT JOIN [DBx].[dbo].[rcs_current_locations] WITH (NOLOCK) ON [lots].[id] = [rcs_current_locations].[lot_id]
	--				AND [lots].[location_id] = [rcs_current_locations].[location_id]
	--			WHERE [lots].[wip_state] = 20
	--				AND (IIF([lots].[is_special_flow] = 1,[job2].[name],[jobs].[name]) = 'WB')
	--				AND [lots].[process_state] IN (2,102)
	--				AND [lots].[location_id] IS NOT NULL
	--				AND [locations].[name] LIKE 'PS%'
	--				AND [lots].[id] NOT IN (SELECT [lot_id] FROM @tb_lot_out)  
	--			UNION ALL
	--			SELECT [lots].[id]
	--				, [lots].[lot_no]
	--				, IIF([lots].[is_special_flow] = 1,[job2].[id],[jobs].[id]) AS [job_id]
	--				, IIF([lots].[is_special_flow] = 1,[job2].[name],[jobs].[name]) AS [job_name]
	--				--, [jobs].[name] AS [job_master]
	--				--, [job2].[name] AS [job_special]
	--				, [lots].[process_state]
	--				, [lots].[location_id]
	--				, [locations].[name] AS [location_name] 
	--				, [locations].[address]
	--				, 101 AS [priority]
	--				, NULL AS [date_at] 
	--				, [lot_on_machine].[id] AS [machine_id]
	--			FROM [APCSProDWH].[rans].[machine_state_ps] AS [lot_on_machine]
	--			INNER JOIN [APCSProDB].[trans].[lots] WITH (NOLOCK) ON [lot_on_machine].[lot_id] = [lots].[id]
	--			INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--			INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
	--			INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
	--			INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
	--			INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
	--			INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
	--				AND [device_flows].[step_no] = [lots].[step_no]
	--			INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
	--			INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
	--			LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lots].[special_flow_id] 
	--				AND [lots].[is_special_flow] = 1
	--			LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id] 
	--				AND  [special_flows].[step_no] = [lot_special_flows].[step_no]
	--			LEFT JOIN [APCSProDB].[method].[jobs] AS [job2] WITH (NOLOCK) ON [job2].[id] = [lot_special_flows].[job_id]
	--			LEFT JOIN [APCSProDB].[method].[processes] AS [processes2] WITH (NOLOCK) ON [processes2].[id] = [job2].[process_id]
	--			LEFT JOIN [APCSProDB].[trans].[locations] WITH (NOLOCK) ON [lots].[location_id] = [locations].[id]
	--			LEFT JOIN [DBx].[dbo].[rcs_current_locations] WITH (NOLOCK) ON [lots].[id] = [rcs_current_locations].[lot_id]
	--				AND [lots].[location_id] = [rcs_current_locations].[location_id]
	--			WHERE [lot_on_machine].[online_state] = 1
	--		) AS [data_1]
	--	) AS [data_2]
	
	--) AS [data_total]
	--INNER JOIN (
	--	SELECT (ROW_NUMBER() OVER (ORDER BY [name] ASC)) AS [id]
	--		, [id] AS [machine_id]
	--		, [name] AS [machine_name]
	--	FROM [APCSProDWH].[rans].[machine_state_ps]
	--	WHERE [online_state] = 1
	--) AS [machine] ON [data_total].[machine_id] = [machine].[id]
	--INNER JOIN [APCSProDB].[trans].[lots] WITH (NOLOCK) ON [data_total].[id] = [lots].[id]
	--INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [lots].[act_device_name_id]
	--INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
	--ORDER BY [data_total].[machine_id] ASC, [data_total].[priority] DESC, [data_total].[date_at] ASC;

	--PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> insert lot plan <---- ');

	--IF EXISTS(SELECT TOP 1 machine_id FROM @lot_run)
	--BEGIN
	--	DELETE FROM [APCSProDWH].[rans].[lot_wip_plans] WHERE [process] = 'WB';
	--	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> delete table APCSProDWH.rans.lot_wip_plans WP <---- ');

	--	INSERT INTO [APCSProDWH].[rans].[lot_wip_plans]
	--		( [machine_id]
	--		, [status_state]
	--		, [process]
	--		, [lot_no_1]
	--		, [lot_no_2]
	--		, [lot_no_3]
	--		, [lot_no_4]
	--		, [lot_no_5]
	--		, [lot_no_6]
	--		, [lot_no_7]
	--		, [lot_no_8]
	--		, [lot_no_9]
	--		, [lot_no_10]
	--		, [device_name_1]
	--		, [device_name_2]
	--		, [device_name_3]
	--		, [device_name_4]
	--		, [device_name_5]
	--		, [device_name_6]
	--		, [device_name_7]
	--		, [device_name_8]
	--		, [device_name_9]
	--		, [device_name_10]
	--		, [lot_no_1_startdate]
	--		, [lot_no_1_enddate]
	--		, [location_id_lot_no_2]
	--		, [lot_no_change]
	--		, [device_name_change]
	--		, [job_id]
	--		, [created_at]
	--		, [created_by]
	--		, [updated_at]
	--		, [updated_by] )
	--	SELECT [machine].[id] AS [machine_id]
	--		--, [machine].[name] AS [machine_name]
	--		, IIF([machine].[lot_id] IS NULL,'Wait','Run') AS [status_state]
	--		, 'WB' AS [process]
	--		, [lot_no_1]
	--		, [lot_no_2]
	--		, [lot_no_3]
	--		, [lot_no_4]
	--		, [lot_no_5]
	--		, [lot_no_6]
	--		, [lot_no_7]
	--		, [lot_no_8]
	--		, [lot_no_9]
	--		, [lot_no_10]
	--		, [device_name_1]
	--		, [device_name_2]
	--		, [device_name_3]
	--		, [device_name_4]
	--		, [device_name_5]
	--		, [device_name_6]
	--		, [device_name_7]
	--		, [device_name_8]
	--		, [device_name_9]
	--		, [device_name_10]
	--		, NULL AS [lot_no_1_startdate]
	--		, NULL AS [lot_no_1_enddate]
	--		, [data_location].[location_2] AS [location_id_lot_no_2]
	--		, NULL AS [lot_no_change]
	--		, NULL AS [device_name_change]
	--		, [data_flow].[flow_1] AS [job_id]
	--		, GETDATE() AS [created_at]
	--		, 1 AS [created_by]
	--		, NULL AS [updated_at]
	--		, NULL AS [updated_by]
	--	FROM [APCSProDWH].[rans].[machine_state_ps] AS [machine]
	--	LEFT JOIN (
	--		SELECT [machine_id]
	--			, [1] AS [lot_no_1]
	--			, [2] AS [lot_no_2]
	--			, [3] AS [lot_no_3]
	--			, [4] AS [lot_no_4]
	--			, [5] AS [lot_no_5]
	--			, [6] AS [lot_no_6]
	--			, [7] AS [lot_no_7]
	--			, [8] AS [lot_no_8]
	--			, [9] AS [lot_no_9]
	--			, [10]  AS [lot_no_10]
	--		FROM (
	--			SELECT [machine_id] ,[lot_no] ,[number] FROM @lot_run
	--		) AS [dd1]
	--		PIVOT (
	--			MAX([lot_no]) FOR [number] IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
	--		) AS [dd2]
	--	) AS [data_lot] ON [machine].[id] = [data_lot].[machine_id]
	--	LEFT JOIN (
	--		SELECT [machine_id]
	--			, [1] AS [device_name_1]
	--			, [2] AS [device_name_2]
	--			, [3] AS [device_name_3]
	--			, [4] AS [device_name_4]
	--			, [5] AS [device_name_5]
	--			, [6] AS [device_name_6]
	--			, [7] AS [device_name_7]
	--			, [8] AS [device_name_8]
	--			, [9] AS [device_name_9]
	--			, [10] AS [device_name_10]
	--		FROM (
	--			SELECT [machine_id] ,[ft_device] ,[number] FROM @lot_run
	--		) AS [dd1]
	--		PIVOT (
	--			MAX([ft_device]) FOR [number] IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
	--		) AS [dd2]
	--	) AS [data_device] ON [machine].[id] = [data_device].[machine_id]
	--	LEFT JOIN (
	--		SELECT [machine_id]
	--			, [1] AS [flow_1]
	--		FROM (
	--			SELECT [machine_id] ,[job_id] ,[number] FROM @lot_run
	--		) AS [dd1]
	--		PIVOT (
	--			MAX([job_id]) FOR [number] IN ([1])
	--		) AS [dd2]
	--	) AS [data_flow] ON [machine].[id] = [data_flow].[machine_id]
	--	LEFT JOIN (
	--		SELECT [machine_id]
	--			, [2] AS [location_2]
	--		FROM (
	--			SELECT [machine_id] ,[location_id] ,[number] FROM @lot_run
	--		) AS [dd1]
	--		PIVOT (
	--			MAX([location_id]) FOR [number] IN ([2])
	--		) AS [dd2]
	--	) AS [data_location] ON [machine].[id] = [data_location].[machine_id];

	--	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> insert table APCSProDWH.rans.lot_wip_plans WB <---- ');
	--END
	--ELSE
	--BEGIN
	--	DELETE FROM [APCSProDWH].[rans].[lot_wip_plans] WHERE [process] = 'WB';
	--	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> delete table APCSProDWH.rans.lot_wip_plans WP <---- ');

	--	INSERT INTO [APCSProDWH].[rans].[lot_wip_plans]
	--		( [machine_id]
	--		, [status_state]
	--		, [process]
	--		, [lot_no_1]
	--		, [lot_no_2]
	--		, [lot_no_3]
	--		, [lot_no_4]
	--		, [lot_no_5]
	--		, [lot_no_6]
	--		, [lot_no_7]
	--		, [lot_no_8]
	--		, [lot_no_9]
	--		, [lot_no_10]
	--		, [device_name_1]
	--		, [device_name_2]
	--		, [device_name_3]
	--		, [device_name_4]
	--		, [device_name_5]
	--		, [device_name_6]
	--		, [device_name_7]
	--		, [device_name_8]
	--		, [device_name_9]
	--		, [device_name_10]
	--		, [lot_no_1_startdate]
	--		, [lot_no_1_enddate]
	--		, [location_id_lot_no_2]
	--		, [lot_no_change]
	--		, [device_name_change]
	--		, [job_id]
	--		, [created_at]
	--		, [created_by]
	--		, [updated_at]
	--		, [updated_by] )
	--	SELECT [machine].[id] AS [machine_id]
	--		--, [machine].[name] AS [machine_name]
	--		, IIF([machine].[lot_id] IS NULL,'Wait','Run') AS [status_state]
	--		, 'WB' AS [process]
	--		, NULL AS [lot_no_1]
	--		, NULL AS [lot_no_2]
	--		, NULL AS [lot_no_3]
	--		, NULL AS [lot_no_4]
	--		, NULL AS [lot_no_5]
	--		, NULL AS [lot_no_6]
	--		, NULL AS [lot_no_7]
	--		, NULL AS [lot_no_8]
	--		, NULL AS [lot_no_9]
	--		, NULL AS [lot_no_10]
	--		, NULL AS [device_name_1]
	--		, NULL AS [device_name_2]
	--		, NULL AS [device_name_3]
	--		, NULL AS [device_name_4]
	--		, NULL AS [device_name_5]
	--		, NULL AS [device_name_6]
	--		, NULL AS [device_name_7]
	--		, NULL AS [device_name_8]
	--		, NULL AS [device_name_9]
	--		, NULL AS [device_name_10]
	--		, NULL AS [lot_no_1_startdate]
	--		, NULL AS [lot_no_1_enddate]
	--		, NULL AS [location_id_lot_no_2]
	--		, NULL AS [lot_no_change]
	--		, NULL AS [device_name_change]
	--		, NULL AS [job_id]
	--		, GETDATE() AS [created_at]
	--		, 1 AS [created_by]
	--		, NULL AS [updated_at]
	--		, NULL AS [updated_by]
	--	FROM [APCSProDWH].[rans].[machine_state_ps] AS [machine];

	--	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> insert table APCSProDWH.rans.lot_wip_plans WB <---- ');
	--END
	--PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> end <---- ');
	-------------------------------------------------------------------------------------------------------------------
	-------- version 2
	-------------------------------------------------------------------------------------------------------------------
	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> start <---- ');
	
	DECLARE @count_mc INT

	SELECT @count_mc = COUNT([id]) FROM [APCSProDWH].[rans].[machine_state_ps]
	WHERE online_state = 1;

	-------------------------------------------------------------------
	DECLARE @tb_lot_out TABLE(
		[lot_id] int
		, [number] int
	)

	INSERT INTO @tb_lot_out (lot_id, number)
	SELECT [lot_id], 1
	FROM [APCSProDWH].[rans].[machine_state_ps]
	WHERE [online_state] = 1 AND [lot_id] IS NOT NULL;

	INSERT INTO @tb_lot_out (lot_id, number)
	SELECT [lot_id2], 2
	FROM [APCSProDWH].[rans].[machine_state_ps]
	WHERE [online_state] = 1 AND [lot_id2] IS NOT NULL;

	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> insert lot in station <---- ');

	DECLARE @lot_run TABLE
	(
		[lot_no] varchar(10)
		, [job_id] INT
		, [ft_device] VARCHAR(30)
		, [package_name] VARCHAR(30)
		, [location_id] int
		, [location_name] varchar(20)
		, [address] varchar(20)
		, [priority] int
		, [date_at] datetime
		, [machine_id] INT
		, [machine_name] varchar(20)
		, [number] int
	)

	INSERT INTO @lot_run
	SELECT [data_total].[lot_no]
		, [data_total].[job_id]
		, [device_names].[ft_name] AS [ft_device]
		, [packages].[name] AS [package_name]
		, [data_total].[location_id]
		, [data_total].[location_name]
		, [data_total].[address]
		, [data_total].[priority]
		, [data_total].[date_at]
		, [machine].[machine_id]
		, [machine].[machine_name]
		, ROW_NUMBER() OVER (PARTITION BY [machine].[machine_name] ORDER BY [data_total].[machine_id] ASC, [data_total].[priority] DESC, [data_total].[date_at] ASC) AS [number]
	FROM (
		SELECT [data_2].[id]
			, [data_2].[lot_no]
			, [data_2].[job_id]
			, [data_2].[location_id]
			, [data_2].[location_name]
			, [data_2].[address]
			, [data_2].[priority]
			, [data_2].[date_at]
			, [data_2].[row]
			, LAG([data_2].[row],1,0) OVER (ORDER BY [priority] DESC, [data_2].[date_at] ASC) + 1  AS [machine_id]
		FROM (
			SELECT [id]
				, [lot_no]
				, [job_id]
				, [location_id]
				, [location_name]
				, [address]
				, [priority]
				, [date_at]
				, [machine_id]
				, (ROW_NUMBER() OVER (ORDER BY [priority] DESC, [date_at]) % @count_mc) AS [row]
			FROM (
				SELECT [lots].[id]
					, [lots].[lot_no]
					, IIF([lots].[is_special_flow] = 1,[job2].[id],[jobs].[id]) AS [job_id]
					, IIF([lots].[is_special_flow] = 1,[job2].[name],[jobs].[name]) AS [job_name]
					, [lots].[process_state]
					, [lots].[location_id]
					, [rack_controls].[name] AS [location_name] 
					, [rack_addresses].[address]
					, [lots].[priority]
					, [rack_addresses].updated_at AS [date_at] 
					--, [rcs_current_locations].[updated_at] AS [date_at] 
					--, IIF([lots].[lot_no]='2308A3490V',100,[lots].[priority]) AS [priority]
					, NULL AS [machine_id]
				FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) 
				INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
				INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
				INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
				INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
				INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
				INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
					AND [device_flows].[step_no] = [lots].[step_no]
				INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
				INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
				LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lots].[special_flow_id] 
					AND [lots].[is_special_flow] = 1
				LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id] 
					AND  [special_flows].[step_no] = [lot_special_flows].[step_no]
				LEFT JOIN [APCSProDB].[method].[jobs] AS [job2] WITH (NOLOCK) ON [job2].[id] = [lot_special_flows].[job_id]
				LEFT JOIN [APCSProDB].[method].[processes] AS [processes2] WITH (NOLOCK) ON [processes2].[id] = [job2].[process_id]
				
				LEFT JOIN [APCSProDB].[rcs].[rack_addresses] WITH (NOLOCK) ON [lots].[location_id] = [rack_addresses].[id]
				LEFT JOIN [APCSProDB].[rcs].[rack_controls] WITH (NOLOCK) ON [rack_addresses].[rack_control_id] = [rack_controls].[id]

				WHERE [lots].[wip_state] = 20
					AND (IIF([lots].[is_special_flow] = 1,[job2].[name],[jobs].[name]) = 'WB')
					AND [lots].[process_state] IN (2,102)
					AND [lots].[location_id] IS NOT NULL
					AND [rack_controls].name LIKE 'PS%'
					AND [lots].[id] NOT IN (SELECT [lot_id] FROM @tb_lot_out)  
			) AS [data_1]
		) AS [data_2]
	) AS [data_total]
	INNER JOIN (
		SELECT (ROW_NUMBER() OVER (ORDER BY [name] ASC)) AS [id]
			, [id] AS [machine_id]
			, [name] AS [machine_name]
		FROM [APCSProDWH].[rans].[machine_state_ps]
		WHERE [online_state] = 1
	) AS [machine] ON [data_total].[machine_id] = [machine].[id]
	INNER JOIN [APCSProDB].[trans].[lots] WITH (NOLOCK) ON [data_total].[id] = [lots].[id]
	INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [lots].[act_device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
	ORDER BY [data_total].[machine_id] ASC, [data_total].[priority] DESC, [data_total].[date_at] ASC;

	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> insert lot plan <---- ');

	IF EXISTS(SELECT TOP 1 machine_id FROM @lot_run)
	BEGIN
		DELETE FROM [APCSProDWH].[rans].[lot_wip_plans_01] WHERE [process] = 'WB';
		PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> delete table APCSProDWH.rans.lot_wip_plans WP <---- ');
		
		INSERT INTO [APCSProDWH].[rans].[lot_wip_plans_01]
			( [machine_id]
			, [status_state]
			, [process]
			, [lot_no_1]
			, [lot_no_2]
			, [lot_no_3]
			, [lot_no_4]
			, [lot_no_5]
			, [lot_no_6]
			, [lot_no_7]
			, [lot_no_8]
			, [lot_no_9]
			, [lot_no_10]
			, [device_name_1]
			, [device_name_2]
			, [device_name_3]
			, [device_name_4]
			, [device_name_5]
			, [device_name_6]
			, [device_name_7]
			, [device_name_8]
			, [device_name_9]
			, [device_name_10]
			, [lot_no_1_startdate]
			, [lot_no_1_enddate]
			, [location_id_lot_no_2]
			, [lot_no_change]
			, [device_name_change]
			, [job_id]
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by] )
		SELECT [machine].[id] AS [machine_id]
			--, [machine].[name] AS [machine_name]
			, IIF([machine].[lot_id] IS NOT NULL OR [machine].[lot_id2] IS NOT NULL,'Run','Wait') AS [status_state]
			, 'WB' AS [process]
			, NULL AS [lot_no_1]
			, [lot_no_2]
			, [lot_no_3]
			, [lot_no_4]
			, [lot_no_5]
			, [lot_no_6]
			, [lot_no_7]
			, [lot_no_8]
			, [lot_no_9]
			, [lot_no_10]
			, NULL AS [device_name_1]
			, [device_name_2]
			, [device_name_3]
			, [device_name_4]
			, [device_name_5]
			, [device_name_6]
			, [device_name_7]
			, [device_name_8]
			, [device_name_9]
			, [device_name_10]
			, NULL AS [lot_no_1_startdate]
			, NULL AS [lot_no_1_enddate]
			, [data_location].[location_2] AS [location_id_lot_no_2]
			, NULL AS [lot_no_change]
			, NULL AS [device_name_change]
			, NULL AS [job_id]
			, GETDATE() AS [created_at]
			, 1 AS [created_by]
			, NULL AS [updated_at]
			, NULL AS [updated_by]
		FROM [APCSProDWH].[rans].[machine_state_ps] AS [machine]
		--OUTER APPLY (
		--	SELECT [lots].[lot_no]
		--		, [device_names].[name] AS [device_name]
		--		, IIF([lots].[is_special_flow] = 1, [job2].[id], [jobs].[id]) AS [job_id]
		--	FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		--	INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [lots].[act_device_name_id]
		--	INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
		--		AND [device_flows].[step_no] = [lots].[step_no]
		--	INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
		--	LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lots].[special_flow_id] 
		--		AND [lots].[is_special_flow] = 1
		--	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id] 
		--		AND  [special_flows].[step_no] = [lot_special_flows].[step_no]
		--	LEFT JOIN [APCSProDB].[method].[jobs] AS [job2] WITH (NOLOCK) ON [job2].[id] = [lot_special_flows].[job_id]
		--	WHERE [lots].[id] = [machine].[lot_id]
		--) AS [lot_pro]
		LEFT JOIN (
			SELECT [machine_id]
				, NULL AS [lot_no_1]
				, [1] AS [lot_no_2]
				, [2] AS [lot_no_3]
				, [3] AS [lot_no_4]
				, [4] AS [lot_no_5]
				, [5] AS [lot_no_6]
				, [6] AS [lot_no_7]
				, [7] AS [lot_no_8]
				, [8] AS [lot_no_9]
				, [9]  AS [lot_no_10]
			FROM (
				SELECT [machine_id] ,[lot_no] ,[number] FROM @lot_run
			) AS [dd1]
			PIVOT (
				MAX([lot_no]) FOR [number] IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
			) AS [dd2]
		) AS [data_lot] ON [machine].[id] = [data_lot].[machine_id]
		LEFT JOIN (
			SELECT [machine_id]
				, NULL AS [device_name_1]
				, [1] AS [device_name_2]
				, [2] AS [device_name_3]
				, [3] AS [device_name_4]
				, [4] AS [device_name_5]
				, [5] AS [device_name_6]
				, [6] AS [device_name_7]
				, [7] AS [device_name_8]
				, [8] AS [device_name_9]
				, [9] AS [device_name_10]
			FROM (
				SELECT [machine_id] ,[ft_device] ,[number] FROM @lot_run
			) AS [dd1]
			PIVOT (
				MAX([ft_device]) FOR [number] IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
			) AS [dd2]
		) AS [data_device] ON [machine].[id] = [data_device].[machine_id]
		LEFT JOIN (
			SELECT [machine_id]
				, [1] AS [location_2]
			FROM (
				SELECT [machine_id] ,[location_id] ,[number] FROM @lot_run
			) AS [dd1]
			PIVOT (
				MAX([location_id]) FOR [number] IN ([1])
			) AS [dd2]
		) AS [data_location] ON [machine].[id] = [data_location].[machine_id];

		PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> insert table APCSProDWH.rans.lot_wip_plans WB <---- ');
	END
	ELSE
	BEGIN
		DELETE FROM [APCSProDWH].[rans].[lot_wip_plans_01] WHERE [process] = 'WB';
		PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> delete table APCSProDWH.rans.lot_wip_plans WP <---- ');

		INSERT INTO [APCSProDWH].[rans].[lot_wip_plans_01]
			( [machine_id]
			, [status_state]
			, [process]
			, [lot_no_1]
			, [lot_no_2]
			, [lot_no_3]
			, [lot_no_4]
			, [lot_no_5]
			, [lot_no_6]
			, [lot_no_7]
			, [lot_no_8]
			, [lot_no_9]
			, [lot_no_10]
			, [device_name_1]
			, [device_name_2]
			, [device_name_3]
			, [device_name_4]
			, [device_name_5]
			, [device_name_6]
			, [device_name_7]
			, [device_name_8]
			, [device_name_9]
			, [device_name_10]
			, [lot_no_1_startdate]
			, [lot_no_1_enddate]
			, [location_id_lot_no_2]
			, [lot_no_change]
			, [device_name_change]
			, [job_id]
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by] )
		SELECT [machine].[id] AS [machine_id]
			--, [machine].[name] AS [machine_name]
			, IIF([machine].[lot_id] IS NOT NULL OR [machine].[lot_id2] IS NOT NULL,'Run','Wait') AS [status_state]
			, 'WB' AS [process]
			, NULL AS [lot_no_1]
			, NULL AS [lot_no_2]
			, NULL AS [lot_no_3]
			, NULL AS [lot_no_4]
			, NULL AS [lot_no_5]
			, NULL AS [lot_no_6]
			, NULL AS [lot_no_7]
			, NULL AS [lot_no_8]
			, NULL AS [lot_no_9]
			, NULL AS [lot_no_10]
			, NULL AS [device_name_1]
			, NULL AS [device_name_2]
			, NULL AS [device_name_3]
			, NULL AS [device_name_4]
			, NULL AS [device_name_5]
			, NULL AS [device_name_6]
			, NULL AS [device_name_7]
			, NULL AS [device_name_8]
			, NULL AS [device_name_9]
			, NULL AS [device_name_10]
			, NULL AS [lot_no_1_startdate]
			, NULL AS [lot_no_1_enddate]
			, NULL AS [location_id_lot_no_2]
			, NULL AS [lot_no_change]
			, NULL AS [device_name_change]
			, NULL AS [job_id]
			, GETDATE() AS [created_at]
			, 1 AS [created_by]
			, NULL AS [updated_at]
			, NULL AS [updated_by]
		FROM [APCSProDWH].[rans].[machine_state_ps] AS [machine];
		--OUTER APPLY (
		--	SELECT [lots].[lot_no]
		--		, [device_names].[name] AS [device_name]
		--		, IIF([lots].[is_special_flow] = 1, [job2].[id], [jobs].[id]) AS [job_id]
		--	FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		--	INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [lots].[act_device_name_id]
		--	INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
		--		AND [device_flows].[step_no] = [lots].[step_no]
		--	INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
		--	LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lots].[special_flow_id] 
		--		AND [lots].[is_special_flow] = 1
		--	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id] 
		--		AND  [special_flows].[step_no] = [lot_special_flows].[step_no]
		--	LEFT JOIN [APCSProDB].[method].[jobs] AS [job2] WITH (NOLOCK) ON [job2].[id] = [lot_special_flows].[job_id]
		--	WHERE [lots].[id] = [machine].[lot_id]
		--) AS [lot_pro];

		PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> insert table APCSProDWH.rans.lot_wip_plans WB <---- ');
	END
	-------------------------------------------------------------------------------------------------------------------
END
