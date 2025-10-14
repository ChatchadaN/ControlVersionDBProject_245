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

CREATE  PROCEDURE [jig].[sp_get_data_root]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id		INT		= NULL
	    , @root_jig_id		INT		= NULL
		, @category_name	NVARCHAR(MAX) = NULL
)
AS
BEGIN
	SET NOCOUNT ON;
	
		SELECT	  ID
				, PartType
				, qrcodebyuser AS basename
				, partname
				, BaseType
				, CAST(LifeTime AS INT) AS LifeTime
				, CAST(STDLifeTime AS INT)  AS STDLifeTime
				, process_id
				, root_jig_id
		FROM  ( SELECT    ID
						, Status
						, PartType
						, qrcodebyuser AS partname
						, ( SELECT jigs.qrcodebyuser  
							FROM APCSProDB.trans.jigs 
							INNER JOIN APCSProDB.jig.productions 
							ON jigs.jig_production_id = productions.id 
							INNER JOIN APCSProDB.jig.categories 
							ON productions.category_id = categories.id 
							WHERE (jigs.id = DefaultData.root_jig_id)
						  ) AS qrcodebyuser
						, ( SELECT productions_2.name AS SubType 
							FROM APCSProDB.trans.jigs AS jigs_2 
							INNER JOIN APCSProDB.jig.productions AS productions_2 
							ON jigs_2.jig_production_id = productions_2.id 
							INNER JOIN APCSProDB.jig.categories AS categories_2 
							ON productions_2.category_id = categories_2.id 
							WHERE (jigs_2.id = DefaultData.root_jig_id)
						  ) AS BaseType
						,value AS LifeTime
						, alarm_value AS STDLifeTime 
						,root_jig_id
						,process_id
				FROM ( SELECT  jigs_1.id AS ID
							 , jigs_1.qrcodebyuser AS qrcodebyuser
							 , jigs_1.status AS Status
							 , productions_1.name AS BaseType 
							 , productions_1.name AS PartType
							 , jigs_1.root_jig_id
							 , jig_conditions.value AS  value
							 , CASE WHEN ISNULL(production_counters.alarm_value,0) = 0  THEN jigs_1.quantity ELSE production_counters.alarm_value END AS  alarm_value
							 , categories_1.lsi_process_id  AS process_id 
						FROM APCSProDB.trans.jigs AS jigs_1 
						LEFT  JOIN  APCSProDB.trans.jig_conditions 
						ON jigs_1.id = jig_conditions.id 
						INNER JOIN  APCSProDB.jig.productions AS productions_1 
						ON jigs_1.jig_production_id = productions_1.id 
						INNER JOIN APCSProDB.jig.production_counters
						ON productions_1.id =  production_counters.production_id
						INNER JOIN  APCSProDB.jig.categories AS categories_1 
						ON productions_1.category_id = categories_1.id 
						WHERE (categories_1.name = @category_name)
					 ) AS DefaultData
		) AS RootData 
		WHERE ( RootData.root_jig_id = @root_jig_id ) 
		ORDER BY ID DESC

		 
END
