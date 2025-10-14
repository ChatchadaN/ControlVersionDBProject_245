-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_set_config_setting_package_group]
	-- Add the parameters for the stored procedure here
	@id INT = 0,
	@package_group_name VARCHAR(10),
	@floor INT --,
	--@state INT = 1 ---- # 1:INSERT, 2:UPDATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE  @package_group_id INT
		, @new_name_group VARCHAR(10);

	SELECT @package_group_id = [id]
		--, @package_group_name = [name] 
	FROM [APCSProDB].[method].[package_groups] 
	WHERE [name] = @package_group_name;
	
	IF (@package_group_id IS NULL OR @package_group_name IS NULL)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Package Group not found. !!' AS [Error_Message_ENG]
			, N'ไม่พบ Package Group นี้ !!' AS [Error_Message_THA]
			, '' AS Handling;
		RETURN;
	END

	SET @new_name_group = TRIM(@package_group_name) + '_' + CAST(@floor AS VARCHAR(2)) + 'F';

	IF NOT EXISTS(SELECT [floor] FROM [APCSProDWH].[cac].[config_package_groups] WHERE [package_groups_id] = @package_group_id AND [floor] = @floor) AND (@id = 0) 
	BEGIN
		INSERT INTO [APCSProDWH].[cac].[config_package_groups]
			( [name]
			, [package_groups_id]
			, [floor]
			, [is_enable]
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by] )
		SELECT @new_name_group
			, @package_group_id
			, @floor
			, 1
			, GETDATE()
			, NULL
			, GETDATE()
			, NULL;

		SELECT 'TRUE' AS [Is_Pass] 
			, 'Insert success.' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูลสำเร็จ' AS [Error_Message_THA]
			, '' AS [Handling];
		RETURN;
	END
	ELSE
	BEGIN
		IF (@id = 0) 
		BEGIN
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Insert fail. !!' AS [Error_Message_ENG]
				, N'เพิ่มข้อมูลผิดพลาด !!' AS [Error_Message_THA]
				, '' AS Handling;
			RETURN;
		END
		ELSE
		BEGIN
			IF EXISTS(SELECT [floor] FROM [APCSProDWH].[cac].[config_package_groups] WHERE [id] = @id)
				AND NOT EXISTS(SELECT [floor] FROM [APCSProDWH].[cac].[config_package_groups] WHERE [package_groups_id] = @package_group_id AND [floor] = @floor)
			BEGIN
				UPDATE [APCSProDWH].[cac].[config_package_groups]
				SET [name] = @new_name_group
					, [package_groups_id] = @package_group_id
					, [floor] = @floor
					, [updated_at] = GETDATE()
					, [updated_by] = NULL
				WHERE [id] = @id;

				SELECT 'TRUE' AS [Is_Pass] 
					, 'Update success.' AS [Error_Message_ENG]
					, N'แก้ไขข้อมูลสำเร็จ' AS [Error_Message_THA]
					, '' AS [Handling];
				RETURN;
			END
			ELSE
			BEGIN
				SELECT 'FALSE' AS [Is_Pass] 
					, 'Update fail. !!' AS [Error_Message_ENG]
					, N'แก้ไขข้อมูลผิดพลาด !!' AS [Error_Message_THA]
					, '' AS Handling;
				RETURN;
			END
		END
	END
END
