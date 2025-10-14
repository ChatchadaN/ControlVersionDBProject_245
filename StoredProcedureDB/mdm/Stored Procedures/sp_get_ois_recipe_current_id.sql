-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_recipe_current_id]
	-- Add the parameters for the stored procedure here
	@job_id INT
	, @device_version_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure her

	SELECT MAX(id) AS id 
	FROM APCSProDB.method.ois_recipes
	WHERE device_version_id = @device_version_id 
	AND job_id = @job_id

END
