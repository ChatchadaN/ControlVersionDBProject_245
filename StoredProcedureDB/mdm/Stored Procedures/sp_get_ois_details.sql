-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_details]
	-- Add the parameters for the stored procedure here
	@device_id			VARCHAR(MAX)	= NULL
	, @package_id		VARCHAR(MAX)	= NULL
	, @program_name		VARCHAR(MAX)	= NULL
	, @pd_cat_id		VARCHAR(MAX)	= NULL
	, @process_id		VARCHAR(MAX)	= NULL
	, @testflow			VARCHAR(MAX)	= NULL

	, @tester			VARCHAR(MAX)	= NULL
	, @test_box			VARCHAR(MAX)	= NULL
	, @test_board		VARCHAR(MAX)	= NULL
	, @adaptor			VARCHAR(MAX)	= NULL
	, @dut				VARCHAR(MAX)	= NULL
	, @bridge_cable		VARCHAR(MAX)	= NULL
	, @option			VARCHAR(MAX)	= NULL
	, @socket			VARCHAR(MAX)	= NULL
	, @version_num		VARCHAR(MAX)	= NULL

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
	/****** Script for SelectTopNRows command from SSMS  ******/

	DECLARE @OIS_DATA_tb TABLE (
		[ois_recipe_id] INT
		, [device_id] INT
		, [device_names] VARCHAR(MAX)		
		, [package_id] INT
		, [package] VARCHAR(MAX)
		, [program_name] VARCHAR(MAX)		
		, [pd_cat_id] INT
		, [production_category]  VARCHAR(MAX)
		, [rank] VARCHAR(MAX)		
		, [process_id] INT
		, [processes] VARCHAR(MAX)
		, [job_id] INT
		, [job] VARCHAR(MAX)
		, [test_time] DECIMAL
		, [dateChanged] DATETIME 
		, [information] NVARCHAR(MAX)
		, [revision_reason] VARCHAR(MAX)
		, [tp_type] VARCHAR(MAX)
		, [tube_type] VARCHAR(MAX)
		, [pattern] VARCHAR(MAX)
		, [handler] VARCHAR(MAX)
		, [version_num] INT
		, [is_highvoltage] INT
		, [socket1] VARCHAR(MAX)
		, [tester1] VARCHAR(MAX)
		, [adaptor1] VARCHAR(MAX)
		, [adaptor2] VARCHAR(MAX)
		, [bridge_cable1] VARCHAR(MAX)
		, [bridge_cable2] VARCHAR(MAX)
		, [dut1] VARCHAR(MAX)
		, [dut2] VARCHAR(MAX)
		, [dut3] VARCHAR(MAX)
		, [test_board1] VARCHAR(MAX)
		, [test_box1] VARCHAR(MAX)
		, [Option1] VARCHAR(MAX)
		, [Option2] VARCHAR(MAX)
		, [Option3] VARCHAR(MAX)
	)
	
	INSERT INTO @OIS_DATA_tb
	SELECT [ois_recipe_id]
		, [device_id]
		, [device_names]
		, [package_id]
		, [package]
		, [program_name]
		, [pd_cat_id]
		, [production_category]
		, [rank]
		, [process_id]
		, [processes]
		, [job_id]
		, [job]
		, [test_time]
		, [dateChanged]
		, [information]
		, [revision_reason]
		, ISNULL([tp_type],'-') AS [tp_type]
		, ISNULL([tube_type],'-') AS [tube_type]
		, [pattern]
		, [handler]
		, [version_num]
		, [is_highvoltage]
		, ISNULL([socket1],'-') AS [socket1]
		, ISNULL([tester1],'-') AS [tester1]
		, ISNULL([adaptor1],'-') AS [adaptor1]
		, ISNULL([adaptor2],'-') AS [adaptor2]
		, ISNULL([bridge_cable1],'-') AS [bridge_cable1]
		, ISNULL([bridge_cable2],'-') AS [bridge_cable2]
		, ISNULL([dut1],'-') AS [dut1]
		, ISNULL([dut2],'-') AS [dut2]
		, ISNULL([dut3],'-') AS [dut3]
		, ISNULL([Board1],'-') AS [test_board1]
		, ISNULL([Box1],'-') AS [test_box1]
		, ISNULL([Option1],'-') AS [Option1]
		, ISNULL([Option2],'-') AS [Option2]
		, ISNULL([Option3],'-') AS [Option3]
	FROM (
		SELECT 
			  [ois_recipe_id]
			, [device_id]
			, [device_names]
			, [package_id]
			, [package]
			, [program_name]
			, [pd_cat_id]
			, [production_category]
			, [rank]
			, [process_id]
			, [processes]
			, [job_id]
			, [job]
			, [test_time]
			, GETDATE() AS [dateChanged]
			, [comment] AS [information]
			, [revision_reason]
			, [tp_type]
			, [tube_type]
			, [pattern]
			, [handler]
			, [is_highvoltage]
			, [version_num]
			, [equipment_types] + CAST([idx] AS VARCHAR) AS [equipment]
			, [equipment_names]
		
		FROM (
			SELECT ois_recipes.id as [ois_recipe_id]
			, device_names.id as device_id
			, device_names.ft_name as device_names
			, packages.id as package_id
			, packages.name as package
			, ois_recipes.program_name
			, ois_recipes.production_category as pd_cat_id
			, item_labels.label_eng as production_category
			, ois_recipes.device_version_id
			, ois_recipes.version_num
			, device_names.rank
			, ois_recipes.[job_id]
			, jobs.name as job
			, processes.id as process_id
			, processes.name as processes
			, ois_recipes.[test_time]
			, ois_recipes.[mc_model_id]
			, models.short_name as handler
			, ois_recipes.[comment]
			, (CASE WHEN ois_recipes.[revision_reason] = '' THEN '-' ELSE ois_recipes.[revision_reason] END) AS [revision_reason]
			, (CASE WHEN ois_recipes.[tp_type] = '' THEN '-' ELSE ois_recipes.[tp_type] END) AS [tp_type]
			, (CASE WHEN ois_recipes.[tube_type] = '' THEN '-' ELSE ois_recipes.[tube_type] END) AS [tube_type]
			, (CASE WHEN ois_recipes.[pattern] = '' THEN '-' ELSE ois_recipes.[pattern] END) AS [pattern]
			, ois_recipes.[is_highvoltage]
			, productions.name as equipment_names
			, categories.short_name as equipment_types
			, ROW_NUMBER() OVER(PARTITION BY ois_recipes.id, categories.short_name ORDER BY ois_recipes.id) AS idx
			FROM APCSProDB.method.ois_recipes
			INNER JOIN APCSProDB.method.ois_recipe_versions on ois_recipes.device_version_id = ois_recipe_versions.id
			INNER JOIN APCSProDB.method.device_names on ois_recipe_versions.device_id = device_names.id
			INNER JOIN APCSProDB.method.packages ON device_names.package_id = packages.id
			INNER JOIN APCSProDB.method.jobs ON ois_recipes.job_id = jobs.id
			INNER JOIN APCSProDB.method.processes on jobs.process_id = processes.id
			LEFT JOIN APCSProDB.mc.models on ois_recipes.mc_model_id = models.id
		
			LEFT JOIN APCSProDB.method.ois_recipe_details ON ois_recipe_details.ois_recipe_id = ois_recipes.id
			LEFT JOIN APCSProDB.jig.productions ON ois_recipe_details.jig_production_id = productions.id
			LEFT JOIN APCSProDB.jig.categories ON productions.category_id = categories.id	
			
			INNER JOIN  APCSProDB.trans.item_labels on [ois_recipes].production_category = item_labels.val
			AND item_labels.name = 'lots.production_category'
		) AS [data]
	) AS [data2]
	PIVOT (
		MAX([equipment_names])
		FOR [equipment] IN ( [socket1]
		,[tester1]
		,[adaptor1]
		,[adaptor2]
		,[bridge_cable1]
		,[bridge_cable2]
		,[dut1]
		,[dut2]
		,[dut3]
		,[Board1]
		,[Box1] 
		,[Option1]
		,[Option2]
		,[Option3]
		)
	) AS [pvt]

	----------------------------------------------------------------------------------------------------------
	-- GET DATA OIS
	SELECT
		[ois_recipe_id]
		, device_id 
		, [device_names]	
		, package_id
		, [package] 
		, [program_name] 
		, [pd_cat_id] 
		, [production_category] 
		, [rank] 
		, process_id
		, [processes]
		, job_id
		, [job] 
		, [test_time] 
		, [dateChanged] 
		, [information]
		, [revision_reason]
		, [tp_type]
		, [tube_type]
		, [pattern]
		, [handler]
		, [version_num]
		, [is_highvoltage]
		, [socket1] 
		, [tester1]
		, [adaptor1]
		, [adaptor2]
		, [bridge_cable1]
		, [bridge_cable2]
		, [dut1]
		, [dut2]
		, [dut3]
		, [test_board1]
		, [test_box1]
		, [Option1]
		, [Option2]
		, [Option3]
	FROM @OIS_DATA_tb

	WHERE ([device_id] = @device_id OR ISNULL(@device_id,'')= '')
	AND (package_id = @package_id OR ISNULL(@package_id,'')= '')
	AND ([program_name] = @program_name OR ISNULL(@program_name,'')= '')
	AND (pd_cat_id = @pd_cat_id	 OR ISNULL(@pd_cat_id,'')= '')
	AND (process_id = @process_id	 OR ISNULL(@process_id,'')= '')
	AND ([job_id] = @testflow	 OR ISNULL(@testflow,'')= '')

	AND (tester1 LIKE '%' + @tester + '%' OR ISNULL(@tester, '') = '')
	AND ([test_box1] LIKE '%' + @test_box + '%' OR ISNULL(@test_box, '') = '')
	AND (test_board1 LIKE '%' + @test_board + '%'  OR ISNULL(@test_board,'')= '')
	
	AND (adaptor1 LIKE '%' +  @adaptor + '%' OR ISNULL(@adaptor,'')= ''
		OR adaptor2 LIKE '%' +  @adaptor + '%' OR ISNULL(@adaptor,'')= '')
	
	AND (dut1 LIKE '%' + @dut + '%' OR ISNULL(@dut,'')= ''
		OR dut2 LIKE '%' + @dut + '%' OR ISNULL(@dut,'')= ''
		OR dut3 LIKE '%' + @dut + '%' OR ISNULL(@dut,'')= '' )
	
	AND (bridge_cable1 LIKE '%' + @bridge_cable OR ISNULL(@bridge_cable,'')= ''
		OR bridge_cable2 LIKE '%' + @bridge_cable OR ISNULL(@bridge_cable,'')= '')
	
	AND (Option1 LIKE '%' + @option + '%'	 OR ISNULL(@option,'')= ''
		OR Option2 LIKE '%' + @option + '%'	 OR ISNULL(@option,'')= ''
		OR Option3 LIKE '%' + @option + '%'	 OR ISNULL(@option,'')= '')
	
	AND (socket1 LIKE '%' + @socket	+ '%' OR ISNULL(@socket,'')= '')
	AND (version_num = @version_num		 OR ISNULL(@version_num	,'')= '')

	END
END