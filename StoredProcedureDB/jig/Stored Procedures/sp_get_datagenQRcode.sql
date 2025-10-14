------------------------------ Creater Rule ------------------------------
-- Project Name				: jig 
-- Written Date             : 2022/01/07
-- Procedure Name 	 		: [jig].[sp_get_production]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_get_datagenQRcode]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		 @process_id	INT				= NULL
	   , @smallcode		NVARCHAR(100)   = NULL
	   , @production_id	INT				= NULL
	   , @amount		INT				= NULL
 
)
AS
BEGIN
	SET NOCOUNT ON;

	IF (@amount <  2 )
	BEGIN 
		 SELECT   processes.id		AS process_id
				, processes.name	AS process_name
				, jigs.id			AS jig_id
				, jigs.barcode		AS barcode
				, jigs.smallcode	AS SmallCode
				, categories.name	AS TypeName
				, categories.short_name	AS Short_name
				, productions.name	AS SubTypeName   
				, ISNULL(qc_comment_id,'')		AS MakerId
				, ISNULL(jigs.qrcodebyuser,'') AS qrcodebyuser
				, COALESCE(collet_recipes.collet_no ,tsukiage_recipes.tsukiage_no,'') AS collet_no
		 FROM APCSProDB.trans.jigs
		 INNER JOIN APCSProDB.jig.productions 
		 ON  jigs.jig_production_id = productions.id
		 INNER JOIN APCSProDB.jig.categories 
		 ON productions.category_id = categories.id
		 INNER JOIN  APCSProDB.method.processes
		 ON processes.id	= categories.lsi_process_id
		 LEFT JOIN   APCSProDB.jig.collet_recipes 
		 ON  productions.id		=   collet_recipes.production_id 
		 LEFT JOIN APCSProDB.jig.tsukiage_recipes 
		 ON productions.id =  tsukiage_recipes.production_id
		 WHERE (jigs.smallcode			= @smallcode 
		 OR jigs.qrcodebyuser			= @smallcode 
		 OR jigs.barcode				= @smallcode
		 )
		 AND categories.lsi_process_id	= @process_id  OR @process_id IS NULL 

	END 
	ELSE
	BEGIN 
		 SELECT  TOP(@amount) processes.id		AS process_id
				, processes.name	AS process_name
				, jigs.id			AS jig_id
				, jigs.barcode		AS barcode
				, jigs.smallcode	AS SmallCode
				, categories.name	AS TypeName
				, categories.short_name	AS Short_name
				, productions.name	AS SubTypeName   
				, ISNULL(qc_comment_id,'')		AS MakerId
				, ISNULL(jigs.qrcodebyuser,'') AS qrcodebyuser
				, COALESCE(collet_recipes.collet_no ,tsukiage_recipes.tsukiage_no,'') AS collet_no
		 FROM APCSProDB.trans.jigs
		 INNER JOIN APCSProDB.jig.productions 
		 ON  jigs.jig_production_id = productions.id
		 INNER JOIN APCSProDB.jig.categories 
		 ON productions.category_id = categories.id
		 LEFT  JOIN  APCSProDB.method.processes
		 ON processes.id	= categories.lsi_process_id
		 LEFT JOIN   APCSProDB.jig.collet_recipes 
		 ON  productions.id			=   collet_recipes.production_id 
		  LEFT JOIN APCSProDB.jig.tsukiage_recipes 
		 ON productions.id =  tsukiage_recipes.production_id
		 WHERE  productions.id		= @production_id
		 ORDER BY jigs.id DESC

	END 

END
