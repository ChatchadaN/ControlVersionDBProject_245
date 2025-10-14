-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_tp_accumulate] 
	-- Add the parameters for the stored procedure here
	@ResultDateStart as Datetime,
	@ResultDateEnd as Datetime,
	@PlanDateStart as datetime,
	@PlanDateEnd as Datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	delete from DBx.dbo.scheduler_tp_qa_accumulate
	insert into DBx.dbo.scheduler_tp_qa_accumulate 
	([pkgname]
	,[devicename]
	,[input]
	,[output]
	,[summary])
	select result.name as pkgname, result.Devicename as devicename , input.Kpcs as input , result.Kpcs as [output], result.Kpcs-input.Kpcs as summary
	from(select pk.name, device.name as Devicename,SUM( lots.qty_in)  as Kpcs
			from [APCSProDB].trans.lot_process_records as lot_record 
			inner join [APCSProDB].trans.lots as lots on lots.id = lot_record.lot_id
			inner join [APCSProDB] .[method].device_names as device on lots.act_device_name_id = device.id 
			inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = device.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join APCSProDB.method.packages as PK on PK.id = lots.act_package_id
		where lot_record.record_class = 2  and job_id in (236,289)  and lots.act_package_id in (235,242,246)
			and lot_record.recorded_at between @ResultDateStart and @ResultDateEnd
		group by device.name ,pk.name) as result 

	inner join 

		(SELECT  device.name as Devicename,sum(lots.qty_in) as Kpcs
			FROM [APCSProDB].[trans].lots as lots 
			inner join [APCSProDB] .[method].device_names as device on lots.act_device_name_id = device.id 
			inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = device.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].[trans].[days] as days on days.id = lots.in_date_id
			where lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips) 
				and days.date_value between @PlanDateStart  and @PlanDateEnd 
			group by device.name , device.ft_name) as input on input.Devicename = result.Devicename
UNION ALL 
select result.name as pkgname, result.Devicename as devicename , input.Kpcs as input , result.Kpcs as [output], result.Kpcs-input.Kpcs as summary
	from(select pk.name, device.name as Devicename,SUM( lots.qty_in)  as Kpcs
			from [APCSProDB].trans.lot_process_records as lot_record 
			inner join [APCSProDB].trans.lots as lots on lots.id = lot_record.lot_id
			inner join [APCSProDB] .[method].device_names as device on lots.act_device_name_id = device.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = device.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join APCSProDB.method.packages as PK on PK.id = lots.act_package_id
		where lot_record.record_class = 2  and job_id in (236,289)  and lots.act_package_id in (242)
			and lot_record.recorded_at between @ResultDateStart and @ResultDateEnd
		group by device.name ,pk.name) as result 

	inner join 

		(SELECT  device.name as Devicename,sum(lots.qty_in) as Kpcs
			FROM [APCSProDB].[trans].lots as lots 
			inner join [APCSProDB] .[method].device_names as device on lots.act_device_name_id = device.id 
			--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = device.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
			inner join [APCSProDB].[trans].[days] as days on days.id = lots.in_date_id
			where lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips) 
				and days.date_value between @PlanDateStart  and @PlanDateEnd 
			group by device.name , device.ft_name) as input on input.Devicename = result.Devicename
	order by summary asc
END
