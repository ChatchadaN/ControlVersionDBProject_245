------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_get_sample]
 
	@production_name AS NVARCHAR(100) =  NULL
 
AS
BEGIN
	SET NOCOUNT ON;

		 SELECT    IIF(limit_date <= DATEADD(MONTH,-1,GETDATE()),0,1) AS is_expire
				, jigs.id  AS jig_id 
				, jigs.barcode
				, productions.id AS productions_id 
				, productions.name as SubType
				, smallcode
				, categories.name as Type
				, categories.id		AS categories_id
				, productions.expiration_base
				, ISNULL(item_labels.label_eng,'')  expiration_unit
				, CONVERT(varchar(max),jigs.created_at,111) AS created_at
				, CONVERT(varchar(max),jigs.limit_date,111) AS limit_date 
				, [status]
				, ISNULL(locations.name,'') AS location_name 
				, CASE WHEN jigs.jig_state = 11 then machines.name else NULL end AS MCNo
				, jigs.jig_state 
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
		LEFT JOIN  APCSProDB.jig.item_labels  
		ON productions.expiration_unit = item_labels.val
		AND  item_labels.[name] = 'productions.expiration_unit'
		LEFT JOIN  APCSProDB.jig.locations 
		ON locations.id = jigs.location_id 
		WHERE category_id =  93
		AND ( productions.[name]  LIKE @production_name+'%' OR @production_name IS NULL)
 

  
END
