
CREATE PROCEDURE [tg].[sp_get_version_label_for_tp]
	-- Add the parameters for the stored procedure here
	@lotno VARCHAR(20), 
	@qrcode_detail CHAR(90)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text] 
		, [lot_no] ) 
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [tg].[sp_get_version_label_for_tp] @lotno = ''' + ISNULL(@LotNo ,'NULL') + ''''
			+ ', @qrcode_detail = ''' + ISNULL(@qrcode_detail ,'NULL') + ''''
		, @LotNo;

	DECLARE @qr_lot_no VARCHAR(10)
		, @qr_device VARCHAR(19)
		, @qr_rank VARCHAR(2)
		, @qr_version VARCHAR(1) 
		, @qr_qty VARCHAR(6)
		, @qr_reel VARCHAR(2)
		, @db_device VARCHAR(19)
		, @db_rank VARCHAR(2)
		, @db_version VARCHAR(1) 
		, @db_qty VARCHAR(6)
		, @db_reel VARCHAR(2)
		, @universal VARCHAR(5)

	------------------------------------------------------------------
	-- # เช็ค QR
	------------------------------------------------------------------
	IF (@qrcode_detail = '') 
	BEGIN
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no] )
		SELECT GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: คิวอาร์โค้ดเป็นค่าว่าง' 
			, ISNULL(@lotno,'NULL');

		SELECT 'FALSE' AS Status 
			, 'QR code is empty. !!' AS Error_Message_ENG
			, N'คิวอาร์โค้ดเป็นค่าว่าง !!' AS Error_Message_THA 
			, N'กรุณาติดต่อ System' AS Handling;
		RETURN;
	END

	------------------------------------------------------------------
	-- # set ค่า ให้ตัวแปร
	------------------------------------------------------------------
	SET @qr_lot_no = SUBSTRING(@qrcode_detail,26,10);
	SET @qr_device = SUBSTRING(@qrcode_detail,1,19);
	SET @qr_rank = RIGHT(REPLACE(@qr_device,' ',''),2);
	SET @qr_version = SUBSTRING(@qrcode_detail,36,1);
	SET @qr_qty = SUBSTRING(@qrcode_detail,20,6);
	SET @qr_reel = CAST(SUBSTRING(@qrcode_detail,37,2) AS INT);

	------------------------------------------------------------------
	-- # เช็ค @qr_lot_no กับ @lot_no
	------------------------------------------------------------------
	IF (@qr_lot_no != @lotno)
	BEGIN
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no] )
		SELECT GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: lot_no ไม่ตรงกับ label' 
			, ISNULL(@lotno,'NULL');

		SELECT 'FALSE' AS Status 
			, 'lot_no do not match label. !!' AS Error_Message_ENG
			, N'lot_no ไม่ตรงกับ label !!' AS Error_Message_THA 
			, N'กรุณาติดต่อ System' AS Handling;
		RETURN;
	END

	--------------------------------------------------------------
	-- # เช็คข้อมูลจากฐานข้อมูล
	------------------------------------------------------------------
	DECLARE @pc_code INT

	SELECT @pc_code = [lots].[pc_instruction_code]
		, @db_device = [device_names].[name]
		, @db_rank = [device_names].[tp_rank]
		, @universal = [device_names].[universal_tp_rank]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
	WHERE [lots].[lot_no] = @lotno;

	IF (@qr_device != @db_device)
	BEGIN
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no] )
		SELECT GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: ReelLabel DeviceName = ' + ISNULL(@qr_device, '') 
				+ ' WorkingSlip DeviceName = ' + ISNULL(@db_device, '')
			, ISNULL(@lotno,'NULL');

		SELECT 'FALSE' AS Status 
			, 'ReelLabel DeviceName = ' + ISNULL(@qr_device, '') + ' WorkingSlip DeviceName = ' + ISNULL(@db_device, '') AS Error_Message_ENG
			, N'ReelLabel DeviceName = ' + ISNULL(@qr_device, '') + ' WorkingSlip DeviceName = ' + ISNULL(@db_device, '') AS Error_Message_THA 
			, N'กรุณาติดต่อ System' AS Handling;
		RETURN;
	END
	ELSE IF (@qr_rank != @db_rank)
	BEGIN
		-- # check universal
		IF (@universal = '' OR @universal IS NULL)
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: ReelLabel TPRank = ' + ISNULL(@qr_rank, '') 
					+ ' WorkingSlip TPRank = ' + ISNULL(@db_rank, '')
				, ISNULL(@lotno,'NULL');

			SELECT 'FALSE' AS Status 
				, 'ReelLabel TPRank = ' + ISNULL(@qr_rank, '') + ' WorkingSlip TPRank = ' + ISNULL(@db_rank, '')  AS Error_Message_ENG
				, N'ReelLabel TPRank = ' + ISNULL(@qr_rank, '') + ' WorkingSlip TPRank = ' + ISNULL(@db_rank, '') AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
	END

	--IF ( SUBSTRING( @lotno, 5, 1 ) = 'D' AND @pc_code IN (13,1) ) --close 2024/05/07 time : 17.22 by Aomsin
	IF (@pc_code = 13)
	BEGIN
		DECLARE @GetTypeofLabel int = 0

		IF(SUBSTRING( @lotno, 5, 1 ) = 'D' )  --add condition check type of lot [PC-Request Work] 2025/01/29 time : 10.00 by Aomsin
		BEGIN
			SELECT @GetTypeofLabel = 20
		END
		ELSE
		BEGIN
			SELECT @GetTypeofLabel = 2
		END

		IF EXISTS (SELECT 1 FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @qr_lot_no AND [no_reel] = @qr_reel AND [type_of_label] = @GetTypeofLabel)
		BEGIN
			SELECT @db_version = SUBSTRING([qrcode_detail],36,1)
				, @db_qty = SUBSTRING([qrcode_detail],20,6)
				, @db_reel = CAST(SUBSTRING([qrcode_detail],37,2) AS INT)
			FROM [APCSProDB].[trans].[label_issue_records]
			WHERE [lot_no] = @qr_lot_no
				AND [no_reel] = @qr_reel 
				AND [type_of_label] = @GetTypeofLabel;
		END
		ELSE
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: ไม่พบ hasuu shipment label ใน database' 
				, ISNULL(@lotno,'NULL');

			SELECT 'FALSE' AS Status 
				, 'not found hasuu shipment label in database. !!' AS Error_Message_ENG
				, N'ไม่พบ hasuu shipment label ใน database !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
	END
	ELSE
	BEGIN
		IF EXISTS (SELECT 1 FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @qr_lot_no AND [no_reel] = @qr_reel AND [type_of_label] = 3)
		BEGIN
			SELECT @db_version = SUBSTRING([qrcode_detail],36,1)
				, @db_qty = SUBSTRING([qrcode_detail],20,6)
				, @db_reel = CAST(SUBSTRING([qrcode_detail],37,2) AS INT)
			FROM [APCSProDB].[trans].[label_issue_records]
			WHERE [lot_no] = @qr_lot_no
				AND [no_reel] = @qr_reel 
				AND [type_of_label] = 3;
		END
		ELSE
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: ไม่พบ reel label ใน database' 
				, ISNULL(@lotno,'NULL');

			SELECT 'FALSE' AS Status 
				, 'not found reel label in database. !!' AS Error_Message_ENG
				, N'ไม่พบ reel label ใน database !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
	END

	------------------------------------------------------------------
	-- # เช็คข้อมูลว่าตรงกันไหม ?
	------------------------------------------------------------------
	IF (@qr_reel = @db_reel AND @qr_version = @db_version AND @qr_qty = @db_qty)
	BEGIN
		----# 1
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no] )
		SELECT GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] SUCCESS: ข้อมูลถูกต้อง' 
			, ISNULL(@lotno,'NULL');

		SELECT 'TRUE' AS Status 
			, 'The information is correct.' AS Error_Message_ENG
			, N'ข้อมูลถูกต้อง' AS Error_Message_THA 
			, N'' AS Handling;
		RETURN;
		----# 1
	END
	ELSE
	BEGIN
		----# 2
		IF (@qr_reel != @db_reel AND @qr_version != @db_version AND @qr_qty != @db_qty) --reel,version,qty
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: reel, version และ QTY ไม่ตรง' 
				, ISNULL(@lotno,'NULL');

			SELECT 'FALSE' AS Status 
				, 'reel ,version and QTY do not match. !!' AS Error_Message_ENG
				, N'reel, version และ QTY ไม่ตรง !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
		ELSE IF (@qr_reel != @db_reel AND @qr_version != @db_version AND @qr_qty = @db_qty) --reel,version
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: reel และ version ไม่ตรง' 
				, ISNULL(@lotno,'NULL');

			SELECT 'FALSE' AS Status 
				, 'reel and label version do not match. !!' AS Error_Message_ENG
				, N'reel และ version ไม่ตรง !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
		ELSE IF (@qr_reel != @db_reel AND @qr_version = @db_version AND @qr_qty != @db_qty) --reel,qty
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: reel และ QTY ไม่ตรง' 
				, ISNULL(@lotno,'NULL');

			SELECT 'FALSE' AS Status 
				, 'reel and QTY do not match. !!' AS Error_Message_ENG
				, N'reel และ QTY ไม่ตรง !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
		ELSE IF (@qr_reel = @db_reel AND @qr_version != @db_version AND @qr_qty != @db_qty) --version,qty
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: version และ QTY ไม่ตรง' 
				, ISNULL(@lotno,'NULL');

			SELECT 'FALSE' AS Status 
				, 'label version and QTY do not match. !!' AS Error_Message_ENG
				, N'label version และ QTY ไม่ตรง !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
		ELSE IF (@qr_reel != @db_reel AND @qr_version = @db_version AND @qr_qty = @db_qty) --reel
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: reel ไม่ตรง' 
				, ISNULL(@lotno,'NULL');

			SELECT 'FALSE' AS Status 
				, 'reel do not match. !!' AS Error_Message_ENG
				, N'reel ไม่ตรง !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
		ELSE IF (@qr_reel = @db_reel AND @qr_version != @db_version AND @qr_qty = @db_qty) --version 
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: version ไม่ตรง' 
				, ISNULL(@lotno,'NULL');

			SELECT 'FALSE' AS Status 
				, 'label version do not match. !!' AS Error_Message_ENG
				, N'label version ไม่ตรง !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
		ELSE IF (@qr_reel = @db_reel AND @qr_version = @db_version AND @qr_qty != @db_qty) --qty
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: QTY ไม่ตรง' 
				, ISNULL(@lotno,'NULL');

			SELECT 'FALSE' AS Status 
				, 'QTY do not match. !!' AS Error_Message_ENG
				, N'QTY ไม่ตรง !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
		ELSE
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, N'EXEC RESULT [tg].[sp_get_version_label_for_tp] ERROR: ไม่เข้าเงื่อนไข' 
				, ISNULL(@lotno,'NULL');

			SELECT 'FALSE' AS Status 
				, 'condition not match. !!' AS Error_Message_ENG
				, N'ไม่เข้าเงื่อนไข !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
		----# 2
	END
END
