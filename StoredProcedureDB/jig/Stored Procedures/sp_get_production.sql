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

CREATE  PROCEDURE [jig].[sp_get_production]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		 @id		INT		= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

		 SELECT  productions.id AS productions_id
		, productions.name AS SubType
		, productions.spec	AS spec
		, ISNULL(production_counters.alarm_value, 0) AS STDLifeTime
		, ISNULL(production_counters.period_value,0) AS [Period]
		, ISNULL(production_counters.warn_value,0) AS warn_value
		, (case when ( productions.expiration_value > 0) and ( production_counters.warn_value > 0) then 100 - FLOOR( production_counters.warn_value * 100 /  productions.expiration_value) else 0 end) AS SafetyPoint
		, (case when ( productions.expiration_value > 0) and ( production_counters.warn_value > 0) then FLOOR(( productions.expiration_value -  production_counters.warn_value) ) else 0 end) AS SafetyPointKPieces 
		, categories.name AS Type
		, processes.id  AS process_id, processes.name AS process_name
		, ISNULL(productions.is_disabled,1) AS is_disabled
		, production_counters.production_id  AS counters_id
		, pack_std_qty
		, unit_code
		, item_labels.label_eng AS unit
		, arrival_std_qty	
		, min_order_qty	
		, lead_time	
		, lead_time_unit	
		, label_issue_qty	
		, expiration_base	 AS expiration_base
		, productions.expiration_unit AS expiration_unit_
		, item_labels_expir.label_eng AS expiration_unit
		, categories.short_name
		, productions.category_id AS category_id
		FROM APCSProDB.jig.productions 
		LEFT JOIN APCSProDB.jig.production_counters 
		ON  productions.id = production_counters.production_id 
		INNER JOIN APCSProDB.jig.categories 
		ON productions.category_id = categories.id 
		LEFT JOIN APCSProDB.method.processes  
		ON processes.id = categories.lsi_process_id 
		LEFT  JOIN APCSProDB.jig.item_labels
		ON productions.unit_code =  item_labels.val
		AND item_labels.name = 'categories.lifetime_unit'
		LEFT  JOIN APCSProDB.jig.item_labels AS item_labels_expir
		ON productions.expiration_unit =  item_labels_expir.val
		AND item_labels_expir.name = 'productions.expiration_unit'
		WHERE  ( productions.category_id  =  @id   OR ISNULL(@id,'') =  '')
		AND productions.is_disabled = 0 AND counter_no =  1
		ORDER BY productions.id ASC

END
