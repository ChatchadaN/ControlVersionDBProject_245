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

CREATE  PROCEDURE [material].[sp_set_suppliers_001]
(
		  @supplier_cd	VARCHAR(10) 
		, @name			NVARCHAR(100)  
		, @emp_id		INT
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY  
 
		INSERT INTO [APCSProDB].[material].[suppliers]
		(		
				 [supplier_cd]
			   , [name]
			   , [created_at]
			   , [created_by] 
		)
		VALUES
		(		
				@supplier_cd
			  , @name
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
