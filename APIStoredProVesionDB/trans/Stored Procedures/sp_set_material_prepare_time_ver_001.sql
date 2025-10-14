-- =============================================
-- Author:		<Author,Yitida P.>
-- Create date: <Create Date, 03 Oct. 2025>
-- Update date: <Update Date, 07 Oct. 2025>
-- Description:	<Description, For prepare materials>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_material_prepare_time_ver_001]
	@barcode VARCHAR(255),
	@emp_code VARCHAR(6),
	@action INT -- 0 Cancel, 1 Unfreeze, 2 Unpack
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @emp_id INT = 0;
	DECLARE @day_id INT;
	DECLARE @is_unfreeze INT = 0; -- 0 Not have history, 1 have history
	DECLARE @ready_step INT = 0; -- 0 Not Ready, Ready
	DECLARE @record_class INT = NULL;
	DECLARE @step_no INT = NULL;

	SELECT @emp_id = id FROM [10.29.1.230].[DWH].[man].[employees] WHERE emp_code = @emp_code

	-- Insert to exec history
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at], [record_class], [login_name] ,[hostname],[appname], [command_text])
	SELECT    GETDATE()
			, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, 'EXEC [trans].sp_set_material_prepare_time] @barcode =''' + ISNULL(CAST(@barcode AS nvarchar(MAX)),'') + ''', @emp_code = ''' + ISNULL(CAST(@emp_code AS nvarchar(MAX)),'') + ''', @action = ''' + ISNULL(CAST(@action AS nvarchar(MAX)),'') + '''';

	-- Get unfreeze history
	SELECT @is_unfreeze = 1
			, @ready_step = CASE WHEN GETDATE() >= wait_limit_date AND GETDATE() <= open_limit_date1 THEN 1 ELSE 0 END
			, @step_no = step_no
	FROM APCSProDB.trans.materials
	WHERE barcode = @barcode
	AND wait_limit_date IS NOT NULL;

	BEGIN TRANSACTION
	BEGIN TRY

		IF ISNULL(@barcode, '') = ''
			BEGIN
				SELECT 'FALSE' AS Is_Pass,
					   'NO BARCODE !!' AS Error_Message_ENG,
					   N'ไม่มี Barcode !!' AS Error_Message_THA,
					   '' AS Handling;
				ROLLBACK;
				RETURN;
			END
		ELSE IF NOT EXISTS ( SELECT 1 FROM APCSProDB.trans.materials WHERE barcode = @barcode ) 
			BEGIN
				SELECT 'FALSE' AS Is_Pass,
					   concat('Invalid Barcode: ', @barcode, ' !!') AS Error_Message_ENG,
					   concat(N'Barcode: ', @barcode, N' ไม่มีในระบบ !!') AS Error_Message_THA,
					   '' AS Handling;
				ROLLBACK;
				RETURN;
			END	 
		ELSE IF @emp_id = 0
			BEGIN 
				SELECT 'FALSE' AS Is_Pass,
					   'No employee code !!' AS Error_Message_ENG,
					   N'ไม่มีรหัสพนักงาน !!' AS Error_Message_THA,
					   '' AS Handling;
				ROLLBACK;
				RETURN;
			END
		ELSE IF @action = 0 -- Set cancel prepare
			BEGIN
				IF @is_unfreeze = 0
					BEGIN
						SELECT 'FALSE' AS Is_Pass,
							   'No unfreeze data !!' AS Error_Message_ENG,
							   N'ไม่มีข้อมูลการทำละลาย !!​' AS Error_Message_THA,
							   '' AS Handling;
						ROLLBACK;
						RETURN;
					END
				ELSE
					BEGIN
						--UPDATE APCSProDB.trans.materials
						--SET materials.wait_limit_date = NULL, 
						--	materials.open_limit_date1 = NULL,
						--	materials.step_no = 100,
						--	materials.updated_at = GETDATE(),
						--	materials.updated_by = @emp_id
						--WHERE barcode = @barcode;
						UPDATE materials
						SET materials.wait_limit_date = ISNULL(source.wait_limit_date, NULL), 
							materials.open_limit_date1 = ISNULL(source.open_limit_date1, NULL),
							materials.step_no = CASE WHEN source.step_no is null THEN 100 ELSE source.step_no END,
							materials.updated_at = GETDATE(),
							materials.updated_by = @emp_id
						FROM APCSProDB.trans.materials materials
						OUTER APPLY (
							SELECT [material_id], [step_no], [open_limit_date1], [wait_limit_date]
							FROM APCSProDB.trans.material_records
							WHERE barcode = @barcode
							AND record_class <> 52
							AND step_no < @step_no
							ORDER BY id DESC
							OFFSET 0 ROW FETCH NEXT 1 ROW ONLY
						) source
						WHERE barcode = @barcode;

						SET @record_class = 52;
					END
			END
		ELSE IF @action = 1 -- Set Prepare
			BEGIN
				IF @is_unfreeze = 1
					BEGIN
						SELECT 'FALSE' AS Is_Pass,
							   'It was unfreeze, Can''t be replicated !!' AS Error_Message_ENG,
							   N'มีการทำละลายแล้ว ไม่สามารถทำซ้ำได้ !!' AS Error_Message_THA,
							   '' AS Handling;
						ROLLBACK;
						RETURN;
					END
				ELSE
					BEGIN
						UPDATE APCSProDB.trans.materials
						SET materials.wait_limit_date = source_table.waiting_limite, 
							materials.open_limit_date1 = source_table.open_limit_date,
							materials.step_no = source_table.step_no,
							materials.updated_at = GETDATE(),
							materials.updated_by = @emp_id
						FROM ( 
								select top 1 m.id, barcode, pf.step_no 
									, DATEADD(hour, waiting_hours, GETDATE()) as waiting_limite
									, DATEADD(hour, (waiting_hours+time_limit1), GETDATE()) as open_limit_date
								from APCSProDB.trans.materials m
								join APCSProDB.material.product_slips ps on m.material_production_id = ps.production_id
								join APCSProDB.material.product_flows pf on ps.slip_id = pf.product_slip_id
								where barcode = @barcode
								and pf.step_no > m.step_no
								and pf.is_used = 1
								and pf.operation_category <> 4
								order by pf.step_no
						) AS source_table
						WHERE source_table.id IS NOT NULL
						AND materials.id = source_table.id;

						SET @record_class = 51;

					END
			END
		ELSE IF @action = 2 -- Set Unpacking
			BEGIN
				IF @ready_step = 0 
				BEGIN
					SELECT 'FALSE' AS Is_Pass,
						   'Material is not available !!' AS Error_Message_ENG,
						   N'วัตถุดิบไม่พร้อมใช้งาน !!' AS Error_Message_THA,
						   '' AS Handling;
					ROLLBACK;
					RETURN;
				END
				ELSE IF @step_no = 300
				BEGIN
					SELECT 'FALSE' AS Is_Pass,
						   'Material has been unpacked !!' AS Error_Message_ENG,
						   N'วัตถุดิบมีการเปิดหีบห่อแล้ว !!' AS Error_Message_THA,
						   '' AS Handling;
					ROLLBACK;
					RETURN;
				END
				ELSE 
				BEGIN
					UPDATE APCSProDB.trans.materials
					SET materials.wait_limit_date = source_table.waiting_limite, 
						materials.open_limit_date1 = source_table.open_limit_date,
						materials.step_no = source_table.step_no,
						materials.updated_at = GETDATE(),
						materials.updated_by = @emp_id
					FROM ( 
							select top 1 m.id, barcode, pf.step_no 
								, DATEADD(hour, waiting_hours, GETDATE()) as waiting_limite
								, DATEADD(hour, (waiting_hours+time_limit1), GETDATE()) as open_limit_date
							from APCSProDB.trans.materials m
							join APCSProDB.material.product_slips ps on m.material_production_id = ps.production_id
							join APCSProDB.material.product_flows pf on ps.slip_id = pf.product_slip_id
							where barcode = @barcode
							and pf.step_no > m.step_no
							and pf.is_used = 1
							and pf.operation_category <> 4
							order by pf.step_no
					) AS source_table
					WHERE source_table.id IS NOT NULL
					AND materials.id = source_table.id;

					SET @record_class = 53;
				END
			END

		--print @@ROWCOUNT;
		--ROLLBACK;

	
			IF @@ROWCOUNT > 0
			BEGIN 
				SELECT @day_id = [id] FROM [APCSProDB].[trans].[days] WHERE date_value = CAST(GETDATE() AS DATE)

				-- เพิ่มการ get material_records_id
				DECLARE @material_records_id INT;
				EXEC	[StoredProcedureDB].[trans].[sp_get_number_id]
						@TABLENAME = N'material_records.id',
						@NEWID = @material_records_id OUTPUT

				-- เพิ่มการ insert ข้อมูล material_records_id
				INSERT INTO APCSProDB.trans.material_records
				SELECT @material_records_id, @day_id, GETDATE(), @emp_id, @record_class,
				id, barcode, material_production_id, step_no, in_quantity, quantity, fail_quantity,pack_count, limit_base_date, contents_record_id, is_production_usage,
				material_state, process_state, qc_state, first_ins_state, final_ins_state, limit_state, limit_date, extended_limit_date, open_limit_date1, open_limit_date2,
				wait_limit_date, location_id, acc_location_id, lot_no, qc_comment_id, qc_memo_id, arrival_material_id, parent_material_id, dest_lot_id, created_at,
				created_by, updated_at, updated_by, null
				FROM [APCSProDB].[trans].[materials]
				WHERE barcode = @barcode
			
				COMMIT;

				IF @action = 1 OR @action = 2
				BEGIN
					SELECT 'TRUE' AS Is_Pass, '' AS Error_Message_ENG, '' AS Error_Message_THA, '' AS Handling, m.id, barcode, step_no,
							[name], quantity, lot_no, wait_limit_date wait_date, open_limit_date1 open_limit_date, limit_date, descriptions as unit,
							emp_code, display_name, m.updated_at
					FROM APCSProDB.trans.materials m
					JOIN APCSProDB.material.productions p on m.material_production_id = p.id
					JOIN APCSProDB.material.material_codes on unit_code = material_codes.code AND [group] = 'package_unit'
					JOIN DWH.man.employees on m.updated_by = employees.id
					WHERE barcode = @barcode
				END
				ELSE 
				BEGIN
					SELECT 'TRUE' AS Is_Pass, 
						   '' AS Error_Message_ENG, 
						   '' AS Error_Message_THA ,
						   '' AS Handling;
				END
			END
			ELSE 
			BEGIN
				ROLLBACK;
				SELECT  'FALSE' AS Is_Pass ,
						'Recording fail. !!' AS Error_Message_ENG ,
						N'การบันทึกผิดพลาด !!' AS Error_Message_THA,
						'' AS Handling
			END
	

		END TRY
		BEGIN CATCH
			ROLLBACK;
			SELECT  'FALSE' AS Is_Pass ,
					'Recording fail. !!' AS Error_Message_ENG ,
					ERROR_MESSAGE() AS Error_Message_ENG ,
					'' AS Handling
		END CATCH
END