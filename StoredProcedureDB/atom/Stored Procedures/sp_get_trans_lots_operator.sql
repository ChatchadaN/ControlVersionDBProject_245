
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_trans_lots_operator]	
	-- Add the parameters for the stored procedure here	
	@lot_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select top(1) [lots].[id] as LotId
	, [lots].[lot_no] as LotNo
	, [packages].[name] as Package 
	, [lots].[act_package_id] as PackageId 
	, [device_names].[name] as Device
	--, [lots].[step_no] as StepNo
	, case when [lots].[is_special_flow] = 1 then [lot_special_flows].step_no ELSE [lots].[step_no] end as StepNo
	, case when [lots].[is_special_flow] = 1 then lot_special_flows.job_id ELSE [lots].act_job_id end as jobid
	, case when [lots].[is_special_flow] = 1 then [job2].[name] ELSE [jobs].[name] end as FlowName
	, case when [lots].[is_special_flow] = 1 then [process2].[name] ELSE [processes].[name] end as [ProcessName]
	, [lots].[qty_in] as Input
	, [lots].[qty_pass] as Good
	, [lots].[qty_fail] as NG
	, [days1].[date_value] as InputDate
	, [days2].[date_value] as ShipDate
	, [item_labels1].[label_eng] as WipState
	, case when [lots].[is_special_flow] = 1 then [item_labels6].[label_eng] ELSE [item_labels2].[label_eng] end as ProcessState
	, case when [lots].[is_special_flow] = 1 then [special_flows].[process_state] ELSE [lots].process_state end as ProcessStateId
	, [item_labels3].[label_eng] as QualityState
	, [item_labels4].[label_eng] as FirstIns
	, [item_labels5].[label_eng] as FinalIns
	, [lots].[is_special_flow] as IsSpecialFlow
	, [lots].[priority] as [Priority]
	, [lots].[finished_at] as EndLotTime
	, [machines].[name] as MachineName
	, [lots].[carrier_no] as CarrierNo
	, [lots].[std_time_sum] as STDTimeSum
	, [lots].[m_no] as MarkingNo
	, [comments].[val] as QCComment
	, [device_names].[tp_rank] as TPRank
	, case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 then 'OrderDelay' ELSE 'Normal' end as [Delay]
	, DATEDIFF(DAY,[days2].[date_value],GETDATE()) as DelayDay, [lots].[updated_at] as [Time]
	, [users1].[emp_num] as Operator
	, [package_groups].[name] as PackageGroup
	--, [processes].[name] as ProcessName
	, [lot_process_records].[record_class]
	, [lot_process_records].[recorded_at]
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
	inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
	left join [APCSProDB].[mc].[machines] on [machines].[id] = [lots].[machine_id]
	inner join [APCSProDB].[trans].[item_labels] as [item_labels1] with (NOLOCK) on [item_labels1].[name] = 'lots.wip_state' and [item_labels1].[val] = [lots].[wip_state]
	inner join [APCSProDB].[trans].[item_labels] as [item_labels2] with (NOLOCK) on [item_labels2].[name] = 'lots.process_state' and [item_labels2].[val] = [lots].[process_state]
	inner join [APCSProDB].[trans].[item_labels] as [item_labels3] with (NOLOCK) on [item_labels3].[name] = 'lots.quality_state' and [item_labels3].[val] = [lots].[quality_state]
	left join [APCSProDB].[trans].[item_labels] as [item_labels4] on [item_labels4].[name] = 'lots.first_ins_state' and [item_labels4].[val] = [lots].[first_ins_state]
	left join [APCSProDB].[trans].[item_labels] as [item_labels5] on [item_labels5].[name] = 'lots.final_ins_state' and [item_labels5].[val] = [lots].[final_ins_state]
	left join [APCSProDB].[trans].[comments] on [comments].[id] = [lots].[qc_comment_id]
	inner join [APCSProDB].[trans].[days] as [day_indate] with (NOLOCK) on [day_indate].id = [lots].in_plan_date_id

	left join [APCSProDB].[man].[users] as [users1] with (NOLOCK) on [users1].[id] = [lots].[updated_by]

	left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
	left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and  [special_flows].step_no = [lot_special_flows].step_no
	left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
	left join [APCSProDB].[method].[processes] as [process2] on [process2].id = [lot_special_flows].act_process_id
	left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]
	left join [APCSProDB].[trans].[lot_process_records] on [lot_process_records].[lot_id] = [lots].[id] and [lot_process_records].[machine_id] = [lots].[machine_id] and [lot_process_records].[record_class] = '1'

	where [lots].[id] = @lot_id
	order by [lot_process_records].[recorded_at] desc

	/*select top(1) [lots].[id] as LotId
	, [lots].[lot_no] as LotNo
	, [packages].[name] as Package 
	, [lots].[act_package_id] as PackageId 
	, [device_names].[name] as Device
	, [lots].[step_no] as StepNo
	, case when [lots].[is_special_flow] = 1 then [job2].[name] ELSE [jobs].[name] end as FlowName
	, [lots].[qty_in] as Input
	, [lots].[qty_pass] as Good
	, [lots].[qty_fail] as NG
	, [days1].[date_value] as InputDate
	, [days2].[date_value] as ShipDate
	, [item_labels1].[label_eng] as WipState
	, case when [lots].[is_special_flow] = 1 then [item_labels6].[label_eng] ELSE [item_labels2].[label_eng] end as ProcessState
	, [item_labels3].[label_eng] as QualityState
	,[item_labels4].[label_eng] as FirstIns
	, [item_labels5].[label_eng] as FinalIns
	, [lots].[is_special_flow] as IsSpecialFlow
	, [lots].[priority] as [Priority]
	, [lots].[finished_at] as EndLotTime
	, [machines].[name] as MachineName
	, [lots].[carrier_no] as CarrierNo
	, [lots].[std_time_sum] as STDTimeSum
	, [lots].[m_no] as MarkingNo
	, [comments].[val] as QCComment
	, [device_names].[tp_rank] as TPRank
	, case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 then 'OrderDelay' ELSE 'Normal' end as [Delay]
	, DATEDIFF(DAY,[days2].[date_value],GETDATE()) as DelayDay, [lots].[updated_at] as [Time]
	, [users1].[emp_num] as Operator
	, [package_groups].[name] as PackageGroup
	, [processes].[name] as ProcessName
	, [lot_process_records].[record_class]
	, [lot_process_records].[recorded_at]
	from [APCSProDB].[trans].[lots] 
	inner join [APCSProDB].[method].[packages] on [packages].[id] = [lots].[act_package_id]
	inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id]
	left join [APCSProDB].[method].[device_names] on [device_names].[id] = [lots].[act_device_name_id]
	left join [APCSProDB].[method].[jobs] on [jobs].[id] = [lots].[act_job_id]
	left join [APCSProDB].[method].[processes] on [processes].[id] = [lots].[act_process_id]
	inner join [APCSProDB].[trans].[days] as [days1] on [days1].[id] = [lots].[in_plan_date_id]
	inner join [APCSProDB].[trans].[days] as [days2] on [days2].[id] = [lots].[out_plan_date_id]
	inner join [APCSProDB].[trans].[item_labels] as [item_labels1] on [item_labels1].[name] = 'lots.wip_state' and [item_labels1].[val] = [lots].[wip_state]
	inner join [APCSProDB].[trans].[item_labels] as [item_labels2] on [item_labels2].[name] = 'lots.process_state' and [item_labels2].[val] = [lots].[process_state]
	inner join [APCSProDB].[trans].[item_labels] as [item_labels3] on [item_labels3].[name] = 'lots.quality_state' and [item_labels3].[val] = [lots].[quality_state]
	left join [APCSProDB].[trans].[item_labels] as [item_labels4] on [item_labels4].[name] = 'lots.first_ins_state' and [item_labels4].[val] = [lots].[first_ins_state]
	left join [APCSProDB].[trans].[item_labels] as [item_labels5] on [item_labels5].[name] = 'lots.final_ins_state' and [item_labels5].[val] = [lots].[final_ins_state]
	left join [APCSProDB].[mc].[machines] on [machines].[id] = [lots].[machine_id]
	left join [APCSProDB].[trans].[comments] on [comments].[id] = [lots].[qc_comment_id]
	left join [APCSProDB].[man].[users] as [users1] on [users1].[id] = [lots].[updated_by]
	left join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lots].[special_flow_id] --and [lots].[special_flow_id] = 1
	left join [APCSProDB].[trans].[lot_special_flows] on [lot_special_flows].[special_flow_id] = [special_flows].[id]
	left join [APCSProDB].[method].[jobs] as [job2] on [job2].[id] = [lot_special_flows].[job_id]
	left join [APCSProDB].[trans].[item_labels] as [item_labels6] on [item_labels6].[name] = 'lots.process_state' and [item_labels6].[val] = [special_flows].[process_state]
	left join [APCSProDB].[trans].[lot_process_records] on [lot_process_records].[lot_id] = [lots].[id] and [lot_process_records].[machine_id] = [lots].[machine_id] and [lot_process_records].[record_class] = '1'
	where [lots].[id] = @lot_id
	order by [lot_process_records].[recorded_at] desc*/
END
