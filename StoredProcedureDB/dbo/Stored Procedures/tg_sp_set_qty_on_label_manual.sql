-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_qty_on_label_manual] 
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) = ''
	,@qty_all int = 0  --จำนวนงาน good + combine
	,@qty_hasuu int = 0
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @LOTNO_ID INT
	DECLARE @Totalhasuu INT
	DECLARE @reel_standard INT
	--add parameter 2021/09/30
	DECLARE @reel_max_before int = 0
	DECLARE @reel_max_after int = 0
	DECLARE @Count_reel int = 0

	DECLARE @Reel_Forslip char(3) = ''
	DECLARE @Reel_Hasuu char(3) = ''
	DECLARE @Qrcode_Forslip char(90) = ''
	DECLARE @Qrcode_Hasuu char(90) = ''
	DECLARE @device_name char(20) = ''
	DECLARE @Barcode_buttom_hasuu char(18) = ''


	SELECT @LOTNO_ID = id from APCSProDB.trans.lots where lot_no = @lot_no

	SELECT @reel_standard = [device_names].pcs_per_pack
	,@device_name = [device_names].[name]
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
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[tg_sp_set_qty_on_label_manual]  @lot_no = ''' + @lot_no + ''',@qty = ''' + CONVERT (varchar (10), @qty_all) + ''',@reel_standard = ''' + CONVERT (varchar (10), @reel_standard) + ''''


    -- Insert statements for procedure here
	IF @lot_no != ''
	BEGIN
		update APCSProDB.trans.lots 
		set 
		--qty_pass = @qty
		--,qty_hasuu = (@qty % @reel_standard)
		qty_out = ((@reel_standard) * ((@qty_all)/(@reel_standard))) 
		where lot_no = @lot_no

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

		

		BEGIN TRY

			-- CREATE 2021/10/01 : Get Data Qrcode
			select @Reel_Forslip = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
			where lot_no = @lot_no 
			and type_of_label = 1

			select @Reel_Hasuu = SUBSTRING(qrcode_detail,36,38)  from  APCSProDB.trans.label_issue_records
			where lot_no = @lot_no 
			and type_of_label = 2

			select @Qrcode_Forslip = Cast(@device_name as varchar(19)) + case when LEN(CAST(@qty_all as varchar(6))) = 5 
			  then '0' + CAST(@qty_all as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Forslip
			  when LEN(CAST(@qty_all as varchar(6))) = 4 
			  then '00' + CAST(@qty_all as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Forslip
			  when LEN(CAST(@qty_all as varchar(6))) = 3 
			  then '000' + CAST(@qty_all as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Forslip
			  when LEN(CAST(@qty_all as varchar(6))) = 2 
			  then '0000' + CAST(@qty_all as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Forslip
			  when LEN(CAST(@qty_all as varchar(6))) = 1 
			  then '00000' + CAST(@qty_all as varchar(6))  + CAST(@lot_no as varchar(10)) + @Reel_Forslip
			  else CAST(@qty_all as varchar(6)) + CAST(@lot_no as varchar(10)) + @Reel_Forslip end 

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

			--CREATE 2021/09/22 Update Qty Forslip
			UPDATE APCSProDB.trans.label_issue_records 
			set qty = @qty_all
			,barcode_bottom = @qty_all
			,qrcode_detail = @Qrcode_Forslip
			,update_at = GETDATE()
			where lot_no = @lot_no
			and type_of_label = 1

			--CREATE 2021/09/22 Update Qty ForHasuu
			UPDATE APCSProDB.trans.label_issue_records 
			--set qty = (@qty % @reel_standard)
			set qty = @qty_hasuu
			,barcode_bottom = @Barcode_buttom_hasuu
			,qrcode_detail = @Qrcode_Hasuu
			,update_at = GETDATE()
			where lot_no = @lot_no
			and type_of_label = 2

			--CREATE 2021/09/30
			IF @Count_reel != 0
			BEGIN
				--check reel_max_before > reel_max_after to be update type_of_label = 0 at reel max
				IF @reel_max_before > @reel_max_after
				BEGIN
					update APCSProDB.trans.label_issue_records 
					set type_of_label = 0
					,update_at = GETDATE()
					where lot_no = @lot_no and type_of_label = 3 and no_reel = @reel_max_before
					--select 'Update Type Label = 0 at Reel Max'
				END
			END

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
