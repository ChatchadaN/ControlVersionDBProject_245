-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_ft_accumulate_plan]
	-- Add the parameters for the stored procedure here
	@DateStart as Datetime,
	@DateEnd as Datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT  device.name as Devicename,device.ft_name as FTDevice ,sum(lots.qty_in) as Kpcs
	
	FROM [APCSProDB].[trans].lots as lots with (NOLOCK) 
	--inner join [APCSProDB].[trans].lots as lots on lots.id = lot_record.lot_id
	inner join [APCSProDB] .[method].device_names as device with (NOLOCK) on lots.act_device_name_id = device.id 
	--inner join [DBxDW].CAC.DeviceGdic on DeviceGdic.device_name COLLATE SQL_Latin1_General_CP1_CI_AS = device.assy_name COLLATE SQL_Latin1_General_CP1_CI_AS
	inner join [APCSProDB].[trans].[days] as days with (NOLOCK) on days.id = lots.in_date_id
	where lots.id not in (select child_lot_id from [APCSProDB] .trans.lot_multi_chips with (NOLOCK)) 
	and days.date_value between @DateStart  and @DateEnd
	group by device.name , device.ft_name

END
