-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_ft_accumulate_result]
	-- Add the parameters for the stored procedure here
	@DateStart as Datetime,
	@DateEnd as Datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select device.name as Devicename,SUM( lots.qty_in)  as Kpcs
from [APCSProDB].trans.lot_process_records as lot_record with (NOLOCK)
inner join [APCSProDB].trans.lots as lots with (NOLOCK) on lots.id = lot_record.lot_id
inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lots.act_device_name_id = device.id 
inner join [DBxDW].CAC.DeviceGdic with (NOLOCK) on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = device.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
where lot_record.record_class = 2  and job_id = 119 and lot_record.recorded_at between @DateStart and @DateEnd
group by device.name
END
