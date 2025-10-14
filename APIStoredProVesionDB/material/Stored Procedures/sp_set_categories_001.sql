------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Sadanun.B
-- Written Date             : 2025/10/02
-- Procedure Name 	 		: [material].[sp_get_categories]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_set_categories_001]
(
		  @short_name	NVARCHAR(100) 
		, @name			NVARCHAR(100)  
		, @emp_id		INT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY  
		
		DECLARE   @categories_id INT	=  1
				, @controls_id INT		=  1

		EXEC [StoredProcedureDB].material.[sp_get_number_id]
			  @TABLENAME		= 'categories.id'	
			, @NEWID			= @categories_id OUTPUT

		EXEC [StoredProcedureDB].material.[sp_get_number_id]
			  @TABLENAME		= 'controls.id'	
			, @NEWID			= @controls_id OUTPUT

		INSERT INTO APCSProDB.[material].[categories]
		(		 
				 id 
			   , [name]
			   , [short_name]
			   , [created_at]
			   , [created_by]
		)
		 VALUES
		(		 
				  @categories_id
				, @name
				, @short_name
				, GETDATE()
				, 1
		)



		INSERT INTO APCSProDB.[material].[controls]
        (	
				 [id]
			   , [name]
			   , [short_name]
			   , [class]
			   , [code]
			   , [created_at]
			   , [created_by]
		)
		VALUES
        (	
				 @controls_id
			   , @name
			   , @short_name
			   , 0
			   , @short_name
			   , GETDATE()
			   , @emp_id
          )
	 



		SELECT    'TRUE' AS Is_Pass
				, N'('+(@name)+') Successfully registered !!' AS Error_Message_ENG
				, N'('+(@name)+') Successfully registered !!' AS Error_Message_THA
				, '' AS Handling

	END TRY  
	BEGIN CATCH  
		SELECT    'FALSE'					AS Is_Pass 
				, N'Failed to register !!'	AS Error_Message_ENG
				, N'Failed to register !!'		AS Error_Message_THA 
				, ''						AS Handling
		
	END CATCH  

END
