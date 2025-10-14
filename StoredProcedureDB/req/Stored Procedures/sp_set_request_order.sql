
CREATE PROCEDURE [req].[sp_set_request_order] 
	@order_no VARCHAR(11) = '',
	@problem_request NVARCHAR(255) = '',
	@category_id INT = NULL,
	@problem_id INT = NULL,
	@app_id INT = NULL,
	@other_detail_1	NVARCHAR(255) = NULL, --# lot_no, barcode
	@other_detail_2	NVARCHAR(255) = NULL, --# mc_name
	@priority TINYINT = NULL,
	@comment_by_requested NVARCHAR(255) = NULL,
	@location VARCHAR(50) = NULL,
	@area NVARCHAR(50) = NULL,
	@file_path NVARCHAR(255) = '',
	@requested_by VARCHAR(10) = '',
	@requested_tel VARCHAR(10) = NULL,
	@ImgTable images READONLY
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @order_id INT;
	BEGIN TRY
		IF (ISNULL(@problem_request, '') != '')
		BEGIN
			PRINT 'INSERT [AppDB].[req].[orders]'

			INSERT INTO [AppDB_app_244].[req].[orders]
			SELECT @order_no AS [order_no]
				, @problem_request AS [problem_request]
				, NULL AS [problem_solve]
				, @category_id AS [category_id]
				, @problem_id AS [problem_id]
				, @app_id AS [app_id]
				, @other_detail_1 AS [other_detail_1]
				, @other_detail_2 AS [other_detail_2]
				, @priority AS [priority]
				, 0 AS [state]
				, @comment_by_requested AS [comment_by_requested]
				, NULL AS [comment_by_system]
				, @location AS [location]
				, @area AS [area]
				, NULL AS [inchange_by]
				, @file_path AS [file_path]
				, @requested_by AS [requested_by]
				, GETDATE() AS [requested_at]
				, @requested_tel AS [requested_tel]
				, NULL AS [solved_by]
				, NULL AS [solved_at];

			SET @order_id = SCOPE_IDENTITY();

			IF EXISTS(SELECT * FROM @ImgTable)
			BEGIN
				PRINT 'INSERT [AppDB].[req].[images]'
				INSERT [AppDB_app_244].[req].[images]
				SELECT @order_id AS [order_id]
					, [image_1]
					, [image_2]
					, [image_3]
					, [image_4]
					, @requested_by AS [created_by]
					, GETDATE() AS [created_at]
					, NULL AS [updated_by]
					, NULL AS [updated_at]
					, NULL AS [image_path_1]
					, NULL AS [image_path_2]
					, NULL AS [image_path_3]
					, NULL AS [image_path_4]
				FROM (
					SELECT 'image_' + CAST([id] AS VARCHAR(10)) AS [columns], [images_file]
					FROM @ImgTable
				) AS [img]
				PIVOT (
					MAX([images_file])
					FOR [columns] IN ([image_1], [image_2], [image_3], [image_4])
				) AS pivotTable;
			END
		
			SELECT 'TRUE' AS [Is_Pass] 
				, '' AS [Error_Message_ENG]
				, N'' AS [Error_Message_THA] 
				, N'' AS [Handling];
			RETURN;
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Insert data error !!' AS [Error_Message_ENG]
				, N'เพิ่มข้อมูลผิดพลาด !!' AS [Error_Message_THA] 
				, N'กรุณาติดต่อ system' AS [Handling];
			RETURN;
		END
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS [Is_Pass] 
			, ERROR_MESSAGE() AS [Error_Message_ENG]
			, ERROR_MESSAGE() AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END CATCH
END
