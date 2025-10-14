-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_ft_accumulate_resultNoneGDIC]
	-- Add the parameters for the stored procedure here
	@DateStart as Datetime,
	@DateEnd as Datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	select device.name as Devicename,SUM( lots.qty_in)  as Kpcs 
	from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
		inner join [APCSProDB].trans.lots as lots with (NOLOCK) on lots.id = lot_record.lot_id
		inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lots.act_device_name_id = device.id 
		inner join APCSProDB.method.packages as pk with (NOLOCK) on pk.id = device.package_id
		inner join APCSProDB.method.package_groups as pkg with (NOLOCK) on pkg.id = pk.package_group_id
	where lot_record.record_class = 2  
		and job_id = (SELECT top 1 (select top 1 job_id from APCSProDB.method.device_flows with (NOLOCK) 
				where step_no = MAX(dvflows.step_no)  and device_slip_id = dvslip.device_slip_id)
				FROM APCSProDB.method.device_names as dvname with (NOLOCK)
					INNER join APCSProDB.method.device_versions as dvVer with (NOLOCK) on dvVer.device_name_id = dvname.id
					INNER JOIN APCSProDB.method.device_slips as dvslip with (NOLOCK) on dvslip.device_id = dvVer.device_id
					INNER JOIN APCSProDB.method.device_flows as dvflows with (NOLOCK) on dvflows.device_slip_id = dvslip.device_slip_id
					INNER JOIN APCSProDB.method.jobs as job with (NOLOCK) on job.id = dvflows.job_id
					INNER JOIN APCSProDB.method.processes as process with (NOLOCK) on process.id = job.process_id
				WHERE process.id = 9 and job.name like 'AUTO%' and dvVer.version_num = dvslip.version_num 
					  and dvname.name = device.name
				GROUP BY dvname.name , dvslip.device_slip_id) 
		and lot_record.recorded_at between @DateStart and @DateEnd and pkg.id = 3
	group by device.name
	order by device.name
--------------------------------Old----------------------------------------------------------------------------
--	select device.name as Devicename,SUM( lots.qty_in)  as Kpcs
--from [APCSProDB].trans.lot_process_records as lot_record 
--inner join [APCSProDB].trans.lots as lots on lots.id = lot_record.lot_id
--inner join [APCSProDB] .[method].device_names as device on lots.act_device_name_id = device.id 
--where lot_record.record_class = 2  and job_id = 108 and lot_record.recorded_at between @DateStart and @DateEnd
--group by device.name
END

-----------------------------------------------------------------------------------------------------------------
