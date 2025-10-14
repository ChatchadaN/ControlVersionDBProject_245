-- =============================================
-- Author:		<NUCHA>
-- Create date: <2022/06/29>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [trans].[sp_get_material_type_001]
	@barcode as VARCHAR(30),
	@material_name as VARCHAR(250),
	@mc_no as VARCHAR(250),
	@lot_no as VARCHAR(10),
	@opno AS VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @material_id as INT,
			@material_type_id as INT,
			@Location_id AS INT,
			@Mat_state AS TINYINT,
			@qty AS DECIMAL,
			@mat_record_id AS INT,
			@mat_type AS NVARCHAR(100),
			@mat_lotno AS VARCHAR(MAX),
			@limitdate AS DATETIME,
			@pack_std_qty AS DECIMAL, 
			@process_state AS TINYINT, 
			@type AS VARCHAR(255)

	SELECT @material_type_id = material_production_id,
	@material_id = m.id,
	@Location_id = location_id,
	@Mat_state = material_state ,
	@mat_type = p.name, --type name
	@limitdate = ISNULL(m.extended_limit_date,m.limit_date), --expire
	@mat_lotno = m.lot_no, --lot_no
	@qty = m.quantity, --quan
	@pack_std_qty = p.pack_std_qty, 
	@type = c.name, 
	@process_state = m.process_state
	FROM APCSProDB.trans.materials m 
	INNER JOIN APCSProDB.material.productions p ON m.material_production_id = p.id
	INNER JOIN APCSProDB.material.categories c ON c.id = p.category_id
	WHERE  m.barcode = @barcode


		IF EXISTS (SELECT 1 FROM   APCSProDB.trans.materials m  WHERE  m.barcode = @barcode)
		BEGIN 
			IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE lot_no = @lot_no)
			BEGIN
				IF @type = 'BONDING WIRE' BEGIN
					IF NOT EXISTS( select 1 from [APCSProDB].[material].[material_commons] 
					where material_production_id = @material_type_id and material_name = @material_name)
						BEGIN
						SELECT 'FALSE' as Is_Pass,
						'Material Type is not match. !!' AS Error_Message_ENG,
						N'Type Material ไม่ตรงกัน !!' AS Error_Message_THA,
						N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
						RETURN 
					END
				END
				ELSE IF @type = 'FRAME' BEGIN
					--IF (SELECT dp.FRAME_NAME FROM APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT dp WHERE dp.LOT_NO_1 = @lot_no) <> @mat_type BEGIN
					IF @material_name <> @mat_type BEGIN
						SELECT 'FALSE' AS Is_Pass, 'Frame type is not match. !!' AS Error_Message_ENG,N'Frame Type ไม่ตรงกัน. !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
						RETURN
					END
				END 
				ELSE IF @type = 'RESIN' BEGIN
					IF @material_name <> @mat_type BEGIN
						SELECT 'FALSE' AS Is_Pass
						, 'Resin type is not match. !!' AS Error_Message_ENG
						, N'Resin Type ไม่ตรงกัน. !!' AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
						RETURN
					END
				END
		 		ELSE IF @type = 'SOLDER TAPE' OR @type = 'SOLDER BALL' BEGIN
					IF @material_name <> @mat_type BEGIN
						SELECT 'FALSE' AS Is_Pass
						, 'Resin type is not match. !!' AS Error_Message_ENG
						, N'Resin Type ไม่ตรงกัน. !!' AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
						RETURN
					END
				END
				ELSE IF @type = 'PASTE' BEGIN
					IF @material_name <> @mat_type BEGIN
						SELECT 'FALSE' AS Is_Pass
						, 'Resin type is not match. !!' AS Error_Message_ENG
						, N'Resin Type ไม่ตรงกัน. !!' AS Error_Message_THA
						, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
						RETURN
					END
				END
				

				SELECT 'TRUE' as Is_Pass,'Pass' AS Error_Message_ENG,N'ผ่าน' AS Error_Message_THA,N'' AS Handling,
					@material_id as Material_id,
					@mat_type as Material_type_name,
					@mat_lotno as mat_lot_no,
					@limitdate as limit,
					@qty as quantity,
					@material_name as slip_material_name,
					@pack_std_qty as pack_std_qty
		END ELSE 
		BEGIN 
				 SELECT 'FALSE' as Is_Pass,
						'This Lot No. could not be found. !!' AS Error_Message_ENG,
						N'ไม่พบข้อมูล Lot No. นี้ !!' AS Error_Message_THA,
						N'ไม่พบข้อมูล Lot No. นี้' AS Handling
				  RETURN 
		
		END



				 
		END ELSE 
		BEGIN 
				 SELECT 'FALSE' as Is_Pass,
						'This material could not be found. !!' AS Error_Message_ENG,
						N'ไม่พบข้อมูล Type Material นี้ !!' AS Error_Message_THA,
						N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
				  RETURN 
		
		END
END

