-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_temp_ver_temp] 
	-- Add the parameters for the stored procedure here
	--
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @PKG varchar(MAX)
	SET @PKG  = 'SSOP-B20W,SSOP-B28W,SSOPB28WR6,SSOP-B10W,SOP-JW8,SSOP-C38W,HTQFP64AV,HTQFP64BV,HTQFP64BVE,HTQFP64V,HTQFP64V-HF,QFP32,QFP32R,UQFP64,UQFP64M,VQFP48C,VQFP48CM,VQFP48CR,VQFP64,VQFP64F,VQFP64M,SQFP-T52,SQFP-T52M,MSOP8,MSOP8-HF,HSON-A8,MSOP10,HSON8,HSON8-HF,TSSOP-B8J,HRP5,HRP7,TO252-3,TO252-5,TO252-J3,TO252-J5,TO263-3,TO263-5,TO263-7,TO252S-5+,TO252S-7+,SIP9,TO252S-3,TO252S-5,TO252-J5F,SOT223-4,SOT223-4F,TO263-3F,TO263-5F,TO220-6M,TO220-7M,HTSSOP-C64A,TSSOP-C48V3,HSSOP-C16,SSOP-A26_20,SSOP-A54_23,SSOP-A54_36,SSOP-A54_42,SOP22,SOP20,SOP24,SOP24-HF,SSOP-A20,SSOP-A24,SSOP-A32,SSOP-B40,SSOP-B24,SSOP-B28,TSSOP-B30,HSOP-M36,SSOP-A44,TSSOP-C44,HTSSOP-C48,HTSSOP-C48R,TSSOP-C48V,HTSSOP-C64,HTSSOP-A44,HTSSOP-A44R,HTSSOP-B54,HTSSOP-B54R,HTSSOP-B20,HTSSOP-B40,TSSOP-B8J,HTSSOPB20E,HTSSOPC48E,SSOP-B20WA,SSOPB20WR1,HTSOPC48XR,SSOPB30W19,SSOP-C26W,MSOP8E-HF,TO263-7L'
    -- Insert statements for procedure here

BEGIN TRANSACTION
BEGIN TRY

	DELETE FROM DBxDW.dbo.scheduler_temp_ft_01
	WHERE PackageName in (SELECT * from STRING_SPLIT ( @PKG , ',' ))
	INSERT INTO DBxDW.dbo.scheduler_temp_ft_01
	SELECT DISTINCT [FTSetupReport].[MCNo]
		, Mc.id as McId
		, Rate.oprate
		, Rate.setupid
		, LotNo
		, pk.name 
		, DeviceName
		, ProgramName
		, TesterType
		, TestFlow
		, TestBoxA 
		, TestBoxB
		, DutcardA
		, DutcardB
		, OptionName1
		, OptionName2
		, case when [State].run_state = 10 THEN 'PlanStop'
				--when [State].run_state = 2 THEN 'Setup'
				when AllLot.LOT1 != '' THEN 'Run'
				when AllLot.LOT2 = '' THEN 'Wait'
				when AllLot.LOT2 collate SQL_Latin1_General_CP1_CI_AS = [FTSetupReport].[MCNo] THEN 'Wait' 
				when AllLot.LOT2 != '' THEN 'Setup'
			ELSE 'Wait' END as [Status]  
		, AllLot.LOT1 
		, AllLot.LOT2
		, AllLot.LOT3
		, AllLot.LOT4
		, AllLot.LOT5
		, AllLot.LOT6
		, AllLot.LOT7
		, AllLot.LOT8
		, AllLot.LOT9
		, AllLot.LOT10
		, AllLot.DEVICE1
		, AllLot.DEVICE2
		, AllLot.DEVICE3
		, AllLot.DEVICE4
		, AllLot.DEVICE5
		, AllLot.DEVICE6
		, AllLot.DEVICE7
		, AllLot.DEVICE8
		, AllLot.DEVICE9
		, AllLot.DEVICE10
		, AllLot.LOT2_RackAddress
		, AllLot.LOT2_RackName
		, case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 then 1 ELSE 0 end as DelayLot
		--, DATEADD(MINUTE,convert(int,[scheduler_temp_testtime].[avg_value] * 60.0),convert(datetime,[LotTime].[LotDate])) as Lot1Date
		
		, AllLot.LOT1_LOTEND as Lot1Date
		, AllLot.LOT1_LOTSTART as Lot1Start
		--, convert(datetime,[LotTime].[LotDate])
		--, convert(int,[scheduler_temp_testtime].[avg_value] * 60.0)
		,AdaptorA,AdaptorB
		FROM [DBx].[dbo].[FTSetupReport]
		inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
		left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
		LEFT join APCSProDB.trans.lots as lot on lot.lot_no = LotNo
		INNER JOIN APCSProDB.method.packages pk on pk.id = lot.act_package_id
		inner join (select MCNo
			, max(LOT1) as LOT1
			, max(LOT2) as LOT2
			, max(LOT3) as LOT3
			, max(LOT4) as LOT4
			, max(LOT5) as LOT5
			, max(LOT6) as LOT6
			, max(LOT7) as LOT7
			, max(LOT8) as LOT8
			, max(LOT9) as LOT9
			, max(LOT10) as LOT10
			, min(DEVICE1) as DEVICE1
			, min(DEVICE2) as DEVICE2
			, min(DEVICE3) as DEVICE3
			, min(DEVICE4) as DEVICE4
			, min(DEVICE5) as DEVICE5
			, min(DEVICE6) as DEVICE6
			, min(DEVICE7) as DEVICE7
			, min(DEVICE8) as DEVICE8
			, min(DEVICE9) as DEVICE9
			, min(DEVICE10) as DEVICE10
			, min(LOT2_RackAddress) as LOT2_RackAddress
			, min(LOT2_RackName) as LOT2_RackName
			, min(LOT1_LOTEND) as LOT1_LOTEND
			, min(LOT1_LOTSTART) as LOT1_LOTSTART
			from
			(SELECT [FTSetupReport].[MCNo]
			, case when [scheduler_temp].[seq_no] = 1 then [scheduler_temp].[lot_no] else null end as LOT1
			, case when [scheduler_temp].[seq_no] = 2 then [scheduler_temp].[lot_no] else null end as LOT2
			, case when [scheduler_temp].[seq_no] = 3 then [scheduler_temp].[lot_no] else null end as LOT3
			, case when [scheduler_temp].[seq_no] = 4 then [scheduler_temp].[lot_no] else null end as LOT4
			, case when [scheduler_temp].[seq_no] = 5 then [scheduler_temp].[lot_no] else null end as LOT5
			, case when [scheduler_temp].[seq_no] = 6 then [scheduler_temp].[lot_no] else null end as LOT6
			, case when [scheduler_temp].[seq_no] = 7 then [scheduler_temp].[lot_no] else null end as LOT7
			, case when [scheduler_temp].[seq_no] = 8 then [scheduler_temp].[lot_no] else null end as LOT8
			, case when [scheduler_temp].[seq_no] = 9 then [scheduler_temp].[lot_no] else null end as LOT9
			, case when [scheduler_temp].[seq_no] = 10 then [scheduler_temp].[lot_no] else null end as LOT10
			, case when [scheduler_temp].[seq_no] = 1 then [scheduler_temp].ft_device else null end as DEVICE1
			, case when [scheduler_temp].[seq_no] = 2 and scheduler_temp.lot_no collate SQL_Latin1_General_CP1_CI_AS = [FTSetupReport].[MCNo] then [scheduler_temp].ft_device +' ('+ [scheduler_temp].flow+')'
				when [scheduler_temp].[seq_no] = 2 then [scheduler_temp].ft_device else null end as DEVICE2
			, case when [scheduler_temp].[seq_no] = 3 and scheduler_temp.lot_no collate SQL_Latin1_General_CP1_CI_AS = [FTSetupReport].[MCNo] then [scheduler_temp].ft_device +' ('+ [scheduler_temp].flow+')'
				when [scheduler_temp].[seq_no] = 3 then [scheduler_temp].ft_device else null end as DEVICE3
			, case when [scheduler_temp].[seq_no] = 4 and scheduler_temp.lot_no collate SQL_Latin1_General_CP1_CI_AS = [FTSetupReport].[MCNo] then [scheduler_temp].ft_device +' ('+ [scheduler_temp].flow+')'
				when [scheduler_temp].[seq_no] = 4 then [scheduler_temp].ft_device else null end as DEVICE4
			, case when [scheduler_temp].[seq_no] = 5 and scheduler_temp.lot_no collate SQL_Latin1_General_CP1_CI_AS = [FTSetupReport].[MCNo] then [scheduler_temp].ft_device +' ('+ [scheduler_temp].flow+')'
				when [scheduler_temp].[seq_no] = 5 then [scheduler_temp].ft_device else null end as DEVICE5
			, case when [scheduler_temp].[seq_no] = 6 and scheduler_temp.lot_no collate SQL_Latin1_General_CP1_CI_AS = [FTSetupReport].[MCNo] then [scheduler_temp].ft_device +' ('+ [scheduler_temp].flow+')'
				when [scheduler_temp].[seq_no] = 6 then [scheduler_temp].ft_device else null end as DEVICE6
			, case when [scheduler_temp].[seq_no] = 7 and scheduler_temp.lot_no collate SQL_Latin1_General_CP1_CI_AS = [FTSetupReport].[MCNo] then [scheduler_temp].ft_device +' ('+ [scheduler_temp].flow+')'
				when [scheduler_temp].[seq_no] = 7 then [scheduler_temp].ft_device else null end as DEVICE7
			, case when [scheduler_temp].[seq_no] = 8 then [scheduler_temp].ft_device else null end as DEVICE8
			, case when [scheduler_temp].[seq_no] = 9 then [scheduler_temp].ft_device else null end as DEVICE9
			, case when [scheduler_temp].[seq_no] = 10 then [scheduler_temp].ft_device else null end as DEVICE10
			, case when [scheduler_temp].[seq_no] = 2 then scheduler_temp.rack_address else null end as LOT2_RackAddress
			, case when [scheduler_temp].[seq_no] = 2 then scheduler_temp.rack_name else null end as LOT2_RackName
			, case when [scheduler_temp].[seq_no] = 1 then scheduler_temp.lot_end else null end as LOT1_LOTEND
			, case when [scheduler_temp].[seq_no] = 1 then scheduler_temp.lot_start else null end as LOT1_LOTSTART
			  FROM [DBx].[dbo].[FTSetupReport]
			  left join [DBxDW].[dbo].[scheduler_temp_01] as [scheduler_temp] on [scheduler_temp].[machine_name] collate SQL_Latin1_General_CP1_CI_AS = [FTSetupReport].[MCNo]
			  left join [APCSProDB].[trans].[lots] on [lots].[lot_no] = [scheduler_temp].[lot_no] collate SQL_Latin1_General_CP1_CI_AS 
			  left join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
			  left join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
			  left join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]) as lot
		group by lot.MCNo) as AllLot on AllLot.MCNo = [FTSetupReport].[MCNo]
		left join [APCSProDB].[trans].[lots] on [lots].[lot_no] = [AllLot].[LOT1] collate SQL_Latin1_General_CP1_CI_AS
		left join [APCSProDB].[trans].[days] as [days2] on [days2].[id] = [lots].[out_plan_date_id]
		left join (select lot_no,  min(lot_process_records.recorded_at) as LotDate 
			from [APCSProDB].[trans].[lots]
			inner join [APCSProDB].[trans].[lot_process_records] on [lot_process_records].[lot_id] = [lots].[id] 
				and [lot_process_records].[step_no] = [lots].[step_no] 
				and [lot_process_records].[process_state] = 2 
				and [lot_process_records].[record_class] = 1
			group by lot_no) as LotTime on LotTime.lot_no = AllLot.LOT1 collate SQL_Latin1_General_CP1_CI_AS
		left join [DBxDW].[dbo].[scheduler_temp_testtime] on [scheduler_temp_testtime].[device] collate SQL_Latin1_General_CP1_CI_AS = AllLot.DEVICE1 
				and [scheduler_temp_testtime].[flow] collate SQL_Latin1_General_CP1_CI_AS = [FTSetupReport].[TestFlow]
		left join APCSProDB.trans.machine_states as [State] on Mc.id = State.machine_id 
		--inner join APCSProDB.trans.lots as lots on lots.lot_no = LotNo
		--left join APCSProDB.method.packages as pk on pk.id = lots.act_package_id

		Where pk.name in (SELECT * from STRING_SPLIT ( @PKG , ',' )) 
		--and [FTSetupReport].[MCNo] not like '%-M-%'
		--and [FTSetupReport].[MCNo] not like '%ith%'
		--and [FTSetupReport].[MCNo] not like '%-z-%'
		and [FTSetupReport].[MCNo] not like '%-00'
		and [FTSetupReport].[MCNo] not like 'FL%'
		and Mc.cell_ip is not null
		and Mc.is_disabled = 0

		--////// Insert scheduler_temp_ft_history  /// update by aun 2022/09/19
		INSERT INTO DBxDW.dbo.scheduler_temp_ft_history_01
		 SELECT  GETDATE() AS record_at
		  ,[MCNo]
		  ,[McId]
		  ,[oprate]
		  ,[setupid]
		  ,[LotNo]
		  ,[PackageName]
		  ,[DeviceName]
		  ,[ProgramName]
		  ,[TesterType]
		  ,[TestFlow]
		  ,[TestBoxA]
		  ,[TestBoxB]
		  ,[DutcardA]
		  ,[DutcardB]
		  ,[OptionName1]
		  ,[OptionName2]
		  ,[Status]
		  ,[LOT1]
		  ,[LOT2]
		  ,[LOT3]
		  ,[LOT4]
		  ,[LOT5]
		  ,[LOT6]
		  ,[LOT7]
		  ,[LOT8]
		  ,[LOT9]
		  ,[LOT10]
		  ,[DEVICE1]
		  ,[DEVICE2]
		  ,[DEVICE3]
		  ,[DEVICE4]
		  ,[DEVICE5]
		  ,[DEVICE6]
		  ,[DEVICE7]
		  ,[DEVICE8]
		  ,[DEVICE9]
		  ,[DEVICE10]
		  ,[LOT2_RackAddress]
		  ,[LOT2_RackName]
		  ,[DelayLot]
		  ,[LOT1Date]
		  ,[LOT1SDate]
		  ,[AdaptorA]
		  ,[AdaptorB]
	  FROM [DBxDW].[dbo].[scheduler_temp_ft_01]

	  DELETE DBxDW.dbo.[scheduler_temp_01] FROM DBxDW.dbo.[scheduler_temp_01] where rack_name is null and rack_address is null and lot_start is null
	  COMMIT;
END TRY
BEGIN CATCH
	PRINT '---> Error <----' +  ERROR_MESSAGE() + '---> Error <----'; 
	ROLLBACK;
END CATCH
END
