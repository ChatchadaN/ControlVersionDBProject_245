------------------------------ Creater Rule ------------------------------
-- Project Name				: jig 
-- Written Date             : 2022/12/07
-- Procedure Name 	 		: [jig].[sp_set_storage]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.locations
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_set_in_scrap]
(
		  @qrcodebyuser		NVARCHAR(100)		= NULL 
		, @update_by		INT					= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

				DECLARE   @jig_state		INT				= 0
						, @jig_id			INT 			= 0
						, @production_id	INT				= 0
						, @user_no			NVARCHAR(10)	= 0

				SELECT	  @jig_id			=  jigs.id
						, @jig_state		=  jigs.jig_state
						, @production_id	=  jigs.jig_production_id
				FROM  APCSProDB.trans.jigs 
				WHERE  (qrcodebyuser		=  @qrcodebyuser 
				OR		smallcode			=  @qrcodebyuser 
				OR		barcode				=  @qrcodebyuser)

	IF EXISTS (SELECT 'xxx' FROM  APCSProDB.trans.jigs WHERE id = @jig_id)
	BEGIN  	

	  BEGIN TRY

				 IF (@jig_state = 12)--12	On Machine
				 BEGIN 
						SELECT    'FALSE' AS Is_Pass
								, N'('+@qrcodebyuser+') used in the machine.!!' AS Error_Message_ENG
								, N'('+@qrcodebyuser+ N') นี้ถูกใช้งานอยู่ในเครื่องจักร !!' AS Error_Message_THA
								, '' AS Handling
								, '' AS Warning
						RETURN
				 END
				 ELSE   IF (@jig_state  IN (13 , 14))--13	Scrap  , 14	Scraped
				 BEGIN 
							SELECT    'TRUE' AS Is_Pass
											, N'('+@qrcodebyuser+') Scrap Successfully !!' AS Error_Message_ENG
											, N'('+@qrcodebyuser+ N') ถูก Scrap เเล้ว !!' AS Error_Message_THA
											, '' AS Handling
											, '' AS Warning
							RETURN
				 END
				 ELSE  
				 BEGIN

				 SET @user_no = (SELECT emp_num FROM APCSProDB.man.users WHERE id = @update_by)

									UPDATE	  APCSProDB.trans.jigs 
									SET		  location_id		= NULL
											, status			= 'Scrap'
											, jigs.jig_state	= 13
											, updated_at		= GETDATE()
											, updated_by		= @update_by
									WHERE	 id	= @jig_id

									INSERT INTO APCSProDB.trans.jig_records 
									(	 
										  [day_id]
										, [record_at]
										, [jig_id]
										, [jig_production_id]
										, [location_id]
										, [created_at]
										, [created_by]
										, [operated_by]
										, transaction_type
										, record_class
									) 
									VALUES 
									(
										  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
										, GETDATE()
										, @jig_id
										, @production_id
										, NULL
										, GETDATE()
										, @update_by
										, @user_no
										, 'Scrap'
										, 13
									)

									SELECT    'TRUE' AS Is_Pass
											, N'('+@qrcodebyuser+') Scrap Successfully !!' AS Error_Message_ENG
											, N'('+@qrcodebyuser+ N') ถูก Scrap เเล้ว !!' AS Error_Message_THA
											, '' AS Handling
											, '' AS Warning
							 
				END
			END	TRY
			BEGIN CATCH
						SELECT    'FALSE' AS Is_Pass 
								, N'Failed to update !!' AS Error_Message_ENG
								, N'การแก้ไขข้อมูลผิดพลาด !!' AS Error_Message_THA 
								, '' AS Handling
			END CATCH	 
	END
	ELSE 
	BEGIN 

		SELECT    'FALSE' AS Is_Pass 
					, N'Data not found!!' AS Error_Message_ENG
					, N'ยังไม่ถูกลงทะเบียน  !!' AS Error_Message_THA 
					, '' AS Handling
	END
END
