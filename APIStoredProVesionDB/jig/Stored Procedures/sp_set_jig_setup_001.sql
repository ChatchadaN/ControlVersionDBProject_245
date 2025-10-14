-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_jig_setup_001]
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
	DECLARE   @JIG_ID				VARCHAR(10)
			, @Smallcode			VARCHAR(4)
			, @MCId					INT
			, @OldJIG				INT
			, @Type					VARCHAR(250)
			, @OPID					INT
			, @State				INT 
			, @Shot_name			NVARCHAR(50)
			, @idx					INT  
			, @jig_production_id	INT 
			, @MCOld				VARCHAR(50)


		SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)
		SET @MCId = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)
		  
		SELECT	  @JIG_ID				= jigs.id 
				, @State				= jig_state 
				, @Smallcode			= jigs.smallcode  
				, @Type					= categories.name
				, @Shot_name			= categories.short_name
				, @jig_production_id	=jig_production_id
		FROM APCSProDB.trans.jigs
		INNER JOIN APCSProDB.jig.productions 
		ON jig_production_id = productions.id 
		INNER JOIN APCSProDB.jig.categories 
		ON category_id = categories.id 
		WHERE (barcode = @QRCode OR qrcodebyuser =@QRCode)

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
				, 'EXEC [jig].[sp_set_jig_setup] @JIG_ID = ''' + ISNULL(CAST(@JIG_ID AS nvarchar(MAX)),'') + ''', @QRCode = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') + ''', @Recipe = ''' + ISNULL(CAST(@Recipe AS nvarchar(MAX)),'') + ''', State Now = ''' + ISNULL(CAST(@State AS nvarchar(MAX)),'') + ''',@OpNO = ''' 
					+ ISNULL(CAST(@OpNO AS nvarchar(MAX)),'') +  ''',@McNo = ''' + ISNULL(CAST(@McNo AS nvarchar(MAX)),'') + ''''
				, @JIG_ID
				, @QRCode 
				, @LOTNO


	IF @LOTNO IS NULL 
	BEGIN
		
		--CHECK BLADE IS NULL
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

						SELECT   'TRUE'								AS Is_Pass
								, N''								AS Error_Message_ENG
								, N''								AS Error_Message_THA
								, N''								AS Handling
								, @QRCode							AS QRCode
								, smallcode							AS Smallcode
								, productions.name					AS [Type]
								, 0									AS QTY
								, CAST(jig_conditions.value AS INT) AS Life_Time
								, CAST(jigs.quantity AS INT)		AS STD_Life_Time
								, jigs.id							AS jig_id
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

		SET @mcid = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)

		IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 1)
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
			(		  @mcid
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
								, CAST(jigs.quantity AS INT)		AS STD_Life_Time
								, jigs.id							AS jig_id
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

		IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 2)
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
			(		  @mcid
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
								, CAST(jigs.quantity AS INT)		AS STD_Life_Time
								, jigs.id							AS jig_id
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
					, 'Update error !!'		AS Error_Message_ENG
					, N'บันทึกข้อมูลผิดพลาด !!'	AS Error_Message_THA
					, N'กรุณาติดต่อ System'	AS Handling
			RETURN

		END CATCH

	END
	ELSE 
	BEGIN 

--lot no ต้องเช็คด้วยว่าส่งหรือไม่ส่ง เพราะเป็นจังหวะ set ถ้าไม่มี lot ก็ต้อง setup ได้

	IF NOT EXISTS ( SELECT jig_sets.id 
					FROM APCSProDB.trans.lots
					INNER JOIN APCSProDB.method.device_flows
					ON lots.device_slip_id = device_flows.device_slip_id
					AND  device_flows.step_no = lots.step_no
					INNER JOIN APCSProDB.method.jig_sets 
					ON  jig_sets.process_id = device_flows.act_process_id
					AND device_flows.jig_set_id = jig_sets.id
					INNER JOIN APCSProDB.method.jig_set_list
					ON jig_set_list.id =  jig_set_list.id
					INNER JOIN APCSProDB.jig.productions
					ON productions.id = jig_set_list.jig_group_id
					INNER JOIN APCSProDB.trans.jigs
					ON productions.id				= jigs.jig_production_id
					WHERE lots.lot_no				= @LOTNO
					AND (jig_sets.code 	= @Recipe OR @Recipe IS NULL)
					AND (barcode = @QRCode OR qrcodebyuser = @QRCode)
					AND  jig_sets.id IS NOT NULL 
				   )
	BEGIN 

			SELECT  'FALSE' AS Is_Pass
					,'Device slips this jig has not been registered yet !!' AS Error_Message_ENG
					,N'Device slips นี้ยังไม่ถูกลงทะเบียน jig !!' AS Error_Message_THA
					,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
			RETURN		
			
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
			ELSE BEGIN

					SELECT    'TRUE'								AS Is_Pass 
							, 'Success !!'							AS Error_Message_ENG
							, N'บันทึกเรียบร้อย !!'						AS Error_Message_THA
							, ''									AS Handling
							, @QRCode								AS QRCode
							, smallcode								AS Smallcode
							, productions.name						AS [Type] 
							, jig_set_list.use_qty					AS QTY
							, CONVERT(int,jc.value)					AS Life_Time
							, CONVERT(int,pc.alarm_value)			AS STD_Life_Time
							, jigs.id								AS jig_id 			
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
					INNER JOIN [APCSProDB].[jig].[production_counters] pc 
					ON pc.production_id = productions.id 
					INNER JOIN  APCSProDB.trans.jigs  
					ON productions.id	= jigs.jig_production_id
					INNER JOIN APCSProDB.trans.jig_conditions jc 
					ON jc.id						= jigs.id
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
			SET @mcid = (SELECT id FROM APCSProDB.mc.machines WHERE name = @MCNo)

				IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 1)
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
					(		  @mcid
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
							, jig_set_list.use_qty					AS QTY
							, CONVERT(int,jc.value)					AS Life_Time
							, CONVERT(int,pc.alarm_value)			AS STD_Life_Time
							, jigs.id								AS jig_id 			
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
					INNER JOIN [APCSProDB].[jig].[production_counters] pc 
					ON pc.production_id = productions.id 
					INNER JOIN  APCSProDB.trans.jigs  
					ON productions.id	= jigs.jig_production_id
					INNER JOIN APCSProDB.trans.jig_conditions jc 
					ON jc.id = jigs.id
					WHERE lots.lot_no				= @LOTNO
					AND (jig_sets.code 				= @Recipe OR @Recipe IS NULL)
					AND  jigs.id					= @JIG_ID 
					AND ( jig_sets.is_disable		= 0 )

					RETURN
					 

				END

				IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @mcid AND idx = 2)
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
					(		  @mcid
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
							, jig_set_list.use_qty					AS QTY
							, CONVERT(int,jc.value)					AS Life_Time
							, CONVERT(int,pc.alarm_value)			AS STD_Life_Time
							, jigs.id								AS jig_id 			
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
					INNER JOIN [APCSProDB].[jig].[production_counters] pc 
					ON pc.production_id = productions.id 
					INNER JOIN  APCSProDB.trans.jigs  
					ON productions.id	= jigs.jig_production_id
					INNER JOIN APCSProDB.trans.jig_conditions jc 
					ON jc.id = jigs.id
					WHERE lots.lot_no				= @LOTNO
					AND (jig_sets.code 				= @Recipe OR @Recipe IS NULL)
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

				IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs  WHERE machine_id = @mcid AND idx = @idx) 
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
							, productions.name								AS [Type] 
							, jig_set_list.use_qty					AS QTY
							, CONVERT(int,jc.value)					AS Life_Time
							, CONVERT(int,pc.alarm_value)			AS STD_Life_Time
							, jigs.id								AS jig_id 			
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
					INNER JOIN [APCSProDB].[jig].[production_counters] pc 
					ON pc.production_id = productions.id 
					INNER JOIN  APCSProDB.trans.jigs  
					ON productions.id	= jigs.jig_production_id
					INNER JOIN APCSProDB.trans.jig_conditions jc 
					ON jc.id = jigs.id
					WHERE lots.lot_no	= @LOTNO
					AND (jig_sets.code 	= @Recipe OR @Recipe IS NULL)
					AND  jigs.id		= @JIG_ID 
					AND ( jig_sets.is_disable  = 0 )

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

				IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs  WHERE machine_id = @mcid AND idx = @idx) 
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
							, jig_set_list.use_qty					AS QTY
							, CONVERT(int,jc.value)					AS Life_Time
							, CONVERT(int,pc.alarm_value)			AS STD_Life_Time
							, jigs.id								AS jig_id 			
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
					INNER JOIN [APCSProDB].[jig].[production_counters] pc 
					ON pc.production_id = productions.id 
					INNER JOIN  APCSProDB.trans.jigs  
					ON productions.id	= jigs.jig_production_id
					INNER JOIN APCSProDB.trans.jig_conditions jc 
					ON jc.id = jigs.id
					WHERE lots.lot_no				= @LOTNO
					AND (jig_sets.code 	= @Recipe OR @Recipe IS NULL)
					AND  jigs.id					= @JIG_ID 
					AND ( jig_sets.is_disable		= 0 )

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

				IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs  WHERE machine_id = @mcid AND idx = @idx) 
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
							, productions.name								AS [Type] 
							, jig_set_list.use_qty					AS QTY
							, CONVERT(int,jc.value)					AS Life_Time
							, CONVERT(int,pc.alarm_value)			AS STD_Life_Time
							, jigs.id								AS jig_id 			
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
					INNER JOIN [APCSProDB].[jig].[production_counters] pc 
					ON pc.production_id = productions.id 
					INNER JOIN  APCSProDB.trans.jigs  
					ON productions.id	= jigs.jig_production_id
					INNER JOIN APCSProDB.trans.jig_conditions jc 
					ON jc.id = jigs.id
					WHERE lots.lot_no				= @LOTNO
					AND (jig_sets.code 	= @Recipe OR @Recipe IS NULL)
					AND  jigs.id					= @JIG_ID 
					AND ( jig_sets.is_disable		= 0 )

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
