-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_wip_monitor_process_table]
	-- Add the parameters for the stored procedure here
	@unit int = 1
	, @package_group varchar(50) = '%'
	, @package varchar(50) = '%'
	, @process varchar(50) = '%'
	, @color_status int = 1 -- 1:ALL, 2:WIP RATE, 3:Delay
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@color_status = 1)
	BEGIN
		IF(@unit = 1)
		BEGIN
			SELECT [wip_monitor_process].[package_group]
				, [wip_monitor_process].[package]
				, [wip_monitor_process].[job] as [process]
				--, [wip_monitor_process].[job]
				, [wip_monitor_process].[today_input]
				, [wip_monitor_process].[twoday_ago_wip]
				, [wip_monitor_process].[oneday_ago_wip]
				, [wip_monitor_process].[today_wip]
				, [wip_monitor_process].[twoday_ago_result]
				, [wip_monitor_process].[oneday_ago_result]
				, [wip_monitor_process].[today_result]
				, [wip_monitor_process].[wip_rate] as [wip_rate]
				, [wip_monitor_process].[progress_delay] as [progress]
				, [wip_monitor_process_table_detail].[problem_point]
				, [wip_monitor_process_table_detail].[action_item]
				, [wip_monitor_process_table_detail].[target]
				, [wip_monitor_process_table_detail].[incharge]
				, [wip_monitor_process_table_detail].[occure_date]
				, [wip_monitor_process_table_detail].[plan_date]
				, case when [wip_monitor_process].[wip_rate] > 1.5 then '#9400d3'
					when [wip_monitor_process].[progress_delay] > 30 then '#ffc0cb' else '' end as [package_color]
				, '' as [today_input_color] --'#CD5C5C'
				, case when [wip_monitor_process].[oneday_ago_wip] > [wip_monitor_process].[twoday_ago_wip] then '#CD5C5C'
					when [wip_monitor_process].[oneday_ago_wip] < [wip_monitor_process].[twoday_ago_wip] then '#8FBC8F' else '' end as [oneday_ago_wip_color]
				, case when [wip_monitor_process].[today_wip] > [wip_monitor_process].[oneday_ago_wip] then '#CD5C5C'
					when [wip_monitor_process].[today_wip] < [wip_monitor_process].[oneday_ago_wip] then '#8FBC8F' else '' end as [today_wip_color] /*#5CC75C*/
				, case when [wip_monitor_process].[wip_rate] > 1.5 then '#9400d3' else '' end as [over_capa_color]
				, case when [wip_monitor_process].[progress_delay] > 30 then '#ffc0cb' else '' end as [progress_color]
				, case when [wip_monitor_process].[today_wip] > [wip_monitor_process_table_detail].[target] then '#ff1493' else '' end as [target_color]
				, case when GETDATE() >= [wip_monitor_process_table_detail].[plan_date] then '#ff1493' else '' end as [plan_date_color]
			FROM [APCSProDWH].[cac].[wip_monitor_process]
			left join [APCSProDWH].[cac].[wip_monitor_process_table_detail] on [wip_monitor_process_table_detail].[package] = [wip_monitor_process].[package] and [wip_monitor_process_table_detail].[process] = [wip_monitor_process].[job]
			where ([wip_monitor_process].[wip_rate] > 1.5
				or [wip_monitor_process].[progress_delay] > 30)
			and [wip_monitor_process].[package_group] like @package_group
			and [wip_monitor_process].[package] like @package
			and [wip_monitor_process].[process] like @process
			and [wip_monitor_process].[process] not in('O/G')
		END
		ELSE
		BEGIN
			SELECT [wip_monitor_process].[package_group]
				, [wip_monitor_process].[package]
				, [wip_monitor_process].[job] as [process]
				--, [wip_monitor_process].[job]
				, [wip_monitor_process].[today_input_pcs]/1000 as [today_input]
				, [wip_monitor_process].[twoday_ago_wip_pcs]/1000 as [twoday_ago_wip]
				, [wip_monitor_process].[oneday_ago_wip_pcs]/1000 as [oneday_ago_wip]
				, [wip_monitor_process].[today_wip_pcs]/1000 as [today_wip]
				, [wip_monitor_process].[twoday_ago_result_pcs]/1000 as [twoday_ago_result]
				, [wip_monitor_process].[oneday_ago_result_pcs]/1000 as [oneday_ago_result]
				, [wip_monitor_process].[today_result_pcs]/1000 as [today_result]
				, [wip_monitor_process].[wip_rate_pcs] as [wip_rate]
				, [wip_monitor_process].[progress_delay_pcs] as [progress]
				, [wip_monitor_process_table_detail].[problem_point]
				, [wip_monitor_process_table_detail].[action_item]
				, [wip_monitor_process_table_detail].[target]
				, [wip_monitor_process_table_detail].[incharge]
				, [wip_monitor_process_table_detail].[occure_date]
				, [wip_monitor_process_table_detail].[plan_date]
				, case when [wip_monitor_process].[wip_rate_pcs] > 1.5 then '#9400d3'
					when [wip_monitor_process].[progress_delay_pcs] > 30 then '#ffc0cb' else '' end as [package_color]
				, '' as [today_input_color] --'#CD5C5C'
				, case when [wip_monitor_process].[oneday_ago_wip_pcs]/1000 > [wip_monitor_process].[twoday_ago_wip_pcs]/1000 then '#CD5C5C'
					when [wip_monitor_process].[oneday_ago_wip_pcs]/1000 < [wip_monitor_process].[twoday_ago_wip_pcs]/1000 then '#8FBC8F' else '' end as [oneday_ago_wip_color]
				, case when [wip_monitor_process].[today_wip_pcs]/1000 > [wip_monitor_process].[oneday_ago_wip_pcs]/1000 then '#CD5C5C'
					when [wip_monitor_process].[today_wip_pcs]/1000 < [wip_monitor_process].[oneday_ago_wip_pcs]/1000 then '#8FBC8F' else '' end as [today_wip_color] /*#5CC75C*/
				, case when [wip_monitor_process].[wip_rate_pcs] > 1.5 then '#9400d3' else '' end as [over_capa_color]
				, case when [wip_monitor_process].[progress_delay_pcs] > 30 then '#ffc0cb' else '' end as [progress_color]
				, case when [wip_monitor_process].[today_wip_pcs]/1000 > [wip_monitor_process_table_detail].[target] then '#ff1493' else '' end as [target_color]
				, case when GETDATE() >= [wip_monitor_process_table_detail].[plan_date] then '#ff1493' else '' end as [plan_date_color]
			FROM [APCSProDWH].[cac].[wip_monitor_process]
			left join [APCSProDWH].[cac].[wip_monitor_process_table_detail] on [wip_monitor_process_table_detail].[package] = [wip_monitor_process].[package] and [wip_monitor_process_table_detail].[process] = [wip_monitor_process].[job]
			where ([wip_monitor_process].[wip_rate_pcs] > 1.5
				or [wip_monitor_process].[progress_delay_pcs] > 30)
			and [wip_monitor_process].[package_group] like @package_group
			and [wip_monitor_process].[package] like @package
			and [wip_monitor_process].[process] like @process
			and [wip_monitor_process].[process] not in('O/G')
		END
	END
	IF(@color_status = 2)
	BEGIN
		IF(@unit = 1)
		BEGIN
			SELECT [wip_monitor_process].[package_group]
				, [wip_monitor_process].[package]
				, [wip_monitor_process].[job] as [process]
				--, [wip_monitor_process].[job]
				, [wip_monitor_process].[today_input]
				, [wip_monitor_process].[twoday_ago_wip]
				, [wip_monitor_process].[oneday_ago_wip]
				, [wip_monitor_process].[today_wip]
				, [wip_monitor_process].[twoday_ago_result]
				, [wip_monitor_process].[oneday_ago_result]
				, [wip_monitor_process].[today_result]
				, [wip_monitor_process].[wip_rate] as [wip_rate]
				, [wip_monitor_process].[progress_delay] as [progress]
				, [wip_monitor_process_table_detail].[problem_point]
				, [wip_monitor_process_table_detail].[action_item]
				, [wip_monitor_process_table_detail].[target]
				, [wip_monitor_process_table_detail].[incharge]
				, [wip_monitor_process_table_detail].[occure_date]
				, [wip_monitor_process_table_detail].[plan_date]
				, case when [wip_monitor_process].[wip_rate] > 1.5 then '#9400d3'
					when [wip_monitor_process].[progress_delay] > 30 then '#ffc0cb' else '' end as [package_color]
				, '' as [today_input_color] --'#CD5C5C'
				, case when [wip_monitor_process].[oneday_ago_wip] > [wip_monitor_process].[twoday_ago_wip] then '#CD5C5C'
					when [wip_monitor_process].[oneday_ago_wip] < [wip_monitor_process].[twoday_ago_wip] then '#8FBC8F' else '' end as [oneday_ago_wip_color]
				, case when [wip_monitor_process].[today_wip] > [wip_monitor_process].[oneday_ago_wip] then '#CD5C5C'
					when [wip_monitor_process].[today_wip] < [wip_monitor_process].[oneday_ago_wip] then '#8FBC8F' else '' end as [today_wip_color] /*#5CC75C*/
				, case when [wip_monitor_process].[wip_rate] > 1.5 then '#9400d3' else '' end as [over_capa_color]
				, case when [wip_monitor_process].[progress_delay] > 30 then '#ffc0cb' else '' end as [progress_color]
				, case when [wip_monitor_process].[today_wip] > [wip_monitor_process_table_detail].[target] then '#ff1493' else '' end as [target_color]
				, case when GETDATE() >= [wip_monitor_process_table_detail].[plan_date] then '#ff1493' else '' end as [plan_date_color]
			FROM [APCSProDWH].[cac].[wip_monitor_process]
			left join [APCSProDWH].[cac].[wip_monitor_process_table_detail] on [wip_monitor_process_table_detail].[package] = [wip_monitor_process].[package] and [wip_monitor_process_table_detail].[process] = [wip_monitor_process].[job]
			where ([wip_monitor_process].[wip_rate] > 1.5)
			and [wip_monitor_process].[package_group] like @package_group
			and [wip_monitor_process].[package] like @package
			and [wip_monitor_process].[process] like @process
			and [wip_monitor_process].[process] not in('O/G')
		END
		ELSE
		BEGIN
			SELECT [wip_monitor_process].[package_group]
				, [wip_monitor_process].[package]
				, [wip_monitor_process].[job] as [process]
				--, [wip_monitor_process].[job]
				, [wip_monitor_process].[today_input_pcs]/1000 as [today_input]
				, [wip_monitor_process].[twoday_ago_wip_pcs]/1000 as [twoday_ago_wip]
				, [wip_monitor_process].[oneday_ago_wip_pcs]/1000 as [oneday_ago_wip]
				, [wip_monitor_process].[today_wip_pcs]/1000 as [today_wip]
				, [wip_monitor_process].[twoday_ago_result_pcs]/1000 as [twoday_ago_result]
				, [wip_monitor_process].[oneday_ago_result_pcs]/1000 as [oneday_ago_result]
				, [wip_monitor_process].[today_result_pcs]/1000 as [today_result]
				, [wip_monitor_process].[wip_rate_pcs] as [wip_rate]
				, [wip_monitor_process].[progress_delay_pcs] as [progress]
				, [wip_monitor_process_table_detail].[problem_point]
				, [wip_monitor_process_table_detail].[action_item]
				, [wip_monitor_process_table_detail].[target]
				, [wip_monitor_process_table_detail].[incharge]
				, [wip_monitor_process_table_detail].[occure_date]
				, [wip_monitor_process_table_detail].[plan_date]
				, case when [wip_monitor_process].[wip_rate_pcs] > 1.5 then '#9400d3'
					when [wip_monitor_process].[progress_delay_pcs] > 30 then '#ffc0cb' else '' end as [package_color]
				, '' as [today_input_color] --'#CD5C5C'
				, case when [wip_monitor_process].[oneday_ago_wip_pcs]/1000 > [wip_monitor_process].[twoday_ago_wip_pcs]/1000 then '#CD5C5C'
					when [wip_monitor_process].[oneday_ago_wip_pcs]/1000 < [wip_monitor_process].[twoday_ago_wip_pcs]/1000 then '#8FBC8F' else '' end as [oneday_ago_wip_color]
				, case when [wip_monitor_process].[today_wip_pcs]/1000 > [wip_monitor_process].[oneday_ago_wip_pcs]/1000 then '#CD5C5C'
					when [wip_monitor_process].[today_wip_pcs]/1000 < [wip_monitor_process].[oneday_ago_wip_pcs]/1000 then '#8FBC8F' else '' end as [today_wip_color] /*#5CC75C*/
				, case when [wip_monitor_process].[wip_rate_pcs] > 1.5 then '#9400d3' else '' end as [over_capa_color]
				, case when [wip_monitor_process].[progress_delay_pcs] > 30 then '#ffc0cb' else '' end as [progress_color]
				, case when [wip_monitor_process].[today_wip_pcs]/1000 > [wip_monitor_process_table_detail].[target] then '#ff1493' else '' end as [target_color]
				, case when GETDATE() >= [wip_monitor_process_table_detail].[plan_date] then '#ff1493' else '' end as [plan_date_color]
			FROM [APCSProDWH].[cac].[wip_monitor_process]
			left join [APCSProDWH].[cac].[wip_monitor_process_table_detail] on [wip_monitor_process_table_detail].[package] = [wip_monitor_process].[package] and [wip_monitor_process_table_detail].[process] = [wip_monitor_process].[job]
			where ([wip_monitor_process].[wip_rate_pcs] > 1.5)
			and [wip_monitor_process].[package_group] like @package_group
			and [wip_monitor_process].[package] like @package
			and [wip_monitor_process].[process] like @process
			and [wip_monitor_process].[process] not in('O/G')
		END
	END
	IF(@color_status = 3)
	BEGIN
		IF(@unit = 1)
		BEGIN
			SELECT [wip_monitor_process].[package_group]
				, [wip_monitor_process].[package]
				, [wip_monitor_process].[job] as [process]
				--, [wip_monitor_process].[job]
				, [wip_monitor_process].[today_input]
				, [wip_monitor_process].[twoday_ago_wip]
				, [wip_monitor_process].[oneday_ago_wip]
				, [wip_monitor_process].[today_wip]
				, [wip_monitor_process].[twoday_ago_result]
				, [wip_monitor_process].[oneday_ago_result]
				, [wip_monitor_process].[today_result]
				, [wip_monitor_process].[wip_rate] as [wip_rate]
				, [wip_monitor_process].[progress_delay] as [progress]
				, [wip_monitor_process_table_detail].[problem_point]
				, [wip_monitor_process_table_detail].[action_item]
				, [wip_monitor_process_table_detail].[target]
				, [wip_monitor_process_table_detail].[incharge]
				, [wip_monitor_process_table_detail].[occure_date]
				, [wip_monitor_process_table_detail].[plan_date]
				, case when [wip_monitor_process].[wip_rate] > 1.5 then '#9400d3'
					when [wip_monitor_process].[progress_delay] > 30 then '#ffc0cb' else '' end as [package_color]
				, '' as [today_input_color] --'#CD5C5C'
				, case when [wip_monitor_process].[oneday_ago_wip] > [wip_monitor_process].[twoday_ago_wip] then '#CD5C5C'
					when [wip_monitor_process].[oneday_ago_wip] < [wip_monitor_process].[twoday_ago_wip] then '#8FBC8F' else '' end as [oneday_ago_wip_color]
				, case when [wip_monitor_process].[today_wip] > [wip_monitor_process].[oneday_ago_wip] then '#CD5C5C'
					when [wip_monitor_process].[today_wip] < [wip_monitor_process].[oneday_ago_wip] then '#8FBC8F' else '' end as [today_wip_color] /*#5CC75C*/
				, case when [wip_monitor_process].[wip_rate] > 1.5 then '#9400d3' else '' end as [over_capa_color]
				, case when [wip_monitor_process].[progress_delay] > 30 then '#ffc0cb' else '' end as [progress_color]
				, case when [wip_monitor_process].[today_wip] > [wip_monitor_process_table_detail].[target] then '#ff1493' else '' end as [target_color]
				, case when GETDATE() >= [wip_monitor_process_table_detail].[plan_date] then '#ff1493' else '' end as [plan_date_color]
			FROM [APCSProDWH].[cac].[wip_monitor_process]
			left join [APCSProDWH].[cac].[wip_monitor_process_table_detail] on [wip_monitor_process_table_detail].[package] = [wip_monitor_process].[package] and [wip_monitor_process_table_detail].[process] = [wip_monitor_process].[job]
			where ([wip_monitor_process].[progress_delay] > 30)
			and [wip_monitor_process].[package_group] like @package_group
			and [wip_monitor_process].[package] like @package
			and [wip_monitor_process].[process] like @process
			and [wip_monitor_process].[process] not in('O/G')
		END
		ELSE
		BEGIN
			SELECT [wip_monitor_process].[package_group]
				, [wip_monitor_process].[package]
				, [wip_monitor_process].[job] as [process]
				--, [wip_monitor_process].[job]
				, [wip_monitor_process].[today_input_pcs]/1000 as [today_input]
				, [wip_monitor_process].[twoday_ago_wip_pcs]/1000 as [twoday_ago_wip]
				, [wip_monitor_process].[oneday_ago_wip_pcs]/1000 as [oneday_ago_wip]
				, [wip_monitor_process].[today_wip_pcs]/1000 as [today_wip]
				, [wip_monitor_process].[twoday_ago_result_pcs]/1000 as [twoday_ago_result]
				, [wip_monitor_process].[oneday_ago_result_pcs]/1000 as [oneday_ago_result]
				, [wip_monitor_process].[today_result_pcs]/1000 as [today_result]
				, [wip_monitor_process].[wip_rate_pcs] as [wip_rate]
				, [wip_monitor_process].[progress_delay_pcs] as [progress]
				, [wip_monitor_process_table_detail].[problem_point]
				, [wip_monitor_process_table_detail].[action_item]
				, [wip_monitor_process_table_detail].[target]
				, [wip_monitor_process_table_detail].[incharge]
				, [wip_monitor_process_table_detail].[occure_date]
				, [wip_monitor_process_table_detail].[plan_date]
				, case when [wip_monitor_process].[wip_rate_pcs] > 1.5 then '#9400d3'
					when [wip_monitor_process].[progress_delay_pcs] > 30 then '#ffc0cb' else '' end as [package_color]
				, '' as [today_input_color] --'#CD5C5C'
				, case when [wip_monitor_process].[oneday_ago_wip_pcs]/1000 > [wip_monitor_process].[twoday_ago_wip_pcs]/1000 then '#CD5C5C'
					when [wip_monitor_process].[oneday_ago_wip_pcs]/1000 < [wip_monitor_process].[twoday_ago_wip_pcs]/1000 then '#8FBC8F' else '' end as [oneday_ago_wip_color]
				, case when [wip_monitor_process].[today_wip_pcs]/1000 > [wip_monitor_process].[oneday_ago_wip_pcs]/1000 then '#CD5C5C'
					when [wip_monitor_process].[today_wip_pcs]/1000 < [wip_monitor_process].[oneday_ago_wip_pcs]/1000 then '#8FBC8F' else '' end as [today_wip_color] /*#5CC75C*/
				, case when [wip_monitor_process].[wip_rate_pcs] > 1.5 then '#9400d3' else '' end as [over_capa_color]
				, case when [wip_monitor_process].[progress_delay_pcs] > 30 then '#ffc0cb' else '' end as [progress_color]
				, case when [wip_monitor_process].[today_wip_pcs]/1000 > [wip_monitor_process_table_detail].[target] then '#ff1493' else '' end as [target_color]
				, case when GETDATE() >= [wip_monitor_process_table_detail].[plan_date] then '#ff1493' else '' end as [plan_date_color]
			FROM [APCSProDWH].[cac].[wip_monitor_process]
			left join [APCSProDWH].[cac].[wip_monitor_process_table_detail] on [wip_monitor_process_table_detail].[package] = [wip_monitor_process].[package] and [wip_monitor_process_table_detail].[process] = [wip_monitor_process].[job]
			where ([wip_monitor_process].[progress_delay_pcs] > 30)
			and [wip_monitor_process].[package_group] like @package_group
			and [wip_monitor_process].[package] like @package
			and [wip_monitor_process].[process] like @process
			and [wip_monitor_process].[process] not in('O/G')
		END
	END
	--IF(@unit = 1)
	--BEGIN
	--	SELECT [wip_monitor_process].[package_group]
	--		, [wip_monitor_process].[package]
	--		, [wip_monitor_process].[job] as [process]
	--		--, [wip_monitor_process].[job]
	--		, [wip_monitor_process].[today_input]
	--		, [wip_monitor_process].[twoday_ago_wip]
	--		, [wip_monitor_process].[oneday_ago_wip]
	--		, [wip_monitor_process].[today_wip]
	--		, [wip_monitor_process].[twoday_ago_result]
	--		, [wip_monitor_process].[oneday_ago_result]
	--		, [wip_monitor_process].[today_result]
	--		, [wip_monitor_process].[wip_rate] as [wip_rate]
	--		, [wip_monitor_process].[progress_delay] as [progress]
	--		, [wip_monitor_process_table_detail].[problem_point]
	--		, [wip_monitor_process_table_detail].[action_item]
	--		, [wip_monitor_process_table_detail].[target]
	--		, [wip_monitor_process_table_detail].[incharge]
	--		, [wip_monitor_process_table_detail].[occure_date]
	--		, [wip_monitor_process_table_detail].[plan_date]
	--		, case when [wip_monitor_process].[wip_rate] > 1.5 then '#9400d3'
	--			when [wip_monitor_process].[progress_delay] > 30 then '#ffc0cb' else '' end as [package_color]
	--		, '' as [today_input_color] --'#CD5C5C'
	--		, case when [wip_monitor_process].[oneday_ago_wip] > [wip_monitor_process].[twoday_ago_wip] then '#CD5C5C'
	--			when [wip_monitor_process].[oneday_ago_wip] < [wip_monitor_process].[twoday_ago_wip] then '#8FBC8F' else '' end as [oneday_ago_wip_color]
	--		, case when [wip_monitor_process].[today_wip] > [wip_monitor_process].[oneday_ago_wip] then '#CD5C5C'
	--			when [wip_monitor_process].[today_wip] < [wip_monitor_process].[oneday_ago_wip] then '#8FBC8F' else '' end as [today_wip_color] /*#5CC75C*/
	--		, case when [wip_monitor_process].[wip_rate] > 1.5 then '#9400d3' else '' end as [over_capa_color]
	--		, case when [wip_monitor_process].[progress_delay] > 30 then '#ffc0cb' else '' end as [progress_color]
	--		, case when [wip_monitor_process].[today_wip] > [wip_monitor_process_table_detail].[target] then '#ff1493' else '' end as [target_color]
	--		, case when GETDATE() >= [wip_monitor_process_table_detail].[plan_date] then '#ff1493' else '' end as [plan_date_color]
	--	FROM [APCSProDWH].[cac].[wip_monitor_process]
	--	left join [APCSProDWH].[cac].[wip_monitor_process_table_detail] on [wip_monitor_process_table_detail].[package] = [wip_monitor_process].[package] and [wip_monitor_process_table_detail].[process] = [wip_monitor_process].[job]
	--	where ([wip_monitor_process].[wip_rate] > 1.5
	--		or [wip_monitor_process].[progress_delay] > 30)
	--	and [wip_monitor_process].[package_group] like @package_group
	--	and [wip_monitor_process].[package] like @package
	--	and [wip_monitor_process].[process] like @process
	--	and [wip_monitor_process].[process] not in('O/G')
	--END
	--ELSE
	--BEGIN
	--	SELECT [wip_monitor_process].[package_group]
	--		, [wip_monitor_process].[package]
	--		, [wip_monitor_process].[job] as [process]
	--		--, [wip_monitor_process].[job]
	--		, [wip_monitor_process].[today_input_pcs]/1000 as [today_input]
	--		, [wip_monitor_process].[twoday_ago_wip_pcs]/1000 as [twoday_ago_wip]
	--		, [wip_monitor_process].[oneday_ago_wip_pcs]/1000 as [oneday_ago_wip]
	--		, [wip_monitor_process].[today_wip_pcs]/1000 as [today_wip]
	--		, [wip_monitor_process].[twoday_ago_result_pcs]/1000 as [twoday_ago_result]
	--		, [wip_monitor_process].[oneday_ago_result_pcs]/1000 as [oneday_ago_result]
	--		, [wip_monitor_process].[today_result_pcs]/1000 as [today_result]
	--		, [wip_monitor_process].[wip_rate_pcs] as [wip_rate]
	--		, [wip_monitor_process].[progress_delay_pcs] as [progress]
	--		, [wip_monitor_process_table_detail].[problem_point]
	--		, [wip_monitor_process_table_detail].[action_item]
	--		, [wip_monitor_process_table_detail].[target]
	--		, [wip_monitor_process_table_detail].[incharge]
	--		, [wip_monitor_process_table_detail].[occure_date]
	--		, [wip_monitor_process_table_detail].[plan_date]
	--		, case when [wip_monitor_process].[wip_rate_pcs] > 1.5 then '#9400d3'
	--			when [wip_monitor_process].[progress_delay_pcs] > 30 then '#ffc0cb' else '' end as [package_color]
	--		, '' as [today_input_color] --'#CD5C5C'
	--		, case when [wip_monitor_process].[oneday_ago_wip_pcs]/1000 > [wip_monitor_process].[twoday_ago_wip_pcs]/1000 then '#CD5C5C'
	--			when [wip_monitor_process].[oneday_ago_wip_pcs]/1000 < [wip_monitor_process].[twoday_ago_wip_pcs]/1000 then '#8FBC8F' else '' end as [oneday_ago_wip_color]
	--		, case when [wip_monitor_process].[today_wip_pcs]/1000 > [wip_monitor_process].[oneday_ago_wip_pcs]/1000 then '#CD5C5C'
	--			when [wip_monitor_process].[today_wip_pcs]/1000 < [wip_monitor_process].[oneday_ago_wip_pcs]/1000 then '#8FBC8F' else '' end as [today_wip_color] /*#5CC75C*/
	--		, case when [wip_monitor_process].[wip_rate_pcs] > 1.5 then '#9400d3' else '' end as [over_capa_color]
	--		, case when [wip_monitor_process].[progress_delay_pcs] > 30 then '#ffc0cb' else '' end as [progress_color]
	--		, case when [wip_monitor_process].[today_wip_pcs]/1000 > [wip_monitor_process_table_detail].[target] then '#ff1493' else '' end as [target_color]
	--		, case when GETDATE() >= [wip_monitor_process_table_detail].[plan_date] then '#ff1493' else '' end as [plan_date_color]
	--	FROM [APCSProDWH].[cac].[wip_monitor_process]
	--	left join [APCSProDWH].[cac].[wip_monitor_process_table_detail] on [wip_monitor_process_table_detail].[package] = [wip_monitor_process].[package] and [wip_monitor_process_table_detail].[process] = [wip_monitor_process].[job]
	--	where ([wip_monitor_process].[wip_rate_pcs] > 1.5
	--		or [wip_monitor_process].[progress_delay_pcs] > 30)
	--	and [wip_monitor_process].[package_group] like @package_group
	--	and [wip_monitor_process].[package] like @package
	--	and [wip_monitor_process].[process] like @process
	--	and [wip_monitor_process].[process] not in('O/G')
	--END
END
