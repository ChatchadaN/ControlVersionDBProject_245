
--[atom].[sp_get_trans_lots_shipment]を改造
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_trans_lots_shipment]	
-- Add the parameters for the stored procedure here	
	 @datestart varchar(50)
	,@dateend varchar(50)

	,@lot_no varchar(10) = '%'
	,@process varchar(50) = '%'
	,@package varchar(50) = '%'
	,@package_group varchar(50) = '%'	
	,@device varchar(50) = '%'	
	,@job varchar(50) = '%'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--set @datestart ='2023-03-08'
	--set @package = 'HSSOP-C16'

	--IF(@datestart = '') AND (@dateend = '')
	--BEGIN
	--	SET @datestart = CONVERT(varchar, FORMAT(getdate()-1, 'yyyy-MM-dd'));
	--	SET @dateend = CONVERT(varchar, FORMAT(getdate(), 'yyyy-MM-dd'));
	--END
	--ELSE
	--BEGIN
	--	SET @datestart = @datestart;
	--	SET @dateend = @dateend;
	--END

    -- Insert statements for procedure here
	select [lots].[id] as LotId
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
	, [lots].[container_no] as ContainerNo
	, [lots].[std_time_sum] as STDTimeSum
	, [lots].[m_no] as MarkingNo
	--, [comments].[val] as QCComment
	, '' as QCComment
	, case when [device_names].[tp_rank] = '' or [device_names].[tp_rank] is null then '-' else [device_names].[tp_rank] end  as TPRank
	, case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 then 'OrderDelay' ELSE 'Normal' end as [Delay]
	, DATEDIFF(DAY,[days2].[date_value],GETDATE()) as DelayDay, [lots].[updated_at] as [Time]
	, [users1].[emp_num] as Operator
	, [package_groups].[name] as PackageGroup
	, [processes].[name] as ProcessName
	, 'http://webserv.thematrix.net/Atom/Shipment/Details?Id='+convert(varchar(50),[lots].[id])+'&Lotno='+convert(varchar(10),[lots].[lot_no])+'&Package='+trim([packages].[name])+'&Device='+trim([device_names].[name])+'&TPRank='+(case when [device_names].[tp_rank] = '' or [device_names].[tp_rank] is null then '-' else [device_names].[tp_rank] end) as Link
	, [days2].[date_value] AS [plan_shipdate]
	from [APCSProDB].[trans].[lots] with (NOLOCK) 
	inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [lots].[act_package_id]
	inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
	inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [lots].[act_device_name_id]
	inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [lots].[act_job_id]
	inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [lots].[act_process_id]
	inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
	inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
	left join [APCSProDB].[trans].[item_labels] as [item_labels1] with (NOLOCK) on [item_labels1].[name] = 'lots.wip_state' and [item_labels1].[val] = [lots].[wip_state]
	left join [APCSProDB].[trans].[item_labels] as [item_labels2] with (NOLOCK) on [item_labels2].[name] = 'lots.process_state' and [item_labels2].[val] = [lots].[process_state]
	left join [APCSProDB].[trans].[item_labels] as [item_labels3] with (NOLOCK) on [item_labels3].[name] = 'lots.quality_state' and [item_labels3].[val] = [lots].[quality_state]
	left join [APCSProDB].[trans].[item_labels] as [item_labels4] with (NOLOCK) on [item_labels4].[name] = 'lots.first_ins_state' and [item_labels4].[val] = [lots].[first_ins_state]
	left join [APCSProDB].[trans].[item_labels] as [item_labels5] with (NOLOCK) on [item_labels5].[name] = 'lots.final_ins_state' and [item_labels5].[val] = [lots].[final_ins_state]
	left join [APCSProDB].[mc].[machines] with (NOLOCK) on [machines].[id] = [lots].[machine_id]
	left join [APCSProDB].[trans].[comments] with (NOLOCK) on [comments].[id] = [lots].[qc_comment_id]
	left join [APCSProDB].[man].[users] as [users1] with (NOLOCK) on [users1].[id] = [lots].[updated_by]
	left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] and [lots].[special_flow_id] = 1
	left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id]
	left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
	left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels2].[name] = 'lots.process_state' and [item_labels2].[val] = [special_flows].[process_state]
	where [lots].[wip_state] in (100,70,101) 
	and [packages].[is_enabled] = 1
	and lot_no like '%'+@lot_no+'%'
	and [package_groups].[name] like @package_group
	and [packages].[name] like @package
	and [device_names].[name] like @device
	and [processes].[name] like @process
	and [jobs].[name] like @job
	and [days1].[date_value] between @datestart and @dateend
	order by [lots].[lot_no] 
end