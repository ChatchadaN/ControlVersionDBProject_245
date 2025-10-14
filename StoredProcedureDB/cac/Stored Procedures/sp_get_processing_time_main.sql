-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_processing_time_main]
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
	DECLARE @seven_date_value varchar(10)


	IF((GETDATE() >= @rohm_date_start) AND (GETDATE() < @rohm_date_end))
	BEGIN
		SET @date_value = convert(varchar(10), GETDATE() - 1, 120)
		SET @seven_date_value = convert(varchar(10), GETDATE() - 7, 120)
	END
	ELSE
	BEGIN
		SET @date_value = convert(varchar(10), GETDATE(), 120)
		SET @seven_date_value = convert(varchar(10), GETDATE() - 6, 120)
	END

    -- Insert statements for procedure here
	select [job]
		, [date_value]
		, AVG([wip_time]) as [wip_time]
		, AVG([processing_time]) as [processing_time]
	from [APCSProDWH].[cac].[wip_monitor_main]
	where [package_group] like @package_group
	and [package] like @package
	and [lot_type] like @lot_type
	and [date_value] between @seven_date_value and @date_value
	group by [job], [date_value], [seq_no]
	order by [seq_no],[job],[date_value]
END
