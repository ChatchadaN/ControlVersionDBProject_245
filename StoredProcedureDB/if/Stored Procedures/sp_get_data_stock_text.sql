-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_stock_text]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT [stock_class]
		, [lot_no]
		, [package_name]
		, [device_name]
		, [assy_name]
		, [rohm_fukuoka_name]
		, [rank]
		, [tp_rank]
		, [pdcd]
		, [hasuu_stock_qty]
		, [wip_qty]
		, [total_qty]
		, [derivery_date]		
	FROM [APCSProDWH].[if].[stock_txt_data_monthly]
	ORDER BY [stock_class], [lot_no];
END