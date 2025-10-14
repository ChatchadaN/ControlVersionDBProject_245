-- =============================================
-- Author:		KITTITAT
-- =============================================
CREATE PROCEDURE [trans].[sp_get_carrier_001]
	@lot_no nvarchar(20) = NULL,
	@carrier_no varchar(11) = NULL,
	@next_carrier_no varchar(11) = NULL,
	@mc_no varchar(50) = NULL, 
	@app_name varchar(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	---------------------------------------------------------
	--- LOG
	---------------------------------------------------------
	INSERT INTO [APIStoredProDB].[dbo].[exec_sp_history]
		([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no])
	SELECT GETDATE()
		, '4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [APIStoredProVersionDB].[trans].[sp_get_carrier_001] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') 
			+ ''', @carrier_no = ''' + ISNULL(CAST(@carrier_no AS varchar),'') 
			+ ''', @next_carrier_no = ''' + ISNULL(CAST(@next_carrier_no AS varchar),'') 
			+ ''', @mc_no = ''' + ISNULL(CAST(@mc_no AS varchar),'') 
			+ ''', @app_name = ''' + ISNULL(CAST(@app_name AS varchar),'') + ''''
		, 'carrier'
	---------------------------------------------------------
	--- Declare
	---------------------------------------------------------	
	DECLARE @dcarrier_no VARCHAR(20) = NULL
	DECLARE @dnext_carrier_no VARCHAR(20) = NULL
	---------------------------------------------------------
	--- Check @Parameter
	---------------------------------------------------------	
	IF ((@carrier_no IS NOT NULL AND @carrier_no != '') AND (@next_carrier_no IS NOT NULL AND @next_carrier_no != ''))
	BEGIN
		GOTO Alls
	END
	ELSE BEGIN
		IF ((@carrier_no IS NULL OR @carrier_no = '') AND (@next_carrier_no IS NULL OR @next_carrier_no = ''))
		BEGIN
			GOTO Nulls
		END
		ELSE BEGIN
			IF (@carrier_no IS NOT NULL AND @carrier_no != '')
			BEGIN
				GOTO CheckCarrier
			END
			ELSE BEGIN
				GOTO CheckNextCarrier
			END
		END
	END
	---------------------------------------------------------
	--- Function
	---------------------------------------------------------
	Alls:
		SELECT 'FALSE' as Is_Pass
			, 'Please select Carrier or NextCarrier !!' AS Error_Message_ENG
			, N'กรุณาเลือก Carrier/NextCarrier !!' AS Error_Message_THA
			, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
		RETURN;

	Nulls:
		SELECT 'FALSE' as Is_Pass
			, 'Carrier is null and NextCarrier is null !!' AS Error_Message_ENG
			, N'Carrier และ NextCarrier เป็นค่าว่าง !!' AS Error_Message_THA
			, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
		RETURN;

	--------------------------------------------------------------------------------------
	Carrier:
		SET @dnext_carrier_no = (SELECT next_carrier_no FROM APCSProDB.trans.lots WHERE next_carrier_no = @carrier_no)
		IF (@dnext_carrier_no IS NOT NULL) BEGIN
			PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- UPDATE IS FAIL')
			SELECT 'FALSE' as Is_Pass
				, 'Carrier is usered to next_carrier_no !!' AS Error_Message_ENG
				, N'Carrier ถูกใช้งานเป็น next_carrier_no แล้ว !!' AS Error_Message_THA
				, N'กรุณาตรวจสอบข้อมูล !!' AS Handling
		END
		ELSE BEGIN
			IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE carrier_no = @carrier_no  AND wip_state = 20) BEGIN
				PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- UPDATE IS FAIL')
				SELECT 'FALSE' as Is_Pass
					, 'Carrier is usered !!' AS Error_Message_ENG
					, N'Carrier ถูกใช้งานแล้ว !!' AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูล !!' AS Handling
			END
			ELSE BEGIN
				SELECT 'TRUE' as Is_Pass
					, '' AS Error_Message_ENG
					, N'' AS Error_Message_THA
					, N'' AS Handling
			END
		END
		RETURN;
	
	CheckCarrier:
		IF (LEN(@carrier_no) = 11)
		BEGIN
			-----------------------------------------------
			IF (SUBSTRING(@carrier_no,4,1)= '-' AND SUBSTRING(@carrier_no,7,1) = '-')
			BEGIN
				GOTO Carrier
			END
			ELSE BEGIN
				GOTO CarrierErrorFormat
			END
			-----------------------------------------------
		END
		ELSE BEGIN
			GOTO CarrierErrorFormat
		END

	CarrierErrorFormat:
		SELECT 'FALSE' as Is_Pass
				, 'Carrier format is invalid !!' AS Error_Message_ENG
				, N'รูปแบบ Carrier ไม่ถูกต้อง !!' AS Error_Message_THA
				, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
		RETURN;
	--------------------------------------------------------------------------------------

	NextCarrier:
		SET @dcarrier_no = (SELECT carrier_no FROM APCSProDB.trans.lots WHERE carrier_no = @next_carrier_no)
		IF (@dcarrier_no IS NOT NULL) BEGIN
			SELECT 'FALSE' as Is_Pass
				, 'Carrier is usered to carrier_no !!' AS Error_Message_ENG
				, N'Carrier ถูกใช้งานเป็น carrier_no แล้ว !!' AS Error_Message_THA
				, N'กรุณาตรวจสอบข้อมูล !!' AS Handling
		END
		ELSE BEGIN
			IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE next_carrier_no = @next_carrier_no  AND wip_state = 20) BEGIN
				SELECT 'FALSE' as Is_Pass
					, 'Carrier is usered !!' AS Error_Message_ENG
					, N'Carrier ถูกใช้งานแล้ว !!' AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูล !!' AS Handling
			END
			ELSE BEGIN
				SELECT 'TRUE' as Is_Pass
					, '' AS Error_Message_ENG
					, N'' AS Error_Message_THA
					, N'' AS Handling
			END
		END
		RETURN;

	CheckNextCarrier:
		IF (LEN(@next_carrier_no) = 11)
		BEGIN
			-----------------------------------------------
			IF (SUBSTRING(@next_carrier_no,4,1)= '-' AND SUBSTRING(@next_carrier_no,7,1) = '-')
			BEGIN
				GOTO NextCarrier
			END
			ELSE BEGIN
				GOTO NextCarrierErrorFormat
			END
			-----------------------------------------------
		END
		ELSE BEGIN
			GOTO NextCarrierErrorFormat
		END

	NextCarrierErrorFormat:
		SELECT 'FALSE' as Is_Pass
				, 'NextCarrier format is invalid !!' AS Error_Message_ENG
				, N'รูปแบบ NextCarrier ไม่ถูกต้อง !!' AS Error_Message_THA
				, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
		RETURN;
	--------------------------------------------------------------------------------------
END
