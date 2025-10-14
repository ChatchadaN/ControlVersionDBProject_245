
Create PROCEDURE [trans].[sp_set_compare_label_001] 
	 @lot_no VARCHAR(10)
	,@item_no VARCHAR(5)
	,@qr_code1 CHAR(114) = ''
	,@qr_code2 CHAR(114) = ''
	,@empno VARCHAR(6) = NULL 
	,@division_id INT = NULL
	,@source_type VARCHAR(10)
AS
BEGIN TRY 
	IF @source_type IS NULL OR LTRIM(RTRIM(@source_type)) = ''
	BEGIN
		SELECT 'FALSE' AS Is_Pass,
				'Missing source_type parameter.' AS Error_Message_ENG,
				N'กรูณาส่งค่า source_type มาด้วย' AS Error_Message_THA,
				N'Please check the input again.' AS Handling;
		RETURN;
	END

	DECLARE @emp_id INT = NULL;

	SELECT @emp_id = [id]
	FROM [DWH_wh_230].[man].[employees]
	WHERE [emp_code] = @empno

	--================== START: OPM LOGIC ===================
	IF (@source_type = 'OPM')
	BEGIN
		IF (@qr_code2 = '')
		BEGIN
			IF EXISTS(SELECT 1 FROM [AppDB_app_244].[trans].[compare_data_center] WHERE [lot_no] = @lot_no AND [item_no] =  @item_no AND [status] = 1) 
			BEGIN 
				INSERT INTO [AppDB_app_244].[trans].[compare_data_center]
							([lot_no],
							 [item_no],
							 [qrcode_1],
							 [qrcode_2],
							 [status],
							 [create_at],
							 [create_by],
							 [update_at],
							 [emp_no],
							 [division_id])

				VALUES (@lot_no, @item_no, @qr_code1, @qr_code2, 2, GETDATE(), @emp_id, GETDATE(), @empno, @division_id)

				SELECT 'FALSE' AS Is_Pass 
					,'Duplicate : Lot No. and Reel data already exist.' AS Error_Message_ENG
					,N'Lot No. และ Reel No. นี้ มีข้อมูลอยู่แล้ว'  AS Error_Message_THA 
					,N'Please input the data again' AS Handling
				RETURN; 
			END
			ELSE
			BEGIN
				--INSERT INTO [trans].[qr_label_opm_test]
				--			([lot_no],
				--			 [reel],
				--			 [qrcode_1],
				--			 [qrcode_2],
				--			 [status],
				--			 [create_at],
				--			 [update_at],
				--			 [emp_no])

				--VALUES (@lot_no, @reel, @qr_code1, @qr_code2, 1,GETDATE(),GETDATE(),@empno)

				SELECT 'TRUE' AS Is_Pass
					,'Pass : Lot No. and Reel data do not exist.' AS Error_Message_ENG
					,N'Lot No. และ Reel No. นี้ ยังไม่มีข้อมูล' AS Error_Message_THA
					,N'Data inserted successfully.' AS Handling
				RETURN;
			END
		END
		BEGIN
			IF(@qr_code1 <> @qr_code2)
			BEGIN
				INSERT INTO [AppDB_app_244].[trans].[compare_data_center]
							([lot_no],
							 [item_no],
							 [qrcode_1],
							 [qrcode_2],
							 [status],
							 [create_at],
							 [create_by],
							 [update_at],
							 [emp_no],
							 division_id)

				VALUES (@lot_no, @item_no, @qr_code1, @qr_code2, 0, GETDATE(), @emp_id, GETDATE(), @empno, @division_id)

				SELECT 'FALSE' AS Is_Pass 
					,'Fail : QRcodeReel and Drypack do not match.' AS Error_Message_ENG
					,N'Drypack และ Tomson ไม่ตรงกัน'  AS Error_Message_THA 
					,N'Please input the data again' AS Handling
				RETURN; 
			END
			ELSE
			BEGIN
				INSERT INTO [AppDB_app_244].[trans].[compare_data_center]
							([lot_no],
							 [item_no],
							 [qrcode_1],
							 [qrcode_2],
							 [status],
							 [create_at],
							 [create_by],
							 [update_at],
							 [emp_no],
							 division_id)

				VALUES (@lot_no, @item_no, @qr_code1, @qr_code2, 1, GETDATE(), @emp_id, GETDATE(), @empno, @division_id)

				--add query insert
				SELECT 'TRUE' AS Is_Pass
					,'Complate : QRcodeReel and Drypack match.' AS Error_Message_ENG
					,N'Drypack และ Tomson ตรงกัน'  AS Error_Message_THA 
					,N'' AS Handling
				RETURN; 
			END
		END
	END
	--================== END: OPM LOGIC =====================
	
	--================== START: TRDI LOGIC ==================
	ELSE IF (@source_type = 'TRDI')
	BEGIN
		SET @qr_code2 = LEFT(@qr_code2, LEN(@qr_code1));

		IF EXISTS (SELECT 1 FROM [AppDB_app_244].[trans].[compare_data_center] WHERE [lot_no] = @lot_no AND [item_no] = @item_no AND [status] = 1)
		BEGIN
			INSERT INTO [AppDB_app_244].[trans].[compare_data_center]
						([lot_no],
						 [item_no],
						 [qrcode_1],
						 [qrcode_2],
						 [status],
						 [create_at],
						 [create_by],
						 [update_at],
						 [emp_no],
						 [division_id])

			VALUES (@lot_no, @item_no, @qr_code1, @qr_code2, 2, GETDATE(), @emp_id, GETDATE(), @empno, @division_id)
			
			SELECT 'FALSE' AS Is_Pass,
				'Data already exist.' AS Error_Message_ENG,
				N'ข้อมูลนี้ถูกสแกนไปแล้ว' AS Error_Message_THA,
				N'กรุณาตรวจสอบกล่องที่สแกน' AS Handling;
			RETURN;
		END

		IF (@qr_code1 <> @qr_code2)
		BEGIN
			INSERT INTO [AppDB_app_244].[trans].[compare_data_center]
						([lot_no],
						 [item_no],
						 [qrcode_1],
						 [qrcode_2],
						 [status],
						 [create_at],
						 [create_by],
						 [update_at],
						 [emp_no],
						 [division_id])

			VALUES (@lot_no, @item_no, @qr_code1, @qr_code2, 0, GETDATE(), @emp_id, GETDATE(), @empno, @division_id)

			SELECT 'FALSE' AS Is_Pass,
				'QR codes do not match.' AS Error_Message_ENG,
				N'QR Code ทั้งสองไม่ตรงกัน' AS Error_Message_THA,
				N'กรุณาตรวจสอบและลองใหม่อีกครั้ง' AS Handling;
			RETURN;
		END
		ELSE
		BEGIN
			INSERT INTO [AppDB_app_244].[trans].[compare_data_center]
						([lot_no],
						 [item_no],
						 [qrcode_1],
						 [qrcode_2],
						 [status],
						 [create_at],
						 [create_by],
						 [update_at],
						 [emp_no],
						 [division_id])

			VALUES (@lot_no, @item_no, @qr_code1, @qr_code2, 1, GETDATE(), @emp_id, GETDATE(), @empno, @division_id)

			SELECT 'TRUE' AS Is_Pass,
				'QR codes match.' AS Error_Message_ENG,
				N'บันทึกข้อมูลสำเร็จ' AS Error_Message_THA,
				N'Data inserted successfully.' AS Handling;
			RETURN;
		END
	END
	--================== END: TRDI LOGIC ====================
END TRY 
BEGIN CATCH 
	-- ดักจับข้อผิดพลาดและคืนค่าข้อความแจ้งเตือน 
	DECLARE @ErrorMessage VARCHAR(4000) = ERROR_MESSAGE();
	SELECT 'FALSE' AS Is_Pass
		, @ErrorMessage AS ResultMessage
		, N''  AS Error_Message_THA 
		, N'' AS Handling
	RETURN;
END CATCH;