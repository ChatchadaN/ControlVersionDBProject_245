-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_webdemo_set_create_lot]
	-- Add the parameters for the stored procedure here
	@new_lotno VARCHAR(10), 
	@original_lotno atom.trans_lots READONLY, 
	@empid INT, 
	@qty INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

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
		, @new_lotno --AS [lot_no]
		, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_create_lot]' 
			+ ' @new_lotno = ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
			+ ' ,@original_lotno = ' + ISNULL( '''' + CAST( STUFF((SELECT CONCAT(',', [lot_no]) FROM @original_lotno FOR XML PATH ('')), 1, 1, '') AS VARCHAR(MAX) ) + '''', 'NULL' ) 
			+ ' ,@empid = ' + ISNULL( CAST( @empid AS VARCHAR(10) ), 'NULL' )
			+ ' ,@qty = ' + ISNULL( CAST( @qty AS VARCHAR(10) ), 'NULL' ); --AS [command_text]

	DECLARE @device_id INT 
			
	SET @device_id  = (
		SELECT [device_names].[id]
		FROM @original_lotno AS [OldLotTable]
		INNER JOIN [APCSProDB].[trans].[lots] ON [OldLotTable].[lot_no] = [lots].[lot_no]
		INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
		GROUP BY [device_names].[id]
	);

	IF NOT EXISTS (SELECT [lot_no] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @new_lotno)
	BEGIN
		---- # create trans.lots
		DECLARE @trans_lots_id INT
		SELECT @trans_lots_id = [numbers].[id] + 1 
		FROM [APCSProDB].[trans].[numbers]
		WHERE [numbers].[name] = 'lots.id';

		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = @trans_lots_id
		WHERE [numbers].[name] = 'lots.id';

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
			, @new_lotno AS [lot_no]
			, [device_slips].[product_family_id]
			, [device_slips].[act_package_id]
			, [device_slips].[act_device_name_id]
			, [device_slips].[device_slip_id]
			, NULL AS [order_id]
			, [device_slips].[step_no]
			, [device_slips].[act_process_id]
			, [device_slips].[act_job_id]
			, @qty AS [qty_in]
			, @qty AS [qty_pass]
			, 0 AS [qty_fail]
			, 0 AS [qty_last_pass]
			, 0 AS [qty_last_fail]
			, 0 AS [qty_pass_step_sum]
			, 0 AS [qty_fail_step_sum]
			, 0 AS [qty_divided]
			, @qty AS [qty_hasuu]
			, 0 AS [qty_out] 
			, 0 AS [is_exist_work]
			, [days].[id] AS [in_plan_date_id]
			, [days].[id] + 15 AS [out_plan_date_id]
			, NULL AS [master_lot_id]
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
			, NULL AS [external_lot_no]
			, 24 AS [production_category] ---- # DLot B/I
		FROM (
			SELECT [device_slips].[device_slip_id]
				, [packages].[product_family_id]
				, [packages].[id] AS [act_package_id]
				, [device_names].[id] AS [act_device_name_id]
				, [device_flows].[step_no]
				, [jobs].[process_id] AS [act_process_id]
				, [jobs].[id] AS [act_job_id]
				, ROW_NUMBER() OVER (
					ORDER BY [device_slips].[version_num] DESC
				) AS [row_version]
				, ROW_NUMBER() OVER (
					PARTITION BY [device_slips].[version_num]
					ORDER BY [device_slips].[version_num] DESC
						,[device_flows].[step_no] ASC
				) AS [row_stepno]
				, [device_slips].[version_num]
				, [device_names].[pcs_per_pack] AS [standard_qty]
			FROM [APCSProDB].[method].[device_slips]
			INNER JOIN [APCSProDB].[method].[device_versions] ON [device_slips].[device_id] = [device_versions].[device_id]
			INNER JOIN [APCSProDB].[method].[device_names] ON [device_versions].[device_name_id] = [device_names].[id]
			INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
			INNER JOIN [APCSProDB].[method].[device_flows]ON [device_slips].[device_slip_id] = [device_flows].[device_slip_id] 
				AND ISNULL([device_flows].[is_skipped],0) <> 1
			INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[id] = [device_flows].[job_id]
			WHERE [device_versions].[device_name_id] = @device_id
				AND [device_versions].[device_type] = 0
				AND [jobs].[id] = 120 ---- # 120 : 100% B/I
				AND [device_slips].[is_released] = 1
		) AS [device_slips]
		INNER JOIN [APCSProDB].[trans].[days] ON [days].[date_value] = FORMAT(GETDATE(), 'yyyy-MM-dd')
		WHERE [row_version] = 1 --slip last version 
			AND [row_stepno] = 1; --first flow in slip 
	END
	ELSE
	BEGIN
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
			, @new_lotno --AS [lot_no]
			, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_create_lot]' 
				+ ' LotNo : ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
				+ ' Error : trans.lots has been created.'; --AS [command_text]

		SELECT 'FALSE' AS [Is_Pass] 
			, 'trans.lots has been created !!' AS [Error_Message_ENG]
			, N'trans.lots ถูกสร้างแล้ว !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END

	IF EXISTS (SELECT [lot_no] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @new_lotno)
	BEGIN
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
END
