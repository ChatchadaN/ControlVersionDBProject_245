
-- =============================================
-- Author:		<Author,Sadanan B.>
-- Create date: <Create Date, 2025/07/31>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_stock_in_pc_detail_001]
	-- Add the parameters for the stored procedure here
		@po_id			INT 
	  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  
				CREATE TABLE #materialreceiving
				(	  po_id					NVARCHAR(100)
					, ponumber				NVARCHAR(100)
					, category_id			INT
					, material_id			INT 
					, unitcode				INT 
					, OrderQuantity			DECIMAL(18,6)
					, ReceivingQuantity		DECIMAL(18,6)
					, PackageSizeQuantity	DECIMAL(18,6)
					, ExpiryDate			NVARCHAR(100)
					, ExpiryCondition		NVARCHAR(100)
					, PackageUnit			NVARCHAR(100)
					, ReceiveUnit			NVARCHAR(100)
					, production_id			INT
					, id					INT
					, quantity				DECIMAL(18,6)
					, ropros_unitname		NVARCHAR(100)
					, arrival_qty			INT
				)	

				INSERT INTO  #materialreceiving
				SELECT        podata.id								AS po_id
							, podata.pono							AS ponumber
							, productions.category_id				AS category_id
							, material_arrival_records.material_id
							, podata.unitcode				 
							, podata.orderqty								AS OrderQuantity
							, podata.orderqty								AS ReceivingQuantity
							, ISNULL(productions.arrival_std_qty, 0)		AS PackageSizeQuantity
							, CONVERT(VARCHAR,CASE WHEN productions.expiration_unit = 1		THEN DATEADD(MINUTE ,productions.expiration_value , GETDATE()) 
									WHEN productions.expiration_unit = 2	THEN DATEADD(HOUR   ,productions.expiration_value , GETDATE()) 
									WHEN productions.expiration_unit = 3	THEN DATEADD(DAY    ,productions.expiration_value , GETDATE()) 
									WHEN productions.expiration_unit = 4	THEN DATEADD(MONTH  ,productions.expiration_value , GETDATE()) 
									WHEN productions.expiration_unit = 5	THEN DATEADD(YEAR   ,productions.expiration_value , GETDATE()) 
									ELSE DATEADD(YEAR ,1 , GETDATE()) END , 121)				AS ExpiryDate
							,CAST(expiration_base.descriptions  AS NVARCHAR(100)) +' (+'+ CAST(productions.expiration_value AS NVARCHAR(100)) + ' '+  CAST(expiration_unit.descriptions AS NVARCHAR(100)) +')' AS    ExpiryCondition
							, unit_code.descriptions			AS PackageUnit
							, podata.unitcode					 AS ReceiveUnit   
							, productions.id						AS production_id 
							, materials.id   
							, materials.quantity
							, unit_convert.ropros_unitname
							,  podata.orderqty		AS arrival_qty
				FROM  APCSProDB.material.productions
				INNER JOIN [APCSProDB].material.purchase_order_items
				ON productions.id	  = purchase_order_items.material_id  
				INNER JOIN APCSProDWH.oneworld.podata		
				ON purchase_order_items.item_cd = podata.itemcode
				INNER JOIN APCSProDWH.oneworld.unit_convert
				ON podata.unitcode = unit_convert.ropros_unit
				INNER JOIN [APCSPRODB].[MATERIAL].SUPPLIER_CONVERSION [CONVERSION] 
				ON [CONVERSION].PO_SUPPLIER_CD = podata.SUPPLIERCODE 
				INNER JOIN APCSProDB.trans.materials
				ON  productions.id  = materials.material_production_id 
				LEFT JOIN APCSProDB.trans.material_arrival_records
				ON material_arrival_records.material_id = materials.id 
				AND    material_arrival_records.po_no = podata.pono
				INNER JOIN APCSProDB.material.categories
				ON categories.id = productions.category_id 
				LEFT JOIN APCSProDB.material.material_codes AS expiration_base
				ON expiration_base.code = productions.expiration_base
				AND  expiration_base.[group] = 'exp_unit'
				LEFT JOIN APCSProDB.material.material_codes AS expiration_unit
				ON expiration_unit.code = productions.expiration_unit
				AND  expiration_unit.[group] = 'time_unit'
				LEFT JOIN APCSProDB.material.material_codes AS unit_code
				ON unit_code.code = productions.unit_code 
				AND  unit_code.[group] = 'package_unit'
				WHERE  
				StoredProcedureDB.material.FN_STRIPCHARACTERS([PRODUCTIONS].[NAME], '^a-z0-9') 
				= StoredProcedureDB.MATERIAL.FN_STRIPCHARACTERS(podata.SPECIFICATION, '^a-z0-9') 
				AND [PRODUCTIONS].SUPPLIER_CD = [CONVERSION].PROD_SUPPLIER_CD			AND 
					podata.id = @po_id
				GROUP BY    podata.id	
							, podata.pono 
							, productions.id			 
							, purchase_order_items.material_id 
							, productions.category_id
							, productions.expiration_unit
							, productions.expiration_base
							, productions.unit_code
							, podata.unitcode			
							, productions.category_id	
							, podata.orderqty	
							, productions.arrival_std_qty
							, podata.unitcode
							, productions.expiration_value
							, unit_convert.ropros_unitname
							, expiration_base.descriptions
							, expiration_unit.descriptions
							, unit_code.descriptions
							, materials.id  
							, materials.quantity
							, material_arrival_records.material_id
			
					 
				 SELECT    po_id					
						 , ponumber				
						 , category_id			
						 , unitcode			 		
						 , OrderQuantity			
						 , ReceivingQuantity		
						 , PackageSizeQuantity	
						 , CONVERT(VARCHAR , ExpiryDate	 , 121)		AS ExpiryDate
						 , ExpiryCondition		
						 , PackageUnit			
						 , ReceiveUnit			
						 , production_id	 	  
						 , IIF(material_id IS NULL, 0,  IIF(SUBSTRING(trim(ropros_unitname) ,1,2) IN ('KP' , 'KM')  , SUM(quantity) / 1000,  SUM(quantity)))  AS ReceivedQuantity
						 , OrderQuantity -  IIF(material_id IS NULL, 0,  IIF(SUBSTRING(trim(ropros_unitname) ,1,2) IN ('KP' , 'KM')  , SUM(quantity)	 / 1000,  SUM(quantity))) AS BalanceQuantity
				 FROM #materialreceiving
				 GROUP BY    po_id					
							, ponumber				
							, category_id			
							, unitcode				 
							, OrderQuantity			
							, ReceivingQuantity		
							, PackageSizeQuantity	
							, ExpiryDate			
							, ExpiryCondition		
							, PackageUnit			
							, ReceiveUnit			
							, production_id
							, ropros_unitname 
							, arrival_qty
							, material_id


				DROP TABLE #materialreceiving
END
