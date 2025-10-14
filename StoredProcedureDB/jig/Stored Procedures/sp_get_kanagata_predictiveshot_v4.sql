-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_get_kanagata_predictiveshot_v4]
	-- Add the parameters for the stored procedure here
	@kanagataNo varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE   @root_id				AS INT
			, @process				AS VARCHAR(5)
			, @tmpData				AS VARCHAR(50)
			, @periodcheck_value	AS INT
			, @period_value			AS INT
				 


	SELECT    @root_id		= APCSProDB.trans.jigs.id
			, @periodcheck_value = jig_conditions.periodcheck_value  
		    , @period_value = production_counters.period_value  
	FROM APCSProDB.trans.jigs 
	INNER JOIN APCSProDB.trans.jig_conditions 
	ON jigs.id = jig_conditions.id 
	INNER JOIN APCSProDB.jig.productions 
	ON jigs.jig_production_id = productions.id
	INNER JOIN APCSProDB.jig.production_counters 
	ON production_counters.production_id = productions.id
	INNER JOIN APCSProDB.jig.categories 
	ON productions.category_id = categories.id
	WHERE  jigs.qrcodebyuser = @kanagataNo

	IF (@root_id is null)
	BEGIN
		SELECT    'FALSE' AS Is_Pass
				, 'Kanagata :[' + @kanagataNo+'] number is not registered. !!'   AS Error_Message_ENG
				, N'Kanagata :[' + @kanagataNo +N'] นี้ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
				, N'กรุณาลงทะเบียน Kanagata ที่เว็บ JIG' AS Handling
				,  '' AS LifeTime_Percen 
				, @periodcheck_value AS  periodcheck_value
				, @period_value  AS  period_value
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
					,'Kanagata Part not yet registered. !!' AS Error_Message_ENG
					,N'Kanakata Part ยังไม่ถูกลงทะเบียน!!' AS Error_Message_THA
					,N'กรุณาลงทะเบียน Kanagata Part ที่เว็บ JIG' AS Handling
					,  '' AS LifeTime_Percen 
					, @periodcheck_value AS  periodcheck_value
					, @period_value  AS  period_value
			RETURN
		END
  
		 IF (@periodcheck_value > @period_value  )
		 BEGIN 
 				SELECT    'FALSE' AS Is_Pass
 						, '('+(qrcodebyuser)+') Please CleanShot  !!' AS Error_Message_ENG
 						, '('+(qrcodebyuser )+N') กรุณาทำ CleanShot !!' AS Error_Message_THA 
 						, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
						, '' AS LifeTime_Percen 
						, @periodcheck_value AS  periodcheck_value
						, @period_value  AS  period_value
 				FROM APCSProDB.trans.jigs 
 				WHERE APCSProDB.trans.jigs.id  = @root_id
 
 				RETURN

		END 
		ELSE IF EXISTS(	SELECT table1.Cul_ShotPerFrame FROM (SELECT jigs.id,barcode,value,warn_value AS SafetyFactor,production_counters.alarm_value  AS STDLifeTime,
			(CASE WHEN (value+warn_value) > production_counters.alarm_value  THEN 'Expire' ELSE 'Ready' END) AS Cul_ShotPerFrame,root_jig_id 
			FROM APCSProDB. trans.jigs INNER JOIN APCSProDB.trans.jig_conditions on jigs.id = jig_conditions.id 
			INNER JOIN APCSProDB.jig.productions on APCSProDB.jig.productions.id = jigs.jig_production_id
			INNER JOIN APCSProDB.jig.production_counters on production_counters.production_id = productions.id
			WHERE  jigs.id <> @root_id and root_jig_id = @root_id) AS table1 WHERE  table1.Cul_ShotPerFrame = 'Expire')
				begin
					SELECT 'FALSE' AS Is_Pass,'Kanagata Part Life Time expire. !!' AS Error_Message_ENG
						,N'Kanakata Part หมดอายุการใช้งาน !!' AS Error_Message_THA
						,N'ตรวจสอบ Part ที่หมดอายุที่เว็บ JIG' AS Handling
						,MAX(FORMAT((CONVERT (DECIMAL(18 , 2),APCSProDB.trans.jig_conditions.value) / CONVERT (DECIMAL(18 , 2),APCSProDB.jig.production_counters.alarm_value )) * 100, 'N2')) AS LifeTime_Percen 
						, @periodcheck_value AS  periodcheck_value
						, @period_value  AS  period_value
					FROM APCSProDB.trans.jigs  
					INNER JOIN APCSProDB.trans.jig_conditions 
					ON jigs.id = APCSProDB.trans.jig_conditions.id 
					INNER JOIN APCSProDB.jig.productions 
					ON APCSProDB.jig.productions.id = jigs.jig_production_id 
					INNER JOIN APCSProDB.jig.production_counters 
					ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
					WHERE  jigs.id <> @root_id and root_jig_id = @root_id

				END
			ELSE
				BEGIN
					SELECT    'TRUE'	AS Is_Pass
							, ''		AS Error_Message_ENG
							, N''		AS Error_Message_THA
							, N''		AS Handling
							, MAX(FORMAT((CONVERT (DECIMAL(18 , 2),APCSProDB.trans.jig_conditions.value) / CONVERT (DECIMAL(18 , 2),APCSProDB.jig.production_counters.alarm_value)) * 100, 'N2')) AS LifeTime_Percen 
							, @periodcheck_value AS  periodcheck_value
							, @period_value  AS  period_value
					FROM APCSProDB.trans.jigs  
					INNER JOIN APCSProDB.trans.jig_conditions 
					ON jigs.id = APCSProDB.trans.jig_conditions.id 
					INNER JOIN APCSProDB.jig.productions 
					ON APCSProDB.jig.productions.id = jigs.jig_production_id 
					INNER JOIN APCSProDB.jig.production_counters 
					ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id 
					WHERE  jigs.id <> @root_id and root_jig_id = @root_id
				END
		END
END