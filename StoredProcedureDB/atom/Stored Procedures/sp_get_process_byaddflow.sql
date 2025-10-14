-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_process_byaddflow]
	-- Add the parameters for the stored procedure here
	@lot_id int
	, @process_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--select top 1 [table_flow].[step_no]
	--	, [table_flow].[job_name]
	--	, [table_flow].[process_name]
	--	, [table_flow].[process_id]
	--	, case when [lots].[step_no] is not null then 'WIP' else '' end as [status]
	--from (select [device_flows].[step_no]
	--			, [device_flows].[is_skipped]
	--			, [jobs].[name] as job_name
	--			, [processes].[name] as process_name
	--			, [processes].[id] as process_id
	--		from [APCSProDB].[method].[device_flows]
	--		inner join [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
	--		inner join [APCSProDB].[method].[processes] on [device_flows].[act_process_id] = [processes].[id]
	--		where [device_flows].[device_slip_id] = (select device_slip_id from [APCSProDB].[trans].[lots] where [lots].[id] = @lot_id)	
	--			and [device_flows].[is_skipped] != 1

	--		UNION ALL

	--		select [lot_special_flows].[step_no]
	--			, [lot_special_flows].[is_skipped]
	--			, [jobs].[name] as job_name
	--			, [processes].[name] as process_name
	--			, [processes].[id] as process_id
	--		from [APCSProDB].[trans].[lot_special_flows]
	--		inner join [APCSProDB].[method].[jobs] on [lot_special_flows].[job_id] = [jobs].[id]
	--		inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
	--		inner join [APCSProDB].[method].[processes] on [lot_special_flows].[act_process_id] = [processes].[id]
	--		where [special_flows].[lot_id] = @lot_id
	--			and [lot_special_flows].[is_skipped] != 1
	--	) as table_flow
	--left join (	select (case when APCSProDB.trans.lots.is_special_flow = 1 then 
	--							(select step_no FROM [APCSProDB].[trans].[special_flows] where id = APCSProDB.trans.lots.special_flow_id) 
	--					else APCSProDB.trans.lots.step_no 
	--				end ) as step_no
	--				, wip_state
	--				, process_state
	--			from [APCSProDB].[trans].[lots]
	--			where [id] = @lot_id
	--			) as [lots] on [table_flow].[step_no] = [lots].[step_no]
	--where process_id = @process_id 
	--	and [lots].[wip_state] = 20
	--	and [lots].[process_state] in (0,100)
	--order by [table_flow].[step_no]


	
	declare @step_no int = NULL
	declare @job_name varchar(30) = NULL
	declare @process_name varchar(30) = NULL
	declare @processes_id int = NULL
	declare @status nvarchar(100) = NULL

	select top 1 @step_no = [table_flow].[step_no]
		, @job_name = [table_flow].[job_name]
		, @process_name = [table_flow].[process_name]
		, @processes_id = [table_flow].[process_id]
		, @status = case when [lots].[step_no] is not null then 'WIP' else '' end 
		from (select [device_flows].[step_no]
				, [device_flows].[is_skipped]
				, [jobs].[name] as job_name
				, [processes].[name] as process_name
				, [processes].[id] as process_id
			from [APCSProDB].[method].[device_flows]
			inner join [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
			inner join [APCSProDB].[method].[processes] on [device_flows].[act_process_id] = [processes].[id]
			where [device_flows].[device_slip_id] = (select device_slip_id from [APCSProDB].[trans].[lots] where [lots].[id] = @lot_id)	
				and [device_flows].[is_skipped] != 1

			UNION ALL

			select [lot_special_flows].[step_no]
				, [lot_special_flows].[is_skipped]
				, [jobs].[name] as job_name
				, [processes].[name] as process_name
				, [processes].[id] as process_id
			from [APCSProDB].[trans].[lot_special_flows]
			inner join [APCSProDB].[method].[jobs] on [lot_special_flows].[job_id] = [jobs].[id]
			inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
			inner join [APCSProDB].[method].[processes] on [lot_special_flows].[act_process_id] = [processes].[id]
			where [special_flows].[lot_id] = @lot_id
				and [lot_special_flows].[is_skipped] != 1
		) as table_flow
	left join (	select (case when APCSProDB.trans.lots.is_special_flow = 1 then 
								(select step_no FROM [APCSProDB].[trans].[special_flows] where id = APCSProDB.trans.lots.special_flow_id) 
						else APCSProDB.trans.lots.step_no 
					end ) as step_no
					, wip_state
					, process_state
				from [APCSProDB].[trans].[lots]
				where [id] = @lot_id
				) as [lots] on [table_flow].[step_no] = [lots].[step_no]
	where process_id = @process_id 
		and [lots].[wip_state] = 20
		and [lots].[process_state] in (0,100)
	order by [table_flow].[step_no]


	if (@step_no IS NOT NULL AND @job_name IS NOT NULL AND @process_name IS NOT NULL AND @processes_id IS NOT NULL AND @status IS NOT NULL)
		begin
			select top 1 @step_no as [step_no]
				, @job_name as [job_name]
				, @process_name as [process_name]
				, @processes_id as[process_id]
				, N'Success' as [status]
		end
	else
		begin
			declare @wip_state varchar(10) = NULL	
			declare @process_state varchar(10) = NULL
			declare @quality_state varchar(10) = NULL
			declare @is_special_flow int = NULL

			SELECT 
				@job_name = [job_name]
				, @processes_id = [process_id]
				, @process_name = [process_name]
				, @wip_state = [wip_state]
				, @process_state = [process_state]
				, @quality_state = [quality_state]
				, @is_special_flow = [is_special_flow]
			FROM (select [lots].[id] as id
					, [lots].[lot_no] as lot_no
					, case when [lots].[is_special_flow] = 1 then [job2].[name] ELSE [jobs].[name] end as [job_name]
					, case when [lots].[is_special_flow] = 1 then [processes2].[name] ELSE [processes].[name] end as [process_name]
					, case when [lots].[is_special_flow] = 1 then [processes2].[id] ELSE [processes].[id] end as [process_id]
					, [item_labels3].[label_eng] as [quality_state]
					, [lots].[wip_state]
					, case when [lots].[is_special_flow] = 1 then [item_labels6].[label_eng] ELSE [item_labels2].[label_eng] end as [process_state]
					, [lots].[is_special_flow]
				from [APCSProDB].[trans].[lots] with (NOLOCK) 
				inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [lots].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
				inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
				inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
				inner join [APCSProDB].[trans].[item_labels] as [item_labels1] with (NOLOCK) on [item_labels1].[name] = 'lots.wip_state' and [item_labels1].[val] = [lots].[wip_state]
				inner join [APCSProDB].[trans].[item_labels] as [item_labels2] with (NOLOCK) on [item_labels2].[name] = 'lots.process_state' and [item_labels2].[val] = [lots].[process_state]
				inner join [APCSProDB].[trans].[item_labels] as [item_labels3] with (NOLOCK) on [item_labels3].[name] = 'lots.quality_state' and [item_labels3].[val] = [lots].[quality_state]

				left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
				left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and  [special_flows].step_no = [lot_special_flows].step_no
				left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
				left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
				left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]
		
				WHERE [lots].[wip_state] in ('10','20','0')

			) as TableAtom
			WHERE [id] = @lot_id

			order by [lot_no]

			if (@process_id != @processes_id)
				begin
					set @status = N'Flow ไม่อยู่ในช่วงที่กำหนด'
				end
			else if (@wip_state != '20' or @wip_state is null)
				 begin
					set @status = N'Wip State ไม่เท่ากับ WIP' 
				 end
			else if (@process_state != '0')
				begin
					set @status = N'Process State ไม่เท่ากับ Wait'
				end
			else if (@quality_state != '0' AND @is_special_flow != '0')
				begin
					set @status = N'Quality State ไม่เท่ากับ Normal(' + @quality_state + '||' + @is_special_flow + ') โปรดติดต่อ QC' 
				end
			
			select 0 as [step_no]
				, @job_name as [job_name]
				, @process_name as [process_name]
				, @processes_id as[process_id]
				, @status as [status]
		end

END