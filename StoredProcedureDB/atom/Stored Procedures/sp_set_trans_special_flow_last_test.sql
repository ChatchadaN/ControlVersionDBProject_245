-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_special_flow_last_test]
	-- Add the parameters for the stored procedure here
	@lot_id INT
	, @step_no INT = NULL
	, @back_step_no INT = NULL --No Use
	, @user_id INT
	, @flow_pattern_id INT = NULL
	, @is_special_flow INT
	, @machine_id INT = -1
	, @recipe VARCHAR(20) = NULL
	, @numadd INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [StoredProcedureDB].[dbo].[exec_spdb_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [storedprocedname]
		, [lot_no]
		, [command_text] )
	SELECT GETDATE() --AS [record_at]
		, 4 AS [record_class]
		, ORIGINAL_LOGIN() --AS [login_name]
		, HOST_NAME() --AS [hostname]
		, APP_NAME() --AS [appname]
		, N'[StoredProcedureDB].[atom].[sp_set_trans_special_flow_last_test]' --AS [storedprocedname]
		, (SELECT CAST([lot_no] AS VARCHAR) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id) --AS [lot_no]
		, '@lot_id = ' + ISNULL(CAST(@lot_id AS VARCHAR),'NULL') 
			+ ' ,@is_special_flow = ' + ISNULL(CAST(@is_special_flow AS VARCHAR),'NULL')
			+ ' ,@step_no = ' + ISNULL(CAST(@step_no AS VARCHAR),'NULL') 
			+ ' ,@flow_pattern_id = '+ ISNULL(CAST(@flow_pattern_id AS VARCHAR),'NULL') 
			+ ' ,@machine_id = ' + ISNULL(CAST(@machine_id AS VARCHAR),'NULL') 
			+ ' ,@recipe = ''' + ISNULL(CAST(@recipe AS VARCHAR),'') + ''''
			+ ' ,@user_id = ' + ISNULL(CAST(@user_id AS VARCHAR),'NULL') --AS [command_text]


	---- ########## VERSION 010 ##########
	EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_010]
		@lot_id = @lot_id, 
		@is_special_flow = @is_special_flow,
		@step_no = @step_no,
		@flow_pattern_id = @flow_pattern_id,
		@machine_id = @machine_id, 
		@recipe = @recipe,
		@user_id = @user_id
	---- ########## VERSION 010 ##########
END
