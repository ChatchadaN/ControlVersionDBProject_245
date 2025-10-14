-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_ois_recipe_is_released]
	-- Add the parameters for the stored procedure here
	@id INT
	, @is_released INT
	, @updated_by INT
	, @job_id INT
	, @device_version_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure her

	BEGIN
	/****** Script for SelectTopNRows command from SSMS  ******/	
		-- อัปเดต ois_recipes ที่มี device_version_id, job_id, และ is_released เป็น 1
		WITH RecipeID AS (
			SELECT id
			FROM APCSProDB.method.ois_recipes
			WHERE device_version_id = @device_version_id
			AND job_id = @job_id
			AND is_released = 1
		)
		UPDATE APCSProDB.method.ois_recipes 
		SET 
			[is_released] = 0,
			[updated_at] = GETDATE(),
			[updated_by] = @updated_by
		WHERE id IN (SELECT id FROM RecipeID);

	-- อัปเดต ois_recipes ที่มี id เท่ากับ @id
		UPDATE APCSProDB.method.ois_recipes 
		SET 
			[is_released] = 1,
			[updated_at] = GETDATE(),
			[updated_by] = @updated_by
		WHERE id = @id;

	END
END
