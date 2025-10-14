-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_capillary_check] 
	-- Add the parameters for the stored procedure here
	@QRCode AS VARCHAR(100),
	@WBCode AS VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS (	SELECT jigs.id,jigs.smallcode, productions.name FROM APCSProDB.trans.jigs INNER JOIN 
		APCSProDB.jig.capillary_recipes ON jig_production_id = capillary_recipes.production_id INNER JOIN
		APCSProDB.jig.productions ON jig_production_id = productions.id
		WHERE barcode = @QRCode AND capillary_recipes.wb_code = @WBCode) 
		
	BEGIN
		SELECT  'TRUE' AS Is_Pass
				, jigs.id
				,jigs.smallcode
				, productions.name AS SubType
				,jig_conditions.value AS LT_Value
				,productions.expiration_value AS Lifetime 
		FROM APCSProDB.trans.jigs 
		INNER JOIN APCSProDB.trans.jig_conditions 
		ON jigs.id = jig_conditions.id 
		INNER JOIN APCSProDB.jig.capillary_recipes 
		ON jig_production_id = capillary_recipes.production_id 
		INNER JOIN APCSProDB.jig.productions 
		ON jig_production_id = productions.id
		WHERE barcode = @QRCode 
		AND capillary_recipes.wb_code = @WBCode
	END
	ELSE BEGIN
		SELECT  'FALSE'		AS Is_Pass
				,'Capillary recipe is invalid !!'	AS Error_Message_ENG
				,N'Capillary recipe ไม่ถูกต้อง !!'		AS Error_Message_THA
				,N'กรุณาตรวจสอบ Capillary recipe ที่เว็บไซต์ JIG' AS Handling  
	END

END
