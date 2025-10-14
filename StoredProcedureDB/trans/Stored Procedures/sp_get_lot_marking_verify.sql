
CREATE PROCEDURE [trans].[sp_get_lot_marking_verify]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @lot_id INT = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no)
	DECLARE @value VARCHAR(255)

	SELECT TOP 1 @value = [value]
	FROM APCSProDB.trans.lot_marking_verify
	WHERE [lot_id] = @lot_id
		AND [is_pass] = 1
	ORDER BY [id] DESC

	IF (@value IS NOT NULL)
	BEGIN
		SELECT 'TRUE' AS [Status] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling]
			, @value AS [value];
		RETURN;
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS [Status] 
			, 'value not found ' AS [Error_Message_ENG]
			, N'ไม่พบ value' AS [Error_Message_THA] 
			, N' กรุณาติดต่อ System' AS [Handling]
			, @value AS [value];
		RETURN;
	END
	
END
