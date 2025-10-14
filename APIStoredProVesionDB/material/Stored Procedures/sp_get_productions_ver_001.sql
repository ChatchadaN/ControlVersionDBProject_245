-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_productions_ver_001]
	@id INT = 0
	, @category_id INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 
			SELECT    CAST([productions].[id] AS INT )	AS [id]
					, [productions].code
					, TRIM(REPLACE([productions].[name],CHAR(160),''))	AS [name]
					, spec		AS specification
					, details		 
					, suppliers.name		AS suppliers
					, CAST(categories.id AS INT )			AS categories_id
					, TRIM(REPLACE(categories.name,CHAR(160),''))			AS categories
					, pack_std_qty 
					, unit_code.descriptions		AS pack_std_qty_unit
					, arrival_std_qty
					, min_order_qty
					, lead_time
					, lead_time.descriptions AS lead_time_unit
					, suppliers.supplier_cd
					, purchase_order_items.po_supplier_cd
					, purchase_order_items.po_supplier_name
					, purchase_order_items.item_cd				AS [po_item]
					, purchase_order_items.calculate_unit		AS [po_unit]
					, [productions].is_disabled
					, [productions].is_released 
					, [productions].expiration_value
					, time_unit.descriptions AS expiration_unit
					, [productions].expiration_base
					, material_codes.descriptions		AS expiration_base_name
			FROM [APCSProDB].[material].[productions]
			INNER JOIN APCSProDB.material.categories
			ON  categories.id  = [productions].category_id
			LEFT JOIN APCSProDB.material.suppliers
			ON  suppliers.supplier_cd  = productions.supplier_cd
			LEFT JOIN  [APCSProDB].material.purchase_order_items
			ON [productions].id  =  purchase_order_items.material_id
			LEFT JOIN [APCSProDB].[material].material_codes
			ON  [group] = 'exp_unit'  
			AND  [productions].expiration_base = material_codes.code
			LEFT JOIN [APCSProDB].[material].material_codes		AS time_unit
			ON  time_unit.[group] = 'time_unit'  
			AND  [productions].expiration_unit = time_unit.code
			LEFT JOIN [APCSProDB].[material].material_codes		AS unit_code
			ON  unit_code.[group] = 'package_unit'  
			AND  [productions].unit_code = unit_code.code
			LEFT JOIN [APCSProDB].[material].material_codes		AS lead_time
			ON  lead_time.[group] = 'time_unit'  
			AND  [productions].lead_time_unit = lead_time.code
			WHERE ([category_id] = @category_id OR ISNULL(@category_id, 0) = 0)
			AND ([productions].[id] =  @id OR ISNULL(@id, 0) = 0)
			ORDER BY  [productions].[name]


END
