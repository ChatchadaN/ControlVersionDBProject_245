------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Sadanun.B
-- Written Date             : 2023/06/27
-- Procedure Name 	 		: [material].[sp_get_productions]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_set_edit_material_commons]
 (
	  @material_production_id  INT  
	, @material_name			NVARCHAR(MAX)
	, @id						INT
 )
AS
BEGIN
	SET NOCOUNT ON;
	 
BEGIN TRY  

		UPDATE [APCSProDB].[material].[material_commons]
		SET		[material_production_id]	= @material_production_id 
				,[material_name]			= @material_name 
		WHERE id =  @id 


		SELECT   'TRUE' AS Is_Pass
					,N'('+(@material_name)+') Successfully edited !!' AS Error_Message_ENG
					,N'('+(@material_name)+') Successfully edited !!' AS Error_Message_THA
					,'' AS Handling
					,'' AS Warning
	
	END TRY  
	BEGIN CATCH  
			SELECT    'FALSE'					AS Is_Pass 
					, N'Failed to edited !!'	AS Error_Message_ENG
					, N'Failed to edited !!'	AS Error_Message_THA 
					, ''						AS Handling

	END CATCH  

END
