-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_kk_get_factend]
	-- Add the parameters for the stored procedure here
	@fromdate varchar(20),
	@todate varchar(20),
	@packageid int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select 
	e.lot_id
	,l.lot_no 
	,o.order_no
	,pg.name as package_group
	,p.name as package
	,d.name as device
	,e.started_at 
	,DATEADD(minute,e.process_time,e.started_at) as finished_at
	,e.process_time 
	,mc.name machine
	,e.input_pcs
	,e.pass_pcs
	,pr.name as process
	,j.name as job
from APCSProDWH.dwh.dim_days as dy 
	inner join apcsprodwh.dwh.fact_end as e 
		on e.day_id = dy.id 
	inner join apcsprodb.trans.lots as l 
		on l.id = e.lot_id 
	inner join apcsprodb.robin.assy_orders as o 
		on o.id = l.order_id 
	inner join apcsprodb.method.packages as p 
		on p.id = l.act_package_id 
	inner join APCSProDB.method.package_groups as pg 
		on pg.id = p.package_group_id 
	inner join APCSProDB.method.device_names as d 
		on d.id = l.act_device_name_id
	inner join apcsprodb.mc.machines as mc 
		on mc.id = e.machine_id
	inner join apcsprodb.method.jobs as j 
		on j.id = e.job_id 
	left outer join APCSProDB.method.processes as pr 
		on pr.id = j.process_id
where dy.date_value >= @fromdate and dy.date_value <= @todate
	and e.package_id = @packageid
	--and mc.name = 'QA-Analy-01'
END
