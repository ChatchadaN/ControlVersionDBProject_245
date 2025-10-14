-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_carrier_check_001]
	-- Add the parameters for the stored procedure here
		@QRCode AS VARCHAR(50) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 
		IF EXISTS  (SELECT    'xxx'
			FROM APCSProDB.trans.jigs
			INNER JOIN APCSProDB.jig.productions 
			ON productions.id = jigs.jig_production_id
			INNER JOIN APCSProDB.jig.categories 
			ON categories.id = productions.category_id
			WHERE  short_name = 'Carrier'   
			AND ( jigs.qrcodebyuser = @QRCode  OR barcode = @QRCode )
			AND jig_state <> 13   --Scrap
			)
			BEGIN 

				IF (SELECT jig_state FROM APCSProDB.trans.jigs
				WHERE jigs.qrcodebyuser = @QRCode  OR barcode = @QRCode ) IN ( 2, 11)   --2 Stock  , 11 To Machine
				BEGIN 

					SELECT    'TRUE'	AS Is_Pass
							, ''		AS Error_Message_ENG
							, ''		AS Error_Message_THA
							, ''		AS Handling
							, ''		AS Warning
					RETURN

				END
				ELSE
				BEGIN 

					SELECT    'FALSE'													AS Is_Pass 
							, 'Please take the carrier ('+ @QRCode +') to cleaning. '	AS Error_Message_ENG
							, N'กรุณานำ Carrier ('+ @QRCode +N') ไป Cleaning !!'			AS Error_Message_THA 
							, N'กรุณาลงทะเบียนที่เว็บ JIG Controlsystem'						AS Handling
							, ''														AS Warning
					RETURN

				END 
			END 
			ELSE
			BEGIN
	
				SELECT    'FALSE'												AS Is_Pass 
						, 'This carrier ('+ @QRCode +') not yet register !!'	AS Error_Message_ENG
						, N'Carrier ('+ @QRCode +N') นี้ยังไม่ถูกลงทะเบียน !!'			AS Error_Message_THA 
						, N'กรุณาลงทะเบียนที่เว็บ JIG Controlsystem'					AS Handling
						, ''													AS Warning
				RETURN

			END 
END
