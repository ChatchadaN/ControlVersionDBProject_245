-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [mdm].[sp_get_material_set_list]
	  @mid int 
	 , @production_id int = NULL
	 , @filter int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		IF(@filter = 1)
		BEGIN
			
			SELECT CASE WHEN matlist.id IS NULL THEN 0 ELSE 1 END AS is_checked
			,matlist.id
			,matlist.idx
			,productions.id AS material_id
			,productions.name
			,productions.details
			,matlist.use_qty
			,il.label_eng AS use_qty_unit
			,il2.label_eng AS limit_time_unit1
			,time_limit1
			,time_warn1
			,CASE WHEN matlist.tomson_code IS NULL THEN '' ELSE  CONCAT(ib.reel_count,' reels') END AS tomson_pattern 
			FROM APCSProDB.material.productions 
			INNER JOIN APCSProDB.method.material_set_list AS matlist ON productions.id = matlist.material_group_id
			LEFT JOIN APCSProDB.method.item_labels il ON il.val = matlist.use_qty_unit AND il.name = 'material_set_list.use_qty_unit' 
			LEFT JOIN APCSProDB.method.item_labels il2 ON il2.val = matlist.limit_time_unit1 AND il2.name = 'material_set_list.limit_time_unit1' 
			LEFT JOIN APCSProDB.method.incoming_boxs ib ON ib.tomson_code = matlist.tomson_code AND ib.idx = 1 
			WHERE productions.category_id = 9 AND matlist.id = @mid

		END
		ELSE IF (@filter = 2)
		BEGIN
			
			SELECT 
				CASE WHEN matlist.id IS NULL THEN 0 ELSE 1 END AS is_checked,
				matlist.id,
				matlist.idx,
				productions.id AS material_id,
				productions.name,
				productions.details,
				matlist.use_qty,
				il.val as use_qty_unit_id,
				il.label_eng AS use_qty_unit,
				il2.val AS limit_time_unit1_id,
				il2.label_eng AS limit_time_unit1,
				time_limit1,
				time_warn1,
				pvt.id AS tomson_pattern_id, 
				CASE 
					WHEN matlist.tomson_code IS NULL THEN '' 
					ELSE CONCAT(ib.reel_count, ' reels') 
				END AS tomson_pattern
			FROM APCSProDB.material.productions 
			INNER JOIN APCSProDB.method.material_set_list AS matlist ON productions.id = matlist.material_group_id
			LEFT JOIN APCSProDB.method.item_labels il ON il.val = matlist.use_qty_unit AND il.name = 'material_set_list.use_qty_unit'
			LEFT JOIN APCSProDB.method.item_labels il2 ON il2.val = matlist.limit_time_unit1 AND il2.name = 'material_set_list.limit_time_unit1'
			LEFT JOIN APCSProDB.method.incoming_boxs ib ON ib.tomson_code = matlist.tomson_code AND ib.idx = 1
			LEFT JOIN (
				SELECT pvt.tomson_code AS id,CONCAT(pvt.[1],' (FULL), ',pvt.[2],' (1/2), ',pvt.[3],' (1/4)') AS patterns 
				FROM 
				(
					SELECT tomson_code, idx, reel_count 
					FROM[APCSProDB].method.incoming_boxs ib) AS tomson_box
					PIVOT( max(reel_count) FOR idx IN([1],[2],[3])
				) AS pvt
			) AS pvt ON pvt.id = matlist.tomson_code
			WHERE 
				productions.category_id = 9 
				AND matlist.id = @mid
				AND productions.id = @production_id;

		END

END
