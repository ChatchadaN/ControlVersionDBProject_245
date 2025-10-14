-- =============================================
-- Author:		<Jakkapong Pureinsin>
-- Create date: <1/6/2022>
-- Description:	<Get_materialSetup_wire Check data from Cellcon>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_material_details] 
	-- Add the parameters for the stored procedure here
	@barcode as VARCHAR(30)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT  m.id
		, barcode
		, location_id
		, l.name as location_name
		, material_state 
		, mco.descriptions as state_name
		, material_production_id as material_type_id
		, p.name as material_type --type name
		, ISNULL(m.extended_limit_date,m.limit_date) as expire_date --expire
		, m.lot_no --lot_no
		, m.quantity --quan
	FROM APCSProDB.trans.materials m 
	INNER JOIN APCSProDB.material.productions p ON m.material_production_id = p.id
	LEFT JOIN APCSProDB.material.locations l on m.location_id = l.id
	LEFT JOIN APCSProDB.material.material_codes mco on m.material_state = mco.code
		and [mco].[group] = 'matl_state'
	WHERE barcode = @barcode

END
