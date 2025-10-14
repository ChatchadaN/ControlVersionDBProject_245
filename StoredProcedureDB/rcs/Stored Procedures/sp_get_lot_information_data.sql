-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_get_lot_information_data]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--check lot in lot_information
	IF EXISTS (SELECT 1 FROM APCSProDB.trans.lot_informations WHERE lot_no = @lot_no)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
		, 'This lot already exists in lot_informations' AS [Error_Message_ENG]
		, N'Lot นี้มีอยู่ใน lot_informations แล้ว' AS [Error_Message_THA] 
		, N'กรุณาติดต่อ ICT' AS [Handling];	
		RETURN;
	END
	ELSE
	BEGIN
		SELECT 'TRUE' AS [Is_Pass]
		, 'This lot not exists in lot_informations' AS [Error_Message_ENG]
		, N'ยังไม่มี Lot นี้ใน lot_informations' AS [Error_Message_THA] 
		, N'' AS [Handling];	
		RETURN;
	END
END
