-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_trans_lot_flows_operator_001]
	-- Add the parameters for the stored procedure here
	@lot_id int	
	--, @device_slip_id int
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
       -- Insert statements for procedure here
	declare @step_no_now int,	@package_id int
	select @step_no_now =
	(case when --APCSProDB.trans.lots.quality_state = 4 and 
			   APCSProDB.trans.lots.is_special_flow = 1 then 
			(select step_no FROM [APCSProDB].[trans].[special_flows] where id = APCSProDB.trans.lots.special_flow_id) 
		   else APCSProDB.trans.lots.step_no 
	 end ) 
	from APCSProDB.trans.lots
	where id = @lot_id

	--find package_id = 275 (TO263-3) for condition color
	select @package_id = act_package_id
	from APCSProDB.trans.lots
	where id = @lot_id

	select [device_flows].[step_no]
		, [device_flows].[is_skipped]
		, [jobs].[name] as job_name
		, [LotFlow].[record_class]
		, [LotFlow].[qty_in]
		, [LotFlow].[qty_pass]
		, [LotFlow].[qty_fail]

		, [LotFlow].[qty_last_pass]
		, [LotFlow].[qty_pass_step_sum]
		, [LotFlow].[qty_fail_step_sum]

		, [LotFlow].[qty_frame_in]
		, [LotFlow].[qty_frame_pass]
		, [LotFlow].[qty_frame_fail]
		, [LotFlow].[machine_id]
		, [LotFlow].[name] as machine_name
		, [LotFlow].[carrier_no]
		, [LotFlow].[next_carrier_no]
		, [LotFlow].[emp_num]
		, [LotFlow].[StartTime] as start_time
		, [LotFlow].[EndTime] as end_time
		, [LotFlow].[SetupTime] as setup_time
		, [item_labels1].[label_eng]
		, 0 as special_flow_id
		, 0 as lot_special_flow_id
		, '#000000' as [color_text]
		, CASE WHEN [device_flows].[is_skipped] = 1 THEN '#c7c7c7'
			   WHEN ([LotFlow].[record_class] IS NULL and [device_flows].[is_skipped] = 0 and [device_flows].[step_no] !=  @step_no_now)  THEN '#eeeeef' 
			   WHEN (([LotFlow].[record_class] IS NULL or [LotFlow].[record_class] = 20) and [device_flows].[is_skipped] = 0 and [device_flows].[step_no] =  @step_no_now)  THEN '#fffd07' 			   
			   --WHEN ([device_flows].[is_skipped] = 0 and [device_flows].[step_no] =  @step_no_now)  THEN '#fffd07'
			   ELSE [item_labels1].color_code 
		  END as [color_label]
		, [LotFlow].[qty_p_nashi]
		, [LotFlow].[qty_combined]
		, [LotFlow].[qty_hasuu]
		, [LotFlow].[qty_out]
		, [LotFlow].[qty_front_ng]
		, [LotFlow].[qty_marker]
		, [LotFlow].[qty_cut_frame]
		, case when @package_id = 275 and (jobs.id = 88 or jobs.id = 106 or jobs.id = 278) then '#e5f9c0'
		  else null end as [color_bg]
		,[device_flows].recipe
	from [APCSProDB].[method].[device_flows]
	left join
	(
		select [LotDetail].[record_class]
		, [LotDetail].[step_no]
		, [LotDetail].[qty_in]
		, [LotDetail].[qty_pass]
		, [LotDetail].[qty_fail]

		, lag([LotDetail].[qty_pass_step_sum],1,[LotDetail].[qty_last_pass]) over (order by [LotDetail].[step_no]) as [qty_last_pass]
		, [LotDetail].[qty_pass_step_sum]
		, [LotDetail].[qty_fail_step_sum]

		, lag([LotDetail].[qty_frame_pass],1,[LotDetail].[qty_frame_in]) over (order by [LotDetail].[step_no]) as [qty_frame_in]
		--, [LotDetail].[qty_frame_in]
		, [LotDetail].[qty_frame_pass]
		, [LotDetail].[qty_frame_fail]
		, [LotDetail].[machine_id]
		, [LotDetail].[carrier_no]
		, [LotDetail].[next_carrier_no]
		, [LotDetail].[name]
		, [LotDetail].[emp_num]
		, [LotStart].[StartTime]

		, [LotDetail].[qty_p_nashi]
		, [LotDetail].[qty_combined]
		, [LotDetail].[qty_hasuu]
		, [LotDetail].[qty_out]
		, [LotDetail].[qty_front_ng]
		, [LotDetail].[qty_marker]
		, [LotDetail].[qty_cut_frame]
		, case when ([LotStart].[StartTime] <= [LotEnd].[EndTime]) then cast([LotEnd].[EndTime] as datetime2) end as EndTime
		, [LotSetup].[SetupTime]
		from
		(
			select [step_no], MAX([id]) as max_id
			from [APCSProDB].[trans].[lot_process_records]
			where [lot_id] = @lot_id
			and [machine_id] > 0
			and [lot_process_records].[record_class] not in (25,26)
			group by [step_no]
		) as StepFlow
		inner join 
		(
			select [lot_process_records].[id]
			, [lot_process_records].[record_class]
			, [lot_process_records].[step_no]
			, [lot_process_records].[qty_in]
			, [lot_process_records].[qty_pass]
			, [lot_process_records].[qty_fail]

			, [lot_process_records].[qty_last_pass]
			, [lot_process_records].[qty_pass_step_sum]
			, [lot_process_records].[qty_fail_step_sum]

			, [lot_process_records].[qty_frame_in]
			, [lot_process_records].[qty_frame_pass]
			, [lot_process_records].[qty_frame_fail]
			, [lot_process_records].[machine_id]
			, [lot_process_records].[carrier_no]
			, [lot_process_records].[next_carrier_no]
			, [APCSProDB].[mc].[machines].[name]
			, [APCSProDB].[man].[users].[emp_num]

			, [lot_process_records].[qty_p_nashi]
			, [lot_process_records].[qty_combined]
			, [lot_process_records].[qty_hasuu]
			, [lot_process_records].[qty_out]
			, [lot_process_records].[qty_front_ng]
			, [lot_process_records].[qty_marker]
			, [lot_process_records].[qty_cut_frame]

			from [APCSProDB].[trans].[lot_process_records]
			left join [APCSProDB].[mc].[machines] on [lot_process_records].[machine_id] = [machines].[id]
			left join [APCSProDB].[man].[users] on [lot_process_records].[updated_by] = [users].[id] 
			where [lot_id] = @lot_id and [lot_process_records].[record_class] not in (25,26)
		) as LotDetail
		on LotDetail.id = StepFlow.max_id
		
		left join
		(
			--select [step_no],[machine_id],MAX([recorded_at]) as SetupTime
			--from [APCSProDB].[trans].[lot_process_records]
			--where [record_class] IN ('5') and [lot_id] = @lot_id
			--group by [step_no],[machine_id]
			----<< update by bass 31/01/2022
			select [step_no]
				,[machine_id]
				,[recorded_at] as SetupTime
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('5') and [lot_id] = @lot_id
			---->> update by bass 31/01/2022
		) as LotSetup
		on LotDetail.step_no = LotSetup.step_no and LotSetup.machine_id = LotSetup.machine_id
			and LotSetup.rowmax = 1 ----update by bass 31/01/2022

		left join
		(
			--select [step_no],[machine_id],MAX([recorded_at]) as StartTime
			--from [APCSProDB].[trans].[lot_process_records]
			--where [record_class] IN ('1','31') and [lot_id] = @lot_id
			--group by [step_no],[machine_id]
			----<< update by bass 31/01/2022
			select [step_no]
				,[machine_id]
				,[recorded_at] as StartTime
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('1','31') and [lot_id] = @lot_id
			---->> update by bass 31/01/2022
		) as LotStart
		on LotDetail.step_no = LotStart.step_no and LotDetail.machine_id = LotStart.machine_id
			and LotStart.rowmax = 1 ----update by bass 31/01/2022

		left join
		(
			--select [step_no],[machine_id],MAX([recorded_at]) as EndTime
			--from [APCSProDB].[trans].[lot_process_records]
			--where [record_class] IN ('2','12','32') and [lot_id] = @lot_id
			--group by [step_no],[machine_id]
			----<< update by bass 31/01/2022
			select [step_no]
				,[machine_id]
				,[recorded_at] as EndTime
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('2','12','32') and [lot_id] = @lot_id
			---->> update by bass 31/01/2022
		) as LotEnd
		on LotDetail.step_no = LotEnd.step_no and LotDetail.machine_id = LotEnd.machine_id
			and LotEnd.rowmax = 1 ----update by bass 31/01/2022
			
	) as LotFlow
	on [device_flows].[step_no] = [LotFlow].[step_no]
	inner join [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
	left join [APCSProDB].[trans].[item_labels] as [item_labels1] on [item_labels1].[name] = 'lot_process_records.record_class' and [item_labels1].[val] = [LotFlow].[record_class]
	where [device_flows].[device_slip_id] = (select device_slip_id from [APCSProDB].[trans].[lots] where [lots].[id] = @lot_id)	
		

	UNION ALL

		select  [lot_special_flows].[step_no]
		, [lot_special_flows].[is_skipped]
		, [jobs].[name] as job_name
		, [LotFlow].[record_class]
		, [LotFlow].[qty_in]
		, [LotFlow].[qty_pass]
		, [LotFlow].[qty_fail]

		, [LotFlow].[qty_last_pass]
		, [LotFlow].[qty_pass_step_sum]
		, [LotFlow].[qty_fail_step_sum]

		, [LotFlow].[qty_frame_in]
		, [LotFlow].[qty_frame_pass]
		, [LotFlow].[qty_frame_fail]
		, [LotFlow].[machine_id]
		, [LotFlow].[name] as machine_name
		, [LotFlow].[carrier_no]
		, [LotFlow].[next_carrier_no]
		, [LotFlow].[emp_num]
		, [LotFlow].[StartTime] as start_time
		, [LotFlow].[EndTime] as end_time
		, [LotFlow].[SetupTime] as setup_time
 		, [item_labels1].[label_eng]
		, [special_flows].[id] as special_flow_id
		, [lot_special_flows].[id] as lot_special_flow_id
		, '#cc00b7' as [color_text]
		, CASE WHEN [lot_special_flows].[is_skipped] = 1 THEN '#c7c7c7'
			   WHEN ([LotFlow].[record_class] IS NULL and [lot_special_flows].[is_skipped] = 0 and [lot_special_flows].[step_no] !=  @step_no_now)  THEN '#eeeeef' 
			   WHEN (([LotFlow].[record_class] IS NULL or [LotFlow].[record_class] = 20) and [lot_special_flows].[is_skipped] = 0 and [lot_special_flows].[step_no] =  @step_no_now)  THEN '#FFFF00' 
			   ELSE [item_labels1].color_code 
		  END as [color_label]

		, [LotFlow].[qty_p_nashi]
		, [LotFlow].[qty_combined]
		, [LotFlow].[qty_hasuu]
		, [LotFlow].[qty_out]
		, [LotFlow].[qty_front_ng]
		, [LotFlow].[qty_marker]
		, [LotFlow].[qty_cut_frame]
		, case when @package_id = 275 and (jobs.id = 88 or jobs.id = 106 or jobs.id = 278) then '#e5f9c0'
		  else null end as [color_bg]
		, [lot_special_flows].recipe
	from [APCSProDB].[trans].[lot_special_flows]
	left join
	(
		select [LotDetail].[record_class]
		, [LotDetail].[step_no]
		, [LotDetail].[qty_in]
		, [LotDetail].[qty_pass]
		, [LotDetail].[qty_fail]

		, lag([LotDetail].[qty_pass_step_sum],1,[LotDetail].[qty_last_pass]) over (order by [LotDetail].[step_no]) as [qty_last_pass]
		, [LotDetail].[qty_pass_step_sum]
		, [LotDetail].[qty_fail_step_sum]

		--, [LotDetail].[qty_frame_in]
		, lag([LotDetail].[qty_frame_pass],1,[LotDetail].[qty_frame_in]) over (order by [LotDetail].[step_no]) as [qty_frame_in]
		, [LotDetail].[qty_frame_pass]
		, [LotDetail].[qty_frame_fail]
		, [LotDetail].[machine_id]
		, [LotDetail].[carrier_no]
		, [LotDetail].[next_carrier_no]
		, [LotDetail].[name]
		, [LotDetail].[emp_num]
		, [LotStart].[StartTime]

		, [LotDetail].[qty_p_nashi]
		, [LotDetail].[qty_combined]
		, [LotDetail].[qty_hasuu]
		, [LotDetail].[qty_out]
		, [LotDetail].[qty_front_ng]
		, [LotDetail].[qty_marker]
		, [LotDetail].[qty_cut_frame]
		, case when ([LotStart].[StartTime] <= [LotEnd].[EndTime]) then cast([LotEnd].[EndTime] as datetime2) end as EndTime
		, [LotSetup].[SetupTime]
		from
		(
			select [step_no], MAX([id]) as max_id
			from [APCSProDB].[trans].[lot_process_records]
			where [lot_id] = @lot_id
			and [machine_id] > 0
			group by [step_no]
		) as StepFlow
		inner join 
		(
			select [lot_process_records].[id]
			, [lot_process_records].[record_class]
			, [lot_process_records].[step_no]
			, [lot_process_records].[qty_in]
			, [lot_process_records].[qty_pass]
			, [lot_process_records].[qty_fail]

			, [lot_process_records].[qty_last_pass]
			, [lot_process_records].[qty_pass_step_sum]
			, [lot_process_records].[qty_fail_step_sum]

			, [lot_process_records].[qty_frame_in]
			, [lot_process_records].[qty_frame_pass]
			, [lot_process_records].[qty_frame_fail]
			, [lot_process_records].[machine_id]
			, [lot_process_records].[carrier_no]
			, [lot_process_records].[next_carrier_no]
			, [APCSProDB].[mc].[machines].[name]
			, [APCSProDB].[man].[users].[emp_num]

			, [lot_process_records].[qty_p_nashi]
			, [lot_process_records].[qty_combined]
			, [lot_process_records].[qty_hasuu]
			, [lot_process_records].[qty_out]
			, [lot_process_records].[qty_front_ng]
			, [lot_process_records].[qty_marker]
			, [lot_process_records].[qty_cut_frame]
			from [APCSProDB].[trans].[lot_process_records]
			left join [APCSProDB].[mc].[machines] on [lot_process_records].[machine_id] = [machines].[id]
			left join [APCSProDB].[man].[users] on [lot_process_records].[updated_by] = [users].[id] 
			where [lot_id] = @lot_id and [lot_process_records].[record_class] not in (25,26)
		) as LotDetail
		on LotDetail.id = StepFlow.max_id
		
		left join
		(
			--select [step_no],[machine_id],MAX([recorded_at]) as SetupTime
			--from [APCSProDB].[trans].[lot_process_records]
			--where [record_class] IN ('5') and [lot_id] = @lot_id
			--group by [step_no],[machine_id]
			----<< update by bass 31/01/2022
			select [step_no]
				,[machine_id]
				,[recorded_at] as SetupTime
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('5') and [lot_id] = @lot_id
			---->> update by bass 31/01/2022
		) as LotSetup
		on LotDetail.step_no = LotSetup.step_no and LotSetup.machine_id = LotSetup.machine_id
			and LotSetup.rowmax = 1 ----update by bass 31/01/2022

		left join
		(
			--select [step_no],[machine_id],MAX([recorded_at]) as StartTime
			--from [APCSProDB].[trans].[lot_process_records]
			--where [record_class] IN ('1','31') and [lot_id] = @lot_id
			--group by [step_no],[machine_id]
			----<< update by bass 31/01/2022
			select [step_no]
				,[machine_id]
				,[recorded_at] as StartTime
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('1','31') and [lot_id] = @lot_id
			---->> update by bass 31/01/2022
		) as LotStart
		on LotDetail.step_no = LotStart.step_no and LotDetail.machine_id = LotStart.machine_id
			and LotStart.rowmax = 1 ----update by bass 31/01/2022

		left join
		(
			--select [step_no],[machine_id],MAX([recorded_at]) as EndTime
			--from [APCSProDB].[trans].[lot_process_records]
			--where [record_class] IN ('2','12','32') and [lot_id] = @lot_id
			--group by [step_no],[machine_id]
			----<< update by bass 31/01/2022
			select [step_no]
				,[machine_id]
				,[recorded_at] as EndTime
				, RANK () OVER ( 
					PARTITION BY [lot_process_records].[step_no]
					ORDER BY [lot_process_records].[recorded_at] DESC
				) [rowmax]
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('2','12','32') and [lot_id] = @lot_id
			---->> update by bass 31/01/2022
		) as LotEnd
		on LotDetail.step_no = LotEnd.step_no and LotDetail.machine_id = LotEnd.machine_id
			and LotEnd.rowmax = 1 ----update by bass 31/01/2022

	) as LotFlow
	on [lot_special_flows].[step_no] = [LotFlow].[step_no]
	inner join [APCSProDB].[method].[jobs] on [lot_special_flows].[job_id] = [jobs].[id]
	left join [APCSProDB].[trans].[item_labels] as [item_labels1] on [item_labels1].[name] = 'lot_process_records.record_class' and [item_labels1].[val] = [LotFlow].[record_class]
	inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
	where [special_flows].[lot_id] = @lot_id
	order by [device_flows].[step_no],start_time
END
