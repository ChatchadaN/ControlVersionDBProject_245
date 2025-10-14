
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/09/29>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_material_repack_001]
	-- Add the parameters for the stored procedure here
		@location_id  			INT
	  , @emp_id					INT			= 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

				
				SELECT	  material_repack_file.id	 AS material_repack_file_id 
						, material_id	
						, barcode	
						, production_name	
						, lot_no	
						, quantity	
						, repack_qty
						, pack_std_qty	
						, pack_unit_qty	
						, pack_unit_name	
						, location_id	
						, from_location.[name]							AS from_location
						, to_location_id	 
						, to_location.[name]								AS to_location		
						, ISNULL(CONVERT(VARCHAR,(material_repack_file.created_at),21),'')	AS created_at
						, ISNULL(created_by.emp_num	,'')				AS created_by	
						, ISNULL(CONVERT(VARCHAR,(material_repack_file.updated_at),21),'') 	AS updated_at
						, ISNULL(updated_by.emp_num	,'')				AS updated_by  
				FROM  APCSProDB.trans.material_repack_file
				INNER JOIN APCSProDB.material.locations from_location
				ON  from_location.id  = material_repack_file.location_id
				INNER JOIN APCSProDB.material.locations to_location
				ON  to_location.id  = material_repack_file.to_location_id
				LEFT JOIN APCSProDB.man.users		AS created_by
				ON  created_by.id =  material_repack_file.created_by  
				LEFT JOIN APCSProDB.man.users		AS updated_by
				ON  updated_by.id =  material_repack_file.updated_by   
				WHERE location_id = @location_id 
				OR material_repack_file.created_by   =	@emp_id
				 
END
