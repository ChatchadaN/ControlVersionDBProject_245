-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wip_transition_process]
	-- Add the parameters for the stored procedure here
	@package_group varchar(50) = '%'
	, @package varchar(50) = '%'
	, @lot_type varchar(50) = '%'
	--, @device varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
	-- Insert statements for procedure here
	--select [job] as [process]
	--	,[date_value]
	--	,SUM([today_wip]) as [wip]
	--	,SUM([today_wip_pcs]) as [wip_pcs]
	--	,SUM([today_order_delay]) as [order_delay]
	--	,SUM([today_order_delay_pcs]) as [order_delay_pcs]
	--	,0 as [input_result]
	--	--,SUM([today_input]) as [input_result]
	--	,0 as [input_result_pcs]
	--	--,SUM([today_input_pcs]) as [input_result_pcs]
	--	,SUM([today_output]) as [output_result]
	--	,SUM([today_output_pcs]) as [output_result_pcs]
	--from [APCSProDWH].[cac].[wip_transition_process] 
	--where [package_group] like @package_group
	--and [package] like @package
	--and [lot_type] like @lot_type
	--group by [job], [date_value], [seq_no]
	--order by [seq_no], [job], [date_value]



	--select [job] as [process]		
	--	, [date_value]
	--	, SUM(total) as [wip]
	--	, SUM(total_pcs) as [wip_pcs]
	--	, SUM(order_delay) as [order_delay]
	--	, SUM(order_delay_pcs) as [order_delay_pcs]
	--	, SUM([today_input]) as [input_result]
	--	, 0 as [input_result_pcs]
	--	, SUM(actual_result) as [output_result]
	--	, SUM(actual_result_pcs) as [output_result_pcs]
	--from [APCSProDWH].[cac].[wip_monitor_main] with (NOLOCK)  
	--where [package_group] like @package_group
	----and [device] like @device
	--and [package] like @package
	--and [lot_type] like @lot_type
	--and [date_value] > GETDATE() - 15
	--group by [job], [date_value], [seq_no]
	--order by [seq_no], [job], [date_value]

	--select [t1].[process]		
	--	, [t1].[date_value]
	--	, [t1].[wip]
	--	, [t1].[wip_pcs]
	--	, [t1].[order_delay]
	--	, [t1].[order_delay_pcs]
	--	, [t1].[input_result]
	--	, [t1].[input_result_pcs]
	--	, [t1].[output_result]
	--	, [t1].[output_result_pcs]
	--from (
	--	select  [job] as [process]		
	--			, [date_value]
	--			, SUM(total) as [wip]
	--			, SUM(total_pcs) as [wip_pcs]
	--			, SUM(order_delay) as [order_delay]
	--			, SUM(order_delay_pcs) as [order_delay_pcs]
	--			, SUM([today_input]) as [input_result]
	--			, 0 as [input_result_pcs]
	--			, SUM(actual_result) as [output_result]
	--			, SUM(actual_result_pcs) as [output_result_pcs]
	--			,[seq_no]
	--		from [APCSProDWH].[cac].[wip_monitor_main] with (NOLOCK)  
	--		where [package_group] like @package_group
	--			--and [device] like @device
	--			and [package] like @package
	--			and [lot_type] like @lot_type 
	--			and [date_value] > GETDATE() - 15
	--		group by [job], [date_value], [seq_no]
	--) as [t1]
	--left join (
	--		select  [job] as [process]	
	--			, [seq_no]
	--			, RANK () OVER ( 
	--				PARTITION BY [job]
	--				ORDER BY [seq_no] asc
	--			) [rowmax]	
	--		from [APCSProDWH].[cac].[wip_monitor_main] with (NOLOCK)  
	--		where [package_group] like @package_group
	--			--and [device] like @device
	--			and [package] like @package
	--			and [lot_type] like @lot_type 
	--			and [date_value] > GETDATE() - 15
	--		group by [job], [seq_no]
	--) as [t2] on [t1].process = [t2].process and [t2].rowmax = 1
	--order by [t2].[seq_no], [t2].[process],  [t1].[date_value] asc

	--select [job] as [process]		
	--	, [date_value]
	--	, SUM(total) as [wip]
	--	, SUM(total_pcs) as [wip_pcs]
	--	, SUM(order_delay) as [order_delay]
	--	, SUM(order_delay_pcs) as [order_delay_pcs]
	--	, SUM([today_input]) as [input_result]
	--	, 0 as [input_result_pcs]
	--	, SUM(actual_result) as [output_result]
	--	, SUM(actual_result_pcs) as [output_result_pcs]
	--	, [seq_no]
	--from (
	--	select [package]
	--		, [job]
	--		, [date_value]
	--		, [total]
	--		, [total_pcs]
	--		, [order_delay]
	--		, [order_delay_pcs]
	--		, [today_input]
	--		, [actual_result]
	--		, [actual_result_pcs]
	--		--, IIF([package] LIKE 'TO2%' AND [job] = 'qcANALYSIS JUDGE',8999 ,[seq_no]) AS [seq_no]
	--		, IIF([job] = 'qcANALYSIS JUDGE',8999 ,[seq_no]) AS [seq_no]
	--	from [APCSProDWH].[cac].[wip_monitor_main] with (NOLOCK)
	--	where [package_group] like @package_group
	--		--and [device] like @device
	--		and [package] like @package
	--		and [lot_type] like @lot_type 
	--		and [date_value] > GETDATE() - 15
	--) as [wip_monitor_main]
	--group by [seq_no], [job], [date_value]
	--order by [seq_no], [job], [date_value] asc;

	--select [job] as [process]		
	--	, [date_value]
	--	, SUM(total) as [wip]
	--	, SUM(total_pcs) as [wip_pcs]
	--	, SUM(order_delay) as [order_delay]
	--	, SUM(order_delay_pcs) as [order_delay_pcs]
	--	, SUM([today_input]) as [input_result]
	--	, 0 as [input_result_pcs]
	--	, SUM(actual_result) as [output_result]
	--	, SUM(actual_result_pcs) as [output_result_pcs]
	--	, [seq_no]
	--from (
	--	select [data_main].[package]
	--		, [data_main].[job]
	--		, [data_main].[date_value]
	--		, isnull([wip_monitor_main].[total],0) as [total]
	--		, isnull([wip_monitor_main].[total_pcs],0) as [total_pcs]
	--		, isnull([wip_monitor_main].[order_delay],0) as [order_delay]
	--		, isnull([wip_monitor_main].[order_delay_pcs],0) as [order_delay_pcs]
	--		, isnull([wip_monitor_main].[today_input],0) as [today_input]
	--		, isnull([wip_monitor_main].[actual_result],0) as [actual_result]
	--		, isnull([wip_monitor_main].[actual_result_pcs],0) as [actual_result_pcs]
	--		, case [data_main].[job]
	--			when 'qcANALYSIS JUDGE' then 8999
	--			when '100% INSP.' then 8600
	--			when 'SAMPLING INSP' then 8600
	--			else [data_main].[seq_no]
	--		end AS [seq_no]
	--		--, [data_main].[seq_no]
	--	from (
	--		select [main].[package]
	--			, [main].[job]
	--			, [main].[seq_no]
	--			, [days].[date_value]
	--		from (
	--			select [package]
	--				, [job]
	--				, [seq_no]
	--			from [APCSProDWH].[cac].[wip_monitor_main] with (nolock)
	--			where [package_group] like @package_group
	--				--and [device] like @device
	--				and [package] like @package
	--				and [lot_type] like @lot_type 
	--				and [date_value] between getdate() - 15 and getdate()
	--			group by [package], [job], [seq_no]
	--		) as [main]
	--		, (
	--			select [date_value]
	--			from [APCSProDB].[trans].[days] with (nolock)
	--			where [days].[date_value] between getdate() - 15 and getdate()
	--		) as [days]
	--	) as [data_main]
	--	left join [APCSProDWH].[cac].[wip_monitor_main] with (nolock) on [data_main].[package] = [wip_monitor_main].[package]
	--		and [data_main].[job] = [wip_monitor_main].[job]
	--		and [data_main].[date_value] = [wip_monitor_main].[date_value]
	--		and [wip_monitor_main].[lot_type] like @lot_type
	--) as [data_main]
	--group by [data_main].[seq_no], [data_main].[job], [data_main].[date_value] 
	--order by [data_main].[seq_no], [data_main].[job], [data_main].[date_value] asc;

	select  [days].[job] as [process]		
		, [days].[date_value]
		, isnull(sum(total),0) as [wip]
		, isnull(sum(total_pcs),0) as [wip_pcs]
		, isnull(sum(order_delay),0) as [order_delay]
		, isnull(sum(order_delay_pcs),0) as [order_delay_pcs]
		, isnull(sum([today_input]),0) as [input_result]
		, 0 as [input_result_pcs]
		, isnull(sum(actual_result),0) as [output_result]
		, isnull(sum(actual_result_pcs),0) as [output_result_pcs]
		, isnull(sum(hold),0) as [hold]
		, isnull(sum(hold_pcs),0) as [hold_pcs]
		, [days].[seq_no]
	from (
		select [package]
			, [job]
			, [seq_no]
			, [date_value]
		from (
			select [main].[package]
				, [main].[job]
				, [main].[seq_no]
				, [days].[date_value]
			from (
				select [package]
					, [job]
					, case [job]
						when 'qcANALYSIS JUDGE' then 8999
						when '100% INSP.' then 8600
						when 'SAMPLING INSP' then 8600
						else [seq_no]
					end AS [seq_no]
				from [APCSProDWH].[cac].[wip_monitor_main] with (nolock)
				where [package_group] like @package_group
					--and [device] like @device
					and [package] like @package
					and [lot_type] like @lot_type 
					and [date_value] between getdate() - 15 and getdate()
				group by [package], [job], [seq_no]
			) as [main]
			, (
				select [date_value]
				from [APCSProDB].[trans].[days] with (nolock)
				where [date_value] between getdate() - 15 and getdate()
			) as [days]
		) as [data_main]
		group by [package], [job], [seq_no], [date_value]
	) as [days]
	left join (
		select [job]
			, [package]
			, isnull([wip_monitor_main].[total],0) as [total]
			, isnull([wip_monitor_main].[total_pcs],0) as [total_pcs]
			, isnull([wip_monitor_main].[order_delay],0) as [order_delay]
			, isnull([wip_monitor_main].[order_delay_pcs],0) as [order_delay_pcs]
			, isnull([wip_monitor_main].[today_input],0) as [today_input]
			, isnull([wip_monitor_main].[actual_result],0) as [actual_result]
			, isnull([wip_monitor_main].[actual_result_pcs],0) as [actual_result_pcs]
			, isnull([wip_monitor_main].[hold],0) as [hold]
			, isnull([wip_monitor_main].[hold_pcs],0) as [hold_pcs]
			, [date_value]
		from [APCSProDWH].[cac].[wip_monitor_main] with (nolock)
		where [package_group] like @package_group
			--and [device] like @device
			and [package] like @package
			and [lot_type] like @lot_type 
			and [date_value] between getdate() - 15 and getdate()
	) as [data_main] on [days].[date_value] = [data_main].[date_value]
		and [days].[job] = [data_main].[job]
		and [days].[package] = [data_main].[package]
	group by [days].[seq_no], [days].[job], [days].[date_value]
	order by [days].[seq_no], [days].[job], [days].[date_value] asc;
END
