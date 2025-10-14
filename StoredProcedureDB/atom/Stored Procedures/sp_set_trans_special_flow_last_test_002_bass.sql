-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_special_flow_last_test_002_bass]
	-- Add the parameters for the stored procedure here
	@lot_id int
	, @is_special_flow int
	, @step_no int = NULL
	, @flow_pattern_id int = NULL
	, @machine_id int = -1
	, @recipe varchar(20) = NULL
	, @user_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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