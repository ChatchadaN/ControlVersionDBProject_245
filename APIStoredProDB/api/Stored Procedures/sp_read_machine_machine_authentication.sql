-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_machine_machine_authentication]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@machine_no varchar(50)
	,	@is_production bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@is_production = 1)
	BEGIN
		/*
		-- ########## VERSION 001 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_machine_machine_authentication_ver_001]
		@username = @username
		, @machine_no = @machine_no
		-- ########## VERSION 001 ##########
		*/

		-- ########## VERSION 001 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_machine_machine_authentication_ver_002]
		@username = @username
		, @machine_no = @machine_no
		-- ########## VERSION 001 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION DEV ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_machine_machine_authentication_ver_002]
		@username = @username
		, @machine_no = @machine_no
		-- ########## VERSION DEV ##########
	END
END
