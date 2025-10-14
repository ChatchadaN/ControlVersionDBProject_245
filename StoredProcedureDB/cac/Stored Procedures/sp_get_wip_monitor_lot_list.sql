-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wip_monitor_lot_list]
	-- Add the parameters for the stored procedure here
	@package_group varchar(50) = '%'
	, @package varchar(50) = '%'
	, @device varchar(50) = '%'
	, @lot_type varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select *
	from
	(select [packages].[name] as [package]
		, [device_names].[name] as [device]
		, [lots].[lot_no] as [lot]
		, [days1].[date_value] as [in_day]
		, DATEDIFF(DAY,[days2].[date_value],GETDATE()) as [delay_day]
		, [lots].[qty_in] as [pieces]
		, [processes].[name] as [process]
		--, [jobs].[name] as [job]
		, [LotRecords].[EndTime]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		inner join [APCSProDB].[trans].[days] as [days1] with (NOLOCK) on [days1].[id] = [lots].[in_plan_date_id]
		--inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[out_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [days2] with (NOLOCK) on [days2].[id] = [lots].[modify_out_plan_date_id]
		left join (select [lot_id], [step_no], MAX(recorded_at) as EndTime
			from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
			where [record_class] in('2','12')
			group by [lot_id], [step_no]) as LotRecords on [LotRecords].[lot_id] = [lots].[id] and [LotRecords].[step_no] = [device_flows].[step_no]
		where [lots].[wip_state] = '20'
		and [device_flows].[is_skipped] = '0'
		and [package_groups].[name] like @package_group
		and [packages].[name] like @package
		and [device_names].[name] like @device
		and SUBSTRING([lots].[lot_no],5,1) like @lot_type
	) as TEMP
	PIVOT
	(
		MAX([EndTime])
		FOR [process] IN([DB]
		, [WB]
		, [MP]
		, [TC]
		, [PL]
		, [FL]
		, [FT]
		, [TP]
		, [O/G]
		, [QA]
		, [Singulation]
		)
	) AS TempPivot
END
