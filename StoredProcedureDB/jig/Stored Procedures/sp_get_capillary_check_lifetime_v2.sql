
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [jig].[sp_get_capillary_check_lifetime_v2]
	-- Add the parameters for the stored procedure here
		 @QRCode			AS NVARCHAR(MAX) 
		,@INPUT_QTY			AS INT			= 0
		,@Lot_No			AS NVARCHAR(MAX)
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

	SELECT	TOP 1 @STDLifeTime	= (APCSProDB.jig.production_counters.alarm_value *1000) 
			,@LifeTime		=((APCSProDB.trans.jig_conditions.value  ) + @INPUT_QTY)
			,@Period		= APCSProDB.jig.production_counters.warn_value  
	FROM APCSProDB.trans.jigs 
	INNER JOIN APCSProDB.trans.jig_conditions 
	ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id 
	INNER JOIN APCSProDB.jig.productions 
	ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
	INNER JOIN APCSProDB.jig.production_counters 
	ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
	WHERE barcode = @QRCode 
 

	IF  @LifeTime >= @STDLifeTime 
		BEGIN
			IF EXISTS (SELECT  '1'    FROM APCSProDB.method.device_names INNER JOIN  APCSProDB.trans.lots ON  lots.act_device_name_id = device_names.id WHERE alias_package_group_id  = 33 AND lot_no = @Lot_No)
			BEGIN 

					    SELECT    'FALSE' AS Is_Pass
								, '('+(barcode)+')  Insufficient for production !!' AS Error_Message_ENG
								, '('+(barcode)+N') ไม่เพียงพอต่อการผลิต !!' AS Error_Message_THA
								, N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system !!' AS [Handling]
								, 1 AS Is_gdic
						FROM APCSProDB.trans.jigs where barcode = @QRCode
				END
				ELSE 
					BEGIN 

						SELECT    'FALSE' AS Is_Pass
								, '('+(barcode)+')  Insufficient for production !!' AS Error_Message_ENG
								, '('+(barcode)+N') ไม่เพียงพอต่อการผลิต !!' AS Error_Message_THA
								, N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ JIG control system !!' AS [Handling]
								, 0 AS Is_gdic
						FROM APCSProDB.trans.jigs where barcode = @QRCode
					END 
		END

	ELSE 
			BEGIN

				SELECT    'TRUE' AS Is_Pass
						, '' AS Error_Message_ENG 
						, '' AS Error_Message_THA
						, '' AS [Handling]
						,  (@LifeTime - @INPUT_QTY) AS  LifeTime
						,   @STDLifeTime  AS  STDLifeTime
			 
			END
 
END
