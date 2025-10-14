-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_socket_check_common_package]
	@QRCode				AS VARCHAR(100) , 
	@LotNo				AS VARCHAR(50) ,
	@Package			AS VARCHAR(50),  --'SSOP-B28W'
	@Cellcon_jig_state	AS INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	IF @Cellcon_jig_state <> 11 BEGIN
		IF (SELECT jigs.status FROM APCSProDB.trans.jigs WHERE barcode = @QRCode)  <> 'On Machine' BEGIN
			SELECT 'FALSE' AS Is_Pass,'Socket ('+ (SELECT jigs.smallcode FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) + ') is not On Machine.' AS Error_Message_ENG
			, N'Socket นี้ ('+ (SELECT jigs.smallcode FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) + N') ไม่ได้อยู่ในเครื่องจักร !!' AS Error_Message_THA
			,'' AS Handling
			RETURN
		END
	END

	IF EXISTS (SELECT APCSProDB.method.jig_sets.id
	FROM      APCSProDB.trans.jigs INNER JOIN
							 APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
							 APCSProDB.method.jig_set_list ON APCSProDB.jig.productions.id = APCSProDB.method.jig_set_list.jig_group_id INNER JOIN
							 APCSProDB.method.jig_sets ON APCSProDB.method.jig_set_list.jig_set_id = APCSProDB.method.jig_sets.id
							WHERE APCSProDB.method.jig_sets.name = @Package and APCSProDB.trans.jigs.barcode = @QRCode and (jig_sets.is_disable is null or jig_sets.is_disable =0))
	BEGIN
		
		DECLARE @pcs_per_test AS VARCHAR(50),
				@process AS VARCHAR(50);
		
		SELECT @pcs_per_test = APCSProDB.method.jig_set_list.use_qty, @process = APCSProDB.method.processes.name
		FROM      APCSProDB.trans.jigs INNER JOIN
								 APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
								 APCSProDB.jig.categories ON APCSProDB.jig.categories.id = APCSProDB.jig.productions.category_id INNER JOIN
								 APCSProDB.method.processes ON APCSProDB.method.processes.id = APCSProDB.jig.categories.lsi_process_id INNER JOIN
								 APCSProDB.method.jig_set_list ON APCSProDB.jig.productions.id = APCSProDB.method.jig_set_list.jig_group_id INNER JOIN
								 APCSProDB.method.jig_sets ON APCSProDB.method.jig_set_list.jig_set_id = APCSProDB.method.jig_sets.id

		WHERE APCSProDB.method.jig_sets.name = @Package and APCSProDB.trans.jigs.barcode = @QRCode and (jig_sets.is_disable is null or jig_sets.is_disable =0)

		IF @process = 'FL' BEGIN
			IF (@pcs_per_test IS NULL or @pcs_per_test = '0') BEGIN
				 SELECT    'FALSE' AS Is_Pass,'Please set PiecePerTest on website JIG (page Socket Common Package) !!' AS Error_Message_ENG,
				 N'กรุณาตั้งค่า PiecePerTest ที่เว็บไซต์ JIG (หน้า Socket Common Package) !!' AS Error_Message_THA ,'' AS Handling
				 FROM APCSProDB.trans.jigs WHERE barcode = @QRCode

				 RETURN
			END
		END

		--//////////////////// data output
		SELECT    'TRUE' AS Is_Pass,'' AS Error_Message_ENG  ,N'' AS Error_Message_THA ,'' AS Handling , APCSProDB.method.jig_set_list.use_qty AS PiecePerTest, APCSProDB.method.jig_sets.name AS Package,productions.name AS SocketType
		FROM      APCSProDB.trans.jigs INNER JOIN
								 APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
								 APCSProDB.method.jig_set_list ON APCSProDB.jig.productions.id = APCSProDB.method.jig_set_list.jig_group_id INNER JOIN
								 APCSProDB.method.jig_sets ON APCSProDB.method.jig_set_list.jig_set_id = APCSProDB.method.jig_sets.id

		WHERE APCSProDB.method.jig_sets.name = @Package and APCSProDB.trans.jigs.barcode = @QRCode and (jig_sets.is_disable is null or jig_sets.is_disable =0)
	END
	ELSE BEGIN
		SELECT    'FALSE' AS Is_Pass,'Socket (' +(smallcode)+ ') is can not use with this package ( '+@Package+' ) !!' AS Error_Message_ENG,
		 N'ไม่สามารถใช้ Socket (' +(smallcode )+ N') กับ package ( '+@Package+ N' ) นี้ได้ !!' AS Error_Message_THA ,'' AS Handling
		 FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
	END
END
