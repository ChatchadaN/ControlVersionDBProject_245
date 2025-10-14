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

CREATE  PROCEDURE [jig].[sp_get_kanagata_part_dd]
(	 
		    @name			NVARCHAR(MAX)		= NULL
		  , @process_id		INT					= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	IF(@process_id	= 8)
		BEGIN

		  SET @name  = (SELECT TOP 1 * FROM STRING_SPLIT(@name,'/'))

			SELECT		  productions.id AS productions_id
						, productions.name 
						, categories.id  AS categories_id
						, categories.lsi_process_id AS process_id
			FROM APCSProDB.jig.categories 
			INNER JOIN APCSProDB.jig.productions ON categories.id = productions.category_id 
			WHERE	(categories.lsi_process_id = @process_id) 
			AND		(categories.name = 'Kanagata Part') 
			AND		productions.name  LIKE '%'+ @name +'%' 
			ORDER BY productions.name ASC

		END 
	
	ELSE 
	BEGIN 

		SELECT		  productions.id AS productions_id
						, productions.name 
						, categories.id  AS categories_id
						, categories.lsi_process_id AS process_id
			FROM APCSProDB.jig.categories 
			INNER JOIN APCSProDB.jig.productions ON categories.id = productions.category_id 
			WHERE	(categories.lsi_process_id = @process_id) 
			AND		(categories.name = 'Kanagata Part') 
			AND		productions.name  LIKE '%'+ @name +'%' 
			ORDER BY productions.name ASC
	END

END
