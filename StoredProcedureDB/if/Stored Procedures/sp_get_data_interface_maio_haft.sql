-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_interface_maio_haft]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT '20' AS [class]
		, [switch_invoice_no]
		, [product_name]
		, [send_order_no]
		, [quantity]
		, 'QI352' AS [wh_from]
		, 'QI971' AS [wh_to]
		, CAST( FORMAT( [date_receive], 'yyMMdd' ) AS CHAR(6) ) AS [date_receive]
	FROM [APCSProDB].[dbo].[half_product_invoice_data]
	--WHERE [check_flag] = '2';
END
