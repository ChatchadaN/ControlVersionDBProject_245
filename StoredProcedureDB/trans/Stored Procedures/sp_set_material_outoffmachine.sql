-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_material_outoffmachine] 
	-- Add the parameters for the stored procedure here
		@barcode_out AS VARCHAR(15),
		@opno AS VARCHAR(6),
		@mcno AS VARCHAR(20),
		@is_outoffstock AS INT = 0
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
		, 'EXEC [trans].[sp_set_material_outoffmachine] @barcode = ''' + ISNULL(CAST(@barcode_out AS varchar),'') + ''', @opno = ''' + ISNULL(CAST(@opno AS varchar),'') 
			+ ''', @mcno = ''' + ISNULL(CAST(@mcno AS varchar),'') + ''', @is_outoffstock = ''' + ISNULL(CAST(@is_outoffstock AS varchar),'') + '''' 
		, @barcode_out
	---->> log exec

    -- Insert statements for procedure here

	BEGIN TRANSACTION
		BEGIN TRY

		IF EXISTS (SELECT 1 FROM APCSProDB.trans.materials WHERE barcode = @barcode_out) BEGIN

			--updata material out
			DECLARE @Location_id_out AS INT,
			@Mat_state_out  AS INT,
			@qty_out  AS DECIMAL(18,6),
			@mat_record_id_out  AS INT,
			@mat_type_out  AS VARCHAR(100),
			@limitdate_out  AS DATETIME

			SELECT @Location_id_out  = location_id, @Mat_state_out  = material_state ,@mat_type_out  = p.name, @limitdate_out  = ISNULL(m.extended_limit_date,m.limit_date)
			, @qty_out = m.quantity
			FROM APCSProDB.trans.materials m INNER JOIN APCSProDB.material.productions p ON m.material_production_id = p.id   WHERE barcode = @barcode_out 

			IF @Location_id_out <> 9 AND @Mat_state_out <> 12 BEGIN
				SELECT 'FALSE' AS Is_Pass ,'This Material is not on machine. !!' AS Error_Message_ENG,N'Material นี้ไม่ได้อยู่ในเครื่องจักร !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
				RETURN
			END

			SET @mat_record_id_out  = (SELECT id + 1 FROM [APCSProDB].[trans].[numbers] WHERE [name] = 'material_records.id')

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
					,IIF(@is_outoffstock = 1,0,2) AS [material_state] --0 Out of stock,2 Returned
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
				  [material_state] = IIF(@is_outoffstock = 1,0,2) --1
				  --,[location_id] = 9
				  ,[updated_at] = GETDATE()
				  ,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
			   WHERE barcode = @barcode_out 

			   --Update machine_materials 
			  -- UPDATE [APCSProDB].[trans].[machine_materials]
					--SET material_id = NULL
			   DELETE [APCSProDB].[trans].[machine_materials]
			   WHERE [machine_id] = (SELECT [machines].[id] FROM [APCSProDB].[mc].[machines] where name = @mcno)
					AND [material_id] = (SELECT [materials].[id] FROM [APCSProDB].[trans].[materials] where barcode = @barcode_out)

		END

		SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'' AS Error_Message_THA, N'' AS Handling
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Update fail. !!' AS Error_Message_ENG,N'การบันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
	END CATCH
END
