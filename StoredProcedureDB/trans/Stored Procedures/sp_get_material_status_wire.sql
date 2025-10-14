-- =============================================
-- Author:		<Jakkapong Pureinsin>
-- Create date: <1/6/2022>
-- Description:	<Get_materialSetup_wire Check data from Cellcon>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_material_status_wire] 
	-- Add the parameters for the stored procedure here
	@barcode as VARCHAR(30),
	@material_name as VARCHAR(250) = '', 
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
			@qc_state AS INT,
			@pack_std_qty AS DECIMAL,
			@limit_state AS INT

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
		, 'EXEC [trans].[sp_get_material_status_wire] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') + ''', @barcode = ''' + ISNULL(CAST(@barcode AS varchar),'') + ''', @material_name = ''' 
			+ ISNULL(CAST(@material_name AS varchar),'') +  ''', @mcno = ''' + ISNULL(CAST(@mc_no AS varchar),'') + '''' + ''', @opno = ''' 
			+ ISNULL(CAST(@opno AS varchar),'') + ''''
		, ISNULL(CAST(@lot_no AS varchar),'')


  IF NOT EXISTS(select * from APCSProDB.trans.materials where barcode = @barcode)
  BEGIN
	SELECT 'FALSE' as Is_Pass,
	'Barcode is not found. !!' AS Error_Message_ENG,
	N'ไม่พบข้อมูล Barcode นี้ !!' AS Error_Message_THA,
	N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling 
	RETURN 
  END


  SELECT @material_type_id = material_production_id,
  @material_id = m.id,
  @Location_id = location_id,
  @Mat_state = material_state ,
  @mat_type = p.name, --type name
  @limitdate = ISNULL(m.extended_limit_date,m.limit_date), --expire
  @mat_lotno = m.lot_no, --lot_no
  @qty = m.quantity, --quan
  @qc_state = m.qc_state,
  @pack_std_qty = p.pack_std_qty,
  @limit_state = m.limit_state
  FROM APCSProDB.trans.materials m INNER JOIN APCSProDB.material.productions p ON m.material_production_id = p.id   WHERE barcode = @barcode
	
	IF @qc_state = 3  BEGIN
		SELECT 'FALSE' AS Is_Pass ,
		'This Material is hold. !!' AS Error_Message_ENG,
		N'Material นี้อยู่ในสถานะ Hold !!' AS Error_Message_THA,
		N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
		RETURN
	END

  	IF(@limitdate < GETDATE() or @limit_state = 5) 
	BEGIN
		SELECT 'FALSE' AS Is_Pass,
		'Material is expire. !!( '+ CAST(@limitdate AS VARCHAR(MAX)) +' )'  AS Error_Message_ENG,
		N'Material นี้หมดอายุการใช้งานแล้ว ( '+ CAST(@limitdate AS VARCHAR(MAX)) +' ) !!' AS Error_Message_THA,
		N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling  
		RETURN
	END

	IF(@qty <= 0 or @Mat_state = 0) 
	BEGIN
		SELECT 'FALSE' AS Is_Pass,
		'Material is used up. !!'  AS Error_Message_ENG,
		N'Material นี้ใช้งานหมดแล้วแล้ว !!' AS Error_Message_THA,
		N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
		RETURN
	END

	DECLARE @mcno_use AS VARCHAR(50) 
	SET @mcno_use = (select TOP 1 MAC.name from APCSProDB.trans.machine_materials MAT inner join APCSProDB.mc.machines MAC on MAT.machine_id = MAC.id where  MAT.material_id = @material_id)

	IF @Location_id = 9 AND @Mat_state = 12 AND @mc_no <> @mcno_use
	BEGIN --Check machine ตรงเครื่องไหม	
		SELECT 'FALSE' AS Is_Pass ,
			N'This Material is on machine ('+ @mcno_use +N') !!' AS Error_Message_ENG,
			N'Material นี้ถูกใช้งานอยู่ที่เครื่องจักร ('+ @mcno_use +N') !!' AS Error_Message_THA,
			N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
		RETURN
	END

	ELSE IF @Location_id <> 9   BEGIN  --AND @Mat_state NOT IN (1,2)
		SELECT 'FALSE' AS Is_Pass ,
		'This Material is on stock. !!' AS Error_Message_ENG,
		N'Material นี้ยังไม่ถูกเบิกออกจาก Stock !!' AS Error_Message_THA,
		N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
		RETURN
	END

	
	SELECT 'TRUE' as Is_Pass,'PASS' AS Error_Message_ENG,N'ผ่าน' AS Error_Message_THA,N'' AS Handling,
		@material_id as Material_id,
		@mat_type as Material_type_name,
		@mat_lotno as mat_lot_no,
		@limitdate as limit,
		@qty as quantity,
		@material_name as slip_material_name,
		@pack_std_qty as pack_std_qty
END
