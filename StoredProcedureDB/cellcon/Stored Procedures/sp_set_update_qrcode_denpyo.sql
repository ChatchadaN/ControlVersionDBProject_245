-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_update_qrcode_denpyo]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10),
	@emp_num VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF EXISTS ( SELECT [LOT_NO_2] FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] WHERE [LOT_NO_2] = @lot_no )
	BEGIN
		------------------------------------------------------------------
		---- # before
		------------------------------------------------------------------
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no] )
		SELECT GETDATE()
			, 4
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			,'EXEC [StoredProcedureDB].[cellcon].[sp_set_update_qrcode_denpyo] @lot_no = ''' + @lot_no + '''' 
				+ ', @emp_num = ''' + @emp_num + ''''
				+ ', [QR_CODE_2_OLD] = ''' + [QR_CODE_2] + ''''
			, @lot_no
		FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
		WHERE [LOT_NO_2] = @lot_no;

		------------------------------------------------------------------
		---- # update
		------------------------------------------------------------------
		update [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
		SET [QR_CODE_2] = CAST(SUBSTRING([QR_CODE_2],1,118) + CAST(REPLACE([PROGRAM_NO], ' ', '') AS CHAR(11)) + SUBSTRING([QR_CODE_2],130,252) AS CHAR(252))
		WHERE [LOT_NO_2] = @lot_no;

		------------------------------------------------------------------
		---- # after
		------------------------------------------------------------------
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no] )
		SELECT GETDATE()
			, 4
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			,'EXEC [StoredProcedureDB].[cellcon].[sp_set_update_qrcode_denpyo] @lot_no = ''' + @lot_no + '''' 
				+ ', @emp_num = ''' + @emp_num + ''''
				+ ', [QR_CODE_2_NEW] = ''' + [QR_CODE_2] + ''''
			, @lot_no
		FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
		WHERE [LOT_NO_2] = @lot_no;
	END
END
