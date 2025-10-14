-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_tp_qa_calculate_ver_temp]
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
	@Pk_name varchar(MAX) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--SELECT <@Param1, sysname, @p1>, <@Param2, sysname, @p2>
	IF(@Pk_name is null or @Pk_name = '')
	BEGIN
		delete from DBx.dbo.scheduler_tp_qa_calculate_01
		insert into DBx.dbo.scheduler_tp_qa_calculate_01
		([pkgname]
		,[devicename]
		,[tp_rank]
		,[jobname]
		,[jobid]
		,[alllot]
		,[sumlots]
		,[sumWipQa]
		,[hold]
		,[sumkpcs]
		,[standardtime]
		,[group])
	
		SELECT DISTINCT WIP.pkg_name AS [pkgname]
	, WIP.device_name AS [devicename]
	, WIP.tp_rank as [tp_rank]
	, WIP.job_name AS [jobname] 
	, WIP.job_id as [jobid]
	, (select COUNT(lot_no) from [DBx].[dbo].[scheduler_tp_qa_wip_01]
		where [DBx].[dbo].[scheduler_tp_qa_wip_01].device_name = WIP.device_name 
		and [DBx].[dbo].[scheduler_tp_qa_wip_01].job_name = WIP.job_name ) as [allLots]

	, (select COUNT(lot_no) from [DBx].[dbo].[scheduler_tp_qa_wip_01] 
		where [DBx].[dbo].[scheduler_tp_qa_wip_01].device_name = WIP.device_name 
		and [DBx].[dbo].[scheduler_tp_qa_wip_01].job_name = WIP.job_name 
		and [DBx].[dbo].[scheduler_tp_qa_wip_01].qa_in is not null ) as [sumlots]

	, (select COUNT(lot_no) from [DBx].[dbo].[scheduler_tp_qa_wip_01] 
		where [DBx].[dbo].[scheduler_tp_qa_wip_01].device_name = WIP.device_name 
		and [DBx].[dbo].[scheduler_tp_qa_wip_01].job_name = WIP.job_name 
		and [DBx].[dbo].[scheduler_tp_qa_wip_01].job_id in (122,316)) as [sumWipQa]

	, (select COUNT(lot_no) from [DBx].[dbo].[scheduler_tp_qa_wip_01] 
		where [DBx].[dbo].[scheduler_tp_qa_wip_01].device_name = WIP.device_name 
		and [DBx].[dbo].[scheduler_tp_qa_wip_01].job_name = WIP.job_name 
		and [DBx].[dbo].[scheduler_tp_qa_wip_01].state = 3 ) as hold
	, sum(WIP.kpcs) AS [sumkpcs] 
	, sum(WIP.standare_time) as [standardtime]
	, WIP.pkg_id
	FROM [DBx].[dbo].[scheduler_tp_qa_wip_01] as WIP
	group by WIP.pkg_name
	, WIP.device_name
	, WIP.job_name
	, WIP.job_id
	, WIP.pkg_id
	,WIP.tp_rank
	order by WIP.job_name
	END
	ELSE
	BEGIN
		CREATE TABLE #temp_tp_wip
(
	--RowIndex int,PackageName varchar(30),DeviceName varchar(30)
	mc_name varchar(20),lot_no varchar(10),device_name varchar(30),pkg_name varchar(30),job_name varchar(30),kpcs int,qty_production real,[state] int,standare_time int,job_id int,update_at Datetime,rack_address varchar(5),rack_name varchar(30),pkg_id int
)

insert into #temp_tp_wip 
SELECT [APCSProDB].[mc].[machines].name AS mc_name
		 , [APCSProDB].[trans].[lots].lot_no
		 , [APCSProDB].[method].device_names.name AS device_name 
		 , [APCSProDB].[method].[packages].name AS pkg_name
		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS job_name
		 , [APCSProDB].[trans] .lots.qty_in  AS kpcs 
		 , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / IIF([APCSProDB].[trans].lots.qty_in <> 0,[APCSProDB].[trans].lots.qty_in ,[APCSProDB].[trans].lots.qty_pass + 1)) else 1 end as qty_production
		 , APCSProDB.trans.lots.quality_state AS [state]
		 , device_flows.process_minutes as standard_time
		 , lots.act_job_id as job_Id 
		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at

		 , rack_addresses.address as rack_address
		 , rack_controls.name as rack_name

		 , [APCSProDB].[method].[packages].package_group_id
		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
		LEFT JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = [APCSProDB].[trans].[lots].device_slip_id and device_flows.step_no = lots.step_no	 

		LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id		
		
		where lots.wip_state = 20 
		and [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @Pk_name , ',' )) 
		and [APCSProDB].[trans].[lots].act_job_id in (222,231,236,289,197,291,122,316,401,409,428) 
		and [APCSProDB].[trans].[lots].is_special_flow = 0 
		--and [APCSProDB].method.device_names.alias_package_group_id != 33
		--and [APCSProDB].[trans].[lots].quality_state = 0 
	 
		union all

		SELECT distinct [APCSProDB].[mc].[machines].name AS mc_name
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS device_name 
			, [APCSProDB].[method].[packages].name AS pkg_name
			, REPLACE(REPLACE(job.name,'(',''),')','') AS job_name
			, [APCSProDB].[trans] .lots.qty_in  AS kpcs 
			, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / IIF([APCSProDB].[trans].lots.qty_in <> 0,[APCSProDB].[trans].lots.qty_in ,[APCSProDB].[trans].lots.qty_pass + 1)) else 1 end as qty_production
			, APCSProDB.trans.lots.quality_state AS [state]
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
		LEFT JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNER JOIN [APCSProDB].method.jobs as job ON  job.id = lotspecial.job_id
		INNer Join [APCSProDB] .[method].device_names on [APCSProDB].trans.lots.act_device_name_id = [APCSProDB] .[method].device_names.id
		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		
		--LEFT join [APCSProDB].trans.locations as locations on locations.id = [APCSProDB].[trans].[lots].location_id 

		LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id	

		where lots.wip_state = 20 
		and [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @Pk_name , ',' ))    
		and lotspecial.job_id in(222,231,236,289,197,291,122,316,397,401,409,428) 
		and [APCSProDB].[trans].[lots].is_special_flow = 1 
		--and [APCSProDB].method.device_names.alias_package_group_id != 33 
		--and [APCSProDB].[trans].[lots].quality_state != 3

		--UNION ALL
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
		-- , locations.address as rack_address
		-- , locations.name as rack_name
		-- , [APCSProDB].[method].[packages].package_group_id
		--FROM [APCSProDB].[trans].lots 
		--INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
		--LEFT JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		--INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		--inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = [APCSProDB].[trans].[lots].device_slip_id and device_flows.step_no = lots.step_no	 
		--LEFT join [APCSProDB].trans.locations as locations on locations.id = [APCSProDB].[trans].[lots].location_id 
		--where lots.wip_state = 20 
		--and [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @Pk_name , ',' )) 
		--and [APCSProDB].[trans].[lots].act_job_id in (231,236,289,197,291) 
		--and [APCSProDB].[trans].[lots].is_special_flow = 0 
		--and [APCSProDB].method.device_names.alias_package_group_id = 33
		--and [APCSProDB].[trans].[lots].quality_state = 0 
	 
		--union all

		--SELECT distinct [APCSProDB].[mc].[machines].name AS mc_name
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
		--	, locations.address as rack_address
		-- , locations.name as rack_name
		-- , [APCSProDB].[method].[packages].package_group_id
		--FROM [APCSProDB].[trans].lots 
		--INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		--inner join APCSProDB.trans.special_flows as special on special.lot_id = [APCSProDB].[trans].[lots].id
		--inner join APCSProDB.trans.lot_special_flows as lotspecial on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
		--LEFT JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		--INNER JOIN [APCSProDB].method.jobs as job ON  job.id = lotspecial.job_id
		--INNer Join [APCSProDB] .[method].device_names on [APCSProDB].trans.lots.act_device_name_id = [APCSProDB] .[method].device_names.id
		--inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		
		--LEFT join [APCSProDB].trans.locations as locations on locations.id = [APCSProDB].[trans].[lots].location_id 
		--where lots.wip_state = 20 
		--and [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @Pk_name , ',' ))    
		--and lotspecial.job_id in(231,236,289,197,291) 
		--and [APCSProDB].[trans].[lots].is_special_flow = 1 
		--and [APCSProDB].method.device_names.alias_package_group_id = 33 
		--and [APCSProDB].[trans].[lots].quality_state != 3

		--select * from #temp_tp_wip
		delete from DBx.dbo.scheduler_tp_qa_calculate_01 where DBx.dbo.scheduler_tp_qa_calculate_01.pkgname in (SELECT * from STRING_SPLIT ( @Pk_name , ',' ))  
		
		insert into DBx.dbo.scheduler_tp_qa_calculate_01
		([pkgname]
		,[devicename]
		,[tp_rank]
		,[jobname]
		,[jobid]
		,[alllot]
		,[sumlots]
		,[sumWipQa]
		,[hold]
		,[sumkpcs]
		,[standardtime]
		,[group])
		SELECT DISTINCT WIP.pkg_name AS [pkgname]
		, WIP.device_name AS [devicename]
		,''
		, WIP.job_name AS [jobname] 
		, WIP.job_id as [jobid]
		, (select COUNT(lot_no) from #temp_tp_wip
			where #temp_tp_wip.device_name = WIP.device_name 
			and #temp_tp_wip.job_name = WIP.job_name ) as [allLots] --sum lot not on rack

		, (select COUNT(lot_no) from [DBx].[dbo].[scheduler_tp_qa_wip_01] 
			where [DBx].[dbo].[scheduler_tp_qa_wip_01].device_name = WIP.device_name 
			and [DBx].[dbo].[scheduler_tp_qa_wip_01].job_name = WIP.job_name ) as [sumlots] --sum lot on rack

		, 0 as [sumWipQa]

		, (select COUNT(lot_no) from #temp_tp_wip 
			where #temp_tp_wip.device_name = WIP.device_name 
			and #temp_tp_wip.job_name = WIP.job_name 
			and #temp_tp_wip.state = 3 ) as hold
		, sum(WIP.kpcs) AS [sumkpcs] 
		, sum(WIP.standare_time) as [standardtime]
		, WIP.pkg_id
		FROM #temp_tp_wip as WIP
		group by WIP.pkg_name
		, WIP.device_name
		, WIP.job_name
		, WIP.job_id
		, WIP.pkg_id

		order by WIP.job_name
		drop table #temp_tp_wip
	END

	--SELECT REPLACE([APCSProDB].[method].[packages].name,' ','') AS [pkgname]
	-- , REPLACE([APCSProDB].[method].device_names.name,' ','') AS [devicename] 
	-- , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS [jobname]
	-- , lots.act_job_id as [jobid] 
	-- , COUNT(lots.id) as [sumlots]
	-- , (SELECT COUNT([APCSProDB].[trans].lots .id) 
	--		FROM [APCSProDB].[trans].lots 
	--		INNER JOIN [APCSProDB].[method].packages as pkg ON [APCSProDB].trans.lots.act_package_id = pkg.id 
	--		INNER JOIN [APCSProDB].method.jobs as job ON [APCSProDB].trans.lots.act_job_id = job.id 
	--		INNER JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	--		INNer Join [APCSProDB] .[method].device_names as devices on [APCSProDB].trans.lots.act_device_name_id = devices.id	
	--		inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = devices.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	--		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	--		where lots.wip_state = 20 and  act_package_id in (235, 242,246)  and act_job_id in(122,236,289,316) and lots.quality_state = 3 
	--			and devices.name = [APCSProDB].[method].device_names.name and job.name =  [APCSProDB].[method].[jobs].name
	--		group by devices.name,pkg.name,job.name) as hold

	-- , sum([APCSProDB].[trans] .lots.qty_in ) AS [sumkpcs] 
	 
	-- --, APCSProDB.trans.lots.process_state AS [state]
	-- , sum(device_flows.process_minutes) as [standardtime]
	 
	--FROM [APCSProDB].[trans].lots 
	--INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	--INNER JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
	--INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id	
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	--inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	--where lots.wip_state = 20 and  act_package_id in (235, 242,246)  and act_job_id in(122,236,289,316) 

	--group by [APCSProDB].[method].device_names.name
	--	,[APCSProDB] .[method].device_names.ft_name
	--	,[APCSProDB].[method].[packages].name
	--	,[APCSProDB].[method].[jobs].name
	--	,lots.act_job_id
	--order by [jobname]
	
END