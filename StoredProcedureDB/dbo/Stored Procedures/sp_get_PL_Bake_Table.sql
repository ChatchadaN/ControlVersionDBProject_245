-- =============================================
-- Author:		<Jakkapong>
-- Create date: <9/16/2021>
-- Description:	<PL BAKE TABLE>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_PL_Bake_Table]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT *  INTO #LotData FROM (
SELECT pkgName,Enable_Flow,COUNT(PkgName) as countLot,1 as colIndex FROM
(		
SELECT PkgName,job_name,null  as Enable_Flow
FROM
	(
	SELECT lot_no,DN.name as Device_name,packages.name as PkgName,processes.name as process_name,jobs.name as job_name,process_state,
	(select job_id
	from [APCSProDB].trans.lots AS LOT --where lot_no = '2122A6307V'
	inner join [APCSProDB].method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join [APCSProDB].method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join [APCSProDB].method.jobs AS J on DF.job_id = J.id
	where job_no IN (0759,0758,0907) AND quality_state = 0 AND wip_state = 20 and LOT.lot_no =  lots.lot_no and DF.is_skipped != 1 ) as Enable_job
	FROM [APCSProDB].[trans].lots with (NOLOCK)
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id
	INNer Join [APCSProDB] .[method].device_names AS DN with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = DN.id 
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	inner join APCSProDB.method.processes on [APCSProDB].method.processes.id = [APCSProDB].method.jobs.process_id
	inner join APCSProDB.method.device_slips AS DS on [APCSProDB].trans.lots.device_slip_id = DS.device_slip_id AND device_flows.device_slip_id = DS.device_slip_id
	where lots.wip_state = 20 
	and is_special_flow IN (0,1) and process_state in(0,100) and quality_state IN (0,4)
	and [APCSProDB].method.processes.name in ('PL') 
	and [APCSProDB].method.jobs.name = 'PL'
	AND lot_no IN (select lot_no from [APCSProDB].trans.lots AS LOT 
	inner join [APCSProDB].method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join [APCSProDB].method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join [APCSProDB].method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0758,0759,0907) AND quality_state = 0 AND wip_state = 20) 
	) 
	as B inner join APCSProDB.method.jobs on Enable_job = id 
) as C group by PkgName,Enable_Flow
UNION
SELECT pkgName,Enable_Flow,COUNT(PkgName) as countLot,2 as colIndex FROM
(		
SELECT PkgName,job_name,null  as Enable_Flow
FROM
	(
	SELECT lot_no,DN.name as Device_name,packages.name as PkgName,processes.name as process_name,jobs.name as job_name,process_state,
	
	(select job_id
	from  [APCSProDB].trans.lots AS LOT --where lot_no = '2122A6307V'
	inner join [APCSProDB].method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join [APCSProDB].method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join [APCSProDB].method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0759,0758,0907) AND quality_state = 0 AND wip_state = 20 and LOT.lot_no =  lots.lot_no and DF.is_skipped != 1 ) as Enable_job
	FROM [APCSProDB].[trans].lots with (NOLOCK)
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id
	INNer Join [APCSProDB] .[method].device_names AS DN with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = DN.id 
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	inner join APCSProDB.method.processes on [APCSProDB].method.processes.id = [APCSProDB].method.jobs.process_id
	inner join APCSProDB.method.device_slips AS DS on [APCSProDB].trans.lots.device_slip_id = DS.device_slip_id AND device_flows.device_slip_id = DS.device_slip_id
	where lots.wip_state = 20 
	and is_special_flow IN (0,1) and process_state in(2) and quality_state IN (0,4) 
	and [APCSProDB].method.processes.name in ('PL') 
	and [APCSProDB].method.jobs.name = 'PL'
	AND lot_no IN (select lot_no from [APCSProDB].trans.lots AS LOT 
	inner join [APCSProDB].method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join [APCSProDB].method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join [APCSProDB].method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0758,0759,0907) AND quality_state = 0 AND wip_state = 20) 
	) 
	as B inner join APCSProDB.method.jobs on Enable_job = id 
) as C group by PkgName,Enable_Flow
UNION

	SELECT pkgName,Enable_Flow,COUNT(PkgName) as countLot,3 as colIndex FROM
(		
SELECT PkgName,job_name,null  as Enable_Flow
FROM
	(
	SELECT lot_no,DN.name as Device_name,packages.name as PkgName,processes.name as process_name,jobs.name as job_name,process_state,
	

	(select job_id
	from [APCSProDB].trans.lots AS LOT 
	inner join [APCSProDB].method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join [APCSProDB].method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join [APCSProDB].method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0759,0758,0907) AND quality_state = 0 AND wip_state = 20 and LOT.lot_no =  lots.lot_no and DF.is_skipped != 1 ) as Enable_job
	FROM [APCSProDB].[trans].lots with (NOLOCK)
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id
	INNer Join [APCSProDB] .[method].device_names AS DN with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = DN.id 
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	inner join APCSProDB.method.processes on [APCSProDB].method.processes.id = [APCSProDB].method.jobs.process_id
	inner join APCSProDB.method.device_slips AS DS on [APCSProDB].trans.lots.device_slip_id = DS.device_slip_id AND device_flows.device_slip_id = DS.device_slip_id
	where lots.wip_state = 20 
	and is_special_flow IN (0,1) and process_state in(0,100,2) and quality_state IN (0,4) 
	and ([APCSProDB].method.processes.id in (32,27,28,8) 
	OR [APCSProDB].method.jobs.id IN (106,155))
	AND lot_no IN (select lot_no from [APCSProDB].trans.lots AS LOT 
	inner join [APCSProDB].method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join [APCSProDB].method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join [APCSProDB].method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0758,0759,0907) AND quality_state = 0 AND wip_state = 20)
	) 
	as B inner join APCSProDB.method.jobs on Enable_job = id 
) as C group by PkgName,Enable_Flow


	UNION

	SELECT pkgName,Enable_Flow,COUNT(PkgName) as countLot,4 as colIndex FROM
(		
	SELECT PkgName,job_name,
case
	when jobs.name = 'FLFT' THEN 'FLFT'
	when jobs.name = 'FLFTTP' THEN 'FLFT'
	else 'Error'
END as Enable_Flow
FROM
	(
	SELECT lot_no,DN.name as Device_name,packages.name as PkgName,processes.name as process_name,jobs.name as job_name,process_state,
	

	(select job_id
	from APCSProDB.trans.lots AS LOT 
	inner join APCSProDB.method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join APCSProDB.method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join APCSProDB.method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0759,0758) AND quality_state = 0 AND wip_state = 20 and LOT.lot_no =  lots.lot_no and DF.is_skipped != 1 ) as Enable_job
		--** ???????? job ???????????????????????? Job ????? **--
	FROM [APCSProDB].[trans].lots with (NOLOCK)
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id
	INNer Join [APCSProDB] .[method].device_names AS DN with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = DN.id 
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	inner join APCSProDB.method.processes on APCSProDB.method.processes.id = APCSProDB.method.jobs.process_id
	inner join APCSProDB.method.device_slips AS DS on APCSProDB.trans.lots.device_slip_id = DS.device_slip_id AND device_flows.device_slip_id = DS.device_slip_id
	where lots.wip_state = 20 
	and is_special_flow IN (0,1) and process_state in(0,100,2) and quality_state IN (0,4)
	and APCSProDB.method.processes.id in (32,27,28,8) -- 8 all FL JOB
	and lot_no NOT IN (select lot_no from APCSProDB.trans.lots where act_job_id IN (92,93) and wip_state = 20 and process_state = 2 and quality_state IN (0,4) )
	AND lot_no IN (select lot_no from APCSProDB.trans.lots AS LOT 
	inner join APCSProDB.method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join APCSProDB.method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join APCSProDB.method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0758,0759,0907) AND quality_state = 0 AND wip_state = 20) 
	) 
	as B inner join APCSProDB.method.jobs on Enable_job = id 
) as C group by PkgName,Enable_Flow


	UNION

		
SELECT pkgName,Enable_Flow,COUNT(PkgName) as countLot,5 as colIndex FROM
(		
SELECT PkgName,job_name,
case
	when jobs.name LIKE 'FLFT%' THEN 'FLFT'
	else 'Error'
END as Enable_Flow
FROM
	(
	SELECT lot_no,DN.name as Device_name,packages.name as PkgName,processes.name as process_name,jobs.name as job_name,process_state,
	


	(select job_id
	from APCSProDB.trans.lots AS LOT 
	inner join APCSProDB.method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join APCSProDB.method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join APCSProDB.method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0759,0758) AND quality_state = 0 AND wip_state = 20 and LOT.lot_no =  lots.lot_no and DF.is_skipped != 1 ) as Enable_job
	FROM [APCSProDB].[trans].lots with (NOLOCK)
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id
	INNer Join [APCSProDB] .[method].device_names AS DN with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = DN.id 
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	inner join APCSProDB.method.processes on APCSProDB.method.processes.id = APCSProDB.method.jobs.process_id
	inner join APCSProDB.method.device_slips AS DS on APCSProDB.trans.lots.device_slip_id = DS.device_slip_id AND device_flows.device_slip_id = DS.device_slip_id
	where lots.wip_state = 20 
	and is_special_flow IN (0,1) and process_state in(2) and quality_state IN (0,4)
	and APCSProDB.method.jobs.id in (92,93)
	AND lot_no IN (select lot_no from APCSProDB.trans.lots AS LOT 
	inner join APCSProDB.method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join APCSProDB.method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join APCSProDB.method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0758,0759,0907) AND quality_state = 0 AND wip_state = 20) 
	) 
	as B inner join APCSProDB.method.jobs on Enable_job = id 
) as C group by PkgName,Enable_Flow


	UNION 


SELECT pkgName,Enable_Flow,COUNT(PkgName) as countLot,6 as colIndex FROM
(		
SELECT PkgName,job_name,
case
	when jobs.name LIKE '%AUTO%' THEN 'FTFT'
	else 'Error'
END as Enable_Flow
FROM
	(
	SELECT lot_no,DN.name as Device_name,packages.name as PkgName,processes.name as process_name,jobs.name as job_name,process_state,
	--ทำการ sub query เอา lot_no ที่ได้ในรอบการค้นหา ไปทำการ sub query เอาแค่อยู่ใน FTFT *(0907)
	(select job_id
	from APCSProDB.trans.lots AS LOT 
	inner join APCSProDB.method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join APCSProDB.method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join APCSProDB.method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0907) AND quality_state = 0 AND wip_state = 20 and LOT.lot_no =  lots.lot_no and DF.is_skipped != 1 ) as Enable_job
		--** แก้ไขเลข job เพื่อเอางานที่ต้องการจาก Job นั้นๆ **--
	FROM [APCSProDB].[trans].lots with (NOLOCK)
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id
	INNer Join [APCSProDB] .[method].device_names AS DN with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = DN.id 
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	inner join APCSProDB.method.processes on APCSProDB.method.processes.id = APCSProDB.method.jobs.process_id
	inner join APCSProDB.method.device_slips AS DS on APCSProDB.trans.lots.device_slip_id = DS.device_slip_id AND device_flows.device_slip_id = DS.device_slip_id
	where lots.wip_state = 20 
	and is_special_flow IN (0,1) and process_state in(0,100,2) and quality_state IN (0,4)
	and (APCSProDB.method.processes.id in (32,27,28) --แก้ไขค่านี้เพื่อ Process ที่ต้องการ ยกตัวอย่างเช่น PL ที่ช่อง AFTER จะเป็นค่า BAKE
	OR APCSProDB.method.jobs.id IN (278,88,106,155,87))  --- แก้ไขค่านี้เพื่อ Job ที่ต้องการ ยกตัวอย่างเช่น PL ที่ช่อง AFTER จะเป็นค่า BAKE
	and lot_no NOT IN (select lot_no from APCSProDB.trans.lots where act_job_id IN (106,155) and wip_state = 20 and process_state = 2 and quality_state IN (0,4) )
	AND lot_no IN (select lot_no from APCSProDB.trans.lots AS LOT 
	inner join APCSProDB.method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join APCSProDB.method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join APCSProDB.method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0758,0759,0907) AND quality_state = 0 AND wip_state = 20) --ในส่วนนี้จะเอา lot ที่มีการผ่าน STEP FLFT FLFTTP FTFT(AUTO1) มารวมกันทั้งหมด
	) 
	as B inner join APCSProDB.method.jobs on Enable_job = id 
) as C group by PkgName,Enable_Flow

	UNION


SELECT pkgName,Enable_Flow,COUNT(PkgName) as countLot,7 as colIndex FROM
(
SELECT PkgName,job_name,
case
	when jobs.name LIKE '%AUTO%' THEN 'FTFT'
	else 'Error'
END as Enable_Flow
FROM
	(
	SELECT lot_no,DN.name as Device_name,packages.name as PkgName,processes.name as process_name,jobs.name as job_name,process_state,
	--ทำการ sub query เอา lot_no ที่ได้ในรอบการค้นหา ไปทำการ sub query เอาแค่อยู่ใน FTFT *(0907)
	(select job_id
	from APCSProDB.trans.lots AS LOT 
	inner join APCSProDB.method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join APCSProDB.method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join APCSProDB.method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0907) AND quality_state = 0 AND wip_state = 20 and LOT.lot_no =  lots.lot_no and DF.is_skipped != 1 ) as Enable_job
		--** แก้ไขเลข job เพื่อเอางานที่ต้องการจาก Job นั้นๆ **--
	FROM [APCSProDB].[trans].lots with (NOLOCK)
	INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
	INNER JOIN [APCSProDB].method.jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
	LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id
	INNer Join [APCSProDB] .[method].device_names AS DN with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = DN.id 
	inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
	inner join APCSProDB.method.processes on APCSProDB.method.processes.id = APCSProDB.method.jobs.process_id
	inner join APCSProDB.method.device_slips AS DS on APCSProDB.trans.lots.device_slip_id = DS.device_slip_id AND device_flows.device_slip_id = DS.device_slip_id
	where lots.wip_state = 20
	and is_special_flow IN (0,1) and process_state in(2) and quality_state IN (0,4)
	and APCSProDB.method.processes.id IN (9) --FT --แก้ไขค่านี้เพื่อ Process ที่ต้องการ ยกตัวอย่างเช่น PL ที่ช่อง AFTER จะเป็นค่า BAKE
	and APCSProDB.method.jobs.id IN (106,155) --AUTO 1--- แก้ไขค่านี้เพื่อ Job ที่ต้องการ ยกตัวอย่างเช่น PL ที่ช่อง AFTER จะเป็นค่า BAKE
	AND lot_no IN (select lot_no from APCSProDB.trans.lots AS LOT 
	inner join APCSProDB.method.device_slips AS DS on LOT.device_slip_id = DS.device_slip_id
	inner join APCSProDB.method.device_flows AS DF on LOT.device_slip_id = DF.device_slip_id AND DS.device_slip_id = DF.device_slip_id
	inner join APCSProDB.method.jobs AS J on DF.job_id = J.id
	where is_released = 1 AND job_no IN (0758,0759,0907) AND quality_state = 0 AND wip_state = 20) --ในส่วนนี้จะเอา lot ที่มีการผ่าน STEP FLFT FLFTTP FTFT(AUTO1) มารวมกันทั้งหมด
	) 
	as B inner join APCSProDB.method.jobs on Enable_job = id 
) as C group by PkgName,Enable_Flow


) as A	order by colIndex,PkgName



select 
PkgName,
ISNULL([1],0) as Col_1,
ISNULL([2],0) as Col_2,
ISNULL([3],0) as Col_3,
ISNULL([4],0) as Col_4,
ISNULL([5],0) as Col_5,
ISNULL([6],0) as Col_6,
ISNULL([7],0) as Col_7
from 
(
	select PkgName,countLot,colindex
	from #LotData
) as Datatable
pivot
(
	max(countLot)
	FOR colIndex in ([1],[2],[3],[4],[5],[6],[7])
) as pivotTable










drop table #LotData
END
