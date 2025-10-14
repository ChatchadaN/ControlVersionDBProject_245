-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[GET_PRODUCT_LAYOUT_BY_LOT_ID]
	-- Add the parameters for the stored procedure here
	@LOT_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select 
		LO.lot_no as [LOT_NO],
		DN.name as [PRD_NAME],
		DSD.chip_size_x as [DEVICE_SIZE_X],
		DSD.chip_size_y as [DEVICE_SIZE_Y],
		DN.strip_row_number as [ROWS],
		DN.strip_column_number as [COLUMNS],
		(DSD.chip_size_x + 10.00)*DN.strip_column_number + 10.00 as SIZE_X,
		(DSD.chip_size_y + 10.00)*DN.strip_row_number + 10.00 as SIZE_Y,
		'mm' as SIZE_UNITS,
		'' as TOP_IMAGE_PATH,
		'' as BOTTOM_IMAGE_PATH,
		5.00 as LOWERLEFT_X,
		5.00 as LOWERLEFT_Y,
		10.00*DN.strip_column_number / (DN.strip_column_number-1) as STEP_X,
		10.00*DN.strip_row_number / (DN.strip_row_number-1) + DSD.chip_size_y  as STEP_Y
	from APCSProDB.trans.lots as LO with(nolock)
	inner join APCSProDB.method.device_names as DN with(nolock) on DN.id = LO.act_device_name_id
	inner join APCSProDB.method.device_slip_details as DSD with(nolock) on DSD.device_slip_id = LO.device_slip_id
	where LO.id = @LOT_ID
	
	return @@ROWCOUNT
END
