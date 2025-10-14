-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rans].[sp_get_leadtime_mp] 
	-- Add the parameters for the stored procedure here
	@package_name VARCHAR(255) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--DECLARE @package_name VARCHAR(255) = 'SSOP-B20W/B20WA/B20WR1'
	DECLARE @table1 TABLE (package_name VARCHAR(MAX))

	INSERT INTO @table1
	EXEC [StoredProcedureDB].[rans].[sp_get_package mp] @type_id = 2,@package_name = @package_name

	DECLARE @table TABLE (
		[id] INT
		, [lot_no] VARCHAR(10)
		, [seq] INT
		, [jobs_id] INT
		, [jobs_name] VARCHAR(20)
		, [process_id] INT
		, [process_name] VARCHAR(20)
		, [kpcs] INT  
		, [lot_kpcs] INT
		, [standard_time] INT
		, [data_hour] DECIMAL(10,1)
		, [device_name] VARCHAR(20)
		, [package_name] VARCHAR(20)
	)

	DECLARE @table2 TABLE (
		[package_name] VARCHAR(20)
		, [device_name] VARCHAR(20)
		, [process_name] VARCHAR(20)
		, [number] INT
		, [data_hour] DECIMAL(10,1)
		, [data_lot] INT
		, [data_kpcs] INT
	)

	------------ get_data ------------ 
	INSERT INTO @table
	SELECT [id]
		, [lot_no]
		, [seq]
		, [jobs_id]
		, [jobs_name]
		, [process_id]
		, [process_name]
		, [kpcs] 
		, [lot_kpcs]
		, [standard_time]
		, [data_hour]
		, [device_name]
		, [package_name]
	FROM (
		SELECT [lots].[id]
			, [lots].[lot_no]
			, [lots].[updated_at] AS [update_time]
			, [lots].[qty_in] AS [total]
			, [lots].[qty_pass] AS [good]
			, [lots].[qty_fail] AS [ng]
			--, [chk_device_flows].[chk_step_no]
			, IIF([lots].[is_special_flow] = 1,[job2].[seq_no],[jobs].[seq_no]) AS [seq]
			, IIF([lots].[is_special_flow] = 1,[job2].[id],[jobs].[id]) AS [jobs_id]
			, IIF([lots].[is_special_flow] = 1,[job2].[name],[jobs].[name]) AS [jobs_name]
			, IIF([lots].[is_special_flow] = 1,[processes2].[id],[processes].[id]) AS [process_id]
			, IIF([lots].[is_special_flow] = 1,[processes2].[name],[processes].[name]) AS [process_name]
			, ([lots].[qty_in]/1000) AS [kpcs] 
			, [device_names].[official_number] AS [lot_kpcs]
			, [device_flows].[process_minutes] AS [standard_time]
			, ISNULL((([lots].[qty_in] / CAST(5880 AS DECIMAL(10,1))) * ([device_flows].[process_minutes] / CAST(60 AS DECIMAL(10,1))))/CAST(4 AS DECIMAL(10,1)),0) AS [data_hour]
			, [device_names].[name] AS [device_name]
			, [packages].[name] AS [package_name]
		FROM [APCSProDB].[trans].[lots] with (NOLOCK) 
		INNER JOIN [APCSProDB].[method].[device_names] with (NOLOCK) ON [device_names].[id] = [lots].[act_device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] with (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[device_flows] with (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
			AND [device_flows].[step_no] = [lots].[step_no]
		INNER JOIN [APCSProDB].[trans].[days] AS [days1] with (NOLOCK) ON [days1].[id] = [lots].[in_plan_date_id]
		CROSS APPLY (
			SELECT TOP 1 [df].[step_no] AS [chk_step_no]
			FROM [APCSProDB].[method].[device_flows] AS [df] with (NOLOCK)
			LEFT JOIN [APCSProDB].[method].[jobs] AS [j] with (NOLOCK) ON [df].[job_id] = [j].[id]
			WHERE [j].[name] = 'MP'
				AND [df].[device_slip_id] = [lots].[device_slip_id]
		) AS [chk_device_flows]
		LEFT JOIN [APCSProDB].[method].[jobs] with (NOLOCK) ON [jobs].[id] = [lots].[act_job_id]
		LEFT JOIN [APCSProDB].[method].[processes] with (NOLOCK) ON [processes].[id] =	[jobs].[process_id]
		LEFT JOIN [APCSProDB].[trans].[special_flows] with (NOLOCK) ON [lots].[id] = [special_flows].[lot_id]
			AND [lots].[special_flow_id] = [special_flows].[id]
			AND [lots].[is_special_flow] = 1
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id] 
			AND [special_flows].[step_no] = [lot_special_flows].[step_no]
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job2] with (NOLOCK) ON [job2].[id] = [lot_special_flows].[job_id]
		LEFT JOIN [APCSProDB].[method].[processes] AS [processes2] with (NOLOCK) ON [processes2].[id] =	 [job2].[process_id]
		WHERE [lots].[wip_state] = 20
			AND [days1].[date_value] <= CONVERT(DATE, GETDATE())
			AND [jobs].[id] NOT IN (10,55) ---- 10:SAMPLING X RAY, 55:DETAPE
	) AS [data_1]
	WHERE [process_id] in (2,23,3,24,25,4) ----  2:DB, 23:DBcure, 3:WB, 24:PLASMA1, 25:PLASMA2, 4:MP

	------------ order_data ------------
	INSERT INTO @table2
	SELECT [data_1].[package_name]
		, [data_1].[device_name]
		, [data_1].[process_name]
		, [data_1].[number]
		, ISNULL([data_2].[data_hour],0) AS [data_hour]
		, ISNULL([data_lot],0) AS [data_lot]
		, ISNULL([data_kpcs],0) AS [data_kpcs]
	FROM (
		SELECT [package_name]
			, [device_name]
			, [process_name]
			, [number]
		FROM (
			SELECT [package_name]
				, [device_name]
			FROM @table
			GROUP BY [package_name], [device_name]
		) AS [data_1], (
			SELECT [process_name]
				, CASE [process_name]
					WHEN 'DB' THEN 1
					WHEN 'DBcure' THEN 2
					WHEN 'WB' THEN 3
					WHEN 'PLASMA1' THEN 4
					WHEN 'PLASMA2' THEN 5
					WHEN 'MP' THEN 6
				END AS [number]
			FROM @table
			GROUP BY [process_name]
		) AS [data_2]
	) AS [data_1]
	LEFT JOIN (
		SELECT [package_name]
			, [device_name]
			, [process_name]
			, SUM([data_hour]) AS [data_hour]
		FROM @table
		GROUP BY [package_name], [device_name], [process_name]
	) AS [data_2] ON [data_1].[package_name] = [data_2].[package_name]
		AND [data_1].[device_name] = [data_2].[device_name]
		AND [data_1].[process_name] = [data_2].[process_name]
	LEFT JOIN (
		SELECT [package_name]
			, [device_name]
			, [process_name]
			, COUNT([lot_no]) AS [data_lot]
		FROM @table
		GROUP BY [package_name], [device_name], [process_name]
	) AS [data_3] ON [data_1].[package_name] = [data_3].[package_name]
		AND [data_1].[device_name] = [data_3].[device_name]
		AND [data_1].[process_name] = [data_3].[process_name]
	LEFT JOIN (
		SELECT [package_name]
			, [device_name]
			, [process_name]
			, SUM([kpcs]) AS [data_kpcs]
		FROM @table
		GROUP BY [package_name], [device_name], [process_name]
	) AS [data_4] ON [data_1].[package_name] = [data_4].[package_name]
		AND [data_1].[device_name] = [data_4].[device_name]
		AND [data_1].[process_name] = [data_4].[process_name]
	ORDER BY [data_1].[package_name]
		, [data_1].[device_name]
		, [data_1].[number] ASC

	------------ pivot_data ------------
	SELECT[m1].[device_name]
		, [lot].[DB] AS [DB_Lot]
		, [lot].[DBcure] AS [DBcure_Lot]
		, [lot].[WB] AS [WB_Lot]
		, [lot].[PLASMA1] AS [PLASMA1_Lot]
		, [lot].[PLASMA2] AS [PLASMA2_Lot]
		, [lot].[MP] AS [MP_Lot]
		, [hour].[DB] AS [DB_Hour]
		, [hour].[DBcure] AS [DBcure_Hour]
		, [hour].[WB] AS [WB_Hour]
		, [hour].[PLASMA1] AS [PLASMA1_Hour]
		, [hour].[PLASMA2] AS [PLASMA2_Hour]
		, [hour].[MP] AS [MP_Hour]
		, [kpcs].[DB] AS [DB_kpcs]
		, [kpcs].[DBcure] AS [DBcure_kpcs]
		, [kpcs].[WB] AS [WB_kpcs]
		, [kpcs].[PLASMA1] AS [PLASMA1_kpcs]
		, [kpcs].[PLASMA2] AS [PLASMA2_kpcs]
		, [kpcs].[MP] AS [MP_kpcs]
	FROM (
		SELECT [device_name],[package_name]
		FROM @table2
		GROUP BY [device_name],[package_name]
	) AS [m1]
	LEFT JOIN (
		SELECT [device_name]
			, [1] AS [DB]
			, [2] AS [DBcure]
			, [3] AS [WB]
			, [4] AS [PLASMA1]
			, [5] AS [PLASMA2]
			, [6] AS [MP]
		FROM (
			SELECT [device_name],[data_lot],[number]
			FROM @table2
		) AS [main_data]
		PIVOT (
			MAX([main_data].[data_lot]) FOR [main_data].[number] IN ([1],[2],[3],[4],[5],[6])
		) AS [P1]
	) AS [lot] ON [m1].[device_name] = [lot].[device_name]
	LEFT JOIN (
		SELECT [device_name]
			, [1] AS [DB]
			, [2] AS [DBcure]
			, [3] AS [WB]
			, [4] AS [PLASMA1]
			, [5] AS [PLASMA2]
			, [6] AS [MP]
		FROM (
			SELECT [device_name],[data_hour],[number]
			FROM @table2
		) AS [main_data]
		PIVOT (
			MAX([main_data].[data_hour]) FOR [main_data].[number] IN ([1],[2],[3],[4],[5],[6])
		) AS [P1]
	) AS [hour] ON [m1].[device_name] = [hour].[device_name]
	LEFT JOIN (
		SELECT [device_name]
			, [1] AS [DB]
			, [2] AS [DBcure]
			, [3] AS [WB]
			, [4] AS [PLASMA1]
			, [5] AS [PLASMA2]
			, [6] AS [MP]
		FROM (
			SELECT [device_name],[data_kpcs],[number]
			FROM @table2
		) AS [main_data]
		PIVOT (
			MAX([main_data].[data_kpcs]) FOR [main_data].[number] IN ([1],[2],[3],[4],[5],[6])
		) AS [P1]
	) AS [kpcs] ON [m1].[device_name] = [kpcs].[device_name]
	WHERE [m1].[package_name] IN (SELECT value FROM STRING_SPLIT ((SELECT TOP 1 package_name FROM @table1),','))
	ORDER BY [device_name] ASC;	
END
