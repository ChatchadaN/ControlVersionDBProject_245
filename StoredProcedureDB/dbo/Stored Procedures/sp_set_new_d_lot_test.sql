
CREATE PROCEDURE [dbo].[sp_set_new_d_lot_test]
	-- Add the parameters for the stored procedure here
	@function INT = 0, --# 0:Lot, 1:Package and Device and Assy
	@hasuu_lotno VARCHAR(10) = '', 
	@packagename VARCHAR(20) = '', 
	@devicename VARCHAR(20) = '', 
	@assyname VARCHAR(20) = '',  
	@total_pcs INT, --qty hasuu all 
	@empno CHAR(6) = '', 
	@newlotno VARCHAR(10) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET NOCOUNT ON;

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no] )
	SELECT GETDATE() AS [record_at]
		, 4 AS [record_class]
		, ORIGINAL_LOGIN() AS [login_name]
		, HOST_NAME() AS [hostname]
		, APP_NAME() AS [appname]
		, 'EXEC [dbo].[sp_set_new_d_lot_test] @function = ' + CAST(@function AS VARCHAR(20))
			+ ', @hasuu_lotno = ''' + @hasuu_lotno + ''''
			+ ', @packagename = ''' + @packagename + ''''
			+ ', @devicename = ''' + @devicename + ''''
			+ ', @assyname = ''' + @assyname + ''''
			+ ', @total_pcs = ' + CAST(@total_pcs AS VARCHAR(20))
			+ ', @empno = ''' + CAST(@empno AS VARCHAR(10)) + ''''
			+ ', @newlotno = ''' + @newlotno + ''''
		AS [command_text]
		, @newlotno AS [lot_no];

	IF (@function = 0) 
	BEGIN
		IF (@hasuu_lotno = '') 
		BEGIN
			----# result
			SELECT 'FALSE' AS Is_Pass 
				, 'lot_no is empty !!' AS Error_Message_ENG
				, N'lot_no เป็นค่าว่าง !!' AS Error_Message_THA
				, N'' AS Handling
			RETURN
		END
	END
	ELSE IF (@function = 1) 
	BEGIN
		----# package
		IF (@packagename = '') 
		BEGIN
			----# result
			SELECT 'FALSE' AS Is_Pass 
				, 'package is empty !!' AS Error_Message_ENG
				, N'package เป็นค่าว่าง !!' AS Error_Message_THA
				, N'' AS Handling
			RETURN
		END
		----# device
		IF (@devicename = '') 
		BEGIN
			----# result
			SELECT 'FALSE' AS Is_Pass 
				, 'device is empty !!' AS Error_Message_ENG
				, N'device เป็นค่าว่าง !!' AS Error_Message_THA
				, N'' AS Handling
			RETURN
		END
		----# assy
		IF (@assyname = '') 
		BEGIN
			----# result
			SELECT 'FALSE' AS Is_Pass 
				, 'assy is empty !!' AS Error_Message_ENG
				, N'assy เป็นค่าว่าง !!' AS Error_Message_THA
				, N'' AS Handling
			RETURN
		END
	END
	ELSE
	BEGIN
		----# result
		SELECT 'FALSE' AS Is_Pass 
			, 'function not found !!' AS Error_Message_ENG
			, N'ไม่พบ function !!' AS Error_Message_THA
			, N'' AS Handling
		RETURN
	END

	DECLARE @ASSY_Model_Name CHAR(20) = ''
		, @Standerd_QTY INT
		, @Hasuu_Qty_Before INT
		, @EmpNo_int INT 
		, @EmpNo_Char CHAR(5) = ' ' 
		, @Lot_Master_id INT = 0
		, @device CHAR(20)

	SELECT @EmpNo_int = CONVERT(INT, @empno); 
	SELECT @EmpNo_Char = CONVERT(CHAR(5),@EmpNo_int); 

	--------------------- Start Get EmpnoId #Modify : 2024/12/26 ---------------------------------------
	DECLARE @GetEmpno varchar(6) = ''
	DECLARE @EmpnoId int = null
	SELECT @GetEmpno = FORMAT(CAST(@empno AS INT), '000000')
	SELECT @EmpnoId = id FROM [APCSProDB].[man].[users] WHERE [emp_num] = @GetEmpno
	------------------------------ End Get EmpnoId #Modify : 2024/12/26 --------------------------------

	IF (@function = 0) 
	BEGIN
		SELECT @Standerd_QTY = [dn].[pcs_per_pack]
			, @ASSY_Model_Name = [dn].[assy_name] 
			, @device = [dn].[name]
		FROM [APCSProDB].[trans].[lots] AS [lot]
		INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [lot].[act_package_id] = [pk].[id]
		INNER JOIN [APCSProDB].[method].[device_names] AS [dn] ON [lot].[act_device_name_id] = [dn].[id]
		WHERE [lot].[lot_no] = @hasuu_lotno

		SELECT @Hasuu_Qty_Before = (@total_pcs) % (@Standerd_QTY);
	END
	ELSE IF (@function = 1) 
	BEGIN
		SELECT @Standerd_QTY = [dn].[pcs_per_pack]
			, @ASSY_Model_Name = [dn].[assy_name] 
			, @device = [dn].[name]
		FROM [APCSProDB].[method].[device_names] AS [dn]
		INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [dn].[package_id] = [pk].[id]
		WHERE [pk].[name] = @packagename
			AND [dn].[name] = @devicename
			AND [dn].[assy_name] = @assyname

		SELECT @Hasuu_Qty_Before = (@total_pcs) % (@Standerd_QTY);
	END

	----# check create new d-lot
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_d_lot_in_tranlot] @lotno = @newlotno
		, @device_name = @device
		, @assy_name = @ASSY_Model_Name
		, @qty = @total_pcs
		, @production_category_val = 99
		, @carrier_no_val = NULL

	----# set @Lot_Master_id newlot
	SELECT @Lot_Master_id = [id] 
	FROM [APCSProDB].[trans].[lots] 
	WHERE [lot_no] = @newlotno;

	--# get id of hasuu lotno
	DECLARE @Lot_Hasuu_id int = null
	DECLARE @lot_id int = null

	SELECT @Lot_Hasuu_id = [id] 
	FROM [APCSProDB].[trans].[lots] 
	WHERE [lot_no] = @hasuu_lotno

	----# check create newlot
	IF @Lot_Master_id > 0
	BEGIN
		BEGIN TRY
			----# create surpluses
			EXEC [StoredProcedureDB].[atom].[sp_set_label_issued_tg] @lot_no = @newlotno
				, @qty_hasuu_brfore = @Hasuu_Qty_Before
				, @Empno_int_value = @EmpNo_int
				, @stock_class = '01'  

			----# create surpluse_records
			EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @newlotno
				, @sataus_record_class = 1
				--, @emp_no_int = @EmpNo_int 
				, @emp_no_int = @EmpnoId  --new 

			----# update surpluses
			UPDATE APCSProDB.trans.surpluses
			SET [in_stock] = 0
				, [mark_no] = 'MX'
			WHERE serial_no = @newlotno

			----# update surpluse_records
			EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @newlotno
				, @sataus_record_class = 2
				--, @emp_no_int = @EmpNo_int 
				, @emp_no_int = @EmpnoId  --new

			SET @lot_id = IIF(@function = 1,@Lot_Master_id, @Lot_Hasuu_id);

			----# create lot_combine query edit : 2023/12/22 time : 14.30 by Aomsin
			INSERT INTO APCSProDB.trans.lot_combine 
			(
				 lot_id
				,idx
				,member_lot_id
				,created_at
				,created_by
				,updated_at
				,updated_by
			)
			VALUES
			( 
				 @Lot_Master_id
				,0  --idx
				,@lot_id 
				,GETDATE()
				--,@EmpNo_int
				,@EmpnoId  --new
				,GETDATE()
				--,@EmpNo_int
				,@EmpnoId  --new
			)

			--add data ro tabel lot_combine_records
			INSERT INTO APCSProDB.trans.lot_combine_records
			(
				 recorded_at
				,operated_by
				,record_class
				,lot_id
				,idx
				,member_lot_id
				,created_at 
				,created_by
				,updated_at
				,updated_by
			)
			VALUES
			(
				 GETDATE()
				 ,@EmpNo_int
				 ,1
				 ,@Lot_Master_id
				,0 --idx
				,@lot_id 
				,GETDATE()
				--,@EmpNo_int
				,@EmpnoId  --new
				,GETDATE()
				--,@EmpNo_int
				,@EmpnoId  --new
			)

			----# create label for create d-slip
			EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @newlotno
				, @process_name = 'TP'
		END TRY
		BEGIN CATCH
			----# result
			SELECT 'FALSE' AS Is_Pass 
				, 'Insert Error !!' AS Error_Message_ENG
				, N'บันทึกข้อมูล lot ผิดพลาด !!' AS Error_Message_THA
				, N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH
	END
	ELSE
	BEGIN
		----# result
		SELECT 'FALSE' AS Is_Pass 
			, 'Not Create lot !!' AS Error_Message_ENG
			, N'ไม่สามารถสร้าง lot ได้ !!' AS Error_Message_THA
			, N' กรุณาติดต่อ System' AS Handling
		RETURN
	END

	----# result
	SELECT 'TRUE' AS Is_Pass 
		, '' AS Error_Message_ENG
		, N'' AS Error_Message_THA
		, N'' AS Handling
	RETURN
END