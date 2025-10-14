-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_trans_lot_process_records]
	-- Add the parameters for the stored procedure here
	@lot_id int
	, @step_no int
	, @machine_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	  SELECT [lot_process_records].[id]
	  ,[lot_process_records].[lot_id]
      ,[lot_process_records].[recorded_at]
	  ,[item_labels6].[label_eng] as [record_class]
	  ,[lot_process_records].record_class as [record_class_id]
	  ,[machines].[name] as [machines_name]
	  ,[lots].[lot_no]
	  ,[users1].[emp_num] as [operated_by]
	  ,[jobs].[name] as [job_name]      	  
	  ,[processes].[name] as [process_name]	
      ,[lot_process_records].[step_no]
      ,[lot_process_records].[qty_in]
      ,[lot_process_records].[qty_pass]
      ,[lot_process_records].[qty_fail]
      ,[lot_process_records].[qty_last_pass]
      ,[lot_process_records].[qty_last_fail]
      ,[lot_process_records].[qty_pass_step_sum]
      ,[lot_process_records].[qty_fail_step_sum]
      ,[lot_process_records].[qty_divided]
      ,[lot_process_records].[qty_hasuu]
      ,[lot_process_records].[qty_out]
	  ,[lot_process_records].[is_onlined]
	  ,[item_labels1].[label_eng] as [wip_state]
	  ,[item_labels2].[label_eng] as [process_state]
	  ,[item_labels3].[label_eng] as [quality_state]
	  ,[item_labels4].[label_eng] as [first_ins_state]
	  ,[item_labels5].[label_eng] as [final_ins_state]
      ,[lot_process_records].[container_no]
	  ,[lot_process_records].[is_special_flow]
      ,[lot_process_records].[special_flow_id]
      ,[lot_process_records].[recipe]
      ,[lot_process_records].[recipe_version]
      ,[lot_process_records].[position_id]
      ,[lot_process_records].[process_job_id]      
      ,[lot_process_records].[dbx_id]
      ,[lot_process_records].[is_temp_devided]
      ,[lot_process_records].[temp_devided_count]
      ,[lot_process_records].[std_time_sum]
      ,[lot_process_records].[pass_plan_time]
      ,[lot_process_records].[pass_plan_time_up]
      ,[lot_process_records].[origin_material_id]
      ,[lot_process_records].[wait_time]
      ,[lot_process_records].[created_at]
      ,[lot_process_records].[created_by]
      ,[lot_process_records].[updated_at]
      ,[lot_process_records].[updated_by]
  FROM [APCSProDB].[trans].[lot_process_records]
	inner join [APCSProDB].[trans].[days] as [days1] on [days1].[id] = [lot_process_records].[day_id]
	inner join [APCSProDB].[man].[users] as [users1] on [users1].[id] = [lot_process_records].[operated_by]
	left join [APCSProDB].[trans].[item_labels] as [item_labels6] on [item_labels6].[name] = 'lot_process_records.record_class' and [item_labels6].[val] = [lot_process_records].[record_class]
	inner join [APCSProDB].[trans].[lots] on [lots].[id] = [lot_process_records].[lot_id]
	inner join [APCSProDB].[method].[processes] on [processes].[id] = [lot_process_records].[process_id]
	inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [lot_process_records].[job_id]
	left join [APCSProDB].[mc].[machines] on [machines].[id] = [lot_process_records].[machine_id]
	inner join [APCSProDB].[trans].[item_labels] as [item_labels1] on [item_labels1].[name] = 'lots.wip_state' and [item_labels1].[val] = [lot_process_records].[wip_state]
	inner join [APCSProDB].[trans].[item_labels] as [item_labels2] on [item_labels2].[name] = 'lots.process_state' and [item_labels2].[val] = [lot_process_records].[process_state]
	inner join [APCSProDB].[trans].[item_labels] as [item_labels3] on [item_labels3].[name] = 'lots.quality_state' and [item_labels3].[val] = [lot_process_records].[quality_state]
	left join [APCSProDB].[trans].[item_labels] as [item_labels4] on [item_labels4].[name] = 'lots.first_ins_state' and [item_labels4].[val] = [lot_process_records].[first_ins_state]
	left join [APCSProDB].[trans].[item_labels] as [item_labels5] on [item_labels5].[name] = 'lots.final_ins_state' and [item_labels5].[val] = [lot_process_records].[final_ins_state]
	left join [APCSProDB].[man].[users] as [users2] on [users2].[id] = [lot_process_records].[updated_by]
	WHERE [lot_process_records].[lot_id] = @lot_id
	and [lot_process_records].[step_no] = @step_no
	--and [lot_process_records].[machine_id] = @machine_id
	order by [lot_process_records].[id]
END
