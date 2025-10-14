-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create Date,,>
-- Description:	<Description,, for calculate adjust by qty_pass>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_calculate_adjust]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10),
	@qty_adjust int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	select lots.id,lot_no
	, @qty_adjust  AS qty_pass
	,qty_combined 

	,CASE WHEN( @qty_adjust  / dn.pcs_per_pack) <= 0 
	 THEN  @qty_adjust  
	 ELSE ( @qty_adjust  / dn.pcs_per_pack) * dn.pcs_per_pack 
	END qty_out 

	,CASE WHEN( @qty_adjust / dn.pcs_per_pack) <= 0 
	 THEN   @qty_adjust 
	 ELSE  @qty_adjust -(( @qty_adjust  / dn.pcs_per_pack) * dn.pcs_per_pack) 
	END qty_hasuu 
                                  
	from APCSProDB.trans.lots
	INNER JOIN APCSProDB.method.device_names dn ON dn.id = lots.act_device_name_id 
	where lots.lot_no = @lot_no
END
