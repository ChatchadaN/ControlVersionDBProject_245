
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [jig].[sp_get_blade_check_lifetime]
	-- Add the parameters for the stored procedure here
		@QRCode AS NVARCHAR(MAX) = NULL

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @STDLifeTime	AS INT,
			@LifeTime		AS INT,
			@Safety			AS INT,
			@Period			AS INT ,
			@JIG_ID			AS INT,
			@MC_ID			AS INT ,
			@Status_JIG_OUT AS varchar(50),
			@OPID			AS INT
	
	SET @JIG_ID = (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode OR qrcodebyuser = @QRCode)	
	SET @Status_JIG_OUT = (SELECT status FROM APCSProDB.trans.jigs WHERE id = @JIG_ID)

	SET @STDLifeTime = (SELECT jigs.quantity 
						FROM APCSProDB.trans.jigs 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters 
						ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where jigs.id = @JIG_ID)

	SET @LifeTime =		(SELECT APCSProDB.trans.jig_conditions.value
						FROM APCSProDB.trans.jigs 
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						where jigs.id = @JIG_ID)

	SET @Safety =		(SELECT (jigs.quantity * production_counters.warn_value )/100 AS _percent  
						FROM APCSProDB.trans.jigs 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
						INNER JOIN APCSProDB.jig.production_counters 
						ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where jigs.id = @JIG_ID)			
 
		 IF  @LifeTime >= @STDLifeTime 
			BEGIN	
				SELECT   'FALSE' AS Is_Pass
						,'('+(smallcode)+') the end of lifetime !!' AS Error_Message_ENG
						,'('+(smallcode)+N') LifeTime  หมดอายุ !!' AS Error_Message_THA
						,N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system !!' AS [Handling]
				FROM APCSProDB.trans.jigs where jigs.id = @JIG_ID 
			END
		ELSE  	IF (@LifeTime >= @Safety)
			 BEGIN 
				SELECT 'FALSE' AS Is_Pass,
				'('+(smallcode)+') To the period. Please cleaning !!' AS Error_Message_ENG,
				'('+(smallcode)+N') ถึง Period Lifetime แล้ว กรุณานำไป Cleaning !!' AS Error_Message_THA
				,N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system !!' AS [Handling]
				FROM APCSProDB.trans.jigs where jigs.id = @JIG_ID 
			 END 
		ELSE BEGIN
			SELECT   'TRUE' AS Is_Pass
					,'' AS Error_Message_ENG 
					,'' AS Error_Message_THA
					,'' AS [Handling]
		END
END
