-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_update_device_flow]
	-- Add the parameters for the stored procedure here
	@slip_id AS INT,
	@job_id AS VARCHAR(10),
	@step_no AS INT = NULL,
	@device_flow_id AS INT = NULL,
	@recipe AS VARCHAR(20) = NULL,
	@new_lead_time AS INT = NULL,
	@new_process_minutes AS INT = NULL,		
	@new_sbl_upper AS DECIMAL = NULL,
	@new_syl_lower AS DECIMAL = NULL,
	@state AS INT
	--1: @recipe 2: @new_lead_time 3:@new_process_minutes 4: @new_sbl_upper 5: @new_syl_lower

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY

		IF(@state = 1)
		BEGIN
			PRINT '1 @recipe'
		
			UPDATE APCSProDB.method.device_flows 
			SET recipe = @recipe
			WHERE device_slip_id = @slip_id  
			AND job_id = @job_id

			--Insert History
			INSERT INTO [APCSProDB].[method_hist].[device_flows_hist]
			   ([category]
			   ,[id]
			   ,[device_slip_id]
			   ,[step_no]
			   ,[next_step_no]
			   ,[act_process_id]
			   ,[job_id]
			   ,[act_package_flow_id]
			   ,[permitted_machine_id]
			   ,[process_minutes]
			   ,[sum_process_minutes]
			   ,[recipe]
			   ,[ng_retest_permitted]
			   ,[is_skipped]
			   ,[material_set_id]
			   ,[jig_set_id]
			   ,[issue_label_type]
			   ,[bincode_set_id]
			   ,[lead_time]
			   ,[lead_time_sum]
			   ,[is_sblsyl])

			(SELECT 2 -- Update
			   ,[id]
			   ,[device_slip_id]
			   ,[step_no]
			   ,[next_step_no]
			   ,[act_process_id]
			   ,[job_id]
			   ,[act_package_flow_id]
			   ,[permitted_machine_id]
			   ,[process_minutes]
			   ,[sum_process_minutes]
			   ,[recipe]
			   ,[ng_retest_permitted]
			   ,[is_skipped]
			   ,[material_set_id]
			   ,[jig_set_id]
			   ,[issue_label_type]
			   ,[bincode_set_id]
			   ,[lead_time]
			   ,[lead_time_sum]
			   ,[is_sblsyl]
			FROM APCSProDB.method.device_flows
			WHERE device_slip_id = @slip_id AND job_id = @job_id) 

		END
		ELSE IF(@state = 4)
		BEGIN
			PRINT '4 @new_sbl_upper'
		
			UPDATE APCSProDB.method.device_flows_sblsyl	
			SET sbl_upper_limit = @new_sbl_upper
			WHERE device_flow_id = @device_flow_id

			INSERT INTO APCSProDB.method_hist.device_flows_sblsyl_hist
				([category]
				  ,[device_flow_id]
				  ,[sbl_upper_limit]
				  ,[syl_lower_limit]
				  ,[created_at]
				  ,[created_by]
				  ,[updated_at]
				  ,[updated_by]
				  ,[is_single_process_judgement])

			(SELECT 2 --update
				,[device_flow_id]
				,[sbl_upper_limit]
				,[syl_lower_limit]
				,[created_at]
				,[created_by]
				,[updated_at]
				,[updated_by]
				,[is_single_process_judgement]
			FROM [APCSProDB].[method].[device_flows_sblsyl]
			WHERE device_flow_id = @device_flow_id)

		END
		ELSE IF(@state = 5)
		BEGIN
			PRINT '5 @new_syl_lower'
		
			UPDATE APCSProDB.method.device_flows_sblsyl
			SET syl_lower_limit = @new_syl_lower
			WHERE device_flow_id = @device_flow_id
		
			INSERT INTO APCSProDB.method_hist.device_flows_sblsyl_hist
				([category]
				  ,[device_flow_id]
				  ,[sbl_upper_limit]
				  ,[syl_lower_limit]
				  ,[created_at]
				  ,[created_by]
				  ,[updated_at]
				  ,[updated_by]
				  ,[is_single_process_judgement])

			(SELECT 2 --update
				,[device_flow_id]
				,[sbl_upper_limit]
				,[syl_lower_limit]
				,[created_at]
				,[created_by]
				,[updated_at]
				,[updated_by]
				,[is_single_process_judgement]
			FROM [APCSProDB].[method].[device_flows_sblsyl]
			WHERE device_flow_id = @device_flow_id)

		END
		ELSE IF(@state = 2)
		BEGIN
			PRINT '2 @new_lead_time'

			-- Update new lead_time 
			UPDATE APCSProDB.method.device_flows 
			SET lead_time = @new_lead_time
			WHERE device_slip_id = @slip_id
			  AND job_id = @job_id;

			--find previous_lead_time_sum
			DECLARE @previous_lead_time_sum INT;

			SELECT @previous_lead_time_sum = ISNULL((
					SELECT TOP 1 lead_time_sum 
					FROM APCSProDB.method.device_flows 
					WHERE device_slip_id = @slip_id
					AND step_no < @step_no
					ORDER BY step_no DESC
			), 0);

			DECLARE @current_lead_time_sum INT = @previous_lead_time_sum + @new_lead_time;

			-- Update lead_time_sum
			UPDATE APCSProDB.method.device_flows 
			SET Lead_time_sum = @current_lead_time_sum
			WHERE device_slip_id = @slip_id
			   AND job_id = @job_id;

			--Update lead_time_sum loop
			DECLARE @update_count INT = 0;
			DECLARE @last_updated_step INT = @step_no;

			WHILE EXISTS(SELECT TOP 1 Lead_time FROM APCSProDB.method.device_flows  WHERE device_slip_id = @slip_id AND step_no > @last_updated_step ORDER BY step_no ASC)
			BEGIN

				DECLARE @next_lead_time INT;
				DECLARE @next_step_no INT;

				--Find next lead_time
				SELECT TOP 1 @next_lead_time = Lead_time, @next_step_no = step_no
				FROM APCSProDB.method.device_flows 
				WHERE device_slip_id = @slip_id
				AND step_no > @last_updated_step
				ORDER BY step_no ASC;

				SET @current_lead_time_sum = @current_lead_time_sum + @next_lead_time;

				UPDATE APCSProDB.method.device_flows 
				SET Lead_time_sum = @current_lead_time_sum
				WHERE device_slip_id = @slip_id
				AND step_no = @next_step_no;

				--Update step_no
				SET @last_updated_step = @next_step_no;

				--Counter Update
				SET @update_count = @update_count + 1;
			END

			--Insert History
			INSERT INTO [APCSProDB].[method_hist].[device_flows_hist]
			   ([category]
			   ,[id]
			   ,[device_slip_id]
			   ,[step_no]
			   ,[next_step_no]
			   ,[act_process_id]
			   ,[job_id]
			   ,[act_package_flow_id]
			   ,[permitted_machine_id]
			   ,[process_minutes]
			   ,[sum_process_minutes]
			   ,[recipe]
			   ,[ng_retest_permitted]
			   ,[is_skipped]
			   ,[material_set_id]
			   ,[jig_set_id]
			   ,[issue_label_type]
			   ,[bincode_set_id]
			   ,[lead_time]
			   ,[lead_time_sum]
			   ,[is_sblsyl])

			(SELECT 2 -- Update
			   ,[id]
			   ,[device_slip_id]
			   ,[step_no]
			   ,[next_step_no]
			   ,[act_process_id]
			   ,[job_id]
			   ,[act_package_flow_id]
			   ,[permitted_machine_id]
			   ,[process_minutes]
			   ,[sum_process_minutes]
			   ,[recipe]
			   ,[ng_retest_permitted]
			   ,[is_skipped]
			   ,[material_set_id]
			   ,[jig_set_id]
			   ,[issue_label_type]
			   ,[bincode_set_id]
			   ,[lead_time]
			   ,[lead_time_sum]
			   ,[is_sblsyl]
			FROM APCSProDB.method.device_flows
			WHERE device_slip_id = @slip_id AND job_id = @job_id) 

		END
		ELSE IF(@state = 3)
		BEGIN
			PRINT '3 @new_process_minutes'

			-- Update process_minutes 
			UPDATE APCSProDB.method.device_flows
			SET process_minutes = @new_process_minutes
			WHERE device_slip_id = @slip_id
			  AND job_id = @job_id
			  AND step_no = @step_no;

			-- find previous_lead_time_sum
			DECLARE @previous_process_minute_sum INT;

			SELECT @previous_process_minute_sum = ISNULL((
					SELECT TOP 1 sum_process_minutes 
					FROM APCSProDB.method.device_flows
					WHERE device_slip_id = @slip_id
					AND step_no < @step_no
					ORDER BY step_no DESC
			), 0);

			DECLARE @current_process_minute_sum INT = @previous_process_minute_sum + @new_process_minutes;

			-- Update process_minute_sum for current step_no
			UPDATE APCSProDB.method.device_flows
			SET sum_process_minutes = @current_process_minute_sum
			WHERE device_slip_id = @slip_id
			  AND job_id = @job_id
			  AND step_no = @step_no;

			-- Update process_minute_sum loop for the following steps
			DECLARE @update_pcmin_count INT = 0;
			DECLARE @last_updated_step_processmin INT = @step_no;

			WHILE EXISTS(SELECT TOP 1 step_no FROM APCSProDB.method.device_flows WHERE device_slip_id = @slip_id AND step_no > @last_updated_step_processmin ORDER BY step_no ASC)
			BEGIN
				DECLARE @next_process_minute INT;
				DECLARE @next_step_no_processmin INT;

				-- Find next step_no and its process_minutes
				SELECT TOP 1 @next_step_no_processmin = step_no, 
							 @next_process_minute = ISNULL(process_minutes, 0)
				FROM APCSProDB.method.device_flows
				WHERE device_slip_id = @slip_id
				AND step_no > @last_updated_step_processmin
				ORDER BY step_no ASC;

				-- Update the current sum of process minutes
				SET @current_process_minute_sum = @current_process_minute_sum + @next_process_minute;

				-- Update the sum_process_minutes for the next step
				UPDATE APCSProDB.method.device_flows
				SET sum_process_minutes = @current_process_minute_sum
				WHERE device_slip_id = @slip_id
				AND step_no = @next_step_no_processmin;

				-- Update the last updated step_no
				SET @last_updated_step_processmin = @next_step_no_processmin;

				-- Counter Update
				SET @update_pcmin_count = @update_pcmin_count + 1;
			END

			--Insert History
			INSERT INTO [APCSProDB].[method_hist].[device_flows_hist]
			   ([category]
			   ,[id]
			   ,[device_slip_id]
			   ,[step_no]
			   ,[next_step_no]
			   ,[act_process_id]
			   ,[job_id]
			   ,[act_package_flow_id]
			   ,[permitted_machine_id]
			   ,[process_minutes]
			   ,[sum_process_minutes]
			   ,[recipe]
			   ,[ng_retest_permitted]
			   ,[is_skipped]
			   ,[material_set_id]
			   ,[jig_set_id]
			   ,[issue_label_type]
			   ,[bincode_set_id]
			   ,[lead_time]
			   ,[lead_time_sum]
			   ,[is_sblsyl])

			(SELECT 2 -- Update
			   ,[id]
			   ,[device_slip_id]
			   ,[step_no]
			   ,[next_step_no]
			   ,[act_process_id]
			   ,[job_id]
			   ,[act_package_flow_id]
			   ,[permitted_machine_id]
			   ,[process_minutes]
			   ,[sum_process_minutes]
			   ,[recipe]
			   ,[ng_retest_permitted]
			   ,[is_skipped]
			   ,[material_set_id]
			   ,[jig_set_id]
			   ,[issue_label_type]
			   ,[bincode_set_id]
			   ,[lead_time]
			   ,[lead_time_sum]
			   ,[is_sblsyl]
			FROM APCSProDB.method.device_flows
			WHERE device_slip_id = @slip_id AND job_id = @job_id) 
		END

		COMMIT; 
		SELECT 'TRUE' AS Is_Pass, 'Successed !!' AS Error_Message_ENG, N'บันทึกข้อมูลเรียบร้อย.' AS Error_Message_THA		
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass, 'Update Faild !!' AS Error_Message_ENG, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
	END CATCH
END