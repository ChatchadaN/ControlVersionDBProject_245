-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_set_wip_transition_process]
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
	delete from [APCSProDWH].[cac].[wip_transition_process] where [date_value] = @date_value
	insert into [APCSProDWH].[cac].[wip_transition_process]
	([date_value]
		,[package_group]
		,[package]
		,[process]
		,[job]
		,[lot_type]
		,[seq_no]
		,[today_input]
		,[today_input_pcs]
		,[today_output]
		,[today_output_pcs]
		,[today_wip]
		,[today_wip_pcs]
		,[today_order_delay]
		,[today_order_delay_pcs])
	select @date_value as [date_value]
		, [master_data].[package_group]
		, [master_data].[package]
		, [master_data].[process]
		, [master_data].[job]
		, [master_data].[lot_type]
		, [master_data].[seq_no]
		, case when [input_today].[today_input] is null then 0 else [input_today].[today_input] end as [today_input]
		, case when [input_today].[today_input_pcs] is null then 0 else [input_today].[today_input_pcs] end as [today_input_pcs]
		, case when [output_today].[today_output] is null then 0 else [output_today].[today_output] end as [today_output]
		, case when [output_today].[today_output_pcs] is null then 0 else [output_today].[today_output_pcs] end as [today_output_pcs]
		, case when [lot].[today_wip] is null then 0 else [lot].[today_wip] end as [today_wip]
		, case when [lot].[today_wip_pcs] is null then 0 else [lot].[today_wip_pcs] end as [today_wip_pcs]
		, case when [lot].[today_order_delay] is null then 0 else [lot].[today_order_delay] end as [today_order_delay]
		, case when [lot].[today_order_delay_pcs] is null then 0 else [lot].[today_order_delay_pcs] end as [today_order_delay_pcs]
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
		--where [APCSProDB].[trans].[lots].[wip_state] = '20'
		where [APCSProDB].[trans].[days].[date_value] <= convert(date, getdate())

		group by [package_groups].[name], [packages].[name], [processes].[name], [jobs].[name], [jobs].[seq_no], SUBSTRING([lots].[lot_no],5,1)) as [master_data]
	left join (select [package_groups].[name] as [package_group]
			, [packages].[name] as [package]
			, [processes].[name] as [process]
			, [jobs].[name] as [job]
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
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [lots].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		inner join [APCSProDB].[trans].[days] with (NOLOCK) on [days].[id] = [lots].[in_date_id]
		--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
		where [APCSProDB].[trans].[lots].[wip_state] = '20'
		group by [package_groups].[name], [packages].[name], [processes].[name], [jobs].[name], SUBSTRING([lots].[lot_no],5,1)) as [lot] on [lot].[package_group] = [master_data].[package_group] and [lot].[package] = [master_data].[package] and [lot].[process] = [master_data].[process] and [lot].[job] = [master_data].[job] and [lot].[lot_type] = [master_data].[lot_type]
	left join (select [package_groups].[name] as [package_group]
			, [packages].[name] as [package]
			, [processes].[name] as [process]
			, [jobs].[name] as [job]
			, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
			, COUNT(case when [days].[date_value] = @date_value then [APCSProDB].[trans].[lots].[lot_no] else NULL end) as [today_input] 
			, SUM(case when [days].[date_value] = @date_value then [APCSProDB].[trans].[lots].[qty_pass] else 0 end) as [today_input_pcs] 
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [lots].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		inner join [APCSProDB].[trans].[days] with (NOLOCK) on [days].[id] = [lots].[in_date_id]
		--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
		where [APCSProDB].[trans].[lots].[wip_state] in ('20','10','0')
		group by [package_groups].[name], [packages].[name], [processes].[name], [jobs].[name], SUBSTRING([lots].[lot_no],5,1)) as [input_today] on [input_today].[package_group] = [master_data].[package_group] and [input_today].[package] = [master_data].[package] and [input_today].[process] = [master_data].[process] and [input_today].[job] = [master_data].[job] and [input_today].[lot_type] = [master_data].[lot_type]
	left join(select [package_groups].[name] as [package_group]
			, [packages].[name] as [package]
			, [processes].[name] as [process]
			, [jobs].[name] as [job]
			, SUBSTRING([lots].[lot_no],5,1) as [lot_type]
			, COUNT([lots].[id]) as [today_output]
			, SUM([lots].[qty_in]) as [today_output_pcs]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[trans].[lot_process_records] with (NOLOCK) on [lot_process_records].[lot_id] = [lots].[id]
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [lots].[device_slip_id] and [device_flows].[step_no] = [lot_process_records].[step_no]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		where [lots].[id] in(select [lot_process_records].[lot_id]
			from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
			inner join [APCSProDB].[trans].[lots] with (NOLOCK) on [lots].[id] = [lot_process_records].[lot_id]
			where [APCSProDB].[trans].[lots].[wip_state] = '100'
			and [APCSProDB].[trans].[lot_process_records].[record_class] in (2,12,32)
			and [APCSProDB].[trans].[lot_process_records].[recorded_at] >= @date_value + ' 08:00:00'
			group by [lot_process_records].[lot_id], [lot_process_records].[step_no])
		group by [package_groups].[name], [packages].[name], [processes].[name], [jobs].[name], SUBSTRING([lots].[lot_no],5,1)) as [output_today] on [output_today].[package_group] = [master_data].[package_group] and [output_today].[package] = [master_data].[package] and [output_today].[process] = [master_data].[process] and [output_today].[job] = [master_data].[job] and [output_today].[lot_type] = [master_data].[lot_type]
	order by [master_data].[package_group], [master_data].[package], [master_data].[process], [master_data].[job], [master_data].[lot_type]
END
