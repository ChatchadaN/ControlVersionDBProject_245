-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_tp_wip] 
	-- Add the parameters for the stored procedure here
	@pkg_id as VARCHAR(20) = '33'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT *
	FROM DBx.dbo.scheduler_tp_qa_wip
	WHERE job_id in (236,289) and pkg_id in (@pkg_id)
	order by lot_no

	--SELECT [APCSProDB].[mc].[machines].name AS mc_name
	-- , [APCSProDB].[trans].[lots].lot_no
	-- , [APCSProDB].[method].device_names.name AS device_name 
	-- , [APCSProDB].[method].[packages].name AS pkg_name
	-- , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS job_name
	-- , [APCSProDB].[trans] .lots.qty_in  AS kpcs 
	-- , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
	-- , APCSProDB.trans.lots.process_state AS [state]
	-- , device_flows.process_minutes as standard_time
	-- , lots.act_job_id as job_Id 
	-- , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at
	-- --, lots.quality_state
	-- , locations.address
	-- , locations.name
	-- , QALog.LogType
	--FROM [APCSProDB].[trans].lots 
	--INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	--INNER JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	--INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	--inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	--left join [APCSProDB].trans.locations as locations on locations.id = lots.location_id 
	--left join [DBx].[QA].[QALogTemp] as QALog on QALog.LotNo = lots.lot_no
	--where lots.wip_state = 20 and  act_package_id in (235,246,242)  and act_job_id in(122,231,236,289,316) and is_special_flow = 0 and lots.quality_state = 0 and QALog.LogType != 'UpdateDevice'
	 
	--union all

	--SELECT [APCSProDB].[mc].[machines].name AS mc_name
	--	, [APCSProDB].[trans].[lots].lot_no
	--	, [APCSProDB].[method].device_names.name AS device_name 
	--	, [APCSProDB].[method].[packages].name AS pkg_name
	--	, REPLACE(REPLACE(job.name,'(',''),')','') AS job_name
	--	, [APCSProDB].[trans] .lots.qty_in  AS kpcs 
	--	, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
	--	, APCSProDB.trans.lots.process_state AS [state]
	--	, device_flows.process_minutes as standard_time
	--	, lotspecial.job_id as job_Id 
	--	, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at 
	--	--, lots.quality_state
	--	, locations.address
	-- , locations.name
	-- , QALog.LogType
	--FROM [APCSProDB].[trans].lots 
	--INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	--inner join APCSProDB.trans.special_flows as special on special.lot_id = lots.id
	--inner join APCSProDB.trans.lot_special_flows as lotspecial on lotspecial.special_flow_id = special.id
	--INNER JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	--INNER JOIN [APCSProDB].method.jobs as job ON  job.id = lotspecial.job_id
	--INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	--inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		
	--left join [APCSProDB].trans.locations as locations on locations.id = lots.location_id 
	--left join [DBx].[QA].[QALogTemp] as QALog on QALog.LotNo = lots.lot_no
	--where lots.wip_state = 20 and  act_package_id in (235,246,242)  and lotspecial.job_id in(122,231,236,289,316) and lots.is_special_flow = 1  and lots.quality_state = 0

	--UNION ALL --none gdic

	--SELECT [APCSProDB].[mc].[machines].name AS mc_name
	-- , [APCSProDB].[trans].[lots].lot_no
	-- , [APCSProDB].[method].device_names.name AS device_name 
	-- , [APCSProDB].[method].[packages].name AS pkg_name
	-- , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS job_name
	-- , [APCSProDB].[trans] .lots.qty_in  AS kpcs 
	-- , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
	-- , APCSProDB.trans.lots.process_state AS [state]
	-- , device_flows.process_minutes as standard_time
	-- , lots.act_job_id as job_Id 
	-- , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at
	-- --, lots.quality_state
	-- , locations.address
	-- , locations.name
	-- , QALog.LogType
	--FROM [APCSProDB].[trans].lots 
	--INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	--INNER JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	--INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	----inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	--inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	--left join [APCSProDB].trans.locations as locations on locations.id = lots.location_id 
	--left join [DBx].[QA].[QALogTemp] as QALog on QALog.LotNo = lots.lot_no
	--where lots.wip_state = 20 
	--	and act_package_id in (242) 
	--	and APCSProDB.method.device_names.id in(5245,5246,5248,5249,5255,5276,5281,5282,5285,5286,5288)
	--	and act_job_id in(122,231,236,289,316) 
	--	and is_special_flow = 0 and lots.quality_state = 0
	 
	--union all

	--SELECT [APCSProDB].[mc].[machines].name AS mc_name
	--	, [APCSProDB].[trans].[lots].lot_no
	--	, [APCSProDB].[method].device_names.name AS device_name 
	--	, [APCSProDB].[method].[packages].name AS pkg_name
	--	, REPLACE(REPLACE(job.name,'(',''),')','') AS job_name
	--	, [APCSProDB].[trans] .lots.qty_in  AS kpcs 
	--	, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
	--	, APCSProDB.trans.lots.process_state AS [state]
	--	, device_flows.process_minutes as standard_time
	--	, lotspecial.job_id as job_Id 
	--	, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at 
	--	--, lots.quality_state
	--	, locations.address
	-- , locations.name
	-- , QALog.LogType
	--FROM [APCSProDB].[trans].lots 
	--INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	--inner join APCSProDB.trans.special_flows as special on special.lot_id = lots.id
	--inner join APCSProDB.trans.lot_special_flows as lotspecial on lotspecial.special_flow_id = special.id
	--INNER JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	--INNER JOIN [APCSProDB].method.jobs as job ON  job.id = lotspecial.job_id
	--INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	----inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	--inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		
	--left join [APCSProDB].trans.locations as locations on locations.id = lots.location_id 
	--left join [DBx].[QA].[QALogTemp] as QALog on QALog.LotNo = lots.lot_no
	--where lots.wip_state = 20 
	--	and act_package_id in (242) 
	--	and APCSProDB.method.device_names.id in(5245,5246,5248,5249,5255,5276,5281,5282,5285,5286,5288) --add device none gdic
	--	and lotspecial.job_id in(122,231,236,289,316) 
	--	and lots.is_special_flow = 1  
	--	and lots.quality_state = 0
END
