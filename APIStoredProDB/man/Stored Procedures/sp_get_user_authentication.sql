-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_user_authentication]
	-- Add the parameters for the stored procedure here
	 @emp_num varchar(10)
	,@password varchar(50) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[man].[sp_get_user_authentication_001]
		@emp_num = @emp_num,
		@password = @password
	-- ########## VERSION 001 ##########
END
