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

CREATE PROCEDURE [jig].[sp_set_jig_trans_edit]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @production_id		INT				= NULL 
		, @barcode				NVARCHAR(100)	= NULL 
		, @update_by			INT				= NULL
		, @value				INT				= NULL
		, @in_quantity			INT				= 1
		, @quantity				INT				= 1
		, @root_jig_id			INT				= NULL 
		, @jig_state			INT				= 11
		, @status				NVARCHAR(100)	= 'To Machine'

)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE	   @jig_id		INT 
			,  @user_no		NVARCHAR(6)
   
 IF EXISTS (SELECT jigs.id FROM APCSProDB.trans.jigs 
			INNER JOIN APCSProDB.jig.productions 
			ON jigs.jig_production_id = productions.id 
			INNER JOIN APCSProDB.jig.categories 
			ON productions.category_id = categories.id 
			WHERE barcode =   @barcode
			AND jigs.jig_production_id  = @production_id 
			)
BEGIN 
		
				SELECT  'FALSE' AS Is_Pass,
						N'('+(@barcode)+') Duplicate information !!' AS Error_Message_ENG,
						N'('+(@barcode)+N')  ถูกลงทะเบียนแล้ว ไม่สามารถลงทะเบียนซ้ำได้ !!' AS Error_Message_THA
						,'' AS Handling
						,N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
		
	END
ELSE
	BEGIN  TRY
			
		   UPDATE [APCSProDB].[trans].[jigs]
		   SET --barcode = @barcode
			  --,
			  [status] = @status
			  ,[jig_production_id] = @production_id
			  ,[in_quantity] = @in_quantity
			  ,[quantity] = @quantity
			  ,[jig_state] = @jig_state
			  ,[root_jig_id] = @root_jig_id
			  ,[updated_at] = GETDATE()
			  ,[updated_by] = @update_by
		 WHERE id  = @jig_id
 

		 UPDATE [APCSProDB].[trans].[jig_conditions]
		 SET	[value] = @value
			  , [reseted_at] = GETDATE()
			  , [reseted_by] = @update_by
		 WHERE id  = @jig_id

				 
				SELECT	TOP 1	'TRUE' AS Is_Pass
						,N'('+(@barcode)+') Successfully registered !!' AS Error_Message_ENG
						,N'('+(@barcode)+N') ลงทะเบียนเรียบร้อย !!' AS Error_Message_THA
						,'' AS Handling
						,'' AS Warning
						,@barcode		As barcode
			 
 

			END	TRY
	
			BEGIN CATCH
				SELECT    'FALSE' AS Is_Pass 
						, 'Failed to register !!' AS Error_Message_ENG
						, N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA 
						, '' AS Handling
			END CATCH	 
END 
