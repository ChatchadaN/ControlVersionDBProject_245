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

CREATE  PROCEDURE [material].[sp_set_locations_001]
(
		  @name					NVARCHAR(40)
		, @headquarter_id		INT
		, @address				VARCHAR(5)
		, @x					VARCHAR(5)
		, @y					VARCHAR(5)
		, @z					VARCHAR(5)
		, @depth				INT
		, @queue				INT
		, @wh_code				VARCHAR(5)
		, @lsi_process_id		INT
		, @emp_id				INT  
)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY  
		
		DECLARE   @locations_id INT	=  1
			 

		EXEC [StoredProcedureDB].material.[sp_get_number_id]
			  @TABLENAME		= 'locations.id'	
			, @NEWID			= @locations_id OUTPUT
			 

		INSERT INTO [APCSProDB].[material].[locations]
		(			[id]
				   ,[name]
				   ,[headquarter_id]
				   ,[address]
				   ,[x]
				   ,[y]
				   ,[z]
				   ,[depth]
				   ,[queue]
				   ,[wh_code]
				   ,[lsi_process_id]
				   ,[created_at]
				   ,[created_by] 
		)
			 VALUES
		(
					 @locations_id
				   , @name			
				   , @headquarter_id
				   , @address		
				   , @x			
				   , @y			
				   , @z			
				   , @depth		
				   , @queue		
				   , @wh_code		
				   , @lsi_process_id
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
