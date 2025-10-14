-- =============================================
-- Author:		<Author,THARIN YENPAIROJ>
-- Create date: <Create Date,13-12-2019,>
-- Description:	<Description,Lsi search alarm history of ApcsPro Website,>
-- =============================================
CREATE PROCEDURE  [dbo].[sp_get_apcspro_alarm_history]
	-- Add the parameters for the stored procedure here
	@mcNo as VARCHAR(50) ='' , 
	@lotNo as  VARCHAR(50) ='', 
	@start as VARCHAR(50)= '',
	@end as VARCHAR(50)=''  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@lotNo != 'NNNK') --Search Machine and Process 
	BEGIN
		--select @mcNo as A ,@lotNo as B
			SELECT APCSProDB.trans.lots.lot_no as LotNo, APCSProDB.mc.machines.name as McNo, APCSProDB.mc.model_alarms.alarm_code as AlarmCode, APCSProDB.mc.alarm_texts.alarm_text as AlarmText, APCSProDB.trans.machine_alarm_records.alarm_on_at as AlarmStart, APCSProDB.trans.machine_alarm_records.alarm_off_at as AlarmEnd
			FROM  APCSProDB.mc.alarm_texts with (NOLOCK) INNER JOIN APCSProDB.mc.model_alarms with (NOLOCK) ON APCSProDB.mc.alarm_texts.alarm_text_id = APCSProDB.mc.model_alarms.alarm_text_id INNER JOIN 
			APCSProDB.trans.machine_alarm_records with (NOLOCK) ON APCSProDB.mc.model_alarms.id = APCSProDB.trans.machine_alarm_records.model_alarm_id INNER JOIN 
			APCSProDB.trans.alarm_lot_records with (NOLOCK) ON APCSProDB.trans.machine_alarm_records.id = APCSProDB.trans.alarm_lot_records.id AND APCSProDB.trans.machine_alarm_records.id = APCSProDB.trans.alarm_lot_records.id INNER JOIN 
			APCSProDB.trans.lots with (NOLOCK) ON APCSProDB.trans.alarm_lot_records.lot_id = APCSProDB.trans.lots.id AND APCSProDB.trans.alarm_lot_records.lot_id = APCSProDB.trans.lots.id INNER JOIN 
			APCSProDB.mc.machines with (NOLOCK) ON APCSProDB.trans.machine_alarm_records.machine_id = APCSProDB.mc.machines.id 
			WHERE APCSProDB.mc.machines.name LIKE @mcNo + '%' and lot_no like @lotNo 
			--order by APCSProDB.trans.machine_alarm_records.alarm_on_at asc
			order by AlarmStart asc
	END
	ELSE  -- Search Lot
	BEGIN
	--select @mcNo as A ,@lotNo as B

			SELECT APCSProDB.trans.lots.lot_no as LotNo, APCSProDB.mc.machines.name as McNo, APCSProDB.mc.model_alarms.alarm_code as AlarmCode, APCSProDB.mc.alarm_texts.alarm_text as AlarmText, APCSProDB.trans.machine_alarm_records.alarm_on_at as AlarmStart, APCSProDB.trans.machine_alarm_records.alarm_off_at as AlarmEnd
			FROM  APCSProDB.mc.alarm_texts with (NOLOCK) INNER JOIN APCSProDB.mc.model_alarms ON APCSProDB.mc.alarm_texts.alarm_text_id = APCSProDB.mc.model_alarms.alarm_text_id INNER JOIN 
			APCSProDB.trans.machine_alarm_records with (NOLOCK) ON APCSProDB.mc.model_alarms.id = APCSProDB.trans.machine_alarm_records.model_alarm_id INNER JOIN 
			APCSProDB.trans.alarm_lot_records with (NOLOCK) ON APCSProDB.trans.machine_alarm_records.id = APCSProDB.trans.alarm_lot_records.id AND APCSProDB.trans.machine_alarm_records.id = APCSProDB.trans.alarm_lot_records.id INNER JOIN 
			APCSProDB.trans.lots with (NOLOCK) ON APCSProDB.trans.alarm_lot_records.lot_id = APCSProDB.trans.lots.id AND APCSProDB.trans.alarm_lot_records.lot_id = APCSProDB.trans.lots.id INNER JOIN 
			APCSProDB.mc.machines with (NOLOCK) ON APCSProDB.trans.machine_alarm_records.machine_id = APCSProDB.mc.machines.id 
			WHERE APCSProDB.mc.machines.name LIKE @mcNo + '%' 
			and APCSProDB.trans.machine_alarm_records.alarm_on_at between @start and @end
			--order by APCSProDB.trans.machine_alarm_records.alarm_on_at asc
			order by AlarmStart asc
		
	END 



	--IF(@start = null)
	--	BEGIN
	--		SELECT APCSProDB.trans.lots.lot_no as LotNo, APCSProDB.mc.machines.name as McNo, APCSProDB.mc.model_alarms.alarm_code as AlarmCode, APCSProDB.mc.alarm_texts.alarm_text as AlarmText, APCSProDB.trans.machine_alarm_records.alarm_on_at as AlarmStart, APCSProDB.trans.machine_alarm_records.alarm_off_at as AlarmEnd
	--		FROM  APCSProDB.mc.alarm_texts with (NOLOCK) INNER JOIN APCSProDB.mc.model_alarms with (NOLOCK) ON APCSProDB.mc.alarm_texts.alarm_text_id = APCSProDB.mc.model_alarms.alarm_text_id INNER JOIN 
	--		APCSProDB.trans.machine_alarm_records with (NOLOCK) ON APCSProDB.mc.model_alarms.id = APCSProDB.trans.machine_alarm_records.model_alarm_id INNER JOIN 
	--		APCSProDB.trans.alarm_lot_records with (NOLOCK) ON APCSProDB.trans.machine_alarm_records.id = APCSProDB.trans.alarm_lot_records.id AND APCSProDB.trans.machine_alarm_records.id = APCSProDB.trans.alarm_lot_records.id INNER JOIN 
	--		APCSProDB.trans.lots with (NOLOCK) ON APCSProDB.trans.alarm_lot_records.lot_id = APCSProDB.trans.lots.id AND APCSProDB.trans.alarm_lot_records.lot_id = APCSProDB.trans.lots.id INNER JOIN 
	--		APCSProDB.mc.machines with (NOLOCK) ON APCSProDB.trans.machine_alarm_records.machine_id = APCSProDB.mc.machines.id 
	--		WHERE APCSProDB.mc.machines.name LIKE @mcNo and lot_no like @lotNo 
	--		order by APCSProDB.trans.machine_alarm_records.alarm_on_at asc
	--	END
	--ELSE
	--	BEGIN
	--		SELECT APCSProDB.trans.lots.lot_no as LotNo, APCSProDB.mc.machines.name as McNo, APCSProDB.mc.model_alarms.alarm_code as AlarmCode, APCSProDB.mc.alarm_texts.alarm_text as AlarmText, APCSProDB.trans.machine_alarm_records.alarm_on_at as AlarmStart, APCSProDB.trans.machine_alarm_records.alarm_off_at as AlarmEnd
	--		FROM  APCSProDB.mc.alarm_texts with (NOLOCK) INNER JOIN APCSProDB.mc.model_alarms ON APCSProDB.mc.alarm_texts.alarm_text_id = APCSProDB.mc.model_alarms.alarm_text_id INNER JOIN 
	--		APCSProDB.trans.machine_alarm_records with (NOLOCK) ON APCSProDB.mc.model_alarms.id = APCSProDB.trans.machine_alarm_records.model_alarm_id INNER JOIN 
	--		APCSProDB.trans.alarm_lot_records with (NOLOCK) ON APCSProDB.trans.machine_alarm_records.id = APCSProDB.trans.alarm_lot_records.id AND APCSProDB.trans.machine_alarm_records.id = APCSProDB.trans.alarm_lot_records.id INNER JOIN 
	--		APCSProDB.trans.lots with (NOLOCK) ON APCSProDB.trans.alarm_lot_records.lot_id = APCSProDB.trans.lots.id AND APCSProDB.trans.alarm_lot_records.lot_id = APCSProDB.trans.lots.id INNER JOIN 
	--		APCSProDB.mc.machines with (NOLOCK) ON APCSProDB.trans.machine_alarm_records.machine_id = APCSProDB.mc.machines.id 
	--		WHERE APCSProDB.mc.machines.name LIKE @mcNo and lot_no like @lotNo 
	--		and APCSProDB.trans.machine_alarm_records.alarm_on_at between @start and @end
	--		order by APCSProDB.trans.machine_alarm_records.alarm_on_at asc
	--	END


END
