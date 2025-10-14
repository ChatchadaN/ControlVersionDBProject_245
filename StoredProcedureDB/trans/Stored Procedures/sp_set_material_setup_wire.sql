-- =============================================
-- Author:		<Kittitat Panomsai>
-- Create date: <1/6/2022>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_material_setup_wire] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(10),
	@barcode AS VARCHAR(15),
	@opno AS VARCHAR(6),
	@mcno AS VARCHAR(20)
	--@input_qty as INT = 0
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
		, 'EXEC [trans].[sp_set_material_setup_wire] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') + ''', @barcode = ''' + ISNULL(CAST(@barcode AS varchar),'') + ''', @opno = ''' 
			+ ISNULL(CAST(@opno AS varchar),'') +  ''', @mcno = ''' + ISNULL(CAST(@mcno AS varchar),'') +''''
		, @lot_no
	---->> log exec

	DECLARE @material_id as INT
		, @material_type_id as INT
		, @Location_id AS INT
		, @Mat_state AS TINYINT
		, @qty AS DECIMAL(18,6)
		, @mat_record_id AS INT
		, @mat_type AS NVARCHAR(100)
		, @mat_lotno AS VARCHAR(MAX)
		, @limitdate AS DATETIME
		, @pack_std_qty AS DECIMAL

	SELECT @material_type_id = material_production_id
		, @material_id = m.id
		, @Location_id = location_id
		, @Mat_state = material_state 
		, @mat_type = p.name --type name
		, @limitdate = ISNULL(m.extended_limit_date,m.limit_date) --expire
		, @mat_lotno = m.lot_no --lot_no
		, @qty = m.quantity --quan
		, @pack_std_qty = p.pack_std_qty
	FROM APCSProDB.trans.materials m 
	INNER JOIN APCSProDB.material.productions p ON m.material_production_id = p.id
	WHERE barcode = @barcode

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
					, location_id AS [to_location_id]
				FROM [APCSProDB].[trans].[materials]
				WHERE barcode = @barcode

				----update material_records.id count
				DECLARE @r AS INT
				set @r = @@ROWCOUNT
				UPDATE APCSProDB.trans.numbers
				SET id = id + @r
				WHERE name = 'material_records.id'

				----update material
				UPDATE APCSProDB.[trans].[materials]
				SET [material_state] = 12
					,[updated_at] = GETDATE()
					,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
				WHERE barcode = @barcode


--//////////////////////// Update Machine Materials   2022/02/10
				IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_materials 
					INNER JOIN APCSProDB.mc.machines ON machines.id = machine_materials.machine_id
					WHERE machines.name = @mcno)
				BEGIN
				--////////////////// UPDATE Material Out
					DECLARE @barcode_out AS VARCHAR(15),
							@mat_record_id_out AS INT

					SELECT @barcode_out = materials.barcode FROM APCSProDB.trans.machine_materials 
						INNER JOIN APCSProDB.mc.machines ON machines.id = machine_materials.machine_id
						INNER JOIN APCSProDB.trans.materials ON materials.id = machine_materials.material_id
					WHERE machines.name = @mcno AND machine_materials.idx = 1

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
							WHERE barcode = @barcode_out 

							--update material_records.id count
							   DECLARE @r_out  AS INT
							   set @r_out  = @@ROWCOUNT
							   UPDATE APCSProDB.trans.numbers
							   SET id = id + @r_out 
							   WHERE name = 'material_records.id'

							--update material out
							   UPDATE APCSProDB.[trans].[materials]
							   SET 
								  [material_state] = IIF([quantity] = 0,0,2) --1
								  --,[location_id] = 9
								  ,[updated_at] = GETDATE()
								  ,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
							   WHERE barcode = @barcode_out 
						END

						IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_materials  
							WHERE machine_id = (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) AND idx = 1)
						BEGIN
							UPDATE APCSProDB.trans.machine_materials 
							SET material_id = @material_id
								,[updated_at] = GETDATE()
								,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
							WHERE machine_id = (SELECT id FROM [APCSProDB].[mc].[machines] where name = @mcno) 
								  AND idx = 1
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
								, 1 as [idx] -- 1-10 wire
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
						, 1 as [idx] --wire
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
--//////////////////////////////////////////////////////

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
			END TRY

			BEGIN CATCH
				ROLLBACK;
				SELECT 'FALSE' AS Is_Pass 
					, 'Update fail. !!' AS Error_Message_ENG
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

			IF @Location_id = 9 AND @Mat_state = 12 AND @mcno <> @mcno_use BEGIN
				SELECT 'FALSE' AS Is_Pass ,
					'This Material is on machine (N'+ @mcno_use +'N) !!' AS Error_Message_ENG,
					N'Material นี้ถูกใช้งานอยู่ที่เครื่องจักร (N'+ @mcno_use +'N) !!' AS Error_Message_THA,
					N'กรุณาตรวจสอบข้อมูลที่เว็บไซต์ Material' AS Handling
				RETURN
			END
		
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

			--SELECT 'FALSE' AS Is_Pass 
			--	,'Material is not in location M/C or stae is not ready !!' AS Error_Message_ENG
			--	, N'Material ไม่ได้อยู่ใน location M/C หรือ Material ไม่พร้อมใช้งาน !!' AS Error_Message_THA
			--	, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
			----------------------------------------------------------------------------------------
		END

END
