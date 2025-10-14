-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create Date,,20220319>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_workingslip_lot_recall_ver_002] 
	-- Add the parameters for the stored procedure here
	@lotno VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT ROW_NUMBER() OVER(ORDER BY [member_lot].[member_lot_id]) AS [row_id]
		, [lots].[id] AS [lot_id]
		, [member_lot].[member_lot_id]
		--, ISNULL([lots].[external_lot_no], '') AS [member_lot]
		, [lots].[lot_no] AS [master_lot]
		, [member_lot].[lot_no] AS [member_lot]
		, [lots].[qty_in] AS [qty_member_lot]
		, CAST([packages].[short_name] AS CHAR(10)) AS [package_name]
		, CAST([device_names].[name] AS CHAR(20)) AS [device_name]
		, CAST(ISNULL([device_names].[rank], '') AS CHAR(7)) AS [Rank]
		, CAST(ISNULL([device_names].[tp_rank], '') AS CHAR(2)) AS [TPRank]
		, CAST([device_names].[assy_name] AS CHAR(20)) AS [ASSY_Model_Name]
		, [device_names].[pcs_per_pack] AS [packing_standard]
		, CASE 
			WHEN SUBSTRING(Trim([lots].[lot_no]),5,1) IN ('D','F') THEN CAST('MX' AS CHAR(12))
			ELSE CAST([surpluses].[mark_no] AS CHAR(12)) 
		END AS [MNo]
		, ISNULL([surpluses].[qc_instruction],'') AS [tomson_3]
		, CAST(ISNULL([surpluses].[mark_no],'') AS CHAR(12)) AS [Mno_Hasuu]
		, CAST(ISNULL([multi_labels].[user_model_name], [device_names].[name]) AS CHAR(20)) AS [Customer_Device]
		, [fukuoka].[R_Fukuoka_Model_Name] AS [R_Fukuoka_Model_Name]
		, CAST([device_names].[ft_name] AS CHAR(20)) AS [ft_name]
		,[sur_mas].[pdcd] AS [pdcd]
		, CASE 
			WHEN [surpluses].[transfer_flag] = 1 THEN [surpluses].[pcs] 
			ELSE CAST('' AS CHAR(6)) 
		END AS [Trans_fer]
		, [member_lot].[device_name_hasuu]
		, FORMAT(IIF([lots].[qty_in] < [device_names].[pcs_per_pack],[lots].[qty_in],([lots].[qty_in] % ([device_names].[pcs_per_pack] * ([lots].[qty_in]/[device_names].[pcs_per_pack])))),'N0') AS [qty_hasuu]
		, FORMAT(IIF([lots].[qty_in] < [device_names].[pcs_per_pack],0,([device_names].[pcs_per_pack] * ([lots].[qty_in]/[device_names].[pcs_per_pack]))),'N0') AS [qty_out] 
		, [PROCESS_RECALL_IF].[ABNORMALCASE]
		, [member_lot].[emp_num]
		, [lots].[created_at]
	FROM [APCSProDB].[trans].[lots]
	CROSS APPLY (
		SELECT [lot_combine].[member_lot_id]
			, [dv_hasuu].[name] AS [device_name_hasuu]
			, [lot_hasuu].[lot_no]
			, [users].[emp_num]
		FROM [APCSProDB].[trans].[lot_combine]
		INNER JOIN [APCSProDB].[trans].[lots] AS [lot_hasuu] ON [lot_combine].[member_lot_id] = [lot_hasuu].[id]
		INNER JOIN [APCSProDB].[method].[device_names] AS [dv_hasuu] ON [dv_hasuu].[id] = [lot_hasuu].[act_device_name_id]
		LEFT JOIN [APCSProDB].[man].[users] ON [lot_combine].[created_by] = [users].[id]
		WHERE [lot_combine].[lot_id] = [lots].[id]
			AND [lot_combine].[lot_id] != [lot_combine].[member_lot_id]
	) AS [member_lot]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [lots].[act_device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
	INNER JOIN [APCSProDB].[trans].[surpluses] AS [sur_mas] ON [lots].[id] = [sur_mas].[lot_id]
	LEFT JOIN [APCSProDB].[trans].[surpluses] ON [surpluses].[lot_id] = [member_lot].[member_lot_id]
	LEFT JOIN [APCSProDB].[method].[multi_labels] ON [device_names].[name] = [multi_labels].[device_name]
	LEFT JOIN [APCSProDWH].[dbo].[PROCESS_RECALL_IF] ON [lots].[lot_no] = [PROCESS_RECALL_IF].[NEWLOT]
	OUTER APPLY (
		SELECT TOP 1 [ROHM_Model_Name]
			, [ASSY_Model_Name]
			, [R_Fukuoka_Model_Name]
		FROM [APCSProDB].[method].[allocat_temp] AS [at] WITH (NOLOCK)
		WHERE TRIM([at].[ROHM_Model_Name]) = TRIM([device_names].[name])
			AND TRIM([at].[ASSY_Model_Name]) = TRIM([device_names].[assy_name]) 
	) AS [fukuoka]	
	WHERE [lots].[lot_no] = @lotno
		AND [lots].[production_category] = 70
END
