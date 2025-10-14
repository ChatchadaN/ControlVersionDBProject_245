-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_user_authorization]
	-- Add the parameters for the stored procedure here
	@emp_num varchar(10)
	,	@app_name varchar(50)
	,	@function_name varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[man].[sp_get_user_authorization_001]
		@emp_num = @emp_num,
		@app_name = @app_name,
		@function_name = @function_name
	-- ########## VERSION 001 ##########
END
