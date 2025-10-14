-- =============================================
-- Author:		Far
-- Create date: #2025/02/24 16.55
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [req].[sp_update_file_path_test]	
	-- Add the parameters for the stored procedure here
	 @order_no VARCHAR(11) = ''
	,@file_path NVARCHAR(255) = ''
	,@ImgTable image_paths READONLY
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--Add Log (Date Modify : 2024.DEC.03 Time : 08.25)
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		  [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [req].[sp_update_file_path]  @order_no = ''' + ISNULL(@order_no,'')
				+ ''', @file_path = ''' + ISNULL(@file_path,'')  + ''''
		, ISNULL(@order_no,'NULL');

	IF @order_no <> ''
	BEGIN
		IF (@file_path <> '')
		BEGIN
			UPDATE [AppDB].[req].[orders]
			SET [file_path] = @file_path
			WHERE [order_no] = @order_no;
		END

		DECLARE @order_id INT;
		DECLARE @requested_by int;
		SET @order_id = (SELECT [id] from [AppDB].[req].[orders] where [order_no] = @order_no);
		SET @requested_by = (SELECT [requested_by] FROM [AppDB].[req].[orders] where [order_no] = @order_no);
		
		IF EXISTS(SELECT * FROM @ImgTable)
		BEGIN
			Insert into [AppDB].[req].[images]
			select @order_id AS [order_id]
					, NULL AS [image_1]
					, NULL AS [image_2]
					, NULL AS [image_3]
					, NULL AS [image_4]
					, @requested_by AS [created_by]
					, GETDATE() AS [created_at]
					, NULL AS [updated_by]
					, NULL AS [updated_at]
					,[image_path_1]
					,[image_path_2]
					,[image_path_3]
					,[image_path_4]
			from (
					SELECT 'image_path_' + CAST([id] AS VARCHAR(10)) AS [columns], [images_file]
					FROM @ImgTable
				) AS [img]
				PIVOT (
					MAX([images_file])
					FOR [columns] IN ([image_path_1], [image_path_2], [image_path_3], [image_path_4])
				) AS pivotTable;

		END

		SELECT 'TRUE' AS [Is_Pass] 
			, 'update file_path in to database success' AS [Error_Message_ENG]
			, N'อัพเดตข้อมูลสำเร็จ' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Update data error !!' AS [Error_Message_ENG]
			, N'อัพเดตข้อมูลผิดพลาด !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END
END
