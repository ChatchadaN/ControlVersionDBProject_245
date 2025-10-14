
-- =============================================
-- Author:		<Database Admin,,NutchanaT k.>
-- Create date: <14/07/2025,,>
-- Description:	<List Employee,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_filter_man]
	-- Add the parameters for the stored procedure here
	  @filter		INT  
	, @id			INT  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[man].[sp_get_filter_man_001]
		@filter = @filter
		, @id = @id
	-- ########## VERSION 001 ##########

END
