-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_ft_qfp_temp]
	-- Add the parameters for the stored procedure here
	@PKG VARCHAR(30) = '1'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@PKG = '1')
	BEGIN
		SELECT [FTSetupReport].[MCNo]
		, Mc.id as McId
		, Rate.oprate
		, Rate.setupid
		, LotNo
		, PackageName
		, DeviceName
		, SUBSTRING (DeviceName , 0,(SELECT CHARINDEX('-', DeviceName))) as CustomDevice
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
		, 0 as DelayLot
		FROM [DBx].[dbo].[FTSetupReport]
		inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
		left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
		left join APCSProDB.trans.machine_states as [State] on Mc.id = State.machine_id
		Where PackageName like ('%HTQFP64%') 
		and [FTSetupReport].[MCNo] not like '%M%'
		and [FTSetupReport].[MCNo] not like '%ith%'
		and [FTSetupReport].[MCNo] not like '%-z-%'
		and [FTSetupReport].[MCNo] not like '%-099%'
		and [FTSetupReport].[MCNo] not like '%-000'
	END
	ELSE IF(@PKG = '2')
	BEGIN
		SELECT [FTSetupReport].[MCNo]
			, Mc.id as McId
			, Rate.oprate
			, Rate.setupid
			, LotNo
			, PackageName
			, DeviceName
			, SUBSTRING (DeviceName , 0,(SELECT CHARINDEX('-', DeviceName))) as CustomDevice
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
			, 0 as DelayLot
			FROM [DBx].[dbo].[FTSetupReport]
			inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
			left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
			left join APCSProDB.trans.machine_states as [State] on Mc.id = State.machine_id
			Where PackageName like ('%VQFP48C%') or PackageName like ('%QFP32%') or PackageName like ('%UQFP64%')
			and [FTSetupReport].[MCNo] not like '%M%'
			and [FTSetupReport].[MCNo] not like '%ith%'
			and [FTSetupReport].[MCNo] not like '%-z-%'
			and [FTSetupReport].[MCNo] not like '%-099%'
			and [FTSetupReport].[MCNo] not like '%-000'
	END
	ELSE IF(@PKG = '3')
	BEGIN
		SELECT [FTSetupReport].[MCNo]
			, Mc.id as McId
			, Rate.oprate
			, Rate.setupid
			, LotNo
			, PackageName
			, DeviceName
			, SUBSTRING (DeviceName , 0,(SELECT CHARINDEX('-', DeviceName))) as CustomDevice
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
			, 0 as DelayLot
			FROM [DBx].[dbo].[FTSetupReport]
			inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
			left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
			left join APCSProDB.trans.machine_states as [State] on Mc.id = State.machine_id
			Where PackageName like ('%QFP32%') 
			and [FTSetupReport].[MCNo] not like '%M%'
			and [FTSetupReport].[MCNo] not like '%ith%'
			and [FTSetupReport].[MCNo] not like '%-z-%'
			and [FTSetupReport].[MCNo] not like '%-099%'
			and [FTSetupReport].[MCNo] not like '%-000'
	END
	ELSE IF(@PKG = '4')
	BEGIN
		SELECT [FTSetupReport].[MCNo]
			, Mc.id as McId
			, Rate.oprate
			, Rate.setupid
			, LotNo
			, PackageName
			, DeviceName
			, SUBSTRING (DeviceName , 0,(SELECT CHARINDEX('-', DeviceName))) as CustomDevice
			, ProgramName
			, TesterType
			, TestFlow
			, TestBoxA 
			, TestBoxB
			, DutcardA
			, DutcardB
			, OptionName1
			, OptionName2
			,case when [State].run_state = 0 THEN 'Ready'
				when [State].run_state = 1 THEN 'Idle'
				when [State].run_state = 2 THEN 'Setup'
				when [State].run_state = 3 THEN 'Ready'
				when [State].run_state = 4 THEN 'Run'
				when [State].run_state = 10 THEN 'PlanStop'
			ELSE 'Wait' END as [Status]
			, 0 as DelayLot
			FROM [DBx].[dbo].[FTSetupReport]
			inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
			left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
			left join APCSProDB.trans.machine_states as [State] on Mc.id = State.machine_id
			Where PackageName like ('%VQFP64%') or PackageName like ('%SQFP-T52%')
			and [FTSetupReport].[MCNo] not like '%M%'
			and [FTSetupReport].[MCNo] not like '%ith%'
			and [FTSetupReport].[MCNo] not like '%-z-%'
			and [FTSetupReport].[MCNo] not like '%-099%'
			and [FTSetupReport].[MCNo] not like '%-000'
	END
	ELSE IF(@PKG = '5')
	BEGIN
		SELECT [FTSetupReport].[MCNo]
			, Mc.id as McId
			, Rate.oprate
			, Rate.setupid
			, LotNo
			, PackageName
			, DeviceName
			, SUBSTRING (DeviceName , 0,(SELECT CHARINDEX('-', DeviceName))) as CustomDevice
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
			, 0 as DelayLot
			FROM [DBx].[dbo].[FTSetupReport]
			inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
			left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
			left join APCSProDB.trans.machine_states as [State] on Mc.id = State.machine_id
			Where PackageName like ('%SQFP-T52%') 
			and [FTSetupReport].[MCNo] not like '%M%'
			and [FTSetupReport].[MCNo] not like '%ith%'
			and [FTSetupReport].[MCNo] not like '%-z-%'
			and [FTSetupReport].[MCNo] not like '%-099%'
			and [FTSetupReport].[MCNo] not like '%-000'
	END
	ELSE IF (@PKG = 'MSOP8')
	BEGIN 
		SELECT Distinct [FTSetupReport].[MCNo]
		, Mc.id as McId
		, Rate.oprate
		, Rate.setupid
		, LotNo
		, PackageName
		, DeviceName
		, SUBSTRING (DeviceName , 0,(SELECT CHARINDEX('-', DeviceName))) as CustomDevice
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
		, 0 as DelayLot
		FROM [DBx].[dbo].[FTSetupReport]
		inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
		left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
		left join APCSProDB.trans.machine_states as [State] on Mc.id = State.machine_id
		--LEFT join APCSProDB.method.device_names as dv on [DBx].[dbo].[FTSetupReport].DeviceName = dv.[name]
		Where PackageName like @PKG +'%' or PackageName like ('%HSON-A8%') --(select name from APCSProDB.method.packages where id = @PKG) 
		and [FTSetupReport].[MCNo] not like '%M%'
		and [FTSetupReport].[MCNo] not like '%ith%'
		and [FTSetupReport].[MCNo] not like '%-z-%'
		and [FTSetupReport].[MCNo] not like '%-099%'
		and [FTSetupReport].[MCNo] not like '%-00'
		and [FTSetupReport].[MCNo] not like '%-000'
	END
	ELSE 
	
	BEGIN
		SELECT Distinct [FTSetupReport].[MCNo]
		, Mc.id as McId
		, Rate.oprate
		, Rate.setupid
		, LotNo
		, PackageName
		, DeviceName
		, SUBSTRING (DeviceName , 0,(SELECT CHARINDEX('-', DeviceName))) as CustomDevice
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
		, 0 as DelayLot
		FROM [DBx].[dbo].[FTSetupReport]
		inner join APCSProDB.mc.machines as Mc on Mc.name = DBx.dbo.FTSetupReport.MCNo
		left join DBx.dbo.scheduler_oprate as Rate on Rate.mcid = Mc.id
		left join APCSProDB.trans.machine_states as [State] on Mc.id = State.machine_id
		--LEFT join APCSProDB.method.device_names as dv on [DBx].[dbo].[FTSetupReport].DeviceName = dv.[name]
		Where PackageName like @PKG +'%' --(select name from APCSProDB.method.packages where id = @PKG) 
		and [FTSetupReport].[MCNo] not like '%M%'
		and [FTSetupReport].[MCNo] not like '%ith%'
		and [FTSetupReport].[MCNo] not like '%-z-%'
		and [FTSetupReport].[MCNo] not like '%-099%'
		and [FTSetupReport].[MCNo] not like '%-00'
		and [FTSetupReport].[MCNo] not like '%-000'
	END
END
