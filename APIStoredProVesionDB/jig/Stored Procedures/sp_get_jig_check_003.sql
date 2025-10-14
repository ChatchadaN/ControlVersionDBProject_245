-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_get_jig_check_003]
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
				, [lot_no]
				, jig_id
				, barcode
		)
		SELECT    GETDATE()
				, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'EXEC [jig].[sp_get_jig_check] @INPUT_QTY  = ''' + ISNULL(CAST(@INPUT_QTY AS nvarchar(MAX)),'') + ''', @JIG_ID = ''' + ISNULL(CAST(@JIG_ID AS nvarchar(MAX)),'') + ''', @QRCode = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') + ''',@OpNO = ''' 
					+ ISNULL(CAST(@OpNO AS nvarchar(MAX)),'') +  ''',@Recipe = ''' + ISNULL(CAST(@Recipe AS nvarchar(MAX)),'') + ''''
				, @LOTNO
				, @JIG_ID
				, @QRCode



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
	ELSE 
	IF (@Shot_name = 'Kanagata')
	BEGIN 

		IF EXISTS ( SELECT name FROM APCSProDB.method.packages  WHERE short_name = @Recipe)
					BEGIN 
						SET @Recipe =  ( SELECT name FROM APCSProDB.method.packages  WHERE short_name = @Recipe)
		END

			IF EXISTS(SELECT jig_sets.id 
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
					ON productions.id				= jigs.jig_production_id
					WHERE lots.lot_no				= @LOTNO
					AND  ISNULL(jig_sets.[name],'')	= @Recipe
					AND  (jigs.id				= @JIG_ID)
					AND  jig_sets.id IS NOT NULL ) 
			BEGIN
 
				--IF (@Category =  'Kanagata Base')
				--BEGIN 
				   
				--	IF (@periodcheck_value > @period_value)
				--	BEGIN 
				 
 			--			SELECT    'FALSE'										AS Is_Pass
 			--					, '('+ qrcodebyuser +') Please CleanShot ('+@periodcheck_value+'/'+@period_value+')'	AS Error_Message_ENG
 			--					, '('+ qrcodebyuser + N') กรุณาทำ CleanShot ('+@periodcheck_value+'/'+@period_value+')'  AS Error_Message_THA 
 			--					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'		AS Handling 
 			--			FROM APCSProDB.trans.jigs 
 			--			WHERE APCSProDB.trans.jigs.id  = @JIG_ID
 
 			--			RETURN
				--	END 
				--	ELSE
				--	BEGIN 
				--		SELECT    'TRUE'												AS Is_Pass		
				--				, ''													AS Error_Message_ENG
				--				, N''													AS Error_Message_THA
				--				, N''													AS Handling
				--				, @QRCode												AS QRCode
				--				, smallcode												AS Smallcode
				--				, productions.name										AS [Type]
				--				, ISNULL(jig_set_list.use_qty,0)						AS QTY
				--				, CONVERT(int,jig_conditions.value)						AS Life_Time
				--				, CONVERT(int,production_counters.alarm_value)			AS STD_Life_Time
				--				, jigs.id												AS jig_id
				--				, FORMAT(COALESCE((CAST(jig_conditions.periodcheck_value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.period_value	,0) ,0), 'N2') AS LifeTime_Percen
				--				, @periodcheck_value									AS  periodcheck_value
				--				, @period_value											AS  period_value
				--		FROM APCSProDB.trans.lots
				--		INNER JOIN APCSProDB.method.device_flows
				--		ON lots.device_slip_id = device_flows.device_slip_id
				--		AND  device_flows.step_no = lots.step_no
				--		INNER JOIN APCSProDB.method.jig_sets 
				--		ON  jig_sets.process_id = device_flows.act_process_id
				--		AND device_flows.jig_set_id = jig_sets.id
				--		INNER JOIN APCSProDB.method.jig_set_list
				--		ON jig_sets.id =  jig_set_list.jig_set_id
				--		INNER JOIN APCSProDB.jig.productions
				--		ON productions.id = jig_set_list.jig_group_id
				--		INNER JOIN [APCSProDB].[jig].[production_counters]  
				--		ON production_counters.production_id = productions.id 
				--		INNER JOIN  APCSProDB.trans.jigs  
				--		ON productions.id	= jigs.jig_production_id
				--		INNER JOIN APCSProDB.trans.jig_conditions  
				--		ON jig_conditions.id			= jigs.id
				--		WHERE lots.lot_no				= @LOTNO
				--		AND  jig_sets.[name]			= @Recipe
			 --			AND  jigs.id					= @JIG_ID 
				--		and (jig_sets.is_disable IS NULL OR jig_sets.is_disable =0)
				--	END 
				--END
				--ELSE
				--BEGIN

				SET @QTY =  (	SELECT jig_set_list.use_qty
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
								ON productions.id				= jigs.jig_production_id
								WHERE lots.lot_no				= @LOTNO
								AND  ISNULL(jig_sets.[name],'')	= @Recipe
								AND  (jigs.id				= @JIG_ID)
								AND  jig_sets.id IS NOT NULL ) 

						SET @STDLifeTime = (SELECT TOP 1 APCSProDB.jig.production_counters.alarm_value  
											FROM APCSProDB.trans.jigs
											INNER JOIN APCSProDB.jig.productions 
											ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
											INNER JOIN APCSProDB.jig.production_counters 
											ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
											WHERE jigs.id <> @root_id AND root_jig_id = @root_id 
											)

						SET @LifeTime =		(SELECT TOP 1 (((APCSProDB.trans.jig_conditions.value + production_counters.period_value ) / @INPUT_QTY )/ @QTY)
											FROM APCSProDB.trans.jigs 
											INNER JOIN APCSProDB.trans.jig_conditions 
											ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id  
											INNER JOIN APCSProDB.jig.productions 
											ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
											INNER JOIN APCSProDB.jig.production_counters 
											on production_counters.production_id = productions.id
											WHERE jigs.id <> @root_id AND root_jig_id = @root_id
											ORDER BY jig_conditions.value  DESC
											)
  
						IF (@LifeTime > @STDLifeTime )
						BEGIN 
								SELECT    'FALSE'													AS Is_Pass
										, '('+(smallcode)+') LifeTime Expire (100%) !!'				AS Error_Message_ENG
										, '('+(smallcode )+N') LifeTime หมดอายุการใช้งาน (100%) !!'		AS Error_Message_THA 
										,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'					AS Handling
								FROM APCSProDB.trans.jigs 
								WHERE jigs.id = @JIG_ID

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
										, ISNULL(jig_set_list.use_qty,0)					AS QTY
										, CONVERT(int,jig_member.value)						AS Life_Time
										, CONVERT(int,production_counters.alarm_value)		AS STD_Life_Time
										, jigs.id											AS jig_id
										, FORMAT(COALESCE((CAST(jig_member.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(jig_member.alarm_value,0) ,0), 'N2') AS LifeTime_Percen
										, @periodcheck_value								AS  periodcheck_value
										, @period_value										AS  period_value
								FROM APCSProDB.trans.lots
								INNER JOIN APCSProDB.method.device_flows				
								ON lots.device_slip_id					=	device_flows.device_slip_id
								AND device_flows.step_no				=	lots.step_no
								INNER JOIN APCSProDB.method.jig_sets					
								ON jig_sets.process_id					=	device_flows.act_process_id
								OR device_flows.jig_set_id				=   jig_sets.id
								INNER JOIN APCSProDB.method.jig_set_list			
								ON jig_sets.id							=	jig_set_list.jig_set_id
								INNER JOIN APCSProDB.jig.productions					
								ON productions.id						=	jig_set_list.jig_group_id
								INNER JOIN APCSProDB.jig.production_counters			
								ON production_counters.production_id	=	productions.id 
								LEFT JOIN APCSProDB.trans.jigs						
								ON productions.id						=	jigs.jig_production_id
								LEFT JOIN (
									SELECT jigs.id AS jig_id
										, jigs.root_jig_id
										, jig_conditions.value
										, jig_conditions.periodcheck_value
										, [production_counters].period_value
										, production_counters.alarm_value
									FROM APCSProDB.trans.jigs  
									INNER JOIN APCSProDB.trans.jig_conditions		
									ON jigs.id								=	jig_conditions.id 
									INNER JOIN APCSProDB.jig.productions			
									ON productions.id						=	jigs.jig_production_id 
									INNER JOIN APCSProDB.jig.production_counters	
									ON production_counters.production_id	=	productions.id
									WHERE jigs.root_jig_id != jigs.id
								) AS jig_member ON jig_member.root_jig_id = jigs.id
								WHERE lots.lot_no				= @LOTNO
								AND  jig_sets.[name]			= @Recipe
			 					AND (jigs.id  = @JIG_ID)
								AND (jig_sets.is_disable IS NULL OR jig_sets.is_disable = 0)
								ORDER BY jig_member.[value]  DESC

					END 
				--END 
			END
			ELSE 
			BEGIN
				SELECT    'FALSE'																				AS Is_Pass
						, 'This package ('+ @Recipe +') cannot be used with a Kanagata type ('+ [name] +'). !!'	AS Error_Message_ENG
						, N'Package ('+ @Recipe +N') นี้ไม่สามารถใช่้กับ Kanageta Type ('+ [name] +N') นี้ได้ !!'			AS Error_Message_THA
						, N'ให้ทำการ Common Package กับ Type Kanageta ที่เว็บ MDM'										AS Handling
				FROM APCSProDB.trans.jigs 
				INNER JOIN APCSProDB.jig.productions 
				ON jig_production_id = productions.id 
				WHERE jigs.id =  @JIG_ID
			END

	END
	ELSE IF NOT EXISTS ( SELECT jig_sets.id 
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
						 ON productions.id				= jigs.jig_production_id
						 WHERE lots.lot_no				= @LOTNO
						 AND  ISNULL(jig_sets.code,'')	= @Recipe
						 AND  (jigs.id					= @JIG_ID )
						 AND  jig_sets.id IS NOT NULL 
						)
	BEGIN 

			SELECT    'FALSE'													AS Is_Pass
					, 'Device slips this jig has not been registered yet !!'	AS Error_Message_ENG
					, N'Device slips นี้ยังไม่ถูกลงทะเบียน jig'							AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System'					AS Handling
			RETURN		
			
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
				ON jc.id = jigs.id
				WHERE lots.lot_no				= @LOTNO
				AND  ISNULL(jig_sets.code,'')	= @Recipe
				AND  jigs.id					= @JIG_ID 
				AND ( jig_sets.is_disable  = 0 )

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
 							, '('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG
 							, '('+(smallcode )+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA 
 							,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
 					FROM APCSProDB.trans.jigs 
 					WHERE jigs.id = @JIG_ID
 					RETURN
 
				END 


					SELECT    'TRUE'						AS Is_Pass		
							, ''							AS Error_Message_ENG
							, N''							AS Error_Message_THA
							, N''							AS Handling
							, @QRCode						AS QRCode
							, smallcode						AS Smallcode
							, productions.name				AS [Type]
							, ISNULL(jig_set_list.use_qty,0)			AS QTY
							, CONVERT(int,jig_conditions.value)			AS Life_Time
							, CONVERT(int,production_counters.alarm_value)	AS STD_Life_Time
							, jigs.id						AS jig_id
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
					ON jig_conditions.id			= jigs.id
					WHERE lots.lot_no				= @LOTNO
					AND  ISNULL(jig_sets.code,'')	= @Recipe
					AND  jigs.id					= @JIG_ID 
					AND ( jig_sets.is_disable		= 0 )

					RETURN 
		 
	END
END
