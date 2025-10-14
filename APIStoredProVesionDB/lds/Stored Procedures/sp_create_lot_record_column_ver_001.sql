-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_create_lot_record_column_ver_001]
	@column_name varchar(50), @json_name varchar(50), @data_type varchar(20), @description nvarchar(255) = null, @emp_code varchar(6)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @target_tb VARCHAR(20);
	DECLARE @new_id INT;
	DECLARE @emp_id INT;
	DECLARE @column_size INT;

	BEGIN TRANSACTION
	BEGIN TRY
	IF EXISTS (SELECT 1 FROM [APCSProDWR].[lds].[lot_record_menu] WHERE [column_name] = TRIM(@column_name))
	BEGIN
		COMMIT;
		SELECT  'FALSE' AS Is_Pass, 
				'Column has been created!!' AS Error_Message_ENG, 
				N'มีการสร้างคอลัมภ์ไว้แล้ว!!' AS Error_Message_THA,
				'' AS Handling
	END
	ELSE
	BEGIN

		-- SELECT @emp_id = id FROM [10.29.1.230].[DWH].[man].[employees] WHERE emp_code = @emp_code;
		SELECT @emp_id = id FROM [DWH].[man].[employees] WHERE emp_code = @emp_code

		SELECT @column_size = COUNT(1)
		FROM APCSProDWR.INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'lot_extends'
		AND TABLE_SCHEMA = 'trans';

		IF (@column_size < 1000) 
		BEGIN		
			SET @target_tb = 'lot_extends';
		END
		ELSE 
		BEGIN
			SET @target_tb = 'lot_transactions';
		END 

		SET @SQL = N'ALTER TABLE [APCSProDWR].[trans].['+ @target_tb +']' + 
             			   ' ADD ' + QUOTENAME(TRIM(@column_name)) + ' ' + @data_type;

		EXEC sp_executesql @statement = @SQL;

		EXEC	[StoredProcedureDB].[lds].[sp_get_number_id]
					@TABLENAME = 'lot_record_menu.id',
					@NEWID = @new_id OUTPUT

		INSERT INTO [APCSProDWR].[lds].[lot_record_menu]
		  (id, column_name, json_name, data_type, created_table, is_common, [description], created_at, created_by)
		VALUES
		  (@new_id, TRIM(@column_name), TRIM(@json_name), @data_type, @target_tb, 0, @description, GETDATE(), @emp_id)

		COMMIT;

		SELECT 'TRUE' AS Is_Pass, 
				'' Error_Message_ENG, 
				'' AS Error_Message_THA ,
				'' AS Handling;

	END

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
