
-- =============================================
-- Author:		<Database Admin,,NutchanaT k.>
-- Create date: <14/07/2025,,>
-- Description:	<List Employee,,>
-- =============================================
CREATE PROCEDURE [mc].[sp_get_models_filter]
	-- Add the parameters for the stored procedure here
@item AS INT, 
@val AS VARCHAR(15) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[mc].[sp_get_models_filter_ver_001]
		@item = @item,
		@val = @val
	-- ########## VERSION 001 ##########

END
