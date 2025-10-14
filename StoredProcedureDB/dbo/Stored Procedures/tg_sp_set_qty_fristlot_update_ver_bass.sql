-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_qty_fristlot_update_ver_bass] 
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10) = '',
	@qty INT = 0, --จำนวนงานทั้งหมดรวม hasuu
	--add parameter date : 2022/02/01 time : 13.24
	@is_inspec_value INT = 0 --is_inspec = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @LOTNO_ID INT
	DECLARE @Totalhasuu INT
	DECLARE @reel_standard INT
	--add parameter 2021/09/30
	DECLARE @reel_max_before INT = 0
	DECLARE @reel_max_after INT = 0
	DECLARE @Count_reel INT = 0

	DECLARE @Reel_Forslip CHAR(3) = ''
	DECLARE @Reel_Hasuu CHAR(3) = ''
	DECLARE @Qrcode_Forslip CHAR(90) = ''
	DECLARE @Qrcode_Hasuu CHAR(90) = ''
	DECLARE @device_name CHAR(20) = ''
	DECLARE @Barcode_buttom_hasuu CHAR(18) = ''
	DECLARE @qty_hasuu INT = 0

	--add parameter 2022/01/22 time : 10.15
	DECLARE @Qrcode_Hasuu_new CHAR(90) = ''
	DECLARE @Barcode_buttom_hasuu_new CHAR(18) = ''

	--add parameter date : 2021/12/02
	DECLARE @qty_out_new_value INT = 0
	DECLARE @qty_out_get_tranlot INT = 0

	DECLARE @pc_code INT = 0

	SELECT @LOTNO_ID = id FROM APCSProDB.trans.lots WHERE lot_no = @lot_no;

	SELECT @reel_standard = [device_names].pcs_per_pack
		, @qty_hasuu = qty_hasuu
		, @device_name = [device_names].[name]
		, @qty_out_get_tranlot = qty_out --add get value date : 2021/12/02
		, @pc_code = pc_instruction_code
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	WHERE [lots].[lot_no] = @lot_no;

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
		, '[after lot end update qty on label] EXEC [dbo].[tg_sp_set_qty_fristlot_update_ver_bass] @lot_no = ''' + @lot_no + ''''
			+ ' ,@qty = ''' + CONVERT(varchar(10), @qty)+ '''' 
			+ ' ,@reel_standard = ''' + CONVERT(varchar (10), @reel_standard) + ''''
		, @lot_no;

	--Get data reel Max Before
	SELECT @reel_max_before = MAX(CAST(no_reel AS INT)) - 2 FROM APCSProDB.trans.label_issue_records  --change type form char is int 2023/03/21 time : 14.30
	WHERE lot_no = @lot_no;

	--Get data reel Max After
	SELECT @reel_max_after = (qty_out/dn.pcs_per_pack) 
	FROM APCSProDB.trans.lots 
	INNER JOIN APCSProDB.method.device_names AS dn ON lots.act_device_name_id = dn.id
	WHERE lot_no = @lot_no;

	SELECT @Count_reel = COUNT(no_reel) FROM APCSProDB.trans.label_issue_records
	WHERE lot_no = @lot_no AND type_of_label = 3;

	-- CREATE 2021/10/01 : Get Data Qrcode
	SELECT @Reel_Forslip = SUBSTRING(qrcode_detail,36,38) FROM APCSProDB.trans.label_issue_records
	WHERE lot_no = @lot_no 
		AND type_of_label = 1;

	SELECT @Reel_Hasuu = SUBSTRING(qrcode_detail,36,38) FROM APCSProDB.trans.label_issue_records
	WHERE lot_no = @lot_no 
		AND type_of_label = 2;

	SELECT @Qrcode_Forslip = CAST(CAST(@device_name AS CHAR(19)) + CAST(IIF(LEN(@qty) > 6,'00000*',FORMAT(@qty, '000000')) AS CHAR(6)) + CAST(@lot_no AS CHAR(10)) + @Reel_Forslip AS CHAR(90))
		, @Qrcode_Hasuu = CAST(CAST(@device_name AS CHAR(19)) + CAST(IIF(LEN(@qty_hasuu) > 6,'00000*',FORMAT(@qty_hasuu, '000000')) AS CHAR(6)) + CAST(@lot_no AS CHAR(10)) + @Reel_Hasuu AS CHAR(90))
		, @Barcode_buttom_hasuu = CAST(CAST(IIF(LEN(@qty_hasuu) > 6,'00000*',FORMAT(@qty_hasuu, '000000')) AS CHAR(6)) + ' ' + SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) AS CHAR(18));

	IF @qty >= @reel_standard  --Add Condition 2021/10/20 เช็คงานที่จำนวนงานน้อยกว่า standard reel จะไม่ update qty on label เพราะจะทำให้ค่าใน label เป็น 0 เพราะฝั่ง cellcon ส่ง hasuu มาเป็น 0
	BEGIN
		IF @lot_no != ''
		BEGIN
			BEGIN TRY
				--CREATE 2021/09/22 Update Qty Forslip
				UPDATE APCSProDB.trans.label_issue_records 
				SET qty = @qty
					, barcode_bottom = @qty
					, qrcode_detail = @Qrcode_Forslip
					, update_at = GETDATE()
				WHERE lot_no = @lot_no
					AND type_of_label = 1;

				--CREATE 2021/09/22 Update Qty ForHasuu
				UPDATE APCSProDB.trans.label_issue_records 
				--set qty = (@qty % @reel_standard)
				SET qty = @qty_hasuu
					, barcode_bottom = @Barcode_buttom_hasuu
					, qrcode_detail = @Qrcode_Hasuu
					, update_at = GETDATE()
				WHERE lot_no = @lot_no
					AND type_of_label = 2;

				--Crate 2022/02/01 Time : 13.27 Check inspec = 1 not disable reel auto
				IF @is_inspec_value != 1
				BEGIN
					--CREATE 2021/09/30
					IF @Count_reel != 0
					BEGIN
						--check reel_max_before > reel_max_after to be update type_of_label = 0 at reel max
						IF @reel_max_before > @reel_max_after
						BEGIN
							UPDATE APCSProDB.trans.label_issue_records 
							SET type_of_label = 0
								, update_at = GETDATE()
							WHERE lot_no = @lot_no AND type_of_label = 3 AND no_reel = @reel_max_before;
							--select 'Update Type Label = 0 at Reel Max'

							--insert data reprint on label his date modify : 2022/11/02 time : 13.57
							INSERT INTO APCSProDB.trans.[label_issue_records_hist] 
								( label_issue_id
								, recorded_at
								, record_class
								, operated_by
								, type_of_label
								, lot_no
								, customer_device
								, rohm_model_name
								, qty
								, barcode_lotno
								, tomson_box
								, tomson_3
								, box_type
								, barcode_bottom
								, mno_std
								, std_qty_before
								, mno_hasuu
								, hasuu_qty_before
								, no_reel
								, qrcode_detail
								, type_label_laterat
								, mno_std_laterat
								, mno_hasuu_laterat
								, barcode_device_detail
								, op_no
								, op_name
								, seq
								, ip_address
								, msl_label
								, floor_life
								, ppbt
								, re_comment
								, version
								, is_logo
								, mc_name
								, barcode_1_mod
								, barcode_2_mod
								, seal
								, create_at
								, create_by
								, update_at
								, update_by )
							SELECT id
								, GETDATE()
								, 2 --fix 2 is update record
								, operated_by
								, type_of_label
								, lot_no
								, customer_device
								, rohm_model_name
								, qty
								, barcode_lotno
								, tomson_box
								, tomson_3
								, box_type
								, barcode_bottom
								, mno_std
								, std_qty_before
								, mno_hasuu
								, hasuu_qty_before
								, no_reel
								, qrcode_detail
								, type_label_laterat
								, mno_std_laterat
								, mno_hasuu_laterat
								, barcode_device_detail
								, op_no
								, op_name
								, seq
								, ip_address
								, msl_label
								, floor_life
								, ppbt
								, re_comment
								, version 
								, is_logo
								, mc_name
								, barcode_1_mod
								, barcode_2_mod
								, seal
								, GETDATE()
								, create_by
								, GETDATE()
								, update_by
							FROM APCSProDB.trans.label_issue_records 
							WHERE lot_no = @lot_no 
								AND type_of_label = 0;
						END
					END
				END
			
				--add condition จำนวนงานที่ส่งมาใหม่มากกว่าค่าเดิมให้ update reel ที่ disibal ไป กลับมาเป็น use เหมือนเดิม date : 2021/12/02 Time : 13.35
				--Check qty_out_new > qty_out_get_tranlot (เช็คจำนวนงานที่ส่งมามากกว่าจำนวนงานที่อยู่ใน table tranlot) 
				SELECT @qty_out_new_value = ((@reel_standard) * ((@qty)/(@reel_standard)));

				--Crate 2022/02/01 Time : 13.28 Check inspec = 1 not disable reel auto
				IF @is_inspec_value != 1
				BEGIN
					IF @qty_out_new_value > @qty_out_get_tranlot --@qty = qty_new_value
					BEGIN
						UPDATE APCSProDB.trans.label_issue_records 
						SET type_of_label = 3
							, update_at = GETDATE()
						WHERE lot_no = @lot_no AND type_of_label = 0 AND no_reel = @reel_max_before;

						--insert data reprint on label his date modify : 2022/11/02 time : 13.57
						INSERT INTO APCSProDB.trans.[label_issue_records_hist] 
							( label_issue_id
							, recorded_at
							, record_class
							, operated_by
							, type_of_label
							, lot_no
							, customer_device
							, rohm_model_name
							, qty
							, barcode_lotno
							, tomson_box
							, tomson_3
							, box_type
							, barcode_bottom
							, mno_std
							, std_qty_before
							, mno_hasuu
							, hasuu_qty_before
							, no_reel
							, qrcode_detail
							, type_label_laterat
							, mno_std_laterat
							, mno_hasuu_laterat
							, barcode_device_detail
							, op_no
							, op_name
							, seq
							, ip_address
							, msl_label
							, floor_life
							, ppbt
							, re_comment
							, version
							, is_logo
							, mc_name
							, barcode_1_mod
							, barcode_2_mod
							, seal
							, create_at
							, create_by
							, update_at
							, update_by )
						SELECT id
							, GETDATE()
							, 2 --fix 2 is update record
							, operated_by
							, type_of_label
							, lot_no
							, customer_device
							, rohm_model_name
							, qty
							, barcode_lotno
							, tomson_box
							, tomson_3
							, box_type
							, barcode_bottom
							, mno_std
							, std_qty_before
							, mno_hasuu
							, hasuu_qty_before
							, no_reel
							, qrcode_detail
							, type_label_laterat
							, mno_std_laterat
							, mno_hasuu_laterat
							, barcode_device_detail
							, op_no
							, op_name
							, seq
							, ip_address
							, msl_label
							, floor_life
							, ppbt
							, re_comment
							, version 
							, is_logo
							, mc_name
							, barcode_1_mod
							, barcode_2_mod
							, seal
							, GETDATE()
							, create_by
							, GETDATE()
							, update_by
						FROM APCSProDB.trans.label_issue_records 
						WHERE lot_no = @lot_no 
							AND type_of_label = 3;
					END
				END
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status 
					, 'INSERT DATA LABEL_HISTORY ERROR !!' AS Error_Message_ENG
					, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
					, N' กรุณาติดต่อ System' AS Handling;
				RETURN;
			END CATCH
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS Status
				,'DELETE DATA ERROR !!' AS Error_Message_ENG
				, N'ข้อมูล Lotno. มีค่าเป็น Null' AS Error_Message_THA
				, N' กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
	END
	ELSE IF @qty < @reel_standard  --add condition update qty hasuu in label --> Date : 2022/01/20 Time : 14.57
	BEGIN
		IF @lot_no != ''
		BEGIN
			IF (@pc_code = 13)
			BEGIN
				SELECT @Qrcode_Hasuu_new = CAST(CAST(@device_name AS CHAR(19)) + CAST(IIF(LEN(@qty_hasuu) > 6,'00000*',FORMAT(@qty_hasuu, '000000')) AS CHAR(6)) + CAST(@lot_no AS CHAR(10)) + @Reel_Forslip AS CHAR(90))
					, @Barcode_buttom_hasuu_new = CAST(CAST(IIF(LEN(@qty_hasuu) > 6,'00000*',FORMAT(@qty_hasuu, '000000')) AS CHAR(6)) + ' ' + SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) AS CHAR(18));
			END
			ELSE
			BEGIN
				SELECT @Qrcode_Hasuu_new = CAST(CAST(@device_name AS CHAR(19)) + CAST(IIF(LEN(@qty) > 6,'00000*',FORMAT(@qty, '000000')) AS CHAR(6)) + CAST(@lot_no AS CHAR(10)) + @Reel_Forslip AS CHAR(90))
					, @Barcode_buttom_hasuu_new = CAST(CAST(IIF(LEN(@qty) > 6,'00000*',FORMAT(@qty, '000000')) AS CHAR(6)) + ' ' + SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) AS CHAR(18));
			END

			BEGIN TRY
				--CREATE 2021/09/22 Update Qty Forslip
				UPDATE APCSProDB.trans.label_issue_records 
				SET qty = @qty
					, barcode_bottom = @qty
					, qrcode_detail = @Qrcode_Forslip
					, update_at = GETDATE()
				WHERE lot_no = @lot_no
				AND type_of_label = 1;

				IF (@pc_code = 13)
				BEGIN
					UPDATE APCSProDB.trans.label_issue_records 
					SET qty = @qty_hasuu
						, barcode_bottom = @Barcode_buttom_hasuu_new
						, qrcode_detail = @Qrcode_Hasuu_new
						, update_at = GETDATE()
					WHERE lot_no = @lot_no
						AND type_of_label = 2;
				END
				ELSE
				BEGIN
					--CREATE 2021/09/22 Update Qty ForHasuu
					UPDATE APCSProDB.trans.label_issue_records 
					SET qty = @qty
						, barcode_bottom = @Barcode_buttom_hasuu_new
						, qrcode_detail = @Qrcode_Hasuu_new
						, update_at = GETDATE()
					WHERE lot_no = @lot_no
						AND type_of_label = 2;
				END

				--Crate 2022/02/01 Time : 13.30 Check inspec = 1 not disable reel auto
				IF @is_inspec_value != 1
				BEGIN
					--Disable Reel เฉพาะงานที่เหลือแค่ hasuu จะ Cacel reel ออกทั้งหมด
					UPDATE APCSProDB.trans.label_issue_records 
					SET type_of_label = 0
						, update_at = GETDATE()
					WHERE lot_no = @lot_no 
						AND type_of_label = 3; 

					--insert data reprint on label his date modify : 2022/11/02 time : 13.57
					INSERT INTO APCSProDB.trans.[label_issue_records_hist] 
						( label_issue_id
						, recorded_at
						, record_class
						, operated_by
						, type_of_label
						, lot_no
						, customer_device
						, rohm_model_name
						, qty
						, barcode_lotno
						, tomson_box
						, tomson_3
						, box_type
						, barcode_bottom
						, mno_std
						, std_qty_before
						, mno_hasuu
						, hasuu_qty_before
						, no_reel
						, qrcode_detail
						, type_label_laterat
						, mno_std_laterat
						, mno_hasuu_laterat
						, barcode_device_detail
						, op_no
						, op_name
						, seq
						, ip_address
						, msl_label
						, floor_life
						, ppbt
						, re_comment
						, version
						, is_logo
						, mc_name
						, barcode_1_mod
						, barcode_2_mod
						, seal
						, create_at
						, create_by
						, update_at
						, update_by )
					SELECT id
						, GETDATE()
						, 2 --fix 2 is update record
						, operated_by
						, type_of_label
						, lot_no
						, customer_device
						, rohm_model_name
						, qty
						, barcode_lotno
						, tomson_box
						, tomson_3
						, box_type
						, barcode_bottom
						, mno_std
						, std_qty_before
						, mno_hasuu
						, hasuu_qty_before
						, no_reel
						, qrcode_detail
						, type_label_laterat
						, mno_std_laterat
						, mno_hasuu_laterat
						, barcode_device_detail
						, op_no
						, op_name
						, seq
						, ip_address
						, msl_label
						, floor_life
						, ppbt
						, re_comment
						, version 
						, is_logo
						, mc_name
						, barcode_1_mod
						, barcode_2_mod
						, seal
						, GETDATE()
						, create_by
						, GETDATE()
						, update_by
					FROM APCSProDB.trans.label_issue_records 
					WHERE lot_no = @lot_no 
						AND type_of_label IN (1,2,3);
				END
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status 
					, 'UPDATE DATA HASUU LABEL_HISTORY ERROR !!' AS Error_Message_ENG
					, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA
					, N' กรุณาติดต่อ System' AS Handling;
				RETURN;
			END CATCH
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS Status 
				, 'DELETE DATA ERROR !!' AS Error_Message_ENG
				, N'ข้อมูล Lotno. มีค่าเป็น Null' AS Error_Message_THA
				, N' กรุณาติดต่อ System' AS Handling;
			RETURN;
		END
	END
END
