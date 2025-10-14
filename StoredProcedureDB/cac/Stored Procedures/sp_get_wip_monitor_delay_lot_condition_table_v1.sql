-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wip_monitor_delay_lot_condition_table_v1]
	-- Add the parameters for the stored procedure here
	  @package_group varchar(50) = '%'
	, @package varchar(50) = '%'
	, @device varchar(50) = '%'
	, @process varchar(50) = '%'
	, @lot_type varchar(50) = '%'
	, @unit int = 1	
	, @day_condition int = 2

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @rohm_date_start datetime = convert(datetime,convert(varchar(10), GETDATE(), 120))
	DECLARE @rohm_date_end datetime = convert(datetime,convert(varchar(10), GETDATE(), 120) + ' 08:00:00')
	DECLARE @date_value varchar(10)
	DECLARE @yesterday_date_value varchar(10)
	DECLARE @day_delay_condition int


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

	SELECT @day_delay_condition =  [daycondition] FROM [APCSProDWH].[cac].[day_delay_condition]

    -- Insert statements for procedure here
	IF(@unit = 1)
	BEGIN
		select [packages].[name] as [package]
		, [device_names].[name] as [device]
		--, [lots].[id] as [lot_id]
		, [lots].[lot_no] as [lot]	
		, [days1].[date_value] as [in_day]
		, DATEDIFF(DAY,[days2].[date_value],@date_value) as [delay_day]
		, [lots].[qty_in] as [pieces]
		, [processes].[name] as [process]
		, case when [lots].[is_special_flow] = 1 then [processes2].[name] ELSE '-' end as [special_flow]
		--, [jobs].[name] as [job]
		, case when [lots].[process_state] = 0 then '#FFDF00' else '#7cfc00' end as process_color
		, case when [lots].[quality_state] = 3 then '#ff9966' else '#c4adc4' end as lot_color
		, [wip_monitor_delay_lot_condition_detail].[status]
		, [wip_monitor_delay_lot_condition_detail].[problem_point]
		, [wip_monitor_delay_lot_condition_detail].[incharge]
		, [wip_monitor_delay_lot_condition_detail].[occure_date]
		, [wip_monitor_delay_lot_condition_detail].[plan_date]
		, case when [wip_monitor_delay_lot_condition_detail].[plan_date] <= @date_value then 'hotpink' else '' end as [plan_date_color]
		, [lots].[updated_at] as [update_date]
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
		and [device_names].[name] like @device
		and [processes].[name] like @process
		and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		and DATEDIFF(DAY,[days2].[date_value],@date_value) >= @day_delay_condition
		order by [lots].[lot_no], [device_flows].[step_no]
	End
	IF(@unit = 2)
	BEGIN		
		select 
		  [packages].[name] as package
		, [device_names].[name] as device
		, [lots].[lot_no] as [lot]		
		, [days1].[date_value] as [in_day]
		, DATEDIFF(DAY,[days2].[date_value],GETDATE()) as delay_day
		, [lots].[qty_in] as [pieces]
		, [processes].[name] as [process]
		, case when [lots].[is_special_flow] = 1 then [processes2].[name] ELSE '-' end as [special_flow]
		, case when [lots].[process_state] = 0 then '#FFDF00' else '#7cfc00' end as process_color
		, case when [lots].[quality_state] = 3 then '#ff9966' else '#c4adc4' end as lot_color
		, [wip_monitor_no_movement_lot_detail].[status]
		, [wip_monitor_no_movement_lot_detail].[problem_point]
		, [wip_monitor_no_movement_lot_detail].[incharge]
		, [wip_monitor_no_movement_lot_detail].[plan_date]
		, case when [wip_monitor_no_movement_lot_detail].[plan_date] <= @date_value then 'hotpink' else '' end as [plan_date_color]
		, [lots].[updated_at] as [update_date]
		, DATEDIFF(DAY,[lots].[updated_at],GETDATE()) as [no_movement_day]
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
		inner join [APCSProDB].[trans].[item_labels] as [item_labels1] with (NOLOCK) on [item_labels1].[name] = 'lots.wip_state' and [item_labels1].[val] = [lots].[wip_state]
		inner join [APCSProDB].[trans].[item_labels] as [item_labels2] with (NOLOCK) on [item_labels2].[name] = 'lots.process_state' and [item_labels2].[val] = [lots].[process_state]
		inner join [APCSProDB].[trans].[item_labels] as [item_labels3] with (NOLOCK) on [item_labels3].[name] = 'lots.quality_state' and [item_labels3].[val] = [lots].[quality_state]
		left join [APCSProDB].[man].[users] as [users1] with (NOLOCK) on [users1].[id] = [lots].[updated_by]
		left join [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail] with (NOLOCK) on [wip_monitor_no_movement_lot_detail].[lot_no] = [lots].[lot_no]
		inner join [APCSProDB].[trans].[days] on [APCSProDB].[trans].[days].id = [APCSProDB].[trans].[lots].in_date_id

		left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
		left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and [special_flows].step_no = [lot_special_flows].step_no
		left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
		left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
		left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]

		where [package_groups].[name] like @package_group
		and [packages].[name] like @package
		and [device_names].[name] like @device
		and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		and [processes].[name] like @process
		and [APCSProDB].[trans].[days].[date_value] <= convert(date, getdate())
		and (GETDATE() - [lots].[updated_at]) > @day_condition
		and [lots].[wip_state] = '20'		
		and NOT(DATEDIFF(DAY,[days2].[date_value],@date_value) >= @day_delay_condition)
		order by [lots].[lot_no]
	END
END
