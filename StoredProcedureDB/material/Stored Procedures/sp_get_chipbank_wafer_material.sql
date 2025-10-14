------------------------------ Creater Rule ------------------------------
-- Project Name				: material
-- Author Name              : Chatchadaporn N
-- Written Date             : 2024/08/22
-- Procedure Name 	 		: [material].[sp_get_wfdetails]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.material.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [material].[sp_get_chipbank_wafer_material]
	-- Add the parameters for the stored procedure here
	@mat_id int = 0	
AS
BEGIN
	SET NOCOUNT ON;
	SET @mat_id = CASE WHEN @mat_id = 0 THEN NULL ELSE @mat_id END

	SELECT [materials].[id] AS material_id
		,[barcode]
		,[material_production_id]
		,wf_details.chip_model_name
		,wf_details.seq_no
		,wf_details.rf_seq_no
		,wf_details.order_no
		,wf_details.case_no
		,[in_quantity]
		,[quantity]
		,[fail_quantity]
		,wf_details.chip_in
		,wf_details.chip_remain
		,[materials].[location_id]
		,locations.[name] AS rack_name
		,[lot_no]
		,[materials].[created_at]
		,[ar].[invoice_no]
	FROM APCSProDB.[trans].[materials]
	INNER JOIN APCSProDB.[trans].[material_arrival_records] [ar] ON [materials].[arrival_material_id] = [ar].[id]
	--LEFT JOIN APCSProDB.rcs.rack_addresses ON materials.location_id = rack_addresses.id
	--LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
	LEFT JOIN APCSProDB.material.locations ON materials.location_id = locations.id
	INNER JOIN APCSProDB.trans.wf_details ON wf_details.material_id = [materials].id
	WHERE ([materials].[id] =  @mat_id  OR  @mat_id  IS NULL)
	AND [materials].[material_production_id] = 1085 
	ORDER BY [materials].[id]

END
