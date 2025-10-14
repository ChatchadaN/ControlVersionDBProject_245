-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_get_blade_check]
	-- Add the parameters for the stored procedure here
		@BLADE AS NVARCHAR(MAX) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE	   @root_id as int
			 
			 
	SELECT	 @root_id = APCSProDB.trans.jigs.id
	FROM   APCSProDB.trans.jigs 
	INNER JOIN APCSProDB.jig.productions 
	ON APCSProDB.trans.jigs.jig_production_id = productions.id 
	INNER JOIN APCSProDB.jig.categories 
	ON APCSProDB.jig.productions.category_id = categories.id
	INNER JOIN APCSProDB.method.processes 
	ON processes.id = categories.lsi_process_id
	WHERE (jigs.qrcodebyuser = @BLADE 
	OR  jigs.smallcode = @BLADE)

	IF (@root_id IS NULL)
	BEGIN
		SELECT    'FALSE'												AS Is_Pass
				,'Blade :[' + @BLADE+'] number is not registered. !!'  AS Error_Message_ENG
				, N'Blade :[' + @BLADE +N'] นี้ยังไม่ถูกลงทะเบียน !!'			AS Error_Message_THA
				, N'กรุณาลงทะเบียน Blade ที่เว็บ JIG'							AS Handling
	END
	ELSE
		BEGIN

		IF NOT EXISTS (	SELECT 1
						FROM APCSProDB. trans.jigs 
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON jigs.id = jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.jig.productions.id = jigs.jig_production_id
						INNER JOIN APCSProDB.jig.production_counters 
						ON production_counters.production_id = productions.id
						WHERE jigs.id = @root_id
					  ) 

		BEGIN

			SELECT	  'FALSE'								AS Is_Pass
					, 'Blade Part not yet registered. !!'	AS Error_Message_ENG
					, N'Blade  ยังไม่ถูกลงทะเบียน!!'				AS Error_Message_THA
					, N'กรุณาลงทะเบียน Blade Part ที่เว็บ JIG'		AS Handling
			RETURN

		END
		
		IF EXISTS (  SELECT  table1.quantity 
					 FROM	  (SELECT  production_counters.alarm_value  AS STDLifeTime
					 		, (CASE WHEN (value) > jigs.quantity  THEN 'Expire' ELSE 'Ready' END) AS quantity
					 		, root_jig_id 
					 FROM APCSProDB.trans.jigs 
					 INNER JOIN APCSProDB.trans.jig_conditions 
					 ON jigs.id = jig_conditions.id 
					 INNER JOIN APCSProDB.jig.productions 
					 ON APCSProDB.jig.productions.id = jigs.jig_production_id
					 INNER JOIN APCSProDB.jig.production_counters 
					 ON production_counters.production_id = productions.id
					 WHERE jigs.id =  @root_id
					 ) AS  table1 
					 WHERE table1.quantity = 'Expire'
				)

		BEGIN
					SELECT	  'FALSE'							AS Is_Pass
							, 'Blade Life Time expire. !!'		AS Error_Message_ENG
							, N'Blade หมดอายุการใช้งาน !!'			AS Error_Message_THA
							, N'ตรวจสอบ Blade ที่หมดอายุที่เว็บ JIG'	AS Handling
							, CAST(jig_conditions.value AS INT) AS [LifeTime]
							, CAST(jigs.quantity AS  INT)		AS STDLifeTime
					FROM APCSProDB.trans.jigs  
					INNER JOIN APCSProDB.trans.jig_conditions 
					ON jigs.id = APCSProDB.trans.jig_conditions.id 
					INNER JOIN APCSProDB.jig.productions 
					ON APCSProDB.jig.productions.id = jigs.jig_production_id 
					INNER JOIN APCSProDB.jig.production_counters 
					ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
					where jigs.id  = @root_id

			END
		ELSE
			BEGIN
						SELECT    'TRUE'							AS Is_Pass
								, N''								AS Error_Message_ENG
								, N''								AS Error_Message_THA
								, N''								AS Handling
								, CAST(jig_conditions.value AS INT) AS [LifeTime]
								, CAST(jigs.quantity AS INT)		AS STDLifeTime
						FROM APCSProDB.trans.jigs  
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON jigs.id = APCSProDB.trans.jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.jig.productions.id = jigs.jig_production_id 
						INNER JOIN APCSProDB.jig.production_counters 
						ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
						WHERE jigs.id = @root_id
				END
		END
END