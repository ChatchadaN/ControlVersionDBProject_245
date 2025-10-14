-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_PD4_Progress_APCSPro]
	-- Add the parameters for the stored procedure here

	@SelectDate		DATE
		-- YYYY-MM-DD

	,@LoadUnit		CHAR
		-- Day		= 'D'
		-- Month	= 'M'		

	,@Floor			CHAR
		-- 1F		= '1'
		-- 2F		= '2'

	,@Job			NVARCHAR(20)
		-- FL
		-- AUTO(1)
		-- AUTO(2)
		-- AUTO(3)
		-- AGING IN
		-- O/G

	,@Package		VARCHAR(20)
		-- All		= IS NULL
		-- Package	= Name Of Package

	,@PackageGroup	VARCHAR(10)
		-- All		= IS NULL
		-- Group	= Name Of Group

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	-- Slect Package In Process

	DECLARE @CountBefore	INT
	SET @CountBefore = -15

	CREATE TABLE #PACKAGE_ALL
	(
			[Package_ID]		INT
			,[Package]			CHAR(20)
			,[Package_FT]		CHAR(20)
			,[PackageGroup]		CHAR(10)
	)

	INSERT INTO #PACKAGE_ALL
			SELECT
					[packages].[id] AS [Package_ID]
					,[packages].[name] AS [Package]
					,[packages].[short_name] AS [Package_FT]
					,[package_groups].[name] AS [PackageGroup]

			FROM
					[APCSProDB].[method].[packages] WITH (NOLOCK)

			INNER JOIN
					[APCSProDB].[method].[package_groups] WITH (NOLOCK)
			ON
					[package_groups].[id] = [packages].[package_group_id]
			WHERE
					[packages].[is_enabled] = '1'
	
	CREATE TABLE #PACKAGE_SELECT
	(
			[Package_ID]		INT
			,[Package]			CHAR(20)
			,[Package_FT]		CHAR(20)
			,[PackageGroup]		CHAR(10)
	)

	IF (@Floor = '1' AND @Package IS NULL AND @PackageGroup IS NULL)
			BEGIN
					IF (@JOB = 'FL')
							BEGIN
									INSERT INTO #PACKAGE_SELECT
									SELECT
											[Package_ID]
											,[Package]
											,[Package_FT]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('POWER','SOP','GDIC') AND [Package] <> 'SSOP-B10W' AND [Package] NOT LIKE '%F'
							END

					ELSE
							BEGIN
									INSERT INTO #PACKAGE_SELECT
									SELECT
											[Package_ID]
											,[Package]
											,[Package_FT]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('-')

									SET @CountBefore = -25
							END
			END
	
	ELSE IF (@Floor = '2' AND @Package IS NULL AND @PackageGroup IS NULL)
			BEGIN
					IF (@JOB = 'FL')
							BEGIN
									INSERT INTO #PACKAGE_SELECT
									SELECT
											[Package_ID]
											,[Package]
											,[Package_FT]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('SMALL','QFP') OR [Package] = 'SSOP-B10W'
							END

					ELSE IF (@JOB = 'HOT O/S')
							BEGIN
									INSERT INTO #PACKAGE_SELECT
									SELECT
											[Package_ID]
											,[Package]
											,[Package_FT]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] = 'WSOF5'
							END

					ELSE IF (@JOB = 'FT')
							BEGIN
									INSERT INTO #PACKAGE_SELECT
									SELECT
											[Package_ID]
											,[Package]
											,[Package_FT]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('SMALL','QFP')

									SET @CountBefore = -25
							END

					ELSE IF (@JOB = 'AUTO(1)')
							BEGIN
									INSERT INTO #PACKAGE_SELECT
									SELECT
											[Package_ID]
											,[Package]
											,[Package_FT]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('SMALL','QFP') AND
											(
												[Package] NOT LIKE '%SOF%'
												AND [Package] NOT LIKE 'SSOP%'
												AND [Package] NOT LIKE 'SOP%'
												AND [Package] <> 'TSSOP-C10J'
											)
							END

					ELSE IF (@JOB = 'AUTO(2)')
							BEGIN
									INSERT INTO #PACKAGE_SELECT
									SELECT
											[Package_ID]
											,[Package]
											,[Package_FT]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('SMALL','QFP') AND
											(
												[Package] NOT LIKE '%SOF%'
												AND [Package] NOT LIKE '%SSOP%'
												AND [Package] NOT LIKE 'SOP%'
												AND [Package] NOT IN ('HTQFP64BV','MSOP10','MSOP8-HF','UQFP64M','VQFP48CR','VQFP64F','HSON-A8')
											)
							END

					ELSE IF (@JOB = 'AUTO(3)')
							BEGIN
									INSERT INTO #PACKAGE_SELECT
									SELECT
											[Package_ID]
											,[Package]
											,[Package_FT]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('SQFP80','UQFP64','VQFP48C','VQFP48CM','VQFP64')
							END

					ELSE IF (@JOB = 'AGING IN')
							BEGIN
									INSERT INTO #PACKAGE_SELECT
									SELECT
											[Package_ID]
											,[Package]
											,[Package_FT]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('HSON-A8','QFP-A64','SSOP-B10W')
											OR [Package] LIKE 'HTQFP64%'
											OR [Package] LIKE 'UQFP64%'
											OR [Package] LIKE 'VQFP64%'
											OR [Package] LIKE 'SQFP%'

									SET @CountBefore = -25
							END

					ELSE IF (@JOB = 'TP')
							BEGIN
									INSERT INTO #PACKAGE_SELECT
									SELECT
											[Package_ID]
											,[Package]
											,[Package_FT]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											([PackageGroup] IN ('SMALL','QFP') OR [Package] = 'SSOP-B10W')
											AND ([Package] NOT LIKE '%SOF%' AND [Package] NOT LIKE 'SOP4%' AND [Package] <> 'SSOP6')

									SET @CountBefore = -25
							END

					ELSE
							BEGIN
									INSERT INTO #PACKAGE_SELECT
									SELECT
											[Package_ID]
											,[Package]
											,[Package_FT]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('SMALL','QFP') OR [Package] = 'SSOP-B10W'

									SET @CountBefore = -25
							END
			END

	ELSE
			BEGIN
					INSERT INTO #PACKAGE_SELECT
					SELECT
							[Package_ID]
							,[Package]
							,[Package_FT]
							,[PackageGroup]
					FROM
							#PACKAGE_ALL AS [PACKAGE_ALL]
					WHERE
							[Package] LIKE '%' + @Package + '%' AND [PackageGroup] LIKE '%' + @PackageGroup + '%'
					
					SET @CountBefore = -25
			END

	
	-- Set Datetime for Load Input Plan
	
	DECLARE	@DateStart		DATE
	DECLARE	@DateEnd		DATE

	IF (@LoadUnit = 'M')
			BEGIN
					SET @DateStart = DATEADD(DAY,@CountBefore,@SelectDate)
					SET @DateEnd = EOMONTH(@SelectDate)
			END
	ELSE IF (@LoadUnit = 'D')
			BEGIN
					SET @DateStart = DATEADD(DAY,@CountBefore,@SelectDate)
					SET @DateEnd = @SelectDate
			END
	ELSE
			BEGIN
					SET @DateStart = DATEADD(DAY,@CountBefore,@SelectDate)
					SET @DateEnd = @SelectDate
			END
	

	-- Load Data in APCS Pro

	CREATE TABLE #INPUTPLAN
	(
			[Input_Date]		DATE
			,[Ship_Date]		DATE
			,[PackageGroup]		CHAR(10)
			,[Package]			CHAR(20)
			,[Package_FT]		CHAR(20)
			,[DeviceSlip_ID]	INT
			,[Device]			CHAR(20)
			,[Device_FT]		VARCHAR(20)
			,[Lot_ID]			INT
			,[Lot_No]			CHAR(20)
			,[InputQty_Pcs]		INT
			,[Shipment]			INT
			,[LastStep_No]		INT
			,[LastQty_Pcs]		INT
			
	)

	INSERT INTO #INPUTPLAN
			SELECT
					[DayInput].[date_value]				AS [Input_Date]
					,[DayShipment].[date_value]			AS [Ship_Date]
					,[PACKAGE_SELECT].[PackageGroup]
					,[PACKAGE_SELECT].[Package]
					,[PACKAGE_SELECT].[Package_FT]
					,[lots].[device_slip_id]			AS [DeviceSlip_ID]
					,[device_names].[name]				AS [Device]
					,[device_names].[ft_name]			AS [Device_FT]
					,[lots].[id]						AS [Lot_ID]
					,[lots].[lot_no]					AS [Lot_No]
					,[lots].[qty_in]					AS [InputQty_Pcs]
					,CASE WHEN ([item_labels1].[label_eng] = 'All Shipped') THEN 1 ELSE 0 END AS [Shipment]
					,[lots].[step_no]					AS [LastStep_No]
					,ISNULL(([lots].[qty_last_pass] + [lots].[qty_last_fail]),0) AS [LastQty_Pcs]
			
			FROM
					[APCSProDB].[trans].[lots]  WITH (NOLOCK)

			INNER JOIN
					#PACKAGE_SELECT AS [PACKAGE_SELECT]
			ON
					[PACKAGE_SELECT].[Package_ID] = [lots].[act_package_id]

			INNER JOIN
					[APCSProDB].[method].[device_names] WITH (NOLOCK)
			ON
					[device_names].[id] = [lots].[act_device_name_id]

			INNER JOIN
					[APCSProDB].[trans].[days] AS [DayInput] WITH (NOLOCK)
			ON		
					[DayInput].[id] = [lots].[in_plan_date_id]

			INNER JOIN
					[APCSProDB].[trans].[days] AS [DayShipment] WITH (NOLOCK)
			ON
					[DayShipment].[id] = [lots].[out_plan_date_id]

			INNER JOIN 
					[APCSProDB].[trans].[item_labels] AS [item_labels1] WITH (NOLOCK)
			ON 
					[item_labels1].[name] = 'lots.wip_state' and [item_labels1].[val] = [lots].[wip_state]

			WHERE 
					[DayInput].[date_value] BETWEEN @DateStart AND @DateEnd

	CREATE TABLE #INPUTPLAN_FLOW
	(
			[Input_Date]			DATE
			,[Ship_Date]			DATE
			,[PackageGroup]			CHAR(10)
			,[Package]				CHAR(20)
			,[Package_FT]				CHAR(20)
			,[Device]				CHAR(20)
			,[Device_FT]			VARCHAR(20)
			,[Lot_ID]				INT
			,[Lot_No]				CHAR(20)
			,[InputQty_Pcs]			INT
			,[Shipment]				INT
			,[LastStep_No]			INT
			,[LastQty_Pcs]			INT

			,[SpacialFlow]			INT
			,[Step_No]				INT
			,[Process]				NVARCHAR(20)
			,[Job]					NVARCHAR(20)
			,[ProcessTime_Min]		INT
			,[LeadTimeSum_Min]		INT
			,[NextStep_No]			INT
	)

	INSERT INTO #INPUTPLAN_FLOW
			SELECT
					[INPUTPLAN].[Input_Date]
					,[INPUTPLAN].[Ship_Date]
					,[INPUTPLAN].[PackageGroup]
					,[INPUTPLAN].[Package]
					,[INPUTPLAN].[Package_FT]
					,[INPUTPLAN].[Device]
					,[INPUTPLAN].[Device_FT]
					,[INPUTPLAN].[Lot_ID]
					,[INPUTPLAN].[Lot_No]
					,[INPUTPLAN].[InputQty_Pcs]
					,[INPUTPLAN].[Shipment]
					,[INPUTPLAN].[LastStep_No]
					,[INPUTPLAN].[LastQty_Pcs]

					,'0'								AS [SpacialFlow]
					,[device_flows].[step_no]			AS [Step_No]
					,[processes].[name]					AS [Process]
					,[jobs].[name]						AS [Job]
					,ISNULL([device_flows].[process_minutes] ,0)			AS [ProcessTime_Min]
					,ISNULL(([device_flows].[lead_time_sum]/60)/24 ,0)		AS [LeadTimeSum_Min]
					,[device_flows].[next_step_no]		AS [NextStep_No]

			FROM 
					#INPUTPLAN AS [INPUTPLAN]

			INNER JOIN
					[APCSProDB].[method].[device_flows] WITH (NOLOCK)
			ON
					[APCSProDB].[method].[device_flows].[device_slip_id] = [INPUTPLAN].[DeviceSlip_ID]

			INNER JOIN 
					[APCSProDB].[method].[jobs]  WITH (NOLOCK)
			ON 
					[APCSProDB].[method].[jobs].[id] = [APCSProDB].[method].[device_flows].[job_id] 

			INNER JOIN 
					[APCSProDB].[method].[processes] WITH (NOLOCK)
			ON 
					[APCSProDB].[method].[processes].[id] = [APCSProDB].[method].[jobs].[process_id]

			WHERE
					[APCSProDB].[method].[device_flows].[is_skipped] = '0'
					AND [APCSProDB].[method].[processes].[id] IN ('6','8','9','10','17','18','20','27','28','29','30','32')

			UNION

			SELECT
					[INPUTPLAN].[Input_Date]
					,[INPUTPLAN].[Ship_Date]
					,[INPUTPLAN].[PackageGroup]
					,[INPUTPLAN].[Package]
					,[INPUTPLAN].[Package_FT]
					,[INPUTPLAN].[Device]
					,[INPUTPLAN].[Device_FT]
					,[INPUTPLAN].[Lot_ID]
					,[INPUTPLAN].[Lot_No]
					,[INPUTPLAN].[InputQty_Pcs]
					,[INPUTPLAN].[Shipment]
					,[INPUTPLAN].[LastStep_No]
					,[INPUTPLAN].[LastQty_Pcs]

					,'1'								AS [SpacialFlow]
					,[lot_special_flows].[step_no]		AS [Step_No]
					,[processes].[name]					AS [Process]
					,[jobs].[name]						AS [Job]
					,'0'								AS [ProcessTime_Min]
					,'0'								AS [LeadTimeSum_Min]
					,CASE 
						WHEN([lot_special_flows].[next_step_no] = [lot_special_flows].[step_no]) 
							THEN [MAX_SP_FLOW].[back_step_no] 
							ELSE [lot_special_flows].[next_step_no] 
						END	AS [NextStepNo]

			FROM 
					#INPUTPLAN AS [INPUTPLAN]

			INNER JOIN
					(SELECT [lot_id],[step_no],[back_step_no],MAX([id]) AS [id] FROM [APCSProDB].[trans].[special_flows] WITH (NOLOCK) GROUP BY [lot_id],[step_no],[back_step_no]) AS [MAX_SP_FLOW]
			ON
					[MAX_SP_FLOW].[lot_id] = [INPUTPLAN].[Lot_ID]

			INNER JOIN
					[APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK)
			ON
					[APCSProDB].[trans].[lot_special_flows].[special_flow_id] = [MAX_SP_FLOW].[id]

			INNER JOIN 
					[APCSProDB].[method].[jobs]  WITH (NOLOCK)
			ON 
					[APCSProDB].[method].[jobs].[id] = [APCSProDB].[trans].[lot_special_flows].[job_id] 

			INNER JOIN 
					[APCSProDB].[method].[processes] WITH (NOLOCK)
			ON 
					[APCSProDB].[method].[processes].[id] = [APCSProDB].[method].[jobs].[process_id]

			WHERE
					[APCSProDB].[trans].[lot_special_flows].[is_skipped] = '0'

	
	CREATE TABLE #INPUTPLAN_RECORD
	(
			[Lot_ID]			INT

			,[Step_No]			INT
			,[Process]			NVARCHAR(20)
			,[Job]				NVARCHAR(20)
			
			,[Recode_ID]	BIGINT
			,[Recode_Datetime]	DATETIME
			,[RecodeClass_No]	TINYINT

			,[Mc_No]			NVARCHAR(30)
			,[Mc_Model]			NVARCHAR(30)
			,[PassQty_Pcs]		INT
	)

	INSERT INTO #INPUTPLAN_RECORD

			SELECT
					[INPUTPLAN_FLOW].[Lot_ID]

					,[INPUTPLAN_FLOW].[Step_No]
					,[INPUTPLAN_FLOW].[Process]
					,[INPUTPLAN_FLOW].[Job]

					,[lot_process_records].[id]				AS [Recode_ID]
					,[lot_process_records].[recorded_at]	AS [Recode_Datetime]
					,[lot_process_records].[record_class]	AS [RecodeClass_No]

					,[machines].[name]						AS [Mc_No]
					,[models].[name]						AS [Mc_Model]
					,[lot_process_records].[qty_pass]		AS [PassQty_Pcs]

			FROM
					#INPUTPLAN_FLOW AS [INPUTPLAN_FLOW]
		
			INNER JOIN
					[APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			ON
					[APCSProDB].[trans].[lot_process_records].[lot_id] = [INPUTPLAN_FLOW].[Lot_ID]
					AND [APCSProDB].[trans].[lot_process_records].[step_no] = [INPUTPLAN_FLOW].[Step_No]

			LEFT JOIN 
					[APCSProDB].[mc].[machines] WITH (NOLOCK)
			ON 
					[APCSProDB].[mc].[machines] .[id] = [APCSProDB].[trans].[lot_process_records].[machine_id]

			LEFT JOIN
					[APCSProDB].[mc].[models] WITH (NOLOCK)
			ON
					[APCSProDB].[mc].[models].[id] = [APCSProDB].[mc].[machines].[machine_model_id]

			WHERE
					[APCSProDB].[trans].[lot_process_records].[record_class] IN ('1','31','2','12','32')
	
	CREATE TABLE #LOAD_APCS
	(
			[Input_Date]			DATE
			,[Ship_Date]			DATE
			,[PackageGroup]			CHAR(10)
			,[Package]				CHAR(20)
			,[Package_FT]			CHAR(20)
			,[Device]				CHAR(20)
			,[Device_FT]			VARCHAR(20)
			,[Lot_No]				CHAR(20)
			,[InputQty_Pcs]			INT
			,[Shipment]				INT
			,[LastStep_No]			INT
			,[LastQty_Pcs]			INT

			,[SpacialFlow]			INT
			,[Step_No]				INT
			,[Process]				NVARCHAR(20)
			,[Job]					NVARCHAR(20)

			,[Mc_No]				NVARCHAR(30)
			,[Mc_Model]				NVARCHAR(30)
			,[PassQty_Pcs]			INT

			,[StartTime]			DATETIME
			,[EndTime]				DATETIME

			,[ProcessTime_Min]		INT
			,[LeadTimeSum_Min]		INT
			,[NextStep_No]			INT
	)

	INSERT INTO #LOAD_APCS

			SELECT
					[INPUTPLAN_FLOW].[Input_Date]
					,[INPUTPLAN_FLOW].[Ship_Date]
					,[INPUTPLAN_FLOW].[PackageGroup]
					,[INPUTPLAN_FLOW].[Package]
					,[INPUTPLAN_FLOW].[Package_FT]
					,[INPUTPLAN_FLOW].[Device]
					,[INPUTPLAN_FLOW].[Device_FT]
					,[INPUTPLAN_FLOW].[Lot_No]
					,[INPUTPLAN_FLOW].[InputQty_Pcs]
					,[INPUTPLAN_FLOW].[Shipment]
					,[INPUTPLAN_FLOW].[LastStep_No]
					,[INPUTPLAN_FLOW].[LastQty_Pcs]

					,[INPUTPLAN_FLOW].[SpacialFlow]
					,[INPUTPLAN_FLOW].[Step_No]
					,[INPUTPLAN_FLOW].[Process]
					,[INPUTPLAN_FLOW].[Job]

					,[RECORD_DETAIL].[Mc_No]
					,[RECORD_DETAIL].[Mc_Model]
					,[RECORD_DETAIL].[PassQty_Pcs]
					
					,[LOT_START].[StartTime]
					,CASE WHEN ([LOT_START].[StartTime] <= [LOT_END].[EndTime]) THEN CAST([LOT_END].[EndTime] AS DATETIME2) END AS [EndTime]

					,[INPUTPLAN_FLOW].[ProcessTime_Min]
					,[INPUTPLAN_FLOW].[LeadTimeSum_Min]
					,[INPUTPLAN_FLOW].[NextStep_No]

			FROM
					#INPUTPLAN_FLOW AS [INPUTPLAN_FLOW]

			LEFT JOIN
			(
					SELECT 
							[Lot_ID]
							,[Step_No]
							,[Process]
							,[Job]
							,MAX([Recode_ID]) AS [Recode_ID]
					FROM 
							#INPUTPLAN_RECORD AS [INPUTPLAN_RECORD]
					GROUP BY
							[Lot_ID]
							,[Step_No]
							,[Process]
							,[Job]

			) AS [STEP_FLOW]

			ON
					[STEP_FLOW].[Lot_ID] = [INPUTPLAN_FLOW].[Lot_ID]
					AND [STEP_FLOW].[Step_No] = [INPUTPLAN_FLOW].[Step_No]
					AND [STEP_FLOW].[Process] = [INPUTPLAN_FLOW].[Process]
					AND [STEP_FLOW].[Job] = [INPUTPLAN_FLOW].[Job]

			LEFT JOIN
					#INPUTPLAN_RECORD AS [RECORD_DETAIL]
			ON
					[RECORD_DETAIL].[Recode_ID] = [STEP_FLOW].[Recode_ID]

			LEFT JOIN
			(
					SELECT 
							[Lot_ID]
							,[Step_No]
							,[Process]
							,[Job]
							,MAX([Recode_Datetime]) AS [StartTime]
					FROM
							#INPUTPLAN_RECORD AS [INPUTPLAN_RECORD]
					WHERE 
							[RecodeClass_No] IN ('1','31')
					GROUP BY 
							[Lot_ID]
							,[Step_No]
							,[Process]
							,[Job]

			) AS [LOT_START]

			ON 
					[LOT_START].[Step_No] = [INPUTPLAN_FLOW].[Step_No] 
					AND [LOT_START].[Lot_ID] = [INPUTPLAN_FLOW].[Lot_ID]
					AND [LOT_START].[Process] = [INPUTPLAN_FLOW].[Process]
					AND [LOT_START].[Job] = [INPUTPLAN_FLOW].[Job]

			LEFT JOIN
			(
					SELECT
							[Lot_ID]
							,[Step_No]
							,[Process]
							,[Job]
							,MAX([Recode_Datetime]) AS [EndTime]
					FROM 
							#INPUTPLAN_RECORD AS [INPUTPLAN_RECORD]
					WHERE 
							[RecodeClass_No] IN ('2','12','32')
					GROUP BY 
							[Lot_ID]
							,[Step_No]
							,[Process]
							,[Job]

			) AS [LOT_END]

			ON 
					[LOT_END].[Step_No] = [INPUTPLAN_FLOW].[Step_No] 
					AND [LOT_END].[Lot_ID] = [INPUTPLAN_FLOW].[Lot_ID]
					AND [LOT_END].[Process] = [INPUTPLAN_FLOW].[Process]
					AND [LOT_END].[Job] = [INPUTPLAN_FLOW].[Job]

			WHERE [INPUTPLAN_FLOW].[Step_No] <> [INPUTPLAN_FLOW].[NextStep_No]

			--ORDER BY [INPUTPLAN_FLOW].[Lot_No],[INPUTPLAN_FLOW].[Step_No]

	DECLARE @LeadtimeJob INT
	
	CREATE TABLE #LOT_IN_JOB
	(
			[Input_Date]			DATE
			,[Ship_Date]			DATE
			,[PackageGroup]			CHAR(10)
			,[Package]				CHAR(20)
			,[Package_FT]			CHAR(20)
			,[Device]				CHAR(20)
			,[Device_FT]			VARCHAR(20)
			,[Lot_No]				CHAR(20)
			,[InputQty_Pcs]			INT
			,[Shipment]				INT
			,[LastStep_No]			INT
			,[LastQty_Pcs]			INT

			,[SpacialFlow]			INT
			,[Step_No]				INT
			,[Process]				NVARCHAR(20)
			,[Job]					NVARCHAR(20)

			,[Mc_No]				NVARCHAR(30)
			,[Mc_Model]				NVARCHAR(30)
			,[PassQty_Pcs]			INT

			,[StartTime]			DATETIME
			,[EndTime]				DATETIME

			,[ProcessTime_Min]		INT
			,[LeadTimeSum_Min]		INT
			,[NextStep_No]			INT
	)

	
	IF (@Job = 'FL')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #LOAD_APCS AS [LOAD_APCS] WHERE [LOAD_APCS].[Job] IN ('ＦＬ','FLFT','FLFTTP','FL(OS1)') AND [SpacialFlow] = '0'

			SET @LeadtimeJob = -2
			END

	ELSE IF (@Job = 'HOT O/S')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #LOAD_APCS AS [LOAD_APCS] WHERE [LOAD_APCS].[Job] = @Job AND [SpacialFlow] = '0'
			
			SET @LeadtimeJob = -3
			END

	ELSE IF (@Job = 'FT')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #LOAD_APCS AS [LOAD_APCS] WHERE [LOAD_APCS].[Job] IN ('AUTO(1)','AUTO(2)','AUTO(3)') AND [SpacialFlow] = '0'

			SET @LeadtimeJob = -2
			END

	ELSE IF (@Job = 'AUTO(1)')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #LOAD_APCS AS [LOAD_APCS] WHERE [LOAD_APCS].[Job] = @Job AND [SpacialFlow] = '0'
			
			SET @LeadtimeJob = -3
			END

	ELSE IF (@Job = 'AUTO(2)')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #LOAD_APCS AS [LOAD_APCS] WHERE [LOAD_APCS].[Job] = @Job AND [SpacialFlow] = '0'
			
			SET @LeadtimeJob = -4
			END

	ELSE IF (@Job = 'AUTO(3)')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #LOAD_APCS AS [LOAD_APCS] WHERE [LOAD_APCS].[Job] = @Job AND [SpacialFlow] = '0'
			
			SET @LeadtimeJob = -5
			END

	ELSE IF (@Job = 'AGING IN')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #LOAD_APCS AS [LOAD_APCS] WHERE [LOAD_APCS].[Process] = @Job AND [SpacialFlow] = '0'

			SET @LeadtimeJob = -6
			END

	ELSE IF (@Job = 'TP')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #LOAD_APCS AS [LOAD_APCS] WHERE [LOAD_APCS].[Process] = @Job AND [SpacialFlow] = '0'

			SET @LeadtimeJob = -7
			END

	ELSE IF (@Job = 'O/G')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #LOAD_APCS AS [LOAD_APCS] WHERE [LOAD_APCS].[Process] = @Job AND [SpacialFlow] = '0'

			SET @LeadtimeJob = -8
			END

	ELSE
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #LOAD_APCS AS [LOAD_APCS] WHERE [LOAD_APCS].[Process] = @Job AND [SpacialFlow] = '0'

			SET @LeadtimeJob = 0
			END 

	--CREATE TABLE #LOT_FULL_DETAIL
	--(
	--		[PackageGroup]			CHAR(10)
	--		,[Package]				CHAR(20)
	--		,[Package_FT]			CHAR(20)
	--		,[Device]				CHAR(20)
	--		,[Device_FT]			VARCHAR(20)
	--		,[Input_Date]			DATE
	--		,[Ship_Date]			DATE
	--		,[Lot_No]				CHAR(20)
	--		,[InputQty_Pcs]			INT
	--		,[LastStep_No]			INT

	--		,[FB_Job]				NVARCHAR(20)
	--		,[FB_StartTime]			DATETIME
	--		,[FB_EndTime]			DATETIME
	--		,[FB_PassQty_Pcs]		INT

	--		,[F_Job]				NVARCHAR(20)
	--		,[F_StartTime]			DATETIME
	--		,[F_EndTime]			DATETIME
	--		,[F_ProcessTime_Min]	INT
	--		,[F_PassQty_Pcs]		INT

	--		,[O_Job]				NVARCHAR(20)
	--		,[O_Mc_No]				NVARCHAR(30)
	--		,[O_Mc_Model]			NVARCHAR(30)
	--		,[O_StartTime]			DATETIME
	--		,[O_EndTime]			DATETIME
	--		,[O_ProcessTime_Min]	INT
	--		,[O_PassQty_Pcs]		INT

	--)

	--INSERT INTO #LOT_FULL_DETAIL
			SELECT 
					TRIM([LOT_OWNER].[PackageGroup])				AS [PackageGroup]
					,TRIM([LOT_OWNER].[Package])					AS [Package]
					,TRIM([LOT_OWNER].[Package_FT])					AS [Package_FT]
					,TRIM([LOT_OWNER].[Device])						AS [Device]
					,[LOT_OWNER].[Device_FT]
					,[LOT_OWNER].[Input_Date]
					,[LOT_OWNER].[Ship_Date]
					,TRIM([LOT_OWNER].[Lot_No])						AS [Lot_No]
					,[LOT_OWNER].[InputQty_Pcs]
					,[LOT_OWNER].[LastQty_Pcs]

					,[LOT_FRONT_BEFORE].[Job]						AS [FB_Job]
					,[LOT_FRONT_BEFORE].[StartTime]					AS [FB_StartTime]
					,[LOT_FRONT_BEFORE].[EndTime]					AS [FB_EndTime]
					,ISNULL([LOT_FRONT_BEFORE].[PassQty_Pcs],0)		AS [FB_PassQty_Pcs]

					,[LOT_FRONT].[Job]								AS [F_Job]
					,[LOT_FRONT].[StartTime]						AS [F_StartTime]
					,[LOT_FRONT].[EndTime]							AS [F_EndTime]
					,[LOT_FRONT].[ProcessTime_Min]					AS [F_ProcessTime_Min]
					,ISNULL([LOT_FRONT].[PassQty_Pcs],0)			AS [F_PassQty_Pcs]

					,[LOT_OWNER].[Job]								AS [O_Job]
					,[LOT_OWNER].[Mc_No]							AS [O_Mc_No]
					,[LOT_OWNER].[Mc_Model]							AS [O_Mc_Model]
					,[LOT_OWNER].[StartTime]						AS [O_StartTime]
					,[LOT_OWNER].[EndTime]							AS [O_EndTime]
					,[LOT_OWNER].[ProcessTime_Min]					AS [O_ProcessTime_Min]
					,CASE WHEN ([LOT_OWNER].[EndTime] IS NULL) 
					THEN 0 ELSE [LOT_OWNER].[PassQty_Pcs] 
					END												AS [O_PassQty_Pcs]

			FROM 
					#LOT_IN_JOB AS [LOT_OWNER]

			LEFT JOIN
					(SELECT [Lot_No],[NextStep_No],MAX([Step_No]) AS [Step_No] FROM #LOAD_APCS GROUP BY [Lot_No],[NextStep_No]) AS [STEPMAX_FRONT]
			ON
					[STEPMAX_FRONT].[Lot_No] = [LOT_OWNER].[Lot_No]
					AND [STEPMAX_FRONT].[NextStep_No] = [LOT_OWNER].[Step_No]

			LEFT JOIN
					#LOAD_APCS AS [LOT_FRONT]
			ON
					[LOT_FRONT].[Lot_No] = [LOT_OWNER].[Lot_No]
					AND [LOT_FRONT].[Step_No] = [STEPMAX_FRONT].[Step_No]
					AND [LOT_FRONT].[NextStep_No] = [LOT_OWNER].[Step_No]

			LEFT JOIN
					(SELECT [Lot_No],[NextStep_No],MAX([Step_No]) AS [Step_No] FROM #LOAD_APCS GROUP BY [Lot_No],[NextStep_No]) AS [STEPMAX_FRONT_BEFORE]
			ON
					[STEPMAX_FRONT_BEFORE].[Lot_No] = [LOT_OWNER].[Lot_No]
					AND [STEPMAX_FRONT_BEFORE].[NextStep_No] = [LOT_FRONT].[Step_No]

			LEFT JOIN
					#LOAD_APCS AS [LOT_FRONT_BEFORE]
			ON
					[LOT_FRONT_BEFORE].[Lot_No] = [LOT_OWNER].[Lot_No]
					AND 
					([LOT_FRONT_BEFORE].[Step_No] = [STEPMAX_FRONT_BEFORE].[Step_No] OR ([STEPMAX_FRONT_BEFORE].[Step_No] IS NULL AND [LOT_FRONT_BEFORE].[Step_No] = ([LOT_FRONT].[Step_No] - 1)))

	--SELECT * FROM #LOT_FULL_DETAIL

END
