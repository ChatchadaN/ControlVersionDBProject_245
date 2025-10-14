-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_special_flow]
	-- Add the parameters for the stored procedure here
	@lot_id INT, 
	@step_no INT = NULL, 
	@user_id INT,  
	@flow_pattern_id INT = NULL,
	@link_flow_no INT = NULL, 
	@assy_ft_class VARCHAR(2) = 'S', 
	@is_special_flow INT, 
	@machine_id INT = -1, 
	@recipe VARCHAR(20) = NULL, 
	@app_state INT = 0 ---- 0:cellcon, 1:web (atom,add special flow)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here

	IF (@app_state = 0)
	BEGIN
		---- #cellcon# ----
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

		------ ########## VERSION 010 ##########
		--EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_010]
		--	@lot_id = @lot_id, 
		--	@is_special_flow = @is_special_flow,
		--	@step_no = @step_no,
		--	@flow_pattern_id = @flow_pattern_id,
		--	@machine_id = @machine_id, 
		--	@recipe = @recipe,
		--	@user_id = @user_id
		------ ########## VERSION 010 ##########

		IF ( @link_flow_no IS NULL )
		BEGIN
			SET @link_flow_no = (
				SELECT TOP 1 [flow_patterns].[link_flow_no]
				FROM [APCSProDB].[method].[flow_patterns]
				INNER JOIN [APCSProDB].[method].[flow_details] ON [flow_patterns].[id] = [flow_details].[flow_pattern_id]
				WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
					AND [flow_details].[flow_pattern_id] = @flow_pattern_id 
			);
		END
		
		------ ########## VERSION 012 ##########
		--EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_012]
		--	@lot_id = @lot_id, 
		--	@step_no = @step_no,
		--	@user_id = @user_id,
		--	@link_flow_no = @link_flow_no, 
		--	@assy_ft_class = @assy_ft_class,
		--	@is_special_flow = @is_special_flow,
		--	@machine_id = @machine_id, 
		--	@recipe = @recipe
		------ ########## VERSION 012 ##########

		---- ########## VERSION 013 ##########
		EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_013]
			@lot_id = @lot_id, 
			@step_no = @step_no,
			@user_id = @user_id,
			@link_flow_no = @link_flow_no, 
			@assy_ft_class = @assy_ft_class,
			@is_special_flow = @is_special_flow,
			@machine_id = @machine_id, 
			@recipe = @recipe
		---- ########## VERSION 013 ##########
	END
END
