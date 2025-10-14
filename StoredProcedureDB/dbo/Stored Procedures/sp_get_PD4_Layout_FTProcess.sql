
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_PD4_Layout_FTProcess]
	-- Add the parameters for the stored procedure here
	
	@Floor			VARCHAR(2)
		-- 1F		= '1'
		-- 2F		= '2'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	CREATE TABLE #LOT_LAST_DATA
	(
			[Package]					CHAR(20)
			,[Device]					CHAR(20)
			,[InputDate]				DATE
			,[ShipDate]					DATE
			,[LotNo]					CHAR(20)
			,[InputQty]					INT
			,[LastQty]					INT

			,[FRONT_BEFORE_EndTime]		DATETIME
			,[FRONT_BEFORE_PassQty]		INT

			,[FRONT_Job]				NVARCHAR(20)
			,[FRONT_McNo]				NVARCHAR(30)
			,[FRONT_StartTime]			DATETIME
			,[FRONT_EndTime]			DATETIME
			,[FRONT_Process_Min]		INT
			,[FRONT_ResultQty]			INT

			,[OWNER_Job]				NVARCHAR(20)
			,[OWNER_McNo]				NVARCHAR(30)
			,[OWNER_McModel]			NVARCHAR(30)
			,[OWNER_StartTime]			DATETIME
			,[OWNER_EndTime]			DATETIME
			,[OWNER_Process_Min]		INT
			,[OWNER_ResultQty]			INT
	)

	DECLARE @SelectDate DATE
	SET @SelectDate = CONVERT(VARCHAR(10), GETDATE(), 102)

	INSERT INTO #LOT_LAST_DATA
			EXEC [dbo].[sp_get_PD4_Progress]
			@SelectDate, 'Other', N'P', @Floor, N'FT', N'ALL'
	
	CREATE TABLE #GET_BM
	(
			[LotNo]					CHAR(20)
			,[MCName]				VARCHAR(15)
			,[Process]				VARCHAR(15)
			,[TimeRequest]			DATETIME
			,[TimeStart]			DATETIME
			,[TimeFinish]			DATETIME
			,[CategoryID]			INT
	)

	INSERT INTO #GET_BM
			EXEC [dbo].[sp_get_scheduler_bm]

	SELECT
			[MCNo]
			,[MCType]
			,[TestFlowName]
			,[Package]
			,[Device]
			,[Final_MC_Data].[LotNo]
			,[LotStartTime]
			,[LotEndTime]
			,[TesterType]
			,[ChannelTesterNo]
			,[BoxName]
			,[ChannelTestBoxNo]

			,CASE 
				WHEN [TimeRequest] IS NOT NULL THEN 'BMPM'
				WHEN DATEDIFF(MINUTE,[LotEndTime],GETDATE()) IS NULL THEN 'RUNNING'
				WHEN DATEDIFF(MINUTE,[LotEndTime],GETDATE()) <= 60 THEN 'FINISH LOT'
				ELSE 'PLAN STOP'
			END AS [Statust]

			,ISNULL([InputQty],0) AS [Input_Qty]
			,ISNULL([LastQty],0) AS [Total_Qty]

			,[TimeRequest]

	FROM
	(

			SELECT
						REPLACE([MachineSetup].[MCNo],'FT-','') AS [MCNo]
						,[OWNER_McModel] AS [MCType]
						,REPLACE([MachineSetup].[TestFlowName],'ASISAMPLE','(ASI)') AS [TestFlowName]
						,[MachineSetup].[Package]
						,[MachineSetup].[Device]
	
						,CASE WHEN [LOT_LAST_DATA].[OWNER_StartTime] >= [MachineSetup].[LotStartTime]
							THEN
								[LOT_LAST_DATA].[LotNo]
							ELSE
								[MachineSetup].[LotNo]
						END AS [LotNo]

						,CASE WHEN [LOT_LAST_DATA].[OWNER_StartTime] >= [MachineSetup].[LotStartTime]
							THEN
								[LOT_LAST_DATA].[OWNER_StartTime]
							ELSE
								[MachineSetup].[LotStartTime]
						END AS [LotStartTime]

						,CASE WHEN [LOT_LAST_DATA].[OWNER_StartTime] >= [MachineSetup].[LotStartTime]
							THEN
								[LOT_LAST_DATA].[OWNER_EndTime]
							ELSE
								[MachineSetup].[LotEndTime]
						END AS [LotEndTime]
						--,[LOT_LAST_DATA].[OWNER_EndTime] AS [LotEndTime]
						
						,[TesterType]
						,[ChannelTesterNo]
						,[BoxName]
						,[ChannelTestBoxNo]


						,CASE WHEN [LOT_LAST_DATA].[OWNER_StartTime] >= [MachineSetup].[LotStartTime]
							THEN
								[LOT_LAST_DATA].[InputQty]
							ELSE
								'0'
						END AS [InputQty]
						--,[InputQty]

						,CASE WHEN [LOT_LAST_DATA].[OWNER_StartTime] >= [MachineSetup].[LotStartTime]
							THEN
								CASE WHEN([LOT_LAST_DATA].[OWNER_EndTime] IS NULL) THEN [LastQty] ELSE [InputQty] END
							ELSE
								'0'
						END AS [LastQty]
						--,CASE WHEN([LOT_LAST_DATA].[OWNER_EndTime] IS NULL) THEN [LastQty] ELSE [InputQty] END AS [LastQty]
			FROM

			(

					SELECT DISTINCT
							[LOT_LAST_DATA].[OWNER_McNo] AS [MCNo]
							,MAX([LOT_LAST_DATA].[OWNER_StartTime]) AS [LotStartTime]

					FROM
							#LOT_LAST_DATA AS [LOT_LAST_DATA]

					WHERE 
							[LOT_LAST_DATA].[OWNER_McNo] LIKE 'FT-EP-%' OR 
							[LOT_LAST_DATA].[OWNER_McNo] LIKE 'FT-T-%' OR 
							[LOT_LAST_DATA].[OWNER_McNo] LIKE 'FT-MT-%' OR 
							[LOT_LAST_DATA].[OWNER_McNo] LIKE 'FT-IFZ-%'

					GROUP BY 
							[LOT_LAST_DATA].[OWNER_McNo]

			) AS [MachineLateLotStart]

			INNER JOIN 
					#LOT_LAST_DATA AS [LOT_LAST_DATA]
			ON
					[LOT_LAST_DATA].[OWNER_McNo] = [MachineLateLotStart].[MCNo] AND
					[LOT_LAST_DATA].[OWNER_StartTime] = [MachineLateLotStart].[LotStartTime]

			INNER JOIN 
			(
					SELECT
							[DBx].[dbo].[FTSetupReport].[MCNo]
							,[DBx].[dbo].[FTSetupReport].[TestFlow] AS [TestFlowName]
							,[DBx].[dbo].[FTSetupReport].[PackageName] AS [Package]
							,[DBx].[dbo].[FTSetupReport].[DeviceName] AS [Device]
							,[DBx].[dbo].[FTSetupReport].[LotNo]
							,[DBx].[dbo].[FTSetupReport].[SetupConfirmDate] AS [LotStartTime]
							,NULL AS [LotEndTime]
							,[DBx].[dbo].[FTSetupReport].[TesterType]

							,CASE WHEN [DBx].[dbo].[FTSetupReport].[TesterNoA] <> ''
								THEN [DBx].[dbo].[FTSetupReport].[TesterNoA]
								ELSE [DBx].[dbo].[FTSetupReport].[TesterNoB] END 
							AS [ChannelTesterNo]

							,CASE WHEN [DBx].[dbo].[FTSetupReport].[TestBoxA] <> ''
								THEN [DBx].[dbo].[FTSetupReport].[TestBoxA]
								ELSE [DBx].[dbo].[FTSetupReport].[TestBoxB] END 
							AS [BoxName]

							,CASE WHEN [DBx].[dbo].[FTSetupReport].[ChannelAFTB] <> ''
								THEN [DBx].[dbo].[FTSetupReport].[ChannelAFTB]
								ELSE [DBx].[dbo].[FTSetupReport].[ChannelBFTB] END 
							AS [ChannelTestBoxNo]

							,NULL AS [DiffTime_min]
					FROM
							[DBx].[dbo].[FTSetupReport] WITH (NOLOCK)
	
			) AS [MachineSetup]

			ON
					[MachineSetup].[MCNo] = [MachineLateLotStart].[MCNo]

	) AS [Final_MC_Data]

	LEFT JOIN
			#GET_BM AS [GET_BM]
	ON
			[GET_BM].[LotNo] = [Final_MC_Data].[LotNo]
			AND [GET_BM].[MCName] = 'FT-' + [Final_MC_Data].[MCNo]

	ORDER BY 
			[MCNo]
END
