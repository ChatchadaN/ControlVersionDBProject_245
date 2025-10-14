-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_interface_send_material_stock_data]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT ROW_NUMBER() OVER(ORDER BY [materials].[barcode] ASC) AS [No]
		, SUBSTRING([materials].[barcode], 2, LEN([materials].[barcode])) AS [Barcode]
		, [categories].[name] AS [Category]
		, [productions].[name] AS [Product]
		, [materials].[lot_no] AS [Lot]
		, [material_arrival_records].[invoice_no] AS [Invoice]
		, [materials].[quantity] AS [Quantity] 
		, [locations].[name] AS [Location]
		, [locations].[wh_code]
		, [materials].[created_at] AS [Receive Date]
		, [il_qc].[label_eng] AS [QC state]
		, [m_state].[descriptions] AS [Material State]
		, [m_ps].[descriptions] AS [Process State]
		, '' AS [Hold Type]
		, [m_ls].[label_eng] AS [Limit State]
		, [materials].[limit_date] AS [Limit Date]
		, [materials].[extended_limit_date] AS [Extend Date]
		, [m_parent].[barcode] AS [Repack]
	FROM [APCSProDB].[trans].[material_arrival_records] 
	INNER JOIN [APCSProDB].[trans].[materials] ON [material_arrival_records].[material_id] = [materials].[id] 
	INNER JOIN [APCSProDB].[material].[productions] ON [materials].[material_production_id] = [productions].[id] 
	INNER JOIN [APCSProDB].[material].[categories] ON [productions].[category_id] = [categories].[id]
	INNER JOIN [APCSProDB].[material].[locations] ON [materials].[location_id] = [locations].[id]
	LEFT JOIN [APCSProDB].[trans].[materials] AS [m_parent] ON [m_parent].[id] = [materials].[parent_material_id]
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [il_qc] ON [il_qc].[val] = [materials].[qc_state]
		AND [il_qc].[name] = 'lots.quality_state' 
	LEFT JOIN [APCSProDB].[material].[material_codes] AS [m_state] ON [m_state].[code] = [materials].[material_state]
		AND [m_state].[group] = 'matl_state' 
	LEFT JOIN [APCSProDB].[material].[material_codes] AS [m_ps] ON [m_ps].[code] = [materials].[process_state]
		AND [m_ps].[group] = 'process_state' 
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [m_ls] ON [m_ls].[val] = [materials].[limit_state] 
		AND [m_ls].[name] = 'lots.quality_state'
	WHERE [materials].[location_id] IN (2,3) 
		AND [categories].[id] = 3 
		AND [materials].[quantity] > 0;
END