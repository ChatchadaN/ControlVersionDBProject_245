-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_lot_inventory]
	 @lot_no VARCHAR(10) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	SELECT   ROW_NUMBER() OVER(ORDER BY lot_inventory.created_at) AS No
			,ISNULL(lot_inventory.id,'')		AS id
			,ISNULL(lot_inventory.lot_id,'')	AS lot_id
			,ISNULL(lot_inventory.lot_no,'')	AS lot_no
			,ISNULL(packages.name,'')			AS package
			,ISNULL(device_names.name,'')		AS device
			,ISNULL(jobs.name,'')				AS job
			,ISNULL(qty_pass,'')				AS qty_pass
			,ISNULL(qty_hasuu,'')				AS qty_hasuu
			,ISNULL(qty_out,'')					AS qty_out
			,ISNULL(qty_combined,'')			AS qty_combined
			,CASE WHEN ( lot_inventory.[location_id] = '' OR lot_inventory.[location_id] IS NULL)  THEN ISNULL(TRIM(locations.name),'')  
				ELSE ISNULL(TRIM(lot_inventory.[location_id]),'')  END AS location
			,ISNULL(lot_inventory.[address],'')				AS [address]
			,ISNULL(fcoino,'')					AS fcoino
			,ISNULL(sheet_no,'')				AS sheet_no
			,ISNULL(CASE WHEN lot_inventory.stock_class =  1 THEN 'WIP' WHEN lot_inventory.stock_class = 2 THEN 'HASUU NOW' ELSE 'HASUU LONG' END,'') AS stock_class
			,ISNULL(class.class_no,'')			AS classification_no
			,ISNULL(year_month,'')				AS year_month 
			,lot_inventory.created_at
			,ISNULL(users1.emp_num,'')			AS created_by
			,lot_inventory.updated_at 
			,ISNULL(users.emp_num,'')			AS updated_by 
	FROM APCSProDB.trans.lot_inventory
	LEFT JOIN APCSProDB.method.packages 
	ON  lot_inventory.package_id = packages.id 
	LEFT JOIN APCSProDB.method.device_names 
	ON  lot_inventory.device_id = device_names.id 
	LEFT JOIN APCSProDB.method.jobs 
	ON  lot_inventory.job_id = jobs.id  
	LEFT JOIN APCSProDB.man.users 
	ON lot_inventory.updated_by = users.id 
	LEFT JOIN APCSProDB.man.users users1 
	ON lot_inventory.created_by   = users1.id  
	LEFT JOIN APCSProDB.trans.surpluses 
	ON APCSProDB.trans.surpluses.serial_no = lot_inventory.lot_no 
    LEFT JOIN APCSProDB.trans.locations 
	ON APCSProDB.trans.locations.id = APCSProDB.trans.surpluses.location_id
	--LEFT JOIN APCSProDB.inv.class_locations as rack 
	--ON rack.location_name =  locations.name 
	--LEFT JOIN APCSProDB.inv.Inventory_classfications as class 
	--ON class.id = rack.class_id
	OUTER APPLY ( 
		SELECT TOP 1 [master].[class_no]
		FROM [APCSProDB].[inv].[class_locations] AS [match]
		INNER JOIN [APCSProDB].[inv].[Inventory_classfications] AS [master] ON [match].[class_id] = [master].[id]  
		WHERE [match].[location_name] = [lot_inventory].[location_id]
		UNION 
		SELECT TOP 1 [master].[class_no]
		FROM [APCSProDB].[inv].[class_locations] AS [match]
		INNER JOIN [APCSProDB].[inv].[Inventory_classfications] AS [master] ON [match].[class_id] = [master].[id]  
		WHERE [master].[class_no] = [lot_inventory].[classification_no]
	) AS [class]
	--WHERE [lot_inventory].[lot_no] like @lot_no
	WHERE (@lot_no <> '%' OR [lot_inventory].[lot_no] LIKE @lot_no)
	ORDER BY  lot_inventory.created_at 
	 
END
