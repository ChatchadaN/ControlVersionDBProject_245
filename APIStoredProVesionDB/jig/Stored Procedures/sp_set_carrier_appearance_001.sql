-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_carrier_appearance_001]
	-- Add the parameters for the stored procedure here
		  @QRCode	AS VARCHAR(50)  
		, @OPNo		AS VARCHAR(10)  
		, @MCNo		AS VARCHAR(50)		= NULL
		, @Status	AS VARCHAR(10)		= NULL	--0 NG , 1 OK

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		DECLARE   @JIG_ID				VARCHAR(10)
				, @Smallcode			VARCHAR(4)
				, @MCId					INT
				, @OldJIG				INT
				, @Type					VARCHAR(250)
				, @OPID					INT
				, @Shot_name			NVARCHAR(50)
				, @jig_production_id	INT 
				, @MCOld				VARCHAR(50)
				, @user_no				NVARCHAR(6)
				, @jig_state			INT


		SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
		SET @MCId = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)
		SET @user_no = (SELECT emp_num FROM APCSProDB.man.users WHERE id = @OPID)
		  
		SELECT	  @JIG_ID				= jigs.id 
				, @jig_state			= jig_state 
				, @Smallcode			= jigs.smallcode  
				, @Type					= categories.name
				, @jig_production_id	= jig_production_id
		FROM APCSProDB.trans.jigs
		INNER JOIN APCSProDB.jig.productions 
		ON jig_production_id = productions.id 
		INNER JOIN APCSProDB.jig.categories 
		ON category_id = categories.id 
		WHERE (barcode = @QRCode OR qrcodebyuser = @QRCode)


		INSERT INTO APIStoredProDB.[dbo].[exec_sp_history_jig]
		(	
				  [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, jig_id
				, barcode
		)
		SELECT    GETDATE()
				, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'EXEC [jig].[sp_set_carrier_appearance] @JIG_ID = ''' + ISNULL(CAST(@JIG_ID AS nvarchar(MAX)),'') + ''', @QRCode = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') + ''', State Now = ''' + ISNULL(CAST(@Status AS nvarchar(MAX)),'') + ''',@OpNO = ''' 
					+ ISNULL(CAST(@OpNO AS nvarchar(MAX)),'') +  ''',@McNo = ''' + ISNULL(CAST(@McNo AS nvarchar(MAX)),'') + ''''
				, @JIG_ID
				, @QRCode 

		IF NOT EXISTS (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE (barcode = @QRCode OR qrcodebyuser = @QRCode)) 
		BEGIN

			SELECT	 'FALSE'							AS Is_Pass
					, 'This JIG is not registered !!'	AS Error_Message_ENG
					, N'JIG นี้ยังไม่ถูกลงทะเบียน !!'			AS Error_Message_THA
					, N' กรุณาตรวจสอบ หรือติดต่อ System'		AS Handling
			RETURN

		END
		-- CHECK MACHINE NUMBER
		IF NOT EXISTS(SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo) 
		BEGIN 

			SELECT    'FALSE'							AS Is_Pass 
					, 'Machine Number is invalid !!'	AS Error_Message_ENG
					, N'Machine Number ไม่ถูกต้อง !!'		AS Error_Message_THA
					, N' กรุณาตรวจสอบ หรือติดต่อ System'		AS Handling

			RETURN

		END
		
		IF EXISTS  (SELECT    'xxx'
			FROM APCSProDB.trans.jigs
			INNER JOIN APCSProDB.jig.productions 
			ON productions.id = jigs.jig_production_id
			INNER JOIN APCSProDB.jig.categories 
			ON categories.id = productions.category_id
			WHERE  short_name = 'Carrier'   
			AND ( jigs.qrcodebyuser = @QRCode  OR barcode = @QRCode )
			AND jig_state <> 13   --Scrap
			)
		BEGIN 
				IF (@jig_state IN (15, 10) ) --10	Measurement   , 15 To Appearance
				BEGIN
						IF (@Status IS NULL OR @Status ='') 
						BEGIN 	 

							UPDATE    APCSProDB.trans.jigs 
							SET		  location_id		= NULL
									, status			= 'To Appearance'
									, jigs.jig_state	= 15
									, updated_at		= GETDATE()
									, updated_by		= @OPNo
							WHERE  id	=  @jig_id

							

							INSERT INTO  APCSProDB.trans.jig_records 
							(		  [day_id]
									, [record_at]
									, [jig_id]
									, [jig_production_id]
									, [location_id]
									, [created_at]
									, [created_by]
									, [operated_by]
									, [transaction_type]
									, record_class
									, jig_state
							) 
							VALUES 
							(		  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
									, GETDATE()
									, @jig_id
									, @jig_production_id
									, NULL
									, GETDATE()
									, @OPID
									, @user_no
									, 'To Appearance'
									, 19
									, 15
							)


							SELECT    'TRUE'										AS Is_Pass
									, N'This Carrier ('+ @QRCode + ') To Appearance!!'	AS Error_Message_ENG
									, N'Carrier นี้ ('+ @QRCode + N') กำลัง Appearance !!'   AS Error_Message_THA
									, ''											AS Handling
							RETURN

						END 
						IF (@Status = '0') 
						BEGIN 	 

							UPDATE    APCSProDB.trans.jigs 
							SET		  location_id		= NULL
									, status			= 'Appearance NG'
									, jigs.jig_state	= 17
									, updated_at		= GETDATE()
									, updated_by		= @OPNo
							WHERE  id	=  @jig_id

							 
							INSERT INTO  APCSProDB.trans.jig_records 
							(		  
									  [day_id]
									, [record_at]
									, [jig_id]
									, [jig_production_id]
									, [location_id]
									, [created_at]
									, [created_by]
									, [operated_by]
									, [transaction_type]
									, record_class
									, jig_state
							) 
							VALUES 
							(		  
									  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
									, GETDATE()
									, @jig_id
									, @jig_production_id
									, NULL
									, GETDATE()
									, @OPID
									, @user_no
									, 'Appearance NG'
									, 21
									, 17
							)


							UPDATE    APCSProDB.trans.jigs 
							SET		  location_id		= NULL
									, status			= 'To Repair'
									, jigs.jig_state	= 6
									, updated_at		= GETDATE()
									, updated_by		= @OPNo
							WHERE  id	=  @jig_id
 
							INSERT INTO  APCSProDB.trans.jig_records 
							(		  
									  [day_id]
									, [record_at]
									, [jig_id]
									, [jig_production_id]
									, [location_id]
									, [created_at]
									, [created_by]
									, [operated_by]
									, [transaction_type]
									, record_class
									, jig_state
							) 
							VALUES 
							(		  
									  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
									, GETDATE()
									, @jig_id
									, @jig_production_id
									, NULL
									, GETDATE()
									, @OPID
									, @user_no
									, 'To Repair'
									, 6
									, 6
							)

							SELECT    'TRUE'											AS Is_Pass
									, N'This Carrier ('+ @QRCode + ') Appearance NG !!'	AS Error_Message_ENG
									, N'Carrier นี้ ('+ @QRCode + N') Appearance NG !!'	AS Error_Message_THA
									, ''												AS Handling
							RETURN


						END 
						ELSE  IF (@Status = '1') 
						BEGIN 

							UPDATE    APCSProDB.trans.jigs 
							SET		  [status]			= 'Appearance'
									, jigs.jig_state	= 16
									, updated_at		= GETDATE()
									, updated_by		= @OPNo
							WHERE  id	=  @jig_id
 
							INSERT INTO  APCSProDB.trans.jig_records 
							(		  [day_id]
									, [record_at]
									, [jig_id]
									, [jig_production_id]
									, [location_id]
									, [created_at]
									, [created_by]
									, [operated_by]
									, [transaction_type]
									, record_class
									, jig_state
							) 
							VALUES 
							(		  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
									, GETDATE()
									, @jig_id
									, @jig_production_id
									, NULL
									, GETDATE()
									, @OPID
									, @user_no
									, 'Appearance'
									, 20
									, 16
							)

							SELECT    'TRUE'															AS Is_Pass
									, N'This Carrier ('+ @QRCode + ') in Appearance!!'					AS Error_Message_ENG
									, N'Carrier นี้ ('+ @QRCode + N') ถูกนำเข้าสถานะ Appearance เรียบร้อย !!'	AS Error_Message_THA
									, ''																AS Handling
							RETURN

					 
						END 
						ELSE 
						BEGIN

							SELECT    'FALSE'												AS Is_Pass 
									, 'This carrier ('+ @QRCode +') was unsuccessfull !!'	AS Error_Message_ENG
									, N'Carrier ('+ @QRCode +N') Appearance ไม่สำเร็จ !!'		AS Error_Message_THA 
									, N'กรุณาลงทะเบียนที่เว็บ JIG Controlsystem'					AS Handling
								 
							RETURN
						END 
				END
				ELSE
				BEGIN

						SELECT    'FALSE'														AS Is_Pass 
								, 'Please take carrier ('+ @QRCode +') to Measurement  !!'		AS Error_Message_ENG
								, N'กรุณานำ Carrier ('+ @QRCode +N') ไป Measurement ก่อน !!'		AS Error_Message_THA 
								, N'เช็คข้มูลที่เว็บ JIG Controlsystem'								AS Handling
								 
						RETURN
				END 

		END 
		ELSE
		BEGIN
	
				SELECT    'FALSE'												AS Is_Pass 
						, 'This carrier ('+ @QRCode +') not yet register !!'	AS Error_Message_ENG
						, N'Carrier ('+ @QRCode +N') นี้ยังไม่ถูกลงทะเบียน !!'			AS Error_Message_THA 
						, N'กรุณาลงทะเบียนที่เว็บ JIG Controlsystem'					AS Handling
		END 
	
END
