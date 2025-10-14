-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_temp]
	-- Add the parameters for the stored procedure here
	@DEBUG INT = '0',
	@PKG VARCHAR(20) = 'SSOP-B20W'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@DEBUG = 0)
	BEGIN
	--SELECT [FTSetupReport].[MCNo]
	--	, Mc.id as McId
	--	, Rate.oprate
	--	, Rate.setupid
	--	, LotNo
	--	, PackageName
	--	, DeviceName
	--	, ProgramName
	--	, TesterType
	--	, TestFlow
	--	, TestBoxA 
	--	, TestBoxB
	--	, DutcardA
	--	, DutcardB
	--	, OptionName1
	--	, OptionName2
	--	, 'Wait' as [Status] 
	--	, 0 as DelayLot
	--	FROM [DBx].[dbo].[FTSetupReport]
	--	inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
	--	left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
	--	Where PackageName in (@PKG) 
	--	and [FTSetupReport].[MCNo] not like '%M%'
	--	and [FTSetupReport].[MCNo] not like '%ith%'
	--	and [FTSetupReport].[MCNo] not like '%-z-%'
	--	and [FTSetupReport].[MCNo] not like '%-099%'
		--- P'got Query
		SELECT [FTSetupReport].[MCNo]
		, Mc.id as McId
		, Rate.oprate
		, Rate.setupid
		, LotNo
		, PackageName
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
		, case when [State].run_state = 0 THEN 'Ready'
				when [State].run_state = 1 THEN 'Idle'
				when [State].run_state = 2 THEN 'Setup'
				when [State].run_state = 3 THEN 'Ready'
				when [State].run_state = 4 THEN 'Run'
				when [State].run_state = 10 THEN 'PlanStop' 
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
		, DATEADD(MINUTE,convert(int,[scheduler_temp_testtime].[avg_value] * 60.0),convert(datetime,[LotTime].[LotDate])) as Lot1Date
		
		--, convert(datetime,[LotTime].[LotDate])
		--, convert(int,[scheduler_temp_testtime].[avg_value] * 60.0)
		FROM [DBx].[dbo].[FTSetupReport]
		inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
		left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
		inner join (select MCNo
			, min(LOT1) as LOT1
			, min(LOT2) as LOT2
			, min(LOT3) as LOT3
			, min(LOT4) as LOT4
			, min(LOT5) as LOT5
			, min(LOT6) as LOT6
			, min(LOT7) as LOT7
			, min(LOT8) as LOT8
			, min(LOT9) as LOT9
			, min(LOT10) as LOT10
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
			, case when [scheduler_temp].[seq_no] = 1 then [device_names].[ft_name] else null end as DEVICE1
			, case when [scheduler_temp].[seq_no] = 2 then [device_names].[ft_name] else null end as DEVICE2
			, case when [scheduler_temp].[seq_no] = 3 then [device_names].[ft_name] else null end as DEVICE3
			, case when [scheduler_temp].[seq_no] = 4 then [device_names].[ft_name] else null end as DEVICE4
			, case when [scheduler_temp].[seq_no] = 5 then [device_names].[ft_name] else null end as DEVICE5
			, case when [scheduler_temp].[seq_no] = 6 then [device_names].[ft_name] else null end as DEVICE6
			, case when [scheduler_temp].[seq_no] = 7 then [device_names].[ft_name] else null end as DEVICE7
			, case when [scheduler_temp].[seq_no] = 8 then [device_names].[ft_name] else null end as DEVICE8
			, case when [scheduler_temp].[seq_no] = 9 then [device_names].[ft_name] else null end as DEVICE9
			, case when [scheduler_temp].[seq_no] = 10 then [device_names].[ft_name] else null end as DEVICE10
			, case when [scheduler_temp].[seq_no] = 2 then scheduler_temp.rack_address else null end as LOT2_RackAddress
			, case when [scheduler_temp].[seq_no] = 2 then scheduler_temp.rack_name else null end as LOT2_RackName
			  FROM [DBx].[dbo].[FTSetupReport]
			  left join [DBxDW].[dbo].[scheduler_temp] on [scheduler_temp].[machine_name] collate SQL_Latin1_General_CP1_CI_AS = [FTSetupReport].[MCNo]
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

		Where PackageName in (@PKG) 
		and [FTSetupReport].[MCNo] not like '%-M-%'
		and [FTSetupReport].[MCNo] not like '%ith%'
		and [FTSetupReport].[MCNo] not like '%-z-%'
		and [FTSetupReport].[MCNo] not like '%-099%'
		and [FTSetupReport].[MCNo] not like '%-00'
		
	END
	ELSE
	BEGIN
		SELECT [FTSetupReport].[MCNo]
		, Mc.id as McId
		, Rate.oprate
		, Rate.setupid
		, LotNo
		, PackageName
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
		, case when [lots].[process_state] = 0 THEN 'Ready'
			when [lots].[process_state] = 1 THEN 'SetUp'
			when [lots].[process_state] = 2 THEN 'Run'
			ELSE 'Wait'
			END as [Status] 
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
		, case when DATEDIFF(DAY,[days2].[date_value],GETDATE()) >= 0 then 1 ELSE 0 end as DelayLot
		, DATEADD(MINUTE,convert(int,[scheduler_temp_testtime].[avg_value] * 60.0),convert(datetime,[LotTime].[LotDate])) as Lot1Date
		--, convert(datetime,[LotTime].[LotDate])
		--, convert(int,[scheduler_temp_testtime].[avg_value] * 60.0)
		FROM [DBx].[dbo].[FTSetupReport]
		inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
		left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
		inner join (select MCNo
			, min(LOT1) as LOT1
			, min(LOT2) as LOT2
			, min(LOT3) as LOT3
			, min(LOT4) as LOT4
			, min(LOT5) as LOT5
			, min(LOT6) as LOT6
			, min(LOT7) as LOT7
			, min(LOT8) as LOT8
			, min(LOT9) as LOT9
			, min(LOT10) as LOT10
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
			, case when [scheduler_temp].[seq_no] = 1 then [device_names].[ft_name] else null end as DEVICE1
			, case when [scheduler_temp].[seq_no] = 2 then [device_names].[ft_name] else null end as DEVICE2
			, case when [scheduler_temp].[seq_no] = 3 then [device_names].[ft_name] else null end as DEVICE3
			, case when [scheduler_temp].[seq_no] = 4 then [device_names].[ft_name] else null end as DEVICE4
			, case when [scheduler_temp].[seq_no] = 5 then [device_names].[ft_name] else null end as DEVICE5
			, case when [scheduler_temp].[seq_no] = 6 then [device_names].[ft_name] else null end as DEVICE6
			, case when [scheduler_temp].[seq_no] = 7 then [device_names].[ft_name] else null end as DEVICE7
			, case when [scheduler_temp].[seq_no] = 8 then [device_names].[ft_name] else null end as DEVICE8
			, case when [scheduler_temp].[seq_no] = 9 then [device_names].[ft_name] else null end as DEVICE9
			, case when [scheduler_temp].[seq_no] = 10 then [device_names].[ft_name] else null end as DEVICE10
			  FROM [DBx].[dbo].[FTSetupReport]
			  left join [DBxDW].[dbo].[scheduler_temp] on [scheduler_temp].[machine_name] collate SQL_Latin1_General_CP1_CI_AS = [FTSetupReport].[MCNo]
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
		Where PackageName in ('SSOP-B20W','SSOP-B28W') 
		and [FTSetupReport].[MCNo] not like '%-M-%'
		and [FTSetupReport].[MCNo] not like '%ith%'
		and [FTSetupReport].[MCNo] not like '%-z-%'
		and [FTSetupReport].[MCNo] not like '%-099%'
		and [FTSetupReport].[MCNo] not like '%-00'
	END
END
