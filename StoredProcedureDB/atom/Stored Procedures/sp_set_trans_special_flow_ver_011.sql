-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_special_flow_ver_011]
	-- Add the parameters for the stored procedure here
	@lot_id INT, 
	@step_no INT = NULL, 
	@user_id INT, 
	@link_flow_no INT = NULL, 
	@assy_ft_class VARCHAR(2), 
	@is_special_flow INT, 
	@machine_id INT = -1, 
	@recipe VARCHAR(20) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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