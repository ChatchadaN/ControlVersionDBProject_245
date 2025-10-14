-- =============================================
-- Author:		<Wathanavipa>
-- Create date: <20210706>
-- Description:	<Get flow by device slip id>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_flow_by_deviceslip_ver_001]
	-- Add the parameters for the stored procedure here
	@devcie_name varchar(50)
	,@assy_name varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--DECLARE @device_slip_no int;
	--DECLARE @devcie_no int;

	select [device_flows].device_slip_id
		,[jobs].id as [id]
		,[jobs].name as [filter_name]
		,[device_flows].step_no
		,[device_flows].next_step_no
	from [APCSProDB].[method].[device_names]
	inner join [APCSProDB].[method].[device_versions] on [device_versions].device_name_id = [device_names].id 
	and version_num = (select MAX(version_num) from [APCSProDB].[method].[device_versions] where device_name_id = [device_names].id )
	inner join [APCSProDB].[method].[device_slips] on [device_slips].device_id = [device_versions].device_id 
	and is_released = 1
	and [device_slips].version_num = (select MAX(version_num) FROM [APCSProDB].[method].[device_slips] where device_id = [device_versions].device_id and is_released = 1)
	inner join [APCSProDB].[method].[device_flows] on [device_flows].device_slip_id = [device_slips].device_slip_id
	inner join [APCSProDB].[method].jobs on jobs.id = [device_flows].job_id
	where [device_names].name like @devcie_name
	and [device_names].assy_name like @assy_name 
	and [device_flows].[is_skipped] != 1
	order by [device_flows].step_no

END
