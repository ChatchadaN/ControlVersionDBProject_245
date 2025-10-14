-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_tp_qa_wip]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
BEGIN TRANSACTION
BEGIN Try
	delete from [DBx].[dbo].[scheduler_tp_qa_wip] where pkg_id in( 33,10)
	insert into [DBx].[dbo].[scheduler_tp_qa_wip] 
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
	,qa_in
	,[pkg_id])

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
	 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
	 --, lots.quality_state
	 , locations.address
	 , locations.name
	 , QALog.LogType
	 , [APCSProDB].[method].[packages].package_group_id
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	left join [DBx].[QA].[QALogTemp] as QALog with (NOLOCK) on QALog.LotNo = lots.lot_no
	where lots.wip_state = 20 and  act_package_id in (235,246,242)  and act_job_id in(122,231,236,289,316,428) and is_special_flow = 0 and lots.quality_state = 0 and QALog.LogType != 'UpdateDevice'
	 
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
		, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
		--, lots.quality_state
		, locations.address
	 , locations.name
	 , QALog.LogType
	 , [APCSProDB].[method].[packages].package_group_id
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lots.id
	inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
	INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	left join [DBx].[QA].[QALogTemp] as QALog with (NOLOCK) on QALog.LotNo = lots.lot_no
	where lots.wip_state = 20 and  act_package_id in (235,246,242)  and lotspecial.job_id in(122,231,236,289,316,428) and lots.is_special_flow = 1  and lots.quality_state = 4

	UNION ALL --none gdic

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
	 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
	 --, lots.quality_state
	 , locations.address
	 , locations.name
	 , QALog.LogType
	 , [APCSProDB].[method].[packages].package_group_id
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	left join [DBx].[QA].[QALogTemp] as QALog with (NOLOCK) on QALog.LotNo = lots.lot_no
	where lots.wip_state = 20 
		and act_package_id in (242,268,269) 
		and APCSProDB.method.device_names.id in(5245,5246,5248,5249,5255,5276,5281,5282,5285,5286,5288)
		and act_job_id in(122,231,236,289,316,428) 
		and is_special_flow = 0 and lots.quality_state = 0
	 
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
		, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
		--, lots.quality_state
		, locations.address
	 , locations.name
	 , QALog.LogType
	 , [APCSProDB].[method].[packages].package_group_id
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lots.id
	inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
	INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	left join [DBx].[QA].[QALogTemp] as QALog with (NOLOCK) on QALog.LotNo = lots.lot_no
	where lots.wip_state = 20 
		and act_package_id in (242,268,269) 
		and APCSProDB.method.device_names.id in(5245,5246,5248,5249,5255,5276,5281,5282,5285,5286,5288) --add device none gdic
		and lotspecial.job_id in(122,231,236,289,316,428) 
		and lots.is_special_flow = 1  
		and lots.quality_state = 4

	UNION ALL -- HSON

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
	 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
	 --, lots.quality_state
	 , locations.address
	 , locations.name
	 , QALog.LogType
	 , [APCSProDB].[method].[packages].package_group_id
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	left join [DBx].[QA].[QALogTemp] as QALog with (NOLOCK) on QALog.LotNo = lots.lot_no
	where lots.wip_state = 20 
		and act_package_id in (61,62,63) 
		--and APCSProDB.method.device_names.id in(5245,5246,5248,5249,5255,5276,5281,5282,5285,5286,5288)
		and act_job_id in(122,231,236,289,316,428) 
		and is_special_flow = 0 and lots.quality_state = 0
	 
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
		, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
		--, lots.quality_state
		, locations.address
	 , locations.name
	 , QALog.LogType
	 , [APCSProDB].[method].[packages].package_group_id
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lots.id
	inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
	INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	left join [DBx].[QA].[QALogTemp] as QALog with (NOLOCK) on QALog.LotNo = lots.lot_no
	where lots.wip_state = 20 
		and act_package_id in (61,62,63) 
		--and APCSProDB.method.device_names.id in(5245,5246,5248,5249,5255,5276,5281,5282,5285,5286,5288) --add device none gdic
		and lotspecial.job_id in(122,231,236,289,316,428) 
		and lots.is_special_flow = 1 
	COMMIT;
END TRY
BEGIN CATCH
	PRINT '---> Error <----' +  ERROR_MESSAGE() + '---> Error <----'; 
	ROLLBACK;
END CATCH	
END