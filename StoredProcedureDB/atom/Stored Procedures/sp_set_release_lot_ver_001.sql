-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create 20211016,,>
-- Description:	<Description,,Release Lot>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_release_lot_ver_001]
	-- Add the parameters for the stored procedure here
	@lot_id varchar(10)
	,@update_by varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @update_at varchar(50)
	,@system_name varchar(10) = 'ATOM_SYSTEM'
	,@r INT = 0
	,@id INT = 0
	,@num INT = 0;

	--set date now  for transition
	set @update_at = GETDATE();

    -- Insert statements for procedure here
	--update quality_state = 0
	update [APCSProDB].[trans].[lots] set [lots].quality_state = 0 WHERE [lots].[id] = @lot_id; 

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
		, 44 as [record_class]
		, [lots].[id] as [lot_id]
		, [act_process_id] as [process_id]
		, [act_job_id] as [job_id]
		, [step_no]
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

	update [APCSProDB].[trans].[lot_hold_controls] 
	set [lot_hold_controls].is_held = 0
	,[lot_hold_controls].updated_at = @update_at
	,[lot_hold_controls].updated_by = @update_by
	WHERE [lot_hold_controls].lot_id = @lot_id
	and [lot_hold_controls].system_name = @system_name

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
	,0 as [is_held]
	FROM [APCSProDB].[trans].lots 
	inner join [APCSProDB].[trans].lot_process_records on lot_process_records.lot_id = lots.id
	inner join [APCSProDB].[trans].[lot_hold_controls] on [lot_hold_controls].lot_id = lots.id
	WHERE lots.id = @lot_id
	and [lot_process_records].record_class = 44
	and lot_process_records.updated_at = @update_at
	and lot_process_records.updated_by = @update_by
	and [lot_hold_controls].lot_id = @lot_id
	and [lot_hold_controls].system_name = @system_name
	and [lot_hold_controls].updated_at = @update_at

END
