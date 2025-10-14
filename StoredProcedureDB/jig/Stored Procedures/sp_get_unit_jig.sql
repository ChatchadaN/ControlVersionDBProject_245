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

CREATE  PROCEDURE [jig].[sp_get_unit_jig]
(	 
		 @param  INT = NULL  
		 , @process_id   INT = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	IF(@param =  1)
	BEGIN 
		SELECT	  categories.id
				, ISNULL(categories.name,'')		AS name
				, processes.id						AS process_id
				, ISNULL(processes.name,'')			AS process_name 
				, ISNULL(categories.short_name,'')	AS Shot_name
				, ISNULL(lifetime_unit,'')			AS unit   
		FROM APCSProDB.method.processes  
		INNER JOIN APCSProDB.jig.categories 
		ON processes.id = categories.lsi_process_id  
		WHERE processes.id = @process_id
		ORDER BY  processes.id ASC
	END
	IF(@param =  2)
	BEGIN
		SELECT	  val		AS id 
				, label_eng AS name
		FROM APCSProDB.jig.item_labels
		WHERE name =  'categories.lifetime_unit'

	END
	IF(@param =  3)
	BEGIN

		SELECT		  processes.id 
					, processes.name 
		FROM  APCSProDB.method.processes
		LEFT JOIN APCSProDB.jig.categories
		ON categories.lsi_process_id =  processes.id 
		GROUP BY   processes.id , processes.name 
	END
	IF(@param =  4)
	BEGIN
		SELECT	  val		AS id 
				, label_eng AS name
		FROM APCSProDB.jig.item_labels
		WHERE name =  'productions.expiration_unit'
	END
	IF(@param =  5)
	BEGIN
		SELECT   [val]			AS id 
				,[label_eng]	AS name
		FROM [APCSProDB].[trans].[item_labels]
		WHERE name = 'jig_records.comment'
	END
	IF(@param = 6)
	BEGIN
		SELECT   [val]			AS id 
				,[label_eng]	AS name
		FROM [APCSProDB].[trans].[item_labels]
		WHERE name = 'jigs.jig_state'

	END
END
