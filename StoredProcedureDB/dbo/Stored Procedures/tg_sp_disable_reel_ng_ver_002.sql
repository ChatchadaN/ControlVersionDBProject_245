-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_disable_reel_ng_ver_002]
	-- Add the parameters for the stored procedure here
	  @lotno_standard varchar(10) = ''
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
	--Check Carrier
	DECLARE @Carrier varchar(11) = ''
	--add declare 2022/08/24 time : 10.00
	DECLARE @qty_pass int = 0
	DECLARE @send_id int = 0 -- 0:not send 1:send
	--add parameter 2023/09/06 time : 14.07
	DECLARE @production_cat int = null
	--add parameter 2024/05/31 time 09.48
	DECLARE @pc_instruction_code int = null
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
		,'EXEC [dbo].[tg_sp_disable_reel_ng_ver_002] @lot_no = ''' + @lotno_standard + ''' @Reel_no = ''' + CAST(@reel_no as varchar(20)) + ''' @qty_input = ''' + CAST(@qty_input as varchar(7)) + ''' @qty_good = ''' + CAST(@qty_good as varchar(7)) + ''' @empno = ''' + @emp_no + ''' @count_reel_ng = ''' + CAST(@count_reel_ng as varchar(7)) + ''''
		,@lotno_standard

	select @EmpNo_int = CONVERT(INT, @emp_no)

	--------------------- Start Get EmpnoId #Modify : 2024/12/26 ---------------------------------------
	DECLARE @GetEmpno varchar(6) = ''
	DECLARE @EmpnoId int = null
	SELECT @GetEmpno = FORMAT(CAST(@emp_no AS INT), '000000')
	SELECT @EmpnoId = id FROM [APCSProDB].[man].[users] WHERE [emp_num] = @GetEmpno
	------------------------------ End Get EmpnoId #Modify : 2024/12/26 --------------------------------
	
	select @Standard_Reel = dn.pcs_per_pack 
		,@State_instock = sur.in_stock
		,@qty_hasuu_before = pcs
		,@device_name = dn.name
		,@qty_shipment_old = lot.qty_out
		,@qty_pass = lot.qty_pass --add set @qty_pass 2022/08/24 time : 10.00
		,@production_cat = lot.production_category
		,@pc_instruction_code = lot.pc_instruction_code  
	from APCSProDB.trans.lots as lot
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	inner join APCSProDB.trans.surpluses as sur on lot.id = sur.lot_id
	where lot.lot_no = @lotno_standard

	--Use at web LSMS date modify : 2022/03/21 time : 14.36
	DECLARE @count_reel_ng_all NVARCHAR(max) = ''
	DECLARE @qty_all_reel_ng int = 0
	SELECT @count_reel_ng_all = COUNT(value) FROM string_split(@reel_no, ',')
	SELECT @qty_all_reel_ng = CASE WHEN @pc_instruction_code = 13 then 0 else @Standard_Reel * @count_reel_ng_all end  --add condition check if pc_code = 13 fix set qty_all_reel_ng is 0 (date modify : 2024/05/31 time : 09.48)

	--add condition check type of label is 20 if pc code = 13 (date modify : 2024/05/31 time : 09.48)
	IF @pc_instruction_code = 13
	BEGIN
		--Disable Reel NG
		UPDATE APCSProDB.trans.label_issue_records
			set type_of_label = 0
			,update_at = GETDATE()
			--,update_by = @EmpNo_int
			,update_by = @EmpnoId  --new
		where lot_no = @lotno_standard
		and type_of_label = 20  
		and no_reel in(SELECT value FROM string_split(@reel_no, ','))
	END
	ELSE
	BEGIN
		--Disable Reel NG
		UPDATE APCSProDB.trans.label_issue_records
			set type_of_label = 0
			,update_at = GETDATE()
			--,update_by = @EmpNo_int
			,update_by = @EmpnoId  --new
		where lot_no = @lotno_standard
		and type_of_label = 3  
		and no_reel in(SELECT value FROM string_split(@reel_no, ','))
	END
	
	DECLARE @Count_reel_good_all int = 0
	select @Count_reel_good_all = COUNT(type_of_label) from APCSProDB.trans.label_issue_records where lot_no = @lotno_standard and type_of_label = 3

	DECLARE @Count_reel_max int = 0
	select @Count_reel_max = MAX(CAST(no_reel as int)) from APCSProDB.trans.label_issue_records where lot_no = @lotno_standard and type_of_label in (0,3)

	--Add condition Check is_web date modify : 2022/03/21 time : 14.36
	select @qty_shipment = case when @state = 1 then (@Standard_Reel * @Count_reel_good_all)  --update condition 2022/03/29 time : 9.31
				else ((@Standard_Reel) * (((@qty_input)/(@Standard_Reel)) - @count_reel_ng)) end

	select @hasuu_now_value = (@qty_good - @qty_shipment)

	--add condition check count reel max 2022/04/01 time : 10.49
	--add condition IIF(@production_cat = 23,(@qty_hasuu_before + @qty_all_reel_ng),@qty_hasuu_before) date : 2023/09/06 time : 14.07
	select @qty_hasuu_in_label = case when @state = 1 
				then 
					case when @State_instock = 2 then  (@qty_hasuu_before + @qty_all_reel_ng)  --edit date : 2023/09/13 time : 12.16 
						 when @State_instock = 0 then  case when @Count_reel_max = 1 then IIF(@production_cat IN (20,23,50),(@qty_hasuu_before + @qty_all_reel_ng),@qty_hasuu_before)  --add production_cat 20 Date edit >> 2024/04/01 time : 09.50 <<
															else (@qty_all_reel_ng) end  --edit date : 2023/11/20 time : 10.35 by Aomsin
															--else (@qty_hasuu_before + @qty_all_reel_ng) end --old close --> 2023/11/20 time : 10.35 by Aomsin
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

	--add query 2022/08/24 time : 10.00
	SET @Qrcode_Forslip = CAST(@device_name AS CHAR(19)) + FORMAT(@qty_forslip_in_label,'000000') + CAST(@lotno_standard AS CHAR(10)) + @Reel_Forslip;
	SET @Qrcode_Hasuu = CAST(@device_name AS CHAR(19)) + FORMAT(@qty_hasuu_in_label,'000000') + CAST(@lotno_standard AS CHAR(10)) + @Reel_Hasuu;
	SET @Barcode_buttom_hasuu = FORMAT(@qty_hasuu_in_label,'000000') + SPACE(1) + CAST(SUBSTRING(@lotno_standard, 1, 4) AS CHAR(4)) + SPACE(1) + CAST(SUBSTRING(@lotno_standard, 5, 6) AS CHAR(6));

	IF @state = 1 --web
	BEGIN
		BEGIN TRY

			--close function update qty after disable reel --> date modify : 2022/03/28 time : 14.11
			--update qty_hasuu in tranlot date modify : 2022/03/21 time : 14.36 , date update 2022/03/29 time : 09.31
			UPDATE APCSProDB.trans.lots
			SET qty_out = @qty_shipment
				,qty_hasuu = case when @State_instock = 2 then @qty_hasuu_in_label 
								  when @State_instock = 1 then qty_hasuu
								  else 0 end
				,wip_state = case when @Count_reel_good_all = 0 then 70 else wip_state end  --update 2022/03/31 time : 15.42
				--check @Count_reel_good_all = 0 Let clear carrier is null
				,carrier_no = case when @Count_reel_good_all = 0 then null else carrier_no end --update 2022/05/09 time : 09.38
			WHERE lot_no = @lotno_standard

			--update qty_hasuu in surpluses
			UPDATE APCSProDB.trans.surpluses
			SET pcs = case when @State_instock = 1 then pcs else @qty_hasuu_in_label end  --Add condition 2022/04/08 time : 9.15
				,updated_at = GETDATE()
				--,updated_by = @EmpNo_int
				,updated_by = @EmpnoId  --new
			WHERE serial_no = @lotno_standard

			--insert surpluses_record is update
			EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
			,@sataus_record_class = 2

			--Update Qty Forslip
			UPDATE APCSProDB.trans.label_issue_records 
			SET qty = @qty_forslip_in_label
				,barcode_bottom = @qty_forslip_in_label
				,qrcode_detail = @Qrcode_Forslip
				,update_at = GETDATE()
				--,update_by = @EmpNo_int
				,update_by = @EmpnoId  --new
			WHERE lot_no = @lotno_standard
			AND type_of_label = 1

			--Update Qty ForHasuu
			UPDATE APCSProDB.trans.label_issue_records 
			SET qty = @qty_hasuu_in_label
				,barcode_bottom = @Barcode_buttom_hasuu
				,qrcode_detail = @Qrcode_Hasuu
				,update_at = GETDATE()
				--,update_by = @EmpNo_int
				,update_by = @EmpnoId  --new
			WHERE lot_no = @lotno_standard
			and type_of_label = 2

			--add query 2022/05/09 time : 09.38
			select @Carrier = case when carrier_no is null then '-' else carrier_no end 
			from APCSProDB.trans.lots 
			where lot_no = @lotno_standard

			--add query 2022/08/24 time : 10.00
			-- send Ukebarai Data
			IF (@Count_reel_good_all = 0)
			BEGIN
				INSERT INTO [DBx].[dbo].[UkebaraiData]
					([DBxProcessID]
					, [DBxLotNo]
					, [DBxMCNo]
					, [DBxLotStartTime]
					, [DBxLotEndTime]
					, [LotNo]
					, [Process_No]
					, [Date]
					, [Time]
					, [Good_Qty]
					, [NG_Qty]
					, [Shipment_Qty])
				SELECT 
					18 AS [DBxProcessID]
					, CAST([lot_no] AS CHAR(10)) AS [DBxLotNo]
					, 'Manual' AS [DBxMCNo]
					, GETDATE() AS [DBxLotStartTime]
					, GETDATE() AS [DBxLotEndTime]
					, CAST([lot_no] AS CHAR(10)) AS [LotNo]
					, '01201' AS [Process_No]
					, FORMAT(GETDATE(),'yyMMdd') AS [Date]
					, FORMAT(GETDATE(),'HHmm') AS [Time] 
					, '00000' AS [Good_Qty]
					, FORMAT(CONVERT(int,[qty_pass]), '00000') AS [NG_Qty]
					,'00000' AS [Shipment_Qty]
				FROM [APCSProDB].[trans].[lots]
				WHERE lot_no = @lotno_standard;
				SET @send_id = 1;
				-------------------------------------------------------
				--add query 2023/05/22 time : 11.27
				DECLARE @good_qty INT
				SELECT @good_qty = [qty_pass]
				FROM [APCSProDB].[trans].[lots]
				WHERE lot_no = @lotno_standard;

				IF (@good_qty < 0) 
				BEGIN
					INSERT INTO [APCSProDWH].[dbo].[ukebarai_errors]
						( [lot_no]
						, [process_no]
						, [date]
						, [time]
						, [good_qty]
						, [ng_qty]
						, [shipment_qty]
						, [mc_name] )
					SELECT @lotno_standard AS [lot_no]
						, '01201' AS [process_no]
						, FORMAT(GETDATE(),'yyMMdd') AS [date]
						, FORMAT(GETDATE(),'HHmm') AS [time]
						, 0 AS [good_qty]
						, @good_qty AS [ng_qty]
						, 0 AS [shipment_qty]
						, 'Manual' AS [mc_name];
				END
				ELSE BEGIN
					INSERT INTO [APCSProDWH].[dbo].[ukebarais]
						( [lot_no]
						, [process_no]
						, [date]
						, [time]
						, [good_qty]
						, [ng_qty]
						, [shipment_qty]
						, [mc_name] )
					SELECT @lotno_standard AS [lot_no]
						, '01201' AS [process_no]
						, FORMAT(GETDATE(),'yyMMdd') AS [date]
						, FORMAT(GETDATE(),'HHmm') AS [time]
						, 0 AS [good_qty]
						, @good_qty AS [ng_qty]
						, 0 AS [shipment_qty]
						, 'Manual' AS [mc_name];
				END
				-------------------------------------------------------
			END

			--add query log 2022/05/09 time : 09.38
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
				,'EXEC [dbo].[tg_sp_disable_reel_ng_check_carrier] @lot_no = ''' + @lotno_standard + ''' @Reel_no = ''' + CAST(@reel_no as varchar(20)) + ''' @qty_input = ''' + CAST(@qty_input as varchar(7)) + ''' @qty_good = ''' + CAST(@qty_good as varchar(7)) + ''' @empno = ''' + @emp_no + ''' @count_reel_ng = ''' + CAST(@count_reel_ng as varchar(7)) + ''' @carrier_no = ''' + @Carrier + ''' send UkebaraiData=' + IIF(@send_id = 1,'TRUE','FALSE')
				,@lotno_standard


			SELECT 'TRUE' AS Status ,'Disable Reel or Update qty_shipment Success !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA 
			RETURN
		END TRY
		BEGIN CATCH 
			SELECT 'FALSE' AS Status ,'Disable Reel or Update qty_shipment Error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH
	END

END
