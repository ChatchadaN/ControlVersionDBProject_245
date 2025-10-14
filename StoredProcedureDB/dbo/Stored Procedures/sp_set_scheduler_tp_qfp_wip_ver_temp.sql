-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_tp_qfp_wip_ver_temp] 
     @pkg as int = 3 
	  
	-- Add the parameters for the stored procedure here
AS
BEGIN
	delete from [DBx].[dbo].[scheduler_tp_qa_wip_01] where pkg_id = @pkg

	If(@pkg = 15)
		Begin
			insert into [DBx].[dbo].[scheduler_tp_qa_wip_01] 
		([mc_name]
		,lot_no
		,device_name
		,pkg_name
		,job_name
		,kpcs
		,qty_production
		,state
		,standare_time
		,job_id
		,update_at
		,rack_address
		,rack_name
		--,qa_in
		,pkg_id
		,tp_rank)

		SELECT [APCSProDB].[mc].[machines].name AS mc_name
		 , [APCSProDB].[trans].[lots].lot_no
		 , [APCSProDB].[method].device_names.name AS device_name 
		 , [APCSProDB].[method].[packages].name AS pkg_name
		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS job_name
		 , [APCSProDB].[trans] .lots.qty_in  AS kpcs 
		 , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		 , APCSProDB.trans.lots.process_state AS [state]
		 , device_flows.process_minutes as standard_time
		 , lots.act_job_id as job_Id 
		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at
		 , rack_addresses.address as rack_address
		 , rack_controls.name as rack_name
		 , [APCSProDB].[method].[packages].package_group_id
		 , APCSProDB.method.device_names.tp_rank
		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
		INNER JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = [APCSProDB].[trans].[lots].device_slip_id and device_flows.step_no = lots.step_no	 
		
		--left join [APCSProDB].trans.locations as locations on locations.id = [APCSProDB].[trans].[lots].location_id 
		LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id				

		--left join [DBx].[QA].[QALogTemp] as QALog on QALog.LotNo = [APCSProDB].[trans].[lots].lot_no
		where lots.wip_state = 20 
		and [APCSProDB].[method].[packages].package_group_id  in (@pkg)  
		and [APCSProDB].[trans].[lots].act_job_id in (50,155,99,106,231,236,289) 
		and [APCSProDB].[trans].[lots].is_special_flow = 0 
		and [APCSProDB].[trans].[lots].quality_state = 0 
		--and QALog.LogType != 'UpdateDevice'
	 
		union all

		SELECT distinct [APCSProDB].[mc].[machines].name AS mc_name
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS device_name 
			, [APCSProDB].[method].[packages].name AS pkg_name
			, REPLACE(REPLACE(job.name,'(',''),')','') AS job_name
			, [APCSProDB].[trans] .lots.qty_in  AS kpcs 
			, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			, APCSProDB.trans.lots.process_state AS [state]
			, device_flows.process_minutes as standard_time
			, lotspecial.job_id as job_Id 
			, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at 
			, rack_addresses.address as rack_address
		 , rack_controls.name as rack_name
		 , [APCSProDB].[method].[packages].package_group_id
		 , APCSProDB.method.device_names.tp_rank
		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		inner join APCSProDB.trans.special_flows as special on special.lot_id = [APCSProDB].[trans].[lots].id
		inner join APCSProDB.trans.lot_special_flows as lotspecial on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
		INNER JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNER JOIN [APCSProDB].method.jobs as job ON  job.id = lotspecial.job_id
		INNer Join [APCSProDB] .[method].device_names on [APCSProDB].trans.lots.act_device_name_id = [APCSProDB] .[method].device_names.id 
		--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		
		
		--left join [APCSProDB].trans.locations as locations on locations.id = [APCSProDB].[trans].[lots].location_id 
		LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id		
		
		where lots.wip_state = 20 
		and [APCSProDB].[method].[packages].package_group_id  in (@pkg)    
		and lotspecial.job_id in(50,155,99,106,231,236,289) 
		and [APCSProDB].[trans].[lots].is_special_flow = 1  
		and [APCSProDB].[trans].[lots].quality_state = 0
		end
	else
		begin
			insert into [DBx].[dbo].[scheduler_tp_qa_wip_01] 
		([mc_name]
		,lot_no
		,device_name
		,pkg_name
		,job_name
		,kpcs
		,qty_production
		,state
		,standare_time
		,job_id
		,update_at
		,rack_address
		,rack_name
		--,qa_in
		,pkg_id)

		SELECT [APCSProDB].[mc].[machines].name AS mc_name
		 , [APCSProDB].[trans].[lots].lot_no
		 , [APCSProDB].[method].device_names.name AS device_name 
		 , [APCSProDB].[method].[packages].name AS pkg_name
		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS job_name
		 , [APCSProDB].[trans] .lots.qty_in  AS kpcs 
		 , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		 , APCSProDB.trans.lots.process_state AS [state]
		 , device_flows.process_minutes as standard_time
		 , lots.act_job_id as job_Id 
		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at
		 --, lots.quality_state
		 , rack_addresses.address as rack_address
		 , rack_controls.name as rack_name
		 --, QALog.LogType
		 , [APCSProDB].[method].[packages].package_group_id
		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
		INNER JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = [APCSProDB].[trans].[lots].device_slip_id and device_flows.step_no = lots.step_no	 
		
		--left join [APCSProDB].trans.locations as locations on locations.id = [APCSProDB].[trans].[lots].location_id 
		LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id	

		--left join [DBx].[QA].[QALogTemp] as QALog on QALog.LotNo = [APCSProDB].[trans].[lots].lot_no
		where lots.wip_state = 20 
		and [APCSProDB].[method].[packages].package_group_id  in (@pkg)  
		and [APCSProDB].[trans].[lots].act_job_id in (231,236,289,316,197,291)--(122,231,236,289,316) 
		and [APCSProDB].[trans].[lots].is_special_flow = 0 
		and [APCSProDB].[trans].[lots].quality_state = 0 
		--and QALog.LogType != 'UpdateDevice'
	 
		union all

		SELECT distinct [APCSProDB].[mc].[machines].name AS mc_name
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS device_name 
			, [APCSProDB].[method].[packages].name AS pkg_name
			, REPLACE(REPLACE(job.name,'(',''),')','') AS job_name
			, [APCSProDB].[trans] .lots.qty_in  AS kpcs 
			, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			, APCSProDB.trans.lots.process_state AS [state]
			, device_flows.process_minutes as standard_time
			, lotspecial.job_id as job_Id 
			, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at 
			, rack_addresses.address as rack_address
			, rack_controls.name as rack_name
			, [APCSProDB].[method].[packages].package_group_id
		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		inner join APCSProDB.trans.special_flows as special on special.lot_id = [APCSProDB].[trans].[lots].id
		inner join APCSProDB.trans.lot_special_flows as lotspecial on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
		INNER JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNER JOIN [APCSProDB].method.jobs as job ON  job.id = lotspecial.job_id
		INNer Join [APCSProDB] .[method].device_names on [APCSProDB].trans.lots.act_device_name_id = [APCSProDB] .[method].device_names.id 
		--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		
		
		--left join [APCSProDB].trans.locations as locations on locations.id = [APCSProDB].[trans].[lots].location_id 
		LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id			
		
		where lots.wip_state = 20 
		and [APCSProDB].[method].[packages].package_group_id  in (@pkg)    
		and lotspecial.job_id in(231,236,289,197,291) 
		and [APCSProDB].[trans].[lots].is_special_flow = 1  
		and [APCSProDB].[trans].[lots].quality_state = 0
		end

END
