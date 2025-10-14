------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Chatchadaporn N
-- Written Date             : 2024/08/22
-- Procedure Name 	 		: [material].[sp_get_wfdetails]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [material].[sp_set_chipbank_wfdata_update]
	 @WFLOTNO VARCHAR(50)	--[WFLOTNO]
	,@SEQNO VARCHAR(50)		--[SEQNO]
	,@WF_COUNT INT			--[WFCOUNT]
	,@CHIP_COUNT INT		--[CHIPCOUNT]

	,@UPDATED_AT DATETIME	--[TIMESTAMP]
	,@OP_ID VARCHAR(50)		--[STAFFNO] 
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRY
		DECLARE @mat_id INT

		SELECT @mat_id = wf_details.material_id 
		FROM [10.28.32.122].APCSProDB_Backup20240516.trans.wf_details
		WHERE wf_details.seq_no = @SEQNO

		--UPDATE MATERIAL : Quantity
		UPDATE [10.28.32.122].[APCSProDB_Backup20240516].[trans].[materials]
		SET quantity = @WF_COUNT
		--,updated_at = GETDATE()
		,updated_at = @UPDATED_AT
		,updated_by = @OP_ID
		WHERE id = @mat_id


		--UPDATE wf_details : chip_remain
		UPDATE [10.28.32.122].APCSProDB_Backup20240516.trans.wf_details
		SET chip_remain = @CHIP_COUNT
		--,updated_at = GETDATE()
		,updated_at = @UPDATED_AT
		,updated_by = @OP_ID
		WHERE material_id = @mat_id

		SELECT 'TRUE' AS Is_Pass
		,'Updated Data Success!!' AS Error_Message_ENG
		,N'บันทึกข้อมูลสำเร็จ !!' AS Error_Message_THA
		,N'' AS Headlind
		COMMIT;
	END TRY
	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass 
		,ERROR_MESSAGE() AS Error_Message_ENG
		,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
		,N'Please check the data !!' AS Headlind
	END CATCH
END
