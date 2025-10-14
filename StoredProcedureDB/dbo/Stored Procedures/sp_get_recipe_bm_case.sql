-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_recipe_bm_case]
	-- Add the parameters for the stored procedure here
	@status AS INT  --0 : pending, 1 : success, 2 : all
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF @status = 0 BEGIN
		SELECT  'TRUE' AS Is_Pass 
			,'' AS Error_Message_ENG
			,N'' AS Error_Message_THA
			,N'' AS Handling
			,bm_case_id
			,rbc.id AS recipe_bm_case_id
			,rbcd.id AS recipe_bm_case_detail_id
			,rbc.status
			,rn.name AS recipe_name
			,ri.item_no AS recipe_item_no
			,rbcd.act_value_before
			,rbcd.act_value_after
			,rbcd.min_value
			,rbcd.max_value
			,rbcd.target_value
			,rbcd.is_confirm
			,rbcd.confirm_by
			,rbcd.remark
		FROM DBx.dbo.recipe_bm_case rbc 
				INNER JOIN DBx.dbo.recipe_bm_case_details rbcd ON rbc.id = rbcd.recipe_bm_case_id
				INNER JOIN APCSProDB.method.recipe_names rn ON rbcd.recipe_name_id = rn.id
				INNER JOIN APCSProDB.method.recipe_items ri ON rbcd.recipe_item_id = ri.id
		WHERE rbc.status = 0
	END 

	ELSE IF @status = 1 BEGIN
		SELECT  'TRUE' AS Is_Pass 
			,'' AS Error_Message_ENG
			,N'' AS Error_Message_THA
			,N'' AS Handling
			,bm_case_id
			,rbc.id AS recipe_bm_case_id
			,rbcd.id AS recipe_bm_case_detail_id
			,rbc.status
			,rn.name AS recipe_name
			,ri.item_no AS recipe_item_no
			,rbcd.act_value_before
			,rbcd.act_value_after
			,rbcd.min_value
			,rbcd.max_value
			,rbcd.target_value
			,rbcd.is_confirm
			,rbcd.confirm_by
			,rbcd.remark
		FROM DBx.dbo.recipe_bm_case rbc 
				INNER JOIN DBx.dbo.recipe_bm_case_details rbcd ON rbc.id = rbcd.recipe_bm_case_id
				INNER JOIN APCSProDB.method.recipe_names rn ON rbcd.recipe_name_id = rn.id
				INNER JOIN APCSProDB.method.recipe_items ri ON rbcd.recipe_item_id = ri.id
		WHERE rbc.status = 1
	END 

	ELSE IF @status = 2 BEGIN
		SELECT 'TRUE' AS Is_Pass 
			,'' AS Error_Message_ENG
			,N'' AS Error_Message_THA
			,N'' AS Handling
			,bm_case_id
			,rbc.id AS recipe_bm_case_id
			,rbcd.id AS recipe_bm_case_detail_id
			,rbc.status
			,rn.name AS recipe_name
			,ri.item_no AS recipe_item_no
			,rbcd.act_value_before
			,rbcd.act_value_after
			,rbcd.min_value
			,rbcd.max_value
			,rbcd.target_value
			,rbcd.is_confirm
			,rbcd.confirm_by
			,rbcd.remark
		FROM DBx.dbo.recipe_bm_case rbc 
				INNER JOIN DBx.dbo.recipe_bm_case_details rbcd ON rbc.id = rbcd.recipe_bm_case_id
				INNER JOIN APCSProDB.method.recipe_names rn ON rbcd.recipe_name_id = rn.id
				INNER JOIN APCSProDB.method.recipe_items ri ON rbcd.recipe_item_id = ri.id
	END 
END
