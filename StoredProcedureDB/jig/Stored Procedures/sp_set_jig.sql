 
CREATE  PROCEDURE [jig].[sp_set_jig]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id			INT				= NULL	 
		, @location_id			INT				= NULL 
		, @production_id		INT				= NULL 
		, @qrcodebyuser			NVARCHAR(100)	= NULL 
		, @created_by			INT				= NULL
		, @categories_name		NVARCHAR(100)	= NULL
		, @category_id			INT				= NULL
		, @status				NVARCHAR(100)	= NULL
		, @jig_state			INT				= NULL
		, @amount				INT				= NULL
		, @value				INT				= NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE	  @jig_id				INT 
			, @user_no				NVARCHAR(6)
			, @expiration_base		INT 


	IF (@production_id <> 0 )   
	BEGIN
		IF (@categories_name = 'RubberCollet' OR @categories_name = 'Tsukiage' OR @categories_name = 'Capillary'OR @categories_name = 'Wedge' OR @categories_name = 'Wire' OR @categories_name = 'Cutter')
			BEGIN 

							BEGIN  TRY

							DECLARE @cnt INT = 1;

							WHILE  @cnt <= @amount
							BEGIN
								INSERT INTO APCSProDB.trans.jigs 
										(
											 jig_production_id
											,status
											,jig_state
											,location_id
											,created_at
											,created_by
										) 
								VALUES 
										(
											@production_id
											,@status
											,@jig_state
											,@location_id
											,GETDATE()
											,@created_by
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

							SET @jig_id  =  (SELECT TOP(1) jigs.id FROM APCSProDB.trans.jigs WHERE jig_production_id = @production_id order by id DESC)
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
										, @location_id		
										, GETDATE()	
										, @created_by
										, @user_no		
										, @status	
										, @jig_state
									)		

								SET @cnt = @cnt + 1;
							END

								IF(@qrcodebyuser IS NULL)
								BEGIN 

									SELECT	TOP 1	  'TRUE'													AS Is_Pass
													, N'('+(@qrcodebyuser)+') Successfully registered !!'		AS Error_Message_ENG
													, N'('+(@qrcodebyuser)+N') ลงทะเบียนเรียบร้อย !!'				AS Error_Message_THA
													, ''														AS Handling
													, ''														AS Warning
													, jigs.barcode
									FROM APCSProDB.jig.productions
									INNER JOIN APCSProDB.trans.jigs
									ON productions.id  = jigs.jig_production_id
									WHERE productions.id = @production_id
									ORDER BY jigs.id DESC

								 END 
								 ELSE
								 BEGIN 

									 SELECT	TOP 1	  'TRUE'													AS Is_Pass
													, N'('+(@qrcodebyuser)+') Successfully registered !!'		AS Error_Message_ENG
													, N'('+(@qrcodebyuser)+N') ลงทะเบียนเรียบร้อย !!'				AS Error_Message_THA
													, ''														AS Handling
													, ''														AS Warning
													, jigs.barcode
									FROM APCSProDB.jig.productions
									INNER JOIN APCSProDB.trans.jigs
									ON productions.id  = jigs.jig_production_id
									WHERE productions.id = @production_id
									ORDER BY jigs.id DESC

								END

								END	TRY
	
						BEGIN CATCH

							SELECT    'FALSE'					AS Is_Pass 
									, N'Failed to register !!'	AS Error_Message_ENG
									, N'การลงทะเบียนผิดพลาด !!'		AS Error_Message_THA 
									, ''						AS Handling

						END CATCH	 

			END
   
		ELSE IF (@categories_name = 'Dicer Blade' AND @amount != 0)
		BEGIN 

			SELECT @expiration_base =   expiration_base
			FROM APCSProDB.jig.productions
			WHERE id  = @production_id


							BEGIN  TRY

							DECLARE @cnt2 INT = 1;

							WHILE  @cnt2 <= @amount
							BEGIN

								INSERT INTO APCSProDB.trans.jigs 
								(
											  jig_production_id
											, lot_no
											, [status]
											, jig_state
											, location_id
											, limit_date
											, created_at
											, created_by
											, quantity
								) 
								VALUES 
								(
											  @production_id
											, @qrcodebyuser
											, @status
											, @jig_state
											, @location_id
											, DATEADD(year, @expiration_base,GETDATE())
											, GETDATE()
											, @created_by
											, @value
								) 

								INSERT INTO APCSProDB.trans.jig_conditions 
								(			
											  control_no
											, reseted_at
											, reseted_by
											 
								) 
								VALUES 
								(			
											  1
											, GETDATE()
											, @created_by 
								)


							SET @jig_id =  ( SELECT TOP(1) jigs.id FROM APCSProDB.trans.jigs WHERE jig_production_id = @production_id ORDER BY id DESC)
							SET @user_no = ( SELECT emp_num FROM APCSProDB.man.users WHERE id = @created_by)

								INSERT INTO APCSProDB.trans.jig_records 				
								(		
											  [day_id]		
											, [record_at]		
											, [jig_id]		
											, [jig_production_id]		
											, location_id		
											, [created_at]		
											, [created_by]		
											, [operated_by]		
											, transaction_type		
											, record_class		
								) 		
								VALUES 				
								(		
											( SELECT id FROM APCSProDB.trans.days WHERE date_value =  CONVERT(date,GETDATE(),111))		
											, GETDATE()		
											, @jig_id		
											, @production_id
											, @location_id		
											, GETDATE()	
											, @created_by
											, @user_no		
											, @status	
											, @jig_state
								)		

								SET @cnt2 = @cnt2 + 1;
							END

							 IF(@qrcodebyuser IS NULL)
							 BEGIN 

									SELECT	TOP 1	  'TRUE'										AS Is_Pass
													, N'('+(productions.[name])+') Successfully registered !!'	AS Error_Message_ENG
													, N'('+(productions.[name])+N') ลงทะเบียนเรียบร้อย !!'				AS Error_Message_THA
													, ''											AS Handling
													, ''											AS Warning
													, jigs.barcode
									FROM APCSProDB.jig.productions
									INNER JOIN APCSProDB.trans.jigs
									ON productions.id  = jigs.jig_production_id
									WHERE productions.id = @production_id
									ORDER BY jigs.id DESC

							 END 
							 ELSE
							 BEGIN 

									 SELECT	TOP 1	 'TRUE' AS Is_Pass
													, N'('+(@qrcodebyuser)+') Successfully registered !!' AS Error_Message_ENG
													, N'('+(@qrcodebyuser)+N') ลงทะเบียนเรียบร้อย !!' AS Error_Message_THA
													, '' AS Handling
													, '' AS Warning
													, jigs.barcode
									FROM APCSProDB.jig.productions
									INNER JOIN APCSProDB.trans.jigs
									ON productions.id  = jigs.jig_production_id
									WHERE productions.id = @production_id
									ORDER BY jigs.id DESC
							END

							END	TRY
	
						BEGIN CATCH
										SELECT    'FALSE' AS Is_Pass 
												, N'Failed to register !!' AS Error_Message_ENG
												, N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA 
												, '' AS Handling
						END CATCH	 
			END
		ELSE IF (@categories_name = 'Sample' )
		BEGIN 

			SELECT @expiration_base =   expiration_base
			FROM APCSProDB.jig.productions
			WHERE id  = @production_id

						BEGIN  TRY
					 
								INSERT INTO APCSProDB.trans.jigs 
								(
											  jig_production_id 
											, [status]
											, jig_state
											, location_id
											, limit_date
											, created_at
											, created_by
											
								) 
								VALUES 
								(
											  @production_id 
											, @status
											, @jig_state
											, @location_id
											, DATEADD(year, @expiration_base,GETDATE())
											, GETDATE()
											, @created_by
											
								) 

								INSERT INTO APCSProDB.trans.jig_conditions 
								(			
											  control_no
											, reseted_at
											, reseted_by
											 
								) 
								VALUES 
								(			
											  1
											, GETDATE()
											, @created_by 
								)


							SET @jig_id =  ( SELECT TOP(1) jigs.id FROM APCSProDB.trans.jigs WHERE jig_production_id = @production_id ORDER BY id DESC)
							SET @user_no = ( SELECT emp_num FROM APCSProDB.man.users WHERE id = @created_by)

								INSERT INTO APCSProDB.trans.jig_records 				
								(		
											  [day_id]		
											, [record_at]		
											, [jig_id]		
											, [jig_production_id]		
											, location_id		
											, [created_at]		
											, [created_by]		
											, [operated_by]		
											, transaction_type		
											, record_class		
								) 		
								VALUES 				
								(		
											( SELECT id FROM APCSProDB.trans.days WHERE date_value =  CONVERT(date,GETDATE(),111))		
											, GETDATE()		
											, @jig_id		
											, @production_id
											, @location_id		
											, GETDATE()	
											, @created_by
											, @user_no		
											, @status	
											, @jig_state
								)		

							 IF(@qrcodebyuser IS NULL)
							 BEGIN 

									SELECT	TOP 1	  'TRUE'										AS Is_Pass
													, N'('+(productions.[name])+') Successfully registered !!'	AS Error_Message_ENG
													, N'('+(productions.[name])+N') ลงทะเบียนเรียบร้อย !!'				AS Error_Message_THA
													, ''											AS Handling
													, ''											AS Warning
													, jigs.barcode
									FROM APCSProDB.jig.productions
									INNER JOIN APCSProDB.trans.jigs
									ON productions.id  = jigs.jig_production_id
									WHERE productions.id = @production_id
									ORDER BY jigs.id DESC

							 END 
							 ELSE
							 BEGIN 

									 SELECT	TOP 1	 'TRUE' AS Is_Pass
													, N'('+(@qrcodebyuser)+') Successfully registered !!' AS Error_Message_ENG
													, N'('+(@qrcodebyuser)+N') ลงทะเบียนเรียบร้อย !!' AS Error_Message_THA
													, '' AS Handling
													, '' AS Warning
													, jigs.barcode
									FROM APCSProDB.jig.productions
									INNER JOIN APCSProDB.trans.jigs
									ON productions.id  = jigs.jig_production_id
									WHERE productions.id = @production_id
									ORDER BY jigs.id DESC
							END

						END	TRY
						BEGIN CATCH
										SELECT    'FALSE' AS Is_Pass 
												, N'Failed to register !!' AS Error_Message_ENG
												, N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA 
												, '' AS Handling
						END CATCH	 
			END
		ELSE
			BEGIN 

					IF EXISTS (SELECT jigs.id FROM APCSProDB.trans.jigs 
								INNER JOIN APCSProDB.jig.productions 
								ON jigs.jig_production_id = productions.id 
								INNER JOIN APCSProDB.jig.categories 
								ON productions.category_id = categories.id 
								WHERE qrcodebyuser =   @qrcodebyuser
								AND jigs.jig_production_id  = @production_id 
								AND categories.lsi_process_id = @process_id 
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
			
							INSERT INTO APCSProDB.trans.jigs 
									(
										 qrcodebyuser
										,jig_production_id
										,status
										,jig_state
										,location_id
										,created_at
										,created_by
									) 
							VALUES 
									(
										 @qrcodebyuser
										,@production_id
										,@status
										,@jig_state
										,@location_id
										,GETDATE()
										,@created_by
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
									,location_id		
									,[created_at]		
									,[created_by]		
									,[operated_by]		
									,transaction_type		
									,record_class		
								) 		
							VALUES 				
								(		
									( SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))		
									, GETDATE()		
									, @jig_id		
									, @production_id
									, @location_id		
									, GETDATE()	
									, @created_by
									, @user_no		
									, @status	
									, @jig_state
								)		
				
							 IF(@qrcodebyuser IS NULL)
							 BEGIN 
 
								SELECT	TOP 1	'TRUE' AS Is_Pass
										,N'('+(name)+') Successfully registered !!' AS Error_Message_ENG
										,N'('+(name)+N') ลงทะเบียนเรียบร้อย !!' AS Error_Message_THA
										,'' AS Handling
										,'' AS Warning
										,jigs.barcode
								FROM APCSProDB.jig.productions
								INNER JOIN APCSProDB.trans.jigs
								ON productions.id  = jigs.jig_production_id
								WHERE productions.id = @production_id
								ORDER BY jigs.id DESC


							 END 
							 ELSE
							 BEGIN 

								 SELECT	TOP 1	'TRUE' AS Is_Pass
											,N'('+(@qrcodebyuser)+') Successfully registered !!' AS Error_Message_ENG
											,N'('+(@qrcodebyuser)+N') ลงทะเบียนเรียบร้อย !!' AS Error_Message_THA
											,'' AS Handling
											,'' AS Warning
											,jigs.barcode
								FROM APCSProDB.jig.productions
								INNER JOIN APCSProDB.trans.jigs
								ON productions.id  = jigs.jig_production_id
								WHERE productions.id = @production_id
								ORDER BY jigs.id DESC

							END


						END	TRY
	
					BEGIN CATCH

						SELECT    'FALSE'					AS Is_Pass 
								, 'Failed to register !!'	AS Error_Message_ENG
								, N'การลงทะเบียนผิดพลาด !!'		AS Error_Message_THA 
								, ''						AS Handling

					END CATCH	 
				END 
		END
 
	ELSE
	BEGIN

		SELECT    'FALSE'						AS Is_Pass 
				, 'Please register type'		AS Error_Message_ENG
				, N'กรุณาลงทะเบียน Type '			AS Error_Message_THA 
				, N'กรุณาตรวจสอบข้อมูลที่ Web Jig'	AS Handling
		 
	END 
END