-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_hasuu_processing_inventory]
	@lot_no VARCHAR(10) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT ROW_NUMBER() OVER(ORDER BY sur.created_at) AS No
	,ISNULL(pk.name,'') AS pack_name
	,ISNULL(dn.name,'') AS device_name
	,ISNULL(sur.serial_no,'') AS lotno
	--,inven.lot_no as inven_lotno
	,ISNULL(sur.pcs,'') AS qty_hasuu
	,ISNULL(lots.id,'') AS lotid
	, ISNULL(CASE WHEN sur.location_id IS NOT NULL  THEN  loca.address ELSE inven.location_id END,'') AS rack_name
	,ISNULL(loca.name,'') AS rack_address
	,'HASUU NOW'  AS status_lot
	, ISNULL(class.class_no,'') AS [classification_no]
	--, ISNULL(sheet_rack_inventory.class_no,'') AS [classification_no]
	FROM APCSProDB.trans.surpluses AS sur
	LEFT JOIN APCSProDB.trans.lot_inventory AS inven on sur.lot_id = inven.lot_id 
	INNER JOIN APCSProDB.trans.lots on sur.lot_id = lots.id
	INNER JOIN APCSProDB.method.packages AS pk on lots.act_package_id = pk.id
	INNER JOIN APCSProDB.method.device_names AS dn on lots.act_device_name_id = dn.id
	LEFT JOIN APCSProDB.trans.locations AS loca on sur.location_id = loca.id	
	LEFT JOIN APCSProDB.inv.class_locations as rack ON rack.location_name =  loca.name 
	LEFT JOIN APCSProDB.inv.Inventory_classfications as class ON class.id = rack.class_id

	--LEFT JOIN  APCSProDWH.atom.sheet_rack_inventory
	--ON sheet_rack_inventory.location =   loca.name
	WHERE sur.in_stock = 2
	AND inven.lot_no IS NULL 
	AND lots.wip_state = 20
	AND serial_no <> ''
	AND (@lot_no <> '%' OR sur.serial_no LIKE @lot_no)
	AND sur.pcs > 0
	ORDER BY sur.serial_no
END
