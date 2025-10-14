-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_license_user_machine]
	-- Add the parameters for the stored procedure here
	@emp_code varchar(10)
	, @machine_model VARCHAR(50)
	, @machine_name VARCHAR(50)
	, @is_automotive	BIT				= 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	---- ########## VERSION 001 ##########
	--EXEC [APIStoredProVersionDB].[man].[sp_get_license_user_machine_001]
	--	@emp_code = @emp_code
	--	,@machine_model = @machine_model
	--	,@machine_name =@machine_name

	---- ########## VERSION 001 ##########

	--	-- ########## VERSION 001 ##########
	--EXEC [APIStoredProVersionDB].[man].[sp_get_license_user_machine_002]
	--	@emp_code			= @emp_code
	--	,@machine_model		= @machine_model
	--	,@machine_name		= @machine_name
	--	,@is_automotive		= @is_automotive

	---- ########## VERSION 001 ##########

	---- ########## VERSION 001 ##########   11.26  check license from skill test
	--EXEC [APIStoredProVersionDB].[man].[sp_get_license_user_machine_003]
	--	@emp_code			= @emp_code
	--	,@machine_model		= @machine_model
	--	,@machine_name		= @machine_name
	--	,@is_automotive		= @is_automotive

	---- ########## VERSION 001 ##########

	---- ########## VERSION 004 ##########   --CHECK AUTOMOTIVE   09.08
	--EXEC [APIStoredProVersionDB].[man].[sp_get_license_user_machine_004]
	--	@emp_code			= @emp_code
	--	,@machine_model		= @machine_model
	--	,@machine_name		= @machine_name
	--	,@is_automotive		= @is_automotive

	---- ########## VERSION 004 ##########

	-- ########## VERSION 005 ##########   --SkillTest New Version
	EXEC [APIStoredProVersionDB].[man].[sp_get_license_user_machine_005]
		@emp_code			= @emp_code
		,@machine_model		= @machine_model
		,@machine_name		= @machine_name
		,@is_automotive		= @is_automotive

	-- ########## VERSION 005 ##########

END
