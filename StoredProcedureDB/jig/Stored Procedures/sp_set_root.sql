 

CREATE  PROCEDURE [jig].[sp_set_root]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id			INT				= NULL	 
		, @production_id		INT				= NULL 
		, @qrcodebyuser			NVARCHAR(50)	= NULL 
		, @category_name		NVARCHAR(50)	= NULL 
		, @created_by			INT				= NULL
		, @category_id			INT				= NULL
		, @jig_id				INT				= NULL
		, @value				INT				= NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE	   @status				NVARCHAR(50)
			,  @jig_state			INT				 
			,  @user_no				NVARCHAR(6)
			,  @expiration_base		INT 
			,  @location_id			INT	

	   IF EXISTS (  SELECT TOP(1) jigs.id ,jigs.Status  
					FROM APCSProDB.trans.jigs 
					INNER JOIN APCSProDB.jig.productions 
					ON  jigs.jig_production_id =  productions.id 
					INNER JOIN APCSProDB.jig.categories 
					ON  productions.category_id = categories.id 
					WHERE qrcodebyuser = @qrcodebyuser
					and categories.lsi_process_id = @process_id
					and categories.name		= @category_name
					and jigs.root_jig_id	= @jig_id
					AND jigs.qrcodebyuser	= @qrcodebyuser
					ORDER BY id DESC
					)
			
		BEGIN 
		
			SELECT  'FALSE' AS Is_Pass,
					N'('+(@qrcodebyuser)+') Duplicate information !!' AS Error_Message_ENG,
					N'('+(@qrcodebyuser)+N')  ถูกลงทะเบียนแล้ว ไม่สามารถลงทะเบียนซ้ำได้ !!' AS Error_Message_THA
					,'' AS Handling
					,N'กรุณาตรวจสอบข้อมูลที่ Web Jig' AS Warning
		
		END
		ELSE
		BEGIN  TRY
		BEGIN
			 
					SELECT TOP(1)  @jig_id				= jigs.id 
								 , @status				= jigs.Status  
								 , @jig_state			= jigs.jig_state
								 , @expiration_base		= expiration_base
								 , @location_id			= location_id
					FROM APCSProDB.trans.jigs 
					INNER JOIN APCSProDB.jig.productions 
					ON  jigs.jig_production_id =  productions.id 
					INNER JOIN APCSProDB.jig.categories 
					ON  productions.category_id = categories.id 
					WHERE jigs.id = @jig_id
					ORDER BY jigs.id DESC





					INSERT INTO APCSProDB.trans.jigs 
					(
							qrcodebyuser
							,jig_production_id
							,status
							,jig_state
							,lot_no
							,root_jig_id
							,location_id
							,limit_date
							,created_at
							,created_by
							,quantity
					) 
					values 
					(		  @qrcodebyuser
							, @production_id
							, @status
							, @jig_state
							, @qrcodebyuser
							, @jig_id
							, @location_id
							, DATEADD(year, @expiration_base,GETDATE())
							, GETDATE()
							, @created_by
							, @value
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

				IF (SELECT counta FROM  (SELECT COUNT(jigs.root_jig_id)AS counta  FROM  APCSProDB.trans.jigs
										 WHERE jigs.root_jig_id = @jig_id GROUP BY root_jig_id ) AS xx
					) >= 10
				BEGIN 

								UPDATE	  APCSProDB.trans.jigs 
								SET		  location_id		= NULL
										, status			= 'Scrap'
										, jigs.jig_state	= 13
										, updated_at		= GETDATE()
										, updated_by		= @created_by
								WHERE	id = @jig_id
								
								SET @user_no = (SELECT emp_num FROM APCSProDB.man.users WHERE id = @created_by)

								INSERT INTO APCSProDB.trans.jig_records 				
							(		
								 [day_id]		
								,[record_at]		
								,[jig_id]		
								,[jig_production_id]		
								,location_id		
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
								, NULL		
								, GETDATE()	
								, @created_by
								, @user_no		
								, 'Scrap'
								, 13
							)		
						SELECT   'TRUE' AS Is_Pass
						,N' Successfully registered !!' AS Error_Message_ENG
						,N' ลงทะเบียนเรียบร้อย !!' AS Error_Message_THA
						,'' AS Handling
						,'' AS Warning

				END

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
