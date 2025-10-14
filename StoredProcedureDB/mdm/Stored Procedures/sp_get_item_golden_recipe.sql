-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_item_golden_recipe]
	-- Add the parameters for the stored procedure here
	@machine_name VARCHAR(255) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT[recipe_items].[id]
		, [recipe_items].[item_no]
		, [recipe_items].[item_name]
		, [recipe_items].[machine_model_id]
		,[models].[name]						AS[machine_model]
		, machines.name							AS[machine_name] 
		FROM [APCSProDB].[method].[recipe_items] 
		INNER JOIN[APCSProDB].[mc].[models] ON [recipe_items].[machine_model_id] = [models].[id] 
		LEFT JOIN[APCSProDB].[mc].[machines] ON [machines].[machine_model_id] = [models].[id] 
		LEFT JOIN[APCSProDB].[man].[users] AS user1 ON [recipe_items].[created_by] = [user1].[id] 
		LEFT JOIN[APCSProDB].[man].[users] AS user2 ON [recipe_items].[updated_by] = [user2].[id]
		WHERE machines.name = @machine_name
	END
END
