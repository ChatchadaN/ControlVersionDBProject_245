-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_shipment_jit_rate]
	-- Add the parameters for the stored procedure here
	@unit int = 1
	, @package_group varchar(50) = '%'
	, @package varchar(50) = '%'
	, @lot_type varchar(50) = '%'
	, @year int = 2023
	, @month varchar(50) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    
	DECLARE @month_int INT
	IF (@month = '')
	BEGIN
		SET @month_int = MONTH(GETDATE());
	END
	ELSE BEGIN
		SET @month_int = MONTH('01-' + @month + '-' + CAST(YEAR(GETDATE()) AS VARCHAR));
	END

	-- Insert statements for procedure here
	IF(@unit = 1)
	BEGIN
		--select DATEPART(DAY,[date_value]) as [date_value]
		--	,(SUM([output_without_delay])*100.0)/SUM([today_output])*1.0 as [jit_rate]
		--	,(SUM([output_without_delay_pcs])*100.0)/SUM([today_output_pcs])*1.0 as [jit_rate_pcs]
		--from [APCSProDWH].[cac].[wip_transition_main] 
		--where [package_group] like @package_group
		--and [package] like @package
		--and [lot_type] like @lot_type
		--and [today_output] > 0
		--and [today_output_pcs] > 0
		--group by DATEPART(DAY,[date_value])
		--order by DATEPART(DAY,[date_value])

		select [day].[date_value]
			, isnull([data].[jit_rate],0) as [jit_rate]
			, isnull([data].[jit_rate_pcs],0) as [jit_rate_pcs]
		from (
			select DATEPART(DAY,[date_value]) as [date_value]
			from [APCSProDB].[trans].[days]
			where YEAR([date_value]) = @year
				and MONTH([date_value]) = @month_int
			group by DATEPART(DAY,[date_value])
		) as [day]
		left join (
			select DATEPART(DAY,[date_value]) as [date_value]
				,(SUM([output_without_delay])*100.0)/SUM([today_output])*1.0 as [jit_rate]
				,(SUM([output_without_delay_pcs])*100.0)/SUM([today_output_pcs])*1.0 as [jit_rate_pcs]
			from [APCSProDWH].[cac].[wip_transition_main] 
			where [package_group] like @package_group
			and [package] like @package
			and [lot_type] like @lot_type
			and [today_output] > 0
			and [today_output_pcs] > 0
			and YEAR([date_value]) = @year
			and MONTH([date_value]) = @month_int
			group by DATEPART(DAY,[date_value])
		) as [data] on [day].[date_value] = [data].[date_value]
		order by [day].[date_value]
	END
	IF(@unit = 2)
	BEGIN
		--select DATEPART(WEEK,[date_value]) as [date_value]
		--	,(SUM([output_without_delay])*100.0)/SUM([today_output])*1.0 as [jit_rate]
		--	,(SUM([output_without_delay_pcs])*100.0)/SUM([today_output_pcs])*1.0 as [jit_rate_pcs]
		--from [APCSProDWH].[cac].[wip_transition_main] 
		--where [package_group] like @package_group
		--and [package] like @package
		--and [lot_type] like @lot_type
		--and [today_output] > 0
		--and [today_output_pcs] > 0
		--group by DATEPART(WEEK,[date_value])
		--order by DATEPART(WEEK,[date_value])

		select [week].[date_value]
			, isnull([data].[jit_rate],0) as [jit_rate]
			, isnull([data].[jit_rate_pcs],0) as [jit_rate_pcs]
		from (
			select DATEPART(WEEK,[date_value]) as [date_value]
			from [APCSProDB].[trans].[days]
			where YEAR([date_value]) = @year
			group by DATEPART(WEEK,[date_value])
		) as [week]
		left join (
			select DATEPART(WEEK,[date_value]) as [date_value]
				,(SUM([output_without_delay])*100.0)/SUM([today_output])*1.0 as [jit_rate]
				,(SUM([output_without_delay_pcs])*100.0)/SUM([today_output_pcs])*1.0 as [jit_rate_pcs]
			from [APCSProDWH].[cac].[wip_transition_main] 
			where [package_group] like @package_group
			and [package] like @package
			and [lot_type] like @lot_type
			and [today_output] > 0
			and [today_output_pcs] > 0
			and YEAR([date_value]) = @year
			group by DATEPART(WEEK,[date_value])
		) as [data] on [week].[date_value] = [data].[date_value]
		order by [week].[date_value]
	END
	IF(@unit = 3)
	BEGIN
		--select DATEPART(MONTH,[date_value]) as [date_value]
		--	,convert(int,(SUM([output_without_delay])*100.0)/SUM([today_output]))*1.0 as [jit_rate]
		--	,convert(int,(SUM([output_without_delay_pcs])*100.0)/SUM([today_output_pcs]))*1.0 as [jit_rate_pcs]
		--from [APCSProDWH].[cac].[wip_transition_main] 
		--where [package_group] like @package_group
		--and [package] like @package
		--and [lot_type] like @lot_type
		--and [today_output] > 0
		--and [today_output_pcs] > 0
		--group by DATEPART(MONTH,[date_value])
		--order by DATEPART(MONTH,[date_value])

		select [month].[date_value]
			, isnull([data].[jit_rate],0) as [jit_rate]
			, isnull([data].[jit_rate_pcs],0) as [jit_rate_pcs]
		from (
			select DATEPART(MONTH,[date_value]) as [date_value]
			from [APCSProDB].[trans].[days]
			where YEAR([date_value]) = @year
			group by DATEPART(MONTH,[date_value])
		) as [month]
		left join (
			select DATEPART(MONTH,[date_value]) as [date_value]
				,convert(int,(SUM([output_without_delay])*100.0)/SUM([today_output]))*1.0 as [jit_rate]
				,convert(int,(SUM([output_without_delay_pcs])*100.0)/SUM([today_output_pcs]))*1.0 as [jit_rate_pcs]
			from [APCSProDWH].[cac].[wip_transition_main] 
			where [package_group] like @package_group
			and [package] like @package
			and [lot_type] like @lot_type
			and [today_output] > 0
			and [today_output_pcs] > 0
			and YEAR([date_value]) = @year
			group by DATEPART(MONTH,[date_value])
		) as [data] on [month].[date_value] = [data].[date_value]
		order by [month].[date_value]
	END
END
