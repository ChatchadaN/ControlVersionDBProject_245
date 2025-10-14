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

CREATE  PROCEDURE [jig].[sp_get_production_details]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		 @id		INT		= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	 SELECT *
 FROM (
		 SELECT  productions.id AS productions_id
		, productions.name AS SubType
		, productions.spec AS spec
		, ISNULL(production_counters.alarm_value, productions.expiration_value ) AS STDLifeTime
		, ISNULL(production_counters.period_value,0) AS [Period]
		, production_counters.warn_value
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
		, expiration_base AS expiration_base	
		, expiration_unit
		, categories.short_name
		FROM APCSProDB.jig.productions 
		LEFT JOIN APCSProDB.jig.production_counters 
		ON  productions.id = production_counters.production_id 
		INNER JOIN APCSProDB.jig.categories 
		ON productions.category_id = categories.id 
		INNER JOIN APCSProDB.method.processes  
		ON processes.id = categories.lsi_process_id 
		LEFT  JOIN APCSProDB.jig.item_labels
		ON productions.unit_code =  item_labels.val
		WHERE  ( productions.id  =  @id   OR @id IS NULL)
		AND productions.is_disabled = 0
		) AS T1
	OUTER APPLY
	(
		SELECT [1] AS Package
		,  (SELECT TOP 1 id  FROM APCSProDB.method.packages WHERE name =[1]  ORDER BY id) AS Package_id  
		, [2] AS Device 
		, (SELECT TOP 1 id FROM APCSProDB.method.device_names WHERE ft_name = [2]  ORDER BY id ) AS Device_id
		, [3] AS Flow 
		, (SELECT TOP 1 id  FROM APCSProDB.method.jobs WHERE name = [3] ORDER BY id)   AS Flow_id
		FROM   
						(
							SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(T1.SubType,',') 

						) t 
						PIVOT
						(
							MAX([value])
							FOR row_num IN (
									[1] 
								,[2]
								,[3]
								)
						) AS pivot_table 

	) AS T2

END