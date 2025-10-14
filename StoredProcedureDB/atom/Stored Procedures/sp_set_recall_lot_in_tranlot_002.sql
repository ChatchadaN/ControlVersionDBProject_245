-- =============================================
-- Author:		<Kittitat P.>
-- Create date: <2023/02/16>
-- Description:	<Create recall_lot (D lot) in trans.lots>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_recall_lot_in_tranlot_002]
	-- Add the parameters for the stored procedure here
	@new_lotno VARCHAR(10)
	, @original_lotno VARCHAR(10)
	, @flow_pattern_id INT
	, @qty_pass INT
    , @qty_out INT
    , @qty_hasuu INT
	, @empid INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----------------------------------------------------------------------------
	----- # log exec stored procedure
	----------------------------------------------------------------------------
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		[record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, ISNULL('EXEC [atom].[sp_set_recall_lot_in_tranlot_003] @new_lotno = ''' + @new_lotno + '''','EXEC [atom].[sp_set_recall_lot_in_tranlot_003] @new_lotno = NULL')
			+ ISNULL(', @original_lotno = ''' + @original_lotno + '''',', @original_lotno = NULL')
			+ ISNULL(', @empid = ' + CAST(@empid AS VARCHAR),', @empid = NULL')
			+ ISNULL(', @flow_pattern_id = ' + CAST(@flow_pattern_id AS VARCHAR),', @flow_pattern_id = NULL')
			+ ISNULL(', @qty_pass = ' + CAST(@qty_pass AS VARCHAR),', @qty_pass= NULL')
			+ ISNULL(', @qty_out = ' + CAST(@qty_out AS VARCHAR),', @qty_out = NULL')
			+ ISNULL(', @qty_hasuu = ' + CAST(@qty_hasuu AS VARCHAR),', @qty_hasuu = NULL')
		, @new_lotno;
	----------------------------------------------------------------------------
	----- # create lot in trans.lots
	----------------------------------------------------------------------------
	------- check surpluses --------
	IF NOT EXISTS (SELECT [serial_no] FROM [APCSProDB].[trans].[surpluses] WITH (NOLOCK) WHERE [serial_no] = @original_lotno)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, 'lot_no hot found in surpluses !!' AS [Error_Message_ENG]
			, N'ไม่พบ lot_no ใน surpluses !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END
	----------------------------------------------------------------------------
	------- create lots --------
	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @trans_lots_original_id INT = (SELECT [id] FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) WHERE [lot_no] = @original_lotno);
		IF EXISTS (
			SELECT [lot_no]
			FROM (
				SELECT [lots].[lot_no]
					, [device_slips].[version_num]
					, ROW_NUMBER() OVER (ORDER BY [device_slips].[version_num] DESC) AS [row]
				FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) 
				INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [lots].[act_device_name_id] = [device_names].[id]
				INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_name_id] = [device_names].[id] 
					AND [device_versions].[device_type] = 6 
				INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_id] = [device_versions].[device_id] 
					AND [device_slips].[is_released] = 1
				WHERE [lots].[id] = @trans_lots_original_id
			) AS [devices]
			WHERE [row] = 1
		)
		BEGIN ---- exists ----
			-----------------------------------------------------------------------------
			------- check lots --------
			IF EXISTS (SELECT [id] FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) WHERE [lot_no] = @new_lotno)
			BEGIN
				UPDATE [APCSProDB].[trans].[lots]
				SET [wip_state] = 20
					, [quality_state] = 0
					, [is_special_flow] = 0
					, [special_flow_id] = NULL
				WHERE [lot_no] = @new_lotno;
			END
			ELSE
			BEGIN
				---------- get lots.id --------  
				DECLARE @trans_lots_id INT
				SELECT @trans_lots_id = [numbers].[id] + 1 
				FROM [APCSProDB].[trans].[numbers] WITH (NOLOCK)
				WHERE [numbers].[name] = 'lots.id';

				-------- set lots.id --------  
				UPDATE [APCSProDB].[trans].[numbers]
				SET [id] = @trans_lots_id
				WHERE [numbers].[name] = 'lots.id';

				-------- set data to trans.lots --------
				INSERT INTO [APCSProDB].[trans].[lots]
					( [id]
					, [lot_no]
					, [product_family_id]
					, [act_package_id]
					, [act_device_name_id]
					, [device_slip_id]
					, [order_id]
					, [step_no]
					, [act_process_id]
					, [act_job_id]
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
					, [in_plan_date_id]
					, [out_plan_date_id]
					, [master_lot_id]
					, [depth]
					, [sequence]
					, [wip_state]
					, [process_state]
					, [quality_state]
					, [first_ins_state]
					, [final_ins_state]
					, [is_special_flow]
					, [special_flow_id]
					, [is_temp_devided]
					, [temp_devided_count]
					, [product_class_id]
					, [priority]
					, [finish_date_id]
					, [finished_at]
					, [in_date_id]
					, [in_at]
					, [ship_date_id]
					, [ship_at]
					, [modify_out_plan_date_id]
					, [start_step_no]
					, [created_at]
					, [created_by]
					, [external_lot_no]
					, [production_category] )
				SELECT @trans_lots_id AS [id]
					, [lots].[lot_no]
					, [lots].[product_family_id]
					, [lots].[act_package_id]
					, [lots].[act_device_name_id]
					, [lots].[device_slip_id]
					, [lots].[order_id]
					, [lots].[step_no]
					, [lots].[act_process_id]
					, [lots].[act_job_id]
					, [lots].[qty_in]
					, [lots].[qty_pass]
					, [lots].[qty_fail]
					, [lots].[qty_last_pass]
					, [lots].[qty_last_fail]
					, [lots].[qty_pass_step_sum]
					, [lots].[qty_fail_step_sum]
					, [lots].[qty_divided]
					, [lots].[qty_hasuu]
					, [lots].[qty_out]
					, [lots].[is_exist_work]
					, [lots].[in_plan_date_id]
					, [lots].[out_plan_date_id]
					, [lots].[master_lot_id]
					, [lots].[depth]
					, [lots].[sequence]
					, [lots].[wip_state]
					, [lots].[process_state]
					, [lots].[quality_state]
					, [lots].[first_ins_state]
					, [lots].[final_ins_state]
					, [lots].[is_special_flow]
					, [lots].[special_flow_id]
					, [lots].[is_temp_devided]
					, [lots].[temp_devided_count]
					, [lots].[product_class_id]
					, [lots].[priority]
					, [lots].[finish_date_id]
					, [lots].[finished_at]
					, [lots].[in_date_id]
					, [lots].[in_at]
					, [lots].[ship_date_id]
					, [lots].[ship_at]
					, [lots].[modify_out_plan_date_id]
					, [lots].[start_step_no]
					, [lots].[created_at]
					, [lots].[created_by]
					, [lots].[external_lot_no]
					, [lots].[production_category]
				FROM (
					SELECT @new_lotno AS [lot_no]
						, [device_slips].[product_family_id]
						, [device_slips].[act_package_id]
						, [device_slips].[act_device_name_id]
						, [device_slips].[device_slip_id]
						, NULL AS [order_id]
						, [device_slips].[step_no] AS [step_no]
						, [device_slips].[act_process_id]
						, [device_slips].[act_job_id]
						, @qty_pass AS [qty_in]
						, @qty_pass AS [qty_pass]
						, 0 AS [qty_fail]
						, 0 AS [qty_last_pass]
						, 0 AS [qty_last_fail]
						, 0 AS [qty_pass_step_sum]
						, 0 AS [qty_fail_step_sum]
						, 0 AS [qty_divided]
						, @qty_hasuu AS [qty_hasuu]
						, @qty_out AS [qty_out]
						, 0 AS [is_exist_work]
						, [days].[id] AS [in_plan_date_id]
						, [days].[id] + 15 AS [out_plan_date_id]
						, [lots].[id] AS [master_lot_id]
						, 0 AS [depth]
						, 0 AS [sequence]
						, 20 AS [wip_state]
						, 0 AS [process_state]
						, 0 AS [quality_state]
						, 0 AS [first_ins_state]
						, 0 AS [final_ins_state]
						, 0 AS [is_special_flow]
						, NULL AS [special_flow_id]
						, 0 AS [is_temp_devided]
						, 0 AS [temp_devided_count]
						, 0 AS [product_class_id]
						, 50 AS [priority]
						, NULL AS [finish_date_id]
						, NULL AS [finished_at]
						, [days].[id] AS [in_date_id]
						, GETDATE() AS [in_at]
						, NULL AS [ship_date_id]
						, NULL AS [ship_at]
						, [days].[id] + 15 AS [modify_out_plan_date_id]
						, [device_slips].[step_no] AS [start_step_no]
						, GETDATE() AS [created_at]
						, @empid AS [created_by]
						, [lots].[lot_no] AS [external_lot_no]
						, 70 AS [production_category]
					FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
					CROSS APPLY (
						SELECT [device_slips].*
						FROM (
							SELECT [device_slips].[device_slip_id]
								, [packages].[product_family_id]
								, [packages].[id] AS [act_package_id]
								, [device_names].[id] AS [act_device_name_id]
								, [device_flows].[step_no]
								, [jobs].[process_id] AS [act_process_id]
								, [jobs].[id] AS [act_job_id]
								, ROW_NUMBER() OVER (ORDER BY [device_slips].[version_num] DESC) AS [row_version]
								, ROW_NUMBER() OVER (PARTITION BY [device_slips].[version_num] ORDER BY [device_slips].[version_num] DESC,[device_flows].[step_no] ASC) AS [row_stepno]
							FROM [APCSProDB].[method].[device_slips] WITH (NOLOCK)
							INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_slips].[device_id] = [device_versions].[device_id]
							INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_versions].[device_name_id] = [device_names].[id]
							INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [device_names].[package_id] = [packages].[id]
							INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [device_flows].[device_slip_id] 
								AND ISNULL([device_flows].[is_skipped],0) <> 1
							INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
							WHERE [device_versions].[device_name_id] = [lots].[act_device_name_id] 
								AND [device_versions].[device_type] = 6 --slip d lot
								AND [device_slips].[is_released] = 1
						) AS [device_slips]
						WHERE [row_version] = 1 --slip last version 
							AND [row_stepno] = 1 --first flow in slip 
					) AS [device_slips]
					INNER JOIN [APCSProDB].[trans].[days] WITH (NOLOCK) ON [days].[date_value] = FORMAT(GETDATE(), 'yyyy-MM-dd')
					WHERE [lots].[id] = @trans_lots_original_id
				) AS [lots]
			END
			-----------------------------------------------------------------------------
			COMMIT TRANSACTION;
			SELECT 'TRUE' AS [Is_Pass] 
				, '' AS [Error_Message_ENG]
				, N'' AS [Error_Message_THA] 
				, N'' AS [Handling];
			RETURN;
			-----------------------------------------------------------------------------
		END ---- exists ----
		ELSE
		BEGIN ---- not exists ----
			-----------------------------------------------------------------------------
			COMMIT TRANSACTION;
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Slip not register !!' AS [Error_Message_ENG]
				, N'Slip ยังไม่ได้ถูกลงทะเบียน !!' AS [Error_Message_THA] 
				, N'กรุณาติดต่อ system' AS [Handling];
			RETURN;
			-----------------------------------------------------------------------------
		END ---- not exists ---
	END TRY
	BEGIN CATCH
		ROLLBACK TRANSACTION;
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Insert data trans.lots error !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล trans.lots ไม่สำเร็จ !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END CATCH
END
