
------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Procedure Name 	 		: [jig].[sp_get_categories]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_get_collet_recipes]
 
AS
BEGIN
	SET NOCOUNT ON;

	

		SELECT	  collet_recipes.id
				, productions.[name]
				, collet_recipes.collet_no
				, collet_recipes.machine_type 
				, collet_recipes.production_id
		FROM APCSProDB.jig.collet_recipes 
		INNER JOIN APCSProDB.jig.productions 
		ON APCSProDB.jig.collet_recipes.production_id = productions.id 
		ORDER BY collet_no

END
 
