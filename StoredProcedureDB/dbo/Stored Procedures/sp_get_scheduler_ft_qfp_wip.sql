-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_ft_qfp_wip]
	-- Add the parameters for the stored procedure here
	@PKG AS VARCHAR(MAX) = '1'
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	IF(@PKG = '1')
	BEGIN
    -- Insert statements for procedure here
		
		SELECT [APCSProDB].[mc].[machines].name AS MCName
			 , [APCSProDB].[trans].[lots].lot_no
			 , [APCSProDB].[method].device_names.name AS DeviceName 
			 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
			 , [APCSProDB].[method].[packages].name AS MethodPkgName
			 --, REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
			 , CASE 
				WHEN jobs.name LIKE '%SBLSYL%' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL',''))
				WHEN jobs.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN jobs.name = 'AUTO(1) RE'
					THEN 'AUTO1'
				ELSE REPLACE(REPLACE(jobs.name,'(',''),')','')
			 END AS JobName
			 , '' as NextJob
			 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
			 , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			 , APCSProDB.trans.lots.process_state AS [state]
			 , device_flows.process_minutes as StandardTime
			 , lots.act_job_id as job_Id 
			 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
			 , lots.quality_state
			 , locations.address
			 , locations.name
		FROM [APCSProDB].[trans].lots with (NOLOCK)
			INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
			INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
			left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		where lots.wip_state = 20 and [APCSProDB].[method].[packages].id in (74,75,76,77,587) and act_job_id in(12,119,110,108,106,87,88,278,155)  and is_special_flow = 0 
					AND DayA.[date_value] <= convert(date, getdate()) 
					AND lot_no NOT IN (select lot_no from APCSProDB.trans.lots AS LOT 
					inner join APCSProDB.method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
					inner join APCSProDB.method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
					inner join APCSProDB.method.jobs AS J on DF.job_id = J.id
					inner join APCSProDB.method.packages as pkg on LOT.act_package_id = pkg.id
					where is_released = 1 AND J.id IN (92,93) AND  quality_state IN (0,4) AND wip_state = 20 and pkg.name in (SELECT name from [APCSProDB].[method].[packages] where id in (74,75,76,77,587)) ) --Filter FLFT FLFTTP
		AND lots.device_slip_id IN (select distinct DS.device_slip_id from APCSProDB.method.device_slips AS DS 
								inner join APCSProDB.method.device_flows as DF on DS.device_slip_id = DF.device_slip_id
								where DS.is_released = 1 and (DF.job_id IN (106,155,359) and DF.is_skipped = 0))

		union all 

		SELECT [APCSProDB].[mc].[machines].name AS MCName
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS DeviceName 
			, [APCSProDB].[method].device_names.ft_name AS FTDevice
			, [APCSProDB].[method].[packages].name AS MethodPkgName
			--, REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
			, CASE 
				WHEN job.name LIKE '%SBLSYL%' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL',''))
				WHEN job.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN job.name = 'AUTO(1) RE'
					THEN 'AUTO1'
				ELSE REPLACE(REPLACE(job.name,'(',''),')','')
			END AS JobName
			, lots.act_job_id as NextJob
			, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
			, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			, APCSProDB.trans.lots.process_state AS [state]
			, device_flows.process_minutes as StandardTime
			, lotspecial.job_id as job_Id 
			, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
			, lots.quality_state
			, locations.address
			, locations.name
		FROM [APCSProDB].[trans].lots with (NOLOCK) 
			INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
			inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lots.id
			inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
			INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
			left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (74,75,76,77,587)  and lotspecial.job_id in(12,119,110,108,106,155) and lots.is_special_flow = 1 
		AND DayA.[date_value] <= convert(date, getdate()) 
		AND	lot_no NOT IN (select lot_no from APCSProDB.trans.lots AS LOT 
					inner join APCSProDB.method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
					inner join APCSProDB.method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
					inner join APCSProDB.method.jobs AS J on DF.job_id = J.id
					inner join APCSProDB.method.packages as pkg on LOT.act_package_id = pkg.id
					where is_released = 1 AND J.id IN (92,93) AND  quality_state IN (0,4) AND wip_state = 20 and pkg.name in (SELECT name from [APCSProDB].[method].[packages] where id in (74,75,76,77,587)) ) 
		AND lots.device_slip_id IN (select distinct DS.device_slip_id from APCSProDB.method.device_slips AS DS 
								inner join APCSProDB.method.device_flows as DF on DS.device_slip_id = DF.device_slip_id
								where DS.is_released = 1 and (DF.job_id IN (106,155,359) and DF.is_skipped = 0)) --Distinct for filter all same slip_id,Slip must have AUTO1
					
	END
	ELSE IF(@PKG = '2')
	BEGIN
	SELECT [APCSProDB].[mc].[machines].name AS MCName
			 , [APCSProDB].[trans].[lots].lot_no
			 , [APCSProDB].[method].device_names.name AS DeviceName 
			 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
			 , [APCSProDB].[method].[packages].name AS MethodPkgName
			 --, REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
			, CASE 
				WHEN jobs.name LIKE '%SBLSYL%' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL',''))
				WHEN jobs.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN jobs.name = 'AUTO(1) RE'
					THEN 'AUTO1'
				ELSE REPLACE(REPLACE(jobs.name,'(',''),')','')
			 END AS JobName
			 , '' as NextJob
			 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
			 , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			 , APCSProDB.trans.lots.process_state AS [state]
			 , device_flows.process_minutes as StandardTime
			 , lots.act_job_id as job_Id 
			 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
			 , lots.quality_state
			 , locations.address
			 , locations.name
		FROM [APCSProDB].[trans].lots with (NOLOCK) 
			INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
			INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
			left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (505,508,509,121,122,346,347)  
		and act_job_id in(119,110,108,106,87,88,278,12,267,155)  and is_special_flow = 0 AND DayA.[date_value] <= convert(date, getdate())

		union all 

		SELECT [APCSProDB].[mc].[machines].name AS MCName
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS DeviceName 
			, [APCSProDB].[method].device_names.ft_name AS FTDevice
			, [APCSProDB].[method].[packages].name AS MethodPkgName
			--, REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
			, CASE 
				WHEN job.name LIKE '%SBLSYL%' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL',''))
				WHEN job.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN job.name = 'AUTO(1) RE'
					THEN 'AUTO1'
				ELSE REPLACE(REPLACE(job.name,'(',''),')','')
			END AS JobName
			, lots.act_job_id as NextJob
			, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
			, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			, APCSProDB.trans.lots.process_state AS [state]
			, device_flows.process_minutes as StandardTime
			, lotspecial.job_id as job_Id 
			, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
			, lots.quality_state
			, locations.address
			, locations.name
		FROM [APCSProDB].[trans].lots with (NOLOCK) 
			INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
			inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lots.id
			inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
			INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
			left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (505,508,509,121,122,346,347)  
		and lotspecial.job_id in(119,110,108,106,12,267,155) and lots.is_special_flow = 1 AND DayA.[date_value] <= convert(date, getdate())
	END
	ELSE IF(@PKG = '3')
	BEGIN
	SELECT [APCSProDB].[mc].[machines].name AS MCName
			 , [APCSProDB].[trans].[lots].lot_no
			 , [APCSProDB].[method].device_names.name AS DeviceName 
			 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
			 , [APCSProDB].[method].[packages].name AS MethodPkgName
			 --, REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
			, CASE 
				WHEN jobs.name LIKE '%SBLSYL%' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL',''))
				WHEN jobs.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN jobs.name = 'AUTO(1) RE'
					THEN 'AUTO1'
				ELSE REPLACE(REPLACE(jobs.name,'(',''),')','')
			END AS JobName
			 , '' as NextJob
			 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
			 , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			 , APCSProDB.trans.lots.process_state AS [state]
			 , device_flows.process_minutes as StandardTime
			 , lots.act_job_id as job_Id 
			 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
			 , lots.quality_state
			 , locations.address
			 , locations.name
		FROM [APCSProDB].[trans].lots with (NOLOCK) 
			INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
			INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
			left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (121,122)  
		and act_job_id in(119,110,108,106,87,88,278,12,267,155)  and is_special_flow = 0 AND DayA.[date_value] <= convert(date, getdate())

		union all 

		SELECT [APCSProDB].[mc].[machines].name AS MCName
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS DeviceName 
			, [APCSProDB].[method].device_names.ft_name AS FTDevice
			, [APCSProDB].[method].[packages].name AS MethodPkgName
			--, REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
			, CASE 
				WHEN job.name LIKE '%SBLSYL%' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL',''))
				WHEN job.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN job.name = 'AUTO(1) RE'
					THEN 'AUTO1'
				ELSE REPLACE(REPLACE(job.name,'(',''),')','')
			  END AS JobName
			, lots.act_job_id as NextJob
			, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
			, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			, APCSProDB.trans.lots.process_state AS [state]
			, device_flows.process_minutes as StandardTime
			, lotspecial.job_id as job_Id 
			, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
			, lots.quality_state
			, locations.address
			, locations.name
		FROM [APCSProDB].[trans].lots with (NOLOCK) 
			INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
			inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lots.id
			inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
			INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
			left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (121,122)  
		and lotspecial.job_id in(119,110,108,106,12,267,155) and lots.is_special_flow = 1 AND DayA.[date_value] <= convert(date, getdate())
	END
	ELSE IF(@PKG = '4')
	BEGIN
	SELECT [APCSProDB].[mc].[machines].name AS MCName
			 , [APCSProDB].[trans].[lots].lot_no
			 , [APCSProDB].[method].device_names.name AS DeviceName 
			 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
			 , [APCSProDB].[method].[packages].name AS MethodPkgName
			 --, REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
			, CASE 
				WHEN jobs.name LIKE '%SBLSYL%' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL',''))
				WHEN jobs.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN jobs.name = 'AUTO(1) RE'
					THEN 'AUTO1'
				ELSE REPLACE(REPLACE(jobs.name,'(',''),')','')
			  END AS JobName
			 , '' as NextJob
			 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
			 , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			 , APCSProDB.trans.lots.process_state AS [state]
			 , device_flows.process_minutes as StandardTime
			 , lots.act_job_id as job_Id 
			 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
			 , lots.quality_state
			 , locations.address
			 , locations.name
		FROM [APCSProDB].[trans].lots with (NOLOCK) 
			INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
			INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
			left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (510,511,512,213,214)  
		and act_job_id in(119,110,108,106,87,88,278,12,267,155)  and is_special_flow = 0 AND DayA.[date_value] <= convert(date, getdate())

		union all 

		SELECT [APCSProDB].[mc].[machines].name AS MCName
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS DeviceName 
			, [APCSProDB].[method].device_names.ft_name AS FTDevice
			, [APCSProDB].[method].[packages].name AS MethodPkgName
			--, REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
			, CASE 
				WHEN job.name LIKE '%SBLSYL%' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL',''))
				WHEN job.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN job.name = 'AUTO(1) RE'
					THEN 'AUTO1'
				ELSE REPLACE(REPLACE(job.name,'(',''),')','')
			  END AS JobName
			, lots.act_job_id as NextJob
			, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
			, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			, APCSProDB.trans.lots.process_state AS [state]
			, device_flows.process_minutes as StandardTime
			, lotspecial.job_id as job_Id 
			, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
			, lots.quality_state
			, locations.address
			, locations.name
		FROM [APCSProDB].[trans].lots with (NOLOCK) 
			INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
			inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lots.id
			inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
			LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
			left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (510,511,512,213,214)  
		and lotspecial.job_id in(119,110,108,106,12,267,155) and lots.is_special_flow = 1 AND DayA.[date_value] <= convert(date, getdate())
	END
	ELSE IF(@PKG = '5')
	BEGIN
	SELECT [APCSProDB].[mc].[machines].name AS MCName
			 , [APCSProDB].[trans].[lots].lot_no
			 , [APCSProDB].[method].device_names.name AS DeviceName 
			 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
			 , [APCSProDB].[method].[packages].name AS MethodPkgName
			 --, REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
			, CASE 
				WHEN jobs.name LIKE '%SBLSYL%' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL',''))
				WHEN jobs.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN jobs.name = 'AUTO(1) RE'
					THEN 'AUTO1'
				ELSE REPLACE(REPLACE(jobs.name,'(',''),')','')
			  END AS JobName
			 , '' as NextJob
			 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
			 , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			 , APCSProDB.trans.lots.process_state AS [state]
			 , device_flows.process_minutes as StandardTime
			 , lots.act_job_id as job_Id 
			 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
			 , lots.quality_state
			 , locations.address
			 , locations.name
		FROM [APCSProDB].[trans].lots with (NOLOCK) 
			INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
			INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
			left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (213,214)  
		and act_job_id in(119,110,108,106,87,88,278,12,267,155)  and is_special_flow = 0 AND DayA.[date_value] <= convert(date, getdate())

		union all 

		SELECT [APCSProDB].[mc].[machines].name AS MCName
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS DeviceName 
			, [APCSProDB].[method].device_names.ft_name AS FTDevice
			, [APCSProDB].[method].[packages].name AS MethodPkgName
			--, REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
			, CASE 
				WHEN job.name LIKE '%SBLSYL%' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL',''))
				WHEN job.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN job.name = 'AUTO(1) RE'
					THEN 'AUTO1'
				ELSE REPLACE(REPLACE(job.name,'(',''),')','')
			  END AS JobName
			, lots.act_job_id as NextJob
			, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
			, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			, APCSProDB.trans.lots.process_state AS [state]
			, device_flows.process_minutes as StandardTime
			, lotspecial.job_id as job_Id 
			, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
			, lots.quality_state
			, locations.address
			, locations.name
		FROM [APCSProDB].[trans].lots with (NOLOCK) 
			INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
			inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lots.id
			inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
			INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
			left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].id in (213,214)  
		and lotspecial.job_id in(119,110,108,106,12,267,155) and lots.is_special_flow = 1 AND DayA.[date_value] <= convert(date, getdate())
	END
	ELSE IF(@PKG='MSOP8')
	BEGIN
		SELECT [APCSProDB].[mc].[machines].name AS MCName
			 , [APCSProDB].[trans].[lots].lot_no
			 , [APCSProDB].[method].device_names.name AS DeviceName 
			 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
			 , [APCSProDB].[method].[packages].name AS MethodPkgName
			 --, REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
			, CASE 
				WHEN jobs.name LIKE '%SBLSYL%' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL',''))
				WHEN jobs.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN jobs.name = 'AUTO(1) RE'
					THEN 'AUTO1'
				ELSE REPLACE(REPLACE(jobs.name,'(',''),')','')
			  END AS JobName
			 , '' as NextJob
			 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
			 , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			 , APCSProDB.trans.lots.process_state AS [state]
			 , device_flows.process_minutes as StandardTime
			 , lots.act_job_id as job_Id 
			 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
			 , lots.quality_state
			 , locations.address
			 , locations.name
		FROM [APCSProDB].[trans].lots with (NOLOCK) 
			INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
			INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
			left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		where lots.wip_state = 20 and  ([APCSProDB].[method].[packages].name like @PKG +'%' or [APCSProDB].[method].[packages].name like ('%HSON-A8%'))  and act_job_id in(119,110,108,106,87,88,278,155)  and is_special_flow = 0 
			and [APCSProDB] .[method].device_names.name in (select DISTINCT dvname.name
				from APCSProDB.method.device_flows as dvflows
					inner join APCSProDB.method.jobs as jobs on dvflows.job_id = jobs.id 
					inner join APCSProDB.trans.lots as lots on lots.device_slip_id = dvflows.device_slip_id
					inner join APCSProDB.method.device_names as dvname on dvname.id = lots.act_device_name_id
					inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
				where dvflows.job_id in (106) and (pk.name like @PKG +'%' or pk.name like ('%HSON-A8%'))
				and dvflows.is_skipped = 0) AND DayA.[date_value] <= convert(date, getdate())
		union all 

		SELECT [APCSProDB].[mc].[machines].name AS MCName
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS DeviceName 
			, [APCSProDB].[method].device_names.ft_name AS FTDevice
			, [APCSProDB].[method].[packages].name AS MethodPkgName
			--, REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
			, CASE 
				WHEN job.name LIKE '%SBLSYL%' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL',''))
				WHEN job.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN job.name = 'AUTO(1) RE'
					THEN 'AUTO1'
				ELSE REPLACE(REPLACE(job.name,'(',''),')','')
			  END AS JobName
			, lots.act_job_id as NextJob
			, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
			, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			, APCSProDB.trans.lots.process_state AS [state]
			, device_flows.process_minutes as StandardTime
			, lotspecial.job_id as job_Id 
			, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
			, lots.quality_state
			, locations.address
			, locations.name
		FROM [APCSProDB].[trans].lots with (NOLOCK) 
			INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
			inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lots.id
			inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
			INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
			left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		where lots.wip_state = 20 and  ([APCSProDB].[method].[packages].name like @PKG +'%' 
		or [APCSProDB].[method].[packages].name like ('%HSON-A8%')) and lotspecial.job_id in(119,110,108,106,155) and lots.is_special_flow = 1 AND DayA.[date_value] <= convert(date, getdate())
	END
	ELSE 
	BEGIN
		
		SELECT [MCName]
			, [lot_no]
			, [DeviceName] 
			, [FTDevice]
			, [MethodPkgName]
			, [JobName]
			, [NextJob]
			, [Kpcs] 
			, ISNULL([qty_production],0) AS [qty_production]
			, [state]
			, [StandardTime]
			, [job_Id]
			, [updated_at]
			, [quality_state]
			, [address]
			, [name]
		FROM (
			SELECT [machines].[name] AS [MCName]
				 , [lots].[lot_no]
				 , [device_names].[name] AS [DeviceName] 
				 , [device_names].[ft_name] AS [FTDevice]
				 , [packages].[name] AS [MethodPkgName]
				 --, REPLACE(REPLACE(REPLACE(IIF([lots].[is_special_flow] = 1,ISNULL([jobs_sp].[name],[jobs].[name]),[jobs].[name]),'(',''),')',''),'SBLSYL','') AS [JobName]
				 , CASE 
					WHEN IIF([lots].[is_special_flow] = 1,ISNULL([jobs_sp].[name],[jobs].[name]),[jobs].[name]) LIKE '%SBLSYL%' 
						THEN TRIM(REPLACE(REPLACE(REPLACE(IIF([lots].[is_special_flow] = 1,ISNULL([jobs_sp].[name],[jobs].[name]),[jobs].[name]),'(',''),')',''),'SBLSYL',''))
					WHEN IIF([lots].[is_special_flow] = 1,ISNULL([jobs_sp].[name],[jobs].[name]),[jobs].[name]) = 'OS+AUTO(1)' 
						THEN 'AUTO1'
					WHEN IIF([lots].[is_special_flow] = 1,ISNULL([jobs_sp].[name],[jobs].[name]),[jobs].[name]) = 'AUTO(1) RE'
						THEN 'AUTO1'
					ELSE REPLACE(REPLACE(IIF([lots].[is_special_flow] = 1,ISNULL([jobs_sp].[name],[jobs].[name]),[jobs].[name]),'(',''),')','')
				   END AS JobName				 
				 , '' as [NextJob]
				 , [lots].[qty_in] AS [Kpcs] 
				 , IIF([lots].[process_state] = 2,(([lots].[qty_in] + 0.0 - ([lots].[qty_last_pass] + [lots].[qty_last_fail])) / NULLIF([lots].[qty_in],0)),1) AS [qty_production]
				 , [lots].[process_state] AS [state]
				 , [device_flows].[process_minutes] AS [StandardTime]
				 , IIF([lots].[is_special_flow] = 1,ISNULL([jobs_sp].[id],[jobs].[id]),[jobs].[id]) AS [job_Id]
				 , [lot_record].[updated_at]
				 , [lots].[quality_state]
				 , [locations].[address]
				 , [locations].[name]  
			FROM [APCSProDB].[trans].[lots] with (NOLOCK)
			INNER JOIN [APCSProDB].[method].[device_flows] with (NOLOCK) 
				ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
				AND [device_flows].[step_no] = [lots].[step_no]	 
			INNER JOIN [APCSProDB].[method].[device_names] with (NOLOCK) 
				ON [lots].[act_device_name_id] = [device_names].[id]
			INNER JOIN [APCSProDB].[method].[packages] with (NOLOCK) 
				ON [lots].[act_package_id] = [packages].[id] 
			INNER JOIN [APCSProDB].[method].[jobs] with (NOLOCK) 
				ON [lots].[act_job_id] = [jobs].[id]
			LEFT JOIN [APCSProDB].[trans].[special_flows] with (NOLOCK)
				ON [lots].[is_special_flow] = 1
				AND [lots].[id] = [special_flows].[lot_id]
				AND [lots].[special_flow_id] = [special_flows].[id]
			LEFT JOIN [APCSProDB].[trans].[lot_special_flows] with (NOLOCK)
				ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
				AND [special_flows].[step_no] = [lot_special_flows].[step_no]
			LEFT JOIN [APCSProDB].[method].[jobs] AS [jobs_sp] with (NOLOCK) 
				ON [lot_special_flows].[job_id] = [jobs_sp].[id]
			LEFT JOIN [APCSProDB].[mc].[machines] with (NOLOCK) 
				ON [lots].[machine_id] = [machines].[id]
			LEFT JOIN [APCSProDB].[trans].[locations] with (NOLOCK) 
				ON [lots].[location_id] = [locations].[id] 
			INNER JOIN [APCSProDB].[trans].[days] with (NOLOCK) ON 
				[lots].[in_plan_date_id] = [days].[id]
			OUTER APPLY (
				SELECT MAX([lot_process_records].[recorded_at]) AS [updated_at]
				FROM [APCSProDB].[trans].[lot_process_records] with (NOLOCK) 
				WHERE [lot_process_records].[lot_id] = [lots].[id]
			) AS [lot_record]
			CROSS APPLY (
				SELECT TOP 1 [DS].[device_slip_id] 
				FROM [APCSProDB].[method].[device_slips] AS [DS] 
				INNER JOIN [APCSProDB].[method].[device_flows] AS [DF] 
					ON [DS].[device_slip_id] = [DF].[device_slip_id]
				WHERE [DS].[device_slip_id] = [lots].[device_slip_id]
					AND [DS].[is_released] = 1 
					AND [DF].[job_id] IN (106,155,359,108,110,119) 
					AND [DF].[is_skipped] = 0
			) AS [lot_device]
			WHERE [lots].[wip_state] = 20
				AND [packages].[name] IN (SELECT value FROM STRING_SPLIT (@PKG, ','))
				AND [days].[date_value] <= CONVERT(DATE, GETDATE()) 
		) AS [lots]
		WHERE [job_Id] IN (12,119,110,108,106,87,88,278,155,50,359,361,362,363,364)


		--SELECT [APCSProDB].[mc].[machines].name AS MCName
		--	 , [APCSProDB].[trans].[lots].lot_no
		--	 , [APCSProDB].[method].device_names.name AS DeviceName 
		--	 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
		--	 , [APCSProDB].[method].[packages].name AS MethodPkgName
		--	 , REPLACE( REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')',''),'SBLSYL','') AS JobName
		--	 , '' as NextJob
		--	 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		--	 , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		--	 , APCSProDB.trans.lots.process_state AS [state]
		--	 , device_flows.process_minutes as StandardTime
		--	 , lots.act_job_id as job_Id 
		--	 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
		--	 , lots.quality_state
		--	 , locations.address
		--	 , locations.name
		--FROM [APCSProDB].[trans].lots with (NOLOCK) 
		--	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		--	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
		--	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		--	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		--	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
		--	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
		--	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
		--	inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		--where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT (  @PKG , ',' ))  and act_job_id in(12,119,110,108,106,87,88,278,155,50,359,361,362,363,364)  and is_special_flow = 0 
		--AND DayA.[date_value] <= convert(date, getdate()) 
		--AND lot_no NOT IN (select lot_no from APCSProDB.trans.lots AS LOT 
		--			inner join APCSProDB.method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
		--			inner join APCSProDB.method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
		--			inner join APCSProDB.method.jobs AS J on DF.job_id = J.id
		--			inner join APCSProDB.method.packages as pkg on LOT.act_package_id = pkg.id
		--			where is_released = 1 AND J.id IN (93) AND  quality_state IN (0,4) AND wip_state = 20 and pkg.name in (SELECT * from STRING_SPLIT (  @PKG , ',' )) ) --Filter FLFT FLFTTP
		--AND lots.device_slip_id IN (select distinct DS.device_slip_id from APCSProDB.method.device_slips AS DS 
		--						inner join APCSProDB.method.device_flows as DF on DS.device_slip_id = DF.device_slip_id
		--						where DS.is_released = 1 and (DF.job_id IN (106,155,359,108,110,119) and DF.is_skipped = 0)) --Distinct for filter all same slip_id,Slip must have AUTO1
					


		--union all 

	 --  SELECT [APCSProDB].[mc].[machines].name AS MCName
		--	, [APCSProDB].[trans].[lots].lot_no
		--	, [APCSProDB].[method].device_names.name AS DeviceName 
		--	, [APCSProDB].[method].device_names.ft_name AS FTDevice
		--	, [APCSProDB].[method].[packages].name AS MethodPkgName
		--	, REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL','') AS JobName
		--	, lots.act_job_id as NextJob
		--	, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		--	, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		--	, APCSProDB.trans.lots.process_state AS [state]
		--	, device_flows.process_minutes as StandardTime
		--	, lotspecial.job_id as job_Id 
		--	, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
		--	, lots.quality_state
		--	, locations.address
		--	, locations.name
		--FROM [APCSProDB].[trans].lots with (NOLOCK) 
		--	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		--	--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
		--	inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lots.id
		--	inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
		--	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		--	INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
		--	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		--	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
		--	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
		--	left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
		--	inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
		--where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT (@PKG , ',' ))  and lotspecial.job_id in(12,119,110,108,106,155,50,359,361,362,363,364) and lots.is_special_flow = 1 
		--AND DayA.[date_value] <= convert(date, getdate()) 
		--AND	lot_no NOT IN (select lot_no from APCSProDB.trans.lots AS LOT 
		--			inner join APCSProDB.method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
		--			inner join APCSProDB.method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
		--			inner join APCSProDB.method.jobs AS J on DF.job_id = J.id
		--			inner join APCSProDB.method.packages as pkg on LOT.act_package_id = pkg.id
		--			where is_released = 1 AND J.id IN (93) AND  quality_state IN (0,4) AND wip_state = 20 and pkg.name in (SELECT * from STRING_SPLIT(@PKG , ',' )) ) 
		--AND lots.device_slip_id IN (select distinct DS.device_slip_id from APCSProDB.method.device_slips AS DS 
		--						inner join APCSProDB.method.device_flows as DF on DS.device_slip_id = DF.device_slip_id
		--						where DS.is_released = 1 and (DF.job_id IN (106,155,359,108,110,119) and DF.is_skipped = 0)) --Distinct for filter all same slip_id,Slip must have AUTO1
	


	END
END



	--BEGIN
	--SELECT [APCSProDB].[mc].[machines].name AS MCName
	--		 , [APCSProDB].[trans].[lots].lot_no
	--		 , [APCSProDB].[method].device_names.name AS DeviceName 
	--		 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
	--		 , [APCSProDB].[method].[packages].name AS MethodPkgName
	--		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS JobName
	--		 , '' as NextJob
	--		 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
	--		 , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
	--		 , APCSProDB.trans.lots.process_state AS [state]
	--		 , device_flows.process_minutes as StandardTime
	--		 , lots.act_job_id as job_Id 
	--		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
	--		 , lots.quality_state
	--		 , locations.address
	--		 , locations.name
	--	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	--		INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	--		INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	--		LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	--		INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--		--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	--		inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	--		left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	--		inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
	--	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PKG , ',' ))  and act_job_id in(12,119,110,108,106,87,88,278,155)  and is_special_flow = 0 
	--		and [APCSProDB] .[method].device_names.name in (select DISTINCT dvname.name
	--			from APCSProDB.method.device_flows as dvflows
	--				inner join APCSProDB.method.jobs as jobs on dvflows.job_id = jobs.id 
	--				inner join APCSProDB.trans.lots as lots on lots.device_slip_id = dvflows.device_slip_id
	--				inner join APCSProDB.method.device_names as dvname on dvname.id = lots.act_device_name_id
	--				inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
	--			where dvflows.job_id in (106,108) and pk.name in (SELECT * from STRING_SPLIT ( @PKG , ',' )) 
	--			and dvflows.is_skipped = 0) AND DayA.[date_value] <= convert(date, getdate())
	--	union all 

	--	SELECT [APCSProDB].[mc].[machines].name AS MCName
	--		, [APCSProDB].[trans].[lots].lot_no
	--		, [APCSProDB].[method].device_names.name AS DeviceName 
	--		, [APCSProDB].[method].device_names.ft_name AS FTDevice
	--		, [APCSProDB].[method].[packages].name AS MethodPkgName
	--		, REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
	--		, lots.act_job_id as NextJob
	--		, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
	--		, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
	--		, APCSProDB.trans.lots.process_state AS [state]
	--		, device_flows.process_minutes as StandardTime
	--		, lotspecial.job_id as job_Id 
	--		, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
	--		, lots.quality_state
	--		, locations.address
	--		, locations.name
	--	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	--		INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	--		--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
	--		inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lots.id
	--		inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
	--		LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	--		INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
	--		INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--		--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	--		inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
	--		left join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
	--		inner join APCSProDB.trans.days as DayA with (NOLOCK) on lots.in_plan_date_id = DayA.id
	--	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PKG , ',' ))  and lotspecial.job_id in(12,119,110,108,106,155) and lots.is_special_flow = 1 
	--	AND DayA.[date_value] <= convert(date, getdate())