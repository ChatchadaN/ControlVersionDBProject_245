-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_qty_fristlot_update_ver3] 
	-- Add the parameters for the stored procedure here
	 @lot_no		varchar(10)  = ''
	,@qty			int			 = 0  
	,@is_process	varchar(10)  = ''
	,@reel_no		varchar(max) = ''
	,@qty_sum_ng	int			 = 0

AS
BEGIN
	print 'exec update record v.3'

	SET NOCOUNT ON;
	DECLARE @LOTNO_ID INT
	DECLARE @Totalhasuu INT
	DECLARE @reel_standard INT
	DECLARE @reel_max_before int = 0
	DECLARE @reel_max_after int = 0
	DECLARE @Count_reel int = 0
	DECLARE @Reel_Forslip char(3) = ''
	DECLARE @Reel_Hasuu char(3) = ''
	DECLARE @Reel_Hasuu_Shipment char(3) = ''
	DECLARE @Qrcode_Forslip char(90) = ''
	DECLARE @Qrcode_Hasuu char(90) = ''
	DECLARE @device_name char(20) = ''
	DECLARE @Barcode_buttom_hasuu char(18) = ''
	DECLARE @qty_hasuu int = 0
	DECLARE @Qrcode_Hasuu_new char(90) = ''
	DECLARE @Barcode_buttom_hasuu_new char(18) = ''
	DECLARE @qty_out_new_value int = 0
	DECLARE @qty_out_get_tranlot int = 0
	DECLARE @in_stock_hasuu tinyint = 0
	DECLARE @qty_hasuu_in_surpluses int = 0
	DECLARE @pcInstruction int = null
	DECLARE @Qrcode_Hasuu_Shipment char(90) = ''
	DECLARE @sum_qty int = 0

	SELECT @LOTNO_ID = id from APCSProDB.trans.lots where lot_no = @lot_no

	SELECT @reel_standard = [device_names].pcs_per_pack
		,@qty_hasuu = [lots].[qty_hasuu]
		,@device_name = [device_names].[name]
		,@qty_out_get_tranlot = qty_out 
		,@in_stock_hasuu = surpluses.in_stock
		,@qty_hasuu_in_surpluses = surpluses.pcs 
		,@pcInstruction = lots.pc_instruction_code
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	INNER JOIN [APCSProDB].[trans].[surpluses] ON [lots].[id] = [surpluses].[lot_id]
	WHERE [lots].[lot_no] = @lot_no
	
	IF @is_process = 'INSP'
	BEGIN
		select @qty_hasuu = IIF(@in_stock_hasuu = 0,@qty_hasuu_in_surpluses,@qty_hasuu)

	END

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text]
	  , [lot_no])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[tg_sp_set_qty_fristlot_update_ver3 after lot end update qty on label]  @lot_no = ''' + @lot_no + ''',@qty = ''' + CONVERT (varchar (10), @qty) + ''',@is_process = ''' +  @is_process + ''',@reel_no = ''' +  @reel_no + ''',@qty_sum_ng = ''' + CONVERT (varchar (10), @qty_sum_ng) + ''''
		,@lot_no

	--Get data reel Max Before
	select @reel_max_before = max(cast(no_reel as int)) - 2 from APCSProDB.trans.label_issue_records  --change type form char is int 2023/03/21 time : 14.30
	where lot_no = @lot_no

	--Get data reel Max After
	select @reel_max_after = (qty_out/dn.pcs_per_pack) 
	from APCSProDB.trans.lots 
	inner join APCSProDB.method.device_names as dn on lots.act_device_name_id = dn.id
	where lot_no = @lot_no

	select @Count_reel = Count(no_reel) from APCSProDB.trans.label_issue_records
	where lot_no = @lot_no and type_of_label = 3

	--Get Data Qrcode
	select @Reel_Forslip = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
	where lot_no = @lot_no 
	and type_of_label = 1

	select @Reel_Hasuu = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
	where lot_no = @lot_no 
	and type_of_label = 2

	select @Reel_Hasuu_Shipment = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
	where lot_no = @lot_no
	and type_of_label = 20

	SELECT @Qrcode_Forslip = CAST(@device_name AS VARCHAR(19)) +
    RIGHT('000000' + CAST(@qty AS VARCHAR(6)), 6) +
    CAST(@lot_no AS VARCHAR(10)) + @Reel_Forslip

	SELECT @Qrcode_Hasuu = CAST(@device_name AS VARCHAR(19)) +
    right('000000' + CAST(@qty_hasuu AS VARCHAR(6)), 6) +
    CAST(@lot_no AS VARCHAR(10)) + @Reel_Hasuu
	
	SELECT @Barcode_buttom_hasuu = right('000000' + CAST(@qty_hasuu AS VARCHAR(6)), 6) + ' ' +
	Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(11))

	IF @qty >= @reel_standard  --Add Condition 2021/10/20 เช็คงานที่จำนวนงานน้อยกว่า standard reel จะไม่ update qty on label เพราะจะทำให้ค่าใน label เป็น 0 เพราะฝั่ง cellcon ส่ง hasuu มาเป็น 0
	BEGIN
		IF @lot_no != ''
		BEGIN
			BEGIN TRY
			--CREATE 2021/09/22 Update Qty ForHasuu
			UPDATE [APCSProDB].[trans].[label_issue_records] 
			set  qty = @qty_hasuu
				,barcode_bottom = @Barcode_buttom_hasuu
				,qrcode_detail = @Qrcode_Hasuu
				,update_at = GETDATE()
			where [lot_no] = @lot_no
			and [type_of_label] = 2

			--Crate 2022/02/01 Time : 13.27 Check inspec = 1 not disable reel auto
			--IF @is_inspec_value != 1
			--IF @is_process != 'inspec'
			--BEGIN
				--CREATE 2021/09/30
				IF @Count_reel != 0
				BEGIN
					IF ISNULL(@reel_no, '') <> ''
					BEGIN
						-- update type_of_label = 0 at reel max					
						update APCSProDB.trans.label_issue_records 
						set type_of_label = 0
						,update_at = GETDATE()
						where lot_no = @lot_no and type_of_label = 3 and no_reel in (SELECT value FROM STRING_SPLIT(@reel_no, ','))--= @reel_max_before
						--select 'Update Type Label = 0 at Reel Max'
					END

					INSERT INTO APCSProDB.trans.[label_issue_records_hist] 
						(
						  label_issue_id
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
						, update_by
						)
						SELECT 
						  id
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
						where lot_no = @lot_no 
						and type_of_label = 0
				END

			--END
			
			select @sum_qty = SUM(CAST(qty AS INT))
			from [APCSProDB].[trans].[label_issue_records] 
			WHERE [lot_no] = @lot_no and type_of_label in (2,3,20)
			print '@sum_qty: ' + CAST(@sum_qty as varchar(10))

			SELECT @Qrcode_Forslip = CAST(@device_name AS VARCHAR(19)) +
			RIGHT('000000' + CAST(@sum_qty AS VARCHAR(6)), 6) +
			CAST(@lot_no AS VARCHAR(10)) + @Reel_Forslip

			--CREATE 2021/09/22 Update Qty Forslip
			UPDATE [APCSProDB].[trans].[label_issue_records] 
			set  qty = @sum_qty	--@qty
				,barcode_bottom = @sum_qty	--@qty
				,qrcode_detail = @Qrcode_Forslip
				,update_at = GETDATE()
			where [lot_no] = @lot_no
			and [type_of_label] = 1


			--add condition จำนวนงานที่ส่งมาใหม่มากกว่าค่าเดิมให้ update reel ที่ disibal ไป กลับมาเป็น use เหมือนเดิม date : 2021/12/02 Time : 13.35
			--Check qty_out_new > qty_out_get_tranlot (เช็คจำนวนงานที่ส่งมามากกว่าจำนวนงานที่อยู่ใน table tranlot) 
			select @qty_out_new_value = ((@reel_standard) * ((@qty)/(@reel_standard)))

			--Crate 2022/02/01 Time : 13.28 Check inspec = 1 not disable reel auto
			--IF @is_inspec_value != 1			
			--IF @is_process != 'inspec'
			--BEGIN
				IF @qty_out_new_value > @qty_out_get_tranlot --@qty = qty_new_value 2025/07/21
				BEGIN
					update APCSProDB.trans.label_issue_records 
					set type_of_label = 3
					,update_at = GETDATE()
					where lot_no = @lot_no and type_of_label = 0 --and no_reel in (SELECT value FROM STRING_SPLIT(@reel_no, ','))--= @reel_max_before

					--insert data reprint on label his date modify : 2022/11/02 time : 13.57
					INSERT INTO APCSProDB.trans.[label_issue_records_hist] 
						(
						  label_issue_id
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
						, update_by
						)
						SELECT 
						  id
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
						where lot_no = @lot_no 
						and type_of_label = 3
				END
			--END
			
		END TRY
		BEGIN CATCH 
			SELECT 'FALSE' AS Status ,'INSERT DATA LABEL_HISTORY ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH

		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS Status ,'DELETE DATA ERROR !!' AS Error_Message_ENG,N'ข้อมูล Lotno. มีค่าเป็น Null' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END
	END
	ELSE IF @qty < @reel_standard  --add condition update qty hasuu in label --> Date : 2022/01/20 Time : 14.57
	BEGIN
		IF @lot_no != ''
		BEGIN

			SELECT @Qrcode_Hasuu_new = CAST(@device_name AS VARCHAR(19)) +
				right('000000' + CAST(@qty AS VARCHAR(6)), 6) +
				CAST(@lot_no AS VARCHAR(10)) + @Reel_Hasuu
			
			select @qty = @qty_out_get_tranlot  --modify update 2024/02/14 time : 11.35 by aomsin			
			SELECT @Barcode_buttom_hasuu_new = right('000000' + CAST(@qty AS VARCHAR(6)), 6) + ' ' +
				Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(11))
			
			select @qty = @qty_out_get_tranlot  --modify update 2024/02/14 time : 11.35 by aomsin
			SELECT @Qrcode_Hasuu_Shipment = CAST(@device_name AS VARCHAR(19)) +
				right('000000' + CAST(@qty AS VARCHAR(6)), 6) +
				CAST(@lot_no AS VARCHAR(10)) + @Reel_Hasuu_Shipment

		BEGIN TRY
			IF @pcInstruction = 13 --pc request new version
			BEGIN
				IF SUBSTRING(@lot_no,5,1) = 'D'
				BEGIN
					print 'lot type d pc-request new version'
					--hasuu stock in
					UPDATE APCSProDB.trans.label_issue_records 
					SET qty = @qty_hasuu
						,barcode_bottom = @Barcode_buttom_hasuu
						,qrcode_detail = @Qrcode_Hasuu
						,update_at = GETDATE()
					WHERE lot_no = @lot_no
					and type_of_label = 2

					--hasuu shipment
					UPDATE APCSProDB.trans.label_issue_records 
					SET qty = @qty_out_get_tranlot
						,barcode_bottom = @Barcode_buttom_hasuu_new
						,qrcode_detail = @Qrcode_Hasuu_Shipment
						,update_at = GETDATE()
					WHERE lot_no = @lot_no
					and type_of_label = 20
				END
				ELSE
				BEGIN
					print 'lot type = A,F,E use codition hasuu stock in same'
					--CREATE 2021/09/22 Update Qty Forslip
					UPDATE APCSProDB.trans.label_issue_records 
					SET qty = @qty_out_get_tranlot
						,barcode_bottom = @qty_out_get_tranlot
						,qrcode_detail = @Qrcode_Forslip
						,update_at = GETDATE()
					WHERE lot_no = @lot_no
					and type_of_label = 1

					--CREATE 2021/09/22 Update Qty ForHasuu shipment
					UPDATE APCSProDB.trans.label_issue_records 
					SET qty = @qty_out_get_tranlot
						,barcode_bottom = @Barcode_buttom_hasuu_new
						,qrcode_detail = @Qrcode_Hasuu_new
						,update_at = GETDATE()
					WHERE lot_no = @lot_no
					and type_of_label = 2
				END
			END
			ELSE
			BEGIN
				print '@pcInstruction <> 13 is hasuu srock in'
				--CREATE 2021/09/22 Update Qty Forslip
				UPDATE APCSProDB.trans.label_issue_records 
				SET qty = @qty_hasuu --modify update 2024/02/14 time : 11.35 by aomsin
					,barcode_bottom = @qty_hasuu 
					,qrcode_detail = @Qrcode_Forslip
					,update_at = GETDATE()
				WHERE lot_no = @lot_no
				and type_of_label = 1

				--CREATE 2021/09/22 Update Qty ForHasuu stock in
				UPDATE APCSProDB.trans.label_issue_records 
				SET qty = @qty_hasuu --modify update 2024/02/14 time : 11.35 by aomsin
					,barcode_bottom = @Barcode_buttom_hasuu
					,qrcode_detail = @Qrcode_Hasuu
					,update_at = GETDATE()
				WHERE lot_no = @lot_no
				and type_of_label = 2
			END

			--Crate 2022/02/01 Time : 13.30 Check inspec = 1 not disable reel auto
			--IF @is_inspec_value != 1
			--BEGIN
			--Disable Reel เฉพาะงานที่เหลือแค่ hasuu จะ Cacel reel ออกทั้งหมด
			update APCSProDB.trans.label_issue_records 
			set type_of_label = 0
			,update_at = GETDATE()
			where lot_no = @lot_no 
			and type_of_label = 3 

			--insert data reprint on label his date modify : 2022/11/02 time : 13.57
			INSERT INTO APCSProDB.trans.[label_issue_records_hist] 
				(
				  label_issue_id
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
				, update_by
				)
				SELECT 
				  id
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
				where lot_no = @lot_no 
				and type_of_label in (1,2,3)
			--END
		END TRY
		BEGIN CATCH 
			SELECT 'FALSE' AS Status ,'UPDATE DATA HASUU LABEL_HISTORY ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH

		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS Status ,'DELETE DATA ERROR !!' AS Error_Message_ENG,N'ข้อมูล Lotno. มีค่าเป็น Null' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END
	END
END
