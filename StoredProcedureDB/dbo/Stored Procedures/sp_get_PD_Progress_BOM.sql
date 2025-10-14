-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_PD_Progress_BOM]
	-- Add the parameters for the stored procedure here
	@PackageName VARCHAR(50),@MachineType VARCHAR(50)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

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
					([DBx].[BOM].[Package].[AssyName] LIKE 'HTQFP64%' AND [DBx].[BOM].[FTDevice].[Name] NOT IN ('BD64532EKV-BZG','BD64532EKV-BZGE2') AND [DBx].[EQP].[FTPCType].[PCMain] IN ('IFTN-44-B','IFTN-44-BHF','NS80-HTQ64'))
					OR ([DBx].[BOM].[Package].[AssyName] LIKE '%HF' AND [DBx].[BOM].[FTDevice].[Name] NOT IN ('BD64532EKV-BZG','BD64532EKV-BZGE2') AND [DBx].[EQP].[FTPCType].[PCMain] IN ('IFTN-44-B','IFTN-44-BHF','NS80-HTQ64'))
					OR ([DBx].[BOM].[Package].[AssyName] IN ('VQFP48C','VQFP64','QFP32','SQFP-T52'))

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
			AND [DBx].[BOM].[TestEquipment].[Name] NOT LIKE 'D7 %'
			AND [BOM_FT_SELECT_2F].[AssyName] LIKE @PackageName
			AND [BOM_FT_SELECT_2F].[PCType] LIKE @MachineType

	GROUP BY
			[BOM_FT_SELECT_2F].[AssyName]
			,[BOM_FT_SELECT_2F].[TesterType]
			,[BOM_FT_SELECT_2F].[FTDevice]
			,[BOM_FT_SELECT_2F].[PCType]
			,[BOM_FT_SELECT_2F].[BomTestFlow]
			,[DBx].[BOM].[TestEquipment].[Name]

END
