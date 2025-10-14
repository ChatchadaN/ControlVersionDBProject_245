------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Sadanun.B
-- Written Date             : 2023/06/27
-- Procedure Name 	 		: [material].[sp_get_categories]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_set_edit_categories]
(
		  @short_name	NVARCHAR(100) = NULL 
		, @name			NVARCHAR(100)  
		, @id			INT			
)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY  

			UPDATE APCSProDB.[material].[categories]
			SET    [name] = @name
				 , [short_name] = @short_name
				 , [updated_at] = GETDATE()
				 , [updated_by] = 1
			WHERE id	= @id


			SELECT   'TRUE' AS Is_Pass
						,N'('+(@name)+') Successfully edited !!' AS Error_Message_ENG
						,N'('+(@name)+') Successfully edited !!' AS Error_Message_THA
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
