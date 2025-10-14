-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_disable_reel_ng_testbass]
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
	--DECLARE @EmpNo_int int = 0
	--DECLARE @Standard_Reel int = 0
	--DECLARE @State_instock tinyint = 5 --default is 5
	--DECLARE @hasuu_now_value int = 0
	--DECLARE @qty_shipment int = 0
	--DECLARE @qty_shipment_old int = 0
	----Label--
	--DECLARE @Reel_Forslip char(3) = ''
	--DECLARE @Reel_Hasuu char(3) = ''
	--DECLARE @Qrcode_Forslip char(90) = ''
	--DECLARE @Qrcode_Hasuu char(90) = ''
	--DECLARE @device_name char(20) = ''
	--DECLARE @Barcode_buttom_hasuu char(18) = ''
	--DECLARE @qty_hasuu_before int = 0
	--DECLARE @qty_hasuu_in_label int  = 0
	--DECLARE @qty_forslip_in_label int = 0

 --   -- Insert statements for procedure here
	
	--INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--(
	--	[record_at]
	--	, [record_class]
	--	, [login_name]
	--	, [hostname]
	--	, [appname]
	--	, [command_text]
	--	, [lot_no]
	--)
	--SELECT GETDATE()
	--	, '4'
	--	, ORIGINAL_LOGIN()
	--	, HOST_NAME()
	--	, APP_NAME()
	--	, 'EXEC [dbo].[tg_sp_disable_reel_ng] @lot_no = ''' + @lotno_standard 
	--		+ ''' @Reel_no = ''' + CAST(@reel_no as varchar(20)) 
	--		+ ''' @qty_input = ''' + CAST(@qty_input as varchar(7)) 
	--		+ ''' @qty_good = ''' + CAST(@qty_good as varchar(7)) 
	--		+ ''' @empno = ''' + @emp_no 
	--		+ ''' @count_reel_ng = ''' + CAST(@count_reel_ng as varchar(7)) + ''''
	--	, @lotno_standard


	--select @EmpNo_int = CONVERT(INT, @emp_no)
	
	--select @Standard_Reel = dn.pcs_per_pack 
	--,@State_instock = sur.in_stock
	--,@qty_hasuu_before = pcs
	--,@device_name = dn.name
	--,@qty_shipment_old = lot.qty_out
	--from APCSProDB.trans.lots as lot
	--inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	--inner join APCSProDB.trans.surpluses as sur on lot.id = sur.lot_id
	--where lot.lot_no = @lotno_standard

	----Use at web LSMS date modify : 2022/03/21 time : 14.36
	--DECLARE @count_reel_ng_all NVARCHAR(max) = ''
	--DECLARE @qty_all_reel_ng int = 0
	--SELECT @count_reel_ng_all = COUNT(value) FROM string_split(@reel_no, ',')
	--SELECT @qty_all_reel_ng = @Standard_Reel * @count_reel_ng_all 


	----Disable Reel NG
	----UPDATE APCSProDB.trans.label_issue_records
	----set type_of_label = 0
	----	, update_at = GETDATE()
	----	, update_by = @EmpNo_int
	----where lot_no = @lotno_standard
	----	and type_of_label = 3
	----	and no_reel in(SELECT value FROM string_split(@reel_no, ','))

	--DECLARE @Count_reel_good_all int = 0
	--select @Count_reel_good_all = COUNT(type_of_label) from APCSProDB.trans.label_issue_records where lot_no = @lotno_standard and type_of_label = 3

	--DECLARE @Count_reel_max int = 0
	--select @Count_reel_max = MAX(CAST(no_reel as int)) from APCSProDB.trans.label_issue_records where lot_no = @lotno_standard and type_of_label in (0,3)

	----Add condition Check is_web date modify : 2022/03/21 time : 14.36
	--select @qty_shipment = case when @state = 1 then (@Standard_Reel * @Count_reel_good_all)  --update condition 2022/03/29 time : 9.31
	--			else ((@Standard_Reel) * (((@qty_input)/(@Standard_Reel)) - @count_reel_ng)) end

	--select @hasuu_now_value = (@qty_good - @qty_shipment)

	----add condition check count reel max 2022/04/01 time : 10.49
	--select @qty_hasuu_in_label = case when @state = 1 
	--			then 
	--				case when @State_instock = 2 then  case when @Count_reel_max = 1 then (@qty_hasuu_before) else (@qty_hasuu_before + @qty_all_reel_ng) end
	--					 when @State_instock = 0 then  case when @Count_reel_max = 1 then (@qty_hasuu_before) else (@qty_hasuu_before + @qty_all_reel_ng) end
	--					 when @State_instock = 1 then  @qty_hasuu_before
	--					 else @qty_shipment end
	--			else (@qty_hasuu_before + @hasuu_now_value) end

	--select @qty_forslip_in_label = (@qty_shipment + @qty_hasuu_in_label)

	---- CREATE 2021/10/01 : Get Data Qrcode
	--select @Reel_Forslip = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
	--where lot_no = @lotno_standard 
	--and type_of_label = 1

	--select @Reel_Hasuu = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
	--where lot_no = @lotno_standard 
	--and type_of_label = 2

	--select @Qrcode_Forslip = Cast(@device_name as varchar(19)) + case when LEN(CAST(@qty_forslip_in_label as varchar(6))) = 5 
	--	then '0' + CAST(@qty_forslip_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Forslip
	--	when LEN(CAST(@qty_forslip_in_label as varchar(6))) = 4 
	--	then '00' + CAST(@qty_forslip_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Forslip
	--	when LEN(CAST(@qty_forslip_in_label as varchar(6))) = 3 
	--	then '000' + CAST(@qty_forslip_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Forslip
	--	when LEN(CAST(@qty_forslip_in_label as varchar(6))) = 2 
	--	then '0000' + CAST(@qty_forslip_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Forslip
	--	when LEN(CAST(@qty_forslip_in_label as varchar(6))) = 1 
	--	then '00000' + CAST(@qty_forslip_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Forslip
	--	else CAST(@qty_forslip_in_label as varchar(6)) + CAST(@lotno_standard as varchar(10)) + @Reel_Forslip end 

	--select @Qrcode_Hasuu = Cast(@device_name as varchar(19)) + case when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 5 
	--	then '0' + CAST(@qty_hasuu_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu
	--	when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 4 
	--	then '00' + CAST(@qty_hasuu_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu
	--	when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 3 
	--	then '000' + CAST(@qty_hasuu_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu
	--	when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 2 
	--	then '0000' + CAST(@qty_hasuu_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu
	--	when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 1 
	--	then '00000' + CAST(@qty_hasuu_in_label as varchar(6))  + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu
	--	else CAST(@qty_hasuu_in_label as varchar(6)) + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu end 
			
	--select @Barcode_buttom_hasuu = case when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 5 then '0' + CAST(@qty_hasuu_in_label as varchar(6)) + ' ' + Cast(SUBSTRING(@lotno_standard, 1, 4) + ' ' + SUBSTRING(@lotno_standard, 5, 6) as char(11))
	--	when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 4 then '00' + CAST(@qty_hasuu_in_label as varchar(6)) + ' ' + Cast(SUBSTRING(@lotno_standard, 1, 4) + ' ' + SUBSTRING(@lotno_standard, 5, 6) as char(11))
	--	when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 3 then '000' + CAST(@qty_hasuu_in_label as varchar(6)) + ' ' + Cast(SUBSTRING(@lotno_standard, 1, 4) + ' ' + SUBSTRING(@lotno_standard, 5, 6) as char(11))
	--	when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 2 then '0000' + CAST(@qty_hasuu_in_label as varchar(6)) + ' ' + Cast(SUBSTRING(@lotno_standard, 1, 4) + ' ' + SUBSTRING(@lotno_standard, 5, 6) as char(11))
	--	when LEN(CAST(@qty_hasuu_in_label as varchar(6))) = 1 then '00000' + CAST(@qty_hasuu_in_label as varchar(6)) + ' ' + Cast(SUBSTRING(@lotno_standard, 1, 4) + ' ' + SUBSTRING(@lotno_standard, 5, 6) as char(11))
	--	else CAST(@qty_hasuu_in_label as varchar(6)) + ' ' + Cast(SUBSTRING(@lotno_standard, 1, 4) + ' ' + SUBSTRING(@lotno_standard, 5, 6) as char(10)) end
	--	+ '''';

	--set @Qrcode_Forslip = cast(@device_name as varchar(19)) + right('000000'+ convert(varchar,@qty_forslip_in_label),6) + cast(@lotno_standard as varchar(10)) + @Reel_Forslip
	--set @Qrcode_Hasuu = cast(@device_name as varchar(19)) + right('000000'+ convert(varchar,@qty_hasuu_in_label),6) + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu
	--set @Barcode_buttom_hasuu = right('000000'+ convert(varchar,@qty_hasuu_in_label),6) + SPACE(1) + cast(SUBSTRING(@lotno_standard, 1, 4) + SPACE(1) + SUBSTRING(@lotno_standard, 5, 6) as char(11)) 


	--IF @state = 1 --web
	--BEGIN
	--	BEGIN TRY

	--		----close function update qty after disable reel --> date modify : 2022/03/28 time : 14.11
	--		----update qty_hasuu in tranlot date modify : 2022/03/21 time : 14.36 , date update 2022/03/29 time : 09.31
	--		--UPDATE APCSProDB.trans.lots
	--		--SET qty_out = @qty_shipment
	--		--	,qty_hasuu = case when @State_instock = 2 then @qty_hasuu_in_label 
	--		--					  when @State_instock = 1 then qty_hasuu
	--		--					  else 0 end
	--		--	,wip_state = case when @Count_reel_good_all = 0 then 70 else wip_state end  --update 2022/03/31 time : 15.42
	--		--WHERE lot_no = @lotno_standard

	--		----update qty_hasuu in surpluses
	--		--UPDATE APCSProDB.trans.surpluses
	--		--SET pcs = @qty_hasuu_in_label
	--		--	,updated_at = GETDATE()
	--		--	,updated_by = @EmpNo_int
	--		--WHERE serial_no = @lotno_standard

	--		----insert surpluses_record is update
	--		--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
	--		--,@sataus_record_class = 2

	--		----Update Qty Forslip
	--		--UPDATE APCSProDB.trans.label_issue_records 
	--		--set qty = @qty_forslip_in_label
	--		--,barcode_bottom = @qty_forslip_in_label
	--		--,qrcode_detail = @Qrcode_Forslip
	--		--,update_at = GETDATE()
	--		--,update_by = @EmpNo_int
	--		--where lot_no = @lotno_standard
	--		--and type_of_label = 1

	--		----Update Qty ForHasuu
	--		--UPDATE APCSProDB.trans.label_issue_records 
	--		--set qty = @qty_hasuu_in_label
	--		--,barcode_bottom = @Barcode_buttom_hasuu
	--		--,qrcode_detail = @Qrcode_Hasuu
	--		--,update_at = GETDATE()
	--		--,update_by = @EmpNo_int
	--		--where lot_no = @lotno_standard
	--		--and type_of_label = 2


	--		SELECT 'TRUE' AS Status ,'Disable Reel or Update qty_shipment Success !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA 
	--		RETURN
	--	END TRY
	--	BEGIN CATCH 
	--		SELECT 'FALSE' AS Status ,'Disable Reel or Update qty_shipment Error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
	--		RETURN
	--	END CATCH
	--END


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
		, 'EXEC [dbo].[tg_sp_disable_reel_ng] @lot_no = ''' + @lotno_standard 
			+ ''' @Reel_no = ''' + CAST(@reel_no as varchar(20)) 
			+ ''' @qty_input = ''' + CAST(@qty_input as varchar(7)) 
			+ ''' @qty_good = ''' + CAST(@qty_good as varchar(7)) 
			+ ''' @empno = ''' + @emp_no 
			+ ''' @count_reel_ng = ''' + CAST(@count_reel_ng as varchar(7)) + ''''
		, @lotno_standard




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


	--Disable Reel NG
	--UPDATE APCSProDB.trans.label_issue_records
	--set type_of_label = 0
	--	, update_at = GETDATE()
	--	, update_by = @EmpNo_int
	--where lot_no = @lotno_standard
	--	and type_of_label = 3
	--	and no_reel in(SELECT value FROM string_split(@reel_no, ','))

	DECLARE @Count_reel_good_all int = 0
	select @Count_reel_good_all = COUNT(type_of_label) from APCSProDB.trans.label_issue_records where lot_no = @lotno_standard and type_of_label = 3

	DECLARE @Count_reel_max int = 0
	select @Count_reel_max = MAX(CAST(no_reel as int)) from APCSProDB.trans.label_issue_records where lot_no = @lotno_standard and type_of_label in (0,3)

	--Add condition Check is_web date modify : 2022/03/21 time : 14.36
	set @qty_shipment = (
		case 
			when @state = 1 then (@Standard_Reel * @Count_reel_good_all)  --update condition 2022/03/29 time : 9.31
			else ((@Standard_Reel) * (((@qty_input)/(@Standard_Reel)) - @count_reel_ng)) 
		end
	)

	set @hasuu_now_value = (@qty_good - @qty_shipment)

	--add condition check count reel max 2022/04/01 time : 10.49
	select @qty_hasuu_in_label = case when @state = 1 
				then 
					case when @State_instock = 2 then  case when @Count_reel_max = 1 then (@qty_hasuu_before) else (@qty_hasuu_before + @qty_all_reel_ng) end
						 when @State_instock = 0 then  case when @Count_reel_max = 1 then (@qty_hasuu_before) else (@qty_hasuu_before + @qty_all_reel_ng) end
						 when @State_instock = 1 then  @qty_hasuu_before
						 else @qty_shipment end
				else (@qty_hasuu_before + @hasuu_now_value) end

	set @qty_forslip_in_label = (@qty_shipment + @qty_hasuu_in_label)

	-- CREATE 2021/10/01 : Get Data Qrcode
	set @Reel_Forslip = ( select SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
							where lot_no = @lotno_standard and type_of_label = 1 )

	set @Reel_Hasuu = ( select SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
						where lot_no = @lotno_standard and type_of_label = 2 )

	set @Qrcode_Forslip = cast(@device_name as varchar(19)) + right('000000'+ convert(varchar,@qty_forslip_in_label),6) + cast(@lotno_standard as varchar(10)) + @Reel_Forslip
	set @Qrcode_Hasuu = cast(@device_name as varchar(19)) + right('000000'+ convert(varchar,@qty_hasuu_in_label),6) + CAST(@lotno_standard as varchar(10)) + @Reel_Hasuu
	set @Barcode_buttom_hasuu = right('000000'+ convert(varchar,@qty_hasuu_in_label),6) + SPACE(1) + cast(SUBSTRING(@lotno_standard, 1, 4) + SPACE(1) + SUBSTRING(@lotno_standard, 5, 6) as char(11)) 


	IF @state = 1 --web
	BEGIN
		BEGIN TRY

			----close function update qty after disable reel --> date modify : 2022/03/28 time : 14.11
			----update qty_hasuu in tranlot date modify : 2022/03/21 time : 14.36 , date update 2022/03/29 time : 09.31
			--UPDATE APCSProDB.trans.lots
			--SET qty_out = @qty_shipment
			--	,qty_hasuu = case when @State_instock = 2 then @qty_hasuu_in_label 
			--					  when @State_instock = 1 then qty_hasuu
			--					  else 0 end
			--	,wip_state = case when @Count_reel_good_all = 0 then 70 else wip_state end  --update 2022/03/31 time : 15.42
			--WHERE lot_no = @lotno_standard

			----update qty_hasuu in surpluses
			--UPDATE APCSProDB.trans.surpluses
			--SET pcs = @qty_hasuu_in_label
			--	,updated_at = GETDATE()
			--	,updated_by = @EmpNo_int
			--WHERE serial_no = @lotno_standard

			----insert surpluses_record is update
			--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
			--,@sataus_record_class = 2

			----Update Qty Forslip
			--UPDATE APCSProDB.trans.label_issue_records 
			--set qty = @qty_forslip_in_label
			--,barcode_bottom = @qty_forslip_in_label
			--,qrcode_detail = @Qrcode_Forslip
			--,update_at = GETDATE()
			--,update_by = @EmpNo_int
			--where lot_no = @lotno_standard
			--and type_of_label = 1

			----Update Qty ForHasuu
			--UPDATE APCSProDB.trans.label_issue_records 
			--set qty = @qty_hasuu_in_label
			--,barcode_bottom = @Barcode_buttom_hasuu
			--,qrcode_detail = @Qrcode_Hasuu
			--,update_at = GETDATE()
			--,update_by = @EmpNo_int
			--where lot_no = @lotno_standard
			--and type_of_label = 2


			SELECT 'TRUE' AS Status ,'Disable Reel or Update qty_shipment Success !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA 
			RETURN
		END TRY
		BEGIN CATCH 
			SELECT 'FALSE' AS Status ,'Disable Reel or Update qty_shipment Error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH
	END

END
