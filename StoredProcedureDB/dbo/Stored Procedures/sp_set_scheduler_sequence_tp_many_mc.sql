-- =============================================
-- Author:		<Jakkapong P.>
-- Create date: <05072021>
-- Description:	<Backup next lot>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_sequence_tp_many_mc]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
----** add status rack 2023-03-09
DECLARE @PackageName varchar(MAX);
SET @PackageName = 'HRP5,HRP7,HTQFP64AV,HTQFP64BV,HTQFP64V,HTQFP64V-HF,QFP32,SQFP-T52,VQFP64,VQFP48C,TO252-J5,TO252-J5F,HSON8,HSON8-HF,HSON-A8,MSOP8,SSOP-B20W,SSOP-B10W,SSOP-B28W,TO252S-3,TO252S-5,TO252S-5+,';
SET @PackageName += 'SSOP-A32,SSOP-B40,TO263-3,TO263-5,TO263-7,HTSSOP-A44,HTSSOP-A44R,HTSSOP-B54,HTSSOP-B54R,HTSSOP-B54E,TO252-J3,SSOP-A20,SSOP-A24,HSOP-M36,SOP20,SOP22,SOP24,TO263-3F,TO263-5F,SOT223-4,SOT223-4F,TSSOP-C48V,TO263-7L,HTSSOPB20E,TO252-5,HTSSOPC48E,HTSSOP-C64A,TSSOP-B30,';
SET @PackageName += 'TO252S-7+,SSOP-A54_23,SSOP-A54_36,SSOP-A54_42,SSOP-A26_20,SSOP-B24,SSOP-B28,SSOP-B30,SSOP-A32,SSOP-B40,SOP-JW8,HSSOP-C16,HTSSOP-B20,HTSSOP-C48R,HTSSOP-C48,HTSSOP-C48E,HTSSOP-B40,SSOP-C38W,TO252-3,TO252-5,';
SET @PackageName += 'SSOPB28WR6,TSSOP-B8J,MSOP8-HF,SSOPB30W19,SSOP-C26W,MSOP8E-HF,SSOPB20WR1,SSOP-B20WA,HTSSOPB20X';
----------------For TEST data output-----------------
delete from [DBx].[dbo].[scheduler_tp_qa_wip] where pkg_id in (SELECT DISTINCT package_group_id FROM APCSProDB.method.packages WHERE name in ((SELECT * from STRING_SPLIT( @PackageName , ',' ))));

BEGIN TRANSACTION;
BEGIN TRY

--Delete old table insert new table HERE !!!
DELETE FROM DBxDW.dbo.[scheduler_temp_seq_tp];




CREATE TABLE #scheduler_temp_seq_tp_TEST
(
 lot_no varchar(30),
 flow varchar(30),
 ft_device varchar(30),
 rack_address varchar(30),
 rack_name varchar(30),
 machine_name varchar(30),
 seq_no decimal,
 package_name varchar(30),
 lot_end DATETIME,
 lot_start DATETIME
);



	  

-----------------------------------------------------




-----------------Get individual WIP include QA and TP Job-----------------------------------------------------------/
	INSERT INTO [DBx].[dbo].[scheduler_tp_qa_wip]([mc_name] ,lot_no ,device_name ,pkg_name ,job_name ,kpcs ,qty_production ,state ,standare_time ,job_id ,update_at ,rack_address ,rack_name ,pkg_id)
	SELECT [APCSProDB].[mc].[machines].name AS mc_name
		 , [APCSProDB].[trans].[lots].lot_no
		 , TRIM([APCSProDB].[method].device_names.name) AS device_name 
		 , TRIM([APCSProDB].[method].[packages].name) AS pkg_name
		 , REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','') AS job_name
		 , [APCSProDB].[trans] .lots.qty_in  AS kpcs 
		 , case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / IIF([APCSProDB].[trans].lots.qty_in <> 0,[APCSProDB].[trans].lots.qty_in ,[APCSProDB].[trans].lots.qty_pass + 1)) else 1 end as qty_production
		 , APCSProDB.trans.lots.process_state AS [state]
		 , device_flows.process_minutes as standard_time
		 , lots.act_job_id as job_Id 
		 , (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at
		 , locations.address as rack_address
		 , locations.name as rack_name
		 , [APCSProDB].[method].[packages].package_group_id
		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id 
		LEFT JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = [APCSProDB].[trans].[lots].device_slip_id and device_flows.step_no = lots.step_no	 
		INNER join [APCSProDB].trans.locations as locations on locations.id = [APCSProDB].[trans].[lots].location_id 
		------------------------------------------------------------------------------------------------------------
		---- add status rack 2023-03-09
		------------------------------------------------------------------------------------------------------------
		left join [DBx].[dbo].[rcs_current_locations] as [current_locations] with (NOLOCK) on [locations].[id] = [current_locations].[location_id]
			and [lots].[id] = [current_locations].[lot_id]
		------------------------------------------------------------------------------------------------------------
		left join APCSProDB.trans.days as days on lots.in_plan_date_id = days.id
		where lots.wip_state = 20 
		and [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) 
		and [APCSProDB].[trans].[lots].act_job_id in (222,231,236,289,197,291,122,316,353,397,401,409,428) 
		and [APCSProDB].[trans].[lots].is_special_flow = 0 
		--and [APCSProDB].method.device_names.alias_package_group_id != 33
		and [APCSProDB].[trans].[lots].quality_state = 0 
		and days.date_value <= GETDATE()
		------------------------------------------------------------------------------------------------------------
		---- add status rack 2023-03-09
		------------------------------------------------------------------------------------------------------------
		and [current_locations].[status] = 1
		------------------------------------------------------------------------------------------------------------
	 
		union all

		SELECT distinct [APCSProDB].[mc].[machines].name AS mc_name
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS device_name 
			, [APCSProDB].[method].[packages].name AS pkg_name
			, REPLACE(REPLACE(job.name,'(',''),')','') AS job_name
			, [APCSProDB].[trans] .lots.qty_in  AS kpcs 
			, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / IIF([APCSProDB].[trans].lots.qty_in <> 0,[APCSProDB].[trans].lots.qty_in ,[APCSProDB].[trans].lots.qty_pass + 1))  else 1 end as qty_production
			, APCSProDB.trans.lots.process_state AS [state]
			, device_flows.process_minutes as standard_time
			, lotspecial.job_id as job_Id 
			, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at 
			, locations.address as rack_address
		 , locations.name as rack_name
		 , [APCSProDB].[method].[packages].package_group_id
		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		inner join APCSProDB.trans.special_flows as special on special.id = [APCSProDB].[trans].[lots].special_flow_id
		inner join APCSProDB.trans.lot_special_flows as lotspecial on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
		LEFT JOIN [APCSProDB].mc.machines ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNER JOIN [APCSProDB].method.jobs as job ON  job.id = lotspecial.job_id
		INNer Join [APCSProDB] .[method].device_names on [APCSProDB].trans.lots.act_device_name_id = [APCSProDB] .[method].device_names.id
		inner join [APCSProDB].method.device_flows on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no		
		INNER join [APCSProDB].trans.locations as locations on locations.id = [APCSProDB].[trans].[lots].location_id
		------------------------------------------------------------------------------------------------------------
		---- add status rack 2023-03-09
		------------------------------------------------------------------------------------------------------------
		left join [DBx].[dbo].[rcs_current_locations] as [current_locations] with (NOLOCK) on [locations].[id] = [current_locations].[location_id]
			and [lots].[id] = [current_locations].[lot_id]
		------------------------------------------------------------------------------------------------------------
		left join APCSProDB.trans.days as days on lots.in_plan_date_id = days.id
		where lots.wip_state = 20 
		and [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))    
		and lotspecial.job_id in(222,231,236,289,197,291,122,316,353,397,401,409,428) 
		and [APCSProDB].[trans].[lots].is_special_flow = 1 
		--and [APCSProDB].method.device_names.alias_package_group_id != 33 
		and [APCSProDB].[trans].[lots].quality_state != 3
		and days.date_value <= GETDATE()
		------------------------------------------------------------------------------------------------------------
		---- add status rack 2023-03-09
		------------------------------------------------------------------------------------------------------------
		and [current_locations].[status] = 1
		------------------------------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------------------------------------------------------/


----- SET TP Calculate TO sum all same deivce into lot ----------***************

 EXEC	[StoredProcedureDB].[dbo].[sp_set_scheduler_tp_qa_calculate] @Pk_name = @PackageName;

------------------------------------------------------------------************



---------------------------------------------------------------------------

CREATE TABLE #tempCalculate_TEST
(
    PackageName varchar(30),DeviceName varchar(30),Job_Name Varchar(20),Job_ID int,SumLots int,SumKpcs int,State varchar(10),StandardTime float,SumHold int,
	AllLots int,SumQA int,PKG_ID int,TP_Rank varchar(10),Is_GDIC int
);

-- GET TP Lot Summation Calucate --

INSERT INTO #tempCalculate_TEST
EXEC	[StoredProcedureDB].[dbo].[sp_get_scheduler_tp_qa_calculate] @value = 1;


---------------------------------------------------------------------


	CREATE TABLE #TPACC_TEST
	(
		PackageName varchar(30),DeviceName varchar(30),INPUT int,[OUTPUT] int,SUMMARY int
	);

	DECLARE @ResultStart varchar(MAX) = CONVERT(DateTime,CONVERT(Varchar, YEAR(GETDATE())) +'-'+CONVERT(Varchar, MONTH(GETDATE()))+'-01 08:00');--CONVERT (date,  DATEADD(day, -9, GETDATE()))
	DECLARE @ResultEND varchar(MAX) = (SELECT GETDATE());

	DECLARE @PlanStart varchar(MAX) = DATEADD(DAY, -9, @ResultStart);
	DECLARE @PlanEND varchar(MAX) = CONVERT(DateTime,CONVERT(Varchar, CONVERT(date, DATEADD(DAY, -9, GETDATE())))+' 08:00');

	INSERT INTO #TPACC_TEST
	select result.name as pkgname, result.Devicename as devicename , input.Kpcs as input , result.Kpcs as [output], result.Kpcs-input.Kpcs as summary
	from(select pk.name, device.id AS device_id , device.name as Devicename,SUM( lots.qty_in)  as Kpcs
			from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) 
			inner join [APCSProDB].trans.lots as lots with (NOLOCK) on lots.id = lot_record.lot_id
			inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lots.act_device_name_id = device.id 
			inner join APCSProDB.method.packages as PK with (NOLOCK) on PK.id = lots.act_package_id
		where lot_record.record_class = 2  and job_id in (222,231,236,289,397,401,409,428)  and PK.name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) --กำหนดแพ็คเก็ทกรุ๊ป
			and lot_record.recorded_at between @ResultStart and @ResultEND
		group by device.name ,pk.name, device.id) as result 

	inner join 

		(SELECT device.id AS device_id, device.name as Devicename,sum(lots.qty_in) as Kpcs
			FROM [APCSProDB].[trans].lots as lots with (NOLOCK) 
			inner join [APCSProDB].[method].device_names as device with (NOLOCK) on lots.act_device_name_id = device.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = device.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].[trans].[days] as days with (NOLOCK) on days.id = lots.in_date_id
			where lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips with (NOLOCK)) 
				and days.date_value between @PlanStart  and @PlanEND
			group by device.name , device.ft_name, device.id) as input 
	
	ON input.device_id = result.device_id;

-----------------------------------------------------------------------------------------------------------------

CREATE TABLE #Get_SumData_TEST
(
	PackageName varchar(30),DeviceName varchar(30),SUMMARY int,CountLots  int,Is_GDIC int,Sum_Job_Name varchar(30)
);

	INSERT INTO #Get_SumData_TEST
		SELECT  Cal.PackageName
				,Cal.DeviceName     --ROW_NUMBER() OVER(ORDER BY acc.SUMMARY ASC)
				,case when acc.SUMMARY is NULL
					THEN 0
				ELSE acc.SUMMARY END as SUMMARY
				,Cal.AllLots  --All lot in process where name TP
				,Cal.Is_GDIC
				,Cal.Job_Name
		FROM #tempCalculate_TEST as Cal
		LEFT JOIN #TPACC_TEST as Acc on (Acc.PackageName = Cal.PackageName) AND (Acc.DeviceName = Cal.DeviceName)
		WHERE Job_Name LIKE '%TP%' AND Cal.PackageName in (SELECT * from STRING_SPLIT ( @PackageName , ',' ));
		--filter only TP WIP

--------------------------------------------------------------------------------------------------------------

-----------------------------TAKE ALL LOT IN MACHINE TO BE FIRST SQ------------------------------------------

CREATE TABLE #Result_WIP_ALL
(
lot_no varchar(30),flow varchar(30),FTDevice varchar(30),rack_address NVARCHAR(30),rack_name NVARCHAR(30),machine_name VARCHAR(30),
seq_no bigint, package_name varchar(30),lot_end datetime,lot_start datetime
);


		select DISTINCT device.name as DeviceName,device.ft_name as FTDevice, lot.lot_no,mc.name as McName,REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
			, max(lot_record.recorded_at) as STARTTIME
			, (SELECT DATEADD(MINUTE, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))), max(lot_record.recorded_at))) AS ENDTIME
			, pk.name as pkg INTO #getLotInMC_TEST
		from  [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
			inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id 
			INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lot.act_job_id
			inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = lot.machine_id
			INNER JOIN APCSProDB.method.packages as pk on pk.id = lot.act_package_id
			inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
			inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
		where lot.act_job_id  in (236,289,231,397,401,222,409,428) 
			and lot.process_state IN (2,102)  
			and lot.wip_state = 20 
			and lot_record.record_class in (1,5) 
			and lot.is_special_flow = 0
			and pk.name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
		group by lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
			,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in,job.name,pk.name
		union all
		select DISTINCT device.name as DeviceName,device.ft_name as FTDevice, lot.lot_no,mc.name as McName,REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
		,max(lot_record.recorded_at) as STARTTIME
		,(SELECT DATEADD(MINUTE, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))), max(lot_record.recorded_at))) AS ENDTIME
		,pk.name
		from  [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
			inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id 
			inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lot.id
			inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id  and special.step_no = lotspecial.step_no
			INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
			inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
			INNER JOIN APCSProDB.method.packages as pk on pk.id = lot.act_package_id
			inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = special.machine_id
			inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
		where lotspecial.job_id  in (222,236,289,231,397,401,409,428) 
			and special.process_state IN (2,102)  
			and lot.wip_state = 20 
			and lot_record.record_class in (1,5) 
			and lot.is_special_flow = 1 
			and pk.name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) 
		group by  lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
			,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in,job.name,pk.name;

	

		--insert to calculate for machineSeq
		INSERT INTO #Result_WIP_ALL
		SELECT distinct lots.lot_no , lots.JobName ,lots.FTDevice ,'' as rack_address,'' as rack_name,lots.MCName as MachineName,1 as Seq_no,lots.pkg ,lots.ENDTIME,lots.STARTTIME 
		FROM #getLotInMC_TEST as lots where lot_no COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN (select lot_no from DBxDW.dbo.[scheduler_temp_seq_tp] ) 

		INSERT INTO DBxDW.dbo.[scheduler_temp_seq_tp]
		SELECT distinct lots.lot_no , lots.JobName ,lots.FTDevice ,'' as rack_address,'' as rack_name,lots.MCName as MachineName,1 as Seq_no,lots.pkg ,lots.ENDTIME,lots.STARTTIME 
		FROM #getLotInMC_TEST as lots where lot_no COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN (select lot_no from DBxDW.dbo.[scheduler_temp_seq_tp] ) 


		UPDATE [DBx].[dbo].[scheduler_tp_qa_mc_setup]
		SET pkgname = TRIM(RunningLot.pkg) , devicename = TRIM(RunningLot.DeviceName)
		FROM (select *,COUNT(*) OVER (PARTITION BY DeviceName) as Dublicate_MC  from #getLotInMC_TEST) AS RunningLot
		WHERE [DBx].[dbo].[scheduler_tp_qa_mc_setup].mcname = RunningLot.MCName and Dublicate_MC = 1; -- Must update mc_table first, if not previous device will jump to next lot. 

		SELECT * INTO #scheduler_tp_qa_mc_setup_TEST FROM [DBx].[dbo].[scheduler_tp_qa_mc_setup]


---------------------------------------------------------------------------------------------------------------------------------------------

--------------FIND WIP TP ONLY FOR GROUPING DEVICE AND MACHINE TOGETHER----------------------------------------------------------------------
			
		SELECT DISTINCT  --Lock Machine Next Lots
		lots.lot_no,Job.name as flow,ft_name as FTDeivce,
		ISNULL(Rack.address,'Setup') as rack_address, --Rack.address
		ISNULL(Rack.name,(select distinct rack.name from DBx.dbo.rcs_records inner join
		(select lot_no,MAX(update_at_in)as Latest_date from DBx.dbo.rcs_records group by  lot_no)as RCS on RCS.lot_no = lots.lot_no WHERE  rcs_records.lot_no= lots.lot_no ))
		as rack_name --Rack.name
		,Machine_table.name as machine_name,
		2 as Seq_no,Package.name as package_name,NULL as lot_end,NULL as lot_start,deivce.name as deviceName,Machine_table.id as mcid INTO #MachineLockSeq
			FROM [APCSProDB].[trans].[machine_states] as machine_state 
			inner join APCSProDB.mc.machines as Machine_table  on machine_id = Machine_table.id
			inner join APCSProDB.trans.lots as lots  on lots.id = next_lot_id
			inner join APCSProDB.method.packages as Package  on lots.act_package_id = Package.id
			inner join APCSProDB.method.device_names as deivce  on lots.act_device_name_id = deivce.id
			left join APCSProDB.trans.locations as Rack  on lots.location_id = Rack.id
			------------------------------------------------------------------------------------------------------------
			---- add status rack 2023-03-09
			------------------------------------------------------------------------------------------------------------
			left join [DBx].[dbo].[rcs_current_locations] as [current_locations] with (NOLOCK) on [Rack].[id] = [current_locations].[location_id]
				and [lots].[id] = [current_locations].[lot_id]
			------------------------------------------------------------------------------------------------------------
			inner join APCSProDB.method.device_flows as flow on lots.device_slip_id = flow.device_slip_id and lots.step_no = flow.step_no
			inner join APCSProDB.method.jobs as Job  on lots.act_job_id = job.id
			where lots.act_job_id  in (222,236,289,231,397,401,409,428) 
			and ((lots.process_state in (0,100) and lots.location_id is not null) or (lots.process_state in (1,101)))
			and lots.wip_state = 20 and lot_no NOT IN (select lot_no from #getLotInMC_TEST ) and Machine_table.name LIKE '%TP%'
			------------------------------------------------------------------------------------------------------------
			---- add status rack 2023-03-09
			------------------------------------------------------------------------------------------------------------
			and [current_locations].[status] = 1
			------------------------------------------------------------------------------------------------------------
				-- and lots.location_id IS NOT NULL 


			
		 --Insert to Result
		  INSERT INTO DBxDW.dbo.[scheduler_temp_seq_tp]
		  SELECT distinct lot_no,flow,FTDeivce,rack_address,rack_name,machine_name,Seq_no,package_name,lot_end,lot_start 
		  FROM #MachineLockSeq where lot_no COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN (select lot_no from #Result_WIP_ALL) 

		  --Add to calculate for machineSeq
		  INSERT INTO #Result_WIP_ALL
		  SELECT distinct lot_no,flow,FTDeivce,rack_address,rack_name,machine_name,Seq_no,package_name,lot_end,lot_start 
		  FROM #MachineLockSeq where lot_no COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN (select lot_no from #Result_WIP_ALL) 



		  --check if machine already have nextlotSet
		  SELECT distinct lot_no,flow,FTDeivce,rack_address,rack_name,machine_name,Seq_no,package_name,lot_end,lot_start INTO #machine_alreadySetNextLot
		  FROM #MachineLockSeq 
	

			--Find seq MC And Make group of Machine
			select *,RANK() OVER(PARTITION BY pkgname ORDER BY mcid ASC) as Seq_MC
			,DENSE_RANK() OVER(ORDER BY pkgname DESC) as MC_group
			INTO #MC_Seq from #scheduler_tp_qa_mc_setup_TEST WHERE pkgname is not null and isOnline = 1 order by pkgname;


CREATE TABLE #WipBeforeTP 
(
	Process nvarchar(30),Package char(30),Device char(30),alias_package_group_id int
	, Is_GDIC int,wip_state tinyint,quality_state tinyint,FT_lots int
);


			INSERT INTO #WipBeforeTP  select * , COUNT(Device) as FT_lots
			from
			(
			select Process.name AS Process,Pkg.name AS Package,
			device.name AS Device
			,device.alias_package_group_id
			,case when device.alias_package_group_id != 33 THEN 
				case when Pkg.name = 'SSOP-B20W' THEN
					CASE WHEN device.rank = 'M' THEN 1
						WHEN device.rank = 'BZM' THEN 1
						WHEN device.rank = 'C' THEN 1
						WHEN device.rank = 'BZC' THEN 1
						WHEN device.rank = 'H' THEN 1
					ELSE 0 END
				ELSE 0 END
			 ELSE 1 END AS Is_GDIC 
			,wip_state
			,quality_state
			from APCSProDB.trans.lots
				inner join APCSProDB.method.jobs AS Jobs on lots.act_job_id = Jobs.id 
				inner join APCSProDB.method.processes AS Process on lots.act_process_id = Process.id and Jobs.process_id = lots.act_process_id
				inner join APCSProDB.method.packages AS Pkg on lots.act_package_id = Pkg.id
				inner Join [APCSProDB] .[method].device_names AS device on lots.act_device_name_id = device.id
			WHERE lots.wip_state = 20
			and Pkg.name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) 
			and Process.name = 'FT'
			and lots.quality_state = 0
			) as A Group by A.Process,A.Package,A.Device,A.Is_GDIC,A.alias_package_group_id,A.wip_state,A.quality_state ;


 

			--INSERT INTO #TempMachineTable SELECT *,RANK() OVER(PARTITION BY PkgName ORDER BY machine_id ASC) as Seq_MC 
			--FROM
			--(
			--SELECT DISTINCT mcname
			--	  ,[machine_id]
			--	  ,pkg.name as PkgName
			--	  ,[package_id]
			--	  ,ISNULL(is_gdic,0) as is_gdicMC
			--  FROM [DBx].[dbo].[tp_mc_matching_packages]
			--  inner join [DBx].[dbo].[scheduler_tp_qa_mc_setup] as setupMC on machine_id = setupMC.mcid
			--  inner join APCSProDB.method.packages as pkg on package_id = pkg.id
			--  where mcid is NOT NULL AND line IS NOT NULL and isOnline = 1
			--) AS A;


			 --old 8/30/2021 1st queue is 1st mcid





			--THIS FUNCTION INSERT FIND LOTS, THAT IS THE SAME DEVICE AS LOCK RUNNING (NEXT LOT) *WARNING THIS LOTS RESULT OF THIS FUNCTION DON'T KNOW WHICH MACHINE  
		SELECT DISTINCT lot_no,DeviceName,pkg_name,job_name,rack_name,rack_address,delay_kpcs,lots_in_process,Is_GDIC,FT_lots,device_type,FTDevice,Total_lots_DeviceLevel,Class,priority_num,
		DENSE_RANK() OVER(PARTITION BY pkg_name ORDER BY lots_in_process DESC,FT_lots DESC,delay_kpcs ASC,Class ASC) as seq_of_groupSamePkg
		INTO #sameAsLockMachine
		FROM 
		(
		SELECT distinct lot_no,DeviceName,pkg_name,job_name,rack_name,rack_address,delay_kpcs,lots_in_process,Is_GDIC,FT_lots,device_type,FTDevice,priority_num
		,COUNT(lot_no) over (PARTITION BY pkg_name,Is_GDIC,DeviceName) as Total_lots_DeviceLevel,
		Class = CASE device_type
		WHEN 0 THEN 'B' --MASTER
		WHEN 6 THEN 'C' --D_LOTS
		WHEN 1 THEN 'D'
		WHEN 100 THEN 'E'
		WHEN 2 THEN 'F'
		WHEN 7 THEN 'G'
		WHEN 8 THEN 'H'
		WHEN 9 THEN 'I'
		ELSE  'NaN'
		END 
		FROM
		(
			SELECT distinct lot_no,DeviceName,pkg_name,job_name,rack_name,rack_address,delay_kpcs,lots_in_process,Is_GDIC,FT_lots,device_type,FTDevice,priority_num
			FROM
			(
				SELECT DISTINCT mc_name as MCName,temp.lot_no,device_name as DeviceName, Lock_table.FTDeivce as FTDevice,pkg_name ,job_name,'' as NextJob,kpcs,qty_production
					,temp.rack_address,temp.rack_name,SUMMARY as delay_kpcs,CountLots as lots_in_process,
					Is_GDIC = 
					CASE 
						WHEN SumData.Is_GDIC >= 1 THEN 1
						ELSE 0
					END,
					ISNULL(LotFTBeforeTP.FT_lots,0) as FT_lots,versions.device_type,
					DENSE_RANK() OVER(ORDER BY pkg_name,Device_Name DESC) as index_helper,
					Trans.priority as priority_num
				FROM [DBx].[dbo].[scheduler_tp_qa_wip] as temp
				inner JOIN APCSProDB.method.device_names as devicename on  temp.device_name = devicename.name
				inner JOIN APCSProDB.trans.lots as Trans on temp.lot_no = Trans.lot_no
				inner JOIN #Get_SumData_TEST as SumData on temp.pkg_name = SumData.PackageName and temp.device_name = SumData.DeviceName and temp.job_name = SumData.Sum_Job_Name
				LEFT JOIN #WipBeforeTP as LotFTBeforeTP on LotFTBeforeTP.Device = temp.device_name and LotFTBeforeTP.Package = temp.pkg_name
				inner join #MachineLockSeq as Lock_table on 
				TRIM(temp.pkg_name) COLLATE SQL_Latin1_General_CP1_CI_AS = TRIM(Lock_table.package_name) COLLATE SQL_Latin1_General_CP1_CI_AS 
				and TRIM(temp.device_name) COLLATE SQL_Latin1_General_CP1_CI_AS = TRIM(Lock_table.deviceName) COLLATE SQL_Latin1_General_CP1_CI_AS ---Joining Point sameAsMachine
				and TRIM(temp.job_name) COLLATE SQL_Latin1_General_CP1_CI_AS = TRIM(Lock_table.flow) COLLATE SQL_Latin1_General_CP1_CI_AS
				and TRIM(Lock_table.package_name) COLLATE SQL_Latin1_General_CP1_CI_AS IN  (select packages.name from [DBx].[dbo].[tp_mc_matching_packages] inner join APCSProDB.method.packages on packages.id = tp_mc_matching_packages.package_id 
				where tp_mc_matching_packages.machine_id =  Lock_table.mcid  )
				inner JOIN APCSProDB.method.device_slips as dvSlip on trans.device_slip_id = dvSlip.device_slip_id
				inner join APCSProDB.method.device_versions as versions on dvSlip.device_id = versions.device_id
				inner join #MC_Seq as IsOnlineMachine_table on IsOnlineMachine_table.mcname = Lock_table.machine_name --check lock is online, if not lot will be difference device type logic.
				WHERE job_id in (222,231,236,289,397,401,409,428) 
				and pkg_name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
				and trans.wip_state = 20 and (temp.rack_name LIKE '%TP%' or temp.rack_name LIKE '%QA%')
				--and pkg_name IN (select pkgname from #scheduler_tp_qa_mc_setup_TEST)
				--and temp.lot_no NOT IN (select serial_no from APCSProDB.trans.surpluses)
				and Trans.lot_no NOT IN (select A.lot_no from #getLotInMC_TEST as A)
				and Trans.lot_no NOT IN (select lot_no from #MachineLockSeq)
				and Trans.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN (select lot_no from #Result_WIP_ALL)
				and trans.wip_state NOT IN (70,100)
				and Lock_table.machine_name NOT IN (select mcname from #scheduler_tp_qa_mc_setup_TEST where isOnline = 0)
			) AS A
		) AS B where lot_no NOT In (select lot_no from #MachineLockSeq)
		) AS C 





CREATE TABLE #DeviceSameAsMc
(
lot_no varchar(30),DeviceName varchar(30),pkg_name varchar(30),job_name varchar(30),rack_name NVARCHAR(30),rack_address NVARCHAR(30),
delay_kpcs int,lots_in_process int,Is_GDIC int,FT_lots bigint,device_type tinyint,FTDevice varchar(30),Total_lots_DeviceLevel int,priority_num int,Class varchar(5),seq_of_groupSamePkg bigint
);


		INSERT INTO #DeviceSameAsMc SELECT DISTINCT lot_no,DeviceName,pkg_name,job_name,rack_name,rack_address,delay_kpcs,lots_in_process,Is_GDIC,FT_lots,device_type,FTDevice,Total_lots_DeviceLevel,priority_num,Class,
		DENSE_RANK() OVER(PARTITION BY pkg_name ORDER BY lots_in_process DESC,FT_lots DESC,delay_kpcs ASC,Class ASC) as seq_of_groupSamePkg
		FROM 
		(
		SELECT lot_no,DeviceName,pkg_name,job_name,rack_name,rack_address,delay_kpcs,lots_in_process,Is_GDIC,FT_lots,device_type,FTDevice
		,COUNT(lot_no) over (PARTITION BY pkg_name,Is_GDIC,DeviceName) as Total_lots_DeviceLevel,priority_num,
		Class = CASE device_type
		WHEN 0 THEN 'B' --MASTER
		WHEN 6 THEN 'C' --D_LOTS
		WHEN 1 THEN 'D'
		WHEN 100 THEN 'E'
		WHEN 2 THEN 'F'
		WHEN 7 THEN 'G'
		WHEN 8 THEN 'H'
		WHEN 9 THEN 'I'
		ELSE  'NaN'
		END 
		FROM
		(
			SELECT distinct lot_no,DeviceName,pkg_name,job_name,rack_name,rack_address,delay_kpcs,lots_in_process,Is_GDIC,FT_lots,device_type,FTDevice,priority_num
			FROM
			(
				SELECT DISTINCT mc_name as MCName,temp.lot_no,device_name as DeviceName,devicename.ft_name as FTDevice,pkg_name ,job_name,'' as NextJob,kpcs,qty_production
					,temp.rack_address,temp.rack_name,SUMMARY as delay_kpcs,CountLots as lots_in_process,
					Is_GDIC = 
					CASE 
						WHEN SumData.Is_GDIC >= 1 THEN 1
						ELSE 0
					END,
					ISNULL(LotFTBeforeTP.FT_lots,0) as FT_lots,versions.device_type,
					DENSE_RANK() OVER(ORDER BY pkg_name,Device_Name DESC) as index_helper,
					Trans.priority as priority_num
				FROM [DBx].[dbo].[scheduler_tp_qa_wip] as temp 
				inner JOIN APCSProDB.method.device_names as devicename on  temp.device_name = devicename.name
				inner JOIN APCSProDB.trans.lots as Trans on temp.lot_no = Trans.lot_no
				inner JOIN #Get_SumData_TEST as SumData on temp.pkg_name = SumData.PackageName and temp.device_name = SumData.DeviceName and temp.job_name = SumData.Sum_Job_Name
				LEFT JOIN #WipBeforeTP as LotFTBeforeTP on LotFTBeforeTP.Device = temp.device_name and LotFTBeforeTP.Package = temp.pkg_name
				inner join #MC_Seq as MC_table on TRIM(temp.pkg_name) = TRIM(MC_table.pkgname) and TRIM(temp.device_name) = TRIM(MC_table.devicename)
				and TRIM(MC_table.pkgname) COLLATE SQL_Latin1_General_CP1_CI_AS IN  (select pkgname from [DBx].[dbo].[tp_mc_matching_packages] inner join APCSProDB.method.packages on packages.id = tp_mc_matching_packages.package_id 
				where tp_mc_matching_packages.machine_id =  MC_table.mcid  )
				inner JOIN APCSProDB.method.device_slips as slips on trans.device_slip_id = slips.device_slip_id 
				inner join APCSProDB.method.device_versions as versions  on slips.device_id = versions.device_id
				WHERE job_id in (222,231,236,289,397,401,409,428) 
				and pkg_name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
				and trans.wip_state = 20 and (rack_name LIKE '%TP%' or rack_name LIKE '%QA%')
				and pkg_name IN (select pkgname from #scheduler_tp_qa_mc_setup_TEST)
				--and temp.lot_no NOT IN (select serial_no from APCSProDB.trans.surpluses)
				and temp.lot_no NOT IN (select Lock.lot_no from #MachineLockSeq AS Lock)
				and temp.lot_no NOT IN (select InMC.lot_no from #getLotInMC_TEST as InMC)
				and temp.lot_no NOT IN (select lot_no from #sameAsLockMachine)
				and Trans.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN (select lot_no from #Result_WIP_ALL)
				and Trans.location_id is not null
				and trans.wip_state NOT IN (70,100)
			) AS A
		) AS B 
		) AS C


CREATE TABLE #NOTDeviceSame_Other
(
	lot_no varchar(30),DeviceName varchar(30),pkg_name varchar(30),job_name varchar(30),rack_name NVARCHAR(30),rack_address NVARCHAR(30),
	delay_kpcs int,lots_in_process int,Is_GDIC int,FT_lots int,device_type tinyint,FTDevice varchar(30),Total_lots_DeviceLevel int,priority_num int,priority_group int,Class varchar(5),seq_of_groupSamePkg int
);
		

		--Find Device with 70 Priorty number	
		SELECT DISTINCT devicename.name as deviceName,Trans.priority as priority_num INTO #Priority_DeviceName
		FROM [DBx].[dbo].[scheduler_tp_qa_wip] as temp
		inner JOIN APCSProDB.method.device_names as devicename on  temp.device_name =devicename.name
		inner JOIN APCSProDB.trans.lots as Trans on temp.lot_no = Trans.lot_no
		inner JOIN #Get_SumData_TEST as SumData on temp.pkg_name = SumData.PackageName and temp.device_name = SumData.DeviceName and temp.job_name = SumData.Sum_Job_Name
		LEFT JOIN #WipBeforeTP as LotFTBeforeTP on LotFTBeforeTP.Device = temp.device_name and LotFTBeforeTP.Package = temp.pkg_name
		inner JOIN APCSProDB.method.device_slips on trans.device_slip_id = device_slips.device_slip_id
		inner join APCSProDB.method.device_versions as versions on device_slips.device_id = versions.device_id
		WHERE job_id in (222,231,236,289,397,401,409,428) 
		and pkg_name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
		and trans.wip_state = 20 and (rack_name LIKE '%TP%' or rack_name LIKE '%QA%')
		and temp.lot_no NOT IN (select SameDeivce.lot_no from #DeviceSameAsMc as SameDeivce) 
		and temp.lot_no NOT IN (select A.lot_no from #getLotInMC_TEST as A)
		and temp.lot_no NOT IN (select lot_no from #MachineLockSeq)
		and temp.lot_no NOT IN (select lot_no from #sameAsLockMachine)
		and trans.wip_state NOT IN (70,100)
		and Trans.priority = 70



		INSERT INTO #NOTDeviceSame_Other
		SELECT   lot_no,DeviceName,pkg_name,job_name,rack_name,rack_address,delay_kpcs,lots_in_process,Is_GDIC,FT_lots,device_type,FTDevice,Total_lots_DeviceLevel,priority_num,
		CASE WHEN applyPriorityGroup < priority_num THEN priority_num
			 ELSE applyPriorityGroup END AS applyPriorityGroup ,
		Class
		, --ISNULL((select max(seq_of_groupSamePkg) from #DeviceSameAsMc where pkg_name = d.pkg_name),0) +
		DENSE_RANK() OVER(PARTITION BY pkg_name ORDER BY applyPriorityGroup DESC,delay_kpcs ASC,lots_in_process DESC,FT_lots DESC,Class ASC,DeviceName ASC) as seq_of_groupSamePkg

		FROM 
		(
		SELECT *,Class  = CASE device_type
		WHEN 0 THEN 'B' ---MASTER
		WHEN 6 THEN 'C' ---D_lots
		WHEN 1 THEN 'D'
		WHEN 100 THEN 'E'
		WHEN 2 THEN 'F'
		WHEN 7 THEN 'G'
		WHEN 8 THEN 'H'
		WHEN 9 THEN 'I'
		ELSE  'NaN'
		END
		FROM
		(
		SELECT distinct lot_no,DeviceName,pkg_name,job_name,rack_name,rack_address,delay_kpcs,lots_in_process,Is_GDIC,FT_lots,device_type,FTDevice
			,COUNT(lot_no) over (PARTITION BY pkg_name,Is_GDIC,DeviceName) as Total_lots_DeviceLevel,priority_num,applyPriorityGroup
		FROM
		(
			SELECT distinct  *,
					DENSE_RANK() OVER(ORDER BY pkg_name,FTDevice DESC) as index_helper
			FROM
				(
					SELECT DISTINCT mc_name as MCName,temp.lot_no,device_name as DeviceName,devicename.ft_name as FTDevice,pkg_name ,job_name,'' as NextJob,kpcs,qty_production,
					temp.rack_address,rack_name,SUMMARY as delay_kpcs,CountLots as lots_in_process,
					Is_GDIC = 
					CASE 
						WHEN SumData.Is_GDIC >= 1 THEN 1
						ELSE 0
					END
					,ISNULL(LotFTBeforeTP.FT_lots,0) as FT_lots,versions.device_type
					,Trans.priority as priority_num
					,ISNULL(#Priority_DeviceName.priority_num,50) as applyPriorityGroup
						FROM [DBx].[dbo].[scheduler_tp_qa_wip] as temp
						inner JOIN APCSProDB.method.device_names as devicename on  temp.device_name =devicename.name
						inner JOIN APCSProDB.trans.lots as Trans on temp.lot_no = Trans.lot_no
						inner JOIN #Get_SumData_TEST as SumData on temp.pkg_name = SumData.PackageName and temp.device_name = SumData.DeviceName and temp.job_name = SumData.Sum_Job_Name
						LEFT JOIN #WipBeforeTP as LotFTBeforeTP on LotFTBeforeTP.Device = temp.device_name and LotFTBeforeTP.Package = temp.pkg_name
						inner JOIN APCSProDB.method.device_slips on trans.device_slip_id = device_slips.device_slip_id
						inner join APCSProDB.method.device_versions as versions on device_slips.device_id = versions.device_id
						left join #Priority_DeviceName on #Priority_DeviceName.deviceName = devicename.name AND #Priority_DeviceName.priority_num = 70
						WHERE job_id in (222,231,236,289,397,401,409,428) 
						and pkg_name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
						and trans.wip_state = 20 and (rack_name LIKE '%TP%' or rack_name LIKE '%QA%')
						--and pkg_name IN (select pkgname from #scheduler_tp_qa_mc_setup_TEST)
						--and temp.lot_no NOT IN (select serial_no from APCSProDB.trans.surpluses)
						and temp.lot_no NOT IN (select SameDeivce.lot_no from #DeviceSameAsMc as SameDeivce) 
						and temp.lot_no NOT IN (select A.lot_no from #getLotInMC_TEST as A)
						and temp.lot_no NOT IN (select lot_no from #MachineLockSeq)
						and temp.lot_no NOT IN (select lot_no from #sameAsLockMachine)
						and Trans.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN (select lot_no from #Result_WIP_ALL )
						and trans.wip_state NOT IN (70,100)
				) 
			AS A
		) 
		AS B  where lot_no NOT In (select lot_no from #MachineLockSeq)
		) 
		AS C
		)
		AS D;



CREATE TABLE #seqGroupMatchMC
(
	lot_no varchar(30),DeviceName varchar(30),pkg_name varchar(30),job_name varchar(30),rack_name NVARCHAR(30),rack_address NVARCHAR(30),
	delay_kpcs int,lots_in_process int,Is_GDIC int,FT_lots int,device_type tinyint,FTDevice varchar(30),Total_lots_DeviceLevel int,priority_num int,applyPriorityGroup int,Class varchar(5),seq_of_groupSamePkg int
);



		--UNION BEFORE ORDER
		INSERT INTO #seqGroupMatchMC 
		select *  
		FROM
		(
		select distinct * from #NOTDeviceSame_Other 
		WHERE DeviceName NOT IN (select DeviceName from #DeviceSameAsMc)
		--AND DeviceName NOT IN (select DeviceName from #sameAsLockMachine)
		) as A order by seq_of_groupSamePkg ASC,lots_in_process DESC,FT_lots DESC,delay_kpcs,Class ASC;


	
----------------------------------------------------------------------------------------------

		SELECT DISTINCT lot_no,flow,FTDevice,rack_address,rack_name,machine_name,
		Seq_no + ISNULL((select DISTINCT 1 from #MachineLockSeq where #MachineLockSeq.machine_name = B.machine_name AND B.dublicate_machineCanRun = 1),0) as Seq_no

		,package_name,lot_end,lot_start,priority_num , 80 as applyPriorityGroup  INTO #LotsOrder_sameLockDevice
		FROM
		(
		SELECT *, ROW_NUMBER() over(PARTITION BY lot_no,package_name,FTDevice,Seq_no order by machine_name DESC) as dublicate_machineCanRun
		FROM
		(
		SELECT DISTINCT sameAsLockMachine.lot_no,job_name as flow,sameAsLockMachine.FTDevice as FTDevice,sameAsLockMachine.rack_address,sameAsLockMachine.rack_name,Lock_lot.machine_name as machine_name
		,

		1 
		+ ROW_NUMBER() over(PARTITION BY Lock_lot.machine_name order by lots_in_process DESC,FT_lots DESC,delay_kpcs ASC,class ASC,sameAsLockMachine.lot_no ASC) as Seq_no
		
		,pkg_name as package_name, NULL as lot_end ,NUll as lot_start , priority_num
		FROM #sameAsLockMachine as sameAsLockMachine
		inner join #MachineLockSeq as Lock_lot on Lock_lot.package_name = pkg_name and Lock_lot.FTDeivce = sameAsLockMachine.FTDevice
		inner join [DBx].[dbo].[scheduler_tp_qa_mc_setup] as Mc_table on Lock_lot.machine_name = Mc_table.mcname
		where sameAsLockMachine.lot_no NOT IN (select Lock.lot_no from #MachineLockSeq as Lock) and sameAsLockMachine.lot_no NOT IN (select inMc.lot_no from #getLotInMC_TEST as inMc) 
		AND Mc_table.isOnline = 1

		) as A
		) as B WHERE dublicate_machineCanRun = 1 --THIS  WHERE WILL ONLY CHOOSE FIRST MACHINE IF DUBLICATE PACKAGE AND DEVICE.
		
		
		
		SELECT * INTO #ResultSameNextLot FROM #LotsOrder_sameLockDevice  where lot_no NOT IN (select lot_no from #MachineLockSeq)
		and lot_no COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN (select lot_no from #Result_WIP_ALL )



-------------------------------------------------------------------------------------------------------

		SELECT DISTINCT lot_no,flow,FTDevice,rack_address,rack_name,machine_name,

		Seq_no + ISNULL((select DISTINCT 1 from #MachineLockSeq where #MachineLockSeq.machine_name = B.machine_name OR (#MachineLockSeq.package_name = B.package_name 
		and #MachineLockSeq.FTDeivce = B.FTDevice)),0) 
		+ ISNULL((select COUNT(machine_name) from #LotsOrder_sameLockDevice where #LotsOrder_sameLockDevice.machine_name = B.machine_name),0)
		as Seq_no


		,package_name,lot_end,lot_start,priority_num , 80 as applyPriorityGroup INTO #LotsOrder_sameDeviceAsMc
		FROM
		(
		SELECT *, ROW_NUMBER() over(PARTITION BY lot_no,package_name,FTDevice,Seq_no order by machine_name DESC) as dublicate_machineCanRun
		FROM
		(
		SELECT DISTINCT lot_no,job_name as flow,DeviceSameAsMC.FTDevice as FTDevice,rack_address,rack_name,Machine_table.mcname as machine_name
		,

		1 
		+ ROW_NUMBER() over(PARTITION BY Machine_table.mcname order by lots_in_process DESC,FT_lots DESC,delay_kpcs ASC,class ASC,lot_no ASC) as Seq_no
		
		,pkg_name as package_name, NULL as lot_end ,NUll as lot_start ,priority_num
		FROM #DeviceSameAsMc as DeviceSameAsMC
		inner join #MC_Seq as Machine_table on Machine_table.pkgname = pkg_name and Machine_table.devicename = DeviceSameAsMC.DeviceName
		where lot_no NOT IN (select Lock.lot_no from #MachineLockSeq as Lock) and lot_no NOT IN (select inMc.lot_no from #getLotInMC_TEST as inMc) 
		) as A
		) as B WHERE dublicate_machineCanRun = 1 --THIS  WHERE WILL ONLY CHOOSE FIRST MACHINE IF DUBLICATE PACKAGE AND DEVICE.
		



		
		SELECT distinct * INTO #ResultSameMachine FROM #LotsOrder_sameDeviceAsMc 
		where lot_no COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN (select lot_no from #Result_WIP_ALL )
		and lot_no NOT IN (select lot_no from #MachineLockSeq) 
		and lot_no NOT IN (select lot_no from #sameAsLockMachine) 
		order by machine_name,lot_no,Seq_no

		--Case To order Which machine get lot first when already have SameNextlot, Nextlot, Running 
		INSERT INTO #Result_WIP_ALL
		select * from  
		(
		Select lot_no,flow,FTDevice,rack_address,rack_name,machine_name,Seq_no,package_name,lot_end,lot_start from #ResultSameMachine
		UNION
		Select lot_no,flow,FTDevice,rack_address,rack_name,machine_name,Seq_no,package_name,lot_end,lot_start from #ResultSameNextLot
		) as A


		-----------------------------------------------------------------------------


		-- need to find available machine first using DBxDW.dbo.[scheduler_temp_seq_tp] table (low lots is 1st queue)
		-- why it have to be here, DBxDW.dbo.[scheduler_temp_seq_tp] going to be deleted every cycle.
		-- this using only difference device logic.

		SELECT *,RANK() OVER(PARTITION BY PkgName ORDER BY wait_lot_max,machine_id ASC) as Seq_MC INTO #TempMachineTable
		FROM
		(
		SELECT DISTINCT mcname
						,[machine_id]
						,TRIM(pkg.name) as PkgName
						,[package_id]
						,ISNULL(is_gdic,0) as is_gdicMC
						,ISNULL(wait_lot,1) as wait_lot_max
					FROM [DBx].[dbo].[tp_mc_matching_packages]
					inner join [DBx].[dbo].[scheduler_tp_qa_mc_setup] as setupMC on machine_id = setupMC.mcid
					inner join APCSProDB.method.packages as pkg on package_id = pkg.id
					left join (select machine_name, MAX(seq_no) as wait_lot FROM #Result_WIP_ALL group by #Result_WIP_ALL.machine_name) as lot_wait 
					on lot_wait.machine_name = setupMC.mcname COLLATE SQL_Latin1_General_CP1_CI_AS 
					where mcid is NOT NULL AND line IS NOT NULL and isOnline = 1
				) as A order by PkgName


		---------------------------------------------------------------------------------------
		
CREATE TABLE #Result_WIP
(
lot_no varchar(30),flow varchar(30),FTDevice varchar(30),rack_address NVARCHAR(30),rack_name NVARCHAR(30),machine_name VARCHAR(30),
seq_no bigint, package_name varchar(30),lot_end datetime,lot_start datetime,priority_num int,applyPriorityGroup int
);



		INSERT INTO #Result_WIP 
		SELECT
		lot_no,job_name as flow,FTDevice,rack_address,rack_name,machine_name,
		CASE
			WHEN Lock = 1 --OR seq_no = (select seq_no from #MachineLockSeq where #MachineLockSeq.FTDeivce = Result.FTDevice)
				THEN seq_no + 1
			WHEN Lock = 0 
				THEN seq_no
		END as seq_no,
		pkg_name as package_name,lot_end,lot_start,priority_num,applyPriorityGroup
		FROM
		(
		SELECT *
		,1 
		+ ISNULL((select COUNT(machine_name) from #LotsOrder_sameDeviceAsMc where #LotsOrder_sameDeviceAsMc.machine_name = E.machine_name),0)
		+ ROW_NUMBER() over(PARTITION BY machine_name order by applyPriorityGroup DESC,priority_num DESC,Group_lot_seq_onMC ASC,delay_kpcs ASC,lots_in_process DESC,FT_lots DESC,class ASC,lot_no ASC)
		+ ISNULL((select COUNT(machine_name) from #LotsOrder_sameLockDevice where #LotsOrder_sameLockDevice.machine_name = E.machine_name),0)
		as seq_no,
			   CASE 
					WHEN Exists (select machine_name from #MachineLockSeq where machine_name = E.machine_name)
						THEN 1
					WHEN NOT Exists (select machine_name from #MachineLockSeq where machine_name = E.machine_name)
						THEN 0
				END as Lock
		FROM
		(
		SELECT lot_no,job_name,D.FTDevice,rack_address,rack_name,MC_TABLE_TEMP.mcname as machine_name,seq_of_groupSamePkg,Group_lot_seq_onMC,
		D.pkg_name,NULL as lot_end,NULL as lot_start
		,Class,delay_kpcs,lots_in_process,FT_lots,DeviceName as Device_Fullname,priority_num,applyPriorityGroup
		FROM
		(
		SELECT *,
		CASE WHEN seq_of_groupSamePkg <= Max_Mc 
			 THEN seq_of_groupSamePkg ELSE
		   ---------Give Seq_mc for lot_seq < machine-------------
			 CASE seq_of_groupSamePkg % Max_Mc WHEN 0 THEN Max_Mc 
										 ELSE seq_of_groupSamePkg % Max_Mc END
		   --------Case When lot > mc, mod lot by Max_mc if equal 0 = last machine.
										 END AS Index_point_mc,
		CASE 
			WHEN seq_of_groupSamePkg <= Max_Mc
				THEN 1 
			WHEN (seq_of_groupSamePkg % Max_Mc) <> 0
				THEN  convert(int,seq_of_groupSamePkg/Max_Mc) + 1
			WHEN (seq_of_groupSamePkg % Max_Mc) = 0
				THEN  convert(int,seq_of_groupSamePkg/Max_Mc)
			END AS Group_lot_seq_onMC
		FROM
		(
		select *, (SELECT DISTINCT MAX(a.Seq_MC) FROM #TempMachineTable AS A WHERE B.pkg_name = A.pkgname and B.Is_GDIC <= A.is_gdicMC ) AS Max_Mc 
		------- Find Max machine for lot by device ----------
		from #seqGroupMatchMC 
		AS B
		) 
		AS C WHERE Max_Mc IS NOT NULL AND lot_no NOT IN (select lot_no from #MachineLockSeq)
		)
		AS D INNER JOIN #TempMachineTable AS MC_TABLE_TEMP ON D.pkg_name = MC_TABLE_TEMP.pkgname AND D.Index_point_mc = MC_TABLE_TEMP.seq_MC
		) 
		AS E  
		)
		AS Result where Result.Device_Fullname NOT IN (select MC_table.devicename from #MC_Seq as MC_table where devicename IS NOT NULL)

		--Find Machine With immediate work.
		select distinct machine_name INTO #PriorMachine from #Result_WIP where #Result_WIP.priority_num = 90
		
		--Mix SameNextLot and SameDeviceMachine Lot together
		SELECT * INTO #NextLotOnNormalMachine FROM 
		(
		SELECT * FROM #ResultSameMachine
		UNION
		SELECT * FROM #ResultSameNextLot
		) as MixResult where machine_name not in (select * from #PriorMachine) OR priority_num = 90

		-- RE:ORDER 90 70 50 in individual Machine
		INSERT INTO DBxDW.dbo.[scheduler_temp_seq_tp]
		SELECT lot_no,flow,FTDevice,rack_address,rack_name,machine_name 
		,1 + ISNULL((select COUNT(machine_name) FROM #machine_alreadySetNextLot where Result.machine_name = #machine_alreadySetNextLot.machine_name),0  )  + ROW_NUMBER() OVER (PARTITION BY machine_name ORDER BY seq_no ASC)  as seq_no
		,package_name,lot_end,lot_start
		FROM (
		SELECT * FROM
		(
		SELECT * FROM #Result_WIP
		UNION 
		SELECT * FROM #NextLotOnNormalMachine 
		) as AutoQueue 
		) as Result --WHERE Result.machine_name <> 'TP-TP-62' 
		ORDER BY machine_name,Result.seq_no


		--DBxDW.dbo.[scheduler_temp_seq_tp]


	




				

		
	
		

	DROP TABLE #Result_WIP_ALL
	DROP TABLE IF EXISTS #tempCalculate_TEST
	DROP TABLE IF EXISTS #TPACC_TEST
	DROP TABLE IF EXISTS #Get_SumData_TEST
	DROP TABLE IF EXISTS #getLotInMC_TEST
	DROP TABLE IF EXISTS #scheduler_tp_qa_mc_setup_TEST
	DROP TABLE IF EXISTS #MC_Seq
	DROP TABLE IF EXISTS #DeviceSameAsMc 
	DROP TABLE IF EXISTS #WipBeforeTP
	DROP TABLE IF EXISTS #NOTDeviceSame_Other
	DROP TABLE IF EXISTS #seqGroupMatchMC
	DROP TABLE IF EXISTS #Result_WIP
	DROP TABLE IF EXISTS #TempMachineTable
	DROP TABLE IF EXISTS #scheduler_temp_seq_tp_TEST
	DROP TABLE IF EXISTS #LotsOrder_sameDeviceAsMc
	DROP TABLE IF EXISTS #MachineLockSeq
	DROP TABLE IF EXISTS #LotsOrder_sameLockDevice
	DROP TABLE IF EXISTS #sameAsLockMachine
	COMMIT;
END TRY
BEGIN CATCH
	PRINT '---> Error <----' +  ERROR_MESSAGE() + '---> Error <----'; 
	ROLLBACK;
END CATCH

END




--SELECT DISTINCT lot_no,flow,FTDevice,rack_address,rack_name,machine_name,
--		Seq_no + ISNULL((select 1 from #MachineLockSeq where #MachineLockSeq.machine_name = B.machine_name OR (#MachineLockSeq.package_name = B.package_name 
--		and #MachineLockSeq.FTDeivce = B.FTDevice)),0) as Seq_no

--		,package_name,lot_end,lot_start INTO #LotsOrder_sameLockDevice
--		FROM
--		(
--		SELECT *, ROW_NUMBER() over(PARTITION BY lot_no,package_name,FTDevice,Seq_no order by machine_name DESC) as dublicate_machineCanRun
--		FROM
--		(
--		SELECT DISTINCT sameAsLockMachine.lot_no,job_name as flow,sameAsLockMachine.FTDevice as FTDevice,sameAsLockMachine.rack_address,sameAsLockMachine.rack_name,Lock_lot.machine_name as machine_name
--		,

--		1 
--		+ ROW_NUMBER() over(PARTITION BY Lock_lot.machine_name order by lots_in_process DESC,FT_lots DESC,delay_kpcs ASC,class ASC,sameAsLockMachine.lot_no ASC) as Seq_no
		
--		,pkg_name as package_name, NULL as lot_end ,NUll as lot_start 
--		FROM #sameAsLockMachine as sameAsLockMachine
--		inner join #MachineLockSeq as Lock_lot on Lock_lot.package_name = pkg_name and Lock_lot.FTDeivce = sameAsLockMachine.FTDevice
--		where sameAsLockMachine.lot_no NOT IN (select Lock.lot_no from #MachineLockSeq as Lock) and sameAsLockMachine.lot_no NOT IN (select inMc.lot_no from #getLotInMC_TEST as inMc) 
--		) as A
--		) as B WHERE dublicate_machineCanRun = 1 --THIS  WHERE WILL ONLY CHOOSE FIRST MACHINE IF DUBLICATE PACKAGE AND DEVICE.
		
		
--		INSERT INTO DBxDW.dbo.[scheduler_temp_seq_tp]
--		SELECT * FROM #LotsOrder_sameLockDevice where lot_no NOT IN (select lot_no from #MachineLockSeq) -- old