
CREATE PROCEDURE [act].[sp_productionlothist_05_get_record_jig_mat] @id INT
AS
BEGIN
	--DECLARE @id BIGINT = 101014111
	--DECLARE @id BIGINT = 101097393
	SELECT lpr.id AS lot_process_record_id
		,lpr.recorded_at
		,jig.process_record_id AS jig_process_record_id
		,jig.jig_id AS jig_id
		,jr.barcode AS jig_barcode
		,jp.id AS jig_production_id
		,jp.name AS jig_production
		,jc.id AS jig_category_id
		,jc.name AS jig_category
		,mat.process_record_id AS material_record_id
		,mat.material_id AS material_id
		,mt.barcode AS material_barcode
		,mt.lot_no AS material_lot_no
		,mp.id AS material_production_id
		,mp.name AS material_production
		,mc.id AS material_category_id
		,mc.name AS material_category
	FROM APCSProDB.trans.lot_process_records AS lpr WITH (NOLOCK)
	LEFT JOIN APCSProDB.trans.lot_jigs AS jig WITH (NOLOCK) ON jig.process_record_id = lpr.id
	LEFT JOIN APCSProDB.trans.jig_records AS jr WITH (NOLOCK) ON jr.id = jig.jig_record_id
	LEFT JOIN APCSProDB.jig.productions AS jp WITH (NOLOCK) ON jp.id = jr.jig_production_id
	LEFT JOIN APCSProDB.jig.categories AS jc WITH (NOLOCK) ON jc.id = jp.category_id
	LEFT JOIN APCSProDB.trans.jigs AS jg WITH (NOLOCK) ON jg.id = jig.jig_id
	LEFT JOIN APCSProDB.trans.lot_materials AS mat WITH (NOLOCK) ON mat.process_record_id = lpr.id
	LEFT JOIN APCSProDB.trans.materials AS mt WITH (NOLOCK) ON mt.id = mat.material_id
	LEFT JOIN APCSProDB.material.productions AS mp WITH (NOLOCK) ON mp.id = mt.material_production_id
	LEFT JOIN APCSProDB.material.categories AS mc WITH (NOLOCK) ON mc.id = mp.category_id
	WHERE lpr.id = @id
	ORDER BY jig_barcode
		,material_barcode
END
