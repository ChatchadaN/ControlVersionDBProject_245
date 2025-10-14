-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_flow_patterns_001]
	@id INT = 0, @product_family_id INT, @category_id INT, @link_flow_no decimal(4, 0), @version_num INT, @is_released INT, @emp_code VARCHAR(6), @comment NVARCHAR(255) = NULL
AS
BEGIN
	
	SET NOCOUNT ON;

	DECLARE @new_id INT
	DECLARE @emp_id INT

	SELECT @emp_id = id FROM [DWH].[man].[employees] WHERE emp_code = @emp_code
	-- SET @emp_id = 703

	BEGIN TRANSACTION

	IF @id IS NOT NULL AND @id <> 0
		-- UPDATE STATEMENT
		-- BEGIN TRANSACTION
		BEGIN TRY
			UPDATE APCSProDB.material.flow_patterns SET
				product_family_id = @product_family_id, 
				category_id = @category_id, 
				link_flow_no = @link_flow_no, 
				version_num = @version_num, 
				is_released = @is_released,
				comments = @comment,
				updated_at = GETDATE(),
				updated_by = @emp_id
			WHERE id = @id

			INSERT INTO APCSProDB.material_hist.flow_patterns_hist
						(category, id, product_family_id, category_id, link_flow_no, version_num, is_released, comments, created_at, created_by, updated_at, updated_by)
			SELECT 2, id, product_family_id, category_id, link_flow_no, version_num, is_released, comments, created_at, created_by, updated_at, updated_by
			FROM [APCSProDB].[material].[flow_patterns]
			WHERE id = @id 

			SELECT    'TRUE'      AS Is_Pass 
					, 'Success'	  AS Error_Message_ENG
					, N'บันทึกสำเร็จ' AS Error_Message_THA
					, '' AS Handling;

			COMMIT; 	

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
		-- INSERT STATEMENT
		BEGIN TRY

			-- get new id
			-- SELECT @new_id = (id + 1) FROM APCSProDB.material.numbers WHERE [name] = 'flow_patterns.id'
			-- DECLARE @new_id INT;
			EXEC	[StoredProcedureDB].[material].[sp_get_number_id]
					@TABLENAME = 'flow_patterns.id',
					@NEWID = @new_id OUTPUT

			-- insert to master table
			INSERT INTO APCSProDB.material.flow_patterns (id, product_family_id, category_id, link_flow_no, version_num, is_released, comments, created_at, created_by)
			VALUES (@new_id, @product_family_id, @category_id, @link_flow_no, @version_num, @is_released, @comment, GETDATE(), @emp_id)

			-- insert to history table
			INSERT INTO APCSProDB.material_hist.flow_patterns_hist 
				(category, id, product_family_id, category_id, link_flow_no, version_num, is_released, comments, created_at, created_by)
			VALUES (1, @new_id, @product_family_id, @category_id, @link_flow_no, @version_num, @is_released, @comment, GETDATE(), @emp_id)

			-- UPDATE APCSProDB.material.numbers SET id = @new_id WHERE [name] = 'flow_patterns.id'

			SELECT    'TRUE'      AS Is_Pass 
					, 'Success'	  AS Error_Message_ENG
					, N'บันทึกสำเร็จ' AS Error_Message_THA
					, '' AS Handling;

			COMMIT; 	

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