-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_lsisearch_workrecord_ver_test]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(20) = '%'
	, @process varchar(50) = '%'
	, @jobs varchar(50) = '%'
	, @machine varchar(50) = '%'
	, @opNo varchar(50) = '%'
	, @packages varchar(50) = '%'
	, @device varchar(50) = '%'
	, @status varchar(50) = '%'
	, @start_time DATETIME = ''
	, @end_time DATETIME = ''
	, @packageGroup varchar(50) = '%'

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


    -- Insert statements for procedure here
	BEGIN
		

		IF (@process = 'FT')
			BEGIN
				EXEC [StoredProcedureDB].[dbo].[sp_get_lsisearch_workrecord_xml_FT]
					@lot_no			= @lot_no
					, @process		= @process
					, @jobs			=  @jobs
					, @machine		=  @machine
					, @opNo			=  @opNo
					, @packages 	=  @packages 
					, @device		=  @device
					, @status		=  @status
					, @start_time 	=  @start_time 
					, @end_time		=  @end_time
					, @packageGroup	=  @packageGroup;
			END
		ELSE IF (@process = 'Burn-In')
			BEGIN
				EXEC [StoredProcedureDB].[dbo].[sp_get_lsisearch_workrecord_xml_BIN]
					@lot_no			= @lot_no
					, @process		= @process
					, @jobs			=  @jobs
					, @machine		=  @machine
					, @opNo			=  @opNo
					, @packages 	=  @packages 
					, @device		=  @device
					, @status		=  @status
					, @start_time 	=  @start_time 
					, @end_time		=  @end_time
					, @packageGroup	=  @packageGroup;
			END
		ELSE
			BEGIN
				SELECT lots.lot_no
					, packages.name AS packages
					, device_names.name AS device
					, processes.name AS process
					, jobs.name AS jobs
					, lot_process_records.step_no
					, machines.name AS machines
					, item_labels.label_eng
					, recorded_at

					, ISNull(lot_process_records.qty_in,0) AS input
					--, LAG( lot_process_records.qty_pass_step_sum, 1, lot_process_records.qty_in ) OVER ( ORDER BY lot_process_records.step_no ) AS input
					, ISNull(lot_process_records.qty_p_nashi,0) AS p_nashi
					, ISNull(lot_process_records.qty_pass,0) AS qty_pass
					--, lot_process_records.qty_pass_step_sum AS qty_pass
					, ISNull(lot_process_records.qty_fail,0) AS qty_fail
					--, lot_process_records.qty_fail_step_sum AS qty_fail
					, ISNull(lot_process_records.qty_front_ng,0) AS qty_front_ng
					, ISNull(lot_process_records.qty_marker,0) AS qty_marker
					, ISNull(lot_process_records.qty_combined,0) AS qty_combined
					, ISNull(lot_process_records.qty_hasuu,0) AS qty_hasuu
					, ISNull(lot_process_records.qty_out,0) AS qty_out
					--, lot_process_records.qty_frame_in AS qty_frame_in	
					, LAG( lot_process_records.qty_frame_pass, 1, lot_process_records.qty_frame_in ) OVER ( ORDER BY lot_process_records.step_no ) AS qty_frame_in
					, ISNull(lot_process_records.qty_frame_pass,0) AS qty_frame_pass
					, ISNull(lot_process_records.qty_frame_fail,0) AS qty_frame_fail
					, users.emp_num
					, lot_process_records.carrier_no
					, lot_process_records.recipe


				FROM [APCSProDB].[trans].[lot_process_records]
				INNER JOIN APCSProDB.trans.lots with (NOLOCK) ON lot_process_records.lot_id = lots.id
				INNER JOIN APCSProDB.method.processes with (NOLOCK) ON lot_process_records.process_id = processes.id
				INNER JOIN APCSProDB.method.jobs with (NOLOCK) ON lot_process_records.job_id = jobs.id
				INNER JOIN APCSProDB.method.packages with (NOLOCK) ON lots.act_package_id = packages.id
				INNER JOIN APCSProDB.method.package_groups with (NOLOCK) ON package_groups.id = packages.package_group_id
				INNER JOIN APCSProDB.method.device_names with (NOLOCK) ON lots.act_device_name_id = device_names.id
				INNER JOIN APCSProDB.mc.machines with (NOLOCK) ON machines.id = lot_process_records.machine_id
				INNER JOIN APCSProDB.man.users with (NOLOCK) ON lot_process_records.operated_by = users.id
				INNER JOIN [APCSProDB].[trans].[item_labels] with (NOLOCK) ON [item_labels].[name] = 'lot_process_records.record_class' 
					AND [item_labels].[val] = [lot_process_records].record_class
				WHERE lots.lot_no LIKE @lot_no
					AND [lot_process_records].record_class in (1,2)
					AND processes.name LIKE @process
					AND jobs.name LIKE @jobs
					AND machines.name LIKE @machine
					AND packages.name LIKE @packages
					AND device_names.name LIKE @device
					AND users.emp_num LIKE @opNo
					AND item_labels.label_eng LIKE @status
					AND package_groups.name LIKE @packageGroup
					AND lot_process_records.recorded_at BETWEEN @start_time AND @end_time
				ORDER BY [lot_process_records].step_no, [lot_process_records].record_class
			END
	END
END
