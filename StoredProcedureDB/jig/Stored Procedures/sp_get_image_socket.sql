------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Written Date             : 2023/12/18
-- Procedure Name 	 		: [jig].[sp_get_image_socket]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.tran.jigs
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_get_image_socket]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id			INT				= NULL	 
		, @jig_record_id		INT				= NULL 
		, @jig_id				INT				= NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE	   @status		NVARCHAR(50)
			,  @jig_state	INT				 
			,  @user_no		NVARCHAR(6)

	   IF NOT EXISTS (  SELECT TOP(1) jigs.id 
					FROM APCSProDB.trans.jigs 
					INNER JOIN  APCSProDB.trans.jig_records
					ON jigs.id  =  jig_records.jig_id 
					WHERE jig_records.id  =  @jig_record_id
					)
			
		BEGIN 
		
			SELECT  'FALSE' AS Is_Pass,
					N' Data not found!!' AS Error_Message_ENG,
					N' ไม่พบข้อมูล !!' AS Error_Message_THA
					,'' AS Handling
					,N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
		
		END
		ELSE
		BEGIN  TRY
		BEGIN
		 
					SELECT	  'TRUE' AS Is_Pass
							, N'' AS Error_Message_ENG
							, N'' AS Error_Message_THA
							, N'' AS Handling 
							,(SELECT binary_file FROM  APCSProDB.trans.binary_data 
							  WHERE  id  = @jig_record_id) AS binary_file
							, jig_records.comment
							, transaction_type
							, jigs.jig_state
					FROM APCSProDB.trans.jigs 
					INNER JOIN APCSProDB.trans.jig_records 
					ON  jig_records.jig_id =  jigs.id 
					INNER JOIN APCSProDB.trans.binary_data 
					ON  jig_records.id = binary_data.id 
					WHERE jig_records.id = @jig_record_id
					   
		END
		END	TRY
		BEGIN CATCH

				SELECT    'FALSE' AS Is_Pass 
						, N'Failed to register !!' AS Error_Message_ENG
						, N'ไม่สามารถบันทึกข้อมูลได้ !!' AS Error_Message_THA 
						, '' AS Handling
		END CATCH	 

END
