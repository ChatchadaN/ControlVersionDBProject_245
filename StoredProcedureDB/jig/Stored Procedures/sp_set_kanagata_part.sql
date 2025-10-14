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

CREATE PROCEDURE [jig].[sp_set_kanagata_part]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id			INT				= 0	 
		, @production_id		INT				 
		, @qrcodebyuser			NVARCHAR(50)	= NULL 
		, @category_name		NVARCHAR(50)	= NULL 
		, @created_by			INT				= 0
		, @category_id			INT				= 0
		, @root_jig_id			INT					
)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE	   @status		NVARCHAR(50)
			,  @jig_state	INT				 
			,  @user_no		NVARCHAR(6)
			,  @jig_id		INT 
			 


	   IF EXISTS (  SELECT TOP(1) jigs.id 
					FROM APCSProDB.trans.jigs 
					INNER JOIN APCSProDB.jig.productions 
					ON  jigs.jig_production_id		=  productions.id 
					INNER JOIN APCSProDB.jig.categories 
					ON  productions.category_id		= categories.id 
					WHERE qrcodebyuser				= @qrcodebyuser
					AND categories.lsi_process_id	= @process_id
					AND categories.name				= @category_name
					AND productions.id				= @production_id
					ORDER BY id DESC
					)
		BEGIN 
		
			SELECT    'FALSE' AS Is_Pass
					, N'('+(@qrcodebyuser)+') Duplicate information !!' AS Error_Message_ENG
					, N'('+(@qrcodebyuser)+N')  ถูกลงทะเบียนแล้ว ไม่สามารถลงทะเบียนซ้ำได้ !!' AS Error_Message_THA
					, '' AS Handling
					, N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
		
		END
		ELSE
		BEGIN  TRY
		BEGIN


		SELECT @jig_state =  jig_state ,@status = [status]  
		FROM APCSProDB.trans.jigs 
		WHERE id  = @root_jig_id

					INSERT INTO APCSProDB.trans.jigs 
					(
							  qrcodebyuser
							, jig_production_id
							, status
							, jig_state
							, root_jig_id
							, created_at
							, created_by
					) 
					values 
					(		  @qrcodebyuser
							, @production_id
							, @status
							, @jig_state
							, @root_jig_id
							, GETDATE()
							, @created_by
							 
					)
					INSERT INTO APCSProDB.trans.jig_conditions 
					(
							  reseted_at
							, reseted_by
					) 
					VALUES 
					(
							  GETDATE()
							, @created_by
					)
					SET @jig_id =  (SELECT TOP(1) jigs.id FROM APCSProDB.trans.jigs WHERE jig_production_id = @production_id order by id DESC)
					SET @user_no = (SELECT emp_num FROM APCSProDB.man.users WHERE id = @created_by)

						INSERT INTO APCSProDB.trans.jig_records 				
							(		
									  [day_id]		
									, [record_at]		
									, [jig_id]		
									, [jig_production_id]		
									, [root_jig_id]		
									, [created_at]		
									, [created_by]		
									, [operated_by]		
									, transaction_type		
									, record_class		
							) 		
						values 				
							(		
									( SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))		
									, GETDATE()		
									, @jig_id		
									, @production_id
									, @root_jig_id
									, GETDATE()	
									, @created_by
									, @user_no		
									, @status	
									, @jig_state
							)		

			  
				SELECT   'TRUE' AS Is_Pass
						,N' Successfully registered !!' AS Error_Message_ENG
						,N' ลงทะเบียนเรียบร้อย !!' AS Error_Message_THA
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
