
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_user_main_v4]	-- Add the parameters for the stored procedure here	
	@lot_no varchar(10) = '%'
	, @package_group varchar(50) = '%'
	, @package varchar(50) = '%'
	, @device varchar(50) = '%'
	, @lot_type varchar(1) = '%'
	, @process varchar(50) = '%'
	, @job varchar(50) = '%'
	, @status varchar(50) = '%'
	, @process_state varchar(50) = '%'
	, @quality_state varchar(50) = '%'
	, @wip_state varchar(50) = '%'
	, @fab_wafer varchar(50) = '%'
	, @assy_name varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [id]
		, [lot_no]
		, [carrier_no]
		, [day_of_week]
		, [delay_status]
		, [delay_day]
		, [device]
		, [ft_device]
		, [package]
		, [tp_rank]
		, [operation]
		, [process_state]
		, [color_label_process_state]
		, [quality_state]
		, [color_label_quality_state]
			, [update_time]
		, [total]
		, [good]
		, [ng]
		, [operator]
		, [link]
		, [fabwf]
		, [assy_name]

		---** delete **---
		, 0 as [is_held]
		, 0 as [is_finished]
		---** delete **---
		, [andon]  
	FROM (select 
			--distinct 
			[lots].[id] as id
			, [lots].[lot_no] as lot_no
			, [lots].[carrier_no] as carrier_no
			, case when SUBSTRING([lots].[lot_no], 6, 1) = '1' then '#7b7b7b'
				when SUBSTRING([lots].[lot_no], 6, 1) = '2' then '#554067' 
				when SUBSTRING([lots].[lot_no], 6, 1) = '3' then '#c67c31'
				when SUBSTRING([lots].[lot_no], 6, 1) = '4' then '#f3f3f3' 
				when SUBSTRING([lots].[lot_no], 6, 1) = '5' then '#4b85a7' 
				when SUBSTRING([lots].[lot_no], 6, 1) = '6' then '#d6a439' 
			  else '#63944d' end as [day_of_week]
			, case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 then 'OrderDelay' ELSE 'Normal' end as [delay_status]
			, case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 then 'ORDER DELAY' ELSE 'NORMAL' end as [status]
			, DATEDIFF(DAY,[days2].[date_value],GETDATE()) as delay_day
			, [device_names].[name] as device
			, [device_names].[ft_name] as ft_device
			, [packages].[name] as package
			, [device_names].[tp_rank] as tp_rank
			--, [jobs].[name] as operation
			, case when [lots].[is_special_flow] = 1 then [job2].[name] ELSE [jobs].[name] end as operation
			, case when [lots].[is_special_flow] = 1 then [processes2].[name] ELSE [processes].[name] end as process
			--, [item_labels2].[label_eng] as process_state
			, case when [lots].[is_special_flow] = 1 then [item_labels6].[label_eng] ELSE [item_labels2].[label_eng] end as process_state
			, case when [lots].[is_special_flow] = 1 then [item_labels6].color_code ELSE [item_labels2].color_code end as [color_label_process_state]
			, [item_labels3].[label_eng] as quality_state
			, [item_labels3].color_code as color_label_quality_state
			, [lots].[updated_at] as update_time
			, [lots].[qty_in] as total
			, [lots].[qty_pass] as good
			, [lots].[qty_fail] as ng
			, [users1].[emp_num] as operator
			, case when [packages].[is_enabled] = 1 then 'http://webserv.thematrix.net/atom/User/Details/' + convert(varchar(50),[lots].[id]) else 'http://webserv.thematrix.net/apcsstaff/Default.aspx?lotNo=' + convert(varchar(10),[lots].[lot_no]) + '&goto=LotHistory' end as link
			--, [fabwafer].fab_wf_lot_no as fabwf
			--, case when [fabwafer].fab_wf_lot_no is not null then [fabwafer].fab_wf_lot_no else '' end as fabwf
			, '' as fabwf
			, [device_names].assy_name as [assy_name]
			, [andon_record].[job_id] as [andon]
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

		inner join [APCSProDB].[trans].[days] as [day_indate] with (NOLOCK) on [day_indate].id = [lots].in_plan_date_id
		left join [APCSProDB].[man].[users] as [users1] with (NOLOCK) on [users1].[id] = [lots].[updated_by]
		left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
		left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and  [special_flows].step_no = [lot_special_flows].step_no
		left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
		left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
		left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]
		outer apply (
					select top 1 job_id
					from  [APCSProDB].[trans].[lot_process_records]
					where  lot_id = lots.id
						and record_class IN (42,43)
				) as [andon_record]

		WHERE [day_indate].[date_value] <= convert(date, getdate())
		and   [package_groups].[name] like @package_group
		and   [lots].[wip_state] in (10,20,0)

	) as TableAtom
	WHERE lot_no like '%'+@lot_no+'%'
		and [package] like @package
		and [device] like @device
		and SUBSTRING([lot_no],5,1) like @lot_type
		and [process] like @process
		and [operation] like @job
		and [process_state] like @process_state
		and [quality_state] like @quality_state
		and [status] like @status
		and [fabwf] like @fab_wafer
		and [assy_name] like @assy_name
	order by [lot_no]

END
