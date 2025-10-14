
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [jig].[sp_get_hp_pp_check_lifetime_v3]
	-- Add the parameters for the stored procedure here
		@HPPP_ID AS INT,
		@INPUT_QTY AS INT  = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @STDLifeTime AS INT,
			@LifeTime AS INT,
			@Safety AS INT,
		 
			@Period AS INT 

	SET @STDLifeTime = (SELECT (CAST(APCSProDB.jig.production_counters.alarm_value  AS INT) * 1000 )
						FROM APCSProDB.trans.jigs INNER JOIN
						--APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where jigs.id = @HPPP_ID)

	SET @LifeTime =		(SELECT (APCSProDB.trans.jig_conditions.value  ) + @INPUT_QTY
						FROM APCSProDB.trans.jigs 
						INNER JOIN APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						where jigs.id = @HPPP_ID)
 	
	SET @Safety =		(SELECT (APCSProDB.trans.jig_conditions.periodcheck_value  ) + @INPUT_QTY    
						FROM APCSProDB.trans.jigs 
						INNER JOIN APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						where jigs.id = @HPPP_ID)
						
	SET @Period =		(SELECT (CAST(APCSProDB.jig.production_counters.warn_value  AS INT) * 1000 )
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
						INNER JOIN APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where jigs.id = @HPPP_ID)

 
		 IF  @LifeTime >= @STDLifeTime 
			BEGIN	
				SELECT   'FALSE' AS Is_Pass
						,'('+(smallcode)+') the end of lifetime !!' AS Error_Message_ENG
						,'('+(smallcode)+N') LifeTime  หมดอายุ !!' AS Error_Message_THA
						,N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system !!' AS [Handling]
				FROM APCSProDB.trans.jigs where jigs.id = @HPPP_ID 
			END
		ELSE  	IF (@Safety >= @Period  )
			 BEGIN 
				SELECT 'FALSE' AS Is_Pass,
				'('+(smallcode)+') To the period. Please cleaning HP/PP !!' AS Error_Message_ENG,
				'('+(smallcode)+N') ถึง Period Lifetime แล้ว กรุณานำ HP/PP ไป Cleaning !!' AS Error_Message_THA
				,N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system !!' AS [Handling]
				FROM APCSProDB.trans.jigs where jigs.id = @HPPP_ID 
			 END 
		ELSE BEGIN
			SELECT   'TRUE' AS Is_Pass
					,'' AS Error_Message_ENG 
					,'' AS Error_Message_THA
					,'' AS [Handling]
		END

END
