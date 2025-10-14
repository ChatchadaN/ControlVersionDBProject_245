------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Procedure Name 	 		: [jig].[sp_get_categories]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_get_collet_chipsize]
 
AS
BEGIN
	SET NOCOUNT ON;

		SELECT     chipsizes.id
				,  chipsizes.ymin
				,  chipsizes.ymax
				,  chipsizes.xmin
				,  chipsizes.xmax
				,  ISNULL(rubber_no, '' ) AS rubber_no
		FROM APCSProDB.jig.chipsizes 
		LEFT JOIN APCSProDB.jig.collet_chipsize_recipes 
		ON chipsizes.id =  collet_chipsize_recipes.chipsize_id 
	 
END
 