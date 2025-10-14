-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wip_monitor_package_group_table]
	-- Add the parameters for the stored procedure here
	@unit int = 1
	, @package_group varchar(50) = '%'
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
	IF (@unit = 1)
	BEGIN
		select [TempPivot].[package]
			, [TempPivot].[pivot_status]
			, [TempPivot].[seq_no]
			, [TempPivot].[color]
			, [TempPivot].[TOTAL]
			, [TempPivot].[DB]
			, [TempPivot].[Bari INSP.] as [BariINSP]
			, [TempPivot].[DBcure]
			, [TempPivot].[PLASMA1]
			, [TempPivot].[WB]
			, [TempPivot].[PLASMA2]
			, [TempPivot].[MP]
			, [TempPivot].[Aging]
			--, [TempPivot].[T/C] as [TC]
			, [TempPivot].[TC] as [TC]
			, [TempPivot].[RF]
			, [TempPivot].[CD]
			, [TempPivot].[PL]
			, [TempPivot].[Bake]
			, [TempPivot].[Auto X-Ray] as [AutoXRay]
			, [TempPivot].[FL]
			, [TempPivot].[X-Ray After] as [XRayAfter]
			, [TempPivot].[Singulation]
			, [TempPivot].[FL Inspect] as [FLInspect]
			, [TempPivot].[FT]
			, [TempPivot].[FT Inspect] as [FTInspect]
			, [TempPivot].[QYI]
			, [TempPivot].[QA]
			, [TempPivot].[Aging In] as [AgingIn]
			, [TempPivot].[TP]
			, [TempPivot].[INSP. after TP] as [INSPAfterTP]
			, [TempPivot].[Aging after TP] as [AgingAfterTP]
			, [TempPivot].[O/G] as [OG]
			, [TempPivot].[Others]
		from
		(
			select package
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
			, case
				when pivot_status = 'NORMAL' THEN '#ADD8E6'
				when pivot_status = 'DELAY' THEN '#FFC0CB'
				when pivot_status = 'ORDER DELAY' THEN '#c4adc4'
				when pivot_status = 'ORDER DELAY HOLD' THEN '#c4adc4'
				when pivot_status = 'TOTAL' THEN '#d3d3d3'
				when pivot_status = 'HOLD' THEN '#ff9966'
				when pivot_status = 'MACHINE' THEN '#4169e1'
				when pivot_status = 'ACTUAL RESULT' THEN '#CD5C5C'
				when pivot_status = 'YESTERDAY RESULT' THEN '#20b2aa' END as color
			from (select [package]
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
			and [package] like @package
			and [lot_type] like @lot_type
			group by [package],[process],[job]
			union all
			select [package]
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
			and [package] like @package
			and [lot_type] like @lot_type
			group by [package]
			union all
			select 'ALL' as [package]
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
			and [package] like @package
			and [lot_type] like @lot_type
			group by [process],[job]
			union all
			select 'ALL' as [package]
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
			and [package] like @package
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
			--, [T/C]
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
		order by package,seq_no
	END

	IF (@unit = 2)
	BEGIN
		select [TempPivot].[package]
			, [TempPivot].[pivot_status]
			, [TempPivot].[seq_no]
			, [TempPivot].[color]
			, [TempPivot].[TOTAL]
			, [TempPivot].[DB]
			, [TempPivot].[Bari INSP.] as [BariINSP]
			, [TempPivot].[DBcure]
			, [TempPivot].[PLASMA1]
			, [TempPivot].[WB]
			, [TempPivot].[PLASMA2]
			, [TempPivot].[MP]
			, [TempPivot].[Aging]
			--, [TempPivot].[T/C] as [TC]
			, [TempPivot].[TC] as [TC]
			, [TempPivot].[RF]
			, [TempPivot].[CD]
			, [TempPivot].[PL]
			, [TempPivot].[Bake]
			, [TempPivot].[Auto X-Ray] as [AutoXRay]
			, [TempPivot].[FL]
			, [TempPivot].[X-Ray After] as [XRayAfter]
			, [TempPivot].[Singulation]
			, [TempPivot].[FL Inspect] as [FLInspect]
			, [TempPivot].[FT]
			, [TempPivot].[FT Inspect] as [FTInspect]
			, [TempPivot].[QYI]
			, [TempPivot].[QA]
			, [TempPivot].[Aging In] as [AgingIn]
			, [TempPivot].[TP]
			, [TempPivot].[INSP. after TP] as [INSPAfterTP]
			, [TempPivot].[Aging after TP] as [AgingAfterTP]
			, [TempPivot].[O/G] as [OG]
			, [TempPivot].[Others]
		from
		(
			select package
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
			, case
				when pivot_status = 'NORMAL' THEN '#ADD8E6'
				when pivot_status = 'DELAY' THEN '#FFC0CB'
				when pivot_status = 'ORDER DELAY' THEN '#c4adc4'
				when pivot_status = 'ORDER DELAY HOLD' THEN '#c4adc4'
				when pivot_status = 'TOTAL' THEN '#d3d3d3'
				when pivot_status = 'HOLD' THEN '#ff9966'
				when pivot_status = 'MACHINE' THEN '#4169e1'
				when pivot_status = 'ACTUAL RESULT' THEN '#CD5C5C'
				when pivot_status = 'YESTERDAY RESULT' THEN '#20b2aa' END as color
			from (select [package]
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
			and [package] like @package
			and [lot_type] like @lot_type
			group by [package],[process],[job]
			union all
			select [package]
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
			and [package] like @package
			and [lot_type] like @lot_type
			group by [package]
			union all
			select 'ALL' as [package]
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
			and [package] like @package
			and [lot_type] like @lot_type
			group by [process],[job]
			union all
			select 'ALL' as [package]
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
			and [package] like @package
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
			--, [T/C]
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
		order by package,seq_no
	END
END
