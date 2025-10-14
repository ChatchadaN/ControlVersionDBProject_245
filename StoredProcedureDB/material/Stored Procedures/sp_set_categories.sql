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

CREATE  PROCEDURE [material].[sp_set_categories]
(
		  @short_name	NVARCHAR(100) = NULL 
		, @name			NVARCHAR(100)  
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY  

		INSERT INTO APCSProDB.[material].[categories]
		(		 id 
			   , [name]
			   , [short_name]
			   , [created_at]
			   , [created_by]
		)
		 VALUES
		(		
				--(SELECT MAX(ISNULL(id,0))+ 1  FROM APCSProDB.[material].[categories])
				(SELECT ISNULL(id,0) + 1 FROM APCSProDB.material.numbers WHERE  name ='categories.id')
				, @name
				, @short_name
				, GETDATE()
				, 1
		)

		UPDATE APCSProDB.material.numbers
		SET id = id + 1
		WHERE  name ='categories.id'

		SELECT   'TRUE' AS Is_Pass
					,N'('+(@name)+') Successfully registered !!' AS Error_Message_ENG
					,N'('+(@name)+') Successfully registered !!' AS Error_Message_THA
					,'' AS Handling
					,'' AS Warning

	END TRY  
	BEGIN CATCH  
		SELECT    'FALSE'					AS Is_Pass 
				, N'Failed to register !!'	AS Error_Message_ENG
				, N'Failed to register !!'		AS Error_Message_THA 
				, ''						AS Handling
		
	END CATCH  

END
