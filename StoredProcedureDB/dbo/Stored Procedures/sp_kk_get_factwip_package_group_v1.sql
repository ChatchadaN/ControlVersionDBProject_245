-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create PROCEDURE [dbo].[sp_kk_get_factwip_package_group_v1]
	-- Add the parameters for the stored procedure here
	@fromdate1 varchar(20),
	@packagegroupid int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
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
		and f.hour_code >= 10 
		and not exists (select * from APCSProDWH.dwh.fact_wip as f2 
							where f2.day_id = f.day_id and f2.hour_code >=10 and f2.hour_code < f.hour_code)
	order by id

END
