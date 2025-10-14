
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_insert_jigs]
	-- Add the parameters for the stored procedure here
	  @CategoryName		NVARCHAR(50)	= NULL
	, @start_date		DATETIME		= '2023-01-01'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE		  @Counter INT  
				, @CountTo  INT
				, @Serialno NVARCHAR(MAX)
  
	IF  (@CategoryName = 'CapillaryTable')  --Capillary
	BEGIN 

		CREATE TABLE #TEMP 
			(
					  Serialno				NVARCHAR(200)
					, CategoryId			NVARCHAR(200) 
					, CapillaryType			NVARCHAR(200)
			) 
		CREATE TABLE #SERIAL
		(
			  Serialno NVARCHAR(MAX)
			, rowno INT 
		)
		INSERT INTO #SERIAL
		SELECT  Serialno ,  ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS rowno 
		FROM  RAIS_TEST.dbo.RWIT_ItemStockTable
		LEFT JOIN APCSProDB_TEST.trans.jigs
		ON  jigs.qrcodebyuser COLLATE SQL_Latin1_General_CP1_CI_AS =  RWIT_ItemStockTable.SerialNo COLLATE SQL_Latin1_General_CP1_CI_AS
		WHERE  CategoryId = @CategoryName
		AND jigs.qrcodebyuser IS NULL 
		AND LastUpdate BETWEEN  @start_date  AND GETDATE()
 
		SET @Counter	=	1
		SET @CountTo	=	(SELECT COUNT(Serialno) FROM  #SERIAL)
		WHILE ( @Counter <= @CountTo)
		BEGIN
		SET @Serialno =  (SELECT Serialno FROM  #SERIAL WHERE rowno = @Counter)
	
				 INSERT INTO #TEMP
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
					FOR DetailKey IN (   
										CapillaryType
									 )
				) AS pivot_table
		 
				UPDATE #TEMP
				SET CategoryId = REPLACE(CategoryId, 'Table', '') 
				FROM #TEMP

				DELETE FROM #TEMP
				WHERE	CapillaryType	IS NULL 
				OR		CategoryId		IS NULL
 
				INSERT INTO APCSProDB_TEST.trans.jigs
				(
						   qrcodebyuser
						, status
						, jig_production_id
						, in_quantity
						, quantity
						, is_production_usage
						, jig_state
						, process_state
						, qc_state
						, created_at
						, created_by
				)
				SELECT     #TEMP.Serialno		AS qrcodebyuser 
						, 'To Machine'			AS status 
						, productions.id		AS jig_production_id  
						, 0						AS in_quantity
						, 0						AS quantity
						, 0						AS is_production_usage
						, 11					AS jig_state
						, 1						AS process_state
						, 0						AS qc_state
						, GETDATE()
						, 1
				FROM #TEMP
				INNER JOIN APCSProDB_TEST.jig.categories
				ON  CategoryId = categories.name
				INNER JOIN APCSProDB_TEST.jig.productions
				ON #TEMP.CapillaryType = productions.name
				AND productions.category_id = (SELECT id FROM APCSProDB_TEST.jig.categories WHERE CategoryId =  categories.name  )
				WHERE #TEMP.CategoryId =  categories.name AND #TEMP.CapillaryType = productions.name

				DELETE FROM  #TEMP
				SET @Counter  = @Counter  + 1
				PRINT @Counter
		END
		DROP TABLE #SERIAL
		DROP TABLE #TEMP

	END 
	IF  (@CategoryName = 'BladeDeviceCrossCheckTbl') --Blade
	BEGIN  

		CREATE TABLE #TEMP_Blade 
			(
					  Serialno				NVARCHAR(200)
					, CategoryId			NVARCHAR(200) 
					, BladeType				NVARCHAR(200)
			) 

		CREATE TABLE #SERIAL_Blade
		(
			  Serialno NVARCHAR(MAX)
			, rowno INT 
		)
		INSERT INTO #SERIAL_Blade
		SELECT		Serialno 
				,   ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS rowno 
		FROM  RAIS_TEST.dbo.RWIT_ItemStockTable
		LEFT JOIN APCSProDB_TEST.trans.jigs
		ON  jigs.qrcodebyuser COLLATE SQL_Latin1_General_CP1_CI_AS =  RWIT_ItemStockTable.SerialNo COLLATE SQL_Latin1_General_CP1_CI_AS
		WHERE  CategoryId = @CategoryName
		AND jigs.qrcodebyuser IS NULL 
		AND LastUpdate BETWEEN  @start_date  AND GETDATE()

		SET @Counter	=	1
		SET @CountTo	=	(SELECT COUNT(Serialno) FROM  #SERIAL_Blade)

		WHILE ( @Counter <= @CountTo)
		BEGIN
		SET @Serialno =  (SELECT Serialno FROM  #SERIAL_Blade WHERE rowno = @Counter)
	
				 INSERT INTO #TEMP_Blade
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
					FOR DetailKey IN (   
										  BladeType
									 )
				) AS pivot_table
		 
				UPDATE #TEMP_Blade
				SET CategoryId = REPLACE(CategoryId, 'DeviceCrossCheckTbl', '') 
				FROM #TEMP_Blade

				DELETE FROM #TEMP_Blade
				WHERE   CategoryId	IS NULL 
				OR		BladeType	IS NULL
  
				INSERT INTO APCSProDB_TEST.trans.jigs
				(
						   qrcodebyuser
						, status
						, jig_production_id
						, in_quantity
						, quantity
						, is_production_usage
						, jig_state
						, process_state
						, qc_state
						, created_at
						, created_by
				)
				SELECT     #TEMP_Blade.Serialno		AS qrcodebyuser 
						, 'To Machine'				AS status 
						, productions.id			AS jig_production_id  
						, 0							AS in_quantity
						, 0							AS quantity
						, 0							AS is_production_usage
						, 11						AS jig_state
						, 1							AS process_state
						, 0							AS qc_state
						, GETDATE()					AS created_at
						, 1							AS created_by
				FROM #TEMP_Blade
				INNER JOIN APCSProDB_TEST.jig.categories
				ON  CategoryId = categories.name
				INNER JOIN APCSProDB_TEST.jig.productions
				ON #TEMP_Blade.BladeType = productions.name
				AND productions.category_id = (SELECT id FROM APCSProDB_TEST.jig.categories WHERE CategoryId =  categories.name  )
				WHERE #TEMP_Blade.CategoryId =  categories.name AND #TEMP_Blade.BladeType = productions.name

				DELETE FROM  #TEMP_Blade
				SET @Counter  = @Counter  + 1
				PRINT @Counter
			END

			DROP TABLE #SERIAL_Blade
			DROP TABLE #TEMP_Blade
	END 
	IF  (@CategoryName = 'Kanagata') --Kanagata
	BEGIN
				CREATE TABLE #TEMP_Kanagate
				(
						  Serialno				NVARCHAR(200)
						, CategoryId			NVARCHAR(200) 
						, PartName				NVARCHAR(200)
				) 

				CREATE TABLE #SERIAL_Kanagate
				(
						  Serialno				NVARCHAR(MAX)
						, rowno					INT 
				)
				INSERT INTO #SERIAL_Kanagate
				SELECT     Serialno 
						 , ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS rowno 
				FROM  RAIS_TEST.dbo.RWIT_ItemStockTable
				LEFT JOIN APCSProDB_TEST.trans.jigs
				ON  jigs.qrcodebyuser COLLATE SQL_Latin1_General_CP1_CI_AS =  RWIT_ItemStockTable.SerialNo COLLATE SQL_Latin1_General_CP1_CI_AS
				WHERE  CategoryId = @CategoryName 
				AND jigs.qrcodebyuser IS NULL 
				AND LastUpdate BETWEEN  @start_date  AND GETDATE()

				SET @Counter	=	1
				SET @CountTo	=	(SELECT COUNT(Serialno) FROM  #SERIAL_Kanagate)

				WHILE ( @Counter <= @CountTo)
				BEGIN
				SET @Serialno =  (SELECT Serialno FROM  #SERIAL_Kanagate WHERE rowno = @Counter)
	
				 INSERT INTO #TEMP_Kanagate
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
					FOR DetailKey IN (   
										  PartName
									 )
				) AS pivot_table
 
				DELETE FROM #TEMP_Kanagate
				WHERE   CategoryId IS NULL
  
				INSERT INTO APCSProDB_TEST.trans.jigs
				(
						   qrcodebyuser
						, status
						, jig_production_id
						, in_quantity
						, quantity
						, is_production_usage
						, jig_state
						, process_state
						, qc_state
						, created_at
						, created_by
				)
				SELECT     #TEMP_Kanagate.Serialno		AS qrcodebyuser 
						, 'To Machine'					AS status 
						, productions.id				AS jig_production_id  
						, 0								AS in_quantity
						, 0								AS quantity
						, 0								AS is_production_usage
						, 11							AS jig_state
						, 1								AS process_state
						, 0								AS qc_state
						, GETDATE()						AS created_at
						, 1								AS created_by
				FROM #TEMP_Kanagate
				INNER JOIN APCSProDB_TEST.jig.categories
				ON  CategoryId = categories.short_name
				INNER JOIN APCSProDB_TEST.jig.productions
				ON #TEMP_Kanagate.PartName = productions.name
				AND productions.category_id = (SELECT TOP 1 id FROM APCSProDB_TEST.jig.categories WHERE CategoryId =  categories.short_name AND lsi_process_id =  9 )
				WHERE #TEMP_Kanagate.CategoryId =  categories.name AND #TEMP_Kanagate.PartName = productions.name

				DELETE FROM  #TEMP_Kanagate
				SET @Counter  = @Counter  + 1
				PRINT @Counter

			END
			DROP TABLE #SERIAL_Kanagate
			DROP TABLE #TEMP_Kanagate

	END 
	IF  (@CategoryName = 'PD_TOOLS') --PD_TOOLS
	BEGIN
				CREATE TABLE #TEMP_TOOLS
				(
						  Serialno				NVARCHAR(200)
						, CategoryId			NVARCHAR(200) 
						, PartName				NVARCHAR(200)
						, Specs					NVARCHAR(200)
				) 

				CREATE TABLE #SERIAL_TOOLS
				(
						  Serialno				NVARCHAR(MAX)
						, rowno					INT 
				)
				INSERT INTO #SERIAL_TOOLS
				SELECT    Serialno 
						, ROW_NUMBER() OVER (ORDER BY (SELECT 1)) AS rowno 
				FROM  RAIS_TEST.dbo.RWIT_ItemStockTable
				LEFT JOIN APCSProDB_TEST.trans.jigs
				ON  jigs.qrcodebyuser COLLATE SQL_Latin1_General_CP1_CI_AS =  RWIT_ItemStockTable.SerialNo COLLATE SQL_Latin1_General_CP1_CI_AS
				WHERE  CategoryId = @CategoryName
				AND jigs.qrcodebyuser IS NULL 
				AND LastUpdate BETWEEN  @start_date  AND GETDATE()


				SET @Counter	=	1
				SET @CountTo	=	(SELECT COUNT(Serialno) FROM  #SERIAL_TOOLS)

				WHILE ( @Counter <= @CountTo)
				BEGIN
				SET @Serialno =  (SELECT Serialno FROM  #SERIAL_TOOLS WHERE rowno = @Counter)
	
				 INSERT INTO #TEMP_TOOLS
				 SELECT * FROM 
				 (
				 SELECT		  Serialno
							, CategoryId
							, DetailKey
							, CASE WHEN DetailValueN IS NULL 
								THEN (CASE WHEN DetailValueR IS NULL THEN  CAST(DetailValueD AS NVARCHAR(MAX))
										ELSE  CAST(DetailValueR AS NVARCHAR(MAX)) END) ELSE  CAST(DetailValueN AS NVARCHAR(MAX)) END AS DetailValueN
				 FROM  RAIS_TEST.dbo.RWIT_ItemDetailTable 
				 WHERE Serialno =   @Serialno   
		 
				 ) t
				 PIVOT
				 (
					min(DetailValueN)
					FOR DetailKey IN (   
											PartName
										  , Specs
									 )
				) AS pivot_table
 
				DELETE FROM #TEMP_TOOLS
				WHERE   CategoryId IS NULL
  
				INSERT INTO APCSProDB_TEST.trans.jigs
				(
						  qrcodebyuser
						, status
						, jig_production_id
						, in_quantity
						, quantity
						, is_production_usage
						, jig_state
						, process_state
						, qc_state
						, created_at
						, created_by
				)
				SELECT     #TEMP_TOOLS.Serialno		AS qrcodebyuser 
						, 'To Machine'				AS status 
						, productions.id			AS jig_production_id  
						, 0							AS in_quantity
						, 0							AS quantity
						, 0							AS is_production_usage
						, 11						AS jig_state
						, 1							AS process_state
						, 0							AS qc_state
						, GETDATE()					AS created_at
						, 1							AS created_by
				FROM #TEMP_TOOLS
				INNER JOIN APCSProDB_TEST.jig.categories
				ON  PartName = categories.name
				INNER JOIN APCSProDB_TEST.jig.productions
				ON #TEMP_TOOLS.Specs = productions.name
				AND productions.category_id = (SELECT TOP 1 id FROM APCSProDB_TEST.jig.categories WHERE PartName =  categories.name )
				WHERE #TEMP_TOOLS.PartName =  categories.name AND #TEMP_TOOLS.Specs = productions.name

				DELETE FROM  #TEMP_TOOLS
				SET @Counter  = @Counter  + 1
				PRINT @Counter

			END
			DROP TABLE #SERIAL_TOOLS
			DROP TABLE #TEMP_TOOLS

	END
END
