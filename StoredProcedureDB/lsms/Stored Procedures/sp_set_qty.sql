
CREATE PROCEDURE [lsms].[sp_set_qty]
	-- Add the parameters for the stored procedure here
	  @lot_no VARCHAR(10)
	, @qty INT 
	, @emp_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--add log date modify : 2024.DEC.04 Time : 11.04 by Aomsin
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
		, 'EXEC [lsms].[sp_set_qty]  @lot_no = ''' + ISNULL(@lot_no, '') 
				+ ''', @qty = ''' + ISNULL(CAST(@qty AS VARCHAR(10)),'') 
				+ ''', @emp_id = ''' + ISNULL(CAST(@emp_id AS VARCHAR(10)),'') + ''''
		, ISNULL(@lot_no,'NULL');

	----------------------------------------------------------------------------
	----- # update lot_informations
	----------------------------------------------------------------------------
	UPDATE [APCSProDB].[trans].[lot_informations]
	SET [qty_pass] = @qty--qty
	WHERE [lot_no] = @lot_no;

	SELECT 'TRUE' AS [Is_Pass]
		, '' AS [Error_Message_ENG]
		, '' AS [Error_Message_THA] 
		, '' AS [Handling];
	RETURN;
END
