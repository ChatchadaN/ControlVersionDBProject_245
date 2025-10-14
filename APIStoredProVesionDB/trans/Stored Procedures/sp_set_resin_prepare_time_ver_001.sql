-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_resin_prepare_time_ver_001]
	@barcode VARCHAR(255), 
	@emp_code VARCHAR(6), 
	@action INT -- 0 Cancel, 1 Unfreeze
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @emp_id INT = 0;
	DECLARE @day_id INT;
	DECLARE @is_unfreeze INT = 0;
	DECLARE @record_class INT = NULL;

	SELECT @emp_id = id FROM [10.29.1.230].[DWH].[man].[employees] WHERE emp_code = @emp_code

	-- Insert to exec history
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at], [record_class], [login_name] ,[hostname],[appname], [command_text])
	SELECT    GETDATE()
			, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, 'EXEC [trans].[sp_set_resin_prepare_time] @barcode =''' + ISNULL(CAST(@barcode AS nvarchar(MAX)),'') + ''', @emp_code = ''' + ISNULL(CAST(@emp_code AS nvarchar(MAX)),'') + ''', @action = ''' + ISNULL(CAST(@action AS nvarchar(MAX)),'') + '''';

	-- Get unfreeze history
	SELECT @is_unfreeze = 1 FROM APCSProDB.trans.materials
	WHERE barcode = @barcode
	AND open_limit_date1 IS NOT NULL;


	IF ISNULL(@barcode, '') = ''
		BEGIN
			SELECT 'FALSE' AS Is_Pass,
				   'NO BARCODE !!' AS Error_Message_ENG,
				   N'ไม่มี Barcode !!' AS Error_Message_THA,
				   '' AS Handling;
		END
	ELSE IF @emp_id = 0
		BEGIN 
			SELECT 'FALSE' AS Is_Pass,
				   'No Employee Code !!' AS Error_Message_ENG,
				   N'ไม่มีรหัสพนักงาน !!' AS Error_Message_THA,
				   '' AS Handling;
		END
	ELSE IF @is_unfreeze = 1 AND @action = 1
		BEGIN
			SELECT 'FALSE' AS Is_Pass,
				   'It has been unfreezing !!' AS Error_Message_ENG,
				   N'มีการทำละลายแล้ว !!' AS Error_Message_THA,
				   '' AS Handling;
		END
	ELSE IF @is_unfreeze = 0 AND @action = 0
		BEGIN
			SELECT 'FALSE' AS Is_Pass,
				   'No defrost data !!' AS Error_Message_ENG,
				   N'ไม่มีข้อมูลการทำละลาย !!​' AS Error_Message_THA,
				   '' AS Handling;
		END
	ELSE
		BEGIN
		BEGIN TRANSACTION
		BEGIN TRY

			SELECT @day_id = [id] FROM [APCSProDB].[trans].[days] WHERE date_value = CAST(GETDATE() AS DATE)

			IF @action = 1
				BEGIN
					-- Set Prepare
					UPDATE APCSProDB.trans.materials
					SET materials.wait_limit_date = source_table.waiting_limite, 
						materials.open_limit_date1 = source_table.open_limit_date,
						materials.updated_at = GETDATE(),
						materials.updated_by = @emp_id
					FROM ( 
						select m.id, barcode
						  , DATEADD(hour, waiting_hours, GETDATE()) as waiting_limite
						  , DATEADD(hour, (waiting_hours+time_limit1), GETDATE()) as open_limit_date
						from APCSProDB.trans.materials m
						join APCSProDB.material.productions p on m.material_production_id = p.id
						join APCSProDB.material.product_slips ps on p.id = ps.production_id
						join APCSProDB.material.flow_patterns fp on ps.flow_pattern_id = fp.id
						join APCSProDB.material.flow_details fd on fp.id = fd.flow_pattern_id and m.step_no = fd.step_no
						where barcode = @barcode
						and fd.is_used = 1 
					) AS source_table
					WHERE materials.id = source_table.id;

					SET @record_class = 51;
				END
			ELSE 
				BEGIN
					-- Cancel Prepare
					UPDATE APCSProDB.trans.materials
					SET materials.wait_limit_date = NULL, 
						materials.open_limit_date1 = NULL,
						materials.updated_at = GETDATE(),
						materials.updated_by = @emp_id
					WHERE barcode = @barcode;

					SET @record_class = 52;
				END	
			
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

			IF @action = 1
			BEGIN
				SELECT 'TRUE' AS Is_Pass, '' AS Error_Message_ENG, '' AS Error_Message_THA, '' AS Handling, m.id, barcode, 
						name, quantity, lot_no, wait_limit_date wait_date, open_limit_date1 open_limit_date, limit_date, descriptions as unit,
						emp_code, display_name, m.updated_at
				FROM APCSProDB.trans.materials m
				JOIN APCSProDB.material.productions p on m.material_production_id = p.id
				JOIN APCSProDB.material.material_codes on unit_code = material_codes.code AND [group] = 'package_unit'
				JOIN [10.29.1.230].DWH.man.employees on m.updated_by = employees.id
				WHERE barcode = @barcode
			END
			ELSE 
			BEGIN
				SELECT 'TRUE' AS Is_Pass, 
					   '' AS Error_Message_ENG, 
					   '' AS Error_Message_THA ,
					   '' AS Handling;
			END

		END TRY
		BEGIN CATCH
			ROLLBACK;

			SELECT  'FALSE' AS Is_Pass ,
					'Recording fail. !!' AS Error_Message_ENG ,
					-- ERROR_MESSAGE() AS Error_Message_ENG ,
					N'การบันทึกผิดพลาด !!' AS Error_Message_THA,
					'' AS Handling
		END CATCH
		END

END