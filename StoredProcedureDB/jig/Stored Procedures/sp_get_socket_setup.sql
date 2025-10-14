-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_socket_setup]
	-- Add the parameters for the stored procedure here
	@QRCodeIn AS VARCHAR(100),
	@QRCodeOut AS VARCHAR(100) = NULL,
	@MCNo AS VARCHAR(50),
	@LotNo AS VARCHAR(10) = NULL, 
	@Package AS VARCHAR(50) = NULL,
	@DataInput AS INT = 0,
	@OPNo AS VARCHAR(6) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		DECLARE @JIG_ID_IN AS INT,
		@JIG_ID_OUT AS INT,
		@MC_ID AS INT ,
		@Status_JIG_IN AS varchar(50),
		@Status_JIG_OUT AS varchar(50),
		@STDLifeTime AS INT,
		@LifeTime AS INT,
		@Safety AS INT,
		@Accu AS INT,
		@OPID AS INT,
		@SmallcodeIn AS varchar(10)

	SET @MC_ID = (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo)

	SET @JIG_ID_IN = (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeIn)
	SET @Status_JIG_IN = (SELECT status FROM APCSProDB.trans.jigs WHERE id = @JIG_ID_IN)
	SET @SmallcodeIn = (SELECT jigs.smallcode FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeIn)
	
	SET @JIG_ID_OUT = (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeOut)	
	SET @Status_JIG_OUT = (SELECT status FROM APCSProDB.trans.jigs WHERE id = @JIG_ID_OUT)
	
	 	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history_jig]
	(	
				[record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, lot_no
			, jig_id
			, barcode
	)
	SELECT    GETDATE()
			, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, 'EXEC [jig].[sp_get_socket_setup] @JIG_ID = ''' + ISNULL(CAST(@JIG_ID_IN AS nvarchar(MAX)),'') + ''', @QRCodeIn = ''' + ISNULL(CAST(@QRCodeIn AS nvarchar(MAX)),'') + ''', @QRCodeOut = ''' + ISNULL(CAST(@QRCodeOut AS nvarchar(MAX)),'') + ''',@OPNo = ''' 
				+ ISNULL(CAST(@OPNo AS nvarchar(MAX)),'') +  ''',@MCNo = ''' + ISNULL(CAST(@MCNo AS nvarchar(MAX)),'') + ''''
			, @LotNo
			, @JIG_ID_IN
			, @QRCodeIn


	--/////////////////////Check Socket Regist
	IF NOT EXISTS (SELECT jigs.id FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeIn) BEGIN
		SELECT 'FALSE' AS Is_Pass,'This socket is not registered !!' AS Error_Message_ENG
		,N'Socket นี้ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA ,'' AS Handling
		RETURN
	END

	--//////////////////// CHECK MACHINE NUMBER
	IF NOT EXISTS (select top(1) id from APCSProDB.mc.machines where machines.name = @MCNo) BEGIN
		SELECT 'FALSE' AS Is_Pass,'Machine Number is invalid !!' AS Error_Message_ENG
		,N'หมายเลขเครื่องจักรไม่ถูกต้อง !!' AS Error_Message_THA ,'' AS Handling
		RETURN
	END

				--//////////////// SOCKET IN
	IF @Status_JIG_IN <> 'To Machine' BEGIN		

		IF @Status_JIG_IN = 'On Machine' BEGIN
			DECLARE @MCOld AS VARCHAR(50)

			SET @MCOld = (SELECT TOP 1 machines.name FROM APCSProDB.trans.jigs LEFT JOIN
					APCSProDB.trans.machine_jigs ON machine_jigs.jig_id = jigs.id LEFT JOIN 
					APCSProDB.mc.machines ON machines.id = machine_jigs.machine_id WHERE jigs.id = @JIG_ID_IN)

			IF @MCOld <> @MCNo BEGIN
				SELECT 'FALSE' AS Is_Pass,N'This JIG ('+ @SmallcodeIn + N') Is use on another Machine ('+ @MCOld + N') !!' AS Error_Message_ENG,
					N'JIG นี้ ('+ @SmallcodeIn + N') ถูกใช้งานอยู่ที่ Machine เครื่องอื่น ('+ @MCOld + N') !!' AS Error_Message_THA,N'กรุณาตรวจสอบข้อมูลที่เว็บ JIG หรือติดต่อ System' AS Handling
				RETURN
			END
		END
		ELSE BEGIN
			SELECT 'FALSE' AS Is_Pass,'Socket ('+ (smallcode) + ') status is not scan out of stock.' AS Error_Message_ENG
				,'Socket ('+ (smallcode) + N') ยังไม่ถูกสแกนออกจาก Stock !!' AS Error_Message_THA ,'' AS Handling
				FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeIn
			RETURN
		END
	END

	----//////////////////// CHECK SOCKET SAME
	--IF @JIG_ID_OUT = @JIG_ID_IN BEGIN
	--	SELECT 'FALSE' AS Is_Pass,'Socket-IN and Socket-OUT are the same !!' AS Error_Message_ENG
	--	,N'Socket ที่นำเข้า และ Socket ที่นำออกซ้ำกัน !!' AS Error_Message_THA ,'' AS Handling
	--	RETURN
	--END



	----//////////////// SOCKET OUT
	--IF EXISTS((SELECT 1 FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeOut)) AND @Status_JIG_OUT <> 'On Machine' BEGIN		
	--	SELECT 'FALSE' AS Is_Pass,'Socket ('+ (smallcode) + ') status is not on machine.' AS Error_Message_ENG
	--	,'Socket ('+ (smallcode) + N') ไม่ได้อยู่ในเครื่องจักร !!' AS Error_Message_THA ,'' AS Handling
	--	FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeIn
	--	RETURN
	--END

	--//////////////// Check Common Package
	--IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE lot_no = @LotNo) BEGIN
	--	IF NOT EXISTS (SELECT APCSProDB.method.jig_sets.id
	--	FROM      APCSProDB.trans.jigs INNER JOIN
	--							 APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
	--							 APCSProDB.method.jig_set_list ON APCSProDB.jig.productions.id = APCSProDB.method.jig_set_list.jig_group_id INNER JOIN
	--							 APCSProDB.method.jig_sets ON APCSProDB.method.jig_set_list.jig_set_id = APCSProDB.method.jig_sets.id
	--							WHERE APCSProDB.method.jig_sets.name = @Package and APCSProDB.trans.jigs.barcode = @QRCodeIn)
	--	BEGIN	
	--		SELECT    'FALSE' AS Is_Pass,'Socket (' +(smallcode)+ ') is can not use with this package ( '+@Package+' ) !!' AS Error_Message_ENG,
	--		 N'ไม่สามารถใช้ Socket (' +(smallcode)+ ') กับ package ( '+@Package+ N' ) นี้ได้ !!' AS Error_Message_THA ,'' AS Handling
	--		 FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeIn
	--		 RETURN
	--	END
	--END

	--////////////////////Check LifeTime
	
SET @STDLifeTime = (SELECT APCSProDB.jig.production_counters.alarm_value / 1000
						FROM APCSProDB.trans.jigs INNER JOIN
						--APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCodeIn)

	SET @LifeTime = (SELECT (APCSProDB.trans.jig_conditions.value / 1000) + (@DataInput / 1000)
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						where barcode = @QRCodeIn)

	SET @Accu = (SELECT (APCSProDB.trans.jig_conditions.accumulate_lifetime / 1000)
						FROM APCSProDB.trans.jigs INNER JOIN
						APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id
						where barcode = @QRCodeIn)

	SET @Safety = (SELECT APCSProDB.jig.production_counters.warn_value / 1000
						FROM APCSProDB.trans.jigs INNER JOIN
						--APCSProDB.trans.jig_conditions ON APCSProDB.trans.jigs.id = APCSProDB.trans.jig_conditions.id INNER JOIN
						APCSProDB.jig.productions ON APCSProDB.trans.jigs.jig_production_id = APCSProDB.jig.productions.id INNER JOIN
						APCSProDB.jig.production_counters ON APCSProDB.jig.production_counters.production_id = APCSProDB.jig.productions.id
						where barcode = @QRCodeIn)
	
	 
	IF (@LifeTime + @Accu) >= (@STDLifeTime + (@STDLifeTime - @Safety)) BEGIN
		SELECT 'FALSE' AS Is_Pass, 
		'('+(smallcode)+') LifeTime Expire (100%) !!' AS Error_Message_ENG,
		'('+(smallcode)+N') LifeTime หมดอายุการใช้งาน (100%) !!' AS Error_Message_THA ,'' AS Handling
		FROM APCSProDB.trans.jigs WHERE barcode = @QRCodeIn

		RETURN
	END

	--//RETUEN DATA
	--SELECT 'TRUE' AS Is_Pass
	--/////////////// RETURN DATA
	SELECT 'TRUE' AS Is_Pass
		, '' AS Error_Message_ENG
		, '' AS Error_Message_THA 
		, '' AS Handling 
		, @QRCodeIn AS QRCode
		, smallcode  AS Smallcode
		, p.name  AS SocketType 
		, CONVERT(int,((jc.value) / 1000)) AS Life_Time
		, CONVERT(int,(p.expiration_value / 1000)) AS STD_Life_Time
		, CONVERT(int,(jc.accumulate_lifetime + jc.value)/ 1000) AS Acc
		, CONVERT(int,(p.expiration_value - pc.warn_value) / 1000) AS Safety
		, j.id AS jig_id 
		, CONVERT(int,(pc.period_value) / 1000) AS STD_Period

	FROM APCSProDB.trans.jigs j 
	INNER JOIN APCSProDB.jig.productions p ON jig_production_id = p.id 
	INNER JOIN [APCSProDB].[jig].[production_counters] pc ON pc.production_id = p.id 
	INNER JOIN APCSProDB.trans.jig_conditions jc ON jc.id = j.id
	WHERE barcode = @QRCodeIn
END
