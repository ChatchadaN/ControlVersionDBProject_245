-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_sequence_gdic_backup_050624] 
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
BEGIN Try

----** add status rack 2023-03-09
DECLARE @PackageName varchar(MAX)
SET @PackageName = 'SSOP-B20W,SSOP-B28W,SSOP-B10W,SOP-JW8,SSOP-C38W,SSOP-B20WA,SSOPB20WR1,SSOPB28WR6'

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
					  where lot.act_job_id  in (106,108,110,119,263,359,361,362,363,364,155)  and lot.process_state != 0  and lot.wip_state= 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 0
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
				--and [FTSetupReport].[MCNo] not like '%-099%' --23/08/28 aun
				and [FTSetupReport].[MCNo] not like '%-000'
				and [FTSetupReport].[SetupStatus] = 'CONFIRMED'
				and Mc.is_disabled = 0
				--and [FTSetupReport].[MCNo] <> 'FT-RAS-004'
		
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
			INTO #AlreadyUpdateGdic
			from #GetGDIC_planTC_NEW  as TC 
			inner join DBx.dbo.FTSetupReport as CurMC on TC.MCName = CurMC.MCNo
			where (CurMC.DeviceName = TC.DeviceName_change and CurMC.TestFlow = Tc.flow_after) OR (CurMC.DeviceName != TC.DeviceName_Now AND CurMC.DeviceName != TC.DeviceName_change)

			UPDATE DBx.dbo.scheduler_setup
			SET [date_complete] = GETDATE()
			FROM #AlreadyUpdateGdic
			where  DBx.dbo.scheduler_setup.date_complete is null and  DBx.dbo.scheduler_setup.mc_no = #AlreadyUpdateGdic.MCName

			DELETE DBxDW.dbo.[scheduler_temp] where lot_no COLLATE SQL_Latin1_General_CP1_CI_AS IN (select MCName from #AlreadyUpdateGdic)


			INSERT INTO #scheduler_temp_TC
			Select distinct tc.MCName , tc.flow_after ,tc.DeviceName_change ,'','',tc.MCName,
			--tc.Seq_No as Seq_no 
			CASE 
				WHEN tc.Seq_no <= 2 THEN 2
				WHEN tc.Seq_no > 2 THEN 
				IIF(tc.Seq_no - (SELECT COUNT(1) FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)  where record_class = 2 and recorded_at >= TC.DateSet and [lot_process_records].machine_id = TC.mc_id and [lot_process_records].day_id > 2500 ) < 2 , 2 ,
				tc.Seq_no - (SELECT COUNT(1) FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)  where record_class = 2 and recorded_at >= TC.DateSet and [lot_process_records].machine_id = TC.mc_id and [lot_process_records].day_id > 2500 )) END AS seq_no
			--, pk.name,NULL,NULL    update at 2022/06/26
			, CurMC.PackageName,NULL,NULL
			from #GetGDIC_planTC_NEW  as TC 
			inner join DBx.dbo.FTSetupReport as CurMC on TC.MCName = CurMC.MCNo
			INNER JOIN APCSProDB.method.device_names as dv on dv.name = TC.DeviceName_change
			--INNER JOIN APCSProDB.method.packages as pk on pk.id = dv.package_id
			where TC.MCName NOT IN (select MCName from #AlreadyUpdateGdic )

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


			------------------Available Machine for Device Type and Flow----------------------
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
				--and ftsetup.[MCNo] not like '%-099%'  --23/08/28 aun
				and ftsetup.[MCNo] not like '%-000'
			-----------------------------------------------------------------------------



			-------------------------------GET RUNNING LOTS----------------------------------------------------------------
			insert #getLotInMC
			select distinct  device.name as DeviceName
			,device.ft_name as FTDevice
			, lot.lot_no
			,mc.name as McName
			, CASE 
			WHEN job.name LIKE '%SBLSYL%' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL',''))
			WHEN job.name = 'OS+AUTO(1)' 
				THEN 'AUTO1'
			WHEN job.name = 'AUTO(1) RE'
				THEN 'AUTO1'
			ELSE REPLACE(REPLACE(job.name,'(',''),')','')
			END AS JobName
			--,REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
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
			where lot.act_job_id  in (106,108,110,119,263,359,361,362,363,364,155)  and lot.process_state in ( 2,102)  and lot.wip_state= 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 0
			    and lot.quality_state NOT IN (3)
				and pk.name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
				and device.alias_package_group_id = 33
			group by lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
				,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in,job.name,pk.name
			union all
		   select distinct device.name as DeviceName,device.ft_name as FTDevice, lot.lot_no,mc.name as McName,REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
			,max(lot_record.recorded_at) as STARTTIME
			,(SELECT DATEADD(MINUTE, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))), max(lot_record.recorded_at))) AS ENDTIME
			,pk.name
			from  [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
			  inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id 
			  inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
			  inner join APCSProDB.trans.special_flows as special with (NOLOCK) on special.lot_id = lot.id
			  INNER JOIN APCSProDB.method.packages as pk on pk.id = lot.act_package_id
			  inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = special.machine_id
			  inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id  and special.step_no = lotspecial.step_no
			  inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
			  INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
		  where lotspecial.job_id  in (106,108,110,155,119,378,263,385,359,361,362,363,364) and special.process_state  in ( 2,102)  and lot.wip_state = 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 1 
		  and special.wip_state =20
				and pk.name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
				and device.alias_package_group_id = 33
				and lot.quality_state NOT IN (3)
		  group by  lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
				,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in,job.name,pk.name


				-------------------------INSERT LOT IN MACHINE PROCEDURE RUNNING HERE----------------------------------------------


				INSERT INTO [DBxDW].[dbo].[scheduler_temp] SELECT LotNo,JobName,FTDeviceName,'','',MCName,1,Package,EndLot,StartLot FROM #getLotInMC


				--------------------------------------------------------------------------------------------------------------------




	CREATE TABLE #getWIPData
	(
		MCName varchar(11), lot_no varchar(10), DeviceName varchar(30), FTDeivceName varchar(20), PkgName varchar(15),JobName varchar(20),
		NextJobName varchar(20), Kpcs int , qty_production float, ProcessState int, StandardTime int, JobID int, UpdatedAt datetime, QualityState int,
		RackAddress varchar(10), RackName varchar(15)
	)

	CREATE TABLE #getWIPData_New
	(
		lot_seq int,A int,MCName varchar(11), lot_no varchar(10), DeviceName varchar(30), FTDeivceName varchar(20), PkgName varchar(15),JobName varchar(20),
		NextJobName varchar(20), JobID int, UpdatedAt datetime, QualityState int,RackAddress varchar(10), RackName varchar(15)
	)

	CREATE TABLE #scheduler_temp_WIP
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

	----------------------Finding WIP------------------------------------------------------------
	INSERT INTO #getWIPData_New
	SELECT RANK() OVER(PARTITION BY DeviceName,JobName ORDER BY lot_no ASC) AS lot_Seq,* FROM
	(
	SELECT ROW_NUMBER() OVER(ORDER BY lot_no ASC) AS A,* FROM (
	SELECT DISTINCT
		  [APCSProDB].[mc].[machines].name AS MCName
		, [APCSProDB].[trans].[lots].lot_no
		, [APCSProDB].[method].device_names.name AS DeviceName 
		, [APCSProDB] .[method].device_names.ft_name AS FTDevice
		, [APCSProDB].[method].[packages].name AS MethodPkgName
		, CASE 
		WHEN [APCSProDB].[method].[jobs].name LIKE '%SBLSYL%' 
			THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL',''))
		WHEN jobs.name = 'OS+AUTO(1)' 
			THEN 'AUTO1'
		WHEN jobs.name = 'AUTO(1) RE'
			THEN 'AUTO1'
		ELSE REPLACE(REPLACE([APCSProDB].[method].[jobs].name,'(',''),')','')
		END as JobName
		, '' as NextJob
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
		------------------------------------------------------------------------------------------------------------
		---- add status rack 2023-03-09
		------------------------------------------------------------------------------------------------------------
		left join [DBx].[dbo].[rcs_current_locations] as [current_locations] with (NOLOCK) on [locations].[id] = [current_locations].[location_id]
			and [lots].[id] = [current_locations].[lot_id]
		------------------------------------------------------------------------------------------------------------
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) 
		and [APCSProDB].method.device_names.alias_package_group_id = 33
		and is_special_flow = 0 and process_state in(0,100,1) and quality_state = 0
		and [APCSProDB] .[method].device_names.name IN (select #tempTypeSetup.DeivceName from #tempTypeSetup)
		and CASE 
				WHEN jobs.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN jobs.name = 'AUTO(1) RE' 
					THEN 'AUTO1'
				ELSE TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL',''))
				END  IN (select distinct Flow from #tempTypeSetup)
		------------------------------------------------------------------------------------------------------------
		---- add status rack 2023-03-09
		------------------------------------------------------------------------------------------------------------
		and [current_locations].[status] = 1
		------------------------------------------------------------------------------------------------------------
		--update by aun 2022/05/21
		--and TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL','')) in (select #tempTypeSetup.Flow from #tempTypeSetup)
		) AS A

		UNION ALL
			
	SELECT DISTINCT  ROW_NUMBER() OVER(ORDER BY lot_no ASC) AS B , * FROM(
		SELECT DISTINCT
		[APCSProDB].[mc].[machines].name AS MCName
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
			WHEN job.name = 'OS+AUTO(1)' 
				THEN 'AUTO1'
			WHEN job.name = 'AUTO(1) RE'
				THEN 'AUTO1'
			ELSE REPLACE(REPLACE(job.name,'(',''),')','')
			END as JobName
		, lots.act_job_id as NextJob
		, lotspecial.job_id as job_Id 
		, (select max(recorded_at) from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK) where lot_record.lot_id = lots.id) as updated_at 
		, lots.quality_state
		, locations.address
		, locations.name
			FROM [APCSProDB].[trans].lots 
			INNER JOIN [APCSProDB].[method].packages  ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
			--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
			inner join APCSProDB.trans.special_flows as special  on lots.special_flow_id = special.id
			inner join APCSProDB.trans.lot_special_flows as lotspecial  on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
			LEFT JOIN [APCSProDB].mc.machines  ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
			INNER JOIN [APCSProDB].method.jobs as job  ON  job.id = lotspecial.job_id
			INNer Join [APCSProDB] .[method].device_names on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
			--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].method.device_flows  on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
			INNER join [APCSProDB].trans.locations as locations  on locations.id = lots.location_id 
			------------------------------------------------------------------------------------------------------------
			---- add status rack 2023-03-09
			------------------------------------------------------------------------------------------------------------
			left join [DBx].[dbo].[rcs_current_locations] as [current_locations] with (NOLOCK) on [locations].[id] = [current_locations].[location_id]
				and [lots].[id] = [current_locations].[lot_id]
			------------------------------------------------------------------------------------------------------------
			where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))  
			and [APCSProDB].method.device_names.alias_package_group_id = 33
			and lotspecial.job_id in(106,108,110,155,119,359,263,385,359,361,362,363,364) and lots.is_special_flow = 1 and lots.process_state in(0,100,1) and lots.quality_state in(0,4)
			and special.process_state in (0,100,1)
			and [APCSProDB] .[method].device_names.name IN (select #tempTypeSetup.DeivceName from #tempTypeSetup)
			and TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL','')) in (select #tempTypeSetup.Flow from #tempTypeSetup)
			and TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'Bin27-CF','')) in (select #tempTypeSetup.Flow from #tempTypeSetup)
			and TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'BIN27','')) in (select #tempTypeSetup.Flow from #tempTypeSetup)
			and CASE 
				WHEN job.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN job.name = 'AUTO(1) RE' 
					THEN 'AUTO1'
				ELSE TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL',''))
				END  IN (select distinct Flow from #tempTypeSetup)
			------------------------------------------------------------------------------------------------------------
			---- add status rack 2023-03-09
			------------------------------------------------------------------------------------------------------------
			and [current_locations].[status] = 1
			------------------------------------------------------------------------------------------------------------
		) AS C 
		) AS D where  lot_no not in (select LotNo from #getLotInMC)	



	-----------------------------GET MACHINE SEQ-----------------------------------
	CREATE TABLE #tempSetupMc_RANK
	(
     Seq_MC int,MCNo varchar(30) primary key , McId int, OpRate real, SetupId int, LotNo varchar(10), PackageName varchar(30), DeviceName varchar(30)
	, TesterType varchar(30),TestFlow varchar(50),[Status] varchar(20),LotEnd Datetime,DelayLot varchar(1)
	)

	INSERT INTO #tempSetupMc_RANK
	select RANK() OVER(PARTITION BY DeviceName,TestFlow ORDER BY LotEnd,McId ASC) as Seq_MC, MCNo,McId,OpRate,SetupId,LotNo,PackageName
	,DeviceName,TesterType,TestFlow,Status,LotEnd,DelayLot from #tempSetupMc





	INSERT INTO #scheduler_temp_WIP
	SELECT TB_LotWip.lot_no,TB_LotWip.JobName,TB_LotWip.FTDeivceName,TB_LotWip.RackAddress,TB_LotWip.RackName,mc.MCNo as machine_name,TB_LotWip.lot_seq_onMC+1 as seq_no,TB_LotWip.PkgName,NULL as lot_end,NULL as lot_start
	FROM #tempSetupMc_RANK AS MC 
	INNER JOIN (
	SELECT *,
		CASE  WHEN lot_seq <= Max_Mc 
				THEN lot_seq ELSE
	   ---------Give Seq_mc for lot_seq < machine-------------
		CASE lot_seq % Max_Mc WHEN 0 THEN Max_Mc 
								   ELSE lot_seq % Max_Mc END
       --------Case When lot > mc, mod lot by Max_mc if equal 0 = last machine.
		END AS Index_point_mc,

		CASE 
			WHEN lot_seq <= Max_Mc
				THEN 1 
		    WHEN (lot_seq % Max_Mc) <> 0
				THEN  convert(int,lot_seq/Max_Mc) + 1
			WHEN (lot_seq % Max_Mc) = 0
				THEN  convert(int,lot_seq/Max_Mc)
		END AS lot_seq_onMC
	
	FROM(
		select (SELECT DISTINCT MAX(a.Seq_MC) FROM #tempSetupMc_RANK AS A WHERE A.DeviceName = B.DeviceName and A.TestFlow = B.JobName) AS Max_Mc
				----- Find Max machine for lot by device -------------
		, lot_seq,lot_no,DeviceName,JobName,FTDeivceName,B.RackAddress,RackName,PkgName

		from #getWIPData_New as B) AS TB
		) AS TB_LotWip ON TB_LotWip.Index_point_mc = mc.Seq_MC AND TB_LotWip.DeviceName = mc.DeviceName AND TB_LotWip.JobName = TestFlow  order by TB_LotWip.DeviceName,lot_seq


		select * INTO #Result from #scheduler_temp_WIP as outerTB where seq_no <= (select seq_no from #scheduler_temp_WIP as innerTB where innerTB.lot_no = outerTB.machine_name)
		OR machine_name not in (select MCName from #GetGDIC_planTC_NEW ) 


		INSERT INTO #Result select WIP.* from #scheduler_temp_WIP as WIP  inner join #scheduler_temp_TC on WIP.machine_name = #scheduler_temp_TC.machine_name and WIP.seq_no < #scheduler_temp_TC.seq_no
		--select * INTO #Result from #scheduler_temp_WIP as outerTB where seq_no <= (select seq_no from #scheduler_temp_WIP as innerTB where innerTB.lot_no = outerTB.machine_name)
		--OR machine_name not in (select MCName from #GetGDIC_planTC_NEW ) 


		INSERT INTO [DBxDW].[dbo].[scheduler_temp] select distinct * from #Result where lot_no NOT IN (select lot_no from #tempLotInMC)

		--select * from #tempSetupMc_RANK

		--select * from #scheduler_temp_WIP where lot_no = '2219A1003V'


		--select * from #getWIPData_New where lot_no = '2219A1003V'


	








drop table #getLotInMC
drop table #getWIPData
drop table #tempMcTC
drop table #tempTypeSetup 
drop table #tempSetupMc
drop table #tempWIPData
drop table #tempMCSetDeivce
drop table #tempLotInMC
drop table #tempMCList
drop table #GetSchedulerSeq

drop table #GetGDIC_planTC_NEW
drop table #AlreadyUpdateGdic
drop table #getWIPData_New
drop table #scheduler_temp_TC
drop table #scheduler_temp_WIP
drop table #tempSetupMc_RANK
drop table #Result

END TRY
BEGIN CATCH
	ROLLBACK;
END CATCH
END
