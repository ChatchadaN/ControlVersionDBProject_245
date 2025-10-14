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

CREATE  PROCEDURE [jig].[sp_set_storage]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id  INT  = NULL	 
		, @location NVARCHAR(MAX) = NULL 
		, @col NVARCHAR(2) =  NULL 
		, @row NVARCHAR(2) =  NULL 
		, @created_by INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON;

  

	IF EXISTS (SELECT  name FROM APCSProDB.jig.locations WHERE name = @location and lsi_process_id =  @process_id)
		BEGIN 
		
		SELECT  'FALSE' AS Is_Pass,
				N'('+(@location)+') Duplicate information !!' AS Error_Message_ENG,
				N'('+(@location)+N') ถูกลงทะเบียนแล้ว ไม่สามารถลงทะเบียนซ้ำได้ !!' AS Error_Message_THA
				,'' AS Handling
				,N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
		
		END
	ELSE
		BEGIN  TRY


			INSERT INTO APCSProDB.jig.locations 
					(
						name
						,y
						,x
						,lsi_process_id
						,created_at
						,created_by
					) 
			VALUES 
					(
						 @location
						,@col
						,@row
						,@process_id
						,GETDATE()
						,@created_by
					) 

			SELECT   'TRUE' AS Is_Pass
					,N'('+(@location)+') Successfully registered !!' AS Error_Message_ENG
					,N'('+(@location)+N') ลงทะเบียนเรียบร้อย !!' AS Error_Message_THA
					,'' AS Handling
					,'' AS Warning

		END	TRY
	
	BEGIN CATCH
		SELECT 'FALSE' AS Is_Pass ,N'Failed to register !!' AS Error_Message_ENG,N'ลงทะเบียนไม่สำเร็จ !!' AS Error_Message_THA ,'' AS Handling
	END CATCH	 

END
