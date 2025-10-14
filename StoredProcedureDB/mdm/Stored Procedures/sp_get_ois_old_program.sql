-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_old_program]
	-- Add the parameters for the stored procedure here
	@id int,
	@device_version_id int,
	@job_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		;WITH RecipeID AS (
			SELECT 
			ois_recipes.id,
			[program_name],
			ois_recipe_versions.device_id,
			productions.name as productions 
			,categories.short_name
			FROM APCSProDB.method.ois_recipes
			INNER JOIN APCSProDB.method.ois_recipe_versions on ois_recipes.device_version_id = ois_recipe_versions.id
			INNER JOIN APCSProDB.method.ois_recipe_details on ois_recipes.id = ois_recipe_details.ois_recipe_id 
			INNER JOIN APCSProDB.jig.productions ON ois_recipe_details.jig_production_id = productions.id
			INNER JOIN APCSProDB.jig.categories ON productions.category_id = categories.id
			WHERE ois_recipes.device_version_id = @device_version_id AND ois_recipes.job_id = @job_id and short_name = 'Tester'--ส่ง device_version_id และ job_id  
		),
		PreviousID AS (
		  SELECT MAX(id) AS previous_id
		  FROM RecipeID
		  WHERE id < @id --ส่ง id program ที่ upload มา
		)

		SELECT PreviousID.previous_id, RecipeID.[program_name] AS old_program , RecipeID.productions as old_tester
		FROM PreviousID
		INNER JOIN RecipeID ON PreviousID.previous_id = RecipeID.id;
END
