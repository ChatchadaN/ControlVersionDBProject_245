
CREATE PROCEDURE [trans].[get_matching_lotoutsource]
( 
	 @LotNo				NVARCHAR(MAX) =  null,
	 @OutSourceLotNo	NVARCHAR(MAX) =  null
)

--============================= Begining Zone ===========================================================================

As
Begin

	SET NOCOUNT ON

	IF EXISTS (
			SELECT  'xxx' FROM OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144; User ID=ship;Password=ship;' ).[Half_Product].[dbo].[Half_Product_Order_List]
			WHERE LotNo = @LotNo AND   OutSourceLotNo   = @OutSourceLotNo  
			)
		BEGIN 
				SELECT  'TRUE' AS Is_Pass
				, '' AS Error_Message_ENG
				, '' AS Error_Message_THA 
				, '' AS Handling  
		END
		ELSE BEGIN
		
			SELECT  'FALSE' AS Is_Pass
				, '' AS Error_Message_ENG
				, '' AS Error_Message_THA 
				, '' AS Handling  
		END 



SET NOCOUNT OFF 

END

 
 
