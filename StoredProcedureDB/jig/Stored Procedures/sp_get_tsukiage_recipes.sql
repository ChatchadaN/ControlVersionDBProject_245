
------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Procedure Name 	 		: [jig].[sp_get_categories]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_get_tsukiage_recipes]
 
AS
BEGIN
	SET NOCOUNT ON;
	 
		SELECT    tsukiage_recipes.id
				, productions.name
				, tsukiage_recipes.tsukiage_no
				, tsukiage_recipes.machine_type 
				, production_id
		FROM  APCSProDB.jig.tsukiage_recipes 
		INNER JOIN  APCSProDB.jig.productions 
		ON  tsukiage_recipes.production_id =  productions.id 
		ORDER BY productions.name
		, tsukiage_recipes.tsukiage_no ASC


END
 
