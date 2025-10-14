-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_trans_special_flow_ver_012]
	-- Add the parameters for the stored procedure here
	@lot_id INT, 
	@step_no INT = NULL, 
	@user_id INT,  
	@link_flow_no INT = NULL, 
	@assy_ft_class VARCHAR(2), 
	@is_special_flow INT, 
	@machine_id INT = -1, 
	@recipe VARCHAR(20) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--<<--------------------------------------------------------------------------
	---# (1) LOG EXEC
	-->>-------------------------------------------------------------------------
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [lot_no]
		, [command_text] )
	SELECT GETDATE() --AS [record_at]
		, 4 AS [record_class]
		, ORIGINAL_LOGIN() --AS [login_name]
		, HOST_NAME() --AS [hostname]
		, APP_NAME() --AS [appname]
		, ( SELECT CAST( [lot_no] AS VARCHAR ) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id ) --AS [lot_no]
		, 'EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_012] @lot_id = ' + ISNULL( CAST( @lot_id AS VARCHAR ), 'NULL' ) 
			+ ' ,@step_no = ' + ISNULL( CAST( @step_no AS VARCHAR ), 'NULL' ) 
			+ ' ,@user_id = ' + ISNULL( CAST( @user_id AS VARCHAR ), 'NULL' )
			+ ' ,@link_flow_no = ' + ISNULL( CAST( @link_flow_no AS VARCHAR ), 'NULL' )
			+ ' ,@assy_ft_class = ''' + ISNULL( CAST( @assy_ft_class AS VARCHAR ), '' )  + ''''
			+ ' ,@is_special_flow = ' + ISNULL( CAST( @is_special_flow AS VARCHAR ), 'NULL' )
			+ ' ,@machine_id = ' + ISNULL( CAST( @machine_id AS VARCHAR ), 'NULL' ) 
			+ ' ,@recipe = ''' + ISNULL( CAST( @recipe AS VARCHAR ), '' ) + ''''; --AS [command_text]
	
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
		, N'[StoredProcedureDB].[atom].[sp_set_trans_special_flow_ver_012]' --AS [storedprocedname]
		, ( SELECT CAST( [lot_no] AS VARCHAR ) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id ) --AS [lot_no]
		, '@lot_id = ' + ISNULL( CAST( @lot_id AS VARCHAR ), 'NULL' ) 
			+ ' ,@step_no = ' + ISNULL( CAST( @step_no AS VARCHAR ), 'NULL' ) 
			+ ' ,@user_id = ' + ISNULL( CAST( @user_id AS VARCHAR ), 'NULL' )
			+ ' ,@link_flow_no = ' + ISNULL( CAST( @link_flow_no AS VARCHAR ), 'NULL' )
			+ ' ,@assy_ft_class = ''' + ISNULL( CAST( @assy_ft_class AS VARCHAR ), '' )  + ''''
			+ ' ,@is_special_flow = ' + ISNULL( CAST( @is_special_flow AS VARCHAR ), 'NULL' )
			+ ' ,@machine_id = ' + ISNULL( CAST( @machine_id AS VARCHAR ), 'NULL' ) 
			+ ' ,@recipe = ''' + ISNULL( CAST( @recipe AS VARCHAR ), '' ) + ''''; --AS [command_text]
	------------------------------------------------------------------------------------------------------------------------------
	--<<--------------------------------------------------------------------------
	---# (2) DECLARE
	-->>-------------------------------------------------------------------------
	--- (2.1) DECLARE PARAMETER
	DECLARE @q1_step_no INT = 0
		, @q1_back_step_no INT = 0
		, @q1_back_step_no_master INT = 0
		, @check_flow INT = NULL
		, @step_no_now INT = 0
		, @count_flow INT = 0
		, @update_spid INT = 0
		, @r_sf INT = 0 -- special_flows
		, @r_lsf INT = 0 -- lot_special_flows
		, @result INT = 0
		, @maxstepc INT = 0
		, @flow_typec INT = 0
		, @result_nowlast INT = 0
		, @result_stepno INT = NULL
	--- (2.2) DECLARE TABLE
	DECLARE @table_flow TABLE (
		[step_no] INT,
		[back_step_no] INT,
		[back_step_no_master] INT,
		[flow_type] INT,
		[status_add_flow] INT,
		[step_no_now] INT
	)
	DECLARE @table_recipe TABLE (
		[job_id] INT,
		[job_name] VARCHAR(30),
		[recipe] VARCHAR(20)
	)
	DECLARE @table_mat_jig TABLE (
		[job_id] INT,
		[job_name] VARCHAR(30),
		[material_set_id] INT,
		[jig_set_id] INT
	)
	------------------------------------------------------------------------------------------------------------------------------
	--<<--------------------------------------------------------------------------
	---# (3) CHECK DATA
	-->>-------------------------------------------------------------------------
	--- (3.1) CHECK IS_SPECIAL_FLOW
	IF ( @is_special_flow NOT IN (0,1) )
	BEGIN
		SELECT 'FALSE' AS Is_Pass 
			, 'is_special_flow is not 0 and 1. !!' AS Error_Message_ENG
			, N'is_special_flow ที่ส่งมาไม่ใช่ 0 และ 1 !!' AS Error_Message_THA 
			, '' AS Handling
			, @result_stepno AS StepNo
			, NULL AS CountFlow;
		RETURN;
	END
	--- (3.2) CHECK WIP_STATE
	IF ( ( SELECT [wip_state] FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id ) NOT IN (0,10,20) )
	BEGIN
		SELECT 'FALSE' AS Is_Pass 
			, 'Wip state is invalid. !!' AS Error_Message_ENG
			, N'Wip state ไม่ถูกต้อง !!' AS Error_Message_THA 
			, '' AS Handling
			, @result_stepno AS StepNo
			, NULL AS CountFlow;
		RETURN;
	END
	--- (3.3) CHECK PROCESS_STATE (ADD NOW IS_SPECIAL_FLOW = 1)
	IF ( @is_special_flow = 1 )
	BEGIN
		--- (3.3.1) CHECK PROCESS_STATE (MASTER FLOW)
		IF ( ( SELECT [process_state] FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id ) NOT IN (0,100) )
		BEGIN
			SELECT 'FALSE' AS Is_Pass 
				, 'Process State is invalid. !!' AS Error_Message_ENG
				, N'Process State ไม่ถูกต้อง !!' AS Error_Message_THA 
				, '' AS Handling
				, @result_stepno AS StepNo
				, NULL AS CountFlow;
			RETURN;
		END
		--- (3.3.2) CHECK PROCESS_STATE (SPECIAL FLOW)
		IF ( ( SELECT [is_special_flow] FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id ) = 1 )
		BEGIN
			IF ( ( SELECT [process_state] FROM [APCSProDB].[trans].[special_flows] 
				WHERE [lot_id] = @lot_id 
					AND [id] = ( SELECT [special_flow_id] FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id ) ) NOT IN (0,100) )
			BEGIN
				SELECT 'FALSE' AS Is_Pass 
					, 'Process State is invalid. !!' AS Error_Message_ENG
					, N'Process State ไม่ถูกต้อง !!' AS Error_Message_THA 
					, '' AS Handling
					, @result_stepno AS StepNo
					, NULL AS CountFlow;
				RETURN;
			END
		END
	END
	--- (3.4) CHECK COUNT FLOW
	SET @count_flow = (
		SELECT COUNT( [flow_details].[job_id] )
		FROM [APCSProDB].[method].[flow_details] 
		INNER JOIN [APCSProDB].[method].[flow_patterns] ON [flow_details].[flow_pattern_id] = [flow_patterns].[id]
		WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
		  AND [flow_patterns].[link_flow_no] = @link_flow_no
		  AND [flow_patterns].[is_released] = 1
	);

	IF ( @count_flow = 0 )
	BEGIN
		SELECT 'FALSE' AS Is_Pass 
			, 'Flow pattern data not found. !!' AS Error_Message_ENG
			, N'ไม่พบข้อมูล flow pattern !!' AS Error_Message_THA 
			, '' AS Handling
			, @result_stepno AS StepNo
			, NULL AS CountFlow;
		RETURN;
	END
	--- (3.5) CHECK FLOW
		--- (3.5.1) INSERT DATA FLOW TO @table_flow
		INSERT INTO @table_flow 
			( [step_no]
			, [back_step_no]
			, [back_step_no_master]
			, [flow_type]
			, [status_add_flow]
			, [step_no_now] )
		SELECT [flow].[step_no]
			, ISNULL( LEAD( [flow].[step_no] ) OVER ( ORDER BY [flow].[step_no] ), 0 ) AS [back_step_no]
			, [flow].[back_step_no] AS [back_step_no_master]
			, [flow].[flow_type]
			, ( CASE WHEN [flow_current].[step_no] <= [flow].[step_no] THEN 1 ELSE 0 END ) AS [status_add_flow]
			, [flow_current].[step_no] AS [step_no_now]
		FROM (
			SELECT [step_no], 1 AS [flow_type], [next_step_no] AS [back_step_no]
			FROM [APCSProDB].[method].[device_flows] 
			WHERE [device_slip_id] = ( SELECT [device_slip_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id ) AND [is_skipped] != 1
			UNION ALL
			SELECT [lot_special_flows].[step_no], 2 AS [flow_type], [special_flows].[back_step_no]
			FROM [APCSProDB].[trans].[special_flows]
			LEFT JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
			WHERE [special_flows].[lot_id] = @lot_id
		) AS [flow]
		LEFT JOIN (
			SELECT [lots].[id] AS [lot_id], IIF( [lot_special_flows].[step_no] IS NULL, [lots].[step_no], [lot_special_flows].[step_no] ) AS [step_no]
			FROM [APCSProDB].[trans].[lots]
			LEFT JOIN [APCSProDB].[trans].[special_flows] ON [lots].[is_special_flow] = 1
				AND [lots].[special_flow_id] = [special_flows].[id]
			LEFT JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
				AND [special_flows].[step_no] = [lot_special_flows].[step_no]
		) [flow_current] ON [flow_current].[lot_id] = @lot_id;
		--- (3.5.2) CHECK STEP NO
		IF ( NOT EXISTS( SELECT 1 FROM @table_flow WHERE [step_no] = @step_no ) )
		BEGIN
			SELECT 'FALSE' AS Is_Pass 
				, 'Step no not found. !!' AS Error_Message_ENG
				, N'ไม่พบ step_no !!' AS Error_Message_THA 
				, '' AS Handling
				, @result_stepno AS StepNo
				, NULL AS CountFlow;
			RETURN;
		END
		--- (3.5.3) CHECK STEP NO 1 CAN NOT ADD FLOW BY ADD NOW (@is_special_flow = 1)
		IF ( @step_no = ( SELECT MIN( [step_no] ) FROM @table_flow ) )
		BEGIN
			IF ( @step_no = 1 AND @is_special_flow = 1 )
			BEGIN
				SELECT 'FALSE' AS Is_Pass 
					, 'Cannot add flow step no 1. !!' AS Error_Message_ENG
					, N'ไม่สามารถเพิ่ม flow step_no ที่ 1 ได้ !!' AS Error_Message_THA 
					, '' AS Handling
					, @result_stepno AS StepNo
					, NULL AS CountFlow;
				RETURN;
			END
		END
		--- (3.5.4) SET PARAMETER (NOW, AFTER)
		IF ( @is_special_flow = 1 )
		BEGIN
			SELECT @q1_step_no = [flow].[step_no]
				, @q1_back_step_no = [flow].[back_step_no]
				, @q1_back_step_no_master = [flow].[back_step_no_master]
				, @step_no_now = [flow].[step_no_now]
			FROM @table_flow AS [flow]
			WHERE [flow].[back_step_no] = @step_no;

			IF ( @step_no = ( SELECT MIN( [step_no] ) FROM @table_flow ) )
			BEGIN
				SET @q1_step_no = 0;
				SET @q1_back_step_no = @step_no;
				SET @q1_back_step_no_master = @step_no;
				SET @step_no_now = @step_no;
			END
		END
		ELSE IF ( @is_special_flow = 0 ) 
		BEGIN
			SELECT @q1_step_no = [flow].[step_no]
				, @q1_back_step_no = [flow].[back_step_no]
				, @q1_back_step_no_master = [flow].[back_step_no_master]
				, @step_no_now = [flow].[step_no_now]
			FROM @table_flow AS [flow]
			WHERE [flow].[step_no] = @step_no;
		END
		--- (3.5.5) CHECK ADD NOW BY WIP STEP NO
		SET @maxstepc = ( SELECT MAX( [step_no] ) FROM @table_flow );
		SET @flow_typec = ( SELECT [flow_type] FROM @table_flow WHERE [step_no] = @step_no );
		IF ( @is_special_flow = 1 AND @step_no = @maxstepc AND @flow_typec = 2 )
		BEGIN
			SET @result_nowlast = 1;
		END
		ELSE 
		BEGIN
			IF ( @is_special_flow = 1 AND @step_no != @step_no_now )
			BEGIN
				SELECT 'FALSE' AS Is_Pass 
					, 'Cannot add flows that are not current step no. !!' AS Error_Message_ENG
					, N'ไม่สามารถเพิ่ม flow ที่ไม่ใช่ step no ปัจจุบันได้ !!' AS Error_Message_THA 
					, '' AS Handling
					, @result_stepno AS StepNo
					, NULL AS CountFlow;
				RETURN;
			END
		END
		--- (3.5.6) CHECK ADD AFTER
		IF ( @result_nowlast = 0 )
		BEGIN
			IF ( ( SELECT [status_add_flow] FROM @table_flow WHERE [step_no] = @step_no ) != 1 )
			BEGIN
				SELECT 'FALSE' AS Is_Pass 
					, 'Cannot add flow that are less than the current step no. !!' AS Error_Message_ENG
					, N'ไม่สามารถเพิ่ม flow ที่น้อยกว่า step_no ปัจจุบันได้ !!' AS Error_Message_THA 
					, '' AS Handling
					, @result_stepno AS StepNo
					, NULL AS CountFlow;
				RETURN;
			END
		END
	--- (3.6) GET&SET RECIPE
	IF ( @recipe IS NULL )
	BEGIN
		INSERT INTO @table_recipe
			( [job_id]
			, [job_name]
			, [recipe] )
		SELECT [jobs].[id] AS [job_id]
			, [jobs].[name] AS [job_name]
			, ( SELECT [recipe] FROM [StoredProcedureDB].[atom].[fnc_get_recipe_ver_003](@lot_id,[jobs].[id]) ) AS [recipe]
		FROM [APCSProDB].[method].[flow_patterns]
		INNER JOIN [APCSProDB].[method].[flow_details] ON [flow_patterns].[id] = [flow_details].[flow_pattern_id]
		INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
		WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
			AND [flow_patterns].[link_flow_no] = @link_flow_no;
	END
	--- (3.7) GET&SET MATERIAL AND JIG (material_set_id, jig_set_id)
	INSERT INTO @table_mat_jig 
		( [job_id]
		, [job_name]
		, [material_set_id]
		, [jig_set_id] )
	SELECT [jobs].[id] AS [job_id]
		, [jobs].[name] AS [job_name]
		, ( SELECT [material_set_id] FROM [StoredProcedureDB].[atom].[fnc_get_mat_and_jig] (@lot_id,[jobs].[id]) ) AS [material_set_id]
		, ( SELECT [jig_set_id] FROM [StoredProcedureDB].[atom].[fnc_get_mat_and_jig] (@lot_id,[jobs].[id]) ) AS [jig_set_id]
	FROM [APCSProDB].[method].[flow_patterns]
	INNER JOIN [APCSProDB].[method].[flow_details] ON [flow_patterns].[id] = [flow_details].[flow_pattern_id]
	INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
	WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
		AND [flow_patterns].[link_flow_no] = @link_flow_no;
	------------------------------------------------------------------------------------------------------------------------------
	--<<--------------------------------------------------------------------------
	---# (4) PROCESSING DATA
	-->>-------------------------------------------------------------------------
	BEGIN TRANSACTION;
	BEGIN TRY
		--- (4.1) ADD NOW
		IF ( @is_special_flow = 1 )
		BEGIN
			IF ( @result_nowlast = 0 )
			BEGIN
				IF ( ( SELECT [flow_type] FROM @table_flow WHERE [step_no] = @step_no ) = 1 )
				BEGIN
					--- INSERT TABLE special_flows
					INSERT INTO [APCSProDB].[trans].[special_flows]
						( [id]
						, [lot_id]
						, [step_no]
						, [back_step_no]
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
						, [is_exist_work]
						, [wip_state]
						, [process_state]
						, [quality_state]
						, [first_ins_state]
						, [final_ins_state]
						, [priority]
						, [finish_date_id]
						, [finished_at]
						, [machine_id]
						, [container_no]
						, [qc_comment_id]
						, [qc_memo_id]
						, [process_job_id]
						, [carried_at]
						, [is_special_flow]
						, [special_flow_id]
						, [instruction_reason_id]
						, [start_special_message_id]
						, [finish_special_message_id]
						, [holded_at]
						, [created_at]
						, [created_by]
						, [updated_at]
						, [updated_by]
						, [limit_time_state]
						, [map_edit_state]
						, [qty_p_nashi]
						, [qty_front_ng]
						, [qty_marker]
						, [qty_cut_frame]
						, [qty_combined]
						, [qty_frame_in]
						, [qty_frame_pass]
						, [qty_frame_fail] )
					SELECT [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [lots].[id] ) AS [id]
						, [lots].[id] AS [lot_id]
						, @q1_step_no + 1 AS [step_no]
						, @q1_back_step_no_master AS [back_step_no]
						, [lots].[qty_pass]
						, [lots].[qty_pass]
						, 0 AS [qty_fail]
						, NULL AS [qty_last_pass]
						, NULL AS [qty_last_fail]
						, NULL AS [qty_pass_step_sum]
						, NULL AS [qty_fail_step_sum]
						, NULL AS [qty_divided]
						, [qty_hasuu] AS [qty_hasuu]
						, [qty_out] AS [qty_out]
						, 0 AS [is_exist_work]
						, 20 AS [wip_state]
						, 0 AS [process_state]
						, 0 AS [quality_state]
						, 0 AS [first_ins_state]
						, 0 AS [final_ins_state]
						, [lots].[priority]
						, [lots].[finish_date_id]
						, [lots].[finished_at]
						, @machine_id AS [machine_id]
						, [lots].[container_no]
						, NULL AS [qc_comment_id]
						, NULL AS [qc_memo_id]
						, NULL AS [process_job_id]
						, [lots].[carried_at]
						, 0 AS [is_special_flow_id]
						, NULL AS [special_flow_id]
						, NULL AS [instruction_reason_id]
						, NULL AS [start_special_message_id]
						, NULL AS [finish_special_message_id]
						, NULL AS [holded_at]
						, GETDATE() AS [created_at]
						, @user_id AS [created_by]
						, NULL AS [updated_at]
						, NULL AS [updated_by]
						, NULL AS [limit_time_state]
						, NULL AS [map_edit_state]
						, [qty_p_nashi]
						, [qty_front_ng]
						, [qty_marker]
						, [qty_cut_frame]
						, [qty_combined]
						, [qty_frame_pass]
						, [qty_frame_pass]
						, [qty_frame_fail]
					FROM [APCSProDB].[trans].[lots] 
					INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'special_flows.id'
					WHERE [lots].[id] = @lot_id;
					--- UPDATE NUMBERS special_flows.id
					SET @r_sf = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_sf
						, @update_spid = [id] + @r_sf
					WHERE [name] = 'special_flows.id';
					--- INSERT TABLE lot_special_flows
					INSERT INTO [APCSProDB].[trans].[lot_special_flows]
						( [id]
						, [special_flow_id]
						, [step_no]
						, [next_step_no]
						, [act_process_id]
						, [job_id]
						, [act_package_flow_id]
						, [permitted_machine_id]
						, [process_minutes]
						, [sum_process_minutes]
						, [recipe]
						, [ng_retest_permitted]
						, [is_skipped]
						, [material_set_id]
						, [jig_set_id]
						, [data_collection_id]
						, [yield_lcl]
						, [ng_category_cnt]
						, [label_issue_id] )
					SELECT [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [id]
						, @update_spid AS [special_flow_id]
						, @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [step_no]
						, ( CASE
							WHEN ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id]) = @count_flow THEN @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] )
							ELSE @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) + 1 END ) AS [next_step_no]
						, [jobs].[process_id] AS [act_process_id]
						, [jobs].[id] AS [job_id]
						, [lots].[act_package_id] AS [act_package_flow_id]
						, 0 AS [permitted_machine_id]
						, 0 AS [process_minutes]
						, 0 AS [sum_process_minutes]
						, IIF( @recipe IS NULL, ( SELECT [recipe] FROM @table_recipe WHERE [job_id] = [jobs].[id] ), @recipe ) AS [recipe]
						, 0 AS [ng_retest_permitted]
						, 0 AS [is_skipped]
						, ( SELECT [material_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [material_set_id]
						, ( SELECT [jig_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [jig_set_id]
						, NULL AS [data_collection_id]
						, NULL AS [yield_lcl]
						, NULL AS [ng_category_cnt]
						, 0 AS [issue_label_type]
					FROM [APCSProDB].[method].[flow_details] 
					INNER JOIN [APCSProDB].[method].[flow_patterns] ON [flow_details].[flow_pattern_id] = [flow_patterns].[id]
					INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'lot_special_flows.id'
					INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
					INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = @lot_id
					WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
						AND [flow_patterns].[link_flow_no] = @link_flow_no;
					--- UPDATE NUMBERS lot_special_flows.id
					SET @r_lsf = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_lsf
					WHERE [name] = 'lot_special_flows.id';
					--- SET RESULT
					SET @result = 1;
					SET @result_stepno = @q1_step_no + @count_flow;
					----------------------------------------------------------------------------------
				END
				ELSE IF ( ( SELECT [flow_type] FROM @table_flow WHERE [step_no] = @step_no ) = 2 )
				BEGIN
					--- GET special_flow_id
					SELECT @update_spid = [lot_special_flows].[special_flow_id]
					FROM [APCSProDB].[trans].[lot_special_flows]
					INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
					WHERE [special_flows].[lot_id] = @lot_id 
						AND [lot_special_flows].[step_no] = @step_no;
					--- CHECK&UPDATE lot_special_flows
					IF ( @update_spid != 0 )
					BEGIN
						IF ( @step_no > ( SELECT MAX( [step_no] ) FROM [APCSProDB].[method].[device_flows] 
							WHERE [device_slip_id] = ( SELECT [device_slip_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id ) 
								AND [is_skipped] != 1 ) )
						BEGIN
							UPDATE [APCSProDB].[trans].[lot_special_flows]
							SET [step_no] = ( [step_no] + @count_flow )
								, [next_step_no] = ( [next_step_no] + @count_flow )
							WHERE [special_flow_id] = @update_spid 
								AND [step_no] >= @step_no;
						END
						ELSE 
						BEGIN
							UPDATE [APCSProDB].[trans].[lot_special_flows]
							SET [step_no] = ( [step_no] + @count_flow )
								, [next_step_no] = ( [next_step_no] + @count_flow )
							WHERE [special_flow_id] = @update_spid 
								AND step_no BETWEEN @step_no AND @q1_back_step_no_master;
						END
					END
					--- INSERT TABLE lot_special_flows
					INSERT INTO [APCSProDB].[trans].[lot_special_flows]
						( [id]
						, [special_flow_id]
						, [step_no]
						, [next_step_no]
						, [act_process_id]
						, [job_id]
						, [act_package_flow_id]
						, [permitted_machine_id]
						, [process_minutes]
						, [sum_process_minutes]
						, [recipe]
						, [ng_retest_permitted]
						, [is_skipped]
						, [material_set_id]
						, [jig_set_id]
						, [data_collection_id]
						, [yield_lcl]
						, [ng_category_cnt]
						, [label_issue_id] )
					select [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [id]
						, @update_spid AS [special_flow_id]
						, @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [step_no]
						, @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) + 1 AS [next_step_no]
						, [jobs].[process_id] AS [act_process_id]
						, [jobs].[id] AS [job_id]
						, [lots].[act_package_id] AS [act_package_flow_id]
						, 0 AS [permitted_machine_id]
						, 0 AS [process_minutes]
						, 0 AS [sum_process_minutes]
						, IIF( @recipe IS NULL, ( SELECT [recipe] FROM @table_recipe WHERE [job_id] = [jobs].[id] ), @recipe ) AS [recipe]
						, 0 AS [ng_retest_permitted]
						, 0 AS [is_skipped]
						, ( SELECT [material_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [material_set_id]
						, ( SELECT [jig_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [jig_set_id]
						, NULL AS [data_collection_id]
						, NULL AS [yield_lcl]
						, NULL AS [ng_category_cnt]
						, 0 AS [issue_label_type]
					FROM [APCSProDB].[method].[flow_details] 
					INNER JOIN [APCSProDB].[method].[flow_patterns] ON [flow_details].[flow_pattern_id] = [flow_patterns].[id]
					INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'lot_special_flows.id'
					INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
					INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = @lot_id
					WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class             
						AND [flow_patterns].[link_flow_no] = @link_flow_no;
					--- UPDATE NUMBERS lot_special_flows.id
					SET @r_lsf = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_lsf
					WHERE [name] = 'lot_special_flows.id';
					--- SET RESULT
					SET @result = 1;
					SET @result_stepno = @q1_step_no + @count_flow;
					----------------------------------------------------------------------------------
				END
			END
			ELSE 
			BEGIN
				--- INSERT TABLE special_flows
				INSERT INTO [APCSProDB].[trans].[special_flows]
					( [id]
					, [lot_id]
					, [step_no]
					, [back_step_no]
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
					, [is_exist_work]
					, [wip_state]
					, [process_state]
					, [quality_state]
					, [first_ins_state]
					, [final_ins_state]
					, [priority]
					, [finish_date_id]
					, [finished_at]
					, [machine_id]
					, [container_no]
					, [qc_comment_id]
					, [qc_memo_id]
					, [process_job_id]
					, [carried_at]
					, [is_special_flow]
					, [special_flow_id]
					, [instruction_reason_id]
					, [start_special_message_id]
					, [finish_special_message_id]
					, [holded_at]
					, [created_at]
					, [created_by]
					, [updated_at]
					, [updated_by]
					, [limit_time_state]
					, [map_edit_state]
					, [qty_p_nashi]
					, [qty_front_ng]
					, [qty_marker]
					, [qty_cut_frame]
					, [qty_combined]
					, [qty_frame_in]
					, [qty_frame_pass]
					, [qty_frame_fail] )
				SELECT [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [lots].[id] ) AS [id]
					, [lots].[id] AS [lot_id]
					, @step_no + 1 AS [step_no]
					, @q1_back_step_no_master AS [back_step_no]
					, [lots].[qty_pass]
					, [lots].[qty_pass]
					, 0 AS [qty_fail]
					, NULL AS [qty_last_pass]
					, NULL AS [qty_last_fail]
					, NULL AS [qty_pass_step_sum]
					, NULL AS [qty_fail_step_sum]
					, NULL AS [qty_divided]
					, [qty_hasuu] AS [qty_hasuu]
					, [qty_out] AS [qty_out]
					, 0 AS [is_exist_work]
					, 20 AS [wip_state]
					, 0 AS [process_state]
					, 0 AS [quality_state]
					, 0 AS [first_ins_state]
					, 0 AS [final_ins_state]
					, [lots].[priority]
					, [lots].[finish_date_id]
					, [lots].[finished_at]
					, @machine_id AS [machine_id]
					, [lots].[container_no]
					, NULL AS [qc_comment_id]
					, NULL AS [qc_memo_id]
					, NULL AS [process_job_id]
					, [lots].[carried_at]
					, 0 AS [is_special_flow_id]
					, NULL AS [special_flow_id]
					, NULL AS [instruction_reason_id]
					, NULL AS [start_special_message_id]
					, NULL AS [finish_special_message_id]
					, NULL AS [holded_at]
					, GETDATE() AS [created_at]
					, @user_id AS [created_by]
					, NULL AS [updated_at]
					, NULL AS [updated_by]
					, NULL AS [limit_time_state]
					, NULL AS [map_edit_state]
					, [qty_p_nashi]
					, [qty_front_ng]
					, [qty_marker]
					, [qty_cut_frame]
					, [qty_combined]
					, [qty_frame_pass]
					, [qty_frame_pass]
					, [qty_frame_fail]
				FROM [APCSProDB].[trans].[lots] 
				INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'special_flows.id'
				WHERE [lots].[id] = @lot_id;
				--- UPDATE NUMBERS special_flows.id
				SET @r_sf = @@ROWCOUNT
				UPDATE [APCSProDB].[trans].[numbers]
				SET [id] = [id] + @r_sf
					, @update_spid = [id] + @r_sf
				WHERE [name] = 'special_flows.id';
				--- INSERT TABLE lot_special_flows
				INSERT INTO [APCSProDB].[trans].[lot_special_flows]
					( [id]
					, [special_flow_id]
					, [step_no]
					, [next_step_no]
					, [act_process_id]
					, [job_id]
					, [act_package_flow_id]
					, [permitted_machine_id]
					, [process_minutes]
					, [sum_process_minutes]
					, [recipe]
					, [ng_retest_permitted]
					, [is_skipped]
					, [material_set_id]
					, [jig_set_id]
					, [data_collection_id]
					, [yield_lcl]
					, [ng_category_cnt]
					, [label_issue_id] )
				SELECT [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [id]
					, @update_spid AS [special_flow_id]
					, @step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [step_no]
					, ( CASE
						WHEN ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id]) = @count_flow THEN @step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] )
						ELSE @step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) + 1 END ) AS [next_step_no]
					, [jobs].[process_id] AS [act_process_id]
					, [jobs].[id] AS [job_id]
					, [lots].[act_package_id] AS [act_package_flow_id]
					, 0 AS [permitted_machine_id]
					, 0 AS [process_minutes]
					, 0 AS [sum_process_minutes]
					, IIF( @recipe IS NULL, ( SELECT [recipe] FROM @table_recipe WHERE [job_id] = [jobs].[id] ), @recipe ) AS [recipe]
					, 0 AS [ng_retest_permitted]
					, 0 AS [is_skipped]
					, ( SELECT [material_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [material_set_id]
					, ( SELECT [jig_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [jig_set_id]
					, NULL AS [data_collection_id]
					, NULL AS [yield_lcl]
					, NULL AS [ng_category_cnt]
					, 0 AS [issue_label_type]
				FROM [APCSProDB].[method].[flow_details] 
				INNER JOIN [APCSProDB].[method].[flow_patterns] ON [flow_details].[flow_pattern_id] = [flow_patterns].[id]
				INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'lot_special_flows.id'
				INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
				INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = @lot_id
				WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
					AND [flow_patterns].[link_flow_no] = @link_flow_no;
				--- UPDATE NUMBERS lot_special_flows.id
				SET @r_lsf = @@ROWCOUNT
				UPDATE [APCSProDB].[trans].[numbers]
				SET [id] = [id] + @r_lsf
				WHERE [name] = 'lot_special_flows.id';
				--- SET RESULT
				SET @result = 1;
				SET @result_stepno = @step_no + @count_flow;
				----------------------------------------------------------------------------------
			END
		END
		--- (4.2) ADD AFTER
		IF (@is_special_flow = 0)
		BEGIN
			IF ( ( SELECT [flow_type] FROM @table_flow WHERE [step_no] = @step_no ) = 1 )
			BEGIN
				--- ADD STEP NO FLOW MASTER
				SET @check_flow = ( SELECT TOP 1 [flow_type] FROM @table_flow WHERE [step_no] > @step_no ORDER BY [step_no] );

				IF ( @check_flow = 2 )
				BEGIN
					--- GET special_flow_id FROM TABLE lot_special_flows
					IF ( EXISTS(
						SELECT [lot_special_flows].[special_flow_id]
						FROM [APCSProDB].[trans].[lot_special_flows]
						INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [special_flows].[lot_id] = @lot_id 
							AND [lot_special_flows].[step_no] = @step_no ) )
					BEGIN
						SELECT @update_spid = [lot_special_flows].[special_flow_id]
						FROM [APCSProDB].[trans].[lot_special_flows]
						INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [special_flows].[lot_id] = @lot_id
							AND [lot_special_flows].[step_no] = @step_no;
					END
					ELSE
					BEGIN
						SELECT @update_spid = [lot_special_flows].[special_flow_id]
						FROM [APCSProDB].[trans].[lot_special_flows]
						INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [special_flows].[lot_id] = @lot_id 
							AND [lot_special_flows].[step_no] = ( @step_no + 1 );
					END
					--- UPDATE TABLE lot_special_flows
					IF ( @update_spid != 0 )
					BEGIN
						UPDATE [APCSProDB].[trans].[lot_special_flows]
						SET [lot_special_flows].[step_no] = ( [lot_special_flows].[step_no] + @count_flow )
							, [lot_special_flows].[next_step_no] = ( [lot_special_flows].[next_step_no] +  @count_flow )
						FROM [APCSProDB].[trans].[lot_special_flows]
						INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [special_flows].[lot_id] = @lot_id 
							AND [lot_special_flows].[special_flow_id] = @update_spid
							AND [lot_special_flows].[step_no] > @step_no;
					END
					--- INSERT TABLE lot_special_flows
					INSERT INTO [APCSProDB].[trans].[lot_special_flows]
						( [id]
						, [special_flow_id]
						, [step_no]
						, [next_step_no]
						, [act_process_id]
						, [job_id]
						, [act_package_flow_id]
						, [permitted_machine_id]
						, [process_minutes]
						, [sum_process_minutes]
						, [recipe]
						, [ng_retest_permitted]
						, [is_skipped]
						, [material_set_id]
						, [jig_set_id]
						, [data_collection_id]
						, [yield_lcl]
						, [ng_category_cnt]
						, [label_issue_id] )
					SELECT [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [id]
						, @update_spid AS [special_flow_id]
						, (@step_no) + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [step_no]
						, (@step_no + 1) + ROW_NUMBER() OVER ( ORDER BY  [flow_details].[flow_pattern_id] ) AS [next_step_no]
						, [jobs].[process_id] AS [act_process_id]
						, [jobs].[id] AS [job_id]
						, [lots].[act_package_id] AS [act_package_flow_id]
						, 0 AS [permitted_machine_id]
						, 0 AS [process_minutes]
						, 0 AS [sum_process_minutes]
						, IIF( @recipe IS NULL, ( SELECT [recipe] FROM @table_recipe WHERE [job_id] = [jobs].[id] ), @recipe ) AS [recipe]
						, 0 AS [ng_retest_permitted]
						, 0 AS [is_skipped]
						, ( SELECT [material_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [material_set_id]
						, ( SELECT [jig_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [jig_set_id]
						, NULL AS [data_collection_id]
						, NULL AS [yield_lcl]
						, NULL AS [ng_category_cnt]
						, NULL AS [label_issue_id]
					FROM [APCSProDB].[method].[flow_details] 
					INNER JOIN [APCSProDB].[method].[flow_patterns] ON [flow_details].[flow_pattern_id] = [flow_patterns].[id]
					INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'lot_special_flows.id'
					INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
					INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = @lot_id
					WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
						AND [flow_patterns].[link_flow_no] = @link_flow_no;
					--- UPDATE NUMBERS lot_special_flows.id
					SET @r_lsf = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_lsf
					WHERE [name] = 'lot_special_flows.id';
					--- SET RESULT
					SET @result = 1;
					SET @result_stepno = @step_no + @count_flow;
					----------------------------------------------------------------------------------------------
				END
				ELSE 
				BEGIN
					--- INSERT TABLE special_flows
					INSERT INTO [APCSProDB].[trans].[special_flows]
						( [id]
						, [lot_id]
						, [step_no]
						, [back_step_no]
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
						, [is_exist_work]
						, [wip_state]
						, [process_state]
						, [quality_state]
						, [first_ins_state]
						, [final_ins_state]
						, [priority]
						, [finish_date_id]
						, [finished_at]
						, [machine_id]
						, [container_no]
						, [qc_comment_id]
						, [qc_memo_id]
						, [process_job_id]
						, [carried_at]
						, [is_special_flow]
						, [special_flow_id]
						, [instruction_reason_id]
						, [start_special_message_id]
						, [finish_special_message_id]
						, [holded_at]
						, [created_at]
						, [created_by]
						, [updated_at]
						, [updated_by]
						, [limit_time_state]
						, [map_edit_state]
						, [qty_p_nashi]
						, [qty_front_ng]
						, [qty_marker]
						, [qty_cut_frame]
						, [qty_combined]
						, [qty_frame_in]
						, [qty_frame_pass]
						, [qty_frame_fail] )
					SELECT [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [lots].[id] ) AS [id]
						, [lots].[id] AS [lot_id]
						, @q1_step_no + 1 AS [step_no]
						, @q1_back_step_no_master AS [back_step_no]
						, [lots].[qty_pass]
						, [lots].[qty_pass]
						, 0 AS [qty_fail]
						, NULL AS [qty_last_pass]
						, NULL AS [qty_last_fail]
						, NULL AS [qty_pass_step_sum]
						, NULL AS [qty_fail_step_sum]
						, NULL AS [qty_divided]
						, [qty_hasuu] AS [qty_hasuu]
						, [qty_out] AS [qty_out]
						, 0 AS [is_exist_work]
						, 20 AS [wip_state]
						, 0 AS [process_state]
						, 0 AS [quality_state]
						, 0 AS [first_ins_state]
						, 0 AS [final_ins_state]
						, [lots].[priority]
						, [lots].[finish_date_id]
						, [lots].[finished_at]
						, @machine_id AS [machine_id]
						, [lots].[container_no]
						, NULL AS [qc_comment_id]
						, NULL AS [qc_memo_id]
						, NULL AS [process_job_id]
						, [lots].[carried_at]
						, 0 AS [is_special_flow_id]
						, NULL AS [special_flow_id]
						, NULL AS [instruction_reason_id]
						, NULL AS [start_special_message_id]
						, NULL AS [finish_special_message_id]
						, NULL AS [holded_at]
						, GETDATE() AS [created_at]
						, @user_id AS [created_by]
						, NULL AS [updated_at]
						, NULL AS [updated_by]
						, NULL AS [limit_time_state]
						, NULL AS [map_edit_state]
						, [qty_p_nashi]
						, [qty_front_ng]
						, [qty_marker]
						, [qty_cut_frame]
						, [qty_combined]
						, [qty_frame_pass]
						, [qty_frame_pass]
						, [qty_frame_fail]
					FROM [APCSProDB].[trans].[lots] 
					INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'special_flows.id'
					WHERE [lots].[id] = @lot_id;
					--- UPDATE NUMBERS special_flows.id
					SET @r_sf = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_sf
						, @update_spid = [id] + @r_sf
					WHERE [name] = 'special_flows.id';
					--- INSERT TABLE lot_special_flows
					INSERT INTO [APCSProDB].[trans].[lot_special_flows]
						( [id]
						, [special_flow_id]
						, [step_no]
						, [next_step_no]
						, [act_process_id]
						, [job_id]
						, [act_package_flow_id]
						, [permitted_machine_id]
						, [process_minutes]
						, [sum_process_minutes]
						, [recipe]
						, [ng_retest_permitted]
						, [is_skipped]
						, [material_set_id]
						, [jig_set_id]
						, [data_collection_id]
						, [yield_lcl]
						, [ng_category_cnt]
						, [label_issue_id] )
					SELECT [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [id]
						, @update_spid AS [special_flow_id]
						, @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [step_no]
						, ( CASE
							WHEN ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) = @count_flow THEN @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] )
							ELSE @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) + 1 END ) AS [next_step_no]
						, [jobs].[process_id] AS [act_process_id]
						, [jobs].[id] AS [job_id]
						, [lots].[act_package_id] AS [act_package_flow_id]
						, 0 AS [permitted_machine_id]
						, 0 AS [process_minutes]
						, 0 AS [sum_process_minutes]
						, IIF( @recipe IS NULL, ( SELECT [recipe] FROM @table_recipe WHERE [job_id] = [jobs].[id] ), @recipe ) AS [recipe]
						, 0 AS [ng_retest_permitted]
						, 0 AS [is_skipped]
						, ( SELECT [material_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [material_set_id]
						, ( SELECT [jig_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [jig_set_id]
						, NULL AS [data_collection_id]
						, NULL AS [yield_lcl]
						, NULL AS [ng_category_cnt]
						, 0 AS [issue_label_type]
					FROM [APCSProDB].[method].[flow_details] 
					INNER JOIN [APCSProDB].[method].[flow_patterns] ON [flow_details].[flow_pattern_id] = [flow_patterns].[id]
					INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'lot_special_flows.id'
					INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
					INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = @lot_id
					WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
						AND [flow_patterns].[link_flow_no] = @link_flow_no;
					--- UPDATE NUMBERS lot_special_flows.id
					SET @r_lsf = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_lsf
					WHERE [name] = 'lot_special_flows.id';
					--- SET RESULT
					SET @result = 1;
					SET @result_stepno = @q1_step_no + @count_flow;
					----------------------------------------------------------------------------------------------
				END
			END
			ELSE IF ( ( SELECT [flow_type] FROM @table_flow WHERE [step_no] = @step_no ) = 2 )
			BEGIN
				--- ADD STEP NO FLOW SPECIAL
				SET @check_flow = ( SELECT TOP 1 [flow_type] FROM @table_flow WHERE [step_no] > @step_no ORDER BY [step_no] );

				IF ( @check_flow = 2 )
				BEGIN
					--- GET special_flow_id FROM TABLE lot_special_flows
					IF ( EXISTS( 
						SELECT [lot_special_flows].[special_flow_id] 
						FROM [APCSProDB].[trans].[lot_special_flows]
						INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [special_flows].[lot_id] = @lot_id 
							AND [lot_special_flows].[step_no] = @step_no ) )
					BEGIN
						SELECT @update_spid = [lot_special_flows].[special_flow_id]
						FROM [APCSProDB].[trans].[lot_special_flows]
						INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [special_flows].[lot_id] = @lot_id 
							AND [lot_special_flows].[step_no] = @step_no;
					END
					ELSE
					BEGIN
						SELECT @update_spid = [lot_special_flows].[special_flow_id]
						FROM [APCSProDB].[trans].[lot_special_flows]
						INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [special_flows].[lot_id] = @lot_id 
							AND [lot_special_flows].[step_no] = ( @step_no + 1 );
					END
					--- UPDATE TABLE lot_special_flows
					IF ( @update_spid != 0 )
					BEGIN
						UPDATE [APCSProDB].[trans].[lot_special_flows]
						SET [lot_special_flows].[step_no] = ( [lot_special_flows].[step_no] + @count_flow )
							, [lot_special_flows].[next_step_no] = ( [lot_special_flows].[next_step_no] +  @count_flow )
						FROM [APCSProDB].[trans].[lot_special_flows]
						INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [special_flows].[lot_id] = @lot_id 
							AND [lot_special_flows].[special_flow_id] = @update_spid
							AND [lot_special_flows].[step_no] > @step_no;
					END
					--- INSERT TABLE lot_special_flows
					INSERT INTO [APCSProDB].[trans].[lot_special_flows]
						( [id]
						, [special_flow_id]
						, [step_no]
						, [next_step_no]
						, [act_process_id]
						, [job_id]
						, [act_package_flow_id]
						, [permitted_machine_id]
						, [process_minutes]
						, [sum_process_minutes]
						, [recipe]
						, [ng_retest_permitted]
						, [is_skipped]
						, [material_set_id]
						, [jig_set_id]
						, [data_collection_id]
						, [yield_lcl]
						, [ng_category_cnt]
						, [label_issue_id] )
					SELECT [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [id]
						, @update_spid AS [special_flow_id]
						, (@step_no) + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [step_no]
						, (@step_no + 1) + ROW_NUMBER() OVER ( ORDER BY  [flow_details].[flow_pattern_id] ) AS [next_step_no]
						, [jobs].[process_id] AS [act_process_id]
						, [jobs].[id] AS [job_id]
						, [lots].[act_package_id] AS [act_package_flow_id]
						, 0 AS [permitted_machine_id]
						, 0 AS [process_minutes]
						, 0 AS [sum_process_minutes]
						, IIF( @recipe IS NULL, ( SELECT [recipe] FROM @table_recipe WHERE [job_id] = [jobs].[id] ), @recipe ) AS [recipe]
						, 0 AS [ng_retest_permitted]
						, 0 AS [is_skipped]
						, ( SELECT [material_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [material_set_id]
						, ( SELECT [jig_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [jig_set_id]
						, NULL AS [data_collection_id]
						, NULL AS [yield_lcl]
						, NULL AS [ng_category_cnt]
						, NULL AS [label_issue_id]
					FROM [APCSProDB].[method].[flow_details] 
					INNER JOIN [APCSProDB].[method].[flow_patterns] ON [flow_details].[flow_pattern_id] = [flow_patterns].[id]
					INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'lot_special_flows.id'
					INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
					INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = @lot_id
					WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
						AND [flow_patterns].[link_flow_no] = @link_flow_no;
					--- UPDATE NUMBERS lot_special_flows.id
					SET @r_lsf = @@ROWCOUNT
					UPDATE [APCSProDB].[trans].[numbers]
					SET [id] = [id] + @r_lsf
					WHERE [name] = 'lot_special_flows.id';
					--- SET RESULT
					SET @result = 1;
					SET @result_stepno = @step_no + @count_flow;
					----------------------------------------------------------------------------------------------
				END
				ELSE 
				BEGIN
					--------------------------------------------------------------------------------------
					IF ( ( SELECT [flow_type] FROM @table_flow WHERE [step_no] = @step_no ) = 1 )
					BEGIN
						--- INSERT TABLE special_flows
						INSERT INTO [APCSProDB].[trans].[special_flows]
							( [id]
							, [lot_id]
							, [step_no]
							, [back_step_no]
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
							, [is_exist_work]
							, [wip_state]
							, [process_state]
							, [quality_state]
							, [first_ins_state]
							, [final_ins_state]
							, [priority]
							, [finish_date_id]
							, [finished_at]
							, [machine_id]
							, [container_no]
							, [qc_comment_id]
							, [qc_memo_id]
							, [process_job_id]
							, [carried_at]
							, [is_special_flow]
							, [special_flow_id]
							, [instruction_reason_id]
							, [start_special_message_id]
							, [finish_special_message_id]
							, [holded_at]
							, [created_at]
							, [created_by]
							, [updated_at]
							, [updated_by]
							, [limit_time_state]
							, [map_edit_state]
							, [qty_p_nashi]
							, [qty_front_ng]
							, [qty_marker]
							, [qty_cut_frame]
							, [qty_combined]
							, [qty_frame_in]
							, [qty_frame_pass]
							, [qty_frame_fail] )
						SELECT [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [lots].[id] ) AS [id]
							, [lots].[id] AS [lot_id]
							, @q1_step_no + 1 AS [step_no]
							, @q1_back_step_no_master AS [back_step_no]
							, [lots].[qty_pass]
							, [lots].[qty_pass]
							, 0 AS [qty_fail]
							, NULL AS [qty_last_pass]
							, NULL AS [qty_last_fail]
							, NULL AS [qty_pass_step_sum]
							, NULL AS [qty_fail_step_sum]
							, NULL AS [qty_divided]
							, [qty_hasuu] AS [qty_hasuu]
							, [qty_out] AS [qty_out]
							, 0 AS [is_exist_work]
							, 20 AS [wip_state]
							, 0 AS [process_state]
							, 0 AS [quality_state]
							, 0 AS [first_ins_state]
							, 0 AS [final_ins_state]
							, [lots].[priority]
							, [lots].[finish_date_id]
							, [lots].[finished_at]
							, @machine_id AS [machine_id]
							, [lots].[container_no]
							, NULL AS [qc_comment_id]
							, NULL AS [qc_memo_id]
							, NULL AS [process_job_id]
							, [lots].[carried_at]
							, 0 AS [is_special_flow_id]
							, NULL AS [special_flow_id]
							, NULL AS [instruction_reason_id]
							, NULL AS [start_special_message_id]
							, NULL AS [finish_special_message_id]
							, NULL AS [holded_at]
							, GETDATE() AS [created_at]
							, @user_id AS [created_by]
							, NULL AS [updated_at]
							, NULL AS [updated_by]
							, NULL AS [limit_time_state]
							, NULL AS [map_edit_state]
							, [qty_p_nashi]
							, [qty_front_ng]
							, [qty_marker]
							, [qty_cut_frame]
							, [qty_combined]
							, [qty_frame_pass]
							, [qty_frame_pass]
							, [qty_frame_fail]
						FROM [APCSProDB].[trans].[lots] 
						INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'special_flows.id'
						WHERE [lots].[id] = @lot_id;
						--- UPDATE NUMBERS special_flows.id
						SET @r_sf = @@ROWCOUNT
						UPDATE [APCSProDB].[trans].[numbers]
						SET [id] = [id] + @r_sf
							, @update_spid = [id] + @r_sf
						WHERE [name] = 'special_flows.id';
						--- INSERT TABLE lot_special_flows
						INSERT INTO [APCSProDB].[trans].[lot_special_flows]
							( [id]
							, [special_flow_id]
							, [step_no]
							, [next_step_no]
							, [act_process_id]
							, [job_id]
							, [act_package_flow_id]
							, [permitted_machine_id]
							, [process_minutes]
							, [sum_process_minutes]
							, [recipe]
							, [ng_retest_permitted]
							, [is_skipped]
							, [material_set_id]
							, [jig_set_id]
							, [data_collection_id]
							, [yield_lcl]
							, [ng_category_cnt]
							, [label_issue_id] )
						SELECT [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [id]
							, @update_spid AS [special_flow_id]
							, @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [step_no]
							, ( CASE
								WHEN ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) = @count_flow THEN @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] )
								ELSE @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) + 1 END ) AS [next_step_no]
							, [jobs].[process_id] AS [act_process_id]
							, [jobs].[id] AS [job_id]
							, [lots].[act_package_id] AS [act_package_flow_id]
							, 0 AS [permitted_machine_id]
							, 0 AS [process_minutes]
							, 0 AS [sum_process_minutes]
							, IIF( @recipe IS NULL, ( SELECT [recipe] FROM @table_recipe WHERE [job_id] = [jobs].[id] ), @recipe ) AS [recipe]
							, 0 AS [ng_retest_permitted]
							, 0 AS [is_skipped]
							, ( SELECT [material_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [material_set_id]
							, ( SELECT [jig_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id] ) AS [jig_set_id]
							, NULL AS [data_collection_id]
							, NULL AS [yield_lcl]
							, NULL AS [ng_category_cnt]
							, 0 AS [issue_label_type]
						FROM [APCSProDB].[method].[flow_details]
						INNER JOIN [APCSProDB].[method].[flow_patterns] ON [flow_details].[flow_pattern_id] = [flow_patterns].[id]
						INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'lot_special_flows.id'
						INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
						INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = @lot_id
						WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
							AND [flow_patterns].[link_flow_no] = @link_flow_no;
						--- UPDATE NUMBERS lot_special_flows.id
						SET @r_lsf = @@ROWCOUNT
						UPDATE [APCSProDB].[trans].[numbers]
						SET [id] = [id] + @r_lsf
						WHERE [name] = 'lot_special_flows.id';
						--- SET RESULT
						SET @result = 1;
						SET @result_stepno = @q1_step_no + @count_flow;
						----------------------------------------------------------------------------------------------
					END
					ELSE IF ( ( SELECT [flow_type] FROM @table_flow WHERE [step_no] = @step_no ) = 2 )
					BEGIN
						--- UPDATE TABLE lot_special_flows
						UPDATE [APCSProDB].[trans].[lot_special_flows]
						SET [next_step_no] = next_step_no + 1
						FROM [APCSProDB].[trans].[lot_special_flows]
						INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [special_flows].[lot_id] = @lot_id 
							AND [lot_special_flows].[step_no] = @step_no;
						--- GET special_flows.id
						SELECT @update_spid = [lot_special_flows].[special_flow_id]
						FROM [APCSProDB].[trans].[lot_special_flows]
						INNER JOIN [APCSProDB].[trans].[special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [special_flows].[lot_id] = @lot_id 
							AND [lot_special_flows].[step_no] = @step_no;
						--- INSERT TABLE lot_special_flows
						INSERT INTO [APCSProDB].[trans].[lot_special_flows]
							( [id]
							, [special_flow_id]
							, [step_no]
							, [next_step_no]
							, [act_process_id]
							, [job_id]
							, [act_package_flow_id]
							, [permitted_machine_id]
							, [process_minutes]
							, [sum_process_minutes]
							, [recipe]
							, [ng_retest_permitted]
							, [is_skipped]
							, [material_set_id]
							, [jig_set_id]
							, [data_collection_id]
							, [yield_lcl]
							, [ng_category_cnt]
							, [label_issue_id] )
						SELECT [nu].[id] + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [id]
							, @update_spid AS [special_flow_id]
							, @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) AS [step_no]
							, ( CASE
								WHEN ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) = @count_flow THEN @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] )
								ELSE @q1_step_no + ROW_NUMBER() OVER ( ORDER BY [flow_details].[flow_pattern_id] ) + 1 END ) AS [next_step_no]
							, [jobs].[process_id] AS [act_process_id]
							, [jobs].[id] AS [job_id]
							, [lots].[act_package_id] AS [act_package_flow_id]
							, 0 AS [permitted_machine_id]
							, 0 AS [process_minutes]
							, 0 AS [sum_process_minutes]
							, IIF( @recipe IS NULL, ( SELECT [recipe] FROM @table_recipe WHERE [job_id] = [jobs].[id] ), @recipe ) AS [recipe]
							, 0 AS [ng_retest_permitted]
							, 0 AS [is_skipped]
							, ( SELECT [material_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id]) AS [material_set_id]
							, ( SELECT [jig_set_id] FROM @table_mat_jig WHERE [job_id] = [jobs].[id]) AS [jig_set_id]
							, NULL AS [data_collection_id]
							, NULL AS [yield_lcl]
							, NULL AS [ng_category_cnt]
							, 0 AS [issue_label_type]
						FROM [APCSProDB].[method].[flow_details]
						INNER JOIN [APCSProDB].[method].[flow_patterns] ON [flow_details].[flow_pattern_id] = [flow_patterns].[id]
						INNER JOIN [APCSProDB].[trans].[numbers] AS [nu] ON [nu].[name] = 'lot_special_flows.id'
						INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
						INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = @lot_id
						WHERE [flow_patterns].[assy_ft_class] = @assy_ft_class
							AND [flow_patterns].[link_flow_no] = @link_flow_no;
						--- UPDATE NUMBERS lot_special_flows.id
						SET @r_lsf = @@ROWCOUNT
						UPDATE [APCSProDB].[trans].[numbers]
						SET [id] = [id] + @r_lsf
						WHERE [name] = 'lot_special_flows.id';
						--- SET RESULT
						SET @result = 1;
						SET @result_stepno = @q1_step_no + @count_flow;
						----------------------------------------------------------------------------------------------
					END
				END
			END
		END
		--- (4.3) UPDATE DATA trans.lots
		IF ( @is_special_flow = 1 )
		BEGIN
			--- *** UPDATE DATA trans.lots ADD NOW
			IF ( ( SELECT [is_special_flow] FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id ) != 1 )
			BEGIN
				UPDATE [APCSProDB].[trans].[lots]
				SET [is_special_flow] = 1
					, [special_flow_id] = @update_spid
					, [process_state] = IIF( [process_state] = 100, 0, [process_state] )
					, [updated_at] = GETDATE()
					, [updated_by] = @user_id
				WHERE [id] = @lot_id;
			END
		END
		ELSE IF ( @is_special_flow = 0 )
		BEGIN
			--- *** UPDATE DATA trans.lots ADD AFTER
			IF ( ( SELECT [is_special_flow] FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id ) != 1 )
			BEGIN
				UPDATE [APCSProDB].[trans].[lots]
				SET [special_flow_id] = @update_spid
					, [updated_at] = GETDATE()
					, [updated_by] = @user_id
				WHERE [id] = @lot_id;
			END
		END
		--- (4.4) RETURN SUCESS AND COMMIT DATA
		IF ( @result = 1 )
		BEGIN
			COMMIT TRANSACTION;
			SELECT 'TRUE' AS Is_Pass 
				, 'Add special flow success.' AS Error_Message_ENG
				, N'เพิ่ม special flow สำเร็จ' AS Error_Message_THA 
				, '' AS Handling
				, @result_stepno AS StepNo
				, @count_flow AS CountFlow;
			RETURN;
		END
	END TRY
	BEGIN CATCH
		--- (4.4) RETURN ERROR AND ROLLBACK DATA
		ROLLBACK TRANSACTION;
		SELECT 'FALSE' AS Is_Pass 
			, 'Update fail. !!' AS Error_Message_ENG
			, N'การบันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA 
			, '' AS Handling
			, @result_stepno AS StepNo
			, NULL AS CountFlow;
		RETURN;
	END CATCH;
	------------------------------------------------------------------------------------------------------------------------------
END