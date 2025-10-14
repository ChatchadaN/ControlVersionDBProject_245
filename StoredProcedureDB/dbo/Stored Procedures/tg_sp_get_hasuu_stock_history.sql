-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_hasuu_stock_history] 
	-- Add the parameters for the stored procedure here
	 @lot_type VARCHAR(50) = NULL, 
	 @start_date DATE = NULL, 
	 @end_date DATE = NULL, 
	 @package NVARCHAR(50) = NULL, 
	 @device NVARCHAR(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [surpluse_records].[serial_no] AS [LotNo]
		, [packages].[name] AS [Type_Name]
		, [device_names].[name] AS [ASSY_Model_Name]
		, [surpluse_records].[pcs] AS [HASU_Stock_QTY]
		, [device_names].[pcs_per_pack] AS [Packing_Standerd_QTY]
		, [device_names].[tp_rank] AS [Rank]
		, IIF(DATEDIFF(YEAR,CONVERT(DATE, [surpluse_records].[created_at]), CONVERT(DATE, GETDATE())) > 3, '#ff6666', '') AS [color]  --edit condition : 2023/09/08 time : 15.05
		, [surpluse_records].[created_at] AS [Derivery_Date]
		, YEAR([surpluse_records].[created_at]) AS [oldyear]
		, YEAR(GETDATE()) AS [Currentyear]
		, CAST(YEAR(GETDATE()) AS INT) - CAST(YEAR([surpluse_records].[created_at]) AS INT) AS [Overdueyear]
		, CASE WHEN [locations].[name] IS NULL THEN 'NoLocation' ELSE [locations].[name] END AS [Rack_Location_name]
		, CASE WHEN [locations].[address] IS NULL THEN 'NoLocation' ELSE [locations].[address] END AS [Rack_Location_address]
		, [item_labels].[label_eng] AS [status]
		, ISNULL([item_comment].[label_eng],'') AS [CommentValue]
	FROM [APCSProDB].[trans].[surpluse_records]
	INNER JOIN [APCSProDB].[trans].[lots] ON [surpluse_records].[serial_no]  = [lots].[lot_no]
	INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id] 
	LEFT JOIN [APCSProDB].[trans].[locations] ON [surpluse_records].[location_id] = [locations].[id]
	LEFT JOIN [APCSProDB].[trans].[item_labels] on [surpluse_records].[in_stock] = CAST([item_labels].[val] AS INT)
		AND [item_labels].[name] = 'surpluse_records.in_stock'
	LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item_comment] ON [surpluse_records].[comment] = CAST([item_comment].[val] AS INT)
		AND [item_comment].[name] = 'surpluses.comment'
	WHERE [surpluse_records].[recorded_at] BETWEEN @start_date AND DATEADD(DAY, 1, @end_date)
		AND (SUBSTRING([surpluse_records].[serial_no], 5, 1) = @lot_type OR ISNULL(@lot_type,'') = '')
		AND ([packages].[name] = @package OR ISNULL(@package,'') = ''  )
		AND ([device_names].[name]  = @device OR ISNULL(@device,'') = '' )
		--AND surpluse_records.comment IS NOT NULL
END
