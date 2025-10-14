
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/07/31>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_stock_out_pc_001]
	-- Add the parameters for the stored procedure here
		@location_id INT 
		, @production_id		INT = 0
		, @material_state		INT = 0
		, @process_state		INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  
		SELECT    materials.id						AS material_id
				, material_pickup_file.barcode  
				, productions.id					AS production_id 
				, material_pickup_file.production_name 
				, material_pickup_file.lot_no 
				, material_pickup_file.quantity  
				, material_codes.descriptions		AS material_state
				, materials.material_state			AS material_state_id
				, materials.process_state			AS process_state_id
				, process_state.descriptions		AS process_state
				, locations.[name]					AS location_name  
		FROM  APCSProDB.trans.material_pickup_file
		INNER JOIN APCSProDB.trans.materials
		ON materials.id  = material_pickup_file.material_id
		INNER JOIN APCSProDB.material.productions
		ON productions.id  =  materials.material_production_id 
		INNER JOIN APCSProDB.material.categories
		ON categories.id  =  productions.category_id
		INNER JOIN APCSProDB.material.material_codes
		ON	material_codes.[group]				= 'matl_state'
		AND material_codes.code = materials.material_state
		INNER JOIN APCSProDB.material.material_codes  AS process_state
		ON	process_state.[group]				= 'process_state'
		AND process_state.code = materials.process_state
		INNER JOIN APCSProDB.material.locations
		ON  locations.id		=materials.location_id
		WHERE material_pickup_file.location_id	= @location_id
		AND  (productions.id =  @production_id OR @production_id = 0)
		AND  (materials.material_state		=  @material_state OR @material_state = 0)	
		AND  (materials.process_state		=  @process_state  OR @process_state  = 0)
END
