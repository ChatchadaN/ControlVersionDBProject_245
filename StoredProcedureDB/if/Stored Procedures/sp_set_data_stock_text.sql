-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_set_data_stock_text]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	------------------------------------------------------------------------------------
	---- # CLARE data
	------------------------------------------------------------------------------------
	DELETE FROM [APCSProDWH].[if].[stock_txt_data_monthly];

	------------------------------------------------------------------------------------
	---- # CPS data
	------------------------------------------------------------------------------------
	INSERT INTO [APCSProDWH].[if].[stock_txt_data_monthly]
		( [stock_class]
		, [lot_no]
		, [package_name]
		, [device_name]
		, [assy_name]
		, [rohm_fukuoka_name]
		, [rank]
		, [tp_rank]
		, [pdcd]
		, [hasuu_stock_qty]
		, [wip_qty]
		, [total_qty]
		, [derivery_date]
		, [remark] )
	SELECT '  ' AS [stock_class]
		, [v_cps_stk_rist_temp].[lot_no]
		, ISNULL([cps_data_temp].[package_name], [pk].[short_name]) AS [package_name]
		, ISNULL([cps_data_temp].[device_name], [dn].[name]) AS [device_name]
		, ISNULL([cps_data_temp].[assy_name], [dn].[assy_name]) AS [assy_name]
		, ISNULL([cps_data_temp].[rohm_fukuoka_name], [lsi_ship].[R_Fukuoka_Model_Name]) AS [rohm_fukuoka_name]
		, ISNULL([cps_data_temp].[rank], ISNULL([dn].[rank], '     ')) AS [rank]
		, ISNULL([cps_data_temp].[tp_rank], ISNULL([dn].[tp_rank], '   ')) AS [tp_rank]	
		, SUBSTRING([sur].[pdcd], 5, 1) AS [pdcd]
		, [v_cps_stk_rist_temp].[qty] AS [hasuu_stock_qty]
		, 0 AS [wip_qty]
		, [v_cps_stk_rist_temp].[qty] AS [total_qty]
		, FORMAT([v_cps_stk_rist_temp].[updated_at], 'yyMMdd') AS [derivery_date]
		, 'CPS' AS [remark]
	FROM [APCSProDWH].[if].[v_cps_stk_rist_temp]
	LEFT JOIN [APCSProDWH].[if].[cps_data_temp] ON [v_cps_stk_rist_temp].[lot_no] = [cps_data_temp].[lot_no]
	LEFT JOIN [APCSProDB].[trans].[lots] ON [v_cps_stk_rist_temp].[lot_no] = [lots].[lot_no]
	LEFT JOIN [APCSProDB].[trans].[surpluses] AS [sur] ON [lots].[id] = [sur].[lot_id]
	LEFT JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id] 
	LEFT JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id] 
	LEFT JOIN [APCSProDWH].[dbo].[LSI_SHIP_IF] AS [lsi_ship] ON [lots].[lot_no] = [lsi_ship].[LotNo];

	------------------------------------------------------------------------------------
	---- # OGI data (MILK-RUN)
	------------------------------------------------------------------------------------
	IF EXISTS (
		SELECT TOP 1 [lots].[lot_no]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[trans].[lot_process_records] ON [lots].[id] = [lot_process_records].[lot_id]
		LEFT JOIN [APCSProDWH].[if].[cps_data_temp] ON [lots].[lot_no] = [cps_data_temp].[lot_no]
		LEFT JOIN [APCSProDWH].[if].[stock_txt_data_monthly] ON [lots].[lot_no] = [stock_txt_data_monthly].[lot_no]
		LEFT JOIN [APCSProDB].[trans].[surpluses] AS [sur] ON [lots].[id] = [sur].[lot_id]
		LEFT JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id] 
		LEFT JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id] 
		LEFT JOIN [APCSProDWH].[dbo].[LSI_SHIP_IF] AS [lsi_ship] ON [lots].[lot_no] = [lsi_ship].[LotNo]
		WHERE (DATEDIFF(DAY, GETDATE(), [lot_process_records].[recorded_at]) = 0)
			AND ([lot_process_records].[recorded_at] BETWEEN FORMAT(GETDATE(), 'yyyy-MM-dd') + ' 08:00:00' AND FORMAT(GETDATE(), 'yyyy-MM-dd') + ' 08:10:00')
			AND ([lot_process_records].[record_class] = 7)
			AND ([lot_process_records].[job_id] = 317)
			AND [stock_txt_data_monthly].[lot_no] IS NULL
	)
	BEGIN
		INSERT INTO [APCSProDWH].[if].[stock_txt_data_monthly]
			( [stock_class]
			, [lot_no]
			, [package_name]
			, [device_name]
			, [assy_name]
			, [rohm_fukuoka_name]
			, [rank]
			, [tp_rank]
			, [pdcd]
			, [hasuu_stock_qty]
			, [wip_qty]
			, [total_qty]
			, [derivery_date]
			, [remark] )
		SELECT '  ' AS [stock_class]
			, CAST([lots].[lot_no] AS VARCHAR(10)) AS [lot_no]
			, ISNULL([cps_data_temp].[package_name], [pk].[short_name]) AS [package_name]
			, ISNULL([cps_data_temp].[device_name], [dn].[name]) AS [device_name]
			, ISNULL([cps_data_temp].[assy_name], [dn].[assy_name]) AS [assy_name]
			, ISNULL([cps_data_temp].[rohm_fukuoka_name], [lsi_ship].[R_Fukuoka_Model_Name]) AS [rohm_fukuoka_name]
			, ISNULL([cps_data_temp].[rank], ISNULL([dn].[rank], '     ')) AS [rank]
			, ISNULL([cps_data_temp].[tp_rank], ISNULL([dn].[tp_rank], '   ')) AS [tp_rank]	
			, SUBSTRING([sur].[pdcd], 5, 1) AS [pdcd]
			, [lots].[qty_out] AS [hasuu_stock_qty]
			, 0 AS [wip_qty]
			, [lots].[qty_out] AS [total_qty]
			, FORMAT(GETDATE(), 'yyMMdd') AS [derivery_date]
			, 'OGI' AS [remark]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[trans].[lot_process_records] ON [lots].[id] = [lot_process_records].[lot_id]
		LEFT JOIN [APCSProDWH].[if].[cps_data_temp] ON [lots].[lot_no] = [cps_data_temp].[lot_no]
		LEFT JOIN [APCSProDWH].[if].[stock_txt_data_monthly] ON [lots].[lot_no] = [stock_txt_data_monthly].[lot_no]
		LEFT JOIN [APCSProDB].[trans].[surpluses] AS [sur] ON [lots].[id] = [sur].[lot_id]
		LEFT JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id] 
		LEFT JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id] 
		LEFT JOIN [APCSProDWH].[dbo].[LSI_SHIP_IF] AS [lsi_ship] ON [lots].[lot_no] = [lsi_ship].[LotNo]
		WHERE (DATEDIFF(DAY, GETDATE(), [lot_process_records].[recorded_at]) = 0)
			AND ([lot_process_records].[recorded_at] BETWEEN FORMAT(GETDATE(), 'yyyy-MM-dd') + ' 08:00:00' AND FORMAT(GETDATE(), 'yyyy-MM-dd') + ' 08:10:00')
			AND ([lot_process_records].[record_class] = 7)
			AND ([lot_process_records].[job_id] = 317)
			AND ([stock_txt_data_monthly].[lot_no] IS NULL);
	END

	------------------------------------------------------------------------------------
	---- # HASUU data
	------------------------------------------------------------------------------------
	INSERT INTO [APCSProDWH].[if].[stock_txt_data_monthly]
		( [stock_class]
		, [lot_no]
		, [package_name]
		, [device_name]
		, [assy_name]
		, [rohm_fukuoka_name]
		, [rank]
		, [tp_rank]
		, [pdcd]
		, [hasuu_stock_qty]
		, [wip_qty]
		, [total_qty]
		, [derivery_date]
		, [remark] )
	SELECT DISTINCT [sur].[stock_class] AS [stock_class]
		, CAST([lots].[lot_no] AS VARCHAR(10)) AS [lot_no]
		, ISNULL([hasuu_data_temp].[package_name], [pk].[short_name]) AS [package_name]
		, ISNULL([hasuu_data_temp].[device_name], [dn].[name]) AS [device_name]
		, ISNULL([hasuu_data_temp].[assy_name], [dn].[assy_name]) AS [assy_name]
		, ISNULL([hasuu_data_temp].[rohm_fukuoka_name], ISNULL([a_temp].[R_Fukuoka_Model_Name], [a_temp_other].[R_Fukuoka_Model_Name])) AS [rohm_fukuoka_name]
		, ISNULL([hasuu_data_temp].[rank], ISNULL([dn].[rank], '     ')) AS [rank]
		, ISNULL([hasuu_data_temp].[tp_rank], ISNULL([dn].[tp_rank], '   ')) AS [tp_rank]	
		, SUBSTRING([sur].[pdcd], 5, 1) AS [pdcd]
		, [sur].[pcs] AS [hasuu_stock_qty]
		, IIF(SUBSTRING([lots].[lot_no], 5, 1) = 'D' 
			, IIF([lots].[production_category] IN (20, 23, 70) 
				AND [lots].[pc_instruction_code] IS NULL
				, IIF([lots].[wip_state] IN (100, 70)
					, 0
					, (ISNULL([dn].[pcs_per_pack], 0) * ([lots].[qty_in] / ISNULL([dn].[pcs_per_pack], 0)))
				)
				, 0
			)
			, 0
		) AS [wip_qty]
		, IIF(SUBSTRING([lots].[lot_no], 5, 1) = 'D' 
			, IIF([lots].[production_category] IN (20, 23, 70) 
				AND [lots].[pc_instruction_code] IS NULL
				, IIF([lots].[wip_state] IN (100, 70)
					, (0 + [sur].[pcs])
					, (ISNULL([dn].[pcs_per_pack], 0) * ([lots].[qty_in] / ISNULL([dn].[pcs_per_pack], 0))) + [sur].[pcs]
				)
				, (0 + [sur].[pcs])
			)
			, (0 + [sur].[pcs])
		) AS [total_qty]
		, FORMAT([sur].[created_at], 'yyMMdd') AS [derivery_date]
		, 'HASUU' AS [remark]
	FROM [APCSProDB].[trans].[surpluses] AS [sur]
	LEFT JOIN [APCSProDWH].[if].[hasuu_data_temp] ON [sur].[serial_no] = [hasuu_data_temp].[lot_no]
	LEFT JOIN [APCSProDB].[trans].[lots] ON [sur].[lot_id] = [lots].[id]
	LEFT JOIN [APCSProDB].[method].[packages] AS [pk] ON [lots].[act_package_id] = [pk].[id] 
	LEFT JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lots].[act_device_name_id] = [dn].[id]
	LEFT JOIN [APCSProDB].[method].[allocat_temp] AS [a_temp] ON [lots].[lot_no] = [a_temp].[LotNo]
	OUTER APPLY (
		SELECT [R_Fukuoka_Model_Name]
		FROM [APCSProDB].[method].[allocat_temp]
		WHERE ([ROHM_Model_Name] = [dn].[name])
			AND ([a_temp].[R_Fukuoka_Model_Name] IS NULL)
		GROUP BY [R_Fukuoka_Model_Name]
	) AS [a_temp_other]
	WHERE [sur].[in_stock] = 2
		AND [sur].[pcs] >= 0;
END