-- =============================================
-- Author:		KITTITAT
-- =============================================
CREATE PROCEDURE [trans].[sp_set_carrier_004]
	@lot_no nvarchar(20),
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
		, 'EXEC [APIStoredProVersionDB].[trans].[sp_set_carrier_004] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') 
			+ ''', @carrier_no = ''' + ISNULL(CAST(@carrier_no AS varchar),'') 
			+ ''', @next_carrier_no = ''' + ISNULL(CAST(@next_carrier_no AS varchar),'') 
			+ ''', @mc_no = ''' + ISNULL(CAST(@mc_no AS varchar),'') 
			+ ''', @app_name = ''' + ISNULL(CAST(@app_name AS varchar),'') + ''''
		, 'carrier';
	---------------------------------------------------------
	--- Update
	---------------------------------------------------------	
	IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE carrier_no = @carrier_no) BEGIN
		---- clear carrier
		--UPDATE APCSProDB.trans.lots
		--	SET carrier_no =  '-'
		--WHERE carrier_no = @carrier_no;
		PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- CLEAR CARRIER ' + @carrier_no)
	END

	IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE next_carrier_no = @next_carrier_no) BEGIN
		---- clear next carrier
		--UPDATE APCSProDB.trans.lots
		--	SET next_carrier_no =  '-'
		--WHERE next_carrier_no = @next_carrier_no;
		PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- CLEAR NEXT CARRIER ' + @next_carrier_no)
	END

	SET @carrier_no = ISNULL(@carrier_no,'');
	SET @next_carrier_no = ISNULL(@next_carrier_no,'');

	IF (@carrier_no != '')
	BEGIN
		UPDATE [APCSProDB].[trans].[lots]
		SET [carrier_no] = @carrier_no
		WHERE [lot_no] = @lot_no;
	END
	ELSE IF (@next_carrier_no != '')
	BEGIN
		UPDATE [APCSProDB].[trans].[lots]
		SET [next_carrier_no] = @next_carrier_no
		WHERE [lot_no] = @lot_no;
	END

	SELECT 'TRUE' as Is_Pass
		, '' AS Error_Message_ENG
		, N'' AS Error_Message_THA
		, N'' AS Handling
	--------------------------------------------------------------------------------------
END
