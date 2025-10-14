-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_jig_setup_004]
	-- Add the parameters for the stored procedure here
	  @QRCode			AS VARCHAR(100)
	, @MCNo				AS VARCHAR(50)
	, @OPNo				AS VARCHAR(6) 
	, @LOTNO			AS NVARCHAR(10) =  NULL
	, @Recipe			AS NVARCHAR(50)	=  NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		DECLARE	  @JIG_ID				AS INT
				, @MC_ID				AS INT
				, @STDLifeTime			AS NVARCHAR(50)
				, @LifeTime				AS NVARCHAR(50)
				, @Safety				AS INT
				, @Accu					AS INT
				, @OPID					AS INT
				, @State				AS INT
				, @Smallcode			AS VARCHAR(4)
				, @QTY					AS INT			=  0
				, @MCOld				AS VARCHAR(50)
				, @Category				AS NVARCHAR(50)
				, @root_id				AS INT
				, @process				AS VARCHAR(5)
				, @periodcheck_value	AS NVARCHAR(50)
				, @period_value			AS NVARCHAR(50)
				, @Shot_name			AS NVARCHAR(20)
				, @MCId					INT
				, @OldJIG				INT
				, @Type					VARCHAR(250)
				, @idx					INT  
				, @jig_production_id	INT 
				,@JIG_OLD				AS INT


		SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
		SET @MCId = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)
		  
	SELECT		@JIG_ID				= jigs.id 
				, @State				= jig_state 
				, @Smallcode			= jigs.smallcode  
				, @Shot_name			= TRIM(categories.short_name)
				, @Category				= categories.[name]
				, @root_id				= jigs.id
				, @periodcheck_value	= ISNULL(jig_conditions.periodcheck_value,0)  
				, @period_value			= ISNULL(production_counters.period_value,0)  
				, @STDLifeTime			= ISNULL(productions.expiration_value	 ,production_counters.alarm_value)
				, @LifeTime				= ISNULL(jig_conditions.[value]			 ,0)
				, @Type					=  productions.[name]
				, @jig_production_id	=  jigs.jig_production_id
	FROM APCSProDB.trans.jigs 
	INNER JOIN APCSProDB.trans.jig_conditions 
	ON jigs.id = jig_conditions.id 
	INNER JOIN APCSProDB.jig.productions
	ON productions.id =  jigs.jig_production_id
	INNER JOIN APCSProDB.jig.production_counters 
	ON production_counters.production_id = productions.id
	INNER JOIN APCSProDB.jig.categories
	ON categories.id  = productions.category_id
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
				, lot_no

		)
		SELECT    GETDATE()
				, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'EXEC [jig].[sp_set_jig_setup] @JIG_ID = ''' + ISNULL(CAST(@JIG_ID AS nvarchar(MAX)),'') + ''', @QRCode = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') +''', @Recipe = ''' + ISNULL(CAST(@Recipe AS nvarchar(MAX)),'')+  ''',@OpNO = ''' 
					+ ISNULL(CAST(@OpNO AS nvarchar(MAX)),'') +  ''',@McNo = ''' + ISNULL(CAST(@McNo AS nvarchar(MAX)),'')   +''''
				, @JIG_ID
				, @QRCode
				, @LOTNO

--lot no ต้องเช็คด้วยว่าส่งหรือไม่ส่ง เพราะเป็นจังหวะ set ถ้าไม่มี lot ก็ต้อง setup ได้
	IF (@LOTNO IS NULL  OR @LOTNO = '' )
	BEGIN
		
		--CHECK JIG IS NULL
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
			SELECT    'FALSE' AS Is_Pass 
					, 'Machine Number is invalid !!' AS Error_Message_ENG
					, N'Machine Number ไม่ถูกต้อง !!' AS Error_Message_THA
					, N' กรุณาตรวจสอบ หรือติดต่อ System' AS Handling

			RETURN
		END

		IF ( @State =  12) --On Machine
		BEGIN  
		
			SET @MCOld = (SELECT machines.name FROM APCSProDB.trans.jigs 
							LEFT JOIN APCSProDB.trans.machine_jigs 
							ON machine_jigs.jig_id = jigs.id 
							LEFT JOIN APCSProDB.mc.machines 
							ON machines.id = machine_jigs.machine_id 
							WHERE jigs.id = @JIG_ID
						 )

			IF @MCOld <> @MCNo 
			BEGIN

				SELECT    'FALSE'														AS Is_Pass
						, N'This JIG ('+ @Smallcode + N') Is use on another Machine ('+ @MCOld + N')!!' AS Error_Message_ENG
						, N'JIG นี้ ('+ @Smallcode + N') ถูกใช้งานอยู่ที่ Machine เครื่องอื่น ('+ @MCOld + N') !!'	AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'						AS Handling
				RETURN

			END
			ELSE 
			BEGIN
			IF (@Shot_name ='Kanagata')
			BEGIN
			 
								SELECT  TOP 1    'TRUE'											AS Is_Pass		
											, ''												AS Error_Message_ENG
											, N''												AS Error_Message_THA
											, N''												AS Handling
											, @QRCode											AS QRCode
											, @Smallcode										AS Smallcode
											, @Type												AS [Type]
											, ISNULL(@QTY,0)									AS QTY
											, CONVERT(INT,max_lifetime.[LifeTime])				AS Life_Time
											, max_lifetime.expiration_value						AS STD_Life_Time			
											, @JIG_ID											AS jig_id
											, ISNULL(max_lifetime.LifeTime_Percen,0)			AS LifeTime_Percen
											, ISNULL(max_lifetime.periodcheck_value	,0)			AS  periodcheck_value
											, ISNULL(max_lifetime.period_value	,0)				AS  period_value
								FROM  
									(	SELECT		  warn_value AS warn_value
													, APCSProDB.trans.jig_conditions.value   AS [LifeTime]
													, FORMAT(COALESCE((CAST(jig_conditions.value AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
													, jigs.smallcode
													, productions.name		AS [Type]
													, jigs.id				AS jig_id 
													, production_counters.alarm_value AS expiration_value
													, production_counters.period_value
													, jig_conditions.periodcheck_value
										FROM APCSProDB.trans.jigs 
										INNER JOIN APCSProDB.trans.jig_conditions 
										ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id  
										INNER JOIN APCSProDB.jig.productions 
										ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
										INNER JOIN APCSProDB.jig.production_counters 
										on production_counters.production_id = productions.id
										WHERE jigs.id <> @JIG_ID AND root_jig_id = @JIG_ID
									 )  AS max_lifetime
									ORDER BY max_lifetime.LifeTime_Percen DESC   
				
									RETURN
				END
				ELSE
				BEGIN
					SELECT   'TRUE'								AS Is_Pass
								, N''								AS Error_Message_ENG
								, N''								AS Error_Message_THA
								, N''								AS Handling
								, @QRCode							AS QRCode
								, smallcode							AS Smallcode
								, productions.name					AS [Type]
								, 0									AS QTY
								, CAST(jig_conditions.value AS INT) AS Life_Time
								, CAST(ISNULL(productions.expiration_value , production_counters.alarm_value) AS INT)		AS STD_Life_Time
								, jigs.id							AS jig_id
								, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
								, @periodcheck_value								AS  periodcheck_value
								, ISNULL(production_counters.period_value,0)		AS  period_value		 
						FROM APCSProDB.trans.jigs  
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON jigs.id = jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions 
						ON productions.id = jigs.jig_production_id 
						INNER JOIN APCSProDB.jig.production_counters 
						ON production_counters.production_id = productions.id 
						WHERE jigs.id = @JIG_ID

						RETURN
						END

			END
		END

		--CHECK STATUS BLADE
		IF ( @State <>  11) --To Machine
		BEGIN	
			SELECT  'FALSE'										AS Is_Pass 
					,N'JIG is in stock !!'						AS Error_Message_ENG
					,N'JIG นี้อยู่ใน Stock !!'						AS Error_Message_THA
					,N' กรุณาสแกนออกจาก Stock หรือติดต่อ System'		AS Handling

			RETURN
		END

		BEGIN TRY 

		IF (@Shot_name ='Kanagata')
		BEGIN
 
			IF SUBSTRING(@MCNo,1,2) <> 'MP' 
			BEGIN
				IF EXISTS (SELECT machine_id FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MCId and idx = 1) 
				BEGIN 
				 
					IF  EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs  WHERE machine_id = @MCId AND idx = 1 AND jig_id =  @JIG_ID)
					BEGIN
				 
				 	SET @MCOld = (SELECT machines.name FROM APCSProDB.trans.jigs 
							LEFT JOIN APCSProDB.trans.machine_jigs 
							ON machine_jigs.jig_id = jigs.id 
							LEFT JOIN APCSProDB.mc.machines 
							ON machines.id = machine_jigs.machine_id 
							WHERE jigs.id = @JIG_ID
						 )

							SELECT    'FALSE'																	AS Is_Pass
									, N'This JIG ('+ barcode + N') Is use on Machine ('+ @MCOld + N')!!'		AS Error_Message_ENG
									, N'JIG นี้ ('+ barcode + N') ถูกใช้งานอยู่ที่ Machine เครื่องนี้ ('+ @MCOld + N') !!'	AS Error_Message_THA
									, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'									AS Handling
							FROM APCSProDB.trans.machine_jigs  
							INNER JOIN APCSProDB.trans.jigs  
							ON jigs.id = machine_jigs.jig_id
							WHERE machine_id = @MCId AND idx = 1 AND jig_id =  @JIG_ID

							RETURN

					END 
					ELSE  
					BEGIN
  
						--//////////UPDATE JIG NEW
						UPDATE APCSProDB.trans.jigs 
						SET   [status]		= 'On Machine'
							, [jig_state]	= 12
							, updated_at	= GETDATE()
							, updated_by	= @OPID 
						WHERE id			= @JIG_ID 
						OR root_jig_id		= @JIG_ID
 
						--//////////Insert JIG Record On Machine
						INSERT INTO APCSProDB.trans.jig_records 
						(	
							  [day_id]
							, [record_at]
							, [jig_id]
							, [jig_production_id]
							, [location_id]
							, [created_at]
							, [created_by]
							, [operated_by]
							, transaction_type
							, mc_no
							, record_class
						) 
						VALUES 
						(
							  (SELECT id FROM APCSProDB.trans.days WHERE date_value =  CONVERT(DATE,GETDATE(),111))
							, GETDATE()
							, @JIG_ID
							, @jig_production_id
							, NULL
							, GETDATE()
							, @OPID
							, @OPNo
							, 'On Machine'
							, @MCNo
							, 12
						)
						 
							SELECT  TOP 1    'TRUE'											AS Is_Pass		
											, ''												AS Error_Message_ENG
											, N''												AS Error_Message_THA
											, N''												AS Handling
											, @QRCode											AS QRCode
											, @Smallcode										AS Smallcode
											, @Type												AS [Type]
											, ISNULL(@QTY,0)									AS QTY
											, CONVERT(INT,max_lifetime.[LifeTime])				AS Life_Time
											, max_lifetime.expiration_value						AS STD_Life_Time			
											, @JIG_ID											AS jig_id
											, ISNULL(max_lifetime.LifeTime_Percen,0)			AS LifeTime_Percen
											, ISNULL(max_lifetime.periodcheck_value	,0)			AS  periodcheck_value
											, ISNULL(max_lifetime.period_value	,0)				AS  period_value
								FROM  
									(	SELECT		  warn_value AS warn_value
													, APCSProDB.trans.jig_conditions.value   AS [LifeTime]
													, FORMAT(COALESCE((CAST(jig_conditions.value AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
													, jigs.smallcode
													, productions.name		AS [Type]
													, jigs.id				AS jig_id 
													, production_counters.alarm_value AS expiration_value
													, production_counters.period_value
													, jig_conditions.periodcheck_value
										FROM APCSProDB.trans.jigs 
										INNER JOIN APCSProDB.trans.jig_conditions 
										ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id  
										INNER JOIN APCSProDB.jig.productions 
										ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
										INNER JOIN APCSProDB.jig.production_counters 
										on production_counters.production_id = productions.id
										WHERE jigs.id <> @JIG_ID AND root_jig_id = @JIG_ID
									 )  AS max_lifetime
									ORDER BY max_lifetime.LifeTime_Percen DESC  

							RETURN
						END
					 
				END
				ELSE  BEGIN
					--//////////UPDATE JIG NEW
				INSERT INTO APCSProDB.trans.machine_jigs 
			(		  machine_id
					, idx
					, jig_group_id
					, jig_id
					, created_at
					, created_by
			) 
			VALUES 
			(		  @MCId
					, 1
					, 1
					, @JIG_ID
					, GETDATE()
					, @OPID
			)

			UPDATE	  [APCSProDB].[trans].[jigs]
			SET		  [status]		= 'On Machine'
					, [jig_state]	= 12
					, [updated_at]	= GETDATE()
					, [updated_by]	= @OPID
			WHERE	  id			= @JIG_ID

			INSERT INTO APCSProDB.trans.jig_records 
			(		  [day_id]
					, [record_at]
					, [jig_id]
					, [jig_production_id]
					, [created_at]
					, [created_by]
					, [operated_by]
					, transaction_type
					, mc_no
					, record_class
			) 
			VALUES
			(
					  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
					, GETDATE()
					, @JIG_ID
					, @jig_production_id
					, GETDATE()
					, @OPID
					, @OPNo
					, 'On Machine'
					, @MCNo
					, 12
			)


							SELECT  TOP 1    'TRUE'											AS Is_Pass		
											, ''												AS Error_Message_ENG
											, N''												AS Error_Message_THA
											, N''												AS Handling
											, @QRCode											AS QRCode
											, @Smallcode										AS Smallcode
											, @Type												AS [Type]
											, ISNULL(@QTY,0)									AS QTY
											, CONVERT(INT,max_lifetime.[LifeTime])				AS Life_Time
											, max_lifetime.expiration_value						AS STD_Life_Time			
											, @JIG_ID											AS jig_id
											, ISNULL(max_lifetime.LifeTime_Percen,0)			AS LifeTime_Percen
											, ISNULL(max_lifetime.periodcheck_value	,0)			AS  periodcheck_value
											, ISNULL(max_lifetime.period_value	,0)				AS  period_value
								FROM  
									(	SELECT		  warn_value AS warn_value
													, APCSProDB.trans.jig_conditions.value   AS [LifeTime]
													, FORMAT(COALESCE((CAST(jig_conditions.value AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
													, jigs.smallcode
													, productions.name		AS [Type]
													, jigs.id				AS jig_id 
													, production_counters.alarm_value AS expiration_value
													, production_counters.period_value
													, jig_conditions.periodcheck_value
										FROM APCSProDB.trans.jigs 
										INNER JOIN APCSProDB.trans.jig_conditions 
										ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id  
										INNER JOIN APCSProDB.jig.productions 
										ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
										INNER JOIN APCSProDB.jig.production_counters 
										on production_counters.production_id = productions.id
										WHERE jigs.id <> @JIG_ID AND root_jig_id = @JIG_ID
									 )  AS max_lifetime
									ORDER BY max_lifetime.LifeTime_Percen DESC  
									RETURN


				END
				 
			END
			ELSE 
			BEGIN
			--/////////////////// Mold Setup Kanagata On machine
			SET  @idx   = 1 
 
				WHILE @idx <= 4 
				BEGIN
					IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MCId AND idx = @idx) 
					BEGIN

						--//////////UPDATE JIG NEW
						UPDATE    APCSProDB.trans.jigs 
						SET		  location_id		= NULL
								, status			= 'On Machine'
								, [jig_state]		= 12
								, updated_at		= GETDATE()
								, updated_by		= @OPID 
						WHERE   id					= @JIG_ID

						INSERT INTO APCSProDB.trans.machine_jigs 
						(		  machine_id
								, idx
								, jig_id
								, created_at
								, created_by
						) 
						VALUES 
						(
								  @MCId
								, @idx
								, @JIG_ID
								, GETDATE()
								, @OPID
						)

						--//////////Insert JIG Record On Machine
						INSERT INTO APCSProDB.trans.jig_records 
						(		  
									[day_id]
								, [record_at]
								, [jig_id]
								, [jig_production_id]
								, [location_id]
								, [created_at]
								, [created_by]
								, [operated_by]
								, transaction_type
								, mc_no
								, record_class
						) 
						VALUES (
									(SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
								, GETDATE()
								, @JIG_ID
								, @jig_production_id
								, NULL
								,  GETDATE()
								,  @OPID
								,  @OPNo
								, 'On Machine'
								, @MCNo
								, 12
						)
							 

						--/////////////// RETURN DATA
						SELECT  TOP 1    'TRUE'											AS Is_Pass		
											, ''												AS Error_Message_ENG
											, N''												AS Error_Message_THA
											, N''												AS Handling
											, @QRCode											AS QRCode
											, @Smallcode										AS Smallcode
											, @Type												AS [Type]
											, ISNULL(@QTY,0)									AS QTY
											, CONVERT(INT,max_lifetime.[LifeTime])				AS Life_Time
											, max_lifetime.expiration_value						AS STD_Life_Time			
											, @JIG_ID											AS jig_id
											, ISNULL(max_lifetime.LifeTime_Percen,0)			AS LifeTime_Percen
											, ISNULL(max_lifetime.periodcheck_value	,0)			AS  periodcheck_value
											, ISNULL(max_lifetime.period_value	,0)				AS  period_value
								FROM  
									(	SELECT		  warn_value AS warn_value
													, APCSProDB.trans.jig_conditions.value   AS [LifeTime]
													, FORMAT(COALESCE((CAST(jig_conditions.value AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
													, jigs.smallcode
													, productions.name		AS [Type]
													, jigs.id				AS jig_id 
													, production_counters.alarm_value AS expiration_value
													, production_counters.period_value
													, jig_conditions.periodcheck_value
										FROM APCSProDB.trans.jigs 
										INNER JOIN APCSProDB.trans.jig_conditions 
										ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id  
										INNER JOIN APCSProDB.jig.productions 
										ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
										INNER JOIN APCSProDB.jig.production_counters 
										on production_counters.production_id = productions.id
										WHERE jigs.id <> @JIG_ID AND root_jig_id = @JIG_ID
									 )  AS max_lifetime
									ORDER BY max_lifetime.LifeTime_Percen DESC  
						 
						RETURN
					END

					SET	@idx = @idx + 1
				END

				IF NOT EXISTS(SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE jig_id = @JIG_ID) 
				BEGIN

					SELECT    'FALSE'													AS Is_Pass
							, 'Update Failed. Can not update Kanagata to machine !!'	AS Error_Message_ENG
							, N'อัพเดทผิดพลาด Kanagata ยังไม่ถูกนำเข้าในเครื่องจักร !!'				AS Error_Message_THA
							, N'กรุณาเบิก หรือตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'			AS Handling
					RETURN

				END
			END

			--END 
		END

		SET @MCId = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)

		IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MCId AND idx = 1)
		BEGIN
			--create new
			INSERT INTO APCSProDB.trans.machine_jigs 
			(		  machine_id
					, idx
					, jig_group_id
					, jig_id
					, created_at
					, created_by
			) 
			VALUES 
			(		  @MCId
					, 1
					, 1
					, @JIG_ID
					, GETDATE()
					, @OPID
			)

			UPDATE	  [APCSProDB].[trans].[jigs]
			SET		  [status]		= 'On Machine'
					, [jig_state]	= 12
					, [updated_at]	= GETDATE()
					, [updated_by]	= @OPID
			WHERE	  id			= @JIG_ID

			INSERT INTO APCSProDB.trans.jig_records 
			(		  [day_id]
					, [record_at]
					, [jig_id]
					, [jig_production_id]
					, [created_at]
					, [created_by]
					, [operated_by]
					, transaction_type
					, mc_no
					, record_class
			) 
			VALUES
			(
					  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
					, GETDATE()
					, @JIG_ID
					, @jig_production_id
					, GETDATE()
					, @OPID
					, @OPNo
					, 'On Machine'
					, @MCNo
					, 12
			)
		

							SELECT   'TRUE'								AS Is_Pass
								, N''								AS Error_Message_ENG
								, N''								AS Error_Message_THA
								, N''								AS Handling
								, @QRCode							AS QRCode
								, smallcode							AS Smallcode
								, productions.name					AS [Type]
								, 0									AS QTY
								, CAST(jig_conditions.value AS INT) AS Life_Time
								, CAST(ISNULL(productions.expiration_value , production_counters.alarm_value) AS INT)		AS STD_Life_Time
								, jigs.id							AS jig_id
								, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
								, @periodcheck_value								AS  periodcheck_value
								, ISNULL(production_counters.period_value,0)		AS  period_value		 
						FROM APCSProDB.trans.jigs  
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON jigs.id = jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions 
						ON productions.id = jigs.jig_production_id 
						INNER JOIN APCSProDB.jig.production_counters 
						ON production_counters.production_id = productions.id 
						WHERE jigs.id = @JIG_ID
						
						RETURN

		END

		IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MCId AND idx = 2)
		BEGIN
		
			--create new
			INSERT INTO APCSProDB.trans.machine_jigs 
			(		  machine_id
					, idx
					, jig_group_id
					, jig_id
					, created_at
					, created_by
			) 
			VALUES 
			(		  @MCId
					, 2
					, 1
					, @JIG_ID
					, GETDATE()
					, @OPID
			)

			UPDATE	  [APCSProDB].[trans].[jigs]
			SET		  [status]		= 'On Machine'
					, [jig_state]	= 12
					, [updated_at]	= GETDATE()
					, [updated_by]	= @OPID
			WHERE id = @JIG_ID

			INSERT INTO APCSProDB.trans.jig_records 
			(		  [day_id]
					, [record_at]
					, [jig_id]
					, [jig_production_id]
					, [created_at]
					, [created_by]
					, [operated_by]
					, transaction_type
					, mc_no
					, record_class
			) 
			values
			(		  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
					, GETDATE()
					, @JIG_ID
					, @jig_production_id
					, GETDATE()
					, @OPID
					, @OPNo
					, 'On Machine'
					, @MCNo
					, 12
			)

							SELECT   'TRUE'								AS Is_Pass
								, N''								AS Error_Message_ENG
								, N''								AS Error_Message_THA
								, N''								AS Handling
								, @QRCode							AS QRCode
								, smallcode							AS Smallcode
								, productions.name					AS [Type]
								, 0									AS QTY
								, CAST(jig_conditions.value AS INT) AS Life_Time
								, CAST(ISNULL(productions.expiration_value , production_counters.alarm_value) AS INT)		AS STD_Life_Time
								, jigs.id							AS jig_id
								, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
								, @periodcheck_value								AS  periodcheck_value
								, ISNULL(production_counters.period_value,0)		AS  period_value		 
						FROM APCSProDB.trans.jigs  
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON jigs.id = jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions 
						ON productions.id = jigs.jig_production_id 
						INNER JOIN APCSProDB.jig.production_counters 
						ON production_counters.production_id = productions.id 
						WHERE jigs.id = @JIG_ID
								
								RETURN

		END


	 
 		END TRY
		BEGIN CATCH 

			SELECT	  'FALSE'				AS Is_Pass 
					, ERROR_MESSAGE()		AS Error_Message_ENG
					, N'บันทึกข้อมูลผิดพลาด !!'	AS Error_Message_THA
					, N'กรุณาติดต่อ System'	AS Handling
			RETURN

		END CATCH

	END
	ELSE 
	BEGIN  IF NOT EXISTS ( 	SELECT TOP 1 jig_sets.id 
							FROM 
								(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id 
										ELSE device_flows.jig_set_id   END  AS jig_set_id  
										,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
										ELSE device_flows.act_process_id   END  AS act_process_id 
										,lots.lot_no
							FROM APCSProDB.trans.lots  
							INNER JOIN APCSProDB.method.device_flows
							ON lots.device_slip_id = device_flows.device_slip_id
							AND  device_flows.step_no =  lots.step_no
							LEFT JOIN [APCSProDB].[trans].[special_flows] 
							ON [special_flows].lot_id = lots.id 
							AND [special_flows].id	  = lots.special_flow_id
							AND lots.is_special_flow  = 1
							LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
							ON [special_flows].id = [lot_special_flows].special_flow_id
							AND [lot_special_flows].step_no =  [special_flows].step_no
							WHERE lots.lot_no	= @LOTNO)   AS sp_jig
						INNER JOIN APCSProDB.method.jig_sets 
						ON  jig_sets.process_id = sp_jig.act_process_id
						AND jig_sets.id = sp_jig.jig_set_id
						INNER JOIN APCSProDB.method.jig_set_list
						ON jig_sets.id =  jig_set_list.jig_set_id
						INNER JOIN APCSProDB.jig.productions
						ON productions.id = jig_set_list.jig_group_id
						INNER JOIN APCSProDB.trans.jigs
						ON productions.id				= jigs.jig_production_id
						WHERE  (jig_sets.code 	= @Recipe OR @Recipe IS NULL)
						AND (jigs.id   = @JIG_ID  )
						AND  jig_sets.id IS NOT NULL 
				   )
	BEGIN 


		IF EXISTS ( SELECT name FROM APCSProDB.method.packages  WHERE short_name = @Recipe)
		BEGIN 
			SET @Recipe =  ( SELECT name FROM APCSProDB.method.packages  WHERE short_name = @Recipe)
		END

	IF  EXISTS (	SELECT TOP 1 jig_sets.id 
						FROM 
							(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id 
									ELSE device_flows.jig_set_id   END  AS jig_set_id  
									,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
									ELSE device_flows.act_process_id   END  AS act_process_id 
									,lots.lot_no
						FROM APCSProDB.trans.lots  
						INNER JOIN APCSProDB.method.device_flows
						ON lots.device_slip_id = device_flows.device_slip_id
						AND  device_flows.step_no =  lots.step_no
						LEFT JOIN [APCSProDB].[trans].[special_flows] 
						ON [special_flows].lot_id = lots.id 
						AND [special_flows].id	  = lots.special_flow_id
						AND lots.is_special_flow  = 1
						LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
						ON [special_flows].id = [lot_special_flows].special_flow_id
						AND [lot_special_flows].step_no =  [special_flows].step_no
						WHERE lots.lot_no	= @LOTNO)   AS sp_jig
						INNER JOIN APCSProDB.method.jig_sets 
						ON  jig_sets.process_id = sp_jig.act_process_id
						AND jig_sets.id = sp_jig.jig_set_id
						INNER JOIN APCSProDB.method.jig_set_list
						ON jig_sets.id =  jig_set_list.jig_set_id
						INNER JOIN APCSProDB.jig.productions
						ON productions.id = jig_set_list.jig_group_id
						INNER JOIN APCSProDB.trans.jigs
						ON productions.id				= jigs.jig_production_id
						WHERE   (jig_sets.[name] 	= @Recipe OR @Recipe IS NULL)
						AND	 (jigs.id   = @JIG_ID  )
						AND  jig_sets.id IS NOT NULL )

		BEGIN

		IF (@Shot_name ='Kanagata')
		BEGIN
		 
				IF SUBSTRING(@MCNo,1,2) <> 'MP' 
				BEGIN
		
					IF EXISTS (SELECT machine_id FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MCId and idx = 1) 
					BEGIN
					  		 
						IF  EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs  WHERE machine_id = @MCId AND idx = 1 AND jig_id =  @JIG_ID)
						BEGIN
				 		 
						SET @MCOld = ( SELECT machines.name FROM APCSProDB.trans.jigs 
										LEFT JOIN APCSProDB.trans.machine_jigs 
										ON machine_jigs.jig_id = jigs.id 
										LEFT JOIN APCSProDB.mc.machines 
										ON machines.id = machine_jigs.machine_id 
										WHERE jigs.id = @JIG_ID)

							SELECT  TOP 1    'TRUE'											AS Is_Pass		
											, ''												AS Error_Message_ENG
											, N''												AS Error_Message_THA
											, N''												AS Handling
											, @QRCode											AS QRCode
											, @Smallcode										AS Smallcode
											, @Type												AS [Type]
											, ISNULL(@QTY,0)									AS QTY
											, CONVERT(INT,max_lifetime.[LifeTime])				AS Life_Time
											, max_lifetime.expiration_value						AS STD_Life_Time			
											, @JIG_ID											AS jig_id
											, ISNULL(max_lifetime.LifeTime_Percen,0)			AS LifeTime_Percen
											, ISNULL(max_lifetime.periodcheck_value	,0)			AS  periodcheck_value
											, ISNULL(max_lifetime.period_value	,0)				AS  period_value
								FROM  
									(	SELECT		  warn_value AS warn_value
													, APCSProDB.trans.jig_conditions.value   AS [LifeTime]
													, FORMAT(COALESCE((CAST(jig_conditions.value AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
													, jigs.smallcode
													, productions.name		AS [Type]
													, jigs.id				AS jig_id 
													, production_counters.alarm_value AS expiration_value
													, production_counters.period_value
													, jig_conditions.periodcheck_value
										FROM APCSProDB.trans.jigs 
										INNER JOIN APCSProDB.trans.jig_conditions 
										ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id  
										INNER JOIN APCSProDB.jig.productions 
										ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
										INNER JOIN APCSProDB.jig.production_counters 
										on production_counters.production_id = productions.id
										WHERE jigs.id <> @JIG_ID AND root_jig_id = @JIG_ID
									 )  AS max_lifetime
									ORDER BY max_lifetime.LifeTime_Percen DESC  

							RETURN

						END 
						ELSE  
						BEGIN

								SET @JIG_OLD =	(SELECT jig_id   FROM APCSProDB.trans.machine_jigs where machine_id = @MC_ID and idx = 1 )

								UPDATE APCSProDB.trans.jigs 
								set   [status]		= 'To Machine'
									, [jig_state]	= 11
									, updated_at	= GETDATE()
									, updated_by	= @OPID 
								WHERE	id = @JIG_OLD OR root_jig_id = @JIG_OLD
								 
								--//////////UPDATE JIG NEW
								UPDATE APCSProDB.trans.jigs 
								SET   location_id	= NULL
									, [status]		= 'On Machine'
									, [jig_state]	= 12
									, updated_at	= GETDATE()
									, updated_by	= @OPID 
								WHERE id			= @JIG_ID 
								OR root_jig_id		= @JIG_ID

 								--create new
								UPDATE APCSProDB.trans.machine_jigs 
								SET  jig_id = @JIG_ID
									,updated_at = GETDATE()
									,updated_by = @OPID 
								WHERE machine_id = @MC_ID and idx = 1 

								--//////////Insert JIG Record On Machine
								INSERT INTO APCSProDB.trans.jig_records 
								(	
									  [day_id]
									, [record_at]
									, [jig_id]
									, [jig_production_id]
									, [location_id]
									, [created_at]
									, [created_by]
									, [operated_by]
									, transaction_type
									, mc_no
									, record_class
								) 
								VALUES 
								(
									  (SELECT id FROM APCSProDB.trans.days WHERE date_value =  CONVERT(DATE,GETDATE(),111))
									, GETDATE()
									, @JIG_ID
									, @jig_production_id
									, NULL
									, GETDATE()
									, @OPID
									, @OPNo
									, 'On Machine'
									, @MCNo
									, 12
								)
						 
									
								SELECT  TOP 1    'TRUE'											AS Is_Pass		
											, ''												AS Error_Message_ENG
											, N''												AS Error_Message_THA
											, N''												AS Handling
											, @QRCode											AS QRCode
											, @Smallcode										AS Smallcode
											, @Type												AS [Type]
											, ISNULL(@QTY,0)									AS QTY
											, CONVERT(INT,max_lifetime.[LifeTime])				AS Life_Time
											, max_lifetime.expiration_value						AS STD_Life_Time			
											, @JIG_ID											AS jig_id
											, ISNULL(max_lifetime.LifeTime_Percen,0)			AS LifeTime_Percen
											, ISNULL(max_lifetime.periodcheck_value	,0)			AS  periodcheck_value
											, ISNULL(max_lifetime.period_value	,0)				AS  period_value
								FROM  
									(	SELECT		  warn_value AS warn_value
													, APCSProDB.trans.jig_conditions.value   AS [LifeTime]
													, FORMAT(COALESCE((CAST(jig_conditions.value AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
													, jigs.smallcode
													, productions.name		AS [Type]
													, jigs.id				AS jig_id 
													, production_counters.alarm_value AS expiration_value
													, production_counters.period_value
													, jig_conditions.periodcheck_value
										FROM APCSProDB.trans.jigs 
										INNER JOIN APCSProDB.trans.jig_conditions 
										ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id  
										INNER JOIN APCSProDB.jig.productions 
										ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
										INNER JOIN APCSProDB.jig.production_counters 
										on production_counters.production_id = productions.id
										WHERE jigs.id <> @JIG_ID AND root_jig_id = @JIG_ID
									 )  AS max_lifetime
									ORDER BY max_lifetime.LifeTime_Percen DESC  

								RETURN
						END
					END
					ELSE
					BEGIN

						UPDATE APCSProDB.trans.jigs 
						SET	  location_id = NULL
							, [status] = 'On Machine'
							, [jig_state] = 12
							, updated_at = GETDATE()
							, updated_by = @OPID 
						WHERE id = @JIG_ID OR root_jig_id = @JIG_ID

						INSERT INTO APCSProDB.trans.machine_jigs 
						(	  machine_id
							, idx
							, jig_id
							, created_at
							, created_by
						) 
						VALUES 
						(	  @MC_ID
							, 1
							, @JIG_ID
							, GETDATE()
							, @OPID
						)
						 
						INSERT INTO APCSProDB.trans.jig_records 
						(	 
							  [day_id]
							, [record_at]
							, [jig_id]
							, [jig_production_id]
							, [location_id]
							, [created_at]
							, [created_by]
							, [operated_by]
							, transaction_type
							, mc_no
							, record_class
						) 
						VALUES 
						(
							  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
							, GETDATE()
							, @JIG_ID
							, @jig_production_id
							, NULL
							, GETDATE()
							, @OPID
							, @OPNo
							, 'On Machine'
							, @MCNo
							, 12
						)
					END
				END
				ELSE 
				BEGIN

					 
					--/////////////////// Mold Setup Kanagata On machine
					SET  @idx   = 1 
			  
						WHILE @idx <= 4 
						BEGIN
							IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MCId AND idx = @idx) 
							BEGIN
							 
								--//////////UPDATE JIG NEW
								UPDATE    APCSProDB.trans.jigs 
								SET		  location_id		= NULL
										, status			= 'On Machine'
										, [jig_state]		= 12
										, updated_at		= GETDATE()
										, updated_by		= @OPID 
								WHERE   id					= @JIG_ID

								INSERT INTO APCSProDB.trans.machine_jigs 
								(		  machine_id
										, idx
										, jig_id
										, created_at
										, created_by
								) 
								VALUES 
								(
											@MCId
										, @idx
										, @JIG_ID
										, GETDATE()
										, @OPID
								)

								--//////////Insert JIG Record On Machine
								INSERT INTO APCSProDB.trans.jig_records 
								(		  
											[day_id]
										, [record_at]
										, [jig_id]
										, [jig_production_id]
										, [location_id]
										, [created_at]
										, [created_by]
										, [operated_by]
										, transaction_type
										, mc_no
										, record_class
								) 
								VALUES (
											(SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
										, GETDATE()
										, @JIG_ID
										, @jig_production_id
										, NULL
										,  GETDATE()
										,  @OPID
										,  @OPNo
										, 'On Machine'
										, @MCNo
										, 12
								)
							  
								
							SELECT  TOP 1    'TRUE'											AS Is_Pass		
											, ''												AS Error_Message_ENG
											, N''												AS Error_Message_THA
											, N''												AS Handling
											, @QRCode											AS QRCode
											, @Smallcode										AS Smallcode
											, @Type												AS [Type]
											, ISNULL(@QTY,0)									AS QTY
											, CONVERT(INT,max_lifetime.[LifeTime])				AS Life_Time
											, max_lifetime.expiration_value						AS STD_Life_Time			
											, @JIG_ID											AS jig_id
											, ISNULL(max_lifetime.LifeTime_Percen,0)			AS LifeTime_Percen
											, ISNULL(max_lifetime.periodcheck_value	,0)			AS  periodcheck_value
											, ISNULL(max_lifetime.period_value	,0)				AS  period_value
								FROM  
									(	SELECT		  warn_value AS warn_value
													, APCSProDB.trans.jig_conditions.value   AS [LifeTime]
													, FORMAT(COALESCE((CAST(jig_conditions.value AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
													, jigs.smallcode
													, productions.name		AS [Type]
													, jigs.id				AS jig_id 
													, production_counters.alarm_value AS expiration_value
													, production_counters.period_value
													, jig_conditions.periodcheck_value
										FROM APCSProDB.trans.jigs 
										INNER JOIN APCSProDB.trans.jig_conditions 
										ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id  
										INNER JOIN APCSProDB.jig.productions 
										ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
										INNER JOIN APCSProDB.jig.production_counters 
										on production_counters.production_id = productions.id
										WHERE jigs.id <> @JIG_ID AND root_jig_id = @JIG_ID
									 )  AS max_lifetime
									ORDER BY max_lifetime.LifeTime_Percen DESC  
						 
								RETURN
							END

							SET	@idx = @idx + 1
						END

						IF NOT EXISTS(SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE jig_id = @JIG_ID) 
						BEGIN

							SELECT    'FALSE'													AS Is_Pass
									, 'Update Failed. Can not update Kanagata to machine !!'	AS Error_Message_ENG
									, N'อัพเดทผิดพลาด Kanagata ยังไม่ถูกนำเข้าในเครื่องจักร !!'				AS Error_Message_THA
									, N'กรุณาเบิก หรือตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'			AS Handling
							RETURN

						END
					END
				END
			 
		END
		ELSE
		BEGIN

			SELECT  'FALSE' AS Is_Pass
					,'Device slips this jig has not been registered yet !!' AS Error_Message_ENG
					,N'Device slips นี้ยังไม่ถูกลงทะเบียน jig !!' AS Error_Message_THA
					,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
			RETURN	
		END
			
	END 
 
	ELSE
	BEGIN 

 
		-- CHECK JIG REGIST
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
			SELECT    'FALSE' AS Is_Pass 
					, 'Machine Number is invalid !!' AS Error_Message_ENG
					, N'Machine Number ไม่ถูกต้อง !!' AS Error_Message_THA
					, N' กรุณาตรวจสอบ หรือติดต่อ System' AS Handling

			RETURN
		END


		IF ( @State =  12) --On Machine
		BEGIN  
		 
			SET @MCOld = (SELECT machines.name FROM APCSProDB.trans.jigs 
							LEFT JOIN APCSProDB.trans.machine_jigs 
							ON machine_jigs.jig_id = jigs.id 
							LEFT JOIN APCSProDB.mc.machines 
							ON machines.id = machine_jigs.machine_id 
							WHERE jigs.id = @JIG_ID
						 )

			IF @MCOld <> @MCNo 
			BEGIN

				SELECT    'FALSE'														AS Is_Pass
						, N'This JIG ('+ @Smallcode + N') Is use on another Machine ('+ @MCOld + N')!!' AS Error_Message_ENG
						, N'JIG นี้ ('+ @Smallcode + N') ถูกใช้งานอยู่ที่ Machine เครื่องอื่น ('+ @MCOld + N') !!'	AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'						AS Handling
				RETURN

			END
			ELSE 
			BEGIN

					SELECT    'TRUE'											AS Is_Pass 
							, 'Success !!'										AS Error_Message_ENG
							, N'บันทึกเรียบร้อย !!'									AS Error_Message_THA
							, ''												AS Handling
							, @QRCode											AS QRCode
							, smallcode											AS Smallcode
							, productions.name									AS [Type] 
							, ISNULL(jig_set_list.use_qty,0)					AS QTY
							, CONVERT(int,jig_conditions.value)					AS Life_Time
							, CONVERT(int,production_counters.alarm_value)		AS STD_Life_Time
							, jigs.id											AS jig_id 	
							, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
							, @periodcheck_value								AS  periodcheck_value
							, @period_value										AS  period_value	
					FROM APCSProDB.trans.lots
					INNER JOIN APCSProDB.method.device_flows
					ON lots.device_slip_id = device_flows.device_slip_id
					AND  device_flows.step_no = lots.step_no
					INNER JOIN APCSProDB.method.jig_sets 
					ON  jig_sets.process_id = device_flows.act_process_id
					AND device_flows.jig_set_id = jig_sets.id
					INNER JOIN APCSProDB.method.jig_set_list
					ON jig_sets.id =  jig_set_list.jig_set_id
					INNER JOIN APCSProDB.jig.productions
					ON productions.id = jig_set_list.jig_group_id
					INNER JOIN [APCSProDB].[jig].[production_counters] 
					ON production_counters.production_id = productions.id 
					INNER JOIN  APCSProDB.trans.jigs  
					ON productions.id	= jigs.jig_production_id
					INNER JOIN APCSProDB.trans.jig_conditions 
					ON jig_conditions.id						= jigs.id
					WHERE lots.lot_no				= @LOTNO
					AND (jig_sets.code 	= @Recipe OR @Recipe IS NULL)
					AND  jigs.id					= @JIG_ID 
					AND ( jig_sets.is_disable		= 0 )

				RETURN
			END
			 
		END

		IF ( @State <>  11) --To Machine
		BEGIN	
			SELECT  'FALSE'										AS Is_Pass 
					,N'JIG is in stock !!'						AS Error_Message_ENG
					,N'JIG นี้อยู่ใน Stock !!'						AS Error_Message_THA
					,N' กรุณาสแกนออกจาก Stock หรือติดต่อ System'		AS Handling

			RETURN
		END
		 
		BEGIN TRY 
		IF (@Shot_name = 'Dicer Blade')
		BEGIN
			SET @MCId = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)

				IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MCId AND idx = 1)
				BEGIN
					--create new
					INSERT INTO APCSProDB.trans.machine_jigs 
					(		  machine_id
							, idx
							, jig_group_id
							, jig_id
							, created_at
							, created_by
					) 
					VALUES 
					(		  @MCId
							, 1
							, 1
							, @JIG_ID
							, GETDATE()
							, @OPID
					)

					UPDATE	  [APCSProDB].[trans].[jigs]
					SET		  [status]		= 'On Machine'
							, [jig_state]	= 12
							, [updated_at]	= GETDATE()
							, [updated_by]	= @OPID
					WHERE	  id			= @JIG_ID

					INSERT INTO APCSProDB.trans.jig_records 
					(		  [day_id]
							, [record_at]
							, [jig_id]
							, [jig_production_id]
							, [created_at]
							, [created_by]
							, [operated_by]
							, transaction_type
							, mc_no
							, record_class
					) 
					VALUES
					(
							  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
							, GETDATE()
							, @JIG_ID
							, @jig_production_id
							, GETDATE()
							, @OPID
							, @OPNo
							, 'On Machine'
							, @MCNo
							, 12
					)

					SELECT    'TRUE'								AS Is_Pass 
							, 'Success !!'							AS Error_Message_ENG
							, N'บันทึกเรียบร้อย !!'						AS Error_Message_THA
							, ''									AS Handling
							, @QRCode								AS QRCode
							, smallcode								AS Smallcode
							, productions.name						AS [Type] 
							, ISNULL(jig_set_list.use_qty,0)					AS QTY
							, CONVERT(int,jig_conditions.value)					AS Life_Time
							, CONVERT(int,production_counters.alarm_value)			AS STD_Life_Time
							, jigs.id								AS jig_id 		
							, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
							, @periodcheck_value								AS  periodcheck_value
							, @period_value										AS  period_value
					FROM 
						(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id 
								ELSE device_flows.jig_set_id   END  AS jig_set_id  
								,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
								ELSE device_flows.act_process_id   END  AS act_process_id 
								,lots.lot_no
					FROM APCSProDB.trans.lots  
					INNER JOIN APCSProDB.method.device_flows
					ON lots.device_slip_id = device_flows.device_slip_id
					AND  device_flows.step_no =  lots.step_no
					LEFT JOIN [APCSProDB].[trans].[special_flows] 
					ON [special_flows].lot_id = lots.id 
					AND [special_flows].id	  = lots.special_flow_id
					AND lots.is_special_flow  = 1
					LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
					ON [special_flows].id = [lot_special_flows].special_flow_id
					AND [lot_special_flows].step_no =  [special_flows].step_no
					WHERE lots.lot_no	= @LOTNO)   AS sp_jig
					INNER JOIN APCSProDB.method.jig_sets 
					ON  jig_sets.process_id = sp_jig.act_process_id
					AND sp_jig.jig_set_id = jig_sets.id
					INNER JOIN APCSProDB.method.jig_set_list
					ON jig_sets.id =  jig_set_list.jig_set_id
					INNER JOIN APCSProDB.jig.productions
					ON productions.id = jig_set_list.jig_group_id
					INNER JOIN [APCSProDB].[jig].[production_counters]  
					ON production_counters.production_id = productions.id 
					INNER JOIN  APCSProDB.trans.jigs  
					ON productions.id	= jigs.jig_production_id
					INNER JOIN APCSProDB.trans.jig_conditions  
					ON jig_conditions.id = jigs.id
					WHERE (jig_sets.code 				= @Recipe OR @Recipe IS NULL)
					AND  jigs.id					= @JIG_ID 
					AND ( jig_sets.is_disable		= 0 )

					RETURN
					 

				END

				IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MCId AND idx = 2)
				BEGIN
		
					--create new
					INSERT INTO APCSProDB.trans.machine_jigs 
					(		  machine_id
							, idx
							, jig_group_id
							, jig_id
							, created_at
							, created_by
					) 
					VALUES 
					(		  @MCId
							, 2
							, 1
							, @JIG_ID
							, GETDATE()
							, @OPID
					)

					UPDATE	  [APCSProDB].[trans].[jigs]
					SET		  [status]		= 'On Machine'
							, [jig_state]	= 12
							, [updated_at]	= GETDATE()
							, [updated_by]	= @OPID
					WHERE id = @JIG_ID

					INSERT INTO APCSProDB.trans.jig_records 
					(		  [day_id]
							, [record_at]
							, [jig_id]
							, [jig_production_id]
							, [created_at]
							, [created_by]
							, [operated_by]
							, transaction_type
							, mc_no
							, record_class
					) 
					values
					(		  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
							, GETDATE()
							, @JIG_ID
							, @jig_production_id
							, GETDATE()
							, @OPID
							, @OPNo
							, 'On Machine'
							, @MCNo
							, 12
					)

					
					SELECT    'TRUE'								AS Is_Pass 
							, 'Success !!'							AS Error_Message_ENG
							, N'บันทึกเรียบร้อย !!'						AS Error_Message_THA
							, ''									AS Handling
							, @QRCode								AS QRCode
							, smallcode								AS Smallcode
							, productions.name						AS [Type] 
							, ISNULL(jig_set_list.use_qty,0)					AS QTY
							, CONVERT(int,jig_conditions.value)					AS Life_Time
							, CONVERT(int,production_counters.alarm_value)			AS STD_Life_Time
							, jigs.id								AS jig_id 		
							, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
							, @periodcheck_value								AS  periodcheck_value
							, @period_value										AS  period_value
					FROM 
						(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id 
								ELSE device_flows.jig_set_id   END  AS jig_set_id  
								,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
								ELSE device_flows.act_process_id   END  AS act_process_id 
								,lots.lot_no
					FROM APCSProDB.trans.lots  
					INNER JOIN APCSProDB.method.device_flows
					ON lots.device_slip_id = device_flows.device_slip_id
					AND  device_flows.step_no =  lots.step_no
					LEFT JOIN [APCSProDB].[trans].[special_flows] 
					ON [special_flows].lot_id = lots.id 
					AND [special_flows].id	  = lots.special_flow_id
					AND lots.is_special_flow  = 1
					LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
					ON [special_flows].id = [lot_special_flows].special_flow_id
					AND [lot_special_flows].step_no =  [special_flows].step_no
					WHERE lots.lot_no	= @LOTNO)   AS sp_jig
					INNER JOIN APCSProDB.method.jig_sets 
					ON  jig_sets.process_id = sp_jig.act_process_id
					AND sp_jig.jig_set_id = jig_sets.id
					INNER JOIN APCSProDB.method.jig_set_list
					ON jig_sets.id =  jig_set_list.jig_set_id
					INNER JOIN APCSProDB.jig.productions
					ON productions.id = jig_set_list.jig_group_id
					INNER JOIN [APCSProDB].[jig].[production_counters]  
					ON production_counters.production_id = productions.id 
					INNER JOIN  APCSProDB.trans.jigs  
					ON productions.id	= jigs.jig_production_id
					INNER JOIN APCSProDB.trans.jig_conditions  
					ON jig_conditions.id = jigs.id
					WHERE  (jig_sets.code 				= @Recipe OR @Recipe IS NULL)
					AND  jigs.id					= @JIG_ID 
					AND ( jig_sets.is_disable		= 0 )


					RETURN
			END
		END 
		IF(@Shot_name = 'Wedge') --idx : 31,32
		BEGIN 
		SET @idx  = 31
	 
			WHILE @idx <= 32 
			BEGIN 

				IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs  WHERE machine_id = @MCId AND idx = @idx) 
				BEGIN
 
				--CREATE NEW
						INSERT INTO APCSProDB.trans.machine_jigs 
						(	  machine_id
							, idx
							, jig_group_id
							, jig_id
							, created_at
							, created_by
						) 
						VALUES 
						(
								@MCId
							, @idx 
							, 1
							, @JIG_ID
							, GETDATE()
							, @OPID
						)

						UPDATE [APCSProDB].[trans].[jigs]
						SET  [status]		= 'On Machine'
							,[jig_state]	= 12
							,[updated_at]	= GETDATE()
							,[updated_by]	= @OPID
						WHERE id			= @JIG_ID

						INSERT INTO APCSProDB.trans.jig_records 
						(		  [day_id]
								, [record_at]
								, [jig_id]
								, [jig_production_id]
								, [created_at]
								, [created_by]
								, [operated_by]
								, transaction_type
								, mc_no
								, record_class
						) 
						VALUES
						(		  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
								, GETDATE()
								, @JIG_ID
								, (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID)
								, GETDATE()
								, @OPID
								, @OPNo
								, 'On Machine'
								, @MCNo
								, 12
						)
					 
				
					SELECT    'TRUE'								AS Is_Pass 
							, 'Success !!'							AS Error_Message_ENG
							, N'บันทึกเรียบร้อย !!'						AS Error_Message_THA
							, ''									AS Handling
							, @QRCode								AS QRCode
							, smallcode								AS Smallcode
							, productions.name						AS [Type] 
							, ISNULL(jig_set_list.use_qty,0)					AS QTY
							, CONVERT(int,jig_conditions.value)					AS Life_Time
							, CONVERT(int,production_counters.alarm_value)			AS STD_Life_Time
							, jigs.id								AS jig_id 		
							, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
							, @periodcheck_value								AS  periodcheck_value
							, @period_value										AS  period_value
					FROM 
						(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id 
								ELSE device_flows.jig_set_id   END  AS jig_set_id  
								,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
								ELSE device_flows.act_process_id   END  AS act_process_id 
								,lots.lot_no
					FROM APCSProDB.trans.lots  
					INNER JOIN APCSProDB.method.device_flows
					ON lots.device_slip_id = device_flows.device_slip_id
					AND  device_flows.step_no =  lots.step_no
					LEFT JOIN [APCSProDB].[trans].[special_flows] 
					ON [special_flows].lot_id = lots.id 
					AND [special_flows].id	  = lots.special_flow_id
					AND lots.is_special_flow  = 1
					LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
					ON [special_flows].id = [lot_special_flows].special_flow_id
					AND [lot_special_flows].step_no =  [special_flows].step_no
					WHERE lots.lot_no	= @LOTNO)   AS sp_jig
					INNER JOIN APCSProDB.method.jig_sets 
					ON  jig_sets.process_id = sp_jig.act_process_id
					AND sp_jig.jig_set_id = jig_sets.id
					INNER JOIN APCSProDB.method.jig_set_list
					ON jig_sets.id =  jig_set_list.jig_set_id
					INNER JOIN APCSProDB.jig.productions
					ON productions.id = jig_set_list.jig_group_id
					INNER JOIN [APCSProDB].[jig].[production_counters]  
					ON production_counters.production_id = productions.id 
					INNER JOIN  APCSProDB.trans.jigs  
					ON productions.id	= jigs.jig_production_id
					INNER JOIN APCSProDB.trans.jig_conditions  
					ON jig_conditions.id = jigs.id
					WHERE  (jig_sets.code 			= @Recipe OR @Recipe IS NULL)
					AND  jigs.id					= @JIG_ID 
					AND ( jig_sets.is_disable		= 0 )


					RETURN
					 		
				END
				
				ELSE IF ((SELECT COUNT(jig_id) FROM APCSProDB.trans.machine_jigs  WHERE machine_id = @MCId AND idx IN (31, 32)) = 2 )
				BEGIN
				 
				SELECT  TOP 1  'FALSE'														AS Is_Pass
						, N'This JIG ('+ jigs.barcode + N') Is use on Machine ('+ machines.name + N')!!' AS Error_Message_ENG
						, N'JIG นี้ ('+ jigs.barcode + N') ถูกใช้งานอยู่ที่ Machine เครื่องนี้ ('+ machines.name + N') !!'	AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'						AS Handling
				FROM APCSProDB.trans.machine_jigs  
				INNER JOIN APCSProDB.trans.jigs  
				ON jigs.id = machine_jigs.jig_id
				INNER JOIN APCSProDB.mc.machines
				ON machines.id  =  machine_jigs.machine_id
				WHERE machine_id = @MCId AND idx = @idx  

				RETURN

				END 
				 
				SET	@idx = @idx + 1

			END
		END
		IF(@Shot_name = 'Wire')		--idx : 33,34
		BEGIN 

		SET @idx  = 33
	 
			WHILE @idx <= 34 
			BEGIN
 
				IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs  WHERE machine_id = @MCId AND idx = @idx) 
				BEGIN
				 
				
				--CREATE NEW
						INSERT INTO APCSProDB.trans.machine_jigs 
						(	  machine_id
							, idx
							, jig_group_id
							, jig_id
							, created_at
							, created_by
						) 
						VALUES 
						(
								@MCId
							, @idx 
							, 1
							, @JIG_ID
							, GETDATE()
							, @OPID
						)

						UPDATE [APCSProDB].[trans].[jigs]
						SET  [status]		= 'On Machine'
							,[jig_state]	= 12
							,[updated_at]	= GETDATE()
							,[updated_by]	= @OPID
						WHERE id			= @JIG_ID

						INSERT INTO APCSProDB.trans.jig_records 
						(		  [day_id]
								, [record_at]
								, [jig_id]
								, [jig_production_id]
								, [created_at]
								, [created_by]
								, [operated_by]
								, transaction_type
								, mc_no
								, record_class
						) 
						VALUES
						(		  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
								, GETDATE()
								, @JIG_ID
								, (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID)
								, GETDATE()
								, @OPID
								, @OPNo
								, 'On Machine'
								, @MCNo
								, 12
						)
				
					SELECT    'TRUE'								AS Is_Pass 
							, 'Success !!'							AS Error_Message_ENG
							, N'บันทึกเรียบร้อย !!'						AS Error_Message_THA
							, ''									AS Handling
							, @QRCode								AS QRCode
							, smallcode								AS Smallcode
							, productions.name						AS [Type] 
							, ISNULL(jig_set_list.use_qty,0)				AS QTY
							, CONVERT(int,jig_conditions.value)					AS Life_Time
							, CONVERT(int,production_counters.alarm_value)			AS STD_Life_Time
							, jigs.id								AS jig_id 		
							, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
							, @periodcheck_value								AS  periodcheck_value
							, @period_value										AS  period_value
					FROM 
						(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id 
								ELSE device_flows.jig_set_id   END  AS jig_set_id  
								,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
								ELSE device_flows.act_process_id   END  AS act_process_id 
								,lots.lot_no
					FROM APCSProDB.trans.lots  
					INNER JOIN APCSProDB.method.device_flows
					ON lots.device_slip_id = device_flows.device_slip_id
					AND  device_flows.step_no =  lots.step_no
					LEFT JOIN [APCSProDB].[trans].[special_flows] 
					ON [special_flows].lot_id = lots.id 
					AND [special_flows].id	  = lots.special_flow_id
					AND lots.is_special_flow  = 1
					LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
					ON [special_flows].id = [lot_special_flows].special_flow_id
					AND [lot_special_flows].step_no =  [special_flows].step_no
					WHERE lots.lot_no	= @LOTNO)   AS sp_jig
					INNER JOIN APCSProDB.method.jig_sets 
					ON  jig_sets.process_id = sp_jig.act_process_id
					AND sp_jig.jig_set_id = jig_sets.id
					INNER JOIN APCSProDB.method.jig_set_list
					ON jig_sets.id =  jig_set_list.jig_set_id
					INNER JOIN APCSProDB.jig.productions
					ON productions.id = jig_set_list.jig_group_id
					INNER JOIN [APCSProDB].[jig].[production_counters]  
					ON production_counters.production_id = productions.id 
					INNER JOIN  APCSProDB.trans.jigs  
					ON productions.id	= jigs.jig_production_id
					INNER JOIN APCSProDB.trans.jig_conditions  
					ON jig_conditions.id = jigs.id
					WHERE  (jig_sets.code 				= @Recipe OR @Recipe IS NULL)
					AND  jigs.id					= @JIG_ID 
					AND ( jig_sets.is_disable		= 0 )


					RETURN
					 		
				END
				ELSE IF ((SELECT COUNT(jig_id) FROM APCSProDB.trans.machine_jigs  WHERE machine_id = @MCId AND idx IN (33, 34)) = 2 )
				BEGIN
				 
				SELECT  TOP 1  'FALSE'														AS Is_Pass
						, N'This JIG ('+ jigs.barcode + N') Is use on Machine ('+ machines.name + N')!!' AS Error_Message_ENG
						, N'JIG นี้ ('+ jigs.barcode + N') ถูกใช้งานอยู่ที่ Machine เครื่องนี้ ('+ machines.name + N') !!'	AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'						AS Handling
				FROM APCSProDB.trans.machine_jigs  
				INNER JOIN APCSProDB.trans.jigs  
				ON jigs.id = machine_jigs.jig_id
				INNER JOIN APCSProDB.mc.machines
				ON machines.id  =  machine_jigs.machine_id
				WHERE machine_id = @MCId AND idx = @idx  

				RETURN

				END 
			
				SET	@idx = @idx + 1

			END
		END
		IF(@Shot_name = 'Cutter') --idx : 35,36
		BEGIN 
		SET @idx  = 35
	 
			WHILE @idx <= 36 
			BEGIN

				IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs  WHERE machine_id = @MCId AND idx = @idx) 
				BEGIN
				--CREATE NEW
						INSERT INTO APCSProDB.trans.machine_jigs 
						(	  machine_id
							, idx
							, jig_group_id
							, jig_id
							, created_at
							, created_by
						) 
						VALUES 
						(
								@MCId
							, @idx 
							, 1
							, @JIG_ID
							, GETDATE()
							, @OPID
						)

						UPDATE [APCSProDB].[trans].[jigs]
						SET  [status]		= 'On Machine'
							,[jig_state]	= 12
							,[updated_at]	= GETDATE()
							,[updated_by]	= @OPID
						WHERE id			= @JIG_ID

						INSERT INTO APCSProDB.trans.jig_records 
						(		  [day_id]
								, [record_at]
								, [jig_id]
								, [jig_production_id]
								, [created_at]
								, [created_by]
								, [operated_by]
								, transaction_type
								, mc_no
								, record_class
						) 
						VALUES
						(		  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
								, GETDATE()
								, @JIG_ID
								, (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID)
								, GETDATE()
								, @OPID
								, @OPNo
								, 'On Machine'
								, @MCNo
								, 12
						)
					 
					
					SELECT    'TRUE'								AS Is_Pass 
							, 'Success !!'							AS Error_Message_ENG
							, N'บันทึกเรียบร้อย !!'						AS Error_Message_THA
							, ''									AS Handling
							, @QRCode								AS QRCode
							, smallcode								AS Smallcode
							, productions.name						AS [Type] 
							, ISNULL(jig_set_list.use_qty,0)				AS QTY
							, CONVERT(int,jig_conditions.value)					AS Life_Time
							, CONVERT(int,production_counters.alarm_value)			AS STD_Life_Time
							, jigs.id								AS jig_id 		
							, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
							, @periodcheck_value								AS  periodcheck_value
							, @period_value										AS  period_value
					FROM 
						(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id 
								ELSE device_flows.jig_set_id   END  AS jig_set_id  
								,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
								ELSE device_flows.act_process_id   END  AS act_process_id 
								,lots.lot_no
					FROM APCSProDB.trans.lots  
					INNER JOIN APCSProDB.method.device_flows
					ON lots.device_slip_id = device_flows.device_slip_id
					AND  device_flows.step_no =  lots.step_no
					LEFT JOIN [APCSProDB].[trans].[special_flows] 
					ON [special_flows].lot_id = lots.id 
					AND [special_flows].id	  = lots.special_flow_id
					AND lots.is_special_flow  = 1
					LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
					ON [special_flows].id = [lot_special_flows].special_flow_id
					AND [lot_special_flows].step_no =  [special_flows].step_no
					WHERE lots.lot_no	= @LOTNO)   AS sp_jig
					INNER JOIN APCSProDB.method.jig_sets 
					ON  jig_sets.process_id = sp_jig.act_process_id
					AND sp_jig.jig_set_id = jig_sets.id
					INNER JOIN APCSProDB.method.jig_set_list
					ON jig_sets.id =  jig_set_list.jig_set_id
					INNER JOIN APCSProDB.jig.productions
					ON productions.id = jig_set_list.jig_group_id
					INNER JOIN [APCSProDB].[jig].[production_counters]  
					ON production_counters.production_id = productions.id 
					INNER JOIN  APCSProDB.trans.jigs  
					ON productions.id	= jigs.jig_production_id
					INNER JOIN APCSProDB.trans.jig_conditions  
					ON jig_conditions.id = jigs.id
					WHERE  (jig_sets.code 				= @Recipe OR @Recipe IS NULL)
					AND  jigs.id					= @JIG_ID 
					AND ( jig_sets.is_disable		= 0 )

					RETURN
					 		
				END

				ELSE IF ((SELECT COUNT(jig_id) FROM APCSProDB.trans.machine_jigs  WHERE machine_id = @MCId AND idx IN (35, 36)) = 2 )
				BEGIN
				 
				SELECT  TOP 1  'FALSE'														AS Is_Pass
						, N'This JIG ('+ jigs.barcode + N') Is use on Machine ('+ machines.name + N')!!' AS Error_Message_ENG
						, N'JIG นี้ ('+ jigs.barcode + N') ถูกใช้งานอยู่ที่ Machine เครื่องนี้ ('+ machines.name + N') !!'	AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'						AS Handling
				FROM APCSProDB.trans.machine_jigs  
				INNER JOIN APCSProDB.trans.jigs  
				ON jigs.id = machine_jigs.jig_id
				INNER JOIN APCSProDB.mc.machines
				ON machines.id  =  machine_jigs.machine_id
				WHERE machine_id = @MCId AND idx = @idx  

				RETURN

				END 

				SET	@idx = @idx + 1
			END
		END
		END TRY
		BEGIN CATCH 
			SELECT    'FALSE'				AS Is_Pass 
					, ERROR_MESSAGE()	AS Error_Message_ENG
					, N'บันทึกข้อมูลผิดพลาด !!'	AS Error_Message_THA
					, N' กรุณาติดต่อ System'	AS Handling
			RETURN
		END CATCH

	END 


	
	END
END
