
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/07/31>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_stock_in_pc_001]
	-- Add the parameters for the stored procedure here
		@location_id			INT 
		, @production_id		INT				= 0
		, @pono					NVARCHAR(100)	= ''
		, @categories_id		INT				=  0 
 

	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  
	SELECT     material_receiving_process.id
				, podata.pono			AS ponumber
				, categories.id		AS category_id 
				, categories.[name]		AS category
				, productions.id		AS production_id 
				, suppliers.[name]	AS product
				, material_receiving_process.invoice_number  AS invoice_number
				, material_receiving_process.lot_number AS lot_number
				, material_receiving_process.package_qty AS package_qty
				, material_receiving_process.order_qty AS order_qty
				, material_receiving_process.receiving_qty AS receiving_qty
				, trim(unit_convert.ropros_unitname) AS unit
				, CONVERT(VARCHAR, material_receiving_process.[expiry_date], 23)  AS [expiry_date]
		FROM APCSProDB.trans.material_receiving_process
		INNER JOIN APCSProDB.material.productions
		ON productions.id  =  material_receiving_process.product_id
		INNER JOIN APCSProDB.material.suppliers
		ON suppliers.supplier_cd = productions.supplier_cd
		INNER JOIN APCSProDB.material.categories
		ON categories.id  =  productions.category_id
		INNER JOIN APCSProDWH.oneworld.podata
		ON  podata.id = material_receiving_process.po_id
		INNER JOIN APCSProDWH.oneworld.unit_convert
		ON podata.unitcode = unit_convert.ropros_unit
		WHERE [status] =  'W'
		AND (location_id		= @location_id		 )
		AND (productions.id		= @production_id	OR @production_id	= 0	)
		AND (podata.pono		= @pono				OR ISNULL(@pono ,'') = '')
		AND (categories.id		= @categories_id 	OR @categories_id 	= 0	) 
		GROUP BY  material_receiving_process.id
		, podata.pono		 
		, categories.[name]	 
		, suppliers.[name]	 
		, material_receiving_process.invoice_number
		, material_receiving_process.lot_number
		, material_receiving_process.package_qty
		, material_receiving_process.order_qty
		, material_receiving_process.receiving_qty
		, unit_convert.ropros_unitname  
		, material_receiving_process.[expiry_date]
		, podata.unitcode 
		, categories.id  
		, productions.id 


END
