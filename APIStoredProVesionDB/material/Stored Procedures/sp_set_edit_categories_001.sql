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

CREATE  PROCEDURE [material].[sp_set_edit_categories_001]
(
		  @short_name			NVARCHAR(100) 
		, @name					NVARCHAR(100)  
		, @emp_id				INT
		, @categories_id		INT  
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY  

		
			UPDATE APCSProDB.[material].[categories]
			SET    [name]		= @name
				 , [short_name] = @short_name
				 , [updated_at] = GETDATE()
				 , [updated_by] = @emp_id
			WHERE id	= @categories_id

			UPDATE  APCSProDB.[material].[controls]
			SET     [name]			= @name
				  , [short_name]	= @short_name
				  , [code]			= @short_name
				  , [updated_at]	= GETDATE()
				  , [updated_by]	= @emp_id
			WHERE id	= @categories_id


			SELECT    'TRUE'									AS Is_Pass
					, N'('+(@name)+') Successfully edited !!'   AS Error_Message_ENG
					, N'('+(@name)+') Successfully edited !!'   AS Error_Message_THA
					, ''									    AS Handling

	END TRY  
	BEGIN CATCH  

			SELECT    'FALSE'					AS Is_Pass 
					, N'Failed to edited !!'	AS Error_Message_ENG
					, N'Failed to edited !!'	AS Error_Message_THA 
					, ''						AS Handling
		
	END CATCH  

END
