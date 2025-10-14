
-- =============================================
-- Author:		<Database Admin,,NutchanaT k.>
-- Create date: <14/08/2025,,>
-- Description:	<get_mc_group_models,,>
-- =============================================
Create PROCEDURE [mc].[sp_get_mc_group_models]
	-- Add the parameters for the stored procedure here
	@machine_group_id AS INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[mc].[sp_get_mc_group_models_ver_001]
		@machine_group_id = @machine_group_id
	-- ########## VERSION 001 ##########

END
