-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================

CREATE PROCEDURE [jig].[sp_set_jig_clean]
( 
	  @process_id	INT				= NULL
	, @barcode		NVARCHAR(100)	= NULL
	, @updated_by	INT				= NULL
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE   @production_id	INT				= 0
			, @jig_id			INT				= 0
			, @jig_state		INT				= 0
			, @STDLifeTime		INT				= 0
			, @LifeTime			INT				= 0
			, @SafetyPoint		INT				= 0
			, @Status			NVARCHAR(10)	= NULL
			, @user_no			NVARCHAR(10)	= 0
  
	IF EXISTS (SELECT'xxxx'
			   FROM APCSProDB.trans.jigs 
               INNER JOIN APCSProDB.jig.productions 
			   ON	 jigs.jig_production_id		=  productions.id 
               INNER JOIN APCSProDB.jig.categories 
			   ON	 productions.category_id	=  categories.id  
			   INNER JOIN APCSProDB.trans.jig_conditions 
			   ON	 jig_conditions.id			= jigs.id 
			   WHERE barcode					= @barcode 
			   AND   categories.lsi_process_id	= @process_id )
	BEGIN

				SELECT    @jig_id			= jigs.id
						, @Status			= jigs.status
						, @jig_state		= jigs.jig_state
						, @production_id	= jigs.jig_production_id			 
						, @LifeTime			= jig_conditions.value				 
						, @STDLifeTime		= production_counters.alarm_value	 
						, @SafetyPoint		= production_counters.warn_value	 
			   FROM APCSProDB.trans.jigs 
               INNER JOIN APCSProDB.jig.productions 
			   ON  jigs.jig_production_id				=  productions.id 
			   INNER JOIN APCSProDB.jig.production_counters
			   ON  production_counters.production_id	=  productions.id
               INNER JOIN APCSProDB.jig.categories 
			   ON  productions.category_id				=  categories.id  
			   INNER JOIN APCSProDB.trans.jig_conditions 
			   ON jig_conditions.id						= jigs.id 
			   WHERE barcode							= @barcode 
			   AND categories.lsi_process_id			= @process_id 
			   
--SELECT * FROM  APCSProDB.trans.item_labels
--WHERE name = 'jigs.jig_state'
--ORDER BY name , val

		IF (@jig_state = 12)  --On Machine
		BEGIN
			SELECT    'TRUE' AS Is_Pass
					, N'This Socket ('+ @barcode + ') use on Machine !!' AS Error_Message_ENG
					, N'Socket นี้ ('+ @barcode + N') นี้ถูกใช้งานอยู่ที่ Machine !!' AS Error_Message_THA
					, '' AS Handling
			RETURN
		END 
		ELSE IF (@jig_state = 2)	--Stock
		BEGIN
			SELECT    'TRUE' AS Is_Pass
					, N'This Socket ('+ @barcode + ') in Stock NG !!' AS Error_Message_ENG
					, N'Socket นี้ ('+ @barcode + N') นี้ไม่ได้อยู่ในสถานะ Stock NG !!' AS Error_Message_THA
					, '' AS Handling
			RETURN
		END 	 
		ELSE IF (@jig_state = 13) --Scrap
		BEGIN
			SELECT    'TRUE' AS Is_Pass
					, N'This Socket ('+ @barcode + ') in Stock NG !!' AS Error_Message_ENG
					, N'Socket นี้ ('+ @barcode + N') นี้ถูก Scrap แล้ว !!' AS Error_Message_THA
					, '' AS Handling
			RETURN
		END 
		ELSE 
		BEGIN 
				IF (@jig_state = 4) --Stock NG
				BEGIN

					UPDATE    APCSProDB.trans.jigs 
					SET		  location_id		= NULL
							, status			= 'To Clean'
							, jigs.jig_state	= 8
							, updated_at		= GETDATE()
							, updated_by		= @updated_by
					WHERE  id	=  @jig_id

					SET @user_no = (SELECT emp_num FROM APCSProDB.man.users WHERE id = @updated_by)

					INSERT INTO  APCSProDB.trans.jig_records 
					(		  [day_id]
							, [record_at]
							, [jig_id]
							, [jig_production_id]
							, [location_id]
							, [created_at]
							, [created_by]
							, [operated_by]
							, [transaction_type]
							, record_class
					) 
					VALUES 
					(		  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
							, GETDATE()
							, @jig_id
							, @production_id
							, NULL
							, GETDATE()
							, @updated_by
							, @user_no
							, 'To Clean'
							, 8
					)

					SELECT    'TRUE' AS Is_Pass
							, N'This Socket ('+ @barcode + ') in Clean!!' AS Error_Message_ENG
							, N'Socket นี้ ('+ @barcode + N') ถูกนำเข้าสถานะ Clean เรียบร้อย !!!!' AS Error_Message_THA
							, '' AS Handling
					RETURN
				END 
				ELSE IF (@jig_state = 6) --To Repair
				BEGIN
					SELECT    'TRUE' AS Is_Pass
							, N'This Socket ('+ @barcode + ') status To Repair !!' AS Error_Message_ENG
							, N'Socket นี้ ('+ @barcode + N') อยู่ในสถานะ To Repair !!' AS Error_Message_THA
							, '' AS Handling
					RETURN
				END 
				ELSE IF (@jig_state = 8) --To Clean
				BEGIN
					IF (@LifeTime >= @STDLifeTime) --To Repair
					BEGIN
						SELECT    'TRUE' AS Is_Pass
								, N'LifeTime Over !!' AS Error_Message_ENG
								, N'การใช้งานเกินอายุการใช้งาน!!' AS Error_Message_THA
								, '' AS Handling
						RETURN
					END 
				END 
				ELSE
				BEGIN 
						SELECT    'FALSE' AS Is_Pass
							, N'Socket status '+ @Status + '!!' AS Error_Message_ENG
							, N'Socket status '+ @Status +'!!' AS Error_Message_THA
							, '' AS Handling
						RETURN 
				END 
		END
	END 
	ELSE
	BEGIN 
			SELECT    'FALSE' AS Is_Pass
					, N'This socket ('+ @barcode + ') Is not register !!' AS Error_Message_ENG
					, N'Socket ('+ @barcode + N') นี้ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
					, '' AS Handling
			RETURN 
	END
END
