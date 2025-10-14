-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_outsource_lot_info_001] 
	-- Add the parameters for the stored procedure here
	@lot_outsource AS VARCHAR(50), 
	@mc_no AS VARCHAR(50), 
	@app_name AS VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


 

    -- Insert statements for procedure here	
		DECLARE @s_lot_outsource AS VARCHAR(50)

		SET @s_lot_outsource = SUBSTRING(TRIM(SUBSTRING(@lot_outsource,CHARINDEX(' ',@lot_outsource), LEN(@lot_outsource))),0,CHARINDEX(' ',TRIM(SUBSTRING(@lot_outsource,CHARINDEX(' ',@lot_outsource), LEN(@lot_outsource) ))))
 

		IF EXISTS (SELECT 1 FROM OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144; User ID=ship;Password=ship;' ).[Half_Product].[dbo].[Half_Product_Order_List] hp
			WHERE  OutSourceLotNo = @lot_outsource )
		BEGIN
		--///////////////////////////////////////////////
			SET @lot_outsource = @lot_outsource
		END

		ELSE IF EXISTS (SELECT 1 FROM OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144; User ID=ship;Password=ship;' ).[Half_Product].[dbo].[Half_Product_Order_List] hp
			WHERE  OutSourceLotNo = @s_lot_outsource)
		BEGIN 
		--///////////////////////////////////////////////
			SET @lot_outsource = @s_lot_outsource
		END

		ELSE BEGIN
			SELECT  'FALSE' AS Is_Pass
				, 'Can not found data lot outsource !!' AS Error_Message_ENG
				, N'ไม่พบข้อมูล lot outsource !!' AS Error_Message_THA 
				, N'กรุณาตรวจสอบข้อมูล lot outsource ที่เว็บ Half Product' AS Handling  
			RETURN
		END
 
		IF EXISTS (SELECT 1 FROM OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144; User ID=ship;Password=ship;' ).[Half_Product].[dbo].[Half_Product_Order_List] hp
					INNER JOIN APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT dp ON dp.LOT_NO_2 = TRIM(hp.LotNo)
					INNER JOIN APCSProDB.trans.lots ON lots.lot_no = TRIM(hp.LotNo)
					WHERE  OutSourceLotNo   = @lot_outsource  AND lots.e_slip_id IS NULL )
		BEGIN 


				SELECT  'TRUE' AS Is_Pass
				, '' AS Error_Message_ENG
				, '' AS Error_Message_THA 
				, '' AS Handling   
				, LotNo AS Lot_no
				, OutSourceLotNo AS Lot_OutSource
				, CAST(dp.QR_CODE_2 AS CHAR(252)) as QR_Code
					FROM OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144; User ID=ship;Password=ship;' ).[Half_Product].[dbo].[Half_Product_Order_List] hp
					INNER JOIN APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT dp ON dp.LOT_NO_2 = TRIM(hp.LotNo)
					INNER JOIN APCSProDB.trans.lots ON lots.lot_no = TRIM(hp.LotNo)
					WHERE  OutSourceLotNo   = @lot_outsource   AND lots.e_slip_id IS NULL
				ORDER BY lots.qty_in DESC, lots.lot_no ASC

 

		END
		ELSE BEGIN
 
 		IF EXISTS (SELECT 1 FROM OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144; User ID=ship;Password=ship;' ).[Half_Product].[dbo].[Half_Product_Order_List] hp
			INNER JOIN APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT dp ON dp.LOT_NO_2 = TRIM(hp.LotNo)
			WHERE  OutSourceLotNo  = @lot_outsource   )
			BEGIN 

				SELECT  'FALSE' AS Is_Pass
				, N'This Lot ('+ @lot_outsource +N') has been registered. !! ' AS Error_Message_ENG
				, N'Lot ('+ @lot_outsource +N') ถูกลงทะเบียบครบเเล้ว  !!' AS Error_Message_THA 
				, N'กรุณาตรวจสอบข้อมูล lot assy ที่เว็บ ATOM' AS Handling

			END 

			ELSE BEGIN

				SELECT  'FALSE' AS Is_Pass
				, 'Can not found data lot assy !!' AS Error_Message_ENG
				, N'ไม่พบข้อมูล lot assy !!' AS Error_Message_THA 
				, N'กรุณาตรวจสอบข้อมูล lot assy ที่เว็บ ATOM' AS Handling

			END 
		END 
END
