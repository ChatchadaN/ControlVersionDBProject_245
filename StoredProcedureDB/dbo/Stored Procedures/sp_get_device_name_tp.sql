-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_device_name_tp] 
	-- Add the parameters for the stored procedure here
	@ft_name VARCHAR(MAX)

AS
BEGIN
	SELECT distinct [APCSProDB].[method].device_names.name AS device_name 
		,device_names.ft_name

		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
		LEFT JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = [APCSProDB].[trans].[lots].device_slip_id and device_flows.step_no = lots.step_no	 
		LEFT join [APCSProDB].trans.locations as locations on locations.id = [APCSProDB].[trans].[lots].location_id 
		where lots.wip_state = 20 
		and [APCSProDB].[trans].[lots].act_job_id in (231,236,289,197,291) 
		and [APCSProDB].[trans].[lots].is_special_flow = 0 
		and [APCSProDB].[trans].[lots].quality_state = 0 
		and ft_name = @ft_name
	 
		union all

		SELECT distinct [APCSProDB].[method].device_names.name AS device_name 
		,device_names.ft_name
		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		inner join APCSProDB.trans.special_flows as special on special.lot_id = [APCSProDB].[trans].[lots].id
		inner join APCSProDB.trans.lot_special_flows as lotspecial on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
		LEFT JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNER JOIN [APCSProDB].method.jobs as job ON  job.id = lotspecial.job_id
		INNer Join [APCSProDB] .[method].device_names on [APCSProDB].trans.lots.act_device_name_id = [APCSProDB] .[method].device_names.id
		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		
		LEFT join [APCSProDB].trans.locations as locations on locations.id = [APCSProDB].[trans].[lots].location_id 
		where lots.wip_state = 20 
		and lotspecial.job_id in(231,236,289,197,291) 
		and [APCSProDB].[trans].[lots].is_special_flow = 1 
		and [APCSProDB].[trans].[lots].quality_state != 3
		and ft_name = @ft_name
END
