-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_product_slip_001]
	  @slip_id INT = 0,
      @production_id INT,
      @flow_pattern_id INT,
      @version_num INT,
      @is_released INT,
	  @emp_code VARCHAR(6)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @new_id INT
	DECLARE @emp_id INT

	SELECT @emp_id = id FROM [DWH].[man].[employees] WHERE emp_code = @emp_code
	-- SET @emp_id = 703

	BEGIN TRANSACTION
	IF @slip_id IS NOT NULL AND @slip_id <> 0
		BEGIN TRY
			-- UPDATE STATEMENT
			-- update at material.product_slips
			UPDATE APCSProDB.material.product_slips SET
				[production_id] = @production_id,
				[flow_pattern_id] = @flow_pattern_id,
				[version_num] = @version_num,
				[is_released] = @is_released,
				[updated_at] = GETDATE(),
				[updated_by] = @emp_id
			WHERE slip_id = @slip_id

			-- insert to material_hist.product_slips_hist
			INSERT INTO [APCSProDB].[material_hist].[product_slips_hist]
				([category], [slip_id], [production_id], [flow_pattern_id], [version_num], [is_released], [created_at], [created_by], [updated_at], [updated_by])
			SELECT 2, [slip_id], [production_id], [flow_pattern_id], [version_num], [is_released], [created_at], [created_by], [updated_at] ,[updated_by]
			FROM APCSProDB.material.product_slips 
			WHERE [slip_id] = @slip_id

			COMMIT;
			SELECT    'TRUE'      AS Is_Pass 
					, 'Success'	  AS Error_Message_ENG
					, N'บันทึกสำเร็จ' AS Error_Message_THA
					, '' AS Handling;

		END TRY
		BEGIN CATCH
			ROLLBACK;
			SELECT  'FALSE' AS Is_Pass ,
					-- 'Recording fail. !!' AS Error_Message_ENG ,
					ERROR_MESSAGE() AS Error_Message_ENG ,
					N'การบันทึกผิดพลาด !!' AS Error_Message_THA,
					'' AS Handling;
		END CATCH

	ELSE

		BEGIN TRY
			-- INSERT STATEMENT
			-- get new id
			-- SELECT @new_id = (id + 1) FROM APCSProDB.material.numbers WHERE [name] = 'product_slips.id'
			EXEC	[StoredProcedureDB].[material].[sp_get_number_id]
					@TABLENAME = 'product_slips.id',
					@NEWID = @new_id OUTPUT

			-- insert to material.product_slips
			INSERT INTO APCSProDB.material.product_slips 
				([slip_id],[production_id],[flow_pattern_id],[version_num],[is_released],[created_at],[created_by])
			VALUES
				(@new_id, @production_id, @flow_pattern_id, @version_num, @is_released, GETDATE(), @emp_id)

			-- insert to material_hist.product_slips_hist
			INSERT INTO [APCSProDB].[material_hist].[product_slips_hist]
				([category],[slip_id],[production_id],[flow_pattern_id],[version_num],[is_released],[created_at],[created_by])
			VALUES
				(1, @new_id, @production_id, @flow_pattern_id, @version_num, @is_released, GETDATE(), @emp_id)

			-- UPDATE APCSProDB.material.numbers SET id = @new_id WHERE [name] = 'product_slips.id'

			COMMIT;
			SELECT    'TRUE'      AS Is_Pass 
						, 'Success'	  AS Error_Message_ENG
						, N'บันทึกสำเร็จ' AS Error_Message_THA
						, '' AS Handling;

		END TRY
		BEGIN CATCH
			ROLLBACK;
			SELECT  'FALSE' AS Is_Pass ,
					-- 'Recording fail. !!' AS Error_Message_ENG ,
					ERROR_MESSAGE() AS Error_Message_ENG ,
					N'การบันทึกผิดพลาด !!' AS Error_Message_THA,
					'' AS Handling;
		END CATCH

END