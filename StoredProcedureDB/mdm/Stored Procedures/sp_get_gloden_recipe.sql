-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_gloden_recipe]
	-- Add the parameters for the stored procedure here
	@recipe_name_id int = 0
	, @recipe_name varchar(20) = ''
	, @state int = 0   --- 0:from web  1:from cellcon
	, @machine_model_id int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF (@state = 0) --- from web
	BEGIN
		SELECT [recipe_name_items].id
			, [recipe_name_items].recipe_name_id
			, [recipe_names].[name] AS [recipe_name]
			, [recipe_name_items].recipe_item_id
			, [recipe_items].[item_no]
			, [recipe_items].[item_name]
			, [recipe_name_items].[min_value]
			, [recipe_name_items].[max_value]
			, [recipe_name_items].[target_value]
			, [recipe_items].item_type
			, [recipe_name_items].[created_at]
			, user1.emp_num AS [created_by]
			, [recipe_name_items].[updated_at]
			, user2.emp_num AS [updated_by]
		FROM [APCSProDB].[method].[recipe_name_items]
		INNER JOIN [APCSProDB].[method].[recipe_names] ON [recipe_name_items].[recipe_name_id] = [recipe_names].[id]
		INNER JOIN [APCSProDB].[method].[recipe_items] ON [recipe_name_items].[recipe_item_id] = [recipe_items].[id]
		LEFT JOIN [APCSProDB].man.users AS user1 ON [recipe_name_items].created_by = user1.id 
		LEFT JOIN [APCSProDB].man.users AS user2 ON [recipe_name_items].updated_by = user2.id 
		WHERE [recipe_name_items].recipe_name_id =  @recipe_name_id  OR  @recipe_name_id  IS NULL 
	END
	ELSE IF (@state = 1) --- from cellcon
		BEGIN
		SELECT [recipe_name_items].id
			, [recipe_name_items].recipe_name_id
			, [recipe_names].[name] AS [recipe_name]
			, [recipe_name_items].recipe_item_id
			, [recipe_items].[item_no]
			, [recipe_items].[item_name]
			, [recipe_name_items].[min_value]
			, [recipe_name_items].[max_value]
			, [recipe_name_items].[target_value]
			, [recipe_items].item_type
			, [recipe_name_items].[created_at]
			, user1.emp_num AS [created_by]
			, [recipe_name_items].[updated_at]
			, user2.emp_num AS [updated_by]
		FROM [APCSProDB].[method].[recipe_name_items]
		INNER JOIN [APCSProDB].[method].[recipe_names] ON [recipe_name_items].[recipe_name_id] = [recipe_names].[id]
		INNER JOIN [APCSProDB].[method].[recipe_items] ON [recipe_name_items].[recipe_item_id] = [recipe_items].[id]
		LEFT JOIN [APCSProDB].man.users AS user1 ON [recipe_name_items].created_by = user1.id 
		LEFT JOIN [APCSProDB].man.users AS user2 ON [recipe_name_items].updated_by = user2.id 
		WHERE [recipe_names].[name] =  @recipe_name AND [recipe_names].[machine_model_id] = @machine_model_id
	END
END
