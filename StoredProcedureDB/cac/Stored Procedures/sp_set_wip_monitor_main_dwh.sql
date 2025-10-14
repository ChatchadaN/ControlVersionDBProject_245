-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_set_wip_monitor_main_dwh]
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
     --Insert statements for procedure here
	delete from [10.29.1.230].[DWH].[cac].[wip_monitor_main_temp]
	insert into [10.29.1.230].[DWH].[cac].[wip_monitor_main_temp]
	([date_value]
		,[package_group]
		,[package]
		,[process]
		,[job]
		,[lot_type]
		,[normal]
		,[normal_pcs]
		,[delay]
		,[delay_pcs]
		,[order_delay]
		,[order_delay_pcs]
		,[order_delay_hold]
		,[order_delay_hold_pcs]
		,[hold]
		,[hold_pcs]
		,[total]
		,[total_pcs]
		,[machine]
		,[machine_pcs]
		,[actual_result]
		,[actual_result_pcs]
		,[yesterday_result]
		,[yesterday_result_pcs]
		,[seq_no]
		,[processing_time]
		,[wip_time]
		,[today_input]
		,[today_input_pcs]
		,[today_output]
		,[today_output_pcs]
		,[specialflow]
		,[specialflow_pcs]
		,[order_delay_special]
		,[order_delay_special_pcs])
	select @date_value as [date_value]
		, [master_data].[package_group]
		, [master_data].[package]
		, [master_data].[process]
		, [master_data].[job]
		, [master_data].[lot_type]
		, case when [lot].[normal] is null then 0 else [lot].[normal] end as [normal]
		, case when [lot].[normal_pcs] is null then 0 else [lot].[normal_pcs] end as [normal_pcs]
		, case when [lot].[delay] is null then 0 else [lot].[delay] end as [delay]
		, case when [lot].[delay_pcs] is null then 0 else [lot].[delay_pcs] end as [delay_pcs]
		, case when [lot].[order_delay] is null then 0 else [lot].[order_delay] end as [order_delay]
		, case when [lot].[order_delay_pcs] is null then 0 else [lot].[order_delay_pcs] end as [order_delay_pcs]
		, case when [lot].[order_delay_hold] is null then 0 else [lot].[order_delay_hold] end as [order_delay_hold]
		, case when [lot].[order_delay_hold_pcs] is null then 0 else [lot].[order_delay_hold_pcs] end as [order_delay_hold_pcs]
		, case when [lot].[hold] is null then 0 else [lot].[hold] end as [hold]
		, case when [lot].[hold_pcs] is null then 0 else [lot].[hold_pcs] end as [hold_pcs]
		, case when [lot].[total] is null then 0 else [lot].[total] end as [total]
		, case when [lot].[total_pcs] is null then 0 else [lot].[total_pcs] end as [total_pcs]
		, case when [lot].[machine] is null then 0 else [lot].[machine] end as [machine]
		, case when [lot].[machine_pcs] is null then 0 else [lot].[machine_pcs] end as [machine_pcs]
		, case when [lot_max].[actual_result] is null then 0 else [lot_max].[actual_result] end as [actual_result]
		, case when [lot_max].[actual_result_pcs] is null then 0 else [lot_max].[actual_result_pcs] end as [actual_result_pcs]
		, case when [lot_max].[yesterday_result] is null then 0 else [lot_max].[yesterday_result] end as [yesterday_result]
		, case when [lot_max].[yesterday_result_pcs] is null then 0 else [lot_max].[yesterday_result_pcs] end as [yesterday_result_pcs]
		, [master_data].[seq_no]
		, case when [lot_processing].[processing_time] is null then 0 else [lot_processing].[processing_time] end as [processing_time]
		, case when [lot_processing].[wip_time] is null then 0 else [lot_processing].[wip_time] end as [wip_time]
		, case when [input_today].[today_input] is null then 0 else [input_today].[today_input] end as [today_input]
		, case when [input_today].[today_input_pcs] is null then 0 else [input_today].[today_input_pcs] end as [today_input_pcs]
		, case when [output_today].[today_output] is null then 0 else [output_today].[today_output] end as [today_output]
		, case when [output_today].[today_output_pcs] is null then 0 else [output_today].[today_output_pcs] end as [today_output_pcs]
		, case when [lot].[specialflow] is null then 0 else [lot].[specialflow] end as [specialflow]
		, case when [lot].[specialflow_pcs] is null then 0 else [lot].[specialflow_pcs] end as [specialflow_pcs]
		, case when [lot].[order_delay_special] is null then 0 else [lot].[order_delay_special] end as [order_delay_special]
		, case when [lot].[order_delay_special_pcs] is null then 0 else [lot].[order_delay_special_pcs] end as [order_delay_special_pcs]
	from
		(select [package_groups].[name] as [package_group]
		, [packages].[name] as [package]
		, [processes].[name] as [process]
		, [jobs].[name] as [job]
		, [jobs].[seq_no] as [seq_no]
		, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
		from [APCSProDB].[trans].[lots] with (NOLOCK) 
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		inner join [APCSProDB].[trans].[days] on [APCSProDB].[trans].[days].id = [APCSProDB].[trans].[lots].in_date_id
		where [APCSProDB].[trans].[lots].[wip_state] in ('20','10','0')
		and [APCSProDB].[method].[device_flows].[is_skipped] = '0'
		--and [APCSProDB].[trans].[days].[date_value] <= convert(date, getdate())
		group by [package_groups].[name], [packages].[name], [processes].[name], [jobs].[name], [jobs].[seq_no], SUBSTRING([lots].[lot_no],5,1)) as [master_data]

	left join (select [package_groups].[name] as [package_group]
			, [packages].[name] as [package]
			, [processes].[name] as [process]
			, [jobs].[name] as [job]
			, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
			, COUNT(case when DATEADD(MINUTE,ISNULL([device_flows].[lead_time_sum] + 1440,0),CONVERT(DATETIME,[days1].[date_value])) > GETDATE() and DATEDIFF(DAY,[days2].[date_value],GETDATE()) < 0 and [APCSProDB].[trans].[lots].[quality_state] <> 3 and [APCSProDB].[trans].[lots].[quality_state] <> 4 then [lots].[lot_no] else NULL end) as [normal]
			, SUM(case when DATEADD(MINUTE,ISNULL([device_flows].[lead_time_sum] + 1440,0),CONVERT(DATETIME,[days1].[date_value])) > GETDATE() and DATEDIFF(DAY,[days2].[date_value],GETDATE()) < 0 and [APCSProDB].[trans].[lots].[quality_state] <> 3 and [APCSProDB].[trans].[lots].[quality_state] <> 4 then [lots].[qty_pass] else NULL end) as [normal_pcs]
			, COUNT(case when DATEADD(MINUTE,ISNULL([device_flows].[lead_time_sum] + 1440,0),CONVERT(DATETIME,[days1].[date_value])) <= GETDATE() and DATEDIFF(DAY,[days2].[date_value],GETDATE()) < 0 and [APCSProDB].[trans].[lots].[quality_state] <> 3 and [APCSProDB].[trans].[lots].[quality_state] <> 4 then [lots].[lot_no] else NULL end) as [delay]
			, SUM(case when DATEADD(MINUTE,ISNULL([device_flows].[lead_time_sum] + 1440,0),CONVERT(DATETIME,[days1].[date_value])) <= GETDATE() and DATEDIFF(DAY,[days2].[date_value],GETDATE()) < 0 and [APCSProDB].[trans].[lots].[quality_state] <> 3 and [APCSProDB].[trans].[lots].[quality_state] <> 4 then [lots].[qty_pass] else NULL end) as [delay_pcs]
			, COUNT(case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 and [APCSProDB].[trans].[lots].[quality_state] <> 3 and [APCSProDB].[trans].[lots].[quality_state] <> 4 then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [order_delay] 
			, SUM(case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 and [APCSProDB].[trans].[lots].[quality_state] <> 3  and [APCSProDB].[trans].[lots].[quality_state] <> 4 then [APCSProDB].[trans].[lots].[qty_pass] else NULL end) as [order_delay_pcs] 
			, COUNT(case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 and [APCSProDB].[trans].[lots].[quality_state] = 3 then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [order_delay_hold] 
			, SUM(case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 and [APCSProDB].[trans].[lots].[quality_state] = 3 then [APCSProDB].[trans].[lots].[qty_pass] else NULL end) as [order_delay_hold_pcs] 
			, COUNT(case when [APCSProDB].[trans].[lots].[quality_state] = 3 then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [hold] 
			, SUM(case when [APCSProDB].[trans].[lots].[quality_state] = 3 then [APCSProDB].[trans].[lots].[qty_pass] else NULL end) as [hold_pcs] 
			, COUNT([lots].[lot_no]) as [total]
			, SUM([lots].[qty_pass]) as [total_pcs]
			, COUNT(case when [APCSProDB].[trans].[lots].[process_state] not in('0','3','100') then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [machine]
			, SUM(case when [APCSProDB].[trans].[lots].[process_state] not in('0','3','100') then [APCSProDB].[trans].[lots].[qty_pass] else NULL end) as [machine_pcs]
			, COUNT(case when [APCSProDB].[trans].[lots].[quality_state] = 4 then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [specialflow] 
			, SUM(case when [APCSProDB].[trans].[lots].[quality_state] = 4 then [APCSProDB].[trans].[lots].[qty_pass] else NULL end) as [specialflow_pcs] 
			, COUNT(case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 and [APCSProDB].[trans].[lots].[quality_state] = 4 then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [order_delay_special] 
			, SUM(case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 and [APCSProDB].[trans].[lots].[quality_state] = 4 then [APCSProDB].[trans].[lots].[qty_pass] else NULL end) as [order_delay_special_pcs] 
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [lots].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
		--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
		where [APCSProDB].[trans].[lots].[wip_state] in ('20','10','0')
		and [days1].[date_value] <= @date_value
		group by [package_groups].[name], [packages].[name], [processes].[name], [jobs].[name], SUBSTRING([lots].[lot_no],5,1)) as [lot] on [lot].[package_group] = [master_data].[package_group] and [lot].[package] = [master_data].[package] and [lot].[process] = [master_data].[process] and [lot].[job] = [master_data].[job] and [lot].[lot_type] = [master_data].[lot_type]
	left join (select [package_groups].[name] as [package_group]
			, [packages].[name] as [package]
			, [processes].[name] as [process]
			, [jobs].[name] as [job]
			, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
			, COUNT(case when [lot_max].[max_date] >= @date_value + ' 08:00:00' then [lots].[id] else NULL end) as [actual_result]
			, SUM(case when [lot_max].[max_date] >= @date_value + ' 08:00:00' then [lots].[qty_pass] else NULL end) as [actual_result_pcs]
			, COUNT(case when [lot_max].[max_date] < @date_value + ' 08:00:00' then [lots].[id] else NULL end) as [yesterday_result]
			, SUM(case when [lot_max].[max_date] < @date_value + ' 08:00:00' then [lots].[qty_pass] else NULL end) as [yesterday_result_pcs]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join (select [lot_process_records].[lot_id]
			, [lot_process_records].[step_no]
			, MAX(recorded_at) as max_date
			from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
			inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
			where [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
			and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @yesterday_date_value + ' 08:00:00'
			group by [lot_process_records].[lot_id], [lot_process_records].[step_no]) as [lot_max] on [lot_max].[lot_id] = [lots].[id]
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [lots].[device_slip_id] and [device_flows].[step_no] = [lot_max].[step_no]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		--where [APCSProDB].[trans].[lots].[wip_state] = '20'
		group by [package_groups].[name], [packages].[name], [processes].[name], [jobs].[name], SUBSTRING([lots].[lot_no],5,1)) as [lot_max] on [lot_max].[package_group] = [master_data].[package_group] and [lot_max].[package] = [master_data].[package] and [lot_max].[process] = [master_data].[process] and [lot_max].[job] = [master_data].[job] and [lot_max].[lot_type] = [master_data].[lot_type]
	left join (select [package_groups].[name] as [package_group]
		, [packages].[name] as [package]
		, [processes].[name] as [process]
		, [jobs].[name] as [job]
		, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
		, SUM([lot_processing_time].[processing_time]) as [processing_time]
		, SUM([lot_processing_time].[wip_time]) as [wip_time]
	from [APCSProDB].[trans].[lots] with (NOLOCK)
	inner join (select [lot_start].[lot_id]
			, [lot_start].[step_no]
			, DATEDIFF(MINUTE, [lot_start].[start_datetime], [lot_end].[end_datetime]) as [processing_time]
			, DATEDIFF(MINUTE, LAG([lot_end].[end_datetime],1,null) OVER(PARTITION BY [lot_start].[lot_id] ORDER BY [lot_start].[step_no]), [lot_start].[start_datetime]) as [wip_time]
		from (select [lot_process_records].[lot_id]
				, [lot_process_records].[step_no]
				, MIN(recorded_at) as [start_datetime]
			from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
			inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
			where [APCSProDB].[trans].[lot_process_records].[record_class] in (1,11,31)
			and [APCSProDB].[trans].[lot_process_records].[lot_id] in (select [lot_process_records].[lot_id]
				from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
				inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
				where [APCSProDB].[trans].[lots].[wip_state] in ('100','101')
				and [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
				and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @date_value + ' 08:00:00'
				group by [lot_process_records].[lot_id], [lot_process_records].[step_no])
			and [APCSProDB].[trans].[lot_process_records].[step_no] > 1
			group by [lot_process_records].[lot_id], [lot_process_records].[step_no]) as [lot_start]
		inner join(select [lot_process_records].[lot_id]
				, [lot_process_records].[step_no]
				, MAX(recorded_at) as [end_datetime]
			from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
			inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
			where [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
			and [APCSProDB].[trans].[lot_process_records].[lot_id] in (select [lot_process_records].[lot_id]
				from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
				inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
				where [APCSProDB].[trans].[lots].[wip_state] in ('100','101')
				and [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
				and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @date_value + ' 08:00:00'
				group by [lot_process_records].[lot_id], [lot_process_records].[step_no])
			and [APCSProDB].[trans].[lot_process_records].[step_no] > 1
			group by [lot_process_records].[lot_id], [lot_process_records].[step_no]) as [lot_end] on [lot_end].[lot_id] = [lot_start].[lot_id] and [lot_end].[step_no] = [lot_start].[step_no]
		) as [lot_processing_time] on [lot_processing_time].[lot_id] = [lots].[id]
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [lots].[device_slip_id] and [device_flows].[step_no] = [lot_processing_time].[step_no]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		group by [package_groups].[name], [packages].[name], [processes].[name], [jobs].[name], SUBSTRING([lots].[lot_no],5,1)) as [lot_processing] on [lot_processing].[package_group] = [master_data].[package_group] and [lot_processing].[package] = [master_data].[package] and [lot_processing].[process] = [master_data].[process] and [lot_processing].[job] = [master_data].[job] and [lot_processing].[lot_type] = [master_data].[lot_type]
	left join (select [package_groups].[name] as [package_group]
			, [packages].[name] as [package]
			, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
			, COUNT([lots].[id]) as [today_input]
			, SUM([lots].[qty_in]) as [today_input_pcs]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[trans].[days] with (NOLOCK) on [days].[id] = [lots].[in_date_id]
		where [APCSProDB].[trans].[lots].[wip_state] in ('20', '10', '0')
		and [days].[date_value] = @date_value
		group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [input_today] on [input_today].[package_group] = [master_data].[package_group] and [input_today].[package] = [master_data].[package] and [input_today].[lot_type] = [master_data].[lot_type]
	left join(select [package_groups].[name] as [package_group]
			, [packages].[name] as [package]
			, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
			, COUNT([lots].[id]) as [today_output]
			, SUM([lots].[qty_in]) as [today_output_pcs]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		where [lots].[id] in(select [lot_process_records].[lot_id]
			from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
			inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
			where [APCSProDB].[trans].[lots].[wip_state] in ('100','101')
			and [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
			and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @date_value + ' 08:00:00'
			group by [lot_process_records].[lot_id], [lot_process_records].[step_no])
		group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [output_today] on [output_today].[package_group] = [master_data].[package_group] and [output_today].[package] = [master_data].[package] and [output_today].[lot_type] = [master_data].[lot_type]
	
	----------------------------ASSY-----------------------------
	--union
	--select @date_value as [date_value]
	--	, [master_data].[package_group]
	--	, [master_data].[package]
	--	, [master_data].[process]
	--	, [master_data].[job]
	--	, [master_data].[lot_type]
	--	, case when [lot].[normal] is null then 0 else [lot].[normal] end as [normal]
	--	, case when [lot].[normal_pcs] is null then 0 else [lot].[normal_pcs] end as [normal_pcs]
	--	, case when [lot].[delay] is null then 0 else [lot].[delay] end as [delay]
	--	, case when [lot].[delay_pcs] is null then 0 else [lot].[delay_pcs] end as [delay_pcs]
	--	, case when [lot].[order_delay] is null then 0 else [lot].[order_delay] end as [order_delay]
	--	, case when [lot].[order_delay_pcs] is null then 0 else [lot].[order_delay_pcs] end as [order_delay_pcs]
	--	, case when [lot].[order_delay_hold] is null then 0 else [lot].[order_delay_hold] end as [order_delay_hold]
	--	, case when [lot].[order_delay_hold_pcs] is null then 0 else [lot].[order_delay_hold_pcs] end as [order_delay_hold_pcs]
	--	, case when [lot].[hold] is null then 0 else [lot].[hold] end as [hold]
	--	, case when [lot].[hold_pcs] is null then 0 else [lot].[hold_pcs] end as [hold_pcs]
	--	, case when [lot].[total] is null then 0 else [lot].[total] end as [total]
	--	, case when [lot].[total_pcs] is null then 0 else [lot].[total_pcs] end as [total_pcs]
	--	, case when [lot].[machine] is null then 0 else [lot].[machine] end as [machine]
	--	, case when [lot].[machine_pcs] is null then 0 else [lot].[machine_pcs] end as [machine_pcs]
	--	, case when [lot_max].[actual_result] is null then 0 else [lot_max].[actual_result] end as [actual_result]
	--	, case when [lot_max].[actual_result_pcs] is null then 0 else [lot_max].[actual_result_pcs] end as [actual_result_pcs]
	--	, case when [lot_max].[yesterday_result] is null then 0 else [lot_max].[yesterday_result] end as [yesterday_result]
	--	, case when [lot_max].[yesterday_result_pcs] is null then 0 else [lot_max].[yesterday_result_pcs] end as [yesterday_result_pcs]
	--	, [master_data].[seq_no]
	--	, case when [lot_processing].[processing_time] is null then 0 else [lot_processing].[processing_time] end as [processing_time]
	--	, case when [lot_processing].[wip_time] is null then 0 else [lot_processing].[wip_time] end as [wip_time]
	--	, case when [input_today].[today_input] is null then 0 else [input_today].[today_input] end as [today_input]
	--	, case when [input_today].[today_input_pcs] is null then 0 else [input_today].[today_input_pcs] end as [today_input_pcs]
	--	, case when [output_today].[today_output] is null then 0 else [output_today].[today_output] end as [today_output]
	--	, case when [output_today].[today_output_pcs] is null then 0 else [output_today].[today_output_pcs] end as [today_output_pcs]
	--from
	--	(select [package_groups].[name] as [package_group]
	--	, [packages].[name] as [package]
	--	, 'DC' as [process]
	--	, 'DC' as [job]
	--	, '0000' as [seq_no]
	--	, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
	--	from [APCSProDB].[trans].[lots] with (NOLOCK)
	--	inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--	inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
	--	inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
	--	inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
	--	inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
	--	--inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [lots].[device_slip_id]
	--	--inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [device_flows].[job_id]
	--	--inner join [APCSProDB].[method].[processes] on [processes].[id] = [jobs].[process_id]
	--	inner join [APCSProDB].[trans].[days] on [APCSProDB].[trans].[days].id = [APCSProDB].[trans].[lots].in_date_id
	--	where [APCSProDB].[trans].[lots].[wip_state] in ('20','10','0')
	--	and [APCSProDB].[trans].[days].[date_value] <= convert(date, getdate())
	--	--and [APCSProDB].[method].[device_flows].[is_skipped] = '0'
	--	group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [master_data]
	--  left join (select [package_groups].[name] as [package_group]
	--		, [packages].[name] as [package]
	--		, 'DC' as [process]
	--		, 'DC' as [job]
	--		, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
	--		, COUNT(case when DATEADD(MINUTE,ISNULL(1440,0),CONVERT(DATETIME,[days1].[date_value])) > GETDATE() and DATEDIFF(DAY,[days2].[date_value],GETDATE()) < 0 and [APCSProDB].[trans].[lots].[quality_state] <> 3 then [lots].[lot_no] else NULL end) as [normal]
	--		, SUM(case when DATEADD(MINUTE,ISNULL(1440,0),CONVERT(DATETIME,[days1].[date_value])) > GETDATE() and DATEDIFF(DAY,[days2].[date_value],GETDATE()) < 0 and [APCSProDB].[trans].[lots].[quality_state] <> 3 then [lots].[qty_pass] else NULL end) as [normal_pcs]
	--		, COUNT(case when DATEADD(MINUTE,ISNULL(1440,0),CONVERT(DATETIME,[days1].[date_value])) <= GETDATE() and DATEDIFF(DAY,[days2].[date_value],GETDATE()) < 0 and [APCSProDB].[trans].[lots].[quality_state] <> 3 then [lots].[lot_no] else NULL end) as [delay]
	--		, SUM(case when DATEADD(MINUTE,ISNULL(1440,0),CONVERT(DATETIME,[days1].[date_value])) <= GETDATE() and DATEDIFF(DAY,[days2].[date_value],GETDATE()) < 0 and [APCSProDB].[trans].[lots].[quality_state] <> 3 then [lots].[qty_pass] else NULL end) as [delay_pcs]
	--		, COUNT(case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 and [APCSProDB].[trans].[lots].[quality_state] <> 3 then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [order_delay] 
	--		, SUM(case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 and [APCSProDB].[trans].[lots].[quality_state] <> 3 then [APCSProDB].[trans].[lots].[qty_pass] else NULL end) as [order_delay_pcs] 
	--		, COUNT(case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 and [APCSProDB].[trans].[lots].[quality_state] = 3 then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [order_delay_hold] 
	--		, SUM(case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 and [APCSProDB].[trans].[lots].[quality_state] = 3 then [APCSProDB].[trans].[lots].[qty_pass] else NULL end) as [order_delay_hold_pcs] 
	--		, COUNT(case when [APCSProDB].[trans].[lots].[quality_state] = 3 then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [hold] 
	--		, SUM(case when [APCSProDB].[trans].[lots].[quality_state] = 3 then [APCSProDB].[trans].[lots].[qty_pass] else NULL end) as [hold_pcs] 
	--		, COUNT([lots].[lot_no]) as [total]
	--		, SUM([lots].[qty_pass]) as [total_pcs]
	--		, COUNT(case when [APCSProDB].[trans].[lots].[process_state] not in('0','3','100') then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [machine]
	--		, SUM(case when [APCSProDB].[trans].[lots].[process_state] not in('0','3','100') then [APCSProDB].[trans].[lots].[qty_pass] else NULL end) as [machine_pcs]
	--	from [APCSProDB].[trans].[lots] with (NOLOCK)
	--	inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--	inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
	--	inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
	--	inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
	--	inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
	--	--inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [lots].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
	--	--inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [device_flows].[job_id]
	--	--inner join [APCSProDB].[method].[processes] on [processes].[id] = [jobs].[process_id]
	--	inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
	--	inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
	--	where [APCSProDB].[trans].[lots].[wip_state] in ('0','10')
	--	and [days1].[date_value] <= @date_value
	--	group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [lot] on [lot].[package_group] = [master_data].[package_group] and [lot].[package] = [master_data].[package] and [lot].[process] = [master_data].[process] and [lot].[job] = [master_data].[job] and [lot].[lot_type] = [master_data].[lot_type]
	--left join (select [package_groups].[name] as [package_group]
	--		, [packages].[name] as [package]
	--		, 'DC' as [process]
	--		, 'DC' as [job]
	--		, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
	--		, COUNT(case when [lot_max].[max_date] >= @date_value + ' 08:00:00' then [lots].[id] else NULL end) as [actual_result]
	--		, SUM(case when [lot_max].[max_date] >= @date_value + ' 08:00:00' then [lots].[qty_pass] else NULL end) as [actual_result_pcs]
	--		, COUNT(case when [lot_max].[max_date] < @date_value + ' 08:00:00' then [lots].[id] else NULL end) as [yesterday_result]
	--		, SUM(case when [lot_max].[max_date] < @date_value + ' 08:00:00' then [lots].[qty_pass] else NULL end) as [yesterday_result_pcs]
	--	from [APCSProDB].[trans].[lots] with (NOLOCK)
	--	inner join (select [lot_process_records].[lot_id]
	--		, [lot_process_records].[step_no]
	--		, MAX(recorded_at) as max_date
	--		from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
	--		inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
	--		where [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
	--		and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @yesterday_date_value + ' 08:00:00'
	--		and [APCSProDB].[trans].[lot_process_records].[step_no] = 1
	--		group by [lot_process_records].[lot_id], [lot_process_records].[step_no]) as [lot_max] on [lot_max].[lot_id] = [lots].[id]
	--	inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--	inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
	--	inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
	--	inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
	--	inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
	--	--inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [lots].[device_slip_id] and [device_flows].[step_no] = [lot_max].[step_no]
	--	--inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [device_flows].[job_id]
	--	--inner join [APCSProDB].[method].[processes] on [processes].[id] = [jobs].[process_id]
	--	--where [APCSProDB].[trans].[lots].[wip_state] = '20'
	--	group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [lot_max] on [lot_max].[package_group] = [master_data].[package_group] and [lot_max].[package] = [master_data].[package] and [lot_max].[process] = [master_data].[process] and [lot_max].[job] = [master_data].[job] and [lot_max].[lot_type] = [master_data].[lot_type]
	--left join (select [package_groups].[name] as [package_group]
	--	, [packages].[name] as [package]
	--	, 'DC' as [process]
	--	, 'DC' as [job]
	--	, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
	--	, SUM([lot_processing_time].[processing_time]) as [processing_time]
	--	, SUM([lot_processing_time].[wip_time]) as [wip_time]
	--from [APCSProDB].[trans].[lots] with (NOLOCK)
	--inner join (select [lot_start].[lot_id]
	--		, [lot_start].[step_no]
	--		, DATEDIFF(MINUTE, [lot_start].[start_datetime], [lot_end].[end_datetime]) as [processing_time]
	--		, DATEDIFF(MINUTE, LAG([lot_end].[end_datetime],1,null) OVER(PARTITION BY [lot_start].[lot_id] ORDER BY [lot_start].[step_no]), [lot_start].[start_datetime]) as [wip_time]
	--	from (select [lot_process_records].[lot_id]
	--			, [lot_process_records].[step_no]
	--			, MIN(recorded_at) as [start_datetime]
	--		from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
	--		inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
	--		where [APCSProDB].[trans].[lot_process_records].[record_class] in (1,11,31)
	--		and [APCSProDB].[trans].[lot_process_records].[lot_id] in (select [lot_process_records].[lot_id]
	--			from [APCSProDB].[trans].[lot_process_records]
	--			inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
	--			where [APCSProDB].[trans].[lots].[wip_state] in ('100','101')
	--			and [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
	--			and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @date_value + ' 08:00:00'
	--			group by [lot_process_records].[lot_id], [lot_process_records].[step_no])
	--		and [APCSProDB].[trans].[lot_process_records].[step_no] = 1
	--		group by [lot_process_records].[lot_id], [lot_process_records].[step_no]) as [lot_start]
	--	inner join(select [lot_process_records].[lot_id]
	--			, [lot_process_records].[step_no]
	--			, MAX(recorded_at) as [end_datetime]
	--		from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
	--		inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
	--		where [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
	--		and [APCSProDB].[trans].[lot_process_records].[lot_id] in (select [lot_process_records].[lot_id]
	--			from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
	--			inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
	--			where [APCSProDB].[trans].[lots].[wip_state] in ('100','101')
	--			and [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
	--			and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @date_value + ' 08:00:00'
	--			group by [lot_process_records].[lot_id], [lot_process_records].[step_no])
	--		and [APCSProDB].[trans].[lot_process_records].[step_no] = 1
	--		group by [lot_process_records].[lot_id], [lot_process_records].[step_no]) as [lot_end] on [lot_end].[lot_id] = [lot_start].[lot_id] and [lot_end].[step_no] = [lot_start].[step_no]
	--	) as [lot_processing_time] on [lot_processing_time].[lot_id] = [lots].[id]
	--	inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--	inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
	--	inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
	--	inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
	--	inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
	--	--inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [lots].[device_slip_id] and [device_flows].[step_no] = [lot_processing_time].[step_no]
	--	--inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [device_flows].[job_id]
	--	--inner join [APCSProDB].[method].[processes] on [processes].[id] = [jobs].[process_id]
	--	group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [lot_processing] on [lot_processing].[package_group] = [master_data].[package_group] and [lot_processing].[package] = [master_data].[package] and [lot_processing].[process] = [master_data].[process] and [lot_processing].[job] = [master_data].[job] and [lot_processing].[lot_type] = [master_data].[lot_type]
	--left join (select [package_groups].[name] as [package_group]
	--		, [packages].[name] as [package]
	--		, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
	--		, COUNT([lots].[id]) as [today_input]
	--		, SUM([lots].[qty_in]) as [today_input_pcs]
	--	from [APCSProDB].[trans].[lots] with (NOLOCK)
	--	inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--	inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
	--	inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
	--	inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
	--	inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
	--	inner join [APCSProDB].[trans].[days] with (NOLOCK) on [days].[id] = [lots].[in_date_id]
	--	where [APCSProDB].[trans].[lots].[wip_state] in ('20', '10', '0')
	--	and [days].[date_value] = @date_value
	--	group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [input_today] on [input_today].[package_group] = [master_data].[package_group] and [input_today].[package] = [master_data].[package] and [input_today].[lot_type] = [master_data].[lot_type]
	--left join(select [package_groups].[name] as [package_group]
	--		, [packages].[name] as [package]
	--		, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
	--		, COUNT([lots].[id]) as [today_output]
	--		, SUM([lots].[qty_in]) as [today_output_pcs]
	--	from [APCSProDB].[trans].[lots] with (NOLOCK)
	--	inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--	inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
	--	inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
	--	inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
	--	inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
	--	where [lots].[id] in(select [lot_process_records].[lot_id]
	--		from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
	--		inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
	--		where [APCSProDB].[trans].[lots].[wip_state] in ('100','101')
	--		and [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
	--		and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @date_value + ' 08:00:00'
	--		group by [lot_process_records].[lot_id], [lot_process_records].[step_no])
	--	group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [output_today] on [output_today].[package_group] = [master_data].[package_group] and [output_today].[package] = [master_data].[package] and [output_today].[lot_type] = [master_data].[lot_type]
	
	
	order by [master_data].[package_group], [master_data].[package], [master_data].[process], [master_data].[job], [master_data].[lot_type]

	delete from [10.29.1.230].[DWH].[cac].[wip_monitor_main] where [date_value] = @date_value
	insert into [10.29.1.230].[DWH].[cac].[wip_monitor_main]
	([date_value]
		,[package_group]
		,[package]
		,[process]
		,[job]
		,[lot_type]
		,[normal]
		,[normal_pcs]
		,[delay]
		,[delay_pcs]
		,[order_delay]
		,[order_delay_pcs]
		,[order_delay_hold]
		,[order_delay_hold_pcs]
		,[hold]
		,[hold_pcs]
		,[total]
		,[total_pcs]
		,[machine]
		,[machine_pcs]
		,[actual_result]
		,[actual_result_pcs]
		,[yesterday_result]
		,[yesterday_result_pcs]
		,[seq_no]
		,[processing_time]
		,[wip_time]
		,[today_input]
		,[today_input_pcs]
		,[today_output]
		,[today_output_pcs]
        ,[specialflow]
        ,[specialflow_pcs]
		,[order_delay_special]
		,[order_delay_special_pcs])
	select [date_value]
		,[package_group]
		,[package]
		,[process]
		,[job]
		,[lot_type]
		,[normal]
		,[normal_pcs]
		,[delay]
		,[delay_pcs]
		,[order_delay]
		,[order_delay_pcs]
		,[order_delay_hold]
		,[order_delay_hold_pcs]
		,[hold]
		,[hold_pcs]
		,[total]
		,[total_pcs]
		,[machine]
		,[machine_pcs]
		,[actual_result]
		,[actual_result_pcs]
		,[yesterday_result]
		,[yesterday_result_pcs]
		,[seq_no]
		,[processing_time]
		,[wip_time]
		,[today_input]
		,[today_input_pcs]
		,[today_output]
		,[today_output_pcs]
		,[specialflow]
        ,[specialflow_pcs]
		,[order_delay_special]
		,[order_delay_special_pcs]
	from [10.29.1.230].[DWH].[cac].[wip_monitor_main_temp] with (NOLOCK)
	where [date_value] = @date_value
END