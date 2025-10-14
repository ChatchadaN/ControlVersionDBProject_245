
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_insert_material] 
	-- Add the parameters for the stored procedure here
	  @CategoryName		NVARCHAR(50)		= NULL
	, @start_date		DATETIME			= '2023-01-01'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE	  @Counter	INT  
			, @CountTo  INT
			, @Serialno NVARCHAR(MAX)

	IF (@CategoryName ='AUWIRE' ) -- AUWIRE
	BEGIN 
		CREATE TABLE #TEMP 
				(
						  Serialno				NVARCHAR(200)
						, CategoryId			NVARCHAR(200) 
						, ProductName			NVARCHAR(200)
						, MaterialName			NVARCHAR(200)
						, MaterialCategory		NVARCHAR(200)
						, SupplierName			NVARCHAR(200)
						, StandardPackingQty	NVARCHAR(200)
						, UnitName				NVARCHAR(200)
						, MaterialLotNo			NVARCHAR(200)
				) 

		CREATE TABLE #SERIAL
		(
			Serialno NVARCHAR(MAX)
			, rowno INT 
		)
		INSERT INTO #SERIAL
		SELECT Serialno ,  ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS rowno 
		FROM  RAIS_TEST.dbo.RWIT_ItemStockTable
		LEFT JOIN APCSProDB_TEST.trans.materials
		ON  materials.barcode COLLATE SQL_Latin1_General_CP1_CI_AS =  RWIT_ItemStockTable.SerialNo COLLATE SQL_Latin1_General_CP1_CI_AS
		WHERE CategoryId		= @CategoryName   
		AND materials.barcode	IS NULL 
		AND LastUpdate BETWEEN  @start_date  AND GETDATE()
		 
		SET @Counter	=	1
		SET @CountTo	=	(SELECT COUNT(Serialno) FROM  #SERIAL)
		WHILE ( @Counter <= @CountTo)
		BEGIN
		SET @Serialno =  (SELECT Serialno FROM  #SERIAL WHERE rowno = @Counter)
	
				INSERT INTO #TEMP
				SELECT * FROM 
				(
					SELECT	  Serialno
							, CategoryId
							, DetailKey
							, CASE WHEN DetailValueN IS NULL 
								THEN (CASE WHEN DetailValueR IS NULL THEN  CAST(DetailValueD AS NVARCHAR(MAX))
										ELSE  CAST(DetailValueR AS NVARCHAR(MAX)) END) ELSE  CAST(DetailValueN AS NVARCHAR(MAX)) END AS DetailValueN
				FROM  RAIS_TEST.dbo.RWIT_ItemDetailTable 
				WHERE Serialno =  @Serialno   
				) t
				PIVOT
				(
				min(DetailValueN)
				FOR DetailKey IN (    ProductName
									, MaterialName
									, MaterialCategory
									, SupplierName
									, StandardPackingQty
									, UnitName
									, MaterialLotNo
								)
				) AS pivot_table

				DELETE FROM #TEMP
				WHERE ProductName	IS NULL 
				OR CategoryId		IS NULL
  
				INSERT INTO APCSProDB_TEST.trans.materials
				(
						  id
						, barcode
						, material_production_id
						, product_slip_id
						, step_no
						, in_quantity
						, quantity
						, fail_quantity
						, pack_count
						, is_production_usage
						, material_state
						, process_state
						, qc_state
						, created_at
						, created_by
				)
				SELECT   (SELECT MAX(id)+1 FROM APCSProDB_TEST.trans.materials)
				, #TEMP.Serialno						AS barcode 
				, ISNULL(productions.id,0)				AS material_production_id 
				, 0										AS product_slip_id  
				, 0										AS step_no
				, ISNULL(#TEMP.StandardPackingQty,0)	AS in_quantity
				, ISNULL(#TEMP.StandardPackingQty,0)	AS quantity
				, 0										AS fail_quantity
				, 0										AS pack_count
				, 0										AS is_production_usage
				, 1										AS material_state
				, 0										AS process_state
				, 0										AS qc_state
				, GETDATE()								AS created_at
				, 1										AS created_by
				FROM #TEMP
				INNER JOIN APCSProDB_TEST.material.categories
				ON #TEMP.CategoryId = categories.name
				INNER JOIN APCSProDB_TEST.material.productions
				ON #TEMP.ProductName = productions.name
				AND productions.category_id = (SELECT id FROM APCSProDB_TEST.material.categories WHERE  #TEMP.CategoryId =  categories.name  )
				WHERE #TEMP.CategoryId =  categories.name AND #TEMP.ProductName = productions.name

				DELETE FROM  #TEMP
				SET @Counter  = @Counter  + 1
				PRINT 	@Counter  
		END

		DROP TABLE #SERIAL
		DROP TABLE #TEMP
	END
	IF (@CategoryName = 'FrameBake' ) -- Frame
	BEGIN 
			CREATE TABLE #TEMP_Frame
			(
					  Serialno				NVARCHAR(200)
					, CategoryId			NVARCHAR(200) 
					, FrameType				NVARCHAR(200)
					, MaterialLotNo			NVARCHAR(200)
			) 

			CREATE TABLE #SERIAL_Frame
			(
					  Serialno				NVARCHAR(MAX)
					, rowno					INT 
			)
			INSERT INTO #SERIAL_Frame
			SELECT  Serialno ,  ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS rowno 
			FROM  RAIS_TEST.dbo.RWIT_ItemStockTable
			LEFT JOIN APCSProDB_TEST.trans.materials
			ON  materials.barcode COLLATE SQL_Latin1_General_CP1_CI_AS =  RWIT_ItemStockTable.SerialNo COLLATE SQL_Latin1_General_CP1_CI_AS
			WHERE CategoryId = @CategoryName
			AND materials.barcode IS NULL 
			AND LastUpdate BETWEEN  @start_date  AND GETDATE()
 
			SET @Counter	=	1
			SET @CountTo	=	(SELECT COUNT(Serialno) FROM  #SERIAL_Frame)

			WHILE ( @Counter <= @CountTo)
			BEGIN
			SET @Serialno =  (SELECT Serialno FROM  #SERIAL_Frame WHERE rowno = @Counter)
	
				INSERT INTO #TEMP_Frame
				SELECT * FROM 
				(
				SELECT	  Serialno
						, CategoryId
						, DetailKey
						, CASE WHEN DetailValueN IS NULL 
							THEN (CASE WHEN DetailValueR IS NULL THEN  CAST(DetailValueD AS NVARCHAR(MAX))
									ELSE  CAST(DetailValueR AS NVARCHAR(MAX)) END) ELSE  CAST(DetailValueN AS NVARCHAR(MAX)) END AS DetailValueN
				FROM  RAIS_TEST.dbo.RWIT_ItemDetailTable 
				WHERE Serialno =  @Serialno   
				) t
				PIVOT
				(
				min(DetailValueN)
				FOR DetailKey IN ( 
									  FrameType
									, MaterialLotNo
									) 
				) AS pivot_table

				DELETE FROM #TEMP_Frame
				WHERE	FrameType	IS NULL 
				OR		CategoryId	IS NULL

				UPDATE #TEMP_Frame
				SET CategoryId = REPLACE(CategoryId, 'Bake', '') 
				FROM #TEMP_Frame 
				SELECT * FROM #TEMP_Frame
  
				INSERT INTO APCSProDB_TEST.trans.materials
				(
						  id
						, barcode
						, material_production_id
						, product_slip_id
						, step_no
						, in_quantity
						, quantity
						, fail_quantity
						, pack_count
						, is_production_usage
						, material_state
						, process_state
						, qc_state
						, lot_no
						, created_at
						, created_by
				)
				SELECT   (SELECT MAX(id)+1 FROM APCSProDB_TEST.trans.materials)  AS id
				, #TEMP_Frame.Serialno						AS barcode 
				, ISNULL(productions.id,0)				AS material_production_id 
				, 0										AS product_slip_id  
				, 0										AS step_no
				, 0										AS in_quantity
				, 0										AS quantity
				, 0										AS fail_quantity
				, 0										AS pack_count
				, 0										AS is_production_usage
				, 1										AS material_state
				, 0										AS process_state
				, 0										AS qc_state
				, #TEMP_Frame.MaterialLotNo				AS lot_no
				, GETDATE()								AS created_at
				, 1										AS created_by
				FROM #TEMP_Frame
				INNER JOIN APCSProDB_TEST.material.categories
				ON #TEMP_Frame.CategoryId = categories.name
				INNER JOIN APCSProDB_TEST.material.productions
				ON #TEMP_Frame.FrameType = productions.name
				AND productions.category_id = (SELECT id FROM APCSProDB_TEST.material.categories WHERE  #TEMP.CategoryId =  categories.name  )
				WHERE #TEMP_Frame.CategoryId =  categories.name AND #TEMP_Frame.FrameType = productions.name

				DELETE FROM  #TEMP_Frame
				SET @Counter  = @Counter  + 1
				PRINT 	@Counter  
			END

			DROP TABLE #SERIAL_Frame
			DROP TABLE #TEMP_Frame
	END
	IF (@CategoryName = 'SupplierNameMaster' ) -- Master
	BEGIN
	 

		CREATE TABLE #TEMP_Master 
				(
						  Serialno				NVARCHAR(200)
						, CategoryId			NVARCHAR(200) 
						, ProductName			NVARCHAR(200)
						, MaterialName			NVARCHAR(200)
						, MaterialCategory		NVARCHAR(200)
						, SupplierName			NVARCHAR(200)
						, StandardPackingQty	NVARCHAR(200)
						, UnitName				NVARCHAR(200)
						 
				) 

		CREATE TABLE #SERIAL_Master 
		(
			Serialno NVARCHAR(MAX)
			, rowno INT 
		)
		INSERT INTO #SERIAL_Master
		SELECT  Serialno ,  ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS rowno 
		FROM  RAIS_TEST.dbo.RWIT_ItemStockTable
		LEFT JOIN APCSProDB_TEST.trans.materials
		ON  materials.barcode COLLATE SQL_Latin1_General_CP1_CI_AS =  RWIT_ItemStockTable.SerialNo COLLATE SQL_Latin1_General_CP1_CI_AS
		WHERE CategoryId = @CategoryName   
		AND materials.barcode IS NULL  
		AND LastUpdate BETWEEN  @start_date  AND GETDATE()
		 
		SET @Counter	=	1
		SET @CountTo	=	(SELECT COUNT(Serialno) FROM  #SERIAL_Master )
		WHILE ( @Counter <= @CountTo)
		BEGIN
		SET @Serialno =  (SELECT Serialno FROM  #SERIAL_Master  WHERE rowno = @Counter)
	
				INSERT INTO #TEMP_Master 
				SELECT * FROM 
				(
				SELECT		  Serialno
						, CategoryId
						, DetailKey
						, CASE WHEN DetailValueN IS NULL 
							THEN (CASE WHEN DetailValueR IS NULL THEN  CAST(DetailValueD AS NVARCHAR(MAX))
									ELSE  CAST(DetailValueR AS NVARCHAR(MAX)) END) ELSE  CAST(DetailValueN AS NVARCHAR(MAX)) END AS DetailValueN
				FROM  RAIS_TEST.dbo.RWIT_ItemDetailTable 
				WHERE Serialno =  @Serialno   
			 
		 
				) t
				PIVOT
				(
				min(DetailValueN)
				FOR DetailKey IN (    ProductName
									, MaterialName
									, MaterialCategory
									, SupplierName
									, StandardPackingQty
									, UnitName
									 
								)
				) AS pivot_table

				DELETE FROM #TEMP_Master 
				WHERE ProductName	IS NULL 
				OR CategoryId		IS NULL
   
				INSERT INTO APCSProDB_TEST.trans.materials
				(
						  id
						, barcode
						, material_production_id
						, product_slip_id
						, step_no
						, in_quantity
						, quantity
						, fail_quantity
						, pack_count
						, is_production_usage
						, material_state
						, process_state
						, qc_state
						, created_at
						, created_by
				)
				SELECT   (SELECT MAX(id)+1 FROM APCSProDB_TEST.trans.materials)
				, Serialno						AS barcode 
				, productions.id				AS material_production_id 
				, 0								AS product_slip_id  
				, 0								AS step_no
				, ISNULL(StandardPackingQty,0)	AS in_quantity
				, ISNULL(StandardPackingQty,0)	AS quantity
				, 0								AS fail_quantity
				, 0								AS pack_count
				, 0								AS is_production_usage
				, 1								AS material_state
				, 0								AS process_state
				, 0								AS qc_state 
				, GETDATE()						AS created_at
				, 1								AS created_by
				FROM #TEMP_Master 
				INNER JOIN APCSProDB_TEST.material.categories
				ON  REPLACE(UPPER(#TEMP_Master .MaterialName),' ' , '') = UPPER(categories.name)
				INNER JOIN APCSProDB_TEST.material.productions
				ON REPLACE(productions.name,' ' , '') = REPLACE(#TEMP_Master .ProductName,' ' , '')
				AND productions.category_id = (SELECT id FROM APCSProDB_TEST.material.categories WHERE REPLACE(UPPER(#TEMP_Master.MaterialName),' ' , '') =  UPPER(categories.name)  )
				WHERE REPLACE(UPPER(MaterialName),' ' , '') =  UPPER(categories.name)   AND #TEMP_Master.ProductName = productions.name
				AND  MaterialCategory  = 'Main Materials'

		 
				DELETE FROM  #TEMP_Master
				SET @Counter  = @Counter  + 1
				PRINT 	@Counter  
		END

		DROP TABLE #SERIAL_Master
		DROP TABLE #TEMP_Master
 
	END 
  
END
