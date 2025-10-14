-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_ft_wip_001]
		@PKG VARCHAR(20) = 'SSOP-B20W'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--------------------------------------------------------------------------------------------------
	-- FT WIP, Retest, INSP, BIN19
	select [MCName]
		, [lot_no]
		, [DeviceName] 
		, [FTDevice]
		, [MethodPkgName]
		, [JobName]
		, [NextJob]
		, [Kpcs] 
		, [qty_production]
		, [state]
		, [StandardTime]
		, [job_Id]
		, [updated_at]
		, [quality_state]
		, [address]
		, [name]
		, [LotKpcs]
	from (
		select [machines].[name] as [MCName]
			 , [lots].[lot_no]
			 , [device_names].[name] as [DeviceName] 
			 , [device_names].[ft_name] AS [FTDevice]
			 , [packages].[name] as [MethodPkgName]
			 , case when [lots].[is_special_flow] = 1 then replace(replace([job2].[name],'(',''),')','') else replace(replace([jobs].[name],'(',''),')','') end as [JobName]
			 , case when [lots].[is_special_flow] = 1 then [lots].[act_job_id] else 0 end as [NextJob]
			 , [lots].[qty_in] as [Kpcs] 
			 , case 
				when [lots].[process_state] = 2 and [lots].[qty_in] > 0 then (([lots].[qty_in] + 0.0 - ([lots].[qty_last_pass] + [lots].[qty_last_fail])) / [lots].[qty_in]) 
				else 1 end as [qty_production]
			 , case
				when [lots].[process_state] = 0 or [lots].[process_state] = 100 then 0
				when [lots].[process_state] = 1 or [lots].[process_state] = 101 then 1
				when [lots].[process_state] = 2 or [lots].[process_state] = 102 then 2
				else 99 end as [state]
			 , [device_flows].[process_minutes] as [StandardTime]
			 , case when [lots].[is_special_flow] = 1 then [job2].[id] ELSE [jobs].[id] end as [job_Id]
			 , [lots].[updated_at]
			 , [lots].[quality_state]
			 , [locations].[address]
			 , [locations].[name]
			 , [device_names].[official_number] as [LotKpcs]
		from [APCSProDB].[trans].[lots] 
		inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [lots].[device_slip_id] and [device_flows].[step_no] = [lots].[step_no]
		inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[mc].[machines] on [lots].[machine_id] = [machines].[id] 
		left join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lots].[special_flow_id] 
		left join [APCSProDB].[trans].[lot_special_flows] on [lot_special_flows].[special_flow_id] = [special_flows].[id] and  [special_flows].step_no = [lot_special_flows].step_no
		left join [APCSProDB].[method].[jobs] as [job2] on [job2].[id] = [lot_special_flows].[job_id]
		left join [APCSProDB].[trans].[locations] on [locations].[id] = [lots].[location_id] 	
		WHERE [packages].[name] in (SELECT value from STRING_SPLIT (@PKG, ',' ))  
			and [lots].[wip_state] = 20
			and [device_names].[alias_package_group_id] = 33
	) as [data]
	where [job_Id] in (87,88,106,108,110,119,120,155,263,278,359,361,362,363,364,379,387,142,329,378,385)
	--------------------------------------------------------------------------------------------------
END
