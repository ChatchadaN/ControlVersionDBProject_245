
CREATE PROCEDURE [trans].[sp_get_outsource_lot_info_003] 
	-- Add the parameters for the stored procedure here
	@lot_outsource AS VARCHAR(70), 
	@mc_no AS VARCHAR(50), 
	@app_name AS VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here	
	DECLARE @s_lot_outsource AS VARCHAR(70);
	---- # ex. 'BD4275FP2-CFX 2CH02441115 1250' ---> '2CH02441115'
	SET @s_lot_outsource = SUBSTRING(TRIM(SUBSTRING(@lot_outsource, CHARINDEX(' ', @lot_outsource), LEN(@lot_outsource))), 0, CHARINDEX(' ', TRIM(SUBSTRING(@lot_outsource, CHARINDEX(' ', @lot_outsource), LEN(@lot_outsource)))));
	SET @s_lot_outsource = IIF(@s_lot_outsource = '', @lot_outsource, @s_lot_outsource);

	------------------------------------------------------------------------------------------------------------------------------
	-- # check is outsuurce from database is
	------------------------------------------------------------------------------------------------------------------------------
	IF NOT EXISTS ( 
		SELECT 1 FROM [ISDB].[Half_Product].[dbo].[Half_Product_Order_List] 
		WHERE [OutSourceLotNo] = @s_lot_outsource 
	)
	BEGIN
		------------------------------------------------------------------------------------------------------------------------------
		SELECT  'FALSE' AS [Is_Pass]
			, 'Can not found data lot outsource !!' AS [Error_Message_ENG]
			, N'ไม่พบข้อมูล lot outsource !!' AS [Error_Message_THA] 
			, N'กรุณาตรวจสอบข้อมูล lot outsource ที่เว็บ Half Product' AS [Handling]; 
		RETURN;
		------------------------------------------------------------------------------------------------------------------------------
	END

	------------------------------------------------------------------------------------------------------------------------------
	-- # check in [Denpyo] and [lots] not register esl card
	------------------------------------------------------------------------------------------------------------------------------
	IF EXISTS ( 
		SELECT 1 FROM [ISDB].[Half_Product].[dbo].[Half_Product_Order_List] AS [hp]
		INNER JOIN [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] AS [Denpyo] ON TRIM([hp].[LotNo]) = [Denpyo].[LOT_NO_2] 
		INNER JOIN [APCSProDB].[trans].[lots] ON [Denpyo].[LOT_NO_2] = [lots].[lot_no]
		WHERE [hp].[OutSourceLotNo] = @s_lot_outsource
			AND [lots].[e_slip_id] IS NULL
	)
	BEGIN 
		------------------------------------------------------------------------------------------------------------------------------
		SELECT 'TRUE' AS [Is_Pass]
			, '' AS [Error_Message_ENG]
			, '' AS [Error_Message_THA] 
			, '' AS [Handling]  
			, CAST([lots].[lot_no] AS VARCHAR(10)) AS [Lot_no]
			, [hp].[OutSourceLotNo] AS [Lot_OutSource]
			, CAST([Denpyo].[QR_CODE_2] AS CHAR(252)) AS [QR_Code]
		FROM [ISDB].[Half_Product].[dbo].[Half_Product_Order_List] AS [hp]
		INNER JOIN [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] AS [Denpyo] ON TRIM([hp].[LotNo]) = [Denpyo].[LOT_NO_2] 
		INNER JOIN [APCSProDB].[trans].[lots] ON [Denpyo].[LOT_NO_2] = [lots].[lot_no]
		WHERE [hp].[OutSourceLotNo] = @s_lot_outsource
			AND [lots].[e_slip_id] IS NULL
		ORDER BY [lots].[qty_in] DESC, [lots].[lot_no] ASC;
		RETURN;
		------------------------------------------------------------------------------------------------------------------------------
	END
	ELSE 
	BEGIN
		------------------------------------------------------------------------------------------------------------------------------
 		IF EXISTS (
			SELECT 1 FROM [ISDB].[Half_Product].[dbo].[Half_Product_Order_List] AS [hp]
			INNER JOIN [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] AS [Denpyo] ON TRIM([hp].[LotNo]) = [Denpyo].[LOT_NO_2] 
			WHERE [hp].[OutSourceLotNo] = @s_lot_outsource
		)
		BEGIN 
			------------------------------------------------------------------------------------------------------------------------------
			SELECT 'FALSE' AS [Is_Pass]
				, N'This Lot (' + @s_lot_outsource + N') has been registered. !! ' AS [Error_Message_ENG]
				, N'Lot (' + @s_lot_outsource + N') ถูกลงทะเบียบครบเเล้ว  !!' AS [Error_Message_THA] 
				, N'กรุณาตรวจสอบข้อมูล lot assy ที่เว็บ ATOM' AS [Handling];
			RETURN;
			------------------------------------------------------------------------------------------------------------------------------
		END 
		ELSE 
		BEGIN
			------------------------------------------------------------------------------------------------------------------------------
			SELECT 'FALSE' AS [Is_Pass]
				, 'Can not found data lot assy !!' AS [Error_Message_ENG]
				, N'ไม่พบข้อมูล lot assy !!' AS [Error_Message_THA] 
				, N'กรุณาตรวจสอบข้อมูล lot assy ที่เว็บ ATOM' AS [Handling];
			RETURN;
			------------------------------------------------------------------------------------------------------------------------------
		END 
		------------------------------------------------------------------------------------------------------------------------------
	END 
END
