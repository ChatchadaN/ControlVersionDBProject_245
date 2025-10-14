------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Author Name              : Sadanun.B
-- Written Date             : 2022/01/07
-- Procedure Name 	 		: [jig].[sp_get_production]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_get_data_jig]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id		INT				= NULL
		, @SmallCode		NVARCHAR(4)		= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

		SELECT	  jigs.id
				, jigs.barcode				AS QRCode
				, jigs.smallcode			AS SmallCode
				, categories.name			AS TypeName
				, productions.name			AS SubTypeName
				, collet_recipes.collet_no	AS collet_no
		FROM APCSProDB.trans.jigs 
		INNER JOIN  APCSProDB.jig.productions 
		ON jigs.jig_production_id	= productions.id 
		INNER JOIN  APCSProDB.jig.categories 
		ON productions.category_id	= categories.id 
		INNER JOIN  APCSProDB.jig.collet_recipes 
		ON productions.id			= collet_recipes.production_id  
		WHERE jigs.smallcode		=  @SmallCode
		AND categories.lsi_process_id = @process_id
		 

END
