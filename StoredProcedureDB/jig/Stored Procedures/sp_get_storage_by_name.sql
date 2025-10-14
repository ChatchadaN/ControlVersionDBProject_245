------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Author Name              : Sadanun.B
-- Written Date             : 2023/04/05
-- Procedure Name 	 		: [jig].[sp_get_storage_by_name]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.locations
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_get_storage_by_name]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id	INT				= NULL
		, @name			NVARCHAR(50)	= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

  
	IF EXISTS (SELECT id , name + ',' + y + ',' + x 
				FROM	APCSProDB.jig.locations 
				WHERE  name + ',' + y + ',' + x = @name
				AND	lsi_process_id = @process_id)
	BEGIN
			
			SELECT    'TRUE' AS Is_Pass
					, N'This Storage ('+ @name + ') Is registed !!' AS Error_Message_ENG
					, N'JIG นี้ ('+ @name + N') ยังถูกลงทะเบียนแล้ว !!' AS Error_Message_THA
					, '' AS Handling
			RETURN
	END 
	ELSE
	BEGIN 
			SELECT    'FALSE' AS Is_Pass
					, N'This Storage ('+ @name + ') Is not register !!' AS Error_Message_ENG
					, N'Storage ('+ @name + N') นี้ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
					, '' AS Handling
			RETURN 
	END
END
