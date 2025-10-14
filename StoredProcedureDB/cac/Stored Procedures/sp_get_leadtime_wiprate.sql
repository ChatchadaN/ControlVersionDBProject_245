-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_leadtime_wiprate]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	SET NOCOUNT ON;

	delete from [DBxDW].[dbo].[LeadTime_Test]

	insert into [DBxDW].[dbo].[LeadTime_Test]
	(
		[LeadTime_Test].PackageGroup
		,[LeadTime_Test].RohmWeek
		,[LeadTime_Test].RohmYear
		,[LeadTime_Test].AVGDay
		,[LeadTime_Test].AVGHour
		,[LeadTime_Test].AVGProcessHour
		,[LeadTime_Test].AVGWipDay
	)
	select PackageGroup, MAXRohmWeek,RohmYear
	, CAST(AVG(DaysOG) AS DECIMAL(10,2)) as AVGDay
	, CAST(SUM(DaysOG) AS DECIMAL(10,2)) as AVGHour
	, CAST(SUM(DayALL) AS DECIMAL(10,2)) as AVGProcessHour
	--, CAST(SUM(DaysOG)/NULLIF(SUM(DayALL), 0) AS DECIMAL(10,2)) as AVGWipDay
	, CAST(SUM(DaysOG)/ (case when  CAST(SUM(DayALL) AS DECIMAL(10,0)) = 0 Then 1 else SUM(DayALL) end) AS DECIMAL(10,2)) as AVGWipDay
	from(
		select 
		 test.id
		 ,test.lot_no
		 ,test.Package
		 ,test.Device
		 ,test.step_no
		 ,test.job
		 ,test.MachineName
		 ,case when test.PackageGroup = 'SOP' then 'SSOP'else test.PackageGroup end as [PackageGroup]
		 ,max(test.startdate) as startdate
		 ,max(test.enddate) as enddate
		 ,test.MINDate
		 ,test.MAXdate
		 ,test.DaysOG
		 ,DATEDIFF ( MINUTE , max(test.startdate) , max(test.enddate) )/60.0/24.0 as DayALL --Millisecond
		 ,test.RohmWeek
		 ,test.RohmYear
		 ,test.RohmMonth  
		 ,test.MAXRohmMonth
		 ,test.MAXRohmWeek
		 from
		 (select  
		 lots.id
		 ,lots.lot_no
		 ,[packages].[name] as Package 
		 ,[device_names].[name] as Device
		 ,[lot_process_records].step_no
		 ,[jobs].name as job
		 ,jobs.short_name
		 ,[machines].[name] as MachineName
		 ,[lot_process_records].[record_class]
		 ,LOTDate.MINDate as MINDate
		 ,LOTDate.MAXdate as MAXdate
		 --,[lot_process_records].recorded_at
		 ,case when [lot_process_records].[record_class] = 1 then recorded_at else null end as [startdate]
		 ,case when [lot_process_records].[record_class] = 2 then recorded_at else null end as [enddate]
		 ,case when [jobs].name = 'OUT GOING INSP' or  [jobs].name = 'O/G' THEN DATEDIFF ( MINUTE , MINDate , MAXDate )/60.0/24.0 ELSE NULL END as DaysOG
		 ,[package_groups].[name] as PackageGroup
		 , DATEPART(week, [lot_process_records].recorded_at) as RohmWeek
		 , DATEPART(MONTH, [lot_process_records].recorded_at) as RohmMonth
		 , DATEPART(YEAR, [lot_process_records].recorded_at) as RohmYear
		 , LOTDate.MAXRohmWeek
		 , LOTDate.MAXRohmMonth
		 from [APCSProDB].[trans].[lot_process_records]
		 inner join APCSProDB.trans.lots on lots.id = APCSProDB.trans.lot_process_records.lot_id
		 inner join [APCSProDB].[method].[packages] on [packages].[id] = [lots].[act_package_id] 
		 inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [lots].[act_device_name_id]
		 inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = device_names.alias_package_group_id
		 inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [lot_process_records].job_id
		 left join [APCSProDB].[mc].[machines] on [machines].[id] = lot_process_records.machine_id
		 --inner join [APCSProDB].[trans].[days] on [days].week_no = DATEPART(week, [lot_process_records].recorded_at)
		 inner join (
			select lots.id  
			,lots.lot_no
			,MIN([lot_process_records].recorded_at) as MINdate
			,MAX([lot_process_records].recorded_at) as MAXdate
			,DATEPART(week, MAX([lot_process_records].recorded_at)) as MAXRohmWeek
			,DATEPART(MONTH, MAX([lot_process_records].recorded_at)) as MAXRohmMonth
			from [APCSProDB].[trans].[lot_process_records]
			inner join APCSProDB.trans.lots on lots.id = APCSProDB.trans.lot_process_records.lot_id
			inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [lot_process_records].job_id
			where
			[lots].[lot_no] like '%A%'
			and jobs.short_name != 'DC'
			and record_class in ('1','2')
			group by lots.lot_no,lots.id) as LOTDate on LOTDate.id = [lot_process_records].lot_id

		where [lot_process_records].lot_id in (
			select [lot_process_records].lot_id
			from [APCSProDB].[trans].[lot_process_records]
			inner join APCSProDB.trans.lots on lots.id = APCSProDB.trans.lot_process_records.lot_id
			where 
			[lots].[lot_no] like '%A%'
			and lots.wip_state = 100
			and lots.finished_at >= '2020-01-01 00:00:00.000')

			and record_class in ('1','2')
			--and DATEPART(YEAR, [lot_process_records].recorded_at) between (year(getdate()) -1) AND (year(getdate()))
			) as test
			group by  test.id
		 ,test.lot_no
		 ,test.Package
		 ,test.Device
		 ,test.step_no
		 ,test.job
		 ,test.MachineName
		 ,test.PackageGroup
		 ,test.MINDate
		 ,test.MAXdate
		 ,test.DaysOG
		 ,test.RohmWeek
		 ,test.RohmYear
		 ,test.RohmMonth
		 ,test.MAXRohmMonth
		 ,test.MAXRohmWeek
		 --order by test.RohmYear asc,test.RohmWeek asc,test.PackageGroup desc
		 ) as [all]	
			--where (RohmYear >= (year(getdate()) -1) and MAXRohmWeek > 4) or (RohmYear >= year(getdate()) and MAXRohmWeek >= 1)
			group by [all].PackageGroup,[all].MAXRohmWeek,[all].RohmYear
			--order by [all].RohmYear asc,[all].MAXRohmWeek asc,[all].PackageGroup desc

	union all

	select 'TOTAL' as PackageGroup, MAXRohmWeek , RohmYear
	, CAST(AVG(DaysOG) AS DECIMAL(10,2)) as AVGDay
	, CAST(SUM(DaysOG) AS DECIMAL(10,2)) as AVGHour
	, CAST(SUM(DayALL) AS DECIMAL(10,2)) as AVGProcessHour
	--, CAST(SUM(DaysOG)/NULLIF(SUM(DayALL), 0) AS DECIMAL(10,2)) as AVGWipDay
	, CAST(SUM(DaysOG)/ (case when  CAST(SUM(DayALL) AS DECIMAL(10,0)) = 0 Then 1 else SUM(DayALL) end) AS DECIMAL(10,2)) as AVGWipDay
	from
	 (select 
	 test.id
	 ,test.lot_no
	 ,test.Package
	 ,test.Device
	 ,test.step_no
	 ,test.job
	 ,test.MachineName
	 ,max(test.startdate) as startdate
	 ,max(test.enddate) as enddate
	 ,test.MINDate
	 ,test.MAXdate
	 ,test.DaysOG
	 ,DATEDIFF ( MINUTE , max(test.startdate) , max(test.enddate) )/60.0/24.0 as DayALL
	 ,test.RohmWeek
	 ,test.RohmYear
	 ,test.RohmMonth  
	 ,test.MAXRohmMonth
	 ,test.MAXRohmWeek
	 from
	 (select  
	 lots.id
	 ,lots.lot_no
	 ,[packages].[name] as Package 
	 ,[device_names].[name] as Device
	 ,[lot_process_records].step_no
	 ,[jobs].name as job
	 ,jobs.short_name
	 ,[machines].[name] as MachineName
	 ,[lot_process_records].[record_class]
	 ,LOTDate.MINDate as MINDate
	 ,LOTDate.MAXdate as MAXdate
	 --,[lot_process_records].recorded_at
	 ,case when [lot_process_records].[record_class] = 1 then recorded_at else null end as [startdate]
	 ,case when [lot_process_records].[record_class] = 2 then recorded_at else null end as [enddate]
	 ,case when [jobs].name = 'OUT GOING INSP' or  [jobs].name = 'O/G' THEN DATEDIFF ( MINUTE , MINDate , MAXDate )/60.0/24.0 ELSE NULL END as DaysOG
	 ,[package_groups].[name] as PackageGroup
	 , DATEPART(week, [lot_process_records].recorded_at) as RohmWeek
	 , DATEPART(MONTH, [lot_process_records].recorded_at) as RohmMonth
	 , DATEPART(YEAR, [lot_process_records].recorded_at) as RohmYear
	 , LOTDate.MAXRohmWeek
	 , LOTDate.MAXRohmMonth
	 from [APCSProDB].[trans].[lot_process_records]
	 inner join APCSProDB.trans.lots on lots.id = APCSProDB.trans.lot_process_records.lot_id
	 inner join [APCSProDB].[method].[packages] on [packages].[id] = [lots].[act_package_id] 
	 inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [lots].[act_device_name_id]
	  inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = device_names.alias_package_group_id
	 inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [lot_process_records].job_id
	 left join [APCSProDB].[mc].[machines] on [machines].[id] = lot_process_records.machine_id
	 inner join (
		select lots.id  
		,lots.lot_no
		,MIN([lot_process_records].recorded_at) as MINdate
		,MAX([lot_process_records].recorded_at) as MAXdate
		,DATEPART(week, MAX([lot_process_records].recorded_at)) as MAXRohmWeek
		,DATEPART(MONTH, MAX([lot_process_records].recorded_at)) as MAXRohmMonth
		from [APCSProDB].[trans].[lot_process_records]
		inner join APCSProDB.trans.lots on lots.id = APCSProDB.trans.lot_process_records.lot_id
		inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [lot_process_records].job_id
		where
		[lots].[lot_no] like '%A%'
		and jobs.short_name != 'DC'
		and record_class in ('1','2')
		group by lots.lot_no,lots.id) as LOTDate on LOTDate.id = [lot_process_records].lot_id

	where [lot_process_records].lot_id in (
		select [lot_process_records].lot_id
		from [APCSProDB].[trans].[lot_process_records]
		inner join APCSProDB.trans.lots on lots.id = APCSProDB.trans.lot_process_records.lot_id
		where 
		[lots].[lot_no] like '%A%'
		and lots.wip_state = 100
		and lots.finished_at >= '2020-01-01 00:00:00.000')

		and record_class in ('1','2')
		--and DATEPART(YEAR, [lot_process_records].recorded_at) between (year(getdate()) -1) AND (year(getdate()))
		--order by lot_no
		) as test
		group by  test.id
	 ,test.lot_no
	 ,test.Package
	 ,test.Device
	 ,test.step_no
	 ,test.job
	 ,test.MachineName
	 ,test.PackageGroup
	 ,test.MINDate
	 ,test.MAXdate
	 ,test.DaysOG
	 ,test.RohmWeek
	 ,test.RohmMonth
	 ,test.RohmYear
	 ,test.MAXRohmMonth
	 ,test.MAXRohmWeek) as [all] 
	 --where (RohmYear >= (year(getdate()) -1) and MAXRohmWeek > 4) or (RohmYear >= year(getdate()) and MAXRohmWeek >= 1)
	 group by [all].MAXRohmWeek,[all].RohmYear
	 order by [all].RohmYear asc,[all].MAXRohmWeek asc,[all].PackageGroup desc
END
