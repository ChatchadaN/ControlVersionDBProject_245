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

CREATE PROCEDURE [jig].[sp_set_jig_trans]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @production_id		INT				= NULL 
		, @barcode				NVARCHAR(MAX)	= NULL 
		, @created_by			INT				= NULL
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
			
		INSERT INTO APCSProDB.trans.jigs 
				(
					
					  jig_production_id
					, [status]
					, jig_state
					, [in_quantity]
				    , [quantity]
				    , [is_production_usage]
				    , [process_state]
				    , [qc_state]
				    , [root_jig_id]
				    , [created_at]
				    , [created_by]
				) 
		VALUES 
				(	
					  @production_id
					, @status
					, @jig_state
					, @in_quantity 
					, @quantity 
					, 0
					, 0
					, 0
					, @root_jig_id
					, GETDATE()
					, @created_by 
				) 


		INSERT INTO APCSProDB.trans.jig_conditions 				
				(				
					 reseted_at		
					,reseted_by		
				) 				
		VALUES 				
				(				
					 GETDATE()		
					,@created_by	
				)				

		SET @jig_id =  (SELECT TOP(1) jigs.id FROM APCSProDB.trans.jigs WHERE jig_production_id = @production_id order by id DESC)
		SET @user_no = (SELECT emp_num FROM APCSProDB.man.users WHERE id = @created_by)


		INSERT INTO APCSProDB.trans.jig_records 				
			(		
				 [day_id]		
				,[record_at]		
				,[jig_id]		
				,[jig_production_id]		
				,[created_at]		
				,[created_by]		
				,[operated_by]		
				,transaction_type		
				,record_class		
			) 		
		values 				
			(		
				( SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))		
				, GETDATE()		
				, @jig_id		
				, @production_id
				, GETDATE()	
				, @created_by
				, @user_no		
				, 'To Machine'	
				, 11
			)		
				 
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
