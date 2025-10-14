-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_set_lot_record_menu_template_ver_001]
	@template_id INT, @extends_id NVARCHAR(MAX), @is_display BIT, @emp_code VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @emp_id INT, @new_id INT;
	DECLARE @is_pass VARCHAR(5) = NULL, @error_item VARCHAR(255) = NULL;

	-- SELECT @emp_id = id FROM [10.29.1.230].[DWH].[man].[employees] WHERE emp_code = @emp_code;
	SELECT @emp_id = id FROM [DWH].[man].[employees] WHERE emp_code = @emp_code

	/* DECLARE @List TABLE (Item VARCHAR(10));
	INSERT INTO @List (Item)
	SELECT value FROM STRING_SPLIT(@extends_id, ','); */

	DECLARE @item VARCHAR(10);
	DECLARE item_cursor CURSOR FOR   		
		SELECT value FROM STRING_SPLIT(@extends_id, ',');
		-- SELECT Item FROM @List;

	OPEN item_cursor;
	FETCH NEXT FROM item_cursor INTO @item;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		--PRINT 'test: ' + @item;
		BEGIN TRY
			IF EXISTS (SELECT 1 FROM APCSProDWR.lds.lot_record_menu_templates 
						WHERE lot_record_templates_id = @template_id 
						AND lot_record_menu_id = @item)
			BEGIN
				-- Update
				UPDATE APCSProDWR.lds.lot_record_menu_templates 
				SET is_display = @is_display, updated_at = GETDATE(), updated_by = @emp_id
				WHERE lot_record_templates_id = @template_id
				AND lot_record_menu_id = @item

			END
			ELSE
			BEGIN
				-- Insert
				EXEC	[StoredProcedureDB].[lds].[sp_get_number_id]
						@TABLENAME = 'lot_record_menu_templates.id',
						@NEWID = @new_id OUTPUT

				INSERT INTO APCSProDWR.lds.lot_record_menu_templates
				(id, lot_record_templates_id, lot_record_menu_id, is_display, created_at, created_by)
				VALUES
				(@new_id, @template_id, @item, @is_display, GETDATE(), @emp_id)

			END		
		END TRY
		BEGIN CATCH
			SET @is_pass = 'FALSE';
			SET @error_item += @item + ',';
		END CATCH

   		FETCH NEXT FROM item_cursor INTO @item;
	END;

	CLOSE item_cursor;
	DEALLOCATE item_cursor;

	IF (@is_pass = 'FALSE')
	BEGIN
		SELECT  'FALSE' AS Is_Pass ,
				(LEFT(@error_item, LEN(@error_item) - 1) + ' recording fail. !!') AS Error_Message_ENG ,
				(LEFT(@error_item, LEN(@error_item) - 1) + N' การบันทึกผิดพลาด !!') AS Error_Message_THA,
				'' AS Handling;
	END
	ELSE
	BEGIN
		SELECT 'TRUE' AS Is_Pass, 
				'' Error_Message_ENG, 
				'' AS Error_Message_THA ,
				'' AS Handling;
	END

END
