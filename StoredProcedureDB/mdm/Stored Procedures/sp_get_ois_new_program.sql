-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_new_program]
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
	BEGIN
	/****** Script for SelectTopNRows command from SSMS  ******/
	SELECT 
	  ois_recipes.id,
	  program_name as new_program,
	  productions.name as new_tester 
	  FROM APCSProDB.method.ois_recipes
	  INNER JOIN APCSProDB.method.ois_recipe_versions on ois_recipes.device_version_id = ois_recipe_versions.id
	  INNER JOIN APCSProDB.method.ois_recipe_details on ois_recipes.id = ois_recipe_details.ois_recipe_id 
	  INNER JOIN APCSProDB.jig.productions ON ois_recipe_details.jig_production_id = productions.id
	  INNER JOIN APCSProDB.jig.categories ON productions.category_id = categories.id
	WHERE ois_recipes.id = @id and ois_recipes.device_version_id = @device_version_id AND ois_recipes.job_id = @job_id and short_name = 'Tester'
	END
END
