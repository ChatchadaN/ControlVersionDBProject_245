-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_flow_details_001]
	@flow_pattern_id INT = 0,
    @step_no INT = 0,
    @operation_category tinyint,
	@state_name nvarchar(30) = NULL,
	@operation_name nvarchar(30) = NULL,
    @waiting_hours INT,
    @limit_time_until1 tinyint,
    @time_limit1 INT,
    @is_used tinyint,
	@emp_code VARCHAR(6)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @emp_id INT
	DECLARE @is_record INT = 0

	SELECT @emp_id = id FROM [DWH].[man].[employees] WHERE emp_code = @emp_code
	-- SET @emp_id = 703

	SELECT @is_record = flow_pattern_id FROM APCSProDB.material.flow_details WHERE flow_pattern_id = @flow_pattern_id AND step_no = @step_no

	BEGIN TRANSACTION
	IF @is_record IS NOT NULL AND @is_record <> 0
		-- UPDATE STATEMENT
		BEGIN
		BEGIN TRY
			UPDATE APCSProDB.material.flow_details SET
				[operation_category] = @operation_category,
				[state_name] = @state_name,
				[operation_name] = @operation_name,
				[waiting_hours] = @waiting_hours,
				[limit_time_until1] = @limit_time_until1,
				[time_limit1] = @time_limit1,
				[is_used] = @is_used,
				[updated_at] = GETDATE(),
				[updated_by] = @emp_id
			WHERE [flow_pattern_id] = @flow_pattern_id
			AND step_no = @step_no

			INSERT INTO APCSProDB.material_hist.flow_details_hist
				([category], [flow_pattern_id] ,[step_no] ,[operation_category],[state_name],[operation_name],[waiting_hours] ,[limit_time_until1] ,[time_limit1] ,[is_used] ,[created_at] ,[created_by], [updated_at], [updated_by])
			SELECT 2 action_category,  flow_pattern_id, step_no, operation_category, state_name, operation_name, waiting_hours, limit_time_until1, time_limit1, is_used, created_at, created_by, updated_at, updated_by
				FROM APCSProDB.material.flow_details
				WHERE flow_pattern_id = @flow_pattern_id
				AND step_no = @step_no

			SELECT    'TRUE'      AS Is_Pass 
					, 'Success'	  AS Error_Message_ENG
					, N'บันทึกสำเร็จ' AS Error_Message_THA
					, '' AS Handling;
			COMMIT; 	

		END TRY		
		BEGIN CATCH
			ROLLBACK;
			SELECT  'FALSE' AS Is_Pass ,
					-- 'Recording fail. !!' AS Error_Message_ENG ,
					ERROR_MESSAGE() AS Error_Message_ENG ,
					N'การบันทึกผิดพลาด !!' AS Error_Message_THA,
					'' AS Handling;
		END CATCH
		END
	ELSE IF (@flow_pattern_id IS NOT NULL AND @flow_pattern_id <> 0) AND (@step_no IS NOT NULL AND @step_no <> 0)
		-- INSERT STATEMENT
		BEGIN
		BEGIN TRY

			INSERT INTO [APCSProDB].[material].[flow_details]
				([flow_pattern_id] ,[step_no] ,[operation_category] ,[state_name] ,[operation_name] ,[waiting_hours] ,[limit_time_until1] ,[time_limit1] ,[is_used] ,[created_at] ,[created_by])
			VALUES 
				(@flow_pattern_id, @step_no, @operation_category, @state_name, @operation_name, @waiting_hours, @limit_time_until1, @time_limit1, 1, GETDATE(), @emp_id)

			INSERT INTO [APCSProDB].[material_hist].[flow_details_hist]
				([category], [flow_pattern_id] ,[step_no] ,[operation_category] ,[state_name],[operation_name] ,[waiting_hours] ,[limit_time_until1] ,[time_limit1] ,[is_used] ,[created_at] ,[created_by])
			VALUES 
				(1, @flow_pattern_id, @step_no, @operation_category, @state_name, @operation_name, @waiting_hours, @limit_time_until1, @time_limit1, 1, GETDATE(), @emp_id)

			SELECT    'TRUE'      AS Is_Pass 
					, 'Success'	  AS Error_Message_ENG
					, N'บันทึกสำเร็จ' AS Error_Message_THA
					, '' AS Handling;

			COMMIT; 	

		END TRY
		BEGIN CATCH
			ROLLBACK;
			SELECT  'FALSE' AS Is_Pass ,
					-- 'Recording fail. !!' AS Error_Message_ENG ,
					ERROR_MESSAGE() AS Error_Message_ENG ,
					N'การบันทึกผิดพลาด !!' AS Error_Message_THA,
					'' AS Handling;
		END CATCH
		END

	ELSE
		BEGIN
		ROLLBACK;
		SELECT  'FALSE' AS Is_Pass ,
				'Recording fail. !!' AS Error_Message_ENG ,
				-- ERROR_MESSAGE() AS Error_Message_ENG ,
				N'การบันทึกผิดพลาด !!' AS Error_Message_THA,
				'' AS Handling;
		END

END
