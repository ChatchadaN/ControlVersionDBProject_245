-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_ft_wip_ver_temp]
	@PKG VARCHAR(20) = 'SSOP-B20W'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- FT WIP
	SELECT [APCSProDB].[mc].[machines].name AS MCName
		, [APCSProDB].[trans].[lots].lot_no
		, [APCSProDB].[method].device_names.name AS DeviceName 
		, [APCSProDB].[method].device_names.ft_name AS FTDevice
		, [APCSProDB].[method].[packages].name AS MethodPkgName
		, CASE 
			WHEN [jobs].name = 'OS+AUTO(1)SBLSYL' 
				THEN 'AUTO1'	
			WHEN [jobs].name  = 'OS+AUTO(1)' 
				THEN 'AUTO1'
			WHEN [jobs].name  = 'OS+AUTO(2)' 
				THEN 'AUTO2'
			WHEN [jobs].name  = 'OS+AUTO(1) HV' 
				THEN 'AUTO1'
			WHEN [jobs].name  = 'AUTO(1) RE'
				THEN 'AUTO1'
			WHEN [jobs].name  = 'AUTO(1) HV'
				THEN 'AUTO1'
			WHEN [jobs].name  LIKE '%SBLSYL%' 
				THEN TRIM(REPLACE(REPLACE(REPLACE([jobs].name ,'(',''),')',''),'SBLSYL',''))
			WHEN [jobs].name  LIKE '%ASISAMPLE%' 
				THEN TRIM(REPLACE(REPLACE(REPLACE([jobs].name ,'(',''),')',''),'ASISAMPLE',''))
			WHEN [jobs].name  LIKE '%BIN27' 
				THEN TRIM(REPLACE(REPLACE(REPLACE([jobs].name ,'(',''),')',''),'BIN27',''))
			WHEN [jobs].name  LIKE '%BIN27-CF' 
				THEN TRIM(REPLACE(REPLACE(REPLACE([jobs].name ,'(',''),')',''),'BIN27-CF',''))
			ELSE REPLACE(REPLACE([jobs].name ,'(',''),')','')
		END AS JobName
		, '' as NextJob
		, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		, case when APCSProDB.trans.lots.process_state = 2 and APCSProDB.trans.lots.qty_in > 0 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		, APCSProDB.trans.lots.process_state AS [state]
		, device_flows.process_minutes as StandardTime
		, lots.act_job_id as job_Id 
		, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at
		, lots.quality_state

		, rack_addresses.address
		, rack_controls.name

		, device_names.official_number as LotKpcs
	FROM [APCSProDB].[trans].lots with (NOLOCK)
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
	
	LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
	LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id	
	
	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT value from STRING_SPLIT (@PKG, ',' ))  
	and act_job_id in (119,110,108,106,87,88,278,263,359,361,362,363,364,120,155,424,423,422,426)  
	and is_special_flow = 0 
	and [APCSProDB].method.device_names.alias_package_group_id = 33
	and lot_no NOT IN ('9999D9999V','9999A9999V','1234A1234V')

	union all
	-- Retest
	SELECT [APCSProDB].[mc].[machines].name AS MCName
		, [APCSProDB].[trans].[lots].lot_no
		, [APCSProDB].[method].device_names.name AS DeviceName 
		, [APCSProDB].[method].device_names.ft_name AS FTDevice
		, [APCSProDB].[method].[packages].name AS MethodPkgName
		, CASE 
		WHEN [job].name = 'OS+AUTO(1)SBLSYL' 
			THEN 'AUTO1'	
		WHEN [job].name  = 'OS+AUTO(1)' 
			THEN 'AUTO1'
		WHEN [job].name  = 'OS+AUTO(2)' 
			THEN 'AUTO2'
		WHEN [job].name  = 'OS+AUTO(1) HV' 
			THEN 'AUTO1'
		WHEN [job].name  = 'AUTO(1) RE'
			THEN 'AUTO1'
		WHEN [job].name  = 'AUTO(1) HV'
			THEN 'AUTO1'
		WHEN [job].name  LIKE '%SBLSYL%' 
			THEN TRIM(REPLACE(REPLACE(REPLACE([job].name ,'(',''),')',''),'SBLSYL',''))
		WHEN [job].name  LIKE '%ASISAMPLE%' 
			THEN TRIM(REPLACE(REPLACE(REPLACE([job].name ,'(',''),')',''),'ASISAMPLE',''))
		WHEN [job].name  LIKE '%BIN27' 
			THEN TRIM(REPLACE(REPLACE(REPLACE([job].name ,'(',''),')',''),'BIN27',''))
		WHEN [job].name  LIKE '%BIN27-CF' 
			THEN TRIM(REPLACE(REPLACE(REPLACE([job].name ,'(',''),')',''),'BIN27-CF',''))
		ELSE REPLACE(REPLACE([job].name ,'(',''),')','')
		END AS JobName
		, lots.act_job_id as NextJob
		, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		, case when APCSProDB.trans.lots.process_state = 2 and APCSProDB.trans.lots.qty_in > 0 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		, APCSProDB.trans.lots.process_state AS [state]
		, device_flows.process_minutes as StandardTime
		, lotspecial.job_id as job_Id 
		, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
		, lots.quality_state

		, rack_addresses.address
		, rack_controls.name

		, device_names.official_number as LotKpcs
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
	inner join APCSProDB.trans.special_flows as special with (NOLOCK) on lots.special_flow_id = special.id
	inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
	INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
	
	LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
	LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id	
		
	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT value from STRING_SPLIT (@PKG, ',' ))  and lotspecial.job_id in(119,110,108,106,263,379,359,361,362,363,364,387,120,155) and lots.is_special_flow = 1 
	and [APCSProDB].method.device_names.alias_package_group_id = 33

	UNION ALL
	-- INSP
	SELECT [APCSProDB].[mc].[machines].name AS MCName
		, [APCSProDB].[trans].[lots].lot_no
		, [APCSProDB].[method].device_names.name AS DeviceName 
		, [APCSProDB].[method].device_names.ft_name AS FTDevice
		, [APCSProDB].[method].[packages].name AS MethodPkgName
		, CASE 
			WHEN [job].name = 'OS+AUTO(1)SBLSYL' 
				THEN 'AUTO1'	
			WHEN [job].name  = 'OS+AUTO(1)' 
				THEN 'AUTO1'
			WHEN [job].name  = 'OS+AUTO(2)' 
				THEN 'AUTO2'
			WHEN [job].name  = 'OS+AUTO(1) HV' 
				THEN 'AUTO1'
			WHEN [job].name  = 'AUTO(1) RE'
				THEN 'AUTO1'
			WHEN [job].name  = 'AUTO(1) HV'
				THEN 'AUTO1'
			WHEN [job].name  LIKE '%SBLSYL%' 
				THEN TRIM(REPLACE(REPLACE(REPLACE([job].name ,'(',''),')',''),'SBLSYL',''))
			WHEN [job].name  LIKE '%ASISAMPLE%' 
				THEN TRIM(REPLACE(REPLACE(REPLACE([job].name ,'(',''),')',''),'ASISAMPLE',''))
			WHEN [job].name  LIKE '%BIN27' 
				THEN TRIM(REPLACE(REPLACE(REPLACE([job].name ,'(',''),')',''),'BIN27',''))
			WHEN [job].name  LIKE '%BIN27-CF' 
				THEN TRIM(REPLACE(REPLACE(REPLACE([job].name ,'(',''),')',''),'BIN27-CF',''))
			ELSE REPLACE(REPLACE([job].name ,'(',''),')','')
		END AS JobName
		, lots.act_job_id as NextJob
		, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		, case when APCSProDB.trans.lots.process_state = 2 and APCSProDB.trans.lots.qty_in > 0 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		, APCSProDB.trans.lots.process_state AS [state]
		, device_flows.process_minutes as StandardTime
		, lotspecial.job_id as job_Id 
		, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
		, lots.quality_state

		, rack_addresses.address
		, rack_controls.name

		, device_names.official_number as LotKpcs
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
	inner join APCSProDB.trans.special_flows as special with (NOLOCK) on lots.special_flow_id = special.id
	inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
	INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		 
	
	LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
	LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id	
	
	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT value from STRING_SPLIT (@PKG, ',' )) and lotspecial.job_id in(142) and lots.act_job_id in(119,110,108,106,359,361,362,363,364,364,155) and lots.is_special_flow = 1 and lots.quality_state = 4
	and [APCSProDB].method.device_names.alias_package_group_id = 33

	UNION ALL
	-- BIN19
	SELECT [APCSProDB].[mc].[machines].name AS MCName
		, [APCSProDB].[trans].[lots].lot_no
		, [APCSProDB].[method].device_names.name AS DeviceName 
		, [APCSProDB].[method].device_names.ft_name AS FTDevice
		, [APCSProDB].[method].[packages].name AS MethodPkgName
		--, CASE 
		--	WHEN job.name LIKE '%SBLSYL%' 
		--		THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL',''))
		--	WHEN job.name = 'OS+AUTO(1)' 
		--		THEN 'AUTO1'
		--	WHEN job.name = 'AUTO(1) RE'
		--		THEN 'AUTO1'
		--	ELSE REPLACE(REPLACE(job.name,'(',''),')','')
		--END AS JobName
		, CASE 
			WHEN [job].name = 'OS+AUTO(1)SBLSYL' 
				THEN 'AUTO1'	
			WHEN [job].name  = 'OS+AUTO(1)' 
				THEN 'AUTO1'
			WHEN [job].name  = 'OS+AUTO(2)' 
				THEN 'AUTO2'
			WHEN [job].name  = 'OS+AUTO(1) HV' 
				THEN 'AUTO1'
			WHEN [job].name  = 'AUTO(1) RE'
				THEN 'AUTO1'
			WHEN [job].name  = 'AUTO(1) HV'
				THEN 'AUTO1'
			WHEN [job].name  LIKE '%SBLSYL%' 
				THEN TRIM(REPLACE(REPLACE(REPLACE([job].name ,'(',''),')',''),'SBLSYL',''))
			WHEN [job].name  LIKE '%ASISAMPLE%' 
				THEN TRIM(REPLACE(REPLACE(REPLACE([job].name ,'(',''),')',''),'ASISAMPLE',''))
			WHEN [job].name  LIKE '%BIN27' 
				THEN TRIM(REPLACE(REPLACE(REPLACE([job].name ,'(',''),')',''),'BIN27',''))
			WHEN [job].name  LIKE '%BIN27-CF' 
				THEN TRIM(REPLACE(REPLACE(REPLACE([job].name ,'(',''),')',''),'BIN27-CF',''))
			ELSE REPLACE(REPLACE([job].name ,'(',''),')','')
		END AS JobName
		, lots.act_job_id as NextJob
		, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
		, case when APCSProDB.trans.lots.process_state = 2 and APCSProDB.trans.lots.qty_in > 0 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
		, APCSProDB.trans.lots.process_state AS [state]
		, device_flows.process_minutes as StandardTime
		, lotspecial.job_id as job_Id 
		, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
		, lots.quality_state

		, rack_addresses.address
		, rack_controls.name

		, device_names.official_number as LotKpcs
	FROM [APCSProDB].[trans].lots with (NOLOCK) 
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
	inner join APCSProDB.trans.special_flows as special with (NOLOCK) on lots.special_flow_id = special.id
	inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
	INNER JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
	INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
	--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		 
	
	LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
	LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id	
	
	where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT value from STRING_SPLIT (@PKG, ',' ))  and lotspecial.job_id in(329,385,378) and lots.act_job_id in(119,110,108,106,359,361,362,363,364,155) and lots.is_special_flow = 1 and lots.quality_state = 4
	and [APCSProDB].method.device_names.alias_package_group_id = 33
END
