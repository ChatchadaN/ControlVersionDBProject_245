-- =============================================
-- Author:		NUCHA
-- Create date: 2022/06/29
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_material_endlot_002]
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(10),
	@barcode AS VARCHAR(100),
	@opno AS VARCHAR(6),
	@mcno AS VARCHAR(20),
	@qty AS DECIMAL(18,6) = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @mat_record_id AS INT
	DECLARE @material_id as INT
		, @material_type_id as INT
		, @Location_id AS INT
		, @Mat_state AS TINYINT
		, @mat_type AS NVARCHAR(100)
		, @mat_lotno AS VARCHAR(MAX)
		, @limitdate AS DATETIME
		, @pack_std_qty AS DECIMAL
		, @type AS VARCHAR(255)
		, @process_state AS TINYINT
		, @AGPasteType				NVARCHAR(MAX)
			, @AGPasteLotNo				NVARCHAR(MAX)
			, @StartTimeMix				DATETIME
			, @FinishTimeMix			DATETIME
			, @EndLot					DATETIME
			, @StockID					INT 
			, @STDLifeTimeUser			INT 
			, @PreformExp				DATETIME
			, @MANU_COND_PRIFORM		NVARCHAR(100)
			, @package					NVARCHAR(100)
			, @device					NVARCHAR(100)
			, @SolderWire				NVARCHAR(100)
			, @material_type AS VARCHAR(MAX),
			@used_date AS VARCHAR(MAX),
			@used_time AS VARCHAR(MAX),
			@expire_date AS VARCHAR(MAX),
			@expire_time AS VARCHAR(MAX),
			@req_date AS VARCHAR(MAX),
			@req_date_format AS VARCHAR(MAX),
			@used_format AS DATETIME,
			@expire_format AS DATETIME,
			@ResinBegin AS VARCHAR(MAX),
			@ResinEnd AS VARCHAR(MAX),
			@date_now AS VARCHAR(MAX)


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

 
	SELECT @material_type_id = material_production_id
		, @material_id = m.id
		, @Location_id = location_id
		, @Mat_state = material_state 
		, @mat_type = p.name --type name
		, @limitdate = ISNULL(m.extended_limit_date,m.limit_date) --expire
		, @mat_lotno = m.lot_no --lot_no
		, @pack_std_qty = p.pack_std_qty
		, @type = c.name
		, @process_state = m.process_state
	FROM APCSProDB.trans.materials m 
	INNER JOIN APCSProDB.material.productions p ON m.material_production_id = p.id
	INNER JOIN APCSProDB.material.categories c ON c.id = p.category_id
	WHERE barcode = @barcode

 
	-- CHECK BARCODE
	IF  EXISTS (SELECT 1 FROM APCSProDB.trans.materials WHERE barcode = @barcode) 
	BEGIN
	 
	
	 IF @type <> 'RESIN' 
	 BEGIN 
	 

		DECLARE @mcno_use AS VARCHAR(50) 
		SET @mcno_use = (select TOP 1 REPLACE(MAC.name,' ','') from APCSProDB.trans.machine_materials MAT inner join APCSProDB.mc.machines MAC on MAT.machine_id = MAC.id where  MAT.material_id = @material_id)

		IF @Location_id <> 9 or @Mat_state <> 12  BEGIN
				SELECT 'FALSE' AS Is_Pass ,
					'This Material is not on machine !!' AS Error_Message_ENG,
					N'Material นี้ไม่ได้อยู่ในเครื่องจักร !!' AS Error_Message_THA,
					N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
			RETURN
		END

		IF  REPLACE(@mcno,' ','') <> REPLACE(@mcno_use,' ','') BEGIN
				SELECT 'FALSE' AS Is_Pass ,
					'This Material is on machine ('+ @mcno_use + N') !!' AS Error_Message_ENG,
					N'Material นี้ถูกใช้งานอยู่ที่เครื่องจักร ('+ @mcno_use + N') !!' AS Error_Message_THA,
					N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
			RETURN
		END
	
		END 

		BEGIN TRANSACTION
		BEGIN TRY
 

		SET @mat_record_id = (SELECT id + 1 FROM [APCSProDB].[trans].[numbers] WHERE [name] = 'material_records.id')

		 
		--Update QTY
		 IF @type = 'RESIN' 
		 BEGIN

			 UPDATE APCSProDB.[trans].[materials]
			 SET [updated_at] = GETDATE()
				,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
			 WHERE barcode = @barcode

		 END 
		 ELSE
		 BEGIN 

				UPDATE APCSProDB.[trans].[materials]
				SET quantity = @qty
					, [material_state] = IIF(@qty = 0,0,[material_state]) --0 Out of stock,2 Used
					,[updated_at] = GETDATE()
					,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
				WHERE barcode = @barcode
		END 

		INSERT INTO [APCSProDB].[trans].[material_records]
		   ([id]
		   ,[day_id]
		   ,[recorded_at]
		   ,[operated_by]
		   ,[record_class]
		   ,[material_id]
		   ,[barcode]
		   ,[material_production_id]
		   ,[step_no]
		   ,[in_quantity]
		   ,[quantity]
		   ,[fail_quantity]
		   ,[pack_count]
		   ,[limit_base_date]
		   ,[contents_list_id]
		   ,[is_production_usage]
		   ,[material_state]
		   ,[process_state]
		   ,[qc_state]
		   ,[first_ins_state]
		   ,[final_ins_state]
		   ,[limit_state]
		   ,[limit_date]
		   ,[extended_limit_date]
		   ,[open_limit_date1]
		   ,[open_limit_date2]
		   ,[wait_limit_date]
		   ,[location_id]
		   ,[acc_location_id]
		   ,[lot_no]
		   ,[qc_comment_id]
		   ,[qc_memo_id]
		   ,[arrival_material_id]
		   ,[parent_material_id]
		   ,[dest_lot_id]
		   ,[created_at]
		   ,[created_by]
		   ,[to_location_id])
		SELECT @mat_record_id AS [id]
			,(SELECT id FROM APCSProDB.trans.days WHERE date_value = CAST(GETDATE()AS date)) AS day_id
			,GETDATE() AS recorded_at
			,(SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno) AS operated_by
			,102 AS recored_class
			,[id] AS material_id
			,[barcode] 
			,[material_production_id]
			,[step_no]
			,[in_quantity]
			,[quantity]
			,[fail_quantity]
			,[pack_count]
			,NULL AS [limit_base_date]
			,NULL AS [contents_list_id]
			,[is_production_usage]
			,[material_state] AS [material_state] --0 Out of stock,2 Used
			,[process_state]
			,[qc_state]
			,[first_ins_state]
			,[final_ins_state]
			,[limit_state]
			,[limit_date]
			,[extended_limit_date]
			,[open_limit_date1]
			,[open_limit_date2]
			,[wait_limit_date]
			,[location_id]
			,[acc_location_id]
			,[lot_no]
			,[qc_comment_id]
			,[qc_memo_id]
			,[arrival_material_id]
			,[parent_material_id]
			,[dest_lot_id]
			,[created_at]
			,[created_by]
			,location_id AS [to_location_id]
		FROM [APCSProDB].[trans].[materials]
		WHERE barcode = @barcode

		--update material_records.id count
		DECLARE @r AS INT
		set @r = @@ROWCOUNT
		UPDATE APCSProDB.trans.numbers
		SET id = id + @r
		WHERE name = 'material_records.id'
		
		--insert lot_materials
		INSERT INTO [APCSProDB].[trans].[lot_materials]
           ([process_record_id]
           ,[material_id])     
		
		 SELECT TOP(1)lpr.id
			,(SELECT id FROM [APCSProDB].[trans].[materials] WHERE barcode = @barcode) 
		 FROM APCSProDB.trans.lot_process_records lpr
		 INNER JOIN APCSProDB.trans.lots l ON l.id  = lot_id  
		 WHERE l.lot_no = @lot_no 
		 ORDER BY lpr.id DESC

		SELECT 'TRUE' AS Is_Pass 
			, 'Success' AS Error_Message_ENG
			, N'สำเร็จ' AS Error_Message_THA
			, N'' AS Handling

		COMMIT; 
	END TRY
	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass 
			, ERROR_MESSAGE () AS Error_Message_ENG
			--, ERROR_MESSAGE () AS Error_Message_THA
			, N'การบันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
			--, ERROR_MESSAGE () AS Handling 
			, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
	END CATCH
	END

	ELSE  IF EXISTS( SELECT * FROM  DBx.MAT.MixAGPaste  WHERE ( DBx.MAT.MixAGPaste.QRCode =  @barcode ))--AND (QRCode IS NOT NULL  AND QRCode <> '')) )
	BEGIN
		SELECT 'TRUE' AS Is_Pass 
			, '' AS Error_Message_ENG
			, N'' AS Error_Message_THA
			, N'' AS Handling

	END 
	ELSE  
	BEGIN
		SELECT 'FALSE' AS Is_Pass
			, 'Material is not found. !!' AS Error_Message_ENG
			, N'ไม่พบข้อมูล Material นี้' AS Error_Message_THA
			, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
		RETURN

	END 

END
