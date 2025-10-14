-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_set_lot_record_template_ver_001]
	@id INT = NULL, @name varchar(50), @display_name nvarchar(50), @description nvarchar(255) = NULL, @emp_code varchar(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @emp_id INT;
	DECLARE @new_id INT;

	DECLARE @is_pass VARCHAR(5);
	DECLARE @error_ENG VARCHAR(255) = NULL;
	DECLARE @error_TH NVARCHAR(255) = NULL;

	SELECT @emp_id = id FROM DWH.man.employees WHERE emp_code = @emp_code
	-- SELECT @emp_id = id FROM [10.29.1.230].[DWH].[man].[employees] WHERE emp_code = @emp_code;

	BEGIN TRANSACTION
	BEGIN TRY

	IF EXISTS (SELECT 1 FROM [APCSProDWR].[lds].[lot_record_templates] WHERE [name] = TRIM(@name)) AND ISNULL(@id, 0) = 0
	BEGIN
		SET @is_pass = 'FALSE';
		SET @error_ENG = 'Template has been created!!';
		SET @error_TH = N'มีการสร้าง Template ไว้แล้ว!!'
	END
    ELSE IF (ISNULL(@id, 0) <> 0)
	BEGIN
		-- UPDATE
		UPDATE [APCSProDWR].[lds].[lot_record_templates] 
		SET [name] = @name, [display_name] = @display_name, [description] = @description, updated_at = GETDATE(), updated_by = @emp_id
		WHERE id = @id

		SET @is_pass = 'TRUE';
	END
	ELSE 
	BEGIN
		-- INSERT
		EXEC	[StoredProcedureDB].[lds].[sp_get_number_id]
					@TABLENAME = 'lot_record_templates.id',
					@NEWID = @new_id OUTPUT

		INSERT INTO [APCSProDWR].[lds].[lot_record_templates] 
		 (id, [name], display_name, [description], created_at, created_by)
		VALUES
		 (@new_id, @name, @display_name, @description, GETDATE(), @emp_id)

		SET @is_pass = 'TRUE';
	END

	COMMIT;

	SELECT  @is_pass AS Is_Pass,
			@error_ENG AS Error_Message_ENG,
			@error_TH AS Error_Message_THA,
			'' AS Handling

	END TRY
	BEGIN CATCH
		ROLLBACK;
		SELECT  'FALSE' AS Is_Pass ,
				--'Recording fail. !!' AS Error_Message_ENG ,
				ERROR_MESSAGE() AS Error_Message_ENG ,
				N'การบันทึกผิดพลาด !!' AS Error_Message_THA,
				'' AS Handling
	END CATCH

END
