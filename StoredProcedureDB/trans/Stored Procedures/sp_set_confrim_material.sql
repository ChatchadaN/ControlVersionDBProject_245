-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_confrim_material]
	-- Add the parameters for the stored procedure here
	@barcode AS VARCHAR(13),
	@user_id AS INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	-----------------------------------
	-- check barcode
	-----------------------------------
	IF NOT EXISTS (SELECT 1 FROM APCSProDB.trans.materials WHERE barcode = @barcode) 
	BEGIN
		-----------------------------------
		-- fail
		-----------------------------------
		SELECT 'FALSE' AS Is_Pass
			, 'Material is not found. !!' AS Error_Message_ENG
			, N'ไม่พบข้อมูล Material นี้' AS Error_Message_THA
			, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling;
		RETURN
	END
	-----------------------------------
	-- check barcode duplicate data
	-----------------------------------
	IF EXISTS (SELECT 1 FROM [APCSProDB].[trans].[material_records] WHERE barcode = @barcode and record_class = 9) 
	BEGIN
		-----------------------------------
		-- by pass
		-----------------------------------
		SELECT 'TRUE' AS Is_Pass 
			, '' AS Error_Message_ENG
			, N'' AS Error_Message_THA
			, N'' AS Handling;
		RETURN
	END
	-----------------------------------
	-- exec
	-----------------------------------
	BEGIN TRANSACTION
	BEGIN TRY
		-------------------------------------------------( TRY )-------------------------------------------------
		DECLARE @mat_record_id AS INT
		DECLARE @r AS INT

		SET @mat_record_id = (SELECT id + 1 FROM [APCSProDB].[trans].[numbers] WHERE [name] = 'material_records.id')
		-----------------------------------
		--(1) update material
		-----------------------------------
		UPDATE APCSProDB.[trans].[materials]
		SET [updated_at] = GETDATE()
			, [updated_by] = @user_id
		WHERE barcode = @barcode;
		-----------------------------------
		--(2) insert material_records
		-----------------------------------
		INSERT INTO [APCSProDB].[trans].[material_records]
		(
			[id]
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
			, [to_location_id]
		)
		SELECT 
			@mat_record_id AS [id]
			, (SELECT id FROM APCSProDB.trans.days WHERE date_value = CAST(GETDATE()AS date)) AS [day_id]
			, GETDATE() AS [recorded_at]
			, @user_id AS [operated_by]
			, 9 AS [recored_class]
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
			, [location_id] AS [to_location_id]
		FROM [APCSProDB].[trans].[materials]
		WHERE barcode = @barcode;	
		-----------------------------------
		--(3) update material_records.id (trans.numbers)
		-----------------------------------
		set @r = @@ROWCOUNT
		UPDATE APCSProDB.trans.numbers
		SET id = id + @r
		WHERE name = 'material_records.id';
		-----------------------------------
		--(4) success
		-----------------------------------
		SELECT 'TRUE' AS Is_Pass 
			, '' AS Error_Message_ENG
			, N'' AS Error_Message_THA
			, N'' AS Handling;
		COMMIT; 
		-------------------------------------------------( TRY )-------------------------------------------------
	END TRY
	BEGIN CATCH
		-------------------------------------------------( CATCH )-------------------------------------------------
		ROLLBACK;
		-----------------------------------
		-- fail
		-----------------------------------
		SELECT 'FALSE' AS Is_Pass 
			, 'Update fail. !!' AS Error_Message_ENG
			, N'การบันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
			, N'กรุณาตรวจสอบข้อมูลที่เว็บ material' AS Handling;
		-------------------------------------------------( CATCH )-------------------------------------------------
	END CATCH
END
