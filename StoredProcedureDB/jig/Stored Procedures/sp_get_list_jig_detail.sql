------------------------------ Creater Rule ------------------------------
-- Project Name				: jig 
-- Written Date             : 2023/05/07
-- Procedure Name 	 		: [jig].[sp_get_production]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_get_list_jig_detail]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @process_id		INT				= NULL
		, @production_id	INT				= NULL 
		, @categories_id	INT				= NULL 
		, @Date				DATETIME		= NULL 
		, @ToDate			DATETIME		= NULL 
)
AS
BEGIN
	SET NOCOUNT ON;


 	  SELECT		  jig_records.id									AS jig_records_id
					, jigs.id											AS jig_id
					, ISNULL(qrcodebyuser,'')							AS qrcodebyuser
					, ISNULL(jigs.smallcode,'')							AS smallcode
					, ISNULL(productions.id,'')							AS productions_id
					, ISNULL(productions.name,'')						AS productions_name
					, ISNULL(categories.id,'')							AS categories_id
					, ISNULL(categories.name,'')						AS categories_name
					, ISNULL(transaction_type,'')						AS [status]
					, CONVERT(VARCHAR(20),jig_records.record_at,20)		AS TransactionDate
					, jig_records.operated_by							AS UserID
					, ISNULL(jig_records.location_id,'')				AS location_id
					, categories.lsi_process_id							AS process_id
					, ISNULL(jigs.barcode,'')							AS barcode
					, (case when transaction_type = 'On Machine' then ISNULL(mc_no,'') else '' END) AS MCNo
					, ISNULL(jig_records.lot_no,'')						AS  lot_no
					, ISNULL(locations.name + ',' + y + ',' + x ,'')	AS Storage 
					, ISNULL(jig_records.comment,'')					AS comment
					, ISNULL(processes.name,'')							AS process_name
		FROM APCSProDB.trans.jigs
		LEFT JOIN	APCSProDB.trans.machine_jigs 
		ON	 machine_jigs.jig_id		= jigs.id
		LEFT JOIN	APCSProDB.mc.machines 
		ON	machines.id					= machine_jigs.machine_id
		INNER JOIN  APCSProDB.trans.jig_records 
		ON jig_records.jig_id			= jigs.id
		INNER JOIN  APCSProDB.jig.productions 
		ON productions.id				= jigs.jig_production_id 
		INNER JOIN  APCSProDB.jig.categories 
		ON categories.id				= productions.category_id 
		INNER JOIN APCSProDB.method.processes
		ON processes.id  =  categories.lsi_process_id
		LEFT JOIN APCSProDB.jig.locations 
		ON jig_records.location_id		= locations.id
		WHERE productions.is_disabled	= 0
		AND (categories.lsi_process_id	= @process_id OR @process_id IS NULL)
		AND (productions.id		= @production_id OR @production_id IS NULL)
		AND (categories.id		= @categories_id OR @categories_id IS NULL)
		AND (IIF(@Date ='' OR @ToDate = '' ,1,0) = 1
		OR	(jig_records.record_at between @Date AND @ToDate) )
		ORDER BY TransactionDate desc


END
