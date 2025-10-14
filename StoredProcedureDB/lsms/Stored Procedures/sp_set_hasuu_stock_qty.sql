
CREATE PROCEDURE [lsms].[sp_set_hasuu_stock_qty]
	-- Add the parameters for the stored procedure here
	  @lot_no VARCHAR(10)
	, @hasuu_stock_qty INT 
	, @in_stock INT = NULL
	, @comment_val INT = NULL
	, @emp_id INT
	, @is_function INT ----# 1:edit by admin 2:edit by input rack
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--add log date modify : 2024.DEC.04 Time : 13.04 by Aomsin
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
		, 'EXEC [lsms].[sp_set_hasuu_stock_qty]  @lot_no = ''' + ISNULL(@lot_no, '') 
				+ ''', @hasuu_stock_qty = ''' + ISNULL(CAST(@hasuu_stock_qty AS VARCHAR(10)),'') 
				+ ''', @in_stock = ''' + ISNULL(CAST(@in_stock AS VARCHAR(10)),'') 
				+ ''', @comment_val = ''' + ISNULL(CAST(@comment_val AS VARCHAR(10)),'') 
				+ ''', @emp_id = ''' + ISNULL(CAST(@emp_id AS VARCHAR(10)),'') 
				+ ''', @is_function = ''' + ISNULL(CAST(@is_function AS VARCHAR(10)),'') + ''''
		, ISNULL(@lot_no,'NULL');
	----------------------------------------------------------------------------
	----- # check function
	----------------------------------------------------------------------------
	IF (@is_function = 1) AND (@in_stock IS NULL)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
			, '@in_stock Is null !!' AS [Error_Message_ENG]
			, N'@in_stock เป็นค่าว่าง !!' AS [Error_Message_THA] 
			, N'ติดต่อ ICT' AS [Handling];
		RETURN;
	END
	ELSE IF (@is_function = 2) AND (@comment_val IS NULL)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
			, '@comment_val Is null !!' AS [Error_Message_ENG]
			, N'@comment_val เป็นค่าว่าง !!' AS [Error_Message_THA] 
			, N'ติดต่อ ICT' AS [Handling];
		RETURN;
	END

	----------------------------------------------------------------------------
	----- # update surpluses
	----------------------------------------------------------------------------
	UPDATE [APCSProDB].[trans].[surpluses]
	SET [pcs] = @hasuu_stock_qty --qty
		, [comment] = 
		( CASE 
			WHEN @is_function = 2 THEN @comment_val 
			ELSE [comment] 
		END ) -- comment
		, [in_stock] =  
		( CASE 
			WHEN @is_function = 1 THEN @in_stock 
			ELSE 
			( CASE 
				WHEN @hasuu_stock_qty = 0 THEN 0 
				ELSE [in_stock] 
			END ) 
		END ) -- in_stock
		, [updated_at] = GETDATE()
		, [updated_by] = @emp_id
	WHERE [serial_no] = @lot_no;

	SELECT 'TRUE' AS [Is_Pass]
		, '' AS [Error_Message_ENG]
		, '' AS [Error_Message_THA] 
		, '' AS [Handling];
	RETURN;
END
