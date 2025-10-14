------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Procedure Name 	 		: [jig].[sp_get_categories]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_get_tsukiage_chipsize]
 
AS
BEGIN
	SET NOCOUNT ON;

			 SELECT   tsukiage_chipsizes.id
					, ISNULL(tsukiage_chipsizes.ymin,0)	AS ymin
					, ISNULL(tsukiage_chipsizes.ymax,0)	AS ymax
					, ISNULL(tsukiage_chipsizes.xmin,0)	AS xmin
					, ISNULL(tsukiage_chipsizes.xmax,0)	AS xmax
					, ISNULL(tsukiage_chipsize_recipes.tsukiage_no,0) AS tsukiage_no
			FROM [APCSProDB].jig.tsukiage_chipsizes 
			LEFT JOIN [APCSProDB].jig.tsukiage_chipsize_recipes 
			ON tsukiage_chipsizes.id = tsukiage_chipsize_recipes.tsukiage_chipsize_id 
			ORDER BY ymin,xmin	 

END
 