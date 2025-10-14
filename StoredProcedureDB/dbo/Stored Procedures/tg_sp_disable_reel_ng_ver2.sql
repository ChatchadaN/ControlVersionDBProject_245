-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_disable_reel_ng_ver2]
	-- Add the parameters for the stored procedure here
	 @lotno_standard varchar(10) = ''
	 --,@reel_no int = 0 
	 ,@reel_no NVARCHAR(max) = ''
	 ,@count_reel_ng int = 0
	 ,@qty_input int = 0 --qty_out_before
	 ,@qty_good int = 0
	 ,@emp_no char(6) = ''
	 ,@state int = 0  --1 = web , 0 = cellcon
AS
BEGIN
	
	SET NOCOUNT ON;
	DECLARE @EmpNo_int int = 0
	DECLARE @Standard_Reel int = 0
	DECLARE @State_instock tinyint = 5 --default is 5
	DECLARE @hasuu_now_value int = 0
	DECLARE @qty_shipment int = 0
	DECLARE @qty_shipment_old int = 0
	--Label--
	DECLARE @Reel_Forslip char(3) = ''
	DECLARE @Reel_Hasuu char(3) = ''
	DECLARE @Qrcode_Forslip char(90) = ''
	DECLARE @Qrcode_Hasuu char(90) = ''
	DECLARE @device_name char(20) = ''
	DECLARE @Barcode_buttom_hasuu char(18) = ''
	DECLARE @qty_hasuu_before int = 0
	DECLARE @qty_hasuu_in_label int  = 0
	DECLARE @qty_forslip_in_label int = 0

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
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[tg_sp_disable_reel_ng] @lot_no = ''' + @lotno_standard + ''' @Reel_no = ''' + CAST(@reel_no as varchar(20)) + ''' @qty_input = ''' + CAST(@qty_input as varchar(7)) + ''' @qty_good = ''' + CAST(@qty_good as varchar(7)) + ''' @empno = ''' + @emp_no + ''' @count_reel_ng = ''' + CAST(@count_reel_ng as varchar(7)) + ''''
		,@lotno_standard

	select @EmpNo_int = CONVERT(INT, @emp_no)
	
	select @Standard_Reel = dn.pcs_per_pack 
	,@State_instock = sur.in_stock
	,@qty_hasuu_before = pcs
	,@device_name = dn.name
	,@qty_shipment_old = lot.qty_out
	from APCSProDB.trans.lots as lot
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	inner join APCSProDB.trans.surpluses as sur on lot.id = sur.lot_id
	where lot.lot_no = @lotno_standard

	--Use at web LSMS date modify : 2022/03/21 time : 14.36
	DECLARE @count_reel_ng_all NVARCHAR(max) = ''
	DECLARE @qty_all_reel_ng int = 0
	SELECT @count_reel_ng_all = COUNT(value) FROM string_split(@reel_no, ',')
	SELECT @qty_all_reel_ng = @Standard_Reel * @count_reel_ng_all 

	--Add condition Check is_web date modify : 2022/03/21 time : 14.36
	select @qty_shipment = case when @state = 1 then (@qty_shipment_old - @qty_all_reel_ng)
				else ((@Standard_Reel) * (((@qty_input)/(@Standard_Reel)) - @count_reel_ng)) end
	select @hasuu_now_value = (@qty_good - @qty_shipment)
	select @qty_hasuu_in_label = case when @state = 1 
				then 
					case when @State_instock = 2 then  (@qty_hasuu_before + @qty_all_reel_ng) 
						 when @State_instock = 0 then  (@qty_hasuu_before + @qty_all_reel_ng) 
						 when @State_instock = 1 then  @qty_hasuu_before
						 else @qty_shipment end
				else (@qty_hasuu_before + @hasuu_now_value) end
	select @qty_forslip_in_label = (@qty_shipment + @qty_hasuu_in_label)

	-- CREATE 2021/10/01 : Get Data Qrcode
	select @Reel_Forslip = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
	where lot_no = @lotno_standard 
	and type_of_label = 1

	select @Reel_Hasuu = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
	where lot_no = @lotno_standard 
	and type_of_label = 2

	select @Qrcode_Forslip = Cast(@device_name as varchar(19)) + case when LEN(CAST(@qty_forslip_in_label as varchar(6))) = 5 
		then '0' + CAST(@qty_forslip_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Forslip
		when LEN(CAST(@qty_forslip_in_label as varchar(6))) = 4 
		then '00' + CAST(@qty_forslip_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Forslip
		when LEN(CAST(@qty_forslip_in_label as varchar(6))) = 3 
		then '000' + CAST(@qty_forslip_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Forslip
		when LEN(CAST(@qty_forslip_in_label as varchar(6))) = 2 
		then '0000' + CAST(@qty_forslip_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Forslip
		when LEN(CAST(@qty_forslip_in_label as varchar(6))) = 1 
		then '00000' + CAST(@qty_forslip_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Forslip
		else CAST(@qty_forslip_in_label as varchar(6)) + CAST(@lotno_standard as varchar(10)) + @Reel_Forslip end 

	select @Qrcode_Hasuu = Cast(@device_name as varchar(19)) + case when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 5 
		then '0' + CAST(@qty_hasuu_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu
		when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 4 
		then '00' + CAST(@qty_hasuu_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu
		when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 3 
		then '000' + CAST(@qty_hasuu_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu
		when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 2 
		then '0000' + CAST(@qty_hasuu_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu
		when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 1 
		then '00000' + CAST(@qty_hasuu_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu
		else CAST(@qty_hasuu_in_label as varchar(6)) + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu end 
			
	select @Barcode_buttom_hasuu = case when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 5 then '0' + CAST(@qty_hasuu_in_label as varchar(6)) + ' ' + Cast(SUBSTRING(@lotno_standard, 1, 4) + ' ' + SUBSTRING(@lotno_standard, 5, 6) as char(11))
		when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 4 then '00' + CAST(@qty_hasuu_in_label as varchar(6)) + ' ' + Cast(SUBSTRING(@lotno_standard, 1, 4) + ' ' + SUBSTRING(@lotno_standard, 5, 6) as char(11))
		when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 3 then '000' + CAST(@qty_hasuu_in_label as varchar(6)) + ' ' + Cast(SUBSTRING(@lotno_standard, 1, 4) + ' ' + SUBSTRING(@lotno_standard, 5, 6) as char(11))
		when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 2 then '0000' + CAST(@qty_hasuu_in_label as varchar(6)) + ' ' + Cast(SUBSTRING(@lotno_standard, 1, 4) + ' ' + SUBSTRING(@lotno_standard, 5, 6) as char(11))
		when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 1 then '00000' + CAST(@qty_hasuu_in_label as varchar(6)) + ' ' + Cast(SUBSTRING(@lotno_standard, 1, 4) + ' ' + SUBSTRING(@lotno_standard, 5, 6) as char(11))
		else CAST(@qty_hasuu_in_label as varchar(6)) + ' ' + Cast(SUBSTRING(@lotno_standard, 1, 4) + ' ' + SUBSTRING(@lotno_standard, 5, 6) as char(10)) end
		+ '''';

	IF @state = 1 --web
	BEGIN
		BEGIN TRY

			--Disable Reel NG
			UPDATE APCSProDB.trans.label_issue_records
			set type_of_label = 0
			,update_at = GETDATE()
			,update_by = @EmpNo_int
			where lot_no = @lotno_standard
			and type_of_label = 3
			and no_reel in(SELECT value FROM string_split(@reel_no, ','))

			--update qty_hasuu in tranlot date modify : 2022/03/21 time : 14.36
			UPDATE APCSProDB.trans.lots
			SET qty_out = @qty_shipment
				,qty_hasuu = @qty_hasuu_in_label
			WHERE lot_no = @lotno_standard

			--update qty_hasuu in surpluses
			UPDATE APCSProDB.trans.surpluses
			SET pcs = @qty_hasuu_in_label
				,updated_at = GETDATE()
				,updated_by = @EmpNo_int
			WHERE serial_no = @lotno_standard

			--insert surpluses_record is update
			EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
			,@sataus_record_class = 2

			--insert label_issue_records_history is update modify : 2023/01/13 time : 11.42
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
			where lot_no = @lotno_standard 
			and type_of_label = 0


			SELECT 'TRUE' AS Status ,'Disable Reel or Update qty_shipment Success !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA 
			RETURN
		END TRY
		BEGIN CATCH 
			SELECT 'FALSE' AS Status ,'Disable Reel or Update qty_shipment Error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH
	END
	ELSE IF @state = 0
	BEGIN
		BEGIN TRY
	
			--Disable Reel NG
			UPDATE APCSProDB.trans.label_issue_records
			set type_of_label = 0
			,update_at = GETDATE()
			,update_by = @EmpNo_int
			where lot_no = @lotno_standard
			and type_of_label = 3
			and no_reel in(SELECT value FROM string_split(@reel_no, ','))

			--Update Qty Forslip
			UPDATE APCSProDB.trans.label_issue_records 
			set qty = @qty_forslip_in_label
			,barcode_bottom = @qty_forslip_in_label
			,qrcode_detail = @Qrcode_Forslip
			,update_at = GETDATE()
			,update_by = @EmpNo_int
			where lot_no = @lotno_standard
			and type_of_label = 1

			--Update Qty ForHasuu
			UPDATE APCSProDB.trans.label_issue_records 
			set qty = @qty_hasuu_in_label
			,barcode_bottom = @Barcode_buttom_hasuu
			,qrcode_detail = @Qrcode_Hasuu
			,update_at = GETDATE()
			,update_by = @EmpNo_int
			where lot_no = @lotno_standard
			and type_of_label = 2

			--Check Condition InStock
			IF @State_instock = 2
			BEGIN
				--update qty_hasuu in surpluses
				UPDATE APCSProDB.trans.surpluses
				SET pcs = pcs + @hasuu_now_value
					,updated_at = GETDATE()
					,updated_by = @EmpNo_int
				WHERE serial_no = @lotno_standard

				--insert surpluses_record is update
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
				,@sataus_record_class = 2

				--update qty_hasuu in tranlot
				UPDATE APCSProDB.trans.lots
				SET qty_hasuu = qty_hasuu + @hasuu_now_value
					,qty_out = @qty_shipment
				WHERE lot_no = @lotno_standard

			END
			ELSE IF @State_instock = 0 
			BEGIN 
				--add query update qty data modify : 2022/03/21 time : 08.09
				--update qty_hasuu in surpluses
				UPDATE APCSProDB.trans.surpluses
				SET pcs = @hasuu_now_value
					,updated_at = GETDATE()
					,updated_by = @EmpNo_int
				WHERE serial_no = @lotno_standard

				--insert surpluses_record is update
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
				,@sataus_record_class = 2

				--update qty_hasuu in tranlot
				UPDATE APCSProDB.trans.lots
				SET qty_hasuu = @hasuu_now_value
					,qty_out = @qty_shipment
				WHERE lot_no = @lotno_standard

			END
			ELSE IF @State_instock = 1
			BEGIN
				--add query update qty data modify : 2022/03/21 time : 08.18
				--update qty_hasuu in tranlot
				UPDATE APCSProDB.trans.lots
				SET   qty_out = @qty_shipment
				WHERE lot_no = @lotno_standard
				--select 'No Update QTY HASUU Because in_stock is not 0 and 2'
			END

			SELECT 'TRUE' AS Status ,'Disable Reel on Cellcon Success !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA 
			RETURN
		END TRY
		BEGIN CATCH 
			SELECT 'FALSE' AS Status ,'Disable Reel on Cellcon Error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH
	END

END
