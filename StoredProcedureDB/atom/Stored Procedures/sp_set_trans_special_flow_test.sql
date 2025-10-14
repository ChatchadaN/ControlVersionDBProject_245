-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_special_flow_test]
	-- Add the parameters for the stored procedure here
	@lot_id INT
	, @step_no INT = NULL
	, @user_id INT
	, @flow_pattern_id INT  = NULL
	, @link_flow_no INT = NULL
	, @assy_ft_class VARCHAR(2) = 'S'
	, @is_special_flow INT
	, @machine_id INT = -1
	, @recipe VARCHAR(20) = NULL
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
		, N'[StoredProcedureDB].[atom].[sp_set_trans_special_flow_test]' --AS [storedprocedname]
		, (SELECT CAST([lot_no] AS VARCHAR) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id) --AS [lot_no]
		, '@lot_id = ' + ISNULL(CAST(@lot_id AS VARCHAR),'NULL') 
			+ ' ,@is_special_flow = ' + ISNULL(CAST(@is_special_flow AS VARCHAR),'NULL')
			+ ' ,@step_no = ' + ISNULL(CAST(@step_no AS VARCHAR),'NULL') 
			+ ' ,@flow_pattern_id = ' + ISNULL(CAST(@flow_pattern_id AS VARCHAR),'NULL') 
			+ ' ,@link_flow_no = '+ ISNULL(CAST(@link_flow_no AS VARCHAR),'NULL') 
			+ ' ,@assy_ft_class = ''' + ISNULL(CAST(@assy_ft_class AS VARCHAR),'NULL') + ''''
			+ ' ,@machine_id = ' + ISNULL(CAST(@machine_id AS VARCHAR),'NULL') 
			+ ' ,@recipe = ''' + ISNULL(CAST(@recipe AS VARCHAR),'') + ''''
			+ ' ,@user_id = ' + ISNULL(CAST(@user_id AS VARCHAR),'NULL') --AS [command_text]

	IF (@link_flow_no IS NULL)
	BEGIN
		SET @link_flow_no = (
			SELECT TOP 1 [flow_patterns].[link_flow_no]
			FROM [APCSProDB].[method].[flow_patterns]
			INNER JOIN [APCSProDB].[method].[flow_details] ON [flow_patterns].[id] = [flow_details].[flow_pattern_id]
			WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
				AND [flow_details].[flow_pattern_id] = @flow_pattern_id 
		);
	END

	---- ########## VERSION 012 ##########
	EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_012]
		@lot_id = @lot_id, 
		@step_no = @step_no,
		@user_id = @user_id,
		@link_flow_no = @link_flow_no, 
		@assy_ft_class = @assy_ft_class,
		@is_special_flow = @is_special_flow,
		@machine_id = @machine_id, 
		@recipe = @recipe
	---- ########## VERSION 012 ##########
END