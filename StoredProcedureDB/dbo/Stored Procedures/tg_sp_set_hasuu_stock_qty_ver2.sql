-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_hasuu_stock_qty_ver2]
-- Add the parameters for the stored procedure here
	 @lotno varchar(10)
	,@hasuu_stock_qty int 
	,@emp_no char(6) = ''
	,@comment_val int = null

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @LOTNO_ID INT
	DECLARE @Empno_int int = 0
	DECLARE @op_no_len_value varchar(10) = ''
	DECLARE @OPName char(20) = ''
	DECLARE @empno_str varchar(10) = ''

	--SEARCH LOT_ID DATA
	select @LOTNO_ID = lot_id from APCSProDB.trans.surpluses where serial_no = @lotno
	
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


	--update log 2022/08/19 time : 16.33
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
		,'EXEC [dbo].[tg_sp_set_hasuu_stock_qty_ver2] @lotno = ''' + @lotno + ''',@hasuu_stock_qty = ''' + CONVERT (varchar (10), @hasuu_stock_qty) + ''',@emp_no = ''' + @emp_no + ''''
		,@lotno

	select @Empno_int = CONVERT(INT, @emp_no)

	---------------------------- Start Get EmpnoId #Modify : 2024/12/26 ----------------------------
	DECLARE @EmpnoId int = null
	SELECT @EmpnoId = id FROM [APCSProDB].[man].[users] WHERE [emp_num] = @op_no_len_value
	---------------------------- End Get EmpnoId #Modify : 2024/12/26 ------------------------------

	--UPDATE QTY TABEL SURPLUSES
	UPDATE [APCSProDB].[trans].[surpluses]
		SET pcs = @hasuu_stock_qty
		,comment = @comment_val
		,in_stock =  case when @hasuu_stock_qty = 0 then 0 
						  else in_stock end --IIF(@hasuu_stock_qty = pcs,0,in_stock) end  --update 2023/10/25 time : 16.58 by Aomsin, last update 2024/06/12 time : 16.03 by Aomsin
		,updated_at = GETDATE()
		--,updated_by = @Empno_int
		,updated_by = @EmpnoId  --new
	WHERE serial_no = @lotno

	--update dmy_out_flag is 1 of Is server --create 2023/10/25 time : 17.04 by Aomsin
	IF @hasuu_stock_qty = 0
	BEGIN
		UPDATE APCSProDWH.dbo.H_STOCK_IF
		SET DMY_OUT_Flag = 1
		WHERE LotNo = @lotno
	END

	-- INSERT RECORD CLASS TO TABLE tg_sp_set_surpluse_records create data : 2021/12/14 time : 09.56
	BEGIN TRY
		EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno
		,@sataus_record_class = 2
		--,@emp_no_int = @Empno_int
		,@emp_no_int = @EmpnoId  --new
	END TRY
	BEGIN CATCH 
		SELECT 'FALSE' AS Status ,'INSERT DATA SURPLUSE_RECORDS ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
	RETURN
	END CATCH


	--Update Column qrcode_detail on record label Hasuu in to table label_issue_record  --> update version in qrcode detail
	UPDATE APCSProDB.trans.label_issue_records
		SET qrcode_detail = CAST(rohm_model_name as varchar(19)) + CAST(FORMAT(@hasuu_stock_qty,'000000') as varchar(6)) + lot_no 
		+ CAST(IIF(VERSION > 9,9,VERSION) AS CHAR(1)) + FORMAT(CAST(no_reel AS INT),'00')
		,barcode_bottom = CAST(FORMAT(@hasuu_stock_qty,'000000') as varchar(6)) + ' ' + CAST(SUBSTRING(lot_no, 1, 4) + ' ' + SUBSTRING(lot_no, 5, 6) as char(11))
		,qty = @hasuu_stock_qty
		,re_comment = case when @comment_val is null then '' else CAST(@comment_val as varchar(1)) end
		,update_at = GETDATE()
		--,update_by = @emp_no
		--,op_no = @emp_no
		--,operated_by = @emp_no
		,update_by = @EmpnoId
		,op_no = @EmpnoId
		,operated_by = @EmpnoId
		,op_name = @OPName
		,version = version + 1
	WHERE lot_no = @lotno 
	AND type_of_label = 2


	--insert data reprint on label hist
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
	where lot_no = @lotno 
	and type_of_label = 2

END
