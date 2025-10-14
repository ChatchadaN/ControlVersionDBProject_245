-- =============================================
-- Author:		<Jakkapong>
-- Create date: <1/11/2022>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_material_type_wire]
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
			@pack_std_qty AS DECIMAL

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no])
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [trans].[sp_get_material_type_wire] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') + ''', @barcode = ''' + ISNULL(CAST(@barcode AS varchar),'') + ''', @material_name = ''' 
			+ ISNULL(CAST(@material_name AS varchar),'') +  ''', @mcno = ''' + ISNULL(CAST(@mc_no AS varchar),'') + '''' + ''', @opno = ''' 
			+ ISNULL(CAST(@opno AS varchar),'') + ''''
		, ISNULL(CAST(@lot_no AS varchar),'')

	SELECT @material_type_id = material_production_id,
	@material_id = m.id,
	@Location_id = location_id,
	@Mat_state = material_state ,
	@mat_type = p.name, --type name
	@limitdate = ISNULL(m.extended_limit_date,m.limit_date), --expire
	@mat_lotno = m.lot_no, --lot_no
	@qty = m.quantity, --quan
	@pack_std_qty = p.pack_std_qty
	FROM APCSProDB.trans.materials m INNER JOIN APCSProDB.material.productions p ON m.material_production_id = p.id   WHERE barcode = @barcode


	IF NOT EXISTS( select * from [APCSProDB].[material].[material_commons] 
	where material_production_id = @material_type_id and material_name = @material_name)
		BEGIN
		SELECT 'FALSE' as Is_Pass,
		'Material Type is not match. !!' AS Error_Message_ENG,
		N'Type Material ไม่ตรงกัน !!' AS Error_Message_THA,
		N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
		RETURN 
	END
	
	SELECT 'TRUE' as Is_Pass,'Pass' AS Error_Message_ENG,N'ผ่าน' AS Error_Message_THA,N'' AS Handling,
		@material_id as Material_id,
		@mat_type as Material_type_name,
		@mat_lotno as mat_lot_no,
		@limitdate as limit,
		@qty as quantity,
		@material_name as slip_material_name,
		@pack_std_qty as pack_std_qty
END
