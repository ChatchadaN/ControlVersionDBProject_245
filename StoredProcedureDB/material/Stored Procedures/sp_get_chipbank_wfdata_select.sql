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

CREATE PROCEDURE [material].[sp_get_chipbank_wfdata_select]
	-- Add the parameters for the stored procedure here
	@waferIds [dbo].[WaferIdList] READONLY,
	@mat_id int 
AS
BEGIN
	SET NOCOUNT ON;
	
	DECLARE @wf_issued int
	, @chip_issued int
	, @wf_new int
	, @chip_new int
	, @wf_old int
	, @chip_old int

	DECLARE @TABLE_WFID TABLE
	(wafer_id int)

	INSERT INTO @TABLE_WFID (wafer_id)
	SELECT WaferId FROM @waferIds

	SELECT @wf_issued = COUNT(idx)
	,@chip_issued = SUM(qty) 
	FROM APCSProDB.trans.wf_datas
	INNER JOIN @TABLE_WFID as wfid ON wf_datas.idx = wfid.wafer_id
	WHERE material_id = @mat_id
	GROUP BY material_id

	SELECT @wf_old = quantity
		,@chip_old = chip_remain
	FROM APCSProDB.trans.materials
	INNER JOIN APCSProDB.trans.wf_details ON materials.id = wf_details.material_id
	INNER JOIN APCSProDB.trans.wf_datas ON materials.id = wf_datas.material_id
	WHERE id = @mat_id 

	--SELECT @wf_issued, @chip_issued
	--SELECT @wf_old, @chip_old
	--SELECT @wf_new,@chip_new

	SET @wf_new = @wf_old - @wf_issued
	SET @chip_new = @chip_old - @chip_issued

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
		,@wf_issued AS wf_issued
		,@chip_issued AS chip_issued
		,@wf_new AS wf_new
		,@chip_new AS chip_new
	FROM APCSProDB.[trans].[materials]
	INNER JOIN APCSProDB.[trans].[material_arrival_records] [ar] ON [materials].[arrival_material_id] = [ar].[id]
	--LEFT JOIN APCSProDB.rcs.rack_addresses ON materials.location_id = rack_addresses.id
	--LEFT JOIN APCSProDB.rcs.rack_controls ON rack_addresses.rack_control_id = rack_controls.id
	LEFT JOIN APCSProDB.material.locations ON [materials].location_id = locations.id
	INNER JOIN APCSProDB.trans.wf_details ON wf_details.material_id = [materials].id
	WHERE [materials].[id] =  @mat_id
	AND [materials].[material_production_id] = 1085
	ORDER BY [materials].[id]

END
