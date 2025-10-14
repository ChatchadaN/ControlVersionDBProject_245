-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_disabel_slip_for_print_F_lot_outsource] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	---- # Debut
	--SELECT [LOT_NO_2]
	--	, [OUTPUT_END_FLG]
	--	, [OUTPUT_DATE]
	--	, '1' AS [NEW_OUTPUT_END_FLG]
	--  , FORMAT(GETDATE(), 'yyyyMMddHHmmss') AS [NEW_OUTPUT_DATE]
	--FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] AS [Denpyo]
	--INNER JOIN [ISDB].[Half_Product].[dbo].[Half_Product_Order_List] AS [h_product] 
	--	ON [Denpyo].[LOT_NO_2] = [h_product].[LotNo]
	--INNER JOIN [APCSProDB].[trans].[lots]
	--	ON [Denpyo].[LOT_NO_2] = [lots].[lot_no]
	--INNER JOIN [APCSProDB].[method].[device_names] 
	--	on [device_names].[id] = [lots].[act_device_name_id]
	--INNER JOIN [APCSProDB].[method].[packages]
	--	on [packages].[id] = [device_names].[package_id]
	--INNER JOIN [APCSProDB].[method].[package_groups]
	--	on [package_groups].[id] = [packages].[package_group_id]
	--WHERE [Denpyo].[OUTPUT_END_FLG] = '0'
	--	AND [package_groups].[name] != 'MAP';
	
	---- # Real
	--UPDATE [Denpyo]
	--SET [OUTPUT_END_FLG] = 1
	--	, [OUTPUT_DATE] = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
	--FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] AS [Denpyo]
	--INNER JOIN [ISDB].[Half_Product].[dbo].[Half_Product_Order_List] AS [h_product] 
	--	ON [Denpyo].[LOT_NO_2] = [h_product].[LotNo]
	--INNER JOIN [APCSProDB].[trans].[lots]
	--	ON [Denpyo].[LOT_NO_2] = [lots].[lot_no]
	--INNER JOIN [APCSProDB].[method].[device_names] 
	--	on [device_names].[id] = [lots].[act_device_name_id]
	--INNER JOIN [APCSProDB].[method].[packages]
	--	on [packages].[id] = [device_names].[package_id]
	--INNER JOIN [APCSProDB].[method].[package_groups]
	--	on [package_groups].[id] = [packages].[package_group_id]
	--WHERE [Denpyo].[OUTPUT_END_FLG] = '0'
	--	AND [package_groups].[name] != 'MAP';

	---- # UPDATE 2025/05/27 16:00:00
	WITH DenpyoTable AS (
		SELECT [Denpyo].[LOT_NO_2]
			, ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS [RowNumber]
			, COUNT([Denpyo].[LOT_NO_2]) OVER() AS [RowTotal]
		FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] AS [Denpyo]
		INNER JOIN [ISDB].[Half_Product].[dbo].[Half_Product_Order_List] AS [h_product] 
			ON [Denpyo].[LOT_NO_2] = [h_product].[LotNo]
		INNER JOIN [APCSProDB].[trans].[lots]
			ON [Denpyo].[LOT_NO_2] = [lots].[lot_no]
		INNER JOIN [APCSProDB].[method].[device_names] 
			on [device_names].[id] = [lots].[act_device_name_id]
		INNER JOIN [APCSProDB].[method].[packages]
			on [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups]
			on [package_groups].[id] = [packages].[package_group_id]
		WHERE [Denpyo].[OUTPUT_END_FLG] = '0'
			AND [package_groups].[name] != 'MAP'
	)
	UPDATE [Denpyo]
	SET [Denpyo].[OUTPUT_END_FLG] = '1'
		, [Denpyo].[OUTPUT_DATE] = FORMAT(GETDATE(), 'yyyyMMddHHmmss')
		, [Denpyo].[TOTAL_PAGE_COUNT] = [RowTotal]
		, [Denpyo].[PAGE_COUNT] = [RowNumber]
	FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] AS [Denpyo]
	INNER JOIN DenpyoTable ON [DenpyoTable].[LOT_NO_2] = [Denpyo].[LOT_NO_2];
END