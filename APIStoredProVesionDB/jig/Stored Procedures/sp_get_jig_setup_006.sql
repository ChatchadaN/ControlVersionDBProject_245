-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_jig_setup_006]
	-- Add the parameters for the stored procedure here
	  @QRCode			AS NVARCHAR(100)
	, @MCNo				AS NVARCHAR(50)	= NULL
	, @OPNo				AS NVARCHAR(6)  = NULL 
	, @Recipe			AS NVARCHAR(50)	= NULL     
	, @INPUT_QTY		AS INT			= 1
	, @LOTNO			AS NVARCHAR(10) = NULL 

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 
    -- Insert statements for procedure here
	DECLARE		  @JIG_ID				AS INT
				, @MC_ID				AS INT
				, @STDLifeTime			AS INT			 
				, @LifeTime				AS INT			 
				, @Safety				AS INT
				, @Accu					AS INT
				, @OPID					AS INT
				, @State				AS INT
				, @Smallcode			AS VARCHAR(10)
				, @QTY					AS INT			
				, @MCOld				AS VARCHAR(50)
				, @Category				AS NVARCHAR(50)
				, @root_id				AS INT
				, @process				AS VARCHAR(5)
				, @periodcheck_value	AS INT
				, @period_value			AS INT
				, @Shot_name			AS NVARCHAR(20)
				, @process_id			INT 
				, @type					NVARCHAR(100)
				, @jig_production_id	INT 
				, @JIG_OLD				AS INT
				, @warn_value			AS INT
				, @LifeTime_accumulate	AS INT 
 

		SET @MC_ID = (select top(1) id from APCSProDB.mc.machines WHERE machines.name = @MCNo)

		SELECT	  @JIG_ID				= jigs.id 
				, @State				= jig_state 
				, @Smallcode			= jigs.smallcode  
				, @Shot_name			= categories.short_name
				, @Category				= categories.[name]
				, @root_id				= jigs.id
				, @periodcheck_value	= ISNULL(jig_conditions.periodcheck_value , 0)
				, @period_value			= ISNULL(production_counters.period_value , 0)
				, @STDLifeTime			= ISNULL(productions.expiration_value, production_counters.alarm_value)
				, @LifeTime				= ISNULL(jig_conditions.[value],0)
				, @process_id			= categories.lsi_process_id
				, @type					= productions.[name]
		FROM APCSProDB.trans.jigs 
		INNER JOIN APCSProDB.trans.jig_conditions 
		ON jigs.id = jig_conditions.id 
		INNER JOIN APCSProDB.jig.productions
		ON productions.id =  jigs.jig_production_id
		INNER JOIN APCSProDB.jig.production_counters 
		ON production_counters.production_id = productions.id
		INNER JOIN APCSProDB.jig.categories
		ON categories.id  = productions.category_id
		WHERE (barcode = @QRCode OR qrcodebyuser = @QRCode OR smallcode = @QRCode)
	 

		--INSERT INTO APIStoredProDB.[dbo].[exec_sp_history_jig]
		--(	
		--		  [record_at]
		--		, [record_class]
		--		, [login_name]
		--		, [hostname]
		--		, [appname]
		--		, [command_text]
		--		, jig_id
		--		, barcode
		--		, lot_no

		--)
		--SELECT    GETDATE()
		--		, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
		--		, ORIGINAL_LOGIN()
		--		, HOST_NAME()
		--		, APP_NAME()
		--		, 'EXEC [jig].[sp_get_jig_setup_006] @JIG_ID = ''' + ISNULL(CAST(@JIG_ID AS nvarchar(MAX)),'') + ''', @QRCode = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') +''', @Recipe = ''' + ISNULL(CAST(@Recipe AS nvarchar(MAX)),'')+  ''',@OpNO = ''' 
		--			+ ISNULL(CAST(@OpNO AS nvarchar(MAX)),'') +  ''',@McNo = ''' + ISNULL(CAST(@McNo AS nvarchar(MAX)),'') +  ''',@INPUT_QTY = ''' + ISNULL(CAST(@INPUT_QTY AS nvarchar(MAX)),'') +''''
		--		, @JIG_ID
		--		, @QRCode
		--		, @LOTNO


	
			--/////////////////////Check jig Regist
			IF NOT EXISTS (SELECT @JIG_ID) 
			BEGIN
					SELECT	  'FALSE'							AS Is_Pass
							, 'This jig is not registered !!'	AS Error_Message_ENG
							, N'JIG นี้ยังไม่ถูกลงทะเบียน !!'		AS Error_Message_THA 
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

		IF (@LOTNO IS NULL OR  @LOTNO = '')
		BEGIN   
			--////////////////////Check LifeTime
			IF (@Shot_name = 'Dicer Blade')
			BEGIN 

		 
						SELECT    'TRUE'											AS Is_Pass
								, ''												AS Error_Message_ENG
								, ''												AS Error_Message_THA 
								, ''												AS Handling 
								, @QRCode											AS QRCode
								, ISNULL(@QTY,0)									AS QTY
								, smallcode											AS Smallcode
								, productions.name									AS [Type] 
								, CONVERT(int,jig_conditions.value)					AS Life_Time
								, CONVERT(int,production_counters.alarm_value)		AS STD_Life_Time
								, jigs.id											AS jig_id 		
								, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
								, @periodcheck_value								AS  periodcheck_value
								, @period_value										AS  period_value
						FROM APCSProDB.trans.jigs  
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON jigs.id = APCSProDB.trans.jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.jig.productions.id = jigs.jig_production_id 
						INNER JOIN APCSProDB.jig.production_counters 
						ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
						WHERE  jigs.id = @JIG_ID

						RETURN
				--END

			END
			ELSE IF (@Shot_name =  'Kanagata')
			BEGIN

		 
							IF (@root_id is null)
							BEGIN
								SELECT    'FALSE'														AS Is_Pass
										, 'Kanagata (' + @QRCode+') number is not registered. !!'		AS Error_Message_ENG
										, N'Kanagata (' + @QRCode +N') นี้ยังไม่ถูกลงทะเบียน !!'				AS Error_Message_THA
										, N'กรุณาลงทะเบียน Kanagata ที่เว็บ JIG'								AS Handling
					
							END

							ELSE
							BEGIN
								IF NOT EXISTS(SELECT 1
									FROM APCSProDB. trans.jigs INNER JOIN APCSProDB.trans.jig_conditions on jigs.id = jig_conditions.id 
									INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = jigs.jig_production_id
									INNER JOIN APCSProDB.jig.production_counters on production_counters.production_id = productions.id
									WHERE  jigs.id <> @root_id and root_jig_id = @root_id) 
								BEGIN
									SELECT   'FALSE' AS Is_Pass
											,'Kanagata Part not yet registered. !!'		AS Error_Message_ENG
											,N'Kanakata Part ยังไม่ถูกลงทะเบียน!!'			AS Error_Message_THA
											,N'กรุณาลงทะเบียน Kanagata Part ที่เว็บ JIG'		AS Handling
						 
									RETURN
								END

							IF EXISTS (SELECT table1.Cul_ShotPerFrame FROM (
								SELECT jigs.id,barcode,[value],warn_value AS SafetyFactor,production_counters.alarm_value  AS STDLifeTime,
								(
									CASE WHEN @process_id =  4     --MP check life time =value+(warn_value/ f-press / qty(kanagata count)
										THEN CASE WHEN CONVERT(INT,(CONVERT(INT,[value])  + (ISNULL(warn_value,1)  / @INPUT_QTY / @QTY))) >  production_counters.alarm_value
										THEN 'Expire' ELSE 'Ready'
										END
									ELSE CASE WHEN ([value] + ISNULL(warn_value, 1)) > production_counters.alarm_value  
									THEN 'Expire' ELSE 'Ready' END
								END  
								) AS Cul_ShotPerFrame,root_jig_id 
								FROM	APCSProDB. trans.jigs 
								INNER JOIN APCSProDB.trans.jig_conditions on jigs.id = jig_conditions.id 
								INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = jigs.jig_production_id
								INNER JOIN APCSProDB.jig.production_counters on production_counters.production_id = productions.id
								WHERE jigs.id <> @root_id and root_jig_id = @root_id
								) AS table1 WHERE table1.Cul_ShotPerFrame = 'Expire')
								BEGIN 
									
								SELECT    'FALSE'													AS Is_Pass
										, '('+(smallcode)+') Kanagata Part Life Time expire. '		AS Error_Message_ENG
										, '('+(smallcode )+N') Kanakata Part หมดอายุการใช้งาน	'		AS Error_Message_THA 
										,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'					AS Handling
										FROM APCSProDB.trans.jigs 
										WHERE jigs.id = @JIG_ID

										RETURN

								END 
								ELSE
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


								END
							END

					 
					END
			ELSE IF (@Shot_name IN ( 'HP','PP') )
			BEGIN 
					 
					IF @MCNo <> (SELECT TOP 1 mc_no FROM APCSProDB.trans.jig_records 
								 WHERE jig_records.jig_id = @JIG_ID 
								AND transaction_type = 'To Machine' ORDER BY id DESC)
					BEGIN

							SELECT	  'FALSE' AS Is_Pass
									, @Shot_name +' ('+ jigs.smallcode +') request MCNo not match between BM Online and JIG !!' AS Error_Message_ENG
									, @Shot_name +' ('+ jigs.smallcode +N') นี้ร้องขอ Machine ไม่ตรงกันระหว่าง BM Online และ JIG !!' AS Error_Message_THA
									, N'กรุณาตรวจสอบ MCNo ของ HP ที่เว็บ JIG System' AS Handling
							FROM APCSProDB.trans.jigs 
							WHERE jigs.id = @JIG_ID

							RETURN
					END
					 
					 	SET @STDLifeTime = (SELECT (CAST(production_counters.alarm_value  AS INT) * 1000 )
											FROM APCSProDB.trans.jigs INNER JOIN 
											APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
											APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
											where jigs.id = @JIG_ID)
						SET @period_value =	(SELECT (CAST(production_counters.period_value  AS INT) * 1000 )
											FROM APCSProDB.trans.jigs INNER JOIN
											APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
											INNER JOIN APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
											where jigs.id = @JIG_ID)

						SET @warn_value =	(SELECT (CAST(APCSProDB.jig.production_counters.warn_value  AS INT) * 1000 )
											FROM APCSProDB.trans.jigs INNER JOIN
											APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
											INNER JOIN APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
											where jigs.id = @JIG_ID)

						SET @LifeTime =		(SELECT (ISNULL(jig_conditions.[value],0)  ) + @INPUT_QTY
											FROM APCSProDB.trans.jigs 
				 							INNER JOIN APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id 
											INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
											where jigs.id = @JIG_ID)

 						SET @LifeTime_accumulate =		(SELECT (jig_conditions.[value]+ ISNULL(accumulate_lifetime,0)  ) + @INPUT_QTY
											FROM APCSProDB.trans.jigs 
				 							INNER JOIN APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id 
											INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
											where jigs.id = @JIG_ID)

						SET @periodcheck_value =		(SELECT (ISNULL(jig_conditions.periodcheck_value,0)  ) + @INPUT_QTY    
											FROM APCSProDB.trans.jigs 
											INNER JOIN APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id 
											INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
											where jigs.id = @JIG_ID)
						
						
					IF  @LifeTime_accumulate >= @STDLifeTime 
					BEGIN	
							SELECT    'FALSE' AS Is_Pass
									, '('+(smallcode)+') the end of lifetime ' AS Error_Message_ENG
									, '('+(smallcode)+N') LifeTime หมดอายุ  ' AS Error_Message_THA
									, N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system ' AS [Handling]
							FROM APCSProDB.trans.jigs where jigs.id = @JIG_ID 

							RETURN

					END
					ELSE  IF (@periodcheck_value >= @period_value  )
					BEGIN 
							SELECT   'FALSE' AS Is_Pass
									, '('+(smallcode)+') To the STD Cleaning. Please cleaning HP/PP ' AS Error_Message_ENG
									, '('+(smallcode)+N') ถึง STD Cleaning  แล้ว กรุณานำ HP/PP ไป Cleaning '+CONVERT(NVARCHAR(100) ,@periodcheck_value) AS Error_Message_THA
									, N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system ' AS [Handling]
							FROM APCSProDB.trans.jigs where jigs.id = @JIG_ID  

							RETURN

					END 	
					ELSE  IF (@LifeTime >= @warn_value  )
					BEGIN 
							SELECT   'FALSE' AS Is_Pass
									, '('+(smallcode)+') To the period. Please cleaning HP/PP ' AS Error_Message_ENG
									, '('+(smallcode)+N') ถึง Period Lifetime แล้ว กรุณานำ HP/PP ไป Cleaning ' AS Error_Message_THA
									, N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system ' AS [Handling]
							FROM APCSProDB.trans.jigs where jigs.id = @JIG_ID 

							RETURN

					END 
					ELSE BEGIN

						SELECT    'TRUE'											AS Is_Pass 
								, ''												AS Error_Message_ENG
								, ''												AS Error_Message_THA 
								, ''												AS Handling 
								, @QRCode											AS QRCode
								, ISNULL(@QTY,0)									AS QTY
								, smallcode											AS Smallcode
								, productions.[name]								AS [Type] 
								, CONVERT(INT,jig_conditions.[value])				AS Life_Time
								, CONVERT(INT,@STDLifeTime)							AS STD_Life_Time
								, jigs.id											AS jig_id 		
								, FORMAT(COALESCE((CAST(jig_conditions.[value]  AS DECIMAL(18 , 2)) * 
									CAST(100  AS DECIMAL(18 , 2)))/ NULLIF(@STDLifeTime,0) ,0), 'N2') AS LifeTime_Percen
								, jig_conditions.periodcheck_value					AS  periodcheck_value
								, @period_value										AS  period_value
						FROM APCSProDB.trans.jigs  
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON jigs.id = APCSProDB.trans.jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.jig.productions.id = jigs.jig_production_id 
						INNER JOIN APCSProDB.jig.production_counters 
						ON  production_counters.production_id =  productions.id 
						WHERE  jigs.id = @JIG_ID

						RETURN
					END
				 

			END
		
			ELSE   -- JIG Wedge , Wire ,Cutter
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
	 
									SELECT    'TRUE'											AS Is_Pass
											, ''												AS Error_Message_ENG
											, ''												AS Error_Message_THA 
											, ''												AS Handling 
											, @QRCode											AS QRCode
											, ISNULL(@QTY,0)									AS QTY
											, smallcode											AS Smallcode
											, productions.name									AS [Type] 
											, CONVERT(int,jig_conditions.value)					AS Life_Time
											, CONVERT(int,production_counters.alarm_value)		AS STD_Life_Time
											, jigs.id											AS jig_id 		
											, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
											, @periodcheck_value								AS  periodcheck_value
											, @period_value										AS  period_value
									FROM APCSProDB.trans.jigs  
									INNER JOIN APCSProDB.trans.jig_conditions 
									ON jigs.id = APCSProDB.trans.jig_conditions.id 
									INNER JOIN APCSProDB.jig.productions 
									ON APCSProDB.jig.productions.id = jigs.jig_production_id 
									INNER JOIN APCSProDB.jig.production_counters 
									ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
									WHERE  jigs.id = @JIG_ID
							RETURN

			END

		END 
			
		ELSE	--//LOT 
		BEGIN 
					--/////////////////////Check  Regist
		IF  EXISTS ( SELECT  sp_jig.jig_set_id FROM  (SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id  ELSE device_flows.jig_set_id   END  AS jig_set_id  
												,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
												ELSE device_flows.act_process_id   END  AS act_process_id 
										,lots.lot_no
										, device_flows.recipe
									 , device_flows.id
									 ,lots.device_slip_id
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
						WHERE  jigs.id = @JIG_ID
						AND  jig_sets.id IS NOT NULL 
							   )
				BEGIN 
	 
					IF (@Shot_name =  'Kanagata')
					BEGIN 
						--IF (@Category = 'Kanagata Part')
						--BEGIN 
							IF (@root_id is null)
							BEGIN
								SELECT    'FALSE'														AS Is_Pass
										, 'Kanagata (' + @QRCode+') number is not registered. !!'		AS Error_Message_ENG
										, N'Kanagata (' + @QRCode +N') นี้ยังไม่ถูกลงทะเบียน !!'				AS Error_Message_THA
										, N'กรุณาลงทะเบียน Kanagata ที่เว็บ JIG'								AS Handling
					
							END

							ELSE
							BEGIN

								IF NOT EXISTS(SELECT 1
									FROM APCSProDB. trans.jigs INNER JOIN APCSProDB.trans.jig_conditions on jigs.id = jig_conditions.id 
									INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = jigs.jig_production_id
									INNER JOIN APCSProDB.jig.production_counters on production_counters.production_id = productions.id
									WHERE  jigs.id <> @root_id and root_jig_id = @root_id) 
								BEGIN
									SELECT   'FALSE' AS Is_Pass
											,'Kanagata Part not yet registered. !!'		AS Error_Message_ENG
											,N'Kanakata Part ยังไม่ถูกลงทะเบียน!!'			AS Error_Message_THA
											,N'กรุณาลงทะเบียน Kanagata Part ที่เว็บ JIG'		AS Handling
						 
									RETURN
								END

								IF EXISTS (SELECT table1.Cul_ShotPerFrame FROM (
								SELECT jigs.id,barcode,[value],warn_value AS SafetyFactor,production_counters.alarm_value  AS STDLifeTime,
								(
									CASE WHEN @process_id =  4     --MP check life time =value+(warn_value/ f-press / qty(kanagata count)
										THEN CASE WHEN CONVERT(INT,(CONVERT(INT,[value])  + (ISNULL(warn_value,1)  / @INPUT_QTY / @QTY))) >  production_counters.alarm_value
										THEN 'Expire' ELSE 'Ready'
										END
									ELSE CASE WHEN ([value] + ISNULL(warn_value, 1)) > production_counters.alarm_value  
									THEN 'Expire' ELSE 'Ready' END
								END  
								) AS Cul_ShotPerFrame,root_jig_id 
								FROM	APCSProDB. trans.jigs 
								INNER JOIN APCSProDB.trans.jig_conditions on jigs.id = jig_conditions.id 
								INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = jigs.jig_production_id
								INNER JOIN APCSProDB.jig.production_counters on production_counters.production_id = productions.id
								WHERE jigs.id <> @root_id and root_jig_id = @root_id
								) AS table1 WHERE table1.Cul_ShotPerFrame = 'Expire')
								BEGIN 

										SELECT    'FALSE'													AS Is_Pass
										, '('+(smallcode)+') Kanagata Part Life Time expire. '		AS Error_Message_ENG
										, '('+(smallcode )+N') Kanakata Part หมดอายุการใช้งาน	'		AS Error_Message_THA 
										,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'					AS Handling
										FROM APCSProDB.trans.jigs 
										WHERE jigs.id = @JIG_ID

										RETURN

								END 
								ELSE
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

								END
							END

					--END 
					--	ELSE
					--	BEGIN
					--			IF (@periodcheck_value > @period_value)
					--			BEGIN 
				 
 				--					SELECT  TOP 1  'FALSE'																			AS Is_Pass
 				--							, '('+ qrcodebyuser +') Please CleanShot ('+@periodcheck_value+'/'+@period_value+')'	AS Error_Message_ENG
 				--							, '('+ qrcodebyuser + N') กรุณาทำ CleanShot ('+@periodcheck_value+'/'+@period_value+')'  AS Error_Message_THA 
 				--							, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'												AS Handling 
 				--					FROM APCSProDB.trans.jigs 
 				--					WHERE APCSProDB.trans.jigs.id  = @JIG_ID
 
 				--					RETURN
					--			END 
					--			ELSE
					--			BEGIN

					--					SELECT    'TRUE'												AS Is_Pass		
					--							, ''													AS Error_Message_ENG
					--							, N''													AS Error_Message_THA
					--							, N''													AS Handling
					--							, @QRCode												AS QRCode
					--							, smallcode												AS Smallcode
					--							, productions.name										AS [Type]
					--							, ISNULL(jig_set_list.use_qty,0)						AS QTY
					--							, CONVERT(int,jig_conditions.value)						AS Life_Time
					--							, CONVERT(int,production_counters.alarm_value)			AS STD_Life_Time
					--							, jigs.id												AS jig_id
					--							, FORMAT(COALESCE((CAST(jig_conditions.periodcheck_value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.period_value	,0) ,0), 'N2') AS LifeTime_Percen
					--							, @periodcheck_value									AS  periodcheck_value
					--							, @period_value											AS  period_value
					--					FROM APCSProDB.trans.lots
					--					INNER JOIN APCSProDB.method.device_flows
					--					ON lots.device_slip_id = device_flows.device_slip_id
					--					AND  device_flows.step_no = lots.step_no
					--					INNER JOIN APCSProDB.method.jig_sets 
					--					ON  jig_sets.process_id = device_flows.act_process_id
					--					AND device_flows.jig_set_id = jig_sets.id
					--					INNER JOIN APCSProDB.method.jig_set_list
					--					ON jig_sets.id =  jig_set_list.jig_set_id
					--					INNER JOIN APCSProDB.jig.productions
					--					ON productions.id = jig_set_list.jig_group_id
					--					INNER JOIN [APCSProDB].[jig].[production_counters]  
					--					ON production_counters.production_id = productions.id 
					--					INNER JOIN  APCSProDB.trans.jigs  
					--					ON productions.id	= jigs.jig_production_id
					--					INNER JOIN APCSProDB.trans.jig_conditions  
					--					ON jig_conditions.id			= jigs.id
					--					WHERE lots.lot_no				= @LOTNO
					--					AND  jig_sets.[name]			= @Recipe
			 	--						AND  jigs.id					= @JIG_ID 
					--					and (jig_sets.is_disable IS NULL OR jig_sets.is_disable =0)
							 
					--			END
					--		END
						END
					ELSE IF (@Shot_name IN ( 'HP','PP') )
					BEGIN 
					 
					IF @MCNo <> (SELECT TOP 1 mc_no FROM APCSProDB.trans.jig_records 
								 WHERE jig_records.jig_id = @JIG_ID 
								AND transaction_type = 'To Machine' ORDER BY id DESC)
					BEGIN

							SELECT	  'FALSE' AS Is_Pass
									, @Shot_name +' ('+ jigs.smallcode +') request MCNo not match between BM Online and JIG !!' AS Error_Message_ENG
									, @Shot_name +' ('+ jigs.smallcode +N') นี้ร้องขอ Machine ไม่ตรงกันระหว่าง BM Online และ JIG !!' AS Error_Message_THA
									, N'กรุณาตรวจสอบ MCNo ของ HP ที่เว็บ JIG System' AS Handling
							FROM APCSProDB.trans.jigs 
							WHERE jigs.id = @JIG_ID

							RETURN
					END
					 
						SET @STDLifeTime = (SELECT (CAST(production_counters.alarm_value  AS INT) * 1000 )
											FROM APCSProDB.trans.jigs INNER JOIN 
											APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
											APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
											where jigs.id = @JIG_ID)
						SET @period_value =	(SELECT (CAST(production_counters.period_value  AS INT) * 1000 )
											FROM APCSProDB.trans.jigs INNER JOIN
											APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
											INNER JOIN APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
											where jigs.id = @JIG_ID)

						SET @warn_value =	(SELECT (CAST(APCSProDB.jig.production_counters.warn_value  AS INT) * 1000 )
											FROM APCSProDB.trans.jigs INNER JOIN
											APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
											INNER JOIN APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
											where jigs.id = @JIG_ID)

						SET @LifeTime =		(SELECT (jig_conditions.[value]  ) + @INPUT_QTY
											FROM APCSProDB.trans.jigs 
				 							INNER JOIN APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id 
											INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
											where jigs.id = @JIG_ID)

 						SET @LifeTime_accumulate =		(SELECT (jig_conditions.[value]+ ISNULL(accumulate_lifetime,0)  ) + @INPUT_QTY
											FROM APCSProDB.trans.jigs 
				 							INNER JOIN APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id 
											INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
											where jigs.id = @JIG_ID)

						SET @periodcheck_value =		(SELECT (jig_conditions.periodcheck_value  ) + @INPUT_QTY    
											FROM APCSProDB.trans.jigs 
											INNER JOIN APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id 
											INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
											where jigs.id = @JIG_ID)
						
						
					IF  @LifeTime_accumulate >= @STDLifeTime 
					BEGIN	
							SELECT    'FALSE' AS Is_Pass
									, '('+(smallcode)+') the end of lifetime ' AS Error_Message_ENG
									, '('+(smallcode)+N') LifeTime หมดอายุ  ' AS Error_Message_THA
									, N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system ' AS [Handling]
							FROM APCSProDB.trans.jigs where jigs.id = @JIG_ID 

							RETURN

					END
					ELSE  IF (@LifeTime >= @warn_value  )
					BEGIN 
							SELECT   'FALSE' AS Is_Pass
									, '('+(smallcode)+') To the period. Please cleaning HP/PP ' AS Error_Message_ENG
									, '('+(smallcode)+N') ถึง Period Lifetime แล้ว กรุณานำ HP/PP ไป Cleaning ' AS Error_Message_THA
									, N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system ' AS [Handling]
							FROM APCSProDB.trans.jigs where jigs.id = @JIG_ID 

							RETURN

					END 
					ELSE  IF (@periodcheck_value >= @period_value  )
					BEGIN 
							SELECT   'FALSE' AS Is_Pass
									, '('+(smallcode)+') To the STD Cleaning. Please cleaning HP/PP ' AS Error_Message_ENG
									, '('+(smallcode)+N') ถึง STD Cleaning  แล้ว กรุณานำ HP/PP ไป Cleaning ' AS Error_Message_THA
									, N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system ' AS [Handling]
							FROM APCSProDB.trans.jigs where jigs.id = @JIG_ID 

							RETURN

					END 	
					ELSE 
					BEGIN
					  
						SELECT    'TRUE'											AS Is_Pass 
								, ''												AS Error_Message_ENG
								, ''												AS Error_Message_THA 
								, ''												AS Handling 
								, @QRCode											AS QRCode
								, ISNULL(@QTY,0)									AS QTY
								, smallcode											AS Smallcode
								, productions.[name]								AS [Type] 
								, CONVERT(INT,jig_conditions.[value])				AS Life_Time
								, CONVERT(INT,@STDLifeTime)							AS STD_Life_Time
								, jigs.id											AS jig_id 		
								, FORMAT(COALESCE((CAST(jig_conditions.[value]  AS DECIMAL(18 , 2)) * 
									CAST(100  AS DECIMAL(18 , 2)))/ NULLIF(@STDLifeTime,0) ,0), 'N2') AS LifeTime_Percen
								, @periodcheck_value				AS  periodcheck_value
								,@period_value				AS  period_value
						FROM APCSProDB.trans.jigs  
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON jigs.id = APCSProDB.trans.jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.jig.productions.id = jigs.jig_production_id 
						INNER JOIN APCSProDB.jig.production_counters 
						ON  production_counters.production_id =  productions.id 
						WHERE  jigs.id = @JIG_ID

						RETURN
					END

					END
					ELSE IF (@Shot_name =  'Tsukiage')
					BEGIN
							
						DECLARE @TsukiageNo AS VARCHAR(10),
								@X AS VARCHAR(10),
								@Y AS VARCHAR(10)
						
						SET @Recipe = (SELECT (CASE WHEN UPPER(@Recipe) in ('AD8312','AD833','AD8312PLUS','SD832D') THEN 'ASM' 
										WHEN UPPER(@Recipe) in ('IDBR','IDBW','CANON-D02','CANON-D10','IDBR-P','IDBR-S','IDBW-2','IDBW-3','BESTEM-D02','BESTEM-D10R') THEN 'ROHM'
										WHEN UPPER(@Recipe) in ('2009SSI','ESEC2009 SSI') THEN 'ESECS'
										WHEN UPPER(@Recipe) in ('2100HS','2100XP','ESEC2100 HS','ESEC2100 XP') THEN 'ESECP'
										ELSE @Recipe END))	
						 	
						SET @STDLifeTime = (SELECT APCSProDB.jig.production_counters.alarm_value / 1000
											FROM APCSProDB.trans.jigs INNER JOIN
											APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
											APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id AND production_counters.counter_no = 1
											WHERE barcode = @QRCode)

						SET @LifeTime = (SELECT (APCSProDB.trans.jig_conditions.value / 1000) + (@INPUT_QTY / 1000)
											FROM APCSProDB.trans.jigs INNER JOIN
											APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
											APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
											WHERE barcode = @QRCode)

						IF (@LifeTime > @STDLifeTime  )
						BEGIN 
								SELECT    'FALSE' AS Is_Pass
										, '('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG
										, '('+(smallcode )+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA 
										, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
								FROM APCSProDB.trans.jigs 
								WHERE barcode = @QRCode

								RETURN
						END 


						IF NOT EXISTS (SELECT PIN_NO From [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo) 
						BEGIN
								SELECT   'FALSE' AS Is_Pass
										, N'This LotNo ('+ @LotNo + N') is not found in DENPYO_PRINT. Plase contract System Dept. !!' AS Error_Message_ENG
										, N'ไม่พบข้อมูล LotNo นี้ ('+ @LotNo + N') ในตาราง DENPYO_PRINT. กรุณาติดต่อแผนก System !!' AS Error_Message_THA
										, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
							RETURN
						END
						ELSE 
						BEGIN

							SET @X = (SELECT MANU_COND_CHIP_SIZE_1 From [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo)
							SET @Y = (SELECT MANU_COND_CHIP_SIZE_2 From [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo)

						END 

							--///////////////Found TsukiageNo By MCType
						IF @Recipe = 'ESECS' 
						BEGIN
							IF EXISTS (SELECT tsukiage_no FROM APCSProDB.jig.tsukiage_chipsize_recipes INNER JOIN
												APCSProDB.jig.tsukiage_chipsizes ON tsukiage_chipsize_recipes.tsukiage_chipsize_id = tsukiage_chipsizes.id
												WHERE (@X BETWEEN xmin AND xmax) AND tsukiage_no like '%PIN%') 
							BEGIN

								--MCType ESECS GET TsukiageNo From tsukiage_chipsize_recipes BY X,Y
								SET @TsukiageNo = (SELECT tsukiage_no FROM APCSProDB.jig.tsukiage_chipsize_recipes INNER JOIN
												APCSProDB.jig.tsukiage_chipsizes ON tsukiage_chipsize_recipes.tsukiage_chipsize_id = tsukiage_chipsizes.id
												  WHERE (IIF(@X >@Y ,@Y , @X ) BETWEEN xmin AND xmax) AND tsukiage_no like '%PIN%' )
							END
							ELSE BEGIN
								SELECT 'FALSE' AS Is_Pass,N'ChipSize is not support. Plase check Tsukiage or register Chipsize to correct !!' AS Error_Message_ENG,
								N'ขนาด ChipSize ไม่ตรงกับข้อมูลในระบบ กรุณาตรวจสอบ Tsukiage หรือ ลงทะเบียน ChipSize ให้ถูกต้อง !!' AS Error_Message_THA
								,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
								RETURN
							END
						END
						ELSE IF @Recipe IN ( 'ASM','ESECP')
						BEGIN
							IF EXISTS (SELECT tsukiage_no FROM APCSProDB.jig.tsukiage_chipsize_recipes INNER JOIN
												APCSProDB.jig.tsukiage_chipsizes ON tsukiage_chipsize_recipes.tsukiage_chipsize_id = tsukiage_chipsizes.id
												WHERE (@X BETWEEN xmin AND xmax) AND (@Y BETWEEN ymin AND ymax) AND tsukiage_no like '%A%') 
							BEGIN
		 


								--MCType ASM GET TsukiageNo From tsukiage_chipsize_recipes BY X,Y
								SET @TsukiageNo = (SELECT TOP 1 tsukiage_no FROM APCSProDB.jig.tsukiage_chipsize_recipes INNER JOIN
												APCSProDB.jig.tsukiage_chipsizes ON tsukiage_chipsize_recipes.tsukiage_chipsize_id = tsukiage_chipsizes.id
												WHERE (@X BETWEEN xmin AND xmax) AND (@Y BETWEEN ymin AND ymax) AND tsukiage_no like '%A%')
							END
							ELSE BEGIN
								SELECT    'FALSE' AS Is_Pass
										, N'ChipSize is not support. Plase check Tsukiager or register Chipsize to correct !!' AS Error_Message_ENG
										, N'ขนาด ChipSize ไม่ตรงกับข้อมูลในระบบ กรุณาตรวจสอบ Tsukiage หรือ ลงทะเบียน ChipSize ให้ถูกต้อง !!' AS Error_Message_THA
										, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
								RETURN
							END
						END
						ELSE BEGIN
							--Another MCType GET TsukiageNo From DENPYO_PRINT BY LotNo
							SET @TsukiageNo = (SELECT PIN_NO From [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo)
						END

 
						--///////////Check Match Data Form JIG.tsukiage_recipes by SubtypeId,RubberNo,MachineType
						IF NOT EXISTS (select 1 from APCSProDB.jig.tsukiage_recipes 
									WHERE production_id = (SELECT jig_production_id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)
									AND tsukiage_no = @TsukiageNo AND machine_type = @Recipe ) 
						BEGIN
								SELECT 'FALSE' AS Is_Pass
								,N'Miss match TsukiageNo ('+ @TsukiageNo +') is not register or This Machine Type ('+ @Recipe +') registration is invalid. !!' AS Error_Message_ENG,
								N'ข้อมูล TsukiageNo ไม่ตรงกัน หรือ TsukiageNo นี้ ('+ @TsukiageNo +N') ยังไม่ได้ลงทะเบียน หรือ Machine Type นี้ ('+ @Recipe +N') ลงทะเบียนไม่ถูกต้อง !!' AS Error_Message_THA
								,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
							
								RETURN
						END


								SELECT    'TRUE'											AS Is_Pass 
										, ''												AS Error_Message_ENG
										, ''												AS Error_Message_THA 
										, ''												AS Handling 
										, @QRCode											AS QRCode
										, ISNULL(@QTY,0)									AS QTY
										, smallcode											AS Smallcode
										, productions.[name]								AS [Type] 
										, CONVERT(INT,jig_conditions.[value])				AS Life_Time
										, CONVERT(INT,@STDLifeTime)							AS STD_Life_Time
										, jigs.id											AS jig_id 		
										, FORMAT(COALESCE((CAST(jig_conditions.[value]  AS DECIMAL(18 , 2)) *CAST(100  AS DECIMAL(18 , 2)))/ NULLIF(@STDLifeTime,0) ,0), 'N2') AS LifeTime_Percen
										, @periodcheck_value				AS  periodcheck_value
										,@period_value				AS  period_value
								FROM APCSProDB.trans.jigs  
								INNER JOIN APCSProDB.trans.jig_conditions 
								ON jigs.id = APCSProDB.trans.jig_conditions.id 
								INNER JOIN APCSProDB.jig.productions 
								ON APCSProDB.jig.productions.id = jigs.jig_production_id 
								INNER JOIN APCSProDB.jig.production_counters 
								ON  production_counters.production_id =  productions.id 
								WHERE  jigs.id = @JIG_ID

						RETURN
					END

					ELSE IF (@Shot_name =  'RubberCollet')
					BEGIN

							DECLARE  @RubberNO  AS VARCHAR(10)

							SET @Recipe		= ( SELECT (CASE WHEN UPPER(@Recipe) in('AD8312','AD8312PLUS','AD833','ROHM','2100HS','ESEC2100 HS','2100XP' ,
													'ESEC2100 XP','IDBR','IDBR-S','IDBR-P','IDBW','IDBW-2','IDBW-3','CANON-D02','BESTEM-D02','CANON-D10R','BESTEM-D10R') 
													THEN 'ROHM/ASM'  
													WHEN UPPER(@Recipe) in ('2009SSI','ESEC2009 SSI','SD832D') 
													THEN 'ESECS' 
													ELSE @Recipe END))
	
							SET @STDLifeTime = (SELECT APCSProDB.jig.production_counters.alarm_value / 1000
												FROM APCSProDB.trans.jigs 
												INNER JOIN APCSProDB.jig.productions 
												ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
												INNER JOIN APCSProDB.jig.production_counters 
												ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
												AND production_counters.counter_no = 1
												WHERE barcode = @QRCode)

							SET @LifeTime = (SELECT (APCSProDB.trans.jig_conditions.value / 1000) + (@INPUT_QTY / 1000)
												FROM APCSProDB.trans.jigs 
												INNER JOIN APCSProDB.trans.jig_conditions 
												ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id 
												INNER JOIN APCSProDB.jig.productions 
												ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
												WHERE barcode = @QRCode)
													--///////////////Found Data in DENPYO_PRINT BY LotNo
							IF NOT EXISTS (SELECT RUBBER_NO From [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo) 
							BEGIN
									SELECT	  'FALSE'																						AS Is_Pass
											, N'This LotNo ('+ @LotNo + N') is not found in DENPYO_PRINT. Plase contract System Dept. !!'	AS Error_Message_ENG
											, N'ไม่พบข้อมูล LotNo นี้ ('+ @LotNo + N') ในตาราง DENPYO_PRINT. กรุณาติดต่อแผนก System !!'				AS Error_Message_THA
											, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'														AS Handling
								RETURN
							END
							ELSE BEGIN
								SET @X = (SELECT MANU_COND_CHIP_SIZE_1 From [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo)
								SET @Y = (SELECT MANU_COND_CHIP_SIZE_2 From [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo)
							END

							--///////////////Found RubberNo By MCType
							IF @Recipe = 'ESECS' 
							BEGIN
								IF EXISTS (SELECT rubber_no 
											FROM APCSProDB.jig.collet_chipsize_recipes 
											INNER JOIN APCSProDB.jig.chipsizes 
											ON chipsize_id = chipsizes.id
											WHERE (@X BETWEEN xmin AND xmax) 
											AND (@Y BETWEEN ymin AND ymax)
											) 
								BEGIN
									--MCType ESECS GET RubberNo From collet_chipsize_recipes BY X,Y
									SET @RubberNO = ( SELECT TOP 1 rubber_no as RubberNo 
														FROM APCSProDB.jig.collet_chipsize_recipes 
														INNER JOIN APCSProDB.jig.chipsizes 
														ON chipsize_id = chipsizes.id
														WHERE (@X BETWEEN xmin AND xmax) 
														AND	(@Y BETWEEN ymin AND ymax)
														)
								END
								ELSE BEGIN
									SELECT	  'FALSE'																				AS Is_Pass
											, N'ChipSize is not support. Plase check RubberNo or register Chipsize to correct !!'	AS Error_Message_ENG
											, N'ขนาด ChipSize ไม่ตรงกับข้อมูลในระบบ กรุณาตรวจสอบ Rubber หรือ ลงทะเบียน ChipSize ให้ถูกต้อง !!'	AS Error_Message_THA
											, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'												AS Handling
									RETURN
								END
							END
							ELSE BEGIN
								--Another MCType GET RubberNo From DENPYO_PRINT BY LotNo
								SET @RubberNO = (SELECT RUBBER_NO From [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_2 = @LotNo)
							END

							--///////////Check Match Data Form JIG.ColletRecipe by SubtypeId,RubberNo,MachineType
							IF NOT EXISTS (SELECT 1 FROM APCSProDB.jig.collet_recipes 
											WHERE production_id = (SELECT jig_production_id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)
											AND collet_no = @RubberNO AND machine_type = @Recipe ) 
							BEGIN
									SELECT    'FALSE'																															AS Is_Pass
											, N'Miss match RubberNo ('+ @RubberNO +') is not register or This Machine Type ('+ @Recipe +') registration is invalid. !!'			AS Error_Message_ENG
											, N'ข้อมูล RubberNo ไม่ตรงกัน หรือ RubberNo นี้ ('+ @RubberNO +N') ยังไม่ได้ลงทะเบียน หรือ Machine Type นี้ ('+ @Recipe +N') ลงทะเบียนไม่ถูกต้อง !!'		AS Error_Message_THA
											, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'																							AS Handling
									RETURN
							END


									--//RETUEN DATA
						SELECT    'TRUE'											AS Is_Pass
								, ''												AS Error_Message_ENG
								, ''												AS Error_Message_THA 
								, ''												AS Handling 
								, @QRCode											AS QRCode
								, ISNULL(@QTY,0)									AS QTY
								, smallcode											AS Smallcode
								, productions.name									AS [Type] 
								, CONVERT(int,jig_conditions.value)					AS Life_Time
								, CONVERT(int,@STDLifeTime)							AS STD_Life_Time
								, jigs.id											AS jig_id 		
								, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(@STDLifeTime,0) ,0), 'N2') AS LifeTime_Percen
								, @periodcheck_value								AS  periodcheck_value
								, @period_value										AS  period_value
						FROM APCSProDB.trans.jigs  
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON jigs.id = APCSProDB.trans.jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.jig.productions.id = jigs.jig_production_id 
						INNER JOIN APCSProDB.jig.production_counters 
						ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
						WHERE  jigs.id = @JIG_ID
			
						RETURN 


					END 

					ELSE   -- JIG Wedge , Wire ,Cutter
					BEGIN   

							 
					SELECT    @QTY =  jig_set_list.use_qty		 
					FROM  (SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id 
										ELSE device_flows.jig_set_id   END  AS jig_set_id  
										,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
										ELSE device_flows.act_process_id   END  AS act_process_id 
										,lots.lot_no
										, device_flows.recipe
									 , device_flows.id
									 ,lots.device_slip_id
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
						WHERE  jigs.id = @JIG_ID
						AND  jig_sets.id IS NOT NULL 

	 
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
						SELECT    'TRUE'											AS Is_Pass
								, ''												AS Error_Message_ENG
								, ''												AS Error_Message_THA 
								, ''												AS Handling 
								, @QRCode											AS QRCode
								, ISNULL(@QTY,0)									AS QTY
								, smallcode											AS Smallcode
								, productions.name									AS [Type] 
								, CONVERT(int,jig_conditions.value)					AS Life_Time
								, CONVERT(int,production_counters.alarm_value)		AS STD_Life_Time
								, jigs.id											AS jig_id 		
								, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
								, @periodcheck_value								AS  periodcheck_value
								, @period_value										AS  period_value
						FROM APCSProDB.trans.jigs  
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON jigs.id = APCSProDB.trans.jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.jig.productions.id = jigs.jig_production_id 
						INNER JOIN APCSProDB.jig.production_counters 
						ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
						WHERE  jigs.id = @JIG_ID

						RETURN
					END
				  
				
				 
				END
				ELSE 
				BEGIN 

			 		IF (@Shot_name = 'Dicer Blade')
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
						 
							SELECT    'TRUE'											AS Is_Pass
									, ''												AS Error_Message_ENG
									, ''												AS Error_Message_THA 
									, ''												AS Handling 
									, @QRCode											AS QRCode
									, ISNULL(@QTY,0)									AS QTY
									, smallcode											AS Smallcode
									, productions.name									AS [Type] 
									, CONVERT(int,jig_conditions.value)					AS Life_Time
									, CONVERT(int,production_counters.alarm_value)		AS STD_Life_Time
									, jigs.id											AS jig_id 		
									, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
									, @periodcheck_value								AS  periodcheck_value
									, @period_value										AS  period_value
							FROM APCSProDB.trans.jigs  
							INNER JOIN APCSProDB.trans.jig_conditions 
							ON jigs.id = APCSProDB.trans.jig_conditions.id 
							INNER JOIN APCSProDB.jig.productions 
							ON APCSProDB.jig.productions.id = jigs.jig_production_id 
							INNER JOIN APCSProDB.jig.production_counters 
							ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
							WHERE  jigs.id = @JIG_ID

							RETURN
					--END

					END
					ELSE 
					BEGIN
							SELECT    'FALSE'											AS Is_Pass
									, 'Device slips this jig type ('+ @type	+') has not been registered yet !!'	AS Error_Message_ENG
									, N'Device slips นี้ยังไม่ถูกลงทะเบียน jig type ('+ @type	+')'				AS Error_Message_THA
									, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'					AS Handling
							RETURN		
					END

				END
			END
END
