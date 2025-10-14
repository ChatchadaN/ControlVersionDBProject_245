-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_kk_get_factwip_package_group_v2]
	-- Add the parameters for the stored procedure here
	@fromdate1 varchar(20),
	@packagegroupid int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select 
	*
	from
	(
	select f.id
		,d.date_value
		,p.name as package
		,dv.name as device_name
		,a.name as assy_name 
		,f.lot_count
		,f.pcs
		,f.job_id
		,j.name as job
	from [APCSProDWH].[dwh].[fact_wip] as f 
		inner join [APCSProDWH].[dwh].[dim_days] as d 
			on d.id = f.day_id 
		inner join APCSProDWH.dwh.dim_packages as p 
			on p.id = f.package_id
		inner join APCSProDWH.dwh.dim_devices as dv 
			on dv.id = f.device_id
		inner join APCSProDWH.dwh.dim_assy_device_names as a
			on a.id = f.assy_name_id
		inner join APCSProDWH.dwh.dim_jobs as j 
			on j.id = f.job_id
	where d.date_value >= @fromdate1
		and f.package_group_id = @packagegroupid
		and f.hour_code >= 15 
		and not exists (select * from APCSProDWH.dwh.fact_wip as f2 
							where f2.day_id = f.day_id and f2.hour_code >=15 and f2.hour_code < f.hour_code)
	union all
select 
	dy.id as day_id
	,dy.date_value as date_value
	,t1.package
	,t1.device
	,t1.assy_name
	,count(t1.lot_id) as lot_count
	--,t1.lot_no
	--,t1.plan_date
	--,t1.in_date
	--,t1.in_at
	--,t1.in_date_id
	--,t1.in_plan_date_id
	,sum(t1.qty_in) as pcs
	,null as job_id
	,'PRE_DB' as job
from apcsprodb.trans.days as dy 
	left outer join 
		(
			select 
				p.id 
				,rtrim(p.name) as package
				,rtrim(d.name) as device
				,rtrim(d.assy_name) as assy_name
				,l.id as lot_id 
				,rtrim(l.lot_no) as lot_no
				,dy_plan.date_value as plan_date
				,dy_in.date_value as in_date
				,l.in_at
				,l.in_date_id
				,l.in_plan_date_id
				,l.qty_in
				--,sum(l.qty_in) over (partition by substring(d.name,1,2)) as dev_sum
			from apcsprodb.method.package_groups as pg 
				inner join apcsprodb.method.packages as p 
					on p.package_group_id = pg.id 
				inner join apcsprodb.method.device_names as d 
					on d.package_id = p.id 
						and d.is_assy_only in(0,1)
				inner join apcsprodb.trans.lots as l with (NOLOCK) 
					on l.act_device_name_id = d.id
				inner join apcsprodb.trans.days as dy_in 
					on dy_in.id = l.in_date_id
				inner join apcsprodb.trans.days as dy_plan 
					on dy_plan.id = l.in_plan_date_id
			where pg.id = @packagegroupid 
				and in_at > dateadd(hour,15,convert(datetime,dy_plan.date_value))
				and dy_plan.date_value > dateadd(MONTH,-1,@fromdate1)

				--and in_date_id >= in_plan_date_id
				--and in_at > dateadd(hour,15,'2020-01-05')
				--and dy_plan.date_value <= '2020-01-05'
				--order by p.id,l.id
		) as t1 
		on t1.in_plan_date_id <= dy.id 
			and t1.in_at > dateadd(hour,15,convert(datetime,dy.date_value))


--where dy.date_value between '2019-11-01' and '2020-01-29'
where dy.date_value between @fromdate1 and CONVERT(date,getdate())
group by
	dy.id
	,dy.date_value
	,t1.package
	,t1.device
	,t1.assy_name


	) as t2
	--where isnull(t2.job_id,0) in (0,25,65) and t2.package = 'SSOP-B20W'
	order by date_value,package,device_name



END
