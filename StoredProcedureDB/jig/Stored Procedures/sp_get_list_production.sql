------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Written Date             : 2022/01/07
-- Procedure Name 	 		: [jig].[sp_get_production]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_get_list_production]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id		INT			 
		, @categories_id	INT				= NULL
		, @production_id	INT				= NULL 
)
AS
BEGIN
	SET NOCOUNT ON;

		SELECT    SubType 
				, Type
				, SUM(CASE WHEN jig_state = 1 THEN 1 ELSE 0 end) AS Regist
				, SUM(CASE WHEN jig_state = 2   THEN 1 ELSE 0 end ) AS Store
				, SUM(CASE WHEN jig_state = 11 
					 THEN 1 ELSE 0 end )AS Inprocess 
				, SUM(CASE WHEN jig_state = 13 THEN 1 ELSE 0 end) AS Scrap
				, SUM(CASE WHEN jig_state = 5 THEN 1 ELSE 0 end) AS Borrow
				, SUM(CASE WHEN jig_state in (8,9) THEN 1 ELSE 0 end) AS Clean
				, SUM(CASE WHEN jig_state <> 14 THEN 1 ELSE 0 end) AS Total
				, SUM(CASE WHEN jig_state = 14 THEN 1 ELSE 0 end) AS Scraped
				, SUM(CASE WHEN jig_state = 12 THEN 1 ELSE 0 end) AS OnMachine
				, SUM(CASE WHEN jig_state in (13,14) THEN 0 ELSE STDLifeTime-LifeTime end) AS Capacity
				, production_id
				, categories_id
				, process_name
				, process_id
		FROM
		(
			SELECT    jigs.id
				    , productions.name AS SubType
					, categories.name AS Type
					, jig_state
					, categories.id  AS categories_id
					, locations.name AS Location
					, (value/1000)AS LifeTime
					, (production_counters.alarm_value) AS STDLifeTime
					, (SELECT COUNT(*) FROM APCSProDB.trans.jig_records WHERE transaction_type = 'Clean' AND jig_id = jigs.id) AS Clean
					, productions.id AS production_id
					, processes.name AS  process_name
					, categories.lsi_process_id AS process_id
			FROM APCSProDB.trans.jigs
			INNER JOIN APCSProDB.trans.jig_conditions 
			on jig_conditions.id			= jigs.id
			INNER JOIN APCSProDB.jig.productions 
			on jigs.jig_production_id		= productions.id
			LEFT JOIN APCSProDB.jig.production_counters 
			ON  productions.id = production_counters.production_id 
			INNER JOIN APCSProDB.jig.categories 
			on categories.id				= productions.category_id
			LEFT  JOIN APCSProDB.jig.locations 
			on jigs.location_id				= locations.id
			INNER JOIN APCSProDB.method.processes
			ON categories.lsi_process_id	= processes.id 
			WHERE production_counters.counter_no =  1 
			AND productions.is_disabled  = 0
			AND  categories.lsi_process_id = @process_id
			AND (categories.id				= @categories_id OR @categories_id IS NULL)
		) AS c
 WHERE	(production_id = @production_id	 OR @production_id IS NULL ) 
 --AND	(categories_id = @categories_id  OR @categories_id IS NULL)
 GROUP BY     SubType 
			, Type 
			, production_id
			, categories_id
			, process_name
			, process_id

END
