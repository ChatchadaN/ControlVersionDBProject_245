-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_product_layout_by_lot_id]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@LOT_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + 'LO.lot_no as [LOT_NO], ';
	SET @CMD_TEXT += N'	' + 'DN.name as [PRD_NAME], ';
	SET @CMD_TEXT += N'	' + 'DN.strip_row_number as [ROWS], ';
	SET @CMD_TEXT += N'	' + 'DN.strip_column_number as [COLUMNS], ';
	SET @CMD_TEXT += N'	' + '''mm'' as SIZE_UNITS, ';
	SET @CMD_TEXT += N'	' + ''''' as TOP_IMAGE_PATH, ';
	SET @CMD_TEXT += N'	' + ''''' as BOTTOM_IMAGE_PATH, ';
	SET @CMD_TEXT += N'	' + '5.00 as LOWERLEFT_X, ';
	SET @CMD_TEXT += N'	' + '5.00 as LOWERLEFT_Y ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.lots as LO with(nolock) ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.device_names as DN with(nolock) on DN.id = LO.act_device_name_id ';
	SET @CMD_TEXT += N'where LO.id = ' + CONVERT(varchar,@LOT_ID) + ' ';
	EXECUTE(@CMD_TEXT)
	
	return @@ROWCOUNT
END
