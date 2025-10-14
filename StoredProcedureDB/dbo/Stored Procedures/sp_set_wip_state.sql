-- =============================================
-- Author:		<Author,,Name>
-- Create date: <03/03/2021,,>
-- Description:	<Change Wip State After Mix,,>
-- Update date: <16/03/2021>
-- Update Name: <009131,Aomsin>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_wip_state]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) 
	,@emp_no varchar(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @device_slip_id int = 0
	DECLARE @step_no int = 0
	DECLARE @job_name varchar(50) = null
	DECLARE @process_name varchar(50) = null 
	DECLARE @emp_no_id int = 0
	DECLARE @step_no_value int = 0
	DECLARE @process_id_value int = 0
	DECLARE @job_id_value int = 0
	DECLARE @job_name_last_value varchar(50) = null
	DECLARE @process_name_last_value varchar(50) = null


    -- Insert statements for procedure here
	select @emp_no_id = id from APCSProDB.man.users where emp_num = @emp_no
	select @emp_no_id as op_id
	-- Start Check table name
	IF @lot_no is not null
	BEGIN
		SELECT @device_slip_id = device_slip_id,@step_no = step_no 
		FROM [APCSProDB].[trans].[lots] 
		--WHERE lot_no = '2107A7090V'
		WHERE lot_no = @lot_no

		IF (@device_slip_id != 0) and (@step_no != 0)
		BEGIN
			--job now
			SELECT TOP 1 @job_name = [jobs].[name], @process_name = [processes].[name]
			FROM [APCSProDB].[method].[device_flows] 
				INNER JOIN [APCSProDB].[method].[jobs] 
					ON [device_flows].[job_id] = [jobs].[id]
				INNER JOIN  [APCSProDB].[method].[processes] 
					ON [jobs].[process_id] = [processes].[id] 
			WHERE device_slip_id = @device_slip_id
				and step_no = @step_no

			SELECT @job_name,@process_name

			--last job
			SELECT Top 1 
			     @step_no_value = [device_flows].step_no
				,@process_id_value = [device_flows].act_process_id
				,@job_id_value = [device_flows].job_id
				,@job_name_last_value = [jobs].[name] 
				,@process_name_last_value = [processes].[name] 
			FROM [APCSProDB].[method].[device_flows]
				INNER JOIN (SELECT max(step_no) as step_no 
								FROM [APCSProDB].[method].[device_flows] 
							WHERE device_slip_id = @device_slip_id
							)as device_flows2 
					ON device_flows.step_no = device_flows2.step_no
				INNER JOIN [APCSProDB].[method].[jobs] 
					ON [device_flows].[job_id] = [jobs].[id] 
				INNER JOIN [APCSProDB].[method].[processes]
					ON [jobs].[process_id] = [processes].[id] 
			WHERE device_slip_id = @device_slip_id
				AND device_flows.is_skipped != 1

			--SELECT @step_no_value,@process_id_value,@job_id_value,@job_name_last_value,@process_name_last_value

			BEGIN TRY 
				IF @lot_no != ''
				BEGIN
					IF @process_name != @process_name_last_value
					BEGIN
						--UPDATE APCSProDB.trans.lots 
						--SET wip_state = 20
						--,process_state = 0
						--,quality_state = 0
						--,first_ins_state = 0
						--,final_ins_state = 0
						--,is_special_flow = 0
						--,special_flow_id = 0
						----,step_no = @step_no_value  --close 2022/02/02 time : 14.35
						----,act_process_id = @process_id_value
						----,act_job_id = @job_id_value
						--,updated_by = @emp_no_id
						--,[carrier_no] = '-'
						--,[next_carrier_no] = ' '
						--where lot_no = @lot_no

						-----------<<< log exec
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
							, 'EXEC [trans].[sp_set_wip_state] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') + ''', @emp_no = ''' + ISNULL(CAST(@emp_no AS varchar),'') +''''
							, @lot_no
						----------->>> log exec
					END

					SELECT 'TRUE' AS Status ,'Update Success !!' AS Error_Message_ENG,N'Update Wip State สำเร็จ !!' AS Error_Message_THA
					RETURN
				END
			END TRY
			BEGIN CATCH 
					SELECT 'FALSE' AS Status ,'Update error !!' AS Error_Message_ENG,N'Update Wip State ไม่สำเร็จ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
					RETURN
			END CATCH

		END

		
	END

END



