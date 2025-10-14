-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_recipe]
	-- Add the parameters for the stored procedure here
	@id int = 0	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @id = CASE WHEN @id = 0 THEN NULL ELSE @id END

    -- Insert statements for procedure here
	BEGIN
	/****** Script for SelectTopNRows command from SSMS  ******/
	SELECT [ois_recipes].[id]
		,[program_name]
		,packages.name as package
		,device_version_id
		,[ois_recipes].version_num
		,ois_recipe_versions.device_id AS device_names_id
		,device_names.ft_name as device_names
		,[ois_recipes].[job_id]
		,jobs.name as job
		,processes.name as processes
		,production_category
		,item_labels.[label_eng] as category
		,[test_time]
		,[is_released]
		,[ois_recipes].[created_at]
		,[ois_recipes].[created_by]
		,[ois_recipes].[updated_at]
		,[ois_recipes].[updated_by]
		,(CASE WHEN ois_recipes.[comment] = '' THEN '-' ELSE ois_recipes.[comment] END) AS [comment]
		,(CASE WHEN ois_recipes.[revision_reason] = '' THEN '-' ELSE ois_recipes.[revision_reason] END) AS [revision_reason]
		,(CASE WHEN ois_recipes.[tp_type] = '' THEN '-' ELSE ois_recipes.[tp_type] END) AS [tp_type]
		,(CASE WHEN ois_recipes.[tube_type] = '' THEN '-' ELSE ois_recipes.[tube_type] END) AS [tube_type]
		,(CASE WHEN ois_recipes.[pattern] = '' THEN '-' ELSE ois_recipes.[pattern] END) AS [pattern]
		,[mc_model_id]
		,models.short_name AS handler
		,is_highvoltage
	FROM APCSProDB.[method].[ois_recipes]
		INNER JOIN APCSProDB.method.ois_recipe_versions on ois_recipes.device_version_id = ois_recipe_versions.id
		INNER JOIN APCSProDB.method.device_names on ois_recipe_versions.device_id = device_names.id
		INNER JOIN APCSProDB.method.packages on device_names.package_id = packages.id
		LEFT JOIN APCSProDB.method.jobs on [ois_recipes].job_id = jobs.id
		LEFT JOIN APCSProDB.method.processes on jobs.process_id = processes.id
		LEFT JOIN APCSProDB.mc.models on [ois_recipes].mc_model_id = models.id
		INNER JOIN APCSProDB.trans.item_labels on [ois_recipes].production_category = item_labels.val
		AND item_labels.name = 'lots.production_category'
	WHERE [ois_recipes].[id] =  @id  OR  @id  IS NULL
	ORDER BY [device_names],[version_num],[program_name]
	END


	-----------------------THIS IS COMMENT FOR CONTROL VERSION STORED TEST -----------------------------


END
