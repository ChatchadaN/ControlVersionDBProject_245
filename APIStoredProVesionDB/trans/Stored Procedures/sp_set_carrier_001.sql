-- =============================================
-- Author:		KITTITAT
-- =============================================
CREATE PROCEDURE [trans].[sp_set_carrier_001]
	@lot_no nvarchar(20),
	@carrier_no varchar(11) = NULL,
	@mc_no varchar(50) = NULL, 
	@app_name varchar(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' START [trans].[sp_set_carrier_001]')
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
		, 'EXEC [APIStoredProVersionDB].[trans].[sp_set_carrier_001] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') 
			+ ''', @carrier_no = ''' + ISNULL(CAST(@carrier_no AS varchar),'') 
			+ ''', @mc_no = ''' + ISNULL(CAST(@mc_no AS varchar),'') 
			+ ''', @app_name = ''' + ISNULL(CAST(@app_name AS varchar),'') + ''''
		, 'carrier'
	---------------------------------------------------------
	--- Declare
	---------------------------------------------------------	
	DECLARE @return_data BIT
	DECLARE @carrier_data VARCHAR(11)
	DECLARE @dcarrier_no VARCHAR(20) = NULL
	DECLARE @dnext_carrier_no VARCHAR(20) = NULL
	DECLARE @dwip_state VARCHAR(20) = NULL
	---------------------------------------------------------
	--- UPDATE
	---------------------------------------------------------
	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' <-- START Check format XXX-XX-XXXX')
	IF (LEN(@carrier_no) = 11)
	BEGIN
		-----------------------------------------------
		IF (SUBSTRING(@carrier_no,4,1)= '-' AND SUBSTRING(@carrier_no,7,1) = '-')
		BEGIN
			PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- FORMAT IS PASS')
			SET @return_data = 1
		END
		ELSE BEGIN
			PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- FORMAT IS FAIL')
			SET @return_data = 0
		END
		-----------------------------------------------
	END
	ELSE BEGIN
		PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- FORMAT IS FAIL')
		SET @return_data = 0
	END
	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --> END Check format XXX-XX-XXXX')
	------------------------------------------------------------------------------------
	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' <-- START Check update')
	IF (@return_data = 1)
	BEGIN
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

				IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE carrier_no = @carrier_no) BEGIN
					---- clear carrier
					--UPDATE APCSProDB.trans.lots
					--	SET carrier_no =  '-'
					--WHERE carrier_no = @carrier_no;
					PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- CLEAR CARRIER ' + @carrier_no)
				END

				---- update carrier
				--UPDATE APCSProDB.trans.lots
				--	SET carrier_no =  @carrier_no
				--WHERE lot_no = @lot_no;
				PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- UPDATE CARRIER ' + @carrier_no + ' TO LOT ' + @lot_no)

				PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- UPDATE IS PASS')
				SELECT 'TRUE' as Is_Pass
					, '' AS Error_Message_ENG
					, N'' AS Error_Message_THA
					, N'' AS Handling
					, @carrier_no as carrier_no
					, @lot_no as lot_no
			END
		END
	END
	ELSE BEGIN
		PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- UPDATE IS FAIL')
		SELECT 'FALSE' as Is_Pass
			, 'Carrier format is invalid !!' AS Error_Message_ENG
			, N'รูปแบบ Carrier ไม่ถูกต้อง !!' AS Error_Message_THA
			, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
	END
	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --> END Check update')
	----------------------------------------------------------------------------------------------
	PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' END [trans].[sp_set_carrier_001]')
END
