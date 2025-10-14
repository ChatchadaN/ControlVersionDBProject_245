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

CREATE  PROCEDURE [jig].[sp_set_kanagata_updatename]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @qrcodebyuser			NVARCHAR(50)	= NULL 
		, @updated_by			INT				= NULL
		, @jig_id				INT 
)
AS
BEGIN
	SET NOCOUNT ON;
   
 BEGIN 
  
			BEGIN  TRY
		 
				UPDATE [APCSProDB].trans.[jigs] 
				SET	   [qrcodebyuser]	= @qrcodebyuser
					  ,[updated_at]		= GETDATE()
					  ,[updated_by]		= @updated_by 
				WHERE  [id]				= @jig_id


			 

				SELECT    'TRUE' AS Is_Pass
						,N'Successfully edited the information. !!' AS Error_Message_ENG
						,N'แก้ไขข้อมูลเรียบร้อยแล้ว !!' AS Error_Message_THA
						,'' AS Handling
						,'' AS Warning

			END	TRY
	
		BEGIN CATCH

				SELECT    'FALSE' AS Is_Pass 
						, N'Failed to edit !!' AS Error_Message_ENG
						, N'การแก้ไขข้อมูลผิดพลาด !!' AS Error_Message_THA 
						, '' AS Handling

		END CATCH	 

   END

END