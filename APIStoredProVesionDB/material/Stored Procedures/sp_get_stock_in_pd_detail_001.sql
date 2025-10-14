
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/07/31>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_stock_in_pd_detail_001]
	-- Add the parameters for the stored procedure here
		@material_outgoings_id			INT  
		 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  
			SELECT	 materials.id  
					, materials.barcode 
					, productions.id			AS productions_id
					, productions.[name]		AS productions_name
					, materials.quantity
					, materials.material_state		AS material_state_id 
					, materials.lot_no
					, ISNULL(code2.descriptions,'')			AS material_state 
					, materials.process_state				AS process_state_id
					, process_state.descriptions			AS process_state 
					, materials.location_id   
					, ISNULL(locations.[name],'')			AS  [location_name] 
					, material_outgoing_items.material_outgoings_id 
			FROM   APCSProDB.trans.material_outgoing_items 
			INNER JOIN APCSProDB.trans.materials
			ON  materials.id  = material_outgoing_items.material_id
			INNER JOIN APCSProDB.material.productions	
			ON  materials.material_production_id  = productions.id  
			LEFT JOIN APCSProDB.material.locations
			ON locations.id  = materials.location_id
			LEFT JOIN APCSProDB.material.material_codes  code2
			ON materials.material_state = code2.code
			AND   code2.[group]		=  'matl_state'
			LEFT JOIN APCSProDB.material.material_codes  process_state
			ON materials.process_state = process_state.code
			AND   process_state.[group]		=  'process_state'
			WHERE material_outgoing_items.material_outgoings_id  =  @material_outgoings_id


END
