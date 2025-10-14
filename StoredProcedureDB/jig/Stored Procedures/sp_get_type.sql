-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_type]
	-- Add the parameters for the stored procedure here
	@QRCode AS VARCHAR(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT 1 FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) BEGIN
		SELECT 'TRUE' AS Is_Pass, APCSProDB.trans.jigs.smallcode AS SmallCode, APCSProDB.jig.categories.name AS Type, APCSProDB.jig.productions.name AS SubType, APCSProDB.trans.jigs.status AS Status
		FROM  APCSProDB.trans.jigs INNER JOIN
			  APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
			  APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id
		WHERE jigs.barcode = @QRCode
		RETURN
	END

	ELSE IF EXISTS(SELECT 1 FROM APCSProDB.trans.jigs WHERE qrcodebyuser = @QRCode) BEGIN
		SELECT 'TRUE' AS Is_Pass, APCSProDB.trans.jigs.smallcode AS SmallCode, APCSProDB.jig.categories.name AS Type, APCSProDB.jig.productions.name AS SubType, APCSProDB.trans.jigs.status AS Status
		FROM  APCSProDB.trans.jigs INNER JOIN
			  APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
			  APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id
		WHERE jigs.qrcodebyuser = @QRCode
		RETURN
	END

	ELSE IF EXISTS(SELECT 1 FROM APCSProDB.trans.jigs WHERE smallcode = @QRCode) BEGIN
		SELECT 'TRUE' AS Is_Pass, APCSProDB.trans.jigs.smallcode AS SmallCode, APCSProDB.jig.categories.name AS Type, APCSProDB.jig.productions.name AS SubType, APCSProDB.trans.jigs.status AS Status
		FROM  APCSProDB.trans.jigs INNER JOIN
			  APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
			  APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id
		WHERE jigs.smallcode = @QRCode
		RETURN
	END

	--ELSE IF EXISTS(SELECT 1 FROM APCSProDB.trans.jigs WHERE id = @QRCode) BEGIN
	--	SELECT 'TRUE' AS Is_Pass, APCSProDB.trans.jigs.smallcode AS SmallCode, APCSProDB.jig.categories.name AS Type, APCSProDB.jig.productions.name AS SubType, APCSProDB.trans.jigs.status AS Status
	--	FROM  APCSProDB.trans.jigs INNER JOIN
	--		  APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
	--		  APCSProDB.jig.categories ON APCSProDB.jig.productions.category_id = APCSProDB.jig.categories.id
	--	WHERE jigs.id = @QRCode
	--	RETURN
	--END

	ELSE BEGIN
		SELECT 'FALSE' AS Is_Pass,N'This JIG ('+ @QRCode + ') Is not register !!' AS Error_Message_ENG,
				N'JIG นี้ ('+ @QRCode + N') ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
		RETURN
	END
END
