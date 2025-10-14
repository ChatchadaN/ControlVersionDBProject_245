-- =============================================
-- Author:		<NUCHA>
-- Create date: <2022/06/29>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [trans].[sp_get_material_status_005] 
	-- Add the parameters for the stored procedure here
	@barcode as NVARCHAR(100),
	@material_name as VARCHAR(250) = '', 
	@mc_no as VARCHAR(250),
	@lot_no as VARCHAR(10)  = '', 
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
			@limit_state AS INT, 
			@process_state AS TINYINT, 
			@catgories AS  VARCHAR(MAX)
			, @is_production_usage		AS INT
			, @material_type			AS VARCHAR(MAX)
			, @AGPasteType				AS NVARCHAR(MAX)
			, @AGPasteLotNo				AS NVARCHAR(MAX)
			, @StartTimeMix				AS DATETIME
			, @FinishTimeMix			AS DATETIME
			, @EndLot					AS DATETIME
			, @StockID					AS INT 
			, @STDLifeTimeUser			AS INT 
			, @PreformExp				AS DATETIME
			, @used_date				AS VARCHAR(MAX)
			, @used_time				AS VARCHAR(MAX)
			, @expire_date				AS VARCHAR(MAX)
			, @expire_time				AS VARCHAR(MAX)
			, @req_date					AS VARCHAR(MAX)
			, @req_date_format			AS VARCHAR(MAX)
			, @used_format				AS DATETIME
			, @expire_format			AS DATETIME
			, @ResinBegin				AS VARCHAR(MAX)
			, @ResinEnd					AS VARCHAR(MAX)
			, @date_now					AS VARCHAR(MAX)
			, @open_limit_date1			AS DATETIME
			, @wait_limit_date			AS DATETIME

--if len >12  (ต้องตัดเอา 12 ตัวหลัง)
--@barcode = ''(ข้อมูลที่ตัดได้)

	--check length and split @barcode

	DECLARE @SplitData TABLE
	(
	    Barcode_split VARCHAR(MAX),
	    Position INT
	)
	 

	--check length and split @barcode
	IF LEN(@barcode) > 13
	BEGIN	
	
	INSERT INTO @SplitData (Barcode_split, Position)
	SELECT value, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Position
	FROM STRING_SPLIT(@barcode, ',')

	SET @barcode = (SELECT TOP 1 REVERSE(value) FROM STRING_SPLIT(REVERSE(@barcode),','))

	END
 
	--IF EXISTS( SELECT 1 FROM  DBx.MAT.MixAGPaste  WHERE DBx.MAT.MixAGPaste.QRCode =  @barcode AND @barcode like 'MAT%')
	--BEGIN 
	--			SELECT    @barcode				=  MixAGPaste.QRCode
	--					, @AGPasteType			=  (SELECT SUBSTRING(REPLACE(MixAGPaste.AGPasteType, '-', '') ,0,CASE WHEN CHARINDEX('/', MixAGPaste.AGPasteType) = 0 THEN LEN(REPLACE(MixAGPaste.AGPasteType, '-', ''))+1 ELSE CHARINDEX('/',REPLACE(MixAGPaste.AGPasteType, '-', ''))  END ))
	--					, @AGPasteLotNo			=  MixAGPaste.AGPasteLotNo
	--					, @StartTimeMix			=  MixAGPaste.StartTimeMix
	--					, @FinishTimeMix		=  MixAGPaste.FinishTimeMix
	--					, @EndLot				=  MixAGPaste.EndLot
	--					, @StockID				=  REPLACE(REPLACE(MixAGPaste.QRCode, 'MAT,', ''), '.', '') 
	--					, @STDLifeTimeUser		= Material.STDLifeTimeUser
	--					, @PreformExp			= MixAGPaste.StartTimeMix + Material.STDLifeTimeUser 
	--			FROM DBx.MAT.MixAGPaste 
	--			INNER JOIN DBx.MAT.Material 
	--			ON  MixAGPaste.AGPasteType =  DBx.MAT.Material.Material_Production 
	--			WHERE (MixAGPaste.QRCode = @barcode )   
	--			ORDER BY  MixAGPaste.FinishTimeMix ASC
 
	--			IF (SELECT TOP 1 VALUE  FROM STRING_SPLIT(@barcode,',')) <> 'MAT' 
	--			BEGIN
	--				SELECT    'FALSE'											AS Is_Pass 
	--						, 'This ('+ @barcode +') format is not correct !!'	AS Error_Message_ENG
	--						, N' ('+ @barcode +N') ฟอร์แมตไม่ถูกต้อง !!'				AS Error_Message_THA 
	--						, N''												AS Handling
	--						, ''												AS Warning

	--				RETURN
	--			END
	--			ELSE IF  (@PreformExp < GETDATE())  
	--			BEGIN 
	--					SELECT    'FALSE'				AS Is_Pass 
	--							, 'Preform Expire'		AS Error_Message_ENG
	--							, N'Preform หมดอายุ'		AS Error_Message_THA 
	--							, N''					AS Handling
	--							, ''					AS Warning

	--					RETURN
	--			END 
	--			ELSE IF  (@EndLot IS NULL)  
	--			BEGIN 
	--					SELECT    'FALSE'																AS Is_Pass 
	--							, 'EndLot'																AS Error_Message_ENG
	--							, N'ยังไม่ได้ End Lot ออกจากเครื่อง Cellcon Mixer กรุณา End lot ก่อนใช้งาน'		AS Error_Message_THA 
	--							, N''																	AS Handling
	--							, ''																	AS Warning

	--					RETURN
	--			END  
	--			ELSE  IF   (@FinishTimeMix > GETDATE()) 
	--			BEGIN 
	--					SELECT    'FALSE'															AS Is_Pass 
	--							, 'In the process of mixing, please come back and mix again.'		AS Error_Message_ENG
	--							, N'อยู่ระหว่างการ mixing กรุณากลับมา mix ใหม่'								AS Error_Message_THA 
	--							, N''																AS Handling
	--							, ''																AS Warning

	--					RETURN
	--			END 
			 
	--			SELECT    @barcode				=  MixAGPaste.QRCode
	--					, @mat_type				=  (SELECT SUBSTRING(REPLACE(MixAGPaste.AGPasteType, '-', '') ,0,CASE WHEN CHARINDEX('/', MixAGPaste.AGPasteType) = 0 THEN LEN(REPLACE(MixAGPaste.AGPasteType, '-', ''))+1 ELSE CHARINDEX('/',REPLACE(MixAGPaste.AGPasteType, '-', ''))  END ))
	--					, @mat_lotno			=  MixAGPaste.AGPasteLotNo
	--					, @material_id			=  REPLACE(REPLACE(MixAGPaste.QRCode, 'MAT,', ''), '.', '') 
	--					, @limitdate			= MixAGPaste.StartTimeMix + Material.STDLifeTimeUser 
	--			FROM DBx.MAT.MixAGPaste 
	--			INNER JOIN DBx.MAT.Material 
	--			ON  MixAGPaste.AGPasteType =  DBx.MAT.Material.Material_Production 
	--			WHERE (MixAGPaste.QRCode = @barcode )   
	--			ORDER BY  MixAGPaste.FinishTimeMix ASC

	--			SELECT  'TRUE' as Is_Pass,'PASS' AS Error_Message_ENG,N'ผ่าน' AS Error_Message_THA,N'' AS Handling,
	--					@material_id as Material_id,
	--					@mat_type as Material_type_name,
	--					@mat_lotno as mat_lot_no,
	--					@limitdate as limit,
	--					@qty as quantity,
	--					@material_name as slip_material_name,
	--					@pack_std_qty as pack_std_qty

	--	RETURN
	--END

 
 
  IF NOT EXISTS (select 'xx' from APCSProDB.trans.materials where barcode = @barcode)
  BEGIN
  
	SELECT    'FALSE' as Is_Pass
			, 'Barcode is not found. !!' AS Error_Message_ENG
			, N'ไม่พบข้อมูล Barcode นี้ !!' AS Error_Message_THA
			, N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling 
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
		 @limit_state = m.limit_state, 
		 @process_state = m.process_state
		 , @catgories =  categories.name
		 , @is_production_usage = ISNULL(m.is_production_usage,0)
		 , @open_limit_date1 =  m.open_limit_date1
		 , @wait_limit_date  =  m.wait_limit_date
  FROM APCSProDB.trans.materials m 
  INNER JOIN APCSProDB.material.productions p 
  ON m.material_production_id = p.id   
  INNER JOIN APCSProDB.material.categories
  ON categories.id  =  p.category_id  
  WHERE barcode = @barcode
 
 
	IF @qc_state = 3  
	BEGIN
		SELECT 'FALSE' AS Is_Pass ,
		'This Material is hold.  ' AS Error_Message_ENG,
		N'Material นี้อยู่ในสถานะ Hold  ' AS Error_Message_THA,
		N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
		RETURN
	END

	ELSE IF(@limitdate < GETDATE() or @limit_state = 5) 
	BEGIN
		SELECT 'FALSE' AS Is_Pass,
		'Material is expire ( '+ CONVERT(VARCHAR,@limitdate,121) +' )'  AS Error_Message_ENG,
		N'Material นี้หมดอายุการใช้งานแล้ว ( '+ CONVERT(VARCHAR,@limitdate,121) +' ) ' AS Error_Message_THA,
		N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling  
		RETURN
	END

	ELSE IF(@qty <= 0 or @Mat_state = 0) 
	BEGIN

		SELECT 'FALSE' AS Is_Pass,
		'Material is used up.'  AS Error_Message_ENG,
		N'Material นี้ใช้งานหมดแล้ว ' AS Error_Message_THA,
		N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
		RETURN
	END
	ELSE IF(@is_production_usage >= 2 AND @mat_type = 'WAFER Surpluses') 
	BEGIN

		SELECT 'FALSE' AS Is_Pass,
				'Surpluses Wafer cannot be reloaded into production more than twice.'  AS Error_Message_ENG,
				N'Surpluses Wafer ไม่สามารถ Re-load เข้าผลิตเกิน 2 ครั้ง ' AS Error_Message_THA,
				N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
		RETURN
	END


	--IF  @catgories = 'PASTE' 
	--BEGIN

	 
	--	--///////////////// Check Mix AG Paste
	--	SELECT    @FinishTimeMix		=  MixAGPaste.FinishTimeMix
	--			, @EndLot				=  MixAGPaste.EndLot						
	--			, @PreformExp			= MixAGPaste.StartTimeMix + Material.STDLifeTimeUser 
	--	FROM DBx.MAT.MixAGPaste 
	--	INNER JOIN DBx.MAT.Material 
	--	ON  MixAGPaste.AGPasteType  = DBx.MAT.Material.Material_Production
	--	WHERE (MixAGPaste.QRCode = @barcode )   
	--	ORDER BY  MixAGPaste.FinishTimeMix ASC

	--	 IF  (@PreformExp < GETDATE())  
	--	BEGIN 
	--			SELECT    'FALSE'				AS Is_Pass 
	--					, 'Preform Expire'		AS Error_Message_ENG
	--					, N'Preform หมดอายุ'		AS Error_Message_THA 
	--					, N''					AS Handling
	--					, ''					AS Warning

	--			RETURN
	--	END 
	--	ELSE IF  (@EndLot IS NULL)  
	--	BEGIN 
	--			SELECT    'FALSE'																AS Is_Pass 
	--					, 'EndLot'																AS Error_Message_ENG
	--					, N'ยังไม่ได้ End Lot ออกจากเครื่อง Cellcon Mixer กรุณา End lot ก่อนใช้งาน  '+@barcode		AS Error_Message_THA 
	--					, N''																	AS Handling
	--					, ''																	AS Warning

	--			RETURN
	--	END  
	--	ELSE  IF   (@FinishTimeMix > GETDATE()) 
	--	BEGIN 
	--			SELECT    'FALSE'															AS Is_Pass 
	--					, 'In the process of mixing, please come back and mix again.'		AS Error_Message_ENG
	--					, N'อยู่ระหว่างการ mixing กรุณากลับมา mix ใหม่'								AS Error_Message_THA 
	--					, N''																AS Handling
	--					, ''																AS Warning

	--			RETURN
	--	END 

	--	ELSE 
	--	BEGIN

	--			SELECT     @mat_type			=  (SELECT SUBSTRING(REPLACE(MixAGPaste.AGPasteType, '-', '') ,0,CASE WHEN CHARINDEX('/', MixAGPaste.AGPasteType) = 0 THEN LEN(REPLACE(MixAGPaste.AGPasteType, '-', ''))+1 ELSE CHARINDEX('/',REPLACE(MixAGPaste.AGPasteType, '-', ''))  END ))
	--					, @mat_lotno			=  MixAGPaste.AGPasteLotNo
	--					, @limitdate			= MixAGPaste.StartTimeMix + Material.STDLifeTimeUser 
	--			FROM DBx.MAT.MixAGPaste 
	--			INNER JOIN DBx.MAT.Material 
	--			ON  MixAGPaste.AGPasteType  = DBx.MAT.Material.Material_Production
	--			WHERE (MixAGPaste.QRCode = @barcode )   
	--			ORDER BY  MixAGPaste.FinishTimeMix ASC
				 
	--	END

	--END

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

	ELSE IF (@catgories ='FRAME')
	BEGIN 
			 IF	(SELECT COUNT(machine_materials.idx) AS idx_number   FROM APCSProDB.trans.machine_materials 
				 INNER JOIN APCSProDB.mc.machines ON machines.id = machine_materials.machine_id
				 INNER JOIN APCSProDB.trans.materials ON materials.id = machine_materials.material_id
				 WHERE machines.name = @mc_no AND machine_materials.idx BETWEEN 11 AND 20 
				 ) >= 10
			 BEGIN 
					SELECT 'FALSE' AS Is_Pass 
							,N'PLEASE CLEAR MATERIAL ON MACHINE !!' AS Error_Message_ENG
							, N'กรุณา CLEAR MATERIAL บน MACHINE ก่อน !!' AS Error_Message_THA
							, N'กรุณาติดต่อ System' AS Handling
							RETURN
			 END
	END 
	
	ELSE IF (@catgories ='RESIN')
	BEGIN
	 
			SELECT 'TRUE' as Is_Pass,'PASS' AS Error_Message_ENG,N'ผ่าน' AS Error_Message_THA,N'' AS Handling,
					@material_id as Material_id,
					@material_name as Material_type_name,
					@mat_lotno as mat_lot_no,
					@open_limit_date1 as limit,
					@qty as quantity,
					@material_name as slip_material_name,
					@pack_std_qty as pack_std_qty

			RETURN
	END 



	SELECT 'TRUE' as Is_Pass,'PASS' AS Error_Message_ENG,N'ผ่าน' AS Error_Message_THA,N'' AS Handling,
		@material_id as Material_id,
		@mat_type as Material_type_name,
		@mat_lotno as mat_lot_no,
		CONVERT(VARCHAR,@limitdate,121) as limit,
		@qty as quantity,
		@material_name as slip_material_name,
		@pack_std_qty as pack_std_qty

	END 
 
 

