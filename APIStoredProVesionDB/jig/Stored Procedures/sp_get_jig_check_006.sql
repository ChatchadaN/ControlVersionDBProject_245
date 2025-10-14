-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_get_jig_check_006]
(
	  @QRCode			AS NVARCHAR(MAX)  
	, @Recipe			AS NVARCHAR(50)	=  ''    --, @WBCode	AS VARCHAR(50) = ''
	, @INPUT_QTY		AS INT			=  1
	, @LOTNO			AS NVARCHAR(10)
	, @OPNo				AS NVARCHAR(6) 
)
AS
BEGIN

 
	DECLARE		  @JIG_ID				AS INT
				, @MC_ID				AS INT
				, @STDLifeTime			AS INT
				, @LifeTime				AS INT
				, @Safety				AS INT
				, @Accu					AS INT
				, @OPID					AS INT
				, @State				AS INT
				, @Smallcode			AS VARCHAR(4)
				, @step_no_now			INT 
				, @lot_id				INT 
				, @QTY					INT 
				, @Category				AS NVARCHAR(50)
				, @periodcheck_value	AS INT
				, @period_value			AS INT
				, @Shot_name			AS NVARCHAR(20)
				, @root_id				AS INT 
				, @process_id			INT 
				, @type					NVARCHAR(100)
 
 				, @FrameLot				AS VARCHAR(50)
				, @FrameHP				AS VARCHAR(50)
				, @FramePP				AS VARChAR(50)
	 			, @warn_value			AS INT
				, @LifeTime_accumulate	AS INT 

	SELECT	  @JIG_ID				= jigs.id 
			, @State				= jig_state 
			, @Smallcode			= jigs.smallcode  
			, @Shot_name			= categories.short_name
			, @Category				= categories.[name]
			, @root_id				= jigs.id
			, @periodcheck_value	= ISNULL(jig_conditions.periodcheck_value , 0)
		    , @period_value			= ISNULL(production_counters.period_value , 0)
			, @STDLifeTime			= ISNULL(productions.expiration_value, 0)
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

	INSERT INTO APIStoredProDB.[dbo].[exec_sp_history_jig]
		(	
				  [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no]
				, jig_id
				, barcode
		)
		SELECT    GETDATE()
				, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'EXEC [jig].[sp_get_jig_check_006] @INPUT_QTY  = ''' + ISNULL(CAST(@INPUT_QTY AS nvarchar(MAX)),'') + ''', @JIG_ID = ''' + ISNULL(CAST(@JIG_ID AS nvarchar(MAX)),'') + ''', @QRCode = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') + ''',@OpNO = ''' 
					+ ISNULL(CAST(@OpNO AS nvarchar(MAX)),'') +  ''',@Recipe = ''' + ISNULL(CAST(@Recipe AS nvarchar(MAX)),'') + ''''
				, @LOTNO
				, @JIG_ID
				, @QRCode

	IF NOT EXISTS (SELECT  sp_jig.jig_set_id
						FROM 
								(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id 
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
						AND   ISNULL(jig_sets.is_disable,0) = 0 
						)
	BEGIN 

			SELECT    'FALSE'											AS Is_Pass
					, 'Device slips this jig type ('+ @type	+') has not been registered yet !!'	AS Error_Message_ENG
					, N'Device slips นี้ยังไม่ถูกลงทะเบียน jig type ('+ @type	+')'				AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'					AS Handling
			RETURN		
			
	END 
	ELSE
	BEGIN 

		IF (@Shot_name = 'Dicer Blade')
		BEGIN 
		--	IF EXISTS (  SELECT  table1.quantity 
		--			 FROM	  (SELECT  production_counters.alarm_value  AS STDLifeTime
		--			 		, (CASE WHEN (value) > jigs.quantity  THEN 'Expire' ELSE 'Ready' END) AS quantity
		--			 		, root_jig_id 
		--			 FROM APCSProDB.trans.jigs 
		--			 INNER JOIN APCSProDB.trans.jig_conditions 
		--			 ON jigs.id = jig_conditions.id 
		--			 INNER JOIN APCSProDB.jig.productions 
		--			 ON APCSProDB.jig.productions.id = jigs.jig_production_id
		--			 INNER JOIN APCSProDB.jig.production_counters 
		--			 ON production_counters.production_id = productions.id
		--			 WHERE jigs.id =  @JIG_ID
		--			 ) AS  table1 
		--			 WHERE table1.quantity = 'Expire'
		--		)

		--BEGIN
		--			SELECT	  'FALSE'							AS Is_Pass
		--					, 'Blade Life Time expire. !!'		AS Error_Message_ENG
		--					, N'Blade หมดอายุการใช้งาน !!'			AS Error_Message_THA
		--					, N'ตรวจสอบ Blade ที่หมดอายุที่เว็บ JIG'	AS Handling
		--					, CAST(jig_conditions.value AS INT) AS Life_Time
		--					, CAST(jigs.quantity AS  INT)		AS STD_Life_Time
		--			FROM APCSProDB.trans.jigs  
		--			INNER JOIN APCSProDB.trans.jig_conditions 
		--			ON jigs.id = APCSProDB.trans.jig_conditions.id 
		--			INNER JOIN APCSProDB.jig.productions 
		--			ON APCSProDB.jig.productions.id = jigs.jig_production_id 
		--			INNER JOIN APCSProDB.jig.production_counters 
		--			ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
		--			where jigs.id  = @JIG_ID

		--	END
		--ELSE
		--	BEGIN

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
								, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
								, @periodcheck_value								AS  periodcheck_value
								, @period_value										AS  period_value
						FROM APCSProDB.trans.jigs  
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON jigs.id = jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions 
						ON productions.id = jigs.jig_production_id 
						INNER JOIN APCSProDB.jig.production_counters 
						ON production_counters.production_id = productions.id 
						WHERE jigs.id = @JIG_ID
			--END
	 
		END 
		ELSE IF (@Shot_name = 'Kanagata')
		BEGIN 
			 
				 SET @QTY =  (	SELECT TOP 1 jig_set_list.use_qty
									FROM 
									(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id 
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
							AND  jig_sets.id IS NOT NULL  ) 

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
											, N'('+(smallcode)+') Kanagata Part Life Time expire. '		AS Error_Message_ENG
											, N'('+(smallcode )+N') Kanakata Part หมดอายุการใช้งาน	'		AS Error_Message_THA 
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
												, @type												AS [Type]
												, ISNULL(@QTY,0)									AS QTY
												, CONVERT(INT,[LifeTime])							AS Life_Time
												, expiration_value									AS STD_Life_Time			
												, @JIG_ID											AS jig_id
												, ISNULL(LifeTime_Percen,0)							AS LifeTime_Percen
												, ISNULL(periodcheck_value	,0)						AS  periodcheck_value
												, ISNULL(period_value	,0)							AS  period_value
									FROM  
										(	SELECT		  warn_value AS warn_value
														, APCSProDB.trans.jig_conditions.value   AS [LifeTime]
														, FORMAT(COALESCE((CAST(jig_conditions.value AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF( production_counters.alarm_value  ,0) ,0), 'N2') AS LifeTime_Percen
														, jigs.smallcode
														, productions.name		AS [Type]
														, jigs.id				AS jig_id 
														,  production_counters.alarm_value   AS expiration_value
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
		ELSE IF (@Shot_name = 'Capillary')
		BEGIN 
				IF  @LifeTime >= @STDLifeTime 
				BEGIN 

					IF EXISTS (SELECT  '1'    
								FROM APCSProDB.method.device_names 
								INNER JOIN  APCSProDB.trans.lots 
								ON  lots.act_device_name_id = device_names.id 
								WHERE alias_package_group_id  = 33 AND lot_no = @LOTNO)
					BEGIN 
			 
								SELECT    'FALSE'											AS Is_Pass
										, '('+(barcode)+')  Insufficient for production !!' AS Error_Message_ENG
										, '('+(barcode)+N') ไม่เพียงพอต่อการผลิต !!'				AS Error_Message_THA
										, N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system !!'	AS Handling
										, 1 AS Is_gdic
								FROM APCSProDB.trans.jigs where barcode = @QRCode
					END
					ELSE 
					BEGIN  
								SELECT    'FALSE'												AS Is_Pass
										, '('+(barcode)+')  Insufficient for production !!'		AS Error_Message_ENG
										, '('+(barcode)+N') ไม่เพียงพอต่อการผลิต !!'					AS Error_Message_THA
										, N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system !!'		AS [Handling]
										, 0 AS Is_gdic
								FROM APCSProDB.trans.jigs where barcode = @QRCode
					END 
				END
				ELSE 
				BEGIN


						SELECT   TOP 1 'TRUE'										AS Is_Pass		
								, ''												AS Error_Message_ENG
								, N''												AS Error_Message_THA
								, N''												AS Handling
								, @QRCode											AS QRCode
								, smallcode											AS Smallcode
								, productions.name									AS [Type]
								, 0													AS QTY
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
		ELSE IF (@Shot_name IN ( 'HP', 'PP'))
		BEGIN 

							SET @STDLifeTime = (SELECT (CAST(production_counters.alarm_value  AS bigint) * 1000 )
												FROM APCSProDB.trans.jigs INNER JOIN 
												APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
												APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
												where jigs.id = @JIG_ID)
							SET @period_value =	(SELECT (CAST(production_counters.period_value  AS bigint) * 1000 )
												FROM APCSProDB.trans.jigs INNER JOIN
												APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
												INNER JOIN APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
												where jigs.id = @JIG_ID)

							SET @warn_value =	(SELECT (CAST(APCSProDB.jig.production_counters.warn_value  AS bigint) * 1000 )
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

					IF (@Category =  'HP')	
					BEGIN 
				 
						--Find HP/PP OnMachine
						IF NOT EXISTS (SELECT 'xxx'
										FROM APCSProDB.trans.machine_jigs
										INNER JOIN APCSProDB.mc.machines
										ON machines.id  = machine_jigs.machine_id
										WHERE jig_id =   @JIG_ID) 
						BEGIN 

									SELECT	  'FALSE' AS Is_Pass
										, @Shot_name +' ('+ jigs.smallcode +') request MCNo not match between BM Online and JIG !!' AS Error_Message_ENG
										, @Shot_name +' ('+ jigs.smallcode +N') นี้ร้องขอ Machine ไม่ตรงกันระหว่าง BM Online และ JIG !!' AS Error_Message_THA
										, N'กรุณาตรวจสอบ MCNo ของ HP ที่เว็บ JIG System' AS Handling
								FROM APCSProDB.trans.jigs 
								WHERE jigs.id = @JIG_ID

								RETURN
						END
								SET @FrameLot	= (SELECT TRIM(FRAME_NAME) AS FRAME_NAME  
													FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] 
													WHERE LOT_NO_1 =  @LotNo)
								SET @FrameHP	= (SELECT DISTINCT APCSProDB.jig.productions.[name] 
													FROM APCSProDB.trans.jigs 
													INNER JOIN APCSProDB.jig.productions 
													ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
													INNER JOIN APCSProDB.jig.categories 
													ON APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
													WHERE APCSProDB.trans.jigs.id = @JIG_ID  )

						IF NOT EXISTS(SELECT 1 FROM APCSProDB.jig.common_frametypes 
										WHERE APCSProDB.jig.common_frametypes.frametype = @FrameHP
										AND APCSProDB.jig.common_frametypes.common_frametype = @FrameLot)
								BEGIN
									SELECT    'FALSE' AS Is_Pass
											, 'Frame Type HP ('+@FrameHP+') and Frame Type LotNo ('+@FrameLot+') not match !!' AS Error_Message_ENG
											, N'Frame Type ของ HP ('+@FrameHP+N') และ Frame Type ของ LotNo  ('+@FrameLot+N') นี้ไม่ตรงกัน !!' AS Error_Message_THA
											, N'กรุณาตรวจสอบ Frame Type ของ HP ที่เว็บ JIG System' AS Handling 
									RETURN
						END ELSE
						BEGIN 
				 
					 
						SELECT   TOP 1 'TRUE'										AS Is_Pass		
								, ''												AS Error_Message_ENG
								, N''												AS Error_Message_THA
								, N''												AS Handling
								, @QRCode											AS QRCode
								, smallcode											AS Smallcode
								, productions.name									AS [Type]
								, 0													AS QTY
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
					END
					ELSE
					BEGIN
							IF NOT EXISTS (SELECT 'xxx'
											FROM APCSProDB.trans.machine_jigs
											INNER JOIN APCSProDB.mc.machines
											ON machines.id  = machine_jigs.machine_id
											WHERE jig_id =   @JIG_ID) 
						BEGIN

								SELECT    'FALSE'																		AS Is_Pass
										, 'HP is not found on machine this. '							AS Error_Message_ENG
										, N'ไม่พบข้อมูล HP ที่ Machine เครื่องนี้กรุณาร้องขอ HP ที่ BM Online !!'	AS Error_Message_THA
										, N' นี้กรุณาร้องขอ HP ที่ BM Online !!'												AS Handling
								--FROM APCSProDB.trans.machine_jigs
								--INNER JOIN APCSProDB.mc.machines
								--ON machines.id  = machine_jigs.machine_id
								--WHERE jig_id =   @JIG_ID

								RETURN
						END
								SET @FrameLot	= (SELECT TRIM(FRAME_NAME) AS FRAME_NAME  FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] where LOT_NO_1 =  @LotNo)
								SET @FramePP	= (SELECT DISTINCT APCSProDB.jig.productions.[name] 
													FROM APCSProDB.trans.jigs 
													INNER JOIN APCSProDB.jig.productions 
													ON APCSProDB.jig.productions.id = APCSProDB.trans.jigs.jig_production_id
													INNER JOIN APCSProDB.jig.categories 
													ON APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id
													WHERE APCSProDB.trans.jigs.id = @JIG_ID )

						IF NOT EXISTS(SELECT 1 FROM APCSProDB.jig.common_frametypes 
										WHERE APCSProDB.jig.common_frametypes.frametype = @FramePP
										AND APCSProDB.jig.common_frametypes.common_frametype = @FrameLot)
								BEGIN
									SELECT    'FALSE' AS Is_Pass
											, 'Frame Type  ('+@FramePP+') and Frame Type LotNo ('+@FrameLot+') not match !!' AS Error_Message_ENG
											, N'Frame Type ('+@FramePP+ N') ของ PP และ Frame Type ('+@FrameLot+N') ของ LotNo นี้ไม่ตรงกัน !!' AS Error_Message_THA
											, N'กรุณาตรวจสอบ Frame Type ของ PP ที่เว็บ JIG System' AS Handling
									
									RETURN
						END ELSE
						BEGIN  
								SELECT   TOP 1 'TRUE'										AS Is_Pass		
										, ''												AS Error_Message_ENG
										, N''												AS Error_Message_THA
										, N''												AS Handling
										, @QRCode											AS QRCode
										, smallcode											AS Smallcode
										, productions.name									AS [Type]
										, 0													AS QTY
										, CONVERT(int,jig_conditions.value)					AS Life_Time
										, CONVERT(int,@STDLifeTime)		AS STD_Life_Time
										, jigs.id											AS jig_id
										, FORMAT(COALESCE((CAST(jig_conditions.value  AS DECIMAL(18 , 2)) * CAST(100  AS DECIMAL(18 , 2)))/ NULLIF(@STDLifeTime,0) ,0), 'N2') AS LifeTime_Percen
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

		END 
		ELSE IF (@Shot_name = 'Tsukiage' )
		BEGIN	
						SET @STDLifeTime = (SELECT APCSProDB.jig.production_counters.alarm_value / 1000
											FROM APCSProDB.trans.jigs INNER JOIN
											APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
											APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id AND production_counters.counter_no = 1
											where barcode = @QRCode)

						SET @LifeTime = (SELECT (APCSProDB.trans.jig_conditions.value / 1000) + (@INPUT_QTY / 1000)
											FROM APCSProDB.trans.jigs INNER JOIN
											APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
											APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
											where barcode = @QRCode)

						IF (@LifeTime > @STDLifeTime  )
						BEGIN 
								SELECT    'FALSE' AS Is_Pass
										, '('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG
										, '('+(smallcode )+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA 
										,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
								FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
								RETURN
						END 
						ELSE 
						BEGIN 

							SELECT   TOP 1 'TRUE'										AS Is_Pass		
									, ''												AS Error_Message_ENG
									, N''												AS Error_Message_THA
									, N''												AS Handling
									, @QRCode											AS QRCode
									, smallcode											AS Smallcode
									, productions.name									AS [Type]
									, 0													AS QTY
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

		END 
		ELSE IF (@Shot_name = 'RubberCollet')
		BEGIN
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

						IF (@LifeTime > @STDLifeTime  )
						BEGIN 
								SELECT    'FALSE' AS Is_Pass
										, '('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG
										, '('+(smallcode )+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA 
										,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
								FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
								RETURN
						END 
						ELSE 
						BEGIN 

							SELECT   TOP 1 'TRUE'										AS Is_Pass		
									, ''												AS Error_Message_ENG
									, N''												AS Error_Message_THA
									, N''												AS Handling
									, @QRCode											AS QRCode
									, smallcode											AS Smallcode
									, productions.name									AS [Type]
									, 0													AS QTY
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
		END 
		ELSE
		BEGIN 
	  
					SELECT    @QTY =  jig_set_list.use_qty		 
								FROM 
									(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id 
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


					SET @STDLifeTime = (SELECT  APCSProDB.jig.production_counters.alarm_value  
								FROM APCSProDB.trans.jigs
								INNER JOIN APCSProDB.jig.productions 
								ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
								INNER JOIN APCSProDB.jig.production_counters 
								ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
								WHERE jigs.id = @JIG_ID)

					SET @LifeTime =	   (SELECT (APCSProDB.trans.jig_conditions.value + (@INPUT_QTY * @QTY)) 
								FROM APCSProDB.trans.jigs 
								INNER JOIN APCSProDB.trans.jig_conditions 
								ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id  
								INNER JOIN APCSProDB.jig.productions 
								ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
								WHERE jigs.id = @JIG_ID)
  

 
					IF (@LifeTime > @STDLifeTime  )
					BEGIN 

 						SELECT    'FALSE' AS Is_Pass
 								, N'('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG
 								, N'('+(smallcode )+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA 
 								,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
 						FROM APCSProDB.trans.jigs 
 						WHERE jigs.id = @JIG_ID
 						RETURN
 
					END 


					SELECT    'TRUE'											AS Is_Pass		
								, ''												AS Error_Message_ENG
								, N''												AS Error_Message_THA
								, N''												AS Handling
								, @QRCode											AS QRCode
								, smallcode											AS Smallcode
								, productions.name									AS [Type]
								, ISNULL(jig_set_list.use_qty,0)					AS QTY
								, CONVERT(int,jig_conditions.[value])					AS Life_Time
								, CONVERT(int,production_counters.alarm_value)		AS STD_Life_Time
								, jigs.id											AS jig_id
 								, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
								, @periodcheck_value								AS  periodcheck_value
								, @period_value										AS  period_value
						FROM 
									(SELECT  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].jig_set_id 
											ELSE device_flows.jig_set_id   END  AS jig_set_id  
											,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].act_process_id 
											ELSE device_flows.act_process_id   END  AS act_process_id 
											,lots.lot_no
											,  CASE WHEN lots.is_special_flow =  1 THEN    [lot_special_flows].recipe 
											ELSE device_flows.recipe   END  AS recipe 
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
						INNER JOIN [APCSProDB].[jig].[production_counters]  
						ON production_counters.production_id = productions.id 
						INNER JOIN  APCSProDB.trans.jigs  
						ON productions.id	= jigs.jig_production_id
						INNER JOIN APCSProDB.trans.jig_conditions  
						ON jig_conditions.id = jigs.id
						WHERE jigs.id   = @JIG_ID 
						AND   ISNULL(jig_sets.is_disable,0) = 0 

						RETURN 
		 
			END
	END 
END
