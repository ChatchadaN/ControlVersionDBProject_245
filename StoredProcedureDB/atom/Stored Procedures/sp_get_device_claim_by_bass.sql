
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_device_claim_by_bass]	-- Add the parameters for the stored procedure here	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--declare @table_atom table
	--(
	--	[lot_no] varchar(20)
	--	, [device] varchar(20)
	--	, [assy_name] varchar(20)
	--	, [ft_device] varchar(20)
	--	, [package] varchar(20)
	--	, [package_group] varchar(20)
	--	, [tp_rank] varchar(10)
	--);
	
	--insert into @table_atom
	--select [lot_no]
	--	, [device]
	--	, [assy_name]
	--	, [ft_device]
	--	, [package]
	--	, [package_group]
	--	, [tp_rank]
	--from (
	--	select [lots].[lot_no]
	--		, [device_names].[name] as [device]
	--		, [device_names].[assy_name]
	--		, [device_names].[ft_name] as [ft_device]
	--		, [packages].[name] as [package]
	--		, [package_groups].[name] as [package_group]
	--		, [device_names].[tp_rank]
	--	from [APCSProDB].[trans].[lots] with (nolock) 
	--	-------------------- date -------------------- 
	--	inner join [APCSProDB].[trans].[days] as [day_indate] with (nolock) on [day_indate].[id] = [lots].[in_plan_date_id]
	--	inner join [APCSProDB].[trans].[days] as [day_outdate] with (nolock) on [day_outdate].[id] = [lots].[modify_out_plan_date_id]
	--	-------------------- date -------------------- 
	--	inner join [APCSProDB].[method].[device_names] with (nolock) on [device_names].[id] = [lots].[act_device_name_id]
	--	inner join [APCSProDB].[method].[packages] with (nolock) on [packages].[id] = [device_names].[package_id]
	--	inner join [APCSProDB].[method].[package_groups] with (nolock) on [package_groups].[id] = [packages].[package_group_id]
	--	-------------------- master_flows --------------------
	--	inner join [APCSProDB].[method].[device_flows] with (nolock) on [device_flows].[device_slip_id] = [lots].[device_slip_id] 
	--		and [device_flows].[step_no] = [lots].[step_no]
	--	inner join [APCSProDB].[method].[jobs] with (nolock) on [jobs].[id] = [device_flows].[job_id]
	--	inner join [APCSProDB].[method].[processes] with (nolock) on [processes].[id] = [jobs].[process_id]
	--	-------------------- master_flows --------------------
	--	-------------------- special_flows -------------------- 
	--	left join [APCSProDB].[trans].[special_flows] with (nolock) on [special_flows].[id] = [lots].[special_flow_id] 
	--	left join [APCSProDB].[trans].[lot_special_flows] with (nolock) on [lot_special_flows].[special_flow_id] = [special_flows].[id] 
	--		and  [special_flows].[step_no] = [lot_special_flows].[step_no]
	--	left join [APCSProDB].[method].[jobs] as [job_special] with (nolock) on [job_special].[id] = [lot_special_flows].[job_id]
	--	left join [APCSProDB].[method].[processes] as [process_special] with (nolock) on [process_special].[id] = [job_special].[process_id]
	--	-------------------- special_flows -------------------- 
	--	--where [lots].[wip_state] in (10,20,0)
	--	--	and [day_indate].[date_value] <= convert(date, getdate())
	--	where [day_indate].[date_value] <= convert(date, '2023-12-01')
	--		AND [lots].[wip_state] in (10,20,0,100,101,70)
	--) as [lots];

	--select [lots].[lot_no] AS [LotNo]
	--from @table_atom as [lots]
	--where [lots].[package] = 'SSOP-B28W'
	--	and [lots].[ft_device] in ('BM60061FV-CD','BM60061AFV-CD')
	--order by [lots].[lot_no];

		select [lots].[lot_no] AS [LotNo]
			--, [lots].[wip_state] 
			--, [day_indate].[date_value]
		from [APCSProDB].[trans].[lots] with (nolock) 
		-------------------- date -------------------- 
		inner join [APCSProDB].[trans].[days] as [day_indate] with (nolock) on [day_indate].[id] = [lots].[in_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [day_outdate] with (nolock) on [day_outdate].[id] = [lots].[modify_out_plan_date_id]
		-------------------- date -------------------- 
		inner join [APCSProDB].[method].[device_names] with (nolock) on [device_names].[id] = [lots].[act_device_name_id]
		inner join [APCSProDB].[method].[packages] with (nolock) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] with (nolock) on [package_groups].[id] = [packages].[package_group_id]
		where [day_indate].[date_value] >= convert(date, '2023-12-14')
			AND [lots].[wip_state] in (0,10,20,70,100,101)
			AND [lots].[lot_no] LIKE '____A____V'
			AND [packages].[name] = 'SSOP-B28W'
			AND year([day_indate].[date_value]) <= year(convert(date, getdate()))    
			AND [device_names].[name] in ('BM60061FV-CDE2','BM60061AFV-CDE2')
END