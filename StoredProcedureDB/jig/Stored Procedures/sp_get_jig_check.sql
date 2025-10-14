-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_get_jig_check]
(
	  @QRCode			AS NVARCHAR(100)  
	, @Recipe			AS NVARCHAR(50)	=  ''    --, @WBCode	AS VARCHAR(50) = ''
	, @INPUT_QTY		AS INT			=  1
	, @LOTNO			AS NVARCHAR(10)
	, @OPNo				AS NVARCHAR(6) 
)
AS
BEGIN

 
		DECLARE	  @JIG_ID			AS INT
				, @MC_ID			AS INT
				, @STDLifeTime		AS INT
				, @LifeTime			AS INT
				, @Safety			AS INT
				, @Accu				AS INT
				, @OPID				AS INT
				, @State			AS INT
				, @Smallcode		AS VARCHAR(4)
				, @step_no_now		INT 
				, @lot_id			INT 
				, @QTY				INT 
				, @Category			AS NVARCHAR(50)
 


 SELECT		  @JIG_ID			= jigs.id 
			, @State			= jig_state 
			, @Smallcode		= jigs.smallcode  
			, @Category			= categories.short_name
	FROM APCSProDB.trans.jigs 
	INNER JOIN APCSProDB.jig.productions
	ON productions.id =  jigs.jig_production_id
	INNER JOIN APCSProDB.jig.categories
	ON categories.id	= productions.category_id
	WHERE (barcode		= @QRCode 
		OR qrcodebyuser = @QRCode)

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history_jig]
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
					AND  ISNULL(jig_sets.code,'')	= @Recipe
					AND  (jigs.barcode				= @QRCode  OR qrcodebyuser = @QRCode)
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
		--					, CAST(jig_conditions.value AS INT) AS [LifeTime]
		--					, CAST(jigs.quantity AS  INT)		AS STDLifeTime
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
								, CAST(jig_conditions.value AS INT) AS [LifeTime]
								, CAST(jigs.quantity AS INT)		AS STDLifeTime
								, jigs.id							AS jig_id
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
							where jigs.id = @JIG_ID)

				SET @LifeTime =	   (SELECT (APCSProDB.trans.jig_conditions.value + (@INPUT_QTY * @QTY)) 
							FROM APCSProDB.trans.jigs 
							INNER JOIN APCSProDB.trans.jig_conditions 
							ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id  
							INNER JOIN APCSProDB.jig.productions 
							ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
							where jigs.id = @JIG_ID)
  
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

					SELECT    'TRUE'				AS Is_Pass		
					, ''							AS Error_Message_ENG
					, N''							AS Error_Message_THA
					, N''							AS Handling
					, @QRCode						AS QRCode
					, smallcode						AS Smallcode
					, productions.name				AS [Type]
					, jig_set_list.use_qty			AS QTY
					, CONVERT(int,jc.value)			AS Life_Time
					, CONVERT(int,pc.alarm_value)	AS STD_Life_Time
					, jigs.id						AS jig_id
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
					AND  ISNULL(jig_sets.code,'')	= @Recipe
					AND  jigs.id					= @JIG_ID 
					AND ( jig_sets.is_disable		= 0 )

		 
	
		END 
	END
END
