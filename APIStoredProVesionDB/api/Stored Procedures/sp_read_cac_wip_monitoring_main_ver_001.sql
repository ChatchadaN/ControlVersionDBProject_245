-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_read_cac_wip_monitoring_main_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@package_group varchar(50) = '%'
	,	@lot_type varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	EXEC [StoredProcedureDB].[cac].[sp_get_wip_monitor_main]
	@package_group = @package_group
	,	@lot_type = @lot_type
END
