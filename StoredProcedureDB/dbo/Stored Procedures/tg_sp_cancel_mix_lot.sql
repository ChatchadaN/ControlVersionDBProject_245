-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_cancel_mix_lot]
	-- Add the parameters for the stored procedure here
	 @lot_standard varchar(10) = ''
	--add parameter data : 2021/12/07 Time : 08.53
	,@emp_no char(6) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @sataus_record_class INT
	DECLARE @lot_id int = 0
	DECLARE @LotType varchar(1)  = ''
	DECLARE @EmpNo_int int = 0
	DECLARE @wip_state int = 0
	DECLARE @pc_code int = 0
	DECLARE @production_category tinyint = 0
	DECLARE @qty_in int = 0
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
		,'EXEC [dbo].[tg_sp_cancel_mix_lot] @lot_standard = ''' + @lot_standard + ''''
		,@lot_standard

	select @EmpNo_int = CONVERT(INT, @emp_no)
	
	DECLARE @op_no_len_value char(5) = '';
	select  @op_no_len_value =  case when LEN(CAST(@emp_no as char(5))) = 4 then '0' + CAST(@emp_no as char(5))
			when LEN(CAST(@emp_no as char(5))) = 3 then '00' + CAST(@emp_no as char(5))
			when LEN(CAST(@emp_no as char(5))) = 2 then '000' + CAST(@emp_no as char(5))
			when LEN(CAST(@emp_no as char(5))) = 1 then '0000' + CAST(@emp_no as char(5))
			else CAST(@emp_no as char(5)) end  

   DECLARE @OPName   char(20)  = '';
   SELECT @OPName =
	CASE
		WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MR.' THEN LEFT(SUBSTRING([users].name, 5,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		WHEN SUBSTRING(CAST(name as char(20)),1,4) ='MISS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MRS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
    ELSE SUBSTRING(CAST(name as char(20)), 1,LEN([users].name)) END 
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @op_no_len_value

	------------------------------ Start Get EmpnoId #Modify : 2024/12/26 ------------------------------
	DECLARE @GetEmpno varchar(6) = ''
	DECLARE @EmpnoId int = null
	SELECT @GetEmpno = FORMAT(CAST(@emp_no AS INT), '000000')
	SELECT @EmpnoId = id FROM [APCSProDB].[man].[users] WHERE [emp_num] = @GetEmpno
	------------------------------ End Get EmpnoId #Modify : 2024/12/26 --------------------------------

	select @lot_id = id
		  ,@wip_state = wip_state 
		  ,@pc_code = pc_instruction_code
		  ,@production_category = production_category
		  ,@qty_in = qty_in
	from APCSProDB.trans.lots 
	where lot_no = @lot_standard

	select @LotType = SUBSTRING(TRIM(lot_no),5,1) from APCSProDB.trans.lots where lot_no = @lot_standard

	--INSERT RECORD CLASS TO TABEL tg_sp_set_lot_combine_records update function : 2021/12/06 Time : 17.19
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_lot_combine_records] @lotno = @lot_standard
	,@sataus_record_class = 3

	IF @lot_id != 0
	BEGIN
		--UPDATE CREATE_BY and UPDATE_BY --> IN TABLE : lot_combine_record Date : 2021/12/07 Time : 10.17
		UPDATE APCSProDB.trans.lot_combine_records 
		set  
			operated_by = @EmpnoId  --new
			,created_by = @EmpnoId  --new
			,updated_by = @EmpnoId  --new
		where lot_id = @lot_id and record_class = 3

		--add function clear qty = 0 in table tranlot date modify : 2022/02/17 time : 16.44
		UPDATE APCSProDB.trans.lots
		set  qty_out = 0
			,qty_hasuu = 0
			,qty_combined = 0
			,pc_instruction_code =  case when SUBSTRING(TRIM(lot_no),5,1) <> 'D' then null  --add column pc_instruction_code update value is null 2022/11/08 time : 08.18 
										 else pc_instruction_code end  --add condition 2023/03/23 time : 10.38
		where lot_no = @lot_standard
	END
	
	-- INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records update function : 2021/12/06 Time : 10.31
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lot_standard
	,@sataus_record_class = 3

	IF @lot_id != 0
	BEGIN
		--UPDATE CREATE_BY and UPDATE_BY --> IN TABLE : surpluse_records Date : 2021/12/07 Time : 10.17
		UPDATE APCSProDB.trans.surpluse_records
		set 
			operated_by = @EmpnoId  --new
			,created_by = @EmpnoId  --new
			,updated_by = @EmpnoId  --new
		where lot_id = @lot_id and record_class = 3
	END
	
	DELETE FROM APCSProDB.trans.surpluses WHERE serial_no = @lot_standard

	--type lot = D จะ update wip state = 200 เท่านั้น ถ้าเป็น type lot ทีไม่ใช่ D จะ check wip state ก่อนว่าเท่ากับ 70 หรือเปล่า
	--edit 17/03/2022 9.40
	--Change Wip State is 200 = Cancel Lot Create 2021/10/26 Time : 17.00
	IF @LotType = 'D'
	BEGIN
		--Update wip_state of table : tran.lots
		UPDATE APCSProDB.trans.lots set wip_state = 200 where lot_no = @lot_standard

		--data modify : 2022/07/06 time : 09.16
		--IF @pc_code = 13  --13 is Pc_Request
		--data modify : 2023/06/13 time : 13.35
		IF @pc_code IN (1,13)  --1:มากกว่าหรือเท่ากับ Standard, 13:is Pc_Request
		BEGIN
			--query update : pcs of lot hasuu that after cancel lot mix pc_request
			UPDATE APCSProDB.trans.surpluses
			SET pcs = case when sur.transfer_flag = 0 then pcs else (pcs + transfer_pcs) end
				,transfer_pcs = 0
				,transfer_flag = 0
				,updated_at = GETDATE()
				--,updated_by = @EmpNo_int
				,updated_by = @EmpnoId --new
			from APCSProDB.trans.lot_combine as lot_cb
			inner join APCSProDB.trans.surpluses as sur on lot_cb.member_lot_id = sur.lot_id
			where lot_cb.lot_id = @lot_id

			--Date Modify : 2023/03/24 Time : 09.29
			INSERT INTO APCSProDB.trans.surpluse_records 
			(
				 recorded_at
				 ,operated_by
				 ,record_class
				 ,surpluse_id
				 ,lot_id
				 ,pcs
				 ,serial_no
				 ,in_stock
				 ,location_id
				 ,acc_location_id
				 ,reprint_count
				 ,created_at
				 ,created_by
				 ,updated_at
				 ,updated_by
				 ,product_code
				 ,qc_instruction
				 ,mark_no
				 ,original_lot_id
				 ,machine_id
				 ,user_code
				 ,product_control_class
				 ,product_class
				 ,production_class
				 ,rank_no
				 ,hinsyu_class
				 ,label_class
				 ,transfer_flag
				 ,transfer_pcs
			)
			SELECT  
				 GETDATE() as record_at
				 --,@EmpNo_int as operated_by
				 ,@EmpnoId as operated_by  --new
				 ,2 as record_class
				 ,id as surpluse_id
				 ,lot_id
				 ,pcs
				 ,serial_no
				 ,in_stock
				 ,location_id
				 ,acc_location_id
				 ,reprint_count
				 ,GETDATE()
				 ,created_by
				 ,GETDATE()
				 ,updated_by
				 ,pdcd
				 ,qc_instruction
				 ,mark_no
				 ,original_lot_id
				 ,machine_id
				 ,user_code
				 ,product_control_class
				 ,product_class
				 ,production_class
				 ,rank_no
				 ,hinsyu_class
				 ,label_class
				 ,transfer_flag
				 ,transfer_pcs
			from APCSProDB.trans.surpluses 
			where serial_no in(select sur.serial_no from APCSProDB.trans.lots 
							   inner join APCSProDB.trans.lot_combine as lot_cb on lots.id = lot_cb.lot_id
							   inner join APCSProDB.trans.surpluses as sur on lot_cb.member_lot_id = sur.lot_id
							   where lot_no = @lot_standard)

			BEGIN TRY
				--UPDATE DATA HASUU QTY IN TABLE LABEL ISUUE RECORD --> Data modify : 2023/03/23 time : 13.33
				UPDATE rec_label
				SET
					qrcode_detail = CAST(rohm_model_name as varchar(19)) + CAST(FORMAT(sur.pcs,'000000') as varchar(6)) + lot_no 
					+ CAST(IIF(VERSION > 9,9,VERSION) AS CHAR(1)) + FORMAT(CAST(no_reel AS INT),'00')
					,barcode_bottom = CAST(FORMAT(sur.pcs,'000000') as varchar(6)) + ' ' + CAST(SUBSTRING(lot_no, 1, 4) + ' ' + SUBSTRING(lot_no, 5, 6) as char(11))
					,qty = sur.pcs
					,update_at = GETDATE()
					--,update_by = @EmpNo_int
					--,op_no = @EmpNo_int
					--,operated_by = @EmpNo_int
					,update_by = @EmpnoId  --new
					,op_no = @EmpnoId  --new
					,operated_by = @EmpnoId  --new
					,op_name = @OPName
					,version = version + 1
				from APCSProDB.trans.label_issue_records as rec_label
				inner join APCSProDB.trans.surpluses as sur on rec_label.lot_no = sur.serial_no
				WHERE lot_no in (select sur.serial_no from APCSProDB.trans.lots 
								 inner join APCSProDB.trans.lot_combine as lot_cb on lots.id = lot_cb.lot_id
								 inner join APCSProDB.trans.surpluses as sur on lot_cb.member_lot_id = sur.lot_id
								 where lot_no = @lot_standard)
				AND type_of_label = 2

				--insert data reprint on label hist  --> Date Modify 2023/03/24 time : 09.29
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
					where lot_no in (select sur.serial_no from APCSProDB.trans.lots 
									 inner join APCSProDB.trans.lot_combine as lot_cb on lots.id = lot_cb.lot_id
									 inner join APCSProDB.trans.surpluses as sur on lot_cb.member_lot_id = sur.lot_id
									 where lot_no = @lot_standard)
					and type_of_label = 2

			END TRY
			BEGIN CATCH
				INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				([record_at]
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
				, 'EXEC [dbo].[tg_sp_cancel_mix_lot Update Hasuu Qty In Table Label Error !! ] @lot_standard = ''' + @lot_standard 
				, @lot_standard
			END CATCH
		END

		--For Re-Work Function --> create 2023/04/05 time : 10.45
		IF @production_category = 23
		BEGIN
			--query update : tranfer_pcs of lot hasuu that after cancel lot re-work function
			UPDATE APCSProDB.trans.surpluses
			SET  transfer_pcs = 0
				,updated_at = GETDATE()
				--,updated_by = @EmpNo_int
				,updated_by = @EmpnoId --new
			from APCSProDB.trans.lot_combine as lot_cb
			inner join APCSProDB.trans.surpluses as sur on lot_cb.member_lot_id = sur.lot_id
			where lot_cb.lot_id = @lot_id

			INSERT INTO APCSProDB.trans.surpluse_records 
			(
				 recorded_at
				 ,operated_by
				 ,record_class
				 ,surpluse_id
				 ,lot_id
				 ,pcs
				 ,serial_no
				 ,in_stock
				 ,location_id
				 ,acc_location_id
				 ,reprint_count
				 ,created_at
				 ,created_by
				 ,updated_at
				 ,updated_by
				 ,product_code
				 ,qc_instruction
				 ,mark_no
				 ,original_lot_id
				 ,machine_id
				 ,user_code
				 ,product_control_class
				 ,product_class
				 ,production_class
				 ,rank_no
				 ,hinsyu_class
				 ,label_class
				 ,transfer_flag
				 ,transfer_pcs
			)
			SELECT  
				 GETDATE() as record_at
				 --,@EmpNo_int as operated_by
				 ,@EmpnoId as operated_by  --new
				 ,2 as record_class
				 ,id as surpluse_id
				 ,lot_id
				 ,pcs
				 ,serial_no
				 ,in_stock
				 ,location_id
				 ,acc_location_id
				 ,reprint_count
				 ,GETDATE()
				 ,created_by
				 ,GETDATE()
				 ,updated_by
				 ,pdcd
				 ,qc_instruction
				 ,mark_no
				 ,original_lot_id
				 ,machine_id
				 ,user_code
				 ,product_control_class
				 ,product_class
				 ,production_class
				 ,rank_no
				 ,hinsyu_class
				 ,label_class
				 ,transfer_flag
				 ,transfer_pcs
			from APCSProDB.trans.surpluses 
			where serial_no in(select sur.serial_no from APCSProDB.trans.lots 
							   inner join APCSProDB.trans.lot_combine as lot_cb on lots.id = lot_cb.lot_id
							   inner join APCSProDB.trans.surpluses as sur on lot_cb.member_lot_id = sur.lot_id
							   where lot_no = @lot_standard)
		END
		ELSE IF @production_category = 21 or @production_category = 22  --create 2023/04/05 time : 16.48
		BEGIN
			--query update : tranfer_pcs of lot hasuu that after cancel lot re-surpluses and resurpluses to rework function
			UPDATE APCSProDB.trans.surpluses
			SET transfer_pcs = case when ISNULL(transfer_pcs,0) = 0 then 0 
					   else (ISNULL(transfer_pcs,0) - @qty_in) end 
				,updated_at = GETDATE()
				--,updated_by = @EmpNo_int
				,updated_by = @EmpnoId  --new
			from APCSProDB.trans.lot_combine as lot_cb
			inner join APCSProDB.trans.surpluses as sur on lot_cb.member_lot_id = sur.lot_id
			where lot_cb.lot_id = @lot_id

			INSERT INTO APCSProDB.trans.surpluse_records 
			(
				 recorded_at
				 ,operated_by
				 ,record_class
				 ,surpluse_id
				 ,lot_id
				 ,pcs
				 ,serial_no
				 ,in_stock
				 ,location_id
				 ,acc_location_id
				 ,reprint_count
				 ,created_at
				 ,created_by
				 ,updated_at
				 ,updated_by
				 ,product_code
				 ,qc_instruction
				 ,mark_no
				 ,original_lot_id
				 ,machine_id
				 ,user_code
				 ,product_control_class
				 ,product_class
				 ,production_class
				 ,rank_no
				 ,hinsyu_class
				 ,label_class
				 ,transfer_flag
				 ,transfer_pcs
			)
			SELECT  
				 GETDATE() as record_at
				 --,@EmpNo_int as operated_by
				 ,@EmpnoId as operated_by  --new
				 ,2 as record_class
				 ,id as surpluse_id
				 ,lot_id
				 ,pcs
				 ,serial_no
				 ,in_stock
				 ,location_id
				 ,acc_location_id
				 ,reprint_count
				 ,GETDATE()
				 ,created_by
				 ,GETDATE()
				 ,updated_by
				 ,pdcd
				 ,qc_instruction
				 ,mark_no
				 ,original_lot_id
				 ,machine_id
				 ,user_code
				 ,product_control_class
				 ,product_class
				 ,production_class
				 ,rank_no
				 ,hinsyu_class
				 ,label_class
				 ,transfer_flag
				 ,transfer_pcs
			from APCSProDB.trans.surpluses 
			where serial_no in(select sur.serial_no from APCSProDB.trans.lots 
							   inner join APCSProDB.trans.lot_combine as lot_cb on lots.id = lot_cb.lot_id
							   inner join APCSProDB.trans.surpluses as sur on lot_cb.member_lot_id = sur.lot_id
							   where lot_no = @lot_standard)
		END
	END
	ELSE BEGIN
		--check work hasuu stock in cancel --> if cancel hasuu stock in change wip state = 20 ,Date modify 2022/02/22 Time : 08.33
		IF @wip_state = 70
		BEGIN
			UPDATE APCSProDB.trans.lots set wip_state = 20 where lot_no = @lot_standard
		END
	END
	--edit 17/03/2022 9.40

	DELETE FROM APCSProDB.trans.label_issue_records WHERE lot_no = @lot_standard

	BEGIN TRY
		delete APCSProDB.trans.lot_combine where lot_id = @lot_id
	END TRY
	BEGIN CATCH 
		SELECT 'FALSE' AS Status ,'UPDATE DATA INSTOCK ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH

	BEGIN TRY
		--Set Record Class = 47 is Cancel TG or Cancel Mixing on web Atom //Date Create : 2022/07/01 Time : 14.09
		EXEC [StoredProcedureDB].[trans].[sp_set_record_class_lot_process_records]
			 @lot_no = @lot_standard
			,@opno = @emp_no
			,@record_class = 47
			,@mcno = 'TP-ATOM-00'
		END TRY
		BEGIN CATCH 
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				([record_at]
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
				, 'EXEC [dbo].[tg_sp_cancel_mix_lot Create Record Class Cancel TG or Cancel Mixing Error] @lot_standard = ''' + @lot_standard 
				, @lot_standard
		END CATCH

		--DELETE DATA ON APCSPro INTERFACE 2022/12/08 Time : 09.38
		DELETE APCSProDWH.dbo.MIX_HIST_IF where HASUU_LotNo = @lot_standard
		DELETE APCSProDWH.dbo.LSI_SHIP_IF where LotNo = @lot_standard
		DELETE APCSProDWH.dbo.H_STOCK_IF where LotNo = @lot_standard
		DELETE APCSProDWH.dbo.PACKWORK_IF where LotNo = @lot_standard
		DELETE APCSProDWH.dbo.WH_UKEBA_IF where LotNo = @lot_standard
		DELETE APCSProDWH.dbo.WORK_R_DB_IF where LotNo = @lot_standard

		--DELETE DATA IN PROCESS RECALL IF TABLE  >>> create : 2023/11/09 time : 14.41 by aomsin <<<
		IF @production_category = 70
		BEGIN
			IF @LotType = 'D' 
			BEGIN
				DELETE APCSProDWH.dbo.PROCESS_RECALL_IF where NEWLOT = @lot_standard

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
					,'EXEC [dbo].[tg_sp_cancel_mix_lot delete data in table PROCESS_RECALL_IF] @lot_standard = ''' + @lot_standard + ''''
					,@lot_standard
			END
		END
END
