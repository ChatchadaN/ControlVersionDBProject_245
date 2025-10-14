-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_get_blade_checktype]
	@QRCode		VARCHAR(MAX)	= NULL ,
	@lot_no		VARCHAR(10)		= NULL , 
	@MC_NO		VARCHAR(50)		= NULL ,
	@Package	NVARCHAR(50)	= NULL 
AS
BEGIN
DECLARE  @JIG_ID	AS INT
		

SET @JIG_ID = (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode OR qrcodebyuser = @QRCode)	

IF EXISTS ( SELECT    APCSProDB.trans.jigs.qrcodebyuser
					, APCSProDB.method.jig_sets.name 
					, productions.name as basetype
			FROM	APCSProDB.trans.jigs 
			INNER JOIN APCSProDB.jig.productions 
			ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
			INNER JOIN APCSProDB.method.jig_set_list 
			ON APCSProDB.jig.productions.id = APCSProDB.method.jig_set_list.jig_group_id 
			INNER JOIN APCSProDB.method.jig_sets 
			ON APCSProDB.method.jig_set_list.jig_set_id = APCSProDB.method.jig_sets.id
			WHERE APCSProDB.method.jig_sets.name = @Package 
			AND jigs.id =  @JIG_ID
			AND (jig_sets.is_disable IS NULL OR jig_sets.is_disable = 0)) 

	BEGIN

			SELECT    'TRUE' AS Is_Pass		
					, '' AS Error_Message_ENG
					, N'' AS Error_Message_THA
					, N'' AS Handling
					, productions.name as bladetype
					, APCSProDB.trans.jigs.qrcodebyuser
					, APCSProDB.method.jig_sets.name AS jigset 
			FROM    APCSProDB.trans.jigs 
			INNER JOIN APCSProDB.jig.productions 
			ON jigs.jig_production_id = productions.id 
			INNER JOIN APCSProDB.method.jig_set_list 
			ON productions.id = jig_set_list.jig_group_id 
			INNER JOIN APCSProDB.method.jig_sets
			ON jig_set_list.jig_set_id = jig_sets.id
			WHERE APCSProDB.method.jig_sets.name  = @Package 
			AND jigs.id =  @JIG_ID
			AND (jig_sets.is_disable IS NULL OR jig_sets.is_disable = 0)

	END
	ELSE BEGIN
			SELECT    'FALSE' AS Is_Pass
					, 'This package ('+ @Package +') cannot be used with a blade type ('+ name +'). !!' AS Error_Message_ENG
					, N'Package ('+ @Package +N') นี้ไม่สามารถใช่้กับ blade Type ('+ name +N') นี้ได้ !!' AS Error_Message_THA
					, N'ให้ทำการ Common Package กับ Type blade ที่เว็บ JIG' AS Handling
			FROM APCSProDB.trans.jigs 
			INNER JOIN APCSProDB.jig.productions 
			ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
			AND jigs.id =  @JIG_ID
	END
END
