-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_machine_alarm_history]
	@machine_name nvarchar(20) = N'',
	@dateFrom datetime = '2020-06-01' 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	--SET NOCOUNT ON;

	select 
	mc.id as machine_id
	,mc.name as machine
	,r.model_alarm_id
	,r.alarm_on_at
	,r.alarm_off_at
	,r.started_at
	,r.repeat_count
	,ma.alarm_code
	,tx.alarm_text
	from apcsprodb.mc.machines as mc with (NOLOCK) 
		inner join apcsprodb.trans.machine_alarm_records as r with (NOLOCK) 
			on r.machine_id = mc.id
		inner join apcsprodb.mc.model_alarms as ma with (NOLOCK) 
			on ma.id = r.model_alarm_id
		inner join apcsprodb.mc.alarm_texts as tx with (NOLOCK)
			on tx.alarm_text_id = ma.alarm_text_id 
	where mc.name = @machine_name
		and r.alarm_on_at > @dateFrom
	order by r.alarm_on_at desc
 END
