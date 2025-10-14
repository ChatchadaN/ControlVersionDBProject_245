------------------------------ Creater Rule ------------------------------
-- Project Name				: jig 
-- Written Date             : 2022/01/07
-- Procedure Name 	 		: [jig].[sp_get_production]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_set_categories]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		   @name			NVARCHAR(100)	
	     , @process_id		INT				= NULL 
		 , @lifetime_unit	NVARCHAR(100)   = NULL 
		 , @created_by		INT				= NULL 
		 , @shotname		NVARCHAR(100)   = NULL 
)
AS
BEGIN
	SET NOCOUNT ON;

	BEGIN  TRY

		INSERT INTO  APCSProDB.[jig].[categories] 
		(			  [name]
					, [short_name]
					, [lsi_process_id]
					, [lifetime_unit]
					, [created_at]
					, [created_by]
					, [updated_at]
					, [updated_by]
		) 
		VALUES 
		(
					  @name
					, @shotname
					, @process_id
					, @lifetime_unit
					, GETDATE()
					, @created_by
					, NULL
					, NULL
		)

			SELECT   'TRUE' AS Is_Pass
						,N'('+(@name)+') Successfully registered !!' AS Error_Message_ENG
						,N'('+(@name)+N') ลงทะเบียนเรียบร้อย !!' AS Error_Message_THA
						,'' AS Handling
						,'' AS Warning


	END	TRY
		BEGIN CATCH
			SELECT    'FALSE' AS Is_Pass 
					, N'Failed to register !!' AS Error_Message_ENG
					, N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA 
					, '' AS Handling
		END CATCH	 

		 
END
