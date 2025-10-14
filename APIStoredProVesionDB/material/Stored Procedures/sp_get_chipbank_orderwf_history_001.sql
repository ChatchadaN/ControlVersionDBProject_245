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

CREATE  PROCEDURE [material].[sp_get_chipbank_orderwf_history_001]
	@WFDATE DATE 
AS
BEGIN
	SET NOCOUNT ON;
	DECLARE @WFDATE_STR VARCHAR(6)
	SET @WFDATE_STR = FORMAT(@WFDATE, 'yyMMdd')

	----------------------------------------------------------------------------------------------
	--SELECT
	--	[CHIPORDER].CHIPMODELNAME
	--	, [CHIPORDER].WFLOTNO
	--	, [CHIPORDER].SEQNO
	--	, IIF(rack_addresses.address IS NULL,[CHIPZAIKO].[LOCATION],rack_addresses.address) AS [LOCATION]
	--	, TRIM([CHIPORDER].WFNOFROM) + ' - ' + TRIM([CHIPORDER].WFNOTO) AS WF_LIST
	--	, CAST([CHIPORDER].WFCOUNT AS INT) AS WFCOUNT
	--	, CAST([CHIPORDER].CHIPCOUNT AS INT) AS CHIPCOUNT
	--	, [CHIPORDER].ORDERNO
	--	, [CHIPORDER].ASSYNAME
	--	, [CHIPORDER].RCVDIV
	--	--, FORMAT(CONVERT(DATE,[CHIPORDER].TIDATE), 'yy/MM/dd') AS TIDATE
	--	, CONVERT(DATE,[CHIPORDER].TIDATE) AS TIDATE

	--	, CAST(materials.in_quantity - SUM(CAST([CHIPORDER].WFCOUNT AS INT)) OVER (
 --  			PARTITION BY [CHIPORDER].SEQNO
 --  			ORDER BY [CHIPORDER].WFNOTO
	--	) AS INT )AS WF_REMAIN

	--	, wf_details.chip_in - SUM(CAST([CHIPORDER].CHIPCOUNT AS INT)) OVER (
 --  			PARTITION BY [CHIPORDER].SEQNO
 --  			ORDER BY [CHIPORDER].WFNOTO
	--	) AS CHIP_REMAIN

	--	, [CHIPORDER].[TYPENAME]
	--	, [CHIPORDER].[BOXNO]

	--	FROM [APCSProDB].[dbo].[CHIPORDER]
	--	LEFT JOIN APCSProDB.trans.wf_details ON [CHIPORDER].SEQNO = wf_details.seq_no
	--	LEFT JOIN APCSProDB.trans.materials ON wf_details.material_id = materials.id
	--	LEFT JOIN APCSProDB.material.locations ON materials.location_id = locations.id
	--	LEFT JOIN APCSProDB.rcs.rack_addresses ON materials.barcode = rack_addresses.item
	--	LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
	--	LEFT JOIN [10.28.1.73].[DBRISTLSI].[dbo].[CHIPZAIKO] ON [CHIPZAIKO].SEQNO = [CHIPORDER].[SEQNO]
	--WHERE [CHIPORDER].TIDATE = @WFDATE_STR

	-----------------------------------------------------------------------------------------------------------------------
	;WITH ParentData AS (
		SELECT 
		    co.CHIPMODELNAME,
		    co.WFLOTNO,
		    co.SEQNO AS parent_seqno,
			mat.barcode AS BARCODE,
		   -- IIF(rack_addresses.address IS NULL, chipzaiko.LOCATION, rack_addresses.address) AS LOCATION,
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
		
	FROM ParentData pd
	LEFT JOIN APCSProDB.trans.materials child ON child.parent_material_id = pd.parent_id
	ORDER BY pd.parent_seqno;

END
