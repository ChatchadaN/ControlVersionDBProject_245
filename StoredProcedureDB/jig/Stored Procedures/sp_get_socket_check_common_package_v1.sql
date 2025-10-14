-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_socket_check_common_package_v1]
	@QRCode as VARCHAR(10) , 
	@LotNo as VARCHAR(50) ,
	@Package as VARCHAR(50)  --'SSOP-B28W'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	IF (SELECT jigs.status FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)  <> 'On Machine' BEGIN
		SELECT 'FALSE' AS Is_Pass,'Socket ('+ (SELECT jigs.smallcode FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) + ') is not On Machine.' AS Error_Message_ENG
		, N'Socket นี้ ('+ (SELECT jigs.smallcode FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) + N') ไม่ได้อยู่ในเครื่องจักร !!' AS Error_Message_THA
		,'' AS Handling
		RETURN
	END

	IF EXISTS (SELECT APCSProDB.method.jig_sets.id
	FROM      APCSProDB.trans.jigs INNER JOIN
							 APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
							 APCSProDB.method.jig_set_list ON APCSProDB.jig.productions.id = APCSProDB.method.jig_set_list.jig_group_id INNER JOIN
							 APCSProDB.method.jig_sets ON APCSProDB.method.jig_set_list.jig_set_id = APCSProDB.method.jig_sets.id
							WHERE APCSProDB.method.jig_sets.name = @Package and APCSProDB.trans.jigs.barcode = @QRCode)
	BEGIN
		SELECT    'TRUE' AS Is_Pass,APCSProDB.method.jig_sets.code AS PiecePerTest, APCSProDB.method.jig_sets.name AS Package,productions.name AS SocketType
		FROM      APCSProDB.trans.jigs INNER JOIN
								 APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
								 APCSProDB.method.jig_set_list ON APCSProDB.jig.productions.id = APCSProDB.method.jig_set_list.jig_group_id INNER JOIN
								 APCSProDB.method.jig_sets ON APCSProDB.method.jig_set_list.jig_set_id = APCSProDB.method.jig_sets.id

		WHERE APCSProDB.method.jig_sets.name = @Package and APCSProDB.trans.jigs.barcode = @QRCode
	END
	ELSE BEGIN
		SELECT    'FALSE' AS Is_Pass,'Socket (' +(smallcode)+ ') is can not use with this package ( '+@Package+' ) !!' AS Error_Message_ENG,
		 N'ไม่สามารถใช้ Socket (' +(smallcode )+ N') กับ package ( '+@Package+ N' ) นี้ได้ !!' AS Error_Message_THA ,'' AS Handling
		 FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
	END
END
