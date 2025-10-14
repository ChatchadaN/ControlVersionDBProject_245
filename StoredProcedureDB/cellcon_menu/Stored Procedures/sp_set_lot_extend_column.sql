-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon_menu].[sp_set_lot_extend_column]
	@column_name varchar(50),
    @json_name varchar(50),
    @data_type varchar(50),
    @display_name_eng varchar(50),
    @display_name_jpn nvarchar(50),
    @description nvarchar(255) = NULL,
	@is_common BIT,
	@emp_code VARCHAR(6)
AS
BEGIN

	SET NOCOUNT ON;

	DECLARE @SQL NVARCHAR(MAX) = NULL;
	DECLARE @column_size INT;
	DECLARE @emp_id INT = NULL;
	DECLARE @error_msg NVARCHAR(255) = '';

	-- SELECT @emp_id = id FROM [10.29.1.230].[DWH].[man].[employees] WHERE emp_code = @emp_code
	SELECT @emp_id = id FROM [DWH_wh_230].[man].[employees] WHERE emp_code = @emp_code;

	BEGIN TRANSACTION
	BEGIN TRY
	IF @is_common = 0 AND (NOT EXISTS (SELECT 1
					  FROM [APCSProDB_lsi_110].[cellcon_menu].[lot_extend_menu]
					  WHERE [column_name] = @column_name))
					  AND (NOT EXISTS (SELECT 1
					  FROM [APCSProDB_lsi_110].[cellcon_menu].[lot_transactions_menu]
					  WHERE [column_name] = @column_name))
	BEGIN
		SELECT @column_size = COUNT(1)
		FROM APCSProDWR.INFORMATION_SCHEMA.COLUMNS
		WHERE TABLE_NAME = 'lot_extended'
		AND TABLE_SCHEMA = 'trans'

		IF (@column_size < 1000) 
		BEGIN
			INSERT INTO [APCSProDB_lsi_110].[cellcon_menu].[lot_extend_menu] 
				([column_name], [json_name], [data_type], [display_name_eng], [display_name_jpn], [description], is_created, [created_at], [created_by])
			VALUES
				(@column_name, @json_name, @data_type, @display_name_eng, @display_name_jpn, @description, 1, GETDATE(), @emp_id);

			SET @SQL = 'ALTER TABLE [APCSProDWR].[trans].[lot_extended]' + 
            		   ' ADD ' + QUOTENAME(@column_name) + ' ' + @data_type
		END
		ELSE
		BEGIN
			INSERT INTO [APCSProDB_lsi_110].[cellcon_menu].[lot_transactions_menu] 
				([column_name], [json_name], [data_type], [display_name_eng], [display_name_jpn], [description], [is_created], [created_at], [created_by])
			VALUES
				(@column_name, @json_name, @data_type, @display_name_eng, @display_name_jpn, @description, 1, GETDATE(), @emp_id);

			SET @SQL = 'ALTER TABLE [APCSProDWR].[trans].[lot_transactions]' + 
            		   ' ADD ' + QUOTENAME(@column_name) + ' ' + @data_type
		END

		EXEC sp_executesql @SQL;
		COMMIT;

		SELECT 'TRUE' AS Is_Pass, 
						'' AS Error_Message_ENG, 
						'' AS Error_Message_THA ,
						'' AS Handling;
			
	END
	ELSE IF @is_common = 1 AND (NOT EXISTS (SELECT 1
					  FROM [APCSProDB_lsi_110].[cellcon_menu].[lot_transactions_menu]
					  WHERE [column_name] = @column_name))
	BEGIN
		INSERT INTO [APCSProDB_lsi_110].[cellcon_menu].[lot_transactions_menu] 
			([column_name], [json_name], [data_type], [display_name_eng], [display_name_jpn], [description], [is_created], [is_common], [created_at], [created_by])
		VALUES
			(@column_name, @json_name, @data_type, @display_name_eng, @display_name_jpn, @description, 1, 1, GETDATE(), @emp_id);

		SET @SQL = 'ALTER TABLE [APCSProDWR].[trans].[lot_transactions]' + 
            	   ' ADD ' + QUOTENAME(@column_name) + ' ' + @data_type;
		EXEC sp_executesql @SQL;
		COMMIT;

		SELECT 'TRUE' AS Is_Pass, 
						'' AS Error_Message_ENG, 
						'' AS Error_Message_THA ,
						'' AS Handling;
	END
	ELSE
	BEGIN
		COMMIT;
		SELECT  'FALSE' AS Is_Pass,
				@column_name + ' already exists' AS Error_Message_ENG,
				@column_name + N' ถูกสร้างไว้ก่อนหน้านี้แล้ว' AS Error_Message_THA,
				'' AS Handling
	END

	END TRY
	BEGIN CATCH
		ROLLBACK;
		SELECT  'FALSE' AS Is_Pass ,
				'Recording fail. !!' AS Error_Message_ENG ,
				N'การสร้างผิดพลาด !!' AS Error_Message_THA,
				'' AS Handling
	END CATCH

	/* IF (@SQL IS NOT NULL)
	BEGIN
		BEGIN TRY
			EXEC sp_executesql @SQL;
			COMMIT;	

			SELECT 'TRUE' AS Is_Pass, 
						'' AS Error_Message_ENG, 
						'' AS Error_Message_THA ,
						'' AS Handling;
		END TRY
		BEGIN CATCH
			ROLLBACK;
			SELECT  'FALSE' AS Is_Pass ,
					'Recording fail. !!' AS Error_Message_ENG ,
					N'การสร้างผิดพลาด !!' AS Error_Message_THA,
					'' AS Handling
		END CATCH
	END */

END