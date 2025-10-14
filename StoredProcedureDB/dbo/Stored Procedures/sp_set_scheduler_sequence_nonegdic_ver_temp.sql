-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_sequence_nonegdic_ver_temp]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	----** add status rack 2023-03-09
	DECLARE @PackageName varchar(MAX)
	--DECLARE @Shot_PackageName varchar(MAX)
	SET @PackageName = 'HTQFP64AV,HTQFP64BV,HTQFP64V,HTQFP64V-HF,HTQFP64VHF,QFP32,QFP32R,UQFP64,UQFP64M,VQFP48C,VQFP48CM,VQFP48CR,VQFP64,' +
					'VQFP64F,VQFP64M,SQFP-T52,SQFP-T52M,MSOP8,MSOP8-HF,HSON-A8,MSOP10,HSON8,HSON8-HF,HRP5,HRP7,TO252-3,TO252-5,TO252-J3,TO252-J5,' +
					'TO220-7M,TO263-3,TO263-5,TO263-7,TO252S-5+,TO252S-7+,SIP9,TO252S-3,TO252S-5,TO252-J5F,SOT223-4,SOT223-4F,TO263-3F,TO263-5F,TO220-6M,HTSSOP-C64A,' +
					'SSOP-B20W,TSSOP-C48VM,HSSOP-C16,SSOP-A26_20,SSOP-A54_23,SSOP-A54_36,SSOP-A54_42,SOP20,SOP22,SOP24,SOP24-HF,' +
					'SSOP-A20,SSOP-A24,SSOP-A32,SSOP-B40,SSOP-B24,SSOP-B28,TSSOP-B30,HSOP-M36,SSOP-A44,TSSOP-C44,HTSSOP-C48,HTSSOP-C48R,TSSOP-C48V,HTSSOP-C64,' +
					'HTSSOP-A44,HTSSOP-A44R,HTSSOP-B54,HTSSOP-B54R,HTSSOP-B20,HTSSOP-B40,TSSOP-B8J,HTQFP64BVE,HTSSOPB20E,HTSSOPC48E,HTSOPC48XR,MSOP8E-HF,TO263-7L,HTSSOPB20X'

BEGIN TRANSACTION
BEGIN Try

	--Clear Next lot
	IF EXISTS(
		SELECT 1 
		FROM APCSProDB.trans.machine_states
		INNER JOIN APCSProDB.trans.lots ON machine_states.next_lot_id = lots.id
		INNER JOIN APCSProDB.mc.machines ON machine_states.machine_id = machines.id
		INNER JOIN DBx.dbo.FTSetupReport ON machines.name = FTSetupReport.MCNo
		INNER JOIN APCSProDB.method.packages ON lots.act_package_id = packages.id
		LEFT JOIN APCSProDB.trans.special_flows ON lots.is_special_flow = 1
			AND lots.id = special_flows.lot_id

		LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id		
		
		LEFT JOIN APCSProDB.trans.lot_special_flows ON lot_special_flows.special_flow_id = lots.special_flow_id
		WHERE machines.name like 'FT%'
		AND PackageName in (SELECT value FROM STRING_SPLIT(@PackageName, ','))
		AND (ISNULL(special_flows.quality_state,lots.quality_state) != 0 
			OR FTSetupReport.SetupStatus = 'POWEROFF' OR lots.location_id IS NULL
			OR ISNULL(rack_addresses.[status] ,0) != 1 )
		AND FTSetupReport.SetupStatus != 'GOODNGTEST'
		AND lot_special_flows.job_id NOT IN (378, 365, 366, 367, 385) 
	)
	BEGIN
		PRINT 'CLEAR Next_lot in Machine_state'

		UPDATE machine_states
		SET next_lot_id = NULL
		FROM APCSProDB.trans.machine_states
		INNER JOIN APCSProDB.trans.lots ON machine_states.next_lot_id = lots.id
		INNER JOIN APCSProDB.mc.machines ON machine_states.machine_id = machines.id
		INNER JOIN DBx.dbo.FTSetupReport ON machines.name = FTSetupReport.MCNo
		INNER JOIN APCSProDB.method.packages ON lots.act_package_id = packages.id
		LEFT JOIN APCSProDB.trans.special_flows ON lots.is_special_flow = 1
			AND lots.id = special_flows.lot_id

		LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id		

		LEFT JOIN APCSProDB.trans.lot_special_flows ON lot_special_flows.special_flow_id = lots.special_flow_id
		WHERE machines.name like 'FT%'
		AND PackageName in (SELECT value FROM STRING_SPLIT(@PackageName, ','))
		AND (ISNULL(special_flows.quality_state,lots.quality_state) != 0 
			OR FTSetupReport.SetupStatus = 'POWEROFF' OR lots.location_id IS NULL
			OR ISNULL(rack_addresses.[status] ,0) != 1 )
		AND FTSetupReport.SetupStatus != 'GOODNGTEST'
		AND lot_special_flows.job_id NOT IN (378, 365, 366, 367, 385) 
	END


	DELETE Temp FROM DBxDW.dbo.[scheduler_temp_01] as Temp
	inner join APCSProDB.method.device_names as deivce on deivce.ft_name COLLATE SQL_Latin1_General_CP1_CI_AS = Temp.ft_device
	WHERE package_name  in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) and (deivce.alias_package_group_id != 33 or deivce.alias_package_group_id is null)
	
	DELETE FROM DBxDW.dbo.[scheduler_temp_01] WHERE package_name  in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) AND machine_name = lot_no
	and package_name <> 'SSOP-B20W'
	
	--Delete type change
	DELETE Temp FROM DBxDW.dbo.[scheduler_temp_01] as Temp
	LEFT join APCSProDB.method.device_names as deivce on deivce.name COLLATE SQL_Latin1_General_CP1_CI_AS = Temp.ft_device
	WHERE package_name  in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) and (deivce.alias_package_group_id != 33 or deivce.alias_package_group_id is null) AND LEN(Temp.lot_no) < 10


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
		,'0' as DelayLot 
		
		INTO #tempSetupMc

		FROM [DBx].[dbo].[FTSetupReport] 
		inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
		left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
		left join APCSProDB.trans.machine_states as [State] on Mc.id = State.machine_id
		INNER JOIN APCSProDB.method.device_names as device on device.name COLLATE SQL_Latin1_General_CP1_CI_AS =  DeviceName
		Where PackageName in (SELECT short_name FROM APCSProDB.method.packages WHERE name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))) --shotname
		--Where PackageName in (SELECT CASE WHEN short_name IN ( 'TO252','SSOP-A54_3','HTSSOPC48R') THEN name ELSE short_name END AS short_name  FROM APCSProDB.method.packages WHERE name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))) --shotname
		--and [FTSetupReport].[MCNo] not like '%-M-%'
		--and [FTSetupReport].[MCNo] not like '%ith%'
		and [FTSetupReport].[MCNo] not like 'FL%'
		and [FTSetupReport].[MCNo] not like '%FTTP%'
		and [FTSetupReport].[MCNo] not like '%-000'
		and [FTSetupReport].[MCNo] not like '%-000'
		--and [FTSetupReport].[MCNo] NOT IN ('FT-M-150','FT-M-167')
		and device.alias_package_group_id != 33
		and Mc.is_disabled = 0
		and [State].online_state = 1
		and [FTSetupReport].[SetupStatus] = 'CONFIRMED'
		and Mc.cell_ip is not null

	--select * from #tempSetupMc
	--drop TABLE #tempSetupMc	
	-- select * from #tempDeivceSet
	--select '#tempDeivceSet complete'


	-----------------------------------------------------------------------------------------------------------------------------------------------
	--INSERT TYPE CHANGE

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
	--select ROW_NUMBER() OVER(ORDER BY MCNo ASC), MCNo,McId from #tempSetupMc where PackageName in (SELECT CASE WHEN short_name IN ( 'TO252','SSOP-A54_3','HTSSOPC48R') THEN name ELSE short_name END AS short_name FROM APCSProDB.method.packages WHERE name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )))
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

	DELETE DBxDW.dbo.[scheduler_temp_01] where lot_no COLLATE SQL_Latin1_General_CP1_CI_AS IN (select MCName from #AlreadyUpdate)

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


	DELETE DBxDW.dbo.[scheduler_temp_01] where lot_no COLLATE SQL_Latin1_General_CP1_CI_AS IN (select lot_no from #scheduler_temp_TC_non)

	insert into DBxDW.dbo.[scheduler_temp_01] select * from #scheduler_temp_TC_non

	-----------------------------------------------------------------------------------------------------------------------------------------------
	
	CREATE TABLE #tempTypeSetup
	(
		index_num int identity(1,1) primary key,DeivceName varchar(30),Flow varchar(50)
	)

	INSERT INTO #tempTypeSetup
	SELECT Distinct ftsetup.DeviceName,ftsetup.TestFlow
	FROM #tempSetupMc as ftsetup
	WHERE ftsetup.PackageName in (SELECT short_name  FROM APCSProDB.method.packages WHERE name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))) 
	and ftsetup.[MCNo] not like '%-000'
	--WHERE ftsetup.PackageName in (SELECT CASE WHEN short_name IN ( 'TO252','SSOP-A54_3','HTSSOPC48R') THEN name ELSE short_name END AS short_name  FROM APCSProDB.method.packages WHERE name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))) 
	--and ftsetup.[MCNo] not like '%-099%'

	-----------------------------------------------------------------------------------------------------------------------------------------------
	--GET LOT in MC

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

	INSERT #getLotInMC
	SELECT distinct  device.name as DeviceName
		, device.ft_name as FTDevice
		, lot.lot_no
		, mc.name as McName
		, CASE 
			WHEN job.name = 'OS+AUTO(1)SBLSYL'	 THEN 'AUTO1'
			WHEN job.name = 'OS+AUTO(1)'		THEN 'AUTO1'
			WHEN job.name = 'OS+AUTO(2)'		THEN 'AUTO2'
			WHEN job.name = 'OS+AUTO(1) HV'		THEN 'AUTO1'
			WHEN job.name = 'AUTO(1) RE'		THEN 'AUTO1'
			WHEN job.name = 'AUTO(1) HV'		THEN 'AUTO1'
			WHEN job.name LIKE '%SBLSYL%' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL',''))
			--WHEN job.name LIKE '%ASISAMPLE%' 
			--	THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'ASISAMPLE',''))
			WHEN job.name LIKE '%BIN27' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'BIN27',''))
			WHEN job.name LIKE '%BIN27-CF' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'BIN27-CF',''))
			ELSE REPLACE(REPLACE(job.name,'(',''),')','')
		END AS JobName
		, (SELECT DATEADD(MINUTE, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))), max(lot_record.recorded_at))) AS ENDTIME
		, max(lot_record.recorded_at) as STARTTIME
		, pk.name
	FROM [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
		inner join [APCSProDB].[trans].lots as lot with (NOLOCK) on lot.id = lot_record.lot_id
		INNER JOIN [APCSProDB].method.jobs as job with (NOLOCK) ON  job.id = lot.act_job_id
		inner join [APCSProDB].[mc].[machines] as mc with (NOLOCK) on mc.id = lot.machine_id
		INNER JOIN APCSProDB.method.packages as pk on pk.id = lot.act_package_id
		inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lot.act_device_name_id = device.id 
		inner join [APCSProDB].[method].[device_flows] as deviceflow with (NOLOCK) on deviceflow.device_slip_id = lot.device_slip_id and deviceflow.step_no = lot.step_no
	WHERE lot.act_job_id  in (106,108,110,119,155,403,359,361,362,363,364,50) and lot.process_state in ( 2,102)  and lot.wip_state= 20 and lot_record.record_class in (1,5) and lot.is_special_flow = 0
		and TRIM(pk.name) in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
		and device.alias_package_group_id != 33
	group by lot.lot_no,lot.process_state,mc.name,lot.id,device.name,device.ft_name
		,deviceflow.process_minutes,lot.is_special_flow,device.official_number,lot.qty_in,job.name,pk.name

	UNION ALL

	select device.name as DeviceName
		, device.ft_name as FTDevice
		, lot.lot_no
		, mc.name as McName
		, CASE 
			WHEN job.name = 'OS+AUTO(1)SBLSYL'	 THEN 'AUTO1'
			WHEN job.name = 'OS+AUTO(1)'		THEN 'AUTO1'
			WHEN job.name = 'OS+AUTO(2)'		THEN 'AUTO2'
			WHEN job.name = 'OS+AUTO(1) HV'		THEN 'AUTO1'
			WHEN job.name = 'AUTO(1) RE'		THEN 'AUTO1'
			WHEN job.name = 'AUTO(1) HV'		THEN 'AUTO1'
			WHEN job.name LIKE '%SBLSYL%' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'SBLSYL',''))
			--WHEN job.name LIKE '%ASISAMPLE%' 
			--	THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'ASISAMPLE',''))
			WHEN job.name LIKE '%BIN27' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'BIN27',''))
			WHEN job.name LIKE '%BIN27-CF' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(job.name,'(',''),')',''),'BIN27-CF',''))
			ELSE REPLACE(REPLACE(job.name,'(',''),')','')
		END AS JobName
		, max(lot_record.recorded_at) as STARTTIME
		, (SELECT DATEADD(MINUTE, (deviceflow.process_minutes*(CAST(lot.qty_in AS float)/CAST(device.official_number AS float))), max(lot_record.recorded_at))) AS ENDTIME
		, pk.name
	from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
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

	INSERT INTO [DBxDW].[dbo].[scheduler_temp_01] SELECT LotNo,JobName,FTDeviceName,'','',MCName,1,Package,StartLot,EndLot FROM #getLotInMC

	-----------------------------------------------------------------------------------------------------------------------------------------------	
	--Get MC with Flow
	CREATE TABLE #MachineFlowMapTable_nongdic
	(
		MCName varchar(50),
		Flow varchar(50)
	)

	INSERT INTO #MachineFlowMapTable_nongdic  
	SELECT DISTINCT [FTSetupReport].[MCNo]
	, TestFlow
	FROM [DBx].[dbo].[FTSetupReport]
	WHERE [FTSetupReport].[MCNo] like 'FT%'

	-----------------------------------------------------------------------------------------------------------------------------------------------	
	--Get Next Lots 2

	CREATE TABLE #LockedNextLots_nongdic
	(
		lot_no varchar(10),
		JobName varchar(50),
		FTDeivceName varchar(50),
		rack_address varchar(50),
		RackName varchar(50),
		machine_name varchar(30),
		seq_no int,
		PkgName varchar(30),
		lot_end datetime,
		lot_start datetime
	)

	INSERT INTO #LockedNextLots_nongdic
	SELECT DISTINCT  
		lots.lot_no
		, CASE 
			WHEN Job.name = 'OS+AUTO(1)SBLSYL'	THEN 'AUTO1'
			WHEN Job.name = 'OS+AUTO(1)'		THEN 'AUTO1'
			WHEN Job.name = 'OS+AUTO(2)'		THEN 'AUTO2'
			WHEN Job.name = 'OS+AUTO(1) HV'		THEN 'AUTO1'
			WHEN Job.name = 'AUTO(1) RE'		THEN 'AUTO1'
			WHEN Job.name = 'AUTO(1) HV'		THEN 'AUTO1'
			WHEN Job.name LIKE '%SBLSYL%' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'SBLSYL',''))
			--WHEN Job.name LIKE '%ASISAMPLE%' 
			--	THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'ASISAMPLE',''))
			WHEN Job.name LIKE '%BIN27' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'BIN27',''))
			WHEN Job.name LIKE '%BIN27-CF' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'BIN27-CF',''))
			ELSE REPLACE(REPLACE(Job.name,'(',''),')','')
		END AS JobName
		, ft_name as FTDeivceName

		, ISNULL(rack_addresses.address,'Setup') as rack_address
		, rack_controls.name as RackName

		,  Machine_table.name as machine_name
		, 2 as seq_no
		, Package.name as PkgName
		, NULL as lot_end
		, NULL as lot_start	
	FROM [APCSProDB].[trans].[machine_states] as machine_state 
		inner join APCSProDB.mc.machines as Machine_table  on machine_id = Machine_table.id
		inner join APCSProDB.trans.lots as lots  on lots.id = machine_state.next_lot_id
		inner join APCSProDB.method.packages as Package  on lots.act_package_id = Package.id
		inner join APCSProDB.method.device_names as deivce  on lots.act_device_name_id = deivce.id

		LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
		
		inner join APCSProDB.method.device_flows as flow on lots.device_slip_id = flow.device_slip_id and lots.step_no = flow.step_no
		inner join APCSProDB.method.processes as process on lots.act_process_id = process.id
		inner join APCSProDB.method.jobs as Job  on lots.act_job_id = job.id
		LEFT JOIN [DBx].[dbo].[FTSetupReport] AS SetupReport ON Machine_table.name = SetupReport.MCNo 

	where ((lots.process_state in (0,100) and lots.location_id is not null) or (lots.process_state in (1,101)))
		and lots.wip_state = 20 
		and TRIM(Package.name) in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
		and Machine_table.name LIKE '%FT%'

		and rack_addresses.[status] = 1

		and SetupReport.SetupStatus != 'POWEROFF'
		and lots.is_special_flow = 0
		and lots.quality_state != 3 --(HOLD)
		and CASE 
				WHEN Job.name = 'OS+AUTO(1)SBLSYL'	THEN 'AUTO1'
				WHEN Job.name = 'OS+AUTO(1)'		THEN 'AUTO1'
				WHEN Job.name = 'OS+AUTO(2)'		THEN 'AUTO2'
				WHEN Job.name = 'AUTO(1) RE'		THEN 'AUTO1'
				WHEN Job.name = 'OS+AUTO(1) HV'		THEN 'AUTO1'
				WHEN Job.name = 'AUTO(1) HV'		THEN 'AUTO1'
				--WHEN Job.name LIKE '%ASISAMPLE%' 
				--	THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'ASISAMPLE',''))
				WHEN Job.name LIKE '%BIN27' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'BIN27',''))
				WHEN Job.name LIKE '%BIN27-CF' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'BIN27-CF',''))
			ELSE REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'SBLSYL','')
			END  IN (select distinct Flow from #tempTypeSetup)
		--and Machine_table.name <> 'FT-RAS-004'
		and deivce.alias_package_group_id != 33
		and Machine_table.name IN (
        SELECT MCName 
        FROM #MachineFlowMapTable_nongdic
        WHERE Flow = CASE 
						WHEN Job.name = 'OS+AUTO(1)SBLSYL'	THEN 'AUTO1'
						WHEN Job.name = 'OS+AUTO(1)'		THEN 'AUTO1'
						WHEN Job.name = 'OS+AUTO(2)'		THEN 'AUTO2'
						WHEN Job.name = 'AUTO(1) RE'		THEN 'AUTO1'
						WHEN Job.name = 'OS+AUTO(1) HV'		THEN 'AUTO1'
						WHEN Job.name = 'AUTO(1) HV'		THEN 'AUTO1'
						--WHEN Job.name LIKE '%ASISAMPLE%' 
						--	THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'ASISAMPLE',''))
						WHEN Job.name LIKE '%BIN27' 
							THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'BIN27',''))
						WHEN Job.name LIKE '%BIN27-CF' 
							THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'BIN27-CF',''))
						ELSE REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'SBLSYL','')
                  END
		)

	UNION ALL

	SELECT DISTINCT  
		lots.lot_no
		, CASE 
			WHEN Job.name = 'OS+AUTO(1)SBLSYL'	THEN 'AUTO1'
			WHEN Job.name = 'OS+AUTO(1)'		THEN 'AUTO1'
			WHEN Job.name = 'OS+AUTO(2)'		THEN 'AUTO2'
			WHEN Job.name = 'OS+AUTO(1) HV'		THEN 'AUTO1'
			WHEN Job.name = 'AUTO(1) RE'		THEN 'AUTO1'
			WHEN Job.name = 'AUTO(1) HV'		THEN 'AUTO1'
			WHEN Job.name LIKE '%SBLSYL%' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'SBLSYL',''))
			--WHEN Job.name LIKE '%ASISAMPLE%' 
			--	THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'ASISAMPLE',''))
			WHEN Job.name LIKE '%BIN27' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'BIN27',''))
			WHEN Job.name LIKE '%BIN27-CF' 
				THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'BIN27-CF',''))
			ELSE REPLACE(REPLACE(job.name,'(',''),')','')
		END as JobName
		, ft_name as FTDeivceName
		
		, ISNULL(rack_addresses.address,'Setup') as rack_address
		, rack_controls.name as RackName
		
		,  Machine_table.name as machine_name
		, 2 as seq_no
		, Package.name as PkgName
		, NULL as lot_end
		, NULL as lot_start	
	FROM [APCSProDB].[trans].[machine_states] as machine_state 
		inner join APCSProDB.mc.machines as Machine_table  on machine_id = Machine_table.id
		inner join APCSProDB.trans.lots as lots  on lots.id = machine_state.next_lot_id
		inner join APCSProDB.method.packages as Package  on lots.act_package_id = Package.id
		inner join APCSProDB.method.device_names as deivce  on lots.act_device_name_id = deivce.id

		LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id

		inner join APCSProDB.method.device_flows as flow on lots.device_slip_id = flow.device_slip_id and lots.step_no = flow.step_no
		inner join APCSProDB.method.processes as process on lots.act_process_id = process.id
		inner join APCSProDB.method.jobs as Job  on lots.act_job_id = job.id
		
		inner join APCSProDB.trans.special_flows as special on lots.special_flow_id = special.lot_id
		inner join APCSProDB.trans.lot_special_flows as lotspecial on lotspecial.special_flow_id = special.id  
		LEFT JOIN [DBx].[dbo].[FTSetupReport] AS SetupReport ON Machine_table.name = SetupReport.MCNo 

	where ((special.process_state in (0,100) and lots.location_id is not null) or (special.process_state in (1,101)))
		and special.wip_state = 20 
		and TRIM(Package.name) in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))
		and Machine_table.name LIKE '%FT%'

		and rack_addresses.[status] = 1
		
		and SetupReport.SetupStatus != 'POWEROFF'
		and lots.is_special_flow = 1
		and lots.quality_state != 3 --(HOLD)
		and CASE 
				WHEN Job.name = 'OS+AUTO(1)SBLSYL' THEN 'AUTO1'
				WHEN Job.name = 'OS+AUTO(1)'		THEN 'AUTO1'
				WHEN Job.name = 'OS+AUTO(2)'		THEN 'AUTO2'
				WHEN Job.name = 'AUTO(1) RE'		THEN 'AUTO1'
				WHEN Job.name = 'OS+AUTO(1) HV'		THEN 'AUTO1'
				WHEN Job.name = 'AUTO(1) HV'		THEN 'AUTO1'
				--WHEN Job.name LIKE '%ASISAMPLE%' 
				--	THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'ASISAMPLE',''))
				WHEN Job.name LIKE '%BIN27' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'BIN27',''))
				WHEN Job.name LIKE '%BIN27-CF' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'BIN27-CF',''))
				ELSE REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'SBLSYL','')
			END IN (select distinct Flow from #tempTypeSetup)
		--and Machine_table.name <> 'FT-RAS-004'
		and deivce.alias_package_group_id != 33
		and Machine_table.name IN (
        SELECT MCName 
        FROM #MachineFlowMapTable_nongdic
        WHERE Flow = CASE 
						WHEN Job.name = 'OS+AUTO(1)SBLSYL' THEN 'AUTO1'
						WHEN Job.name = 'OS+AUTO(1)'		THEN 'AUTO1'
						WHEN Job.name = 'OS+AUTO(2)'		THEN 'AUTO2'
						WHEN Job.name = 'AUTO(1) RE'		THEN 'AUTO1'
						WHEN Job.name = 'OS+AUTO(1) HV'		THEN 'AUTO1'
						WHEN Job.name = 'AUTO(1) HV'		THEN 'AUTO1'
						--WHEN Job.name LIKE '%ASISAMPLE%' 
						--	THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'ASISAMPLE',''))
						WHEN Job.name LIKE '%BIN27' 
							THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'BIN27',''))
						WHEN Job.name LIKE '%BIN27-CF' 
							THEN TRIM(REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'BIN27-CF',''))
						ELSE REPLACE(REPLACE(REPLACE(Job.name,'(',''),')',''),'SBLSYL','')
					END
		)


	CREATE TABLE #CountMc_nongdic (
		lot_no Varchar(20)
		, machine_count INT	
	)

	INSERT INTO #CountMc_nongdic
	SELECT lot_no, COUNT(DISTINCT machine_name) as count_mc FROM #LockedNextLots_nongdic
	GROUP BY lot_no

	IF EXISTS(SELECT 1 FROM #CountMc_nongdic WHERE machine_count > 1)
	BEGIN
		UPDATE machine_states
		SET next_lot_id = NULL
		FROM [APCSProDB].[trans].[machine_states]
		INNER JOIN #CountMc_nongdic AS mc_count ON [machine_states].next_lot_id = (SELECT id FROM APCSProDB.trans.lots WHERE lot_no = mc_count.lot_no)
		WHERE mc_count.machine_count > 1
	END

	--print 'START #LockedNextLots_nongdic_game'
	INSERT INTO [DBxDW].[dbo].[scheduler_temp_01] select * from #LockedNextLots_nongdic
	WHERE lot_no in (SELECT lot_no FROM #CountMc_nongdic WHERE machine_count = 1)
	--print 'END #LockedNextLots_nongdic_game'
	-----------------------------------------------------------------------------------------------------------------------------------------------	
	--Get WIP
			
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
					WHEN jobs.name = 'OS+AUTO(1)SBLSYL' THEN 'AUTO1'
					WHEN jobs.name = 'OS+AUTO(1)'		THEN 'AUTO1'
					WHEN jobs.name = 'OS+AUTO(2)'		THEN 'AUTO2'
					WHEN jobs.name = 'AUTO(1) RE'		THEN 'AUTO1'
					WHEN jobs.name = 'OS+AUTO(1) HV'		THEN 'AUTO1'
					WHEN jobs.name = 'AUTO(1) HV'		THEN 'AUTO1'
					--WHEN jobs.name LIKE '%ASISAMPLE%' 
					--	THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'ASISAMPLE',''))
					WHEN jobs.name LIKE '%BIN27' 
						THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'BIN27',''))
					WHEN jobs.name LIKE '%BIN27-CF' 
						THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'BIN27-CF',''))
					ELSE REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL','')
				  END as JobName 
				, '' as NextJob
				, rack_addresses.address
				, rack_controls.name as rack_name

		FROM [APCSProDB].[trans].lots with (NOLOCK)
		INNER JOIN [APCSProDB].[method].packages with (NOLOCK) ON [APCSProDB].trans.lots.act_package_id = [APCSProDB].method.packages.id 
		INNER JOIN [APCSProDB].method.jobs as jobs with (NOLOCK) ON [APCSProDB].trans.lots.act_job_id = jobs.id 
		LEFT JOIN [APCSProDB].mc.machines with (NOLOCK) ON [APCSProDB].trans.lots.machine_id = [APCSProDB].mc.machines.id 
		INNer Join [APCSProDB] .[method].device_names with (NOLOCK) on [APCSProDB] .trans .lots .act_device_name_id = [APCSProDB] .[method].device_names.id 
		--inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = [APCSProDB] .[method].device_names.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
		inner join [APCSProDB].method.device_flows with (NOLOCK) on device_flows.device_slip_id = lots.device_slip_id and device_flows.step_no = lots.step_no	 
		
		LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
			
		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PackageName , ',' )) 
		and is_special_flow = 0 and process_state in(0,100,1) and quality_state = 0
		and APCSProDB.method.device_names.alias_package_group_id != 33
		and [APCSProDB] .[method].device_names.name IN (select #tempTypeSetup.DeivceName from #tempTypeSetup)
		and CASE 
				WHEN jobs.name = 'OS+AUTO(1)SBLSYL' THEN 'AUTO1'
				WHEN jobs.name = 'OS+AUTO(1)'		THEN 'AUTO1'
				WHEN jobs.name = 'OS+AUTO(2)'		THEN 'AUTO2'
				WHEN jobs.name = 'AUTO(1) RE'		THEN 'AUTO1'
				WHEN jobs.name = 'OS+AUTO(1) HV'		THEN 'AUTO1'
				WHEN jobs.name = 'AUTO(1) HV'		THEN 'AUTO1'
				--WHEN jobs.name LIKE '%ASISAMPLE%' 
				--	THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'ASISAMPLE',''))
				WHEN jobs.name LIKE '%BIN27' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'BIN27',''))
				WHEN jobs.name LIKE '%BIN27-CF' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'BIN27-CF',''))
				ELSE REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL','')
			END  IN (select distinct Flow from #tempTypeSetup)
		------------------------------------------------------------------------------------------------------------
		---- add status rack 2023-03-09
		------------------------------------------------------------------------------------------------------------
		and rack_addresses.[status] = 1
		------------------------------------------------------------------------------------------------------------
		) AS A
		--and IIF(REPLACE(REPLACE(jobs.name,'(',''),')','') = 'OS+AUTO1','AUTO1',REPLACE(REPLACE(jobs.name,'(',''),')','')) in(select distinct Flow from #tempTypeSetup)
	
	UNION ALL

	SELECT ROW_NUMBER() OVER(ORDER BY lot_no ASC) AS B,* FROM 
	(
		SELECT DISTINCT 
			 [APCSProDB].[mc].[machines].name AS MCName
			, [APCSProDB].[trans].[lots].lot_no
			, [APCSProDB].[method].device_names.name AS DeviceName 
			, [APCSProDB].[method].device_names.ft_name AS FTDevice
			, [APCSProDB].[method].[packages].name AS MethodPkgName
			, CASE 
				WHEN jobs.name = 'OS+AUTO(1)SBLSYL' THEN 'AUTO1'
				WHEN jobs.name = 'OS+AUTO(1)'		THEN 'AUTO1'
				WHEN jobs.name = 'OS+AUTO(2)'		THEN 'AUTO2'
				WHEN jobs.name = 'AUTO(1) RE'		THEN 'AUTO1'
				WHEN jobs.name = 'OS+AUTO(1) HV'		THEN 'AUTO1'
				WHEN jobs.name = 'AUTO(1) HV'		THEN 'AUTO1'
				--WHEN jobs.name LIKE '%ASISAMPLE%' 
				--	THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'ASISAMPLE',''))
				WHEN jobs.name LIKE '%BIN27' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'BIN27',''))
				WHEN jobs.name LIKE '%BIN27-CF' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'BIN27-CF',''))
				ELSE REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL','')
			  END as JobName --IIF(REPLACE(REPLACE(jobs.name,'(',''),')','') = 'OS+AUTO1','AUTO1',REPLACE(REPLACE(jobs.name,'(',''),')','')) as JobName
			, lots.act_job_id as NextJob
			, rack_addresses.address
			, rack_controls.name as rack_name

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
		
		LEFT JOIN APCSProDB.rcs.rack_addresses ON lots.lot_no = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id

		where lots.wip_state = 20 and  [APCSProDB].[method].[packages].name in (SELECT * from STRING_SPLIT ( @PackageName , ',' ))  
		and lotspecial.job_id in(119,110,108,106,263,155,403,359,361,362,363,364,50) and lots.is_special_flow = 1
		and lots.process_state in(0,100,1) 
		and lots.quality_state in(0,4)
		and special.process_state in(0,100,1) and special.quality_state in (0,4)
		and APCSProDB.method.device_names.alias_package_group_id != 33
		and [APCSProDB] .[method].device_names.name IN (select #tempTypeSetup.DeivceName from #tempTypeSetup )
		and CASE 
				WHEN jobs.name = 'OS+AUTO(1)SBLSYL' THEN 'AUTO1'
				WHEN jobs.name = 'OS+AUTO(1)'		THEN 'AUTO1'
				WHEN jobs.name = 'OS+AUTO(2)'		THEN 'AUTO2'
				WHEN jobs.name = 'AUTO(1) RE'		THEN 'AUTO1'
				WHEN jobs.name = 'OS+AUTO(1) HV'		THEN 'AUTO1'
				WHEN jobs.name = 'AUTO(1) HV'		THEN 'AUTO1'
				--WHEN jobs.name LIKE '%ASISAMPLE%' 
				--	THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'ASISAMPLE',''))
				WHEN jobs.name LIKE '%BIN27' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'BIN27',''))
				WHEN jobs.name LIKE '%BIN27-CF' 
					THEN TRIM(REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'BIN27-CF',''))
				ELSE REPLACE(REPLACE(REPLACE(jobs.name,'(',''),')',''),'SBLSYL','')
			END  IN (select distinct Flow from #tempTypeSetup)
		--and IIF(REPLACE(REPLACE(jobs.name,'(',''),')','') = 'OS+AUTO1','AUTO1',REPLACE(REPLACE(jobs.name,'(',''),')','')) in(select distinct Flow from #tempTypeSetup)
		------------------------------------------------------------------------------------------------------------
		---- add status rack 2023-03-09
		------------------------------------------------------------------------------------------------------------
		and rack_addresses.[status] = 1
		------------------------------------------------------------------------------------------------------------
		) AS C 
		) AS D
		where  lot_no not in (select LotNo from #getLotInMC)
		and lot_no not in (SELECT lot_no FROM #LockedNextLots_nongdic)

	-----------------------------------------------------------------------------------------------------------------------------------------------
	--GET MACHINE SEQ  **EDIT 26/08/2024 chatchadaporn n.
		
	CREATE TABLE #tempSetupMc_RANK
	(
	     Seq_MC int,MCNo varchar(30) primary key , McId int, next_lot_id int, OpRate real, SetupId int, LotNo varchar(10), PackageName varchar(30), DeviceName varchar(30)
		, TesterType varchar(30),TestFlow varchar(50),[Status] varchar(20),LotEnd Datetime,DelayLot varchar(1)
	)

	INSERT INTO #tempSetupMc_RANK
	SELECT RANK() OVER(PARTITION BY DeviceName, TestFlow ORDER BY 
		CASE 
			WHEN machine_states.next_lot_id IS NULL THEN 0
			ELSE 1
		END,
		next_lot_id ,LotEnd , McId ASC
		) AS Seq_MC
	,MCNo
	,McId
	,machine_states.next_lot_id
	,oprate
	,setupid
	,LotNo
	,PackageName
	,DeviceName
	,TesterType
	,TestFlow
	,Status
	,LotEnd
	,DelayLot
	FROM #tempSetupMc AS setupMC
	INNER JOIN APCSProDB.trans.machine_states ON setupMC.McId = machine_states.machine_id
	WHERE online_state = 1
	-----------------------------------------------------------------------------------------------------------------------------------------------
	--SET INSERT scheduler_temp
	
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

	INSERT INTO #scheduler_temp
	SELECT 
	    TB_LotWip.lot_no,
	    TB_LotWip.JobName,
	    TB_LotWip.FTDeivceName,
	    TB_LotWip.rack_address,
	    TB_LotWip.RackName,
	    mc.MCNo as machine_name,
		--TB_LotWip.lot_seq_onMC + 1 as seq_no,
		
		CASE 
			WHEN EXISTS (SELECT 1 FROM #LockedNextLots_nongdic WHERE #LockedNextLots_nongdic.machine_name = mc.MCNo)
				THEN TB_LotWip.lot_seq_onMC + 2
			ELSE TB_LotWip.lot_seq_onMC + 1
		END AS seq_no,

	    TB_LotWip.PkgName,
	    NULL as lot_end,
	    NULL as lot_start
	FROM #tempSetupMc_RANK AS MC 
	INNER JOIN (
	    SELECT *,
	        CASE 
	            WHEN lot_seq <= Max_Mc THEN lot_seq 
	            ELSE
	                CASE lot_seq % Max_Mc WHEN 0 THEN Max_Mc ELSE lot_seq % Max_Mc END
	        END AS Index_point_mc,
	        CASE 
	            WHEN lot_seq <= Max_Mc THEN 1 
	            WHEN (lot_seq % Max_Mc) <> 0 THEN convert(int, lot_seq / Max_Mc) + 1
	            WHEN (lot_seq % Max_Mc) = 0 THEN convert(int, lot_seq / Max_Mc)
	        END AS lot_seq_onMC
	    FROM (
	        SELECT 
	            (SELECT DISTINCT MAX(a.Seq_MC) FROM #tempSetupMc_RANK AS A WHERE A.DeviceName = B.DeviceName AND A.TestFlow = B.JobName) AS Max_Mc,
	            lot_seq,
	            lot_no,
	            DeviceName,
	            JobName,
	            FTDeivceName,
	            rack_address, 
	            RackName,
	            PkgName
	        FROM #tempWIPData_NonGdic AS B
	    ) AS TB
	) AS TB_LotWip 
	ON TB_LotWip.Index_point_mc = mc.Seq_MC AND TB_LotWip.DeviceName = mc.DeviceName AND TB_LotWip.JobName = TestFlow  
	WHERE NOT EXISTS (SELECT 1 FROM #LockedNextLots_nongdic WHERE #LockedNextLots_nongdic.lot_no = TB_LotWip.lot_no)
	ORDER BY TB_LotWip.DeviceName, lot_seq

	select * INTO #Result from #scheduler_temp as outerTB where seq_no <= (select seq_no from #scheduler_temp as innerTB where innerTB.lot_no = outerTB.machine_name)
	OR machine_name not in (select MCName from #GetNonGDIC_planTC_NEW ) 

	INSERT INTO #Result select WIP.* from #scheduler_temp as WIP  inner join #scheduler_temp_TC_non on WIP.machine_name = #scheduler_temp_TC_non.machine_name and WIP.seq_no < #scheduler_temp_TC_non.seq_no


	INSERT INTO [DBxDW].[dbo].[scheduler_temp_01] select * from #Result

	-----------------------------------------------------------------------------------------------------------------------------------------------	

		drop table #LockedNextLots_nongdic
		drop table #CountMc_nongdic
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
		drop table #MachineFlowMapTable_nongdic
		COMMIT;
END TRY
BEGIN CATCH
PRINT '---> Error <----' +  ERROR_MESSAGE() + '---> Error <----'; 
	ROLLBACK;
END CATCH
END