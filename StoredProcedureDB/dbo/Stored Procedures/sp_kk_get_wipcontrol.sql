-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_kk_get_wipcontrol]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select 
	ROW_NUMBER() over (order by il.occurred_at desc,il.id) as [No]
	,il.id 
	,il.name
	,p.name as Package
	,'' as Device
	,il.wip_lot_count as [Value]
	,il.alarm_value as [UCL]
	,format(il.occurred_at,'yyyy-MM-dd HH:mm:ss') as [Occurred at]
	,case when il.cleared_at is null then '' else format(il.cleared_at,'yyyy-MM-dd HH:mm:ss') end as [Cleared at]
	,r.recorded_at
	,r.alarm_value
from APCSProDWH.dwh.setting_package_input_limit as il with (NOLOCK) 
	inner join APCSProDWH.dwh.dim_packages as p 
		on p.id = il.package_id 
	left outer join APCSProDWH.dwh.[package_input_limit_records] as r 
		on r.input_limit_id = il.id
			and r.alarm_value <> il.alarm_value
--where il.is_alarmed = 1 and isnull(il.is_input_control,0) <> 1
order by il.occurred_at desc,il.id,r.recorded_at


END
