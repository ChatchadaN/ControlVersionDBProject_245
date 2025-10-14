-- =============================================
-- Author:		<Wathanavipa>
-- Create date: <20210706>
-- Description:	<Get flow by device slip id>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_flow_by_deviceslip]
	-- Add the parameters for the stored procedure here
	@devcie_name varchar(50)
	,@assy_name varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	---- ########## VERSION 002 ##########
	EXEC [StoredProcedureDB].[atom].[sp_get_flow_by_deviceslip_ver_002]
		@devcie_name = @devcie_name
		, @assy_name = @assy_name;
	---- ########## VERSION 002 ##########
END
