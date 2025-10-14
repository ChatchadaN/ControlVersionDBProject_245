-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_kk_get_processrecords]
	@fromdate varchar(20),
	@todate varchar(20),
	@packageid int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select 
		r.lot_id
		,SUBSTRING(l.lot_no,5,1) as lot_type
		,l.lot_no 
		,o.order_no
		,pg.name as package_group
		,p.name as package
		,d.name as device
		,rs.recorded_at as lot_start
		,r.recorded_at as lot_end
		,datediff(minute,rs.recorded_at,r.recorded_at) as process_time
		,mc.name machine
		,rs.qty_pass as input_qty
		,r.qty_pass as pass_qty
		,pr.name as process
		,j.name as job
	from apcsprodb.method.packages as p 
		inner join APCSProDB.method.package_groups as pg 
			on pg.id = p.package_group_id 
		inner join apcsprodb.method.device_names as d 
			on d.package_id = p.id 
				and d.is_assy_only in(0,1)
		inner join apcsprodb.trans.lots as l 
			on l.act_device_name_id = d.id
		left outer join apcsprodb.robin.assy_orders as o 
			on o.id = l.order_id 

		inner join apcsprodb.trans.lot_process_records as r 
			on r.lot_id = l.id 
				and r.record_class in(2)
		inner join apcsprodb.mc.machines as mc 
			on mc.id = r.machine_id
		inner join apcsprodb.method.jobs as j 
			on j.id = r.job_id 
		left outer join APCSProDB.method.processes as pr 
			on pr.id = j.process_id
		inner join apcsprodb.trans.lot_process_records as rs 
			on rs.lot_id = r.lot_id 
				and rs.record_class in(1)
				and rs.job_id = r.job_id 
				and rs.machine_id = r.machine_id
				and rs.id < r.id
	where r.recorded_at >= @fromdate and r.recorded_at <= @todate
		and p.id = @packageid
	and r.record_class = 2
	--and l.act_package_id = 242
	order by r.id

END
