
CREATE PROCEDURE [lsms].[sp_check_record]
	-- Add the parameters for the stored procedure here
	@master_lot VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		------------------------------------------------
	----- # Check data lot record in trans.lot_combine
	----------------------------------------------------
	IF EXISTS (SELECT *
	,[lot_mas].[lot_no] AS [lot_no]
	,[lot_mas].[id] AS [lot_id]
	FROM APCSProDB.trans.lot_informations AS [lot_mas]
	INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lot_combine].[lot_id] = [lot_mas].[id]
	WHERE [lot_mas].[lot_no] = @master_lot)
BEGIN
	SELECT 'FALSE' AS [Is_pass]
		, N'This information already exists.' AS [Error_Message_ENG]
		, N'มีประวัติการทำ TSUGITASHI ไปแล้ว' AS [Error_Message_THA]
		,  'Please check information lotno' AS [Handling]
	RETURN;
END
	ELSE
BEGIN
	SELECT 'TRUE' AS [Is_pass]
		, N'This information has not been recorded yet.' AS [Error_Message_ENG]
		, N'Lotno นี้ ยังไม่มีประวัติการทำ TSUGITASHI' AS [Error_Message_THA]
		,  'Please check information lotno' AS [Handling];
	RETURN;
END

END
