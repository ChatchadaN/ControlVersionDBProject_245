
CREATE PROCEDURE [lsms].[sp_set_lot_information] 
	-- Add the parameters for the stored procedure here
	  @LotNo VARCHAR(20)
	, @Type CHAR(20)
	, @SLine CHAR(3)
	, @ProductCode CHAR(20)
	, @RohmProductCode CHAR(20)
	, @TRNo CHAR(11)
	, @Spec CHAR(3)
	, @Pack CHAR(5)
	, @HFERank CHAR(6)
	, @Marking1 VARCHAR(14)
	, @Marking2 VARCHAR(14)
	, @Marking3 VARCHAR(14)
	, @MStamp CHAR(1)
	, @WStamp CHAR(2)
	, @ReceivingCateg CHAR(1)
	, @ProductCateg CHAR(2)
	, @OrderNo VARCHAR(15)
	, @InputDate DATETIME
	, @OutputDate DATETIME
	, @InputQty INT
	, @OutputQty INT
	, @PackUnitQty INT
	, @InputProcCode CHAR(6)
	, @OutputProcCode CHAR(6)
	, @RouteNo CHAR(6)
	, @Priority TINYINT = NULL
	, @ReInputLot BIT
	, @UseOldLotNo BIT
	, @LotCompQty INT
	, @LotCancelQty INT
	, @LotCompDate DATETIME = NULL
	, @WorkslipPrinted BIT 
	, @ProductLabelPrinted BIT
	, @FuntionType INT ---# 1: LSMS, 2: RCS
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--!------------------------------------------------------------------------------------------------------!--
	--add log date modify : 2024.DEC.04 Time : 11.49 by Aomsin
	--!------------------------------------------------------------------------------------------------------!--
	------------------------------------------------------------------------------------------------------------
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
		, 'EXEC [lsms].[sp_set_lot_information]  @LotNo = ''' + ISNULL(@LotNo, '') 
				+ ''', @Type = ''' + ISNULL(@Type,'') 
				+ ''', @SLine = ''' + ISNULL(@SLine,'') 
				+ ''', @ProductCode = ''' + ISNULL(@ProductCode,'') 
				+ ''', @RohmProductCode = ''' + ISNULL(@RohmProductCode,'') 
				+ ''', @TRNo = ''' + ISNULL(@TRNo,'') 
				+ ''', @Spec = ''' + ISNULL(@Spec,'') 
				+ ''', @Pack = ''' + ISNULL(@Pack,'') 
				+ ''', @HFERank = ''' + ISNULL(@HFERank,'') 
				+ ''', @Marking1 = ''' + ISNULL(@Marking1,'') 
				+ ''', @Marking2 = ''' + ISNULL(@Marking2,'') 
				+ ''', @Marking3 = ''' + ISNULL(@Marking3,'') 
				+ ''', @MStamp = ''' + ISNULL(@MStamp,'') 
				+ ''', @ReceivingCateg = ''' + ISNULL(@ReceivingCateg,'') 
				+ ''', @ProductCateg = ''' + ISNULL(@ProductCateg,'') 
				+ ''', @OrderNo = ''' + ISNULL(@OrderNo,'') 
				+ ''', @InputDate = ''' + ISNULL(CAST(@InputDate AS varchar(10)),'') 
				+ ''', @OutputDate = ''' + ISNULL(CAST(@OutputDate AS varchar(10)),'') 
				+ ''', @InputQty = ''' + ISNULL(CAST(@InputQty AS varchar(10)),'') 
				+ ''', @OutputQty = ''' + ISNULL(CAST(@OutputQty AS varchar(10)),'') 
				+ ''', @PackUnitQty = ''' + ISNULL(CAST(@PackUnitQty AS varchar(10)),'') 
				+ ''', @InputProcCode = ''' + ISNULL(@InputProcCode,'') 
				+ ''', @OutputProcCode = ''' + ISNULL(@OutputProcCode,'') 
				+ ''', @RouteNo = ''' + ISNULL(@RouteNo,'') 
				+ ''', @Priority = ''' + ISNULL(CAST(@Priority AS varchar(5)),'') 
				+ ''', @ReInputLot = ''' + ISNULL(CAST(@ReInputLot AS varchar(2)),'') 
				+ ''', @UseOldLotNo = ''' + ISNULL(CAST(@UseOldLotNo AS varchar(2)),'') 
				+ ''', @LotCompQty = ''' + ISNULL(CAST(@LotCompQty AS varchar(2)),'') 
				+ ''', @LotCancelQty = ''' + ISNULL(CAST(@LotCancelQty AS varchar(2)),'') 
				+ ''', @LotCompDate = ''' + ISNULL(CAST(@LotCompDate AS varchar(2)),'') 
				+ ''', @WorkslipPrinted = ''' + ISNULL(CAST(@WorkslipPrinted AS varchar(2)),'') 
				+ ''', @ProductLabelPrinted = ''' + ISNULL(CAST(@ProductLabelPrinted AS varchar(2)),'') 
				+ ''', @FuntionType = ''' + ISNULL(CAST(@FuntionType AS varchar(2)),'') + ''''
		, ISNULL(@LotNo,'NULL');

	--!------------------------------------------------------------------------------------------------------!--
	------------------------------------------------------------------------------------------------------------
	DECLARE @countLot INT = 0
		, @countSurplus INT = 0

	IF EXISTS(SELECT [lot_no] FROM [APCSProDB].[trans].[lot_informations] WHERE [lot_no] = @LotNo)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
			, 'This Lot already contains information !!' AS [Error_Message_ENG]
			, N'Lot นี้มีข้อมูลอยู่แล้ว !!' AS [Error_Message_THA] 
			, N'ติดต่อ ICT' AS [Handling];
		RETURN;
	END

	 -- Insert statements for procedure here
	INSERT INTO [APCSProDB].[trans].[lot_informations]
		( [lot_no]
		, [type_name]
		, [s_line]
		, [product_code]
		, [rohm_product_code]
		, [tr_no]
		, [spec]
		, [pack]
		, [hfe_rank]
		, [marking_1]
		, [marking_2]
		, [marking_3]
		, [m_stamp]
		, [w_stamp]
		, [receiving_categ]
		, [product_categ]
		, [order_no]
		, [input_date]
		, [output_date]
		, [input_qty]
		, [output_qty]
		, [pack_unit_qty]
		, [input_proc_code]
		, [output_proc_code]
		, [route_no]
		, [priority]
		, [re_input_lot]
		, [use_old_lot_no]
		, [lot_comp_qty]
		, [lot_cancel_qty]
		, [lot_comp_date]
		, [workslip_printed]
		, [product_label_printed]
		, [created_at]
		, [created_by]
		, [updated_at]
		, [updated_by]
		, [qty_pass] 
		, [qty_hasuu] )
	VALUES
		( @LotNo
		, @Type
		, @SLine
		, @ProductCode
		, @RohmProductCode
		, @TRNo
		, @Spec
		, @Pack
		, @HFERank
		, @Marking1
		, @Marking2
		, @Marking3
		, @MStamp
		, @WStamp
		, @ReceivingCateg 
		, @ProductCateg
		, @OrderNo
		, @InputDate
		, @OutputDate
		, @InputQty
		, @OutputQty
		, @PackUnitQty
		, @InputProcCode
		, @OutputProcCode
		, @RouteNo
		, @Priority
		, @ReInputLot
		, @UseOldLotNo
		, @LotCompQty
		, @LotCancelQty
		, @LotCompDate
		, @WorkslipPrinted
		, @ProductLabelPrinted
		, GETDATE()
		, 1
		, NULL
		, NULL
		, @InputQty
		, 0 );

	SET @countLot = @@ROWCOUNT;
	IF (@FuntionType = 1)
	BEGIN
		--------------------------------------------------------------------
		IF (@countLot > 0)
		BEGIN
			SELECT 'TRUE' AS [Is_Pass]
				, 'Data added successfully' AS [Error_Message_ENG]
				, N'เพิ่มข้อมูลสำเร็จ' AS [Error_Message_THA] 
				, N'ติดต่อ ICT' AS [Handling];
			RETURN;
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS [Is_Pass]
				, 'Failed to add data [lot_informations]' AS [Error_Message_ENG]
				, N'เพิ่มข้อมูลไม่สำเร็จ' AS [Error_Message_THA] 
				, N'ติดต่อ ICT' AS [Handling];
			RETURN;
		END
		--------------------------------------------------------------------
	END
	ELSE IF (@FuntionType = 2)
	BEGIN
		--------------------------------------------------------------------
		IF (@countLot > 0)
		BEGIN
			DECLARE @trans_surpluses_id INT
			SELECT @trans_surpluses_id = [numbers].[id] + 1 
			FROM [APCSProDB].[trans].[numbers]
			WHERE [numbers].[name] = 'surpluses.id';

			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = @trans_surpluses_id
			WHERE [numbers].[name] = 'surpluses.id';

			INSERT INTO [APCSProDB].[trans].[surpluses]
				( [id]
				, [lot_id]
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
				, [lot_informations].[input_qty] AS [pcs]
				, [lot_informations].[lot_no] AS [serial_no]
				, 3 AS [in_stock]
				, NULL AS [location_id]
				, NULL AS [acc_location_id]
				, GETDATE() AS [created_at]
				, 1 AS [created_by]
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
			WHERE [lot_no] = @LotNo;

			SET @countSurplus = @@ROWCOUNT;
			IF (@countSurplus > 0)
			BEGIN
				SELECT 'TRUE' AS [Is_Pass]
					, 'Data added successfully' AS [Error_Message_ENG]
					, N'เพิ่มข้อมูลสำเร็จ' AS [Error_Message_THA] 
					, N'ติดต่อ ICT' AS [Handling];
				RETURN;		
			END
			ELSE
			BEGIN
			SELECT 'FALSE' AS [Is_Pass]
				, 'Failed to add data [surpluses]' AS [Error_Message_ENG]
				, N'เพิ่มข้อมูลไม่สำเร็จ' AS [Error_Message_THA] 
				, N'ติดต่อ ICT' AS [Handling];
			RETURN;
		END
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS [Is_Pass]
				, 'Failed to add data' AS [Error_Message_ENG]
				, N'เพิ่มข้อมูลไม่สำเร็จ' AS [Error_Message_THA] 
				, N'ติดต่อ ICT' AS [Handling];
			RETURN;
		END
		--------------------------------------------------------------------
	END
	ELSE
	BEGIN
		--------------------------------------------------------------------
		SELECT 'FALSE' AS [Is_Pass]
			, 'Function not found !!' AS [Error_Message_ENG]
			, N'ไม่พบ function นี้!!' AS [Error_Message_THA] 
			, N'ติดต่อ ICT' AS [Handling];
		RETURN;
		--------------------------------------------------------------------
	END
END
