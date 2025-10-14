-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_eslip]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10),
	@eslip VARCHAR(50),
	@is_funtion INT --#0:Update, 1:Unlink
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
    -- Insert statements for procedure here

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
		, 'EXEC [atom].[sp_set_eslip] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') 
			+ ''', @eslip = ''' + ISNULL(CAST(@eslip AS varchar),'')
			+ ''', @is_funtion = ''' + ISNULL(CAST(@is_funtion AS varchar),'') + ''''
		, @lot_no;

	BEGIN TRANSACTION
	BEGIN TRY
		IF (@is_funtion = 0) --Update
		BEGIN
			--#clear eslip
			UPDATE [APCSProDB].[trans].[lots]
			SET e_slip_id = NULL
			WHERE e_slip_id = @eslip;
		
			--#update eslip
			UPDATE [APCSProDB].[trans].[lots]
			SET e_slip_id = @eslip
			WHERE lot_no = @lot_no;

			COMMIT TRANSACTION;
		END
		ELSE IF (@is_funtion = 1) --Unlink
		BEGIN
			--#clear eslip by lot
			UPDATE [APCSProDB].[trans].[lots]
			SET e_slip_id = NULL
			WHERE e_slip_id = @eslip;

			COMMIT TRANSACTION;
		END

		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END TRY
	BEGIN CATCH
		-----------------------------------------------------------------------------
		ROLLBACK TRANSACTION;
		SELECT 'FALSE' AS [Is_Pass] 
			, 'update data error !!' AS [Error_Message_ENG]
			, N'บันทึกข้อมูลไม่สำเร็จ !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
		-----------------------------------------------------------------------------
	END CATCH
END
