------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Author Name              : Sadanun.B
-- Written Date             : 2022/12/07
-- Procedure Name 	 		: [jig].[sp_get_storage]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.locations
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_set_storage_delete]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		@id  INT  = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

BEGIN  TRY
		
		DELETE FROM APCSProDB.jig.locations WHERE id = @id

		SELECT	'TRUE' AS Is_Pass
				,N'Successfully registered !!' AS Error_Message_ENG
				,N'เรียบร้อย !!' AS Error_Message_THA
				,'' AS Handling
				,'' AS Warning

END	TRY
BEGIN CATCH
		
		SELECT	  'FALSE' AS Is_Pass 
				, 'Failed to register !!' AS Error_Message_ENG
				, N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA 
				, '' AS Handling

	END CATCH	

END
