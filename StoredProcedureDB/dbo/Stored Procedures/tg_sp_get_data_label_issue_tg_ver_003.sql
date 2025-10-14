-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_label_issue_tg_ver_003]
	-- Add the parameters for the stored procedure here
	@lotno VARCHAR(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--update parameter lotno data : 2021/12/09 time : 11.42
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
		, 'EXEC [dbo].[tg_sp_get_data_label_issue_tg_ver_003] @lotno = ''' + @lotno + ''''
		, @lotno;

    -- Insert statements for procedure here
	IF NOT EXISTS( SELECT LotNo FROM APCSProDB.method.allocat where LotNo = @lotno )
		AND NOT EXISTS( SELECT LotNo FROM APCSProDB.method.allocat_temp where LotNo = @lotno )
	BEGIN
		----# RETURN FALSE
		SELECT 'FALSE' AS [Status] 
			, 'SEARCH DATA ERROR !!' AS [Error_Message_ENG]
			, N'ไม่พบข้อมูลของ lotno :' + @lotno AS [Error_Message_THA] 
			, N' กรุณาติดต่อ System' AS [Handling]
			, 'Null' AS [Lotno]
			, 'Null' AS [Package]
			, 'Null' AS [ROHM_Model_Name]
			, '0' AS [QtyPass_Standard]
			, '0' AS [Totalhasuu]
			, '0' AS [Standerd_QTY]
			, '0' AS [Qty_Full_Reel_All]
			, '0' AS [wip_state]
			, '0' AS [quality_state]
			, 'Null' AS [quality_state_name];
		RETURN;
	END

	----# RETURN TRUE
	SELECT [lots].[lot_no] AS [Lotno]
		, [device_names].[name] AS [ROHM_Model_Name]
		, [device_names].[assy_name] AS [ASSY_Model_Name]
		, [packages].[name] AS [Package]
		, CASE 
			WHEN [device_names].[rank] = ' ' THEN '-' 
			ELSE [device_names].[rank] 
		END AS [ranks]
		, [device_names].[tp_rank]
		, [lots].[qty_pass] AS [QtyPass_Standard]
		, CASE 
			WHEN [device_names].[pcs_per_pack] = 0 THEN '0' 
			ELSE ([lots].[qty_pass])%([device_names].[pcs_per_pack]) 
		END AS [Totalhasuu]
		, [device_names].[pcs_per_pack] AS [Standerd_QTY]
		, CASE 
			WHEN [device_names].[pcs_per_pack] = 0 THEN '0' 
			WHEN ([device_names].[pcs_per_pack]) * ([lots].[qty_pass]/([device_names].[pcs_per_pack])) = 0 THEN '0'
			ELSE ([device_names].[pcs_per_pack]) * ([lots].[qty_pass]/([device_names].[pcs_per_pack])) 
		END AS [Qty_Full_Reel_All]
		, [lots].[wip_state]
		, 'TRUE' AS [Status]
		--, CASE 
		--	WHEN [denpyo].[ORDER_MODEL_NAME] IS NULL THEN ' ' 
		--	ELSE CAST([denpyo].[ORDER_MODEL_NAME] AS CHAR(20)) 
		--END AS [R_Fukuoka_Model_Name]
		--, [denpyo].[MNO2] AS [Mno_STD]
		--, CASE 
		--	WHEN ([lots].[qty_pass] > [device_names].[pcs_per_pack] OR [lots].[qty_pass] = [device_names].[pcs_per_pack]) THEN '0' 
		--	ELSE [lots].[quality_state] 
		--END AS [quality_state]		
		, [allocat].[R_Fukuoka_Model_Name]
		, [allocat].[MNo] AS [Mno_STD]
		, [lots].[quality_state] AS [quality_state] --edit condition 2023/09/15 time : 15.19 by aomsin
		, [item_labels].[label_eng] AS [quality_state_name]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] AS device_names  ON [device_names].[id] = [device_versions].[device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id]  = [packages].[id]
	CROSS APPLY (
		SELECT TOP 1 [LotNo]
			, [R_Fukuoka_Model_Name]
			, [MNo]
		FROM (
			SELECT [LotNo]
				, [R_Fukuoka_Model_Name]
				, [MNo] 
			FROM [APCSProDB].[method].[allocat] 
			WHERE [LotNo] = [lots].[lot_no]
			UNION
			SELECT [LotNo]
				, [R_Fukuoka_Model_Name]
				, [MNo] 
			FROM [APCSProDB].[method].[allocat_temp] 
			WHERE [LotNo] = [lots].[lot_no]
		) AS [allocat]
	) AS [allocat]
	--INNER JOIN [APCSProDB].[method].[allocat] ON [lots].[lot_no] = allocat.LotNo 
	--LEFT JOIN [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] AS [denpyo] on [lots].[lot_no] = [denpyo].[LOT_NO_1]
	LEFT JOIN [APCSProDB].[trans].[item_labels] ON [item_labels].[name] = 'lots.quality_state'
		AND [lots].[quality_state] = [item_labels].[val]
	WHERE [lots].[lot_no] = @lotno;
END
