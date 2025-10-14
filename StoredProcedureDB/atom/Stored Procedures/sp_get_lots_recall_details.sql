-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_lots_recall_details]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @trans_lots_id INT
		, @wip_state INT

	SELECT @trans_lots_id = [id]
		, @wip_state = [wip_state]
	FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) WHERE [lot_no] = @lot_no;

	------- check lots --------
	IF (@trans_lots_id IS NULL)
	BEGIN
		-------- not exists device slip --------
		SELECT 'FALSE' AS [Is_Pass] 
			, 'lot_no not found !!' AS [Error_Message_ENG]
			, N'ไม่พบ lot_no' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END

	------- check surpluses --------
	IF NOT EXISTS (SELECT [serial_no] FROM [APCSProDB].[trans].[surpluses] WITH (NOLOCK) WHERE [serial_no] = @lot_no)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, 'lot_no hot found in surpluses !!' AS [Error_Message_ENG]
			, N'ไม่พบ lot_no ใน surpluses !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END

	------- check recall --------
	IF EXISTS (
		SELECT [lot_master].[lot_no] FROM [APCSProDB].[trans].[lot_combine]
		INNER JOIN [APCSProDB].[trans].[lots] AS [lot_master] ON [lot_combine].[lot_id] = [lot_master].[id]
		INNER JOIN [APCSProDB].[trans].[lots] AS [lot_member] ON [lot_combine].[member_lot_id] = [lot_member].[id]
		WHERE [lot_member].[lot_no] = '2036A2421V'
			AND [lot_master].[production_category] = 70)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, 'This lot_no has been recalled. !!' AS [Error_Message_ENG]
			, N'lot_no นี้ทำการ Recall แล้ว. !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END

	-------- check device slip --------
	IF EXISTS (
		SELECT TOP 1 [lot_no]
		FROM (
			SELECT [lots].[lot_no]
				, [device_slips].[version_num]
				, ROW_NUMBER() OVER (ORDER BY [device_slips].[version_num] DESC) AS [row]
			FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) 
			INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [lots].[act_device_name_id] = [device_names].[id]
			INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_name_id] = [device_names].[id] 
				AND [device_versions].[device_type] = 6 
			INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_id] = [device_versions].[device_id] 
				AND [device_slips].[is_released] = 1
			WHERE [lots].[id] = '374027'
		) AS [devices]
		WHERE [row] = 1
	)

	BEGIN
		-------- exists device slip --------
		-------- check shipment --------
		IF (@wip_state IN (70,100))
		BEGIN
			-------- shipment --------
			SELECT 'TRUE' AS [Is_Pass] 
				, '' AS [Error_Message_ENG]
				, N'' AS [Error_Message_THA] 
				, N'' AS [Handling];
			RETURN;
		END
		ELSE
		BEGIN
			-------- not shipment --------
			SELECT 'FALSE' AS [Is_Pass] 
				, 'LotNo is shipped only !!' AS [Error_Message_ENG]
				, N'LotNo shipment แล้วเท่านั้น' AS [Error_Message_THA] 
				, N'กรุณาติดต่อ system' AS [Handling];
			RETURN;
		END
	END
    ELSE
	BEGIN
		-------- not exists device slip --------
		SELECT 'FALSE' AS [Is_Pass] 
			, 'Slip not register !!' AS [Error_Message_ENG]
			, N'Slip ยังไม่ได้ถูกลงทะเบียน' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
	END
END
