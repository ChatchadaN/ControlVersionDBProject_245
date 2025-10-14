-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_clear_special_flow]
	-- Add the parameters for the stored procedure here
	@lot_id INT, ----# required
	@special_id INT = NULL,
	@lot_special_id INT = NULL,
	@flowfon INT = 0,
	@step_no INT = NULL, ----# required
	@appname VARCHAR(30) = NULL ----# required
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	---- ########## VERSION 007 ##########
	--EXEC [StoredProcedureDB].[atom].[sp_set_clear_special_flow_ver_007]
	--	@lot_id = @lot_id, 
	--	@step_no = @step_no,
	--	@appname = @appname
	---- ########## VERSION 007 ##########

	---- ########## VERSION 008 ##########
	--EXEC [StoredProcedureDB].[atom].[sp_set_clear_special_flow_ver_008]
	--	@lot_id = @lot_id, 
	--	@step_no = @step_no,
	--	@appname = @appname
	---- ########## VERSION 008 #########

	---- ########## VERSION 009 ##########
	EXEC [StoredProcedureDB].[atom].[sp_set_clear_special_flow_ver_009]
		@lot_id = @lot_id, 
		@step_no = @step_no,
		@appname = @appname
	---- ########## VERSION 009 #########
END