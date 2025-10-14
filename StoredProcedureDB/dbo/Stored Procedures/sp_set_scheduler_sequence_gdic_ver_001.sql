-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_sequence_gdic_ver_001] 
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
DECLARE @PackageName varchar(MAX)
SET @PackageName = 'SSOP-B20W,SSOP-B28W,SSOP-B10W,SOP-JW8,SSOP-C38W'

DELETE FROM DBxDW.dbo.[scheduler_temp]
WHERE package_name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))

CREATE TABLE #tempSetupMc
(
    MCNo varchar(30), McId int, OpRate real, SetupId int, LotNo varchar(10), PackageName varchar(30), DeviceName varchar(30),
	 CustomDevice varchar(30), ProgramName varchar(30), TesterType varchar(30),TestFlow varchar(50), TestBoxA varchar(30),
	 TestBoxB varchar(30), DutcardA varchar(30), DutcardB varchar (30), OptionName1 varchar(30), OptionName2 varchar(30),
	 [Status] varchar(20),LotEnd Datetime,DelayLot varchar(1)
)

	INSERT INTO #tempSetupMc
SELECT DISTINCT [FTSetupReport].[MCNo], Mc.id as McId, Rate.oprate, Rate.setupid, LotNo, PackageName, DeviceName
		 , SUBSTRING (DeviceName , 0,(SELECT CHARINDEX('-', DeviceName))) as CustomDevice
		, ProgramName, TesterType, TestFlow, TestBoxA 
		, TestBoxB, DutcardA, DutcardB, OptionName1, OptionName2
		, case when [State].run_state = 0 THEN 'Ready'
				when [State].run_state = 1 THEN 'Idle'
				when [State].run_state = 2 THEN 'Setup'
				when [State].run_state = 3 THEN 'Ready'
				when [State].run_state = 4 THEN 'Run'
				when [State].run_state = 10 THEN 'PlanStop' 
			ELSE 'Wait' END as [Status] 
		
		,(select top 1 (SELECT DATEADD(MINUTE, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))), max(lot_record.recorded_at))) AS ENDTIME
			--, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))) as aaa
			from  [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
			  inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id
			  inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = lot.machine_id
			  inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
			  inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
			  where lot.act_job_id  in (106,108,110,119,263,359,361,362,363,364)  and lot.process_state != 0  and lot.wip_state= 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 0
			  and mc.name = [FTSetupReport].[MCNo]
			  group by lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
			  ,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in) AS ENDTIME
		,'0' as DelayLot
		FROM [DBx].[dbo].[FTSetupReport]
		inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
		left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
		left join APCSProDB.trans.machine_states as [State] on Mc.id = State.machine_id
		Where PackageName in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) 
		and [FTSetupReport].[MCNo] not like '%-M-%'
		and [FTSetupReport].[MCNo] not like '%ith%'
		and [FTSetupReport].[MCNo] not like '%-z-%'
		and [FTSetupReport].[MCNo] not like '%-099%'
		and [FTSetupReport].[MCNo] not like '%-000'
		
		--select * from #tempSetupMc
		--drop TABLE #tempSetupMc
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

 
-- select * from #tempDeivceSet
--select '#tempDeivceSet complete'
DECLARE @cnt INT = 1;


CREATE TABLE #GetSchedulerSeq
			(
			Seq_no int, MCName Varchar(30), Prioritys int,DeviceName_change varchar(30),DeviceName_Now varchar(30),DateSet Datetime,JobName_Af Varchar(20)
			)

CREATE TABLE #tempMcTC
			(
			RowIndex int,MCName Varchar(30),Seq_No int,DeviceName_change varchar(30),DeviceName_Now varchar(30),JobName_Be Varchar(20), JobName_Af Varchar(20),PK_Name VarChar(30)
			)
CREATE TABLE #tempMCList
			(
			RowIndex int,MCName Varchar(30),MC_ID int
			)

CREATE TABLE #GetGDIC_planTC_NEW
			(
			index_num int identity(1,1),Prioritys int,MCName Varchar(30),Seq_no int,
			DeviceName_change varchar(30),DeviceName_Now varchar(30),DateSet Datetime,date_complete Datetime,mc_id int,flow_before Varchar(MAX),flow_after Varchar(MAX)
			)

			
CREATE TABLE #scheduler_temp_TC
			(
				   [lot_no] Varchar(30)
				  ,[flow] Varchar(30)
				  ,[ft_device] Varchar(30)
				  ,[rack_address] Varchar(30)
				  ,[rack_name] Varchar(30)
				  ,[machine_name] Varchar(30)
				  ,[seq_no] int
				  ,[package_name] Varchar(30)
				  ,[lot_end] DATETIME
				  ,[lot_start] DATETIME
			)


			--Get machineList from setup to use in TypeChange
			INSERT INTO #tempMCList
			select ROW_NUMBER() OVER(ORDER BY MCNo ASC), MCNo,McId from #tempSetupMc where PackageName in (SELECT short_name FROM APCSProDB.method.packages WHERE name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )))

			INSERT INTO #GetGDIC_planTC_NEW
			SELECT * FROM DBx.dbo.scheduler_setup WHERE mc_id IN (select #tempMCList.MC_ID from #tempMCList) AND date_complete is null 

			Select TC.index_num,TC.MCName,TC.Seq_no,TC.DeviceName_change,TC.DeviceName_Now,TC.flow_after,TC.flow_before,CurMC.DeviceName,CurMC.TestFlow 
			INTO #AlreadyUpdate
			from #GetGDIC_planTC_NEW  as TC 
			inner join DBx.dbo.FTSetupReport as CurMC on TC.MCName = CurMC.MCNo
			where (CurMC.DeviceName = TC.DeviceName_change and CurMC.TestFlow = Tc.flow_after) OR (CurMC.DeviceName != TC.DeviceName_Now AND CurMC.DeviceName != TC.DeviceName_change)

			UPDATE DBx.dbo.scheduler_setup
			SET [date_complete] = GETDATE()
			FROM #AlreadyUpdate
			where  DBx.dbo.scheduler_setup.date_complete is null and  DBx.dbo.scheduler_setup.mc_no = #AlreadyUpdate.MCName

			DELETE DBxDW.dbo.[scheduler_temp] where lot_no COLLATE SQL_Latin1_General_CP1_CI_AS IN (select MCName from #AlreadyUpdate)


			INSERT INTO #scheduler_temp_TC
			Select distinct tc.MCName , tc.flow_after ,tc.DeviceName_change ,'','',tc.MCName,
			--tc.Seq_No as Seq_no 
			CASE 
				WHEN tc.Seq_no <= 2 THEN 2
				WHEN tc.Seq_no > 2 THEN tc.Seq_no - (SELECT COUNT(*) FROM [APCSProDB].[trans].[lot_process_records] where record_class = 2 and recorded_at >= TC.DateSet and [lot_process_records].machine_id = TC.mc_id ) END AS seq_no
			, pk.name,NULL,NULL
			from #GetGDIC_planTC_NEW  as TC 
			inner join DBx.dbo.FTSetupReport as CurMC on TC.MCName = CurMC.MCNo
			INNER JOIN APCSProDB.method.device_names as dv on dv.name = TC.DeviceName_change
			INNER JOIN APCSProDB.method.packages as pk on pk.id = dv.package_id
			where TC.MCName NOT IN (select MCName from #AlreadyUpdate )

			DELETE DBxDW.dbo.[scheduler_temp] where lot_no COLLATE SQL_Latin1_General_CP1_CI_AS IN (select lot_no from #scheduler_temp_TC)

			insert into DBxDW.dbo.[scheduler_temp] select * from #scheduler_temp_TC


			--------------------------------------------------------------------
CREATE TABLE #tempLotInMC
	(
		RowIndex int,DeviceName varchar(30),FTDeviceName varchar(30),LotNo varchar(10),MCName varchar(11),JobName Varchar(20), StartLot datetime,EndLot datetime 
		, Package varchar(30)
	)
CREATE TABLE #tempMCSetDeivce
	(
		RowIndex int, MCName varchar(11),  DeviceName varchar(30), PkgName varchar(15),JobName varchar(20) ,Lotend datetime
			  
	)

CREATE TABLE #getLotInMC
	(
		DeviceName varchar(30),FTDeviceName varchar(30),LotNo varchar(10),MCName varchar(11),JobName Varchar(20), StartLot datetime,EndLot datetime 
		, Package varchar(30)
	)

CREATE TABLE #tempWIPData
	(
		RowIndex int, MCName varchar(11), lot_no varchar(10), DeviceName varchar(30), FTDeivceName varchar(20), PkgName varchar(15),JobName varchar(20),
		NextJobName varchar(20), Kpcs int , qty_production float, ProcessState int, StandardTime int, JobID int, UpdatedAt datetime, QualityState int,
		RackAddress varchar(10), RackName varchar(15)
	)


CREATE TABLE #getWIPData
	(
		MCName varchar(11), lot_no varchar(10), DeviceName varchar(30), FTDeivceName varchar(20), PkgName varchar(15),JobName varchar(20),
		NextJobName varchar(20), Kpcs int , qty_production float, ProcessState int, StandardTime int, JobID int, UpdatedAt datetime, QualityState int,
		RackAddress varchar(10), RackName varchar(15)
	)

CREATE TABLE #tempTypeSetup
	(
		DeivceName varchar(30),Flow varchar(50)
	)

	INSERT INTO #tempTypeSetup
SELECT Distinct ftsetup.DeviceName,ftsetup.TestFlow
FROM #tempSetupMc as ftsetup
WHERE ftsetup.PackageName in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) 
and ftsetup.[MCNo] not like '%-M-%'
		and ftsetup.[MCNo] not like '%ith%'
		and ftsetup.[MCNo] not like '%-z-%'
		and ftsetup.[MCNo] not like '%-099%'
		and ftsetup.[MCNo] not like '%-000'
----------------------------------------------------
--select '#tempTypeSetup complete'
------------------------------------------------------
			CREATE TABLE #tempDeivceSet
			(
				DeivceName varchar(30),Flow varchar(50),RowIndex int
			)

				insert into #tempDeivceSet
			select *,ROW_NUMBER() OVER(ORDER BY settemp.DeivceName,settemp.Flow ASC) 
			from  #tempTypeSetup as settemp

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
			where lot.act_job_id  in (106,108,110,119,263,359,361,362,363,364)  and lot.process_state not in ( 0,100)  and lot.wip_state= 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 0
			    and lot.quality_state NOT IN (3)
				and pk.name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
				and device.alias_package_group_id = 33
			group by lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
				,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in,job.name,pk.name
			union all
		   select device.name as DeviceName,device.ft_name as FTDevice, lot.lot_no,mc.name as McName,REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
			,max(lot_record.recorded_at) as STARTTIME
			,(SELECT DATEADD(MINUTE, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))), max(lot_record.recorded_at))) AS ENDTIME
			,pk.name
			from  [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
			  inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id 
			  inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
			  inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lot.id
			  INNER JOIN APCSProDB.method.packages as pk on pk.id = lot.act_package_id
			  inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = special.machine_id
			  inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id
			  inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
			  INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
		  where lotspecial.job_id  in (106,108,110,119,378,263,385,359,361,362,363,364) and special.process_state not in ( 0,100)  and lot.wip_state = 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 1 
				and pk.name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
				and device.alias_package_group_id = 33
				and lot.quality_state NOT IN (3)
		  group by  lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
				,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in,job.name,pk.name

				--select *  from #getLotInMC

				insert #tempLotInMC
				select ROW_NUMBER() OVER(ORDER BY MCName ASC), *  from #getLotInMC

				--select *  from #tempLotInMC
		---------- lot in mc new ---------------------------------------------------
		DECLARE @loopinmc int = 1

		WHILE @loopinmc <= (select MAX(RowIndex) from  #tempLotInMC)
			BEGIN
			IF NOT EXISTS(SELECT * FROM [DBxDW].[dbo].[scheduler_temp] WHERE lot_no COLLATE SQL_Latin1_General_CP1_CI_AS =(select LotNo from #tempLotInMC where RowIndex = @loopinmc) AND flow COLLATE SQL_Latin1_General_CP1_CI_AS =(select JobName from #tempLotInMC where RowIndex = @loopinmc) )
				BEGIN
				INSERT INTO [DBxDW].[dbo].[scheduler_temp]
				SELECT DISTINCT lots.LotNo , lots.JobName ,lots.FTDeviceName ,'','',lots.MCName as MachineName,1 as Seq_no,lots.Package ,lots.EndLot,lots.StartLot
				FROM #tempLotInMC as lots 
				WHERE RowIndex = @loopinmc
				ORDER BY lots.LotNo
			
				--SET @loopinmc = @loopinmc+1
				END
			SET @loopinmc = @loopinmc+1
			--ELSE
			--	BEGIN
			--	SELECT * FROM [DBxDW].[dbo].[scheduler_temp] WHERE lot_no =(select lot_no from #tempLotInMC where RowIndex = @loopinmc) AND flow COLLATE SQL_Latin1_General_CP1_CI_AS =(select JobName from #tempLotInMC where RowIndex = @loopinmc) 
			--	END
			END
		

		--select * from DBxDW.dbo.scheduler_temp where package_name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
		----------------------Set lot Que--------------------------------------------------
WHILE @cnt <= (select COUNT(DeivceName) from  #tempDeivceSet)
BEGIN
   --select * from #tempDeivceSet where RowIndex = @cnt
   
   -------- WIP DATA-----------------------------------
			
			insert into #getWIPData
			SELECT [APCSProDB].[mc].[machines].name AS MCName
				 , [APCSProDB].[trans].[lots].lot_no
				 , [APCSProDB].[method].device_names.name AS DeviceName 
				 , [APCSProDB] .[method].device_names.ft_name AS FTDevice
				 , [APCSProDB].[method].[packages].name AS MethodPkgName
				 , CASE 
					WHEN [APCSProDB].[method].[jobs].name LIKE '%SBLSYL%' 
						THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL',''))
					ELSE REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','')
					END as JobName
				 , '' as NextJob
				 , [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
				 , case when APCSProDB.trans.lots.process_state = 2 and APCSProDB.trans.lots.qty_in > 0 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
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
			LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
			INNER join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) 
			and [APCSProDB].method.device_names.alias_package_group_id = 33
			and is_special_flow = 0 and process_state in(0,100) and quality_state = 0
			and [APCSProDB] .[method].device_names.name = (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex = @cnt)
			and TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL','')) in(select Flow from #tempDeivceSet where RowIndex = @cnt)
		UNION ALL
			SELECT [APCSProDB].[mc].[machines].name AS MCName
				, [APCSProDB].[trans].[lots].lot_no
				, [APCSProDB].[method].device_names.name AS DeviceName 
				, [APCSProDB].[method].device_names.ft_name AS FTDevice
				, [APCSProDB].[method].[packages].name AS MethodPkgName
				, CASE 
					WHEN job.name LIKE '%SBLSYL%' 
						THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL',''))
					WHEN job.name LIKE '%BIN27-CF%'
						THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'BIN27-CF',''))
					WHEN job.name LIKE '%BIN27%'
						THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'BIN27',''))
					ELSE REPLACE(REPLACE(job.name,'(',''),')','')
					END as JobName
				, lots.act_job_id as NextJob
				, [APCSProDB].[trans] .lots.qty_in  AS Kpcs 
				, case when APCSProDB.trans.lots.process_state = 2 and APCSProDB.trans.lots.qty_in > 0 then (([APCSProDB].[trans].lots.qty_in + 0.0 - ([APCSProDB].[trans].lots.qty_last_pass + [APCSProDB].[trans].lots.qty_last_fail)) / [APCSProDB].[trans].lots.qty_in) else 1 end as qty_production
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
			inner join APCSProDB.trans.special_flows as special with (NOLOCK) on lots.special_flow_id = special.id
			inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
			LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
			INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
			INNER join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
			where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))  
			and [APCSProDB].method.device_names.alias_package_group_id = 33
			and lotspecial.job_id in(119,110,108,106,359,361,362,363,364) and lots.is_special_flow = 1 and lots.process_state in(0,100) and lots.quality_state in(0,4)
			and [APCSProDB] .[method].device_names.name = (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex = @cnt)
			and TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL','')) in(select Flow from #tempDeivceSet where RowIndex = @cnt)
			and TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'Bin27-CF','')) in(select Flow from #tempDeivceSet where RowIndex = @cnt)
			and TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'BIN27','')) in(select Flow from #tempDeivceSet where RowIndex = @cnt)
		order by lot_no
	---------------------------------------------------------------
	--select '#tempWIPData complete'
	------------MC Data--------------------------------------------
			INSERT INTO #tempMCSetDeivce
			SELECT ROW_NUMBER() OVER(ORDER BY setup.LotEnd ASC)-1,
			setup.MCNo , setup.DeviceName ,setup.PackageName , setup.TestFlow ,setup.LotEnd 
			FROM #tempSetupMc  as setup
			where DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex = @cnt)
			and TestFlow = (select Flow from #tempDeivceSet where RowIndex = @cnt)

			--select * from #tempMCSetDeivce
			INSERT INTO #tempWIPData
			select ROW_NUMBER() OVER(ORDER BY gets.lot_no),* from #getWIPData as gets 
			where DeviceName = (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex = @cnt)
				and JobName in(select Flow from #tempDeivceSet where RowIndex = @cnt)
			
			--select * from #tempWIPData where DeviceName = (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex = @cnt)
			--and JobName in(select Flow from #tempDeivceSet where RowIndex = @cnt)
	
	DECLARE @loop INT = 1;

	DECLARE @CountMCs INT = (select COUNT(MCName) from #tempMCSetDeivce where DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt) 
	AND JobName in ((select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt))) --นับจำนวนแถวของ Mc 

	DECLARE @mod INT = @CountMCs 
	DECLARE @CountLots INT = (select COUNT(lot_no) from #tempWIPData where DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt) 
	AND JobName in ((select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt))) --นับจำนวนแถวของ lot 

	--DECLARE @Round int = Case when @CountMCs > @CountLots then @CountMCs ELSE @CountLots END
	DECLARE @Round int =  @CountLots 
	--select @CountMCs as MCs ,@CountLots as Lots 
	DECLARE @Seq_no int = 2
	
			WHILE @loop <= @Round
				BEGIN
				
					DECLARE @indexMc INT = (@mod % @CountMCs)
					--เทสค่าตัวแปร-----
					--select @indexMc as indexMc,@Seq_no as Seq
					--select @loop as loops
					--select @indexMc as IndexMC ,@mod as modValue --เทสค่าตัวแปร
					--------------
					--DECLARE @Lot_no varchar(30) = (SELECT lots.lot_no FROM #tempWIPData as lots  
					--				WHERE DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt) 
					--				AND JobName in ((select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt))
					--				AND RowIndex = @loop) --parameter lotno
					--DECLARE @Flow varchar(30) = (SELECT lots.JobName FROM #tempWIPData as lots  
					--				WHERE DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt) 
					--				AND JobName in ((select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt))
					--				AND RowIndex = @loop) --parameter flow
					--Select @Lot_no as lotno,@Flow as flow
					DECLARE @MC_name varchar(20) = (SELECT mc.MCName 
													FROM #tempMCSetDeivce as Mc
													WHERE DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt) 
													AND JobName in ((select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt))
													AND RowIndex = @indexMc)
					--DECLARE @Seq_no int = CASE WHEN (SELECT COUNT(seq_no) FROM [DBxDW].[dbo].[scheduler_temp] WHERE machine_name = @MC_name) = 0 THEN 0
					--						ELSE (SELECT MAX(seq_no) FROM [DBxDW].[dbo].[scheduler_temp] WHERE machine_name = @MC_name) 
					--						END ---หาค่า seq_no มากที่สุดของ Mc

				   
					

					--SELECT @MC_name as mc,@Seq_no as seq
					--SELECT @loop
					--SELECT @MC_name as mcNAme,@Seq_no as seq,@Lot_no as lot_no ,@CountMCs as cMc, @CountLots as cLots ,(select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt) as DV ,
					--(select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt) as Flow ,@loop as loopLots ,@indexMc as IndexMC
					IF NOT EXISTS(SELECT * FROM [DBxDW].[dbo].[scheduler_temp] where lot_no collate SQL_Latin1_General_CP1_CI_AS = @MC_name and seq_no <= @Seq_no) -- ไม่พบ TC SET LOT 
					BEGIN
						      INSERT INTO [DBxDW].[dbo].[scheduler_temp]
								SELECT lots.lot_no , lots.JobName ,lots.FTDeivceName ,lots.RackAddress,lots.RackName
								,@MC_name as MachineName
								,@Seq_no as Seq_no , lots.PkgName ,NULL,NULL
								FROM #tempWIPData as lots 
								WHERE DeviceName =  (select #tempDeivceSet.DeivceName from #tempDeivceSet where RowIndex =  @cnt) 
								AND JobName in ((select #tempDeivceSet.Flow from #tempDeivceSet where RowIndex =  @cnt))
								AND RowIndex = @loop
						SET @loop = @loop+1
					END
					ELSE
					BEGIN
						IF(@CountMCs <= 1)
						BEGIN
						--select 'TC one mc' ,@MC_name as mcname
							BREAK
						END
					END
					IF(@CountMCs > 1)
						BEGIN
							SET @mod = @mod+1
							SET @indexMc = @mod % @CountMCs
							IF((@CountMCs-1)-@indexMc = 0)
								BEGIN
									IF EXISTS (SELECT * FROM [DBxDW].[dbo].[scheduler_temp] where lot_no collate SQL_Latin1_General_CP1_CI_AS = @MC_name and seq_no <= @Seq_no and lot_no = machine_name)
									BEGIN
										BREAK --protect loop
									END
								END
						END
					IF(@indexMc = 0)
						BEGIN
							SET @Seq_no = @Seq_no+1
						END
					
				END
				
			
	SET @cnt = @cnt+1
	
END

--select * from #tempDeivceSet 
--select * from #tempSetupMc
--select * from #getWIPData
--select * from DBxDW.dbo.scheduler_temp
drop table #getLotInMC
drop table #getWIPData
drop table #tempMcTC
drop table #tempTypeSetup 
drop table #tempSetupMc
drop table #tempDeivceSet
drop table #tempWIPData
drop table #tempMCSetDeivce
drop table #tempLotInMC
drop table #tempMCList
drop table #GetSchedulerSeq

drop table #GetGDIC_planTC_NEW
drop table #AlreadyUpdate
drop table #scheduler_temp_TC
END