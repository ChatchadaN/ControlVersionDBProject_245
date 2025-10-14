-- =============================================
-- =============================================
CREATE PROCEDURE [tg].[sp_get_check_lot_pc_request]
	-- Add the parameters for the stored procedure here
	 @lot_no VARCHAR(10),
	 @mc_id INT,
	 @emp_no VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	----# insert log
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [tg].[sp_get_check_lot_pc_request] @lot_no = ' + ISNULL('''' + CAST(@lot_no AS VARCHAR) + '''','NULL')
			+ ', @mc_id = ' + ISNULL(CAST(@mc_id AS VARCHAR),'NULL')
			+ ', @emp_no = ' + ISNULL('''' + CAST(@emp_no AS VARCHAR) + '''','NULL')
		, ISNULL(CAST(@lot_no AS VARCHAR),'NULL');

	IF EXISTS (SELECT [lots].[lot_no] FROM [APCSProDB].[trans].[lots] WHERE [lots].[lot_no] = @lot_no)
	BEGIN
		IF EXISTS (SELECT [lots].[lot_no] FROM [APCSProDB].[trans].[lots] WHERE [lots].[lot_no] = @lot_no AND [lots].[pc_instruction_code] = 13)
		BEGIN
			----# pc_instruction_code = 13
			SELECT 'TRUE' AS Is_Pass
				, [lots].[qty_out] AS qty_out
			FROM [APCSProDB].[trans].[lots]
			WHERE [lots].[lot_no] = @lot_no;
		END
		ELSE
		BEGIN
			----# pc_instruction_code <> 13
			SELECT 'FALSE' AS Is_Pass
				, 0 AS qty_out;
		END
	END
	ELSE
	BEGIN
		----# not found lot_no
		SELECT 'FALSE' AS Is_Pass
			, 0 AS qty_out;
	END
END
