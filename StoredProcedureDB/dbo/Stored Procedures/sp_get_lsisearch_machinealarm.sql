-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_lsisearch_machinealarm]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(20) = '%'
	, @process varchar(50) = '%'
	, @machine varchar(50) = '%'
	, @start_time DATETIME = ''
	, @end_time DATETIME = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


    -- Insert statements for procedure here
	BEGIN		
		IF (@machine like '%FL-AXI%')
		BEGIN
			SELECT lots.lot_no
				, processes.name AS process
				, machines.name AS machine
				, model_alarms.alarm_code
				, alarm_texts.alarm_text
				, alarm_on_at
				, alarm_off_at
				, item_labels.label_eng AS alarm_level
			FROM APCSProDB.trans.machine_alarm_records
			INNER JOIN APCSProDB.trans.alarm_lot_records with (NOLOCK) ON machine_alarm_records.id = alarm_lot_records.id 
			INNER JOIN APCSProDB.trans.lots with (NOLOCK) ON alarm_lot_records.lot_id = lots.id
			INNER JOIN APCSProDB.mc.machines with (NOLOCK) ON machine_alarm_records.machine_id = machines.id
			INNER JOIN APCSProDB.mc.model_alarms with (NOLOCK) ON machine_alarm_records.model_alarm_id = model_alarms.id
			INNER JOIN APCSProDB.mc.alarm_texts with (NOLOCK) ON model_alarms.alarm_text_id = alarm_texts.alarm_text_id
			INNER JOIN APCSProDB.mc.group_models with (NOLOCK) ON model_alarms.machine_model_id = group_models.machine_model_id 
			INNER JOIN APCSProDB.method.jobs with (NOLOCK) ON group_models.machine_group_id = jobs.machine_group_id
			INNER JOIN APCSProDB.method.processes with (NOLOCK) ON jobs.process_id = processes.id
			INNER JOIN APCSProDB.mc.item_labels with (NOLOCK) ON item_labels.name = 'model_alarms.alarm_level'
				AND item_labels.val = model_alarms.alarm_level
			WHERE lots.lot_no LIKE @lot_no
			AND machines.name  LIKE @machine
			AND machine_alarm_records.alarm_on_at between @start_time and @end_time

			Group by lots.lot_no
				, processes.name 
				, machines.name
				, model_alarms.alarm_code
				, alarm_texts.alarm_text
				, alarm_on_at
				, alarm_off_at
				, item_labels.label_eng 

			ORDER BY alarm_on_at
			OPTION (RECOMPILE);
		END
		ELSE
		BEGIN
			SELECT lots.lot_no
				, processes.name AS process
				, machines.name AS machine
				, model_alarms.alarm_code
				, alarm_texts.alarm_text
				, alarm_on_at
				, alarm_off_at
				, item_labels.label_eng AS alarm_level
			FROM APCSProDB.trans.machine_alarm_records
			INNER JOIN APCSProDB.trans.alarm_lot_records with (NOLOCK) ON machine_alarm_records.id = alarm_lot_records.id 
			INNER JOIN APCSProDB.trans.lots with (NOLOCK) ON alarm_lot_records.lot_id = lots.id
			INNER JOIN APCSProDB.mc.machines with (NOLOCK) ON machine_alarm_records.machine_id = machines.id
			INNER JOIN APCSProDB.mc.model_alarms with (NOLOCK) ON machine_alarm_records.model_alarm_id = model_alarms.id
			INNER JOIN APCSProDB.mc.alarm_texts with (NOLOCK) ON model_alarms.alarm_text_id = alarm_texts.alarm_text_id
			INNER JOIN APCSProDB.mc.group_models with (NOLOCK) ON model_alarms.machine_model_id = group_models.machine_model_id 
			INNER JOIN APCSProDB.method.jobs with (NOLOCK) ON group_models.machine_group_id = jobs.machine_group_id
			INNER JOIN APCSProDB.method.processes with (NOLOCK) ON jobs.process_id = processes.id
			INNER JOIN APCSProDB.mc.item_labels with (NOLOCK) ON item_labels.name = 'model_alarms.alarm_level'
				AND item_labels.val = model_alarms.alarm_level
			WHERE lots.lot_no LIKE @lot_no
			AND processes.name LIKE @process
			AND machines.name  LIKE @machine
			AND machine_alarm_records.alarm_on_at between @start_time and @end_time

			Group by lots.lot_no
				, processes.name 
				, machines.name
				, model_alarms.alarm_code
				, alarm_texts.alarm_text
				, alarm_on_at
				, alarm_off_at
				, item_labels.label_eng 

			ORDER BY alarm_on_at
			OPTION (RECOMPILE);
		END
	END
END
