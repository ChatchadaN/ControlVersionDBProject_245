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

CREATE  PROCEDURE [material].[sp_get_chipbank_wfdetails]
AS
BEGIN
	SET NOCOUNT ON;

	SELECT
		[material_id]
		, materials.barcode
		, materials.lot_no
		, [chip_model_name]
		, [seq_no]
		, [rf_seq_no]
		, [out_div]
		, [rec_div]
		, [chip_in]
		, [chip_remain]
		, [order_no]
		, [slip_no]
		, [slip_no_eda]
		, [case_no]
		, [fuk1_flag]
		, [fuk2_flag]
		, [plasma]
		, wf_details.[created_at]
		, wf_details.[created_by]
		, wf_details.[updated_at]
		, wf_details.[updated_by]
	FROM APCSProDB.trans.wf_details
	INNER JOIN APCSProDB.trans.materials ON wf_details.material_id = materials.id

END
