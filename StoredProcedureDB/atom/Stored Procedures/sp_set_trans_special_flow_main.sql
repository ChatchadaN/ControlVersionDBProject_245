-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_special_flow_main]
	-- Add the parameters for the stored procedure here
	@lot_id INT
	, @step_no INT = NULL
	, @back_step_no INT = NULL --No Use
	, @user_id INT
	, @flow_pattern_id INT  = NULL
	, @is_special_flow INT
	, @machine_id INT = -1
	, @recipe VARCHAR(20) = NULL
	, @numadd INT = NULL --No Use
	, @app_state INT = 0 ---- 0:cellcon, 1:web (atom,add special flow)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here
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
		, N'[StoredProcedureDB].[atom].[sp_set_trans_special_flow_main]' --AS [storedprocedname]
		, (SELECT CAST([lot_no] AS VARCHAR) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id) --AS [lot_no]
		, '@lot_id = ' + ISNULL(CAST(@lot_id AS VARCHAR),'NULL') 
			+ ' ,@is_special_flow = ' + ISNULL(CAST(@is_special_flow AS VARCHAR),'NULL')
			+ ' ,@step_no = ' + ISNULL(CAST(@step_no AS VARCHAR),'NULL') 
			+ ' ,@flow_pattern_id = '+ ISNULL(CAST(@flow_pattern_id AS VARCHAR),'NULL') 
			+ ' ,@machine_id = ' + ISNULL(CAST(@machine_id AS VARCHAR),'NULL') 
			+ ' ,@recipe = ''' + ISNULL(CAST(@recipe AS VARCHAR),'') + ''''
			+ ' ,@user_id = ' + ISNULL(CAST(@user_id AS VARCHAR),'NULL') --AS [command_text]

	IF (@app_state = 0)
	BEGIN
		---- #cellcon# ----
		---- ########## VERSION 009 ##########
		EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_009]
			@lot_id = @lot_id, 
			@is_special_flow = @is_special_flow,
			@step_no = @step_no,
			@flow_pattern_id = @flow_pattern_id,
			@machine_id = @machine_id, 
			@recipe = @recipe,
			@user_id = @user_id;
		---- ########## VERSION 009 ##########
	END
	ELSE IF (@app_state = 1)
	BEGIN
		---- #web (atom,add special flow)# ----
		------ ########## VERSION 005 ##########
		--EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_005]
		--	@lot_id = @lot_id, 
		--	@is_special_flow = @is_special_flow,
		--	@step_no = @step_no,
		--	@flow_pattern_id = @flow_pattern_id,
		--	@machine_id = @machine_id, 
		--	@recipe = @recipe,
		--	@user_id = @user_id
		------ ########## VERSION 005 ##########

		------ ########## VERSION 006 ##########
		--EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_006]
		--	@lot_id = @lot_id, 
		--	@is_special_flow = @is_special_flow,
		--	@step_no = @step_no,
		--	@flow_pattern_id = @flow_pattern_id,
		--	@machine_id = @machine_id, 
		--	@recipe = @recipe,
		--	@user_id = @user_id
		------ ########## VERSION 006 ##########

		------ ########## VERSION 007 ##########
		--EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_007]
		--	@lot_id = @lot_id, 
		--	@is_special_flow = @is_special_flow,
		--	@step_no = @step_no,
		--	@flow_pattern_id = @flow_pattern_id,
		--	@machine_id = @machine_id, 
		--	@recipe = @recipe,
		--	@user_id = @user_id
		------ ########## VERSION 007 ##########

		------ ########## VERSION 008 ##########
		--EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_008]
		--	@lot_id = @lot_id, 
		--	@is_special_flow = @is_special_flow,
		--	@step_no = @step_no,
		--	@flow_pattern_id = @flow_pattern_id,
		--	@machine_id = @machine_id, 
		--	@recipe = @recipe,
		--	@user_id = @user_id
		------ ########## VERSION 008 ##########

		------ ########## VERSION 009 ##########
		--EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_009]
		--	@lot_id = @lot_id, 
		--	@is_special_flow = @is_special_flow,
		--	@step_no = @step_no,
		--	@flow_pattern_id = @flow_pattern_id,
		--	@machine_id = @machine_id, 
		--	@recipe = @recipe,
		--	@user_id = @user_id
		------ ########## VERSION 009 ##########

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
END
