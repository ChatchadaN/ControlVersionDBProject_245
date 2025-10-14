-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_lots_recall_qty]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT --IIF([lots].[pc_instruction_code] = 13 AND SUBSTRING([lots].[lot_no], 5, 1) = 'D', ISNULL([lots].[qty_pass], 0), ISNULL([qty_out], 0)) AS [qty_pass]
		CASE WHEN ([lots].[pc_instruction_code] = 13 AND SUBSTRING([lots].[lot_no], 5, 1) = 'D') 
				THEN ISNULL([lots].[qty_pass], 0)
			WHEN [lots].[pc_instruction_code] = 11 
				THEN ([lots].[qty_out] + [lots].[qty_hasuu])
			ELSE ISNULL([qty_out], 0) 
		END AS [qty_pass]  --edit 2025/04/17 time: 11.54 by Aomsin
		, ISNULL(IIF([surpluses].[in_stock] = 2,[surpluses].[pcs],0),0) AS [qty_hasuu]
		, ISNULL([device_names].[pcs_per_pack], 0) AS [pcs_per_pack]
		,[pc_instruction_code] AS [pc_instruction_code]
	FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
	LEFT JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) 
		ON [lots].[act_device_name_id] = [device_names].[id]
	LEFT JOIN [APCSProDB].[trans].[surpluses] WITH (NOLOCK) 
		ON [lots].[id] = [surpluses].[lot_id]
	WHERE [lot_no] = @lot_no;
END