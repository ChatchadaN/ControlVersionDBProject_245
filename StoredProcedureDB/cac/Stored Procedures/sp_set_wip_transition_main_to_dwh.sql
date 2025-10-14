-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_set_wip_transition_main_to_dwh] 
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

	--DELETE t1
 --FROM [10.29.1.230].[DWH].[cac].[wip_transition_main] AS t1
 --WHERE EXISTS (
 --    SELECT 1
 --    FROM [APCSProDWH].[cac].[wip_monitor_main] AS t2
 --    WHERE t1.[date_value] = t2.[date_value]
 --      AND t1.[package_group] = t2.[package_group]
 --      AND t1.[package] = t2.[package]
 --      AND t1.[process] = t2.[process]
 --      AND t1.[job] = t2.[job]
 --      AND t1.[lot_type] = t2.[lot_type]
 --      AND t1.[date_value] BETWEEN @date_value AND GETDATE() );

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
	--delete from [APCSProDWH].[cac].[wip_transition_main] where [date_value] = @date_value
	insert into [10.29.1.230].[DWH].[cac].[wip_transition_main]
	([date_value]
		,[package_group]
		,[package]
		,[lot_type]
		,[today_input]
		,[today_input_pcs]
		,[today_output]
		,[today_output_pcs]
		,[today_wip]
		,[today_wip_pcs]
		,[today_order_delay]
		,[today_order_delay_pcs]
		,[output_without_delay]
		,[output_without_delay_pcs]
		,[leadtime_min_minute]
		,[leadtime_max_minute]
		,[leadtime_avg_minute]
		,[factory]
		,[hq]
		,[division]
		,[product_family]
		,[partition_no])
	select @date_value as [date_value]
		, [master_data].[package_group]
		, [master_data].[package]
		, [master_data].[lot_type]
		, case when [input_today].[today_input] is null then 0 else [input_today].[today_input] end as [today_input]
		, case when [input_today].[today_input_pcs] is null then 0 else [input_today].[today_input_pcs] end as [today_input_pcs]
		, case when [output_today].[today_output] is null then 0 else [output_today].[today_output] end as [today_output]
		, case when [output_today].[today_output_pcs] is null then 0 else [output_today].[today_output_pcs] end as [today_output_pcs]
		, case when [lot].[today_wip] is null then 0 else [lot].[today_wip] end as [today_wip]
		, case when [lot].[today_wip_pcs] is null then 0 else [lot].[today_wip_pcs] end as [today_wip_pcs]
		, case when [lot].[today_order_delay] is null then 0 else [lot].[today_order_delay] end as [today_order_delay]
		, case when [lot].[today_order_delay_pcs] is null then 0 else [lot].[today_order_delay_pcs] end as [today_order_delay_pcs]
		, case when [output_today].[output_without_delay] is null then 0 else [output_today].[output_without_delay] end as [output_without_delay]
		, case when [output_today].[output_without_delay_pcs] is null then 0 else [output_today].[output_without_delay_pcs] end as [output_without_delay_pcs]
		, case when [leadtime].[leadtime_min_minute] is null then 0 else [leadtime].[leadtime_min_minute] end as [leadtime_min_minute]
		, case when [leadtime].[leadtime_max_minute] is null then 0 else [leadtime].[leadtime_max_minute] end as [leadtime_max_minute]
		, case when [leadtime].[leadtime_avg_minute] is null then 0 else [leadtime].[leadtime_avg_minute] end as [leadtime_avg_minute]
		, 'RIST' AS [factory]
		, 'LSI' AS [HQ]
		, 'LSI Production' as [division]	
		, 'LSI IC' as [product_family]
		, 20 AS [partition_no]
	from
		(select [package_groups].[name] as [package_group]
		, [packages].[name] as [package]
		, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[trans].[days] on [APCSProDB].[trans].[days].id = [APCSProDB].[trans].[lots].in_date_id
		--where [APCSProDB].[trans].[lots].[wip_state] = '20'

		and [APCSProDB].[trans].[days].[date_value] <= convert(date,getdate())

		group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [master_data]
	left join (select [package_groups].[name] as [package_group]
			, [packages].[name] as [package]
			, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
			, COUNT([lots].[lot_no]) as [today_wip]
			, SUM([lots].[qty_pass]) as [today_wip_pcs]
			, COUNT(case when DATEDIFF(DAY,[days2].[date_value],@date_value) >= 0 then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [today_order_delay] 
			, SUM(case when DATEDIFF(DAY,[days2].[date_value],@date_value) >= 0 then [APCSProDB].[trans].[lots].[qty_pass] else 0 end) as [today_order_delay_pcs] 
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[trans].[days] with (NOLOCK) on [days].[id] = [lots].[in_date_id]
		--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
		where [APCSProDB].[trans].[lots].[wip_state] in ('20','10','0')
		group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [lot] on [lot].[package_group] = [master_data].[package_group] and [lot].[package] = [master_data].[package] and [lot].[lot_type] = [master_data].[lot_type]
	left join (select [package_groups].[name] as [package_group]
			, [packages].[name] as [package]
			, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
			, COUNT(case when [days].[date_value] = @date_value then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [today_input] 
			, SUM(case when [days].[date_value] = @date_value then [APCSProDB].[trans].[lots].[qty_pass] else 0 end) as [today_input_pcs] 
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[trans].[days] with (NOLOCK) on [days].[id] = [lots].[in_date_id]
		--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
		group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [input_today] on [input_today].[package_group] = [master_data].[package_group] and [input_today].[package] = [master_data].[package] and [input_today].[lot_type] = [master_data].[lot_type]
	left join(select [package_groups].[name] as [package_group]
			, [packages].[name] as [package]
			, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
			, COUNT([lots].[id]) as [today_output]
			, SUM([lots].[qty_in]) as [today_output_pcs]
			, COUNT(case when DATEDIFF(DAY,[days2].[date_value],@date_value) < 0 then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [output_without_delay] 
			, SUM(case when DATEDIFF(DAY,[days2].[date_value],@date_value) < 0 then [APCSProDB].[trans].[lots].[qty_pass] else 0 end) as [output_without_delay_pcs] 
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
		where [lots].[id] in(select [lot_process_records].[lot_id]
			from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
			inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
			where [APCSProDB].[trans].[lots].[wip_state] in ('100','101')
			and [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
			and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @date_value + ' 08:00:00'
			group by [lot_process_records].[lot_id], [lot_process_records].[step_no])
		group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [output_today] on [output_today].[package_group] = [master_data].[package_group] and [output_today].[package] = [master_data].[package] and [output_today].[lot_type] = [master_data].[lot_type]
	left join(select [package_groups].[name] as [package_group]
			, [packages].[name] as [package]
			, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
			, MIN(DATEDIFF(minute,[min_date].[start_datetime],[max_date].[end_datetime])) as leadtime_min_minute
			, MAX(DATEDIFF(minute,[min_date].[start_datetime],[max_date].[end_datetime])) as leadtime_max_minute
			, AVG(DATEDIFF(minute,[min_date].[start_datetime],[max_date].[end_datetime])) as leadtime_avg_minute
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_versions].[device_name_id] = [device_names].[id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join (select [lot_process_records].[lot_id]
				, MIN(recorded_at) as [start_datetime]
			from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
			where [APCSProDB].[trans].[lot_process_records].[record_class] in (1,11,31)
			and [APCSProDB].[trans].[lot_process_records].[lot_id] in (select [lot_process_records].[lot_id]
				from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
				inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
				where [APCSProDB].[trans].[lots].[wip_state] = '100'
				and [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
				and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @date_value + ' 08:00:00'
				group by [lot_process_records].[lot_id])
			group by [lot_process_records].[lot_id]) as [min_date] on [min_date].[lot_id] = [lots].[id]
		inner join (select [lot_process_records].[lot_id]
				, MAX(recorded_at) as [end_datetime]
			from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
			where [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
			and [APCSProDB].[trans].[lot_process_records].[lot_id] in (select [lot_process_records].[lot_id]
				from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
				inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
				where [APCSProDB].[trans].[lots].[wip_state] = '100'
				and [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
				and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @date_value + ' 08:00:00'
				group by [lot_process_records].[lot_id])
			group by [lot_process_records].[lot_id]) as [max_date] on [max_date].[lot_id] = [lots].[id]
		where [lots].[wip_state] = 100
		group by [package_groups].[name], [packages].[name], SUBSTRING([lots].[lot_no],5,1)) as [leadtime] on [leadtime].[package_group] = [master_data].[package_group] and [leadtime].[package] = [master_data].[package] and [leadtime].[lot_type] = [master_data].[lot_type]
	order by [master_data].[package_group], [master_data].[package], [master_data].[lot_type]

END