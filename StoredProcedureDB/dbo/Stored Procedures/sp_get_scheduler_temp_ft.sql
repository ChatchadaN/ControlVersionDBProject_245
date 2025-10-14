-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_temp_ft] 
	-- Add the parameters for the stored procedure here
	@PKG VARCHAR(MAX) ='',
	@IsGDIC INT = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@IsGDIC = 1)
	BEGIN
		-- select distinct temp.MCNo,temp.McId,temp.oprate,temp.setupid,temp.LotNo,temp.PackageName,temp.DeviceName,temp.ProgramName,temp.TesterType
		--,temp.TestFlow,temp.TestBoxA,temp.TestBoxB,temp.DutcardA,temp.DutcardB,temp.OptionName1,temp.OptionName2
		--,temp.[Status],temp.LOT1,LOT2,LOT3,LOT4,LOT5,LOT6,LOT7,LOT8,LOT9,LOT10
		--,DEVICE1,DEVICE2,DEVICE3,DEVICE4,DEVICE5,DEVICE6,DEVICE7,DEVICE8,DEVICE9,DEVICE10
		--,temp.LOT2_RackAddress,temp.LOT2_RackName,DelayLot,LOT1Date,LOT1SDate,temp.AdaptorA,temp.AdaptorB ,  SUBSTRING (DeviceName , 0,(SELECT CHARINDEX('-', DeviceName))) as CustomDevice
		--from DBxDW.dbo.scheduler_temp_ft  as temp
		--INNER JOIN APCSProDB.method.device_names on APCSProDB.method.device_names.name =  temp.DeviceName COLLATE SQL_Latin1_General_CP1_CI_AS
		--where PackageName in (SELECT * from STRING_SPLIT ( @PKG , ',' ))	
		--	and [APCSProDB].method.device_names.alias_package_group_id = 33
		--	--and [MCNo] not like '%ith%'
		--	--and [MCNo] not like '%-z-%'
		--	--and [MCNo] not like '%-099%'
		--	and [MCNo] not like '%-000'

		-- select distinct temp.MCNo,temp.McId,temp.oprate,temp.setupid,temp.LotNo,temp.PackageName,temp.DeviceName,temp.ProgramName,temp.TesterType
		--,temp.TestFlow,temp.TestBoxA,temp.TestBoxB,temp.DutcardA,temp.DutcardB,temp.OptionName1,temp.OptionName2
		--,temp.[Status],temp.LOT1,LOT2,LOT3,LOT4,LOT5,LOT6,LOT7,LOT8,LOT9,LOT10
		--,DEVICE1,DEVICE2,DEVICE3,DEVICE4,DEVICE5,DEVICE6,DEVICE7,DEVICE8,DEVICE9,DEVICE10
		--,temp.LOT2_RackAddress,temp.LOT2_RackName,DelayLot,LOT1Date,LOT1SDate,temp.AdaptorA,temp.AdaptorB ,  SUBSTRING (temp.DeviceName , 0,(SELECT CHARINDEX('-', temp.DeviceName))) as CustomDevice
		--,temp.Status
		--,FTSetupReport.SetupStatus
		--from DBxDW.dbo.scheduler_temp_ft  as temp
		--INNER JOIN APCSProDB.method.device_names on APCSProDB.method.device_names.name =  temp.DeviceName COLLATE SQL_Latin1_General_CP1_CI_AS
		--INNER JOIN  DBx.dbo.FTSetupReport on temp.MCNo = FTSetupReport.MCNo COLLATE SQL_Latin1_General_CP1_CI_AS
		--where temp.PackageName in (SELECT * from STRING_SPLIT ( @PKG , ',' ))	
		--	and [APCSProDB].method.device_names.alias_package_group_id = 33
		--	--and [MCNo] not like '%ith%'
		--	--and [MCNo] not like '%-z-%'
		--	--and [MCNo] not like '%-099%'
		--	and temp.[MCNo] not like '%-000'
		--	--OR (FTSetupReport.SetupStatus = 'CANCELED' OR FTSetupReport.SetupStatus = 'POWEROFF')
	
		SELECT DISTINCT temp.MCNo,temp.McId,temp.oprate,temp.setupid,temp.LotNo,temp.PackageName,temp.DeviceName,temp.ProgramName,temp.TesterType,temp.TestFlow,
			temp.TestBoxA,temp.TestBoxB,temp.DutcardA,temp.DutcardB,temp.OptionName1,temp.OptionName2,temp.[Status],
			temp.LOT1,CASE WHEN temp.LOT1 != '' THEN DATEDIFF(DAY, lot1_days.date_value, GETDATE()) ELSE NULL END AS DELAY1,
			LOT2,CASE WHEN temp.LOT2 != '' THEN DATEDIFF(DAY, lot2_days.date_value, GETDATE()) ELSE NULL END AS DELAY2,
			LOT3,CASE WHEN temp.LOT3 != '' THEN DATEDIFF(DAY, lot3_days.date_value, GETDATE()) ELSE NULL END AS DELAY3,
			LOT4,CASE WHEN temp.LOT4 != '' THEN DATEDIFF(DAY, lot4_days.date_value, GETDATE()) ELSE NULL END AS DELAY4,
			LOT5,CASE WHEN temp.LOT5 != '' THEN DATEDIFF(DAY, lot5_days.date_value, GETDATE()) ELSE NULL END AS DELAY5,
			LOT6,CASE WHEN temp.LOT6 != '' THEN DATEDIFF(DAY, lot6_days.date_value, GETDATE()) ELSE NULL END AS DELAY6,
			LOT7,CASE WHEN temp.LOT7 != '' THEN DATEDIFF(DAY, lot7_days.date_value, GETDATE()) ELSE NULL END AS DELAY7,
			LOT8,CASE WHEN temp.LOT8 != '' THEN DATEDIFF(DAY, lot8_days.date_value, GETDATE()) ELSE NULL END AS DELAY8,
			LOT9,CASE WHEN temp.LOT9 != '' THEN DATEDIFF(DAY, lot9_days.date_value, GETDATE()) ELSE NULL END AS DELAY9,
			LOT10,CASE WHEN temp.LOT10 != '' THEN DATEDIFF(DAY, lot10_days.date_value, GETDATE()) ELSE NULL END AS DELAY10,
			DEVICE1,DEVICE2,DEVICE3,DEVICE4,DEVICE5,DEVICE6,DEVICE7,DEVICE8,DEVICE9,DEVICE10,temp.LOT2_RackAddress,temp.LOT2_RackName,DelayLot,
			LOT1Date,LOT1SDate,temp.AdaptorA,temp.AdaptorB,SUBSTRING(temp.DeviceName, 0, (SELECT CHARINDEX('-', temp.DeviceName))) AS CustomDevice,temp.Status,FTSetupReport.SetupStatus

		FROM DBxDW.dbo.scheduler_temp_ft AS temp
			INNER JOIN APCSProDB.method.device_names ON APCSProDB.method.device_names.name = temp.DeviceName COLLATE SQL_Latin1_General_CP1_CI_AS
			INNER JOIN DBx.dbo.FTSetupReport ON temp.MCNo = FTSetupReport.MCNo COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots ON temp.LotNo = lots.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot1 ON temp.LOT1 = lot1.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot2 ON temp.LOT2 = lot2.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot3 ON temp.LOT3 = lot3.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot4 ON temp.LOT4 = lot4.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot5 ON temp.LOT5 = lot5.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot6 ON temp.LOT6 = lot6.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot7 ON temp.LOT7 = lot7.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot8 ON temp.LOT8 = lot8.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot9 ON temp.LOT9 = lot9.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot10 ON temp.LOT10 = lot10.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.days AS lot1_days ON lot1.modify_out_plan_date_id = lot1_days.id 
			LEFT JOIN APCSProDB.trans.days AS lot2_days ON lot2.modify_out_plan_date_id = lot2_days.id
			LEFT JOIN APCSProDB.trans.days AS lot3_days ON lot3.modify_out_plan_date_id = lot3_days.id
			LEFT JOIN APCSProDB.trans.days AS lot4_days ON lot4.modify_out_plan_date_id = lot4_days.id
			LEFT JOIN APCSProDB.trans.days AS lot5_days ON lot5.modify_out_plan_date_id = lot5_days.id
			LEFT JOIN APCSProDB.trans.days AS lot6_days ON lot6.modify_out_plan_date_id = lot6_days.id
			LEFT JOIN APCSProDB.trans.days AS lot7_days ON lot7.modify_out_plan_date_id = lot7_days.id
			LEFT JOIN APCSProDB.trans.days AS lot8_days ON lot8.modify_out_plan_date_id = lot8_days.id
			LEFT JOIN APCSProDB.trans.days AS lot9_days ON lot9.modify_out_plan_date_id = lot9_days.id
			LEFT JOIN APCSProDB.trans.days AS lot10_days ON lot10.modify_out_plan_date_id = lot10_days.id
		where temp.PackageName in (SELECT * from STRING_SPLIT ( @PKG , ',' ))	
			and [APCSProDB].method.device_names.alias_package_group_id = 33
			--and [MCNo] not like '%ith%'
			--and [MCNo] not like '%-z-%'
			--and [MCNo] not like '%-099%'
			and temp.[MCNo] not like '%-000'
			--OR (FTSetupReport.SetupStatus = 'CANCELED' OR FTSetupReport.SetupStatus = 'POWEROFF')
	END
	ELSE
	BEGIN
		--select distinct temp.MCNo,temp.McId,temp.oprate,temp.setupid,temp.LotNo,temp.PackageName,temp.DeviceName,temp.ProgramName,temp.TesterType
		--,temp.TestFlow,temp.TestBoxA,temp.TestBoxB,temp.DutcardA,temp.DutcardB,temp.OptionName1,temp.OptionName2
		--,temp.[Status],temp.LOT1,LOT2,LOT3,LOT4,LOT5,LOT6,LOT7,LOT8,LOT9,LOT10
		--,DEVICE1,DEVICE2,DEVICE3,DEVICE4,DEVICE5,DEVICE6,DEVICE7,DEVICE8,DEVICE9,DEVICE10
		--,temp.LOT2_RackAddress,temp.LOT2_RackName,DelayLot,LOT1Date,LOT1SDate ,temp.AdaptorA,temp.AdaptorB,  SUBSTRING (DeviceName , 0,(SELECT CHARINDEX('-', DeviceName))) as CustomDevice
		--from DBxDW.dbo.scheduler_temp_ft as temp
		--INNER JOIN APCSProDB.method.device_names on APCSProDB.method.device_names.name =  temp.DeviceName COLLATE SQL_Latin1_General_CP1_CI_AS
		--where PackageName in (SELECT * from STRING_SPLIT ( @PKG , ',' ))
		--and [APCSProDB].method.device_names.alias_package_group_id != 33
		--	--and [MCNo] not like '%-M-%'
		--	--and [MCNo] not like '%ith%'
		--	--and [MCNo] not like '%-z-%'
		--	and temp.[MCNo] not like '%-000'
		--	and temp.[MCNo] not like '%TP-%'
		--	--and temp.MCNo NOT IN ('FT-M-150','FT-M-167')

		--select distinct temp.MCNo,temp.McId,temp.oprate,temp.setupid,temp.LotNo,temp.PackageName,temp.DeviceName,temp.ProgramName,temp.TesterType
		--,temp.TestFlow,temp.TestBoxA,temp.TestBoxB,temp.DutcardA,temp.DutcardB,temp.OptionName1,temp.OptionName2
		--,temp.[Status],temp.LOT1,LOT2,LOT3,LOT4,LOT5,LOT6,LOT7,LOT8,LOT9,LOT10
		--,DEVICE1,DEVICE2,DEVICE3,DEVICE4,DEVICE5,DEVICE6,DEVICE7,DEVICE8,DEVICE9,DEVICE10
		--,temp.LOT2_RackAddress,temp.LOT2_RackName,DelayLot,LOT1Date,LOT1SDate ,temp.AdaptorA,temp.AdaptorB,  SUBSTRING (temp.DeviceName , 0,(SELECT CHARINDEX('-', temp.DeviceName))) as CustomDevice
		--,FTSetupReport.SetupStatus
		--from DBxDW.dbo.scheduler_temp_ft as temp
		--INNER JOIN APCSProDB.method.device_names on APCSProDB.method.device_names.name =  temp.DeviceName COLLATE SQL_Latin1_General_CP1_CI_AS
		--INNER JOIN  DBx.dbo.FTSetupReport on temp.MCNo = FTSetupReport.MCNo COLLATE SQL_Latin1_General_CP1_CI_AS
		--where temp.PackageName in (SELECT * from STRING_SPLIT ( @PKG , ',' ))
		--and [APCSProDB].method.device_names.alias_package_group_id != 33
		--	--and [MCNo] not like '%-M-%'
		--	--and [MCNo] not like '%ith%'
		--	--and [MCNo] not like '%-z-%'
		--	and temp.[MCNo] not like '%-000'
		--	and temp.[MCNo] not like '%TP-%'
		--	--OR (FTSetupReport.SetupStatus = 'CANCELED' OR FTSetupReport.SetupStatus = 'POWEROFF')
		--	--and temp.MCNo NOT IN ('FT-M-150','FT-M-167')

		SELECT DISTINCT temp.MCNo,temp.McId,temp.oprate,temp.setupid,temp.LotNo,temp.PackageName,temp.DeviceName,temp.ProgramName,temp.TesterType,temp.TestFlow,
			temp.TestBoxA,temp.TestBoxB,temp.DutcardA,temp.DutcardB,temp.OptionName1,temp.OptionName2,temp.[Status],
			temp.LOT1,CASE WHEN temp.LOT1 != '' THEN DATEDIFF(DAY, lot1_days.date_value, GETDATE()) ELSE NULL END AS DELAY1,
			LOT2,CASE WHEN temp.LOT2 != '' THEN DATEDIFF(DAY, lot2_days.date_value, GETDATE()) ELSE NULL END AS DELAY2,
			LOT3,CASE WHEN temp.LOT3 != '' THEN DATEDIFF(DAY, lot3_days.date_value, GETDATE()) ELSE NULL END AS DELAY3,
			LOT4,CASE WHEN temp.LOT4 != '' THEN DATEDIFF(DAY, lot4_days.date_value, GETDATE()) ELSE NULL END AS DELAY4,
			LOT5,CASE WHEN temp.LOT5 != '' THEN DATEDIFF(DAY, lot5_days.date_value, GETDATE()) ELSE NULL END AS DELAY5,
			LOT6,CASE WHEN temp.LOT6 != '' THEN DATEDIFF(DAY, lot6_days.date_value, GETDATE()) ELSE NULL END AS DELAY6,
			LOT7,CASE WHEN temp.LOT7 != '' THEN DATEDIFF(DAY, lot7_days.date_value, GETDATE()) ELSE NULL END AS DELAY7,
			LOT8,CASE WHEN temp.LOT8 != '' THEN DATEDIFF(DAY, lot8_days.date_value, GETDATE()) ELSE NULL END AS DELAY8,
			LOT9,CASE WHEN temp.LOT9 != '' THEN DATEDIFF(DAY, lot9_days.date_value, GETDATE()) ELSE NULL END AS DELAY9,
			LOT10,CASE WHEN temp.LOT10 != '' THEN DATEDIFF(DAY, lot10_days.date_value, GETDATE()) ELSE NULL END AS DELAY10,
			DEVICE1,DEVICE2,DEVICE3,DEVICE4,DEVICE5,DEVICE6,DEVICE7,DEVICE8,DEVICE9,DEVICE10,temp.LOT2_RackAddress,temp.LOT2_RackName,DelayLot,
			LOT1Date,LOT1SDate,temp.AdaptorA,temp.AdaptorB,SUBSTRING(temp.DeviceName, 0, (SELECT CHARINDEX('-', temp.DeviceName))) AS CustomDevice,temp.Status,FTSetupReport.SetupStatus

		FROM DBxDW.dbo.scheduler_temp_ft AS temp
			INNER JOIN APCSProDB.method.device_names ON APCSProDB.method.device_names.name = temp.DeviceName COLLATE SQL_Latin1_General_CP1_CI_AS
			INNER JOIN DBx.dbo.FTSetupReport ON temp.MCNo = FTSetupReport.MCNo COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots ON temp.LotNo = lots.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot1 ON temp.LOT1 = lot1.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot2 ON temp.LOT2 = lot2.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot3 ON temp.LOT3 = lot3.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot4 ON temp.LOT4 = lot4.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot5 ON temp.LOT5 = lot5.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot6 ON temp.LOT6 = lot6.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot7 ON temp.LOT7 = lot7.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot8 ON temp.LOT8 = lot8.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot9 ON temp.LOT9 = lot9.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.lots AS lot10 ON temp.LOT10 = lot10.lot_no COLLATE SQL_Latin1_General_CP1_CI_AS
			LEFT JOIN APCSProDB.trans.days AS lot1_days ON lot1.modify_out_plan_date_id = lot1_days.id 
			LEFT JOIN APCSProDB.trans.days AS lot2_days ON lot2.modify_out_plan_date_id = lot2_days.id
			LEFT JOIN APCSProDB.trans.days AS lot3_days ON lot3.modify_out_plan_date_id = lot3_days.id
			LEFT JOIN APCSProDB.trans.days AS lot4_days ON lot4.modify_out_plan_date_id = lot4_days.id
			LEFT JOIN APCSProDB.trans.days AS lot5_days ON lot5.modify_out_plan_date_id = lot5_days.id
			LEFT JOIN APCSProDB.trans.days AS lot6_days ON lot6.modify_out_plan_date_id = lot6_days.id
			LEFT JOIN APCSProDB.trans.days AS lot7_days ON lot7.modify_out_plan_date_id = lot7_days.id
			LEFT JOIN APCSProDB.trans.days AS lot8_days ON lot8.modify_out_plan_date_id = lot8_days.id
			LEFT JOIN APCSProDB.trans.days AS lot9_days ON lot9.modify_out_plan_date_id = lot9_days.id
			LEFT JOIN APCSProDB.trans.days AS lot10_days ON lot10.modify_out_plan_date_id = lot10_days.id
		where temp.PackageName in (SELECT * from STRING_SPLIT ( @PKG , ',' ))
			and [APCSProDB].method.device_names.alias_package_group_id != 33
			--and [MCNo] not like '%-M-%'
			--and [MCNo] not like '%ith%'
			--and [MCNo] not like '%-z-%'
			and temp.[MCNo] not like '%-000'
			and temp.[MCNo] not like '%TP-%'
			--OR (FTSetupReport.SetupStatus = 'CANCELED' OR FTSetupReport.SetupStatus = 'POWEROFF')
			--and temp.MCNo NOT IN ('FT-M-150','FT-M-167')
	END
END
