-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_lot_in_machine]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	select lot.id,device.name as DeviceName,device.ft_name as FTDevice, lot.lot_no,mc.name as McName, lot.process_state,max(lot_record.recorded_at) as update_time 
	,lot.qty_in  AS Kpcs,deviceflow.process_minutes as StandardTime,device.official_number as StandardLot,lot.is_special_flow
	from  [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
  inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id
  inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = lot.machine_id
  inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
  inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
  where lot.act_job_id  in (106,108,110,119,263,342,370) and lot.process_state != 0  and lot.wip_state= 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 0
  group by lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
  ,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in
   

  union all

   select lot.id,device.name as DeviceName,device.ft_name as FTDevice, lot.lot_no,mc.name as McName, special.process_state,max(lot_record.recorded_at) as update_time 
	,lot.qty_in  AS Kpcs,deviceflow.process_minutes as StandardTime,device.official_number as StandardLot,lot.is_special_flow
	from  [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
  inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id 
  inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
  inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lot.id
  inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = special.machine_id
  inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id
  inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
  where lotspecial.job_id  in (106,108,110,119,263,342,370) and special.process_state != 0  and lot.wip_state = 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 1
  group by lot.lot_no,special.process_state,mc.name,lot.id,device.name,device.ft_name
  ,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in
  
  union all 

  select lot.id,device.name as DeviceName,device.ft_name as FTDevice, lot.lot_no,mc.name as McName, lot.process_state,max(lot_record.recorded_at) as update_time 
	,lot.qty_in  AS Kpcs,deviceflow.process_minutes as StandardTime,device.official_number as StandardLot,lot.is_special_flow 
	from  [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
  inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id
  inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = lot.machine_id
  inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
  inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
  where lot.act_job_id  in (88,278,87) and lot.process_state = 2  and lot.wip_state= 20 and lot_record.record_class in (1) 
  group by lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
  ,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in

 order by max(lot_record.recorded_at) DESC
END
