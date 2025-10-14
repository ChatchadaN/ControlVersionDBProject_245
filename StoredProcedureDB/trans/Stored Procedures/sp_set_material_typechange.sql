-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_material_typechange]
	-- Add the parameters for the stored procedure here
	@barcode AS VARCHAR(13),
	@opno AS VARCHAR(6),
	@mcno AS VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @Location_id AS INT,
			@Mat_state AS INT,
			@qty AS DECIMAL(18,6),
			@mat_record_id AS INT,
			@mat_type AS VARCHAR(100),
			@limitdate AS DATETIME

	-- CHECK BARCODE
	IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.materials WHERE barcode = @barcode) BEGIN
		SELECT 'FALSE' AS Is_Pass, 'Material is not found. !!' AS Error_Message_ENG,N'ไม่พบข้อมูล Material นี้' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
		RETURN
	END

	SELECT @Location_id = location_id, @Mat_state = material_state ,@mat_type = p.name, @limitdate = ISNULL(m.extended_limit_date,m.limit_date)
	FROM APCSProDB.trans.materials m INNER JOIN APCSProDB.material.productions p ON m.material_production_id = p.id   WHERE barcode = @barcode

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
					,11 AS recored_class
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
					,0 AS [material_state]
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
					,7 AS [to_location_id]
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
				  [material_state] = 0
				  ,[location_id] = 7
				  ,[updated_at] = GETDATE()
				  ,[updated_by] = (SELECT id FROM APCSProDB.man.users WHERE emp_num = @opno)
				WHERE barcode = @barcode

			   SELECT 'TRUE' AS Is_Pass ,'' AS Error_Message_ENG,N'' AS Error_Message_THA,@mat_type AS Material_Type, N'' AS Handling
			COMMIT; 
		END TRY

		BEGIN CATCH
			ROLLBACK;
			SELECT 'FALSE' AS Is_Pass ,'Update fail. !!' AS Error_Message_ENG,N'การบันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling
		END CATCH
	
END
