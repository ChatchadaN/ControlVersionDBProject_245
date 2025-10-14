-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_item_recipe]
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
	SELECT [recipe_items].[id]
		, [recipe_items].[item_no]
		, [recipe_items].[item_name]
		, recipe_items.item_type
		, item_labels.label_eng AS item_type_name
		, [recipe_items].[machine_model_id]
		, [models].[name] AS [machine_model]
		, [recipe_items].[created_at]
		, user1.emp_num AS [created_by]
		, [recipe_items].[updated_at]
		, user2.emp_num AS [updated_by] 
		FROM [APCSProDB].[method].[recipe_items] 
		INNER JOIN [APCSProDB].[mc].[models] ON [recipe_items].[machine_model_id] = [models].[id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] ON [recipe_items].[item_type] = [item_labels].[val]
			and [item_labels].name = 'recipe_items.item_type'
		LEFT JOIN [APCSProDB].man.users AS user1 ON[recipe_items].created_by = user1.id
		LEFT JOIN [APCSProDB].man.users AS user2 ON[recipe_items].updated_by = user2.id 
		WHERE [recipe_items].[id] =  @id  OR  @id  IS NULL
	END
END
