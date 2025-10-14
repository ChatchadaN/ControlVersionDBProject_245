
CREATE PROCEDURE [trans].[sp_check_pickup_fifo] @barcode VARCHAR(50), @minrecdate date OUTPUT
AS
BEGIN

	SET NOCOUNT ON;

SET @minrecdate = (SELECT min(materials.created_at )
FROM apcsprodb.trans.materials INNER JOIN
apcsprodb.trans.material_records on materials.id = material_records.material_id
WHERE material_records.id in (SELECT MAX(apcsprodb.trans.material_records.id) as M_ID 
								FROM apcsprodb.trans.materials
								INNER JOIN apcsprodb.trans.material_records ON apcsprodb.trans.materials.id = apcsprodb.trans.material_records.material_id
								WHERE materials.material_production_id = (SELECT productions.id FROM apcsprodb.trans.materials  INNER JOIN
													apcsprodb.material.productions ON productions.id = apcsprodb.trans.materials.material_production_id 
													WHERE barcode = @barcode) 
													and material_records.record_class in (1,2) group by materials.barcode) 
AND apcsprodb.trans.materials.location_id in (1,2)
AND APCSProDB.trans.materials.barcode not in (select barcode from APCSProDB.trans.material_pickup_file)
AND CAST(materials.created_at AS date) < (SELECT CAST(created_at as date) FROM apcsprodb.trans.materials WHERE barcode = @barcode));
END
