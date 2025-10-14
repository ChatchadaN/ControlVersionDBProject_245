-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wip_monitor_delay_lot_v2]
	-- Add the parameters for the stored procedure here
	@package_group varchar(50) = '%'
	, @package varchar(50) = '%'
	, @lot_type varchar(50) = '%'
	, @status int = 1
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
	IF(@status = 4)
	BEGIN 
		select [master_data].[package_group]
		, [master_data].[range_group]
		, case when [counter].[lot_count] is null then 0 else [counter].[lot_count] end as [lot_count]
		, case when [counter].[lot_count_pcs] is null then 0 else [counter].[lot_count_pcs] end as [lot_count_pcs]
		from (select [package_groups].[name] as [package_group]
			, [range_all].[range_group]
					from [APCSProDB].[trans].[lots] with (NOLOCK)
					inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
					inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
					inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
					inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
					inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
					inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
					inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
					inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
					inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
					--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
					inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
					left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

					left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
					left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
					left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
					left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
					left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

			,(select '1-2' as [range_group]
				union
				select '3-4' as [range_group]
				union
				select '5-6' as [range_group]
				union
				select '7-8' as [range_group]
				union
				select '9-10' as [range_group]) as [range_all]
			where [lots].[wip_state] in ('20','10','0')
			and DATEDIFF(DAY,[days2].[date_value],@date_value) > 0
			and DATEDIFF(DAY,[days2].[date_value],@date_value) <= 10
			and [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
			and [lots].[lot_no] <> '9999A9999V'
			group by [package_groups].[name], [range_all].[range_group]) as [master_data]
			left join (select [package_groups].[name] as [package_group]
				, case
					when CONVERT(int, ROUND(DATEDIFF(DAY,[days2].[date_value],@date_value)/2.0,0)) = 1 then '1-2'
					when CONVERT(int, ROUND(DATEDIFF(DAY,[days2].[date_value],@date_value)/2.0,0)) = 2 then '3-4'
					when CONVERT(int, ROUND(DATEDIFF(DAY,[days2].[date_value],@date_value)/2.0,0)) = 3 then '5-6'
					when CONVERT(int, ROUND(DATEDIFF(DAY,[days2].[date_value],@date_value)/2.0,0)) = 4 then '7-8'
					when CONVERT(int, ROUND(DATEDIFF(DAY,[days2].[date_value],@date_value)/2.0,0)) = 5 then '9-10'
					else '10+' end as [range_group]
				, COUNT([lots].[lot_no]) as [lot_count]
				, SUM([lots].[qty_in]) as [lot_count_pcs]
					from [APCSProDB].[trans].[lots] with (NOLOCK)
					inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
					inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
					inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
					inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
					inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
					inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
					inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
					inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
					inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
					--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
					inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
					left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

					left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
					left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
					left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
					left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
					left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

			where [lots].[wip_state] in ('20','10','0')
			and DATEDIFF(DAY,[days2].[date_value],@date_value) > 0
			and DATEDIFF(DAY,[days2].[date_value],@date_value) <= 10
			and [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
			and [lots].[lot_no] <> '9999A9999V'
			group by [package_groups].[name], CONVERT(int, ROUND(DATEDIFF(DAY,[days2].[date_value],@date_value)/2.0,0))) as [counter] on [counter].[package_group] = [master_data].[package_group] and [counter].[range_group] = [master_data].[range_group]
			
			union
			select 'ALL' as [package_group]
				, 'TOTAL' as [range_group]
				, COUNT([lots].[lot_no]) as [lot_count]
				, SUM([lots].[qty_in]) as [lot_count_pcs]
					from [APCSProDB].[trans].[lots] with (NOLOCK)
					inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
					inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
					inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
					inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
					inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
					inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
					inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
					inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
					inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
					--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
					inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
					left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

					left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
					left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
					left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
					left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
					left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

			where [lots].[wip_state] in ('20','10','0')
			and DATEDIFF(DAY,[days2].[date_value],@date_value) > 0
			and DATEDIFF(DAY,[days2].[date_value],@date_value) <= 10
			and [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
			and [lots].[lot_no] <> '9999A9999V'
	END
	IF(@status = 2)
	BEGIN

		select 'ALL' as [package_group]
			, 'TOTAL' as [range_group]
			, COUNT([lots].[lot_no]) as [lot_count]
			, SUM([lots].[qty_in]) as [lot_count_pcs]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
		--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
		left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

		left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
		left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
		left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
		left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
		left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

		where [lots].[wip_state] in ('20','10','0')
		--and [device_flows].[is_skipped] = '0'
		and [package_groups].[name] like @package_group
		and [packages].[name] like @package
		and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		and DATEDIFF(DAY,[days2].[date_value],@date_value) > 10
		and [lots].[lot_no] <> '9999A9999V'

		union

		select [master_data].[package_group]
		, [master_data].[range_group]
		, case when [counter].[lot_count] is null then 0 else [counter].[lot_count] end as [lot_count]
		, case when [counter].[lot_count_pcs] is null then 0 else [counter].[lot_count_pcs] end as [lot_count_pcs]
		from (select [package_groups].[name] as [package_group]
			, [range_all].[range_group]
			from [APCSProDB].[trans].[lots] with (NOLOCK)
			inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
			inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
			inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
			inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
			inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
			inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
			inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
			inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
			--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
			inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
			left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

			left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
			left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
			left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
			left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
			left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

			,(select '11-20' as [range_group]
				union
				select '21-30' as [range_group]
				union
				select '31-40' as [range_group]
				union
				select '40+' as [range_group]) as [range_all]
			where [lots].[wip_state] in ('20','10','0')
			and DATEDIFF(DAY,[days2].[date_value],@date_value) > 10
			and [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
			and [lots].[lot_no] <> '9999A9999V'
			group by [package_groups].[name], [range_all].[range_group]) as [master_data]

		left join (select [table1].[package_group],
						[table1].[range_group],
						SUM([table1].[lot_count]) as [lot_count],
						SUM([table1].[lot_count_pcs]) as [lot_count_pcs]
					from (select [package_groups].[name] as [package_group]
							, case
								when CONVERT(int, CEILING((DATEDIFF(DAY,[days2].[date_value],@date_value)-10)/10.0)) = 1 then '11-20'
								when CONVERT(int, CEILING((DATEDIFF(DAY,[days2].[date_value],@date_value)-10)/10.0)) = 2 then '21-30'
								when CONVERT(int, CEILING((DATEDIFF(DAY,[days2].[date_value],@date_value)-10)/10.0)) = 3 then '31-40'
								else '40+' end as [range_group]
								, COUNT([lots].[lot_no]) as [lot_count]
								, SUM([lots].[qty_in]) as [lot_count_pcs]
							from [APCSProDB].[trans].[lots] with (NOLOCK)
							inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
							inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
							inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
							inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
							inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
							inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
							inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
							inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
							inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
							--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
							inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
							left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

							left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
							left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
							left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
							left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
							left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

							where [lots].[wip_state] in ('20','10','0')
							and DATEDIFF(DAY,[days2].[date_value],@date_value) > 10
							and [package_groups].[name] like @package_group
							and [packages].[name] like @package
							and SUBSTRING([lots].[lot_no],5,1) like @lot_type
							and [lots].[lot_no] <> '9999A9999V'
							group by [package_groups].[name], CONVERT(int, CEILING((DATEDIFF(DAY,[days2].[date_value],@date_value)-10)/10.0))
						) as table1
						group by [package_group],[range_group]) as [counter] 
		on [counter].[package_group] = [master_data].[package_group] 
		and [counter].[range_group] = [master_data].[range_group]

	END
	IF(@status = 3)
	BEGIN
		select 'ALL' as [package_group]
			, 'TOTAL' as [range_group]
			, COUNT([lots].[lot_no]) as [lot_count]
			, SUM([lots].[qty_in]) as [lot_count_pcs]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
		--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
		left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

		left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
		left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
		left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
		left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
		left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

		where [lots].[wip_state] in ('20','10','0')
		and DATEDIFF(DAY,[days2].[date_value],@date_value) > 0
		--and DATEDIFF(DAY,[days2].[date_value],@date_value) <= 10
		and [package_groups].[name] like @package_group
		and [packages].[name] like @package
		and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		and [lots].[lot_no] <> '9999A9999V'
		union
		select [master_data].[package_group]
		, [master_data].[range_group]
		, case when [counter].[lot_count] is null then 0 else [counter].[lot_count] end as [lot_count]
		, case when [counter].[lot_count_pcs] is null then 0 else [counter].[lot_count_pcs] end as [lot_count_pcs]
		from (select [package_groups].[name] as [package_group]
			, [range_all].[range_group]
			from [APCSProDB].[trans].[lots] with (NOLOCK)
			inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
			inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
			inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
			inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
			inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
			inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
			inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
			inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
			--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
			inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
			left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

			left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
			left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
			left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
			left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
			left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

			,(select '1-2' as [range_group]
				union
				select '3-4' as [range_group]
				union
				select '5-6' as [range_group]
				union
				select '7-8' as [range_group]
				union
				select '9-10' as [range_group]) as [range_all]
			where [lots].[wip_state] in ('20','10','0')
			and DATEDIFF(DAY,[days2].[date_value],@date_value) > 0
			and DATEDIFF(DAY,[days2].[date_value],@date_value) <= 10
			and [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
			and [lots].[lot_no] <> '9999A9999V'
			group by [package_groups].[name], [range_all].[range_group]) as [master_data]
		left join (select [package_groups].[name] as [package_group]
				, case
					when CONVERT(int, ROUND(DATEDIFF(DAY,[days2].[date_value],@date_value)/2.0,0)) = 1 then '1-2'
					when CONVERT(int, ROUND(DATEDIFF(DAY,[days2].[date_value],@date_value)/2.0,0)) = 2 then '3-4'
					when CONVERT(int, ROUND(DATEDIFF(DAY,[days2].[date_value],@date_value)/2.0,0)) = 3 then '5-6'
					when CONVERT(int, ROUND(DATEDIFF(DAY,[days2].[date_value],@date_value)/2.0,0)) = 4 then '7-8'
					when CONVERT(int, ROUND(DATEDIFF(DAY,[days2].[date_value],@date_value)/2.0,0)) = 5 then '9-10'
					else '10+' end as [range_group]
				, COUNT([lots].[lot_no]) as [lot_count]
				, SUM([lots].[qty_in]) as [lot_count_pcs]
			from [APCSProDB].[trans].[lots] with (NOLOCK)
			inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
			inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
			inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
			inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
			inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
			inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
			inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
			inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
			--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
			inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
			left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

			left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
			left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
			left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
			left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
			left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

			where [lots].[wip_state] in ('20','10','0')
			and DATEDIFF(DAY,[days2].[date_value],@date_value) > 0
			and DATEDIFF(DAY,[days2].[date_value],@date_value) <= 10
			and [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
			and [lots].[lot_no] <> '9999A9999V'
			group by [package_groups].[name], CONVERT(int, ROUND(DATEDIFF(DAY,[days2].[date_value],@date_value)/2.0,0))) as [counter] on [counter].[package_group] = [master_data].[package_group] and [counter].[range_group] = [master_data].[range_group]
		union
		select [master_data].[package_group]
		, [master_data].[range_group]
		, case when [counter].[lot_count] is null then 0 else [counter].[lot_count] end as [lot_count]
		, case when [counter].[lot_count_pcs] is null then 0 else [counter].[lot_count_pcs] end as [lot_count_pcs]
		from (select [package_groups].[name] as [package_group]
			, [range_all].[range_group]
			from [APCSProDB].[trans].[lots] with (NOLOCK)
			inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
			inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
			inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
			inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
			inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
			inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
			inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
			inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
			--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
			inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
			left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

			left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
			left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
			left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
			left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
			left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

			,(select 'Higher 10' as [range_group]
				) as [range_all]
			where [lots].[wip_state] in ('20','10','0')
			and DATEDIFF(DAY,[days2].[date_value],@date_value) > 10
			and [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
			and [lots].[lot_no] <> '9999A9999V'
			group by [package_groups].[name], [range_all].[range_group]) as [master_data]
		left join (select [package_groups].[name] as [package_group]
				, 'Higher 10' as [range_group]
				, COUNT([lots].[lot_no]) as [lot_count]
				, SUM([lots].[qty_in]) as [lot_count_pcs]
			from [APCSProDB].[trans].[lots] with (NOLOCK)
			inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
			inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
			inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
			inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
			inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
			inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
			inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
			inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
			--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
			inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
			left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

			left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
			left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
			left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
			left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
			left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

			where [lots].[wip_state] in ('20','10','0')
			and DATEDIFF(DAY,[days2].[date_value],@date_value) > 10
			and [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
			and [lots].[lot_no] <> '9999A9999V'
			group by [package_groups].[name]) as [counter] on [counter].[package_group] = [master_data].[package_group] and [counter].[range_group] = [master_data].[range_group]

	END
	IF(@status = 1)
	BEGIN 
		select 'ALL' as [package_group]
			, 'TOTAL' as [range_group]
			, COUNT([lots].[lot_no]) as [lot_count]
			, SUM([lots].[qty_in]) as [lot_count_pcs]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
		--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
		left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

		left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
		left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
		left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
		left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
		left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

		where [lots].[wip_state] in ('20','10','0')
		and DATEDIFF(DAY,[days2].[date_value],@date_value) >= 1
		and DATEDIFF(DAY,[days2].[date_value],@date_value) <= 10
		and [package_groups].[name] like @package_group
		and [packages].[name] like @package
		and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		and [lots].[lot_no] <> '9999A9999V'
		union
		select [master_data].[package_group]
		, [master_data].[range_group]
		, case when [counter].[lot_count] is null then 0 else [counter].[lot_count] end as [lot_count]
		, case when [counter].[lot_count_pcs] is null then 0 else [counter].[lot_count_pcs] end as [lot_count_pcs]
		from (select [package_groups].[name] as [package_group]
			, [range_all].[range_group]
			from [APCSProDB].[trans].[lots] with (NOLOCK)
			inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
			inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
			inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
			inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
			inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
			inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
			inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
			inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
			--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
			inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
			left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

			left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
			left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
			left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
			left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
			left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

			,(
				select '-01' as [range_group]
				union
				select '00' as [range_group]
				union
				select '01' as [range_group]
				union
				select '02' as [range_group]
				union
				select '03' as [range_group]
				union
				select '04' as [range_group]
				union
				select '05' as [range_group]
				union
				select '06' as [range_group]
				union
				select '07' as [range_group]
				union
				select '08' as [range_group]
				union
				select '09' as [range_group]
				union
				select '10' as [range_group]) as [range_all]
			where [lots].[wip_state] in ('20','10','0')
			and DATEDIFF(DAY,[days2].[date_value],@date_value) >= -1 --'-1'
			and DATEDIFF(DAY,[days2].[date_value],@date_value) <= 10
			and [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
			and [lots].[lot_no] <> '9999A9999V'
			group by [package_groups].[name], [range_all].[range_group]) as [master_data]
		left join (select [package_groups].[name] as [package_group]
				, DATEDIFF(DAY,[days2].[date_value],@date_value) as [range_group]
				, COUNT([lots].[lot_no]) as [lot_count]
				, SUM([lots].[qty_in]) as [lot_count_pcs]
			from [APCSProDB].[trans].[lots] with (NOLOCK)
			inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
			inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
			inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
			inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
			inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
			inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
			inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
			inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
			--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
			inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
			left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

			left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
			left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
			left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
			left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
			left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

			where [lots].[wip_state] in ('20','10','0')
			and DATEDIFF(DAY,[days2].[date_value],@date_value) >= -1 -- '-1'
			and DATEDIFF(DAY,[days2].[date_value],@date_value) <= 10
			and [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
			and [lots].[lot_no] <> '9999A9999V'
			group by [package_groups].[name], DATEDIFF(DAY,[days2].[date_value],@date_value)) as [counter] on [counter].[package_group] = [master_data].[package_group] and [counter].[range_group] = [master_data].[range_group]
	END
	--backup add grahp 00
	IF(@status = 5)
	BEGIN 
		select [master_data].[package_group]
		, [master_data].[range_group]
		, case when [counter].[lot_count] is null then 0 else [counter].[lot_count] end as [lot_count]
		, case when [counter].[lot_count_pcs] is null then 0 else [counter].[lot_count_pcs] end as [lot_count_pcs]
		from (select [package_groups].[name] as [package_group]
			, [range_all].[range_group]
					from [APCSProDB].[trans].[lots] with (NOLOCK)
					inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
					inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
					inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
					inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
					inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
					inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
					inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
					inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
					inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
					--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
					inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
					left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

					left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
					left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
					left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
					left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
					left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

			,(
				select '00' as [range_group]
				union
				select '01' as [range_group]
				union
				select '02' as [range_group]
				union
				select '03' as [range_group]
				union
				select '04' as [range_group]
				union
				select '05' as [range_group]
				union
				select '06' as [range_group]
				union
				select '07' as [range_group]
				union
				select '08' as [range_group]
				union
				select '09' as [range_group]
				union
				select '10' as [range_group]) as [range_all]
			where [lots].[wip_state] in ('20','10','0')
			and DATEDIFF(DAY,[days2].[date_value],@date_value) >= 0
			and DATEDIFF(DAY,[days2].[date_value],@date_value) <= 10
			and [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
			and [lots].[lot_no] <> '9999A9999V'
			group by [package_groups].[name], [range_all].[range_group]) as [master_data]
		left join (select [package_groups].[name] as [package_group]
				, DATEDIFF(DAY,[days2].[date_value],@date_value) as [range_group]
				, COUNT([lots].[lot_no]) as [lot_count]
				, SUM([lots].[qty_in]) as [lot_count_pcs]
					from [APCSProDB].[trans].[lots] with (NOLOCK)
					inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
					inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
					inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
					inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
					inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
					inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
					inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
					inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
					inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
					--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
					inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
					left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

					left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
					left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
					left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
					left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
					left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

			where [lots].[wip_state] in ('20','10','0')
			and DATEDIFF(DAY,[days2].[date_value],@date_value) >= 0
			and DATEDIFF(DAY,[days2].[date_value],@date_value) <= 10
			and [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
			and [lots].[lot_no] <> '9999A9999V'
			group by [package_groups].[name], DATEDIFF(DAY,[days2].[date_value],@date_value)) as [counter] on [counter].[package_group] = [master_data].[package_group] and [counter].[range_group] = [master_data].[range_group]
		union
		select 'ALL' as [package_group]
			, 'TOTAL' as [range_group]
			, COUNT([lots].[lot_no]) as [lot_count]
			, SUM([lots].[qty_in]) as [lot_count_pcs]
				from [APCSProDB].[trans].[lots] with (NOLOCK)
				inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
				inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
				inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
				inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
				inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
				inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
				inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
				inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
				inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
				--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
				inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
				left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] with (NOLOCK) on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]

				left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
				left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
				left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
				left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
				left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

		where [lots].[wip_state] in ('20','10','0')
		and DATEDIFF(DAY,[days2].[date_value],@date_value) >= 0
		and DATEDIFF(DAY,[days2].[date_value],@date_value) <= 10
		and [package_groups].[name] like @package_group
		and [packages].[name] like @package
		and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		and [lots].[lot_no] <> '9999A9999V'
	END
END
