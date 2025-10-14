------------------------------ Creater Rule ------------------------------
-- Project Name				: jig 
-- Written Date             : 2023/01/05
-- Procedure Name 	 		: [jig].[jigs]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.jigs
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_get_dicer_blade]
(	 
		  @qrcodebyuser		NVARCHAR(100)		= NULL
		  , @process_id		INT					= NULL
)
AS
BEGIN
	SET NOCOUNT ON;


	SELECT   jigs.id							AS ID
			,ISNULL(jigs.qrcodebyuser,'')		AS qrcodebyuser
			,ISNULL(jigs.status,'')				AS [Status]
			,ISNULL(productions.name,'')		AS [DicerType]
			,ISNULL(categories.name,'')			AS [Type]
			,categories.id						AS categories_id 
			,categories.lsi_process_id			AS process_id 
			,jigs.jig_production_id				AS production_id 
			,ISNULL(locations.name,'')			AS [location]
	FROM APCSProDB.trans.jigs 
	INNER JOIN APCSProDB.jig.productions 
	ON jigs.jig_production_id		= productions.id 
	INNER JOIN APCSProDB.jig.categories 
	ON productions.category_id		= categories.id 
	LEFT JOIN APCSProDB.jig.locations
	ON locations.id  =  jigs.location_id
	WHERE (categories.short_name	= 'Dicer Blade') 
	AND jigs.qrcodebyuser			= @qrcodebyuser
	AND categories.lsi_process_id	= @process_id OR @process_id IS NULL 
	AND root_jig_id IS NULL
	ORDER BY ID DESC
		 
END
