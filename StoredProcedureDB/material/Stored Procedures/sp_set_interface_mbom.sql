-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_interface_mbom]
	-- Add the parameters for the stored procedure here
	(
		@state INT
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@state = 1) --MMS
	BEGIN
		DELETE [APCSProDWH].[dbo].[AP_FactoryStockInformation_RIST_LSI_IF]
		WHERE stateFlag = 1

		INSERT INTO [APCSProDWH].[dbo].[AP_FactoryStockInformation_RIST_LSI_IF]
		  SELECT color
				, date
				, goodsCode
				, soukocode
				,SUM(dailyStockQuantity) AS dailyStockQuantity
				, processQuantityUnitCode
				, deleteFlag
				, stateFlag
		  FROM (
		  		SELECT 
				'RT' AS color
				,GETDATE() AS date
				,'RT' + item_cd AS goodsCode
				,'LSIT' AS soukocode
				,materials.quantity AS dailyStockQuantity
				,podata.unitcode AS processQuantityUnitCode
				,0 AS deleteFlag
				,1 AS stateFlag
				, materials.id
				FROM APCSProDB.material.productions
				INNER JOIN APCSProDB.material.purchase_order_items as p_order ON productions.id = p_order.material_id
				INNER JOIN APCSProDB.trans.materials ON productions.id = materials.material_production_id
				INNER JOIN APCSProDWH.oneworld.podata ON p_order.item_cd = podata.itemcode
				WHERE location_id < 4 and category_id != 9 and materials.quantity > 0
				GROUP BY item_cd,item_name,productions.name,productions.unit_code,podata.unitcode,materials.quantity, materials.id) as tb_temp
			GROUP BY color, date, goodsCode, soukocode, processQuantityUnitCode, deleteFlag, stateFlag

		--SELECT 
		--'RT' AS color
		--,GETDATE() AS date
		--,'RT' + item_cd AS goodsCode
		--,'LSIT' AS soukocode
		--,SUM(materials.quantity) AS dailyStockQuantity
		--,podata.unitcode AS processQuantityUnitCode
		--,0 AS deleteFlag
		--,1 AS stateFlag
		--FROM APCSProDB.material.productions
		--INNER JOIN APCSProDB.material.purchase_order_items as p_order ON productions.id = p_order.material_id
		--INNER JOIN APCSProDB.trans.materials ON productions.id = materials.material_production_id
		--INNER JOIN APCSProDWH.oneworld.podata ON p_order.item_cd = podata.itemcode
		--WHERE location_id < 4 and category_id != 9 and materials.quantity > 0
		--GROUP BY item_cd,item_name,productions.name,productions.unit_code,podata.unitcode

		INSERT INTO [APCSProDWH].[dbo].[AP_FactoryStockInformation_RIST_LSI_IF_HIST]
		SELECT 
			GETDATE() AS [history_at]
		  ,[color]
		  ,[date]
		  ,[goodsCode]
		  ,[soukoCode]
		  ,[dailyStockQuantity]
		  ,[processQuantityUnitCode]
		  ,[deleteFlag]
		  ,[stateFlag]
		FROM [APCSProDWH].[dbo].[AP_FactoryStockInformation_RIST_LSI_IF]
		WHERE stateFlag = 1
		
	END

	ELSE IF(@state = 2) --Ledger
	BEGIN
		DELETE [APCSProDWH].[dbo].[AP_FactoryStockInformation_RIST_LSI_IF]
		WHERE stateFlag = 2

		INSERT INTO [APCSProDWH].[dbo].[AP_FactoryStockInformation_RIST_LSI_IF]
		SELECT 'RT' AS color
		,mlp.created_at AS date
		,'RT' + item_cd AS goodsCode
		,'LSIT' AS soukocode
		,wh_inv_qty AS dailyStockQuantity
		,podata.unitcode AS processQuantityUnitCode
		,0 AS deleteFlag
		,2 AS stateFlag
		FROM [APCSProDB].[trans].[material_ledger_process] mlp
		INNER JOIN APCSProDB.material.productions ON productions.name = mlp.product_name
		INNER JOIN APCSProDB.material.purchase_order_items as p_order ON productions.id = p_order.material_id
		INNER JOIN APCSProDWH.oneworld.podata ON p_order.item_cd = podata.itemcode
		GROUP BY item_cd,podata.unitcode,wh_inv_qty,mlp.created_at

		INSERT INTO [APCSProDWH].[dbo].[AP_FactoryStockInformation_RIST_LSI_IF_HIST]
		SELECT 
			GETDATE() AS [history_at]
		  ,[color]
		  ,[date]
		  ,[goodsCode]
		  ,[soukoCode]
		  ,[dailyStockQuantity]
		  ,[processQuantityUnitCode]
		  ,[deleteFlag]
		  ,[stateFlag]
		FROM [APCSProDWH].[dbo].[AP_FactoryStockInformation_RIST_LSI_IF]
		WHERE stateFlag = 2
	END

END
