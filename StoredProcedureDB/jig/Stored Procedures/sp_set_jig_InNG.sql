------------------------------ Creater Rule ------------------------------
-- Project Name				: jig
-- Procedure Name 	 		: [jig].[sp_set_jig_InNG]
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: APCSProDB.jig.productions
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [jig].[sp_set_jig_InNG]
(	-- ADD THE PARAMETERS FOR THE STORED PROCEDURE HERE
		  @Process_id		INT				= NULL
		, @Barcode			NVARCHAR(100)	= NULL
		, @Location			NVARCHAR(100)	= NULL
		, @Updated_by		INT				= 1
		, @Img1				VARBINARY(MAX)	= NULL
		, @Img2				VARBINARY(MAX)	= NULL
		, @Img3				VARBINARY(MAX)	= NULL
		, @File				VARBINARY(MAX)	= NULL
		, @Jig_record		INT				= 0
)
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE   @locations_id		INT 
			, @jig_id			INT 
			, @jig_records_id	INT
			, @user_no			NVARCHAR(10)

	SET @jig_id =(SELECT id  FROM APCSProDB.trans.jigs WHERE barcode = @Barcode) 
	SET @locations_id = ( SELECT  id 
						  FROM	APCSProDB.jig.locations 
						  WHERE  name + ',' + y + ',' + x = @Location
						  AND	lsi_process_id = @process_id
						)
IF (@File IS NULL )
BEGIN 
	BEGIN TRY

		 UPDATE APCSProDB.trans.jigs 
		 SET	  location_id		= @locations_id
				, [status]			= 'Stock NG'
				, jigs.jig_state	= 4
				, updated_at		= GETDATE()
				, updated_by		= @updated_by
		 WHERE    id				= @jig_id

		SET @user_no = (SELECT emp_num FROM APCSProDB.man.users WHERE id = @updated_by)

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
			, [transaction_type]
			, record_class
		) 
		VALUES 
		(
			  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
			, GETDATE()
			, @jig_id
			, (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @jig_id) 
			, @locations_id
			, GETDATE()
			, @updated_by
			, @user_no
			, 'Stock NG'
			, 4
		)

		SET @jig_records_id = ( SELECT TOP 1  id from APCSProDB.trans.jig_records  
								WHERE jig_id = @jig_id     ORDER BY jig_records.id DESC
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

		SELECT TOP(1)  'TRUE'					AS Is_Pass 
					, N'Success'				AS Error_Message_ENG
					, N'บันทึกข้อมูลสำเร็จ'			AS Error_Message_THA 
					, ''						AS Handling
					, jig_records.id			AS id
					, jig_records.operated_by	AS MyUserID
					, CONVERT(datetime,jig_records.record_at,111) AS TransactionDate 
					, jigs.smallcode			AS SmallCode
					, productions.name			AS SocketName
					, categories.name			AS SocketType
					, ISNULL(locations.name,'')			AS Location
					, jig_records.transaction_type AS TransactionType 
					, convert(decimal(18,1),CEILING(jig_conditions.value/100.0)/10) AS LifeTime 
					, convert(decimal(18,1),CEILING((jig_conditions.value + jig_conditions.accumulate_lifetime)/100.0)/10) AS AccumulateLifeTime 
					, [users].name
					, @jig_records_id  AS records_id
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
		ORDER BY jig_records.id desc

		END TRY
		BEGIN CATCH
			SELECT    'FALSE'				AS Is_Pass 
					, ERROR_MESSAGE()		AS Error_Message_ENG
					, N'บันทึกข้อมูลผิดพลาด !!'	AS Error_Message_THA 
					, ''					AS Handling
		END CATCH	
END
ELSE
BEGIN 

		UPDATE APCSProDB.[trans].[binary_data]  
		SET  [binary_file] =   @File 
		WHERE [id] =  @Jig_record

		SELECT TOP(1)  'TRUE'					AS Is_Pass 
					, N'Success'				AS Error_Message_ENG
					, N'บันทึกข้อมูลสำเร็จ'			AS Error_Message_THA 
					, ''						AS Handling
					, jig_records.id			AS id
					, jig_records.operated_by	AS MyUserID
					, CONVERT(datetime,jig_records.record_at,111) AS TransactionDate 
					, jigs.smallcode			AS SmallCode
					, productions.name			AS SocketName
					, categories.name			AS SocketType
					, ISNULL(locations.name,'')			AS Location
					, jig_records.transaction_type AS TransactionType 
					, convert(decimal(18,1),CEILING(jig_conditions.value/100.0)/10) AS LifeTime 
					, convert(decimal(18,1),CEILING((jig_conditions.value + jig_conditions.accumulate_lifetime)/100.0)/10) AS AccumulateLifeTime 
					, [users].name
					, jig_records.id		AS records_id
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
		WHERE jig_records.id = @Jig_record
		ORDER BY jig_records.id desc

	END 

END
