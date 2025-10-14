-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_testsum_wip_transition_all]
	-- Add the parameters for the stored procedure here
	@unit varchar(50) = 'Lots'
	,@lbGroup varchar(50) = '%'
	, @package varchar(50) = '%'
	, @lotType varchar(50) = '%'
	, @package_group varchar(50) = '%'
	, @lot_type varchar(50) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
--select [Type],convert(int,round(Accumulate,0)) as Accumulate,convert(int,round(case when [Type] = 'InputPlan' then 1 else Accumulate/
--(
--	select sum(case when @unit = 'Lots' then InputPlan else InputPlanKPcs end) as Accumulate from DBx.dbo.MasterPackage 
--	where PackageGroup like @lbGroup and Package like @package
--) end *100,0)) as AchievementRate
--from 
--(
--	select [Type],sum(Accumulate) as Accumulate from
--	(
--		select Package,'InputPlan' as [Type],case when @unit = 'Lots' then InputPlan else InputPlanKPcs end as Accumulate
--		from DBx.dbo.MasterPackage where PackageGroup like @lbGroup and Package like @package
--		union
--		(
--			select FORM_NAME as Package,'InputACT' as [Type],convert(int,round(sum(case when @unit = 'Lots' then 1 else PRD_PIECE/1000.0 end)/datepart(day,getdate())*datediff(day, DBx.dbo.CRohmDate(GETDATE()-1),DATEADD(month,1,GETDATE())),0)) as Accumulate 
--			from DBxDW.CAC.WIPTransition where [Type] = 'INPUT' and substring([DAY],1,5) = substring(convert(varchar,DBx.dbo.CRohmDate(GETDATE()),11),1,5) and [DAY] < convert(varchar,DBx.dbo.CRohmDate(GETDATE()),11) and LOT_NO LIKE '%' + @lotType + '%'
--			and PackageGroup like @lbGroup and FORM_NAME like @package and not(LOT_NO like '%F%')
--			group by FORM_NAME
--		)
--		union
--		(
--			select FORM_NAME as Package,'Shipment' as [Type],convert(int,round(sum(case when @unit = 'Lots' then 1 else PRD_PIECE/1000.0 end)/datepart(day,getdate())*datediff(day, DBx.dbo.CRohmDate(GETDATE()-1),DATEADD(month,1,GETDATE())),0)) as Accumulate 
--			from DBxDW.CAC.WIPTransition where [Type] = 'OUTPUT' and substring([DAY],1,5) = substring(convert(varchar,DBx.dbo.CRohmDate(GETDATE()),11),1,5) and [DAY] < convert(varchar,DBx.dbo.CRohmDate(GETDATE()),11) and LOT_NO LIKE '%' + @lotType + '%'
--			and PackageGroup like @lbGroup and FORM_NAME like @package and not(LOT_NO like'%F%')
--			group by FORM_NAME
--		)
--	) as a group by Type
--) as b order by case when [Type] = 'InputPlan' then 1 when [Type] = 'InputACT' then 2 when [Type] = 'Shipment' then 3 end asc

--2020/08/10
--select [type]
-- ,convert(int,round(accumulate,0)) as accumulate
-- ,convert(int,round(convert(float,accumulate)/(select convert(float,sum([setting_input_plan].[input_plan_per_day_pcs] )) as accumulate 
-- from [APCSProDWH].[cac].[setting_input_plan] 
-- inner join [APCSProDB].[method].[packages] on [packages].name = [setting_input_plan].[package]
-- inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id]
-- where [plan_start_date] >= CONVERT(date,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))
-- and [plan_start_date]  < CONVERT(date,getdate())
-- and [APCSProDWH].[cac].[setting_input_plan].package like @package
-- and [package_groups].name like @package_group)  *100,0)) as achievement_rate


--2024/05/29
--select*
-- from
--(
--	select [type],sum(accumulate) as accumulate from
--	(	
--		SELECT [package_groups].[name] as package_group,[package],'InputPlan' as [type]
--		--,sum([setting_input_plan].[input_plan_per_day_pcs]) as accumulate
--		,convert(int,round((SUM([setting_input_plan].[input_plan_per_day_pcs])/datepart(day,getdate()))*datediff(day, CONVERT(DATE, GETDATE()-1),DATEADD(month,1,GETDATE())),0)) as accumulate
--		FROM [APCSProDWH].[cac].[setting_input_plan]
--		inner join [APCSProDB].[method].[packages] on [packages].name = [setting_input_plan].[package]
--		inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id]
--		where [plan_start_date] >= CONVERT(date, DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0)) 
--		and [plan_start_date]  < CONVERT(date,getdate())
--		and [APCSProDWH].[cac].[setting_input_plan].package like @package 
--		and [package_groups].name like @package_group
--		group by package,[package_groups].[name]
		
--		union
--		(
--			select [package_groups].[name] as package_group,[packages].[name] as package,'InputACT' as [type]
--			,convert(int,round((SUM(lots.qty_in)/datepart(day,getdate()))*datediff(day, CONVERT(DATE, GETDATE()-1),DATEADD(month,1,GETDATE())),0)) as accumulate
--			from APCSProDB.trans.lots
--			inner join [APCSProDB].[trans].[days] on [APCSProDB].[trans].[days].id = [APCSProDB].[trans].[lots].in_date_id
--			--inner join [APCSProDB].[trans].[lot_multi_chips] on [APCSProDB].[trans].[lot_multi_chips].child_lot_id <> [APCSProDB].[trans].lots.id
--			inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
--			inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
--			inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
--			inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]			
--			inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id]
--			where
--			 [APCSProDB].[trans].[days].[date_value] >= CONVERT(date,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))
--			and [APCSProDB].[trans].[days].[date_value] <= CONVERT(date,getdate())
--			and [APCSProDB].[method].[packages].name like @package
--			and [APCSProDB].[method].[package_groups].name like @package_group
--			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
--			group by packages.name,[package_groups].[name]
--		)

--		union
--		(
--			select [package_groups].[name] as package_group,[packages].name as package,'Shipment' as [type],convert(int,round((SUM(lots.qty_in)/datepart(day,getdate()))*datediff(day, CONVERT(DATE, GETDATE()-1),DATEADD(month,1,GETDATE())),0)) as accumulate
--			from [APCSProDB].trans.lot_process_records 
--			inner join [APCSProDB].[trans].[lots] as lots on [lots].id = [lot_process_records].lot_id
--			inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
--			inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
--			inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
--			inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
--			inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id]
--			where lot_process_records.[recorded_at] >= DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0) 
--			and lot_process_records.[recorded_at] <= getdate()
--			and lot_process_records.record_class = 2 
--			and job_id in (151,317) 
--			and lots.wip_state = 100
--			and [APCSProDB].[method].[packages].name like @package
--			and [APCSProDB].[method].[package_groups].name like @package_group
--			and SUBSTRING([lots].[lot_no],5,1) like @lot_type
--			group by packages.name,[package_groups].[name]
--		)		
--	) as a group by [type]
--) as b order by case when [type] = 'InputPlan' then 1 when [type] = 'InputACT' then 2 when [type] = 'Shipment' then 3 end asc
	
	IF (@lbGroup = 'SSOP')
	BEGIN
		SET @lbGroup = 'SOP'
	END

	SELECT [type]
		, SUM([accumulate]) AS [accumulate]
	FROM (
		/* ------------------------------------------------------------------------------ */
		SELECT 1 AS [type_id]
			, 'InputPlan' AS [type]
			, CAST(ROUND (
				/* 1 */ 
					( SUM( [setting_input_plan].[input_plan_per_day_pcs] ) / 
						/* start_datepart */ DATEPART(DAY, GETDATE()) /* end_datepart */
					) 
				/* 1 */ * 
				/* 2 */  
				/* start_datediff */ 
					DATEDIFF(
						/* interval */ DAY /* interval */, 
						/* start_date */ CONVERT(DATE, GETDATE() - 1) /* start_date */, 
						/* end_date */ DATEADD(MONTH, 1, GETDATE()) /* end_date */
					)
				 /* end_datediff */
				 /* 2 */
				, 0) AS INT
			) AS [accumulate]
		FROM [APCSProDWH].[cac].[setting_input_plan] WITH (NOLOCK)
		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[name] = [setting_input_plan].[package]
		INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		WHERE [plan_start_date] >= CAST(DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) AS DATE) 
			AND [plan_start_date] < CAST(GETDATE() AS DATE)
			AND [package_groups].[name] LIKE @lbGroup
			AND [setting_input_plan].[package] LIKE @package
		GROUP BY [package_groups].[name]
		UNION
		SELECT 1 AS [type_id]
			, 'InputPlan' AS [type]
			, 0 AS [accumulate]
		/* ------------------------------------------------------------------------------ */
		UNION
		/* ------------------------------------------------------------------------------ */
		SELECT 2 AS [type_id]
			, 'InputACT' AS [type]
			, CAST(ROUND (
				/* 1 */ 
					( SUM( [lots].[qty_in] ) / 
						/* start_datepart */ DATEPART(DAY, GETDATE()) /* end_datepart */
					) 
				/* 1 */ * 
				/* 2 */  
				/* start_datediff */ 
					DATEDIFF(
						/* interval */ DAY /* interval */, 
						/* start_date */ CONVERT(DATE, GETDATE() - 1) /* start_date */, 
						/* end_date */ DATEADD(MONTH, 1, GETDATE()) /* end_date */
					)
				 /* end_datediff */
				 /* 2 */
				, 0) AS INT
			) AS [accumulate]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		INNER JOIN [APCSProDB].[trans].[days] WITH (NOLOCK) ON [days].[id] = [lots].[in_date_id]
		INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [lots].[act_device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		WHERE ( [days].[date_value] BETWEEN DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) AND GETDATE() ) 
			AND [package_groups].[name] LIKE @lbGroup
			AND [packages].[name] LIKE @package
		GROUP BY [package_groups].[name]
		UNION
		SELECT 2 AS [type_id]
			, 'InputACT' AS [type]
			, 0 AS [accumulate]
		/* ------------------------------------------------------------------------------ */
		UNION
		/* ------------------------------------------------------------------------------ */
		SELECT 3 AS [type_id]
			, 'Shipment' AS [type]
			, CAST(ROUND (
				/* 1 */ 
					( SUM( [lots].[qty_in] ) / 
						/* start_datepart */ DATEPART(DAY, GETDATE()) /* end_datepart */
					) 
				/* 1 */ * 
				/* 2 */  
				/* start_datediff */ 
					DATEDIFF(
						/* interval */ DAY /* interval */, 
						/* start_date */ CONVERT(DATE, GETDATE() - 1) /* start_date */, 
						/* end_date */ DATEADD(MONTH, 1, GETDATE()) /* end_date */
					)
				 /* end_datediff */
				 /* 2 */
				, 0) AS INT
			) AS [accumulate]
		FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK)
		INNER JOIN [APCSProDB].[trans].[lots] WITH (NOLOCK) ON [lots].[id] = [lot_process_records].[lot_id]
		INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [lots].[act_device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups] WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		WHERE ( [lot_process_records].[recorded_at] BETWEEN DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0) AND GETDATE() ) 
			AND [lot_process_records].[record_class] = 2 
			AND [job_id] IN (151,317) 
			AND [lots].[wip_state] = 100
			AND [package_groups].[name] LIKE @lbGroup
			AND [packages].[name] LIKE @package
		GROUP BY [package_groups].[name]
		UNION
		SELECT 3 AS [type_id]
			, 'Shipment' AS [type]
			, 0 AS [accumulate]
		/* ------------------------------------------------------------------------------ */
	) AS [a]
	GROUP BY [type_id], [type]
	ORDER BY [type_id] ASC;
END
