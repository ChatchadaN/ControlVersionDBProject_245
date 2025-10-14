-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_set_list_by_id]
	-- Add the parameters for the stored procedure here
	@id INT 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
	/****** Script for SelectTopNRows command from SSMS  ******/
	SELECT [id]
		, [ois_set_id]
		, [set_name]
		, [ois_recipe_id]
		, [program_name]
		, [package]
		, [device_names]
		, [rank]
		, [processes]
		, [job]
		, [test_time]
		, [dateChanged]
		, [information]
		, [revision_reason]
		, ISNULL([tp_type],'-') AS [tp_type]
		, ISNULL([tube_type],'-') AS [tube_type]
		, [pattern]
		, [handler]
		, version_num
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
		SELECT [id]
		  , [ois_set_id]
		  , [name] AS [set_name]
		  , [ois_recipe_id]
		  , [program_name]
		  , [package]
		  , [device_names]
		  , [rank]
		  , [processes]
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
		  , version_num
		  , [equipment_types] + CAST([idx] AS VARCHAR) AS [equipment]
		  , [equipment_names]
		FROM (
			 SELECT ois_set_lists.[id]
				, ois_set_lists.ois_set_id
				, ois_sets.name
				, ois_set_lists.ois_recipe_id
				, ois_recipes.program_name
				, packages.name as package
				, ois_recipes.device_version_id
				, ois_recipes.version_num
				, device_names.ft_name as device_names
				, device_names.rank
				, ois_recipes.[job_id]
				, jobs.name as job
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
			FROM APCSProDB.method.ois_set_lists
			INNER JOIN APCSProDB.method.ois_sets ON ois_set_lists.ois_set_id = ois_sets.id
			INNER JOIN APCSProDB.method.ois_recipes ON ois_set_lists.ois_recipe_id = ois_recipes.id
			INNER JOIN APCSProDB.method.ois_recipe_versions on ois_recipes.device_version_id = ois_recipe_versions.id
			INNER JOIN APCSProDB.method.device_names on ois_recipe_versions.device_id = device_names.id
			INNER JOIN APCSProDB.method.packages ON device_names.package_id = packages.id
			INNER JOIN APCSProDB.method.jobs ON ois_recipes.job_id = jobs.id
			INNER JOIN APCSProDB.method.processes on jobs.process_id = processes.id
			LEFT JOIN APCSProDB.method.ois_recipe_details ON ois_recipe_details.ois_recipe_id = ois_recipes.id
			LEFT JOIN APCSProDB.jig.productions ON ois_recipe_details.jig_production_id = productions.id
			LEFT JOIN APCSProDB.jig.categories ON productions.category_id = categories.id
			LEFT JOIN APCSProDB.mc.models on ois_recipes.mc_model_id = models.id
			WHERE ois_set_lists.id = @id
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

	END
END
