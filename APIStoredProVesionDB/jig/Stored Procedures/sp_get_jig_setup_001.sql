-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_jig_setup_001]
	-- Add the parameters for the stored procedure here
	  @QRCode			AS NVARCHAR(100)
	, @MCNo				AS NVARCHAR(50)
	, @OPNo				AS NVARCHAR(6) 
	, @Recipe			AS NVARCHAR(50)	=  NULL     
	, @INPUT_QTY		AS INT			= 1
	, @LOTNO			AS NVARCHAR(10) = NULL 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 
    -- Insert statements for procedure here
	DECLARE		  @JIG_ID			AS INT
				, @MC_ID			AS INT
				, @STDLifeTime		AS INT
				, @LifeTime			AS INT
				, @Safety			AS INT
				, @Accu				AS INT
				, @OPID				AS INT
				, @State			AS INT
				, @Smallcode		AS VARCHAR(4)
				, @QTY				AS INT			=  0
				, @MCOld			AS VARCHAR(50)
				, @Category			AS NVARCHAR(50)


	SET @MC_ID = (select top(1) id from APCSProDB.mc.machines WHERE machines.name = @MCNo)

	SELECT	  @JIG_ID			= jigs.id 
			, @State			= jig_state 
			, @Smallcode		= jigs.smallcode  
			, @Category			= categories.short_name
	FROM APCSProDB.trans.jigs 
	INNER JOIN APCSProDB.jig.productions
	ON productions.id =  jigs.jig_production_id
	INNER JOIN APCSProDB.jig.categories
	ON categories.id  = productions.category_id
	WHERE (barcode = @QRCode 
			OR qrcodebyuser = @QRCode)
	 

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
				, 'EXEC [jig].[sp_get_jig_setup] @JIG_ID = ''' + ISNULL(CAST(@JIG_ID AS nvarchar(MAX)),'') + ''', @QRCode = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') + ''',@OpNO = ''' 
					+ ISNULL(CAST(@OpNO AS nvarchar(MAX)),'') +  ''',@McNo = ''' + ISNULL(CAST(@McNo AS nvarchar(MAX)),'') + ''''
				, @JIG_ID
				, @QRCode
				, @LOTNO


	
			--/////////////////////Check jig Regist
			IF NOT EXISTS (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE (barcode = @QRCode OR qrcodebyuser = @QRCode)) 
			BEGIN
					SELECT	  'FALSE'							AS Is_Pass
							, 'This jig is not registered !!'	AS Error_Message_ENG
							, N'Socket นี้ยังไม่ถูกลงทะเบียน !!'		AS Error_Message_THA 
							, ''								AS Handling
					RETURN
			END

			--//////////////////// CHECK MACHINE NUMBER
			IF NOT EXISTS (SELECT TOP(1) id FROM APCSProDB.mc.machines WHERE machines.name = @MCNo) 
			BEGIN
					SELECT	  'FALSE'							AS Is_Pass
							, 'Machine Number is invalid !!'	AS Error_Message_ENG
							, N'หมายเลขเครื่องจักรไม่ถูกต้อง !!'			AS Error_Message_THA 
							, ''								AS Handling
					RETURN
			END

		--//////////////// SOCKET IN
			IF @State <> 11 -- To Machine
			BEGIN		

				IF @State = 12 -- On Machine 
				BEGIN	

					

					SET @MCOld =  ( SELECT TOP 1 machines.name 
									FROM APCSProDB.trans.jigs
									LEFT JOIN	APCSProDB.trans.machine_jigs 
									ON machine_jigs.jig_id = jigs.id
									LEFT JOIN 	APCSProDB.mc.machines 
									ON machines.id = machine_jigs.machine_id 
									WHERE jigs.id = @JIG_ID
								   )

					IF @MCOld <> @MCNo 
					BEGIN
							SELECT	  'FALSE' AS Is_Pass
									, N'This JIG ('+ @Smallcode + N') Is use on another Machine ('+ @MCOld + N') !!' AS Error_Message_ENG
									, N'JIG นี้ ('+ @Smallcode + N') ถูกใช้งานอยู่ที่ Machine เครื่องอื่น ('+ @MCOld + N') !!' AS Error_Message_THA
									, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
							RETURN
					END
				END
				ELSE 
				BEGIN
								SELECT	  'FALSE' AS Is_Pass
										, 'JIG ('+ (smallcode) + ') status is not scan out of stock.' AS Error_Message_ENG
										, 'JIG ('+ (smallcode) + N') ยังไม่ถูกสแกนออกจาก Stock !!' AS Error_Message_THA 
										, '' AS Handling
								FROM APCSProDB.trans.jigs 
								WHERE jigs.id = @JIG_ID
								RETURN
				END
			END

		IF @LOTNO IS NULL 
		BEGIN   
			--////////////////////Check LifeTime
			IF (@Category = 'Dicer Blade')
			BEGIN 

				--SET @STDLifeTime = (SELECT jigs.quantity 
				--					FROM APCSProDB.trans.jigs 
				--					INNER JOIN APCSProDB.jig.productions 
				--					ON jigs.jig_production_id = APCSProDB.jig.productions.id 
				--					INNER JOIN APCSProDB.jig.production_counters 
				--					ON production_counters.production_id = APCSProDB.jig.productions.id
				--					where jigs.id = @JIG_ID)

				--SET @LifeTime =		(SELECT APCSProDB.trans.jig_conditions.value
				--					FROM APCSProDB.trans.jigs 
				--					INNER JOIN APCSProDB.trans.jig_conditions 
				--					ON jigs.id = jig_conditions.id 
				--					INNER JOIN APCSProDB.jig.productions 
				--					ON jigs.jig_production_id = productions.id
				--					where jigs.id = @JIG_ID)

				--SET @Safety =		(SELECT (jigs.quantity * production_counters.warn_value )/100 AS _percent  
				--					FROM APCSProDB.trans.jigs 
				--					INNER JOIN APCSProDB.jig.productions 
				--					ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
				--					INNER JOIN APCSProDB.jig.production_counters 
				--					ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
				--					where jigs.id = @JIG_ID)			

  
				--IF  ( @LifeTime >= @STDLifeTime )
				--BEGIN	
				--		SELECT   'FALSE' AS Is_Pass
				--				,'('+(smallcode)+') the end of lifetime !!' AS Error_Message_ENG
				--				,'('+(smallcode)+N') LifeTime  หมดอายุ !!' AS Error_Message_THA
				--				,N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system !!' AS [Handling]
				--		FROM APCSProDB.trans.jigs where jigs.id = @JIG_ID 

				--		RETURN

				--END
				--ELSE  IF (@LifeTime >= @Safety)
				--BEGIN 
				--		SELECT  'FALSE' AS Is_Pass,
				--				'('+(smallcode)+') To the period. Please cleaning !!' AS Error_Message_ENG,
				--				'('+(smallcode)+N') ถึง Period Lifetime แล้ว กรุณานำไป Cleaning !!' AS Error_Message_THA
				--				,N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system !!' AS [Handling]
				--		FROM APCSProDB.trans.jigs where jigs.id = @JIG_ID 

				--		RETURN
				--END 
				--ELSE 
				--BEGIN
						--//RETUEN DATA
	 
						SELECT   'TRUE'									AS Is_Pass
									, ''									AS Error_Message_ENG
									, ''									AS Error_Message_THA 
									, ''									AS Handling 
									, @QRCode								AS QRCode
									, @QTY									AS QTY
									, smallcode								AS Smallcode
									, p.name								AS [Type] 
									, CONVERT(int,jc.value)					AS Life_Time
									, CONVERT(int,pc.alarm_value)			AS STD_Life_Time
									, j.id									AS jig_id 			
						FROM APCSProDB.trans.jigs j 
						INNER JOIN APCSProDB.jig.productions p 
						ON jig_production_id = p.id 
						INNER JOIN [APCSProDB].[jig].[production_counters] pc 
						ON pc.production_id = p.id 
						INNER JOIN APCSProDB.trans.jig_conditions jc 
						ON jc.id = j.id
						WHERE j.id = @JIG_ID

						RETURN
				--END

			END
			ELSE 
			BEGIN

							SET @STDLifeTime = (SELECT  APCSProDB.jig.production_counters.alarm_value  
												FROM APCSProDB.trans.jigs
												INNER JOIN APCSProDB.jig.productions 
												ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
												INNER JOIN APCSProDB.jig.production_counters 
												ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
												where jigs.id = @JIG_ID)

							SET @LifeTime =		(SELECT (APCSProDB.trans.jig_conditions.value ) 
												FROM APCSProDB.trans.jigs 
												INNER JOIN APCSProDB.trans.jig_conditions 
												ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id  
												INNER JOIN APCSProDB.jig.productions 
												ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
												where jigs.id = @JIG_ID)
  
							IF (@LifeTime > @STDLifeTime  )
							BEGIN 
									SELECT    'FALSE'													AS Is_Pass
											, '('+(smallcode)+') LifeTime Expire (100%) !!'				AS Error_Message_ENG
											, '('+(smallcode )+N') LifeTime หมดอายุการใช้งาน (100%) !!'		AS Error_Message_THA 
											,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'					AS Handling
									FROM APCSProDB.trans.jigs 
									WHERE jigs.id = @JIG_ID

									RETURN

							END 

						--//RETUEN DATA
	 
							SELECT   'TRUE'									AS Is_Pass
									, ''									AS Error_Message_ENG
									, ''									AS Error_Message_THA 
									, ''									AS Handling 
									, @QRCode								AS QRCode
									, @QTY									AS QTY
									, smallcode								AS Smallcode
									, p.name								AS [Type] 
									, CONVERT(int,jc.value)					AS Life_Time
									, CONVERT(int,pc.alarm_value)			AS STD_Life_Time
									, j.id									AS jig_id 			
							FROM APCSProDB.trans.jigs j 
							INNER JOIN APCSProDB.jig.productions p 
							ON jig_production_id = p.id 
							INNER JOIN [APCSProDB].[jig].[production_counters] pc 
							ON pc.production_id = p.id 
							INNER JOIN APCSProDB.trans.jig_conditions jc 
							ON jc.id = j.id
							WHERE j.id = @JIG_ID
							RETURN

			END

		END 
	ELSE
	BEGIN 
				--/////////////////////Check  Regist
		 	IF NOT EXISTS ( SELECT jig_sets.id 
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
							INNER JOIN APCSProDB.trans.jigs
							ON productions.id	= jigs.jig_production_id
							WHERE lots.lot_no	= @LOTNO
							AND  (jig_sets.code 	= @Recipe OR @Recipe IS NULL)
							AND  (barcode = @QRCode 
								 OR qrcodebyuser = @QRCode
								 )
							AND  jig_sets.id IS NOT NULL 
						   )
			BEGIN 

					SELECT  'FALSE' AS Is_Pass
							,'Device slips this material has not been registered yet !!' AS Error_Message_ENG
							,N'Device slips นี้ยังไม่ถูกลงทะเบียน Material' AS Error_Message_THA
							,N'กรุณาตรวจสอบข้อมูลที่ Web MDM' AS Handling
					RETURN		
			
			END 
			ELSE 
			BEGIN 

		 		IF (@Category = 'Dicer Blade')
				BEGIN 

 

					--SET @STDLifeTime = (SELECT jigs.quantity 
					--					FROM APCSProDB.trans.jigs 
					--					INNER JOIN APCSProDB.jig.productions 
					--					ON jigs.jig_production_id = APCSProDB.jig.productions.id 
					--					INNER JOIN APCSProDB.jig.production_counters 
					--					ON production_counters.production_id = APCSProDB.jig.productions.id
					--					where jigs.id = @JIG_ID)

					--SET @LifeTime =		(SELECT APCSProDB.trans.jig_conditions.value
					--					FROM APCSProDB.trans.jigs 
					--					INNER JOIN APCSProDB.trans.jig_conditions 
					--					ON jigs.id = jig_conditions.id 
					--					INNER JOIN APCSProDB.jig.productions 
					--					ON jigs.jig_production_id = productions.id
					--					where jigs.id = @JIG_ID)

					--SET @Safety =		(SELECT (jigs.quantity * production_counters.warn_value )/100 AS _percent  
					--					FROM APCSProDB.trans.jigs 
					--					INNER JOIN APCSProDB.jig.productions 
					--					ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
					--					INNER JOIN APCSProDB.jig.production_counters 
					--					ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
					--					where jigs.id = @JIG_ID)			

  
					--IF  ( @LifeTime >= @STDLifeTime )
					--BEGIN	
					--		SELECT   'FALSE' AS Is_Pass
					--				,'('+(smallcode)+') the end of lifetime !!' AS Error_Message_ENG
					--				,'('+(smallcode)+N') LifeTime  หมดอายุ !!' AS Error_Message_THA
					--				,N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system !!' AS [Handling]
					--		FROM APCSProDB.trans.jigs where jigs.id = @JIG_ID 

					--		RETURN

					--END
					--ELSE  IF (@LifeTime >= @Safety)
					--BEGIN 
					--		SELECT  'FALSE' AS Is_Pass,
					--				'('+(smallcode)+') To the period. Please cleaning !!' AS Error_Message_ENG,
					--				'('+(smallcode)+N') ถึง Period Lifetime แล้ว กรุณานำไป Cleaning !!' AS Error_Message_THA
					--				,N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system !!' AS [Handling]
					--		FROM APCSProDB.trans.jigs where jigs.id = @JIG_ID 

					--		RETURN
					--END 
					--ELSE 
					--BEGIN
							--//RETUEN DATA
	 
							SELECT   'TRUE'									AS Is_Pass
									, ''									AS Error_Message_ENG
									, ''									AS Error_Message_THA 
									, ''									AS Handling 
									, @QRCode								AS QRCode
									, @QTY									AS QTY
									, smallcode								AS Smallcode
									, p.name								AS [Type] 
									, CONVERT(int,jc.value)					AS Life_Time
									, CONVERT(int,pc.alarm_value)			AS STD_Life_Time
									, j.id									AS jig_id 			
							FROM APCSProDB.trans.jigs j 
							INNER JOIN APCSProDB.jig.productions p 
							ON jig_production_id = p.id 
							INNER JOIN [APCSProDB].[jig].[production_counters] pc 
							ON pc.production_id = p.id 
							INNER JOIN APCSProDB.trans.jig_conditions jc 
							ON jc.id = j.id
							WHERE j.id = @JIG_ID

							RETURN
					--END

				END
				ELSE 
				BEGIN
			 
		 
					SELECT    @QTY =  jig_set_list.use_qty		 
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
					AND  (jig_sets.code 	= @Recipe OR @Recipe IS NULL)
					AND  jigs.id					= @JIG_ID 
					AND ( jig_sets.is_disable		= 0 )

	 
				--////////////////////Check LifeTime
	
				SET @STDLifeTime = (SELECT  APCSProDB.jig.production_counters.alarm_value  
									FROM APCSProDB.trans.jigs
									INNER JOIN APCSProDB.jig.productions 
									ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
									INNER JOIN APCSProDB.jig.production_counters 
									ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
									where jigs.id = @JIG_ID)

				SET @LifeTime =		(SELECT (APCSProDB.trans.jig_conditions.value ) + (@INPUT_QTY * @QTY)
									FROM APCSProDB.trans.jigs 
									INNER JOIN APCSProDB.trans.jig_conditions 
									ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id  
									INNER JOIN APCSProDB.jig.productions 
									ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
									where jigs.id = @JIG_ID)
  
				IF (@LifeTime > @STDLifeTime  )
				BEGIN 
						SELECT    'FALSE'													AS Is_Pass
								, '('+(smallcode)+') LifeTime Expire (100%) !!'				AS Error_Message_ENG
								, '('+(smallcode )+N') LifeTime หมดอายุการใช้งาน (100%) !!'		AS Error_Message_THA 
								,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'					AS Handling
						FROM APCSProDB.trans.jigs 
						WHERE jigs.id = @JIG_ID

						RETURN

				END 

						--//RETUEN DATA
	 
						SELECT   'TRUE'									AS Is_Pass
								, ''									AS Error_Message_ENG
								, ''									AS Error_Message_THA 
								, ''									AS Handling 
								, @QRCode								AS QRCode
								, @QTY									AS QTY
								, smallcode								AS Smallcode
								, p.name								AS [Type] 
								, CONVERT(int,jc.value)					AS Life_Time
								, CONVERT(int,pc.alarm_value)			AS STD_Life_Time
								, j.id									AS jig_id 			
						FROM APCSProDB.trans.jigs j 
						INNER JOIN APCSProDB.jig.productions p 
						ON jig_production_id = p.id 
						INNER JOIN [APCSProDB].[jig].[production_counters] pc 
						ON pc.production_id = p.id 
						INNER JOIN APCSProDB.trans.jig_conditions jc 
						ON jc.id = j.id
						WHERE j.id = @JIG_ID
				END

			END
	END
END
