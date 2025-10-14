-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_material_stock_data]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT             ROW_NUMBER() OVER(ORDER BY materials.barcode ASC) AS [No],SUBSTRING(APCSProDB.trans.materials.barcode,2,LEN(APCSProDB.trans.materials.barcode)) AS Barcode, APCSProDB.material.categories.name AS Category
					   ,APCSProDB.material.productions.name AS Product, APCSProDB.trans.materials.lot_no AS Lot, APCSProDB.trans.material_arrival_records.invoice_no AS Invoice
					   ,APCSProDB.trans.materials.quantity AS Quantity 
                       ,APCSProDB.material.locations.name AS Location,locations.wh_code, APCSProDB.trans.materials.created_at AS [Receive Date]
					   ,il_qc.label_eng AS [QC state],m_state.descriptions AS [Material State], m_ps.descriptions AS [Process State]
					   ,'' AS [Hold Type] ,m_ls.label_eng AS [Limit State]
					   ,APCSProDB.trans.materials.limit_date AS [Limit Date], APCSProDB.trans.materials.extended_limit_date AS [Extend Date]
					   ,m_parent.barcode AS Repack
	FROM               APCSProDB.trans.material_arrival_records INNER JOIN
                       APCSProDB.trans.materials ON APCSProDB.trans.material_arrival_records.material_id = APCSProDB.trans.materials.id INNER JOIN
                       APCSProDB.material.productions ON APCSProDB.trans.materials.material_production_id = APCSProDB.material.productions.id INNER JOIN
                       APCSProDB.material.categories ON APCSProDB.material.productions.category_id = APCSProDB.material.categories.id  INNER JOIN
                       APCSProDB.material.locations ON APCSProDB.trans.materials.location_id = APCSProDB.material.locations.id LEFT JOIN
					   APCSProDB.trans.materials m_parent ON m_parent.id = materials.parent_material_id LEFT JOIN
					   APCSProDB.trans.item_labels il_qc ON il_qc.val = materials.qc_state AND il_qc.name = 'lots.quality_state' LEFT JOIN
					   APCSProDB.material.material_codes m_state ON m_state.code = materials.material_state AND m_state.[group] = 'matl_state' LEFT JOIN
					   APCSProDB.material.material_codes m_ps ON m_ps.code = materials.process_state AND m_ps.[group] = 'process_state' LEFT JOIN
					   APCSProDB.trans.item_labels m_ls ON m_ls.val = materials.limit_state AND m_ls.name = 'lots.quality_state'

	WHERE materials.location_id in (2,3) AND categories.id = 3 AND materials.quantity > 0
	--ORDER BY barcode 
END
