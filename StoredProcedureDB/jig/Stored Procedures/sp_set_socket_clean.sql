------------------------------ Creater Rule ------------------------------
-- Project Name				: jig 
-- Written Date             : 2023/12/11
-- Procedure Name 	 		: [jig].[sp_set_socket_repair]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.locations
-- Specific Logic           : 
-- Purpose					: Set Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE  PROCEDURE [jig].[sp_set_socket_clean]
(
		  @Process_id		INT				= NULL
		, @Barcode			NVARCHAR(100)	
		, @Updated_by		INT				= 1
		, @Img1				VARCHAR(MAX)	= NULL
		, @Img2				VARCHAR(MAX)	= NULL
		, @Img3				VARCHAR(MAX)	= NULL
		, @File				VARBINARY(MAX)	= NULL
		, @Jig_record		INT				= 0
)
AS
BEGIN
	SET NOCOUNT ON;

				DECLARE   @jig_state				INT				 
						, @jig_id					INT 			 
						, @production_id			INT				 
						, @user_no					NVARCHAR(10)	 
						, @jig_records_id			INT
						, @accumulate_lifetime		INT
						, @SafetyPoint				INT 
						, @binary_file				VARBINARY(MAX)  



				SELECT	  @jig_id				=  jigs.id
						, @jig_state			=  jigs.jig_state
						, @production_id		=  jigs.jig_production_id
						, @accumulate_lifetime	=  IIF(jig_conditions.accumulate_lifetime IS NULL,jig_conditions.[value],accumulate_lifetime + accumulate_lifetime )
						, @SafetyPoint			=  IIF(production_counters.warn_value IS NULL,production_counters.alarm_value,production_counters.warn_value ) 
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

 
IF EXISTS (SELECT 'xxx' FROM  APCSProDB.trans.jigs WHERE id = @jig_id)
BEGIN  	
		
	BEGIN TRY
	IF (@Img1 IS NULL )
	BEGIN 
				IF (@jig_state IN (2 ,  12 , 14) )--12	On Machine ,2	Stock ,14	Scraped
				BEGIN 
					SELECT    'FALSE' AS Is_Pass
							, N' JIG ('+@Barcode+') status is '+status+' !!' AS Error_Message_ENG
							, N' JIG ('+@Barcode+ N') นี้สถานะ '+status +' !!' AS Error_Message_THA
							, '' AS Handling
							, '' AS Warning
					FROM APCSProDB.trans.jigs
					WHERE id  = @jig_id
					
					RETURN

				END
				ELSE   IF (@jig_state  IN (4))  -- 4	Stock NG
				BEGIN 
						 
						UPDATE APCSProDB.trans.jigs 
						SET	  location_id		= NULL
							, [status]			= 'To Clean'
							, jigs.jig_state	= 8
							, updated_at		= GETDATE()
							, updated_by		= @Updated_by
						WHERE id = @jig_id

						INSERT INTO APCSProDB.trans.jig_records 
							(	 
									[day_id]
								, [record_at]
								, [jig_id]
								, [jig_production_id]
								, [location_id]
								, [created_at]
								, [created_by]
								, [operated_by]
								, transaction_type
								, record_class
								, jig_state
							) 
							VALUES 
							(
								  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
								, GETDATE()
								, @jig_id
								, @production_id
								, NULL
								, GETDATE()
								, @Updated_by
								, @user_no
								, 'To Clean'
								, 8
								, 8
							)
							
						SELECT    'TRUE'					AS Is_Pass 
								, N'Success'				AS Error_Message_ENG
								, N'บันทึกข้อมูลสำเร็จ'			AS Error_Message_THA 
								, ''						AS Handling
								, jig_state
								, [status]
						FROM APCSProDB.trans.jigs
						WHERE id =  @jig_id

						RETURN

				END

				ELSE IF (@jig_state =  6)
				BEGIN
						IF (@accumulate_lifetime >=  @SafetyPoint)
						BEGIN
							
							SELECT    'FALSE'						AS Is_Pass 
									, N'LifeTime Over  !!'			AS Error_Message_ENG
									, N'การใช้งานเกินอายุการใช้งาน !!'		AS Error_Message_THA 
									, ''							AS Handling
							RETURN

						END 
						ELSE
						BEGIN 
								
							SELECT		  'TRUE'					AS Is_Pass 
										, N'Success'				AS Error_Message_ENG
										, N'บันทึกข้อมูลสำเร็จ'			AS Error_Message_THA 
										, ''						AS Handling
										, jig_state
										, [status]
							FROM APCSProDB.trans.jigs
							WHERE id =  @jig_id
							RETURN
						END 
				END 
				ELSE
				BEGIN 

					SELECT    'FALSE' AS Is_Pass
							, N' JIG ('+@Barcode+') status is '+jigs.status+' !!' AS Error_Message_ENG
							, N' JIG ('+@Barcode+ N') นี้สถานะ '+jigs.status +' !!' AS Error_Message_THA
							, '' AS Handling
							, '' AS Warning
					FROM APCSProDB.trans.jigs
					WHERE id  = @jig_id

					RETURN
				END

				 
	END
	ELSE IF (@Img1 IS NOT NULL AND @File IS NULL )
	BEGIN 
		
 
		SET @binary_file =  (SELECT TOP 1  binary_file 
								FROM APCSProDB.trans.jigs 
								INNER JOIN APCSProDB.trans.jig_records
								ON jigs.id  = jig_records.jig_id
								INNER JOIN APCSProDB.trans.binary_data
								ON binary_data.id  = jig_records.id 
								WHERE jig_id = @jig_id 
								AND jig_records.record_class = 4
								ORDER BY jig_records.created_at DESC)


			SET @jig_records_id = ( SELECT TOP 1  id 
									FROM APCSProDB.trans.jig_records  
									WHERE jig_id = @jig_id     
									ORDER BY jig_records.id DESC
								  )

	 
		INSERT INTO APCSProDB.trans.binary_data 
		(		  [id]
				, [binary_data1]
				, [binary_data2]
				, [binary_data3]
		) 
		VALUES 
		(		  @jig_records_id
				, (SELECT LOWER(CONVERT(VARCHAR(32), HashBytes('MD5', @Img1), 2)))
				, (SELECT LOWER(CONVERT(VARCHAR(32), HashBytes('MD5', @Img2), 2)))
				, (SELECT LOWER(CONVERT(VARCHAR(32), HashBytes('MD5', @Img3), 2)))
		)

		SELECT TOP(1)  'TRUE'											AS Is_Pass 
					 , N'Success'										AS Error_Message_ENG
					 , N'บันทึกข้อมูลสำเร็จ'									AS Error_Message_THA 
					 , ''												AS Handling
					 , jig_records.id									AS id
					 , jig_records.operated_by							AS MyUserID
					 , CONVERT(datetime,jig_records.record_at,111)		AS TransactionDate 
					 , jigs.smallcode									AS SmallCode
					 , productions.name									AS SocketName
					 , categories.name									AS SocketType
					 , ISNULL(locations.name,'')						AS [Location]
					 , jig_records.transaction_type						AS TransactionType 
					 , convert(decimal(18,1),CEILING(jig_conditions.value/100.0)/10)											AS [LifeTime]
					 , convert(decimal(18,1),CEILING((jig_conditions.value + jig_conditions.accumulate_lifetime)/100.0)/10)		AS AccumulateLifeTime 
					 , [users].[name]									AS [name]
					 , @jig_records_id									AS records_id
					 , @binary_file										AS binary_file
		FROM APCSProDB.trans.jig_records 
		INNER JOIN  APCSProDB.trans.jigs 
		ON jig_records.jig_id = jigs.id 
		INNER JOIN APCSProDB.trans.jig_conditions 
		ON jigs.id = jig_conditions.id 
		INNER JOIN APCSProDB.jig.productions 
		ON jigs.jig_production_id = productions.id 
		INNER JOIN APCSProDB.jig.categories 
		ON productions.category_id = categories.id 
		LEFT OUTER JOIN APCSProDB.jig.locations 
		ON jig_records.location_id = locations.id
		LEFT JOIN [APCSProDB].[man].[users]
		ON [users].emp_num = jig_records.operated_by
		WHERE jig_records.jig_id = @jig_id
		ORDER BY jig_records.id DESC


		END
	ELSE IF (@File IS NOT NULL)
	BEGIN 
		
		UPDATE APCSProDB.[trans].[binary_data]  
		SET  [binary_file] =  @File
		WHERE [id] =  @Jig_record

		SELECT TOP(1)  'TRUE'										AS Is_Pass 
					, N'Success'									AS Error_Message_ENG
					, N'บันทึกข้อมูลสำเร็จ'								AS Error_Message_THA 
					, ''											AS Handling
					, jig_records.id								AS id
					, jig_records.operated_by						AS MyUserID
					, CONVERT(datetime,jig_records.record_at,111)	AS TransactionDate 
					, jigs.smallcode								AS SmallCode
					, productions.name								AS SocketName
					, categories.name								AS SocketType
					, ISNULL(locations.name,'')						AS [Location]
					, jig_records.transaction_type					AS TransactionType 
					, convert(decimal(18,1),CEILING(jig_conditions.value/100.0)/10) AS [LifeTime]
					, convert(decimal(18,1),CEILING((jig_conditions.value + jig_conditions.accumulate_lifetime)/100.0)/10) AS AccumulateLifeTime 
					, [users].name
					, jig_records.id								AS records_id
					, @binary_file									AS binary_file
		FROM APCSProDB.trans.jig_records 
		INNER JOIN  APCSProDB.trans.jigs 
		ON jig_records.jig_id = jigs.id 
		INNER JOIN APCSProDB.trans.jig_conditions 
		ON jigs.id = jig_conditions.id 
		INNER JOIN APCSProDB.jig.productions 
		ON jigs.jig_production_id = productions.id 
		INNER JOIN APCSProDB.jig.categories 
		ON productions.category_id = categories.id 
		LEFT OUTER JOIN APCSProDB.jig.locations 
		ON jig_records.location_id = locations.id
		LEFT JOIN [APCSProDB].[man].[users]
		ON [users].emp_num = jig_records.operated_by
		WHERE jig_records.jig_id = @jig_id
		ORDER BY jig_records.id DESC
		 
	END
	END	TRY
	BEGIN CATCH
				SELECT    'FALSE' AS Is_Pass 
						, ERROR_MESSAGE()		 AS Error_Message_ENG
						, N'การแก้ไขข้อมูลผิดพลาด !!' AS Error_Message_THA 
						, '' AS Handling
	END CATCH	 
	END
	
	ELSE 
	BEGIN 

		SELECT    'FALSE' AS Is_Pass 
					, N'Data not found!!' AS Error_Message_ENG
					, N'ยังไม่ถูกลงทะเบียน  !!' AS Error_Message_THA 
					, '' AS Handling
	END
END
