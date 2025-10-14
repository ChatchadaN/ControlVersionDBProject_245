
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_lot_in_process]	-- Add the parameters for the stored procedure here	
	@lot_no varchar(10) = '%'
	, @lot_type varchar(1) = '%'
	, @package_group varchar(50) = '%'
	, @package varchar(50) = '%'
	, @device varchar(50) = '%'
	, @process varchar(50) = '%'
	, @job varchar(50) = '%'
	, @status varchar(50) = '%'
	, @process_state varchar(50) = '%'
	, @quality_state varchar(50) = '%'
	, @app_name varchar(100) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare @table_atom table
	(
		[id] int
		, [lot_no] varchar(20)
		, [lot_type] varchar(2)
		, [carrier_no] varchar(20)
		, [day_of_week] varchar(20)
		, [delay_status] varchar(20)
		, [delay_day] int
		, [device] varchar(20)
		, [assy_name] varchar(20)
		, [ft_device] varchar(20)
		, [package] varchar(20)
		, [package_group] varchar(20)
		, [tp_rank] varchar(10)
		, [operation] varchar(30)
		, [process] varchar(30)
		, [process_state] varchar(50)
		, [color_label_process_state] varchar(20)
		, [quality_state] varchar(50)
		, [color_label_quality_state] varchar(20)
		, [update_time] datetime
		, [total] int
		, [good] int
		, [ng] int
		, [operator] varchar(10)
		, [link] varchar(max)
		, [andon] int
		, [app_name] varchar(100)
		, [plan_shipdate] date
		, [e_slip_id] varchar(17)
	);
	
	insert into @table_atom
	select [id]
		, [lot_no]
		, [lot_type]
		, [carrier_no]
		, [day_of_week]
		, [delay_status]
		, [delay_day]
		, [device]
		, [assy_name]
		, [ft_device]
		, [package]
		, [package_group]
		, [tp_rank]
		, [operation]
		, [process]
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
		, [andon] 
		, [app_name]
		, [plan_shipdate]
		, [e_slip_id]
	from (
		select [lots].[id]
			, [lots].[lot_no]
			, substring([lot_no],5,1) as [lot_type]
			, isnull([lots].[carrier_no],'-') as [carrier_no]
			, case substring([lots].[lot_no],6,1)
				when '1' then '#7b7b7b'
				when '2' then '#554067' 
				when '3' then '#c67c31'
				when '4' then '#f3f3f3' 
				when '5' then '#4b85a7' 
				when '6' then '#d6a439' 
				else '#63944d' 
			end as [day_of_week]
			--, iif(datediff(day,[day_outdate].[date_value],getdate()) >= 0,'OrderDelay','Normal') as [delay_status]
			, case 
				when DATEADD(MINUTE,ISNULL([device_flows].[lead_time_sum] + 1440,0), CONVERT(DATETIME, [day_indate].[date_value])) <= GETDATE() and DATEDIFF(DAY, [day_outdate].[date_value],GETDATE()) < 0 AND [lots].[quality_state] <> 3 AND [lots].[quality_state] <> 4 THEN 'Delay' 
				when DATEADD(MINUTE,ISNULL([device_flows].[lead_time_sum] + 1440,0), CONVERT(DATETIME, [day_indate].[date_value])) > GETDATE() and DATEDIFF(DAY, [day_outdate].[date_value],GETDATE()) < 0 AND [lots].[quality_state] <> 3 AND [lots].[quality_state] <> 4 THEN 'Normal'
				when DATEDIFF(DAY, [day_outdate].[date_value], GETDATE()) >= 0 AND [lots].[quality_state] <> 3 AND [lots].[quality_state] <> 4 THEN 'OrderDelay'
				else 'N/A' 
			end as [delay_status]
			, datediff(day,[day_outdate].[date_value],getdate()) as [delay_day]
			, [device_names].[name] as [device]
			, [device_names].[assy_name]
			, [device_names].[ft_name] as [ft_device]
			, [packages].[name] as [package]
			, [package_groups].[name] as [package_group]
			, [device_names].[tp_rank]
			, iif([lots].[is_special_flow] = 1,[job_special].[name],[jobs].[name]) as [operation]
			, iif([lots].[is_special_flow] = 1,[process_special].[name],[processes].[name]) as [process]
			, iif([lots].[is_special_flow] = 1,[item_process_state_sp].[label_eng],[item_process_state].[label_eng]) as [process_state]
			, iif([lots].[is_special_flow] = 1,[item_process_state_sp].[color_code],[item_process_state].[color_code]) as [color_label_process_state]
			, [item_quality_state].[label_eng] as [quality_state] 
			, [item_quality_state].[color_code] as [color_label_quality_state]
			, [lots].[updated_at] as [update_time]
			, [lots].[qty_in] as [total]
			, [lots].[qty_pass] as [good]
			, [lots].[qty_fail] as [ng]
			, isnull([users].[emp_num],'-') as [operator]
			, iif([packages].[is_enabled] = 1,'http://webserv.thematrix.net/atom/User/Details/' + convert(varchar(50),[lots].[id]),'http://webserv.thematrix.net/apcsstaff/Default.aspx?lotNo=' + convert(varchar(10),[lots].[lot_no]) + '&goto=LotHistory') as [link]
			, [andon].[job_id] as [andon] 
			, isnull(trc.status + ',', '[],') + isnull(stop_lot.status + ',', '[],') + isnull(andon.status + ',', '[],') + isnull(ocr.status + ',', '[],') as [app_name]
			, [day_outdate1].[date_value] AS [plan_shipdate]
			, [lots].[e_slip_id]
		from [APCSProDB].[trans].[lots] with (nolock) 
		-------------------- date -------------------- 
		inner join [APCSProDB].[trans].[days] as [day_indate] with (nolock) on [day_indate].[id] = [lots].[in_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [day_outdate1] with (nolock) on [day_outdate1].[id] = [lots].[out_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [day_outdate] with (nolock) on [day_outdate].[id] = [lots].[modify_out_plan_date_id]
		-------------------- date -------------------- 
		inner join [APCSProDB].[method].[device_names] with (nolock) on [device_names].[id] = [lots].[act_device_name_id]
		inner join [APCSProDB].[method].[packages] with (nolock) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (nolock) on [package_groups].[id] = [packages].[package_group_id]
		-------------------- master_flows --------------------
		inner join [APCSProDB].[method].[device_flows] with (nolock) on [device_flows].[device_slip_id] = [lots].[device_slip_id] 
			and [device_flows].[step_no] = [lots].[step_no]
		inner join [APCSProDB].[method].[jobs] with (nolock) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] with (nolock) on [processes].[id] = [jobs].[process_id]
		-------------------- master_flows --------------------
		-------------------- special_flows -------------------- 
		left join [APCSProDB].[trans].[special_flows] with (nolock) on [special_flows].[id] = [lots].[special_flow_id] 
		left join [APCSProDB].[trans].[lot_special_flows] with (nolock) on [lot_special_flows].[special_flow_id] = [special_flows].[id] 
			and  [special_flows].[step_no] = [lot_special_flows].[step_no]
		left join [APCSProDB].[method].[jobs] as [job_special] with (nolock) on [job_special].[id] = [lot_special_flows].[job_id]
		left join [APCSProDB].[method].[processes] as [process_special] with (nolock) on [process_special].[id] = [job_special].[process_id]
		-------------------- special_flows -------------------- 
		-------------------- item_labels -------------------- 
		left join [APCSProDB].[trans].[item_labels] as [item_wip_state] with (nolock) on [item_wip_state].[name] = 'lots.wip_state' 
			and [item_wip_state].[val] = [lots].[wip_state]
		left join [APCSProDB].[trans].[item_labels] as [item_process_state] with (nolock) on [item_process_state].[name] = 'lots.process_state' 
			and [item_process_state].[val] = [lots].[process_state]
		left join [APCSProDB].[trans].[item_labels] as [item_quality_state] with (nolock) on [item_quality_state].[name] = 'lots.quality_state' 
			and [item_quality_state].[val] = [lots].[quality_state]
		left join [APCSProDB].[trans].[item_labels] as [item_process_state_sp] with (nolock) on [item_process_state_sp].[name] = 'lots.process_state' 
			and [item_process_state_sp].[val] = [special_flows].[process_state]
		-------------------- item_labels --------------------
		-------------------- users --------------------
		left join [APCSProDB].[man].[users] with (nolock) on [users].[id] = [lots].[updated_by]
		-------------------- users --------------------
		--outer apply (
		--	select top 1 [job_id]
		--	from [APCSProDB].[trans].[lot_process_records] with (nolock)
		--	where  lot_id = lots.id
		--		and record_class IN (42,43)
		--) as [andon_record]
		--outer apply (
		--	select top 1 '[TRC]' as [status]
		--	from [APCSProDB].[trans].[trc_controls] with (nolock)
		--	where  lot_id = lots.id
		--) as [trc]
		--outer apply (
		--	select top 1 '[StopLot]' as [status]
		--	from [APCSProDB].[trans].[lot_hold_controls] with (nolock)
		--	where  lot_id = lots.id
		--		and [system_name] = 'lot stop instruction'
		--) as [stop_lot]
		--outer apply (
		--	select top 1 '[Andon]' as [status]
		--	from [APCSProDB].[trans].[lot_hold_controls] with (nolock)
		--	where  lot_id = lots.id
		--		and [system_name] = 'andon'
		--) as [andon]
		--outer apply (
		--	select top 1 '[OCR]' as [status]
		--	from [APCSProDB].[trans].[lot_marking_verify] with (nolock)
		--	where lot_id = lots.id
		--) as [ocr]
		outer apply (
			select top 1 [job_id], '[Andon]' as [status]
			from [APCSProDB].[trans].[lot_process_records] with (nolock)
			where  lot_id = lots.id
				and record_class IN (42,43)
		) as [andon]
		outer apply (
			select top 1 '[TRC]' as [status]
			from [APCSProDB].[trans].[lot_process_records] with (nolock)
			where  lot_id = lots.id
				and record_class IN (52,53)
		) as [trc]
		outer apply (
			select top 1 '[StopLot]' as [status]
			from [APCSProDB].[trans].[lot_process_records] with (nolock)
			where  lot_id = lots.id
				and record_class IN (48)
		) as [stop_lot]
		outer apply (
			select top 1 '[OCR]' as [status]
			from [APCSProDB].[trans].[lot_process_records] with (nolock)
			where  lot_id = lots.id
				and record_class IN (130,131)
		) as [ocr]
		where [lots].[wip_state] in (10,20,0)
			and [day_indate].[date_value] <= convert(date, getdate())
	) as [lots];

	select [lots].[id]
		, [lots].[lot_no]
		, [lots].[carrier_no]
		, [lots].[day_of_week]
		, [lots].[delay_status]
		, [lots].[delay_day]
		, [lots].[device]
		, [lots].[assy_name]
		, [lots].[ft_device]
		, [lots].[package]
		, [lots].[tp_rank]
		, [lots].[operation]
		, [lots].[process_state]
		, [lots].[color_label_process_state]
		, [lots].[quality_state]
		, [lots].[color_label_quality_state]
		, [lots].[update_time]
		, [lots].[total]
		, [lots].[good]
		, [lots].[ng]
		, [lots].[operator]
		, [lots].[link]
		, [lots].[andon] 
		, [lots].[plan_shipdate]
		, [lots].[e_slip_id]
	from @table_atom as [lots]
	where [lots].[lot_no] like '%' + @lot_no + '%'
		and [lots].[lot_type] like @lot_type
		and [lots].[package_group] like @package_group
		and [lots].[package] like @package
		and [lots].[device] like @device
		and [lots].[process] like @process
		and [lots].[operation] like @job
		and [lots].[process_state] like @process_state
		and [lots].[quality_state] like @quality_state
		and upper([lots].[delay_status]) like REPLACE(@status, ' ', '')
		and [lots].[app_name] like '%_' + @app_name + '_%'
	order by [lots].[lot_no];
END
