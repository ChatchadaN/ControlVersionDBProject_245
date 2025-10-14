-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_jig_data]
 		  @Process_id		INT				= NULL
		, @Barcode			NVARCHAR(100)	 
 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 
		
		IF EXISTS (SELECT 'xxx' FROM   APCSProDB.trans.jigs WHERE ( barcode = @Barcode OR qrcodebyuser = @Barcode OR smallcode = @Barcode ))
		BEGIN 

			SELECT   TOP 1   'TRUE'										AS Is_Pass
					, ''												AS Error_Message_ENG
					, ''												AS Error_Message_THA 
					, ''												AS Handling 
					, jigs.id											AS jig_id
					, ISNULL(jigs.barcode,'')							AS barcode
					, ISNULL(@Barcode,'')								AS qrcode
	  				, ISNULL(categories.id,'')							AS categories_id
					, ISNULL(categories.[name],'')						AS categories_name
					, ISNULL(productions.id,'')							AS productions_id
					, ISNULL(productions.[name],'')						AS productions_name
					, ISNULL(qrcodebyuser,'')							AS qrcodebyuser
					, ISNULL(jigs.smallcode,'')							AS smallcode
					, ISNULL(jigs.jig_state,'')							AS [jig_state] 
					, ISNULL(jigs.[status],'')							AS [status] 
					, ISNULL(CONVERT(VARCHAR,jigs.limit_date,111),'')   AS limit_date
					, categories.lsi_process_id							AS process_id
					, ISNULL(processes.[name],'')						AS process_name
					, ISNULL(locations.[name] + '-' + y + '-' + x ,'')	AS storage 
					, ISNULL(jig_conditions.[value],0)					AS life_time
					, ISNULL(production_counters.alarm_value ,0)		AS std_life_time
					, ISNULL(production_counters.period_value ,0)		AS period_value
					, ISNULL(jig_conditions.periodcheck_value,0)		AS [periodcheck_value]
					, FORMAT(COALESCE((CAST(jig_conditions.value  AS decimal(18 , 2)) * CAST(100  AS decimal(18 , 2)))/ NULLIF(production_counters.alarm_value,0) ,0), 'N2') AS lifetime_percen
					, ISNULL(jigs.lot_no,'')							AS lot_no
					, FORMAT(ISNULL(jig_conditions.accumulate_lifetime,0),'N0'	)		AS accumulate_lifetime
			FROM APCSProDB.trans.jigs
			INNER JOIN APCSProDB.trans.jig_conditions
			ON jigs.id = jig_conditions.id  
			INNER JOIN  APCSProDB.jig.productions 
			ON productions.id	= jigs.jig_production_id 
			INNER JOIN  APCSProDB.jig.production_counters
			ON productions.id	= production_counters.production_id 
			AND counter_name   <>  'Stock'
			INNER JOIN  APCSProDB.jig.categories 
			ON categories.id				= productions.category_id 
			INNER JOIN APCSProDB.method.processes
			ON processes.id  =  categories.lsi_process_id
			LEFT JOIN APCSProDB.jig.locations 
			ON jigs.location_id		= locations.id
			WHERE (jigs.barcode = @Barcode  OR jigs.qrcodebyuser =  @Barcode 	OR jigs.smallcode = @Barcode )
		 END
		 ELSE
		 BEGIN

					SELECT	  'FALSE'							AS Is_Pass
							, 'This jig is not registered !!'	AS Error_Message_ENG
							, N'JIG นี้ยังไม่ถูกลงทะเบียน !!'		AS Error_Message_THA 
							, ''								AS Handling
					RETURN


		END 

END
	 
 