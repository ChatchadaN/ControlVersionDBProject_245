-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_clear_special_flow_ver_009]
	-- Add the parameters for the stored procedure here
	@lot_id INT, 
	@step_no INT, 
	@appname VARCHAR(30) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	---# (1) LOG EXEC
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [atom].[sp_set_clear_special_flow_ver_009] @lot_id = ''' + ISNULL( CAST( @lot_id AS VARCHAR ), '' ) 
			+ ''', @step_no = ''' + ISNULL( CAST( @step_no AS VARCHAR ), '' ) 
			+ ''',@appname = ''' + ISNULL( CAST( @appname AS VARCHAR ), '' )  + ''''
		, ( SELECT CAST( [lot_no] AS VARCHAR ) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id );

	INSERT INTO [StoredProcedureDB].[dbo].[exec_spdb_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [storedprocedname]
		, [lot_no]
		, [command_text] )
	SELECT GETDATE() --AS [record_at]
		, 4 AS [record_class]
		, ORIGINAL_LOGIN() --AS [login_name]
		, HOST_NAME() --AS [hostname]
		, APP_NAME() --AS [appname]
		, N'[StoredProcedureDB].[atom].[sp_set_clear_special_flow_ver_009]' --AS [storedprocedname]
		, ( SELECT CAST( [lot_no] AS VARCHAR ) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id ) --AS [lot_no]
		, '@lot_id = ' + ISNULL( CAST( @lot_id AS VARCHAR ), 'NULL' ) 
			+ ' ,@step_no = ' + ISNULL( CAST( @step_no AS VARCHAR ), 'NULL' ) 
			+ ' ,@appname = ''' + ISNULL( CAST( @appname AS VARCHAR ), '' ) + ''''; --AS [command_text]
	
	---# (2) DECLARE
	DECLARE @next_step INT = 0, --# 0:Fail  1:Pass
		@status_add_flow INT = 0, --# 0:ลบไม่ได้ 1:ลบได้
		@step_no_wip INT = 0,
		@special_id INT = NULL,
		@lot_special_id INT = NULL,
		@count_delete INT = 0,
		@max_step_no INT = NULL,
		@run_status INT = NULL,
		@special_flow_id_update INT = NULL,
		@is_update_step_no INT = 0,  --# 0:ไม่ update 1:update
		@s_stepno INT = NULL,
		@s_process INT = NULL,
		@s_job INT = NULL

	---# (3) CHECK STEP NO
	IF EXISTS ( 
		SELECT 1 
		FROM [APCSProDB].[method].[device_flows] 
		WHERE [device_slip_id] = ( 
			SELECT [device_slip_id] 
			FROM [APCSProDB].[trans].[lots] 
			WHERE [lots].[id] = @lot_id 
		) 
		AND [step_no] = @step_no 
	) 
	BEGIN
		SELECT 'FALSE' AS Is_Pass 
			, 'Cannot cancel master flow. !!' AS Error_Message_ENG
			, N'ไม่สามารถยกเลิก master flow ได้ !!' AS Error_Message_THA 
			, '' AS Handling;
		RETURN;
	END
	ELSE IF EXISTS ( 
		SELECT 2 
		FROM [APCSProDB].[trans].[special_flows]
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
		WHERE [special_flows].[lot_id] = @lot_id 
			AND [lot_special_flows].[step_no] = @step_no 
	) 
	BEGIN
		SET @next_step = 1;
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Is_Pass 
			, 'Not found step no. !!' AS Error_Message_ENG
			, N'ไม่พบ step no !!' AS Error_Message_THA 
			, '' AS Handling;
		RETURN;
	END

	---# (4) CHECK RECORD_CLASS LAST OF STEP_NO
	SELECT @run_status = [table].[record_class]
	FROM (
		SELECT [lot_special_flows].[step_no]
			, [lot_special_flows].[next_step_no]
			, [lot_process_records].[recorded_at]
			, [lot_process_records].[record_class]
			, [item_labels].[label_eng]
			, [item_labels].[val]
			, [special_flows].[id] AS [special_flow_id]
			, [lot_special_flows].[id] AS [lot_special_flow_id]
			, ROW_NUMBER () OVER ( PARTITION BY [lot_special_flows].[step_no] ORDER BY [lot_process_records].[recorded_at] DESC ) AS [rowmax]
		FROM [APCSProDB].[trans].[lot_special_flows]
		LEFT JOIN [APCSProDB].[trans].[special_flows] ON [lot_special_flows].[special_flow_id] = [special_flows].[id]
		LEFT JOIN [APCSProDB].[trans].[lot_process_records] ON [special_flows].[lot_id] = [lot_process_records].[lot_id]
			AND [lot_special_flows].[step_no] = [lot_process_records].[step_no]
			AND [lot_process_records].[job_id] = [lot_special_flows].[job_id]
		LEFT JOIN [APCSProDB].[trans].[item_labels] ON [item_labels].[name] = 'lot_process_records.record_class' 
			AND [item_labels].[val] = [lot_process_records].[record_class] 
		WHERE [special_flows].[lot_id] = @lot_id
			AND [lot_special_flows].[step_no] = @step_no
	) AS [table]
	WHERE [table].[rowmax] = 1;

	---# (5) CHECK ADD SPECIAL FLOW
	SELECT @step_no_wip = ISNULL( [lot_special_flows].[step_no], [lots].[step_no] )
		, @special_id = [special_flows].[id]
		, @lot_special_id = [lot_special_flows].[id]
	FROM [APCSProDB].[trans].[lots]
	LEFT JOIN [APCSProDB].[trans].[special_flows] ON [lots].[is_special_flow] = 1
		AND [lots].[special_flow_id] = [special_flows].[id]
		AND [lots].[id] = [special_flows].[lot_id]
	LEFT JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
		AND [special_flows].[step_no] = [lot_special_flows].[step_no]
	WHERE [lots].[id] = @lot_id;

	IF ( @step_no_wip IS NOT NULL )
	BEGIN
		IF (@step_no_wip <= @step_no)
		BEGIN
			SET @status_add_flow = 1; --# 1:ลบได้
		END
		ELSE
		BEGIN
			SET @status_add_flow = 0; --# 0:ลบไม่ได้
		END
	END
	ELSE
	BEGIN
		SET @status_add_flow = 0; --# 0:ลบไม่ได้
	END

	---# (6) CONDITION
	IF ( @status_add_flow = 1 )
	BEGIN
		IF ( @step_no = @step_no_wip AND @special_id IS NOT NULL )
		BEGIN
			----# DELETE SPECIAL FLOW FLOW is_special_flow = 1
			---- ** DELETE
			IF ( @run_status IS NULL OR @run_status IN (25,4) ) --# 25:IntoSpecialFlow, 4:LotOpened
			BEGIN
				--PRINT 'NULL,25,4'
				---- ** GET COUNT FLOW
				SET @count_delete = ( 
					SELECT COUNT( [special_flow_id] ) 
					FROM [APCSProDB].[trans].[lot_special_flows]
					WHERE [special_flow_id] = @special_id 
				);

				---- ** GET MAX STEP FLOW
				SET @max_step_no = (
					SELECT MAX( [step_no] ) 
					FROM [APCSProDB].[trans].[lot_special_flows] 
					WHERE [special_flow_id] = @special_id
				);

				---- ** DELETE lot_special_flows
				DELETE FROM [APCSProDB].[trans].[lot_special_flows] 
				WHERE [special_flow_id] = @special_id
					AND [id] = @lot_special_id;

				---- ** DELETE lot_special_flows_sblsyl
				IF EXISTS (
					SELECT [lot_special_flow_id] 
					FROM [APCSProDB].[trans].[lot_special_flows_sblsyl]
					WHERE [lot_special_flow_id] = @lot_special_id
				)
				BEGIN
					DELETE FROM [APCSProDB].[trans].[lot_special_flows_sblsyl]
					WHERE [lot_special_flow_id] = @lot_special_id;
				END

				IF ( @count_delete = 1 )
				BEGIN
					---- ** DELETE special_flows
					DELETE FROM [APCSProDB].[trans].[special_flows] 
					WHERE [id] = @special_id;
					
					SET @is_update_step_no = 1;
				END
				ELSE
				BEGIN
					---- ** UPDATE STEP NO
					UPDATE [APCSProDB].[trans].[lot_special_flows]
					SET [step_no] = [step_no] - 1
						, [next_step_no] = [next_step_no] - 1
					WHERE [special_flow_id] = @special_id
						AND [step_no] > @step_no;

					IF (@step_no = @max_step_no)
					BEGIN
						---- ** UPDATE MAX STEP NO
						UPDATE [APCSProDB].[trans].[lot_special_flows]
						SET [next_step_no] = [step_no]
						WHERE [special_flow_id] = @special_id
							AND [step_no] = ( 
								SELECT MAX( [step_no] ) 
								FROM [APCSProDB].[trans].[lot_special_flows] 
								WHERE [special_flow_id] = @special_id 
							);

						IF ( @step_no = ( SELECT [step_no] FROM [APCSProDB].[trans].[special_flows] WHERE [id] = @special_id ) )
						BEGIN
							UPDATE [APCSProDB].[trans].[special_flows]
							SET [step_no] = ( 
									SELECT MAX( [step_no] ) 
									FROM [APCSProDB].[trans].[lot_special_flows] 
									WHERE [special_flow_id] = @special_id 
								)
								, [exec_state] = 1
								, [wip_state] = 100
							WHERE [id] = @special_id;

							SET @is_update_step_no = 1;
						END
					END
				END
			END
			ELSE IF ( @run_status IN (23,6) ) --# 23:AbnormalEndBeforeProcess, 6:LotCancel
			BEGIN
				--PRINT '23,6'
				---- ** GET COUNT FLOW
				SET @count_delete = ( 
					SELECT COUNT( [special_flow_id] ) 
					FROM [APCSProDB].[trans].[lot_special_flows]
					WHERE [special_flow_id] = @special_id 
				);

				IF ( @count_delete > 1 )
				BEGIN
					---- ** SET STEP NO special_flows
					UPDATE [APCSProDB].[trans].[special_flows]
					SET [step_no] = (
						SELECT TOP 1 [next_step_no]
						FROM [APCSProDB].[trans].[lot_special_flows]
						WHERE special_flow_id = @special_id
							AND [step_no] = @step_no
					)
					WHERE [id] = @special_id;
				END
				ELSE IF ( @count_delete = 1 )  BEGIN
					---- ** SET wip_state special_flows = 100
					UPDATE [APCSProDB].[trans].[special_flows]
					SET [exec_state] = 1
						, [wip_state] = 100
					WHERE [id] = @special_id;

					SET @is_update_step_no = 1;
				END
			END
			ELSE
			BEGIN
				---- ** RETURN
				SELECT 'FALSE' AS Is_Pass 
					, 'Cannot cancel flow because lot has already been processed. !!' AS Error_Message_ENG
					, N'ไม่สามารถยกเลิก flow ได้ เนื่องจากมีการ processed lot แล้ว !!' AS Error_Message_THA 
					, '' AS Handling;
				RETURN;
			END
		END
		ELSE
		BEGIN
			----# DELETE SPECIAL FLOW FLOW is_special_flow = 0
			---- ** GET special_id and lot_special_id 
			SELECT @special_id = special_flows.id
				, @lot_special_id = lot_special_flows.id
			FROM [APCSProDB].[trans].[special_flows]
			LEFT JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
			WHERE [special_flows].[lot_id] = @lot_id
				AND [lot_special_flows].[step_no] = @step_no;

			---- ** GET COUNT FLOW
			SET @count_delete = ( 
				SELECT COUNT( [special_flow_id] ) 
				FROM [APCSProDB].[trans].[lot_special_flows]
				WHERE [special_flow_id] = @special_id 
			);

			---- ** GET MAX STEP FLOW
			SET @max_step_no = (
				SELECT MAX( [step_no] ) 
				FROM [APCSProDB].[trans].[lot_special_flows] 
				WHERE [special_flow_id] = @special_id
			);

			---- ** DELETE lot_special_flows
			DELETE FROM [APCSProDB].[trans].[lot_special_flows] 
			WHERE [special_flow_id] = @special_id
				AND [id] = @lot_special_id;

			---- ** DELETE lot_special_flows_sblsyl
			IF EXISTS (
				SELECT [lot_special_flow_id] 
				FROM [APCSProDB].[trans].[lot_special_flows_sblsyl]
				WHERE [lot_special_flow_id] = @lot_special_id
			)
			BEGIN
				DELETE FROM [APCSProDB].[trans].[lot_special_flows_sblsyl]
				WHERE [lot_special_flow_id] = @lot_special_id;
			END

			IF ( @count_delete = 1 )
			BEGIN
				---- ** DELETE special_flows
				DELETE FROM [APCSProDB].[trans].[special_flows] 
				WHERE [id] = @special_id;
			END
			ELSE
			BEGIN
				---- ** UPDATE STEP NO
				UPDATE [APCSProDB].[trans].[lot_special_flows]
				SET [step_no] = [step_no] - 1
					, [next_step_no] = [next_step_no] - 1
				WHERE [special_flow_id] = @special_id
					AND [step_no] > @step_no;

				IF (@step_no = @max_step_no)
				BEGIN
					---- ** UPDATE MAX STEP NO
					UPDATE [APCSProDB].[trans].[lot_special_flows]
					SET [next_step_no] = [step_no]
					WHERE [special_flow_id] = @special_id
						AND [step_no] = ( 
							SELECT MAX( [step_no] ) 
							FROM [APCSProDB].[trans].[lot_special_flows] 
							WHERE [special_flow_id] = @special_id 
						);
				END
			END
		END
	
		---- ** CHECK UPDATE STEP NO			
		IF ( @is_update_step_no = 1 )
		BEGIN
			---- ** GET special_flow_id
			SELECT TOP 1 @special_flow_id_update = [lot_special_flows].[special_flow_id]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDB].[trans].[special_flows] ON [lots].[id] = [special_flows].[lot_id]
			INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
			WHERE [lots].[id] = @lot_id
				AND [lot_special_flows].[step_no] >= [lots].[step_no]
				AND [special_flows].[wip_state] = 20
			ORDER BY [lot_special_flows].[step_no] ASC;

			---- ** SET STEP FLOW
			IF ( @step_no > ( SELECT [lots].[step_no] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id ) )
			BEGIN
				SELECT @s_stepno = [device_flows].[step_no]
					, @s_process = [device_flows].[act_process_id]
					, @s_job = [device_flows].[job_id]
				FROM (
					SELECT [lots].[special_flow_id]
						, [lots].[is_special_flow]
						, [lots].[device_slip_id]
						, [lots].[step_no]
					FROM [APCSProDB].[trans].[lots]
					WHERE [lots].[id] = @lot_id
				) AS [lots]
				INNER JOIN [APCSProDB].[method].[device_flows] ON [lots].[device_slip_id] = [device_flows].[device_slip_id]
					AND [device_flows].is_skipped != 1	
				WHERE [device_flows].[step_no] = ( 
					SELECT [device_flows].[next_step_no]
					FROM (
						SELECT [lots].[special_flow_id]
							, [lots].[is_special_flow]
							, [lots].[device_slip_id]
							, [lots].[step_no]
						FROM [APCSProDB].[trans].[lots]
						WHERE [lots].[id] = @lot_id
					) AS [lots]
					INNER JOIN [APCSProDB].[method].[device_flows] ON [lots].[device_slip_id] = [device_flows].[device_slip_id]
						AND [device_flows].is_skipped != 1
					WHERE [device_flows].[step_no] = [lots].[step_no]
				);
			END
			ELSE 
			BEGIN
				SELECT @s_stepno = [device_flows].[step_no]
					, @s_process = [device_flows].[act_process_id]
					, @s_job = [device_flows].[job_id]
				FROM (
					SELECT [lots].[special_flow_id]
						, [lots].[is_special_flow]
						, [lots].[device_slip_id]
						, [lots].[step_no]
					FROM [APCSProDB].[trans].[lots]
					WHERE [lots].[id] = @lot_id
				) AS [lots]
				INNER JOIN [APCSProDB].[method].[device_flows] ON [lots].[device_slip_id] = [device_flows].[device_slip_id]
					AND [device_flows].is_skipped != 1	
				WHERE [device_flows].[step_no] = [lots].[step_no];
			END

			---- ** UPDATE TABLE trans.lots
			UPDATE [APCSProDB].[trans].[lots]
			SET [is_special_flow] = 0
				, [special_flow_id] = @special_flow_id_update
				, [quality_state] = 0
				, [step_no] = @s_stepno
				, [act_process_id] = @s_process
				, [act_job_id] = @s_job
			WHERE [id] = @lot_id;
		END

		---- ** RETURN
		SELECT 'TRUE' AS Is_Pass 
			, '' AS Error_Message_ENG
			, '' AS Error_Message_THA 
			, '' AS Handling;
		RETURN;
	END
	ELSE
	BEGIN
		---- ** RETURN
		SELECT 'FALSE' AS Is_Pass 
			, 'Cannot cancel flow. !!' AS Error_Message_ENG
			, N'ไม่สามารถยกเลิก flow ได้ !!' AS Error_Message_THA 
			, '' AS Handling;
		RETURN;
	END
END
