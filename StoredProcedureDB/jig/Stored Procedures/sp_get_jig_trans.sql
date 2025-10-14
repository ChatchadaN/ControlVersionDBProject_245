------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Author Name              : Sadanun.B
-- Written Date             : 2022/01/07
-- Procedure Name 	 		: [jig].[sp_get_production]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_get_jig_trans]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @id 					INT				= NULL
		, @production_id 		INT				= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	 
 SELECT    jigs.id  AS jig_id 
			, jigs.barcode
			, jigs.qrcodebyuser
			, productions.id AS productions_id 
			, productions.name as SubType
			, smallcode
			, categories.name as Type
			, categories.id		AS categories_id
			, jig_conditions.periodcheck_value  AS PeriodCheckTime
			, value AS LifeTime
			, production_counters.warn_value  AS STDPeriodCheckTime
			, production_counters.alarm_value  AS STDLifeTime
			, jig_conditions.accumulate_lifetime AS AccumulateLifeTime
			, ISNULL(status,'') AS  [Status]
			, jigs.location_id
			, categories.lsi_process_id   AS process_id
			, CASE WHEN jigs.jig_state = 11 then ISNULL(machines.name,'') else '' end AS MCNo
			, jigs.jig_state 
			, jigs.root_jig_id
			, jigs.quantity
			, jigs.in_quantity
	FROM APCSProDB.trans.jigs 
	INNER JOIN APCSProDB.trans.jig_conditions 
	ON jig_conditions.id = jigs.id 
	INNER JOIN APCSProDB.jig.productions 
	ON productions.id = jigs.jig_production_id 
	INNER JOIN APCSProDB.jig.production_counters 
	ON production_counters.production_id = productions.id 
	INNER JOIN APCSProDB.jig.categories 
	ON categories.id = productions.category_id 
	LEFT JOIN  APCSProDB.trans.machine_jigs 
	ON machine_jigs.jig_id = jigs.id 
	LEFT JOIN  APCSProDB.mc.machines 
	ON machines.id = machine_jigs.machine_id 
	LEFT JOIN  APCSProDB.jig.comments  
	ON comments.id = jigs.qc_comment_id
	LEFT JOIN APCSProDB.jig.locations 
	ON jigs.location_id = locations.id
	WHERE jigs.jig_state <> 14  
	AND ((jigs.id  = @id  OR @id IS NULL )
	AND (jigs.jig_production_id = @production_id OR @production_id IS NULL ))
	 
END
