-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_get_lot_fraction_data]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- Insert statements for procedure here
	--DECLARE @ProcessCode VARCHAR(50)
	----check in FractionStock
	--IF EXISTS(SELECT 1 FROM [10.29.1.229].[TRSURPLUS].[dbo].[FractionStock] WHERE [LotNo] = @lot_no)
	--BEGIN		
	--	SELECT @ProcessCode = [ProcessCode] 
	--	FROM [10.29.1.229].[TRSURPLUS].[dbo].[FractionStock]
	--	WHERE [LotNo] = @lot_no
	--END

	----check ว่าเป็น fraction หรือไม่
	--IF EXISTS(SELECT 1 FROM [10.29.1.229].[TRSURPLUS].[dbo].[WareHouse]
	--WHERE [WarehouseCode] = @ProcessCode AND [WarehouseCateg] = 10)
	--BEGIN
	--	SELECT 'FALSE' AS [Is_Pass]
	--	, 'This lot is Fraction' AS [Error_Message_ENG]
	--	, N'Lot นี้เป็น Fraction' AS [Error_Message_THA] 
	--	, N'กรุณาติดต่อ System' AS [Handling];	
	--	RETURN;
	--END

	--check lot is fraction
	IF EXISTS(SELECT 1 FROM [10.29.1.229].[TRSURPLUS].[dbo].[FractionStock]
	INNER JOIN [10.29.1.229].[TRSURPLUS].[dbo].[WareHouse] ON [FractionStock].[ProcessCode] = [WareHouse].[WarehouseCode]
	WHERE [FractionStock].[LotNo] = @lot_no AND [WareHouse].[WarehouseCateg] = 10)
	BEGIN
		SELECT 'TRUE' AS [Is_Pass]
		, 'This lot is Fraction' AS [Error_Message_ENG]
		, N'Lot นี้เป็น Fraction' AS [Error_Message_THA] 
		, N'กรุณาติดต่อ ICT' AS [Handling];	
		RETURN;
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
		, 'This lot is not Fraction' AS [Error_Message_ENG]
		, N'Lot นี้ไม่ใช่ Fraction' AS [Error_Message_THA] 
		, N'กรุณาติดต่อ ICT' AS [Handling];	
		RETURN;
	END

	--check lot in lot_information
	--IF EXISTS (SELECT 1 FROM APCSProDB.trans.lot_informations WHERE lot_no = @lot_no)
	--BEGIN
	--	SELECT 'FALSE' AS [Is_Pass]
	--	, 'This lot already exists in lot_informations' AS [Error_Message_ENG]
	--	, N'Lot นี้มีอยู่ใน lot_informations แล้ว' AS [Error_Message_THA] 
	--	, N'กรุณาติดต่อ ICT' AS [Handling];	
	--	RETURN;
	--END
	--ELSE
	--BEGIN
	--	SELECT 'TRUE' AS [Is_Pass]
	--	, 'This lot not exists in lot_informations' AS [Error_Message_ENG]
	--	, N'ยังไม่มี Lot นี้ใน lot_informations' AS [Error_Message_THA] 
	--	, N'' AS [Handling];	
	--	RETURN;
	--END
END
