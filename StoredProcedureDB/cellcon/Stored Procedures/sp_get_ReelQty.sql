-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_ReelQty] 
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
  SELECT TOP (1000) lot.lot_no,lot.qty_in,dev.pcs_per_pack,CEILING(CONVERT(float, lot.qty_out)/CONVERT(float,dev.pcs_per_pack)) as reel_qty
  FROM [APCSProDB].[trans].[lots] as lot with (NOLOCK) 
  inner join [APCSProDB].[method].[device_names] as dev with (NOLOCK)
  ON lot.act_device_name_id = dev.id
  WHERE lot_no = @lot_no

END
