-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_special_flow_ver_010]
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
	
	DECLARE @link_flow_no INT = NULL, 
		@assy_ft_class VARCHAR(2) = 'S'

	SET @link_flow_no = (
		SELECT TOP 1 [flow_patterns].[link_flow_no]
		FROM [APCSProDB].[method].[flow_patterns]
		INNER JOIN [APCSProDB].[method].[flow_details] ON [flow_patterns].[id] = [flow_details].[flow_pattern_id]
		WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
			AND [flow_details].[flow_pattern_id] = @flow_pattern_id 
	);

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