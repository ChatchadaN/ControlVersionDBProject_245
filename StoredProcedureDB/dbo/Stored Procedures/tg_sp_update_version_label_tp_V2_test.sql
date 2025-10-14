-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_update_version_label_tp_V2_test]  
	-- Add the parameters for the stored procedure here
	 @lotno varchar(10) = ''
	,@Type_label int = 0
	,@reel_number char(3) = ''
	,@status int = 0  --1 : Update Version , 2 : Update QRCode
	,@emp_no int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--Add parameter Date Modify : 2022/02/28 time : 13.20
	DECLARE @op_no_len_value varchar(10) = ''
	DECLARE @OPName char(20) = ''
	DECLARE @empno_str varchar(10) = ''

	select @empno_str = CAST(@emp_no as varchar(10))
	select  @op_no_len_value =  RIGHT('000000'+ CONVERT(VARCHAR,TRIM(@empno_str)),6)

	SELECT @OPName =
	CASE
		WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MR.' THEN LEFT(SUBSTRING([users].name, 5,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		WHEN SUBSTRING(CAST(name as char(20)),1,4) ='MISS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MRS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
    ELSE SUBSTRING(CAST(name as char(20)), 1,LEN([users].name)) END 
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @op_no_len_value

    -- Insert statements for procedure here
	IF @status = 1
	BEGIN
		IF @reel_number = ' '
		BEGIN
				--UPDATE VERSION PRINT COUNT
				update APCSProDB.trans.label_issue_records 
				set version = version + 1  
				,update_at = GETDATE()
				,update_by = @emp_no
				,op_no = @emp_no
				,operated_by = @emp_no
				,op_name = @OPName --add value opname update in record date modify : 2022/02/28 time : 13.20
				where lot_no = @lotno
				and type_of_label = @Type_label

				BEGIN TRY
					--Set Record label history date modify : 2022/02/22 time : 09.20
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
					, 2 --fix 2
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
					, @emp_no
					FROM APCSProDB.trans.label_issue_records 
					where lot_no = @lotno
					and type_of_label = @Type_label
				END TRY
				BEGIN CATCH 
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
						,'EXEC [dbo].[tg_sp_update_version_label_tp_V2 Set Record His All Reel Error] @lotno = ''' + @lotno + ''',@empno = ''' + CAST(@emp_no as varchar(7)) + ''''
						,@lotno
				END CATCH
		END
	ELSE
		BEGIN
			   --UPDATE VERSION PRINT COUNT
				update APCSProDB.trans.label_issue_records 
				set version = version + 1  
				,update_at = GETDATE()
				,update_by = @emp_no
				,op_no = @emp_no
				,operated_by = @emp_no
				,op_name = @OPName --add value opname update in record date modify : 2022/02/28 time : 13.20
				where lot_no = @lotno
				and type_of_label = @Type_label
				and no_reel = @reel_number

				BEGIN TRY
					--Set Record label history date modify : 2022/02/22 time : 09.20
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
					, 2 --fix 2
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
					, @emp_no
					FROM APCSProDB.trans.label_issue_records 
					where lot_no = @lotno
					and type_of_label = @Type_label
					and no_reel = @reel_number
				END TRY
				BEGIN CATCH 
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
						,'EXEC [dbo].[tg_sp_update_version_label_tp_V2 Set Record His Error] @lotno = ''' + @lotno + ''',@empno = ''' + CAST(@emp_no as varchar(7)) + ''''
						,@lotno
				END CATCH

		END
	END
	ELSE IF @status = 2
	BEGIN
		IF @reel_number = ' '
		BEGIN
				--UPDATE QRCODE DETAIL REEL
				update APCSProDB.trans.label_issue_records
				--SET qrcode_detail = SUBSTRING(qrcode_detail,1,35) + Cast((VERSION) as char(1)) + RIGHT('00'+ CONVERT(VARCHAR,trim(no_reel)),2)
				SET qrcode_detail = case when LEN(no_reel) = '2' 
							then SUBSTRING(qrcode_detail,1,35) + Cast((VERSION) as char(1)) + no_reel
					   else SUBSTRING(qrcode_detail,1,35) + Cast((VERSION) as char(1)) + '0' + no_reel 
					   end
				where lot_no = @lotno 
				and type_of_label = @Type_label

				select lot_no,qrcode_detail,version from APCSProDB.trans.label_issue_records 
				where lot_no = @lotno
				and type_of_label = @Type_label
		END
	ELSE
		BEGIN
				--UPDATE QRCODE DETAIL REEL
				update APCSProDB.trans.label_issue_records
				--SET qrcode_detail = SUBSTRING(qrcode_detail,1,35) + Cast((VERSION) as char(1)) + RIGHT('00'+ CONVERT(VARCHAR,trim(no_reel)),2)
				SET qrcode_detail = case when LEN(no_reel) = '2' 
							then SUBSTRING(qrcode_detail,1,35) + Cast((VERSION) as char(1)) + no_reel
					   else SUBSTRING(qrcode_detail,1,35) + Cast((VERSION) as char(1)) + '0' + no_reel 
					   end
				where lot_no = @lotno 
				and type_of_label = @Type_label
				and no_reel = @reel_number
		END
	END
	
	--Create log store Date : 2021/11/22 Time : 15.49
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
			,'EXEC [dbo].[tg_sp_update_version_label_tp_V2] @lotno = ''' + @lotno + ''',@empno = ''' + CAST(@emp_no as varchar(7)) + ''''
			,@lotno

END
