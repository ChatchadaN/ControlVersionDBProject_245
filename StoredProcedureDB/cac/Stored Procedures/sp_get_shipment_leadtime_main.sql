-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_shipment_leadtime_main]
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
    
	-- Insert statements for procedure here
	IF(@unit = 1)
	BEGIN

		select [date_value] as [date]
			,DATEPART(DAY,[date_value]) as [date_value]
			,MIN([leadtime_min_minute])/60/24.0 as [leadtime_min]
			,Max([leadtime_max_minute])/60/24.0 as [leadtime_max]
			,AVG([leadtime_avg_minute])/60/24.0 as [leadtime_avg]
		from [APCSProDWH].[cac].[wip_transition_main] 
		where [package_group] like @package_group
		and [package] like @package
		and [lot_type] like @lot_type
		and [date_value] >= dbx.dbo.CRohmDate(GETDATE()-30) 
		and [date_value] <= dbx.dbo.CRohmDate(GETDATE())
		group by DATEPART(DAY,[date_value]),[date_value]
		order by [date],[date_value]

		--select DATEPART(DAY,[date_value]) as [date_value]
		--	,AVG([leadtime_min_minute])/60/24.0 as [leadtime_min]
		--	,AVG([leadtime_max_minute])/60/24.0 as [leadtime_max]
		--	,AVG([leadtime_avg_minute])/60/24.0 as [leadtime_avg]
		--from [APCSProDWH].[cac].[wip_transition_main] 
		--where [package_group] like @package_group
		--and [package] like @package
		--and [lot_type] like @lot_type
		--group by DATEPART(DAY,[date_value])
		--order by DATEPART(DAY,[date_value])

	END
	IF(@unit = 2)
	BEGIN
		--select DATEPART(WEEK,[date_value]) as [date_value]
		--	,AVG([leadtime_min_minute])/60/24.0 as [leadtime_min]
		--	,AVG([leadtime_max_minute])/60/24.0 as [leadtime_max]
		--	,AVG([leadtime_avg_minute])/60/24.0 as [leadtime_avg]
		--from [APCSProDWH].[cac].[wip_transition_main] 
		--where [package_group] like @package_group
		--and [package] like @package
		--and [lot_type] like @lot_type
		--group by DATEPART(WEEK,[date_value])
		--order by DATEPART(WEEK,[date_value])
		select 
		 test.[year] as [year]
		,test.[week] as [date_value]
		,min([leadtime_min]) as [leadtime_min]
		,max(leadtime_max) as [leadtime_max]
		,AVG(leadtime_avg) as [leadtime_avg]
		from
		(
			select 
			DATEPART(year,[date_value]) as [year]
			,DATEPART(WEEK,[date_value]) as [week]
				,AVG([leadtime_min_minute])/60/24.0 as [leadtime_min]
				,AVG([leadtime_max_minute])/60/24.0 as [leadtime_max]
				,AVG([leadtime_avg_minute])/60/24.0 as [leadtime_avg]
			from [APCSProDWH].[cac].[wip_transition_main] 
			where [package_group] like @package_group
			and [package] like @package
			and [lot_type] like @lot_type
			group by DATEPART(WEEK,[date_value]),DATEPART(year,[date_value])
			--order by [year],[date_value]
		)as test
		group by [year],test.[week]
		order by [year],test.[week]
	END
	IF(@unit = 3)
	BEGIN
		--v1
		--select DATEPART(MONTH,[date_value]) as [date_value]
		--	,AVG([leadtime_min_minute])/60/24.0 as [leadtime_min]
		--	,AVG([leadtime_max_minute])/60/24.0 as [leadtime_max]
		--	,AVG([leadtime_avg_minute])/60/24.0 as [leadtime_avg]
		--from [APCSProDWH].[cac].[wip_transition_main] 
		--where [package_group] like @package_group
		--and [package] like @package
		--and [lot_type] like @lot_type
		--group by DATEPART(MONTH,[date_value])
		--order by DATEPART(MONTH,[date_value])

		--v2
		--select		
		--	DATEPART(year,[date_value]) as [year]
		--	,DATEPART(MONTH,[date_value]) as [date_value]
		--	,AVG([leadtime_min_minute])/60/24.0 as [leadtime_min]
		--	,AVG([leadtime_max_minute])/60/24.0 as [leadtime_max]
		--	,AVG([leadtime_avg_minute])/60/24.0 as [leadtime_avg]
		--from [APCSProDWH].[cac].[wip_transition_main] 
		--where [package_group] like @package_group
		--and [package] like @package
		--and [lot_type] like @lot_type
		--group by DATEPART(MONTH,[date_value]),DATEPART(year,[date_value])
		--order by [year],[date_value]

		--v3
		select 
		 test.year as [year]
		,test.MONTH as [date_value]
		,min([leadtime_min]) as [leadtime_min]
		,max(leadtime_max) as [leadtime_max]
		,AVG(leadtime_avg) as [leadtime_avg]
		from
		(
			select 
			DATEPART(year,[date_value]) as [year]
			,DATEPART(MONTH,[date_value]) as [MONTH]
			,DATEPART(WEEK,[date_value]) as [date_value]
				,AVG([leadtime_min_minute])/60/24.0 as [leadtime_min]
				,AVG([leadtime_max_minute])/60/24.0 as [leadtime_max]
				,AVG([leadtime_avg_minute])/60/24.0 as [leadtime_avg]
			from [APCSProDWH].[cac].[wip_transition_main] 
			where [package_group] like @package_group
			and [package] like @package
			and [lot_type] like @lot_type
			group by DATEPART(WEEK,[date_value])
			,DATEPART(year,[date_value])
			,DATEPART(MONTH,[date_value])	
		) as test
		group by [year],test.MONTH
		order by [year],test.MONTH

	END
END
