-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_surpluses_001] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	----------------------------------------------------
	---- surpluses
	----------------------------------------------------
	SELECT [surpluses].[serial_no] AS [lot_no]
		,ISNULL([surpluses].[pcs],0) AS [qty]
		,ISNULL(CAST([surpluses].[in_stock] AS VARCHAR) + ':' + CAST([item_labels].[label_eng] AS VARCHAR),'') AS [in_stock]
		,ISNULL([surpluses].[pdcd],'') AS [product_code]
		,ISNULL([surpluses].[qc_instruction],'') AS [qc_instruction]
		,ISNULL([surpluses].[mark_no],'') AS [mark_no]
		,ISNULL([surpluses].[transfer_flag],0) AS [transfer_flag]
		,ISNULL([surpluses].[transfer_pcs],0) AS [transfer_pcs]
		,ISNULL([surpluses].[is_ability],0) AS [is_ability]
		,ISNULL([surpluses].[created_at],'') AS [created_at]
		,ISNULL(CAST([surpluses].[created_by] AS VARCHAR),'') AS [created_by]
		,ISNULL([surpluses].[updated_at],'') AS [updated_at]
		,ISNULL(CAST([surpluses].[updated_by] AS VARCHAR),'') AS [updated_by]
	FROM [APCSProDB].[trans].[surpluses]
	LEFT JOIN [APCSProDB].[trans].[item_labels] ON [item_labels].[name] = 'surpluse_records.in_stock'
		AND [surpluses].[in_stock] = CAST([item_labels].[val] AS INT)
	WHERE [surpluses].[serial_no] = @lot_no
	----------------------------------------------------------------------------------------------
END 
