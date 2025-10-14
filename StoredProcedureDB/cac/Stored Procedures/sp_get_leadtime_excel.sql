-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_leadtime_excel]
	-- Add the parameters for the stored procedure here
	@package_group varchar(50) = '%'	
	, @lot_type varchar(50) = '%'
	, @package varchar(50) = '%'
	, @start_date date = NULL
	, @end_date date = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	--select [package_groups].[name] as [package_groups]
	--	, [packages].[name] as [package]
	--	, [device_names].[name] as [device]
	--	, [lots].[lot_no] as [lot]
	--	, [days1].[date_value] as [in_day]
	--	, DATEDIFF(DAY,[days2].[date_value],GETDATE()) as [delay_day]
	--	, [lots].[qty_in] as [pieces]
	--	, [processes].[name] as [process]
	--	, [jobs].[name] as [job]
	--	--, [device_flows].[step_no]
	--	, [LotRecords2].[StartTime] as [start_time]
	--	, [LotRecords].[EndTime] as [end_time]
	--from [APCSProDB].[trans].[lots] with (NOLOCK)
	--inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--inner join ( select  [lots].[id] as [lot_id]
	--		, [lots].[lot_no] as [lot]
	--		, [lots].[qty_in] as [pieces]
	--		, [device_flows].[step_no]
	--		, [device_slips].[device_slip_id]
	--		, [device_flows].[job_id]
	--		, [device_flows].[is_skipped]
	--		from [APCSProDB].[trans].[lots] with (NOLOCK)
	--		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
	--		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]

	--		UNION ALL

	--		select [lot].[id] as [lot_id]
	--		, [lot].[lot_no] as [lot]
	--		, [lot].[qty_in] as [pieces]
	--		, [special_flows].step_no
	--		, (select top 1 [device_slips].[device_slip_id] 
	--			from [APCSProDB].[trans].[lots] with (NOLOCK)
	--			inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--			inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
	--			inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id] 
	--			where [lots].[device_slip_id] = [lot].device_slip_id) as [device_slip_id]
	--		, [lot_special_flows].[job_id]
	--		, 0 as [is_skipped]
	--		from [APCSProDB].[trans].[lots] as lot with (NOLOCK)
	--		left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [lot].[id] = [special_flows].[lot_id] 
	--		left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] 
	--			and  [special_flows].step_no = [lot_special_flows].step_no
			
	--	) as [device_flows] on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [lots].[id] = [device_flows].[lot_id]

	--inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
	--inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
	--inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
	--inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
	--inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
	--inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
	--inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
	----inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
	--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
	--left join (select [lot_id], [step_no], MAX(recorded_at) as EndTime
	--	from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
	--	where [record_class] in(2)
	--	group by [lot_id], [step_no]) as LotRecords on [LotRecords].[lot_id] = [lots].[id] and [LotRecords].[step_no] = [device_flows].[step_no]
	--left join (select [lot_id], [step_no], MAX(recorded_at) as StartTime
	--	from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
	--	where [record_class] in(5)
	--	group by [lot_id], [step_no]) as LotRecords2 on [LotRecords2].[lot_id] = [lots].[id] and [LotRecords2].[step_no] = [device_flows].[step_no]
	--where [lots].[wip_state] in (100,70)
	--and [device_flows].[is_skipped] = 0
	--and [package_groups].[name] like @package_group
	--and SUBSTRING([lots].[lot_no],5,1) like @lot_type
	--and [packages].[name] like @package
	--and ([lots].updated_at BETWEEN @start_date AND @end_date)
	----order by [lots].[lot_no],[device_flows].[step_no]
	--order by [package_groups].[name],[packages].[name],[device_names].[name],[lots].[lot_no],[device_flows].[step_no]

	SELECT [package_groups].[name] AS [package_groups]
		, [packages].[name] AS [package]
		, [device_names].[name] AS [device]
		, [lots].[lot_no] AS [lot]
		, [days1].[date_value] AS [in_day]
		, DATEDIFF( DAY, [days2].[date_value], GETDATE() ) AS [delay_day]
		, [lots].[qty_in] AS [pieces]
		, [processes].[name] AS [process]
		, [jobs].[name] AS [job]
		, [LotRecords2].[StartTime] AS [start_time]
		, [LotRecords].[EndTime] AS [end_time]
		, [package_groups].[id]
	FROM (
		SELECT [lots].[device_slip_id]
			, [lots].[act_device_name_id]
			, [lots].[id]
			, [lots].[lot_no]
			, [lots].[in_plan_date_id]
			, [lots].[modify_out_plan_date_id]
			, [lots].[wip_state]
			, [lots].[qty_in]
			, [device_flows].[step_no]
			, [device_flows].[job_id]
			, [lots].[updated_at]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [lots].[device_slip_id] = [device_slips].[device_slip_id] 
			AND [device_slips].[is_released] = 1
		INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
			AND [device_flows].[is_skipped] = 0
		WHERE [lots].[wip_state] IN (100,70)
			AND ( [lots].[updated_at] BETWEEN @start_date AND @end_date )
			AND SUBSTRING( [lots].[lot_no], 5, 1 ) LIKE @lot_type
		UNION ALL
		SELECT [lots].[device_slip_id]
			, [lots].[act_device_name_id]
			, [lots].[id]
			, [lots].[lot_no]
			, [lots].[in_plan_date_id]
			, [lots].[modify_out_plan_date_id]
			, [lots].[wip_state]
			, [lots].[qty_in]
			, [special_flows].[step_no]
			, [lot_special_flows].[job_id]
			, [lots].[updated_at]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		INNER JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK) ON [lots].[id] = [special_flows].[lot_id] 
		INNER JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK) ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
			AND [special_flows].[step_no] = [lot_special_flows].[step_no]
		WHERE [lots].[wip_state] IN (100,70)
			AND ( [lots].[updated_at] BETWEEN @start_date AND @end_date )
			AND SUBSTRING( [lots].[lot_no], 5, 1 ) LIKE @lot_type
	) AS [lots]
	INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [lots].[act_device_name_id] = [device_names].[id]
	INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [device_names].[package_id] = [packages].[id] 
	INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [packages].[package_group_id] = [package_groups].[id]
	INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [lots].[job_id]
	INNER JOIN [APCSProDB].[method].[processes] WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
	INNER JOIN [APCSProDB].[trans].[days] AS [days1] WITH (NOLOCK) ON [lots].[in_plan_date_id] = [days1].[id] 
	INNER JOIN [APCSProDB].[trans].[days] AS [days2] WITH (NOLOCK) ON [lots].[modify_out_plan_date_id] = [days2].[id]
	OUTER APPLY (
		SELECT MAX([recorded_at]) AS [EndTime]
		FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
		WHERE [lot_process_records].[record_class] = 2
			AND [lot_process_records].[lot_id] = [lots].[id]
			AND [lot_process_records].[step_no] = [lots].[step_no]
	) AS [LotRecords]
	OUTER APPLY (
		SELECT MAX([recorded_at]) AS [StartTime]
		FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
		WHERE [lot_process_records].[record_class] = 5
			AND [lot_process_records].[lot_id] = [lots].[id]
			AND [lot_process_records].[step_no] = [lots].[step_no]
	) AS [LotRecords2]
	WHERE [package_groups].[name] like @package_group
		AND [packages].[name] LIKE @package
		AND [package_groups].[id] NOT IN (1, 35)
	ORDER BY [package_groups].[name]
		, [packages].[name]
		, [device_names].[name]
		, [lots].[lot_no]
		, [lots].[step_no];
END
