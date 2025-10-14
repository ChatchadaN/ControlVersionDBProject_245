-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_jig_accumulate]
 		  @Process_id		INT				= NULL
		, @Barcode			NVARCHAR(100)	
		, @Updated_by		INT				= 1
 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 
				DECLARE   @jig_state				INT				 
						, @jig_id					INT 			 
						, @production_id			INT				 
						, @user_no					NVARCHAR(10)	 
						, @jig_records_id			INT
						, @accumulate_lifetime		INT
						, @SafetyPoint				INT 
						, @binary_file				VARBINARY(MAX)  


				SET @user_no = (SELECT emp_num FROM APCSProDB.man.users WHERE id = @Updated_by)



		SELECT			  @jig_id				=  jigs.id
						, @jig_state			=  jigs.jig_state 
						, @production_id		=  jigs.jig_production_id
				FROM  APCSProDB.trans.jigs 
				INNER JOIN APCSProDB.trans.jig_conditions
				ON jig_conditions.id  = jigs.id 
				INNER JOIN APCSProDB.jig.productions
				ON jigs.jig_production_id  =  productions.id
				INNER JOIN APCSProDB.jig.production_counters
				ON production_counters.production_id =  productions.id 
				INNER JOIN APCSProDB.jig.categories
				ON categories.id  =  productions.category_id
				WHERE  (qrcodebyuser					=  @Barcode  
				OR		smallcode						=  @Barcode  
				OR		barcode							=  @Barcode )
				AND		categories.lsi_process_id		=  @Process_id
 

	IF EXISTS (SELECT @jig_id FROM  APCSProDB.trans.jigs 
				INNER JOIN APCSProDB.trans.jig_conditions
				ON jig_conditions.id  = jigs.id 
				INNER JOIN APCSProDB.jig.productions
				ON jigs.jig_production_id  =  productions.id
				INNER JOIN APCSProDB.jig.production_counters
				ON production_counters.production_id =  productions.id 
				INNER JOIN APCSProDB.jig.categories
				ON categories.id  =  productions.category_id
				WHERE  (qrcodebyuser					=  @Barcode  
				OR		smallcode						=  @Barcode  
				OR		barcode							=  @Barcode )
				AND		categories.lsi_process_id		=  @Process_id)
	BEGIN  	
  
			BEGIN TRY
			 
				IF (@jig_state <> 7 )--12	On Machine , 2 Stock , 14 Scrap 
				BEGIN 

					SELECT    'FALSE' AS Is_Pass
							, N' jig ('+@Barcode+ N') status is not repair !!' AS Error_Message_ENG
							, N' jig ('+@Barcode+ N')  ยังไม่ถูก Repair !!' AS Error_Message_THA
							, '' AS Handling
							, '' AS Warning
					FROM APCSProDB.trans.jigs
					WHERE id  = @jig_id
					
					RETURN

				END
				ELSE   IF (@jig_state = 7)  -- 7	Repair
				BEGIN 
						
						UPDATE APCSProDB.trans.jig_conditions 
						SET		jig_conditions.accumulate_lifetime		= 0 
							  , jig_conditions.[value]					= 0  
						FROM APCSProDB.trans.jigs 
						INNER JOIN APCSProDB.trans.jig_conditions 
						ON jigs.id		= jig_conditions.id 
						WHERE jigs.id   =  @jig_id
					 
					INSERT INTO  [APCSProDB].[trans].[jig_condition_records]
					(
							  [day_id]
							, [recorded_at]
							, [jig_id]
							, [control_no]
							, [val]
							, [reseted_at]
							, [reseted_by]
							, [periodcheck_value]
							, accumulate_lifetime
					)
		   			SELECT    (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
							, GETDATE()
							, id
							, control_no
							, [value]
							, GETDATE()
							, @Updated_by
							, periodcheck_value 
							, accumulate_lifetime
					FROM  APCSProDB.trans.jig_conditions
					WHERE id = @JIG_ID

					INSERT INTO APCSProDB.trans.jig_records 
					(			
								  [day_id]
								, [record_at]
								, [jig_id]
								, [jig_production_id]
								, [created_at]
								, [created_by]
								, [operated_by]
								, transaction_type 
								, record_class
					) 
					VALUES
					(			  
								  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date, GETDATE(), 111))
								, GETDATE()
								, @JIG_ID
								, @production_id
								, GETDATE()
								, @Updated_by
								, @user_no
								, 'Reset LifeTime' 
								, 16
					)
			

				SELECT		  'TRUE'							AS Is_Pass 
							, N'Reset LifeTime done !!'		AS Error_Message_ENG
							, N'Reset LifeTime เรียบร้อย !!'		AS Error_Message_THA
							, N' กรุณาติดต่อ System'				AS Handling


				END
			
			END TRY
			BEGIN CATCH

				SELECT		  'FALSE'							AS Is_Pass 
							, ERROR_MESSAGE()					AS Error_Message_ENG
							, N'การบันทึกการจบการผลิตผิดพลาด !!'		AS Error_Message_THA
							, N' กรุณาติดต่อ System'				AS Handling
 
			END CATCH	


	END  
	ELSE 
	BEGIN 

		SELECT    'FALSE'									AS Is_Pass 
				, N''  + @Barcode + N' Data not found!!'	AS Error_Message_ENG
				, N''  + @Barcode + N' ยังไม่ถูกลงทะเบียน  !!'	AS Error_Message_THA 
				, ''										AS Handling
	END
		 
END
	 
 