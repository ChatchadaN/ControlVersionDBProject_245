------------------------------ Creater Rule ------------------------------
-- Project Name				: material 
-- Written Date             : 2023/06/27
-- Procedure Name 	 		: [material].[sp_get_productions]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_get_materials]
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
		FROM APCSProDB.trans.materials 
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
		WHERE  ((materials.material_production_id = @production_id OR @production_id IS NULL)
		AND  (materials.id  = @id OR @id IS NULL)) 
		AND materials.material_state in (1,2 ) 
		AND materials.quantity > 0
		--OR(barcode =  @barcode OR @barcode IS NULL)



END
