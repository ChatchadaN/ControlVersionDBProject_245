------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Author Name              : Sadanun.B
-- Written Date             : 2022/12/07
-- Procedure Name 	 		: [jig].[sp_set_storage]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.locations
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_set_kanagata_delete]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		   @jig_id				INT 
)
AS
BEGIN
	SET NOCOUNT ON;
   
 BEGIN 
  
			BEGIN  TRY
				

				IF EXISTS (SELECT 'xxx' FROM APCSProDB.trans.jigs WHERE root_jig_id = @jig_id )
				BEGIN 

				SELECT    'FALSE' AS Is_Pass 
						, N'Cannot delete '+ jigs.qrcodebyuser + N' !!' AS Error_Message_ENG
						, N'ไม่สามารถลบ '+ jigs.qrcodebyuser + N'ได้ !!' AS Error_Message_THA 
						, '' AS Handling
						FROM APCSProDB.trans.jigs 
						WHERE id = @jig_id 

				END 
				ELSE
				BEGIN 

					DELETE FROM [APCSProDB].trans.jig_records 
					WHERE jig_id = @jig_id
				 
					DELETE FROM [APCSProDB].trans.jig_conditions 
					WHERE id  = @jig_id

					DELETE FROM [APCSProDB].trans.jigs  
					WHERE id = @jig_id


					SELECT    'TRUE' AS Is_Pass
							,N'Successfully delete the information. !!' AS Error_Message_ENG
							,N'ลบข้อมูลเรียบร้อยแล้ว !!' AS Error_Message_THA
							,'' AS Handling
							,'' AS Warning
				END
			END	TRY
	
		BEGIN CATCH

				SELECT    'FALSE' AS Is_Pass 
						, N'Failed to delete !!' AS Error_Message_ENG
						, N'การลบข้อมูลผิดพลาด !!' AS Error_Message_THA 
						, '' AS Handling

		END CATCH	 

   END

END