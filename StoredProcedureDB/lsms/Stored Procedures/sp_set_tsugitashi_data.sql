
CREATE PROCEDURE [lsms].[sp_set_tsugitashi_data]
	-- Add the parameters for the stored procedure here
	  @master_lot VARCHAR(10)
	, @totalqty INT = null
	, @qty_shipment INT = null
	, @qty_surpluses INT = null
	, @qty_faction INT = null
	, @is_function INT =  0  --> 0 = Tg+Faction, 1 = Tg-0 (no faction)
	, @hasuu_lot TG_List READONLY
	, @emp_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @DIs_Pass nvarchar(max)
		, @DError_Message_ENG nvarchar(max)
		, @DError_Message_THA nvarchar(max)
		, @DHandling nvarchar(max)
		, @ReelStandard int = null

	DECLARE @trans_surpluses_id INT

	--add log date modify : 2024.DEC.04 Time : 11.02 by Aomsin
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		  [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [lsms].[sp_set_tsugitashi_data]  @master_lot = ''' + ISNULL(@master_lot, '') 
				+ ''', @totalqty = ''' + ISNULL(CAST(@totalqty AS VARCHAR(10)),'') 
				+ ''', @qty_shipment = ''' + ISNULL(CAST(@qty_shipment AS VARCHAR(10)),'') 
				+ ''', @qty_surpluses = ''' + ISNULL(CAST(@qty_surpluses AS VARCHAR(10)),'') 
				+ ''', @qty_faction = ''' + ISNULL(CAST(@qty_faction AS VARCHAR(10)),'') 
				+ ''', @emp_id = ''' + ISNULL(CAST(@emp_id AS VARCHAR(10)),'') + ''''
		, ISNULL(@master_lot,'NULL');

	------------------------------------------------------------------------------------------------------
	----- # get standard reel of lot_informations
	------------------------------------------------------------------------------------------------------
	SELECT @ReelStandard = pack_unit_qty from APCSProDB.trans.lot_informations where lot_no = @master_lot
	------------------------------------------------------------------------------------------------------
	----- # insert surpluses
	------------------------------------------------------------------------------------------------------
	IF NOT EXISTS(SELECT [serial_no] FROM [APCSProDB].[trans].[surpluses] WHERE [serial_no] = @master_lot)
	BEGIN
		SELECT @trans_surpluses_id = [numbers].[id] + 1 
		FROM [APCSProDB].[trans].[numbers]
		WHERE [numbers].[name] = 'surpluses.id';

		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = @trans_surpluses_id
		WHERE [numbers].[name] = 'surpluses.id';

		INSERT INTO [APCSProDB].[trans].[surpluses]
			( [id]
			, [lot_id]
			, [surpluses_reel_count]
			, [surpluses_qty]
			, [is_surpluses]
			, [pcs]
			, [serial_no]
			, [in_stock]
			, [location_id]
			, [acc_location_id]
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by]
			, [reprint_count]
			, [pdcd]
			, [qc_instruction]
			, [mark_no]
			, [original_lot_id]
			, [machine_id]
			, [user_code]
			, [product_control_class]
			, [product_class]
			, [production_class]
			, [rank_no]
			, [hinsyu_class]
			, [label_class]
			, [transfer_flag]
			, [transfer_pcs]
			, [stock_class]
			, [is_ability]
			, [comment]
			, [is_test_fttp] )
		SELECT @trans_surpluses_id AS [id]
			, [lot_informations].[id] AS [lot_id]
			, IIF(ISNULL(@ReelStandard,0) = 0,0,(@qty_surpluses/@ReelStandard)) --> surpluses reel count
			, @qty_surpluses --> qty surpluses
			, IIF(@qty_surpluses <> 0,1,null)  --> is have surpluses
			, @qty_faction --> qty hasuu
			, [lot_informations].[lot_no] AS [serial_no]
			, 2 AS [in_stock]
			, NULL AS [location_id]
			, NULL AS [acc_location_id]
			, GETDATE() AS [created_at]
			, @emp_id AS [created_by]
			, NULL AS [updated_at]
			, NULL AS [updated_by]
			, NULL AS [reprint_count]
			, NULL AS [pdcd]
			, NULL AS [qc_instruction]
			, [lot_informations].[marking_1] AS [mark_no]
			, NULL AS [original_lot_id]
			, NULL AS [machine_id]
			, NULL AS [user_code]
			, NULL AS [product_control_class]
			, NULL AS [product_class]
			, NULL AS [production_class]
			, NULL AS [rank_no]
			, NULL AS [hinsyu_class]
			, NULL AS [label_class]
			, NULL AS [transfer_flag]
			, NULL AS [transfer_pcs]
			, NULL AS [stock_class]
			, NULL AS [is_ability]
			, NULL AS [comment]
			, NULL AS [is_test_fttp]
		FROM [APCSProDB].[trans].[lot_informations]
		WHERE [lot_no] = @master_lot;
	
		----# check surpluses
		IF NOT EXISTS(SELECT [serial_no] FROM [APCSProDB].[trans].[surpluses] WHERE [serial_no] = @master_lot)
		BEGIN
			SELECT 'FALSE' AS [Is_Pass]
					, 'Failed to add data [surpluses]' AS [Error_Message_ENG]
					, N'เพิ่มข้อมูลไม่สำเร็จ' AS [Error_Message_THA] 
					, N'ติดต่อ ICT' AS [Handling];
			RETURN;
		END
	END

	----------------------------------------------------------------------------
	----- # insert in trans.lot_combine, trans.lot_combine_records
	----------------------------------------------------------------------------
	EXEC [StoredProcedureDB].[lsms].[sp_set_mixing_tg]
		@master_lot = @master_lot
		, @emp_id = @emp_id
		, @hasuu_lot = @hasuu_lot
		, @is_return = 0
		, @Is_Pass = @DIs_Pass OUTPUT
		, @Error_Message_ENG = @DError_Message_ENG OUTPUT
		, @Error_Message_THA = @DError_Message_THA OUTPUT
		, @Handling = @DHandling OUTPUT;

	IF (@DIs_Pass = 'FALSE')
	BEGIN
		SELECT	@DIs_Pass AS [Is_Pass]
			, @DError_Message_ENG AS [Error_Message_ENG]
			, @DError_Message_THA AS [Error_Message_THA]
			, @DHandling AS [Handling];
		RETURN;
	END

	----------------------------------------------------------------------------
	----- # Update in_stock hasuu_lot
	----------------------------------------------------------------------------
	IF EXISTS(SELECT TOP 1 [lot_no] FROM @hasuu_lot)
	BEGIN
		UPDATE [surpluses]
		SET [surpluses].[in_stock] = 0
			, [surpluses].[updated_at] = GETDATE()
			, [surpluses].[updated_by] = @emp_id
		FROM [APCSProDB].[trans].[surpluses]
		INNER JOIN @hasuu_lot AS [hasuu_lot] ON [surpluses].[serial_no] = [hasuu_lot].[lot_no];
	END

	SELECT 'TRUE' AS [Is_Pass]
		, '' AS [Error_Message_ENG]
		, '' AS [Error_Message_THA]
		, '' AS [Handling];
	RETURN;
END
