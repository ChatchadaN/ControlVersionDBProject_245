
CREATE PROCEDURE [atom].[sp_set_update_carrier]
	@lot_no nvarchar(20) = NULL,
	@old_carrier_no varchar(11) = NULL,
	@old_next_carrier_no varchar(11) = NULL,
	@carrier_no varchar(11) = NULL,
	@next_carrier_no varchar(11) = NULL,
	@state_action int, --1:change carrier 2:clear carrier
	@state_carrier int, --1:carrier_no 2:next_carrier_no
	@opnumber varchar(10),
	@mc_no varchar(50) = NULL, 
	@app_name varchar(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no])
	SELECT GETDATE()
		, '4' --1 Insert, 2 Update, 3 Delete, 4 StoredProcedure
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [StoredProcedureDB].[atom].[sp_set_update_carrier] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') 
			+ ''', @old_carrier_no = ''' + ISNULL(CAST(@old_carrier_no AS varchar),'') 
			+ ''', @old_next_carrier_no = ''' + ISNULL(CAST(@old_next_carrier_no AS varchar),'') 
			+ ''', @carrier_no = ''' + ISNULL(CAST(@carrier_no AS varchar),'') 
			+ ''', @next_carrier_no = ''' + ISNULL(CAST(@next_carrier_no AS varchar),'') 
			+ ''', @state_action = ' + ISNULL(CAST(@state_action AS varchar),'') 
			+ ', @state_carrier = ' + ISNULL(CAST(@state_carrier AS varchar),'') 
			+ ', @opnumber = ''' + ISNULL(CAST(@opnumber AS varchar),'') 
			+ ''', @mc_no = ''' + ISNULL(CAST(@mc_no AS varchar),'') 
			+ ''', @app_name = ''' + ISNULL(CAST(@app_name AS varchar),'') + ''''
		, @lot_no;

	DECLARE @success_status INT = 0;

	IF (@state_action = 1)
	BEGIN
		--1:change carrier
		IF (@state_carrier = 1)
		BEGIN
			--1:carrier_no
			UPDATE [APCSProDB].[trans].[lots] 
			SET [carrier_no] = @carrier_no 
			WHERE [lot_no] = @lot_no;
			SET @success_status = 1;
		END
		ELSE IF (@state_carrier = 2)
		BEGIN
			--2:next_carrier_no
			UPDATE [APCSProDB].[trans].[lots] 
			SET [next_carrier_no] = @next_carrier_no 
			WHERE [lot_no] = @lot_no;
			SET @success_status = 1;
		END
	END
	ELSE IF (@state_action = 2)
	BEGIN
		--2:clear carrier
		IF (@state_carrier = 1)
		BEGIN
			--1:carrier_no
			UPDATE [APCSProDB].[trans].[lots] 
			SET [carrier_no] = NULL 
			WHERE [lot_no] = @lot_no;
			SET @success_status = 1;
		END
		ELSE IF (@state_carrier = 2)
		BEGIN
			--2:next_carrier_no
			UPDATE [APCSProDB].[trans].[lots] 
			SET [next_carrier_no] = NULL 
			WHERE [lot_no] = @lot_no;
			SET @success_status = 1;
		END
	END

	IF (@success_status = 1)
	BEGIN
		SELECT 'TRUE' as Is_Pass
			, '' AS Error_Message_ENG
			, N'' AS Error_Message_THA
			, N'' AS Handling
		RETURN;
	END
	ELSE
		BEGIN
		SELECT 'FALSE' as Is_Pass
			, 'Contact system !!' AS Error_Message_ENG
			, N'ติดต่อ system !!' AS Error_Message_THA
			, N'ติดต่อ system !!' AS Handling
		RETURN;
	END
END
