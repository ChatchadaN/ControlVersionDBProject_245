-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_cancel_lot_ver_001]
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
	,@num INT = 0
	,@device_slip_id int
	,@process_id int
	,@job_id int
	,@job_step int

	--set date now  for transition
	set @update_at = GETDATE();

	-- Find process id and job id by lot_id,device_slip_id and step_no
	select @device_slip_id =  [lot_stop_instructions].device_slip_id
	,@job_step = [lot_stop_instructions].stop_step_no
	from [APCSProDB].[trans].[lot_stop_instructions]
	where [lot_stop_instructions].lot_id = @lot_id
	and [lot_stop_instructions].is_finished = 0
	
	select 
	@process_id = processes.id
	,@job_id = job_id
	from [APCSProDB].method.device_flows
	inner join [APCSProDB].method.processes on processes.id = device_flows.act_process_id
	inner join [APCSProDB].method.jobs on jobs.id = device_flows.job_id
	where device_flows.device_slip_id = @device_slip_id
	and device_flows.step_no = @job_step

    -- Insert statements for procedure here
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
		, 44 as [record_class]
		, [lots].[id] as [lot_id]
		, @process_id as [process_id]
		, @job_id as [job_id]
		, @job_step as [step_no]
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

		update [APCSProDB].[trans].[lot_stop_instructions] 
		set [lot_stop_instructions].is_finished = 2
		,[lot_stop_instructions].updated_at = @update_at
		,[lot_stop_instructions].updated_by = @update_by
		where [lot_stop_instructions].lot_id = @lot_id
		and [lot_stop_instructions].is_finished = 0

END
