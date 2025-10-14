-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create 20210731,,>
-- Description:	<Description,,Stop Lot>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_stop_lot_ver_001] 
	-- Add the parameters for the stored procedure here
	@lot_id varchar(10)
	,@job_step int
	,@comment_id int
	,@update_by varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @update_at varchar(50)
	,@system_name varchar(10) = 'ATOM_SYSTEM'
	,@current_step int
	,@member_lot int
	,@device_slip_id int
	,@process_id int
	,@job_id int

	DECLARE @r INT = 0;
	DECLARE @id INT = 0;
	DECLARE @num INT = 0;
	--set date now  for transition
	set @update_at = GETDATE();

    -- Insert statements for procedure here

	-- Find process id and job id by lot_id,device_slip_id and step_no
	select @device_slip_id = lots.device_slip_id from [APCSProDB].[trans].lots where id = @lot_id
	
	select 
	@process_id = processes.id
	,@job_id = job_id
	from [APCSProDB].method.device_flows
	inner join [APCSProDB].method.processes on processes.id = device_flows.act_process_id
	inner join [APCSProDB].method.jobs on jobs.id = device_flows.job_id
	where device_flows.device_slip_id = @device_slip_id
	and device_flows.step_no = @job_step

	-- check lot_id have member_lot or not
	-- check jobid is current or not
	select @current_step = [lots].step_no FROM [APCSProDB].[trans].[lots] where id =  @lot_id;
	BEGIN TRANSACTION
		BEGIN TRY
			IF(@current_step = @job_step)
			BEGIN 
				--stop at current job
				--update quality_state = 1 
				update [APCSProDB].[trans].[lots] set [lots].quality_state = 1 WHERE [lots].[id] = @lot_id; 
				--update lot_process_recodes
				INSERT INTO [APCSProDB].[trans].[lot_process_records](
				[id]
				  ,[day_id]
				  ,[recorded_at]
				  ,[operated_by]
				  ,[record_class]
				  ,[lot_id]
				  ,[process_id]
				  ,[job_id]
				  ,[step_no]
				  ,[qty_in]
				  ,[qty_pass]
				  ,[qty_fail]
				  ,[qty_last_pass]
				  ,[qty_last_fail]
				  ,[qty_pass_step_sum]
				  ,[qty_fail_step_sum]
				  ,[qty_divided]
				  ,[qty_hasuu]
				  ,[qty_out]
				  ,[recipe]
				  ,[recipe_version]
				  ,[machine_id]
				  ,[position_id]
				  ,[process_job_id]
				  ,[is_onlined]
				  ,[dbx_id]
				  ,[wip_state]
				  ,[process_state]
				  ,[quality_state]
				  ,[first_ins_state]
				  ,[final_ins_state]
				  ,[is_special_flow]
				  ,[special_flow_id]
				  ,[is_temp_devided]
				  ,[temp_devided_count]
				  ,[container_no]
				  ,[extend_data]
				  ,[std_time_sum]
				  ,[pass_plan_time]
				  ,[pass_plan_time_up]
				  ,[origin_material_id]
				  ,[treatment_time]
				  ,[wait_time]
				  ,[qc_comment_id]
				  ,[qc_memo_id]
				  ,[created_at]
				  ,[created_by]
				  ,[updated_at]
				  ,[updated_by])
					SELECT [nu].[id] + row_number() over (order by [lots].[id])
					, [days].[id] [day_id]
					, @update_at as [recorded_at]
					, @update_by as [operated_by]
					, 48 as [record_class]
					, [lots].[id] as [lot_id]
					, [act_process_id] as [process_id]
					, [act_job_id] as [job_id]
					, @job_step as [step_no]
					, [qty_in]
					, [qty_pass]
					, [qty_fail]
					, [qty_last_pass]
					, [qty_last_fail]
					, [qty_pass_step_sum]
					, [qty_fail_step_sum]
					, [qty_divided]
					, [qty_hasuu]
					, [qty_out]
					, NULL as [recipe]
					, 1 as [recipe_version]
					, [machine_id]
					, NULL as [position_id]
					, [process_job_id]
					, 0 as [is_onlined]
					, 0 as [dbx_id]
					, [wip_state]
					, [process_state]
					, [quality_state]
					, [first_ins_state]
					, [final_ins_state]
					, [is_special_flow]
					, [special_flow_id]
					, [is_temp_devided]
					, [temp_devided_count]
					, [container_no]
					, NULL as [extend_data]
					, [std_time_sum]
					, [pass_plan_time]
					, [pass_plan_time_up]
					, [origin_material_id]
					, NULL as [treatment_time]
					, NULL as [wait_time]
					, [qc_comment_id]
					, [qc_memo_id]
					, [created_at]
					, [created_by]
					, @update_at as [updated_at]
					, @update_by as [updated_by]
					FROM [APCSProDB].[trans].[lots] 
					INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
					INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
					WHERE [lots].[id] = @lot_id

				SET @r = @@ROWCOUNT
				 UPDATE [APCSProDB].[trans].[numbers]
				 SET [id] = [id] + @r
				 WHERE [name] = 'lot_process_records.id'

				 --check lot_id and system_name table trans.lot_hold_controls 
				 select @num = COUNT([lot_hold_controls].id) from [APCSProDB].[trans].[lot_hold_controls] 
				 where [lot_hold_controls].lot_id = @lot_id
				 and [lot_hold_controls].system_name = @system_name;
				 --if @num > 0 then update table trans.lot_hold_controls else insert table trans.lot_hold_controls
				 IF(@num > 0)
				 BEGIN
					update [APCSProDB].[trans].[lot_hold_controls]
					set is_held = 1
					,updated_at = @update_at
					,updated_by = @update_by
					where [lot_hold_controls].lot_id = @lot_id
					and [lot_hold_controls].system_name = @system_name; 
				 END
				 ELSE
				 BEGIN
					--insert to table trans.lot_hold_controls
					 select top 1 @id = [lot_hold_controls].id 
					 from  [APCSProDB].[trans].[lot_hold_controls] 
					 order by [lot_hold_controls].id desc;

					 insert into [APCSProDB].[trans].[lot_hold_controls]
					 (
					   [id]
					  ,[lot_id]
					  ,[system_name]
					  ,[is_held]
					  ,[updated_at]
					  ,[updated_by]
					 )
					 values
					 (
						@id+1
						,@lot_id
						,@system_name 
						,1 
						,@update_at
						,@update_by 
					 )
				 END;
		 
				 SET @r = @@ROWCOUNT
				 UPDATE [APCSProDB].[trans].[numbers]
				 SET [id] = [id] + @r
				 WHERE [name] = 'lot_hold_controls.id'

				 --insert table [trans].[lot_hold_control_records]
				 insert into [APCSProDB].[trans].[lot_hold_control_records](
					 [id]
				  ,[hold_control_id]
				  ,[lot_id]
				  ,[system_name]
				  ,[updated_at]
				  ,[updated_by]
				  ,[is_held]
				 )
				 select 
				 lot_process_records.id as [id]
				 ,[lot_hold_controls].id as [hold_control_id]
				 ,@lot_id as [lot_id]
				 ,@system_name as [system_name]
				 ,@update_at as [updated_at]
				 ,@update_by as [updated_by]
				 ,1 as [is_held]
				 FROM [APCSProDB].[trans].lots 
				 inner join [APCSProDB].[trans].lot_process_records on lot_process_records.lot_id = lots.id
				 inner join [APCSProDB].[trans].[lot_hold_controls] on [lot_hold_controls].lot_id = lots.id
				 WHERE lots.id = @lot_id
				 and [lot_process_records].record_class = 48
				 and lot_process_records.updated_at = @update_at
				 and lot_process_records.updated_by = @update_by
				 and [lot_hold_controls].lot_id = @lot_id
				 and [lot_hold_controls].system_name = @system_name
				 and [lot_hold_controls].updated_at = @update_at

				 --insert table [trans].[lot_stop_instructions]
				 select top 1 @id = [lot_stop_instructions].stop_instruction_id 
				 from  [APCSProDB].[trans].[lot_stop_instructions]
				 order by [lot_stop_instructions].stop_instruction_id desc;

				 insert into [APCSProDB].[trans].[lot_stop_instructions]
				 (
					[stop_instruction_id]
				  ,[device_slip_id]
				  ,[stop_step_no]
				  ,[display_message_id]
				  ,[is_finished]
				  ,[updated_at]
				  ,[updated_by]
				  ,[instruction_record_id]
				  ,[lot_id]
				 )
				 select 
				 @id+1 as [stop_instruction_id]
				 ,lots.device_slip_id as [device_slip_id]
				 ,@current_step as [stop_step_no]
				 ,@comment_id as [display_message_id]
				 ,1 as [is_finished]
				 ,@update_at as [updated_at]
				 ,@update_by as [updated_by]
				 ,lot_process_records.id as [instruction_record_id]
				 ,@lot_id as [lot_id]
				 from [APCSProDB].[trans].lots
				 inner join [APCSProDB].[trans].lot_process_records on lot_process_records.lot_id = lots.id
				 where lots.id = @lot_id
				 and [lot_process_records].record_class = 48
				 and lot_process_records.updated_at = @update_at
				 and lot_process_records.updated_by = @update_by

				 SET @r = @@ROWCOUNT
				 UPDATE [APCSProDB].[trans].[numbers]
				 SET [id] = [id] + @r
				 WHERE [name] = 'lot_stop_instructions.stop_instruction_id'

			END
			ELSE
			BEGIN
				--stop at future job
				--update lot_process_recodes
				INSERT INTO [APCSProDB].[trans].[lot_process_records](
				[id]
				,[day_id]
				,[recorded_at]
				,[operated_by]
				,[record_class]
				,[lot_id]
				,[process_id]
				,[job_id]
				,[step_no]
				,[wip_state]
				,[process_state]
				,[quality_state]
				,[is_special_flow]
				,[is_temp_devided]
				,[updated_at]
				,[updated_by])
					SELECT [nu].[id] + row_number() over (order by [lots].[id])
					, [days].[id] [day_id]
					, @update_at as [recorded_at]
					, @update_by as [operated_by]
					, 48 as [record_class]
					, [lots].[id] as [lot_id]
					, @process_id as [process_id]
					, @job_id as [job_id]
					--, @job_step as [step_no]
					, @current_step as [step_no]
					, [wip_state]
					, [process_state]
					, [quality_state]
					, [is_special_flow]
					, [is_temp_devided]
					, @update_at as [updated_at]
					, @update_by as [updated_by]
					FROM [APCSProDB].[trans].[lots] 
					INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = CONVERT(DATE,GETDATE())
					INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_process_records.id'
					WHERE [lots].[id] = @lot_id

				SET @r = @@ROWCOUNT
				UPDATE [APCSProDB].[trans].[numbers]
			    SET [id] = [id] + @r
				WHERE [name] = 'lot_process_records.id'

				 insert into [APCSProDB].[trans].[lot_stop_instructions]
				 (
					[stop_instruction_id]
				  ,[device_slip_id]
				  ,[stop_step_no]
				  ,[display_message_id]
				  ,[is_finished]
				  ,[updated_at]
				  ,[updated_by]
				  ,[instruction_record_id]
				  ,[lot_id]
				 )
				 select 
				 [nu].[id] + row_number() over (order by [lots].[id])
				 ,lots.device_slip_id as [device_slip_id]
				 --,@current_step as [stop_step_no]
				 ,@job_step as [stop_step_no]
				 ,@comment_id as [display_message_id]
				 ,0 as [is_finished]
				 ,@update_at as [updated_at]
				 ,@update_by as [updated_by]
				 ,lot_process_records.id as [instruction_record_id]
				 ,@lot_id as [lot_id]
				 from [APCSProDB].[trans].lots
				 inner join [APCSProDB].[trans].lot_process_records on lot_process_records.lot_id = lots.id
				 INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'lot_stop_instructions.stop_instruction_id'
				 where lots.id = @lot_id
				 and [lot_process_records].record_class = 48
				 and lot_process_records.updated_at = @update_at
				 and lot_process_records.updated_by = @update_by

				 SET @r = @@ROWCOUNT
				 UPDATE [APCSProDB].[trans].[numbers]
				 SET [id] = [id] + @r
				 WHERE [name] = 'lot_stop_instructions.stop_instruction_id'
			END;
			--select '1' as [status],'successfully' as [message];
			commit
		END TRY
		BEGIN CATCH
			ROLLBACK
			--select '0' as [status], ERROR_MESSAGE() as [message];
		END CATCH
END
