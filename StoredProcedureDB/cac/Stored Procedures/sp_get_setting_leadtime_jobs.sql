-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_setting_leadtime_jobs]
	-- Add the parameters for the stored procedure here
	@status int = 1
	, @package_name varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@status = 1)
	BEGIN
		select distinct [jobs].[name]
		from [APCSProDB].[method].[jobs] with (NOLOCK)
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[job_id] = [jobs].[id]
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		where [packages].[name] like @package_name
		and ([device_names].[rank] is not null
			and [device_names].[rank] != '')
	END
	IF(@status = 2)
	BEGIN
		select distinct [jobs].[name]
		from [APCSProDB].[method].[jobs] with (NOLOCK)
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[job_id] = [jobs].[id]
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		where [packages].[name] like @package_name
		and ([device_names].[rank] is null
			or [device_names].[rank] = '')
	END
END
