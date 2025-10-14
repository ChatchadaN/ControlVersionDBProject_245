-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rans].[sp_set_scheduler_temp_mp] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-------------------------------------------------------------------------------------------------------------------
	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> start <---- ');
	---- machine_register
	DECLARE @GetCompareMcRack TABLE 
	(
		[machine_id] INT
		, [machine_name] VARCHAR(20)
		, [location_id] INT
		, [location_name] VARCHAR(20)
		, [location_address] VARCHAR(20)
	)

	---- get machine
	DECLARE @GetMachine TABLE 
	(
		[machine_id] INT
		, [machine_name] VARCHAR(20)
	)

	DECLARE @GetMachine2 TABLE 
	(
		[machine_id] INT
		, [machine_name] VARCHAR(20)
		, [column] VARCHAR(20)
		, [lot_no] VARCHAR(20)
	)
	---- get location
	DECLARE @GetLocation TABLE 
	(
		[location_id] INT
		, [location_name] VARCHAR(20)
		, [location_address] VARCHAR(20)
	)

	DECLARE @GetSetupMc TABLE 
	(
		[package_id] INT
		, [package_name] VARCHAR(20)
		, [machine_id] INT
		, [machine_name] VARCHAR(20)
		, [jig_name] VARCHAR(20)
		, [online_state] INT
	)

	DECLARE @TableTempLot TABLE 
	(
		[lot_no] VARCHAR(20),
		[flow] VARCHAR(20),
		[ft_device] VARCHAR(30),
		[location_id] INT,
		[machine_id] INT,
		[seq_no] INT,
		[package_name] VARCHAR(30),
		[lot_start] DATETIME,
		[lot_end] DATETIME
	)

	---- machine_register
	INSERT INTO @GetCompareMcRack
	SELECT [machine_location_settings].[machine_id]
		, [machines].[name]
		, [machine_location_settings].[location_id]
		, [locations].[name]
		, [locations].[address]
	FROM [APCSProDWH].[rans].[machine_location_settings]
	LEFT JOIN [APCSProDB].[trans].[locations] ON [machine_location_settings].[location_id] = [locations].[id]
	LEFT JOIN [APCSProDB].[mc].[machines] ON [machine_location_settings].[machine_id] = [machines].[id];

	---- get machine
	INSERT INTO @GetMachine
	SELECT [machine_id]
		, [machine_name] 
	FROM @GetCompareMcRack
	GROUP BY [machine_id], [machine_name];

	---- get location
	INSERT INTO @GetLocation
	SELECT [location_id]
		, [location_name] 
		, [location_address]
	FROM @GetCompareMcRack
	GROUP BY [location_id], [location_name], [location_address]; 

	---- debbbug select data
	--SELECT * FROM @GetCompareMcRack AS [machine_registers];
	--SELECT * FROM @GetMachine AS [machines];
	--SELECT * FROM @GetLocation AS [locations];


	---- get machine used by set kanakata
	INSERT INTO @GetSetupMc
	SELECT 	[packages].[id] AS [packages_id]
		, [packages].[name] AS [package_name] 
		, [machines].[machine_id] AS [machine_id]
		, [machines].[machine_name] AS [machine_name]
		, [categories].[short_name] AS [jig_name] 
		--, [categories].[name]
		--, [productions].[name]
		, [machine_states].[online_state]
	FROM @GetMachine AS [machines]  
	INNER JOIN [APCSProDB].[trans].[machine_jigs] WITH (NOLOCK) ON [machines].[machine_id] = [machine_jigs].[machine_id]
	INNER JOIN [APCSProDB].[trans].[jigs] WITH (NOLOCK) ON [machine_jigs].[jig_id] = [jigs].[id]
	INNER JOIN [APCSProDB].[method].[jig_set_list] WITH (NOLOCK)  ON [jigs].[jig_production_id] = [jig_set_list].[jig_group_id]
	INNER JOIN [APCSProDB].[jig].[productions] WITH (NOLOCK) ON [jig_set_list].[jig_group_id] = [productions].[id]
	INNER JOIN [APCSProDB].[jig].[categories] WITH (NOLOCK) ON [productions].[category_id] = [categories].[id]
	INNER JOIN [APCSProDB].[method].[jig_sets] WITH (NOLOCK) ON [jig_set_list].[jig_set_id] = [jig_sets].[id]
	INNER JOIN @GetCompareMcRack AS [machine_location_settings] ON [machines].[machine_id] = [machine_location_settings].[machine_id] --- Machine Register Rack_location
	INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[short_name] = [jig_sets].[name]
	INNER JOIN [APCSProDB].[trans].[machine_states] WITH (NOLOCK) ON [machines].[machine_id] = [machine_states].[machine_id]
	WHERE [categories].[short_name] = 'Kanagata'
		AND [machine_states].[online_state] = 1
	GROUP BY [machines].[machine_id]
		, [machines].[machine_name]
		, [packages].[id]
		, [packages].[name]
		, [categories].[short_name]
		, [machine_states].[online_state]
	ORDER BY [machines].[machine_name];
	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> get machine used by set kanakata <---- ');

	---- debbbug select data
	--SELECT * FROM @GetSetupMc ORDER BY [machine_name];

	---- set lot
	---- set lot run seq_no = 1
	INSERT INTO @TableTempLot
	SELECT [Data_q1].[lot_no]
		, [Data_q1].[flow]
		, [Data_q1].[ft_device]
		, [Data_q1].[location_id]
		, [Data_q1].[machine_id]
		, [Data_q1].[seq_no]
		, [Data_q1].[package_name]
		, [Data_q1].[lot_start]
		, DATEADD(MINUTE, ([Data_q1].[process_minutes] * (CAST([Data_q1].[qty_in] AS FLOAT)/CAST([Data_q1].[official_number] AS FLOAT))), [Data_q1].[lot_start]) AS [lot_end]
		--, [process_minutes]
		--, [official_number]
		--, [qty_in]
	FROM (
		SELECT [lots].[lot_no]
			, IIF([lots].[is_special_flow] = 1,[lot_special_flows].[job_id],[lots].[act_job_id]) AS [flow]
			, [device_names].[ft_name] AS [ft_device]
			, '' AS [location_id]
			, [lots].[machine_id]
			, 1 AS [seq_no]
			, [packages].[name] AS [package_name]
			, [lot_process_records].[recorded_at] AS [lot_start]
			--, DATEADD(MINUTE, ([device_flows].[process_minutes] * (CAST([lots].[qty_in] AS FLOAT)/CAST([device_names].[official_number] AS FLOAT))), [lot_process_records].[recorded_at]) AS [lot_end]
			, ROW_NUMBER() OVER (PARTITION BY [lots].[lot_no] ORDER BY [lot_process_records].[id] DESC) AS [max_row]
			, [device_flows].[process_minutes]
			, [device_names].[official_number]
			, [lots].[qty_in]
		--FROM [StoredProcedureDB].[trans].[lots]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) 
		INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [lots].[act_job_id]
		INNER JOIN [APCSProDB].[mc].[machines] WITH (NOLOCK) ON [machines].[id] = [lots].[machine_id]
		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [lots].[act_package_id]
		INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [lots].[act_device_name_id] = [device_names].[id]
		INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
			AND [device_flows].[step_no] = [lots].[step_no]
		LEFT JOIN [APCSProDB].[trans].[days] WITH (NOLOCK) ON [days].[id] = [lots].[modify_out_plan_date_id]
		LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [lots].[is_special_flow] = 1
			AND [lots].[id] = [special_flows].[lot_id]
			AND [lots].[special_flow_id] = [special_flows].[id]
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
			AND [special_flows].[step_no] = [lot_special_flows].[step_no]
		LEFT JOIN [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK) ON [lots].[id] = [lot_process_records].[lot_id]
			AND [lot_process_records].[step_no] = IIF([lots].[is_special_flow] = 1 AND [lot_special_flows].[job_id] = 29,[lot_special_flows].[step_no],[lots].[step_no])
			AND [lot_process_records].[record_class] IN (1,5)
		WHERE ((([lots].[is_special_flow] = 0 OR [lots].[is_special_flow] IS NULL) AND [lots].[act_job_id] = 29) 
				OR ([lots].[is_special_flow] = 1 AND [lot_special_flows].[job_id] = 29)) -- 29 : Flow MP 
			AND ((([lots].[is_special_flow] = 0 OR [lots].[is_special_flow] IS NULL) AND [lots].[process_state] IN (2,102)) 
				OR ([lots].[is_special_flow] = 1 AND [special_flows].[process_state] IN (2,102))) -- process_state 2:Processing , 102 : Abnormal Start
			AND [lots].[wip_state] = 20 
			AND [lots].[quality_state] <> 3 -- quality_state 3 : Hold
	) AS [Data_q1]
	WHERE [Data_q1].[max_row] = 1
	UNION ALL
	---- set lot wip seq_no between 2 and 10
	SELECT [lots].[lot_no]
		, IIF([lots].[is_special_flow] = 1,[lot_special_flows].[job_id],[lots].[act_job_id]) AS [flow]
		, [device_names].[ft_name] AS [ft_device]
		, [locations].[location_id]
		, [machine_registers].[machine_id]
		, (ROW_NUMBER() OVER (PARTITION BY [machine_registers].[machine_name],[locations].[location_name] ORDER BY [lots].[priority] DESC, [lots].[lot_no] ASC) + 1) AS [seq_no]
		, [machine_registers].[package_name]
		, NULL AS [lot_start]
		, NULL AS [lot_end]
	FROM @GetSetupMc AS [machine_registers]
	INNER JOIN @GetCompareMcRack AS [machine_location_settings] ON [machine_registers].[machine_id] = [machine_location_settings].[machine_id]
	INNER JOIN @GetLocation AS [locations] ON [machine_location_settings].[location_id] = [locations].[location_id]
	--INNER JOIN [StoredProcedureDB].[trans].[lots] ON [locations].[location_id] = [lots].[location_id]
	--	AND [lots].[act_package_id] = [machine_registers].[package_id]
	INNER JOIN [APCSProDB].[trans].[lots] WITH (NOLOCK) ON [locations].[location_id] = [lots].[location_id]
		AND [lots].[act_package_id] = [machine_registers].[package_id]
	INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [lots].[act_device_name_id] = [device_names].[id]
	LEFT JOIN [APCSProDB].[trans].[days] WITH (NOLOCK) ON [days].[id] = [lots].[modify_out_plan_date_id]
	LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [lots].[is_special_flow] = 1
		AND [lots].[id] = [special_flows].[lot_id]
		AND [lots].[special_flow_id] = [special_flows].[id]
	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
		AND [special_flows].[step_no] = [lot_special_flows].[step_no]
	WHERE ((([lots].[is_special_flow] = 0 OR [lots].[is_special_flow] IS NULL) AND [lots].[act_job_id] = 29) 
			OR ([lots].[is_special_flow] = 1 AND [lot_special_flows].[job_id] = 29)) -- 29 : Flow MP
		AND ((([lots].[is_special_flow] = 0 OR [lots].[is_special_flow] IS NULL) AND [lots].[process_state] = 0) 
			OR ([lots].[is_special_flow] = 1 AND [special_flows].[process_state] = 0));
	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> set lot seq_no between 1 and 10 <---- ');

	---- debbbug select data
	--SELECT * FROM @TableTempLot ORDER BY [machine_id],[seq_no];

	---- debbbug condition test
	--DELETE FROM @TableTempLot WHERE lot_no = '2302A6319V';
	--DELETE FROM @TableTempLot WHERE seq_no BETWEEN 2 AND 5;

	IF EXISTS(SELECT TOP 1 machine_id FROM @TableTempLot)
	BEGIN
		DELETE FROM [APCSProDWH].[rans].[lot_wip_plans] WHERE [process] = 'MP';
		PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> delete table APCSProDWH.rans.lot_wip_plans <---- ');

		INSERT INTO [APCSProDWH].[rans].[lot_wip_plans]
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
		SELECT [get_machines].[machine_id]
			--, [machines].[name] -- comment select
			--, [machine_states].[online_state] -- comment select
			, CASE
				WHEN [lot_no_1] != '' THEN 'Run'
				ELSE 'Wait' 
			END AS [status_state]
			, 'MP'
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
			, [lot_start] AS [lot_no_1_startdate]
			, [lot_end] AS [lot_no_1_enddate]
			, [location_id_lot_no_2]
			, NULL AS [lot_no_change]
			, NULL AS [device_name_change]
			, [flow] AS [job_id]
			, GETDATE() AS [created_at]
			, 1 AS [created_by]
			, NULL AS [updated_at]
			, NULL AS [updated_by]
		---- machine register
		FROM @GetMachine AS [get_machines]
		--LEFT JOIN [APCSProDB].[mc].[machines] ON [get_machines].[machine_id] = [machines].[id]
		--LEFT JOIN [APCSProDB].[trans].[machine_states] ON [machines].[id] = [machine_states].[machine_id]
		---- lot_no
		LEFT JOIN (
			SELECT machine_id
				, [1] AS [lot_no_1]
				, [2] AS [lot_no_2]
				, [3] AS [lot_no_3]
				, [4] AS [lot_no_4]
				, [5] AS [lot_no_5]
				, [6] AS [lot_no_6]
				, [7] AS [lot_no_7]
				, [8] AS [lot_no_8]
				, [9] AS [lot_no_9]
				, [10] AS [lot_no_10]
			FROM (
				SELECT machine_id, lot_no, seq_no
				FROM @TableTempLot AS [TempLot]
			) AS T1
			PIVOT
			(
				MAX(lot_no) FOR [seq_no] IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
			) AS T2
		) AS [lot_no] ON [get_machines].[machine_id] = [lot_no].[machine_id]
		---- device name
		LEFT JOIN (
			SELECT machine_id
				, [1] AS [device_name_1]
				, [2] AS [device_name_2]
				, [3] AS [device_name_3]
				, [4] AS [device_name_4]
				, [5] AS [device_name_5]
				, [6] AS [device_name_6]
				, [7] AS [device_name_7]
				, [8] AS [device_name_8]
				, [9] AS [device_name_9]
				, [10] AS [device_name_10]
			FROM (
				SELECT machine_id, ft_device, seq_no
				FROM @TableTempLot AS [TempLot]
			) AS T1
			PIVOT
			(
				MAX(ft_device) FOR [seq_no] IN ([1],[2],[3],[4],[5],[6],[7],[8],[9],[10])
			) AS T2
		) AS [device] ON [lot_no].[machine_id] = [device].[machine_id]
		---- location lot_no_2
		LEFT JOIN (
			SELECT machine_id
				, [2] AS [location_id_lot_no_2]
			FROM (
				SELECT machine_id, location_id, seq_no
				FROM @TableTempLot AS [TempLot]
			) AS T1
			PIVOT
			(
				MAX(location_id) FOR [seq_no] IN ([2])
			) AS T2
		) AS [rack] ON [device].[machine_id] = [rack].[machine_id]
		---- job lot_no_1
		LEFT JOIN (
			SELECT machine_id
				, [1] AS [flow]
			FROM (
				SELECT machine_id, flow, seq_no
				FROM @TableTempLot AS [TempLot]
			) AS T1
			PIVOT
			(
				MAX(flow) FOR [seq_no] IN ([1])
			) AS T2
		) AS [job] ON [job].[machine_id] = [lot_no].[machine_id]
		---- lot_start lot_no_1
		LEFT JOIN (
			SELECT machine_id
				, [1] AS [lot_start]
			FROM (
				SELECT machine_id, lot_start, seq_no
				FROM @TableTempLot AS [TempLot]
			) AS T1
			PIVOT
			(
				MAX(lot_start) FOR [seq_no] IN ([1])
			) AS T2
		) AS [date_start] ON [date_start].[machine_id] = [lot_no].[machine_id]
		---- lot_end lot_no_1
		LEFT JOIN (
			SELECT machine_id
				, [1] AS [lot_end]
			FROM (
				SELECT machine_id, lot_end, seq_no
				FROM @TableTempLot AS [TempLot]
			) AS T1
			PIVOT
			(
				MAX(lot_end) FOR [seq_no] IN ([1])
			) AS T2
		) AS [date_end] ON [date_end].[machine_id] = [lot_no].[machine_id];
		--ORDER BY [machines].[id]
		PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> insert table APCSProDWH.rans.lot_wip_plans <---- ');
	END
	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' ----> end <---- ');
	-------------------------------------------------------------------------------------------------------------------
END
