------------------------------ Creater Rule ------------------------------
-- Project Name				: jig 
-- Procedure Name 	 		: [jig].[sp_get_production]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_get_list_jig]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id		INT				= NULL
		, @SmallCode		NVARCHAR(4)		= NULL
		, @QRCode			NVARCHAR(4)		= NULL
		, @production_id	INT				
		, @categories_id	INT				 
		, @Location			NVARCHAR(MAX)	= NULL
		, @MCNo				NVARCHAR(MAX)	= NULL
		, @Status			NVARCHAR(MAX)	= NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	 
		
SELECT   ROW_NUMBER() OVER(ORDER BY CASE WHEN status != 'Store' THEN 1 ELSE 2 END , SmallCode) AS [Index]
		,  jigs.id  AS jig_id 
						, jigs.barcode
						, jigs.qrcodebyuser
						, productions.id AS productions_id 
						, productions.name as SubType
						, smallcode
						, categories.name as Type
						, categories.id		AS categories_id
						, jig_conditions.periodcheck_value  AS PeriodCheckTime
						, [value] AS [LifeTime]
						, ISNULL(production_counters.period_value,0) AS STDPeriodCheckTime
						, production_counters.alarm_value  AS STDLifeTime
						, jig_conditions.accumulate_lifetime AS AccumulateLifeTime
						, [status]
						, ISNULL(locations.name + ',' + y + ',' + x ,'') AS Storage
						, jigs.location_id
						, categories.lsi_process_id   AS process_id
						, CASE WHEN jigs.jig_state = 12 then machines.name else NULL end AS MCNo
						, comments.val as Maker
						, jigs.jig_state 
				, fixed_assets.fixed_asset_num     AS fixed_asset_num
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
				ON locations.id  =  jigs.location_id
				LEFT JOIN APCSProDB.jig.fixed_assets
				ON jigs.id  = fixed_assets.jig_id
		WHERE  jigs.jig_production_id	= @production_id
		AND     categories.lsi_process_id		= @process_id 
		AND   categories.id		= @categories_id   

END
