-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_cac_wip_monitoring_main]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@package_group varchar(50) = '%'
	,	@lot_type varchar(50) = '%'
	,	@is_production bit = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@is_production = 1)
	BEGIN
		-- ########## VERSION 001 ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_cac_wip_monitoring_main_ver_001]
		@username = @username
		,	@package_group = @package_group
		,	@lot_type = @lot_type
		-- ########## VERSION 001 ##########
	END
	ELSE
	BEGIN
		-- ########## VERSION DEV ##########
		EXEC [APIStoredProVersionDB].[api].[sp_read_cac_wip_monitoring_main_ver_001]
		@username = @username
		,	@package_group = @package_group
		,	@lot_type = @lot_type
		-- ########## VERSION DEV ##########
	END
END
