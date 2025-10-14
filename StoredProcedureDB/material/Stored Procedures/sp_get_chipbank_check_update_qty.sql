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

CREATE  PROCEDURE [material].[sp_get_chipbank_check_update_qty]
	@mat_id INT 
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @barcode varchar(50)
	,@wflot_no varchar(50)
	,@wf_old int
	,@chip_old int
	,@wf_issued int
	,@chip_issued int
	,@wf_new int
	,@chip_new int
	,@row_num int

	SELECT @barcode = barcode
	,@wflot_no = lot_no
	,@wf_old = quantity
	,@chip_old = chip_remain
	,@wf_issued = count(idx) 
	,@chip_issued = sum(qty)
	,@row_num = (ROW_NUMBER() OVER (ORDER BY barcode, lot_no))
	FROM APCSProDB.trans.materials
	INNER JOIN APCSProDB.trans.wf_details ON materials.id = wf_details.material_id
	INNER JOIN APCSProDB.trans.wf_datas ON materials.id = wf_datas.material_id
	WHERE id = @mat_id and is_enable = 0
	GROUP BY barcode,lot_no,quantity,chip_remain

	IF(@row_num IS NULL)
	BEGIN
	
		PRINT 'NULL'

		SELECT @barcode = barcode
		,@wflot_no = lot_no
		,@wf_new = quantity
		,@chip_new = chip_remain
		,@wf_issued = 0 
		,@chip_issued = 0
		FROM APCSProDB.trans.materials
		INNER JOIN APCSProDB.trans.wf_details ON materials.id = wf_details.material_id
		INNER JOIN APCSProDB.trans.wf_datas ON materials.id = wf_datas.material_id
		WHERE id = @mat_id
		GROUP BY barcode,lot_no,quantity,chip_remain

		SELECT
		ISNULL(@wf_issued,0) as wf_issued
		,ISNULL(@chip_issued,0) as chip_issued
		,ISNULL(@wf_new,0) as wf_new
		,ISNULL(@chip_new,0) as chip_new

	END
	ELSE
	BEGIN

		PRINT 'NOT NULL'

		SET @wf_new = @wf_old - @wf_issued
		SET @chip_new = @chip_old - @chip_issued

		SELECT
		ISNULL(@wf_issued,0) as wf_issued
		,ISNULL(@chip_issued,0) as chip_issued
		,ISNULL(@wf_new,0) as wf_new
		,ISNULL(@chip_new,0) as chip_new

	END
END
