

CREATE PROCEDURE [req].[sp_set_request_order_ver_002] 
	@problem_request NVARCHAR(255) = '',
	@category_id INT = NULL,
	@problem_id INT = NULL,
	@app_id INT = NULL,
	@other_detail_1	NVARCHAR(255) = NULL, --# lot_no, barcode
	@other_detail_2	NVARCHAR(255) = NULL, --# mc_name
	@priority TINYINT = NULL,
	@comment_by_requested NVARCHAR(255) = NULL,
	@location_id INT = NULL,
	@area NVARCHAR(50) = NULL,
	@file_path NVARCHAR(255) = '',
	@requested_by VARCHAR(10) = '',
	@requested_tel VARCHAR(10) = NULL--,
	--@ImgTable images READONLY
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @order_id INT;
	DECLARE @order_no NVARCHAR(11);
	
	DECLARE @table_order TABLE ( [order_no] NVARCHAR(11) )
	INSERT INTO @table_order
	EXEC [StoredProcedureDB].[req].[sp_get_order_no];

	SET @order_no = (SELECT [order_no] FROM @table_order);
	SET @requested_by = (SELECT [id] FROM [10.29.1.230].[DWH].[man].[employees] WHERE [emp_code] = @requested_by);

	--Add Log (Date Modify : 2024.DEC.03 Time : 08.23)
	--INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--(
	--	  [record_at]
	--	, [record_class]
	--	, [login_name]
	--	, [hostname]
	--	, [appname]
	--	, [command_text]
	--	, [lot_no]
	--)
	--SELECT GETDATE()
	--	, '4'
	--	, ORIGINAL_LOGIN()
	--	, HOST_NAME()
	--	, APP_NAME()
	--	, 'EXEC [req].[sp_set_request_order_ver_002]  @order_no = ''' + ISNULL(@order_no,'') 
	--			+ ''', @problem_request = ''' + ISNULL(@problem_request,'') 
	--			+ ''', @category_id = ''' + ISNULL(CAST(@category_id AS varchar(2)),'') 
	--			+ ''', @problem_id = ''' + ISNULL(CAST(@problem_id AS varchar(2)),'') 
	--			+ ''', @app_id = ''' + ISNULL(CAST(@app_id AS varchar(2)),'')
	--			+ ''', @other_detail_1 = ''' + ISNULL(@other_detail_1,'')
	--			+ ''', @other_detail_2 = ''' + ISNULL(@other_detail_2,'')
	--			+ ''', @priority = ''' + ISNULL(CAST(@priority AS varchar(2)),'') 
	--			+ ''', @comment_by_requested = ''' + ISNULL(@comment_by_requested,'')
	--			+ ''', @location_id = ''' + ISNULL(CAST(@location_id AS varchar(2)),'')  
	--			+ ''', @area = ''' + ISNULL(@area,'')
	--			+ ''', @file_path = ''' + ISNULL(@file_path,'')
	--			+ ''', @requested_by = ''' + ISNULL(@requested_by,'')
	--			+ ''', @requested_tel = ''' + ISNULL(@requested_tel,'')  + ''''
	--	, ISNULL(@order_no,'NULL'); 

	--BEGIN TRANSACTION;
	BEGIN TRY
		IF (ISNULL(@problem_request, '') != '')
		BEGIN
			PRINT 'INSERT [AppDB_app_244].[req].[orders]'

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
				, @location_id AS [location]
				, @area AS [area]
				, NULL AS [inchange_by]
				, @file_path AS [file_path]
				, @requested_by AS [requested_by]
				, GETDATE() AS [requested_at]
				, @requested_tel AS [requested_tel]
				, NULL AS [solved_by]
				, NULL AS [solved_at];

			--SET @order_id = SCOPE_IDENTITY();

			--IF EXISTS(SELECT * FROM @ImgTable)
			--BEGIN
			--	PRINT 'INSERT [AppDB].[req].[images]'
			--	INSERT [AppDB].[req].[images]
			--	SELECT @order_id AS [order_id]
			--		, [image_1]
			--		, [image_2]
			--		, [image_3]
			--		, [image_4]
			--		, @requested_by AS [created_by]
			--		, GETDATE() AS [created_at]
			--		, NULL AS [updated_by]
			--		, NULL AS [updated_at]
			--		, NULL AS [image_path_1]
			--		, NULL AS [image_path_2]
			--		, NULL AS [image_path_3]
			--		, NULL AS [image_path_4]
			--	FROM (
			--		SELECT 'image_' + CAST([id] AS VARCHAR(10)) AS [columns], [images_file]
			--		FROM @ImgTable
			--	) AS [img]
			--	PIVOT (
			--		MAX([images_file])
			--		FOR [columns] IN ([image_1], [image_2], [image_3], [image_4])
			--	) AS pivotTable;
			--END
		
			--COMMIT;
			SELECT 'TRUE' AS [Is_Pass] 
				, 'request_no is ' + @order_no AS [Error_Message_ENG]
				, N'request_no คือ ' + @order_no AS [Error_Message_THA] 
				, N'' AS [Handling]
				, @order_no AS [orderno];
			RETURN;
		END
		ELSE
		BEGIN
			--COMMIT;
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Insert data error !!' AS [Error_Message_ENG]
				, N'เพิ่มข้อมูลผิดพลาด !!' AS [Error_Message_THA] 
				, N'กรุณาติดต่อ system' AS [Handling]
				, '' AS [orderno];
			RETURN;
		END
	END TRY
	BEGIN CATCH
		--IF @@ERROR <> 0
		--BEGIN
		--	ROLLBACK;
		--END

		PRINT 'ROLLBACK'
		SELECT 'FALSE' AS [Is_Pass] 
			, ERROR_MESSAGE() AS [Error_Message_ENG]
			, ERROR_MESSAGE() AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling]
			, '' AS [orderno];
		RETURN;
	END CATCH
END
