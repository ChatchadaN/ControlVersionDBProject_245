-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_special_flow_order_by_request]
	-- Add the parameters for the stored procedure here
	@lotNo VARCHAR(10) = '',
	@stepNo INT = NULL,
	@flowPatternId INT = NULL,
	@isOccurred INT = NULL,
	@comment VARCHAR(50) = '',
	@emp_no CHAR(6) = '',
	@is_status INT = 0,
	@order_id INT = 0,
	@is_action INT = 0 --# 0:Insert 1:Update
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;
	--is_status (0 : Request, 1 : Receive, 2 : Success, 3 : Cancel)
	DECLARE @lot_id int = null
	DECLARE @user_id int = null

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
		, 'EXEC [atom].[sp_set_special_flow_order_by_request] @lotNo = ''' + @lotNo + ''''
		, @lotNo

	SELECT @lot_id = [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lotNo
	SELECT @user_id = [id] FROM [APCSProDB].[man].[users] WHERE [emp_num] = @emp_no

	IF (@lot_id IS NULL)
	BEGIN
		SELECT 'FALSE' AS Is_Pass 
			, 'Not found LotNo !!' AS Error_Message_ENG
			, N'ไม่พบ LotNo !!'  AS Error_Message_THA 
			, N'' AS Handling
		RETURN
	END

	IF (@is_action = 0)
	BEGIN
		INSERT INTO [APCSProDB].[trans].[request_special_flows]
			( [lot_id]
			, [step_no]
			, [flow_pattern_id]
			, [is_occurred]
			, [is_status]
			, [comment]
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by] )
		VALUES 
			( @lot_id
			, @stepNo
			, @flowPatternId
			, @isOccurred
			, 0 -- is_status 
			, @comment
			, GETDATE()
			, @user_id
			, GETDATE()
			, @user_id );
	END
	ELSE IF (@is_action = 1)
	BEGIN
		UPDATE [APCSProDB].[trans].[request_special_flows]
		SET [is_status] = @is_status
			, [updated_at] = GETDATE()
			, [updated_by] = @user_id
		WHERE [id] = @order_id
			AND [lot_id] = @lot_id;
	END

	IF @@ROWCOUNT > 0  
	BEGIN
		SELECT 'TRUE' AS Is_Pass 
			, 'Request order success' AS Error_Message_ENG
			, N'บันทึกข้อมูลสำเร็จ'  AS Error_Message_THA 
			, N'' AS Handling
		RETURN
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Is_Pass 
			, 'Request order error !!' AS Error_Message_ENG
			, N'ไม่สามารถ request order ได้ !!'  AS Error_Message_THA 
			, N'' AS Handling
		RETURN
	END
END