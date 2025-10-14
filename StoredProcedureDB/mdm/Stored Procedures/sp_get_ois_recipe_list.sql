-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_recipe_list]
	-- Add the parameters for the stored procedure here
	@ois_recipe_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
	/****** Script for SelectTopNRows command from SSMS  ******/
	SELECT [ois_recipe_details].[id]
	      ,[ois_recipe_id]
		  ,ois_recipes.program_name
	      ,[jig_production_id]
		  ,productions.name AS productions
		  ,productions.category_id 
		  ,categories.short_name AS categories
		  ,[ois_recipe_details].unit
		  ,item_labels.label_eng AS unit_type
	FROM APCSProDB.[method].[ois_recipe_details]
	INNER JOIN APCSProDB.method.ois_recipes ON [ois_recipe_details].ois_recipe_id = ois_recipes.id
	INNER JOIN APCSProDB.jig.productions ON [ois_recipe_details].jig_production_id = productions.id
	INNER JOIN APCSProDB.jig.categories ON productions.category_id = categories.id
	INNER JOIN APCSProDB.method.item_labels ON item_labels.name = 'jig_set_list.use_qty_unit' 
	and item_labels.val = [ois_recipe_details].unit_type
	WHERE [ois_recipe_id] = @ois_recipe_id
	END
END
