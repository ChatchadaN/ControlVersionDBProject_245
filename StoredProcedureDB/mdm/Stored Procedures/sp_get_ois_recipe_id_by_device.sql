-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_recipe_id_by_device]
	-- Add the parameters for the stored procedure here
	@job_id int
	,@deviceName int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
	/****** Script for SelectTopNRows command from SSMS  ******/
		SELECT MAX(ois_recipes.id) AS ois_recipe_id 
		FROM APCSProDB.method.ois_recipes
		INNER JOIN APCSProDB.method.ois_recipe_versions on ois_recipe_versions.id = ois_recipes.device_version_id
		WHERE ois_recipes.job_id = @job_id and ois_recipe_versions.device_id = @deviceName
	END
END
