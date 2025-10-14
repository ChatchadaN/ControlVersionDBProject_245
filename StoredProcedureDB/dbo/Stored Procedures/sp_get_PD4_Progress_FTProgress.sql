-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_PD4_Progress_FTProgress]
	-- Add the parameters for the stored procedure here
	@PackageName VARCHAR(50),@MachineType VARCHAR(50),@DateStart DATE,@DataType VARCHAR(50)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	--DECLARE @DataType		VARCHAR(50)
	--DECLARE @PackageName	VARCHAR(50)
	--DECLARE @MachineType	VARCHAR(50)
	--DECLARE @DateStart		DATE

	DECLARE @DateTimeStart	DATETIME

	DECLARE @MaxAuto		INTEGER
	DECLARE @MaxLeadTime	INTEGER
	DECLARE @CountAuto		INTEGER
	DECLARE @CountLeadtime	INTEGER
	
	DECLARE @CountDay		INTEGER

	--SET @DataType = 'Equipment'
	--SET @PackageName = 'HTQFP%'
	--SET @MachineType = '%'
	--SET @DateStart = '2020-01-01'

	SET @DateTimeStart = @DateStart
	SET @DateTimeStart = DATEADD(HOUR,8,@DateTimeStart)

	SET @MaxAuto = 0
	SET @MaxLeadTime = 0

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
			EXEC [StoredProcedureDB].[dbo].[sp_get_PD4_Progress_BOM] @PackageName, @MachineType

	CREATE TABLE #LOT_APCSPro
	(
			[PackageGroup]			CHAR(10)
			,[Package]				CHAR(20)
			,[Package_FT]			CHAR(20)
			,[Device]				CHAR(20)
			,[Device_FT]			VARCHAR(20)
			,[Input_Date]			DATE
			,[Ship_Date]			DATE
			,[Lot_No]				CHAR(20)
			,[InputQty_Pcs]			INT
			,[LastStep_No]			INT

			,[FB_Job]				NVARCHAR(20)
			,[FB_StartTime]			DATETIME
			,[FB_EndTime]			DATETIME
			,[FB_PassQty_Pcs]		INT

			,[F_Job]				NVARCHAR(20)
			,[F_StartTime]			DATETIME
			,[F_EndTime]			DATETIME
			,[F_ProcessTime_Min]	INT
			,[F_PassQty_Pcs]		INT

			,[O_Job]				NVARCHAR(20)
			,[O_Mc_No]				NVARCHAR(30)
			,[O_Mc_Model]			NVARCHAR(30)
			,[O_StartTime]			DATETIME
			,[O_EndTime]			DATETIME
			,[O_ProcessTime_Min]	INT
			,[O_PassQty_Pcs]		INT

	)

	INSERT INTO #LOT_APCSPro
			EXEC [dbo].[sp_get_PD4_Progress_APCSPro] @DateStart, N'M', N'2', N'FT', @PackageName, NULL

	CREATE TABLE #CAC_DATA_LAST
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

			,[InputDay]			DATE
			,[LeadTime_Day]		INTEGER
			,[InputDay_Leadtime] DATE
			,[LotNo]			VARCHAR(50)
			,[PiecesInput]		REAL

			,[FRONT_Name]		VARCHAR(50)
			,[FRONT_Start]		DATETIME
			,[FRONT_End]		DATETIME

			,[OWNER_Name]		VARCHAR(50)
			,[OWNER_McNo]		VARCHAR(50)
			,[OWNER_Start]		DATETIME
			,[OWNER_End]		DATETIME

			,[PiecesActual]		REAL
	)

	INSERT INTO #CAC_DATA_LAST
			
			SELECT
					[PackageName]
					,[DeviceName]
					,'A' + SUBSTRING([LOT_APCSPro].[O_Job],6,1) AS [TestFlow]			

					,[MachineType]
					,[TestEquipment]
					,[TesterType]

					,[TestTime]
					,[RPM]
					,[BoxCapa]
					,[TotalBoxCapa]
					,[LeadTimeOfLot]

					,[Input_Date]			AS [InputDay]
					,ISNULL([LeadTimeInput_Device].[LeadTime_Day],[LeadTimeInput_Package].[LeadTime_Day]) AS [LeadTime_Day]
					,DATEADD(DAY,ISNULL([LeadTimeInput_Device].[LeadTime_Day],[LeadTimeInput_Package].[LeadTime_Day]),[Input_Date])	AS [InputDay_Leadtime]
					,[Lot_No]				AS [LotNo]
					,[InputQty_Pcs]/1000			AS [PiecesInput]

					,[FB_Job]				AS [FRONT_Name]
					,[F_StartTime]			AS [FRONT_Start]
					,[F_EndTime]			AS [FRONT_End]

					,[O_Job]				AS [OWNER_Name]
					,[O_Mc_No]				AS [OWNER_McNo]
					,[O_StartTime]			AS [OWNER_Start]
					,[O_EndTime]			AS [OWNER_End]

					--,[O_PassQty_Pcs]/1000		AS [PiecesActual]
					,[InputQty_Pcs]/1000		AS [PiecesActual]
			FROM
					#LOT_APCSPro AS [LOT_APCSPro]

			INNER JOIN
					#FT_BOM_LAST AS [FT_BOM_LAST]
			ON
					[FT_BOM_LAST].[PackageName] = [LOT_APCSPro].[Package_FT]
					AND [FT_BOM_LAST].[DeviceName] = [LOT_APCSPro].[Device]
					AND [FT_BOM_LAST].[TestFlow] = 'A' + SUBSTRING([LOT_APCSPro].[O_Job],6,1)

			LEFT JOIN
					OPENDATASOURCE('SQLNCLI', 'Data Source = 10.28.32.122;User ID=sa;Password=P@$$w0rd;').[DBx].[BOM_FL].[LeadTimeInput_Device] AS [LeadTimeInput_Device]
			ON
					[LeadTimeInput_Device].[Package_Name] = [FT_BOM_LAST].[PackageName]
					AND [LeadTimeInput_Device].[Device_Name] = [FT_BOM_LAST].[DeviceName]

			LEFT JOIN
					OPENDATASOURCE('SQLNCLI', 'Data Source = 10.28.32.122;User ID=sa;Password=P@$$w0rd;').[DBx].[BOM_FL].[LeadTimeInput_Package] AS [LeadTimeInput_Package]
			ON
					[LeadTimeInput_Package].[Package_Name] = [FT_BOM_LAST].[PackageName]


	--CREATE TABLE #CHECK_DEVICE
	--(
	--		[PackageName]		VARCHAR(50)
	--		,[DeviceName]		VARCHAR(50)
	--		,[TesterType]		VARCHAR(50)
	--		,[TestFlow]			VARCHAR(50)
	--		,[TestEquipment]	VARCHAR(50)
	--		,[MachineType]		VARCHAR(50)
	--		,[OWNER_McNo]		VARCHAR(50)
	--)

	--INSERT INTO #CHECK_DEVICE
	--		SELECT
	--				[PackageName]
	--				,[DeviceName]
	--				,[TesterType]
	--				,[TestFlow]
	--				,[TestEquipment] 
	--				,[MachineType]
	--				,[OWNER_McNo]
	--		FROM
	--				#CAC_DATA_LAST
	--		GROUP BY
	--				[PackageName]
	--				,[DeviceName]
	--				,[TesterType]
	--				,[TestFlow]
	--				,[TestEquipment] 
	--				,[MachineType]
	--				,[OWNER_McNo]


	--/ < STRAT > Euipment and Machine Setup

	CREATE TABLE #MACHINE_SETUP
	(
			[TestFlow]			VARCHAR(50)
			,[Job]				NVARCHAR(20)
			,[TestEquipment]	VARCHAR(50)
			,[PackageName]		VARCHAR(50)
			,[DeviceName]		VARCHAR(50)
			,[MCNo]				VARCHAR(50)
			,[Date]				DATE
	)

	INSERT INTO #MACHINE_SETUP
			EXEC [dbo].[sp_get_PD4_Progress_MachineSetup] @DateStart


	CREATE TABLE #MACHINE_SETUP_LAST
	(
			[PackageName]		VARCHAR(50)
			,[DeviceName]		VARCHAR(50)
			,[TesterType]		VARCHAR(50)
			,[TestFlow]			VARCHAR(50)
			,[TestEquipment]	VARCHAR(50)
			,[MachineType]		VARCHAR(50)
			,[OWNER_McNo]		VARCHAR(50)

			,[BoxCapa]			REAL
			,[Date]				DATE
	)

	INSERT INTO #MACHINE_SETUP_LAST

	SELECT
			[FT_BOM_LAST].[PackageName]
			,[FT_BOM_LAST].[DeviceName]
			,[FT_BOM_LAST].[TesterType]
			,[FT_BOM_LAST].[TestFlow]
			,[FT_BOM_LAST].[TestEquipment]
			,[FT_BOM_LAST].[MachineType]
			,[MACHINE_SETUP].[MCNo] AS [OWNER_McNo]

			,MAX([FT_BOM_LAST].[BoxCapa]) AS [BoxCapa]
			,[MACHINE_SETUP].[Date]
	
	FROM 
			#MACHINE_SETUP AS [MACHINE_SETUP]

	RIGHT JOIN
			#FT_BOM_LAST AS [FT_BOM_LAST]
	ON
			[FT_BOM_LAST].[PackageName] = [MACHINE_SETUP].[PackageName]
			AND [FT_BOM_LAST].[DeviceName] = [MACHINE_SETUP].[DeviceName]
			AND [FT_BOM_LAST].[TestFlow] = [MACHINE_SETUP].[TestFlow]

	GROUP BY
			[FT_BOM_LAST].[PackageName]
			,[FT_BOM_LAST].[DeviceName]
			,[FT_BOM_LAST].[TesterType]
			,[FT_BOM_LAST].[TestFlow]
			,[FT_BOM_LAST].[TestEquipment]
			,[FT_BOM_LAST].[MachineType]
			,[MACHINE_SETUP].[MCNo]

			,[MACHINE_SETUP].[Date]


	CREATE TABLE #FT_PROGESS_SUM_LAST
	(
			[PackageName]		VARCHAR(50)
			,[DeviceName]		VARCHAR(50)
			,[TesterType]		VARCHAR(50)
			,[TestFlow]			VARCHAR(50)
			,[TestEquipment]	VARCHAR(50)
			,[MachineType]		VARCHAR(50)
			,[OWNER_McNo]		VARCHAR(50)

			,[DataType]			VARCHAR(50)
			,[D_1]				REAL
			,[D_2]				REAL
			,[D_3]				REAL
			,[D_4]				REAL
			,[D_5]				REAL
			,[D_6]				REAL
			,[D_7]				REAL
			,[D_8]				REAL
			,[D_9]				REAL
			,[D_10]				REAL
			,[D_11]				REAL
			,[D_12]				REAL
			,[D_13]				REAL
			,[D_14]				REAL
			,[D_15]				REAL
			,[D_16]				REAL
			,[D_17]				REAL
			,[D_18]				REAL
			,[D_19]				REAL
			,[D_20]				REAL
			,[D_21]				REAL
			,[D_22]				REAL
			,[D_23]				REAL
			,[D_24]				REAL
			,[D_25]				REAL
			,[D_26]				REAL
			,[D_27]				REAL
			,[D_28]				REAL
			,[D_29]				REAL
			,[D_30]				REAL
			,[D_31]				REAL

			,[D_SUM]			REAL

	)

	INSERT INTO #FT_PROGESS_SUM_LAST

			SELECT
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]

					,'1.INPUT ACTUAL' AS [DataType]

					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY, 0,@DateStart) THEN [PiecesInput] ELSE 0 END) AS [D_1]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY, 1,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_2]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY, 2,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_3]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY, 3,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_4]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY, 4,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_5]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY, 5,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_6]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY, 6,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_7]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY, 7,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_8]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY, 8,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_9]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY, 9,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_10]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,10,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_11]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,11,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_12]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,12,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_13]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,13,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_14]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,14,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_15]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,15,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_16]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,16,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_17]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,17,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_18]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,18,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_19]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,19,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_20]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,20,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_21]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,21,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_22]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,22,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_23]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,23,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_24]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,24,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_25]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,25,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_26]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,26,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_27]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,27,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_28]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,28,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_29]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,29,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_30]
					,SUM(CASE WHEN [InputDay_Leadtime] = DATEADD(DAY,30,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_31]

					,SUM(CASE WHEN [InputDay_Leadtime] BETWEEN DATEADD(DAY, 0,@DateStart) AND DATEADD(DAY,30,@DateStart) THEN [PiecesInput]  ELSE 0 END) AS [D_SUM]

			FROM 
					#CAC_DATA_LAST AS [CAC_DATA_LAST]
								
			WHERE 
					[CAC_DATA_LAST].[InputDay_Leadtime] BETWEEN @DateStart AND DATEADD(DAY,-1,DATEADD(MONTH,1,@DateStart)) OR [CAC_DATA_LAST].[InputDay_Leadtime] IS NULL

			GROUP BY
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]

			UNION

			SELECT
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]

					,'2.WIP DELAY' AS [DataType]

					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,1,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,1,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_1]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,2,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,2,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_2]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,3,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,3,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_3]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,4,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,4,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_4]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,5,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,5,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_5]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,6,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,6,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_6]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,7,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,7,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_7]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,8,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,8,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_8]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,9,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,9,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_9]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,10,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,10,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_10]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,11,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,11,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_11]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,12,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,12,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_12]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,13,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,13,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_13]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,14,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,14,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_14]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,15,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,15,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_15]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,16,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,16,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_16]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,17,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,17,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_17]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,18,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,18,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_18]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,19,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,19,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_19]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,20,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,20,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_20]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,21,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,21,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_21]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,22,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,22,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_22]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,23,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,23,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_23]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,24,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,24,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_24]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,25,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,25,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_25]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,26,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,26,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_26]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,27,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,27,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_27]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,28,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,28,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_28]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,29,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,29,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_29]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,30,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,30,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_30]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,31,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,31,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_31]

					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,1,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,31,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_SUM]

			FROM 
					#CAC_DATA_LAST AS [CAC_DATA_LAST]

			WHERE 
					[CAC_DATA_LAST].[InputDay_Leadtime] BETWEEN DATEADD(MONTH,-1,@DateStart) AND DATEADD(DAY,-1,@DateStart) OR [CAC_DATA_LAST].[InputDay_Leadtime] IS NULL

			GROUP BY
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]

			UNION

			SELECT
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]

					,'3.WIP' AS [DataType]

					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,1,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,1,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_1]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,2,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,2,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_2]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,3,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,3,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_3]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,4,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,4,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_4]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,5,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,5,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_5]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,6,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,6,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_6]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,7,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,7,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_7]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,8,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,8,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_8]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,9,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,9,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_9]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,10,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,10,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_10]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,11,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,11,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_11]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,12,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,12,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_12]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,13,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,13,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_13]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,14,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,14,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_14]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,15,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,15,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_15]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,16,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,16,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_16]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,17,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,17,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_17]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,18,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,18,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_18]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,19,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,19,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_19]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,20,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,20,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_20]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,21,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,21,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_21]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,22,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,22,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_22]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,23,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,23,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_23]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,24,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,24,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_24]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,25,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,25,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_25]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,26,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,26,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_26]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,27,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,27,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_27]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,28,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,28,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_28]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,29,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,29,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_29]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,30,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,30,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_30]
					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,31,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,31,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_31]

					,SUM(CASE WHEN (([OWNER_End] > DATEADD(DAY,1,@DateTimeStart) OR [OWNER_End] IS NULL) AND [FRONT_End] < DATEADD(DAY,31,@DateTimeStart)) THEN [PiecesInput] ELSE 0 END) AS [D_SUM]

			FROM 
					#CAC_DATA_LAST AS [CAC_DATA_LAST]

			WHERE 
					[CAC_DATA_LAST].[InputDay_Leadtime] >= @DateStart OR [CAC_DATA_LAST].[InputDay_Leadtime] IS NULL

			GROUP BY
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]

			UNION

			SELECT
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]

					,'4.RESULT DELAY' AS [DataType]

					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,0,@DateTimeStart) AND DATEADD(DAY,1,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_1]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,1,@DateTimeStart) AND DATEADD(DAY,2,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_2]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,2,@DateTimeStart) AND DATEADD(DAY,3,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_3]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,3,@DateTimeStart) AND DATEADD(DAY,4,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_4]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,4,@DateTimeStart) AND DATEADD(DAY,5,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_5]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,5,@DateTimeStart) AND DATEADD(DAY,6,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_6]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,6,@DateTimeStart) AND DATEADD(DAY,7,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_7]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,7,@DateTimeStart) AND DATEADD(DAY,8,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_8]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,8,@DateTimeStart) AND DATEADD(DAY,9,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_9]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,9,@DateTimeStart) AND DATEADD(DAY,10,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_10]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,10,@DateTimeStart) AND DATEADD(DAY,11,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_11]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,11,@DateTimeStart) AND DATEADD(DAY,12,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_12]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,12,@DateTimeStart) AND DATEADD(DAY,13,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_13]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,13,@DateTimeStart) AND DATEADD(DAY,14,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_14]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,14,@DateTimeStart) AND DATEADD(DAY,15,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_15]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,15,@DateTimeStart) AND DATEADD(DAY,16,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_16]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,16,@DateTimeStart) AND DATEADD(DAY,17,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_17]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,17,@DateTimeStart) AND DATEADD(DAY,18,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_18]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,18,@DateTimeStart) AND DATEADD(DAY,19,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_19]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,19,@DateTimeStart) AND DATEADD(DAY,20,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_20]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,20,@DateTimeStart) AND DATEADD(DAY,21,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_21]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,21,@DateTimeStart) AND DATEADD(DAY,22,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_22]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,22,@DateTimeStart) AND DATEADD(DAY,23,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_23]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,23,@DateTimeStart) AND DATEADD(DAY,24,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_24]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,24,@DateTimeStart) AND DATEADD(DAY,25,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_25]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,25,@DateTimeStart) AND DATEADD(DAY,26,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_26]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,26,@DateTimeStart) AND DATEADD(DAY,27,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_27]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,27,@DateTimeStart) AND DATEADD(DAY,28,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_28]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,28,@DateTimeStart) AND DATEADD(DAY,29,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_29]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,29,@DateTimeStart) AND DATEADD(DAY,30,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_30]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,30,@DateTimeStart) AND DATEADD(DAY,31,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_31]

					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,0,@DateTimeStart) AND DATEADD(DAY,31,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_SUM]

			FROM

					#CAC_DATA_LAST AS [CAC_DATA_LAST]
								
			WHERE 
					[CAC_DATA_LAST].[InputDay_Leadtime] BETWEEN DATEADD(MONTH,-1,@DateStart) AND DATEADD(DAY,-1,(@DateStart)) OR [CAC_DATA_LAST].[InputDay_Leadtime] IS NULL

			GROUP BY
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]
								
			UNION

			SELECT
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]

					,'5.RESULT' AS [DataType]

					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,0,@DateTimeStart) AND DATEADD(DAY,1,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_1]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,1,@DateTimeStart) AND DATEADD(DAY,2,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_2]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,2,@DateTimeStart) AND DATEADD(DAY,3,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_3]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,3,@DateTimeStart) AND DATEADD(DAY,4,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_4]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,4,@DateTimeStart) AND DATEADD(DAY,5,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_5]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,5,@DateTimeStart) AND DATEADD(DAY,6,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_6]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,6,@DateTimeStart) AND DATEADD(DAY,7,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_7]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,7,@DateTimeStart) AND DATEADD(DAY,8,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_8]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,8,@DateTimeStart) AND DATEADD(DAY,9,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_9]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,9,@DateTimeStart) AND DATEADD(DAY,10,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_10]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,10,@DateTimeStart) AND DATEADD(DAY,11,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_11]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,11,@DateTimeStart) AND DATEADD(DAY,12,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_12]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,12,@DateTimeStart) AND DATEADD(DAY,13,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_13]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,13,@DateTimeStart) AND DATEADD(DAY,14,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_14]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,14,@DateTimeStart) AND DATEADD(DAY,15,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_15]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,15,@DateTimeStart) AND DATEADD(DAY,16,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_16]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,16,@DateTimeStart) AND DATEADD(DAY,17,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_17]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,17,@DateTimeStart) AND DATEADD(DAY,18,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_18]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,18,@DateTimeStart) AND DATEADD(DAY,19,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_19]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,19,@DateTimeStart) AND DATEADD(DAY,20,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_20]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,20,@DateTimeStart) AND DATEADD(DAY,21,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_21]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,21,@DateTimeStart) AND DATEADD(DAY,22,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_22]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,22,@DateTimeStart) AND DATEADD(DAY,23,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_23]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,23,@DateTimeStart) AND DATEADD(DAY,24,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_24]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,24,@DateTimeStart) AND DATEADD(DAY,25,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_25]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,25,@DateTimeStart) AND DATEADD(DAY,26,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_26]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,26,@DateTimeStart) AND DATEADD(DAY,27,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_27]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,27,@DateTimeStart) AND DATEADD(DAY,28,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_28]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,28,@DateTimeStart) AND DATEADD(DAY,29,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_29]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,29,@DateTimeStart) AND DATEADD(DAY,30,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_30]
					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,30,@DateTimeStart) AND DATEADD(DAY,31,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_31]

					,SUM(CASE WHEN [OWNER_End] BETWEEN DATEADD(DAY,0,@DateTimeStart) AND DATEADD(DAY,31,@DateTimeStart) THEN [PiecesInput] ELSE 0 END) AS [D_SUM]

			FROM
					#CAC_DATA_LAST AS [CAC_DATA_LAST]
								
			WHERE 
					[CAC_DATA_LAST].[InputDay_Leadtime] >= @DateStart OR [CAC_DATA_LAST].[InputDay_Leadtime] IS NULL

			GROUP BY
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]
			
			UNION
			
			SELECT
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]

					,'6.BOX SETUP' AS [DataType]

					,SUM(CASE WHEN [Date] = DATEADD(DAY,0,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_1]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,1,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_2]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,2,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_3]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,3,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_4]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,4,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_5]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,5,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_6]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,6,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_7]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,7,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_8]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,8,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_9]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,9,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_10]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,10,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_11]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,11,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_12]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,12,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_13]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,13,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_14]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,14,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_15]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,15,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_16]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,16,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_17]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,17,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_18]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,18,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_19]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,19,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_20]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,20,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_21]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,21,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_22]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,22,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_23]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,23,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_24]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,24,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_25]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,25,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_26]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,26,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_27]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,27,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_28]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,28,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_29]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,29,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_30]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,30,@DateStart) THEN [BoxCapa] ELSE 0 END) AS [D_31]

					,'0' AS [D_SUM]

			FROM
					#MACHINE_SETUP_LAST AS [MACHINE_SETUP_LAST]

			GROUP BY
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]

			UNION

			SELECT
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]

					,'7.MACHINE SETUP' AS [DataType]

					,SUM(CASE WHEN [Date] = DATEADD(DAY,0,@DateStart) THEN 1 ELSE 0 END) AS [D_1]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,1,@DateStart) THEN 1 ELSE 0 END) AS [D_2]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,2,@DateStart) THEN 1 ELSE 0 END) AS [D_3]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,3,@DateStart) THEN 1 ELSE 0 END) AS [D_4]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,4,@DateStart) THEN 1 ELSE 0 END) AS [D_5]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,5,@DateStart) THEN 1 ELSE 0 END) AS [D_6]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,6,@DateStart) THEN 1 ELSE 0 END) AS [D_7]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,7,@DateStart) THEN 1 ELSE 0 END) AS [D_8]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,8,@DateStart) THEN 1 ELSE 0 END) AS [D_9]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,9,@DateStart) THEN 1 ELSE 0 END) AS [D_10]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,10,@DateStart) THEN 1 ELSE 0 END) AS [D_11]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,11,@DateStart) THEN 1 ELSE 0 END) AS [D_12]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,12,@DateStart) THEN 1 ELSE 0 END) AS [D_13]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,13,@DateStart) THEN 1 ELSE 0 END) AS [D_14]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,14,@DateStart) THEN 1 ELSE 0 END) AS [D_15]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,15,@DateStart) THEN 1 ELSE 0 END) AS [D_16]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,16,@DateStart) THEN 1 ELSE 0 END) AS [D_17]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,17,@DateStart) THEN 1 ELSE 0 END) AS [D_18]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,18,@DateStart) THEN 1 ELSE 0 END) AS [D_19]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,19,@DateStart) THEN 1 ELSE 0 END) AS [D_20]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,20,@DateStart) THEN 1 ELSE 0 END) AS [D_21]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,21,@DateStart) THEN 1 ELSE 0 END) AS [D_22]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,22,@DateStart) THEN 1 ELSE 0 END) AS [D_23]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,23,@DateStart) THEN 1 ELSE 0 END) AS [D_24]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,24,@DateStart) THEN 1 ELSE 0 END) AS [D_25]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,25,@DateStart) THEN 1 ELSE 0 END) AS [D_26]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,26,@DateStart) THEN 1 ELSE 0 END) AS [D_27]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,27,@DateStart) THEN 1 ELSE 0 END) AS [D_28]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,28,@DateStart) THEN 1 ELSE 0 END) AS [D_29]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,29,@DateStart) THEN 1 ELSE 0 END) AS [D_30]
					,SUM(CASE WHEN [Date] = DATEADD(DAY,30,@DateStart) THEN 1 ELSE 0 END) AS [D_31]

					,'0' [D_SUM]

			FROM
					#MACHINE_SETUP_LAST AS [MACHINE_SETUP_LAST]

			GROUP BY
					[PackageName]
					,[DeviceName]
					,[TesterType]
					,[TestFlow]
					,[TestEquipment] 
					,[MachineType]
					,[OWNER_McNo]

	--/ Equipment Registor

	CREATE TABLE #EQP_REGISTER
	(
			[PackageName]		VARCHAR(50)
			,[DeviceName]		VARCHAR(50)
			,[TesterType]		VARCHAR(50)
			,[TestFlow]			VARCHAR(50)
			,[TestEquipment]	VARCHAR(50)
			,[MachineType]		VARCHAR(50)
			,[Total]			INTEGER
	)

	INSERT INTO #EQP_REGISTER

	SELECT
			[FT_BOM_LAST].[PackageName]
			,[FT_BOM_LAST].[DeviceName]
			,[FT_BOM_LAST].[TesterType]
			,[FT_BOM_LAST].[TestFlow]
			,[FT_BOM_LAST].[TestEquipment] 
			,[FT_BOM_LAST].[MachineType]
			,[EQP_REGISTER_SAM].[Total]

	FROM
	(

			SELECT 
					[DBx].[EQP].[Equipment].[SubType] AS [TestEquipment]
					,COUNT([DBx].[EQP].[Equipment].[ID]) AS [Total]

			FROM 
					[DBx].[EQP].[Equipment]

			WHERE 
					[DBx].[EQP].[Equipment].[ProcessID] = '9' AND 
					[DBx].[EQP].[Equipment].[EquipmentTypeID] IN ('1','2')

			GROUP BY 
					[DBx].[EQP].[Equipment].[SubType]

	) AS [EQP_REGISTER_SAM]

	INNER JOIN
			#FT_BOM_LAST AS [FT_BOM_LAST]
	ON
			[FT_BOM_LAST].[TestEquipment] = [EQP_REGISTER_SAM].[TestEquipment]
			


	--/ WIP Delay

	CREATE TABLE #WIP_DELAY
	(
			[PackageName]		VARCHAR(50)
			,[DeviceName]		VARCHAR(50)
			,[TesterType]		VARCHAR(50)
			,[TestFlow]			VARCHAR(50)
			,[TestEquipment]	VARCHAR(50)
			,[MachineType]		VARCHAR(50)

			,[InputDelay]		REAL
	)

	INSERT #WIP_DELAY
	SELECT
			[PackageName]
			,[DeviceName]
			,[TesterType]
			,[TestFlow]
			,[TestEquipment] 
			,[MachineType]

			,SUM(CASE WHEN ([OWNER_End] >= @DateTimeStart OR [OWNER_End] IS NULL) THEN [PiecesInput] ELSE 0 END) AS [InputDelay]

	FROM 
			#CAC_DATA_LAST AS [CAC_DATA_LAST]

	WHERE 
			[CAC_DATA_LAST].[InputDay_Leadtime] BETWEEN DATEADD(MONTH,-1,@DateStart) AND DATEADD(DAY,-1,@DateStart) OR [CAC_DATA_LAST].[InputDay_Leadtime] IS NULL

	GROUP BY
			[PackageName]
			,[DeviceName]
			,[TesterType]
			,[TestFlow]
			,[TestEquipment] 
			,[MachineType]


	--** SUM BY PACKAGE **
	SELECT
			'All' AS [TesterType]
			,[FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]
			,'All' AS [TestEquipment] 
			,'All' AS [MachineType]

			,CAST(ROUND([MACHINE_SETUP_LAST_CAPAMAX].[BoxCapa_Max], 1) AS DECIMAL(10,1)) AS [BoxCapa]
			,CAST(ROUND([EQP_REGISTER_MAX].[Total_Max], 1) AS DECIMAL(10,1)) AS [BoxTotal]
			,CAST(ROUND([WIP_DELAY_SUM].[InputDelay_Sum], 1) AS DECIMAL(10,1)) AS [InputDelay]

			,[DataType]

			,CAST(ROUND([D_1], 1) AS DECIMAL(10,1)) AS [D_1]
			,CAST(ROUND([D_2], 1) AS DECIMAL(10,1)) AS [D_2]
			,CAST(ROUND([D_3], 1) AS DECIMAL(10,1)) AS [D_3]
			,CAST(ROUND([D_4], 1) AS DECIMAL(10,1)) AS [D_4]
			,CAST(ROUND([D_5], 1) AS DECIMAL(10,1)) AS [D_5]
			,CAST(ROUND([D_6], 1) AS DECIMAL(10,1)) AS [D_6]
			,CAST(ROUND([D_7], 1) AS DECIMAL(10,1)) AS [D_7]
			,CAST(ROUND([D_8], 1) AS DECIMAL(10,1)) AS [D_8]
			,CAST(ROUND([D_9], 1) AS DECIMAL(10,1)) AS [D_9]
			,CAST(ROUND([D_10], 1) AS DECIMAL(10,1)) AS [D_10]
			,CAST(ROUND([D_11], 1) AS DECIMAL(10,1)) AS [D_11]
			,CAST(ROUND([D_12], 1) AS DECIMAL(10,1)) AS [D_12]
			,CAST(ROUND([D_13], 1) AS DECIMAL(10,1)) AS [D_13]
			,CAST(ROUND([D_14], 1) AS DECIMAL(10,1)) AS [D_14]
			,CAST(ROUND([D_15], 1) AS DECIMAL(10,1)) AS [D_15]
			,CAST(ROUND([D_16], 1) AS DECIMAL(10,1)) AS [D_16]
			,CAST(ROUND([D_17], 1) AS DECIMAL(10,1)) AS [D_17]
			,CAST(ROUND([D_18], 1) AS DECIMAL(10,1)) AS [D_18]
			,CAST(ROUND([D_19], 1) AS DECIMAL(10,1)) AS [D_19]
			,CAST(ROUND([D_20], 1) AS DECIMAL(10,1)) AS [D_20]
			,CAST(ROUND([D_21], 1) AS DECIMAL(10,1)) AS [D_21]
			,CAST(ROUND([D_22], 1) AS DECIMAL(10,1)) AS [D_22]
			,CAST(ROUND([D_23], 1) AS DECIMAL(10,1)) AS [D_23]
			,CAST(ROUND([D_24], 1) AS DECIMAL(10,1)) AS [D_24]
			,CAST(ROUND([D_25], 1) AS DECIMAL(10,1)) AS [D_25]
			,CAST(ROUND([D_26], 1) AS DECIMAL(10,1)) AS [D_26]
			,CAST(ROUND([D_27], 1) AS DECIMAL(10,1)) AS [D_27]
			,CAST(ROUND([D_28], 1) AS DECIMAL(10,1)) AS [D_28]
			,CAST(ROUND([D_29], 1) AS DECIMAL(10,1)) AS [D_29]
			,CAST(ROUND([D_30], 1) AS DECIMAL(10,1)) AS [D_30]
			,CAST(ROUND([D_31], 1) AS DECIMAL(10,1)) AS [D_31]

	FROM
	(
			SELECT 
					[FT_PROGESS_SUM_LAST].[TestFlow]
					,[FT_PROGESS_SUM_LAST].[DataType]

					,SUM([D_1]) AS [D_1]
					,SUM([D_2]) AS [D_2]
					,SUM([D_3]) AS [D_3]
					,SUM([D_4]) AS [D_4]
					,SUM([D_5]) AS [D_5]
					,SUM([D_6]) AS [D_6]
					,SUM([D_7]) AS [D_7]
					,SUM([D_8]) AS [D_8]
					,SUM([D_9]) AS [D_9]
					,SUM([D_10]) AS [D_10]
					,SUM([D_11]) AS [D_11]
					,SUM([D_12]) AS [D_12]
					,SUM([D_13]) AS [D_13]
					,SUM([D_14]) AS [D_14]
					,SUM([D_15]) AS [D_15]
					,SUM([D_16]) AS [D_16]
					,SUM([D_17]) AS [D_17]
					,SUM([D_18]) AS [D_18]
					,SUM([D_19]) AS [D_19]
					,SUM([D_20]) AS [D_20]
					,SUM([D_21]) AS [D_21]
					,SUM([D_22]) AS [D_22]
					,SUM([D_23]) AS [D_23]
					,SUM([D_24]) AS [D_24]
					,SUM([D_25]) AS [D_25]
					,SUM([D_26]) AS [D_26]
					,SUM([D_27]) AS [D_27]
					,SUM([D_28]) AS [D_28]
					,SUM([D_29]) AS [D_29]
					,SUM([D_30]) AS [D_30]
					,SUM([D_31]) AS [D_31]
			
			FROM 
					#FT_PROGESS_SUM_LAST AS [FT_PROGESS_SUM_LAST]

			GROUP BY
					[FT_PROGESS_SUM_LAST].[TestFlow]
					,[FT_PROGESS_SUM_LAST].[DataType]

	) AS [FT_PROGESS_SUM_LAST_TESTFLOW]

	INNER JOIN
			(
					SELECT
							[MACHINE_SETUP_LAST].[TestFlow]
							,MAX([MACHINE_SETUP_LAST].[BoxCapa]) AS [BoxCapa_Max]

					FROM
							#MACHINE_SETUP_LAST AS [MACHINE_SETUP_LAST]
					
					GROUP BY
							[MACHINE_SETUP_LAST].[TestFlow]

			) AS [MACHINE_SETUP_LAST_CAPAMAX]
	ON
			[MACHINE_SETUP_LAST_CAPAMAX].[TestFlow] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]

	INNER JOIN

			(
					SELECT
							[EQP_REGISTER_TOTALMAX].[TestFlow]
							,SUM([EQP_REGISTER_TOTALMAX].[Total_Max]) AS [Total_Max]

					FROM
							(
									SELECT
											[EQP_REGISTER].[TesterType]
											,[EQP_REGISTER].[TestFlow]
											,[EQP_REGISTER].[TestEquipment] 
											,[EQP_REGISTER].[MachineType]

											,MAX([EQP_REGISTER].[Total]) AS [Total_Max]

									FROM
											#EQP_REGISTER AS [EQP_REGISTER]
					
									GROUP BY
											[EQP_REGISTER].[TesterType]
											,[EQP_REGISTER].[TestFlow]
											,[EQP_REGISTER].[TestEquipment] 
											,[EQP_REGISTER].[MachineType]

							) AS [EQP_REGISTER_TOTALMAX]
					
					GROUP BY
							[EQP_REGISTER_TOTALMAX].[TestFlow]

			) AS [EQP_REGISTER_MAX]
	ON
			[EQP_REGISTER_MAX].[TestFlow] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]

	INNER JOIN
			(
					SELECT
							[WIP_DELAY].[TestFlow]
							,SUM([WIP_DELAY].[InputDelay]) AS [InputDelay_Sum]

					FROM
							#WIP_DELAY AS [WIP_DELAY]
					
					GROUP BY
							[WIP_DELAY].[TestFlow]

			) AS [WIP_DELAY_SUM]
	ON
			[WIP_DELAY_SUM].[TestFlow] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]

	ORDER BY
			[FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]
			,[FT_PROGESS_SUM_LAST_TESTFLOW].[DataType]

	IF @DataType = 'Equipment'

	BEGIN
			--** SUM BY EQUIPMENT **
			SELECT
					[FT_PROGESS_SUM_LAST_TESTFLOW].[TesterType]
					,[FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]
					,[FT_PROGESS_SUM_LAST_TESTFLOW].[TestEquipment] 
					,[FT_PROGESS_SUM_LAST_TESTFLOW].[MachineType]

					,CAST(ROUND([MACHINE_SETUP_LAST_CAPAMAX].[BoxCapa_Max], 1) AS DECIMAL(10,1)) AS [BoxCapa]
					,CAST(ROUND([EQP_REGISTER_TOTALMAX].[Total_Max], 1) AS DECIMAL(10,1)) AS [BoxTotal]
					,CAST(ROUND([WIP_DELAY_SUM].[InputDelay_Sum], 1) AS DECIMAL(10,1)) AS [InputDelay]

					,[DataType]

					,CAST(ROUND([D_1], 1) AS DECIMAL(10,1)) AS [D_1]
					,CAST(ROUND([D_2], 1) AS DECIMAL(10,1)) AS [D_2]
					,CAST(ROUND([D_3], 1) AS DECIMAL(10,1)) AS [D_3]
					,CAST(ROUND([D_4], 1) AS DECIMAL(10,1)) AS [D_4]
					,CAST(ROUND([D_5], 1) AS DECIMAL(10,1)) AS [D_5]
					,CAST(ROUND([D_6], 1) AS DECIMAL(10,1)) AS [D_6]
					,CAST(ROUND([D_7], 1) AS DECIMAL(10,1)) AS [D_7]
					,CAST(ROUND([D_8], 1) AS DECIMAL(10,1)) AS [D_8]
					,CAST(ROUND([D_9], 1) AS DECIMAL(10,1)) AS [D_9]
					,CAST(ROUND([D_10], 1) AS DECIMAL(10,1)) AS [D_10]
					,CAST(ROUND([D_11], 1) AS DECIMAL(10,1)) AS [D_11]
					,CAST(ROUND([D_12], 1) AS DECIMAL(10,1)) AS [D_12]
					,CAST(ROUND([D_13], 1) AS DECIMAL(10,1)) AS [D_13]
					,CAST(ROUND([D_14], 1) AS DECIMAL(10,1)) AS [D_14]
					,CAST(ROUND([D_15], 1) AS DECIMAL(10,1)) AS [D_15]
					,CAST(ROUND([D_16], 1) AS DECIMAL(10,1)) AS [D_16]
					,CAST(ROUND([D_17], 1) AS DECIMAL(10,1)) AS [D_17]
					,CAST(ROUND([D_18], 1) AS DECIMAL(10,1)) AS [D_18]
					,CAST(ROUND([D_19], 1) AS DECIMAL(10,1)) AS [D_19]
					,CAST(ROUND([D_20], 1) AS DECIMAL(10,1)) AS [D_20]
					,CAST(ROUND([D_21], 1) AS DECIMAL(10,1)) AS [D_21]
					,CAST(ROUND([D_22], 1) AS DECIMAL(10,1)) AS [D_22]
					,CAST(ROUND([D_23], 1) AS DECIMAL(10,1)) AS [D_23]
					,CAST(ROUND([D_24], 1) AS DECIMAL(10,1)) AS [D_24]
					,CAST(ROUND([D_25], 1) AS DECIMAL(10,1)) AS [D_25]
					,CAST(ROUND([D_26], 1) AS DECIMAL(10,1)) AS [D_26]
					,CAST(ROUND([D_27], 1) AS DECIMAL(10,1)) AS [D_27]
					,CAST(ROUND([D_28], 1) AS DECIMAL(10,1)) AS [D_28]
					,CAST(ROUND([D_29], 1) AS DECIMAL(10,1)) AS [D_29]
					,CAST(ROUND([D_30], 1) AS DECIMAL(10,1)) AS [D_30]
					,CAST(ROUND([D_31], 1) AS DECIMAL(10,1)) AS [D_31]

			FROM
			(
					SELECT 
							[FT_PROGESS_SUM_LAST].[TesterType]
							,[FT_PROGESS_SUM_LAST].[TestFlow]
							,[FT_PROGESS_SUM_LAST].[TestEquipment] 
							,[FT_PROGESS_SUM_LAST].[MachineType]
							,[FT_PROGESS_SUM_LAST].[DataType]

							,SUM([D_1]) AS [D_1]
							,SUM([D_2]) AS [D_2]
							,SUM([D_3]) AS [D_3]
							,SUM([D_4]) AS [D_4]
							,SUM([D_5]) AS [D_5]
							,SUM([D_6]) AS [D_6]
							,SUM([D_7]) AS [D_7]
							,SUM([D_8]) AS [D_8]
							,SUM([D_9]) AS [D_9]
							,SUM([D_10]) AS [D_10]
							,SUM([D_11]) AS [D_11]
							,SUM([D_12]) AS [D_12]
							,SUM([D_13]) AS [D_13]
							,SUM([D_14]) AS [D_14]
							,SUM([D_15]) AS [D_15]
							,SUM([D_16]) AS [D_16]
							,SUM([D_17]) AS [D_17]
							,SUM([D_18]) AS [D_18]
							,SUM([D_19]) AS [D_19]
							,SUM([D_20]) AS [D_20]
							,SUM([D_21]) AS [D_21]
							,SUM([D_22]) AS [D_22]
							,SUM([D_23]) AS [D_23]
							,SUM([D_24]) AS [D_24]
							,SUM([D_25]) AS [D_25]
							,SUM([D_26]) AS [D_26]
							,SUM([D_27]) AS [D_27]
							,SUM([D_28]) AS [D_28]
							,SUM([D_29]) AS [D_29]
							,SUM([D_30]) AS [D_30]
							,SUM([D_31]) AS [D_31]
			
					FROM 
							#FT_PROGESS_SUM_LAST AS [FT_PROGESS_SUM_LAST]

					GROUP BY
							[FT_PROGESS_SUM_LAST].[TesterType]
							,[FT_PROGESS_SUM_LAST].[TestFlow]
							,[FT_PROGESS_SUM_LAST].[TestEquipment] 
							,[FT_PROGESS_SUM_LAST].[MachineType]
							,[FT_PROGESS_SUM_LAST].[DataType]

			) AS [FT_PROGESS_SUM_LAST_TESTFLOW]

			INNER JOIN
					(
							SELECT
									[MACHINE_SETUP_LAST].[TesterType]
									,[MACHINE_SETUP_LAST].[TestFlow]
									,[MACHINE_SETUP_LAST].[TestEquipment] 
									,[MACHINE_SETUP_LAST].[MachineType]

									,MAX([MACHINE_SETUP_LAST].[BoxCapa]) AS [BoxCapa_Max]

							FROM
									#MACHINE_SETUP_LAST AS [MACHINE_SETUP_LAST]
					
							GROUP BY
									[MACHINE_SETUP_LAST].[TesterType]
									,[MACHINE_SETUP_LAST].[TestFlow]
									,[MACHINE_SETUP_LAST].[TestEquipment] 
									,[MACHINE_SETUP_LAST].[MachineType]

					) AS [MACHINE_SETUP_LAST_CAPAMAX]
			ON
					[MACHINE_SETUP_LAST_CAPAMAX].[TesterType] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TesterType]
					AND [MACHINE_SETUP_LAST_CAPAMAX].[TestFlow] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]
					AND [MACHINE_SETUP_LAST_CAPAMAX].[TestEquipment] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestEquipment]
					AND [MACHINE_SETUP_LAST_CAPAMAX].[MachineType] = [FT_PROGESS_SUM_LAST_TESTFLOW].[MachineType]

			INNER JOIN

					(
							SELECT
									[EQP_REGISTER].[TesterType]
									,[EQP_REGISTER].[TestFlow]
									,[EQP_REGISTER].[TestEquipment] 
									,[EQP_REGISTER].[MachineType]

									,MAX([EQP_REGISTER].[Total]) AS [Total_Max]

							FROM
									#EQP_REGISTER AS [EQP_REGISTER]
					
							GROUP BY
									[EQP_REGISTER].[TesterType]
									,[EQP_REGISTER].[TestFlow]
									,[EQP_REGISTER].[TestEquipment] 
									,[EQP_REGISTER].[MachineType]

					) AS [EQP_REGISTER_TOTALMAX]
			ON
					[EQP_REGISTER_TOTALMAX].[TesterType] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TesterType]
					AND [EQP_REGISTER_TOTALMAX].[TestFlow] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]
					AND [EQP_REGISTER_TOTALMAX].[TestEquipment] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestEquipment]
					AND [EQP_REGISTER_TOTALMAX].[MachineType] = [FT_PROGESS_SUM_LAST_TESTFLOW].[MachineType]

			INNER JOIN
					(
							SELECT
									[WIP_DELAY].[TesterType]
									,[WIP_DELAY].[TestFlow]
									,[WIP_DELAY].[TestEquipment] 
									,[WIP_DELAY].[MachineType]

									,SUM([WIP_DELAY].[InputDelay]) AS [InputDelay_Sum]

							FROM
									#WIP_DELAY AS [WIP_DELAY]
					
							GROUP BY
									[WIP_DELAY].[TesterType]
									,[WIP_DELAY].[TestFlow]
									,[WIP_DELAY].[TestEquipment] 
									,[WIP_DELAY].[MachineType]

					) AS [WIP_DELAY_SUM]
			ON
					[WIP_DELAY_SUM].[TesterType] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TesterType]
					AND [WIP_DELAY_SUM].[TestFlow] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]
					AND [WIP_DELAY_SUM].[TestEquipment] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestEquipment]
					AND [WIP_DELAY_SUM].[MachineType] = [FT_PROGESS_SUM_LAST_TESTFLOW].[MachineType]

			INNER JOIN
					(
							SELECT 
									[FT_PROGESS_SUM_LAST].[TesterType]
									,[FT_PROGESS_SUM_LAST].[TestFlow]
									,[FT_PROGESS_SUM_LAST].[TestEquipment] 
									,[FT_PROGESS_SUM_LAST].[MachineType]

									,SUM([D_SUM]) AS [D_SUM]
			
							FROM 
									#FT_PROGESS_SUM_LAST AS [FT_PROGESS_SUM_LAST]

							GROUP BY
									[FT_PROGESS_SUM_LAST].[TesterType]
									,[FT_PROGESS_SUM_LAST].[TestFlow]
									,[FT_PROGESS_SUM_LAST].[TestEquipment] 
									,[FT_PROGESS_SUM_LAST].[MachineType]

							HAVING SUM([D_SUM]) > 0

					) AS [CLEAR_DATA_ZERO]
			ON
					[CLEAR_DATA_ZERO].[TesterType] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TesterType]
					AND [CLEAR_DATA_ZERO].[TestFlow] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]
					AND [CLEAR_DATA_ZERO].[TestEquipment] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestEquipment]
					AND [CLEAR_DATA_ZERO].[MachineType] = [FT_PROGESS_SUM_LAST_TESTFLOW].[MachineType]

			ORDER BY
					[FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]
					,[FT_PROGESS_SUM_LAST_TESTFLOW].[TestEquipment] 
					,[FT_PROGESS_SUM_LAST_TESTFLOW].[TesterType]
					,[FT_PROGESS_SUM_LAST_TESTFLOW].[MachineType]
					,[DataType]	
	END

	ELSE IF @DataType = 'Machine'

	BEGIN
	
			--** SUM BY MACHINE **
			CREATE TABLE #MACHINE_REGISTOR
			(
					[OWNER_McNo]	VARCHAR(50)
					,[MachineType]	VARCHAR(50)
					,[Location]		VARCHAR(50)
			)

			INSERT INTO #MACHINE_REGISTOR

					SELECT 
							[DBx].[EQP].[Equipment].[Name] AS [OWNER_McNo]
							,[DBx].[EQP].[FTMachine].[PCType] AS [MachineType]
							,[DBx].[EQP].[Equipment].[Location]

					FROM 
							[DBx].[EQP].[Equipment]

					LEFT JOIN
							[DBx].[EQP].[FTMachine]
					ON
							[DBx].[EQP].[FTMachine].[MachineID] = [DBx].[EQP].[Equipment].[ID]

					WHERE 
							[EquipmentTypeID] = '8' AND [ProcessID] = '9' AND [Location] LIKE 'FT2-%'

			SELECT
					'-' AS [TesterType]
					,'-' AS [TestFlow]
					,[FT_PROGESS_SUM_LAST_TESTFLOW].[OWNER_McNo]
					,'-' AS [MachineType]

					,'0' AS [BoxCapa]
					,'0' AS [BoxTotal]
					,'0' AS [InputDelay]

					,[FT_PROGESS_SUM_LAST_TESTFLOW].[DataType]

					,CAST(ROUND([D_1], 1) AS DECIMAL(10,1)) AS [D_1]
					,CAST(ROUND([D_2], 1) AS DECIMAL(10,1)) AS [D_2]
					,CAST(ROUND([D_3], 1) AS DECIMAL(10,1)) AS [D_3]
					,CAST(ROUND([D_4], 1) AS DECIMAL(10,1)) AS [D_4]
					,CAST(ROUND([D_5], 1) AS DECIMAL(10,1)) AS [D_5]
					,CAST(ROUND([D_6], 1) AS DECIMAL(10,1)) AS [D_6]
					,CAST(ROUND([D_7], 1) AS DECIMAL(10,1)) AS [D_7]
					,CAST(ROUND([D_8], 1) AS DECIMAL(10,1)) AS [D_8]
					,CAST(ROUND([D_9], 1) AS DECIMAL(10,1)) AS [D_9]
					,CAST(ROUND([D_10], 1) AS DECIMAL(10,1)) AS [D_10]
					,CAST(ROUND([D_11], 1) AS DECIMAL(10,1)) AS [D_11]
					,CAST(ROUND([D_12], 1) AS DECIMAL(10,1)) AS [D_12]
					,CAST(ROUND([D_13], 1) AS DECIMAL(10,1)) AS [D_13]
					,CAST(ROUND([D_14], 1) AS DECIMAL(10,1)) AS [D_14]
					,CAST(ROUND([D_15], 1) AS DECIMAL(10,1)) AS [D_15]
					,CAST(ROUND([D_16], 1) AS DECIMAL(10,1)) AS [D_16]
					,CAST(ROUND([D_17], 1) AS DECIMAL(10,1)) AS [D_17]
					,CAST(ROUND([D_18], 1) AS DECIMAL(10,1)) AS [D_18]
					,CAST(ROUND([D_19], 1) AS DECIMAL(10,1)) AS [D_19]
					,CAST(ROUND([D_20], 1) AS DECIMAL(10,1)) AS [D_20]
					,CAST(ROUND([D_21], 1) AS DECIMAL(10,1)) AS [D_21]
					,CAST(ROUND([D_22], 1) AS DECIMAL(10,1)) AS [D_22]
					,CAST(ROUND([D_23], 1) AS DECIMAL(10,1)) AS [D_23]
					,CAST(ROUND([D_24], 1) AS DECIMAL(10,1)) AS [D_24]
					,CAST(ROUND([D_25], 1) AS DECIMAL(10,1)) AS [D_25]
					,CAST(ROUND([D_26], 1) AS DECIMAL(10,1)) AS [D_26]
					,CAST(ROUND([D_27], 1) AS DECIMAL(10,1)) AS [D_27]
					,CAST(ROUND([D_28], 1) AS DECIMAL(10,1)) AS [D_28]
					,CAST(ROUND([D_29], 1) AS DECIMAL(10,1)) AS [D_29]
					,CAST(ROUND([D_30], 1) AS DECIMAL(10,1)) AS [D_30]
					,CAST(ROUND([D_31], 1) AS DECIMAL(10,1)) AS [D_31]

			FROM
			(
					SELECT 
							[MACHINE_REGISTOR].[OWNER_McNo]

							,'5.RESULT' AS [DataType]

							,SUM([D_1]) AS [D_1]
							,SUM([D_2]) AS [D_2]
							,SUM([D_3]) AS [D_3]
							,SUM([D_4]) AS [D_4]
							,SUM([D_5]) AS [D_5]
							,SUM([D_6]) AS [D_6]
							,SUM([D_7]) AS [D_7]
							,SUM([D_8]) AS [D_8]
							,SUM([D_9]) AS [D_9]
							,SUM([D_10]) AS [D_10]
							,SUM([D_11]) AS [D_11]
							,SUM([D_12]) AS [D_12]
							,SUM([D_13]) AS [D_13]
							,SUM([D_14]) AS [D_14]
							,SUM([D_15]) AS [D_15]
							,SUM([D_16]) AS [D_16]
							,SUM([D_17]) AS [D_17]
							,SUM([D_18]) AS [D_18]
							,SUM([D_19]) AS [D_19]
							,SUM([D_20]) AS [D_20]
							,SUM([D_21]) AS [D_21]
							,SUM([D_22]) AS [D_22]
							,SUM([D_23]) AS [D_23]
							,SUM([D_24]) AS [D_24]
							,SUM([D_25]) AS [D_25]
							,SUM([D_26]) AS [D_26]
							,SUM([D_27]) AS [D_27]
							,SUM([D_28]) AS [D_28]
							,SUM([D_29]) AS [D_29]
							,SUM([D_30]) AS [D_30]
							,SUM([D_31]) AS [D_31]
			
					FROM 
							#FT_PROGESS_SUM_LAST AS [FT_PROGESS_SUM_LAST]

					RIGHT JOIN
							#MACHINE_REGISTOR AS [MACHINE_REGISTOR]

					ON
							[MACHINE_REGISTOR].[OWNER_McNo] = [FT_PROGESS_SUM_LAST].[OWNER_McNo] OR [FT_PROGESS_SUM_LAST].[OWNER_McNo] IS NULL

					WHERE 
							[DataType] IN ('4.RESULT DELAY','5.RESULT') OR [DataType] IS NULL

					GROUP BY
							[MACHINE_REGISTOR].[OWNER_McNo]

					UNION

					SELECT 
							[MACHINE_REGISTOR].[OWNER_McNo]

							,'6.BOX SETUP' AS [DataType]

							,MAX([D_1]) AS [D_1]
							,MAX([D_2]) AS [D_2]
							,MAX([D_3]) AS [D_3]
							,MAX([D_4]) AS [D_4]
							,MAX([D_5]) AS [D_5]
							,MAX([D_6]) AS [D_6]
							,MAX([D_7]) AS [D_7]
							,MAX([D_8]) AS [D_8]
							,MAX([D_9]) AS [D_9]
							,MAX([D_10]) AS [D_10]
							,MAX([D_11]) AS [D_11]
							,MAX([D_12]) AS [D_12]
							,MAX([D_13]) AS [D_13]
							,MAX([D_14]) AS [D_14]
							,MAX([D_15]) AS [D_15]
							,MAX([D_16]) AS [D_16]
							,MAX([D_17]) AS [D_17]
							,MAX([D_18]) AS [D_18]
							,MAX([D_19]) AS [D_19]
							,MAX([D_20]) AS [D_20]
							,MAX([D_21]) AS [D_21]
							,MAX([D_22]) AS [D_22]
							,MAX([D_23]) AS [D_23]
							,MAX([D_24]) AS [D_24]
							,MAX([D_25]) AS [D_25]
							,MAX([D_26]) AS [D_26]
							,MAX([D_27]) AS [D_27]
							,MAX([D_28]) AS [D_28]
							,MAX([D_29]) AS [D_29]
							,MAX([D_30]) AS [D_30]
							,MAX([D_31]) AS [D_31]
			
					FROM 
							#FT_PROGESS_SUM_LAST AS [FT_PROGESS_SUM_LAST]

					RIGHT JOIN
							#MACHINE_REGISTOR AS [MACHINE_REGISTOR]
					ON
							[MACHINE_REGISTOR].[OWNER_McNo] = [FT_PROGESS_SUM_LAST].[OWNER_McNo] OR [FT_PROGESS_SUM_LAST].[OWNER_McNo] IS NULL

					WHERE 
							[DataType] IN ('6.BOX SETUP') OR [DataType] IS NULL

					GROUP BY
							[MACHINE_REGISTOR].[OWNER_McNo]

					UNION

					SELECT 
							[MACHINE_REGISTOR].[OWNER_McNo]

							,[FT_PROGESS_SUM_LAST].[DataType]

							,'0' AS [D_1]
							,'0' AS [D_2]
							,'0' AS [D_3]
							,'0' AS [D_4]
							,'0' AS [D_5]
							,'0' AS [D_6]
							,'0' AS [D_7]
							,'0' AS [D_8]
							,'0' AS [D_9]
							,'0' AS [D_10]
							,'0' AS [D_11]
							,'0' AS [D_12]
							,'0' AS [D_13]
							,'0' AS [D_14]
							,'0' AS [D_15]
							,'0' AS [D_16]
							,'0' AS [D_17]
							,'0' AS [D_18]
							,'0' AS [D_19]
							,'0' AS [D_20]
							,'0' AS [D_21]
							,'0' AS [D_22]
							,'0' AS [D_23]
							,'0' AS [D_24]
							,'0' AS [D_25]
							,'0' AS [D_26]
							,'0' AS [D_27]
							,'0' AS [D_28]
							,'0' AS [D_29]
							,'0' AS [D_30]
							,'0' AS [D_31]
			
					FROM 
							#FT_PROGESS_SUM_LAST AS [FT_PROGESS_SUM_LAST]

					RIGHT JOIN
							#MACHINE_REGISTOR AS [MACHINE_REGISTOR]

					ON
							[MACHINE_REGISTOR].[OWNER_McNo] = [FT_PROGESS_SUM_LAST].[OWNER_McNo] OR [FT_PROGESS_SUM_LAST].[OWNER_McNo] IS NULL

					WHERE 
							[DataType] NOT IN ('5.RESULT','6.BOX SETUP') OR [DataType] IS NULL

					GROUP BY
							[MACHINE_REGISTOR].[OWNER_McNo]
							,[FT_PROGESS_SUM_LAST].[DataType]

			) AS [FT_PROGESS_SUM_LAST_TESTFLOW]

			WHERE
					[OWNER_McNo] IN
					(
							SELECT 
									[OWNER_McNo]
			
							FROM 
									#FT_PROGESS_SUM_LAST AS [FT_PROGESS_SUM_LAST]
					)

			ORDER BY
					[FT_PROGESS_SUM_LAST_TESTFLOW].[OWNER_McNo] 
					,[FT_PROGESS_SUM_LAST_TESTFLOW].[DataType]

	DROP TABLE #MACHINE_REGISTOR

	END

	ELSE IF @DataType = 'Device'

	BEGIN
			--** SUM BY DEVICE **
			SELECT
					'-' AS [TesterType]
					,[FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]
					,[FT_PROGESS_SUM_LAST_TESTFLOW].[DeviceName]
					,'-' AS [MachineType]

					,CAST(ROUND([MACHINE_SETUP_LAST_CAPAMAX].[BoxCapa_Max], 1) AS DECIMAL(10,1)) AS [BoxCapa]
					,CAST(ROUND([EQP_REGISTER_TOTALMAX].[Total_Max], 1) AS DECIMAL(10,1)) AS [BoxTotal]
					,CAST(ROUND([WIP_DELAY_SUM].[InputDelay_Sum], 1) AS DECIMAL(10,1)) AS [InputDelay]

					,[DataType]

					,CAST(ROUND([D_1], 1) AS DECIMAL(10,1)) AS [D_1]
					,CAST(ROUND([D_2], 1) AS DECIMAL(10,1)) AS [D_2]
					,CAST(ROUND([D_3], 1) AS DECIMAL(10,1)) AS [D_3]
					,CAST(ROUND([D_4], 1) AS DECIMAL(10,1)) AS [D_4]
					,CAST(ROUND([D_5], 1) AS DECIMAL(10,1)) AS [D_5]
					,CAST(ROUND([D_6], 1) AS DECIMAL(10,1)) AS [D_6]
					,CAST(ROUND([D_7], 1) AS DECIMAL(10,1)) AS [D_7]
					,CAST(ROUND([D_8], 1) AS DECIMAL(10,1)) AS [D_8]
					,CAST(ROUND([D_9], 1) AS DECIMAL(10,1)) AS [D_9]
					,CAST(ROUND([D_10], 1) AS DECIMAL(10,1)) AS [D_10]
					,CAST(ROUND([D_11], 1) AS DECIMAL(10,1)) AS [D_11]
					,CAST(ROUND([D_12], 1) AS DECIMAL(10,1)) AS [D_12]
					,CAST(ROUND([D_13], 1) AS DECIMAL(10,1)) AS [D_13]
					,CAST(ROUND([D_14], 1) AS DECIMAL(10,1)) AS [D_14]
					,CAST(ROUND([D_15], 1) AS DECIMAL(10,1)) AS [D_15]
					,CAST(ROUND([D_16], 1) AS DECIMAL(10,1)) AS [D_16]
					,CAST(ROUND([D_17], 1) AS DECIMAL(10,1)) AS [D_17]
					,CAST(ROUND([D_18], 1) AS DECIMAL(10,1)) AS [D_18]
					,CAST(ROUND([D_19], 1) AS DECIMAL(10,1)) AS [D_19]
					,CAST(ROUND([D_20], 1) AS DECIMAL(10,1)) AS [D_20]
					,CAST(ROUND([D_21], 1) AS DECIMAL(10,1)) AS [D_21]
					,CAST(ROUND([D_22], 1) AS DECIMAL(10,1)) AS [D_22]
					,CAST(ROUND([D_23], 1) AS DECIMAL(10,1)) AS [D_23]
					,CAST(ROUND([D_24], 1) AS DECIMAL(10,1)) AS [D_24]
					,CAST(ROUND([D_25], 1) AS DECIMAL(10,1)) AS [D_25]
					,CAST(ROUND([D_26], 1) AS DECIMAL(10,1)) AS [D_26]
					,CAST(ROUND([D_27], 1) AS DECIMAL(10,1)) AS [D_27]
					,CAST(ROUND([D_28], 1) AS DECIMAL(10,1)) AS [D_28]
					,CAST(ROUND([D_29], 1) AS DECIMAL(10,1)) AS [D_29]
					,CAST(ROUND([D_30], 1) AS DECIMAL(10,1)) AS [D_30]
					,CAST(ROUND([D_31], 1) AS DECIMAL(10,1)) AS [D_31]

			FROM
			(
					SELECT 
							[FT_PROGESS_SUM_LAST].[DeviceName]
							,[FT_PROGESS_SUM_LAST].[TestFlow]
							,[FT_PROGESS_SUM_LAST].[DataType]

							,SUM([D_1]) AS [D_1]
							,SUM([D_2]) AS [D_2]
							,SUM([D_3]) AS [D_3]
							,SUM([D_4]) AS [D_4]
							,SUM([D_5]) AS [D_5]
							,SUM([D_6]) AS [D_6]
							,SUM([D_7]) AS [D_7]
							,SUM([D_8]) AS [D_8]
							,SUM([D_9]) AS [D_9]
							,SUM([D_10]) AS [D_10]
							,SUM([D_11]) AS [D_11]
							,SUM([D_12]) AS [D_12]
							,SUM([D_13]) AS [D_13]
							,SUM([D_14]) AS [D_14]
							,SUM([D_15]) AS [D_15]
							,SUM([D_16]) AS [D_16]
							,SUM([D_17]) AS [D_17]
							,SUM([D_18]) AS [D_18]
							,SUM([D_19]) AS [D_19]
							,SUM([D_20]) AS [D_20]
							,SUM([D_21]) AS [D_21]
							,SUM([D_22]) AS [D_22]
							,SUM([D_23]) AS [D_23]
							,SUM([D_24]) AS [D_24]
							,SUM([D_25]) AS [D_25]
							,SUM([D_26]) AS [D_26]
							,SUM([D_27]) AS [D_27]
							,SUM([D_28]) AS [D_28]
							,SUM([D_29]) AS [D_29]
							,SUM([D_30]) AS [D_30]
							,SUM([D_31]) AS [D_31]
			
					FROM 
							#FT_PROGESS_SUM_LAST AS [FT_PROGESS_SUM_LAST]

					GROUP BY
							[FT_PROGESS_SUM_LAST].[DeviceName]
							,[FT_PROGESS_SUM_LAST].[TestFlow]
							,[FT_PROGESS_SUM_LAST].[DataType]

			) AS [FT_PROGESS_SUM_LAST_TESTFLOW]

			INNER JOIN
					(
							SELECT
									[MACHINE_SETUP_LAST].[DeviceName]
									,[MACHINE_SETUP_LAST].[TestFlow]

									,MAX([MACHINE_SETUP_LAST].[BoxCapa]) AS [BoxCapa_Max]

							FROM
									#MACHINE_SETUP_LAST AS [MACHINE_SETUP_LAST]
					
							GROUP BY
									[MACHINE_SETUP_LAST].[DeviceName]
									,[MACHINE_SETUP_LAST].[TestFlow]

					) AS [MACHINE_SETUP_LAST_CAPAMAX]
			ON
					[MACHINE_SETUP_LAST_CAPAMAX].[DeviceName] = [FT_PROGESS_SUM_LAST_TESTFLOW].[DeviceName]
					AND [MACHINE_SETUP_LAST_CAPAMAX].[TestFlow] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]

			INNER JOIN

					(
							SELECT
									[EQP_REGISTER].[DeviceName]
									,[EQP_REGISTER].[TestFlow]

									,MAX([EQP_REGISTER].[Total]) AS [Total_Max]

							FROM
									#EQP_REGISTER AS [EQP_REGISTER]
					
							GROUP BY
									[EQP_REGISTER].[DeviceName]
									,[EQP_REGISTER].[TestFlow]


					) AS [EQP_REGISTER_TOTALMAX]
			ON
					[EQP_REGISTER_TOTALMAX].[DeviceName] = [FT_PROGESS_SUM_LAST_TESTFLOW].[DeviceName]
					AND [EQP_REGISTER_TOTALMAX].[TestFlow] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]

			INNER JOIN
					(
							SELECT
									[WIP_DELAY].[DeviceName]
									,[WIP_DELAY].[TestFlow]

									,SUM([WIP_DELAY].[InputDelay]) AS [InputDelay_Sum]

							FROM
									#WIP_DELAY AS [WIP_DELAY]
					
							GROUP BY
									[WIP_DELAY].[DeviceName]
									,[WIP_DELAY].[TestFlow]

					) AS [WIP_DELAY_SUM]
			ON
					[WIP_DELAY_SUM].[DeviceName] = [FT_PROGESS_SUM_LAST_TESTFLOW].[DeviceName]
					AND [WIP_DELAY_SUM].[TestFlow] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]

			INNER JOIN
					(
							SELECT 
									[FT_PROGESS_SUM_LAST].[DeviceName]
									,[FT_PROGESS_SUM_LAST].[TestFlow]

									,SUM([D_SUM]) AS [D_SUM]
			
							FROM 
									#FT_PROGESS_SUM_LAST AS [FT_PROGESS_SUM_LAST]

							GROUP BY
									[FT_PROGESS_SUM_LAST].[DeviceName]
									,[FT_PROGESS_SUM_LAST].[TestFlow]

							HAVING SUM([D_SUM]) > 0

					) AS [CLEAR_DATA_ZERO]
			ON
					[CLEAR_DATA_ZERO].[DeviceName] = [FT_PROGESS_SUM_LAST_TESTFLOW].[DeviceName]
					AND [CLEAR_DATA_ZERO].[TestFlow] = [FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]

			ORDER BY
					[FT_PROGESS_SUM_LAST_TESTFLOW].[TestFlow]
					,[FT_PROGESS_SUM_LAST_TESTFLOW].[DeviceName] 
					,[DataType]	
	END

	ELSE

	BEGIN

			SELECT '0'

	END
	
	--DROP TABLE #FT_BOM_LAST
	--DROP TABLE #LOT_APCSPro

	--DROP TABLE #CAC_DATA_LAST
	--DROP TABLE #CHECK_DEVICE
	
	--DROP TABLE #MACHINE_SETUP
	--DROP TABLE #MACHINE_SETUP_LAST

	--DROP TABLE #FT_PROGESS_SUM_LAST

	--DROP TABLE #EQP_REGISTER
	--DROP TABLE #WIP_DELAY

END