-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_start_step]
	-- Add the parameters for the stored procedure here
	 @lot_id int
	,@step_no int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @device_slip_id INT;
	DECLARE @act_process_id INT;
	DECLARE @act_job_id INT;
    -- Insert statements for procedure here

	-- find device_slip_id of lot
	SELECT @device_slip_id = device_slip_id
	FROM [APCSProDB].[trans].[lots]
	where id = @lot_id
	-- find act_process_id and act_job_id
	SELECT 
	@act_process_id = [device_flows].act_process_id
	,@act_job_id = [device_flows].job_id
	FROM [APCSProDB].[method].[device_flows] 
	inner join [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id] 
	inner join [APCSProDB].[method].[processes] on [jobs].[process_id] = [processes].[id] 
	where device_slip_id = @device_slip_id and step_no = @step_no
	-- update data at trans.lots
	update [APCSProDB].[trans].[lots]
	set [step_no] = case when (CONVERT(varchar(50),@step_no) = '') then NULL else @step_no end
	,[wip_state] = case when (CONVERT(varchar(50),20) = '') then NULL else 20 end
 	,[act_process_id] = case when (CONVERT(varchar(50),@act_process_id) = '') then NULL else @act_process_id end
	,[act_job_id] = case when (CONVERT(varchar(50),@act_job_id) = '') then NULL else @act_job_id end
	,[start_step_no] = case when (CONVERT(varchar(50),@step_no) = '') then NULL else @step_no end
	WHERE [lots].[id] = @lot_id;
END
