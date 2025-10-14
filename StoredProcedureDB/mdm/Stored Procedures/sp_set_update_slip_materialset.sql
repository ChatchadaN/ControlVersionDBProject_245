-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_update_slip_materialset]
	-- Add the parameters for the stored procedure here
	@slip_id AS INT,
	@mat_id AS INT,
	@process AS VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		IF @process = 'OGI' BEGIN
			----/////////////////// Update Device Flows
			UPDATE [APCSProDB].[method].[device_flows]
                SET [material_set_id] = @mat_id
            WHERE device_slip_id = @slip_id AND job_id = 317

			--/////////////////// Insert History
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
		   WHERE device_slip_id = @slip_id AND job_id = 317)
		 --SELECT 'TRUE' AS Is_Pass, 'Successed !!' AS Error_Message_ENG, N'บันทึกข้อมูลเรียบร้อย.' AS Error_Message_THA	
		END
		ELSE BEGIN
			----/////////////////// Update Device Flows
			UPDATE [APCSProDB].[method].[device_flows]
                SET [material_set_id] = @mat_id
            WHERE device_slip_id = @slip_id AND job_id = 289

			--/////////////////// Insert History
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
			WHERE device_slip_id = @slip_id AND job_id = 289)
			--SELECT 'TRUE' AS Is_Pass, 'Successed !!' AS Error_Message_ENG, N'บันทึกข้อมูลเรียบร้อย.' AS Error_Message_THA	
		END

		COMMIT; 
		SELECT 'TRUE' AS Is_Pass, 'Successed !!' AS Error_Message_ENG, N'บันทึกข้อมูลเรียบร้อย.' AS Error_Message_THA		
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass, 'Update Faild !!' AS Error_Message_ENG, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
	END CATCH
END
