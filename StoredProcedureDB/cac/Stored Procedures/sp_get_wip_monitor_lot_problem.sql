-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wip_monitor_lot_problem]
	-- Add the parameters for the stored procedure here
	@package varchar(50) = '%'
	, @process varchar(50) = '%'
	, @status int = 1 -- 1: APCSPRO, 2: APCS
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
    -- Insert statements for procedure here
	IF(@status = 1)
	BEGIN
		select [master_data].*
		from (select [lots].[id]
				, [device_flows].[step_no]
				, [lots].[lot_no]
				, [package_groups].[name] as [package_group]
				, [packages].[name] as [package]
				, [device_names].[name] as [device_name]
				, [processes].[name] as [process]
				, [jobs].[name] as [job]
				, 'http://webserv.thematrix.net/atom/User/Details/' + CONVERT(varchar(10), [lots].[id]) +'?WipState=Already%20Input' as [web_access]
				, [jobs].[seq_no] as [seq_no]
			from [APCSProDB].[trans].[lots] with (NOLOCK)
			inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
				inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
				inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
				inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
				inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
				inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [lots].[device_slip_id]
			inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
			inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
			where [lots].[wip_state] = '20'
			and [packages].[is_enabled] = 1
			and [device_flows].[is_skipped] = 0
			and [device_flows].[step_no] < [lots].[step_no]
			and [device_flows].[step_no] >= [lots].[start_step_no] 
			and [packages].[name] like @package
			and [processes].[name] like @process ) as [master_data]
		left join (select [lot_process_records].[lot_id]
				, [lot_process_records].[step_no]
				, MAX(recorded_at) as [end_date]
			from [APCSProDB].[trans].[lot_process_records] with (NOLOCK)
			where [lot_process_records].[record_class] in (2,12,32)
			group by [lot_process_records].[lot_id], [lot_process_records].[step_no]) as [lot_max] on [lot_max].[lot_id] = [master_data].[id] and [lot_max].[step_no] = [master_data].[step_no]
		where [lot_max].[end_date] is null
		order by [master_data].[lot_no], [master_data].[seq_no]
	END
END
