------------------------------ Creater Rule ------------------------------
-- Project Name				: material 
-- Written Date             : 2025/07/10
-- Procedure Name 	 		: APCSProDB.trans.materials
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_get_materials_stock_list_001]
 (
		@location_id	INT			--= 9
	  , @from_date		DATETIME    --= '2025-07-08' 
	  , @to_date		DATETIME	--= '2025-07-09'
 )
AS
BEGIN
	SET NOCOUNT ON;


	SET @to_date =   DATEADD(DAY, 1,   DATEADD(millisecond, -1,CONVERT(VARCHAR,@to_date, 23)))

				SELECT    materials.id												AS material_id 
						, materials.barcode 
						, categories.id 													AS categories_id   
						, categories.name													AS categories_name  
						, productions.id													AS   production_id
						, productions.name													AS production_name
						, materials.lot_no 
						, material_arrival_records.invoice_no
						, materials.quantity 
						, materials.location_id
						, ISNULL(locations.name,'')											AS  [locations_name]
						, ISNULL(FORMAT(materials.created_at,'yyyy-MM-dd'),'')				AS received_date
						, materials.qc_state												AS qc_state_id
						, qc_state.label_eng												AS qc_state
						, materials.material_state											AS material_state_id 
						, ISNULL(matl_state.descriptions,'')								AS material_state 
						, materials.process_state											AS process_state_id  
						, ISNULL(process_state.descriptions,'')								AS process_state 
						, ISNULL(comments.val,'')											AS hold_type	
						, limit_state.label_eng												AS limit_state
						, FORMAT(materials.limit_date,'yyyy-MM-dd') 						AS limit_date
						, ISNULL(FORMAT(materials.extended_limit_date,'yyyy-MM-dd'),'')		AS extended_limit_date
						, ISNULL(parent_material.barcode,'')								AS repack
				FROM APCSProDB.trans.materials
				INNER JOIN APCSProDB.trans.material_arrival_records
				ON materials.arrival_material_id  =   material_arrival_records.id
				INNER JOIN APCSProDB.material.productions
				ON productions.id =  materials.material_production_id  
				INNER JOIN APCSProDB.material.categories
				ON categories.id =  productions.category_id  
				LEFT JOIN APCSProDB.material.material_codes   process_state
				ON materials.process_state		= process_state.code
				AND   process_state.[group]		=  'process_state'
				LEFT JOIN APCSProDB.material.material_codes  matl_state
				ON materials.material_state = matl_state.code
				AND   matl_state.[group]		=  'matl_state'
				LEFT JOIN APCSProDB.material.locations
				ON locations.id  = materials.location_id
				LEFT JOIN  APCSProDB.trans.item_labels		AS qc_state
				ON  materials.qc_state = qc_state.val
				AND  qc_state.[name] = 'lots.quality_state'
				LEFT JOIN APCSProDB.trans.comments
				ON  comments.id = materials.qc_comment_id 
				LEFT JOIN  APCSProDB.trans.item_labels		AS limit_state
				ON  materials.limit_state = limit_state.val
				AND  limit_state.[name] = 'lots.quality_state' 
				LEFT JOIN APCSProDB.trans.materials		parent_material
				ON  parent_material.id  = materials.parent_material_id
				WHERE  materials.location_id  = @location_id
				AND (CONVERT(VARCHAR,materials.created_at,23) >= @from_date  AND CONVERT(VARCHAR,materials.created_at, 23) <= @to_date )
				ORDER BY materials.id  DESC 



END
