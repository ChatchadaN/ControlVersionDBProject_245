-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[andon_view_item_001]
	@andon_id INT
AS
BEGIN
	
	
		SELECT	 	  contrl.id
					, contrl.andon_control_no
					, contrl.comment_id_at_finding
					, [abnormal_detail].[name]		AS comment_name_at_finding
					, contrl.machine_id
					, machines.[name]				AS machine_name
					, items.item
					, [sub_categories].[name]		AS sub_category_name
					, items.sub_category_id
					, locations.[name]				AS location_name
					, items.location_id
					, contrl.comments
					, users.emp_code				AS  created_by
					, items.created_at
					, updated_by.emp_code			AS updated_by
					, contrl.updated_at
		FROM   [APCSProDB].trans.andon_controls AS contrl 
		INNER JOIN [APCSProDB].trans.andon_items AS items 
		ON contrl.id = items.andon_control_id
		LEFT JOIN [APCSProDB].[trans].[abnormal_detail]
		ON contrl.comment_id_at_finding = [abnormal_detail].id
		LEFT JOIN [APCSProDB].mc.machines
		ON machines.id   = contrl.machine_id
		LEFT JOIN [10.29.1.230].[AppDB].[dbo].[sub_categories]
		ON [sub_categories].id = items.sub_category_id
		LEFT JOIN [APCSProDB].trans.locations 
		ON items.location_id = locations.id
		LEFT JOIN  [10.29.1.230].[DWH].[man].[employees] users
		ON users.id  = items.created_by
		LEFT JOIN [10.29.1.230].[DWH].[man].[employees] updated_by
		ON updated_by.id  = items.updated_by
		WHERE contrl.id = @andon_id
END
