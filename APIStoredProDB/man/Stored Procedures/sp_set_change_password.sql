-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_set_change_password]
	-- Add the parameters for the stored procedure here
	  @emp_code varchar(6)
	, @new_password varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[man].[sp_set_change_password_001]
		@emp_code = @emp_code,
		@new_password = @new_password
	-- ########## VERSION 001 ##########
END
