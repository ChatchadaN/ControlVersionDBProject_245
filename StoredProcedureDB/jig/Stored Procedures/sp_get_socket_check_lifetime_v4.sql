
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_socket_check_lifetime_v4]
	-- Add the parameters for the stored procedure here
		@QRCode AS VARCHAR(15),
		@DataInput AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @STDLifeTime AS INT,
			@LifeTime AS INT,
			@Safety AS INT,
			@Accu AS INT,
			@Period AS INT 

	SET @STDLifeTime = (SELECT APCSProDB.jig.production_counters.alarm_value / 1000
						FROM APCSProDB.trans.jigs INNER JOIN
						--APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode)

	SET @LifeTime = (SELECT (APCSProDB.trans.jig_conditions.value / 1000) + (@DataInput / 1000)
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode)

	SET @Accu = (SELECT (APCSProDB.trans.jig_conditions.accumulate_lifetime / 1000)
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode)

	SET @Safety = (SELECT APCSProDB.jig.production_counters.warn_value / 1000
						FROM APCSProDB.trans.jigs INNER JOIN
						--APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode)
	
	SET @Period = (SELECT APCSProDB.jig.production_counters.period_value / 1000
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode)

	IF (@LifeTime + @Accu) >= (@STDLifeTime + (@STDLifeTime - @Safety)) BEGIN
		SELECT 'FALSE' AS Is_Pass, 
		'('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG,
		'('+(smallcode )+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA 
		,'' AS Handling
		,'' AS Warning
		FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
	END
	ELSE BEGIN 
		IF (@LifeTime >= @Period  )
			 BEGIN 
				SELECT 'TRUE' AS Is_Pass,
				'('+(smallcode)+') To the period. Please cleaning socket !!' AS Error_Message_ENG,
				'('+(smallcode)+N') ถึง Period Lifetime แล้ว กรุณานำ Socket ไป Cleaning !!' AS Error_Message_THA
				,'TRUE' AS Handling
				,'' AS Warning
				FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
			 END 
		ELSE IF (@LifeTime + @Accu) >= @STDLifeTime 
			BEGIN	
				SELECT 'TRUE' AS Is_Pass,
				'('+(smallcode)+') Near the end of lifetime !!' AS Error_Message_ENG,
				'('+(smallcode)+N') LifeTime ใกล้หมดอายุ !!' AS Error_Message_THA
				,'TRUE' AS Handling
				,'' AS Warning
				FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
			END
		ELSE BEGIN
			SELECT 'TRUE' AS Is_Pass
			,'' AS Error_Message_ENG
			,'' AS Error_Message_THA
			,'' AS Handling
			,'' AS Warning
		END
	END
END
