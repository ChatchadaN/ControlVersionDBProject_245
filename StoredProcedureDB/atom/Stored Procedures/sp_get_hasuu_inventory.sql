-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_hasuu_inventory]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @datetime DATETIME
	DECLARE @year_now int = 0
	SET @datetime = GETDATE()
	SELECT @year_now = (FORMAT(@datetime,'yy')-3)
 
	SELECT * FROM (
	SELECT ROW_NUMBER() OVER(ORDER BY sur.created_at) AS No
	,ISNULL(pk.name,'') AS pack_name
	,ISNULL(dn.name,'') AS device_name
	,ISNULL(sur.serial_no,'') AS lotno
	,ISNULL(sur.pcs,'') AS qty_hasuu
	,ISNULL(lots.id,'') AS lotid
	,ISNULL(CASE WHEN sur.location_id IS NOT NULL  THEN  loca.name ELSE inven.location_id END,'') AS rack_name
	,ISNULL(loca.address,'') AS rack_address
	, ISNULL(CASE WHEN  SUBSTRING(sur.serial_no,1,2) >= @year_now THEN 'HASUU NOW' 
		ELSE 'HASUU LONG' END,0) AS status_lot
	, ISNULL(class.class_no,'') AS [classification_no]
	--, ISNULL(sheet_rack_inventory.class_no,'') AS [classification_no]
	,sur.in_stock
	,(SELECT TOP(1) 1 FROM [APCSProDB].[trans].[lots] 
									 INNER JOIN [APCSProDB].[trans].[lot_process_records] ON [lots].[id] = [lot_process_records].[lot_id]
									  AND [lot_process_records].[record_class] = 1 --1 :LotStart
									  AND [lot_process_records].[job_id] IN (93,199,209,222,236,289,293,323,332,369,401,143,287)
									 WHERE [lots].[lot_no] = sur.serial_no) AS is_tp
	FROM APCSProDB.trans.surpluses AS sur
	LEFT JOIN APCSProDB.trans.lot_inventory AS inven on sur.lot_id = inven.lot_id AND (inven.stock_class in ('02','03'))
	INNER JOIN APCSProDB.trans.lots on sur.lot_id = lots.id
	INNER JOIN APCSProDB.method.packages AS pk on lots.act_package_id = pk.id
	INNER JOIN APCSProDB.method.device_names AS dn on lots.act_device_name_id = dn.id
	LEFT JOIN APCSProDB.trans.locations AS loca on sur.location_id = loca.id
	LEFT JOIN APCSProDB.inv.class_locations as rack ON rack.location_name =  loca.name 
	LEFT JOIN APCSProDB.inv.Inventory_classfications as class ON class.id = rack.class_id
	--LEFT JOIN APCSProDWH.atom.sheet_rack_inventory ON sheet_rack_inventory.[location]   =  loca.name 
	WHERE sur.in_stock = 2 and sur.pcs > 0
	AND inven.lot_no IS NULL AND sur.serial_no <> ''
	AND (@lot_no <> '%' OR sur.serial_no LIKE @lot_no)) AS hasuu_data
	WHERE is_tp = 1
	ORDER BY hasuu_data.lotno 

	--SELECT ROW_NUMBER() OVER(ORDER BY sur.created_at) AS No
	--,ISNULL(pk.name,'') AS pack_name
	--,ISNULL(dn.name,'') AS device_name
	--,ISNULL(sur.serial_no,'') AS lotno
	--,ISNULL(sur.pcs,'') AS qty_hasuu
	--, ISNULL(CASE WHEN sur.location_id IS NOT NULL  THEN  loca.name ELSE inven.location_id END,'') AS rack_name
	--,ISNULL(loca.address,'') AS rack_address
	--, ISNULL(CASE WHEN  SUBSTRING(sur.serial_no,1,2) >= @year_now THEN 'HASUU NOW' 
	--	ELSE 'HASUU LONG' END,0) AS status_lot
	--, ISNULL(sheet_rack_inventory.class_no,'') AS [classification_no]
	--,sur.in_stock
	--FROM APCSProDB.trans.surpluses AS sur
	--LEFT JOIN APCSProDB.trans.lot_inventory AS inven on sur.lot_id = inven.lot_id AND (inven.stock_class in ('02','03'))
	--INNER JOIN APCSProDB.trans.lots on sur.lot_id = lots.id
	--INNER JOIN APCSProDB.method.packages AS pk on lots.act_package_id = pk.id
	--INNER JOIN APCSProDB.method.device_names AS dn on lots.act_device_name_id = dn.id
	--LEFT JOIN APCSProDB.trans.locations AS loca on sur.location_id = loca.id
	--LEFT JOIN APCSProDWH.atom.sheet_rack_inventory
	--ON sheet_rack_inventory.[location]   =  loca.name 
	--WHERE sur.in_stock = 2 and sur.pcs > 0 
	--AND inven.lot_no IS NULL  AND sur.serial_no <> ''
	--ORDER BY sur.serial_no 

END
