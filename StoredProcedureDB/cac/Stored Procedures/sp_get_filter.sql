-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_filter]
	-- Add the parameters for the stored procedure here
	@lot_type varchar(1) = '%'
	, @package_group varchar(50) = '%'
	, @package varchar(50) = '%'
	, @device varchar(50) = '%'
	, @process varchar(50) = '%'
	, @filter int = 1 -- 1: Package Group, 2: Package, 3: Device, 4: Process, 5: Lot Type, 6: Year, 7: Month, 8: ShortPackage
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@filter = 1)
	BEGIN
		select distinct [package_groups].[name] as [filter_name]
		from [APCSProDB].[trans].[lots]
		inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] on [processes].[id] = [jobs].[process_id]
		--where [package_groups].[name] like @package_group
		--and [packages].[name] like @package
		--and [device_names].[name] like @device
		--and [processes].[name] like @process
		--and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		order by [package_groups].[name]
	END
	IF(@filter = 2)
	BEGIN
		--- package
		select [packages].[name] as [filter_name]
		from (
			select [act_device_name_id] from [APCSProDB].[trans].[lots]
			group by [act_device_name_id]
		) as [lots]
		inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [lots].[act_device_name_id]
		inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id]
		where [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and [device_names].[name] like @device
		group by [packages].[name]
		order by [packages].[name]
	END
	IF(@filter = 3)
	BEGIN
		--- device
		select [device_names].[name] as [filter_name]
		from (
			select [act_device_name_id] from [APCSProDB].[trans].[lots]
			group by [act_device_name_id]
		) as [lots]
		inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [lots].[act_device_name_id]
		inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id]
		where [package_groups].[name] like @package_group
			and [packages].[name] like @package
			and [device_names].[name] like @device
		group by [device_names].[name]
		order by [device_names].[name]
	END
	IF(@filter = 4)
	BEGIN
		select distinct [processes].[name] as [filter_name]
			, [processes].[process_no]
		from [APCSProDB].[method].[processes]
		where [processes].[name] like @process
		and [processes].[process_no] is not null
		order by [processes].[process_no] 
	END
	IF(@filter = 5)
	BEGIN
		select 'A' as [filter_name]
		union all
		select 'B' as [filter_name]
		union all
		select 'D' as [filter_name]
		union all
		select 'E' as [filter_name]
		union all
		select 'F' as [filter_name]
		union all
		select 'G' as [filter_name]
		union all
		select 'H' as [filter_name]
		union all
		select 'S' as [filter_name]
		union all
		select 'V' as [filter_name]
	END
	IF(@filter = 6)
	BEGIN
		select year(date_value) as [filter_name]
		from [APCSProDWH].[cac].[wip_transition_main]
		group by year(date_value)
		--order by year(date_value) desc
	END
	IF(@filter = 7)
	BEGIN
		select DATENAME( MONTH, DATEADD( MONTH, month(date_value), -1)) as [filter_name]
		from [APCSProDWH].[cac].[wip_transition_main]
		group by month(date_value)
	END
	IF(@filter = 8)
	BEGIN
		--- package
		select [packages].[short_name] as [filter_name]
		from (
			select [act_device_name_id] from [APCSProDB].[trans].[lots]
			group by [act_device_name_id]
		) as [lots]
		inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [lots].[act_device_name_id]
		inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id]
		where [package_groups].[name] like @package_group
			and [packages].[short_name] like @package
			and [device_names].[name] like @device
		group by [packages].[short_name]
		order by [packages].[short_name]
	END
END
