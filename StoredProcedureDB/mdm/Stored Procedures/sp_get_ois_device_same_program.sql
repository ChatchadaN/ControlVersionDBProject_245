-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_device_same_program]
	-- Add the parameters for the stored procedure here
	@jobs INT,
	@program_name VARCHAR(MAX)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
	/****** Script for SelectTopNRows command from SSMS  ******/
	SELECT ois_recipes.id  
		,ois_recipe_versions.device_id 
		,device_names.ft_name 
		,ois_recipes.program_name
		,ois_recipes.job_id
	FROM APCSProDB.method.ois_recipes
	INNER JOIN APCSProDB.method.ois_recipe_versions ON ois_recipes.device_version_id = ois_recipe_versions.id
	INNER JOIN APCSProDB.method.device_names ON ois_recipe_versions.device_id = device_names.id
	WHERE program_name = @program_name and ois_recipes.job_id = @jobs
	END
END
