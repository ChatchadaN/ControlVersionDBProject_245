-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_sequence_tp_nonegdic]
	-- Add the parameters for the stored procedure here
AS
BEGIN
----** add status rack 2023-03-09
DECLARE @PackageName varchar(MAX)
SET @PackageName = 'HTSSOP-B40'

--DECLARE @PKG_ID varchar(MAX)
--SET @PKG_ID = '5,33'


--SELECT * from STRING_SPLIT ( @PKG_ID , ',' )

----SET TP WIP TO DBX [scheduler_tp_qa_wip]----------
delete from [DBx].[dbo].[scheduler_tp_qa_wip] where pkg_id in (SELECT package_group_id FROM APCSProDB.method.packages WHERE name in ((SELECT * from STRING_SPLIT( @PackageName , ',' ))))

	INSERT INTO [DBx].[dbo].[scheduler_tp_qa_wip] ([mc_name] ,lot_no ,device_name ,pkg_name ,job_name ,kpcs ,qty_production ,state ,standare_time ,job_id ,update_at ,rack_address ,rack_name ,pkg_id)
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
		where lots.wip_state = 20 
		and [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) 
		and [APCSProDB].[trans].[lots].act_job_id in (231,236,289) 
		and [APCSProDB].[trans].[lots].is_special_flow = 0 
		and [APCSProDB].[trans].[lots].quality_state = 0 
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
			, case when APCSProDB.trans.lots.process_state = 2 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
			, APCSProDB.trans.lots.process_state AS [state]
			, device_flows.process_minutes as standard_time
			, lotspecial.job_id as job_Id 
			, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record where lot_record.lot_id = lots.id) as updated_at 
			, locations.address as rack_address
		 , locations.name as rack_name
		 , [APCSProDB].[method].[packages].package_group_id
		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		inner join APCSProDB.trans.special_flows as special on special.lot_id = [APCSProDB].[trans].[lots].id
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
		where lots.wip_state = 20 
		and [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))    
		and lotspecial.job_id in(231,236,289) 
		and [APCSProDB].[trans].[lots].is_special_flow = 1  
		and [APCSProDB].[trans].[lots].quality_state != 3
		------------------------------------------------------------------------------------------------------------
		---- add status rack 2023-03-09
		------------------------------------------------------------------------------------------------------------
		and [current_locations].[status] = 1
		------------------------------------------------------------------------------------------------------------

-------------------------------
----- SET TP Calculate----------
EXEC	[StoredProcedureDB].[dbo].[sp_set_scheduler_tp_qa_calculate]
--------------------------------
CREATE TABLE #tempCalculate
(
    PackageName varchar(30),DeviceName varchar(30),Job_Name Varchar(20),Job_ID int,SumLots int,SumKpcs int,State varchar(10),StandardTime float,SumHold int,
	AllLots int,SumQA int,PKG_ID int,TP_Rank varchar(10),Is_GDIC int
)
------- GET TP Calcilate -------
INSERT INTO #tempCalculate
EXEC	[StoredProcedureDB].[dbo].[sp_get_scheduler_tp_qa_calculate]

--SELECT * FROM #tempCalculate
--DROP TABLE #tempCalculate
--------------------------------
CREATE TABLE #DeviceAndPk
(
	RowIndex int,PackageName varchar(30),DeviceName varchar(30)
)

INSERT INTO #DeviceAndPk
SELECT ROW_NUMBER() OVER(ORDER BY PackageName ASC) , PackageName,DeviceName FROM #tempCalculate WHERE PackageName in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
---var devicename = lstTPQAacc.Where(x=> x.Group == 3).Select(p => new { p.DeviceName, p.PKGName }).Distinct().ToList();

----GET TP ACC TP-------------
CREATE TABLE #TPACC
(
	PackageName varchar(30),DeviceName varchar(30),INPUT int,[OUTPUT] int,SUMMARY int
)

DECLARE @ResultStart varchar(MAX) = CONVERT(DateTime,CONVERT(Varchar, YEAR(GETDATE())) +'-'+CONVERT(Varchar, MONTH(GETDATE()))+'-01 08:00')--CONVERT (date,  DATEADD(day, -9, GETDATE()))
DECLARE @ResultEND varchar(MAX) = (SELECT GETDATE())

DECLARE @PlanStart varchar(MAX) = DATEADD(DAY, -9, @ResultStart)
DECLARE @PlanEND varchar(MAX) = CONVERT(DateTime,CONVERT(Varchar, CONVERT(date, DATEADD(DAY, -9, GETDATE())))+' 08:00')

--SELECT @PlanStart as PST,@PlanEND as PE, @ResultStart as RST,@ResultEND as RE


INSERT INTO #TPACC
select result.name as pkgname, result.Devicename as devicename , input.Kpcs as input , result.Kpcs as [output], result.Kpcs-input.Kpcs as summary
	from(select pk.name, device.name as Devicename,SUM( lots.qty_in)  as Kpcs
			from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) 
			inner join [APCSProDB].trans.lots as lots with (NOLOCK) on lots.id = lot_record.lot_id
			inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lots.act_device_name_id = device.id 
			inner join APCSProDB.method.packages as PK with (NOLOCK) on PK.id = lots.act_package_id
		where lot_record.record_class = 2  and job_id in (231,236,289)  and PK.name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) --กำหนดแพ็คเก็ทกรุ๊ป
			and lot_record.recorded_at between @ResultStart and @ResultEND
		group by device.name ,pk.name) as result 

	inner join 

		(SELECT  device.name as Devicename,sum(lots.qty_in) as Kpcs
			FROM [APCSProDB].[trans].lots as lots with (NOLOCK) 
			inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lots.act_device_name_id = device.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = device.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].[trans].[days] as days with (NOLOCK) on days.id = lots.in_date_id
			where lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips with (NOLOCK)) 
				and days.date_value between @PlanStart  and @PlanEND
			group by device.name , device.ft_name) as input on input.Devicename = result.Devicename

	CREATE TABLE #SUMMARYData
(
	RowIndex int,PackageName varchar(30),DeviceName varchar(30),SUMMARY int,CountLots int
)

--SELECT DISTINCT * FROM #TPACC ORDER BY SUMMARY 
INSERT INTO #SUMMARYData
SELECT  ROW_NUMBER() OVER(ORDER BY Cal.PackageName ASC),Cal.PackageName,Cal.DeviceName
		
		,case when acc.SUMMARY is NULL THEN 0
			ELSE acc.SUMMARY END as SUMMARY
		,Cal.AllLots 
	FROM #tempCalculate as Cal
LEFT JOIN #TPACC as Acc on (Acc.PackageName = Cal.PackageName) AND (Acc.DeviceName = Cal.DeviceName)
WHERE Job_Name = 'TP' AND Cal.PackageName in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))

	CREATE TABLE #PKList--DeviceListAcc
(
	RowIndex int,PackageName varchar(30)
)
CREATE TABLE #tempPKList(PackageName varchar(30))

INSERT INTO #tempPKList
SELECT DISTINCT PackageName FROM #SUMMARYData --ORDER BY SUMMARY ASC,CountLots DESC 
--SELECT ROW_NUMBER() OVER(ORDER BY PackageName), * from STRING_SPLIT ( @PackageName , ',' )

INSERT INTO #PKList
SELECT ROW_NUMBER() OVER(ORDER BY PackageName),PackageName FROM #tempPKList

DROP TABLE #tempPKList

--SELECT * from #PKList 

DECLARE @loopAcc int = 1
WHILE @loopAcc <= (select MAX(RowIndex) from  #PKList)
			BEGIN
			IF  EXISTS	(SELECT TOP (1)  1 FROM #SUMMARYData WHERE PackageName = (Select PackageName From #PKList Where RowIndex = @loopAcc)
				ORDER BY SUMMARY ASC, CountLots DESC)
				BEGIN

				DECLARE @DeviceName Varchar(30) = (SELECT TOP 1  DeviceName FROM #SUMMARYData WHERE PackageName = (Select PackageName From #PKList Where RowIndex = @loopAcc)
												ORDER BY SUMMARY ASC, CountLots DESC)
				DECLARE @PK Varchar(30) = (Select PackageName From #PKList Where RowIndex = @loopAcc)
				DECLARE @PKG_ID int =(select package_group_id from APCSProDB.method.packages where name = @PK)
				
				--SELECT @DeviceName as dv,@PK as Pk, @PKG_ID as PKG_ID
					EXEC	[StoredProcedureDB].[dbo].[sp_set_scheduler_tp_qa_setup_mc]
					@Devicename = @DeviceName,
					@PKG = @PK,
					@IsGDIC = @PKG_ID
				END
			SET @loopAcc = @loopAcc+1
			END 

DROP TABLE #tempCalculate
DROP TABLE #DeviceAndPk
DROP TABLE #TPACC
DROP TABLE #SUMMARYData
DROP TABLE #PKList
-------------------------------

----------------------------------
DELETE FROM DBxDW.dbo.[scheduler_temp_seq_tp]
WHERE package_name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))

CREATE TABLE #tempSetupMc
(
    PackageName varchar(30),MCNo varchar(30), McId int,MC_Type Varchar(20),DeviceName varchar(30),Package_id int,TP_Rank varchar(10),LotEnd Datetime
)

	INSERT INTO #tempSetupMc
	SELECT pkgname,mcname,mcid,mctype,devicename,is_gdic,tp_rank
	,(select top 1 (SELECT DATEADD(MINUTE, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))), max(lot_record.recorded_at))) AS ENDTIME
			--, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))) as aaa
			from  [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
			  inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id
			  inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = lot.machine_id
			  inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
			  inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
			  where lot.act_job_id  in (231,236,289) and lot.process_state != 0  and lot.wip_state= 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 0
			  and mc.name = DBx.dbo.scheduler_tp_qa_mc_setup.mcname--[FTSetupReport].[MCNo]
			  group by lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
			  ,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in) as ENDLOT
	FROM DBx.dbo.scheduler_tp_qa_mc_setup
	WHERE is_gdic in ((SELECT package_group_id FROM APCSProDB.method.packages WHERE name in ((SELECT * from STRING_SPLIT ( @PackageName , ',' )))))
		
		--select * from #tempSetupMc
		--drop TABLE #tempSetupMc
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------
CREATE TABLE #tempTypeSetup
(
    DeivceName varchar(30)
)

	INSERT INTO #tempTypeSetup
	SELECT Distinct MCSetup.DeviceName
	FROM #tempSetupMc as MCSetup
	WHERE MCSetup.PackageName in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) 
	
----------------------------------------------------
--select '#tempTypeSetup complete'
------------------------------------------------------
CREATE TABLE #tempDeivceSet
(
    DeivceName varchar(30),RowIndex int
)

	insert into #tempDeivceSet
select *,ROW_NUMBER() OVER(ORDER BY settemp.DeivceName,settemp.DeivceName ASC) 
from  #tempTypeSetup as settemp
 
 --select * from #tempDeivceSet 
--select '#tempDeivceSet complete'
DECLARE @cnt INT = 1;

CREATE TABLE #tempWIPData
			(
			  RowIndex int, MCName varchar(11), lot_no varchar(10), DeviceName varchar(30), FTDeivceName varchar(20), PkgName varchar(15),JobName varchar(20),
			  NextJobName varchar(20), Kpcs int , qty_production float, ProcessState int, StandardTime int, JobID int, UpdatedAt datetime, 
			  RackAddress varchar(10), RackName varchar(15)
			)
CREATE TABLE #getWIPData
			(
			  MCName varchar(11), lot_no varchar(10), DeviceName varchar(30), FTDeivceName varchar(20), PkgName varchar(15),JobName varchar(20),
			  NextJobName varchar(20), Kpcs int , qty_production float, ProcessState int, StandardTime int, JobID int, UpdatedAt datetime, 
			  RackAddress varchar(10), RackName varchar(15)
			)

CREATE TABLE #tempMCSetDeivce
			(
				RowIndex int, MCName varchar(11),  DeviceName varchar(30), PkgName varchar(15),Lotend datetime
			)

CREATE TABLE #tempLotInMC
			(
				RowIndex int,DeviceName varchar(30),FTDeviceName varchar(30),LotNo varchar(10),MCName varchar(11),JobName Varchar(20), StartLot datetime,EndLot datetime 
				, Package varchar(30)
			)

CREATE TABLE #getLotInMC
			(
				DeviceName varchar(30),FTDeviceName varchar(30),LotNo varchar(10),MCName varchar(11),JobName Varchar(20), StartLot datetime,EndLot datetime 
				, Package varchar(30)
			)

--CREATE TABLE #tempMcTC
--			(
--			RowIndex int,MCName Varchar(30),Seq_No int,DeviceName_change varchar(30),DeviceName_Now varchar(30),JobName_Be Varchar(20), JobName_Af Varchar(20),PK_Name VarChar(30)
--			)
--			------------ type change new----------------------------------------
--				INSERT INTO #tempMcTC
--				SELECT  ROW_NUMBER() OVER(ORDER BY tcSetup.date_change ASC),
--					tcSetup.mc_no,tcSetup.sequence,tcSetup.device_change,tcSetup.device_now,tcSetup.flow_before,tcSetup.flow_after,pk.name
--				FROM DBx.dbo.scheduler_setup as tcSetup
--				INNER JOIN APCSProDB.method.device_names as dv on dv.name = tcSetup.device_change
--				INNER JOIN APCSProDB.method.packages as pk on pk.id = dv.package_id
--				WHERE tcSetup.date_change is not null and tcSetup.date_complete is NULL and tcSetup.device_change is not null and pk.name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))

--				DECLARE @loopTC int = 1

--				WHILE @loopTC <= (select MAX(rowIndex) from  #tempMcTC)
--				BEGIN
--				if not exists(SELECT * FROM [DBxDW].[dbo].[scheduler_temp] where lot_no collate SQL_Latin1_General_CP1_CI_AS =  (SELECT tc.MCName FROM #tempMcTC as tc where RowIndex = @loopTC) )
--					BEGIN
					
--						INSERT INTO [DBxDW].[dbo].[scheduler_temp]
--						SELECT DISTINCT tc.MCName , tc.JobName_Af ,tc.DeviceName_change+'('+tc.JobName_Af+')' ,'','',tc.MCName
--							,tc.Seq_No as Seq_no , tc.PK_Name ,NULL,NULL
--						FROM #tempMcTC as tc
--						where RowIndex = @loopTC
--						SET @loopTC = @loopTC+1
--					END
--				else
--					BEGIN
--						SET @loopTC = @loopTC+1
--					END
--				END
			--------------------------------------------------------------------

			insert #getLotInMC
			select  device.name as DeviceName,device.ft_name as FTDevice, lot.lot_no,mc.name as McName,REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
				, max(lot_record.recorded_at) as STARTTIME
				, (SELECT DATEADD(MINUTE, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))), max(lot_record.recorded_at))) AS ENDTIME
				, pk.name
			from  [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
			  inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id
			  INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lot.act_job_id
			  inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = lot.machine_id
			  INNER JOIN APCSProDB.method.packages as pk on pk.id = lot.act_package_id
			  inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
			  inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
			where lot.act_job_id  in (236,289,231) and lot.process_state not in ( 0,100)  and lot.wip_state= 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 0
				and pk.name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
			group by lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
				,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in,job.name,pk.name
			union all
		   select device.name as DeviceName,device.ft_name as FTDevice, lot.lot_no,mc.name as McName,REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
			,max(lot_record.recorded_at) as STARTTIME
			,(SELECT DATEADD(MINUTE, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))), max(lot_record.recorded_at))) AS ENDTIME
			,pk.name
			from  [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
			  inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id 
			  inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lot.id
			  inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id
			  INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
			  inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
			  INNER JOIN APCSProDB.method.packages as pk on pk.id = lot.act_package_id
			  inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = special.machine_id
			  inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
		  where lotspecial.job_id  in (236,289,231) and special.process_state not in ( 0,100)  and lot.wip_state = 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 1 
				and pk.name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
		  group by  lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
				,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in,job.name,pk.name

				insert #tempLotInMC
				select ROW_NUMBER() OVER(ORDER BY MCName ASC), *  from #getLotInMC

		---------- lot in mc new ---------------------------------------------------
		DECLARE @loopinmc int = 1

		WHILE @loopinmc <= (select MAX(RowIndex) from  #tempLotInMC)
			BEGIN
			IF NOT EXISTS(SELECT * FROM [DBxDW].[dbo].[scheduler_temp_seq_tp] WHERE lot_no COLLATE SQL_Latin1_General_CP1_CI_AS =(select LotNo from #tempLotInMC where RowIndex = @loopinmc) AND flow COLLATE SQL_Latin1_General_CP1_CI_AS =(select JobName from #tempLotInMC where RowIndex = @loopinmc) )
				BEGIN
				INSERT INTO [DBxDW].[dbo].[scheduler_temp_seq_tp]
				SELECT DISTINCT lots.LotNo , lots.JobName ,lots.FTDeviceName ,'','',lots.MCName as MachineName,1 as Seq_no,lots.Package ,lots.EndLot,lots.StartLot
				FROM #tempLotInMC as lots 
				WHERE RowIndex = @loopinmc
				ORDER BY lots.LotNo
				END
			SET @loopinmc = @loopinmc+1
			END
		----------------------Set lot Que-------------------------------------------------- 
WHILE @cnt <= (select COUNT(DeivceName) from  #tempDeivceSet)
BEGIN
   -------- WIP DATA-----------------------------------
			
			INSERT INTO #getWIPData
			SELECT DISTINCT  mc_name as MCName,lot_no,device_name as DeviceName,devicename.ft_name as FTDevice,pkg_name ,job_name,'' as NextJob,kpcs,qty_production,[state]
				,standare_time,job_id,temp.update_at,temp.rack_address,temp.rack_name
			FROM DBx.dbo.scheduler_tp_qa_wip as temp
			inner JOIN APCSProDB.method.device_names as devicename on  temp.device_name =devicename.name
			WHERE job_id in (231,236,289) and pkg_name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
			and device_name = (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex = @cnt)
			order by lot_no


			--SELECT * FROM #getWIPData
			
			--------------------------------------------------------------- 
			INSERT INTO #tempWIPData
			select ROW_NUMBER() OVER(ORDER BY gets.lot_no),* from #getWIPData as gets 
			where DeviceName = (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex = @cnt)

			--SELECT * FROM #tempWIPData
	--select '#tempWIPData complete'
	------------MC Data--------------------------------------------
			INSERT INTO #tempMCSetDeivce
			SELECT ROW_NUMBER() OVER(ORDER BY setup.LotEnd ASC)-1,
			setup.MCNo , setup.DeviceName ,setup.PackageName,setup.LotEnd
			FROM #tempSetupMc  as setup
			where DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex = 1)
			--and TestFlow = (select Flow from #tempDeivceSet where RowIndex = @cnt)


			--select * from #tempMCSetDeivce

			 

	DECLARE @loop INT = 1;

	DECLARE @CountMCs INT = (select COUNT(MCName) from #tempMCSetDeivce where DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt))
	--D JobName in ((select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt))) --นับจำนวนแถวของ Mc 

	DECLARE @mod INT = @CountMCs 
	DECLARE @CountLots INT = (select COUNT(lot_no) from #tempWIPData where DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt)) 
	--AND JobName in ((select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt))) --นับจำนวนแถวของ lot 

	DECLARE @Round int =  @CountLots 

	DECLARE @Seq_no int = 2
	
			WHILE @loop <= @Round
				BEGIN
				
					DECLARE @indexMc INT = (@mod % @CountMCs)
					
					DECLARE @Lot_no varchar(30) = (SELECT lots.lot_no FROM #tempWIPData as lots  
									WHERE DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt) 
									--AND JobName in ((select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt))
									AND RowIndex = @loop) --parameter lotno
					DECLARE @Flow varchar(30) = (SELECT lots.JobName FROM #tempWIPData as lots  
									WHERE DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt) 
									--AND JobName in ((select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt))
									AND RowIndex = @loop) --parameter flow
					
					DECLARE @MC_name varchar(20) = (SELECT mc.MCName 
													FROM #tempMCSetDeivce as Mc
													WHERE DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt) 
													--AND JobName in ((select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt))
													AND RowIndex = @indexMc)
					
					IF NOT EXISTS(SELECT 1 FROM [DBxDW].[dbo].[scheduler_temp_seq_tp] where lot_no collate SQL_Latin1_General_CP1_CI_AS = @Lot_no) -- ไม่พบ TC SET LOT 
					BEGIN
					--select @cnt as cnt , @loop as loop
								INSERT INTO [DBxDW].[dbo].[scheduler_temp_seq_tp]
								SELECT lots.lot_no , lots.JobName ,lots.FTDeivceName ,lots.RackAddress,lots.RackName
								,@MC_name as MachineName
								,@Seq_no as Seq_no , lots.PkgName ,NULL,NULL
								FROM #tempWIPData as lots 
								WHERE DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt) 
								--AND JobName in ((select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt))
								AND RowIndex = @loop
						SET @loop = @loop+1
					END
					ELSE
					BEGIN
						IF(@CountMCs <= 1)
						BEGIN
						--select 'TC one mc' ,@MC_name as mcname
						SET @loop = @loop+1
						SET @Seq_no = @Seq_no-1
							--BREAK
						END
					END
					IF(@CountMCs > 1)
						BEGIN
							SET @mod = @mod+1
							SET @indexMc = @mod % @CountMCs
						END
					IF(@indexMc = 0)
						BEGIN
							SET @Seq_no = @Seq_no+1
						END
					
				END
				
			
	SET @cnt = @cnt+1 --<----ถึงนี่แล้ว
	
END
--DROP TABLE #tempCalculate
--DROP TABLE #DeviceAndPk
--DROP TABLE #TPACC
--DROP TABLE #SUMMARYData
--DROP TABLE #PKList
drop table #tempSetupMc
drop table #tempTypeSetup
drop table #tempDeivceSet
drop table #getLotInMC
drop table #getWIPData
drop table #tempWIPData
drop table #tempMCSetDeivce
drop table #tempLotInMC
--drop table #tempMcTC
 




END
