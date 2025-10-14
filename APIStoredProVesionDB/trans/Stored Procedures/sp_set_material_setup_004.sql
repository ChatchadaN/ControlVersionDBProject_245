-- =============================================
-- Author:		NUCHA
-- Create date: 2022/06/29
-- Description:	<Description,,>
-- =============================================
 CREATE PROCEDURE [trans].[sp_set_material_setup_004] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(10) = NULL ,
	@barcode AS VARCHAR(100),
	@opno AS VARCHAR(6),
	@mcno AS VARCHAR(20)
	--@input_qty as INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE   @material_id as INT
			, @material_type_id as INT
			, @Location_id AS INT
			, @Mat_state AS TINYINT
			, @qty AS DECIMAL(18,6)
			, @mat_record_id AS INT
			, @mat_type AS NVARCHAR(100)
			, @mat_lotno AS VARCHAR(MAX)
			, @limitdate AS DATETIME
			, @pack_std_qty AS DECIMAL
			, @type AS VARCHAR(255)
			, @process_state AS TINYINT
			, @idx AS INT = 1
			, @MC_ID AS INT

	--check length and split @barcode
	
	DECLARE @SplitData TABLE
	(
	    Barcode_split VARCHAR(MAX),
	    Position INT
	)


	 IF LEN(@barcode) > 13
	BEGIN	
	
	INSERT INTO @SplitData (Barcode_split, Position)
	SELECT value, ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS Position
	FROM STRING_SPLIT(@barcode, ',')

	SET @barcode = (SELECT TOP 1 REVERSE(value) FROM STRING_SPLIT(REVERSE(@barcode),','))

	END




	IF EXISTS( SELECT 1 FROM  DBx.MAT.MixAGPaste  WHERE DBx.MAT.MixAGPaste.QRCode =  @barcode  AND @barcode like 'MAT%')
		BEGIN 
 
				SELECT    @barcode				=  MixAGPaste.QRCode
						, @mat_type			=  (SELECT SUBSTRING(REPLACE(MixAGPaste.AGPasteType, '-', '') ,0,CASE WHEN CHARINDEX('/', MixAGPaste.AGPasteType) = 0 THEN LEN(REPLACE(MixAGPaste.AGPasteType, '-', ''))+1 ELSE CHARINDEX('/',REPLACE(MixAGPaste.AGPasteType, '-', ''))  END ))
						, @mat_lotno			=  MixAGPaste.AGPasteLotNo
						, @material_id				=  REPLACE(REPLACE(MixAGPaste.QRCode, 'MAT,', ''), '.', '') 
						, @limitdate			= MixAGPaste.StartTimeMix + Material.STDLifeTimeUser 
				FROM DBx.MAT.MixAGPaste 
				INNER JOIN DBx.MAT.Material 
				ON  MixAGPaste.AGPasteType  = DBx.MAT.Material.Material_Production 
				WHERE (MixAGPaste.QRCode = @barcode )   
				ORDER BY  MixAGPaste.FinishTimeMix ASC
 
	 
					SELECT 'TRUE' AS Is_Pass 
							, '' AS Error_Message_ENG
							, N'' AS Error_Message_THA
							, N'' AS Handling
							, @material_id as Material_id
							, @mat_type as Material_type_name
							, @mat_lotno as mat_lot_no
							, @limitdate as limit
							, @qty as quantity
							, @pack_std_qty as pack_std_qty 
						RETURN
				END 

	IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.materials WHERE barcode = @barcode) 
	BEGIN

		SELECT 'FALSE' as Is_Pass,
			'Barcode is not found. !!' AS Error_Message_ENG,
			N'ไม่พบข้อมูล Barcode นี้ !!' AS Error_Message_THA,
			N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling 
		RETURN 
	END



	SELECT @material_type_id = material_production_id
		, @material_id = m.id
		, @Location_id = location_id
		, @Mat_state = material_state 
		, @mat_type = p.name --type name
		, @limitdate = ISNULL(m.extended_limit_date,m.limit_date) --expire
		, @mat_lotno = m.lot_no --lot_no
		, @qty = m.quantity --quan
		, @pack_std_qty = p.pack_std_qty
		, @type = c.name
		, @process_state = m.process_state
	FROM APCSProDB.trans.materials m 
	INNER JOIN APCSProDB.material.productions p ON m.material_production_id = p.id
	INNER JOIN APCSProDB.material.categories c ON c.id = p.category_id
	WHERE barcode = @barcode

	IF (@mat_type ='FRAME')
	BEGIN 
			 IF	(SELECT COUNT(machine_materials.idx) AS idx_number   FROM APCSProDB.trans.machine_materials 
				 INNER JOIN APCSProDB.mc.machines ON machines.id = machine_materials.machine_id
				 INNER JOIN APCSProDB.trans.materials ON materials.id = machine_materials.material_id
				 WHERE machines.name = @mcno AND machine_materials.idx BETWEEN 11 AND 20 
				 ) >= 10
			 BEGIN 
					SELECT 'FALSE' AS Is_Pass 
							,N'PLEASE CLEAR MATERIAL ON MACHINE !!' AS Error_Message_ENG
							, N'กรุณา CLEAR MATERIAL บน MACHINE ก่อน !!' AS Error_Message_THA
							, N'กรุณาติดต่อ System' AS Handling

					RETURN
			 END
	END 
	 
	IF @Location_id <> 9   BEGIN  --AND @Mat_state NOT IN (1,2)
		SELECT 'FALSE' AS Is_Pass ,
		'This Material is on stock. !!' AS Error_Message_ENG,
		N'Material นี้ยังไม่ถูกเบิกออกจาก Stock !!' AS Error_Message_THA,
		N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
		RETURN
	END

	IF (@Location_id = 9 AND @Mat_state in (1,2))  
		BEGIN	
			----------------------------------------------------------------------------------------
			BEGIN TRANSACTION
			BEGIN TRY

				SET @mat_record_id = (SELECT id + 1 FROM [APCSProDB].[trans].[numbers] WHERE [name] = 'material_records.id')

				INSERT INTO [APCSProDB].[trans].[material_records]
					([id]
					, [day_id]
					, [recorded_at]
					, [operated_by]
					, [record_class]
					, [material_id]
					, [barcode]
					, [material_production_id]
					, [step_no]
					, [in_quantity]
					, [quantity]
					, [fail_quantity]
					, [pack_count]
					, [limit_base_date]
					, [contents_list_id]
					, [is_production_usage]
					, [material_state]
					, [process_state]
					, [qc_state]
					, [first_ins_state]
					, [final_ins_state]
					, [limit_state]
					, [limit_date]
					, [extended_limit_date]
					, [open_limit_date1]
					, [open_limit_date2]
					, [wait_limit_date]
					, [location_id]
					, [acc_location_id]
					, [lot_no]
					, [qc_comment_id]
					, [qc_memo_id]
					, [arrival_material_id]
					, [parent_material_id]
					, [dest_lot_id]
					, [created_at]
					, [created_by]
					, [to_location_id])
				SELECT @mat_record_id AS [id]
					, (SELECT id FROM APCSProDB.trans.days WHERE date_value = CAST(GETDATE()AS date)) AS [day_id]
					, GETDATE() AS [recorded_at]
					, (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno) AS [operated_by]
					, 5 AS [recored_class]
					, [id] AS [material_id]
					, [barcode] 
					, [material_production_id]
					, [step_no]
					, [in_quantity]
					, [quantity]
					, [fail_quantity]
					, [pack_count]
					, NULL AS [limit_base_date]
					, NULL AS [contents_list_id]
					, [is_production_usage]
					, 12 AS [material_state]
					, 1 AS [process_state]
					, [qc_state]
					, [first_ins_state]
					, [final_ins_state]
					, [limit_state]
					, [limit_date]
					, [extended_limit_date]
					, [open_limit_date1]
					, [open_limit_date2]
					, [wait_limit_date]
					, [location_id]
					, [acc_location_id]
					, [lot_no]
					, [qc_comment_id]
					, [qc_memo_id]
					, [arrival_material_id]
					, [parent_material_id]
					, [dest_lot_id]
					, [created_at]
					, [created_by]
					, location_id AS [to_location_id]
				FROM [APCSProDB].[trans].[materials]
				WHERE barcode = @barcode

				----update material_records.id count
				--DECLARE @r AS INT
				--set @r = @@ROWCOUNT
				UPDATE APCSProDB.trans.numbers
				SET id = @mat_record_id
				WHERE name = 'material_records.id'

				----update material
				UPDATE APCSProDB.[trans].[materials]
				SET [material_state] = 12
					,[process_state] = 1
					,[updated_at] = GETDATE()
					,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
				WHERE barcode = @barcode


--//////////////////////// Update Machine Materials   2022/02/10
				IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_materials 
					INNER JOIN APCSProDB.mc.machines ON machines.id = machine_materials.machine_id
					WHERE machines.name = @mcno)
				BEGIN
				--////////////////// UPDATE Material Out
					DECLARE @barcode_out AS VARCHAR(15) = 0,
							@mat_record_id_out AS INT
				
					IF @type = 'BONDING WIRE' BEGIN


					SET @idx=  1

						SELECT @barcode_out = materials.barcode FROM APCSProDB.trans.machine_materials 
							INNER JOIN APCSProDB.mc.machines ON machines.id = machine_materials.machine_id
							INNER JOIN APCSProDB.trans.materials ON materials.id = machine_materials.material_id
						WHERE machines.name = @mcno AND machine_materials.idx = @idx
					END
  

					SET @mat_record_id_out  = (SELECT id + 1 FROM [APCSProDB].[trans].[numbers] WHERE [name] = 'material_records.id')

					IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_materials 
						INNER JOIN APCSProDB.mc.machines ON machines.id = machine_materials.machine_id
						INNER JOIN APCSProDB.trans.materials ON materials.id = machine_materials.material_id
						WHERE machines.name = @mcno and materials.barcode = @barcode_out)
					BEGIN
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

							SELECT @mat_record_id_out AS [id]
								,(SELECT id FROM APCSProDB.trans.days WHERE date_value = CAST(GETDATE()AS date)) AS day_id
								,GETDATE() AS recorded_at
								,(SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno) AS operated_by
								,80 AS recored_class
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
								,IIF([quantity] = 0,0,2) AS [material_state] --0 Out of stock,2 Returned
								,0 AS [process_state]
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
							WHERE barcode = @barcode_out 

						--update material_records.id count
						   --DECLARE @r_out  AS INT
						   --set @r_out  = @@ROWCOUNT
						   UPDATE APCSProDB.trans.numbers
						   SET id = @mat_record_id_out 
						   WHERE name = 'material_records.id'
		
						--update material out
						   UPDATE APCSProDB.[trans].[materials]
						   SET 
							  [material_state] = IIF([quantity] = 0,0,2) --1
							  ,[process_state] = 0
							  ,[updated_at] = GETDATE()
							  ,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
						   WHERE barcode = @barcode_out 
					END

					IF @type = 'BONDING WIRE' 
					BEGIN
					 
					SET @idx = 1
					WHILE @idx <= 10 BEGIN

						IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_materials  
							WHERE machine_id = (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) AND idx = @idx)
						BEGIN
							UPDATE APCSProDB.trans.machine_materials 
							SET material_id = @material_id
								,[updated_at] = GETDATE()
								,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
							WHERE machine_id = (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) 
								  AND idx = @idx
						END
						ELSE BEGIN

							INSERT INTO [APCSProDB].[trans].[machine_materials]
								([machine_id]
								,[idx]
								,[material_group_id]
								,[material_id]
								,[location_id]
								,[acc_location_id]
								,[created_at]
								,[created_by]
								,[updated_at]
								,[updated_by])
							SELECT (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) as [machine_id]
								, @idx as [idx] -- 1-10 wire
								, 1 as [material_group_id]
								, [materials].[id] as [material_id]
								, NULL as [location_id]
								, NULL as [acc_location_id]
								, GETDATE() as [created_at]
								, (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno) as [created_by]
								, NULL as [updated_at]
								, NULL as [updated_by]
							FROM [APCSProDB].[trans].[materials]
							WHERE barcode = @barcode
						END
						--////////////////////////Data Return//////////////////////////////

								SELECT   'TRUE'			AS Is_Pass 
										, ''			AS Error_Message_ENG
										, N''			AS Error_Message_THA
										, N''			AS Handling
										, @material_id	AS Material_id
										, @mat_type		AS Material_type_name
										, @mat_lotno	AS mat_lot_no
										, @limitdate	AS limit
										, @qty			AS quantity
										, @pack_std_qty AS pack_std_qty 
						
								COMMIT; 
								RETURN
								END
							SET	@idx = @idx + 1
						END
						ELSE IF @type = 'FRAME' 
						BEGIN
							SET @MC_ID = (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno)
							SET @idx =  11

							WHILE @idx <= 20 
							BEGIN
						
							IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_materials WHERE machine_id = @MC_ID AND idx = @idx) BEGIN
								INSERT INTO [APCSProDB].[trans].[machine_materials]
									([machine_id]
									,[idx]
									,[material_group_id]
									,[material_id]
									,[location_id]
									,[acc_location_id]
									,[created_at]
									,[created_by]
									,[updated_at]
									,[updated_by])
								SELECT (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) as [machine_id]
									, @idx as [idx] -- 11-20 frame
									, 1 as [material_group_id]
									, [materials].[id] as [material_id]
									, NULL as [location_id]
									, NULL as [acc_location_id]
									, GETDATE() as [created_at]
									, (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno) as [created_by]
									, NULL as [updated_at]
									, NULL as [updated_by]
								FROM [APCSProDB].[trans].[materials]
								WHERE barcode = @barcode

								--////////////////////////Data Return//////////////////////////////

								SELECT 'TRUE' AS Is_Pass 
									, '' AS Error_Message_ENG
									, N'' AS Error_Message_THA
									, N'' AS Handling
									, @material_id as Material_id
									, @mat_type as Material_type_name
									, @mat_lotno as mat_lot_no
									, @limitdate as limit
									, @qty as quantity
									, @pack_std_qty as pack_std_qty 

								COMMIT; 
								RETURN
							END

						SET	@idx = @idx + 1
						END
					END
					ELSE IF @type = 'SOLDER TAPE' OR @type = 'SOLDER BALL'   
					BEGIN

					SET @idx =  1    --1-10  
					WHILE @idx <= 5 BEGIN
					 
						IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_materials  
						WHERE machine_id = (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) AND idx = @idx)
						BEGIN
							UPDATE APCSProDB.trans.machine_materials 
							SET material_id = @material_id
								,[updated_at] = GETDATE()
								,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
							WHERE machine_id = (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) 
								  AND idx =@idx
						END
						ELSE 
						BEGIN


							INSERT INTO [APCSProDB].[trans].[machine_materials]
								([machine_id]
								,[idx]
								,[material_group_id]
								,[material_id]
								,[location_id]
								,[acc_location_id]
								,[created_at]
								,[created_by]
								,[updated_at]
								,[updated_by])
							SELECT (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) as [machine_id]
								, @idx as [idx] -- 1-5 SOLDER
								, 1 as [material_group_id]
								, [materials].[id] as [material_id]
								, NULL as [location_id]
								, NULL as [acc_location_id]
								, GETDATE() as [created_at]
								, (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno) as [created_by]
								, NULL as [updated_at]
								, NULL as [updated_by]
							FROM [APCSProDB].[trans].[materials]
							WHERE barcode = @barcode
						  

						SELECT 'TRUE' AS Is_Pass 
							, '' AS Error_Message_ENG
							, N'' AS Error_Message_THA
							, N'' AS Handling
							, @material_id as Material_id
							, @mat_type as Material_type_name
							, @mat_lotno as mat_lot_no
							, @limitdate as limit
							, @qty as quantity
							, @pack_std_qty as pack_std_qty 
						
								COMMIT; 
								RETURN
							END

						SET	@idx = @idx + 1
						END
					END

					ELSE IF  @type = 'PASTE' 
					BEGIN

					SET @idx =  1    --1-10  

					WHILE @idx <= 5 BEGIN

						IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_materials  
						WHERE machine_id = (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) AND idx = @idx)
						BEGIN
							UPDATE APCSProDB.trans.machine_materials 
							SET material_id = @material_id
								,[updated_at] = GETDATE()
								,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
							WHERE machine_id = (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) 
								  AND idx =@idx
						END
						ELSE 
						BEGIN


							INSERT INTO [APCSProDB].[trans].[machine_materials]
								([machine_id]
								,[idx]
								,[material_group_id]
								,[material_id]
								,[location_id]
								,[acc_location_id]
								,[created_at]
								,[created_by]
								,[updated_at]
								,[updated_by])
							SELECT (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) as [machine_id]
								, @idx as [idx] -- 1-5 PASTE
								, 1 as [material_group_id]
								, [materials].[id] as [material_id]
								, NULL as [location_id]
								, NULL as [acc_location_id]
								, GETDATE() as [created_at]
								, (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno) as [created_by]
								, NULL as [updated_at]
								, NULL as [updated_by]
							FROM [APCSProDB].[trans].[materials]
							WHERE barcode = @barcode
						END

						--////////////////////////Data Return//////////////////////////////
					 

						SELECT    @mat_type		=  (SELECT SUBSTRING(REPLACE(MixAGPaste.AGPasteType, '-', '') ,0,CASE WHEN CHARINDEX('/', MixAGPaste.AGPasteType) = 0 THEN LEN(REPLACE(MixAGPaste.AGPasteType, '-', ''))+1 ELSE CHARINDEX('/',REPLACE(MixAGPaste.AGPasteType, '-', ''))  END ))
								, @mat_lotno	=  MixAGPaste.AGPasteLotNo
								, @limitdate	= MixAGPaste.StartTimeMix + Material.STDLifeTimeUser 
						FROM DBx.MAT.MixAGPaste 
						INNER JOIN DBx.MAT.Material 
						ON  MixAGPaste.AGPasteType  = DBx.MAT.Material.Material_Production 
						WHERE (MixAGPaste.QRCode = @barcode )   
						ORDER BY  MixAGPaste.FinishTimeMix ASC
						  
									SELECT 'TRUE' AS Is_Pass 
									, '' AS Error_Message_ENG
									, N'' AS Error_Message_THA
									, N'' AS Handling
									, @material_id as Material_id
									, @mat_type as Material_type_name
									, @mat_lotno as mat_lot_no
									, @limitdate as limit
									, @qty as quantity
									, @pack_std_qty as pack_std_qty 

								COMMIT; 
								RETURN
							END

						SET	@idx = @idx + 1
						END

				END
				ELSE 
				BEGIN
					IF @type = 'BONDING WIRE' 
					BEGIN

					SET @idx=  1

					WHILE @idx <= 10 
					BEGIN
							IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_materials WHERE machine_id = @MC_ID AND idx = @idx) BEGIN
							INSERT INTO [APCSProDB].[trans].[machine_materials]
							([machine_id]
							,[idx]
							,[material_group_id]
							,[material_id]
							,[location_id]
							,[acc_location_id]
							,[created_at]
							,[created_by]
							,[updated_at]
							,[updated_by])
						SELECT (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) as [machine_id]
							, @idx as [idx] -- 1-10 wire
							, 1 as [material_group_id]
							, [materials].[id] as [material_id]
							, NULL as [location_id]
							, NULL as [acc_location_id]
							, GETDATE() as [created_at]
							, (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno) as [created_by]
							, NULL as [updated_at]
							, NULL as [updated_by]
						FROM [APCSProDB].[trans].[materials]
						WHERE barcode = @barcode

								--////////////////////////Data Return//////////////////////////////

								SELECT 'TRUE' AS Is_Pass 
									, '' AS Error_Message_ENG
									, N'' AS Error_Message_THA
									, N'' AS Handling
									, @material_id as Material_id
									, @mat_type as Material_type_name
									, @mat_lotno as mat_lot_no
									, @limitdate as limit
									, @qty as quantity
									, @pack_std_qty as pack_std_qty 

								COMMIT; 
								RETURN
							END

						SET	@idx = @idx + 1
						END
					END
					ELSE IF @type = 'FRAME' 
					BEGIN

						SET @MC_ID = (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno)
						SET @idx =  11

						WHILE @idx <= 20 BEGIN

							IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_materials WHERE machine_id = @MC_ID AND idx = @idx) 
							BEGIN
								INSERT INTO [APCSProDB].[trans].[machine_materials]
									([machine_id]
									,[idx]
									,[material_group_id]
									,[material_id]
									,[location_id]
									,[acc_location_id]
									,[created_at]
									,[created_by]
									,[updated_at]
									,[updated_by])
								SELECT (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) as [machine_id]
									, @idx as [idx] -- 11-20 frame
									, 1 as [material_group_id]
									, [materials].[id] as [material_id]
									, NULL as [location_id]
									, NULL as [acc_location_id]
									, GETDATE() as [created_at]
									, (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno) as [created_by]
									, NULL as [updated_at]
									, NULL as [updated_by]
								FROM [APCSProDB].[trans].[materials]
								WHERE barcode = @barcode

								--////////////////////////Data Return//////////////////////////////

								SELECT 'TRUE' AS Is_Pass 
									, '' AS Error_Message_ENG
									, N'' AS Error_Message_THA
									, N'' AS Handling
									, @material_id as Material_id
									, @mat_type as Material_type_name
									, @mat_lotno as mat_lot_no
									, @limitdate as limit
									, @qty as quantity
									, @pack_std_qty as pack_std_qty 

								COMMIT; 
								RETURN
							END

						SET	@idx = @idx + 1
						END
					END
 					ELSE IF  @type = 'SOLDER TAPE' OR @type = 'SOLDER BALL' 
					BEGIN
 
					SET @idx =  1
					WHILE @idx <= 5 
					BEGIN
					
					IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_materials WHERE machine_id = @MC_ID AND idx = @idx) 
					BEGIN

						INSERT INTO [APCSProDB].[trans].[machine_materials]
							([machine_id]
							,[idx]
							,[material_group_id]
							,[material_id]
							,[location_id]
							,[acc_location_id]
							,[created_at]
							,[created_by]
							,[updated_at]
							,[updated_by])
						SELECT (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) as [machine_id]
							, @idx as [idx] -- 1-5 SOLDER
							, 1 as [material_group_id]
							, [materials].[id] as [material_id]
							, NULL as [location_id]
							, NULL as [acc_location_id]
							, GETDATE() as [created_at]
							, (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno) as [created_by]
							, NULL as [updated_at]
							, NULL as [updated_by]
						FROM [APCSProDB].[trans].[materials]
						WHERE barcode = @barcode
  

						SELECT 'TRUE' AS Is_Pass 
									, '' AS Error_Message_ENG
									, N'' AS Error_Message_THA
									, N'' AS Handling
									, @material_id as Material_id
									, @mat_type as Material_type_name
									, @mat_lotno as mat_lot_no
									, @limitdate as limit
									, @qty as quantity
									, @pack_std_qty as pack_std_qty 

								COMMIT; 
								RETURN
							END

						SET	@idx = @idx + 1
						END
					END

					ELSE IF   @type = 'PASTE' 
					BEGIN
 
						SET @idx =  1
				  
						WHILE @idx <= 5 
						BEGIN
							IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.machine_materials WHERE machine_id = @MC_ID AND idx = @idx) 
							BEGIN

									INSERT INTO [APCSProDB].[trans].[machine_materials]
										(	  [machine_id]
											, [idx]
											, [material_group_id]
											, [material_id]
											, [location_id]
											, [acc_location_id]
											, [created_at]
											, [created_by]
											, [updated_at]
											, [updated_by])
									SELECT 
									(		 SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) as [machine_id]
											, @idx as [idx] -- 1-5 SOLDER
											, 1 as [material_group_id]
											, [materials].[id] as [material_id]
											, NULL as [location_id]
											, NULL as [acc_location_id]
											, GETDATE() as [created_at]
											, (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno) as [created_by]
											, NULL as [updated_at]
											, NULL as [updated_by]
									FROM [APCSProDB].[trans].[materials]
									WHERE barcode = @barcode
 

									SELECT    @mat_type				=  (SELECT SUBSTRING(REPLACE(MixAGPaste.AGPasteType, '-', '') ,0,CASE WHEN CHARINDEX('/', MixAGPaste.AGPasteType) = 0 THEN LEN(REPLACE(MixAGPaste.AGPasteType, '-', ''))+1 ELSE CHARINDEX('/',REPLACE(MixAGPaste.AGPasteType, '-', ''))  END ))
											, @mat_lotno			=  MixAGPaste.AGPasteLotNo
											, @limitdate			= MixAGPaste.StartTimeMix + Material.STDLifeTimeUser 
									FROM DBx.MAT.MixAGPaste 
									INNER JOIN DBx.MAT.Material 
									ON  MixAGPaste.AGPasteType  = DBx.MAT.Material.Material_Production 
									WHERE (MixAGPaste.QRCode = @barcode )   
									ORDER BY  MixAGPaste.FinishTimeMix ASC


									SELECT 'TRUE' AS Is_Pass 
												, '' AS Error_Message_ENG
												, N'' AS Error_Message_THA
												, N'' AS Handling
												, @material_id as Material_id
												, @mat_type as Material_type_name
												, @mat_lotno as mat_lot_no
												, @limitdate as limit
												, @qty as quantity
												, @pack_std_qty as pack_std_qty 
										COMMIT; 
										RETURN
									END

								SET	@idx = @idx + 1
							END
						END
				ELSE
				BEGIN


					SELECT 'FALSE' AS Is_Pass 
					, 'Material Type this not register' AS Error_Message_ENG
					, N'Material Type นี้ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling

					COMMIT;
					RETURN
				END 

			END 
			END TRY

			BEGIN CATCH
				ROLLBACK;
				SELECT 'FALSE' AS Is_Pass 
					, ERROR_MESSAGE() AS Error_Message_ENG
					, N'การบันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
			END CATCH
			----------------------------------------------------------------------------------------
		END
	
		ELSE BEGIN 
			----------------------------------------------------------------------------------------
			--CHECK MATERIAL ON MACHINE
			DECLARE @mcno_use AS VARCHAR(50) 
			SET @mcno_use = (select TOP 1 MAC.name from APCSProDB.trans.machine_materials MAT inner join APCSProDB.mc.machines MAC on MAT.machine_id = MAC.id where  MAT.material_id = @material_id)
	
			IF @mcno <> @mcno_use BEGIN
				SELECT 'FALSE' AS Is_Pass ,
					'This Material is on machine ('+ @mcno_use + N') !!' AS Error_Message_ENG,
					N'Material นี้ถูกใช้งานอยู่ที่เครื่องจักร ('+ @mcno_use + N') !!' AS Error_Message_THA,
					N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
				RETURN
			END

			IF @type = 'SOLDER TAPE' OR @type = 'SOLDER BALL'  OR @type = 'PASTE' 
			BEGIN
				
				IF @type = 'PASTE' 
				BEGIN 

				SELECT    @mat_type				=  (SELECT SUBSTRING(REPLACE(MixAGPaste.AGPasteType, '-', '') ,0,CASE WHEN CHARINDEX('/', MixAGPaste.AGPasteType) = 0 THEN LEN(REPLACE(MixAGPaste.AGPasteType, '-', ''))+1 ELSE CHARINDEX('/',REPLACE(MixAGPaste.AGPasteType, '-', ''))  END ))
						, @mat_lotno			=  MixAGPaste.AGPasteLotNo
						, @limitdate			= MixAGPaste.StartTimeMix + Material.STDLifeTimeUser 
				FROM DBx.MAT.MixAGPaste 
				INNER JOIN DBx.MAT.Material 
				ON  MixAGPaste.AGPasteType  = DBx.MAT.Material.Material_Production 
				WHERE (MixAGPaste.QRCode = @barcode )   
				ORDER BY  MixAGPaste.FinishTimeMix ASC

				END 

					SELECT  'TRUE'				AS Is_Pass 
							, ''				AS Error_Message_ENG
							, N''				AS Error_Message_THA
							, N''				AS Handling
							, @material_id		AS Material_id
							, @mat_type			AS Material_type_name
							, @mat_lotno		AS mat_lot_no
							, @limitdate		AS limit
							, @qty				AS quantity
							, @pack_std_qty		AS pack_std_qty 
						
						 
						RETURN
					END
		ELSE
		BEGIN 
				SELECT 'TRUE' AS Is_Pass 
					, '' AS Error_Message_ENG
					, N'' AS Error_Message_THA
					, N'' AS Handling
					, @material_id as Material_id
					, @mat_type as Material_type_name
					, @mat_lotno as mat_lot_no
					, @limitdate as limit
					, @qty as quantity
					, @pack_std_qty as pack_std_qty
		END
			----------------------------------------------------------------------------------------
	END
END
