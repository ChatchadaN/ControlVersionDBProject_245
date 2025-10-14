-- =============================================
-- Author:		<Author,,Name : Vanatjaya P. 009131>
-- Create date: <Create Date,2022/08/02,Time : 15.51>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_cancel_mix_lot_on_cellcon]
	-- Add the parameters for the stored procedure here
	 @lot_standard varchar(10) = ''
	,@emp_no varchar(6) = ''
	,@mc_name varchar(50) = ''
	--,@appName varchar(30) = ''
	,@process_name varchar(20) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lot_id int 
	DECLARE @type_lot varchar(1) = ''
	DECLARE @EmpNo_int int = 0
	DECLARE @package_name char(10) = ''
	DECLARE @package_group_name char(10) = ''

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
		,'EXEC [dbo].[tg_sp_cancel_mix_lot_on_cellcon --> Access Store] @lot_standard = ''' + @lot_standard + ''',@emp_no = ''' + @emp_no + ''',@mc_name = ''' + @mc_name + ''',@process_name = ''' + @process_name + ''',@package_group_name = ''' + @package_group_name + ''',@package_name = ''' + @package_name + ''''
		,@lot_standard

	--Add check wip 70,100 2022/11/30 Time : 11.30
	IF ((select wip_state from APCSProDB.trans.lots where lot_no = @lot_standard) in (100,70))
	BEGIN
		SELECT 'FALSE' AS Status 
			, 'Lot Shipment !!' AS Error_Message_ENG
			, N'ไม่สามารถ Cancel tg Auto ได้ เพราะ Shipment แล้ว' AS Error_Message_THA 
			, N' กรุณาติดต่อ System' AS Handling
		RETURN
	END

	--Add check pc_instruction_code in (11,13) 2025/01/24 Time : 11.30 by Aomsin
	IF ((select pc_instruction_code from APCSProDB.trans.lots where lot_no = @lot_standard) in (11,13))
	BEGIN
		SELECT 'FALSE' AS Status 
			, 'Lot PC-Request !!' AS Error_Message_ENG
			, N'ไม่สามารถ Cancel tg Auto ได้ ให้ทำการ Cancel ผ่านหน้าเว็บ LSMS เท่านั้น' AS Error_Message_THA 
			, N' กรุณาติดต่อ System' AS Handling
		RETURN
	END

	select @lot_id = lots.id 
		, @type_lot = SUBSTRING(TRIM(lots.lot_no),5,1)
		, @package_name = TRIM(pk.name)
		, @package_group_name = TRIM(pk_g.name)
	from APCSProDB.trans.lots 
	inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
	inner join APCSProDB.method.package_groups as pk_g on pk.package_group_id = pk_g.id
	where lot_no = @lot_standard

	select @EmpNo_int = CONVERT(INT, @emp_no)

	--------------------- Start Get EmpnoId #Modify : 2024/12/26 ---------------------------------------
	DECLARE @GetEmpno varchar(6) = ''
	DECLARE @EmpnoId int = null
	SELECT @GetEmpno = FORMAT(CAST(@emp_no AS INT), '000000')
	SELECT @EmpnoId = id FROM [APCSProDB].[man].[users] WHERE [emp_num] = @GetEmpno
	------------------------------ End Get EmpnoId #Modify : 2024/12/26 --------------------------------

	DECLARE @count_row_lot_combine int = 0
	select @count_row_lot_combine = COUNT(lot_id) from APCSProDB.trans.lot_combine where lot_id = @lot_id

	--Add Condition Update InStock is 2 of Lot Hasuu Before 2022/10/19 Time : 10.37
	DECLARE @member_lotid int = null
	DECLARE @member_lotno varchar(10) = ''
	DECLARE @get_qty_hasuu int = null

	select @member_lotid = lot_cb.member_lot_id
		,@member_lotno = sur.serial_no 
	from APCSProDB.trans.lot_combine as lot_cb
	inner join APCSProDB.trans.surpluses as sur on lot_cb.member_lot_id = sur.lot_id
	where lot_cb.lot_id = @lot_id

	--add condition check package do not delete data mix or tg --> create 2022/04/21 time : 15.53
	IF @package_group_name != 'QFP'
	BEGIN
		IF @package_name != 'HSON-A8'
		BEGIN
			IF @member_lotid <> @lot_id
			BEGIN
				update [APCSProDB].[trans].[surpluses] set in_stock = 2,updated_at = GETDATE(),updated_by = 1 where lot_id = @member_lotid

				IF @member_lotno <> ''
				BEGIN
					-- INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records 
					EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @member_lotno
					,@sataus_record_class = 2

					--UPDATE DMY_OUT_FLAG to Is Server  2022/12/09 time : 09.42
					update APCSProDWH.dbo.H_STOCK_IF set DMY_OUT_Flag = '' where LotNo = @member_lotno

					--Add query update qty_hasuu on tran.lots when cancel lot --> date modify : 2024/02/19 time : 09.54 by Aomsin <--
					--Get data
					select @get_qty_hasuu = pcs from APCSProDB.trans.surpluses where serial_no = @member_lotno
					--Update data
					update APCSProDB.trans.lots set qty_hasuu = @get_qty_hasuu,updated_at = GETDATE() where lot_no = @member_lotno

				END
			END

			IF @type_lot = 'A' or @type_lot = 'F'  --add condition 2023/04/11 time : 09.31
			BEGIN
				--DELETE DATA ON APCSPro INTERFACE 2023/03/29 change position Time : 09.46
				DELETE APCSProDWH.dbo.MIX_HIST_IF where HASUU_LotNo = @lot_standard
				DELETE APCSProDWH.dbo.LSI_SHIP_IF where LotNo = @lot_standard
				DELETE APCSProDWH.dbo.H_STOCK_IF where LotNo = @lot_standard
				DELETE APCSProDWH.dbo.PACKWORK_IF where LotNo = @lot_standard
				DELETE APCSProDWH.dbo.WH_UKEBA_IF where LotNo = @lot_standard
				DELETE APCSProDWH.dbo.WORK_R_DB_IF where LotNo = @lot_standard
			END

			IF @count_row_lot_combine != 0  --เช็คว่ามีข้อมูลใน lot_combine หรือไม่ ถ้ามีถึงจะ delete data ได้
			BEGIN
				BEGIN TRY
					--IF @process_name = 'TP'  --close : 2022/09/24 time : 13.23
					--BEGIN
						IF @type_lot = 'A' or @type_lot = 'F'
						BEGIN
							--INSERT RECORD CLASS TO TABEL tg_sp_set_lot_combine_records update function : 2021/12/06 Time : 17.19
							EXEC [StoredProcedureDB].[dbo].[tg_sp_set_lot_combine_records] @lotno = @lot_standard
							,@sataus_record_class = 3

							IF @lot_id != 0
							BEGIN
								--UPDATE CREATE_BY and UPDATE_BY --> IN TABLE : lot_combine_record Date : 2021/12/07 Time : 10.17
								UPDATE APCSProDB.trans.lot_combine_records 
								set  
									operated_by = @EmpnoId --new
									,created_by = @EmpnoId --new
									,updated_by = @EmpnoId --new
								where lot_id = @lot_id and record_class = 3

								--add function clear qty = 0 in table tranlot date modify : 2022/02/17 time : 16.44
								UPDATE APCSProDB.trans.lots
								set  qty_out = 0
									,qty_hasuu = 0
									,qty_combined = 0
									,pc_instruction_code = null  --add column pc_instruction_code update value is null 2022/11/08 time : 08.19
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
									operated_by = @EmpnoId --new
									,created_by = @EmpnoId --new
									,updated_by = @EmpnoId --new
								where lot_id = @lot_id and record_class = 3
							END
			
							--Delete Record on table : Surpluses
							DELETE FROM APCSProDB.trans.surpluses WHERE serial_no = @lot_standard
							--Delate Record on table : label issue record
							DELETE FROM APCSProDB.trans.label_issue_records WHERE lot_no = @lot_standard

							BEGIN TRY
								DELETE APCSProDB.trans.lot_combine where lot_id = @lot_id
							END TRY
							BEGIN CATCH 
								SELECT 'FALSE' AS Status ,'DELETE DATA IN LOT COMBINE ERROR !!' AS Error_Message_ENG,N'ไม่สามารถลบ data ใน lot_combine ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
								RETURN
							END CATCH

							BEGIN TRY
								--Set Record Class = 47 is Cancel TG or Cancel Mixing on web Atom //Date Create : 2022/07/01 Time : 14.09
								EXEC [StoredProcedureDB].[trans].[sp_set_record_class_lot_process_records]
									@lot_no = @lot_standard
									,@opno = @emp_no
									,@record_class = 47
									,@mcno = @mc_name
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
									SELECT 
									  GETDATE()
									, '4'
									, ORIGINAL_LOGIN()
									, 'StoredProcedureDB'
									, APP_NAME()
									, 'EXEC [dbo].[tg_sp_cancel_mix_lot_on_cellcon Create Record Class Cancel TG or Cancel Mixing Error] @lot_standard = ''' + @lot_standard 
									, @lot_standard
							END CATCH
						END
						ELSE
						BEGIN
							SELECT 'FALSE' AS Status ,'No Type Lot A or F !!' AS Error_Message_ENG,N'ไม่สามารถ Cancel tg Auto ได้ เพราะ Type Lot ไม่ใช่ A หรือ F !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
							RETURN
						END
					--END
				END TRY
				BEGIN CATCH 
					SELECT 'FALSE' AS Status ,'EXECUTE STORE CNACEL TG ERROR !!' AS Error_Message_ENG,N'EXECUTE STORE CNACEL TG ไม่ผ่าน !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
					RETURN
				END CATCH
			END
			ELSE
			BEGIN
				INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
					([record_at]
					, [record_class]
					, [login_name]
					, [hostname]
					, [appname]
					, [command_text]
					, [lot_no]
					)
					SELECT 
					  GETDATE()
					, '4'
					, ORIGINAL_LOGIN()
					, 'StoredProcedureDB'
					, APP_NAME()
					, 'EXEC [dbo].[tg_sp_cancel_mix_lot_on_cellcon No Data Lot Combine or No data mix] @lot_standard = ''' + @lot_standard + ''',@emp_no = ''' + @emp_no + ''',@mc_name = ''' + @mc_name + ''',@process_name = ''' + @process_name + ''''
					, @lot_standard
			END
		END
		ELSE
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			([record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no]
			)
			SELECT 
			  GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, 'StoredProcedureDB'
			, APP_NAME()
			, 'EXEC [dbo].[tg_sp_cancel_mix_lot_on_cellcon No Cancel data mix] @lot_standard = ''' + @lot_standard + ''',@emp_no = ''' + @emp_no + ''',@mc_name = ''' + @mc_name + ''',@process_name = ''' + @process_name + ''',@package_group_name = ''' + @package_group_name + ''',@package_name = ''' + @package_name + ''''
			, @lot_standard
		END
	END
	ELSE
	BEGIN
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			([record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no]
			)
			SELECT 
			  GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, 'StoredProcedureDB'
			, APP_NAME()
			, 'EXEC [dbo].[tg_sp_cancel_mix_lot_on_cellcon No Cancel data mix] @lot_standard = ''' + @lot_standard + ''',@emp_no = ''' + @emp_no + ''',@mc_name = ''' + @mc_name + ''',@process_name = ''' + @process_name + ''',@package_group_name = ''' + @package_group_name + ''',@package_name = ''' + @package_name + ''''
			, @lot_standard
	END
END
