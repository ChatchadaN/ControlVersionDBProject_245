-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_temp_ft_v2] 
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
		 select distinct temp.MCNo,temp.McId,temp.oprate,temp.setupid,temp.LotNo,temp.PackageName,temp.DeviceName,temp.ProgramName,temp.TesterType
		,temp.TestFlow,temp.TestBoxA,temp.TestBoxB,temp.DutcardA,temp.DutcardB,temp.OptionName1,temp.OptionName2
		,temp.[Status],temp.LOT1,LOT2,LOT3,LOT4,LOT5,LOT6,LOT7,LOT8,LOT9,LOT10
		,DEVICE1,DEVICE2,DEVICE3,DEVICE4,DEVICE5,DEVICE6,DEVICE7,DEVICE8,DEVICE9,DEVICE10
		,temp.LOT2_RackAddress,temp.LOT2_RackName,DelayLot,LOT1Date,LOT1SDate,temp.AdaptorA,temp.AdaptorB ,  SUBSTRING (temp.DeviceName , 0,(SELECT CHARINDEX('-', temp.DeviceName))) as CustomDevice
		,temp.Status
		,FTSetupReport.SetupStatus
		from DBxDW.dbo.scheduler_temp_ft  as temp
		INNER JOIN APCSProDB.method.device_names on APCSProDB.method.device_names.name =  temp.DeviceName COLLATE SQL_Latin1_General_CP1_CI_AS
		INNER JOIN  DBx.dbo.FTSetupReport on temp.MCNo = FTSetupReport.MCNo COLLATE SQL_Latin1_General_CP1_CI_AS
		where temp.PackageName in (SELECT * from STRING_SPLIT ( @PKG , ',' ))	
			and [APCSProDB].method.device_names.alias_package_group_id = 33
			--and [MCNo] not like '%ith%'
			--and [MCNo] not like '%-z-%'
			--and [MCNo] not like '%-099%'
			and temp.[MCNo] not like '%-000'

			order by MCNo
	END
	ELSE
	BEGIN
		select distinct temp.MCNo,temp.McId,temp.oprate,temp.setupid,temp.LotNo,temp.PackageName,temp.DeviceName,temp.ProgramName,temp.TesterType
		,temp.TestFlow,temp.TestBoxA,temp.TestBoxB,temp.DutcardA,temp.DutcardB,temp.OptionName1,temp.OptionName2
		,temp.[Status],temp.LOT1,LOT2,LOT3,LOT4,LOT5,LOT6,LOT7,LOT8,LOT9,LOT10
		,DEVICE1,DEVICE2,DEVICE3,DEVICE4,DEVICE5,DEVICE6,DEVICE7,DEVICE8,DEVICE9,DEVICE10
		,temp.LOT2_RackAddress,temp.LOT2_RackName,DelayLot,LOT1Date,LOT1SDate ,temp.AdaptorA,temp.AdaptorB,  SUBSTRING (temp.DeviceName , 0,(SELECT CHARINDEX('-', temp.DeviceName))) as CustomDevice
		,FTSetupReport.SetupStatus
		from DBxDW.dbo.scheduler_temp_ft as temp
		INNER JOIN APCSProDB.method.device_names on APCSProDB.method.device_names.name =  temp.DeviceName COLLATE SQL_Latin1_General_CP1_CI_AS
		INNER JOIN  DBx.dbo.FTSetupReport on temp.MCNo = FTSetupReport.MCNo COLLATE SQL_Latin1_General_CP1_CI_AS
		where temp.PackageName in (SELECT * from STRING_SPLIT ( @PKG , ',' ))
		and [APCSProDB].method.device_names.alias_package_group_id != 33
			--and [MCNo] not like '%-M-%'
			--and [MCNo] not like '%ith%'
			--and [MCNo] not like '%-z-%'
			and temp.[MCNo] not like '%-000'
			and temp.[MCNo] not like '%TP-%'
			--and temp.MCNo NOT IN ('FT-M-150','FT-M-167')
	END
END
