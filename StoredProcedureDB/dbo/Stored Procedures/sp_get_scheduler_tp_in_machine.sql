-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_tp_in_machine]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select lot.id as lotId ,device.name as devicename, lot.lot_no as lotno ,mc.name as mcname, lot.process_state as process_state,max(lot_record.recorded_at) as update_time 
		,deviceflow.process_minutes as standardtime,lot.is_special_flow
	from  [APCSProDB].trans.lot_process_records as lot_record
		inner join [APCSProDB].[trans].lots as lot on lot.id = lot_record.lot_id
		inner join [APCSProDB].[mc].[machines] as mc on mc.id = lot.machine_id
		inner join [APCSProDB] .[method].device_names as device on lot.act_device_name_id = device.id 
		inner join [APCSProDB].[method].[device_flows] as deviceflow on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
	where lot.act_job_id  in (236,289,231) and lot.process_state != 0  and lot.wip_state= 20 and lot_record.record_class in (1,5) 
	--and lot_no = '2023A5077V'
	group by lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
		,deviceflow.process_minutes,lot.is_special_flow

	
END
