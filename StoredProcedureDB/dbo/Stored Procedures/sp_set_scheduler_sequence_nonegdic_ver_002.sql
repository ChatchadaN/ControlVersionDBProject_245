-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_sequence_nonegdic_ver_002]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	DECLARE @PackageName varchar(MAX)
	--DECLARE @Shot_PackageName varchar(MAX)
SET @PackageName = 'HTQFP64AV,HTQFP64BV,HTQFP64V,HTQFP64V-HF,HTQFP64VHF,QFP32,QFP32R,UQFP64,UQFP64M,VQFP48C,VQFP48CM,VQFP48CR,VQFP64,' +
					'VQFP64F,VQFP64M,SQFP-T52,SQFP-T52M,MSOP8,MSOP8-HF,HSON-A8,MSOP10,HSON8,HSON8-HF,HRP5,HRP7,TO252-3,TO252-5,TO252-J3,TO252-J5,' +
					'TO220-7M,TO263-3,TO263-5,TO263-7,TO252S-5+,TO252S-7+,SIP9,TO252S-3,TO252S-5,TO252-J5F,SOT223-4,SOT223-4F,TO263-3F,TO263-5F,TO220-6M,HTSSOP-C64A,' +
					'SSOP-B20W,TSSOP-C48VM,HSSOP-C16,SSOP-A26_20,SSOP-A54_23,SSOP-A54_36,SSOP-A54_42,SOP20,SOP22,SOP24,SOP24-HF,' +
					'SSOP-A20,SSOP-A24,SSOP-A32,SSOP-B40,SSOP-B24,SSOP-B28,TSSOP-B30,HSOP-M36,SSOP-A44,TSSOP-C44,HTSSOP-C48,HTSSOP-C48R,TSSOP-C48V,HTSSOP-C64,' +
					'HTSSOP-A44,HTSSOP-A44R,HTSSOP-B54,HTSSOP-B54R,HTSSOP-B20,HTSSOP-B40,TSSOP-B8J,HTQFP64BVE,HTSSOPB20E,HTSSOPC48E'

BEGIN TRANSACTION
BEGIN Try

DELETE Temp FROM DBxDW.dbo.[scheduler_temp] as Temp
inner join APCSProDB.method.device_names as deivce on deivce.ft_name COLLATE SQL_Latin1_General_CP1_CI_AS = Temp.ft_device
WHERE package_name  in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) and (deivce.alias_package_group_id != 33 or deivce.alias_package_group_id is null)

DELETE FROM DBxDW.dbo.[scheduler_temp] WHERE package_name  in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) AND machine_name = lot_no
and package_name <> 'SSOP-B20W'

--Delete type change
DELETE Temp FROM DBxDW.dbo.[scheduler_temp] as Temp
LEFT join APCSProDB.method.device_names as deivce on deivce.name COLLATE SQL_Latin1_General_CP1_CI_AS = Temp.ft_device
WHERE package_name  in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) and (deivce.alias_package_group_id != 33 or deivce.alias_package_group_id is null) AND LEN(Temp.lot_no) < 10


CREATE TABLE #scheduler_temp
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




SELECT DISTINCT [FTSetupReport].[MCNo], Mc.id as McId, Rate.oprate, Rate.setupid, LotNo, PackageName, DeviceName, TesterType, TestFlow
				, case when [State].run_state = 0 THEN 'Ready'
						when [State].run_state = 1 THEN 'Idle'
						when [State].run_state = 2 THEN 'Setup'
						when [State].run_state = 3 THEN 'Ready'
						when [State].run_state = 4 THEN 'Run'
						when [State].run_state = 10 THEN 'PlanStop' 
					ELSE 'Wait' END as [Status] 
		
		,(select top 1 (SELECT DATEADD(MINUTE, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))), max(lot_record.recorded_at))) AS LotEnd
			--, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))) as aaa
			from  [APCSProDB].trans.lot_process_records as lot_record 
			  inner join [APCSProDB].[trans].lots as lot  on lot.id = lot_record.lot_id
			  inner join [APCSProDB].[mc].[machines] as mc  on mc.id = lot.machine_id
			  inner join [APCSProDB] .[method].device_names as device  on lot.act_device_name_id = device.id 
			  inner join [APCSProDB].[method].[device_flows] as deviceflow  on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
			  where lot.act_job_id  in (106,108,110,119,155,50) and lot.process_state != 0  and lot.wip_state= 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 0
			  and mc.name = [FTSetupReport].[MCNo]
			  group by lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
			  ,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in) AS LotEnd
		,'0' as DelayLot INTO #tempSetupMc
		FROM [DBx].[dbo].[FTSetupReport] 
		inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
		left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
		left join APCSProDB.trans.machine_states as [State] on Mc.id = State.machine_id
		INNER JOIN APCSProDB.method.device_names as device on device.name COLLATE SQL_Latin1_General_CP1_CI_AS =  DeviceName
		Where PackageName in (SELECT short_name FROM APCSProDB.method.packages WHERE name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))) --shotname
		--and [FTSetupReport].[MCNo] not like '%-M-%'
		--and [FTSetupReport].[MCNo] not like '%ith%'
		and [FTSetupReport].[MCNo] not like 'FL%'
		and [FTSetupReport].[MCNo] not like '%FTTP%'
		and [FTSetupReport].[MCNo] not like '%-000'
		and [FTSetupReport].[MCNo] not like '%-000'
		--and [FTSetupReport].[MCNo] NOT IN ('FT-M-150','FT-M-167')
		and device.alias_package_group_id != 33
		and Mc.is_disabled = 0
		--select * from #tempSetupMc
		--drop TABLE #tempSetupMc
-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------


 
-- select * from #tempDeivceSet
--select '#tempDeivceSet complete'





CREATE TABLE #tempMCList
(
	RowIndex int,MCName Varchar(30),MC_ID int
)
CREATE TABLE #GetSchedulerSeq
(
	Seq_no int, MCName Varchar(30), Prioritys int,DeviceName_change varchar(30),DeviceName_Now varchar(30),DateSet Datetime,JobName_Af Varchar(20)
)
CREATE TABLE #GetNonGDIC_planTC_NEW
(
index_num int identity(1,1),Prioritys int,MCName Varchar(30),Seq_no int,
DeviceName_change varchar(30),DeviceName_Now varchar(30),DateSet Datetime,date_complete Datetime,mc_id int,flow_before Varchar(MAX),flow_after Varchar(MAX)
)

			
CREATE TABLE #scheduler_temp_TC_non
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


INSERT INTO #tempMCList
	select ROW_NUMBER() OVER(ORDER BY MCNo ASC), MCNo,McId from #tempSetupMc where PackageName in (SELECT short_name FROM APCSProDB.method.packages WHERE name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )))

INSERT INTO #GetNonGDIC_planTC_NEW
	SELECT * FROM DBx.dbo.scheduler_setup WHERE mc_id IN (select #tempMCList.MC_ID from #tempMCList) AND date_complete is null 


	Select TC.index_num,TC.MCName,TC.Seq_no,TC.DeviceName_change,TC.DeviceName_Now,TC.flow_after,TC.flow_before,CurMC.DeviceName,CurMC.TestFlow 
	INTO #AlreadyUpdate
	from #GetNonGDIC_planTC_NEW  as TC 
	inner join DBx.dbo.FTSetupReport as CurMC on TC.MCName = CurMC.MCNo
	where (CurMC.DeviceName = TC.DeviceName_change and CurMC.TestFlow = Tc.flow_after) OR (CurMC.DeviceName != TC.DeviceName_Now AND CurMC.DeviceName != TC.DeviceName_change)
	
	UPDATE DBx.dbo.scheduler_setup
	SET [date_complete] = GETDATE()
	FROM #AlreadyUpdate
	where  DBx.dbo.scheduler_setup.date_complete is null and  DBx.dbo.scheduler_setup.mc_no = #AlreadyUpdate.MCName

	DELETE DBxDW.dbo.[scheduler_temp] where lot_no COLLATE SQL_Latin1_General_CP1_CI_AS IN (select MCName from #AlreadyUpdate)

	INSERT INTO #scheduler_temp_TC_non
	Select distinct tc.MCName , tc.flow_after ,tc.DeviceName_change ,'','',tc.MCName,
	--tc.Seq_No as Seq_no 
	CASE 
		WHEN tc.Seq_no <= 2 THEN 2
		WHEN tc.Seq_no > 2 THEN 
		IIF(tc.Seq_no - (SELECT COUNT(1) FROM [APCSProDB].[trans].[lot_process_records] with(NOLOCK) where record_class = 2 and recorded_at >= TC.DateSet and [lot_process_records].machine_id = TC.mc_id and 
		day_id > 2500 and [lot_process_records].recorded_at > dateadd(day, -50, getdate())) < 2,
		2 ,
		tc.Seq_no - (SELECT COUNT(1) FROM [APCSProDB].[trans].[lot_process_records] with(NOLOCK) where record_class = 2 and recorded_at >= TC.DateSet and [lot_process_records].machine_id = TC.mc_id and 
		day_id > 2500 and [lot_process_records].recorded_at > dateadd(day, -50, getdate()))) END AS seq_no
	, pk.name,NULL,NULL
	from #GetNonGDIC_planTC_NEW  as TC 
	inner join DBx.dbo.FTSetupReport as CurMC on TC.MCName = CurMC.MCNo
	INNER JOIN APCSProDB.method.device_names as dv on dv.name = TC.DeviceName_change
	INNER JOIN APCSProDB.method.packages as pk on pk.id = dv.package_id
	where TC.MCName NOT IN (select MCName from #AlreadyUpdate )


	DELETE DBxDW.dbo.[scheduler_temp] where lot_no COLLATE SQL_Latin1_General_CP1_CI_AS IN (select lot_no from #scheduler_temp_TC_non)

	insert into DBxDW.dbo.[scheduler_temp] select * from #scheduler_temp_TC_non


---------------------------END OF TYPE CHANGE PROCEDURE---------------------------
			
			


-------------------------START QUEUING PROCEDURE------------------------------------

CREATE TABLE #tempTypeSetup
(
    index_num int identity(1,1) primary key,DeivceName varchar(30),Flow varchar(50),
)

	INSERT INTO #tempTypeSetup
SELECT Distinct ftsetup.DeviceName,ftsetup.TestFlow
FROM #tempSetupMc as ftsetup
WHERE ftsetup.PackageName in (SELECT short_name FROM APCSProDB.method.packages WHERE name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))) 
		and ftsetup.[MCNo] not like '%-000'
		--and ftsetup.[MCNo] not like '%-099%'




CREATE TABLE #tempLotInMC
(
	RowIndex int,DeviceName varchar(30),FTDeviceName varchar(30),LotNo varchar(10),MCName varchar(11),JobName Varchar(20), StartLot datetime,EndLot datetime 
	, Package varchar(30)
)

CREATE TABLE #tempWIPData
(
	RowIndex int, MCName varchar(11), lot_no varchar(10), DeviceName varchar(30), FTDeivceName varchar(20), PkgName varchar(15),JobName varchar(20),
	NextJobName varchar(20), Kpcs int , qty_production float, ProcessState int, StandardTime int, JobID int, UpdatedAt datetime, QualityState int,
	RackAddress varchar(10), RackName varchar(15)
)


CREATE TABLE #getLotInMC
			(
				RowIndex int IDENTITY(1,1) ,DeviceName varchar(30),FTDeviceName varchar(30),LotNo varchar(10)
				,MCName varchar(11),JobName Varchar(20), StartLot datetime,EndLot datetime , Package varchar(30)
			)
					insert #getLotInMC
			select distinct  device.name as DeviceName,device.ft_name as FTDevice, lot.lot_no,mc.name as McName,REPLACE(REPLACE(job.name,'(',''),')','') AS JobName
				, (SELECT DATEADD(MINUTE, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))), max(lot_record.recorded_at))) AS ENDTIME
				, max(lot_record.recorded_at) as STARTTIME
				, pk.name
			from  [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
			  inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id
			  INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lot.act_job_id
			  inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = lot.machine_id
			  INNER JOIN APCSProDB.method.packages as pk on pk.id = lot.act_package_id
			  inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
			  inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
			where lot.act_job_id  in (106,108,110,119,155,403,359,361,362,363,364,50) and lot.process_state in ( 2,102)  and lot.wip_state= 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 0
				and TRIM(pk.name) in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
				and device.alias_package_group_id != 33
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
			  inner join APCSProDB.trans.lot_special_flows as lotspecial with (NOLOCK) on lotspecial.special_flow_id = special.id  and special.step_no = lotspecial.step_no
			  inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
			  INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lotspecial.job_id
		  where lotspecial.job_id  in (106,108,110,119,155,403,359,361,362,363,364,50) and special.process_state in ( 2,102)  and lot.wip_state = 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 1 
				and TRIM(pk.name) in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
				and device.alias_package_group_id != 33 and special.wip_state = 20
		  group by  lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
				,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in,job.name,pk.name

				INSERT INTO [DBxDW].[dbo].[scheduler_temp] SELECT LotNo,JobName,FTDeviceName,'','',MCName,1,Package,StartLot,EndLot FROM #getLotInMC





----------------------------------- WIP DATA-----------------------------------
			
CREATE TABLE #tempWIPData_NonGdic
(
	lot_seq int,A int, MCName varchar(11), lot_no varchar(10), DeviceName varchar(30), FTDeivceName varchar(20), PkgName varchar(15),JobName varchar(20),
	NextJobName varchar(20), RackName varchar(15) ,rack_address varchar(15)
)

	INSERT INTO #tempWIPData_NonGdic
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
						WHEN jobs.name = 'OS+AUTO(1)' 
							THEN 'AUTO1'
						WHEN jobs.name = 'AUTO(1) RE'
							THEN 'AUTO1'
						--ELSE REPLACE(REPLACE(jobs.name,'(',''),')','')
						ELSE REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL','')
				  END as JobName --IIF(REPLACE(REPLACE(jobs.name,'(',''),')','') = 'OS+AUTO1','AUTO1',REPLACE(REPLACE(jobs.name,'(',''),')','')) as JobName
				, '' as NextJob
				, locations.name
				, locations.address
		FROM [APCSProDB].[trans].lots with (NOLOCK)
		INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		INNER JOIN [APCSProDB].method.jobs as jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = jobs.id 
		LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
		inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
		INNER join [APCSProDB].trans.locations as locations with (NOLOCK) on locations.id = lots.location_id 
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) 
		and is_special_flow = 0 and process_state in(0,100,1) and quality_state = 0
		and APCSProDB.method.device_names.alias_package_group_id != 33
		and [APCSProDB] .[method].device_names.name IN (select #tempTypeSetup.DeivceName from #tempTypeSetup)
		and CASE 
					WHEN jobs.name = 'OS+AUTO(1)' 
						THEN 'AUTO1'
					WHEN jobs.name = 'AUTO(1) RE' 
						THEN 'AUTO1'
					--ELSE REPLACE(REPLACE(jobs.name,'(',''),')','')
					ELSE REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL','')
					END  IN (select distinct Flow from #tempTypeSetup)
		) AS A
		--and IIF(REPLACE(REPLACE(jobs.name,'(',''),')','') = 'OS+AUTO1','AUTO1',REPLACE(REPLACE(jobs.name,'(',''),')','')) in(select distinct Flow from #tempTypeSetup)
	UNION ALL
		SELECT ROW_NUMBER() OVER(ORDER BY lot_no ASC) AS B,* FROM (
		SELECT DISTINCT 
			 [APCSProDB].[mc].[machines].name AS MCName
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS DeviceName 
			, [APCSProDB].[method].device_names.ft_name AS FTDevice
			, [APCSProDB].[method].[packages].name AS MethodPkgName
			, CASE 
					WHEN jobs.name = 'OS+AUTO(1)' 
						THEN 'AUTO1'
					WHEN jobs.name = 'AUTO(1) RE'
						THEN 'AUTO1'
					--ELSE REPLACE(REPLACE(jobs.name,'(',''),')','')
					ELSE REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL','')
			  END as JobName --IIF(REPLACE(REPLACE(jobs.name,'(',''),')','') = 'OS+AUTO1','AUTO1',REPLACE(REPLACE(jobs.name,'(',''),')','')) as JobName
			, lots.act_job_id as NextJob
			, locations.name
			, locations.address
		FROM [APCSProDB].[trans].lots 
		INNER JOIN [APCSProDB].[method].packages  ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		--INNER JOIN [APCSProDB].method.jobs ON [APCSProDB].trans.lots.act_job_id = [APCSProDB].method.jobs.id
		inner join APCSProDB.trans.special_flows as special on lots.special_flow_id = special.id
		inner join APCSProDB.trans.lot_special_flows as lotspecial  on lotspecial.special_flow_id = special.id and special.step_no = lotspecial.step_no
		LEFT JOIN [APCSProDB].mc.machines  ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNER JOIN [APCSProDB].method.jobs as jobs  ON  jobs.id = lotspecial.job_id
		INNer Join [APCSProDB] .[method].device_names  on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
		inner join [APCSProDB].method.device_flows  on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	
		INNER join [APCSProDB].trans.locations as locations  on locations.id = lots.location_id 
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))  
		and lotspecial.job_id in(119,110,108,106,263,155,403,359,361,362,363,364,50) and lots.is_special_flow = 1 and lots.process_state in(0,100,1) and lots.quality_state in (0,4)
		and special.process_state in (0,100,1)
		and APCSProDB.method.device_names.alias_package_group_id != 33
		and [APCSProDB] .[method].device_names.name IN (select #tempTypeSetup.DeivceName from #tempTypeSetup )
		and CASE 
				WHEN jobs.name = 'OS+AUTO(1)' 
					THEN 'AUTO1'
				WHEN jobs.name = 'AUTO(1) RE' 
					THEN 'AUTO1'
				--ELSE REPLACE(REPLACE(jobs.name,'(',''),')','')
				ELSE REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL','')
				END  IN (select distinct Flow from #tempTypeSetup)
		--and IIF(REPLACE(REPLACE(jobs.name,'(',''),')','') = 'OS+AUTO1','AUTO1',REPLACE(REPLACE(jobs.name,'(',''),')','')) in(select distinct Flow from #tempTypeSetup)
		) AS C 
		) AS D
		where  lot_no not in (select LotNo from #getLotInMC)



		
CREATE TABLE #tempSetupMc_RANK
(
     Seq_MC int,MCNo varchar(30) primary key , McId int, OpRate real, SetupId int, LotNo varchar(10), PackageName varchar(30), DeviceName varchar(30)
	, TesterType varchar(30),TestFlow varchar(50),[Status] varchar(20),LotEnd Datetime,DelayLot varchar(1)
)

	INSERT INTO #tempSetupMc_RANK
	select RANK() OVER(PARTITION BY DeviceName,TestFlow ORDER BY LotEnd,McId ASC) as Seq_MC, * from #tempSetupMc

	INSERT INTO #scheduler_temp
	SELECT TB_LotWip.lot_no,TB_LotWip.JobName,TB_LotWip.FTDeivceName,TB_LotWip.rack_address,TB_LotWip.RackName,mc.MCNo as machine_name,TB_LotWip.lot_seq_onMC+1 as seq_no,TB_LotWip.PkgName,NULL as lot_end,NULL as lot_start
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
		, lot_seq,lot_no,DeviceName,JobName,FTDeivceName,rack_address,RackName,PkgName

		from #tempWIPData_NonGdic as B) AS TB
		) AS TB_LotWip ON TB_LotWip.Index_point_mc = mc.Seq_MC AND TB_LotWip.DeviceName = mc.DeviceName AND TB_LotWip.JobName = TestFlow  order by TB_LotWip.DeviceName,lot_seq


		select * INTO #Result from #scheduler_temp as outerTB where seq_no <= (select seq_no from #scheduler_temp as innerTB where innerTB.lot_no = outerTB.machine_name)
		OR machine_name not in (select MCName from #GetNonGDIC_planTC_NEW ) 

		INSERT INTO #Result select WIP.* from #scheduler_temp as WIP  inner join #scheduler_temp_TC_non on WIP.machine_name = #scheduler_temp_TC_non.machine_name and WIP.seq_no < #scheduler_temp_TC_non.seq_no


		INSERT INTO [DBxDW].[dbo].[scheduler_temp] select * from #Result where lot_no NOT IN (select lot_no from #tempLotInMC)






















		drop table #getLotInMC
		drop table #tempTypeSetup 
		drop table #tempSetupMc
		drop table #tempWIPData
		drop table #tempLotInMC
		drop table #GetSchedulerSeq
		drop table #tempMCList
		drop table #GetNonGDIC_planTC_NEW
		drop table #Result
		drop table #scheduler_temp
		drop table #tempSetupMc_RANK
		drop table #tempWIPData_NonGdic
		drop table #AlreadyUpdate
		drop table #scheduler_temp_TC_non
		COMMIT;
END TRY
BEGIN CATCH
	ROLLBACK;
END CATCH
END
