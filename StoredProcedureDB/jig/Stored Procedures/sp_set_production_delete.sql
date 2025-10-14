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

CREATE PROCEDURE [jig].[sp_set_production_delete]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @production_id			INT				= NULL 
		, @disable					INT 			= NULL 
		, @updated_by				INT 
)
AS
BEGIN
	SET NOCOUNT ON;
	 
 BEGIN 
	 
			BEGIN  TRY
		 
			BEGIN

				UPDATE  APCSProDB.jig.productions 
				SET   is_disabled		= @disable
					, updated_at		= GETDATE()
					, updated_by		= @updated_by
				WHERE productions.id	= @production_id


				UPDATE  APCSProDB.jig.production_counters 
				SET   is_disabled	 =  @disable
					, updated_at	 = GETDATE()
					, updated_by	 = @updated_by
				WHERE production_id  =  @production_id



				SELECT   'TRUE' AS Is_Pass
						,N' Successfully !!' AS Error_Message_ENG
						,N' แก้ไขข้อมูลสำเร็จ !!' AS Error_Message_THA
						,'' AS Handling
						,'' AS Warning

			END

			END	TRY
	
		BEGIN CATCH
			SELECT    'FALSE' AS Is_Pass 
					, N'Failed to register !!' AS Error_Message_ENG
					, N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA 
					, '' AS Handling
		END CATCH	 

   END

   END
