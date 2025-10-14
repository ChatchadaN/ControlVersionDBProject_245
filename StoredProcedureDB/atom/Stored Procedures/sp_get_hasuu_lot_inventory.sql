-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_hasuu_lot_inventory]
	@lot_no VARCHAR(10) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT lot_inventory.lot_no AS [LotNo]
		, ISNULL(packages.name,'') AS [Package]
		, ISNULL(device_names.name,'') AS [Device]
		, ISNULL(jobs.name,'') AS [Operation]
		, ISNULL(lot_inventory.qty_hasuu,0) AS [QTY_INVENTORY]
		, ISNULL([surpluses].[pcs],0) AS [QTY_OLD]
		, IIF([surpluses].[pcs] >= lot_inventory.qty_hasuu,([surpluses].[pcs] - lot_inventory.qty_hasuu),(lot_inventory.qty_hasuu - [surpluses].[pcs])) AS [DIFF]
		, ISNULL(IIF(lot_inventory.location_id = '',[locations].[name],lot_inventory.location_id),[locations].[name]) AS [Location]
		, ISNULL(lot_inventory.fcoino,0) AS [FCOINO]
		, ISNULL(lot_inventory.sheet_no,0) AS [SheetNo]
		, ISNULL([item_labels].[label_eng],'') AS [StockClass]
		, ISNULL(lot_inventory.year_month,'') AS [YearMonth]
		, ISNULL(FORMAT(lot_inventory.created_at,'yyyy-MM-dd HH:mm:ss'),'') AS [CreatedAt]
		, ISNULL(user_created.emp_num,'') AS [CreatedBy]
		, ISNULL(FORMAT(lot_inventory.updated_at,'yyyy-MM-dd HH:mm:ss'),'') AS [UpdatedAt]
		, ISNULL(user_updated.emp_num,'') AS [UpdatedBy]
		, 'IN STOCK' AS [State]
	FROM [APCSProDB].[trans].[surpluses] WITH (NOLOCK)
	INNER JOIN [APCSProDB].[trans].[lot_inventory] WITH (NOLOCK) ON [surpluses].[serial_no] = UPPER([lot_inventory].[lot_no])
	LEFT JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [lot_inventory].[device_id] = [device_names].[id]
	LEFT JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [lot_inventory].[package_id] = [packages].[id]
	LEFT JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [lot_inventory].[job_id] = [jobs].[id]
	LEFT JOIN [APCSProDB].[man].[users] AS [user_created] WITH (NOLOCK) ON [lot_inventory].[created_by] = [user_created].[id]
	LEFT JOIN [APCSProDB].[man].[users] AS [user_updated] WITH (NOLOCK) ON [lot_inventory].[updated_by] = [user_updated].[id]
	LEFT JOIN [APCSProDB].[trans].[item_labels] WITH (NOLOCK) ON [lot_inventory].[stock_class] = [item_labels].[val]
		AND [item_labels].[name] = 'lot_inventory.stock_class'
	LEFT JOIN [APCSProDB].[trans].[locations] WITH (NOLOCK) ON [surpluses].[location_id] = [locations].[id]
	WHERE [lot_inventory].[stock_class] IN ('02','03')
		AND [lot_inventory].[lot_no] LIKE @lot_no
	UNION ALL
	SELECT lot_inventory.lot_no AS [LotNo]
		, ISNULL(packages.name,'') AS [Package]
		, ISNULL(device_names.name,'') AS [Device]
		, ISNULL(jobs.name,'') AS [Operation]
		, lot_inventory.qty_hasuu AS [QTY_INVENTORY]
		, 0 AS [QTY_OLD]
		, lot_inventory.qty_hasuu AS [DIFF]
		, ISNULL(lot_inventory.location_id,'') AS [Location]
		, ISNULL(lot_inventory.fcoino,0) AS [FCOINO]
		, ISNULL(lot_inventory.sheet_no,0) AS [SheetNo]
		, ISNULL([item_labels].[label_eng],'') AS [StockClass]
		, ISNULL(lot_inventory.year_month,'') AS [YearMonth]
		, ISNULL(FORMAT(lot_inventory.created_at,'yyyy-MM-dd HH:mm:ss'),'') AS [CreatedAt]
		, ISNULL(user_created.emp_num,'') AS [CreatedBy]
		, ISNULL(FORMAT(lot_inventory.updated_at,'yyyy-MM-dd HH:mm:ss'),'') AS [UpdatedAt]
		, ISNULL(user_updated.emp_num,'') AS [UpdatedBy]
		, 'OUT STOCK' AS [State]
	FROM [APCSProDB].[trans].[lot_inventory] WITH (NOLOCK) 
	LEFT JOIN [APCSProDB].[trans].[surpluses] WITH (NOLOCK) ON [surpluses].[serial_no] = UPPER([lot_inventory].[lot_no])
	LEFT JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [lot_inventory].[device_id] = [device_names].[id]
	LEFT JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) ON [lot_inventory].[package_id] = [packages].[id]
	LEFT JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [lot_inventory].[job_id] = [jobs].[id]
	LEFT JOIN [APCSProDB].[man].[users] AS [user_created] WITH (NOLOCK) ON [lot_inventory].[created_by] = [user_created].[id]
	LEFT JOIN [APCSProDB].[man].[users] AS [user_updated] WITH (NOLOCK) ON [lot_inventory].[updated_by] = [user_updated].[id]
	LEFT JOIN [APCSProDB].[trans].[item_labels] WITH (NOLOCK) ON [lot_inventory].[stock_class] = [item_labels].[val]
		AND [item_labels].[name] = 'lot_inventory.stock_class'
	WHERE [surpluses].[serial_no] IS NULL
		AND [lot_inventory].[stock_class] IN ('02','03')
		AND [lot_inventory].[lot_no] LIKE @lot_no
	ORDER BY [CreatedAt]
	
END
