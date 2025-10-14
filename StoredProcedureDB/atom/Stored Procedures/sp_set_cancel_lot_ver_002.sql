-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_cancel_lot_ver_002]
	-- Add the parameters for the stored procedure here
	@lot_id varchar(10)
	,@update_by varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	---------------------------------------------------------------------------
	-- Log exec StoredProcedureDB
    ---------------------------------------------------------------------------	
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no])
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'exec [atom].[sp_set_cancel_lot_ver_002] @lot_id = ''' + ISNULL(CAST(@lot_id AS varchar),'') 
			+ ''', @update_by = ''' + ISNULL(CAST(@update_by AS varchar),'') + ''''
		, (select cast(lot_no as varchar) from [APCSProDB].[trans].[lots] where id = @lot_id)
	-----------------------------------------------------------------
	-- DECLARE
	-----------------------------------------------------------------
	DECLARE @update_at VARCHAR(50)
		, @system_name VARCHAR(30) = 'lot stop instruction'
		, @r INT = 0
		, @id INT = 0
		, @num INT = 0
		, @device_slip_id INT
		, @process_id INT
		, @job_id INT
		, @job_step INT

	--set date now  for transition
	SET @update_at = GETDATE();
	-----------------------------------------------------------------
	-- (1) set parameter @device_slip_id,@job_step
	-----------------------------------------------------------------
	-- Find process id and job id by lot_id,device_slip_id and step_no
	SELECT @device_slip_id = [lot_stop_instructions].[device_slip_id]
		, @job_step = [lot_stop_instructions].[stop_step_no]
	FROM [APCSProDB].[trans].[lot_stop_instructions]
	WHERE [lot_stop_instructions].[lot_id] = @lot_id
		AND [lot_stop_instructions].[is_finished] = 0
	-----------------------------------------------------------------
	-- (2) set parameter @process_id,@job_id
	-----------------------------------------------------------------
	SELECT @process_id = processes.id
		, @job_id = job_id
	FROM [APCSProDB].[method].[device_flows]
	INNER JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [device_flows].[act_process_id]
	INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[id] = [device_flows].[job_id]
	WHERE [device_flows].[device_slip_id] = @device_slip_id
		AND [device_flows].[step_no] = @job_step
	-----------------------------------------------------------------
	-- (3) lot_process_records
	-----------------------------------------------------------------
    -- Insert statements for procedure here
	INSERT INTO [APCSProDB].[trans].[lot_process_records]
		([id]
		, [day_id]
		, [recorded_at]
		, [operated_by]
		, [record_class]
		, [lot_id]
		, [process_id]
		, [job_id]
		, [step_no]
		, [wip_state]
		, [process_state]
		, [quality_state]
		, [is_special_flow]
		, [is_temp_devided]
		, [updated_at]
		, [updated_by])
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
	-----------------------------------------------------------------
	-- (4) lot_stop_instructions
	-----------------------------------------------------------------
	UPDATE [APCSProDB].[trans].[lot_stop_instructions] 
	SET [lot_stop_instructions].[is_finished] = 2
		, [lot_stop_instructions].[updated_at] = @update_at
		, [lot_stop_instructions].[updated_by] = @update_by
	WHERE [lot_stop_instructions].[lot_id] = @lot_id
		AND [lot_stop_instructions].[is_finished] = 0

END
