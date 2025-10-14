-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_interface_check_stock_text]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @text NVARCHAR(255) = '';
	------------------------------------------------------------------------------------
	---- # Check have data CPS
	------------------------------------------------------------------------------------
	IF NOT EXISTS (
		SELECT TOP 1 [lot_no]	
		FROM [APCSProDWH].[if].[stock_txt_data_monthly]	
		WHERE [remark] IN ('CPS', 'OGI')	
	)
	BEGIN
		SET @text += IIF(@text = '', 'Datail : ', ' and ');
		SET @text += '(CPS no data)';
	END

	------------------------------------------------------------------------------------
	---- # Check have data HASUU
	------------------------------------------------------------------------------------
	IF NOT EXISTS (
		SELECT TOP 1 [lot_no]	
		FROM [APCSProDWH].[if].[stock_txt_data_monthly]	
		WHERE [remark] IN ('HASUU')
	)
	BEGIN
		SET @text += IIF(@text = '', 'Datail : ', ' and ');
		SET @text += '(HASUU no data)';
	END

	------------------------------------------------------------------------------------
	---- # Check duplicate data
	------------------------------------------------------------------------------------
	IF EXISTS(
		SELECT [lot_no], [remark], COUNT([lot_no]) AS [Expr1]		
		FROM [APCSProDWH].[if].[stock_txt_data_monthly]		
		GROUP BY [lot_no], [remark]		
		HAVING (COUNT([lot_no]) <> 1)	
	)
	BEGIN
		SET @text += IIF(@text = '', 'Datail : ', ' and ');
		SET @text += '(duplicate data)';
	END

	------------------------------------------------------------------------------------
	---- # Check data device_name, assy_name, rohm_fukuoka_name
	------------------------------------------------------------------------------------
	IF EXISTS(
		SELECT [lot_no]	
		FROM [APCSProDWH].[if].[stock_txt_data_monthly]		
		WHERE ([device_name] IS NULL OR [device_name] = '')
			OR ([assy_name] IS NULL OR [assy_name] = '')
			OR ([rohm_fukuoka_name] IS NULL OR [rohm_fukuoka_name] = '')
	)
	BEGIN
		SET @text += IIF(@text = '', 'Datail : ', ' and ');
		SET @text += '(device_name or assy_name or rohm_fukuoka_name error)';
	END

	------------------------------------------------------------------------------------
	---- # Check hasuu_stock_qty, wip_qty, total_qty
	------------------------------------------------------------------------------------
	IF EXISTS(
		SELECT [lot_no]
		FROM [APCSProDWH].[if].[stock_txt_data_monthly]		
		WHERE ([hasuu_stock_qty] < 0)
			OR ([wip_qty] < 0)
			OR ([total_qty] < 0)
	)
	BEGIN
		SET @text += IIF(@text = '', 'Datail : ', ' and ');
		SET @text += '(hasuu_stock_qty less than 0 or wip_qty less than 0 or total_qty less than 0)';
	END

	------------------------------------------------------------------------------------
	---- # Check rohm_fukuoka_name
	------------------------------------------------------------------------------------
	IF EXISTS(
		SELECT [package_name]
			, [device_name]
			, [assy_name]
			, COUNT([rohm_fukuoka_name]) AS [Expr1]			
		FROM (
			SELECT [package_name]
				, [device_name]
				, [assy_name]
				, [rohm_fukuoka_name]			
			FROM [APCSProDWH].[if].[stock_txt_data_monthly]		
			GROUP BY [package_name]
				, [device_name]
				, [assy_name]
				, [rohm_fukuoka_name]
		) AS [derivedtbl_1]			
		GROUP BY [package_name]
			, [device_name]
			, [assy_name]			
		HAVING (COUNT([rohm_fukuoka_name]) > 1)	
	)
	BEGIN
		SET @text += IIF(@text = '', 'Datail : ', ' and ');
		SET @text += '(rohm_fukuoka_name more than 1)';
	END

	IF (@text = '')
	BEGIN
		SELECT 'TRUE' AS [Is_Pass] 
			, 'Datail : pass' AS [Error_Message_ENG]
			, N'Datail : pass' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS [Is_Pass] 
			, @text AS [Error_Message_ENG]
			, @text AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
END