-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,Cellcon OGI USE Reprint Label>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_update_version_print_label_test_by_aomsin] 
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
	,@type_of_label_drypack int = 0
	,@type_of_label_tomson int = 0
	,@type_of_label_tray int = 0  --update parameter date : 2021/12/10 time : 16.12
	,@type_of_label_pc_request int = 0 --add parameter data : 2022/03/03
	,@Reel_Num char(3) = ''  --if งาน tray ต้องส่งเลข tomson มาหาว่ามี set อะไรบ้างแล้วนำไป update version set
	,@emp_no char(6) = '' --add parameter date modify : 2022/02/17 time : 13.31
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--Add parameter Date Modify : 2022/02/28 time : 13.45
	DECLARE @op_no_len_value varchar(10) = ''
	DECLARE @OPName char(20) = ''
	DECLARE @PC_COde int = 0
	DECLARE @Check_Tray char(10) = ''

	select @PC_COde = case when pc_instruction_code is null then 0 else pc_instruction_code end 
	from APCSProDB.trans.lots where lot_no = @lot_no

	SELECT @Check_Tray = TRAY FROM [StoredProcedureDB].[atom].[fnc_tg_sp_get_Material] (@lot_no)

	--Create log store Date : 2022/02/26 Time : 09.48
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
			,'EXEC [dbo].[tg_sp_update_version_print_label at process OGI] @lotno = ''' + @lot_no + ''',@empno = ''' + CAST(@emp_no as varchar(7)) + ''',@is_pc_request = ''' + CAST(@type_of_label_pc_request as varchar(2)) + ''',@pc_code = ''' + CAST(@PC_COde as varchar(2)) + ''''
			,@lot_no

    -- Insert statements for procedure here

	--Add Query Date Modify : 2022/02/28 time : 13.45
	select  @op_no_len_value =  RIGHT('000000'+ CONVERT(VARCHAR,TRIM(@emp_no)),6)
	SELECT @OPName =
	CASE
		WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MR.' THEN LEFT(SUBSTRING([users].name, 5,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		WHEN SUBSTRING(CAST(name as char(20)),1,4) ='MISS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MRS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
    ELSE SUBSTRING(CAST(name as char(20)), 1,LEN([users].name)) END 
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @op_no_len_value

	BEGIN TRY 
		IF @type_of_label_drypack = 4 AND @type_of_label_tomson = 5
		BEGIN
			update APCSProDB.trans.label_issue_records 
			set version = version + 1  
				--,update_by = (select id from APCSProDB.man.users where emp_num = @emp_no) --use id
				,update_by = CAST(@emp_no as int) --add update value emp_no after reprint -->Date Modify : 2022/02/26 time : 11.00
				,update_at = GETDATE()
				,op_no = CAST(@emp_no as int)  --add update value emp_no after reprint -->Date Modify : 2022/02/28 time : 14.40
				,operated_by = CAST(@emp_no as int)  --add update value emp_no after reprint -->Date Modify : 2022/02/28 time : 14.40
				,op_name = @OPName --add update value emp_name after reprint -->Date Modify : 2022/02/28 time : 11.45
			where lot_no = @lot_no
			and type_of_label in(@type_of_label_drypack,@type_of_label_tomson) 
			and no_reel = @Reel_Num

			BEGIN TRY
				--Insert Record Reprint label Date modify : 2022/02/17 time : 16.54
				INSERT INTO APCSProDB.trans.[label_issue_records_hist] (
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
				, 2 --fix 2 = update version
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
				and type_of_label in(@type_of_label_drypack,@type_of_label_tomson) and no_reel = @Reel_Num
			END TRY
			BEGIN CATCH
				SELECT 'FALSE' AS Status ,'INSERT RECORD ERROR !!' AS Error_Message_ENG,N'ไม่เข้า function เก็บ record การ reprint ' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH

		END
		ELSE IF @type_of_label_drypack = 4 AND @type_of_label_tomson = 0
		BEGIN
			update APCSProDB.trans.label_issue_records 
			set version = version + 1  
				,update_by = CAST(@emp_no as int) --add update value emp_no after reprint -->Date Modify : 2022/02/26 time : 11.00
				,update_at = GETDATE()
				,op_no = CAST(@emp_no as int)  --add update value emp_no after reprint -->Date Modify : 2022/02/28 time : 14.40
				,operated_by = CAST(@emp_no as int)  --add update value emp_no after reprint -->Date Modify : 2022/02/28 time : 14.40
				,op_name = @OPName --add update value emp_name after reprint -->Date Modify : 2022/02/28 time : 11.45
			where lot_no = @lot_no
			and type_of_label = @type_of_label_drypack
			and no_reel = @Reel_Num

			--Insert Record Reprint label Date modify : 2022/02/17 time : 16.54
			BEGIN TRY
				INSERT INTO APCSProDB.trans.[label_issue_records_hist] (
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
				, 2 --fix 2 = update version
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
				and type_of_label = @type_of_label_drypack and no_reel = @Reel_Num
			END TRY
			BEGIN CATCH
				SELECT 'FALSE' AS Status ,'INSERT RECORD ERROR !!' AS Error_Message_ENG,N'ไม่เข้า function เก็บ record การ reprint ' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH

		END
		ELSE IF @type_of_label_tomson = 5 AND @type_of_label_drypack = 0
		BEGIN
			update APCSProDB.trans.label_issue_records 
			set version = version + 1  
				,update_by = CAST(@emp_no as int) --add update value emp_no after reprint -->Date Modify : 2022/02/26 time : 11.00
				,update_at = GETDATE()
				,op_no = CAST(@emp_no as int)  --add update value emp_no after reprint -->Date Modify : 2022/02/28 time : 14.40
				,operated_by = CAST(@emp_no as int)  --add update value emp_no after reprint -->Date Modify : 2022/02/28 time : 14.40
				,op_name = @OPName --add update value emp_name after reprint -->Date Modify : 2022/02/28 time : 11.45
			where lot_no = @lot_no
			and type_of_label = @type_of_label_tomson
			and no_reel = @Reel_Num

			--Insert Record Reprint label Date modify : 2022/02/17 time : 16.54
			BEGIN TRY
				INSERT INTO APCSProDB.trans.[label_issue_records_hist] (
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
				, 2 --fix 2 = update version
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
				and type_of_label = @type_of_label_tomson and no_reel = @Reel_Num
			END TRY
			BEGIN CATCH
				SELECT 'FALSE' AS Status ,'INSERT RECORD ERROR !!' AS Error_Message_ENG,N'ไม่เข้า function เก็บ record การ reprint ' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH

		END
		--add condition update version type tray --> date : 2021/12/14 time : 10.41
		ELSE IF @type_of_label_tray = 6 AND @type_of_label_drypack = 0 AND @type_of_label_tomson = 0
		BEGIN
			UPDATE APCSProDB.trans.label_issue_records 
			SET version = version + 1 
				,update_by = CAST(@emp_no as int) --add update value emp_no after reprint -->Date Modify : 2022/02/26 time : 11.00
				,update_at = GETDATE()
				,op_no = CAST(@emp_no as int)  --add update value emp_no after reprint -->Date Modify : 2022/02/28 time : 14.40
				,operated_by = CAST(@emp_no as int)  --add update value emp_no after reprint -->Date Modify : 2022/02/28 time : 14.40
				,op_name = @OPName --add update value emp_name after reprint -->Date Modify : 2022/02/28 time : 11.45
			where lot_no = @lot_no
			and type_of_label = 6 
			and seq = @Reel_Num --tomson_no

			--Insert Record Reprint label Date modify : 2022/02/17 time : 16.54
			BEGIN TRY
				INSERT INTO APCSProDB.trans.[label_issue_records_hist] (
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
				, 2 --fix 2 = update version
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
				and type_of_label = 6 and no_reel = @Reel_Num
			END TRY
			BEGIN CATCH
				SELECT 'FALSE' AS Status ,'INSERT RECORD ERROR !!' AS Error_Message_ENG,N'ไม่เข้า function เก็บ record การ reprint ' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH

		END
		ELSE IF @type_of_label_pc_request = 21
		BEGIN
			update APCSProDB.trans.label_issue_records 
			set version = version + 1  
				,update_by = CAST(@emp_no as int) 
				,update_at = GETDATE()
				,op_no = CAST(@emp_no as int)  
				,operated_by = CAST(@emp_no as int)  
				,op_name = @OPName 
			where lot_no = @lot_no
			and type_of_label = @type_of_label_pc_request
			and no_reel = @Reel_Num

			--Insert Record Reprint label Date modify : 2022/02/17 time : 16.54
			BEGIN TRY
				INSERT INTO APCSProDB.trans.[label_issue_records_hist] (
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
				, 2 --fix 2 = update version
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
				and type_of_label = @type_of_label_pc_request and no_reel = @Reel_Num
			END TRY
			BEGIN CATCH
				SELECT 'FALSE' AS Status ,'INSERT RECORD ERROR !!' AS Error_Message_ENG,N'ไม่เข้า function เก็บ record การ reprint ' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS Status ,'UPDATE VERSION PRINT COUNT ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ update ข้อมูลได้' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END

		--Add Condition 2022/07/22 time : 14.02
		IF @PC_COde = 11 or @PC_COde = 13
		BEGIN
			IF @Check_Tray = 'NO USE'
			BEGIN
				update APCSProDB.trans.label_issue_records 
				set version = version + 1  
				,update_by = CAST(@emp_no as int) 
				,update_at = GETDATE()
				,op_no = CAST(@emp_no as int)  
				,operated_by = CAST(@emp_no as int)  
				,op_name = @OPName 
				where lot_no = @lot_no
				and type_of_label in (4,5,21)
			END
			
			--Insert Record Reprint label Date modify : 2022/07/22 time : 14.03
			--BEGIN TRY
			--	INSERT INTO APCSProDB.trans.[label_issue_records_hist] (
			--	  label_issue_id
			--	, recorded_at
			--	, record_class
			--	, operated_by
			--	, type_of_label
			--	, lot_no
			--	, customer_device
			--	, rohm_model_name
			--	, qty
			--	, barcode_lotno
			--	, tomson_box
			--	, tomson_3
			--	, box_type
			--	, barcode_bottom
			--	, mno_std
			--	, std_qty_before
			--	, mno_hasuu
			--	, hasuu_qty_before
			--	, no_reel
			--	, qrcode_detail
			--	, type_label_laterat
			--	, mno_std_laterat
			--	, mno_hasuu_laterat
			--	, barcode_device_detail
			--	, op_no
			--	, op_name
			--	, seq
			--	, ip_address
			--	, msl_label
			--	, floor_life
			--	, ppbt
			--	, re_comment
			--	, version
			--	, is_logo
			--	, mc_name
			--	, barcode_1_mod
			--	, barcode_2_mod
			--	, seal
			--	, create_at
			--	, create_by
			--	, update_at
			--	, update_by
			--	)
			--	SELECT 
			--	  id
			--	, GETDATE()
			--	, 2 --fix 2 = update version
			--	, operated_by
			--	, type_of_label
			--	, lot_no
			--	, customer_device
			--	, rohm_model_name
			--	, qty
			--	, barcode_lotno
			--	, tomson_box
			--	, tomson_3
			--	, box_type
			--	, barcode_bottom
			--	, mno_std
			--	, std_qty_before
			--	, mno_hasuu
			--	, hasuu_qty_before
			--	, no_reel
			--	, qrcode_detail
			--	, type_label_laterat
			--	, mno_std_laterat
			--	, mno_hasuu_laterat
			--	, barcode_device_detail
			--	, op_no
			--	, op_name
			--	, seq
			--	, ip_address
			--	, msl_label
			--	, floor_life
			--	, ppbt
			--	, re_comment
			--	, version
			--	, is_logo
			--	, mc_name
			--	, barcode_1_mod
			--	, barcode_2_mod
			--	, seal
			--	, GETDATE()
			--	, create_by
			--	, GETDATE()
			--	, update_by
			--	FROM APCSProDB.trans.label_issue_records 
			--	where lot_no = @lot_no
			--	and type_of_label in (4,5,21)
			--END TRY
			--BEGIN CATCH
			--	SELECT 'FALSE' AS Status ,'INSERT RECORD ERROR !!' AS Error_Message_ENG,N'ไม่เข้า function เก็บ record การ reprint ' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			--	RETURN
			--END CATCH
		END

	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Status ,'UPDATE DATA ERROR !!' AS Error_Message_ENG,N'ไม่เข้า function update version print count ' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH

END
