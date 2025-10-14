-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_setting_leadtime_jobs_table]
	-- Add the parameters for the stored procedure here
	@status int = 1
	, @package_name varchar(50) = '%'
	, @job_name varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@status = 1)
	BEGIN
		select [packages].[name] as [package]
		, [device_names].[name] as [device]
		, [jobs].[name] as [jobs]
		, [lead_time]
		from [APCSProDB].[method].[device_flows] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		where [device_flows].[device_slip_id] in(select distinct [device_slips].[device_slip_id]
			from [APCSProDB].[method].[device_slips] with (NOLOCK)
			inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
			inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
			where [packages].[name] like @package_name
			and ([device_names].[rank] is not null
			and [device_names].[rank] != ''))
		and [job_id] in(select distinct [id]
			from [APCSProDB].[method].[jobs] with (NOLOCK)
			where [name] like @job_name)
		order by [packages].[name], [device_names].[name], [jobs].[seq_no]
	END
	IF(@status = 2)
	BEGIN
		select [packages].[name] as [package]
		, [device_names].[name] as [device]
		, [jobs].[name] as [jobs]
		, [lead_time]
		from [APCSProDB].[method].[device_flows] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		where [device_flows].[device_slip_id] in(select distinct [device_slips].[device_slip_id]
			from [APCSProDB].[method].[device_slips] with (NOLOCK)
			inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
			inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
			where [packages].[name] like @package_name
			and ([device_names].[rank] is null
			or [device_names].[rank] = ''))
		and [job_id] in(select distinct [id]
			from [APCSProDB].[method].[jobs] with (NOLOCK)
			where [name] like @job_name)
		order by [packages].[name], [device_names].[name], [jobs].[seq_no]
	END
END
