-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[get_matching_lotoutsource_001]
( 
	 @lot_outsource AS VARCHAR(20),
	 @device_name AS VARCHAR(50) = NULL,
	 @is_pass AS VARCHAR(10) OUTPUT,
	 @assy_lot_no AS VARCHAR(10) OUTPUT

)

--============================= Begining Zone ===========================================================================

As
Begin

	SET NOCOUNT ON

		IF EXISTS (
			SELECT 1 FROM OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144; User ID=ship;Password=ship;' ).[Half_Product].[dbo].[Half_Product_Order_List] hp
			INNER JOIN APCSProDB.trans.lots ON lots.lot_no = TRIM(hp.LotNo)
			WHERE  OutSourceLotNo   = @lot_outsource  AND lots.e_slip_id IS NULL
			)
		BEGIN 
				SELECT TOP 1 @is_pass = 'TRUE', @assy_lot_no = LotNo  
					FROM OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144; User ID=ship;Password=ship;' ).[Half_Product].[dbo].[Half_Product_Order_List] hp
					INNER JOIN APCSProDB.trans.lots ON lots.lot_no = TRIM(hp.LotNo)
					WHERE  OutSourceLotNo   = @lot_outsource  AND lots.e_slip_id IS NULL
				ORDER BY lots.qty_in DESC, lots.lot_no ASC

				--SELECT  'TRUE' AS Is_Pass
				--, '' AS Error_Message_ENG
				--, '' AS Error_Message_THA 
				--, '' AS Handling  
		END
		ELSE BEGIN
				SET @is_pass = 'FALSE'
				SET @assy_lot_no = NULL

				--SELECT  'FALSE' AS Is_Pass
				--, '' AS Error_Message_ENG
				--, '' AS Error_Message_THA 
				--, '' AS Handling  
		END 

END
