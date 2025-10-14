-- =============================================
-- Author:		<Jakkapong Pureinsin>
-- Create date: <10/9/2021>
-- Description:	<GetPLwip_withoutRackLocation>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_PLWip]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	
SELECT machineCanRun.name as McRunName
		 , [APCSProDB].[trans].[lots].lot_no
		 , TRIM([APCSProDB].[method].device_names.name) AS device_name 
		 , TRIM([APCSProDB].[method].[packages].name) AS pkg_name
		 , [APCSProDB].[trans] .lots.qty_in  AS kpcs 
		 , packages.id as Pkg_id 
		 , [DBx].[dbo].[ransMasterPL].group_no as group_no
		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
		LEFT JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = [APCSProDB].[trans].[lots].device_slip_id and device_flows.step_no = lots.step_no
		inner join [DBx].[dbo].[ransMasterPL] on APCSProDB.method.packages.id = [DBx].[dbo].[ransMasterPL].package_id 
		LEFT JOIN [APCSProDB].mc.machines as machineCanRun on [DBx].[dbo].[ransMasterPL].machine_id = machineCanRun.id
		where lots.wip_state = 20 
		and [APCSProDB].[trans].[lots].act_job_id in (83,275) 
		and [APCSProDB].[trans].[lots].is_special_flow = 0 
		--and [APCSProDB].method.device_names.alias_package_group_id != 33
		and [APCSProDB].[trans].[lots].quality_state = 0
		and APCSProDB.trans.lots.process_state = 0

		
	    union all

		SELECT machineCanRun.name as McRunName
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS device_name 
			, [APCSProDB].[method].[packages].name AS pkg_name
			, [APCSProDB].[trans] .lots.qty_in  AS kpcs 
			, packages.id as Pkg_id 
		 , [DBx].[dbo].[ransMasterPL].group_no as group_no 
		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		inner join APCSProDB.trans.special_flows as special on special.lot_id = [APCSProDB].[trans].[lots].id
		inner join APCSProDB.trans.lot_special_flows as lotspecial on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
		LEFT JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id
		INNER JOIN [APCSProDB].method.jobs as job ON  job.id = lotspecial.job_id
		INNer Join [APCSProDB] .[method].device_names on [APCSProDB].trans.lots.act_device_name_id = [APCSProDB] .[method].device_names.id
		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
		inner join [DBx].[dbo].[ransMasterPL] on APCSProDB.method.packages.id = [DBx].[dbo].[ransMasterPL].package_id 
		LEFT JOIN [APCSProDB].mc.machines as machineCanRun on [DBx].[dbo].[ransMasterPL].machine_id = machineCanRun.id
		where lots.wip_state = 20 
		and lotspecial.job_id in(83,275) 
		and [APCSProDB].[trans].[lots].is_special_flow = 1 
		--and [APCSProDB].method.device_names.alias_package_group_id != 33 
		and [APCSProDB].[trans].[lots].quality_state != 3
		and APCSProDB.trans.lots.process_state = 0
	

  
	
END
