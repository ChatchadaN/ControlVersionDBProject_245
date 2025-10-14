-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_socket_check_lifetime_v1]
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
			@Safety AS INT

	SET @STDLifeTime = (SELECT APCSProDB.jig.productions.expiration_value / 1000
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

	SET @Safety = (SELECT APCSProDB.jig.production_counters.warn_value / 1000
						FROM APCSProDB.trans.jigs INNER JOIN
						--APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode)
	
	IF @LifeTime >= @STDLifeTime BEGIN
		SELECT 'FALSE' AS Is_Pass, 
		'('+(SELECT jigs.smallcode FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG,
		'('+(SELECT jigs.smallcode FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA
	END
	ELSE BEGIN 
		IF ((@LifeTime/@STDLifeTime) * 100) >= @Safety BEGIN
			SELECT 'TRUE' AS Is_Pass,
			'('+(SELECT jigs.smallcode FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)+') Near the end of lifetime !!' AS Error_Message_ENG,
			'('+(SELECT jigs.smallcode FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)+N') LifeTime ใกล้หมดอายุ !!' AS Error_Message_THA,'TRUE' AS Warning
		END
		ELSE BEGIN
			SELECT 'TRUE' AS Is_Pass,'FALSE' AS Warning
		END
	END
END
