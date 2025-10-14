------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_set_sample]
 (
		   @jig_id			INT
		 , @extend_date		DATETIME 
		 , @update_by		INT 
 )
AS
BEGIN
	SET NOCOUNT ON;


BEGIN TRY

		UPDATE  APCSProDB.trans.jigs 
		SET	  limit_date	= @extend_date
			, updated_by	= @update_by
			, updated_at	= GETDATE()
		WHERE id = @jig_id


		SELECT   'TRUE'						AS Is_Pass 
				, 'Update data success'		AS Error_Message_ENG
				, N'แก้ไขข้อมูลสำเร็จ'			AS Error_Message_THA 
				, ''						AS Handling

 
  END TRY
	BEGIN CATCH

		SELECT   'FALSE'						AS Is_Pass 
				, 'End Lot Fail !!'				AS Error_Message_ENG
				, N'การบันทึกการจบการผลิตผิดพลาด !!' AS Error_Message_THA 
				, ''							AS Handling
 
	END CATCH	

END
