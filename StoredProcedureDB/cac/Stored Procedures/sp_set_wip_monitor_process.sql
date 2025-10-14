-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_set_wip_monitor_process]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rohm_date_start datetime = convert(datetime,convert(varchar(10), GETDATE(), 120))
	DECLARE @rohm_date_end datetime = convert(datetime,convert(varchar(10), GETDATE(), 120) + ' 08:00:00')
	DECLARE @date_value varchar(10)
	DECLARE @yesterday_date_value varchar(10)


	IF((GETDATE() >= @rohm_date_start) AND (GETDATE() < @rohm_date_end))
	BEGIN
		SET @date_value = convert(varchar(10), GETDATE() - 1, 120)
		SET @yesterday_date_value = convert(varchar(10), GETDATE() - 2, 120)
	END
	ELSE
	BEGIN
		SET @date_value = convert(varchar(10), GETDATE(), 120)
		SET @yesterday_date_value = convert(varchar(10), GETDATE() - 1, 120)
	END
    -- Insert statements for procedure here
	delete from [APCSProDWH].[cac].[wip_monitor_process_temp]
	insert into [APCSProDWH].[cac].[wip_monitor_process_temp]
	([package_group]
	, [package]
	, [process]
	, [job]
	, [today_wip]
	, [today_wip_pcs]
	, [today_delay]
	, [today_delay_pcs]
	, [oneday_ago_wip]
	, [oneday_ago_wip_pcs]
	, [twoday_ago_wip]
	, [twoday_ago_wip_pcs]
	, [today_input]
	, [today_input_pcs]
	, [today_result]
	, [today_result_pcs]
	, [oneday_ago_result]
	, [oneday_ago_result_pcs]
	, [twoday_ago_result]
	, [twoday_ago_result_pcs]
	, [wip_rate]
	, [wip_rate_pcs]
	, [progress_delay]
	, [progress_delay_pcs])
	select [master_data].[package_group]
		, [master_data].[package]
		, [master_data].[process]
		, [master_data].[job]
		, [oneday_ago].[today_wip]
		, [oneday_ago].[today_wip_pcs]
		, [oneday_ago].[today_delay]
		, [oneday_ago].[today_delay_pcs]
		, [twoday_ago].[oneday_ago_wip]
		, [twoday_ago].[oneday_ago_wip_pcs]
		, [threeday_ago].[twoday_ago_wip]
		, [threeday_ago].[twoday_ago_wip_pcs]
		, [input_today].[today_input]
		, [input_today].[today_input_pcs]
		, [today].[today_result]
		, [today].[today_result_pcs]
		, [oneday_ago].[oneday_ago_result]
		, [oneday_ago].[oneday_ago_result_pcs]
		, [twoday_ago].[twoday_ago_result]
		, [twoday_ago].[twoday_ago_result_pcs]
		, case when NULLIF([sum_threeday_result].[threeday_result], 0) > 0 then [sum_threeday_wip].[threeday_wip]*1.00/[sum_threeday_result].[threeday_result] else 0.00 end as [wip_rate]
		, case when NULLIF([sum_threeday_result].[threeday_result_pcs], 0) > 0 then [sum_threeday_wip].[threeday_wip_pcs]*1.00/[sum_threeday_result].[threeday_result_pcs] else 0.00 end as [wip_rate_pcs]
		, case when NULLIF([oneday_ago].[today_delay], 0) > 0 then [oneday_ago].[today_delay]*100.00/[oneday_ago].[today_wip] else 0.00 end as [progress_delay]
		, case when NULLIF([oneday_ago].[today_delay_pcs], 0) > 0 then [oneday_ago].[today_delay_pcs]*100.00/[oneday_ago].[today_wip_pcs] else 0.00 end as [progress_delay_pcs]
	from (select [package_group]
			, [package]
			, [process]
			, [job]
		from [APCSProDWH].[cac].[wip_monitor_main]
		group by [package_group],[package],[process],[job]) as master_data
	left join (select [package_group]
			, [package]
			, [process]
			, [job]
			--, SUM([delay]) as [today_delay]
			--, SUM([delay_pcs]) as [today_delay_pcs]
			--, SUM(total) as [today_wip]
			--, SUM(total_pcs) as [today_wip_pcs]
			, SUM(yesterday_result) as [today_result]
			, SUM(yesterday_result_pcs) as [today_result_pcs]
		from [APCSProDWH].[cac].[wip_monitor_main]
		where [date_value] = convert(varchar(10), GETDATE(), 120)
		group by [package_group],[package],[process],[job]) as [today] on [today].[package_group] = [master_data].[package_group] and [today].[package] = [master_data].[package] and [today].[process] = [master_data].[process] and [today].[job] = [master_data].[job]
	left join (select [package_group]
			, [package]
			, [process]
			, [job]
			, SUM(total) as [today_wip]
			, SUM(total_pcs) as [today_wip_pcs]
			, SUM([delay]) as [today_delay]
			, SUM([delay_pcs]) as [today_delay_pcs]
			, SUM(yesterday_result) as [oneday_ago_result]
			, SUM(yesterday_result_pcs) as [oneday_ago_result_pcs]
		from [APCSProDWH].[cac].[wip_monitor_main]
		where [date_value] = convert(varchar(10), GETDATE() - 1, 120)
		group by [package_group],[package],[process],[job]) as [oneday_ago] on [oneday_ago].[package_group] = [master_data].[package_group] and [oneday_ago].[package] = [master_data].[package] and [oneday_ago].[process] = [master_data].[process] and [oneday_ago].[job] = [master_data].[job]
	left join (select [package_group]
			, [package]
			, [process]
			, [job]
			, SUM(total) as [oneday_ago_wip]
			, SUM(total_pcs) as [oneday_ago_wip_pcs]
			, SUM(yesterday_result) as [twoday_ago_result]
			, SUM(yesterday_result_pcs) as [twoday_ago_result_pcs]
		from [APCSProDWH].[cac].[wip_monitor_main]
		where [date_value] = convert(varchar(10), GETDATE() - 2, 120)
		group by [package_group],[package],[process],[job]) as [twoday_ago] on [twoday_ago].[package_group] = [master_data].[package_group] and [twoday_ago].[package] = [master_data].[package] and [twoday_ago].[process] = [master_data].[process] and [twoday_ago].[job] = [master_data].[job]
	left join (select [package_group]
			, [package]
			, [process]
			, [job]
			, SUM(total) as [twoday_ago_wip]
			, SUM(total_pcs) as [twoday_ago_wip_pcs]
			--, SUM(yesterday_result) as [twoday_ago_result]
			--, SUM(yesterday_result_pcs) as [twoday_ago_result_pcs]
		from [APCSProDWH].[cac].[wip_monitor_main]
		where [date_value] = convert(varchar(10), GETDATE() - 3, 120)
		group by [package_group],[package],[process],[job]) as [threeday_ago] on [threeday_ago].[package_group] = [master_data].[package_group] and [threeday_ago].[package] = [master_data].[package] and [threeday_ago].[process] = [master_data].[process] and [threeday_ago].[job] = [master_data].[job]
	left join (select [package_group]
			, [package]
			, [process]
			, [job]
			, SUM(total) as [threeday_wip]
			, SUM(total_pcs) as [threeday_wip_pcs]
		from [APCSProDWH].[cac].[wip_monitor_main]
		where [date_value] between convert(varchar(10), GETDATE() - 3, 120) and convert(varchar(10), GETDATE() - 1, 120)
		group by [package_group],[package],[process],[job]) as [sum_threeday_wip] on [sum_threeday_wip].[package_group] = [master_data].[package_group] and [sum_threeday_wip].[package] = [master_data].[package] and [sum_threeday_wip].[process] = [master_data].[process] and [sum_threeday_wip].[job] = [master_data].[job]
	left join (select [package_group]
			, [package]
			, [process]
			, [job]
			, SUM(yesterday_result) as [threeday_result]
			, SUM(yesterday_result_pcs) as [threeday_result_pcs]
		from [APCSProDWH].[cac].[wip_monitor_main]
		where [date_value] between convert(varchar(10), GETDATE() - 2, 120) and convert(varchar(10), GETDATE(), 120)
		group by [package_group],[package],[process],[job]) as [sum_threeday_result] on [sum_threeday_result].[package_group] = [master_data].[package_group] and [sum_threeday_result].[package] = [master_data].[package] and [sum_threeday_result].[process] = [master_data].[process] and [sum_threeday_result].[job] = [master_data].[job]
	left join (select [package_groups].[name] as [package_group]
			, [packages].[name] as [package]
			, COUNT([lots].[id]) as [today_input]
			, SUM([lots].[qty_in]) as [today_input_pcs]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[trans].[days] with (NOLOCK) on [days].[id] = [lots].[in_date_id]
		where [APCSProDB].[trans].[lots].[wip_state] in ('20','10','0')
		and [days].[date_value] = @date_value
		group by [package_groups].[name], [packages].[name]) as [input_today] on [input_today].[package_group] = [master_data].[package_group] and [input_today].[package] = [master_data].[package]
	--left join (select [package_groups].[name] as [package_group]
	--		, [packages].[name] as [package]
	--		, [processes].[name] as [process]
	--		, [jobs].[name] as [job]
	--		, COUNT([lots].[id]) as [today_result]
	--		, SUM([lots].[qty_pass]) as [today_result_pcs]
	--	from [APCSProDB].[trans].[lots]
	--	inner join (select [lot_process_records].[lot_id]
	--		, [lot_process_records].[step_no]
	--		, MAX(recorded_at) as max_date
	--		from [APCSProDB].[trans].[lot_process_records]
	--		inner join [APCSProDB].[trans].[lots] on [lots].[id] = [lot_process_records].[lot_id]
	--		where [APCSProDB].[trans].[lots].[wip_state] = '20'
	--		and [APCSProDB].[trans].[lot_process_records].[record_class] = 2
	--		and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @date_value + ' 08:00:00'
	--		group by [lot_process_records].[lot_id], [lot_process_records].[step_no]) as [lot_max] on [lot_max].[lot_id] = [lots].[id]
	--	inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--	inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
	--	inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
	--	inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
	--	inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id]
	--	inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [lots].[device_slip_id] and [device_flows].[step_no] = [lot_max].[step_no]
	--	inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [device_flows].[job_id]
	--	inner join [APCSProDB].[method].[processes] on [processes].[id] = [jobs].[process_id]
	--	where [APCSProDB].[trans].[lots].[wip_state] = '20'
	--	group by [package_groups].[name], [packages].[name], [processes].[name], [jobs].[name]) as [shipment_today] on [shipment_today].[package_group] = [master_data].[package_group] and [shipment_today].[package] = [master_data].[package] and [shipment_today].[process] = [master_data].[process] and [shipment_today].[job] = [master_data].[job]
	delete from [APCSProDWH].[cac].[wip_monitor_process]
	insert into [APCSProDWH].[cac].[wip_monitor_process]
	([package_group]
	, [package]
	, [process]
	, [job]
	, [today_wip]
	, [today_wip_pcs]
	, [today_delay]
	, [today_delay_pcs]
	, [oneday_ago_wip]
	, [oneday_ago_wip_pcs]
	, [twoday_ago_wip]
	, [twoday_ago_wip_pcs]
	, [today_input]
	, [today_input_pcs]
	, [today_result]
	, [today_result_pcs]
	, [oneday_ago_result]
	, [oneday_ago_result_pcs]
	, [twoday_ago_result]
	, [twoday_ago_result_pcs]
	, [wip_rate]
	, [wip_rate_pcs]
	, [progress_delay]
	, [progress_delay_pcs])
	select [package_group]
	, [package]
	, [process]
	, [job]
	, [today_wip]
	, [today_wip_pcs]
	, [today_delay]
	, [today_delay_pcs]
	, [oneday_ago_wip]
	, [oneday_ago_wip_pcs]
	, [twoday_ago_wip]
	, [twoday_ago_wip_pcs]
	, [today_input]
	, [today_input_pcs]
	, [today_result]
	, [today_result_pcs]
	, [oneday_ago_result]
	, [oneday_ago_result_pcs]
	, [twoday_ago_result]
	, [twoday_ago_result_pcs]
	, [wip_rate]
	, [wip_rate_pcs]
	, [progress_delay]
	, [progress_delay_pcs]
	from [APCSProDWH].[cac].[wip_monitor_process_temp] with (NOLOCK)
END
