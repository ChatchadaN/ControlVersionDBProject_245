-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_checkmaterial]
	-- Add the parameters for the stored procedure here
	@QRCode AS VARCHAR(12),
	@LotNo AS VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @location AS INT,
			@expiredate AS DATETIME,
			@type AS VARCHAR(250),
			@lotframetype AS VARCHAR(250),
			@materialtype AS VARCHAR(50)

	SELECT @type = p.name, @location = location_id, @expiredate = CONVERT(VARCHAR, CAST( limit_date AS date)) + ' 23:59:59', @materialtype = c.name
	FROM [APCSProDB].[trans].[materials] mt
			INNER JOIN APCSProDB.material.productions p ON p.id = mt.material_production_id
			INNER JOIN APCSProDB.material.categories c ON c.id = p.category_id
	WHERE barcode = @QRCode

    -- Insert statements for procedure here
	IF EXISTS(SELECT 1 FROM [APCSProDB].[trans].[materials] WHERE barcode = @QRCode) BEGIN
		IF NOT EXISTS (SELECT 1 FROM APCSProDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT WHERE LOT_NO_1 = @LotNo) BEGIN
			SELECT 'FALSE' AS Is_Pass,N'Lot number  ('+ @LotNo + ') is incorrect. !!' AS Error_Message_ENG,
				N'เลข Lot ('+ @LotNo + N') ไม่ถูกต้อง !!' AS Error_Message_THA
			RETURN
		END

		IF @location <> 7 BEGIN
			SELECT 'FALSE' AS Is_Pass,N'This material ('+ @QRCode + ') has not been accepted into process. !!' AS Error_Message_ENG,
				N'Material นี้ ('+ @QRCode + N') ยังไม่ถูกรับเข้าในกระบวนการผลิต !!' AS Error_Message_THA
			RETURN
		END

		--IF GETDATE() > @expiredate BEGIN
		--	SELECT 'FALSE' AS Is_Pass,N'This material ('+ @QRCode + ') has expired. !!' AS Error_Message_ENG,
		--		N'Material นี้ ('+ @QRCode + N') หมดอายุการใช้งานแล้ว !!' AS Error_Message_THA			
		--	RETURN
		--END
		
		--////////////////// IS FRAME
		IF @materialtype = 'FRAME' BEGIN
			SET @lotframetype = (SELECT FRAME_NAME FROM APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT WHERE LOT_NO_1 = @LotNo)

			IF @type <> @lotframetype BEGIN
				SELECT 'FALSE' AS Is_Pass,N'Miss match frame type. !!' AS Error_Message_ENG,
					N'Frame Type ไม่ตรงกัน !!' AS Error_Message_THA
				RETURN
			END	
		END

		--////////////////
		ELSE IF @materialtype = 'BONDING WIRE' BEGIN
			SELECT @materialtype AS Material_Type
		END

		--////////////////
		ELSE IF @materialtype = 'PASTE' OR @materialtype = 'SOLDER TAPE' OR @materialtype = 'SOLDER BALL'BEGIN
			SELECT @materialtype AS Material_Type
		END

		--////////////////
		ELSE BEGIN
			SELECT @materialtype AS Material_Type
		END

		--/////////////// RETURN DATA
		SELECT 'TRUE' AS Is_Pass,p.name AS Material_Type,mt.barcode,mt.lot_no AS Material_Lot,CONVERT(VARCHAR, CAST( mt.limit_date AS date)) + ' 23:59:59' AS Expire_Date 
			FROM [APCSProDB].[trans].[materials] mt
				INNER JOIN APCSProDB.material.productions p ON p.id = mt.material_production_id
		WHERE barcode = @QRCode
	END
	ELSE BEGIN
		SELECT 'FALSE' AS Is_Pass,N'This material ('+ @QRCode + ') is not register. !!' AS Error_Message_ENG,
				N'Material นี้ ('+ @QRCode + N') ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
		RETURN
	END
END
