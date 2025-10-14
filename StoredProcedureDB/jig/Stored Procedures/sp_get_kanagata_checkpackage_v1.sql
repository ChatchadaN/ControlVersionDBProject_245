CREATE PROCEDURE [jig].[sp_get_kanagata_checkpackage_v1]
	@kanagataNo as VARCHAR(50) = NULL, --'FI-009','T-178'
	@jigset as  VARCHAR(50) = NULL, --'SSOP-B28W/TC'
	@LotNo as VARCHAR(50) = NULL,
	@Package as VARCHAR(50) = NULL --'SSOP-B28W'
AS
BEGIN


SELECT    APCSProDB.trans.jigs.qrcodebyuser, APCSProDB.method.jig_sets.name ,productions.name as basetype
FROM      APCSProDB.trans.jigs INNER JOIN
                         APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
                         APCSProDB.method.jig_set_list ON APCSProDB.jig.productions.id = APCSProDB.method.jig_set_list.jig_group_id INNER JOIN
                         APCSProDB.method.jig_sets ON APCSProDB.method.jig_set_list.jig_set_id = APCSProDB.method.jig_sets.id

where APCSProDB.method.jig_sets.name = @Package and APCSProDB.trans.jigs.qrcodebyuser = @kanagataNo


--------------------Check Package		
--IF NOT  EXISTS (SELECT APCSProDB.trans.jigs.qrcodebyuser, APCSProDB.method.jig_sets.name ,productions.name as basetype
--					FROM APCSProDB.trans.jigs INNER JOIN
--                          APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
--                          APCSProDB.method.jig_set_list ON APCSProDB.jig.productions.id = APCSProDB.method.jig_set_list.jig_group_id INNER JOIN
--                          APCSProDB.method.jig_sets ON APCSProDB.method.jig_set_list.jig_set_id = APCSProDB.method.jig_sets.id
--					WHERE APCSProDB.method.jig_sets.name = @Package and APCSProDB.trans.jigs.qrcodebyuser = @kanagataNo) 
--BEGIN
-- 	SELECT 'FALSE' AS Is_Pass,'Package ('+ @Package +') And Kanagata No.('+ @kanagataNo +') Miss Match. Plase check Common Package in Website JIGAndTooling !!' AS Error_Message_ENG,N'Package ('+ @Package +') นี้ไม่สามารถใช้กับ Kanagata No.('+ @kanagataNo +N') นี้ได้. กรุณาตรวจสอบการ Common Package ที่เว็บ JIGAndTooling !!'  AS Error_Message_THA
--	RETURN
--END


--ELSE BEGIN

--	DECLARE @rootID as VARCHAR(10)
--	SET @rootID = (SELECT id FROM APCSProDB.trans.jigs WHERE qrcodebyuser = @kanagataNo)
--------------------Check Part is not confirm
--		IF EXISTS (SELECT status FROM APCSProDB.trans.jigs WHERE root_jig_id = @rootID AND status = 'Wait Confirm')
--		BEGIN
--			 SELECT 'FALSE' AS Is_Pass,'Plase Confirm Part Change. This Kanagata No.('+ @kanagataNo +'), Plase check Confirm Part in Website JIGAndTooling !!' AS Error_Message_ENG,N' Kanagata No.('+ @kanagataNo +N') นี้มี Part ที่ยังไม่ได้ Confirm การเปลี่ยน Part. กรุณาตรวจสอบการ Confirm Part ที่เว็บ JIGAndTooling !!' AS Error_Message_THA
--			 RETURN
--		END
--END

--SELECT 'TRUE' AS Is_Pass 
--RETUN
END
