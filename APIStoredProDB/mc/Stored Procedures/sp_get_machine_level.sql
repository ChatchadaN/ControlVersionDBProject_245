
-- =============================================
-- Author:		<Database Admin,,NutchanaT k.>
-- Create date: <14/07/2025,,>
-- Description:	<List Employee,,>
-- =============================================
Create PROCEDURE [mc].[sp_get_machine_level]
	-- Add the parameters for the stored procedure here
@val AS VARCHAR(15) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[mc].[sp_get_machine_level_ver_001]
		@val = @val
	-- ########## VERSION 001 ##########

END
