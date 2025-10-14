-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wip_monitor_main_table]
	-- Add the parameters for the stored procedure here
	@unit int = 1
	, @package_group varchar(50) = '%'
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
	IF (@unit = 1)
	BEGIN
		select [master_data].[package_group]
			, [master_data].[pivot_status]
			, [master_data].[seq_no]
			, [setting_color].[color_code] as [color]
			, [master_data].[TOTAL]
			, [master_data].[DB]
			, [master_data].[Bari INSP.] as [BariINSP]
			, [master_data].[DBcure]
			, [master_data].[PLASMA1]
			, [master_data].[WB]
			, [master_data].[PLASMA2]
			, [master_data].[MP]
			, [master_data].[Aging]
			, [master_data].[TC] as [TC]
			, [master_data].[RF]
			, [master_data].[CD]
			, [master_data].[PL]
			, [master_data].[Bake]
			, [master_data].[Auto X-Ray] as [AutoXRay]
			, [master_data].[FL]
			, [master_data].[X-Ray After] as [XRayAfter]
			, [master_data].[Singulation]
			, [master_data].[FL Inspect] as [FLInspect]
			, [master_data].[FT]
			, [master_data].[FT Inspect] as [FTInspect]
			, [master_data].[QYI]
			, [master_data].[QA]
			, [master_data].[Aging In] as [AgingIn]
			, [master_data].[TP]
			, [master_data].[INSP. after TP] as [INSPAfterTP]
			, [master_data].[Aging after TP] as [AgingAfterTP]
			, [master_data].[O/G] as [OG]
			, [master_data].[Others]
		from
			(select *
			from
			(
				select package_group
				, process
				, pivot_status
				, pivot_counter
				, case
					when pivot_status = 'NORMAL' THEN '1'
					when pivot_status = 'DELAY' THEN '2'
					when pivot_status = 'ORDER DELAY' THEN '3'
					when pivot_status = 'ORDER DELAY HOLD' THEN '6'
					when pivot_status = 'TOTAL' THEN '5'
					when pivot_status = 'HOLD' THEN '4'
					when pivot_status = 'MACHINE' THEN '7'
					when pivot_status = 'ACTUAL RESULT' THEN '8'
					when pivot_status = 'YESTERDAY RESULT' THEN '9' END as seq_no
				from (select [package_group]
					,[process]
					,[job]
					,SUM([normal]) as [NORMAL]
					,SUM([delay]) as [DELAY]
					,SUM([order_delay]) as [ORDER DELAY]
					,SUM([order_delay_hold]) as [ORDER DELAY HOLD]
					,SUM([hold]) as [HOLD]
					,SUM([total]) as [TOTAL]
					,SUM([machine]) as [MACHINE]
					,SUM([actual_result]) as [ACTUAL RESULT]
					,SUM([yesterday_result]) as [YESTERDAY RESULT]
				from [APCSProDWH].[cac].[wip_monitor_main] 
				where [date_value] = @date_value
				and [package_group] like @package_group
				and [lot_type] like @lot_type
				group by [package_group],[process],[job]
				union all
				select [package_group]
					,'TOTAL' as [process]
					,'TOTAL' as [job]
					,SUM([normal]) as [NORMAL]
					,SUM([delay]) as [DELAY]
					,SUM([order_delay]) as [ORDER DELAY]
					,SUM([order_delay_hold]) as [ORDER DELAY HOLD]
					,SUM([hold]) as [HOLD]
					,SUM([total]) as [TOTAL]
					,SUM([machine]) as [MACHINE]
					,SUM([actual_result]) as [ACTUAL RESULT]
					,SUM([yesterday_result]) as [YESTERDAY RESULT]
				from [APCSProDWH].[cac].[wip_monitor_main] 
				where [date_value] = @date_value
				and [package_group] like @package_group
				and [lot_type] like @lot_type
				group by [package_group]
				union all
				select 'ALL' as [package_group]
					,[process]
					,[job]
					,SUM([normal]) as [NORMAL]
					,SUM([delay]) as [DELAY]
					,SUM([order_delay]) as [ORDER DELAY]
					,SUM([order_delay_hold]) as [ORDER DELAY HOLD]
					,SUM([hold]) as [HOLD]
					,SUM([total]) as [TOTAL]
					,SUM([machine]) as [MACHINE]
					,SUM([actual_result]) as [ACTUAL RESULT]
					,SUM([yesterday_result]) as [YESTERDAY RESULT]
				from [APCSProDWH].[cac].[wip_monitor_main] 
				where [date_value] = @date_value
				and [package_group] like @package_group
				and [lot_type] like @lot_type
				group by [process],[job]
				union all
				select 'ALL' as [package_group]
					,'TOTAL' as [process]
					,'TOTAL' as [job]
					,SUM([normal]) as [NORMAL]
					,SUM([delay]) as [DELAY]
					,SUM([order_delay]) as [ORDER DELAY]
					,SUM([order_delay_hold]) as [ORDER DELAY HOLD]
					,SUM([hold]) as [HOLD]
					,SUM([total]) as [TOTAL]
					,SUM([machine]) as [MACHINE]
					,SUM([actual_result]) as [ACTUAL RESULT]
					,SUM([yesterday_result]) as [YESTERDAY RESULT]
				from [APCSProDWH].[cac].[wip_monitor_main] 
				where [date_value] = @date_value
				and [package_group] like @package_group
				and [lot_type] like @lot_type
				) as Temp
				UNPIVOT
				(
					pivot_counter
					FOR pivot_status IN([NORMAL]
					, [DELAY]
					, [ORDER DELAY]
					, [ORDER DELAY HOLD]
					, [HOLD]
					, [TOTAL]
					, [MACHINE]
					, [ACTUAL RESULT]
					, [YESTERDAY RESULT]
					)
				) AS TempPivot
			) AS Temp 
			PIVOT
			(
				SUM([pivot_counter])
				FOR [process] IN([TOTAL]
				, [DB]
				, [Bari INSP.]
				, [DBcure]
				, [PLASMA1]
				, [WB]
				, [PLASMA2]
				, [MP]
				, [Aging]
				, [TC]
				, [RF]
				, [CD]
				, [PL]
				, [Bake]
				, [Auto X-Ray]
				, [FL]
				, [X-Ray After]
				, [Singulation]
				, [FL Inspect]
				, [FT]
				, [FT Inspect]
				, [QYI]
				, [QA]
				, [Aging In]
				, [TP]
				, [INSP. after TP]
				, [Aging after TP]
				, [O/G]
				, [Others]
				)
			) AS TempPivot
		) as [master_data]
		inner join [APCSProDWH].[cac].[setting_color] on [setting_color].[color_name] = [master_data].[pivot_status]
		order by package_group,seq_no
	END

	IF (@unit = 2)
	BEGIN
		select [master_data].[package_group]
			, [master_data].[pivot_status]
			, [master_data].[seq_no]
			, [setting_color].[color_code] as [color]
			, [master_data].[TOTAL]
			, [master_data].[DB]
			, [master_data].[Bari INSP.] as [BariINSP]
			, [master_data].[DBcure]
			, [master_data].[PLASMA1]
			, [master_data].[WB]
			, [master_data].[PLASMA2]
			, [master_data].[MP]
			, [master_data].[Aging]
			, [master_data].[TC] as [TC]
			, [master_data].[RF]
			, [master_data].[CD]
			, [master_data].[PL]
			, [master_data].[Bake]
			, [master_data].[Auto X-Ray] as [AutoXRay]
			, [master_data].[FL]
			, [master_data].[X-Ray After] as [XRayAfter]
			, [master_data].[Singulation]
			, [master_data].[FL Inspect] as [FLInspect]
			, [master_data].[FT]
			, [master_data].[FT Inspect] as [FTInspect]
			, [master_data].[QYI]
			, [master_data].[QA]
			, [master_data].[Aging In] as [AgingIn]
			, [master_data].[TP]
			, [master_data].[INSP. after TP] as [INSPAfterTP]
			, [master_data].[Aging after TP] as [AgingAfterTP]
			, [master_data].[O/G] as [OG]
			, [master_data].[Others]
		from
			(select *
			from
			(
				select package_group
				, process
				, pivot_status
				, pivot_counter
				, case
					when pivot_status = 'NORMAL' THEN '1'
					when pivot_status = 'DELAY' THEN '2'
					when pivot_status = 'ORDER DELAY' THEN '3'
					when pivot_status = 'ORDER DELAY HOLD' THEN '6'
					when pivot_status = 'TOTAL' THEN '5'
					when pivot_status = 'HOLD' THEN '4'
					when pivot_status = 'MACHINE' THEN '7'
					when pivot_status = 'ACTUAL RESULT' THEN '8'
					when pivot_status = 'YESTERDAY RESULT' THEN '9' END as seq_no
				from (select [package_group]
					,[process]
					,[job]
					,SUM([normal_pcs])/1000 as [NORMAL]
					,SUM([delay_pcs])/1000 as [DELAY]
					,SUM([order_delay_pcs])/1000 as [ORDER DELAY]
					,SUM([order_delay_hold_pcs])/1000 as [ORDER DELAY HOLD]
					,SUM([hold_pcs])/1000 as [HOLD]
					,SUM([total_pcs])/1000 as [TOTAL]
					,SUM([machine_pcs])/1000 as [MACHINE]
					,SUM([actual_result_pcs])/1000 as [ACTUAL RESULT]
					,SUM([yesterday_result_pcs])/1000 as [YESTERDAY RESULT]
				from [APCSProDWH].[cac].[wip_monitor_main] 
				where [date_value] = @date_value
				and [package_group] like @package_group
				and [lot_type] like @lot_type
				group by [package_group],[process],[job]
				union all
				select [package_group]
					,'TOTAL' as [process]
					,'TOTAL' as [job]
					,SUM([normal_pcs])/1000 as [NORMAL]
					,SUM([delay_pcs])/1000 as [DELAY]
					,SUM([order_delay_pcs])/1000 as [ORDER DELAY]
					,SUM([order_delay_hold_pcs])/1000 as [ORDER DELAY HOLD]
					,SUM([hold_pcs])/1000 as [HOLD]
					,SUM([total_pcs])/1000 as [TOTAL]
					,SUM([machine_pcs])/1000 as [MACHINE]
					,SUM([actual_result_pcs])/1000 as [ACTUAL RESULT]
					,SUM([yesterday_result_pcs])/1000 as [YESTERDAY RESULT]
				from [APCSProDWH].[cac].[wip_monitor_main] 
				where [date_value] = @date_value
				and [package_group] like @package_group
				and [lot_type] like @lot_type
				group by [package_group]
				union all
				select 'ALL' as [package_group]
					,[process]
					,[job]
					,SUM([normal_pcs])/1000 as [NORMAL]
					,SUM([delay_pcs])/1000 as [DELAY]
					,SUM([order_delay_pcs])/1000 as [ORDER DELAY]
					,SUM([order_delay_hold_pcs])/1000 as [ORDER DELAY HOLD]
					,SUM([hold_pcs])/1000 as [HOLD]
					,SUM([total_pcs])/1000 as [TOTAL]
					,SUM([machine_pcs])/1000 as [MACHINE]
					,SUM([actual_result_pcs])/1000 as [ACTUAL RESULT]
					,SUM([yesterday_result_pcs])/1000 as [YESTERDAY RESULT]
				from [APCSProDWH].[cac].[wip_monitor_main] 
				where [date_value] = @date_value
				and [package_group] like @package_group
				and [lot_type] like @lot_type
				group by [process],[job]
				union all
				select 'ALL' as [package_group]
					,'TOTAL' as [process]
					,'TOTAL' as [job]
					,SUM([normal_pcs])/1000 as [NORMAL]
					,SUM([delay_pcs])/1000 as [DELAY]
					,SUM([order_delay_pcs])/1000 as [ORDER DELAY]
					,SUM([order_delay_hold_pcs])/1000 as [ORDER DELAY HOLD]
					,SUM([hold_pcs])/1000 as [HOLD]
					,SUM([total_pcs])/1000 as [TOTAL]
					,SUM([machine_pcs])/1000 as [MACHINE]
					,SUM([actual_result_pcs])/1000 as [ACTUAL RESULT]
					,SUM([yesterday_result_pcs])/1000 as [YESTERDAY RESULT]
				from [APCSProDWH].[cac].[wip_monitor_main] 
				where [date_value] = @date_value
				and [package_group] like @package_group
				and [lot_type] like @lot_type
				) as Temp
				UNPIVOT
				(
					pivot_counter
					FOR pivot_status IN([NORMAL]
					, [DELAY]
					, [ORDER DELAY]
					, [ORDER DELAY HOLD]
					, [HOLD]
					, [TOTAL]
					, [MACHINE]
					, [ACTUAL RESULT]
					, [YESTERDAY RESULT]
					)
				) AS TempPivot
			) AS Temp 
			PIVOT
			(
				SUM([pivot_counter])
				FOR [process] IN([TOTAL]
				, [DB]
				, [Bari INSP.]
				, [DBcure]
				, [PLASMA1]
				, [WB]
				, [PLASMA2]
				, [MP]
				, [Aging]
				, [TC]
				, [RF]
				, [CD]
				, [PL]
				, [Bake]
				, [Auto X-Ray]
				, [FL]
				, [X-Ray After]
				, [Singulation]
				, [FL Inspect]
				, [FT]
				, [FT Inspect]
				, [QYI]
				, [QA]
				, [Aging In]
				, [TP]
				, [INSP. after TP]
				, [Aging after TP]
				, [O/G]
				, [Others]
				)
			) AS TempPivot
		) as [master_data]
		inner join [APCSProDWH].[cac].[setting_color] on [setting_color].[color_name] = [master_data].[pivot_status]
		order by package_group,seq_no
	END
END
