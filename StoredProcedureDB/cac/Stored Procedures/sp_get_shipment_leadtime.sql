-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_shipment_leadtime]
	-- Add the parameters for the stored procedure here
	@unit int = 1
	, @package_group varchar(50) = '%'
	, @package varchar(50) = '%'
	, @lot_type varchar(50) = '%'
	, @startdate date = null
	, @enddate date = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@startdate is null)
	BEGIN
		SET @startdate = convert(date,GETDATE())
	END
	IF(@enddate is null)
	BEGIN
		SET @enddate = convert(date,GETDATE())
	END
	IF(@unit = 1)
	BEGIN
		select [package]
			, [job]
			, [seq_no]
			, SUM([processing_time])/60/24 as [total_time]
			, '#ff9966' as [total_time_color]
		from [APCSProDWH].[cac].[wip_monitor_main]
		where [package_group] like @package_group
		and [package] like @package
		and [lot_type] like @lot_type
		and [date_value] between @startdate and @enddate
		group by [package], [job], [seq_no]
		UNION ALL
		select [package]
			, [job] + 'WIP' as [job]
			, [seq_no]
			, SUM([wip_time])/60/24 as [total_time]
			, '#d3d3d3' as [total_time_color]
		from [APCSProDWH].[cac].[wip_monitor_main]
		where [package_group] like @package_group
		and [package] like @package
		and [lot_type] like @lot_type
		and [date_value] between @startdate and @enddate
		group by [package], [job], [seq_no]
		order by [package], [seq_no],[job]
	END
	IF(@unit = 2)
	BEGIN
		select [package] as [package]
			, 'Process Time' as [job]
			, 'ALL' as [seq_no]
			, SUM([processing_time]) as [total_time]
			, '#ff9966' as [total_time_color]
		from [APCSProDWH].[cac].[wip_monitor_main]
		where [package_group] like @package_group
		and [package] like @package
		and [lot_type] like @lot_type
		and [date_value] between @startdate and @enddate
		group by [package]
		UNION ALL
		select [package] as [package]
			, 'WIP Time' as [job]
			, 'ALL' as [seq_no]
			, SUM([wip_time]) as [total_time]
			, '#d3d3d3' as [total_time_color]
		from [APCSProDWH].[cac].[wip_monitor_main]
		where [package_group] like @package_group
		and [package] like @package
		and [lot_type] like @lot_type
		and [date_value] between @startdate and @enddate
		group by [package]
	END
END
