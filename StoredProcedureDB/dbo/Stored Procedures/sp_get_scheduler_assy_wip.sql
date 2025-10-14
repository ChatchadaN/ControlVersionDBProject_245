-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_assy_wip]
	@PKG VARCHAR(MAX) = 'SSOP-B20W'

AS
--Contains
IF(@PKG like 'SSOP-B%')
	BEGIN
	
	SELECT [APCSProDB].[mc].[machines].name AS MCName
		 , [APCSProDB].[trans].[lots].lot_no
		 , [APCSProDB].[method].device_names.name AS DeviceName 
		 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
		 , [APCSProDB].[method].[packages].name AS MethodPkgName
		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
		 , '' as NextJob
		 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		, 1.0000 as qty_production
		 --, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		 , APCSProDB.trans.lots.process_state AS [state]
		 ,(SELECT top 1 (select top 1 process_minutes from APCSProDB.method.device_flows with (NOLOCK) 
				where step_no = MAX(dvflows.step_no)  and device_slip_id = dvslip.device_slip_id)
				FROM APCSProDB.method.device_names as dvname with (NOLOCK)
					INNER join APCSProDB.method.device_versions as dvVer with (NOLOCK) on dvVer.device_name_id = dvname.id
					INNER JOIN APCSProDB.method.device_slips as dvslip with (NOLOCK) on dvslip.device_id = dvVer.device_id
					INNER JOIN APCSProDB.method.device_flows as dvflows with (NOLOCK) on dvflows.device_slip_id = dvslip.device_slip_id
					INNER JOIN APCSProDB.method.jobs as job with (NOLOCK) on job.id = dvflows.job_id
					INNER JOIN APCSProDB.method.processes as process with (NOLOCK) on process.id = job.process_id
				WHERE process.id = 9 and job.name like 'AUTO%' and dvVer.version_num = dvslip.version_num 
					  and dvname.name = [APCSProDB].[method].device_names.name
				GROUP BY dvname.name , dvslip.device_slip_id) as StandardTime
		 --, device_flows.process_minutes as StandardTime
		 , lots.act_job_id as job_Id 
		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
		 , lots.quality_state
		 , locations.address
		 , locations.name
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join APCSProDB.method.package_groups on [APCSProDB].[method].packages.package_group_id = package_groups.id and package_groups.id = 33 and device_names.alias_package_group_id = 33
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT value from STRING_SPLIT (@PKG, ',' )) 
	and act_job_id in(32,14,19,20,27,29,31,36,268,45,51,52,53,301,6,83,275,40,269,313)  
	and is_special_flow = 0 
	and lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips)
	END
ELSE IF (@PKG = '1')
	BEGIN
		SELECT [APCSProDB].[mc].[machines].name AS MCName
		 , [APCSProDB].[trans].[lots].lot_no
		 , [APCSProDB].[method].device_names.name AS DeviceName 
		 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
		 , [APCSProDB].[method].[packages].name AS MethodPkgName
		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
		 , '' as NextJob
		 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		 , 1.0000 as qty_production
		-- , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		 , APCSProDB.trans.lots.process_state AS [state]
		 ,(SELECT top 1 (select top 1 process_minutes from APCSProDB.method.device_flows with (NOLOCK) 
				where step_no = MAX(dvflows.step_no)  and device_slip_id = dvslip.device_slip_id)
				FROM APCSProDB.method.device_names as dvname with (NOLOCK)
					INNER join APCSProDB.method.device_versions as dvVer with (NOLOCK) on dvVer.device_name_id = dvname.id
					INNER JOIN APCSProDB.method.device_slips as dvslip with (NOLOCK) on dvslip.device_id = dvVer.device_id
					INNER JOIN APCSProDB.method.device_flows as dvflows with (NOLOCK) on dvflows.device_slip_id = dvslip.device_slip_id
					INNER JOIN APCSProDB.method.jobs as job with (NOLOCK) on job.id = dvflows.job_id
					INNER JOIN APCSProDB.method.processes as process with (NOLOCK) on process.id = job.process_id
				WHERE process.id = 9 and job.name like 'AUTO%' and dvVer.version_num = dvslip.version_num 
					  and dvname.name = [APCSProDB].[method].device_names.name
				GROUP BY dvname.name , dvslip.device_slip_id) as StandardTime
		 --, device_flows.process_minutes as StandardTime
		 , lots.act_job_id as job_Id 
		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
		 , lots.quality_state
		 , locations.address
		 , locations.name
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join APCSProDB.method.package_groups on [APCSProDB].[method].packages.package_group_id = package_groups.id and package_groups.id = 33 and device_names.alias_package_group_id = 33
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (74,75,76,77) 
	and act_job_id in(32,14,19,20,27,29,31,36,268,45,51,52,53,301,6,83,275,40,269,313,12,87,88,278,313)  and is_special_flow = 0 
	and lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips)
	END
ELSE IF (@PKG = '2')
	BEGIN
		SELECT [APCSProDB].[mc].[machines].name AS MCName
		 , [APCSProDB].[trans].[lots].lot_no
		 , [APCSProDB].[method].device_names.name AS DeviceName 
		 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
		 , [APCSProDB].[method].[packages].name AS MethodPkgName
		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
		 , '' as NextJob
		 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		 , 1.0000 as qty_production
		 -- case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		 , APCSProDB.trans.lots.process_state AS [state]
		 ,(SELECT top 1 (select top 1 process_minutes from APCSProDB.method.device_flows with (NOLOCK) 
				where step_no = MAX(dvflows.step_no)  and device_slip_id = dvslip.device_slip_id)
				FROM APCSProDB.method.device_names as dvname with (NOLOCK)
					INNER join APCSProDB.method.device_versions as dvVer with (NOLOCK) on dvVer.device_name_id = dvname.id
					INNER JOIN APCSProDB.method.device_slips as dvslip with (NOLOCK) on dvslip.device_id = dvVer.device_id
					INNER JOIN APCSProDB.method.device_flows as dvflows with (NOLOCK) on dvflows.device_slip_id = dvslip.device_slip_id
					INNER JOIN APCSProDB.method.jobs as job with (NOLOCK) on job.id = dvflows.job_id
					INNER JOIN APCSProDB.method.processes as process with (NOLOCK) on process.id = job.process_id
				WHERE process.id = 9 and job.name like 'AUTO%' and dvVer.version_num = dvslip.version_num 
					  and dvname.name = [APCSProDB].[method].device_names.name
				GROUP BY dvname.name , dvslip.device_slip_id) as StandardTime
		 --, device_flows.process_minutes as StandardTime
		 , lots.act_job_id as job_Id 
		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at
		 , lots.quality_state
		 , locations.address
		 , locations.name
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (505,508,509) 
	and act_job_id in(32,14,19,20,27,29,31,36,268,45,51,52,53,301,6,83,275,40,269,313,12,267,87,88,278,313)  and is_special_flow = 0 
	and lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips)
	END
ELSE IF (@PKG = '3')
	BEGIN
		SELECT [APCSProDB].[mc].[machines].name AS MCName
		 , [APCSProDB].[trans].[lots].lot_no
		 , [APCSProDB].[method].device_names.name AS DeviceName 
		 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
		 , [APCSProDB].[method].[packages].name AS MethodPkgName
		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
		 , '' as NextJob
		 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		 , 1.0000 as qty_production
		 --case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		 , APCSProDB.trans.lots.process_state AS [state]
		,(SELECT top 1 (select top 1 process_minutes from APCSProDB.method.device_flows with (NOLOCK) 
				where step_no = MAX(dvflows.step_no)  and device_slip_id = dvslip.device_slip_id)
				FROM APCSProDB.method.device_names as dvname with (NOLOCK)
					INNER join APCSProDB.method.device_versions as dvVer with (NOLOCK) on dvVer.device_name_id = dvname.id
					INNER JOIN APCSProDB.method.device_slips as dvslip with (NOLOCK) on dvslip.device_id = dvVer.device_id
					INNER JOIN APCSProDB.method.device_flows as dvflows with (NOLOCK) on dvflows.device_slip_id = dvslip.device_slip_id
					INNER JOIN APCSProDB.method.jobs as job with (NOLOCK) on job.id = dvflows.job_id
					INNER JOIN APCSProDB.method.processes as process with (NOLOCK) on process.id = job.process_id
				WHERE process.id = 9 and job.name like 'AUTO%' and dvVer.version_num = dvslip.version_num 
					  and dvname.name = [APCSProDB].[method].device_names.name
				GROUP BY dvname.name , dvslip.device_slip_id) as StandardTime
		 --, device_flows.process_minutes as StandardTime
		 , lots.act_job_id as job_Id 
		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at
		 , lots.quality_state
		 , locations.address
		 , locations.name
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (121,122) 
	and act_job_id in(32,14,19,20,27,29,31,36,268,45,51,52,53,301,6,83,275,40,269,313,12,267,87,88,278,313)  and is_special_flow = 0 
	and lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips)
	END
ELSE IF (@PKG = '4')
	BEGIN
		SELECT [APCSProDB].[mc].[machines].name AS MCName
		 , [APCSProDB].[trans].[lots].lot_no
		 , [APCSProDB].[method].device_names.name AS DeviceName 
		 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
		 , [APCSProDB].[method].[packages].name AS MethodPkgName
		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
		 , '' as NextJob
		 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		 , 1.0000 as qty_production
		 --, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		 , APCSProDB.trans.lots.process_state AS [state]
		 ,(SELECT top 1 (select top 1 process_minutes from APCSProDB.method.device_flows with (NOLOCK) 
				where step_no = MAX(dvflows.step_no)  and device_slip_id = dvslip.device_slip_id)
				FROM APCSProDB.method.device_names as dvname with (NOLOCK)
					INNER join APCSProDB.method.device_versions as dvVer with (NOLOCK) on dvVer.device_name_id = dvname.id
					INNER JOIN APCSProDB.method.device_slips as dvslip with (NOLOCK) on dvslip.device_id = dvVer.device_id
					INNER JOIN APCSProDB.method.device_flows as dvflows with (NOLOCK) on dvflows.device_slip_id = dvslip.device_slip_id
					INNER JOIN APCSProDB.method.jobs as job with (NOLOCK) on job.id = dvflows.job_id
					INNER JOIN APCSProDB.method.processes as process with (NOLOCK) on process.id = job.process_id
				WHERE process.id = 9 and job.name like 'AUTO%' and dvVer.version_num = dvslip.version_num 
					  and dvname.name = [APCSProDB].[method].device_names.name
				GROUP BY dvname.name , dvslip.device_slip_id) as StandardTime
		 --, device_flows.process_minutes as StandardTime
		 , lots.act_job_id as job_Id 
		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
		 , lots.quality_state
		 , locations.address
		 , locations.name
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (510,511,512,213,214) 
	and act_job_id in(32,14,19,20,27,29,31,36,268,45,51,52,53,301,6,83,275,40,269,313,12,267,87,88,278,313)  and is_special_flow = 0 
	and lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips)
	END
	ElSE IF(@PKG ='MSOP8')
	BEGIN
		SELECT [APCSProDB].[mc].[machines].name AS MCName
		 , [APCSProDB].[trans].[lots].lot_no
		 , [APCSProDB].[method].device_names.name AS DeviceName 
		 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
		 , [APCSProDB].[method].[packages].name AS MethodPkgName
		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
		 , '' as NextJob
		 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		 , 1.0000 as qty_production
		-- , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		 , APCSProDB.trans.lots.process_state AS [state]
		 ,(SELECT top 1 (select top 1 process_minutes from APCSProDB.method.device_flows with (NOLOCK) 
				where step_no = MAX(dvflows.step_no)  and device_slip_id = dvslip.device_slip_id)
				FROM APCSProDB.method.device_names as dvname with (NOLOCK)
					INNER join APCSProDB.method.device_versions as dvVer with (NOLOCK) on dvVer.device_name_id = dvname.id
					INNER JOIN APCSProDB.method.device_slips as dvslip with (NOLOCK) on dvslip.device_id = dvVer.device_id
					INNER JOIN APCSProDB.method.device_flows as dvflows with (NOLOCK) on dvflows.device_slip_id = dvslip.device_slip_id
					INNER JOIN APCSProDB.method.jobs as job with (NOLOCK) on job.id = dvflows.job_id
					INNER JOIN APCSProDB.method.processes as process with (NOLOCK) on process.id = job.process_id
				WHERE process.id = 9 and job.name like 'AUTO%' and dvVer.version_num = dvslip.version_num 
					  and dvname.name = [APCSProDB].[method].device_names.name
				GROUP BY dvname.name , dvslip.device_slip_id) as StandardTime
		 --, device_flows.process_minutes as StandardTime
		 , lots.act_job_id as job_Id 
		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
		 , lots.quality_state
		 , locations.address
		 , locations.name
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	where lots.wip_state = 20 and  ([APCSProDB].[method].[packages].name like @PKG +'%' or [APCSProDB].[method].[packages].name like ('%HSON-A8%') )
	and act_job_id in(32,14,19,20,27,29,31,36,268,45,51,52,53,301,6,83,275,40,269,313,12,87,88,278,313)  and is_special_flow = 0 
	and lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips)
	and [APCSProDB] .[method].device_names.name in (select DISTINCT dvname.name
				from APCSProDB.method.device_flows as dvflows
					inner join APCSProDB.method.jobs as jobs on dvflows.job_id = jobs.id 
					inner join APCSProDB.trans.lots as lots on lots.device_slip_id = dvflows.device_slip_id
					inner join APCSProDB.method.device_names as dvname on dvname.id = lots.act_device_name_id
					inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
				where dvflows.job_id in (106) and pk.name in( @PKG ,'HSON-A8')
				and dvflows.is_skipped = 0 and lots.wip_state = 20)
	END
		ElSE IF(@PKG ='All_SSOP-B20W')
	BEGIN
		SELECT [APCSProDB].[mc].[machines].name AS MCName
		 , [APCSProDB].[trans].[lots].lot_no
		 , [APCSProDB].[method].device_names.name AS DeviceName 
		 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
		 , [APCSProDB].[method].[packages].name AS MethodPkgName
		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
		 , '' as NextJob
		 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		 , 1.0000 as qty_production
		-- , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		 , APCSProDB.trans.lots.process_state AS [state]
		 ,(SELECT top 1 (select top 1 process_minutes from APCSProDB.method.device_flows with (NOLOCK) 
				where step_no = MAX(dvflows.step_no)  and device_slip_id = dvslip.device_slip_id)
				FROM APCSProDB.method.device_names as dvname with (NOLOCK)
					INNER join APCSProDB.method.device_versions as dvVer with (NOLOCK) on dvVer.device_name_id = dvname.id
					INNER JOIN APCSProDB.method.device_slips as dvslip with (NOLOCK) on dvslip.device_id = dvVer.device_id
					INNER JOIN APCSProDB.method.device_flows as dvflows with (NOLOCK) on dvflows.device_slip_id = dvslip.device_slip_id
					INNER JOIN APCSProDB.method.jobs as job with (NOLOCK) on job.id = dvflows.job_id
					INNER JOIN APCSProDB.method.processes as process with (NOLOCK) on process.id = job.process_id
				WHERE process.id = 9 and job.name like 'AUTO%' and dvVer.version_num = dvslip.version_num 
					  and dvname.name = [APCSProDB].[method].device_names.name
				GROUP BY dvname.name , dvslip.device_slip_id) as StandardTime
		 --, device_flows.process_minutes as StandardTime
		 , lots.act_job_id as job_Id 
		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
		 , lots.quality_state
		 , locations.address
		 , locations.name
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( 'SSOP-B20W' , ',' ))  
	and act_job_id in(32,14,19,20,27,29,31,36,268,45,51,52,53,301,6,83,275,40,269,313,12,87,88,278,313)  and is_special_flow = 0 
	and lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips)
	and [APCSProDB] .[method].device_names.name in (select DISTINCT dvname.name
				from APCSProDB.method.device_flows as dvflows
					inner join APCSProDB.method.jobs as jobs on dvflows.job_id = jobs.id 
					inner join APCSProDB.trans.lots as lots on lots.device_slip_id = dvflows.device_slip_id
					inner join APCSProDB.method.device_names as dvname on dvname.id = lots.act_device_name_id
					inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
				where dvflows.job_id in (106,155) and pk.name in (SELECT * from STRING_SPLIT ( 'SSOP-B20W' , ',' ))
				and dvflows.is_skipped = 0 and lots.wip_state = 20)
	END
ELSE
BEGIN
		SELECT [APCSProDB].[mc].[machines].name AS MCName
		 , [APCSProDB].[trans].[lots].lot_no
		 , [APCSProDB].[method].device_names.name AS DeviceName 
		 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
		 , [APCSProDB].[method].[packages].name AS MethodPkgName
		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
		 , '' as NextJob
		 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		 , 1.0000 as qty_production
		-- , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		 , APCSProDB.trans.lots.process_state AS [state]
		 ,(SELECT top 1 (select top 1 process_minutes from APCSProDB.method.device_flows with (NOLOCK) 
				where step_no = MAX(dvflows.step_no)  and device_slip_id = dvslip.device_slip_id)
				FROM APCSProDB.method.device_names as dvname with (NOLOCK)
					INNER join APCSProDB.method.device_versions as dvVer with (NOLOCK) on dvVer.device_name_id = dvname.id
					INNER JOIN APCSProDB.method.device_slips as dvslip with (NOLOCK) on dvslip.device_id = dvVer.device_id
					INNER JOIN APCSProDB.method.device_flows as dvflows with (NOLOCK) on dvflows.device_slip_id = dvslip.device_slip_id
					INNER JOIN APCSProDB.method.jobs as job with (NOLOCK) on job.id = dvflows.job_id
					INNER JOIN APCSProDB.method.processes as process with (NOLOCK) on process.id = job.process_id
				WHERE process.id = 9 and job.name like 'AUTO%' and dvVer.version_num = dvslip.version_num 
					  and dvname.name = [APCSProDB].[method].device_names.name
				GROUP BY dvname.name , dvslip.device_slip_id) as StandardTime
		 --, device_flows.process_minutes as StandardTime
		 , lots.act_job_id as job_Id 
		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
		 , lots.quality_state
		 , locations.address
		 , locations.name
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PKG , ',' ))  
	and act_job_id in(32,14,19,20,27,29,31,36,268,45,51,52,53,301,6,83,275,40,269,313,12,87,88,278,313)  and is_special_flow = 0 
	and lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips)
	and [APCSProDB] .[method].device_names.name in (select DISTINCT dvname.name
				from APCSProDB.method.device_flows as dvflows
					inner join APCSProDB.method.jobs as jobs on dvflows.job_id = jobs.id 
					inner join APCSProDB.trans.lots as lots on lots.device_slip_id = dvflows.device_slip_id
					inner join APCSProDB.method.device_names as dvname on dvname.id = lots.act_device_name_id
					inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
				where dvflows.job_id in (106,155,359) and pk.name in (SELECT * from STRING_SPLIT ( @PKG , ',' ))
				and dvflows.is_skipped = 0 and lots.wip_state = 20)
	END
