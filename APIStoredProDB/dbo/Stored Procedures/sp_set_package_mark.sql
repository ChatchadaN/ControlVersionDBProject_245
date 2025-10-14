
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_package_mark]	-- Add the parameters for the stored procedure here	
	@id INT
	, @is_enable INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[dbo].[sp_set_package_mark_001] 
		@id = @id
		, @is_enable = @is_enable;
	-- ########## VERSION 001 ##########
END
