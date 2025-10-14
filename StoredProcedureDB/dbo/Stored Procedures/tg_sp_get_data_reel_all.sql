-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,2022/02/26,>
-- Description:	<Description,use function rollback reel cancel,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_reel_all]
	-- Add the parameters for the stored procedure here
	 @lotno varchar(17) = ''
	,@reel_no NVARCHAR(max) = ''
	,@count_reel_rollback int = 0
	,@emp_no char(6) = ''
	,@status_int int = 0 --1 is get data,2 is set data

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @qty_shipment int = 0
	DECLARE @Count_reel_good_all int = 0
	DECLARE @Standard_Reel int = 0
	DECLARE @qty_hasuu int = 0
	DECLARE @qty_forslip_in_label int = 0
	--Label
	DECLARE @Reel_Forslip char(3) = ''
	DECLARE @Qrcode_Forslip char(90) = ''
	DECLARE @device_name char(20) = ''
	--Update Qty_Hasuu and Label For Hasuu
	DECLARE @Qrcode_ForHasuu char(90) = ''
	DECLARE @Barcode_buttom_hasuu char(18) = ''
	DECLARE @qty_hasuu_rollback int = 0
	DECLARE @Reel_ForHasuu_Number char(3) = ''
	DECLARE @qty_hasuu_now int = 0
	DECLARE @in_stock_now int = 0
	DECLARE @Count_Reel_Rollback_All int = 0
	DECLARE @get_lot_by_eslno varchar(10) = ''

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
		,'EXEC [dbo].[tg_sp_get_data_reel_all] @lot_no = ''' + @lotno + ''' @Reel_no = ''' + CAST(@reel_no as varchar(20)) + ''' @Status = ''' + CAST(@status_int as varchar(2)) + ''' @Count_Reel_Rollback = ''' + CAST(@count_reel_rollback as varchar(2)) + ''' @empno = ''' + @emp_no + ''''
		,@lotno

	SELECT @Count_Reel_Rollback_All = COUNT(value) FROM string_split(@reel_no, ',')

	--Add condition 2025/02/10 time : 14.50 by Aomsin
	IF EXISTS (SELECT 1 FROM APCSProDB.trans.lots WHERE e_slip_id = @lotno)
	BEGIN
		SELECT @get_lot_by_eslno = lot_no FROM APCSProDB.trans.lots WHERE e_slip_id = @lotno
		SET @lotno = @get_lot_by_eslno
	END

	SELECT @lotno = TRIM(@lotno)

	SELECT 
		 @Standard_Reel = dn.pcs_per_pack 
		,@device_name = dn.name
		,@in_stock_now = sur.in_stock
	FROM APCSProDB.trans.lots as lot
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	inner join APCSProDB.trans.surpluses as sur on lot.id = sur.lot_id
	where lot.lot_no = @lotno

    -- Insert statements for procedure here
	IF @lotno != ''
	BEGIN
		IF @status_int = 1 --GET DATA
		BEGIN
			select no_reel 
			from APCSProDB.trans.label_issue_records 
			where lot_no = @lotno
			and type_of_label = 0
		END
		ELSE IF @status_int = 2 --SET DATA
		BEGIN
			BEGIN TRY
				--RollBack Reel 
				UPDATE APCSProDB.trans.label_issue_records
				SET type_of_label = 3
				,update_at = GETDATE()
				,update_by = CAST(@emp_no as int)
				where lot_no = @lotno
				and type_of_label = 0
				and no_reel in(SELECT value FROM string_split(@reel_no, ','))

				--Add Function Update qty_out After to do Rollback Reel Date Modify : 2022/04/14 Time : 09.40
				--Get Data All Reel Count
				select @Count_reel_good_all = COUNT(type_of_label) from APCSProDB.trans.label_issue_records where lot_no = @lotno and type_of_label = 3
				select @Reel_Forslip = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
				where lot_no = @lotno
				and type_of_label = 1

				--สูตรหาจำนวนงาน Hasuu ที่ Rollback Reel กลับไป
				select @qty_hasuu_rollback = (@Count_Reel_Rollback_All * @Standard_Reel)

				--สูตรหาจำนวนงาน Hasuu ที่เหลือล่าสุด หลังจาก Rollback Reel กลับไป
				select @qty_hasuu_now = case when qty = 0 then @qty_hasuu_rollback 
										     when qty < @qty_hasuu_rollback then qty
												else (qty - @qty_hasuu_rollback) end
				from APCSProDB.trans.label_issue_records 
				where lot_no = @lotno and type_of_label = 2

				--สูตรคำนวณหาค่า qty_shipment หรือ qty_out
				select @qty_shipment = (@Count_reel_good_all * @Standard_Reel)
				--Get Data qty Hasuu
				--select @qty_hasuu = qty from APCSProDB.trans.label_issue_records where lot_no = @lotno and type_of_label = 2
				select @qty_forslip_in_label = (@Count_reel_good_all * @Standard_Reel) + @qty_hasuu_now
				--Get Data Qrcode in ForSlip
				select @Qrcode_Forslip = cast(@device_name as varchar(19)) + right('000000'+ convert(varchar,@qty_forslip_in_label),6) + cast(@lotno as varchar(10)) + @Reel_Forslip
				
				--------------------------------------------- New Get Data Hasuu 2022/06/23 Time : 11.30 -----------------------------------------------
				--Get Reel Number of Label For Hasuu
				select @Reel_ForHasuu_Number = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
				where lot_no = @lotno and type_of_label = 2

				--Create New Data Qrcode For Label Hasuu
				select @Qrcode_ForHasuu = cast(@device_name as varchar(19)) + right('000000'+ convert(varchar,@qty_hasuu_now),6) + cast(@lotno as varchar(10)) + @Reel_ForHasuu_Number
				
				--Create New Data Barcode Qty For Label Hasuu
				select @Barcode_buttom_hasuu = right('000000'+ convert(varchar,@qty_hasuu_now),6) + ' ' + Cast(SUBSTRING(@lotno, 1, 4) + ' ' + SUBSTRING(@lotno, 5, 6) as char(11))

				IF @in_stock_now = 0
				BEGIN
					--Update qty_out Tran lot
					UPDATE APCSProDB.trans.lots
						SET qty_out = @qty_shipment
					WHERE lot_no = @lotno
				END
				ELSE IF @in_stock_now = 2  --New Condition 2022/06/23 Time : 11.30
				BEGIN
					--Update qty_out Tran lot
					UPDATE APCSProDB.trans.lots
						SET qty_out = @qty_shipment
						,qty_hasuu = @qty_hasuu_now
					WHERE lot_no = @lotno
				END

				--Update qty at for slip in label issue record
				UPDATE APCSProDB.trans.label_issue_records 
					SET qty = @qty_forslip_in_label
					,barcode_bottom = @qty_forslip_in_label
					,qrcode_detail = @Qrcode_Forslip
					,update_at = GETDATE()
					,update_by = CAST(@emp_no as int)
				WHERE lot_no = @lotno
				and type_of_label = 1

				------------------------------------ New Update 2022/06/23 Time : 11.30 -----------------------------------------

				--Update qty at for hasuu in label issue record
				UPDATE APCSProDB.trans.label_issue_records 
					SET qty = @qty_hasuu_now
					,barcode_bottom = @Barcode_buttom_hasuu
					,qrcode_detail = @Qrcode_ForHasuu
					,update_at = GETDATE()
					,update_by = CAST(@emp_no as int)
				WHERE lot_no = @lotno
				and type_of_label = 2

				--Update Qty Hasuu in Table : Surpluses and Surpluses Record
				UPDATE APCSProDB.trans.surpluses
					SET pcs = @qty_hasuu_now
					,updated_at = GETDATE()
					,updated_by = CAST(@emp_no as int)
				WHERE serial_no = @lotno

				-- INSERT RECORD CLASS TO TABLE tg_sp_set_surpluse_records
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] 
				 @lotno = @lotno
				,@sataus_record_class = 2  --2 = Update
				,@emp_no_int = @emp_no

				--Add Log Date Modify : 2022/04/14 Time : 8.34
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
					,'EXEC [dbo].[tg_sp_get_data_reel_all Set Data Reel RollBack] @lot_no = ''' + @lotno + ''' @Reel_no = ''' + CAST(@reel_no as varchar(20)) + ''' @Status = ''' + CAST(@status_int as varchar(2)) + ''' @Count_Reel_Rollback = ''' + CAST(@count_reel_rollback as varchar(2)) + ''' @empno = ''' + @emp_no + ''''
					,@lotno

				SELECT 'TRUE' AS Status ,'Rollback Reel Success !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA 
				RETURN
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status ,'Rollback Reel Error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH
		END
	END
	
END
