-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_set_setting_leadtime]
	-- Add the parameters for the stored procedure here
	@status int = 1
	, @package_name varchar(50) = '%'
	, @job_name varchar(50) = '%'
	, @value int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@status = 1)
	BEGIN
		update [APCSProDB].[method].[device_flows]
		set [lead_time] = @value
		where [device_flows].[device_slip_id] in(select distinct [device_slips].[device_slip_id]
			from [APCSProDB].[method].[device_slips]
			inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
			inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
			where [packages].[name] like @package_name
			and ([device_names].[rank] is not null
			and [device_names].[rank] != ''))
		and [job_id] in(select distinct [id]
			from [APCSProDB].[method].[jobs]
			where [name] like @job_name)
	END
	IF(@status = 2)
	BEGIN
		update [APCSProDB].[method].[device_flows]
		set [lead_time] = @value
		where [device_flows].[device_slip_id] in(select distinct [device_slips].[device_slip_id]
			from [APCSProDB].[method].[device_slips]
			inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
			inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
			where [packages].[name] like @package_name
			and ([device_names].[rank] is null
			or [device_names].[rank] = ''))
		and [job_id] in(select distinct [id]
			from [APCSProDB].[method].[jobs]
			where [name] like @job_name)
	END
END
