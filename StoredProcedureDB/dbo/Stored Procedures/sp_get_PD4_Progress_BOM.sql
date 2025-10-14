-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_PD4_Progress_BOM]
	-- Add the parameters for the stored procedure here
	@PackageName VARCHAR(50),@MachineType VARCHAR(50)
	--,@TestFlow VARCHAR(10)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	CREATE TABLE #BOM_FT_SELECT_2F_MAX
	(
			[PackageName]		VARCHAR(50)
			,[DeviceName]		VARCHAR(50)
			,[TestFlow]			VARCHAR(50)
			,[MachineType]		VARCHAR(50)
			,[TestEquipment]	VARCHAR(50)
			,[TesterType]		VARCHAR(50)

			,[TestTime]			REAL
			,[RPM]				REAL
			,[BoxCapa]			REAL
			,[TotalBoxCapa]		REAL
			,[LeadTimeOfLot]	REAL
	)

	INSERT INTO #BOM_FT_SELECT_2F_MAX

	SELECT
			[BOM_FT_SELECT_2F].[AssyName] AS [PackageName]
			,[BOM_FT_SELECT_2F].[FTDevice] AS [DeviceName]
			,[BOM_FT_SELECT_2F].[BomTestFlow] AS [TestFlow]
			,[BOM_FT_SELECT_2F].[PCType] AS [MachineType]
			,[DBx].[BOM].[TestEquipment].[Name] AS [TestEquipment]
			,[BOM_FT_SELECT_2F].[TesterType]
			
			,MAX([BOM_FT_SELECT_2F].[TestTime]) AS [TestTime]
			,MAX([BOM_FT_SELECT_2F].[RPM]) AS [RPM]
			,MAX([BOM_FT_SELECT_2F].[BoxCapa]) AS [BoxCapa]
			,MAX([BOM_FT_SELECT_2F].[TotalBoxCapa]) AS [TotalBoxCapa]
			,MAX([BOM_FT_SELECT_2F].[LeadTimeOfLot]) AS [LeadTimeOfLot]

	FROM

	(

			SELECT
					[DBx].[BOM].[FTBom].[ID]

					--,[DBx].[BOM].[FTBom].[PackageID] 
					,[DBx].[BOM].[Package].[FullName]
					,[DBx].[BOM].[Package].[AssyName]

					--,[DBx].[BOM].[Package].[PackageGroupID]
					,[DBx].[BOM].[PackageGroup].[Name] AS [PackageGroup]

					--,[DBx].[BOM].[FTBom].[FTDeviceID]
					,[DBx].[BOM].[FTDevice].[Name] AS [FTDevice]

					--,[DBx].[BOM].[FTBom].[TesterTypeID]
					,[DBx].[dbo].[TesterType].[Name] AS [TesterType]
		
					--,[DBx].[BOM].[FTBom].[BomTesterTypeID]
					,[DBx].[BOM].[BomTesterType].[Name] AS [BomTesterType]

					,[DBx].[BOM].[FTBom].[TestChannel]

					--,[DBx].[BOM].[FTBom].[TestFlowID]
					,[DBx].[dbo].[TestFlow].[Name] AS [TestFlow]

					--,[DBx].[BOM].[FTBom].[BomTestFlowID]
					,[DBx].[BOM].[BomTestFlow].[Name] AS [BomTestFlow]

					--,[DBx].[BOM].[FTBom].[PCMachineTypeID]
					,[DBx].[EQP].[FTPCType].[PCType]
					,[DBx].[EQP].[FTPCType].[PCMain]

					,[TempOfProduct]
					,[TempOfMachine]
					,[DSStartDate]
					,[ESStartDate]
					,[CSSTartDate]
					,[PLStartDate]
					,[MPStartDate]

					--,[DBx].[BOM].[FTBom].[SocketTypeID]
					,[DBx].[dbo].[SocketType].[Name] AS [SocketType]

					--,[DBx].[dbo].[SocketType].[SocketPinTypeID]
					,[DBx].[dbo].[SocketPinType].[Name] AS [SocketPinType]

					,[TestProgram]
					,[TestTime]
					,[SpecialRank]
					,[InspectionCondition]
					,[RPM]
					,[BoxCapa]
					,[TotalBoxCapa]
					,[LeadTimeOfLot]
					,[ProductionLine]
					,[TubeTray]
					,[Emboss]
					,[Reel]
					,[HandlerLeadTime]
					,[TesterLoadTime]

			FROM 
					[DBx].[BOM].[FTBom]
  
			INNER JOIN
					[DBx].[BOM].[Package]
			ON
					[DBx].[BOM].[Package].[ID] = [DBx].[BOM].[FTBom].[PackageID]

			INNER JOIN
					[DBx].[BOM].[PackageGroup]
			ON
					[DBx].[BOM].[PackageGroup].[ID] = [DBx].[BOM].[Package].[PackageGroupID]

			INNER JOIN
					[DBx].[BOM].[FTDevice]
			ON
					[DBx].[BOM].[FTDevice].[ID] = [DBx].[BOM].[FTBom].[FTDeviceID]

			INNER JOIN
					[DBx].[BOM].[BomTesterType]
			ON
					[DBx].[BOM].[BomTesterType].[ID] = [DBx].[BOM].[FTBom].[BomTesterTypeID]

			INNER JOIN
					[DBx].[BOM].[BomTestFlow]
			ON
					[DBx].[BOM].[BomTestFlow].[ID] = [DBx].[BOM].[FTBom].[BomTestFlowID]

			INNER JOIN 
					[DBx].[dbo].[TesterType]
			ON
					[DBx].[dbo].[TesterType].[ID] = [DBx].[BOM].[FTBom].[TesterTypeID]

			INNER JOIN
					[DBx].[dbo].[TestFlow]
			ON
					[DBx].[dbo].[TestFlow].[ID] = [DBx].[BOM].[FTBom].[TestFlowID]

			INNER JOIN
					[DBx].[EQP].[FTPCType]
			ON
					[DBx].[EQP].[FTPCType].[ID] = [DBx].[BOM].[FTBom].[PCMachineTypeID]

			INNER JOIN
					[DBx].[dbo].[SocketType]
			ON
					[DBx].[dbo].[SocketType].[ID] = [DBx].[BOM].[FTBom].[SocketTypeID]

			INNER JOIN
					[DBx].[dbo].[SocketPinType]
			ON
					[DBx].[dbo].[SocketPinType].[ID] = [DBx].[dbo].[SocketType].[SocketPinTypeID]

			WHERE
					(([DBx].[BOM].[FTBom].[ProductionLine] LIKE 'FT-2F-%' AND [DBx].[BOM].[Package].[AssyName] NOT IN ('SSOP-B10W','TSSOP-B8J','HTQFP64V','HTQFP64VHF','MSOP8','MSOP8-HF')) OR

					([DBx].[BOM].[Package].[AssyName] = 'TSSOP-B8J' AND [DBx].[EQP].[FTPCType].[PCMain] LIKE 'IFTN%') OR
		
					([DBx].[BOM].[Package].[AssyName] IN ('HTQFP64V','HTQFP64VHF') AND [DBx].[BOM].[FTDevice].[Name] LIKE 'BU%' AND [DBx].[EQP].[FTPCType].[PCMain] LIKE 'NS-%') OR
					([DBx].[BOM].[Package].[AssyName] IN ('HTQFP64V','HTQFP64VHF') AND [DBx].[BOM].[FTDevice].[Name] NOT LIKE 'BU%') OR
		
					([DBx].[BOM].[Package].[AssyName] IN ('MSOP8','MSOP8-HF') AND [DBx].[BOM].[FTDevice].[Name] LIKE 'BR%' AND [DBx].[EQP].[FTPCType].[PCMain] LIKE 'NS-%') OR
					([DBx].[BOM].[Package].[AssyName] IN ('MSOP8','MSOP8-HF') AND [DBx].[BOM].[FTDevice].[Name] NOT LIKE 'BR%' AND [DBx].[EQP].[FTPCType].[PCMain] LIKE 'IFTN-%') OR
					([DBx].[BOM].[Package].[AssyName] IN ('MSOP8','MSOP8-HF') AND [DBx].[BOM].[FTDevice].[Name] NOT LIKE 'BR%'))

	) AS [BOM_FT_SELECT_2F]

	LEFT JOIN
			[DBx].[BOM].[FTBomTestEquipment]
	ON
			[DBx].[BOM].[FTBomTestEquipment].[FTBomID] = [BOM_FT_SELECT_2F].[ID]

	LEFT JOIN
			[DBx].[BOM].[TestEquipment]
	ON
			[DBx].[BOM].[TestEquipment].[ID] = [DBx].[BOM].[FTBomTestEquipment].[TestEquipmentID]

	LEFT JOIN
			[DBx].[EQP].[Equipment]
	ON
			[DBx].[EQP].[Equipment].[SubType] = [DBx].[BOM].[TestEquipment].[Name]

	WHERE 
			[DBx].[EQP].[Equipment].[EquipmentTypeID] IN ('1','2')
			AND [BOM_FT_SELECT_2F].[AssyName] LIKE @PackageName
			AND [BOM_FT_SELECT_2F].[PCType] LIKE @MachineType

	GROUP BY
			[BOM_FT_SELECT_2F].[AssyName]
			,[BOM_FT_SELECT_2F].[TesterType]
			,[BOM_FT_SELECT_2F].[FTDevice]
			,[BOM_FT_SELECT_2F].[PCType]
			,[BOM_FT_SELECT_2F].[BomTestFlow]
			,[DBx].[BOM].[TestEquipment].[Name]

	--/...

	CREATE TABLE #BOM_FT_SELECT_MSOP8
	(
			[PackageName]		VARCHAR(50)
			,[DeviceName]		VARCHAR(50)
			,[TestFlow]			VARCHAR(10)
			,[Total]			INTEGER
	)

	INSERT INTO #BOM_FT_SELECT_MSOP8

	SELECT 
			[PackageName]
			,[DeviceName]
			,[TestFlow]
			,COUNT([DeviceName]) AS [Total]

	FROM #BOM_FT_SELECT_2F_MAX AS [BOM_FT_SELECT_2F_MAX]

	WHERE [DeviceName] LIKE 'BR%' AND [PackageName] IN ('MSOP8','MSOP8-HF') AND [TestFlow] <> 'A2 ASI (S)' 

	GROUP BY 
			[PackageName]
			,[DeviceName]
			,[TestFlow]

	--/...

	CREATE TABLE #BOM_FT_SELECT_MSOP8_DOUBLE_MAX
	(
			[PackageName]		VARCHAR(50)
			,[DeviceName]		VARCHAR(50)
			,[TestFlow]			VARCHAR(10)

			,[TestTime]			REAL
			,[RPM]				REAL
			,[BoxCapa]			REAL
			,[TotalBoxCapa]		REAL
			,[LeadTimeOfLot]	REAL
	)

	INSERT INTO #BOM_FT_SELECT_MSOP8_DOUBLE_MAX

	SELECT
			[BOM_FT_SELECT_2F_MAX].[PackageName]
			,[BOM_FT_SELECT_2F_MAX].[DeviceName]
			,[BOM_FT_SELECT_2F_MAX].[TestFlow]

			,MAX([TestTime]) AS [TestTime]
			,MAX([RPM]) AS [TestTime]
			,MAX([BoxCapa]) AS [TestTime]
			,MAX([TotalBoxCapa]) AS [TestTime]
			,MAX([LeadTimeOfLot]) AS [TestTime]

	FROM
			#BOM_FT_SELECT_2F_MAX AS [BOM_FT_SELECT_2F_MAX]

	INNER JOIN
			#BOM_FT_SELECT_MSOP8 AS [BOM_FT_SELECT_MSOP8]

	ON
			[BOM_FT_SELECT_MSOP8].[PackageName] = [BOM_FT_SELECT_2F_MAX].[PackageName]
			AND [BOM_FT_SELECT_MSOP8].[DeviceName] = [BOM_FT_SELECT_2F_MAX].[DeviceName]
			AND [BOM_FT_SELECT_MSOP8].[TestFlow] = [BOM_FT_SELECT_2F_MAX].[TestFlow]

	WHERE [BOM_FT_SELECT_MSOP8].[Total] = '2'

	GROUP BY
			[BOM_FT_SELECT_2F_MAX].[PackageName]
			,[BOM_FT_SELECT_2F_MAX].[DeviceName]
			,[BOM_FT_SELECT_2F_MAX].[TestFlow]

	--/...

	CREATE TABLE #FT_BOM_LAST
	(
			[PackageName]		VARCHAR(50)
			,[DeviceName]		VARCHAR(50)
			,[TestFlow]			VARCHAR(50)
			,[MachineType]		VARCHAR(50)
			,[TestEquipment]	VARCHAR(50)
			,[TesterType]		VARCHAR(50)

			,[TestTime]			REAL
			,[RPM]				REAL
			,[BoxCapa]			REAL
			,[TotalBoxCapa]		REAL
			,[LeadTimeOfLot]	REAL
	)

	INSERT INTO #FT_BOM_LAST

	SELECT
			[BOM_FT_SELECT_2F_MAX].[PackageName]
			,[BOM_FT_SELECT_2F_MAX].[DeviceName]
			,[BOM_FT_SELECT_2F_MAX].[TestFlow]
			,CASE 
					WHEN [MachineType] NOT LIKE '%_8M' AND [TestTime] <= '3.34' THEN 'NS80SH-MS8'
					WHEN [MachineType] NOT LIKE '%_8M' AND [TestTime] > '3.34' THEN 'NS80-MS8'
					ELSE [MachineType] END [MachineType]
			,[TestEquipment]
			,[TesterType]

			,[TestTime]
			,[RPM]
			,[BoxCapa]
			,[TotalBoxCapa]
			,[LeadTimeOfLot]

	FROM
			#BOM_FT_SELECT_2F_MAX AS [BOM_FT_SELECT_2F_MAX]

	INNER JOIN
			#BOM_FT_SELECT_MSOP8 AS [BOM_FT_SELECT_MSOP8]

	ON
			[BOM_FT_SELECT_MSOP8].[PackageName] = [BOM_FT_SELECT_2F_MAX].[PackageName] AND
			[BOM_FT_SELECT_MSOP8].[DeviceName] = [BOM_FT_SELECT_2F_MAX].[DeviceName] AND
			[BOM_FT_SELECT_MSOP8].[TestFlow] = [BOM_FT_SELECT_2F_MAX].[TestFlow]

	WHERE [BOM_FT_SELECT_MSOP8].[Total] = '1'

	UNION

	SELECT
			[BOM_FT_SELECT_2F_MAX].[PackageName]
			,[BOM_FT_SELECT_2F_MAX].[DeviceName]
			,[BOM_FT_SELECT_2F_MAX].[TestFlow]
			,[MachineType]
			,[TestEquipment]
			,[TesterType]

			,[BOM_FT_SELECT_MSOP8_DOUBLE_MAX].[TestTime]
			,[BOM_FT_SELECT_MSOP8_DOUBLE_MAX].[RPM]
			,[BOM_FT_SELECT_MSOP8_DOUBLE_MAX].[BoxCapa]
			,[BOM_FT_SELECT_MSOP8_DOUBLE_MAX].[TotalBoxCapa]
			,[BOM_FT_SELECT_MSOP8_DOUBLE_MAX].[LeadTimeOfLot]

	FROM
			#BOM_FT_SELECT_2F_MAX AS [BOM_FT_SELECT_2F_MAX]

	INNER JOIN
			#BOM_FT_SELECT_MSOP8_DOUBLE_MAX AS [BOM_FT_SELECT_MSOP8_DOUBLE_MAX]

	ON
			[BOM_FT_SELECT_MSOP8_DOUBLE_MAX].[PackageName] = [BOM_FT_SELECT_2F_MAX].[PackageName] AND
			[BOM_FT_SELECT_MSOP8_DOUBLE_MAX].[DeviceName] = [BOM_FT_SELECT_2F_MAX].[DeviceName] AND
			[BOM_FT_SELECT_MSOP8_DOUBLE_MAX].[TestFlow] = [BOM_FT_SELECT_2F_MAX].[TestFlow]

	WHERE
			([TestEquipment] NOT LIKE '%_8M' AND [BOM_FT_SELECT_2F_MAX].[TestTime] > '6.19') OR
			([TestEquipment] LIKE '%_8M' AND [BOM_FT_SELECT_2F_MAX].[TestTime] <= '6.19') 

	UNION
	
	SELECT * FROM #BOM_FT_SELECT_2F_MAX AS [BOM_FT_SELECT_2F_MAX]

	WHERE NOT ([DeviceName] LIKE 'BR%' AND [PackageName] IN ('MSOP8','MSOP8-HF'))

	SELECT * FROM #FT_BOM_LAST

	DROP TABLE #BOM_FT_SELECT_2F_MAX
	DROP TABLE #BOM_FT_SELECT_MSOP8
	DROP TABLE #BOM_FT_SELECT_MSOP8_DOUBLE_MAX
	DROP TABLE #FT_BOM_LAST

END
