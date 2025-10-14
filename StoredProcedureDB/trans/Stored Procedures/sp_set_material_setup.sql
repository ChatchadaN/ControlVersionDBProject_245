-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_material_setup] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(10),
	@barcode AS VARCHAR(15),
	@opno AS VARCHAR(6),
	@mcno AS VARCHAR(20),
	@input_qty as DECIMAL(18,6) = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	----<< log exec
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
		, 'EXEC [trans].[sp_set_material_setup] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') + ''', @barcode = ''' + ISNULL(CAST(@barcode AS varchar),'') + ''', @opno = ''' 
			+ ISNULL(CAST(@opno AS varchar),'') +  ''', @mcno = ''' + ISNULL(CAST(@mcno AS varchar),'') + '''' + ''', @input_qty = ''' + ISNULL(CAST(@input_qty AS varchar),'') + ''''
		, @lot_no
	---->> log exec

    -- Insert statements for procedure here
	DECLARE @Location_id AS INT,
			@Mat_state AS INT,
			@qty AS DECIMAL(18,6),
			@mat_record_id AS INT,
			@mat_type AS VARCHAR(100),
			@limitdate AS DATETIME,
			@mat_lotno AS VARCHAR(MAX)

	-- CHECK BARCODE
	IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.materials WHERE barcode = @barcode) BEGIN
		SELECT 'FALSE' AS Is_Pass, 'Material is not found. !!' AS Error_Message_ENG,N'ไม่พบข้อมูล Material นี้ !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
		RETURN
	END

	SELECT @Location_id = location_id, @Mat_state = material_state ,@mat_type = p.name, @limitdate = ISNULL(m.extended_limit_date,m.limit_date)
	,@mat_lotno = m.lot_no,@qty = m.quantity
	FROM APCSProDB.trans.materials m INNER JOIN APCSProDB.material.productions p ON m.material_production_id = p.id   WHERE barcode = @barcode

	--CHECK EXPIRE
	IF(@limitdate < GETDATE()) BEGIN
		SELECT 'FALSE' AS Is_Pass, 'Material is expire. !!( '+ @limitdate +' )'  AS Error_Message_ENG,N'Material นี้หมดอายุการใช้งานแล้ว ( '+ @limitdate +' ) !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
		RETURN
	END

	IF(@qty <= 0 ) BEGIN
		SELECT 'FALSE' AS Is_Pass, 'Material is used up. !!'  AS Error_Message_ENG,N'Material นี้ใช้งานหมดแล้วแล้ว !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
		RETURN
	END

	--CHECK TYPE 
	IF (SELECT dp.FRAME_NAME FROM APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT dp WHERE dp.LOT_NO_1 = @lot_no) <> @mat_type BEGIN
		SELECT 'FALSE' AS Is_Pass, 'Frame type is not match. !!' AS Error_Message_ENG,N'Frame Type ไม่ตรงกัน. !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
		RETURN
	END

	--  location = Machine, state = 1 (พร้อมใช้)
	IF (@Location_id = 9 AND @Mat_state in (1,2))  BEGIN	

		BEGIN TRANSACTION
		BEGIN TRY

			SET @mat_record_id = (SELECT id + 1 FROM [APCSProDB].[trans].[numbers] WHERE [name] = 'material_records.id')

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
					,5 AS recored_class
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
					,12 AS [material_state]
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

			   --update material
			   UPDATE APCSProDB.[trans].[materials]
			   SET 				 
				  [material_state] = 12
				  --,[location_id] = 9
				  ,[updated_at] = GETDATE()
				  ,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
				WHERE barcode = @barcode

				--update material on machine
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
					, 1 as [idx] --frame
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

				IF(@qty < @input_qty ) BEGIN
					SELECT 'TRUE' AS Is_Pass, 'This material is not enough. !!'  AS Error_Message_ENG,N'Material นี้ไม่เพียงพอในการผลิต กรุณาเพิ่ม Material !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling, 
							@barcode AS Barcode, @mat_type AS Material_Type, @mat_lotno AS Mat_Lotno,@qty AS QTY, @limitdate AS Expire_Date
				END
				ELSE BEGIN
					SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'' AS Error_Message_THA, N'' AS Handling, @barcode AS Barcode, @mat_type AS Material_Type, @mat_lotno AS Mat_Lotno,@qty AS QTY, @limitdate AS Expire_Date
				END
			COMMIT; 
		END TRY

		BEGIN CATCH
			ROLLBACK;
			SELECT 'FALSE' AS Is_Pass ,'Update fail. !!' AS Error_Message_ENG,N'การบันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
		END CATCH
	END
	ELSE BEGIN
	--CHECK MATERIAL ON MACHINE
		IF @Location_id = 9 AND @Mat_state = 12 BEGIN
			SELECT 'FALSE' AS Is_Pass ,'This Material is on another machine. !!' AS Error_Message_ENG,N'Material นี้ถูกใช้งานอยู่ที่เครื่องจักรอื่นแล้ว !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
			RETURN
		END
		
		SELECT 'FALSE' AS Is_Pass ,'Material State Invalid. !!' AS Error_Message_ENG,N'สถานะ Material ไม่ถูกต้อง !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
	END
END
