------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Written Date             : 2025/01/08
-- Procedure Name 	 		: [jig].[sp_get_socket_history]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_get_maintenance_report]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id		INT			 
		, @categories_id	INT				= NULL
		, @production_id	INT				= NULL 
		, @Barcode			NVARCHAR(10)	= NULL 
		, @Date				DATETIME		= NULL
		, @ToDate			DATETIME		= NULL
)
AS
BEGIN

	SET NOCOUNT ON;
	 
 
		SELECT     jig_records_id	AS jig_records_id
				 , jig_id
				 , smallcode 
			     , productions_name 
			     , categories_name 
				 , CASE WHEN TransactionType = 'Stock' THEN 
			 		CASE WHEN locations.name LIKE 'FT-F%' THEN 'INP' WHEN locations.name LIKE 'FT-H%' THEN 'Stock H' ELSE TransactionType END 
					WHEN TransactionType ='Stock NG' THEN 
			 		CASE WHEN locations.name LIKE 'FT-F%' THEN 'INP NG' ELSE TransactionType END 
					ELSE TransactionType END AS TransactionType 
				 , TransactionDate AS TransactionDate
				 , UserID
				  , CASE WHEN binary_file IS NOT NULL THEN 1 ELSE 0 END binary_file 
				 , ISNULL(MCNo ,'' ) AS MCNo
				 , (CASE WHEN TransactionType in ('Stock','Stock NG') THEN locations.name + '-' + y + '-' + x ELSE '' END) AS STORAGE
				 , ISNULL(lot_no,'')  AS lot_no
				 , barcode
				 , record_at
		FROM ( SELECT     jig_records.id						AS jig_records_id
				        , jig_records.jig_id
				 		, smallcode
				 		, productions.id						AS productions_id
				 		, productions.name						AS productions_name
				 		, categories.name						AS [categories_name]
						, categories.id							AS [categories_id]
						, transaction_type						AS TransactionType
						, CONVERT(VARCHAR(20),record_at,20)		AS TransactionDate
						, operated_by							AS UserID
						, binary_data.binary_file
						, (CASE WHEN transaction_type = 'To Machine' THEN machines.name ELSE NULL END) AS MCNo
						, CASE WHEN binary_data1 IS NOT NULL THEN 1 ELSE 0 END AS hasImage
						, jig_records.location_id
						, categories.lsi_process_id
						, jig_records.lot_no
				 		, jigs.barcode
				 		, jig_records.record_at
		FROM APCSProDB.trans.jigs
			LEFT JOIN APCSProDB.trans.machine_jigs 
			ON machine_jigs.jig_id = jigs.id
			LEFT JOIN APCSProDB.mc.machines 
			ON machines.id = machine_jigs.machine_id
			INNER JOIN APCSProDB.trans.jig_records 
			ON jig_records.jig_id = jigs.id
			INNER JOIN APCSProDB.trans.binary_data 
			ON binary_data.id = jig_records.id
			INNER JOIN APCSProDB.jig.productions 
			ON productions.id = jigs.jig_production_id 
			INNER JOIN APCSProDB.jig.categories 
			ON categories.id = productions.category_id 
		) AS a 
			LEFT JOIN APCSProDB.jig.locations 
			ON a.location_id = locations.id 
			WHERE  a.lsi_process_id = @process_id
			AND (productions_id		= @production_id  OR @production_id IS NULL ) 
			AND (categories_id		= @categories_id  OR @categories_id IS NULL ) 
			AND (record_at BETWEEN  @Date AND @ToDate )
		ORDER BY TransactionDate DESC

 
 
END
