-- =============================================
-- Author:		<Author,,Name : Aomsin>
-- Create date: <Create Date,2021/10/08,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_re_surpluses_manual_by_aomsin]
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

	select @Lot_Master_id = id from APCSProDB.trans.lots where lot_no = @Newlot

		--Insert Hasuu Stock In Table : H_Stock_IF to IS Server update date : 2023/02/02 Time : 13.25
		BEGIN TRY
			--H_STOCK_IF
			--INSERT INTO APCSProDWH.dbo.H_STOCK_IF (
			--   [Stock_Class]
			--  ,[PDCD]
			--  ,[LotNo]
			--  ,[Type_Name]
			--  ,[ROHM_Model_Name]
			--  ,[ASSY_Model_Name]
			--  ,[R_Fukuoka_Model_Name]
			--  ,[TIRank]
			--  ,[Rank]
			--  ,[TPRank]
			--  ,[SUBRank]
			--  ,[Mask]
			--  ,[KNo]
			--  ,[MNo]
			--  ,[ORNo]
			--  ,[Packing_Standerd_QTY]
			--  ,[Tomson_Mark_1]
			--  ,[Tomson_Mark_2]
			--  ,[Tomson_Mark_3]
			--  ,[WFLotNo]
			--  ,[LotNo_Class]
			--  ,[User_Code]
			--  ,[Product_Control_Clas]
			--  ,[Product_Class]
			--  ,[Production_Class]
			--  ,[Rank_No]
			--  ,[HINSYU_Class]
			--  ,[Label_Class]
			--  ,[HASU_Stock_QTY]
			--  ,[HASU_WIP_QTY]
			--  ,[HASUU_Working_Flag]
			--  ,[OUT_OUT_FLAG]
			--  ,[Label_Confirm_Class]
			--  ,[OPNo]
			--  ,[DMY_IN__Flag]
			--  ,[DMY_OUT_Flag]
			--  ,[Derivery_Date]
			--  ,[Derivery_Time]
			--  ,[Timestamp_Date]
			--  ,[Timestamp_Time]
			--)
			--VALUES(
			--	 '02'
			--	,@Pdcd
			--	,@Newlot
			--	,@Package
			--	,@ROHM_Model_Name
			--	,@ASSY_Model_Name
			--	,@R_Fukuoka_Model_Name
			--	,@TIRank
			--	,@Rank_H_Stock
			--	,@TPRank
			--	,@SUBRank --subrank
			--	,@Mask --mask
			--	,@KNo --kno
			--	,@MNo --Mark_no
			--	,@ORNo
			--	,@Standerd_QTY
			--	,'' --tomson1
			--	,'' --tomson2
			--	,@Tomson_Mark_3
			--	,@WFLotNo
			--	,'' --lotno_class
			--	,@User_code --user_coce
			--	,@Product_Control_Clas
			--	,@ProductClass
			--	,@ProductionClass
			--	,@RankNo
			--	,@HINSYU_Class
			--	,@Label_Class
			--	,@qty_original
			--	,'0'
			--	,''
			--	,@Out_Out_Flag --OUT_OUT_FLAG
			--	,''
			--	,@op_no_len_value
			--	,''
			--	,''
			--	,GETDATE()
			--	,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			--	,CURRENT_TIMESTAMP 
			--	,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				
			--)

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
					,'02'
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

END
