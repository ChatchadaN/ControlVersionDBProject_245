-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_setupchecksheet_getbom]
	-- Add the parameters for the stored procedure here
	@CustomerDeviceName varchar(20), 
	@PackageName varchar(20), 
	@TestFlowName varchar(20), 
	@TesterTypeName varchar(50), 
	@PCMain varchar(50), 
	@isOIS bit = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	--RIST
	IF(@isOIS = 0) 
	BEGIN
		SELECT FTBom.ID
			 , FTBom.PackageID
			 , FTBom.FTDeviceID
			 , BomTesterType.TesterTypeID
			 , FTBom.BomTesterTypeID
			 , FTBom.TestChannel
			 , FTBom.TestFlowID
			 , FTBom.BomTestFlowID
			 , FTBom.PCMachineTypeID
			 , FTBom.TempOfProduct
			 , FTBom.TempOfMachine
			 , FTBom.DSStartDate
			 , FTBom.ESStartDate
			 , FTBom.CSSTartDate
			 , FTBom.PLStartDate
			 , FTBom.MPStartDate
			 , FTBom.SocketTypeID
			 , FTBom.TestProgram
			 , FTBom.TestTime
			 , FTBom.SpecialRank
			 , FTBom.InspectionCondition
			 , FTBom.RPM
			 , FTBom.BoxCapa
			 , FTBom.TotalBoxCapa
			 , FTBom.LeadTimeOfLot
			 , FTBom.ProductionLine
			 , FTBom.TubeTray
			 , FTBom.Emboss
			 , FTBom.Reel
			 , FTBom.HandlerLeadTime
			 , FTBom.TesterLoadTime

		FROM [DBx].[BOM].[FTBom] 
		INNER JOIN [DBx].[BOM].[FTDevice]		ON FTDevice.ID		= FTBom.FTDeviceID
		INNER JOIN [DBx].[BOM].[Package]		ON Package.ID		= FTBom.PackageID
		INNER JOIN [DBx].[BOM].[BomTesterType]	ON BomTesterType.ID = FTBom.BomTesterTypeID
		INNER JOIN [DBx].[dbo].[TestFlow]		ON TestFlow.ID		= FTBom.TestFlowID
		INNER JOIN [DBx].[dbo].[TesterType]		ON TesterType.ID	= BomTesterType.TesterTypeID
		INNER JOIN [DBx].[EQP].[FTPCType]		ON FTPCType.ID		= FTBom.PCMachineTypeID
                      
		WHERE (FTDevice.Name = @CustomerDeviceName) 
		  AND (FTPCType.PCMain = @PCMain) 
		  AND (TestFlow.Name = @TestFlowName) 
		  AND (TesterType.Name = @TesterTypeName) 
		  AND (Package.AssyName = @PackageName) --[BOM].[Package] can't use becoz it not same as apcspro and use in another program in PD site
	END
	--REPI
	ELSE
	BEGIN
		DECLARE @FTDevice varchar(30), @InputRank varchar(10)
		SET @FTDevice = SUBSTRING(@CustomerDeviceName, 0, LEN(@CustomerDeviceName) - CHARINDEX('-', REVERSE(@CustomerDeviceName)) + 1)
		SET @InputRank = RIGHT(@CustomerDeviceName, CASE WHEN (CHARINDEX('-', REVERSE(@CustomerDeviceName)) - 1) = -1 THEN 0 ELSE CHARINDEX('-', REVERSE(@CustomerDeviceName)) - 1 END)
		
		IF(@InputRank = '')
		BEGIN
			SET @InputRank = '-'
		END

		SELECT OIS.*
		FROM DBx.dbo.OIS
		CROSS APPLY string_split([OIS].InputRank, '/') AS str
		WHERE [OIS].DeviceName	 = @FTDevice 
		  AND [OIS].TestFlowName = @TestFlowName
		  AND [OIS].TestTypeName = @TesterTypeName
		  AND [OIS].Package1	 = @PackageName
		  AND str.value = @InputRank
	END
END
