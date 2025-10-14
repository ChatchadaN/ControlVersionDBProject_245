-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_program_cellcon]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(20)
	, @mc_no VARCHAR(20) 
	, @recipe_id INT
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here	

	DECLARE @category_lot INT
	,@process_id INT
	,@job_id INT
	,@row_num INT
	,@ft_device VARCHAR(50)

	DECLARE @program_name VARCHAR(50)
	,@process VARCHAR(50)
	,@job VARCHAR(50)
	,@device_name VARCHAR(50)
	,@category_ois VARCHAR(50)

	DECLARE @tester1 VARCHAR(50)
	,@test_box1 VARCHAR(50)
	,@adaptor1 VARCHAR(50)
	,@adaptor2 VARCHAR(50)
	,@dut1 VARCHAR(50)
	,@dut2 VARCHAR(50)
	,@bridge_cable1 VARCHAR(50)
	,@bridge_cable2 VARCHAR(50)
	,@Option1 VARCHAR(50)
	,@Option2 VARCHAR(50)
	,@Option3 VARCHAR(50)

	DECLARE @commonjob_id int

	-- Check lot exists trans.lot
	IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE lot_no = @lot_no)
	BEGIN
		PRINT N'ไม่พบ lot in trans.lots'
	
		SELECT 'FALSE' AS Is_Pass 
			, 'lot_no not found in  trans.lots. Please check the data !!' AS Error_Message_ENG
			, N'ไม่พบข้อมูล lot_no นี้ใน trans.lots กรุณาตรวสอบข้อมูล !!' AS Error_Message_THA
			, '' AS [program_name]
			, '' AS [process]
			, '' AS [job]
			, '' AS [device_name]
			, '' AS [category_ois]
			, '' AS [tester1]
			, '' AS [test_box1]
			, '' AS [adaptor1]
			, '' AS [adaptor2]
			, '' AS [dut1]
			, '' AS [dut2]
			, '' AS [bridge_cable1]
			, '' AS [bridge_cable2]
			, '' AS [Option1]
			, '' AS [Option2]
			, '' AS [Option3]
		RETURN;
	END
	
	-- Check OIS Set
	IF NOT EXISTS (SELECT 1 FROM APCSProDB.method.ois_sets WHERE ois_sets.id = @recipe_id)
	BEGIN
		PRINT N'Case ไม่มี OIS Set'
	
		SELECT 'FALSE' AS Is_Pass 
			, 'OIS Set not found. Please check the data !!' AS Error_Message_ENG
			, N'ไม่พบ OIS Set นี้ กรุณาตรวสอบข้อมูล !!' AS Error_Message_THA
			, '' AS [program_name]
			, '' AS [process]
			, '' AS [job]
			, '' AS [device_name]
			, '' AS [category_ois]
			, '' AS [tester1]
			, '' AS [test_box1]
			, '' AS [adaptor1]
			, '' AS [adaptor2]
			, '' AS [dut1]
			, '' AS [dut2]
			, '' AS [bridge_cable1]
			, '' AS [bridge_cable2]
			, '' AS [Option1]
			, '' AS [Option2]
			, '' AS [Option3]
		RETURN;
	END

	---- Get data from trans.lots
	--SELECT @category_lot = production_category 
	--, @process_id = act_process_id
	--, @job_id = act_job_id
	--, @ft_device = ft_name
	--FROM APCSProDB.trans.lots
	--INNER JOIN APCSProDB.method.device_slips ON lots.device_slip_id = device_slips.device_slip_id
	--INNER JOIN APCSProDB.method.device_names ON lots.act_device_name_id = device_names.id
	--WHERE lot_no = @lot_no

	----Common job
	--SELECT @commonjob_id = to_job_id
	--FROM APCSProDB.trans.job_commons
	--WHERE job_id = @job_id


	DECLARE @is_spf int

	SELECT @is_spf = is_special_flow
	FROM APCSProDB.trans.lots
	WHERE lot_no = @lot_no

	--special_flow
	IF (@is_spf = 1)
	BEGIN
		print 'special_flow'

		-- Get data from trans.lots
		SELECT TOP 1 
		@category_lot = production_category 
		, @process_id = lots.act_process_id
		, @job_id = lot_special_flows.job_id
		, @ft_device = ft_name
		FROM APCSProDB.trans.lots
		INNER JOIN APCSProDB.method.device_slips on lots.device_slip_id = device_slips.device_slip_id
		INNER JOIN APCSProDB.method.device_names ON lots.act_device_name_id = device_names.id
		INNER JOIN APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
		INNER JOIN APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
		WHERE lot_no = @lot_no
		ORDER BY special_flows.id desc

		SELECT @commonjob_id = to_job_id
		FROM APCSProDB.trans.job_commons
		WHERE job_id = @job_id
	END
	--master_flow
	ELSE IF (@is_spf = 0)
	BEGIN
		print 'master_flow'

		-- Get data from trans.lots
		SELECT @category_lot = production_category 
		, @process_id = act_process_id
		, @job_id = act_job_id
		, @ft_device = ft_name
		FROM APCSProDB.trans.lots
		INNER JOIN APCSProDB.method.device_slips on lots.device_slip_id = device_slips.device_slip_id
		INNER JOIN APCSProDB.method.device_names ON lots.act_device_name_id = device_names.id
		WHERE lot_no = @lot_no

		SELECT @commonjob_id = to_job_id
		FROM APCSProDB.trans.job_commons
		WHERE job_id = @job_id
	END

	-- Check device lot ไม่ตรงกับ device recipe
	IF NOT EXISTS(SELECT 1 FROM APCSProDB.method.ois_sets WHERE ois_sets.id = @recipe_id AND [name] = @ft_device)
	BEGIN
		PRINT N'Case ผิดพลาด device lot ไม่ตรงกับ device recipe'
	
		SELECT 'FALSE' AS Is_Pass 
			, 'Device lot not mactch with Device recipe. Please check the data !!' AS Error_Message_ENG
			, N'Device lot ไม่ตรงกับ Device recipe กรุณาตรวสอบข้อมูล !!' AS Error_Message_THA
			, '' AS [program_name]
			, '' AS [process]
			, '' AS [job]
			, '' AS [device_name]
			, '' AS [category_ois]
			, '' AS [tester1]
			, '' AS [test_box1]
			, '' AS [adaptor1]
			, '' AS [adaptor2]
			, '' AS [dut1]
			, '' AS [dut2]
			, '' AS [bridge_cable1]
			, '' AS [bridge_cable2]
			, '' AS [Option1]
			, '' AS [Option2]
			, '' AS [Option3]
		RETURN;
	END

	--Check row production_category more then 1
	SELECT @row_num = COUNT(ois_set_lists.id)
	FROM APCSProDB.method.ois_sets
	INNER JOIN APCSProDB.method.ois_set_lists ON ois_sets.id = ois_set_lists.ois_set_id
	INNER JOIN APCSProDB.method.ois_recipes ON ois_set_lists.ois_recipe_id = ois_recipes.id
	WHERE ois_sets.id = @recipe_id 
	AND ois_recipes.production_category = @category_lot
	AND ois_recipes.is_released = 1
	AND ois_sets.name = @ft_device
	AND ois_recipes.job_id = @commonjob_id

	BEGIN TRANSACTION
	BEGIN TRY
		IF @row_num = 0
		BEGIN
			PRINT N'Case ois set ไม่จับคู่ ois recipe'

			ROLLBACK;
			SELECT 'FALSE' AS Is_Pass 
				, 'Program not found. Please check the data !!' AS Error_Message_ENG
				, N'ไม่พบข้อมูล Program กรุณาตรวสอบข้อมูล !!' AS Error_Message_THA
				, '' AS [program_name]
				, '' AS [process]
				, '' AS [job]
				, '' AS [device_name]
				, '' AS [category_ois]
				, '' AS [tester1]
				, '' AS [test_box1]
				, '' AS [adaptor1]
				, '' AS [adaptor2]
				, '' AS [dut1]
				, '' AS [dut2]
				, '' AS [bridge_cable1]
				, '' AS [bridge_cable2]
				, '' AS [Option1]
				, '' AS [Option2]
				, '' AS [Option3]
			RETURN;
		END
		ELSE IF @row_num > 1 
		BEGIN
			PRINT 'Case Multi'

			ROLLBACK;
			SELECT 'FALSE' AS Is_Pass 
				, 'This function not support for multi case !!' AS Error_Message_ENG
				, N'ฟังก์ชันนี้ยังไม่รองรับงาน Multi !!' AS Error_Message_THA
				, '' AS [program_name]
				, '' AS [process]
				, '' AS [job]
				, '' AS [device_name]
				, '' AS [category_ois]
				, '' AS [tester1]
				, '' AS [test_box1]
				, '' AS [adaptor1]
				, '' AS [adaptor2]
				, '' AS [dut1]
				, '' AS [dut2]
				, '' AS [bridge_cable1]
				, '' AS [bridge_cable2]
				, '' AS [Option1]
				, '' AS [Option2]
				, '' AS [Option3]
			RETURN;

			--IF NOT EXISTS(SELECT 1 FROM DBx.dbo.FTSetupReport WHERE MCNo = @mc_no AND LotNo = @lot_no )
			--BEGIN
			--	PRINT N'check in checksheet mcno or lotno ไม่ตรง'
		
			--	ROLLBACK;
			--	SELECT 'FALSE' AS Is_Pass 
			--		, 'Lot_no not found in MCNo. Please check the data !!' AS Error_Message_ENG
			--		, N'ไม่พบข้อมูล lot_no ใน MCNo กรุณาตรวสอบข้อมูล !!' AS Error_Message_THA
			--		, '' AS [program_name]
			--		, '' AS [process]
			--		, '' AS [job]
			--		, '' AS [device_name]
			--		, '' AS [category_ois]
			--		, '' AS [tester1]
			--		, '' AS [test_box1]
			--		, '' AS [adaptor1]
			--		, '' AS [adaptor2]
			--		, '' AS [dut1]
			--		, '' AS [dut2]
			--		, '' AS [bridge_cable1]
			--		, '' AS [bridge_cable2]
			--		, '' AS [Option1]
			--		, '' AS [Option2]
			--		, '' AS [Option3]
			--	RETURN;
			--END

			---- GET OIS DATA
			--DECLARE @OIS_DATA TABLE
			--(
			--	[program_name]		VARCHAR(50)
			--	, [processes]		VARCHAR(50)
			--	, [jobs]			VARCHAR(50)
			--	, [ft_device]		VARCHAR(50)
			--	, [category_ois]	VARCHAR(50)
			--	, [tester1]			VARCHAR(50)
			--	, [test_box1]		VARCHAR(50)
			--	, [adaptor1]		VARCHAR(50)
			--	, [adaptor2]		VARCHAR(50)
			--	, [dut1]			VARCHAR(50)
			--	, [dut2]			VARCHAR(50)
			--	, [bridge_cable1]	VARCHAR(50)
			--	, [bridge_cable2]	VARCHAR(50)
			--	, [Option1]			VARCHAR(50)
			--	, [Option2]			VARCHAR(50)
			--	, [Option3]	 VARCHAR(50)	
			--)

			--INSERT INTO @OIS_DATA
			--SELECT 
			--	[program_name]
			--	, processes
			--	, jobs
			--	, ft_device 
			--	, category_ois
			--	, ISNULL([tester1],'') AS [tester1]
			--	, ISNULL([Box1],'') AS [test_box1]
			--	, ISNULL([adaptor1],'') AS [adaptor1]
			--	, ISNULL([adaptor2],'') AS [adaptor2]
			--	, ISNULL([dut1],'') AS [dut1]
			--	, ISNULL([dut2],'') AS [dut2]
			--	, ISNULL([bridge_cable1],'') AS [bridge_cable1]
			--	, ISNULL([bridge_cable2],'') AS [bridge_cable2]
			--	, ISNULL([Option1],'') AS [Option1]
			--	, ISNULL([Option2],'') AS [Option2]
			--	, ISNULL([Option3],'') AS [Option3]
	
			--FROM (
			--	SELECT 
			--		[program_name]
			--		,processes
			--		,jobs
			--		,ft_device
			--		,category_ois
			--		,[equipment_types] + CAST([idx] AS VARCHAR) AS [equipment]
			--		,[equipment_names]
			--	FROM (
			--		SELECT [program_name]
			--		, processes.name as processes
			--		, jobs.name as jobs
			--		, ois_sets.name as ft_device
			--		, item_labels.label_eng AS category_ois
			--		, productions.name AS equipment_names
			--		, categories.name as equipment_types
			--		,ROW_NUMBER() OVER(PARTITION BY ois_recipes.id, categories.name ORDER BY ois_recipes.id) AS idx
			--		FROM APCSProDB.method.ois_sets
			--		INNER JOIN APCSProDB.method.ois_set_lists ON ois_sets.id = ois_set_lists.ois_set_id
			--		INNER JOIN APCSProDB.method.ois_recipes ON ois_set_lists.ois_recipe_id = ois_recipes.id
			--		INNER JOIN APCSProDB.method.processes ON ois_sets.process_id = processes.id
			--		INNER JOIN APCSProDB.method.jobs ON ois_recipes.job_id = jobs.id
			--		INNER JOIN APCSProDB.trans.item_labels ON item_labels.name = 'lots.production_category'
			--			AND ois_recipes.production_category = item_labels.val
			--		INNER JOIN APCSProDB.method.ois_recipe_details ON ois_recipes.id = ois_recipe_details.ois_recipe_id
			--		INNER JOIN APCSProDB.jig.productions ON ois_recipe_details.jig_production_id = productions.id
			--		INNER JOIN APCSProDB.jig.categories ON productions.category_id = categories.id
			--		WHERE ois_sets.id = @recipe_id 
			--		AND production_category = @category_lot
			--		AND ois_recipes.is_released = 1
			--		AND ois_recipes.job_id = @@commonjob_id
			--		) AS  [data]
			--	) AS [data2]
			--	PIVOT (
			--	MAX([equipment_names])
			--	FOR [equipment] IN ( 
			--	[tester1]
			--	,[Box1] 
			--	,[adaptor1]
			--	,[adaptor2]
			--	,[dut1]
			--	,[dut2]
			--	,[bridge_cable1]
			--	,[bridge_cable2]
			--	,[Option1]
			--	,[Option2]
			--	,[Option3] )
			--) AS [pvt]	

			---- Find Program for Case Multi same Equipment with SetupCheckSheet
			--SELECT 
			--	@program_name = OIS.[program_name]
			--	, @process = OIS.processes
			--	, @job = OIS.jobs
			--	, @device_name = OIS.ft_device
			--	, @category_ois = OIS.category_ois
			--	, @tester1 = OIS.tester1
			--	, @test_box1 = OIS.test_box1
			--	, @adaptor1 = OIS.adaptor1
			--	, @adaptor2 = OIS.adaptor2
			--	, @dut1 = OIS.dut1
			--	, @dut2 = OIS.dut2
			--	, @bridge_cable1 = OIS.bridge_cable1
			--	, @bridge_cable2 = OIS.bridge_cable2
			--	, @Option1 = OIS.Option1
			--	, @Option2 = OIS.Option2
			--	, @Option3 = OIS.Option3
			--FROM 
			--	DBx.dbo.FTSetupReport FT
			--JOIN 
			--	@OIS_DATA AS OIS
			--ON 
			--	FT.TesterType = OIS.tester1
			--	AND FT.TestBoxA = OIS.test_box1
			--	AND (
			--		(FT.AdaptorA = OIS.adaptor1 AND FT.AdaptorB = OIS.adaptor2) OR 
			--		(FT.AdaptorA = OIS.adaptor2 AND FT.AdaptorB = OIS.adaptor1)
			--	)
			--	AND (
			--		(FT.DutcardA = OIS.dut1 AND FT.DutcardB = OIS.dut2) OR 
			--		(FT.DutcardA = OIS.dut2 AND FT.DutcardB = OIS.dut1)
			--	)
			--	AND (
			--		(FT.BridgecableA = OIS.bridge_cable1 AND FT.BridgecableB = OIS.bridge_cable2) OR 
			--		(FT.BridgecableA = OIS.bridge_cable2 AND FT.BridgecableB = OIS.bridge_cable1)
			--	)
			--	AND (
			--		(FT.OptionName1 = OIS.Option1 AND FT.OptionName2 = OIS.Option2 AND FT.OptionName3 = OIS.Option3) OR
			--		(FT.OptionName1 = OIS.Option1 AND FT.OptionName2 = OIS.Option3 AND FT.OptionName3 = OIS.Option2) OR
			--		(FT.OptionName1 = OIS.Option2 AND FT.OptionName2 = OIS.Option1 AND FT.OptionName3 = OIS.Option3) OR
			--		(FT.OptionName1 = OIS.Option2 AND FT.OptionName2 = OIS.Option3 AND FT.OptionName3 = OIS.Option1) OR
			--		(FT.OptionName1 = OIS.Option3 AND FT.OptionName2 = OIS.Option1 AND FT.OptionName3 = OIS.Option2) OR
			--		(FT.OptionName1 = OIS.Option3 AND FT.OptionName2 = OIS.Option2 AND FT.OptionName3 = OIS.Option1)
			--	)
			--WHERE 
			--	FT.MCNo = @mc_no AND LotNo = @lot_no

			--IF @program_name IS NULL
			--BEGIN
			--	ROLLBACK;
			--	SELECT 'FALSE' AS Is_Pass 
			--		, 'GET Program Failed !!' AS Error_Message_ENG
			--		, N'ไม่พบ Program ที่ตรงกับเงื่อนไข' AS Error_Message_THA
			--		, '' AS [program_name]
			--		, '' AS [process]
			--		, '' AS [job]
			--		, '' AS [device_name]
			--		, '' AS [category_ois]
			--		, '' AS [tester1]
			--		, '' AS [test_box1]
			--		, '' AS [adaptor1]
			--		, '' AS [adaptor2]
			--		, '' AS [dut1]
			--		, '' AS [dut2]
			--		, '' AS [bridge_cable1]
			--		, '' AS [bridge_cable2]
			--		, '' AS [Option1]
			--		, '' AS [Option2]
			--		, '' AS [Option3]
			--	RETURN;
			--END

			--SELECT 'TRUE' AS Is_Pass 
			--	, 'Get Program Success!!' AS Error_Message_ENG
			--	, N'Get Program Success!!' AS Error_Message_THA
			--	, @program_name AS [program_name]
			--	, @process AS [process]
			--	, @job AS [job]
			--	, @device_name AS [device_name]
			--	, @category_ois AS [category_ois]
			--	, @tester1 AS [tester1]
			--	, @test_box1 AS [test_box1]
			--	, @adaptor1 AS [adaptor1]
			--	, @adaptor2 AS [adaptor2]
			--	, @dut1 AS [dut1]
			--	, @dut2 AS [dut2]
			--	, @bridge_cable1 AS [bridge_cable1]
			--	, @bridge_cable2 AS [bridge_cable2]
			--	, @Option1 AS [Option1]
			--	, @Option2 AS [Option2]
			--	, @Option3 AS [Option3]
			--COMMIT;

		END
		ELSE
		BEGIN
			PRINT 'Case Lot Mass or Sample/Eva or TE Eva'
		
			SELECT 
				@program_name = [program_name]
				, @process = processes
				, @job = jobs
				, @device_name = ft_device 
				, @category_ois = category_ois
				, @tester1	= ISNULL([tester1],'')
				, @test_box1 = ISNULL([Box1],'')
				, @adaptor1 = ISNULL([adaptor1],'')
				, @adaptor2 = ISNULL([adaptor2],'')
				, @dut1 = ISNULL([dut1],'')
				, @dut2 = ISNULL([dut2],'')
				, @bridge_cable1 = ISNULL([bridge_cable1],'')
				, @bridge_cable2 = ISNULL([bridge_cable2],'')
				, @Option1 = ISNULL([Option1],'')
				, @Option2 = ISNULL([Option2],'')
				, @Option3 = ISNULL([Option3],'')
			FROM (
				SELECT 
					[program_name]
					,processes
					,jobs
					,ft_device
					,category_ois
					,[equipment_types] + CAST([idx] AS VARCHAR) AS [equipment]
					,[equipment_names]
				FROM (
					SELECT [program_name]
					, processes.name as processes
					, jobs.name as jobs
					, ois_sets.name as ft_device
					, item_labels.label_eng AS category_ois
					, productions.name AS equipment_names
					, categories.name as equipment_types
					,ROW_NUMBER() OVER(PARTITION BY ois_recipes.id, categories.name ORDER BY ois_recipes.id) AS idx
					FROM APCSProDB.method.ois_sets
					INNER JOIN APCSProDB.method.ois_set_lists ON ois_sets.id = ois_set_lists.ois_set_id
					INNER JOIN APCSProDB.method.ois_recipes ON ois_set_lists.ois_recipe_id = ois_recipes.id
					INNER JOIN APCSProDB.method.processes ON ois_sets.process_id = processes.id
					INNER JOIN APCSProDB.method.jobs ON ois_recipes.job_id = jobs.id
					INNER JOIN APCSProDB.trans.item_labels ON item_labels.name = 'lots.production_category'
						AND ois_recipes.production_category = item_labels.val
					INNER JOIN APCSProDB.method.ois_recipe_details ON ois_recipes.id = ois_recipe_details.ois_recipe_id
					INNER JOIN APCSProDB.jig.productions ON ois_recipe_details.jig_production_id = productions.id
					INNER JOIN APCSProDB.jig.categories ON productions.category_id = categories.id
					WHERE ois_sets.id = @recipe_id 
					AND production_category = @category_lot
					AND ois_recipes.is_released = 1
					AND ois_recipes.job_id = @commonjob_id
					) AS  [data]
				) AS [data2]
				PIVOT (
				MAX([equipment_names])
				FOR [equipment] IN ( 
				[tester1]
				,[Box1] 
				,[adaptor1]
				,[adaptor2]
				,[dut1]
				,[dut2]
				,[bridge_cable1]
				,[bridge_cable2]
				,[Option1]
				,[Option2]
				,[Option3] )
			) AS [pvt]	
	
			SELECT 'TRUE' AS Is_Pass 
				, 'Get Program Success!!' AS Error_Message_ENG
				, N'Get Program Success!!' AS Error_Message_THA
				, @program_name AS [program_name]
				, @process AS [process]
				, @job AS [job]
				, @device_name AS [device_name]
				, @category_ois AS [category_ois]
				, @tester1 AS [tester1]
				, @test_box1 AS [test_box1]
				, @adaptor1 AS [adaptor1]
				, @adaptor2 AS [adaptor2]
				, @dut1 AS [dut1]
				, @dut2 AS [dut2]
				, @bridge_cable1 AS [bridge_cable1]
				, @bridge_cable2 AS [bridge_cable2]
				, @Option1 AS [Option1]
				, @Option2 AS [Option2]
				, @Option3 AS [Option3]
			COMMIT;
		END
	END TRY

	BEGIN CATCH	
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass 
			, ERROR_MESSAGE() AS Error_Message_ENG
			, N'เกิดข้อผิดพลาด !!' AS Error_Message_THA
			, '' AS [program_name]
			, '' AS [process]
			, '' AS [job]
			, '' AS [device_name]
			, '' AS [category_ois]
			, '' AS [tester1]
			, '' AS [test_box1]
			, '' AS [adaptor1]
			, '' AS [adaptor2]
			, '' AS [dut1]
			, '' AS [dut2]
			, '' AS [bridge_cable1]
			, '' AS [bridge_cable2]
			, '' AS [Option1]
			, '' AS [Option2]
			, '' AS [Option3]
		RETURN;
	END CATCH

END
