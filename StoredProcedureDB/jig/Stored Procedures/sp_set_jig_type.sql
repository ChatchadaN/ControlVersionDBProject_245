------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Written Date             : 2022/12/07
-- Procedure Name 	 		: [jig].[sp_set_jig_type]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.locations
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_set_jig_type]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @id				 INT				= NULL 
		, @Shot_name		 NVARCHAR(50)		= NULL 
		, @unit				 NVARCHAR(50)		= NULL
		, @name				 NVARCHAR(50)		= NULL 
		, @update_by		 INT				= NULL
)		
AS
BEGIN
	SET NOCOUNT ON;
	
 
 BEGIN 
			BEGIN  TRY
		 
			BEGIN

				 UPDATE [APCSProDB].jig.[categories]
				 SET	   [name]			= @name 
						  , short_name		= @Shot_name
					      , updated_at		= GETDATE()
						  , lifetime_unit	= @unit
					      , updated_by		= @update_by
				 WHERE  id =  @id


				SELECT    'TRUE'										AS Is_Pass
						, N'Successfully edited the information. !!'	AS Error_Message_ENG
						, N'แก้ไขข้อมูลเรียบร้อยแล้ว !!'						AS Error_Message_THA
						, ''											AS Handling
						, ''											AS Warning

			END
			END	TRY
	
		BEGIN CATCH
			SELECT    'FALSE'					AS Is_Pass 
					, N'Failed to register !!'	AS Error_Message_ENG
					, N'การแก้ไขข้อมูลผิดพลาด !!'	AS Error_Message_THA 
					, ''						AS Handling
		END CATCH	 

   END

   END
