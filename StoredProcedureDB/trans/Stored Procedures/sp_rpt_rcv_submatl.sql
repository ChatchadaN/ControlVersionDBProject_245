
CREATE PROCEDURE [trans].[sp_rpt_rcv_submatl]
@YEAR_MONTH VARCHAR(8),
@LOCATION_ID INT,
@USER_ID INT
AS
BEGIN
	SELECT	[YEAR_MONTH]
           ,[PRODUCT_NAME]
           ,[ITEM]
           ,[PROCESS]
           ,[QUANTITY]
           ,[UNIT]
           ,[AMOUNT]
		   FROM [TRANS].[RPT_SUB_MATERIAL_RECEIVING] WHERE [YEAR_MONTH] = @YEAR_MONTH;
END


