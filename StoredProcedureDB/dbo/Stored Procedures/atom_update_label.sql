-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[atom_update_label] 
	-- Add the parameters for the stored procedure here
	 @lot_id INT  = 0
	 ,@update_by varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE	  @LOTNO_ID INT
			, @Totalhasuu INT
			, @reel_standard INT
			--add parameter 2021/09/30
			, @reel_max_before int = 0
			, @reel_max_after int = 0
			, @Count_reel int = 0
			 
			, @Reel_Forslip char(3) = ''
			, @Reel_Hasuu char(3) = ''
			, @Qrcode_Forslip char(90) = ''
			, @Qrcode_Hasuu char(90) = ''
			, @device_name char(20) = ''
			, @Barcode_buttom_hasuu char(18) = ''
			, @qty_hasuu int = 0
			, @qty INT = 0
			, @lot_no varchar(10) = ''
			--add parameter 2022/01/22 time : 10.15
			, @Qrcode_Hasuu_new char(90) = ''
			, @Barcode_buttom_hasuu_new char(18) = ''
			--add parameter date : 2021/12/02
			, @qty_out_new_value int = 0
			, @qty_out_get_tranlot int = 0
			, @Reel_Hasuu_Shipment char(3) = ''
			, @Qrcode_Hasuu_Shipment char(90) = ''
			, @pcInstruction int = null

	SELECT @lot_no = lot_no from APCSProDB.trans.lots where id = @lot_id
	SELECT @qty    = (SELECT (qty_hasuu + qty_out)   FROM APCSProDB.trans.lots where id = @lot_id)

	SELECT @reel_standard = [device_names].pcs_per_pack
		,@qty_hasuu = qty_hasuu
		,@device_name = [device_names].[name]
		,@qty_out_get_tranlot = qty_out --add get value date : 2021/12/02
		,@pcInstruction = lots.pc_instruction_code
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	WHERE [lots].[lot_no] = @lot_no

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
		,'EXEC [dbo].[atom_update_lable]   @lot_no = ''' + @lot_no + ''',@qty = ''' + CONVERT (varchar (10), @qty) + ''',@reel_standard = ''' + CONVERT (varchar (10), @reel_standard) + ''''
		,@lot_no

	--Get data reel Max Before
	select @reel_max_before = max(no_reel) - 2 from APCSProDB.trans.label_issue_records
	where lot_no = @lot_no

	--Get data reel Max After
	select @reel_max_after = (qty_out/dn.pcs_per_pack) 
	from APCSProDB.trans.lots 
	inner join APCSProDB.method.device_names as dn on lots.act_device_name_id = dn.id
	where lot_no = @lot_no

	select @Count_reel = Count(no_reel) from APCSProDB.trans.label_issue_records
	where lot_no = @lot_no and type_of_label = 3

	-- CREATE 2021/10/01 : Get Data Qrcode
	select @Reel_Forslip = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
	where lot_no = @lot_no 
	and type_of_label = 1

	select @Reel_Hasuu = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
	where lot_no = @lot_no 
	and type_of_label = 2

	select @Reel_Hasuu_Shipment = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
	where lot_no = @lot_no
	and type_of_label = 20

	select @Qrcode_Forslip = Cast(@device_name as varchar(19)) + case when LEN(CAST(@qty as varchar(6))) = 5 
	  then '0' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Forslip
	  when LEN(CAST(@qty as varchar(6))) = 4 
	  then '00' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Forslip
	  when LEN(CAST(@qty as varchar(6))) = 3 
	  then '000' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Forslip
	  when LEN(CAST(@qty as varchar(6))) = 2 
	  then '0000' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Forslip
	  when LEN(CAST(@qty as varchar(6))) = 1 
	  then '00000' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Forslip
	  else CAST(@qty as varchar(6)) + CAST(@lot_no as varchar(10)) + @Reel_Forslip end 

	select @Qrcode_Hasuu = Cast(@device_name as varchar(19)) + case when LEN(CAST(@qty_hasuu as varchar(6))) = 5 
	  then '0' + CAST(@qty_hasuu as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu
	  when LEN(CAST(@qty_hasuu as varchar(6))) = 4 
	  then '00' + CAST(@qty_hasuu as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu
	  when LEN(CAST(@qty_hasuu as varchar(6))) = 3 
	  then '000' + CAST(@qty_hasuu as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu
	  when LEN(CAST(@qty_hasuu as varchar(6))) = 2 
	  then '0000' + CAST(@qty_hasuu as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu
	  when LEN(CAST(@qty_hasuu as varchar(6))) = 1 
	  then '00000' + CAST(@qty_hasuu as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu
	  else CAST(@qty_hasuu as varchar(6)) + CAST(@lot_no as varchar(10)) + @Reel_Hasuu end 
	
	select @Barcode_buttom_hasuu = case when LEN(CAST(@qty_hasuu as varchar(6))) = 5 then '0' + CAST(@qty_hasuu as varchar(6)) + ' ' + Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(11))
	  when LEN(CAST(@qty_hasuu as varchar(6))) = 4 then '00' + CAST(@qty_hasuu as varchar(6)) + ' ' + Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(11))
	  when LEN(CAST(@qty_hasuu as varchar(6))) = 3 then '000' + CAST(@qty_hasuu as varchar(6)) + ' ' + Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(11))
	  when LEN(CAST(@qty_hasuu as varchar(6))) = 2 then '0000' + CAST(@qty_hasuu as varchar(6)) + ' ' + Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(11))
	  when LEN(CAST(@qty_hasuu as varchar(6))) = 1 then '00000' + CAST(@qty_hasuu as varchar(6)) + ' ' + Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(11))
	  else CAST(@qty_hasuu as varchar(6)) + ' ' + Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(10)) end
	  + '''';

	IF @qty >= @reel_standard  --Add Condition 2021/10/20 เช็คงานที่จำนวนงานน้อยกว่า standard reel จะไม่ update qty on label เพราะจะทำให้ค่าใน label เป็น 0 เพราะฝั่ง cellcon ส่ง hasuu มาเป็น 0
	BEGIN
		IF @lot_no != ''
		BEGIN
			BEGIN TRY
			--CREATE 2021/09/22 Update Qty Forslip
			UPDATE APCSProDB.trans.label_issue_records 
			set qty = @qty
			,barcode_bottom = @qty
			,qrcode_detail = @Qrcode_Forslip
			,update_at = GETDATE()
			, update_by =  @update_by
			where lot_no = @lot_no
			and type_of_label = 1

			--CREATE 2021/09/22 Update Qty ForHasuu
			UPDATE APCSProDB.trans.label_issue_records 
			--set qty = (@qty % @reel_standard)
			set qty = @qty_hasuu
			,barcode_bottom = @Barcode_buttom_hasuu
			,qrcode_detail = @Qrcode_Hasuu
			,update_at = GETDATE()
			, update_by =  @update_by
			where lot_no = @lot_no
			and type_of_label = 2

			--Crate 2022/02/01 Time : 13.27 Check inspec = 1 not disable reel auto
			--IF @is_inspec_value != 1
			--BEGIN
				--CREATE 2021/09/30
				IF @Count_reel != 0
				BEGIN
					--check reel_max_before > reel_max_after to be update type_of_label = 0 at reel max
					IF @reel_max_before > @reel_max_after
					BEGIN
						update APCSProDB.trans.label_issue_records 
						set type_of_label = 0
						,update_at = GETDATE()
						, update_by =  @update_by
						where lot_no = @lot_no and type_of_label = 3 and no_reel = @reel_max_before
						--select 'Update Type Label = 0 at Reel Max'
					END
				END
			--END
			

			--add condition จำนวนงานที่ส่งมาใหม่มากกว่าค่าเดิมให้ update reel ที่ disibal ไป กลับมาเป็น use เหมือนเดิม date : 2021/12/02 Time : 13.35
			--Check qty_out_new > qty_out_get_tranlot (เช็คจำนวนงานที่ส่งมามากกว่าจำนวนงานที่อยู่ใน table tranlot) 
			select @qty_out_new_value = ((@reel_standard) * ((@qty)/(@reel_standard)))

			--Crate 2022/02/01 Time : 13.28 Check inspec = 1 not disable reel auto
			--IF @is_inspec_value != 1
			--BEGIN
				IF @qty_out_new_value > @qty_out_get_tranlot --@qty = qty_new_value
				BEGIN
					update APCSProDB.trans.label_issue_records 
					set type_of_label = 3
					,update_at = GETDATE()
					,update_by =  @update_by
					where lot_no = @lot_no and type_of_label = 0 and no_reel = @reel_max_before
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

			select @Qrcode_Hasuu_new = Cast(@device_name as varchar(19)) + case when LEN(CAST(@qty as varchar(6))) = 5 
			  then '0' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu
			  when LEN(CAST(@qty as varchar(6))) = 4 
			  then '00' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu
			  when LEN(CAST(@qty as varchar(6))) = 3 
			  then '000' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu
			  when LEN(CAST(@qty as varchar(6))) = 2 
			  then '0000' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu
			  when LEN(CAST(@qty as varchar(6))) = 1 
			  then '00000' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu
			  else CAST(@qty as varchar(6)) + CAST(@lot_no as varchar(10)) + @Reel_Hasuu end 
			
			select @qty = @qty_out_get_tranlot  --modify update 2024/02/14 time : 14.22 by aomsin
			select @Barcode_buttom_hasuu_new = case when LEN(CAST(@qty as varchar(6))) = 5 then '0' + CAST(@qty as varchar(6)) + ' ' + Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(11))
			  when LEN(CAST(@qty as varchar(6))) = 4 then '00' + CAST(@qty as varchar(6)) + ' ' + Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(11))
			  when LEN(CAST(@qty as varchar(6))) = 3 then '000' + CAST(@qty as varchar(6)) + ' ' + Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(11))
			  when LEN(CAST(@qty as varchar(6))) = 2 then '0000' + CAST(@qty as varchar(6)) + ' ' + Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(11))
			  when LEN(CAST(@qty as varchar(6))) = 1 then '00000' + CAST(@qty as varchar(6)) + ' ' + Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(11))
			  else CAST(@qty as varchar(6)) + ' ' + Cast(SUBSTRING(@lot_no, 1, 4) + ' ' + SUBSTRING(@lot_no, 5, 6) as char(10)) end
			  + '''';
			
			select @qty = @qty_out_get_tranlot  --modify update 2024/02/14 time : 14.22 by aomsin
			select @Qrcode_Hasuu_Shipment = Cast(@device_name as varchar(19)) + case when LEN(CAST(@qty as varchar(6))) = 5 
			  then '0' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu_Shipment
			  when LEN(CAST(@qty as varchar(6))) = 4 
			  then '00' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu_Shipment
			  when LEN(CAST(@qty as varchar(6))) = 3 
			  then '000' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu_Shipment
			  when LEN(CAST(@qty as varchar(6))) = 2 
			  then '0000' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu_Shipment
			  when LEN(CAST(@qty as varchar(6))) = 1 
			  then '00000' + CAST(@qty as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Hasuu_Shipment
			  else CAST(@qty as varchar(6)) + CAST(@lot_no as varchar(10)) + @Reel_Hasuu_Shipment end 

			BEGIN TRY
				--close query update 2024/02/14 time : 14.22 by aomsin
				--CREATE 2021/09/22 Update Qty Forslip
				--UPDATE APCSProDB.trans.label_issue_records 
				--	set qty = @qty
				--	,barcode_bottom = @qty
				--	,qrcode_detail = @Qrcode_Forslip
				--	,update_at = GETDATE()
				--	, update_by =  @update_by
				--where lot_no = @lot_no
				--and type_of_label = 1

				--CREATE 2021/09/22 Update Qty ForHasuu
				--UPDATE APCSProDB.trans.label_issue_records 
				--	set qty = @qty
				--	,barcode_bottom = @Barcode_buttom_hasuu_new
				--	,qrcode_detail = @Qrcode_Hasuu_new
				--	,update_at = GETDATE()
				--	, update_by =  @update_by
				--where lot_no = @lot_no
				--and type_of_label = 2
				--============================================================--
				--modify update 2024/02/14 time : 14.22 by aomsin
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
