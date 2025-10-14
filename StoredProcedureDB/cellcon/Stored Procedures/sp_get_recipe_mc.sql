-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_recipe_mc] 
	-- Add the parameters for the stored procedure here
	@package varchar(20),@mcno varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT pl_recipe.Recipe_Name AS recipe_mc FROM DBx.cellcon.pl_recipe WHERE pl_recipe.Package_Name = @package AND pl_recipe.MCNo = @mcno

END
