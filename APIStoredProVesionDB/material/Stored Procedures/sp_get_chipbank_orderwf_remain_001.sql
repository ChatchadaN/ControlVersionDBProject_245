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

CREATE  PROCEDURE [material].[sp_get_chipbank_orderwf_remain_001]
	@WFDATE DATE 
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @WFDATE_STR VARCHAR(6)
	SET @WFDATE_STR = FORMAT(@WFDATE, 'yyMMdd')

	----------------------------------------------------------------------------------------------
	-- Subquery: ดึง wafer ที่เบิกออกไป
	;WITH PickedMaterials AS (
		SELECT
       		pickup.material_id AS child_mat_id
       		, pickup.barcode AS child_barcode
			, child_wf.seq_no AS child_seqno
			, child_mat.location_id AS child_location_id
			, pickup.quantity AS pickup_wf

			, child_mat.parent_material_id
			, parent_mat.barcode AS parent_barcode
			, parent_wf.seq_no AS parent_seq_no
			, parent_mat.location_id AS parent_location_id

			----กรณีเบิกทั้งกล่อง barcode นั้น ไม่มี parent_mat_id ใช้ seqno ตัวเอง
			, IIF(child_mat.parent_material_id IS NULL,child_wf.seq_no ,parent_wf.seq_no) AS seqno

   		FROM APCSProDB.trans.material_pickup_file pickup
		LEFT JOIN APCSProDB.trans.wf_details child_wf ON pickup.material_id = child_wf.material_id
		LEFT JOIN APCSProDB.trans.materials child_mat ON pickup.material_id = child_mat.id
		LEFT JOIN APCSProDB.material.productions child_prod ON child_mat.material_production_id = child_prod.id
		LEFT JOIN APCSProDB.material.categories child_categories ON child_prod.category_id = child_categories.id

		LEFT JOIN APCSProDB.trans.wf_details parent_wf ON child_mat.parent_material_id = parent_wf.material_id
		LEFT JOIN APCSProDB.trans.materials parent_mat ON child_mat.parent_material_id = parent_mat.id
		LEFT JOIN APCSProDB.material.productions parent_prod ON parent_mat.material_production_id = parent_prod.id
		LEFT JOIN APCSProDB.material.categories parent_categories ON parent_prod.category_id = parent_categories.id

		WHERE child_categories.id = 11 OR parent_categories.id = 11
	),

	OrderListData AS (
		SELECT 
		    co.CHIPMODELNAME,
		    co.WFLOTNO,
		    co.SEQNO AS parent_seqno,
			mat.barcode AS BARCODE,
		  --  IIF(rack_addresses.address IS NULL, chipzaiko.LOCATION, rack_addresses.address) AS LOCATION,
		    rack_controls.name + ' [' + rack_addresses.address  +']' AS [LOCATION],
		    mat.quantity AS CURRENT_WF,
		    wf_details.chip_remain AS CURRENT_CHIP,
		    TRIM(co.WFNOFROM) + ' - ' + TRIM(co.WFNOTO) AS ORDER_WFLIST,
		    CAST(co.WFCOUNT AS INT) AS ORDER_WF,
		    CAST(co.CHIPCOUNT AS INT) AS ORDER_CHIP,
		    co.ORDERNO,
		    co.ASSYNAME,
		    co.RCVDIV,
		    CONVERT(DATE, co.TIDATE) AS TIDATE,
		    CAST(mat.in_quantity - SUM(CAST(co.WFCOUNT AS INT)) OVER (
		        PARTITION BY co.SEQNO ORDER BY co.WFNOTO
		    ) AS INT) AS REMAIN_WF,
		    wf_details.chip_in - SUM(CAST(co.CHIPCOUNT AS INT)) OVER (
		        PARTITION BY co.SEQNO ORDER BY co.WFNOTO
		    ) AS REMAIN_CHIP,
		    co.TYPENAME,
		    co.BOXNO,
		    mat.id AS parent_id,
		    mat.location_id,
		    mat.parent_material_id
		FROM [APCSProDB].[dbo].[CHIPORDER] co
		LEFT JOIN APCSProDB.trans.wf_details ON co.SEQNO = wf_details.seq_no
		LEFT JOIN APCSProDB.trans.materials mat ON wf_details.material_id = mat.id
		LEFT JOIN APCSProDB.rcs.rack_addresses ON mat.barcode = rack_addresses.item
		LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
		--LEFT JOIN [10.28.1.73].[DBRISTLSI].[dbo].[CHIPZAIKO] chipzaiko ON chipzaiko.SEQNO = co.SEQNO
		WHERE co.TIDATE = @WFDATE_STR
	)


	-- Final Query: รวมข้อมูล
	SELECT 
   		pd.CHIPMODELNAME
		, pd.WFLOTNO
		, pd.parent_seqno AS SEQNO
		, pd.parent_id
		, pd.BARCODE
		, pd.[LOCATION]
		, pd.CURRENT_WF
		, pd.CURRENT_CHIP
		, pd.ORDER_WFLIST
		, pd.ORDER_WF
		, pd.ORDER_CHIP
		, pd.ORDERNO
		, pd.ASSYNAME
		, pd.RCVDIV
		, CONVERT(VARCHAR(100), pd.TIDATE)		AS TIDATE
		, pd.REMAIN_WF
		, pd.REMAIN_CHIP
		, pd.TYPENAME
		, pd.BOXNO

   		, child.id AS child_id
   		, child.barcode AS NEW_BARCODE
   		, child.quantity AS PICKED_WF
		
		, CASE 
       		WHEN picked_mat.child_barcode IS NOT NULL THEN 1  --ถ้ามีใน pickup
       		WHEN child.barcode IS NOT NULL THEN  --ถ้ามี barcode ลูกใช้ location ตัวลูกบอก status
        		CASE 
        			WHEN child.location_id != 16 THEN 0
        			WHEN child.location_id = 16 THEN 2
        		END
       		ELSE --ถ้าไม่มี barcode ลูกใช้ location ตัวแม่บอก status
        		CASE 
        			WHEN pd.location_id != 16 THEN 0
        			WHEN pd.location_id = 16 THEN 2
        		END
   		END AS [wf_state]

		, CASE 
       		WHEN picked_mat.child_barcode IS NOT NULL THEN 'Picked Up'  --ถ้ามีใน pickup
       		WHEN child.barcode IS NOT NULL THEN  --ถ้ามี barcode ลูกใช้ location ตัวลูกบอก status
        		CASE 
        			WHEN child.location_id != 16 THEN 'Stock Out'
        			WHEN child.location_id = 16 THEN 'In Stock'
        		END
       		ELSE --ถ้าไม่มี barcode ลูกใช้ location ตัวแม่บอก status
        		CASE 
        			WHEN pd.location_id != 16 THEN 'Stock Out'
        			WHEN pd.location_id = 16 THEN 'In Stock'
        		END
   		END AS [wf_status]

		,child.id
		,pd.parent_id

	FROM OrderListData pd
	LEFT JOIN APCSProDB.trans.materials child ON child.parent_material_id = pd.parent_id
	-- COALESCE(child.id, pd.parent_id) จะเลือก child.id ถ้ามีค่า (ไม่เป็น NULL) มีการ Repack
	LEFT JOIN PickedMaterials picked_mat ON picked_mat.child_mat_id = COALESCE(child.id, pd.parent_id)

	ORDER BY pd.parent_seqno, pd.TIDATE;

END
