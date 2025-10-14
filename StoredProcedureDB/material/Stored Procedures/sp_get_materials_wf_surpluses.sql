
------------------------------ Creater Rule ------------------------------
-- Project Name				: material 
-- Written Date             : 2024/09/26
-- Procedure Name 	 		: [material].[sp_get_productions]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB_Backup20240516.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_get_materials_wf_surpluses]
  (
	  @id				INT = NULL 
	, @barcode			NVARCHAR(100) = NULL
	, @production_id	INT =  NULL
 )
AS
BEGIN
	SET NOCOUNT ON;

		SELECT	    categories.id			AS categories_id
				  , categories.name			AS categories_name 
				  , productions.id			AS productions_id
				  , productions.name		AS productions_name
				  , materials.id			AS materials_id 
				  , materials.barcode 
				  , in_quantity 
				  , materials.quantity 
				  , process_state
				  , ISNULL(code3.descriptions,'')		AS process_statename
				  , material_state
				  , ISNULL(code2.descriptions,'')		AS material_statename
				  , FORMAT(materials.limit_date,'yyyy-MM-dd') 	AS limit_date
				  , ISNULL(FORMAT(extended_limit_date,'yyyy-MM-dd'),' ')	AS extended_limit_date
				  , materials.location_id
				  , ISNULL(locations.name,'')			AS  [locations_name]
				  , materials.lot_no
				  , materials.limit_state	 
				  , ''						AS limit_statenamne
				  , wf_datas.idx
				  , wf_details.chip_model_name
				  , wf_details.order_no
				  , users.emp_num				created_by
				  , user_update.emp_num			updated_by
				  , wf_details.created_at		created_at
				  , wf_details.updated_at		updated_at
		FROM APCSProDB.trans.materials
		INNER JOIN APCSProDB.trans.wf_details
		ON materials.id  = wf_details.material_id
		INNER JOIN  APCSProDB.trans.wf_datas
		ON materials.id  = wf_datas.material_id
		INNER JOIN APCSProDB.material.productions
		ON materials.material_production_id =  productions.id  
		INNER JOIN APCSProDB.material.categories
		ON productions.category_id = categories.id 
		LEFT JOIN APCSProDB.material.locations
		ON locations.id  = materials.location_id
		LEFT JOIN APCSProDB.material.material_codes   code3
		ON materials.process_state		= code3.code
		AND   code3.[group]		=  'process_state'
		LEFT JOIN APCSProDB.material.material_codes  code2
		ON materials.material_state = code2.code
		AND   code2.[group]		=  'matl_state'
		LEFT JOIN APCSProDB.man.users    
		ON users.id		= wf_details.created_by
		LEFT JOIN APCSProDB.man.users     user_update
		ON user_update.id		= wf_details.updated_by
		WHERE  
		((materials.material_production_id = @production_id OR @production_id IS NULL)
		AND  (materials.id  = @id OR @id IS NULL)) 
		AND  productions.name =  'WAFER Surpluses'   


END
