------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Chatchadaporn N
-- Written Date             : 2024/08/22
-- Procedure Name 	 		: [material].[sp_get_wfdetails]
-- Database Referd			: StoredProcedureDB
---- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [material].[sp_set_chipbank_WFMat]
	-- Add the parameters for the stored procedure here
	@mat_id int
	, @wafer_new decimal
	, @chip_new decimal
	, @waferIds [dbo].[WaferIdList] READONLY
	, @created_by VARCHAR(10)

AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @emp_id int

	SELECT @emp_id = id FROM APCSProDB.man.users
	WHERE emp_num = @created_by

	DECLARE @TABLE_WFID TABLE
	(wafer_id int)

	INSERT INTO @TABLE_WFID (wafer_id)
	SELECT WaferId FROM @waferIds

	BEGIN TRANSACTION;
	BEGIN TRY
		--IF (@wafer_new = 0 or @chip_new = 0)
		--BEGIN
		--	ROLLBACK;
		--	SELECT 'FALSE' AS Is_Pass
		--	,'No Wafer Request !!' AS Error_Message_ENG
		--	,N'ERROR: ไม่มีการเบิก Wafer !!' AS Error_Message_THA
		--	,N'Please check the data !!' AS Headlind
		--	RETURN;
		--END

		DECLARE @wf_new_x int
		, @chip_new_x int
		, @wf_old int
		, @chip_old int
		, @wf_old_x int
		, @chip_old_x int

		SELECT @wf_old_x = COUNT(idx)
		, @chip_old_x = SUM(qty)
		FROM APCSProDB.trans.wf_datas AS wf
		INNER JOIN @TABLE_WFID AS wf_id 
			ON wf.idx = wf_id.wafer_id
		WHERE wf.material_id = @mat_id

		SELECT @wf_old = quantity
		,@chip_old = chip_remain
		FROM APCSProDB.trans.materials
		INNER JOIN APCSProDB.trans.wf_details ON materials.id = wf_details.material_id
		INNER JOIN APCSProDB.trans.wf_datas ON materials.id = wf_datas.material_id
		WHERE id = @mat_id 

		--SET @wf_new_x = @wf_old - @wf_old_x
		SET @chip_new_x = @chip_old - @chip_old_x

		IF (@chip_new <> @chip_new_x)
		BEGIN
			ROLLBACK;
			SELECT 'FALSE' AS Is_Pass
			,'The number of Wafer or Chip is incorrect !!' AS Error_Message_ENG
			,N'ERROR: Chip ไม่ถูกต้อง !!' AS Error_Message_THA
			,N'Please check the data !!' AS Headlind
			RETURN;
		END

		BEGIN
			--UPDATE wafer_data is_enable = 0 (Disable)
			UPDATE wf
			SET wf.is_enable = 0
			FROM APCSProDB.trans.wf_datas AS wf
			INNER JOIN @TABLE_WFID AS wf_id 
				ON wf.idx = wf_id.wafer_id
			WHERE wf.material_id = @mat_id

			--UPDATE WFCOUNT
			UPDATE APCSProDB.trans.materials
			SET quantity = @wafer_new
			,updated_at = GETDATE()
			,updated_by = @emp_id
			WHERE id = @mat_id

			--UPDATE CHIP_REMAIN
			UPDATE APCSProDB.trans.wf_details
			SET chip_remain = @chip_new
			,updated_at = GETDATE()
			,updated_by = @emp_id
			WHERE material_id = @mat_id
		END

		SELECT 'TRUE' AS Is_Pass
		,'Updated Data Success!!' AS Error_Message_ENG
		,N'บันทึกข้อมูลสำเร็จ !!' AS Error_Message_THA
		,N'' AS Headlind
		COMMIT;

	END TRY
	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass 
		,'Updated fail. !!' AS Error_Message_ENG
		,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
		,N'Please check the data !!' AS Headlind
	END CATCH

END