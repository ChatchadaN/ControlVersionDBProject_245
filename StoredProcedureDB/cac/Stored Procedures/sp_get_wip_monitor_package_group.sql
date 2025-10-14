-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wip_monitor_package_group]
	-- Add the parameters for the stored procedure here
	@package_group varchar(50) = '%'
	, @package varchar(50) = '%'
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

    -- Insert statements for procedure here
	--select 'ALL' as [package]
	--	,[job]
	--	,[seq_no]
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
	--	,SUM([specialflow]) as [specialflow]
	--	,SUM([specialflow_pcs])/1000 as [specialflow_pcs]
	--	,SUM([order_delay_special]) as [order_delay_special]
	--	,SUM([order_delay_special_pcs])/1000 as [order_delay_special_pcs]
	--from [APCSProDWH].[cac].[wip_monitor_main] 
	--where [date_value] = @date_value
	--and [package_group] like @package_group
	--and [package] like @package
	--and [lot_type] like @lot_type
	--group by [job],[seq_no]
	--union all
	--select 'ALL' as [package]
	--	,'TOTAL' as [job]
	--	,100000 as [seq_no]
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
	--	,SUM([specialflow]) as [specialflow]
	--	,SUM([specialflow_pcs])/1000 as [specialflow_pcs]
	--	,SUM([order_delay_special]) as [order_delay_special]
	--	,SUM([order_delay_special_pcs])/1000 as [order_delay_special_pcs]
	--from [APCSProDWH].[cac].[wip_monitor_main] 
	--where [date_value] = @date_value
	--and [package_group] like @package_group
	--and [package] like @package
	--and [lot_type] like @lot_type
	--order by [package],[seq_no]

	--select [package]
	--	--,[job]
	--	,IIF([jobs].[short_name] is null,[job],[jobs].[short_name]) as [job]
	--	,[jobs].[name] as [full_job]
	--	,[table].[seq_no]
	--	,[normal]
	--	,[normal_pcs]
	--	,[delay]
	--	,[delay_pcs]
	--	,[order_delay]
	--	,[order_delay_pcs]
	--	,[order_delay_hold]
	--	,[order_delay_hold_pcs]
	--	,[hold]
	--	,[hold_pcs]
	--	,[total]
	--	,[total_pcs]
	--	,[machine]
	--	,[machine_pcs]
	--	,[actual_result]
	--	,[actual_result_pcs]
	--	,[yesterday_result]
	--	,[yesterday_result_pcs]
	--	,[specialflow]
	--	,[specialflow_pcs]
	--	,[order_delay_special]
	--	,[order_delay_special_pcs]
	--from (
	--	select 'ALL' as [package]
	--		,IIF([job] like '%?%',REPLACE([job], N'?', N'･'),[job]) as [job]
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
	--		,SUM([specialflow]) as [specialflow]
	--		,SUM([specialflow_pcs])/1000 as [specialflow_pcs]
	--		,SUM([order_delay_special]) as [order_delay_special]
	--		,SUM([order_delay_special_pcs])/1000 as [order_delay_special_pcs]
	--	from [APCSProDWH].[cac].[wip_monitor_main] 
	--	where [date_value] = @date_value
	--	and [package_group] like @package_group
	--	and [package] like @package
	--	and [lot_type] like @lot_type
	--	group by [job],[seq_no],[process]
	--	union all
	--	select 'ALL' as [package]
	--		,'TOTAL' as [job]
	--		,'' as [process]
	--		,100000 as [seq_no]
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
	--		,SUM([specialflow]) as [specialflow]
	--		,SUM([specialflow_pcs])/1000 as [specialflow_pcs]
	--		,SUM([order_delay_special]) as [order_delay_special]
	--		,SUM([order_delay_special_pcs])/1000 as [order_delay_special_pcs]
	--	from [APCSProDWH].[cac].[wip_monitor_main] 
	--	where [date_value] = @date_value
	--	and [package_group] like @package_group
	--	and [package] like @package
	--	and [lot_type] like @lot_type
	--) as [table]
	--left join (
	--	select jobs.name,jobs.short_name,[processes].[name] as [process] from [APCSProDB].[method].[jobs]
	--	inner join [APCSProDB].[method].[processes] on [processes].[id] = [jobs].[process_id]
	--	group by jobs.name,jobs.short_name,[processes].[name]
	--) as [jobs] on [table].[job] = CAST([jobs].[name] AS VARCHAR(100))
	--	and [table].[process] = [jobs].[process]
	--order by [table].[package],[table].[seq_no]

	select *
	from (
		select 'ALL' as [package]
			, 'TOTAL' as [full_job]
			,'TOTAL' as [job]
			,'' as [process]
			,100000 as [seq_no]
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
			,SUM([specialflow]) as [specialflow]
			,SUM([specialflow_pcs])/1000 as [specialflow_pcs]
			,SUM([order_delay_special]) as [order_delay_special]
			,SUM([order_delay_special_pcs])/1000 as [order_delay_special_pcs]
		from [APCSProDWH].[cac].[wip_monitor_main] 
		where [date_value] = @date_value
			and [package_group] like @package_group
			and [package] like @package
			and [lot_type] like @lot_type
		union all
		select [package]
			--,[full_job]
			,[jobs].[name] as [full_job]
			,[jobs].[short_name] AS [job]
			,[process]
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
			,[specialflow]
			,[specialflow_pcs]
			,[order_delay_special]
			,[order_delay_special_pcs]
		from (
			select 'ALL' as [package]
				--,[jobs].[name] AS [full_job]
				,[wip_monitor_main].[job]
				,[process]
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
				,SUM([specialflow]) as [specialflow]
				,SUM([specialflow_pcs])/1000 as [specialflow_pcs]
				,SUM([order_delay_special]) as [order_delay_special]
				,SUM([order_delay_special_pcs])/1000 as [order_delay_special_pcs]
			from [APCSProDWH].[cac].[wip_monitor_main] 
			--left join [APCSProDB].[method].[jobs] ON [wip_monitor_main].[job] = CAST([jobs].[name] AS VARCHAR(100))
			where [date_value] = @date_value
			and [package_group] like @package_group
			and [package] like @package
			and [lot_type] like @lot_type
			group by [job],[wip_monitor_main].[seq_no],[process]--,[jobs].[name] --,[jobs].[id]
		) AS [table]
		outer apply (
			select top 1 [jobs].[short_name], [jobs].[name]
			from [APCSProDB].[method].[jobs] 
			where [jobs].[name] = [table].[job]
		) as [jobs]
	) as [table]
	order by [table].[package],[table].[seq_no];
END
