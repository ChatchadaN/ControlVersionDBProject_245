
CREATE PROCEDURE [trans].[sp_set_lot_extended_column]
		@extendColumnIDJson NVARCHAR(MAX),		
		@emp_code VARCHAR(6)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(MAX);
	DECLARE @id INT;
	DECLARE @ColumnName NVARCHAR(128);
   	DECLARE @DataType NVARCHAR(50);
	DECLARE @column_size INT;
	DECLARE @emp_id INT = NULL;
	DECLARE @error_item NVARCHAR(255) = '';
	DECLARE @error_msg_th NVARCHAR(255) = '';
	DECLARE @error_msg_en NVARCHAR(255) = '';

	-- SELECT @emp_id = id FROM [10.29.1.230].[DWH].[man].[employees] WHERE emp_code = @emp_code
	SELECT @emp_id = id FROM [DWH_wh_230].[man].[employees] WHERE emp_code = @emp_code;

	BEGIN TRY

		DECLARE extendcolumn_cursor CURSOR FOR
		SELECT [id], [column_name], [data_type]
		FROM [APCSProDB_lsi_110].[cellcon_menu].[lot_extend_menu]
		WHERE id IN (	
			SELECT value
       		FROM OPENJSON(@extendColumnIDJson)
		)
		AND is_created = 0;

		OPEN extendcolumn_cursor;
		FETCH NEXT FROM extendcolumn_cursor INTO @id, @ColumnName, @DataType;
	
		WHILE @@FETCH_STATUS = 0
   		BEGIN	
			IF (ISNULL(@ColumnName,'') <> '') AND (ISNULL(@DataType,'') <> '')
			BEGIN
				IF NOT EXISTS (SELECT 1
								FROM APCSProDWR.INFORMATION_SCHEMA.COLUMNS
								WHERE TABLE_NAME = 'lot_extended'
								AND TABLE_SCHEMA = 'trans'
								AND COLUMN_NAME = @ColumnName)
				BEGIN
					SELECT @column_size = COUNT(1)
					FROM APCSProDWR.INFORMATION_SCHEMA.COLUMNS
					WHERE TABLE_NAME = 'lot_extended'
					AND TABLE_SCHEMA = 'trans'
				
					IF (@column_size < 1000) 
					BEGIN		
						SET @SQL = 'ALTER TABLE [APCSProDWR].[trans].[lot_extended]' + 
              					   ' ADD ' + QUOTENAME(@ColumnName) + ' ' + @DataType
					END
					ELSE 
					BEGIN
						SET @SQL = 'ALTER TABLE [APCSProDWR].[trans].[lot_transactions]' + 
              					   ' ADD ' + QUOTENAME(@ColumnName) + ' ' + @DataType
					END 

					BEGIN TRANSACTION
					BEGIN TRY

						EXEC sp_executesql @SQL;

						UPDATE [APCSProDB_lsi_110].[cellcon_menu].[lot_extend_menu]
								SET is_created = 1 , created_by = @emp_id, created_at = GETDATE()
						WHERE [column_name] = @ColumnName
						AND is_created = 0;

						COMMIT;
				
					END TRY
					BEGIN CATCH
						ROLLBACK;
						SET @error_item += @ColumnName + ',';
					END CATCH
				END
				ELSE
				BEGIN
					UPDATE [APCSProDB_lsi_110].[cellcon_menu].[lot_extend_menu]
								SET is_created = 1 , created_by = @emp_id, created_at = GETDATE()
					WHERE [column_name] = @ColumnName
					AND is_created = 0;
				END
			END
			ELSE
			BEGIN
				SET @error_item = 'Error: ';
			END

			FETCH NEXT FROM extendcolumn_cursor INTO @id, @ColumnName, @DataType;

		END

   		CLOSE extendcolumn_cursor;
   		DEALLOCATE extendcolumn_cursor;

		IF (ISNULL(@error_item,'') <> '')
		BEGIN
			SET @error_item = LEFT(@error_item, LEN(@error_item) - 1);
			SET @error_msg_en = @error_item + ' failed to create column!';
			SET @error_msg_th = @error_item + N' Column สร้างไม่สำเร็จ!';

			SELECT  'FALSE' AS Is_Pass ,
					@error_msg_en AS Error_Message_ENG ,
					@error_msg_th AS Error_Message_THA,
					'' AS Handling
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
		SELECT  'FALSE' AS Is_Pass ,
				'Recording fail. !!' AS Error_Message_ENG ,
				N'การบันทึกผิดพลาด !!' AS Error_Message_THA,
				'' AS Handling
	END CATCH

END
