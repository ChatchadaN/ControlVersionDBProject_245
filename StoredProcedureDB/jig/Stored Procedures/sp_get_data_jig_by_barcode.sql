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

CREATE  PROCEDURE [jig].[sp_get_data_jig_by_barcode]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id		INT				= NULL
		, @SmallCode		NVARCHAR(100)	= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @jig_state INT  , @jig_status NVARCHAR(10)

 


	IF EXISTS(SELECT 'xxx'
			FROM APCSProDB.trans.jigs 
			INNER JOIN  APCSProDB.jig.productions 
			ON jigs.jig_production_id	= productions.id 
			INNER JOIN  APCSProDB.jig.categories 
			ON productions.category_id	= categories.id 
			WHERE ( jigs.barcode = @SmallCode )
			AND categories.lsi_process_id = @process_id )
	BEGIN

			SELECT  @jig_state =  jigs.jig_state , @jig_status =  jigs.[status]
			FROM APCSProDB.trans.jigs 
			INNER JOIN  APCSProDB.jig.productions 
			ON jigs.jig_production_id	= productions.id 
			INNER JOIN  APCSProDB.jig.categories 
			ON productions.category_id	= categories.id 
			WHERE ( jigs.barcode = @SmallCode )
			AND categories.lsi_process_id = @process_id

			
			IF (@jig_state IN (4,12,13))--4 Stock NG  , 13 Scrap , 12	On Machine
			BEGIN 
					SELECT    'FALSE' AS Is_Pass
							, N'This Socket ('+ @SmallCode + ') status is '+ @jig_status + ' !!' AS Error_Message_ENG
							, N'Socket นี้ ('+ @SmallCode + N') สถานะ '+ @jig_status + ' !!' AS Error_Message_THA
							, '' AS Handling
					RETURN
			END
			ELSE
			BEGIN 
					SELECT    'TRUE' AS Is_Pass
							, N'This Socket ('+ @SmallCode + ') Is registed !!' AS Error_Message_ENG
							, N'Socket นี้ ('+ @SmallCode + N') ถูกลงทะเบียนแล้ว !!' AS Error_Message_THA
							, '' AS Handling
					RETURN
			END

	END 
	ELSE
	BEGIN 
			SELECT    'FALSE' AS Is_Pass
					, N'This Socket ('+ @SmallCode + ') Is not register !!' AS Error_Message_ENG
					, N'Socket ('+ @SmallCode + N') นี้ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
					, '' AS Handling
			RETURN 
	END
END
