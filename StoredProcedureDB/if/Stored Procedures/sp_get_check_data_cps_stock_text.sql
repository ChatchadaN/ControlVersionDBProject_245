-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_check_data_cps_stock_text]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	------------------------------------------------------------------------------------
	---- # Check have data
	------------------------------------------------------------------------------------
	IF NOT EXISTS (
		SELECT TOP 1 [lot_no]	
		---- # Real
		--FROM [APCSProDWH].[if].[stock_txt_data_monthly]
		---- # Test
		FROM [APCSProDWH].[if].[test_stock_txt_data_monthly]
		WHERE [remark] IN ('CPS', 'OGI')
	)
	BEGIN
		SELECT 'TRUE' AS [Is_Pass];
		RETURN;
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS [Is_Pass];
		RETURN;
	END
END