-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_recipe_name]
	-- Add the parameters for the stored procedure here
	@id int = 0	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
	SET @id = CASE WHEN @id = 0 THEN NULL ELSE @id END
		SELECT [recipe_names].[id]
		,[recipe_names].[name] AS recipe_name
		,[recipe_names].[machine_model_id]
		,[models].[name] AS machine_model
		,[eva_machine_id]
		,[machines].name AS machine_name 
		,[recipe_names].[created_at] 
		,user1.emp_num AS[created_by]
		,[recipe_names].[updated_at]
		,user2.emp_num AS[updated_by]
		FROM[APCSProDB].[method].[recipe_names]
		INNER JOIN[APCSProDB].[mc].[machines] on[recipe_names].eva_machine_id = [machines].id 
		INNER JOIN [APCSProDB].[mc].[models] ON [recipe_names].[machine_model_id] = [models].[id] 
		LEFT JOIN[APCSProDB].man.users AS user1 ON[recipe_names].created_by = user1.id 
		LEFT JOIN[APCSProDB].man.users AS user2 ON[recipe_names].updated_by = user2.id 
		WHERE [recipe_names].[id] =  @id  OR  @id  IS NULL
	END
END
