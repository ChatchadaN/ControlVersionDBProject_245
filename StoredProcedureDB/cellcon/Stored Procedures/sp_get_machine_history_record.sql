-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_machine_history_record]
	-- Add the parameters for the stored procedure here
	@machine_name varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select top 50 [lot].[id] as LotId
	, [lot].[lot_no] as LotNo
	, [packages].[name] as Package 
	, [device_names].[name] as Device
	, case when [lot].[is_special_flow] = 1 then [job2].[name] ELSE [jobs].[name] end as FlowName
	, [lot].[qty_in] as Input
	, [lot].[qty_pass] as Good
	, [lot].[qty_fail] as NG
	, [days1].[date_value] as InputDate
	, [days2].[date_value] as ShipDate
	, case when [lot].[is_special_flow] = 1 then [item_labels6].[label_eng] ELSE [item_labels2].[label_eng] end as ProcessState
	, [item_labels3].[label_eng] as QualityState
	, [lot].[is_special_flow] as IsSpecialFlow
	, [lot].[container_no] as ContainerNo
	, case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 then 'OrderDelay' ELSE 'Normal' end as [Delay]
	, DATEDIFF(DAY,[days2].[date_value],GETDATE()) as DelayDay
	--, [machine].[name] as MachineNo
	, [machine_lots].[name] as MachineNo
	, max([lot_record].updated_at) as Update_time
	,[loaction].[name] as [Location]
	from [APCSProDB].[trans].[lot_process_records] as [lot_record] with (NOLOCK) 
	inner join [APCSProDB].[trans].[lots] as [lot] with (NOLOCK) on [lot_record].lot_id = [lot].id
	left join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [lot].[act_package_id]
	left join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [lot].[act_device_name_id]
	left join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [lot].[act_job_id]
	inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lot].[in_plan_date_id]
	inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lot].[out_plan_date_id]
	inner join [APCSProDB].[trans].[item_labels] as [item_labels1] with (NOLOCK) on [item_labels1].[name] = 'lots.wip_state' and [item_labels1].[val] = [lot].[wip_state]
	inner join [APCSProDB].[trans].[item_labels] as [item_labels2] with (NOLOCK) on [item_labels2].[name] = 'lots.process_state' and [item_labels2].[val] = [lot].[process_state]
	inner join [APCSProDB].[trans].[item_labels] as [item_labels3] with (NOLOCK) on [item_labels3].[name] = 'lots.quality_state' and [item_labels3].[val] = [lot].[quality_state]
	left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lot].[special_flow_id] and [lot].[special_flow_id] = 1
	left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id]
	left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
	left join [APCSProDB].[trans].[item_labels] as [item_labels6] with (NOLOCK) on [item_labels2].[name] = 'lots.process_state' and [item_labels2].[val] = [special_flows].[process_state]
	inner join [APCSProDB].[mc].[machines] as [machine] with (NOLOCK) on machine.id = [lot_record].[machine_id]
	left join [APCSProDB].[trans].[locations] as [loaction] with (NOLOCK) on loaction.[id] = [lot].[location_id]
	left join [APCSProDB].[mc].[machines] as [machine_lots] with (NOLOCK) on machine_lots.id = lot.machine_id          
	where ([item_labels1].[val] in ('20')) and machine.[name] ='WB-M-168'
	--and [packages].[is_enabled] = 1) or ([item_labels1].[val] in ('20') and [packages].[name] in ('HSOP-M36','HTSSOP-A44','HTSSOP-A44R','HTSSOP-B20') )
	group by [lot].[id]
	, [lot].[lot_no] 
	, [packages].[name]  
	, [device_names].[name] 
	, case when [lot].[is_special_flow] = 1 then [job2].[name] ELSE [jobs].[name] end 
	, [lot].[qty_in] 
	, [lot].[qty_pass] 
	, [lot].[qty_fail] 
	, [days1].[date_value] 
	, [days2].[date_value]
	, case when [lot].[is_special_flow] = 1 then [item_labels6].[label_eng] ELSE [item_labels2].[label_eng] end 
	, [item_labels3].[label_eng]
	, [lot].[is_special_flow]
	, [lot].[container_no]
	, case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 then 'OrderDelay' ELSE 'Normal' end
	, DATEDIFF(DAY,[days2].[date_value],GETDATE())
	--,[machine].[name]
	,[machine_lots].[name]
	,[loaction].[name] 
	,lot.machine_id
	order by max([lot_record].updated_at) desc
END
