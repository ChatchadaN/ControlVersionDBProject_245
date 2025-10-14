-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_license]
	-- Add the parameters for the stored procedure here
	@emp_code varchar(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [APIStoredProDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [man].[sp_get_license_002] @emp_code = ''' + @emp_code + ''''

	---- ########## VERSION 001 ##########
	--EXEC [APIStoredProVersionDB].[man].[sp_get_license_001]
	--	@emp_code = @emp_code
	---- ########## VERSION 001 ##########

	---- ########## VERSION 001 ##########   13.58 cehck from view skill test
	--EXEC [APIStoredProVersionDB].[man].[sp_get_license_002]
	--	@emp_code = @emp_code
	---- ########## VERSION 001 ##########


	--	-- ########## VERSION 001 ##########
	--EXEC [APIStoredProVersionDB].[man].[sp_get_license_003]
	--	@emp_code = @emp_code
	---- ########## VERSION 001 ##########

	----CHECK AUTOMOTIVE   09.08
	--		-- ########## VERSION 001 ##########
	--EXEC [APIStoredProVersionDB].[man].[sp_get_license_004]
	--	@emp_code = @emp_code
	---- ########## VERSION 001 ##########

		--Skill Test New Version
	-- ########## VERSION 005 ##########
	EXEC [APIStoredProVersionDB].[man].[sp_get_license_005]
		@emp_code = @emp_code
	-- ########## VERSION 005 ##########

END
