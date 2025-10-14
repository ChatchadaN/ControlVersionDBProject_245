------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Procedure Name 	 		: [jig].[sp_get_categories]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_get_categories]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		@process_id		INT  = NULL
		, @id			INT	 = NULL
	 
)
AS
BEGIN
	SET NOCOUNT ON;

		 SELECT    processes.id  AS process_id
				 , processes.name  AS process_name
				 , categories.id  AS id
				 , categories.name AS name
				 , categories.short_name 
				 , categories.lifetime_unit
				 , item_labels.val  labels_unit
		FROM  APCSProDB.jig.categories 
		LEFT JOIN APCSProDB.method.processes  
		ON processes.id		= categories.lsi_process_id 
		LEFT JOIN APCSProDB.jig.item_labels
		ON lifetime_unit =  label_eng
		AND item_labels.name = 'categories.lifetime_unit'
		WHERE ((processes.id  =  @process_id OR ISNULL(@process_id,'') =  '')
		AND (categories.id  = @id OR @id IS NULL) )
 

END
