
CREATE PROCEDURE [tg].[sp_get_print_label_attachment]
	-- Add the parameters for the stored procedure here
	@LotNo VARCHAR(20) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements
	SET NOCOUNT ON;

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
		, 'EXEC [tg].[sp_get_print_label_attachment] Access Store @LotNo = ''' + ISNULL(@LotNo ,'NULL') + ''''
		, @LotNo;

	DECLARE @pc_code INT
		, @attachment VARCHAR(50)

	IF ( SUBSTRING( @lotno, 5, 1 ) = 'D' )
	BEGIN
		-- # [1] type D lot
		SELECT @pc_code = [lots].[pc_instruction_code]
			, @attachment = [pc_request_orders].[attachment_need]
		FROM [APCSProDB].[trans].[pc_request_orders]
		INNER JOIN [APCSProDB].[trans].[lots] ON [pc_request_orders].[lot_id] = [lots].[id]
		WHERE [lots].[lot_no] = @LotNo;

		IF ( @pc_code IN ( 1,11,13 ) )
		BEGIN
			-- # [1.1] pc_code in (1,11,13) and have data in table pc_request_orders
			IF (@attachment != '')
			BEGIN
				-- # [1.1.1] have attachment
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
					, 'EXEC [tg].[sp_get_print_label_attachment] Result Store @LotNo = ''' + ISNULL(@LotNo ,'NULL') + ''' [result] = TRUE'
					, @LotNo;

				SELECT 'TRUE' AS [result];
				RETURN;
			END
			ELSE
			BEGIN
				-- # [1.1.2] not have attachment
				SELECT 'FALSE' AS [result];
				RETURN;
			END
		END
		ELSE
		BEGIN
			-- # [1.2] pc_code not in (1,11,13) or not have data in table pc_request_orders
			SELECT 'FALSE' AS [result];
			RETURN;
		END
	END
	ELSE
	BEGIN
		-- # [2] type Other lot
		SELECT 'FALSE' AS [result];
		RETURN;
	END
END
