-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_PD4_Progress_Test]
	-- Add the parameters for the stored procedure here

	@SelectDate		DATE
		-- YYYY-MM-DD

	,@ReportType	VARCHAR(20)
		-- DailyReport
		-- WipByLot
	
	,@UnitType		CHAR
		-- Lot		= 'L'
		-- Kpcs		= 'K'
		-- Pcs		= 'P'

	,@Floor			VARCHAR(2)
		-- 1F		= '1'
		-- 2F		= '2'

	,@Job			NVARCHAR(20)
		-- FL
		-- AUTO(1)
		-- AUTO(2)
		-- AUTO(3)
		-- AGING IN
		-- O/G

	,@Package		CHAR(20)
		-- All Package		= 'ALL'
		-- Other Package	= Name Of Package

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	DECLARE @SelectDateTime		DATETIME
	DECLARE @LeadtimeJob		INT
	DECLARE @countBefore		INT
	DECLARE @countAfter			INT

	DECLARE @RateInput			FLOAT

	DECLARE @TpType				VARCHAR(10)
	SET @TpType = @Job

	SET @SelectDateTime = @SelectDate
	SET @SelectDateTime = DATEADD(HOUR,8,@SelectDateTime)

	SET @CountBefore	= -45
	SET @countAfter		= 0

	SET @RateInput = 0.8

	IF (@Job = 'FL' or @Job = 'HOT O/S' or @Job = 'TP' or @Job = 'AGING IN' or @Job = 'O/G')
			BEGIN
					SET @RateInput = 0.8
			END
	ELSE
			BEGIN
					SET @RateInput = 1.5
			END

	IF(@Floor = '22' AND @JOB = 'TP(TODO)')
			BEGIN
					SET @JOB = 'TP'
			END
	ELSE
			BEGIN
					SET @JOB = @JOB
			END

	CREATE TABLE #PACKAGE_ALL
	(
			[Package_ID]		INT
			,[Package]			CHAR(20)
			,[PackageGroup]		CHAR(10)
	)

	INSERT INTO #PACKAGE_ALL
	SELECT
			[packages].[id] AS [Package_ID]
			,[packages].[name] AS [Package]
			,[package_groups].[name] AS [PackageGroup]

	FROM
			[APCSProDB].[method].[packages] WITH (NOLOCK)

	INNER JOIN
			[APCSProDB].[method].[package_groups] WITH (NOLOCK)
	ON
			[package_groups].[id] = [packages].[package_group_id]
	WHERE
			[packages].[is_enabled] = '1'


	CREATE TABLE #PACKAGE_FLOOR
	(
			[Package_ID]		INT
			,[Package]			CHAR(20)
			,[PackageGroup]		CHAR(10)
	)

	IF (@Floor = '1' AND @Package = 'ALL')
			BEGIN
					IF (@JOB = 'FL')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('GDIC')
											OR [Package] IN ('HSSOP-C16','HTSSOP-A44','HTSSOP-A44R','HTSSOP-B20','HTSSOP-B40','HTSSOP-B54','HTSSOP-C48','HTSSOPC48E','HTSSOP-C48R','SSOP-A54_23','SSOP-A54_36','SSOP-B28W','TSSOP-C48V')
							END

					ELSE
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('-')
							END
			END
	
	ELSE IF (@Floor = '2' AND @Package = 'ALL')
			BEGIN
					IF (@JOB = 'FL')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] = 'SMALL'
							END

					ELSE IF (@JOB = 'HOT O/S')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] = 'WSOF5'
							END

					ELSE IF (@JOB = 'FT')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] = 'SMALL'
							END

					ELSE IF (@JOB = 'AUTO(1)')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] = 'SMALL' AND
											(
												[Package] NOT LIKE '%SOF%'
												AND [Package] NOT LIKE 'SSOP%'
												AND [Package] NOT LIKE 'SOP%'
												AND [Package] <> 'TSSOP-C10J'
											)
							END

					ELSE IF (@JOB = 'AUTO(2)')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] = 'SMALL' AND
											(
												[Package] NOT LIKE '%SOF%'
												AND [Package] NOT LIKE '%SSOP%'
												AND [Package] NOT LIKE 'SOP%'
												AND [Package] NOT IN ('MSOP10','MSOP8-HF','HSON-A8')
											)
							END

					ELSE IF (@JOB = 'AUTO(3)')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] = '-'
							END

					ELSE IF (@JOB = 'AGING IN')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] = 'HSON-A8'
							END

					ELSE IF (@JOB = 'TP')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											([PackageGroup] = 'SMALL')
											AND ([Package] NOT LIKE '%SOF%' AND [Package] NOT LIKE 'SOP4%' AND [Package] <> 'SSOP6')
							END

					ELSE
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('-')
							END
			END

	ELSE IF (@Floor = '22' AND @Package = 'ALL') --TODO
			BEGIN
					IF (@JOB = 'FL')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('HRP5','HRP7','TO263-3F','TO263-5F','TO252S-3','TO252S-5','SOT223-4','SOT223-4F','TO252-J5F')
											OR [Package] IN ('HSOP-M36','SOP20','SOP22','SOP24','SSOP-A20','SSOP-A24','HTSSOPC-64','HTSSOP-C64A','SSOP-B24','SSOP-B28','TSSOP-B30')
											OR [Package] IN ('TO263-3','TO263-5','TO263-7','TO252-J3','TO252-J5','TO252-3','TO252-5','TO252-3','TO252-5','TO252-3/5','TO252-3/5')
											OR [Package] IN ('SSOP-A32','SSOP-B40')
							END

					ELSE IF (@JOB = 'HOT O/S')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] = '-'
							END

					ELSE IF (@JOB = 'FT')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('HRP5','HRP7','TO263-3F','TO263-5F','TO252S-3','TO252S-5','SOT223-4','SOT223-4F','TO252-J5F')
											OR [Package] IN ('HSOP-M36','SOP20','SOP22','SOP24','SSOP-A20','SSOP-A24','HTSSOPC-64','HTSSOP-C64A','SSOP-B24','SSOP-B28','TSSOP-B30')
											OR [Package] IN ('TO263-3','TO263-5','TO263-7','TO252-J3','TO252-J5','TO252-3','TO252-5','TO252-3','TO252-5','TO252-3/5','TO252-3/5')
											OR [Package] IN ('SSOP-A32','SSOP-B40')
							END

					ELSE IF (@JOB = 'AUTO(1)')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('HRP5','HRP7','TO263-3F','TO263-5F','TO252S-3','TO252S-5','SOT223-4','SOT223-4F','TO252-J5F')
											OR [Package] IN ('HSOP-M36','SOP20','SOP22','SOP24','SSOP-A20','SSOP-A24','HTSSOPC-64','HTSSOP-C64A','SSOP-B24','SSOP-B28','TSSOP-B30')
											OR [Package] IN ('TO263-3','TO263-5','TO263-7','TO252-J3','TO252-J5','TO252-3','TO252-5','TO252-3','TO252-5','TO252-3/5','TO252-3/5')
											OR [Package] IN ('SSOP-A32','SSOP-B40')
							END

					ELSE IF (@JOB = 'AUTO(2)')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('HRP5','HRP7','TO263-3F','TO263-5F','TO252S-3','TO252S-5','SOT223-4','SOT223-4F','TO252-J5F')
											OR [Package] IN ('HSOP-M36','SOP20','SOP22','SOP24','SSOP-A20','SSOP-A24','HTSSOPC-64','HTSSOP-C64A','SSOP-B24','SSOP-B28','TSSOP-B30')
											OR [Package] IN ('TO263-3','TO263-5','TO263-7','TO252-J3','TO252-J5','TO252-3','TO252-5','TO252-3','TO252-5','TO252-3/5','TO252-3/5')
											OR [Package] IN ('SSOP-A32','SSOP-B40')
							END

					ELSE IF (@JOB = 'AUTO(3)')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] = '-'
							END

					ELSE IF (@JOB = 'AGING IN')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] = '-'
							END

					ELSE IF (@JOB = 'TP' AND @TpType = 'TP')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('TO263-3','TO263-5','TO263-7','TO252-J3','TO252-J5','TO252-3','TO252-5','TO252-3','TO252-5','TO252-3/5','TO252-3/5')
											OR [Package] IN ('SSOP-A32','SSOP-B40')
							END

					ELSE IF (@JOB = 'TP' AND @TpType = 'TP(TODO)')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('HRP5','HRP7','TO263-3F','TO263-5F','TO252S-3','TO252S-5','SOT223-4','SOT223-4F','TO252-J5F')
											OR [Package] IN ('HSOP-M36','SOP20','SOP22','SOP24','SSOP-A20','SSOP-A24','HTSSOPC-64','HTSSOP-C64A','SSOP-B24','SSOP-B28','TSSOP-B30')
							END

					ELSE
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('HRP5','HRP7','TO263-3F','TO263-5F','TO252S-3','TO252S-5','SOT223-4','SOT223-4F','TO252-3','TO252-5','TO252-J5','TO252-J5F')
											OR [Package] IN ('HSOP-M36','SOP20','SOP22','SOP24','SSOP-A20','SSOP-A24','HTSSOPC-64','HTSSOP-C64A','SSOP-B24','SSOP-B28')
							END
			END

	ELSE IF (@Floor = '3' AND @Package = 'ALL')
			BEGIN
					IF (@JOB = 'FL')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('QFP')
							END

					ELSE IF (@JOB = 'HOT O/S')
					BEGIN
							INSERT INTO #PACKAGE_FLOOR
							SELECT
									[Package_ID]
									,[Package]
									,[PackageGroup]
							FROM
									#PACKAGE_ALL AS [PACKAGE_ALL]
							WHERE
									[Package] = '-'
					END

					ELSE IF (@JOB = 'FT')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('QFP')
							END

					ELSE IF (@JOB = 'AUTO(1)')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('QFP')
							END

					ELSE IF (@JOB = 'AUTO(2)')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('QFP') AND
											(
												[Package] NOT LIKE '%SOF%'
												AND [Package] NOT LIKE '%SSOP%'
												AND [Package] NOT LIKE 'SOP%'
												AND [Package] NOT IN ('HTQFP64BV','MSOP10','MSOP8-HF','UQFP64M','VQFP48CR','VQFP64F','HSON-A8')
											)
							END

					ELSE IF (@JOB = 'AUTO(3)')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('SQFP80','UQFP64','VQFP48C','VQFP48CM','VQFP64')
							END

					ELSE IF (@JOB = 'AGING IN')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[Package] IN ('QFP-A64')
											OR [Package] LIKE 'HTQFP64%'
											OR [Package] LIKE 'UQFP64%'
											OR [Package] LIKE 'VQFP64%'
											OR [Package] LIKE 'SQFP%'
							END

					ELSE IF (@JOB = 'TP')
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('QFP')
							END

					ELSE
							BEGIN
									INSERT INTO #PACKAGE_FLOOR
									SELECT
											[Package_ID]
											,[Package]
											,[PackageGroup]
									FROM
											#PACKAGE_ALL AS [PACKAGE_ALL]
									WHERE
											[PackageGroup] IN ('-')
							END
			END

	ELSE
			BEGIN
					INSERT INTO #PACKAGE_FLOOR
					SELECT
							[Package_ID]
							,[Package]
							,[PackageGroup]
					FROM
							#PACKAGE_ALL AS [PACKAGE_ALL]
					WHERE
							[Package] = @Package
			END

	CREATE TABLE #INPUTPLAN
	(
			[CreatDate]			DATETIME
			,[InputDate]		DATE
			,[ShipDate]			DATE
			,[PackageGroup]		CHAR(10)
			,[Package]			CHAR(20)
			,[Device]			CHAR(20)

			,[Lot_ID]			INT
			,[DeviceSlip_ID]	INT
			,[LotNo]			CHAR(20)
			,[InputQty]			INT
			,[LastQty]			INT

			,[LastStep_No]		INT
			,[Shipment]			BIT
	)

	INSERT INTO #INPUTPLAN
	SELECT 
			[lots].[created_at] AS [CreatDate]
			,[DayInput].[date_value] AS [InputDate]
			,[DayShipment].[date_value] AS [ShipDate]
			,[PACKAGE_FLOOR].[PackageGroup]
			,[PACKAGE_FLOOR].[Package]
			,[device_names].[name] AS [Device]

			,[lots].[id] AS [Lot_ID]
			,[lots].[device_slip_id] AS [DeviceSlip_ID]
			,[lots].[lot_no] AS [LotNo]
			,CASE 
					WHEN (@UnitType = 'L') THEN 1
					WHEN (@UnitType = 'K') THEN [lots].[qty_in] / 1000
					ELSE [lots].[qty_in]
			END AS [InputQty]

			,CASE 
					WHEN (@UnitType = 'L') THEN 1
					WHEN (@UnitType = 'K') THEN ([lots].[qty_last_pass] + [lots].[qty_last_fail]) / 1000
					ELSE ([lots].[qty_last_pass] + [lots].[qty_last_fail])
			END AS [LastQty]

			,[lots].[step_no] AS [LastStep_No]
			,CASE WHEN ([item_labels1].[label_eng] IN ('All Shipped','Partially Shipped')) THEN 1 ELSE 0 END AS [Shipment]

	FROM
			[APCSProDB].[trans].[lots]  WITH (NOLOCK)

	INNER JOIN
			#PACKAGE_FLOOR AS [PACKAGE_FLOOR]
	ON
			[PACKAGE_FLOOR].[Package_ID] = [lots].[act_package_id]

	INNER JOIN
			[APCSProDB].[method].[device_names] WITH (NOLOCK)
	ON
			[device_names].[id] = [lots].[act_device_name_id]

	INNER JOIN 
			[APCSProDB].[method].[jobs]  WITH (NOLOCK)
	ON 
			[jobs].[id] = [lots].[act_job_id]

	INNER JOIN 
			[APCSProDB].[method].[processes] WITH (NOLOCK)
	ON
			[processes].[id] = [lots].[act_process_id]

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
			[DayInput].[date_value] BETWEEN DATEADD(DAY,@CountBefore,@SelectDate) AND DATEADD(DAY,@countAfter,@SelectDate)
			AND [item_labels1].[label_eng] <> 'Cancel' AND SUBSTRING([lots].[lot_no],1,2) IN ('22','23')


	CREATE TABLE #INPUTPLAN_FLOW
	(
			[CreatDate]			DATETIME
			,[InputDate]		DATE
			,[ShipDate]			DATE
			,[PackageGroup]		CHAR(10)
			,[Package]			CHAR(20)
			,[Device]			CHAR(20)
			,[Lot_ID]			INT
			,[DeviceSlip_ID]	INT
			,[LotNo]			CHAR(20)
			,[InputQty]			INT
			,[LastQty]			INT
			,[LastStep_No]		INT
			,[Shipment]			BIT

			,[StepNo]			INT
			,[Process]			NVARCHAR(20)
			,[Job]				NVARCHAR(20)
			,[NextStepNo]		INT

			,[Process_Min]		INT
	)

	INSERT INTO #INPUTPLAN_FLOW

			SELECT
					[INPUTPLAN].*
					,[device_flows].[step_no] AS [StepNo]
					,[processes].[name] AS [Process]
					,[jobs].[name] AS [Job]
					,[device_flows].[next_step_no] AS [NextStepNo]

					,ISNULL([device_flows].[process_minutes] ,0) AS [Process_Min]

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
					[INPUTPLAN].*
					,[special_flows].[step_no] AS [StepNo]
					,[processes].[name] AS [Process]
					,[jobs].[name] AS [Job]
					,[special_flows].[back_step_no] AS [NextStepNo]

					,'0' AS [Process_Min]

			FROM 
					#INPUTPLAN AS [INPUTPLAN]

			INNER JOIN
					[APCSProDB].[trans].[special_flows] WITH (NOLOCK)
			ON
					[APCSProDB].[trans].[special_flows].[lot_id] = [INPUTPLAN].[Lot_ID]

			INNER JOIN
					[APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK)
			ON
					[APCSProDB].[trans].[lot_special_flows].[special_flow_id] = [APCSProDB].[trans].[special_flows].[id]

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

	
	CREATE TABLE #LOT_DETAIL
	(
			[LotProcess_ID]		BIGINT
			,[Lot_ID]			INT
			
			,[StepNo]			INT
			,[Process]			NVARCHAR(20)
			,[Job]				NVARCHAR(20)
			,[NextStepNo]		INT
			
			,[RecodeClass]		TINYINT
			,[McNo]				NVARCHAR(30)
			,[McModel]			NVARCHAR(30)
			,[RecodeTime]		DATETIME
			,[PassQty]			INT
	)

	INSERT INTO #LOT_DETAIL

			SELECT
					[lot_process_records].[id] AS [LotProcess_ID]
					,[INPUTPLAN_FLOW].[Lot_ID]

					,[INPUTPLAN_FLOW].[StepNo]
					,[APCSProDB].[method].[processes].[name] AS [Process]
					,[APCSProDB].[method].[jobs].[name] AS [Job]
					,[INPUTPLAN_FLOW].[NextStepNo]
					
					,[lot_process_records].[record_class] AS [RecodeClass]
					,[machines].[name] AS [McNo]
					,[models].[name] AS [McModel]
					,[APCSProDB].[trans].[lot_process_records].[recorded_at] AS [RecodeDatetime]
					,[APCSProDB].[trans].[lot_process_records].[qty_pass] AS [PassQty]

			FROM
					#INPUTPLAN_FLOW AS [INPUTPLAN_FLOW]
		
			INNER JOIN
					[APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
			ON
					[APCSProDB].[trans].[lot_process_records].[lot_id] = [INPUTPLAN_FLOW].[Lot_ID]
					AND [APCSProDB].[trans].[lot_process_records].[step_no] = [INPUTPLAN_FLOW].[StepNo]

			LEFT JOIN 
					[APCSProDB].[mc].[machines] WITH (NOLOCK)
			ON 
					[APCSProDB].[mc].[machines] .[id] = [APCSProDB].[trans].[lot_process_records].[machine_id]

			LEFT JOIN
					[APCSProDB].[mc].[models] WITH (NOLOCK)
			ON
					[APCSProDB].[mc].[models].[id] = [APCSProDB].[mc].[machines].[machine_model_id]

			INNER JOIN 
					[APCSProDB].[method].[jobs] WITH (NOLOCK)
			ON 
					[APCSProDB].[method].[jobs].[id] = [APCSProDB].[trans].[lot_process_records].[job_id] 

			INNER JOIN 
					[APCSProDB].[method].[processes] WITH (NOLOCK)
			ON 
					[APCSProDB].[method].[processes].[id] = [APCSProDB].[trans].[lot_process_records].[process_id]

			WHERE
					[APCSProDB].[trans].[lot_process_records].[record_class] IN ('1','31','2','12','32')


	CREATE TABLE #LOT_DETAIL_GROUP
	(		
			[Lot_ID]			INT

			,[StepNo]			INT
			,[Process]			NVARCHAR(20)
			,[Job]				NVARCHAR(20)
			,[NextStepNo]		INT
			
			,[McNo]				NVARCHAR(30)
			,[McModel]			NVARCHAR(30)
			,[StartTime]		DATETIME
			,[EndTime]			DATETIME
			,[PassQty]			INT
	)

	INSERT INTO	#LOT_DETAIL_GROUP
			
			SELECT
					[LOT_DETAIL].[Lot_ID]

					,[LOT_DETAIL].[StepNo]
					,[LOT_DETAIL].[Process]
					,[LOT_DETAIL].[Job]
					,[LOT_DETAIL].[NextStepNo]

					,[LOT_DETAIL].[McNo]	
					,[LOT_DETAIL].[McModel]
					,[LOT_START].[StartTime]
					,CASE WHEN ([LOT_START].[StartTime] <= [LOT_END].[EndTime]) THEN CAST([LOT_END].[EndTime] AS datetime2) END AS [EndTime]
					,[LOT_DETAIL].[PassQty]

			FROM
					#LOT_DETAIL AS [LOT_DETAIL]

			RIGHT JOIN
			(
					SELECT 
							[Lot_ID]
							,[StepNo]
							,[Process]
							,[Job]
							,MAX([LotProcess_ID]) AS [LotProcess_ID]
					FROM 
							#LOT_DETAIL AS [LOT_DETAIL]
					GROUP BY
							[Lot_ID]
							,[StepNo]
							,[process]
							,[job]

			) AS [STEP_FLOW]

			ON
					[STEP_FLOW].[LotProcess_ID] = [LOT_DETAIL].[LotProcess_ID]
	
			LEFT JOIN
			(
					SELECT 
							[Lot_ID]
							,[StepNo]
							,[Process]
							,[Job]
							,MAX([RecodeTime]) AS [StartTime]
					FROM
							#LOT_DETAIL AS [LOT_DETAIL]
					WHERE 
							[RecodeClass] IN ('1','31')
					GROUP BY 
							[Lot_ID]
							,[StepNo]
							,[Process]
							,[Job]

			) AS [LOT_START]

			ON 
					[LOT_START].[StepNo] = [LOT_DETAIL].[StepNo] 
					AND [LOT_START].[Lot_ID] = [LOT_DETAIL].[Lot_ID]
					AND [LOT_START].[Process] = [LOT_DETAIL].[Process]
					AND [LOT_START].[Job] = [LOT_DETAIL].[Job]

			LEFT JOIN
			(
					SELECT
							[Lot_ID]
							,[StepNo]
							,[Process]
							,[Job]
							,MAX([RecodeTime]) AS [EndTime]
					FROM 
							#LOT_DETAIL AS [LOT_DETAILA]
					WHERE 
							[RecodeClass] IN ('2','12','32')
					GROUP BY 
							[Lot_ID]
							,[StepNo]
							,[Process]
							,[Job]

			) AS [LOT_END]

			ON 
					[LOT_END].[StepNo] = [LOT_DETAIL].[StepNo] 
					AND [LOT_END].[Lot_ID] = [LOT_DETAIL].[Lot_ID]
					AND [LOT_END].[Process] = [LOT_DETAIL].[Process]
					AND [LOT_END].[Job] = [LOT_DETAIL].[Job]


	CREATE TABLE #LOT_IN_JOB
	(
			[CreatDate]			DATETIME
			,[InputDate]		DATE
			,[ShipDate]			DATE
			,[PackageGroup]		CHAR(10)
			,[Package]			CHAR(20)
			,[Device]			CHAR(20)
			,[Lot_ID]			INT
			,[DeviceSlip_ID]	INT
			,[LotNo]			CHAR(20)
			,[InputQty]			INT
			,[LastQty]			INT
			,[LastStep_No]		INT
			,[Shipment]			BIT

			,[StepNo]			INT
			,[Process]			NVARCHAR(20)
			,[Job]				NVARCHAR(20)
			,[NextStepNo]		INT

			,[Process_Min]		INT
	)

	
	IF (@Job = 'FL')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #INPUTPLAN_FLOW AS [INPUTPLAN_FLOW] WHERE [INPUTPLAN_FLOW].[Job] IN ('ＦＬ','FLFT','FLFTTP','FL(OS1)')

			SET @LeadtimeJob = -2
			END

	ELSE IF (@Job = 'HOT O/S')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #INPUTPLAN_FLOW AS [INPUTPLAN_FLOW] WHERE [INPUTPLAN_FLOW].[Job] = @Job
			
			SET @LeadtimeJob = -3
			END

	ELSE IF (@Job = 'AUTO(1)')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #INPUTPLAN_FLOW AS [INPUTPLAN_FLOW] WHERE [INPUTPLAN_FLOW].[Job] IN (@Job,'OS+AUTO(1)')
			
			SET @LeadtimeJob = -3
			END

	ELSE IF (@Job = 'AUTO(2)')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #INPUTPLAN_FLOW AS [INPUTPLAN_FLOW] WHERE [INPUTPLAN_FLOW].[Job] = @Job
			
			SET @LeadtimeJob = -4
			END

	ELSE IF (@Job = 'AUTO(3)')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #INPUTPLAN_FLOW AS [INPUTPLAN_FLOW] WHERE [INPUTPLAN_FLOW].[Job] = @Job
			
			SET @LeadtimeJob = -5
			END

	ELSE IF (@Job = 'AGING IN')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #INPUTPLAN_FLOW AS [INPUTPLAN_FLOW] WHERE [INPUTPLAN_FLOW].[Process] = @Job

			SET @LeadtimeJob = -6
			END

	ELSE IF (@Job = 'TP')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #INPUTPLAN_FLOW AS [INPUTPLAN_FLOW] WHERE ([INPUTPLAN_FLOW].[Process] = @Job AND [INPUTPLAN_FLOW].[Job] NOT IN ('TP-TP','Lot Matching'))

			SET @LeadtimeJob = -7
			END

	ELSE IF (@Job = 'O/G')
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #INPUTPLAN_FLOW AS [INPUTPLAN_FLOW] WHERE [INPUTPLAN_FLOW].[Process] = @Job

			SET @LeadtimeJob = -8
			END

	ELSE
			BEGIN
			INSERT INTO #LOT_IN_JOB
			SELECT * FROM #INPUTPLAN_FLOW AS [INPUTPLAN_FLOW] WHERE [INPUTPLAN_FLOW].[Process] = @Job

			SET @LeadtimeJob = 0
			END 

	CREATE TABLE #INPUTPLAN_DETAIL
	(
			[InputDate]					DATE
			,[ShipDate]					DATE
			,[PackageGroup]				CHAR(10)
			,[Package]					CHAR(20)
			,[Device]					CHAR(20)
			,[LotNo]					CHAR(20)
			,[InputQty]					INT
			,[LastQty]					INT

			,[FRONT_BEFORE_StepNo]		INT
			,[FRONT_BEFORE_Job]			NVARCHAR(20)
			,[FRONT_BEFORE_McNo]		NVARCHAR(30)
			,[FRONT_BEFORE_StartTime]	DATETIME
			,[FRONT_BEFORE_EndTime]		DATETIME
			,[FRONT_BEFORE_PassQty]		INT

			,[FRONT_StepNo]				INT
			,[FRONT_Job]				NVARCHAR(20)
			,[FRONT_McNo]				NVARCHAR(30)
			,[FRONT_StartTime]			DATETIME
			,[FRONT_EndTime]			DATETIME
			,[FRONT_Process_Min]		INT
			,[FRONT_PassQty]			INT

			,[OWNER_StepNo]				INT
			,[OWNER_Job]				NVARCHAR(20)
			,[OWNER_McNo]				NVARCHAR(30)
			,[OWNER_McModel]			NVARCHAR(30)
			,[OWNER_StartTime]			DATETIME
			,[OWNER_EndTime]			DATETIME
			,[OWNER_Process_Min]		INT
			,[OWNER_PassQty]			INT

			,[LastStep_No]				INT
			,[Shipment]					BIT
	)

	INSERT INTO #INPUTPLAN_DETAIL

			SELECT 
					[LOT_OWNER].[InputDate] 
					,[LOT_OWNER].[ShipDate]
					,[LOT_OWNER].[PackageGroup]
					,[LOT_OWNER].[Package]
					,[LOT_OWNER].[Device]
					,[LOT_OWNER].[LotNo]
					,[LOT_OWNER].[InputQty]
					,[LOT_OWNER].[LastQty]

					,CASE 
							WHEN ([LOT_OWNER].[StepNo] = '100' AND [LOT_FRONT_BEFORE].[StepNo] IS NULL) THEN '80'
							WHEN ([LOT_FRONT].[StepNo] = '100' AND [LOT_FRONT_BEFORE].[StepNo] IS NULL) THEN '90'
							ELSE [LOT_FRONT_BEFORE].[StepNo] 
					END AS [FRONT_BEFORE_StepNo]

					,CASE 
							WHEN ([LOT_OWNER].[StepNo] = '100' AND [LOT_FRONT_BEFORE].[Job] IS NULL) THEN 'TSUGITASHI BEFORE'
							WHEN ([LOT_FRONT].[StepNo] = '100' AND [LOT_FRONT_BEFORE].[Job] IS NULL) THEN 'TSUGITASHI'
							ELSE [LOT_FRONT_BEFORE].[Job] 
					END AS [FRONT_BEFORE_Job]

					,CASE 
							WHEN ([LOT_OWNER].[StepNo] = '100' AND [LOT_DETAIL_FRONT_BEFORE].[McNo] IS NULL) THEN 'TP-TG-XX'
							WHEN ([LOT_FRONT].[StepNo] = '100' AND [LOT_DETAIL_FRONT_BEFORE].[McNo] IS NULL) THEN 'TP-TG-XX'
							ELSE [LOT_DETAIL_FRONT_BEFORE].[McNo]
					END AS [FRONT_BEFORE_McNo]

					,CASE 
							WHEN ([LOT_OWNER].[StepNo] = '100' AND [LOT_DETAIL_FRONT_BEFORE].[StartTime] IS NULL) THEN [LOT_OWNER].[CreatDate]
							WHEN ([LOT_FRONT].[StepNo] = '100' AND [LOT_DETAIL_FRONT_BEFORE].[StartTime] IS NULL) THEN [LOT_OWNER].[CreatDate]
							ELSE [LOT_DETAIL_FRONT_BEFORE].[StartTime]
					END AS [FRONT_BEFORE_StartTime]

					,CASE 
							WHEN ([LOT_OWNER].[StepNo] = '100' AND [LOT_DETAIL_FRONT_BEFORE].[EndTime] IS NULL) THEN [LOT_OWNER].[CreatDate]
							WHEN ([LOT_FRONT].[StepNo] = '100' AND [LOT_DETAIL_FRONT_BEFORE].[EndTime] IS NULL) THEN [LOT_OWNER].[CreatDate]
							ELSE [LOT_DETAIL_FRONT_BEFORE].[EndTime]
					END AS [FRONT_BEFORE_EndTime]
					
					,CASE 
							WHEN (@UnitType = 'L') THEN 1
							WHEN (@UnitType = 'K' AND [LOT_DETAIL_FRONT_BEFORE].[PassQty] IS NOT NULL) THEN [LOT_DETAIL_FRONT_BEFORE].[PassQty] / 1000
							WHEN (@UnitType = 'P' AND [LOT_DETAIL_FRONT_BEFORE].[PassQty] IS NOT NULL) THEN [LOT_DETAIL_FRONT_BEFORE].[PassQty]
							WHEN (@UnitType = 'K' AND [LOT_DETAIL_FRONT_BEFORE].[PassQty] IS NULL) THEN [LOT_OWNER].[InputQty] / 1000
							WHEN (@UnitType = 'P' AND [LOT_DETAIL_FRONT_BEFORE].[PassQty] IS NULL) THEN [LOT_OWNER].[InputQty]
							ELSE '0'
					END AS [FRONT_BEFORE_PassQty]

					,CASE 
							WHEN ([LOT_OWNER].[StepNo] = '100' AND [LOT_FRONT].[StepNo] IS NULL) THEN '90'
							ELSE [LOT_FRONT].[StepNo]
					END AS [FRONT_StepNo]

					,CASE 
							WHEN ([LOT_OWNER].[StepNo] = '100' AND [LOT_FRONT].[Job] IS NULL) THEN 'TSUGITASHI'
							ELSE [LOT_FRONT].[Job]
					END AS [FRONT_Job]

					,CASE 
							WHEN ([LOT_OWNER].[StepNo] = '100' AND [LOT_DETAIL_FRONT].[McNo] IS NULL) THEN 'TP-TG-XX'
							ELSE [LOT_DETAIL_FRONT].[McNo]
					END AS [FRONT_McNo]

					,CASE 
							WHEN ([LOT_OWNER].[StepNo] = '100' AND [LOT_DETAIL_FRONT].[StartTime] IS NULL) THEN [LOT_OWNER].[CreatDate]
							ELSE [LOT_DETAIL_FRONT].[StartTime]
					END AS [FRONT_StartTime]

					,CASE 
							WHEN ([LOT_OWNER].[StepNo] = '100' AND [LOT_DETAIL_FRONT].[EndTime] IS NULL) THEN [LOT_OWNER].[CreatDate]
							ELSE [LOT_DETAIL_FRONT].[EndTime]
					END AS [FRONT_EndTime]

					,CASE 
							WHEN ([LOT_OWNER].[StepNo] = '100' AND [LOT_FRONT].[Process_Min] IS NULL) THEN '0'
							ELSE [LOT_FRONT].[Process_Min]
					END AS [FRONT_Process_Min]

					,CASE 
							WHEN (@UnitType = 'L') THEN 1
							WHEN (@UnitType = 'K' AND [LOT_DETAIL_FRONT].[PassQty] IS NOT NULL) THEN [LOT_DETAIL_FRONT].[PassQty] / 1000
							WHEN (@UnitType = 'P' AND [LOT_DETAIL_FRONT].[PassQty] IS NOT NULL) THEN [LOT_DETAIL_FRONT].[PassQty]
							WHEN (@UnitType = 'K' AND [LOT_DETAIL_FRONT].[PassQty] IS NULL) THEN [LOT_OWNER].[InputQty] / 1000
							WHEN (@UnitType = 'P' AND [LOT_DETAIL_FRONT].[PassQty] IS NULL) THEN [LOT_OWNER].[InputQty]
							ELSE '0'
					END AS [FRONT_PassQty]

					,[LOT_OWNER].[StepNo] AS [OWNER_StepNo]
					,[LOT_OWNER].[Job] AS [OWNER_Job]
					,[LOT_DETAIL_OWNER].[McNo] AS [OWNER_McNo]
					,[LOT_DETAIL_OWNER].[McModel] AS [OWNER_McModel]
					,[LOT_DETAIL_OWNER].[StartTime] AS [OWNER_StartTime]
					,[LOT_DETAIL_OWNER].[EndTime] AS [OWNER_StartTime]
					,[LOT_OWNER].[Process_Min] AS [OWNER_Process_Min]
					,CASE 
							WHEN (@UnitType = 'L') THEN 1
							WHEN (@UnitType = 'K' AND [LOT_DETAIL_OWNER].[PassQty] IS NOT NULL) THEN [LOT_DETAIL_OWNER].[PassQty] / 1000
							WHEN (@UnitType = 'P' AND [LOT_DETAIL_OWNER].[PassQty] IS NOT NULL) THEN [LOT_DETAIL_OWNER].[PassQty]
							WHEN (@UnitType = 'K' AND [LOT_DETAIL_OWNER].[PassQty] IS NULL) THEN [LOT_OWNER].[InputQty] / 1000
							WHEN (@UnitType = 'P' AND [LOT_DETAIL_OWNER].[PassQty] IS NULL) THEN [LOT_OWNER].[InputQty]
							ELSE '0'
					END AS [OWNER_PassQty]

					,[LOT_OWNER].[LastStep_No]
					,[LOT_OWNER].[Shipment]

			FROM 
					#LOT_IN_JOB AS [LOT_OWNER]

			LEFT JOIN
					#INPUTPLAN_FLOW AS [LOT_FRONT]
			ON
					[LOT_FRONT].[Lot_ID] = [LOT_OWNER].[Lot_ID]
					AND [LOT_FRONT].[NextStepNo] = [LOT_OWNER].[StepNo]

			LEFT JOIN
					#INPUTPLAN_FLOW AS [LOT_FRONT_BEFORE]
			ON
					[LOT_FRONT_BEFORE].[Lot_ID] = [LOT_FRONT].[Lot_ID]
					AND ([LOT_FRONT_BEFORE].[NextStepNo] = [LOT_FRONT].[StepNo] OR [LOT_FRONT_BEFORE].[StepNo] = ([LOT_FRONT].[StepNo]-1))

			LEFT JOIN 
					#LOT_DETAIL_GROUP AS [LOT_DETAIL_OWNER]
			ON
					[LOT_DETAIL_OWNER].[Lot_ID] = [LOT_OWNER].[Lot_ID]
					AND [LOT_DETAIL_OWNER].[StepNo] = [LOT_OWNER].[StepNo]
					AND [LOT_DETAIL_OWNER].[Process] = [LOT_OWNER].[Process]
					AND [LOT_DETAIL_OWNER].[Job] = [LOT_OWNER].[Job]

			LEFT JOIN 
					#LOT_DETAIL_GROUP AS [LOT_DETAIL_FRONT]
			ON
					[LOT_DETAIL_FRONT].[Lot_ID] = [LOT_FRONT].[Lot_ID]
					AND [LOT_DETAIL_FRONT].[StepNo] = [LOT_FRONT].[StepNo]
					AND [LOT_DETAIL_FRONT].[Process] = [LOT_FRONT].[Process]
					AND [LOT_DETAIL_FRONT].[Job] = [LOT_FRONT].[Job]

			LEFT JOIN 
					#LOT_DETAIL_GROUP AS [LOT_DETAIL_FRONT_BEFORE]
			ON
					[LOT_DETAIL_FRONT_BEFORE].[Lot_ID] = [LOT_FRONT_BEFORE].[Lot_ID]
					AND [LOT_DETAIL_FRONT_BEFORE].[StepNo] = [LOT_FRONT_BEFORE].[StepNo]
					AND [LOT_DETAIL_FRONT_BEFORE].[Process] = [LOT_FRONT_BEFORE].[Process]
					AND [LOT_DETAIL_FRONT_BEFORE].[Job] = [LOT_FRONT_BEFORE].[Job]


	CREATE TABLE #INPUTPLAN_DETAIL_MAX
	(
			[Package]					CHAR(20)
			,[Device]					CHAR(20)
			,[InputDate]				DATE
			,[ShipDate]					DATE
			,[LotNo]					CHAR(20)
			,[InputQty]					INT
			,[LastQty]					INT

			,[FRONT_BEFORE_StepNo]		INT
			,[FRONT_BEFORE_Job]			NVARCHAR(20)
			,[FRONT_BEFORE_McNo]		NVARCHAR(30)
			,[FRONT_BEFORE_StartTime]	DATETIME
			,[FRONT_BEFORE_EndTime]		DATETIME
			,[FRONT_BEFORE_PassQty]		INT

			,[FRONT_StepNo]				INT
			,[FRONT_Job]				NVARCHAR(20)
			,[FRONT_McNo]				NVARCHAR(30)
			,[FRONT_StartTime]			DATETIME
			,[FRONT_EndTime]			DATETIME
			,[FRONT_Process_Min]		INT
			,[FRONT_ResultQty]			INT

			,[OWNER_StepNo]				INT
			,[OWNER_Job]				NVARCHAR(20)
			,[OWNER_McNo]				NVARCHAR(30)
			,[OWNER_McModel]			NVARCHAR(30)
			,[OWNER_StartTime]			DATETIME
			,[OWNER_EndTime]			DATETIME
			,[OWNER_Process_Min]		INT
			,[OWNER_ResultQty]			INT

			,[LastStep_No]				INT
			,[Shipment]					BIT
	)

	INSERT INTO #INPUTPLAN_DETAIL_MAX

			SELECT DISTINCT 
					[Package]
					,[Device]
					,[InputDate]
					,[ShipDate]
					,[INPUTPLAN_DETAIL].[LotNo]
					,[InputQty]
					,[LastQty]

					,[FRONT_BEFORE_StepNo]
					,[FRONT_BEFORE_Job]
					,[FRONT_BEFORE_McNo]
					,[FRONT_BEFORE_StartTime]
					,[FRONT_BEFORE_EndTime]
					,ISNULL([FRONT_BEFORE_PassQty],0) AS [FRONT_BEFORE_ResultQty]

					,[FRONT_StepNo]
					,[FRONT_Job]
					,[FRONT_McNo]
					,[FRONT_StartTime]
					,[FRONT_EndTime]
					,[FRONT_Process_Min]
					,ISNULL([FRONT_PassQty],0) AS [FRONT_ResultQty]

					,[OWNER_StepNo]
					,[INPUTPLAN_DETAIL].[OWNER_Job]
					,[OWNER_McNo]
					,[OWNER_McModel]
					,[OWNER_StartTime]
					,[OWNER_EndTime]
					,[OWNER_Process_Min]
					,CASE WHEN ([OWNER_EndTime] IS NULL) THEN 0 ELSE [OWNER_PassQty] END AS [OWNER_ResultQty]

					,[LastStep_No]
					,[Shipment]

			FROM 
					#INPUTPLAN_DETAIL AS [INPUTPLAN_DETAIL]

			INNER JOIN
					(
							SELECT 
									[LotNo],[OWNER_Job],MAX([FRONT_BEFORE_StepNo]) AS [FRONT_BEFORE_StepNo_Max]
							FROM 
									#INPUTPLAN_DETAIL AS [INPUTPLAN_DETAIL] 
							GROUP BY 
									[LotNo],[OWNER_Job]

					) AS [INPUTPLAN_DETAIL_MAX]
			ON
					[INPUTPLAN_DETAIL_MAX].[LotNo] = [INPUTPLAN_DETAIL].[LotNo]
					AND [INPUTPLAN_DETAIL_MAX].[OWNER_Job] = [INPUTPLAN_DETAIL].[OWNER_Job]
					AND [INPUTPLAN_DETAIL_MAX].[FRONT_BEFORE_StepNo_Max] = [INPUTPLAN_DETAIL].[FRONT_BEFORE_StepNo]

	
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

	INSERT INTO #LOT_LAST_DATA
	SELECT 
			[Package]
			,[Device]
			,[InputDate]
			,[ShipDate]
			,[LotNo]
			,[InputQty]
			,[LastQty]

			,[FRONT_BEFORE_EndTime]
			,[FRONT_BEFORE_PassQty]

			,[FRONT_Job]
			,[FRONT_McNo]
			,[FRONT_StartTime]
			,[FRONT_EndTime]
			,[FRONT_Process_Min]
			,[FRONT_ResultQty]

			,[OWNER_Job]
			,[OWNER_McNo]
			,[OWNER_McModel]
			,[OWNER_StartTime]
			,[OWNER_EndTime]
			,[OWNER_Process_Min]
			,[OWNER_ResultQty]

	FROM
			#INPUTPLAN_DETAIL_MAX AS [INPUTPLAN_DETAIL_MAX]
	WHERE 
			NOT([OWNER_EndTime] IS NULL AND ([LastStep_No] > [OWNER_StepNo] OR [Shipment] = '1')) 
			
	
	IF (@ReportType = 'DailyReport')
			BEGIN
					SELECT 
							[PACKAGE_FLOOR].[Package]
							,ISNULL ([InputPlan_Process].[Input Tomorrow],0) AS [Input Tomorrow]
							,CAST(ISNULL ([MachineDay],0) AS DECIMAL(10,1)) AS [M/C Day]
							,CAST(ISNULL ([MachineNight],0) AS DECIMAL(10,1)) AS [M/C Night]
							,ISNULL ([Total Front],0) AS [Total Front]
							,ISNULL ([Total 08:00],0) AS [Wip 08:00]
							,ISNULL ([Total 14:00],0) AS [Wip 14:00]
							,ISNULL ([Total 20:00],0) AS [Wip 20:00]
							,ISNULL ([Total 02:00],0) AS [Wip 02:00]
                    
							,ISNULL ([Plan1],0) AS [Plan Day 1]
							,ISNULL ([Plan2],0) AS [Plan Day 2]
							,ISNULL (([Plan1] + [Plan2]),0) As [Plan Day Total]
							,ISNULL ([Day 1],0) AS [Day 1]
							,ISNULL ([Day 2],0) AS [Day 2]
							,ISNULL (([Day 1]+[Day 2]),0) AS [Day Total]

							,ISNULL ([Plan4],0) As [Plan Night 1]
							,ISNULL ([Plan5],0) As [Plan Night 2]
							,ISNULL (([Plan4] + [Plan5]),0) As [Plan Night Total]
							,ISNULL ([Night 1],0) AS [Night 1]                                                                                                                                                                                                                                                                                                        
							,ISNULL ([Night 2],0) AS [Night 2]
							,ISNULL (([Night 1]+[Night 2]),0) AS [Night Total]
							,ISNULL (([Day 1]+[Day 2]+[Night 1]+[Night 2]),0) AS [Result Total]
							,ISNULL ([Total 08:00 Tomorrow],0) AS [Wip 08:00 Tomorrow]
							,ISNULL ([InputPlan_Process].[Input Today],0) AS [Input Today]
							,ISNULL (([Plan1] + [Plan2] + [Plan4] + [Plan5]),0) As [Plan Total]
							--,((ISNULL (([Day 1]+[Day 2]+[Night 1]+[Night 2]),0) + ((ISNULL ([DelayResult],0) + ISNULL ([DelayDailyReport].[ProgressDelay],0)) - ISNULL ([DelayInput],0))) - ISNULL ([InputPlan_Process].[Input Today],0)) As [Progress Delay]
							,'0' As [Progress Delay]
							--,((ISNULL ([DelayResult],0) + ISNULL ([DelayDailyReport].[ProgressDelay],0)) - ISNULL ([DelayInput],0)) AS [Progrees Delay Yesterday]
							,'0' AS [Progrees Delay Yesterday]
							,[Comment]
							,CAST((@RateInput * ISNULL ([InputPlan_Process].[Input Today],0)) AS DECIMAL(10,1)) AS [STD Wip]
							,CAST((ISNULL([DataCapacity].[Capacity],0) * (ISNULL([MachineDay],0) + ISNULL([MachineNight],0))) AS DECIMAL(10,1)) AS [CAPA Setup]

							,CONCAT('~/SearchPackageDetail.aspx?Date=',@SelectDate,'&Floor=', @Floor,'&Process=', @TpType ,'&PackageName=' , [PACKAGE_FLOOR].[Package]) AS [PackageLike]
	
					FROM
							#PACKAGE_FLOOR AS [PACKAGE_FLOOR]
	
					LEFT JOIN 
							(
									SELECT 
											[Package]
											,SUM(CASE WHEN [FRONT_EndTime] <= @SelectDateTime AND ([OWNER_EndTime] > @SelectDateTime OR [OWNER_EndTime] IS NULL) THEN [FRONT_ResultQty] ELSE 0 END) AS [Total 08:00]
											,SUM(CASE WHEN [FRONT_EndTime] <= DATEADD(HOUR,6,@SelectDateTime) AND ([OWNER_EndTime] > DATEADD(HOUR,6,@SelectDateTime) OR [OWNER_EndTime] IS NULL) THEN [FRONT_ResultQty] ELSE 0 END) AS [Total 14:00]
											,SUM(CASE WHEN [FRONT_EndTime] <= DATEADD(HOUR,12,@SelectDateTime) AND ([OWNER_EndTime] > DATEADD(HOUR,12,@SelectDateTime) OR [OWNER_EndTime] IS NULL) THEN [FRONT_ResultQty] ELSE 0 END) AS [Total 20:00]
											,SUM(CASE WHEN [FRONT_EndTime] <= DATEADD(HOUR,18,@SelectDateTime) AND ([OWNER_EndTime] > DATEADD(HOUR,18,@SelectDateTime) OR [OWNER_EndTime] IS NULL) THEN [FRONT_ResultQty] ELSE 0 END) AS [Total 02:00]
											,SUM(CASE WHEN [FRONT_EndTime] <= DATEADD(HOUR,24,@SelectDateTime) AND ([OWNER_EndTime] > DATEADD(HOUR,24,@SelectDateTime) OR [OWNER_EndTime] IS NULL) THEN [FRONT_ResultQty] ELSE 0 END) AS [Total 08:00 Tomorrow]

									FROM
											#LOT_LAST_DATA AS [LOT_LAST_DATA]
	
									GROUP BY 
											[Package]

							) AS [DATA_WIP]
					ON 
							[DATA_WIP].[Package] = [PACKAGE_FLOOR].[Package]

					LEFT JOIN 
							(
									SELECT 
											[Package]
											,SUM(CASE WHEN [FRONT_BEFORE_EndTime] <= DATEADD(HOUR,24,@SelectDateTime) AND ([FRONT_EndTime] > DATEADD(HOUR,24,@SelectDateTime) OR ([FRONT_EndTime] IS NULL AND [OWNER_StartTime] IS NULL)) THEN [FRONT_BEFORE_PassQty] ELSE 0 END) AS [Total Front]

									FROM
											#LOT_LAST_DATA AS [LOT_LAST_DATA]
	
									GROUP BY 
											[Package]

							) AS [DATA_WIP_FRONT]
					ON 
							[DATA_WIP_FRONT].[Package] = [PACKAGE_FLOOR].[Package]

					LEFT JOIN 
							(
									SELECT 
											[Package],
											SUM(CASE WHEN [OWNER_EndTime] BETWEEN @SelectDateTime AND DATEADD(HOUR,6,@SelectDateTime) THEN [OWNER_ResultQty] ELSE 0 END) AS [Day 1],
											SUM(CASE WHEN [OWNER_EndTime] BETWEEN DATEADD(HOUR,6,@SelectDateTime) AND DATEADD(HOUR,12,@SelectDateTime) THEN [OWNER_ResultQty] ELSE 0 END) AS [Day 2],
											SUM(CASE WHEN [OWNER_EndTime] BETWEEN DATEADD(HOUR,12,@SelectDateTime) AND DATEADD(HOUR,18,@SelectDateTime) THEN [OWNER_ResultQty] ELSE 0 END) AS [Night 1],
											SUM(CASE WHEN [OWNER_EndTime] BETWEEN DATEADD(HOUR,18,@SelectDateTime) AND DATEADD(HOUR,24,@SelectDateTime) THEN [OWNER_ResultQty] ELSE 0 END) AS [Night 2], 
											SUM(CASE WHEN [OWNER_EndTime] BETWEEN DATEADD(DAY,-1,@SelectDateTime) AND  @SelectDateTime THEN [OWNER_ResultQty] ELSE 0 END) AS [DelayResult]
					
									FROM 
											#LOT_LAST_DATA AS [LOT_LAST_DATA]
					
									GROUP BY 
											[Package]

							) AS [PackageResult] 
					ON 
							[PackageResult].[Package] = [PACKAGE_FLOOR].[Package]

					LEFT JOIN 
							(
									SELECT 
											[LOT_IN_JOB].[Package] 
											,SUM(CASE WHEN [LOT_IN_JOB].[InputDate] = DATEADD(DAY,(-1) + @LeadtimeJob,@SelectDate) THEN [InputQty] ELSE 0 END) AS [DelayInput] 
											,SUM(CASE WHEN [LOT_IN_JOB].[InputDate] = DATEADD(DAY,@LeadtimeJob,@SelectDate) THEN [InputQty] ELSE 0 END) AS [Input Today]
											,SUM(CASE WHEN [LOT_IN_JOB].[InputDate] = DATEADD(DAY,1 + @LeadtimeJob,@SelectDate) THEN [InputQty] ELSE 0 END) AS [Input Tomorrow]
									FROM 
											#LOT_IN_JOB AS [LOT_IN_JOB]		
									WHERE
											SUBSTRING([LotNo],5,1) IN ('A')
														
									GROUP BY
											[Package]

							) AS [InputPlan_Process]				
					ON 
							[InputPlan_Process].[Package] = [PACKAGE_FLOOR].[Package]

					LEFT JOIN 
							(
									SELECT
											[PackageName]
											,[MachineDay]
											,[MachineNight]
											,CASE 
													WHEN (@UnitType = 'L') THEN [Plan1]
													WHEN (@UnitType = 'K') THEN 0
													ELSE 0
											END AS [Plan1]
											,CASE 
													WHEN (@UnitType = 'L') THEN [Plan2]
													WHEN (@UnitType = 'K') THEN 0
													ELSE 0
											END AS [Plan2]
											,CASE 
													WHEN (@UnitType = 'L') THEN [Plan4]
													WHEN (@UnitType = 'K') THEN 0
													ELSE 0
											END AS [Plan4]
											,CASE 
													WHEN (@UnitType = 'L') THEN [Plan5]
													WHEN (@UnitType = 'K') THEN 0
													ELSE 0
											END AS [Plan5]
											,CASE 
													WHEN (@UnitType = 'L') THEN [ProgressDelay]
													WHEN (@UnitType = 'K') THEN 0
													ELSE 0
											END AS [ProgressDelay]
											,[Comment] 
									FROM 
											[DBx].[dbo].[FL_DailyReport_Plan] WITH (NOLOCK)

									WHERE [PlanDate] = @SelectDate AND [ProcessName] = @TpType
							) AS [DataPlan]
					ON 
							[DataPlan].[PackageName] = [PACKAGE_FLOOR].[Package]

					LEFT JOIN 
							(		
									SELECT 
											[PackageName]
											,[Month]
											,CASE 
													WHEN (@UnitType = 'L') THEN [Capacity]
													WHEN (@UnitType = 'K') THEN 0
													ELSE 0
											END AS [Capacity]
									FROM 
											[DBx].[dbo].[FL_DailyReport_DataSetting] WITH (NOLOCK)
									UNPIVOT
									(
											[Capacity] FOR [Month] IN ([Month1],[Month2],[Month3],[Month4],[Month5],[Month6],[Month7],[Month8],[Month9],[Month10],[Month11],[Month12])
									
									) AS [CAPA_PIVOT]

									WHERE 
											[DataType] = 'CAPACITY' AND [DataYear] = YEAR(@SelectDate) AND [ProcessName] = @Job AND [Month] = CONCAT('Month',MONTH(@SelectDate))

							) AS [DataCapacity]            
					ON 
							[DataCapacity].[PackageName] = [PACKAGE_FLOOR].[Package]

					LEFT JOIN 
							(
									SELECT 
											[PackageName],[ProgressDelay] 
									FROM 
											[DBx].[dbo].[FL_DailyReport_Plan] WITH (NOLOCK)
									WHERE 
											[PlanDate] = DATEADD(DAY,-1,@SelectDate) AND [ProcessName] = @Job
							) AS [DelayDailyReport]
					ON 
							[DelayDailyReport].[PackageName] = [PACKAGE_FLOOR].[Package]

					ORDER BY
							[PACKAGE_FLOOR].[PackageGroup] DESC,[PACKAGE_FLOOR].[Package]
			END

	ELSE IF (@ReportType = 'WipByLot')
			BEGIN
					SELECT
							[No]
							,[DaySlip]
							,[Package]
							,[Device]
							,[LotNo]
							,[DateDelay]

							,[PiecesFrontBefore]

							,[FrontProcessName]
							,[StarttimeFront]
							,CASE 
								WHEN ([Location] = 'FRONT PD.') THEN DATEADD(MINUTE,[FRONT_Process_Min],[StarttimeFront])
								ELSE [EndtimeFront] END
							AS [EndtimeFront]
							,CASE 
								WHEN ([Location] = 'FRONT PD.') THEN [LastQty]
								ELSE [PiecesFront] END
							AS [PiecesFront]

							,[Location]

							,[StarttimeOwner]
							,CASE 
								WHEN ([Location] = 'WIP' OR [Location] = 'FRONT PD.' OR [Location] = 'LOT End' OR [Location] = '-') THEN [EndtimeOwner]
								ELSE DATEADD(MINUTE,[OWNER_Process_Min],[StarttimeOwner]) END
							AS [EndtimeOwner]
							,CASE 
								WHEN ([Location] = 'WIP' OR [Location] = 'FRONT PD.' OR [Location] = 'LOT End' OR [Location] = '-') THEN [PiecesOwner]
								ELSE [LastQty] END
							AS [PiecesOwner]

							,[Remark]

					FROM
							(
							SELECT DISTINCT 
									ROW_NUMBER() OVER(ORDER BY DATEDIFF(DAY,[ShipDate],@SelectDate) DESC,[LotNo] ASC) AS [No]
									,CASE 
											WHEN (SUBSTRING([LotNo],6,1) = '1') THEN 'Tue.'
											WHEN (SUBSTRING([LotNo],6,1) = '2') THEN 'Wed.'
											WHEN (SUBSTRING([LotNo],6,1) = '3') THEN 'Thu.'
											WHEN (SUBSTRING([LotNo],6,1) = '4') THEN 'Fri.'
											WHEN (SUBSTRING([LotNo],6,1) = '5') THEN 'Sat.'
											WHEN (SUBSTRING([LotNo],6,1) = '6') THEN 'Sun.'
											WHEN (SUBSTRING([LotNo],6,1) = '7') THEN 'Mon.'
											ELSE '-' END
									AS [DaySlip]
									,[Package]
									,[Device]
									,[LotNo]
									,DATEDIFF(DAY,[ShipDate],@SelectDate) AS [DateDelay]

									,[FRONT_BEFORE_PassQty] AS [PiecesFrontBefore]

									,CASE 
											WHEN ([FRONT_StartTime] IS NOT NULL AND [FRONT_EndTime] IS NOT NULL AND [OWNER_EndTime] > DATEADD(DAY,1,@SelectDateTime)) THEN 'WIP'
											WHEN ([FRONT_StartTime] IS NOT NULL AND [FRONT_EndTime] IS NULL) THEN 'FRONT PD.'
											WHEN ([FRONT_StartTime] IS NOT NULL AND [FRONT_EndTime] IS NOT NULL AND [OWNER_StartTime] IS NULL) THEN 'WIP'
											WHEN ([OWNER_StartTime] IS NOT NULL AND [OWNER_EndTime] IS NULL) THEN [OWNER_McNo]
											WHEN ([OWNER_EndTime] IS NOT NULL) THEN 'LOT End'
											ELSE '-'
									END AS [Location]

									,[FRONT_Job] AS [FrontProcessName]
									,[FRONT_StartTime] AS [StarttimeFront]
									,[FRONT_EndTime] AS [EndtimeFront]
									,[FRONT_Process_Min]
									,ISNULL([FRONT_ResultQty],0) AS [PiecesFront]

									,[OWNER_StartTime] AS [StarttimeOwner]
									,[OWNER_EndTime] AS [EndtimeOwner]
									,[OWNER_Process_Min]
									,CASE WHEN ([OWNER_EndTime] IS NULL) THEN 0 ELSE [FRONT_ResultQty] END AS [PiecesOwner]

									,[LOT_LAST_DATA].[LastQty]

									,ISNULL([DBx].[dbo].[FL_DailyReport_LotRemark].[remark],[wip_monitor_delay_lot_condition_detail].[status]) AS [Remark]

							FROM 
									#LOT_LAST_DATA AS [LOT_LAST_DATA]

							LEFT JOIN
									[DBx].[dbo].[FL_DailyReport_LotRemark] WITH (NOLOCK)
							ON
									[DBx].[dbo].[FL_DailyReport_LotRemark].[lot_no] = [LOT_LAST_DATA].[LotNo]
									AND [DBx].[dbo].[FL_DailyReport_LotRemark].[job_front] = [LOT_LAST_DATA].[FRONT_Job]
									AND [DBx].[dbo].[FL_DailyReport_LotRemark].[job_owner] = @TpType
							
							LEFT JOIN
									[APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] WITH (NOLOCK)
							ON
									[LOT_LAST_DATA].[LotNo] = [wip_monitor_delay_lot_condition_detail].[lot_no]

							WHERE
									([OWNER_EndTime] > @SelectDateTime AND [FRONT_EndTime] < DATEADD(DAY,1,@SelectDateTime))
									OR ([OWNER_EndTime] IS NULL AND [FRONT_EndTime] < DATEADD(DAY,1,@SelectDateTime))
									OR ([FRONT_EndTime] IS NULL AND [OWNER_EndTime] IS NULL AND [FRONT_StartTime] < DATEADD(DAY,1,@SelectDateTime))
							) AS [WipByLot]
			END

	ELSE IF (@ReportType = 'Other')
			BEGIN
					SELECT * FROM #LOT_LAST_DATA AS [LOT_LAST_DATA] 
			END

	ELSE IF (@ReportType = 'CheckData')
			BEGIN
					SELECT * FROM #INPUTPLAN AS [INPUTPLAN]
			END

	ELSE IF (@ReportType = 'InputPlan')
			BEGIN
					SELECT 
							[LOT_IN_JOB].[Package]
							,[LOT_IN_JOB].[Device]
							,[LOT_IN_JOB].[InputDate]
							,[LOT_IN_JOB].[LotNo]
							,[LOT_IN_JOB].[InputQty]
							
					FROM 
							#LOT_IN_JOB AS [LOT_IN_JOB]		
					WHERE
							SUBSTRING([LotNo],5,1) IN ('A') AND [LOT_IN_JOB].[InputDate] = DATEADD(DAY,@LeadtimeJob,@SelectDate)
			END

	ELSE
			BEGIN
					SELECT * FROM #LOT_LAST_DATA AS [LOT_LAST_DATA] 
			END

	DROP TABLE #INPUTPLAN
	DROP TABLE #INPUTPLAN_DETAIL
	DROP TABLE #INPUTPLAN_DETAIL_MAX
	DROP TABLE #INPUTPLAN_FLOW
	DROP TABLE #LOT_DETAIL
	DROP TABLE #LOT_DETAIL_GROUP
	DROP TABLE #LOT_IN_JOB
	DROP TABLE #LOT_LAST_DATA
	DROP TABLE #PACKAGE_ALL
	DROP TABLE #PACKAGE_FLOOR
END