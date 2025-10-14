-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wip_monitor_main]
	-- Add the parameters for the stored procedure here
	@package_group varchar(50) = '%'
	, @lot_type varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @rohm_date_start datetime = convert(datetime,convert(varchar(10), GETDATE(), 120))
	DECLARE @rohm_date_end datetime = convert(datetime,convert(varchar(10), GETDATE(), 120) + ' 08:00:00')
	DECLARE @date_value varchar(10)


	IF((GETDATE() >= @rohm_date_start) AND (GETDATE() < @rohm_date_end))
	BEGIN
		SET @date_value = convert(varchar(10), GETDATE() - 1, 120)
	END
	ELSE
	BEGIN
		SET @date_value = convert(varchar(10), GETDATE(), 120)
	END

	select *
	from (
		select [package_group]
			,[jobs].[name] as [job]
			,[seq_no]
			,[normal]
			,[normal_pcs]
			,[delay]
			,[delay_pcs]
			,[order_delay]
			,[order_delay_pcs]
			,[order_delay_hold]
			,[order_delay_hold_pcs]
			,[hold]
			,[hold_pcs]
			,[total]
			,[total_pcs]
			,[machine]
			,[machine_pcs]
			,[actual_result]
			,[actual_result_pcs]
			,[yesterday_result]
			,[yesterday_result_pcs]
		from (
			select 'ALL' as [package_group]
				,[wip_monitor_main].[job]
				,[wip_monitor_main].[seq_no]
				,SUM([normal]) as [normal]
				,SUM([normal_pcs])/1000 as [normal_pcs]
				,SUM([delay]) as [delay]
				,SUM([delay_pcs])/1000 as [delay_pcs]
				,SUM([order_delay]) as [order_delay]
				,SUM([order_delay_pcs])/1000 as [order_delay_pcs]
				,SUM([order_delay_hold]) as [order_delay_hold]
				,SUM([order_delay_hold_pcs])/1000 as [order_delay_hold_pcs]
				,SUM([hold]) as [hold]
				,SUM([hold_pcs])/1000 as [hold_pcs]
				,SUM([total]) as [total]
				,SUM([total_pcs])/1000 as [total_pcs]
				,SUM([machine]) as [machine]
				,SUM([machine_pcs])/1000 as [machine_pcs]
				,SUM([actual_result]) as [actual_result]
				,SUM([actual_result_pcs])/1000 as [actual_result_pcs]
				,SUM([yesterday_result]) as [yesterday_result]
				,SUM([yesterday_result_pcs])/1000 as [yesterday_result_pcs]
			from [APCSProDWH].[cac].[wip_monitor_main] 
			where [date_value] = @date_value
				and [package_group] like @package_group
				and [lot_type] like @lot_type
			group by [job], [wip_monitor_main].[seq_no]
		) AS [table]
		outer apply (
			select top 1 [jobs].[short_name], [jobs].[name]
			from [APCSProDB].[method].[jobs] 
			where [jobs].[name] = [table].[job]
		) as [jobs]
	) as [table]
	order by [table].[package_group], [table].[seq_no];

    -- Insert statements for procedure here
	--select 'ALL' as [package_group]
	--	--,[job]
	--	,[jobs].[name] AS [job]
	--	,[wip_monitor_main].[seq_no]
	--	,SUM([normal]) as [normal]
	--	,SUM([normal_pcs])/1000 as [normal_pcs]
	--	,SUM([delay]) as [delay]
	--	,SUM([delay_pcs])/1000 as [delay_pcs]
	--	,SUM([order_delay]) as [order_delay]
	--	,SUM([order_delay_pcs])/1000 as [order_delay_pcs]
	--	,SUM([order_delay_hold]) as [order_delay_hold]
	--	,SUM([order_delay_hold_pcs])/1000 as [order_delay_hold_pcs]
	--	,SUM([hold]) as [hold]
	--	,SUM([hold_pcs])/1000 as [hold_pcs]
	--	,SUM([total]) as [total]
	--	,SUM([total_pcs])/1000 as [total_pcs]
	--	,SUM([machine]) as [machine]
	--	,SUM([machine_pcs])/1000 as [machine_pcs]
	--	,SUM([actual_result]) as [actual_result]
	--	,SUM([actual_result_pcs])/1000 as [actual_result_pcs]
	--	,SUM([yesterday_result]) as [yesterday_result]
	--	,SUM([yesterday_result_pcs])/1000 as [yesterday_result_pcs]
	--from [APCSProDWH].[cac].[wip_monitor_main] 
	--outer apply (
	--	select top 1 [jobs].[short_name], [jobs].[name]
	--	from [APCSProDB].[method].[jobs] 
	--	where [jobs].[name] = [wip_monitor_main].[job]
	--) as [jobs]
	--where [date_value] = @date_value
	--and [package_group] like @package_group
	--and [lot_type] like @lot_type
	--group by [job], [wip_monitor_main].[seq_no], [jobs].[name]
	--order by [package_group], [wip_monitor_main].[seq_no], [jobs].[name]

	--select [package_group]
	--		,IIF([jobs].[short_name] is null,[job],[jobs].[short_name]) as [job]
	--		,[seq_no]
	--		,[normal]
	--		,[normal_pcs]
	--		,[delay]
	--		,[delay_pcs]
	--		,[order_delay]
	--		,[order_delay_pcs]
	--		,[order_delay_hold]
	--		,[order_delay_hold_pcs]
	--		,[hold]
	--		,[hold_pcs]
	--		,[total]
	--		,[total_pcs]
	--		,[machine]
	--		,[machine_pcs]
	--		,[actual_result]
	--		,[actual_result_pcs]
	--		,[yesterday_result]
	--		,[yesterday_result_pcs]
	--from (
	--	select 'ALL' as [package_group]
	--		,IIF([job] like '%?%',REPLACE([job], N'?', N'･'),[job]) as [job]
	--		--,job
	--		,[process]
	--		,[seq_no]
	--		,SUM([normal]) as [normal]
	--		,SUM([normal_pcs])/1000 as [normal_pcs]
	--		,SUM([delay]) as [delay]
	--		,SUM([delay_pcs])/1000 as [delay_pcs]
	--		,SUM([order_delay]) as [order_delay]
	--		,SUM([order_delay_pcs])/1000 as [order_delay_pcs]
	--		,SUM([order_delay_hold]) as [order_delay_hold]
	--		,SUM([order_delay_hold_pcs])/1000 as [order_delay_hold_pcs]
	--		,SUM([hold]) as [hold]
	--		,SUM([hold_pcs])/1000 as [hold_pcs]
	--		,SUM([total]) as [total]
	--		,SUM([total_pcs])/1000 as [total_pcs]
	--		,SUM([machine]) as [machine]
	--		,SUM([machine_pcs])/1000 as [machine_pcs]
	--		,SUM([actual_result]) as [actual_result]
	--		,SUM([actual_result_pcs])/1000 as [actual_result_pcs]
	--		,SUM([yesterday_result]) as [yesterday_result]
	--		,SUM([yesterday_result_pcs])/1000 as [yesterday_result_pcs]
	--	from [APCSProDWH].[cac].[wip_monitor_main] 
	--	where [date_value] = @date_value
	--	--and [package_group] like @package_group
	--	--and [lot_type] like @lot_type
	--	group by [job],[seq_no],[process]
	--	--order by [package_group],[seq_no]
	--) as [table]
	--left join (
	--	select jobs.name,jobs.short_name,[processes].[name] as [process] from [APCSProDB].[method].[jobs]
	--	inner join [APCSProDB].[method].[processes] on [processes].[id] = [jobs].[process_id]
	--	group by jobs.name,jobs.short_name,[processes].[name]
	--) as [jobs] on [table].[job] = [jobs].[name]
	--	and [table].[process] = [jobs].[process]
	--order by [table].[package_group],[table].[seq_no]

END
