-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create 20211016,,>
-- Description:	<Description,,Release Lot>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_next_flow_ver_002]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----# TRY CATCH
	BEGIN TRY 
		----# TRY
		IF EXISTS (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no)
		BEGIN
			----# EXISTS lot_no

			----# (0) DECLARE PARAMETER
			DECLARE @lot_id INT = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no)
			--DECLARE @lot_id int = 2
			DECLARE @special_flow_id_update INT = NULL
			DECLARE @is_sp_flow INT = 0
			DECLARE @step_no INT = NULL
			DECLARE @step_flow INT = NULL
			DECLARE @step_flow_master INT = NULL
			DECLARE @table TABLE (
				special_flow_id INT,
				step_no INT,
				back_step_no INT
			)
			----# (0) END DECLARE PARAMETER

			----# (1) SET DATA SPECIAL FLOW
			----# (1.1) SET DATA STEP_NO, IS_SPECIAL_FLOW, STEP_NO_MASTER
			SELECT @step_no = ISNULL([lot_special_flows].[step_no], [lots].[step_no]) --AS [step_no]
				, @is_sp_flow = [lots].[is_special_flow]
				, @step_flow_master = [lots].[step_no]
			FROM [APCSProDB].[trans].[lots]
			LEFT JOIN [APCSProDB].[trans].[special_flows]
				ON [lots].[id] = [special_flows].[lot_id]
				AND [lots].[special_flow_id] = [special_flows].[id]
				AND [lots].[is_special_flow] = 1
			LEFT JOIN [APCSProDB].[trans].[lot_special_flows]
				ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
				AND [special_flows].[step_no] = [lot_special_flows].[step_no]
			WHERE [lots].[id] = @lot_id;
			----# (1.1) END SET DATA STEP_NO, IS_SPECIAL_FLOW, STEP_NO_MASTER

			----# (1.2) SET DATA LOT
			IF (@is_sp_flow = 0)
			BEGIN
				----# (1.2.1) IS_SPECIAL_FLOW = 0
				-----------------------------------------------------------------------------------------------------------
				INSERT INTO @table 
					( [special_flow_id]
					, [step_no]
					, [back_step_no] )
				SELECT [special_flow_id]
					, [step_no]
					, [back_step_no]
				FROM (
					----# FROM (1)
					SELECT [table].[step_no]
						, [table].[back_step_no]
						, ISNULL([special_flows].special_flow_id, 0) AS [special_flow_id]
						, [special_flows].[wip_state]
					FROM (
						----# FROM (2)
						SELECT t3.step_no
							, t3.back_step_no
							, ISNULL([device_flows].[next_step_no], MAX([device_flows].[next_step_no]) OVER (ORDER BY [t3].[back_step_no])) AS [next_step_no]
						FROM (
							----# FROM (3)
							SELECT [step_no]
								, [back_step_no]
								, [lot_id]
							FROM (
								----# FROM (4)
								SELECT LAG([step_no]) OVER (ORDER BY [step_no]) AS [step_no]
									, [step_no] AS [back_step_no]
									, @lot_id AS [lot_id]
								FROM (
									----# FROM (4.1)
									SELECT [device_flows].[step_no]
									FROM [APCSProDB].[method].[device_flows]
									INNER JOIN [APCSProDB].[method].[jobs] 
										ON [device_flows].[job_id] = [jobs].[id]
									WHERE [device_flows].[device_slip_id] = (SELECT [device_slip_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)	
										AND [device_flows].[is_skipped] = 0
									UNION ALL
									SELECT [lot_special_flows].[step_no]
									FROM [APCSProDB].[trans].[special_flows]
									LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
										ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
									WHERE [special_flows].[lot_id] = @lot_id
									----# END FROM (4.1)
								) AS [t1]
								UNION ALL
								SELECT MAX([step_no]) AS [step_no]
									, MAX([step_no]) AS [back_step_no]
									, @lot_id AS [lot_id]
								FROM (
									----# FROM (4.2)
									SELECT [device_flows].[step_no]
									FROM [APCSProDB].[method].[device_flows]
									INNER JOIN [APCSProDB].[method].[jobs] 
										ON [device_flows].[job_id] = [jobs].[id]
									WHERE [device_flows].[device_slip_id] = (SELECT [device_slip_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)	
										AND [device_flows].[is_skipped] = 0
									UNION ALL
									SELECT [lot_special_flows].[step_no]
									FROM [APCSProDB].[trans].[special_flows]
									LEFT JOIN [APCSProDB].[trans].[lot_special_flows] 
										ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
									WHERE [special_flows].[lot_id] = @lot_id
									----# END FROM (4.2)
								) AS [t2]
								----# END FROM (4)
							) AS [tsum]
							WHERE [tsum].[step_no] IS NOT NULL
							----# END FROM (3)
						) AS [t3]
						LEFT JOIN [APCSProDB].[method].[device_flows] 
							ON [device_flows].[device_slip_id] = (SELECT [device_slip_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)
							AND [device_flows].[step_no] = [t3].[step_no]
						----# END FROM (2)
					) as [table]
					LEFT JOIN (
						SELECT [lot_special_flows].[special_flow_id]
							, [lot_special_flows].[id] AS [lot_special_flows_id]
							, [lot_special_flows].[step_no]
							, [special_flows].[wip_state]
						FROM [APCSProDB].[trans].[lots]
						INNER JOIN [APCSProDB].[trans].[special_flows] 
							ON [lots].[id] = [special_flows].[lot_id]
						INNER JOIN [APCSProDB].[trans].[lot_special_flows] 
							ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [lots].[id] = @lot_id
					) AS [special_flows] on [table].step_no = [special_flows].[step_no]
					----# END FROM (1)
				) AS [table]
				WHERE [table].[wip_state] = 20
					AND [table].[special_flow_id] != 0
				ORDER BY [table].[step_no];
						
				DECLARE @id INT = NULL;

				IF EXISTS (SELECT 1 FROM @table WHERE [back_step_no] = @step_flow_master)
				BEGIN
					SET @id  = (SELECT TOP 1 [special_flow_id] FROM @table WHERE [back_step_no] = @step_flow_master);
					UPDATE [APCSProDB].[trans].[lots]
					SET [is_special_flow] = 1,
						[special_flow_id] = @id
					WHERE [id] = @lot_id;

					UPDATE [APCSProDB].[trans].[special_flows]
					SET [special_flows].[qty_in] = [lots].[qty_in]
						, [special_flows].[qty_pass] = [lots].[qty_pass]
						, [special_flows].[qty_fail] = [lots].[qty_fail]
						, [special_flows].[qty_last_pass] = [lots].[qty_last_pass]
						, [special_flows].[qty_last_fail] = [lots].[qty_last_fail]
						, [special_flows].[qty_pass_step_sum] = [lots].[qty_pass_step_sum]
						, [special_flows].[qty_fail_step_sum] = [lots].[qty_fail_step_sum]
						, [special_flows].[qty_divided] = [lots].[qty_divided]
						, [special_flows].[qty_hasuu] = [lots].[qty_hasuu]
						, [special_flows].[qty_out] = [lots].[qty_out]
						, [special_flows].[qty_frame_in] = [lots].[qty_frame_in]
						, [special_flows].[qty_frame_pass] = [lots].[qty_frame_pass]
						, [special_flows].[qty_frame_fail] = [lots].[qty_frame_fail]
						, [special_flows].[qty_frame_last_pass] = [lots].[qty_frame_last_pass]
						, [special_flows].[qty_frame_last_fail] = [lots].[qty_frame_last_fail]
						, [special_flows].[qty_frame_pass_step_sum] = [lots].[qty_frame_pass_step_sum]
						, [special_flows].[qty_frame_fail_step_sum]	 = [lots].[qty_frame_fail_step_sum]
						, [special_flows].[qty_p_nashi] = [lots].[qty_p_nashi]
						, [special_flows].[qty_front_ng] = [lots].[qty_front_ng]
						, [special_flows].[qty_marker] = [lots].[qty_marker]
						, [special_flows].[qty_cut_frame] = [lots].[qty_cut_frame]
					FROM [APCSProDB].[trans].[special_flows]
					INNER JOIN [APCSProDB].[trans].[lots] 
						ON [special_flows].[lot_id] = [lots].[id]
					WHERE [special_flows].[id] = @id 
						AND [special_flows].[lot_id] = @lot_id;

					--------------------------------------------------------------
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
						, 'EXEC [atom].[sp_set_next_flow_ver_002] update special flow is now(1) special_flow_id = ' + IIF(CAST(IIF(@id IS NULL,-1,@id) AS VARCHAR(20)) = -1,'NULL',CAST(IIF(@id IS NULL,-1,@id) AS VARCHAR(20)))
						, @lot_no
					--------------------------------------------------------------
					SELECT 'TRUE' AS Status
						, 'Update special flow now Success !!' AS Error_Message_ENG
						, N'Update special flow now เรียบร้อย !!' AS Error_Message_THA
				END
				ELSE
				BEGIN
					SET @id  = (SELECT TOP 1 [special_flow_id] FROM @table WHERE [step_no] >= @step_no order by step_no);
					UPDATE [APCSProDB].[trans].[lots]
					SET [is_special_flow] = 0,
						[special_flow_id] = @id
					WHERE [id] = @lot_id;			
					--------------------------------------------------------------
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
						, 'EXEC [atom].[sp_set_next_flow_ver_002] update special flow is after(0) special_flow_id = ' + IIF(CAST(IIF(@id IS NULL,-1,@id) AS VARCHAR(20)) = -1,'NULL',CAST(IIF(@id IS NULL,-1,@id) AS VARCHAR(20)))
						, @lot_no
					--------------------------------------------------------------
					SELECT 'TRUE' AS Status
						, 'Update special flow after Success !!' AS Error_Message_ENG
						, N'Update special flow after เรียบร้อย !!' AS Error_Message_THA
				END	
				----------------------------------------------------------------------------------------
				----# (1.2.1) END IS_SPECIAL_FLOW = 0
			END
			ELSE
			BEGIN
				----# (1.2.2) IS_SPECIAL_FLOW != 0
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
					, 'EXEC [atom].[sp_set_next_flow_ver_002] not update special flow (1)'
					, @lot_no
				--------------------------------------------------------------
				SELECT 'TRUE' AS Status
					, 'Not update special flow !!' AS Error_Message_ENG
					, N'ไม่ update special flow !!' AS Error_Message_THA
				----# (1.2.2) END IS_SPECIAL_FLOW != 0
			END
			----# (1.2) END SET DATA LOT
			----# (1) END SET DATA SPECIAL FLOW

			----# (2) SET DATA UKEBARAI
			IF NOT EXISTS (
				SELECT [package_groups].[id]
				FROM [APCSProDB].[trans].[lots] 
				INNER JOIN [APCSProDB].[method].[device_names] 
					ON [lots].[act_device_name_id] = [device_names].[id]
				INNER JOIN [APCSProDB].[method].[packages] 
					ON [device_names].[package_id] = [packages].[id]
				INNER JOIN [APCSProDB].[method].[package_groups] 
					ON [packages].[package_group_id] = [package_groups].[id]
				WHERE [package_groups].[id] = 35
					AND [lots].[id] = @lot_id
			)
			BEGIN
				EXEC [StoredProcedureDB].[trans].[sp_set_ukebarai_data] @lot_id = @lot_id;
			END
			----# (2) END SET DATA UKEBARAI
			----# END EXISTS lot_no
		END
		----# END TRY
	END TRY
	BEGIN CATCH 
		----# CATCH
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
			, 'EXEC [atom].[sp_set_next_flow_ver_002] error update'
			, @lot_no
		--------------------------------------------------------------
		SELECT 'FALSE' AS Status 
			, 'Update special flow error !!' AS Error_Message_ENG
			, N'Update ข้อมูล special flow ผิดพลาด !!' AS Error_Message_THA 
		RETURN
		----# END CATCH
	END CATCH
	----# END TRY CATCH
END