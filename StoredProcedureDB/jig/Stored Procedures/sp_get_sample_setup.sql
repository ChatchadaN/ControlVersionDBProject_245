-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_sample_setup]
	-- Add the parameters for the stored procedure here
	  @QRCode			AS VARCHAR(100)	-- 'SSOP-B20W,BM60014FV-C,A1'
	, @MCNo				AS VARCHAR(50)  -- '2320A3447V1'
	, @LotNo			AS VARCHAR(10) 
	, @Device			AS VARCHAR(50)
	, @Flow				AS VARCHAR(50)
	, @OPNo				AS VARCHAR(6) 
	, @Package			AS VARCHAR(50) =  NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		DECLARE @JIG_ID		AS INT 
		, @MC_ID			AS INT 
		, @STDLifeTime		AS DATETIME
		, @LifeTime			AS DATETIME
		, @Safety			AS DATETIME 
		, @OPID				AS INT 
		, @Smallcode		AS VARCHAR(4)
		, @State			AS INT
		, @productions_name AS NVARCHAR(100)
		, @app_name			AS NVARCHAR(100) = 'API'
	
	DECLARE @SplitData TABLE
	(
	     Package	VARCHAR(MAX),
	    Device		VARCHAR(MAX),
		Flow		VARCHAR(MAX)
	)

	SET @MC_ID	= (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo)
	SELECT	  @JIG_ID				=  jigs.id 
			, @Smallcode			=  jigs.smallcode
			, @State				=  jigs.jig_state
			, @productions_name		= REPLACE(productions.name,' ','')
	FROM APCSProDB.trans.jigs 
	INNER JOIN APCSProDB.jig.productions
	ON productions.id  =  jigs.jig_production_id
	WHERE barcode = @QRCode
	 

  INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history_jig]
		   ([record_at]
		  , [record_class]
		  , [login_name]
		  , [hostname]
		  , [appname]
		  , [command_text]
		  , lot_no
		  , jig_id
		  , barcode
		   )
SELECT GETDATE()
			,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			, 'EXEC [jig].[sp_get_sample_setup] @QRCode  = ''' + ISNULL(CAST(@QRCode AS nvarchar(MAX)),'') + ''',@MCNo  = ''' + ISNULL(CAST(@MCNo AS nvarchar(MAX)),'') + ''', @Device = ''' + ISNULL(CAST(@Device AS nvarchar(MAX)),'') + ''', @Package= ''' + ISNULL(CAST(@Package AS nvarchar(MAX)),'') + ''',@Flow= ''' 
				+ ISNULL(CAST(@Flow AS nvarchar(MAX)),'') +  ''',@OPNo = ''' + ISNULL(CAST(@OPNo AS nvarchar(MAX)),'') + ''''
			, @LotNo
			, @JIG_ID
			, @QRCode
			 
			  
	--/////////////////////Check Socket Regist
	IF NOT EXISTS (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) 
	BEGIN

			--SELECT     'FALSE' AS Is_Pass
			--			, 'This socket is not registered !!' AS Error_Message_ENG
			--			, N'Socket นี้ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA 
			--			, '' AS Handling

				 SELECT	  'FALSE'		AS Is_Pass
						, 1				AS code
						, @app_name		AS [app_name] 
						, '' 			AS comment
		RETURN
		 
	END

	IF (SELECT jig_state FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) = 13 BEGIN
			
			
			SELECT	  'FALSE'		AS Is_Pass
						, 18				AS code
						, @app_name		AS [app_name] 
						, '' 			AS comment
			RETURN
		END


	--//////////////////// CHECK MACHINE NUMBER
	IF NOT EXISTS (SELECT TOP(1) id FROM APCSProDB.mc.machines WHERE machines.name = @MCNo) 
	BEGIN

		--SELECT    'FALSE' AS Is_Pass
		--		, 'Machine Number is invalid !!' AS Error_Message_ENG 
		--		, N'หมายเลขเครื่องจักรไม่ถูกต้อง !!' AS Error_Message_THA
		--		, '' AS Handling
		--RETURN

		SELECT	  'FALSE'		AS Is_Pass
				 , 2			AS code
				 , @app_name	AS [app_name]
				 , '' 			AS comment
		RETURN
	END
	IF EXISTS (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) 
	BEGIN
					INSERT INTO @SplitData
					SELECT * FROM   
					(
						SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@productions_name,',') 

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

		-- IF (@Package  <>  (SELECT Package   FROM  @SplitData))    edit 2023-07-18   no check package
		-- BEGIN
		--		 SELECT	  'FALSE1'		AS Is_Pass
		--				, 13			AS code
		--				, @app_name		AS [app_name] 
		--				, '' 			AS comment
		--		RETURN
		--END

		--ELSE 
		IF (@Device <>  (SELECT Device   FROM  @SplitData))
		BEGIN
				 SELECT	  'FALSE'		AS Is_Pass
						, 20			AS code
						, @app_name		AS [app_name] 
						, '' 			AS comment
				RETURN
		END

		ELSE IF @Flow <> (SELECT Flow FROM  @SplitData)
		BEGIN
				 SELECT	  'FALSE'		AS Is_Pass
						, 21			AS code
						, @app_name		AS [app_name] 
						, ''			AS comment
						--SELECT	@Flow ,  TRIM(CONVERT(VARCHAR(20),(SELECT Flow FROM  @SplitData)))
				RETURN
		END

	
	 
	END


	--//////////////// CHECK STAGE To Machine

	IF @State <> 11 
	BEGIN		 --11 To Machine

		IF @State = 12 
		BEGIN	 --12 On Machine

			DECLARE @MCOld AS VARCHAR(50)

			SET @MCOld = (SELECT TOP 1 machines.name FROM APCSProDB.trans.jigs  
					LEFT JOIN  APCSProDB.trans.machine_jigs ON machine_jigs.jig_id = jigs.id 
					LEFT JOIN  APCSProDB.mc.machines ON machines.id = machine_jigs.machine_id WHERE jigs.id = @JIG_ID)

			IF @MCOld <> @MCNo BEGIN

				--SELECT 'FALSE' AS Is_Pass
				--,N'This JIG ('+ @SmallcodeIn + N') Is use on another Machine ('+ @MCOld + N') !!' AS Error_Message_ENG
				--	,N'JIG นี้ ('+ @SmallcodeIn + N') ถูกใช้งานอยู่ที่ Machine เครื่องอื่น ('+ @MCOld + N') !!' AS Error_Message_THA
				--,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
				--RETURN
				 
				SELECT	  'FALSE'		AS Is_Pass
						 , 3			AS code
						 , @app_name	AS [app_name]
						 , @MCOld		AS comment
				RETURN
			END
		END
		ELSE BEGIN

			--SELECT	  'FALSE' AS Is_Pass
			--		, 'Socket ('+ (smallcode) + ') status is not scan out of stock.' AS Error_Message_ENG
			--		, 'Socket ('+ (smallcode) + N') ยังไม่ถูกสแกนออกจาก Stock !!' AS Error_Message_THA 
			--		, '' AS Handling
			--FROM APCSProDB.trans.jigs 
			--WHERE barcode = @QRCode

				SELECT	  'FALSE'	 AS Is_Pass
						, 4			 AS code
						, @app_name  AS [app_name]
						, '' 		 AS comment


			RETURN
		END
	END

	--////////////////////Check LifeTime
	
	SET @STDLifeTime =   (SELECT  jigs.limit_date 
						FROM APCSProDB.trans.jigs 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						INNER JOIN APCSProDB.jig.production_counters 
						ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode)


	SET @LifeTime	=   (SELECT GETDATE())

	SET @Safety		= (SELECT (DATEADD(month, -1, @STDLifeTime))
						FROM APCSProDB.trans.jigs 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id 
						INNER JOIN APCSProDB.jig.production_counters 
						ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode)
 
	
		IF (@LifeTime > @STDLifeTime ) 
		BEGIN
				-- SELECT   'FALSE' AS Is_Pass
				--		, '('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG
				--		, '('+(smallcode)+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA 
				--		, '' AS Handling
				--FROM APCSProDB.trans.jigs WHERE barcode = @QRCode

				SELECT	  'FALSE'	 AS Is_Pass
						, 5			 AS code
						, @app_name  AS [app_name]
						, '' 		 AS comment
				RETURN
		 END 
	 
		END
 
		IF (@LifeTime >=  @Safety) 
		BEGIN
	 
				--SELECT	  'FALSE' AS Is_Pass 
				--		, '('+(smallcode)+')  Near the end of lifetime !!' AS Error_Message_ENG
				--		, '('+(smallcode)+N')  LifeTime ใกล้หมดอายุ !! ' AS Error_Message_THA 
				--		, '' AS Handling
				--FROM APCSProDB.trans.jigs 
				--WHERE barcode = @QRCode

				SELECT	  'TRUE'     AS Is_Pass
						, 6			 AS code
						, @app_name  AS [app_name]
						, '' 		 AS comment
						, @QRCode			AS QRCode
						, smallcode			AS Smallcode
						, productions.name  AS [Type] 
						, FORMAT(GETDATE(),'yyyy-MM-dd hh:mm:ss tt')  AS Life_Time
						, FORMAT( jigs.limit_date ,'yyyy-MM-dd hh:mm:ss tt') AS STD_Life_Time
						, FORMAT(DATEADD(month, -1, DATEADD(YEAR, productions.expiration_base, productions.created_at )), 'yyyy-MM-dd hh:mm:ss tt') AS Safety
						, jigs.id		AS jig_id 
				FROM APCSProDB.trans.jigs  
				INNER JOIN APCSProDB.jig.productions   
				ON jig_production_id = productions.id 
				INNER JOIN [APCSProDB].[jig].[production_counters]   
				ON [production_counters].production_id = productions.id 
				INNER JOIN APCSProDB.trans.jig_conditions   
				ON jig_conditions.id = jigs.id
				WHERE jigs.id =  @JIG_ID
 

		END 
		ELSE
		BEGIN 

		SELECT	  'TRUE'			AS Is_Pass
				, 12				AS code
				, @app_name			AS [app_name]
				, ''				AS comment
				, @QRCode			AS QRCode
				, smallcode			AS Smallcode
				, productions.name  AS [Type] 
				, FORMAT(GETDATE(),'yyyy-MM-dd hh:mm:ss tt')  AS Life_Time
				, FORMAT( jigs.limit_date ,'yyyy-MM-dd hh:mm:ss tt') AS STD_Life_Time
				, FORMAT(DATEADD(month, -1, DATEADD(YEAR, productions.expiration_base, productions.created_at )), 'yyyy-MM-dd hh:mm:ss tt') AS Safety
				, jigs.id		AS jig_id 
		FROM APCSProDB.trans.jigs  
		INNER JOIN APCSProDB.jig.productions   
		ON jig_production_id = productions.id 
		INNER JOIN [APCSProDB].[jig].[production_counters]   
		ON [production_counters].production_id = productions.id 
		INNER JOIN APCSProDB.trans.jig_conditions   
		ON jig_conditions.id = jigs.id
		WHERE jigs.id =  @JIG_ID

END
