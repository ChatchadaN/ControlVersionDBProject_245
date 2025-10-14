

CREATE PROCEDURE [req].[sp_update_request_order] 
	@order_no			NVARCHAR(255)	= NULL,
	@category_id		INT				= NULL,
	@app_id				INT				= NULL,
	@subject_id			INT				= NULL,
	@problem			NVARCHAR(255)	= NULL, --# lot_no, barcode
	@mcname				NVARCHAR(255)	= NULL, --# mc_name
	@is_status			TINYINT			= NULL,
	@location_id		INT				= NULL,
	@area				NVARCHAR(50)	= NULL,
	@problem_solve_by	NVARCHAR(255)	= NULL,
	@user_comment		NVARCHAR(255)	= NULL,
	@system_comment		NVARCHAR(255)	= NULL,
	@get_case			NVARCHAR(255)	= NULL,
	@lot_no				NVARCHAR(255)	= null,
	@tel				varchar(10)		= null,
	@empId_save			NVARCHAR(255)	= NULL, --Add emp_id 2025/02/03 time : 11.24 by Far--
	--@version			Int				= 0,
	@send_to_mail		NVARCHAR(max)	= NULL

AS
BEGIN
	SET NOCOUNT ON;
	if(@tel is null and @lot_no is null)
	begin
		DECLARE @empId INT = NULL
		, @get_request_id INT = NULL
		, @set_page varchar(20) = 'Management'
		--set @set_page = IIF(@is_status = 2, 'Management', 'Index')

		SELECT @empId = CONVERT(int,@get_case)
		SELECT @get_request_id = [id] FROM [AppDB_app_244].[req].[orders] WHERE [order_no] = @order_no

		--Add Log (Date Modify : 2024.DEC.03 Time : 08.27)
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
		--	, 'EXEC [req].[sp_update_request_order]  @order_no = ''' + ISNULL(@order_no, '') 
		--			+ ''', @get_case = ''' + ISNULL(@get_case, '') 
		--			+ ''', @category_id = ''' + ISNULL(CAST(@category_id AS VARCHAR(10)),'') 
		--			+ ''', @problem_id = ''' + ISNULL(CAST(@subject_id AS VARCHAR(10)),'') 
		--			+ ''', @app_id = ''' + ISNULL(CAST(@app_id AS VARCHAR(10)),'')
		--			+ ''', @problem = ''' + ISNULL(@problem, '') 
		--			+ ''', @mcname = ''' + ISNULL(@mcname, '') 
		--			+ ''', @is_status = ''' + ISNULL(CAST(@is_status AS VARCHAR(10)),'') 
		--			--+ ''', @lot_no = ''' + ISNULL(@lot_no, '')  + ''''
		--			+ ''', @location_id = ''' + ISNULL(CAST(@location_id AS VARCHAR(10)),'')  
		--			+ ''', @area = ''' + ISNULL(@area, '')  
		--			+ ''', @problem_solve_by = ''' + ISNULL(@problem_solve_by, '') 
		--			+ ''', @user_comment = ''' + ISNULL(@user_comment, '') 
		--			+ ''', @system_comment = ''' + ISNULL(@system_comment, '')  + ''''
		--			--+ ''', @tel = ''' + ISNULL(@tel, '')  + ''''
		--	, ISNULL(@order_no,'NULL');


		BEGIN TRANSACTION;
		BEGIN TRY
			IF (ISNULL(@order_no, '') != '')
			BEGIN
				PRINT 'Update [DWH].[req].[orders]'
				UPDATE [AppDB_app_244].[req].[orders]
				SET [category_id] = @category_id
					,[app_id] = @app_id
					,[problem_id] = @subject_id
					,[problem_request] = @problem
					,[other_detail_2] = @mcname
					,[state] = @is_status
					,[location_id] = @location_id
					,[area] = @area
					,[problem_solve] = @problem_solve_by
					,[comment_by_requested] = @user_comment
					,[comment_by_system] = @system_comment
					,[inchange_by] = @get_case
					-- close and change 20241206 time : 14.26 by Aomsin --
					--,[solved_by] = IIF(@is_status = 3,@empId,NULL)  
					--,[solved_at] = IIF(@is_status = 3,GETDATE(),NULL)  
					,[solved_by] = ISNULL(@empId,NULL) 
					,[solved_at] = GETDATE() 
					--,[requested_tel] = @tel
					--,[other_detail_1] = @lot_no
				WHERE [AppDB_app_244].[req].[orders].[order_no] = @order_no;

				--Add Function Send mail #2025.FEB.10 Time: 23.57 by Aomsin
				EXEC [StoredProcedureDB].[req].[sp_set_send_mail_notification] @request_id = @get_request_id, @set_page = @set_page

				COMMIT;
				SELECT 'TRUE' AS [Is_Pass] 
					, 'order_no is ' + @order_no AS [Error_Message_ENG]
					, N'order_no คือ ' + @order_no AS [Error_Message_THA] 
					, N'' AS [Handling];
				RETURN;
			END
			ELSE
			BEGIN
				COMMIT;
				SELECT 'FALSE' AS [Is_Pass] 
					, 'Update data error !!' AS [Error_Message_ENG]
					, N'แก้ไขข้อมูลผิดพลาด !!' AS [Error_Message_THA] 
					, N'กรุณาติดต่อ system' AS [Handling];
				RETURN;
			END
		END TRY
		BEGIN CATCH
			IF @@ERROR <> 0
			BEGIN
				ROLLBACK;
			END

			PRINT 'ROLLBACK'
			SELECT 'FALSE' AS [Is_Pass] 
				, ERROR_MESSAGE() AS [Error_Message_ENG]
				, ERROR_MESSAGE() AS [Error_Message_THA] 
				, N'กรุณาติดต่อ system' AS [Handling];
			RETURN;
		END CATCH
	end
	else
	begin
		exec [StoredProcedureDB].[req].[sp_update_request_order_ver_002] 
			@order_no				= @order_no			,
			@category_id			= @category_id		,
			@app_id					= @app_id			,
			@subject_id				= @subject_id		,
			@problem				= @problem			,	--# lot_no, barcode
			@mcname					= @mcname			,	--# mc_name
			@is_status				= @is_status		,
			@location_id			= @location_id		,
			@area					= @area				,
			@problem_solve_by		= @problem_solve_by	,
			@user_comment			= @user_comment		,
			@system_comment			= @system_comment	,
			@get_case				= @get_case			,
			@lot_no					= @lot_no			,
			@tel					= @tel				,
			@empId_save				= @empId_save		,
			@send_to_mail			= @send_to_mail
		
	end
END
