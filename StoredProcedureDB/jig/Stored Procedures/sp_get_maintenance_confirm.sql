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

CREATE  PROCEDURE [jig].[sp_get_maintenance_confirm]
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
	 
 
		SELECT	 jig_records_id	AS jig_records_id
				 , jig_id
				 , smallcode 
			     , productions_name 
			     , categories_name 
				 , CASE WHEN TransactionType = 'Stock' THEN 
				 	CASE WHEN locations.name Like 'FL-F%' THEN 'INP' ELSE 'Store' END WHEN TransactionType ='Stock NG' THEN 
				 	CASE WHEN locations.name Like 'FL-F%' THEN 'INP NG' ELSE 'Store' END ELSE TransactionType END AS TransactionType 
				 , TransactionDate AS TransactionDate
				 , UserID
				 , CASE WHEN binary_file IS NOT NULL THEN 1 ELSE 0 END binary_file 
				 , ISNULL(locations.name +','+y+','+x,'')  AS STORAGE
				 , ISNULL(MCNo ,'' ) AS MCNo
			     , ISNULL(lot_no,'')  AS lot_no
				 , barcode
				 , record_at
		FROM	 (SELECT 	jig_records.id	AS jig_records_id
				      , jig_records.jig_id
				 	 , smallcode
				 	 , productions.id		AS productions_id
				 	 , productions.name		AS productions_name
				 	 , categories.name		AS [categories_name]
					 , categories.id		AS [categories_id]
				 	 , transaction_type		AS TransactionType
				 	 , CONVERT(VARCHAR(20),record_at,20)  AS TransactionDate
				 	 , operated_by AS UserID 
					 , (CASE WHEN transaction_type = 'To Machine' THEN machines.name ELSE NULL END) AS MCNo
				 	 , binary_data.binary_file
				 	 , jig_records.location_id
				 	 , categories.lsi_process_id
				 	 , jig_records.lot_no
				 	 , jigs.barcode
				 	 , jig_records.record_at
				 FROM  APCSProDB.trans.jig_records 
				 INNER JOIN  APCSProDB.trans.jigs 
				 ON  jig_records.jig_id =  jigs.id
				 LEFT JOIN APCSProDB.trans.machine_jigs 
				 ON machine_jigs.jig_id = jigs.id
				 LEFT JOIN APCSProDB.mc.machines 
				 ON machines.id = machine_jigs.machine_id
				 INNER JOIN APCSProDB.trans.jig_conditions 
				 ON  jigs.id =  jig_conditions.id 
				 INNER JOIN APCSProDB.jig.productions 
				 ON  jigs.jig_production_id = productions.id 
				 INNER JOIN APCSProDB.jig.categories 
				 ON  productions.category_id =  categories.id 
				 LEFT OUTER JOIN APCSProDB.jig.locations 
				 ON  jig_records.location_id =  locations.id 
				 LEFT OUTER JOIN APCSProDB.trans.binary_data 
				 ON binary_data.id = jig_records.id
				 LEFT JOIN ( SELECT jig_id,location_id FROM APCSProDB.trans.jig_records 
				 			WHERE ID IN (select max(ID) FROM APCSProDB.trans.jig_records WHERE location_id IS NOT NULL GROUP BY jig_id)
				 			) AS Storage 
				 ON jig_records.jig_id = Storage.jig_id
				 WHERE binary_data1 IS NOT NULL 
				 AND comment IS NULL 
				 AND transaction_type IN ('Clean','Repair') 
				 AND categories.short_name = 'Socket'  
		) AS a 
		LEFT JOIN APCSProDB.jig.locations 
		on a.location_id = locations.id
		WHERE  a.lsi_process_id = @process_id
		AND (productions_id		= @production_id  OR @production_id IS NULL ) 
		AND (categories_id		= @categories_id  OR @categories_id IS NULL ) 
		AND (record_at BETWEEN  @Date AND @ToDate )
		ORDER BY TransactionDate DESC

 
 
END
