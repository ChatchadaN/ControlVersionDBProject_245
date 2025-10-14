-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_carrier_check]
	-- Add the parameters for the stored procedure here
		@QRCode AS VARCHAR(100) 
	 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	 
	--IF (SELECT COUNT(value)  from string_split (@QRCode,'-')) <> 3 BEGIN
	--		SELECT    'FALSE'	AS Is_Pass 
	--		, 'This carrier ('+ @QRCode +') format is not correct !!'		AS Error_Message_ENG
	--		, N'Carrier ('+ @QRCode +N') ฟอร์แมตไม่ถูกต้อง !!'		AS Error_Message_THA 
	--		, N'กรุณาลงทะเบียนที่เว็บ JIG Controlsystem'		AS Handling
	--		, ''AS Warning

	--		RETURN
	--END

	--IF (SELECT LEN( SUBSTRING  (@QRCode,0,CHARINDEX('-',@QRCode)) )) <> 3 BEGIN
	--		SELECT    'FALSE'	AS Is_Pass 
	--		, 'This carrier ('+ @QRCode +') format is not correct !!'		AS Error_Message_ENG
	--		, N'Carrier ('+ @QRCode +N') ฟอร์แมตไม่ถูกต้อง !!'		AS Error_Message_THA 
	--		, N'กรุณาลงทะเบียนที่เว็บ JIG Controlsystem'		AS Handling
	--		, ''AS Warning

	--		RETURN
	--END

	--IF (SELECT LEN( SUBSTRING  (@QRCode,CHARINDEX('-',@QRCode)+1, CHARINDEX('-', (SUBSTRING (@QRCode,CHARINDEX('-',@QRCode)+1,LEN(@QRCode))))-1 ))) <> 2 BEGIN
	--		SELECT    'FALSE'	AS Is_Pass 
	--		, 'This carrier ('+ @QRCode +') format is not correct !!'		AS Error_Message_ENG
	--		, N'Carrier ('+ @QRCode +N') ฟอร์แมตไม่ถูกต้อง !!'		AS Error_Message_THA 
	--		, N'กรุณาลงทะเบียนที่เว็บ JIG Controlsystem'		AS Handling
	--		, ''AS Warning

	--		RETURN
	--END

	--IF (SELECT LEN( SUBSTRING  (REVERSE(@QRCode),0,CHARINDEX('-',REVERSE(@QRCode) )))) <> 4  BEGIN
	--		SELECT    'FALSE'	AS Is_Pass 
	--		, 'This carrier ('+ @QRCode +') format is not correct !!'		AS Error_Message_ENG
	--		, N'Carrier ('+ @QRCode +N') ฟอร์แมตไม่ถูกต้อง !!'		AS Error_Message_THA 
	--		, N'กรุณาลงทะเบียนที่เว็บ JIG Controlsystem'		AS Handling
	--		, ''AS Warning

	--		RETURN
	--END

										
	--SELECT    'TRUE'	AS Is_Pass
	--	, ''		AS Error_Message_ENG
	--	, ''		AS Error_Message_THA
	--	, ''		AS Handling
	--	, ''		AS Warning

 
 
		IF EXISTS  (SELECT    'xxx'
			FROM APCSProDB.trans.jigs
			INNER JOIN APCSProDB.jig.productions 
			ON productions.id = jigs.jig_production_id
			INNER JOIN APCSProDB.jig.categories 
			ON categories.id = productions.category_id
			WHERE  short_name = 'Carrier'   
			AND ( jigs.qrcodebyuser = @QRCode  OR barcode = @QRCode )
			-- AND jig_state <> 13   --Scrap
			)
			BEGIN 

				SELECT    'TRUE'	AS Is_Pass
						, ''		AS Error_Message_ENG
						, ''		AS Error_Message_THA
						, ''		AS Handling
						, ''		AS Warning

			END 
			ELSE
				BEGIN
	
					SELECT    'FALSE'	AS Is_Pass 
							, 'This carrier ('+ @QRCode +') not yet register !!'		AS Error_Message_ENG
							, N'Carrier ('+ @QRCode +N') นี้ยังไม่ถูกลงทะเบียน !!'		AS Error_Message_THA 
							, N'กรุณาลงทะเบียนที่เว็บ JIG Controlsystem'		AS Handling
							, ''		AS Warning
	
				END 
			END
 