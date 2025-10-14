-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_set_sample_setup]
	-- Add the parameters for the stored procedure here
	  @QRCode			AS VARCHAR(100)
 	, @MCNo				AS VARCHAR(50)
	, @OPNo				AS VARCHAR(6) 
	, @Device			AS VARCHAR(50)
	, @Flow				AS VARCHAR(50)
	, @Package			AS VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	SET NOCOUNT ON;
	DECLARE		  @JIG_ID				AS INT 
				, @MC_ID				AS INT 
				, @STDLifeTime			AS DATETIME
				, @LifeTime				AS DATETIME
				, @Safety				AS DATETIME 
				, @JID_OLD				AS INT
				, @OPID					AS INT 
				, @Smallcode			AS VARCHAR(4)
				, @State				AS INT
				, @app_name				AS NVARCHAR(100) = 'API'
				, @productions_name		AS NVARCHAR(100)

	SET @OPID = (SELECT TOP(1) ISNULL(id,1) AS id FROM APCSProDB.man.users WHERE emp_num = @OPNo)

	DECLARE @SplitData TABLE
	(
	    Package		NVARCHAR(MAX),
	    Device		NVARCHAR(MAX),
		Flow		NVARCHAR(MAX)
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
		  , jig_id
		  , barcode
		   )
SELECT GETDATE()
			,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			, 'EXEC [jig].[sp_set_sample_setup] @MCNo  = ''' + ISNULL(CAST(@MCNo AS nvarchar(MAX)),'') + ''', @Device = ''' + ISNULL(CAST(@Device AS nvarchar(MAX)),'') + ''', @Package= ''' + ISNULL(CAST(@Package AS nvarchar(MAX)),'') + ''',@Flow= ''' 
				+ ISNULL(CAST(@Flow AS nvarchar(MAX)),'') +  ''',@OPNo = ''' + ISNULL(CAST(@OPNo AS nvarchar(MAX)),'') + ''''
			, @JIG_ID
			, @QRCode



 
	--/////////////////////Check Socket Regist
	IF NOT EXISTS (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCode) BEGIN
			--SELECT     'FALSE' AS Is_Pass
			--			, 'This socket is not registered !!' AS Error_Message_ENG
			--			, N'Socket นี้ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA 
			--			, '' AS Handling

				 SELECT	 'FALSE'		AS Is_Pass
						,1				AS code
						,@app_name		AS [app_name] 
						, '' 			AS comment
	END

	----//////////////////// CHECK MACHINE NUMBER
	IF NOT EXISTS (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo) BEGIN
				--SELECT    'FALSE' AS Is_Pass
				--		, 'Machine Number is invalid !!' AS Error_Message_ENG 
				--		, N'หมายเลขเครื่องจักรไม่ถูกต้อง !!' AS Error_Message_THA
				--		, '' AS Handling
				--RETURN

				SELECT	  'FALSE'		AS Is_Pass
						 , 2			AS code
						 , @app_name	AS [app_name]
						 , '' 			AS comment
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
		-- IF (@Package  <>  (SELECT Package   FROM  @SplitData))
		-- BEGIN
		--		 SELECT	  'FALSE'		AS Is_Pass
		--				, 13			AS code
		--				, @app_name		AS [app_name] 
		--				, '' 			AS comment
		--		RETURN
		--END
		IF (@Device <>  (SELECT Device   FROM  @SplitData))
		BEGIN
				 SELECT	  'FALSE'		AS Is_Pass
						, 13			AS code
						, @app_name		AS [app_name] 
						, '' 			AS comment
				RETURN
		END
		IF (@Flow <> (SELECT Flow   FROM  @SplitData))
		BEGIN
				 SELECT	  'FALSE'		AS Is_Pass
						,13			AS code
						, @app_name		AS [app_name] 
						, '' 			AS comment
				RETURN
		END
	 
	END

	--////////////////////Check LifeTime
	SET @STDLifeTime =   (SELECT jigs.limit_date
						FROM APCSProDB.trans.jigs 
						INNER JOIN APCSProDB.jig.productions 
						ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						INNER JOIN APCSProDB.jig.production_counters 
						ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode)


	SET @LifeTime	=  (SELECT GETDATE())

	SET @Safety		= (SELECT (DATEADD(month, -1, @STDLifeTime))
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCode)
	
	
		 IF (@LifeTime > @STDLifeTime ) 
		 BEGIN
				-- SELECT   'FALSE' AS Is_Pass
				--		, '('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG
				--		, '('+(smallcode)+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA 
				--		, '' AS Handling
				--FROM APCSProDB.trans.jigs WHERE barcode = @QRCode
				--RETURN
					SELECT	 'FALSE'		AS Is_Pass
							, 5				AS code
							, @app_name		AS [app_name]
							, '' 			AS comment
				RETURN

		 END 
	 
 

		
	--//////////////// SOCKET IN
	IF @State = 11   --To machine
	BEGIN	
		BEGIN TRY 
		--//////////// SOCKET OLD
		IF EXISTS (SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MC_ID AND idx =  21)
		BEGIN 
	 
					SET @JID_OLD = (SELECT TOP 1 jig_id FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MC_ID  AND idx = 21 )

					UPDATE    APCSProDB.trans.jigs 
					SET		  location_id	= NULL
							, status		= 'To Machine'
							, [jig_state]	= 11
							, updated_at	= GETDATE()
							, updated_by	= @OPID 
					WHERE id = @JID_OLD


					DELETE FROM APCSProDB.trans.machine_jigs 
					WHERE machine_id = @MC_ID 
					AND jig_id = @JID_OLD

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
							, mc_no
							, record_class
					) 
					values (
							  (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
							, GETDATE()
							, @JID_OLD
							, (SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JID_OLD)
							, NULL, GETDATE()
							, @OPID
							, @OPNo
							, 'To Machine'
							, NULL
							, 11
					)

		END 
		--//////////// SOCKET NULL
		IF NOT EXISTS ( SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE machine_id = @MC_ID AND idx =  21) 
		BEGIN

		 
			--//////////UPDATE JIG NEW
			UPDATE APCSProDB.trans.jigs 
			SET		  location_id	= NULL
					, status		= 'On Machine'
					, [jig_state]	= 12
					, updated_at	= GETDATE()
					, updated_by	= @OPID 
			WHERE id = @JIG_ID

			INSERT INTO APCSProDB.trans.machine_jigs
			(		machine_id
					,idx
					,jig_id
					,created_at
					,created_by
			) 
			VALUES
			(		@MC_ID
					,21
					,@JIG_ID
					,GETDATE()
					,@OPID
			)

			--//////////Insert JIG Record On Machine
			INSERT INTO APCSProDB.trans.jig_records 
			(		  [day_id]
					, [record_at]
					, [jig_id]
					, [jig_production_id]
					, [location_id]
					, [created_at]
					, [created_by]
					, [operated_by]
					, transaction_type
					, mc_no
					, record_class
			) 
			VALUES 
			(		 (SELECT id FROM APCSProDB.trans.days where date_value =  CONVERT(date,GETDATE(),111))
					, GETDATE()
					, @JIG_ID,(SELECT jig_production_id FROM APCSProDB.trans.jigs where id = @JIG_ID)
					, NULL
					, GETDATE()
					, @OPID
					, @OPNo
					, 'On Machine'
					, @MCNo
					, 12
			)			
		END
		 

		IF NOT EXISTS(SELECT 1 FROM APCSProDB.trans.machine_jigs WHERE jig_id = @JIG_ID) BEGIN
			--SELECT    'FALSE' AS Is_Pass
			--		, 'Update Failed. Can not update Socket to machine !!' AS Error_Message_ENG
			--		, N'อัพเดทผิดพลาด Socket ยังไม่ถูกนำเข้าในเครื่องจักร !!' AS Error_Message_THA 
			--		, '' AS Handling

		 		SELECT	  'FALSE'		AS Is_Pass
						, 7				AS code
						, @app_name		AS [app_name]
						, '' 			AS comment
			RETURN
		END
		
			IF (@LifeTime >=  @Safety) 
			BEGIN

				 SELECT	  'TRUE'			AS Is_Pass
							, 6				AS code
							, @app_name			AS [app_name]
							, ''				AS comment
							, @QRCode			AS QRCode
							, smallcode			AS Smallcode
							, p.name  AS [Type] 
							, FORMAT(GETDATE(),'yyyy-MM-dd hh:mm:ss tt')  AS Life_Time
							, FORMAT(j.limit_date,'yyyy-MM-dd hh:mm:ss tt') AS STD_Life_Time
							, FORMAT(DATEADD(month, -1, DATEADD(YEAR, p.expiration_base, p.created_at )), 'yyyy-MM-dd hh:mm:ss tt') AS Safety
							, j.id		AS jig_id 
					FROM APCSProDB.trans.jigs j 
					INNER JOIN APCSProDB.jig.productions p ON jig_production_id = p.id 
					INNER JOIN [APCSProDB].[jig].[production_counters] pc ON pc.production_id = p.id 
					INNER JOIN APCSProDB.trans.jig_conditions jc ON jc.id = j.id
					WHERE barcode = @QRCode
					

			END 
			ELSE
			BEGIN 
		 
					SELECT	  'TRUE'			AS Is_Pass
							, 12				AS code
							, @app_name			AS [app_name]
							, ''				AS comment
							, @QRCode			AS QRCode
							, smallcode			AS Smallcode
							, p.name  AS [Type] 
							, FORMAT(GETDATE(),'yyyy-MM-dd hh:mm:ss tt')  AS Life_Time
							, FORMAT(j.limit_date,'yyyy-MM-dd hh:mm:ss tt') AS STD_Life_Time
							, FORMAT(DATEADD(month, -1, DATEADD(YEAR, p.expiration_base, p.created_at )), 'yyyy-MM-dd hh:mm:ss tt') AS Safety
							, j.id		AS jig_id 
					FROM APCSProDB.trans.jigs j 
					INNER JOIN APCSProDB.jig.productions p ON jig_production_id = p.id 
					INNER JOIN [APCSProDB].[jig].[production_counters] pc ON pc.production_id = p.id 
					INNER JOIN APCSProDB.trans.jig_conditions jc ON jc.id = j.id
					WHERE barcode = @QRCode
			END 
		
		END TRY
		BEGIN CATCH

			--SELECT	  'FALSE' AS Is_Pass
			--		, 'Update Failed !!' AS Error_Message_ENG
			--		, N'การบันทึกข้อมูล sample Good/Ng ผิดพลาด !!' AS Error_Message_THA 
			--		, '' AS Handling

				SELECT	 'FALSE'		AS Is_Pass
						, 8				AS code
						, @app_name		AS [app_name]
						, '' 			AS comment
		END CATCH

	END
	ELSE BEGIN

		IF @State =  12  --'On Machine'
		BEGIN  

			DECLARE @MCOld AS VARCHAR(50)

			SET @MCOld = (  SELECT TOP 1 machines.name 
							FROM APCSProDB.trans.jigs 
							LEFT JOIN APCSProDB.trans.machine_jigs 
							ON machine_jigs.jig_id = jigs.id 
							LEFT JOIN APCSProDB.mc.machines 
							ON machines.id = machine_jigs.machine_id
							WHERE jigs.id = @JIG_ID
						 )

			IF @MCOld <> @MCNo BEGIN

				--SELECT	  'FALSE' AS Is_Pass
				--		, N'This JIG ('+ @Smallcode + N') Is use on another Machine ('+ @MCOld + N') !!' AS Error_Message_ENG
				--		, N'JIG นี้ ('+ @Smallcode + N') ถูกใช้งานอยู่ที่ Machine เครื่องอื่น ('+ @MCOld + N') !!' AS Error_Message_THA
				--		, N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling

				SELECT	 'FALSE'		AS Is_Pass
						, 3				AS code
						, @app_name		AS [app_name]
						, @MCOld		AS comment

				RETURN

			END

					--/////////////// RETURN DATA

					IF (@LifeTime >=  @Safety) 
					BEGIN

							 SELECT	  'TRUE'			AS Is_Pass
										, 6				AS code
										, @app_name			AS [app_name]
										, ''				AS comment
										, @QRCode			AS QRCode
										, smallcode			AS Smallcode
										, p.name  AS [Type] 
										, FORMAT(GETDATE(),'yyyy-MM-dd hh:mm:ss tt')  AS Life_Time
										, FORMAT(j.limit_date,'yyyy-MM-dd hh:mm:ss tt') AS STD_Life_Time
										, FORMAT(DATEADD(month, -1, DATEADD(YEAR, p.expiration_base, p.created_at )), 'yyyy-MM-dd hh:mm:ss tt') AS Safety
										, j.id		AS jig_id 
								FROM APCSProDB.trans.jigs j 
								INNER JOIN APCSProDB.jig.productions p ON jig_production_id = p.id 
								INNER JOIN [APCSProDB].[jig].[production_counters] pc ON pc.production_id = p.id 
								INNER JOIN APCSProDB.trans.jig_conditions jc ON jc.id = j.id
								WHERE barcode = @QRCode
					

					END 
					ELSE
					BEGIN 
								SELECT    'TRUE'		AS Is_Pass
										, 12			AS code
										, @app_name		AS [app_name]
										, ''			AS comment
										, @QRCode		AS QRCode
										, smallcode		AS Smallcode
										, p.name		AS [Type]
										, GETDATE()		AS Life_Time
										, FORMAT(j.limit_date,'yyyy-MM-dd hh:mm:ss tt') AS STD_Life_Time
										, DATEADD(month, -1, DATEADD(YEAR, p.expiration_base, p.created_at )) AS Safety
										, j.id AS jig_id 
								FROM APCSProDB.trans.jigs j 
								INNER JOIN APCSProDB.jig.productions p ON jig_production_id = p.id 
								INNER JOIN [APCSProDB].[jig].[production_counters] pc ON pc.production_id = p.id 
								INNER JOIN APCSProDB.trans.jig_conditions jc ON jc.id = j.id
								WHERE barcode = @QRCode
						END 
		END
		ELSE BEGIN

			--SELECT    'FALSE' AS Is_Pass
			--		, 'Socket ('+ (smallcode ) + ') status is not scan out of stock.' AS Error_Message_ENG
			--		, 'Socket ('+ (smallcode) + N') ยังไม่ถูกสแกนออกจาก Stock !!' AS Error_Message_THA 
			--		, '' AS Handling
			--FROM	APCSProDB.trans.jigs 
			--WHERE	barcode = @QRCode

				SELECT	 'FALSE'		AS Is_Pass
						, 4				AS code
						, @app_name		AS [app_name]
						, '' 			AS comment
			RETURN
		END
	END
END
