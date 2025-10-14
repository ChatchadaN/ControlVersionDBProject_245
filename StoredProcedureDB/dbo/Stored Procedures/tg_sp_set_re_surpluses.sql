-- =============================================
-- Author:		<Author,,Name : Aomsin>
-- Create date: <Create Date,2021/10/08,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_re_surpluses]
	-- Add the parameters for the stored procedure here
	 @lotno_original varchar(10) = ''
	,@qty_original int = 0
	,@lotno_new_value varchar(10) = ''
	,@emp_no char(6)
	,@prodution_category_state int = 0  --add parameter 2022/04/22 time : 13.48
	,@carrier_input varchar(11) = '' --add parameter 2022/05/05 time : 09.48
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @r int= 0;
	DECLARE @Lot_Master_id int = 0
	DECLARE @Lot_Hasuu_id int = 0
	DECLARE @LotNo varchar(10) =''
	DECLARE @StockClass char(2) ='' 
	DECLARE @Pdcd char(5) =''
	DECLARE @LotNo_H_Stock char(10) =''
	DECLARE @HASU_Stock_QTY int
	DECLARE @Packing_Standerd_QTY int
	DECLARE @Packing_Standerd_QTY_H_Stock int
	DECLARE @Qty_Full_Reel_All int
	DECLARE @Package char(20) = ''
	DECLARE @ROHM_Model_Name char(20) ='' 
	DECLARE @ASSY_Model_Name char(20) = ''
	DECLARE @R_Fukuoka_Model_Name char(20) ='' 
	DECLARE @TIRank char(5) ='' 
	DECLARE @Rank_H_Stock char(5) ='' 
	DECLARE @TPRank char(3) ='' 
	DECLARE @SUBRank char(3)='' 
	DECLARE @Mask char(2) ='' 
	DECLARE @KNo char(3) ='' 
	DECLARE @Tomson_Mark_1 char(4) ='' 
	DECLARE @Tomson_Mark_2 char(4) ='' 
	DECLARE @Tomson_Mark_3 char(4)='' 
	DECLARE @ORNo char(12)='' 
	DECLARE @MNo char(10)='' 
	DECLARE @WFLotNo char(20)='' 
	DECLARE @LotNo_Class char(1)='' 
	DECLARE @Label_Class char(1)='' 
	DECLARE @Product_Control_Clas char(3)='' 
	DECLARE @HasuuLotNo char(10)='' 
	DECLARE @HasuuLotNo2 char(10)='' 
	DECLARE @ProductClass char(1)='' 
	DECLARE @ProductionClass char(1)='' 
	DECLARE @RankNo char(6)=''
	DECLARE @User_code char(6)=''
	DECLARE @HINSYU_Class char(1)='' 
	DECLARE @Out_Out_Flag char(1)='' 
	DECLARE @Standerd_QTY int
	DECLARE @datestart as varchar(50) = cast( GETDATE() as date) 
	DECLARE @Hasuu_Qty_Before int
	DECLARE @EmpNo_int INT
	DECLARE @op_no_len_value char(5) = '';
	DECLARE @lotno_type char(1) = ''
	DECLARE @user_code_value char(4)
	DECLARE @product_control_class_value char(3)
	DECLARE @product_class_value char(1)
	DECLARE @production_class_value char(1)
	DECLARE @rank_no_value char(6)
	DECLARE @hinsyu_class_value char(1)
	DECLARE @label_class_value char(1)
	DECLARE @Original_lot_front varchar(4) = ''
	DECLARE @Original_lot_back varchar(5) = ''
	DECLARE @Newlot varchar(10) = ''
	--Add Parameter 2021/10/27
	DECLARE @Chk_Wip_State tinyint = 0
	--Add Parameter 2022/03/14
	DECLARE @Chk_qty_out int = 0
	--Add Parameter 2022/06/28
	DECLARE @Chk_in_stock int = 0

	--add parameter for get data of interface table date time : 2023/04/12 time : 
	DECLARE @Count_lsiship_IF int = null
	DECLARE @Count_hstock_IF int = null
	DECLARE @Count_lot_combine int = null
	DECLARE @Count_surpluses int = null
	DECLARE @Count_label_record int = null

	select @Newlot = @lotno_new_value

	select 
	 @Lot_Hasuu_id = lot.id
	,@StockClass = '01' --fix
	,@LotNo_H_Stock = sur.serial_no
	,@Pdcd = sur.pdcd
	,@HASU_Stock_QTY = sur.pcs 
	,@Standerd_QTY = dn.pcs_per_pack
	,@Packing_Standerd_QTY = dn.pcs_per_pack
	,@Packing_Standerd_QTY_H_Stock = dn.pcs_per_pack
	,@Package = pk.short_name
	,@ROHM_Model_Name = dn.name
	,@ASSY_Model_Name = dn.assy_name 
	,@R_Fukuoka_Model_Name = isnull(Fukuoka.R_Fukuoka_Model_Name,Fukuoka_Hstock.R_Fukuoka_Model_Name)
	,@TIRank = case when dn.rank is null then '' else dn.rank end
	,@Rank_H_Stock = case when dn.rank is null then '' else dn.rank end
	,@TPRank = case when dn.tp_rank is null then '' else dn.tp_rank end
	,@SUBRank = '' --fix blank
	,@Mask = '' --fix blank
	,@KNo = '' --fix blank
	,@Tomson_Mark_1 = '' --fix blank
	,@Tomson_Mark_2 = '' --fix blank
	,@Tomson_Mark_3 = sur.qc_instruction
	,@ORNo = case 
		when SUBSTRING(sur.serial_no,5,1) = 'D' or SUBSTRING(sur.serial_no,5,1) = 'F' then 'NO' 
		else 
			case
				when (allocat.ORNo = '' or allocat.ORNo is null) then '' 
				else allocat.ORNo 
			end
		end --AS ORNo
	,@MNo = sur.mark_no
	,@WFLotNo = '' --fix blank
	,@LotNo_Class = '' --fix blank
	,@Out_Out_Flag = 'B' --fix
	,@user_code_value = sur.user_code
	,@product_control_class_value = sur.product_control_class
	,@product_class_value = sur.product_class
	,@production_class_value = sur.production_class
	,@rank_no_value = sur.rank_no
	,@hinsyu_class_value = sur.hinsyu_class
	,@label_class_value = sur.label_class
	,@Chk_qty_out = lot.qty_out
	,@Chk_in_stock = sur.in_stock
	from APCSProDB.trans.surpluses as sur
	inner join APCSProDB.trans.lots as lot on sur.serial_no = lot.lot_no
	inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	left join APCSProDB.method.allocat_temp as allocat on lot.lot_no = allocat.LotNo  --update query 2023/02/02 time : 13.25
	 -- ** find R_Fukuoka_Model_Name in allocat_temp
	outer apply (
		 select top 1 R_Fukuoka_Model_Name
		 from APCSProDB.method.allocat_temp
		 where trim(allocat_temp.ROHM_Model_Name) = trim(dn.name)
		  and trim(allocat_temp.ASSY_Model_Name) = trim(dn.assy_name)
	) as Fukuoka 
	-- ** find R_Fukuoka_Model_Name in H_STOCK_IF  //add condition 2023/04/18 time : 10.38
	outer apply (
		 select top 1 R_Fukuoka_Model_Name
		 from APCSProDWH.dbo.H_STOCK_IF
		 where LotNo = sur.serial_no
	) as Fukuoka_Hstock
	where serial_no = @lotno_original

	select @EmpNo_int = CONVERT(INT, @emp_no)
	select  @op_no_len_value =  case when LEN(CAST(@EmpNo_int as char(5))) = 4 then '0' + CAST(@EmpNo_int as char(5))
			when LEN(CAST(@EmpNo_int as char(5))) = 3 then '00' + CAST(@EmpNo_int as char(5))
			when LEN(CAST(@EmpNo_int as char(5))) = 2 then '000' + CAST(@EmpNo_int as char(5))
			when LEN(CAST(@EmpNo_int as char(5))) = 1 then '0000' + CAST(@EmpNo_int as char(5))
			else CAST(@EmpNo_int as char(5)) end 

	-- add parameter 2022/05/24 time : 10.25
	DECLARE @user_id int = 1 --ถ้าหาค่าไม่เจอจะ fix เป็น admin = 1
	select @user_id = id from APCSProDB.man.users where emp_num = @emp_no

	--------------------- Start Get EmpnoId #Modify : 2024/12/26 ---------------------------------------
	DECLARE @GetEmpno varchar(6) = ''
	DECLARE @EmpnoId int = null
	SELECT @GetEmpno = FORMAT(CAST(@emp_no AS INT), '000000')
	SELECT @EmpnoId = id FROM [APCSProDB].[man].[users] WHERE [emp_num] = @GetEmpno
	------------------------------ End Get EmpnoId #Modify : 2024/12/26 --------------------------------

	--Create D lot in Tranlot
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_d_lot_in_tranlot] 
	 @lotno = @Newlot
	,@device_name = @ROHM_Model_Name
	,@assy_name = @ASSY_Model_Name
	,@qty = @qty_original
	,@production_category_val = @prodution_category_state  --add parameter : 2022/04/25 time : 10.32
	,@carrier_no_val = @carrier_input --add parameter : 2022/05/05 time : 09.59

	select @Lot_Master_id = id from APCSProDB.trans.lots where lot_no = @Newlot

	--UPDATE WIP SATE IS HASUU
	--Check New Condition Poduction_Category for Update Wip State Create : 2022/04/26 time : 09.15
	IF @prodution_category_state = 21  --prodution_category 21 = Hasuu Stock In
	BEGIN
		--IF @Chk_Wip_State != 70
		--BEGIN
			--UPDATE WIP SATE OF HASUU
			update APCSProDB.trans.lots 
			set qty_hasuu = @qty_original
			,wip_state = 70
			where lot_no = @Newlot
		--END
	END
	ELSE IF @prodution_category_state = 22 --prodution_category 22 = Hasuu Have Flow Rework
	BEGIN
		--UPDATE WIP SATE OF HASUU
		update APCSProDB.trans.lots 
		set qty_hasuu = @qty_original
		,wip_state = 20
		where lot_no = @Newlot

		--update in_stock = 0 for lot hasuu original -->add condition 2022/06/28 time : 10.45
		--support case work machine hang or ng > reel ...
		IF @Chk_in_stock = 2  
		BEGIN
			update APCSProDB.trans.surpluses
			set in_stock = 0
			,updated_at = GETDATE()
			--,updated_by = @EmpNo_int
			,updated_by = @EmpnoId  --new
			where serial_no = @lotno_original

			--INSERT RECORD CLASS TO TABEL surpluse_records
			EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_original
			,@sataus_record_class = 2
			--,@emp_no_int = @EmpNo_int 
			,@emp_no_int = @EmpnoId --new
		END
	END
	ELSE
	BEGIN
		--IF @Chk_Wip_State != 70
		--BEGIN
			--UPDATE WIP SATE OF HASUU
			update APCSProDB.trans.lots 
			set qty_hasuu = @qty_original
				,wip_state = 70
			where lot_no = @Newlot
		--END
	END

	--add condition check master lot id is zero (do not re-surpluses) date modify : 2023/03/30 time : 11.09
	IF @Lot_Master_id > 0
	BEGIN
		-- INSERT DATA TO TABEL SURPLUESE
		INSERT INTO [APCSProDB].[trans].[surpluses]
		( [id]
		, [lot_id]
		, [pcs]
		, [serial_no]
		, [in_stock]
		, [location_id]
		, [acc_location_id]
		, [created_at]
		, [created_by]
		, [updated_at]
		, [updated_by]
		, [pdcd]
		, [qc_instruction]
		, [mark_no]
		, [original_lot_id]
		, [user_code]
		, [product_control_class]
		, [product_class]
		, [production_class]
		, [rank_no]
		, [hinsyu_class]
		, [label_class]
		, [stock_class] --date modify : 2022/03/10 time : 14.33
		)
		SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
		, @Lot_Master_id AS lot_id
		, @qty_original AS pcs
		, @Newlot AS serial_no
		, '2' AS in_stock
		, NULL AS location_id
		, NULL AS acc_location_id
		, GETDATE() AS created_at
		--, @EmpNo_int AS created_by
		, @EmpnoId AS created_by  --new
		, GETDATE() AS updated_at
		--, @EmpNo_int AS updated_by
		, @EmpnoId AS updated_by  --new
		, @Pdcd
		, @Tomson_Mark_3
		, @MNo --MarkNo of Original Lot hasuu
		, @Lot_Hasuu_id --Original lot hasuu
		, @user_code_value
		, @product_control_class_value
		, @product_class_value
		, @production_class_value
		, @rank_no_value
		, @hinsyu_class_value
		, @label_class_value
		, '01' --date modify : 2022/03/10 time : 14.33
		FROM [APCSProDB].[trans].[surpluses]
		INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'surpluses.id'

		-- Update Row In Table tran.number
		set @r = @@ROWCOUNT
		update [APCSProDB].[trans].[numbers]
		set id = id + @r 
		from [APCSProDB].[trans].[numbers]
		where name = 'surpluses.id'

		--INSERT RECORD CLASS TO TABEL surpluse_records
		EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @Newlot
		,@sataus_record_class = 1
		--,@emp_no_int = @EmpNo_int 
		,@emp_no_int = @EmpnoId 

		---- INSERT DATA IN TABLE LOT COMBINE
		--EXEC [StoredProcedureDB].[atom].[sp_set_mixing_tg] 
		-- @lotno0 = @lotno_original
		--,@master_lot_no = @Newlot
		--,@emp_no_value = @emp_no

		-- Call new version store set data in lot_combine table  --new 2024/12/26
		EXEC [StoredProcedureDB].[atom].[sp_set_mixing_tg_002] @new_lotno = @Newlot
			, @lot_no = @lotno_original  --(array version)
			, @empid = @EmpnoId
			, @app_type = 1


		-- INSERT DATA IN TABLE LABEL_HISTORY
		EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @Newlot
		,@process_name = 'TP'

		--add check wip sate Date : 2021/10/27 Time : 13.37
		select @Chk_Wip_State = wip_state from APCSProDB.trans.lots where lot_no = @Newlot

		--Check qty_out of lot original = 0 --> Date Modify : 2022/03/15 time : 08.10
		IF @Chk_qty_out = 0
		BEGIN
			IF @lotno_original != ''
			BEGIN
				--UPDATE WIP SATE LOT Original is 100
				update APCSProDB.trans.lots 
				set wip_state = 100
				where lot_no = @lotno_original 
			END
		END

		--Update column tranfer_pcs in table : surpluses --> create : 2023/04/05 time : 14.02
		UPDATE APCSProDB.trans.surpluses
		SET  transfer_pcs = transfer_pcs + @qty_original  --update : 2023/04/06 time : 15.36
			,updated_at = GETDATE()
			--,updated_by = @EmpNo_int
			,updated_by = @EmpnoId  --new
		WHERE serial_no = @lotno_original

		--Insert Record in table : surpluses_record of lot original --> create : 2023/04/05 time : 14.02
		EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_original
		,@sataus_record_class = 2
		--,@emp_no_int = @EmpNo_int 
		,@emp_no_int = @EmpnoId --new 

		--add record_class lot original
		IF @prodution_category_state = 21  --prodution_category 21 = Hasuu Stock In
		BEGIN
			--Set record_class = 35 is Resurpluses Show on web Atom //Date Create : 2022/05/09 Time : 10.57
			BEGIN TRY
				EXEC [StoredProcedureDB].[trans].[sp_set_record_class_lot_process_records]
				 @lot_no = @lotno_original
				,@opno = @emp_no
				,@record_class = 35
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
					,'EXEC [dbo].[tg_sp_set_re_surpluses Set Record Class lot original is 35 Error Hasuu Stock In] @lotno_new = ''' + @lotno_new_value + ''',@empno = ''' + @emp_no + ''',@lotno_orginal = ''' + @lotno_original + ''''
					,@lotno_new_value
			END CATCH
			
		END
		ELSE IF @prodution_category_state = 22 --prodution_category 22 = Hasuu Have Flow Rework
		BEGIN
			--Set record_class = 36 is Resurpluses to Rework  Show on web Atom //Date Create : 2022/05/09 Time : 10.57
			BEGIN TRY
				EXEC [StoredProcedureDB].[trans].[sp_set_record_class_lot_process_records]
				 @lot_no = @lotno_original
				,@opno = @emp_no
				,@record_class = 36

				--Get Data Step_no --> Date Modify : 2022/05/24 time : 13.30
				--DECLARE @get_step_no int
				--EXEC @get_step_no = [StoredProcedureDB].[atom].[sp_get_step_no] @lot_no = @Newlot
				--SELECT @get_step_no

				--add flow Reel Rework Auto (Special Flow) to store --> Date Modify : 2022/05/24 time : 13.30
				--EXEC [StoredProcedureDB].[atom].[sp_set_trans_special_flow_last_test_002_bass]  
				--   @lot_id = @Lot_Master_id
				-- , @is_special_flow = 1
				-- , @step_no = @get_step_no
				-- , @flow_pattern_id = 1873 --Reel Rework
				-- , @user_id = @user_id
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
					,'EXEC [dbo].[tg_sp_set_re_surpluses Set Record Class lot original is 36 Error Hasuu Stock In] @lotno_new = ''' + @lotno_new_value + ''',@empno = ''' + @emp_no + ''',@lotno_orginal = ''' + @lotno_original + ''''
					,@lotno_new_value
			END CATCH
		END

		--Insert Hasuu Stock In Table : H_Stock_IF to IS Server update date : 2023/02/02 Time : 13.25
		BEGIN TRY
			--H_STOCK_IF
			INSERT INTO APCSProDWH.dbo.H_STOCK_IF (
			   [Stock_Class]
			  ,[PDCD]
			  ,[LotNo]
			  ,[Type_Name]
			  ,[ROHM_Model_Name]
			  ,[ASSY_Model_Name]
			  ,[R_Fukuoka_Model_Name]
			  ,[TIRank]
			  ,[Rank]
			  ,[TPRank]
			  ,[SUBRank]
			  ,[Mask]
			  ,[KNo]
			  ,[MNo]
			  ,[ORNo]
			  ,[Packing_Standerd_QTY]
			  ,[Tomson_Mark_1]
			  ,[Tomson_Mark_2]
			  ,[Tomson_Mark_3]
			  ,[WFLotNo]
			  ,[LotNo_Class]
			  ,[User_Code]
			  ,[Product_Control_Clas]
			  ,[Product_Class]
			  ,[Production_Class]
			  ,[Rank_No]
			  ,[HINSYU_Class]
			  ,[Label_Class]
			  ,[HASU_Stock_QTY]
			  ,[HASU_WIP_QTY]
			  ,[HASUU_Working_Flag]
			  ,[OUT_OUT_FLAG]
			  ,[Label_Confirm_Class]
			  ,[OPNo]
			  ,[DMY_IN__Flag]
			  ,[DMY_OUT_Flag]
			  ,[Derivery_Date]
			  ,[Derivery_Time]
			  ,[Timestamp_Date]
			  ,[Timestamp_Time]
			)
			VALUES(
				 '01'
				,@Pdcd
				,@Newlot
				,@Package
				,@ROHM_Model_Name
				,@ASSY_Model_Name
				,@R_Fukuoka_Model_Name
				,@TIRank
				,@Rank_H_Stock
				,@TPRank
				,@SUBRank --subrank
				,@Mask --mask
				,@KNo --kno
				,@MNo --Mark_no
				,@ORNo
				,@Standerd_QTY
				,'' --tomson1
				,'' --tomson2
				,@Tomson_Mark_3
				,@WFLotNo
				,'' --lotno_class
				,@User_code --user_coce
				,@Product_Control_Clas
				,@ProductClass
				,@ProductionClass
				,@RankNo
				,@HINSYU_Class
				,@Label_Class
				,@qty_original
				,'0'
				,''
				,@Out_Out_Flag --OUT_OUT_FLAG
				,''
				,@op_no_len_value
				,''
				,''
				,GETDATE()
				,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				,CURRENT_TIMESTAMP 
				,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				
			)

			--LSI_SHIP_IF --Add Query : 2023/02/03 Time : 09.43
			INSERT INTO [APCSProDWH].[dbo].[LSI_SHIP_IF] (
				 [LotNo]
				,[Type_Name]
				,[ROHM_Model_Name]
				,[ASSY_Model_Name]
				,[R_Fukuoka_Model_Name]
				,[TIRank]
				,[Rank]
				,[TPRank]
				,[SUBRank]
				,[PDCD]
				,[Mask]
				,[KNo]
				,[MNo]
				,[ORNo]
				,[Packing_Standerd_QTY]
				,[Tomson1]
				,[Tomson2]
				,[Tomson3]
				,[WFLotNo]
				,[LotNo_Class]
				,[User_Code]
				,[Product_Control_Clas]
				,[Product_Class]
				,[Production_Class]
				,[Rank_No]
				,[HINSYU_Class]
				,[Label_Class]
				,[Standard_LotNo]
				,[Complement_LotNo_1]
				,[Complement_LotNo_2]
				,[Complement_LotNo_3]
				,[Standard_MNo]
				,[Complement_MNo_1]
				,[Complement_MNo_2]
				,[Complement_MNo_3]
				,[Standerd_QTY]
				,[Complement_QTY_1]
				,[Complement_QTY_2]
				,[Complement_QTY_3]
				,[Shipment_QTY]
				,[Good_Product_QTY]
				,[Used_Fin_Packing_QTY]
				,[HASUU_Out_Flag]
				,[OUT_OUT_FLAG]
				,[Stock_Class]
				,[Label_Confirm_Class]
				,[allocation_Date]
				,[Delete_Flag]
				,[OPNo]
				,[Timestamp_Date]
				,[Timestamp_Time]
				)
					VALUES (					
					 @Newlot
					,@Package
					,@ROHM_Model_Name
					,@ASSY_Model_Name
					,@R_Fukuoka_Model_Name
					,@TIRank
					,@Rank_H_Stock
					,@TPRank
					,@SUBRank --sub_rank
					,@Pdcd
					,@Mask --mask
					,@KNo --kno
					,@MNo  --Mno Original Lot Hasuu
					,@ORNo
					,@Standerd_QTY
					,'' --tomson_1
					,'' --tomson_2
					,@Tomson_Mark_3
					,@WFLotNo
					,'' --lotno_class
					,'' --user_code
					,@Product_Control_Clas
					,@ProductClass
					,@ProductionClass
					,@RankNo
					,@HINSYU_Class
					,@Label_Class
					,@Newlot --standard_lotno
					,'' -- hasuu_lotno ตัวที่ 1
					,'' -- hasuu_lotno ตัวที่ 2 ถ้ามี
					,'' -- hasuu_lotno ตัวที่ 3 ถ้ามี
					,@MNo --Markno
					,'' -- Mno_hsuu ตัวที่ 1 ถ้ามี
					,'' -- Mno_hsuu ตัวที่ 2 ถ้ามี
					,'' -- Mno_hsuu ตัวที่ 3 ถ้ามี
					,@qty_original -- qty lot standard
					,'' -- qty hasuu_lotno ตัวที่ 1
					,'' -- qty hasuu_lotno ตัวที่ 2
					,'' -- qty hasuu_lotno ตัวที่ 3
					,0 -- จำนวนงาน shipment fix = 0
					,@qty_original -- จำนวนงานทั้งหมด
					,''
					,''
					,@Out_Out_Flag
					,'01'
					,'2'
					,GETDATE()
					,'' -- delete_flage
					,@op_no_len_value --opno
					,CURRENT_TIMESTAMP --timestamp_date
					,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
				)
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
				,'EXEC [dbo].[tg_sp_set_re_surpluses] @empno = ''' + @emp_no + ''',@lotno_orginal = ''' + @lotno_original + ''',@qty_original = ''' + CONVERT (varchar (10), @qty_original) + ''',@lotno_new = ''' + @lotno_new_value + ''',@production_category = ''' + CONVERT (varchar (3), @prodution_category_state) + ''',@Comment = ''' + N'Insert Hasuu Re Surpluses at H_Stock by IS Error !!' + ''''
				,@lotno_new_value
		END CATCH

		--add function check data in table interface and table apcsproDB
		SELECT @Count_lsiship_IF = COUNT(LotNo) FROM APCSProDWH.[dbo].LSI_SHIP_IF where LotNo = @Newlot
		SELECT @Count_hstock_IF = COUNT(LotNo) FROM APCSProDWH.[dbo].H_STOCK_IF where LotNo = @Newlot
		--get table ApcsproDB
		SELECT @Count_lot_combine = COUNT(*) FROM APCSProDB.trans.lot_combine where lot_id = @Lot_Master_id
		SELECT @Count_surpluses = COUNT(serial_no) FROM APCSProDB.trans.surpluses where serial_no = @Newlot
		SELECT @Count_label_record =  COUNT(lot_no) FROM APCSProDB.trans.label_issue_records where lot_no = @Newlot

		--Check record data is zero or not  (Date Create 2023/04/12 Time : 16.22)
		IF @Count_lsiship_IF = 0 or @Count_hstock_IF = 0 or @Count_lot_combine = 0 or @Count_surpluses = 0 or @Count_label_record = 0
		BEGIN
			--Call Store For Cancel Re-Surpluses 
			EXEC [StoredProcedureDB].[dbo].[tg_sp_cancel_mix_lot] @lot_standard = @Newlot
			,@emp_no = @emp_no

			DECLARE @Qty_Hasuu_Lot_Original int = null
			SELECT @Qty_Hasuu_Lot_Original = pcs FROM APCSProDB.trans.surpluses where serial_no = @lotno_original

			IF @Qty_Hasuu_Lot_Original is not null
			BEGIN
				UPDATE APCSProDWH.dbo.H_STOCK_IF
				SET  @HASU_Stock_QTY = @Qty_Hasuu_Lot_Original  --update : 2023/04/06 time : 15.36
				WHERE LotNo = CAST(@lotno_original As char(10))
			END

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
				,'EXEC [dbo].[tg_sp_set_re_surpluses Auto Cancel Lot Re-Surpluses] @lotno_new = ''' + @lotno_new_value + ''',@empno = ''' + @emp_no + ''',@lotno_orginal = ''' + @lotno_original + ''',@qty_original = ''' + CONVERT (varchar (10), @qty_original) + ''',@lotno_new_wip_state = ''' + CONVERT (varchar (10), @Chk_Wip_State) + ''',@production_category = ''' + CONVERT (varchar (3), @prodution_category_state) + ''''
				,@lotno_new_value

			SELECT 'FALSE' AS Status 
			,CAST(@Newlot as varchar(10)) AS New_lot_value 
			--add value date modify : 2022/05/26 time : 16.02
			,@Lot_Master_id AS lot_master_id
			,@user_id AS userid
			RETURN

		END
		ELSE
		BEGIN
			--log store 
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
					,'EXEC [dbo].[tg_sp_set_re_surpluses create re-surpluses success] @lotno_new = ''' + @lotno_new_value + ''',@empno = ''' + @emp_no + ''',@lotno_orginal = ''' + @lotno_original + ''',@qty_original = ''' + CONVERT (varchar (10), @qty_original) + ''',@lotno_new_wip_state = ''' + CONVERT (varchar (10), @Chk_Wip_State) + ''',@production_category = ''' + CONVERT (varchar (3), @prodution_category_state) + ''''
					,@lotno_new_value

			SELECT 'TRUE' AS Status 
			,CAST(@Newlot as varchar(10)) AS New_lot_value 
			--add value date modify : 2022/05/26 time : 16.02
			,@Lot_Master_id AS lot_master_id
			,@user_id AS userid
			RETURN
		END
	END
	ELSE
	BEGIN
		--log store 
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
				,'EXEC [dbo].[tg_sp_set_re_surpluses Not Create lot re-surpluses] @lotno_new = ''' + @lotno_new_value + ''',@empno = ''' + @emp_no + ''',@lotno_orginal = ''' + @lotno_original + ''',@qty_original = ''' + CONVERT (varchar (10), @qty_original) + ''''
				,@lotno_new_value

		SELECT 'FALSE' AS Status 
		,CAST(@Newlot as varchar(10)) AS New_lot_value 
		--add value date modify : 2022/05/26 time : 16.02
		,@Lot_Master_id AS lot_master_id
		,@user_id AS userid
		RETURN
	END

END
