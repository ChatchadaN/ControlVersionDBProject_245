------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Author Name              : Sadanun.B
-- Written Date             : 2023/01/05
-- Procedure Name 	 		: [jig].[jigs]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.jigs
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_get_categories_byqrcodebyuser]
(	 
		 @qrcodebyuser			NVARCHAR(50)		= NULL ,
		 @process_id			INT					 =  NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	 	SELECT	TOP 1		  productions.id AS productions_id
						, categories.name 
						, categories.id  AS categories_id
						, categories.lsi_process_id AS process_id
			FROM APCSProDB.trans.jigs 
			INNER JOIN APCSProDB.jig.productions 
			ON jigs.jig_production_id	= productions.id 
			INNER JOIN APCSProDB.jig.categories 
			ON productions.category_id	= categories.id 
			WHERE   jigs.qrcodebyuser			= @qrcodebyuser
			AND (categories.lsi_process_id 		=   @process_id OR  @process_id IS NULL)
END
