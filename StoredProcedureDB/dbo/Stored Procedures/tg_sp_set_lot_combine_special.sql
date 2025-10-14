-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_lot_combine_special] 
	-- Add the parameters for the stored procedure here
	 @lotno_standard varchar(10) = ''
	,@qty_lot_std int = 0
	,@lotno_hasuu varchar(10) = ''
	,@qty_lot_hasuu int = 0
	,@empno char(6) = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Check_Lot_Hasuu char(10) = ' ' --ใช้ check lot hasuu ว่ามีค่าใน allocat หรือเปล่า
	DECLARE @MNo_Standard char(10) = ' '
	DECLARE @Package char(10) = ' '
	DECLARE @Package_lot_hasuu char(10) = ' '
	DECLARE @Rank char(5) = ' '
	DECLARE @Rank_hasuu char(5) = ' '
	DECLARE @Rank_hasuu_H_Stock char(5) = ' '
	DECLARE @Standerd_QTY char(7) = ' '
	--DECLARE @MNo char(10) = ' '
	DECLARE @ASSY_Model_Name char(20) = ' '
	DECLARE @Hasuu_Stock_QTY int
	DECLARE @QtyPass_Standard int
	DECLARE @Total int
	DECLARE @Reel int
	DECLARE @Totalhasuu int 
	DECLARE @Qty_Full_Reel_All int
	DECLARE @Qty_Standard_Lsiship int
	DECLARE @Stock_Class char(2) = ' '
	DECLARE @Pdcd char(5) = ' '
	DECLARE @ROHM_Model_Name char(20) = ' '
	DECLARE @Device_lot_hasuu char(20) = ' '
	DECLARE @R_Fukuoka_Model_Name char(20) = ' '
	DECLARE @TIRank char(5) = ' '
	DECLARE @TPRank char(3) = ' '
	DECLARE @SUBRank char(3) = ' '
	DECLARE @Mask char(2) = ' '
	DECLARE @KNo char(3) = ' '
	DECLARE @Tomson_Mark_1 char(4) = ' '
	DECLARE @Tomson_Mark_2 char(4) = ' '
	DECLARE @Tomson_Mark_3 char(4) = ' '
	DECLARE @Tomson_Mark_3_lot_hasuu char(4) = ' '
	DECLARE @Tomson_Mark_3_lot_hasuu_H_Stock char(4) = ' '
	DECLARE @ORNo char(12) = ' '
	DECLARE @WFLotNo char(20) = ' '
	DECLARE @LotNo_Class char(1) = ' '
	DECLARE @Product_Control_Clas char(3) = ' '
	DECLARE @ProductClass char(1) = ' '
	DECLARE @ProductionClass char(1) = ' '
	DECLARE @RankNo char(6) = ' '
	DECLARE @HINSYU_Class char(1) = ' '
	DECLARE @Label_Class char(1) = ' '
	DECLARE @User_code char(6) = ' '
	DECLARE @Out_Out_Flag char(1) = ' '
	DECLARE @Allocation_Date char(30) = ' '
	DECLARE @Chk_Fristlot char(10) = ' '
	DECLARE @Lot_id INT --create 2020/11/23
	DECLARE @datestart as varchar(50) = cast( GETDATE() as date) 
	DECLARE @EmpNo_int INT --update 2021/02/04
	DECLARE @EmpNo_Char char(5) = ' ' --update 2021/02/11
	DECLARE @count_lotid_fristlot int = 0 --update 2021/05/23
	DECLARE @Lot_Type_Hasuu char(1);
	DECLARE @Lot_Type_Standard char(1);
	DECLARE @MNo_Hasuu_Value char(10) = ' '
	DECLARE @Check_lot_label_issue varchar(10) = ''

	select @EmpNo_int = CONVERT(INT, @empno) --update 2021/02/04
	select @EmpNo_Char = CONVERT(char(5),@EmpNo_int); --update 2021/02/11

	DECLARE @op_no_len_value char(5) = '';

	--select @op_no_len = @EmpNo_Char

	select  @op_no_len_value =  case when LEN(CAST(@EmpNo_Char as char(5))) = 4 then '0' + CAST(@EmpNo_Char as char(5))
			when LEN(CAST(@EmpNo_Char as char(5))) = 3 then '00' + CAST(@EmpNo_Char as char(5))
			when LEN(CAST(@EmpNo_Char as char(5))) = 2 then '000' + CAST(@EmpNo_Char as char(5))
			when LEN(CAST(@EmpNo_Char as char(5))) = 1 then '0000' + CAST(@EmpNo_Char as char(5))
			else CAST(@EmpNo_Char as char(5)) end 

	select 
	 @Lot_id = [tranlot].[id]
	,@Package = allocat.Type_Name
	,@ROHM_Model_Name = allocat.ROHM_Model_Name
	,@ASSY_Model_Name =  allocat.ASSY_Model_Name
	,@R_Fukuoka_Model_Name = allocat.R_Fukuoka_Model_Name
	,@TIRank = allocat.TIRank
	,@Rank = allocat.Rank
	,@TPRank = allocat.TPRank
	,@SUBRank = allocat.SUBRank
	,@Mask = Mask
	,@KNo = KNo
	,@QtyPass_Standard = @qty_lot_std
	,@Total = (@qty_lot_std + @qty_lot_hasuu)  -- จำนวนงานเดิมที่มีอยู่รวมกับจำนวน hasuu ที่ส่งค่ามา
	,@Totalhasuu = (@qty_lot_std + @qty_lot_hasuu)%(allocat.Packing_Standerd_QTY) -- จำนวนงานเดิมที่มีอยู่รวมกับจำนวน hasuu ที่ส่งค่ามาหารจำนวน standard
	,@Standerd_QTY = CAST(allocat.Packing_Standerd_QTY AS char(7)) --edit 2021/01/14
	,@Qty_Full_Reel_All = (allocat.Packing_Standerd_QTY) * ((@qty_lot_std + @qty_lot_hasuu)/(allocat.Packing_Standerd_QTY)) -- จำนวนงานเต็ม reel ทั้งหมด
	,@Qty_Standard_Lsiship = ((allocat.Packing_Standerd_QTY) * ((@qty_lot_std + @qty_lot_hasuu)/(allocat.Packing_Standerd_QTY)) - @qty_lot_hasuu) 
	,@Out_Out_Flag =  allocat.OUT_OUT_FLAG
	,@Allocation_Date = allocat.allocation_Date
	,@MNo_Standard = allocat.MNo --mno_standard
	,@Pdcd = allocat.PDCD --PDCD
	,@ORNo = allocat.ORNo --ORNO
	,@Tomson_Mark_1 = allocat.Tomson1
	,@Tomson_Mark_2 = allocat.Tomson2
	,@Tomson_Mark_3 = allocat.Tomson3
	,@WFLotNo = allocat.WFLotNo
	,@Label_Class = allocat.Label_Class
	,@ProductionClass = allocat.Production_Class --production_class
	,@ProductClass = allocat.Product_Class --product_class
	,@Product_Control_Clas = allocat.Product_Control_Cl_1 --product_control_class
	FROM [APCSProDB].[trans].[lots]  as tranlot
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = tranlot.[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] as device_names  ON [device_names].[id] = [device_versions].[device_name_id]
	INNER JOIN [APCSProDB].[method].[packages] as packages ON [device_names].[package_id]  = [packages].[id]
	INNER JOIN [APCSProDB].[method].[allocat] as allocat ON tranlot.lot_no = allocat.LotNo 
	WHERE tranlot.[lot_no] = @lotno_standard

	select 
	@Package_lot_hasuu = pk.short_name
	,@Device_lot_hasuu =  dn.name
	,@Rank_hasuu = case when dn.rank is null then '' else dn.rank end
	,@Tomson_Mark_3_lot_hasuu = case when den_pyo.TOMSON_INDICATION is null then '' else den_pyo.TOMSON_INDICATION end
	from APCSProDB.trans.lots as lot
	inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	inner join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_4
	where lot.lot_no = @lotno_hasuu

	select @Lot_Type_Hasuu = SUBSTRING(lot_no,5,1) from APCSProDB.trans.lots where lot_no = @lotno_hasuu

	select @Lot_Type_Standard = SUBSTRING(lot_no,5,1) from APCSProDB.trans.lots where lot_no = @lotno_standard

	--LOG FILE TO STORE Create 2021/17/05 end
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
		,'EXEC [dbo].[tg_sp_set_lot_combine_special]  @lotno_standard = ''' + @lotno_standard + ''', @hasuu_lot = ''' + @lotno_hasuu + ''', @qty_lot_standard = ''' + CONVERT (varchar (10), @qty_lot_std) + ''', @qty_lot_hasuu = '''+ CONVERT (varchar (10), @qty_lot_hasuu) + ''', @empno = ''' + @empno + ''''
		,@lotno_standard

	--IF @Lot_Type_Standard = 'A' and @lotno_hasuu = 'A'
	--BEGIN
		IF @Package = @Package_lot_hasuu AND @ROHM_Model_Name = @Device_lot_hasuu AND @Rank = @Rank_hasuu AND @Tomson_Mark_3 = @Tomson_Mark_3_lot_hasuu
		BEGIN
			--insrt into to DB-IS
					INSERT INTO OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[MIX_HIST](
						  --[M_O_No]
						  --,[FREQ]
							[HASUU_LotNo]
							,[LotNo]
						  --,[P_O_No]
						  ,[Stock_Class]
						  ,[Type_Name]
						  ,[ROHM_Model_Name]
						  ,[PDCD]
						  ,[ASSY_Model_Name]
						  ,[R_Fukuoka_Model_Name]
						  ,[TIRank]
						  ,[Rank]
						  ,[TPRank]
						  ,[SUBRank]
						  ,[Mask]
						  ,[KNo]
						  ,[MNo]
						  ,[Tomson1]
						  ,[Tomson2]
						  ,[Tomson3]
						  ,[allocation_Date]
						  ,[ORNo]
						  ,[WFLotNo]
						  --,[User_Code]
						  ,[LotNo_Class]
						  ,[Label_Class]
						  --,[Multi_Class]
						  ,[Product_Control_Clas]
						  ,[Packing_Standerd_QTY]
						  --,[Date_Code]
						  --,[HASUU_Out_Flag]
						  ,[QTY]
						  --,[Transfer_Flag]
						  --,[Transfer]
						  ,[OPNo]
						  --,[Theoretical]
						  ,[OUT_OUT_FLAG]
						  ,[MIXD_DATE]
						  ,[TimeStamp_date]
						  ,[TimeStamp_time]
						 )
							VALUES (					
								 @lotno_standard
								,@lotno_standard
								,'01' --modify 20201218 stockclass 01 change 02
								,@package
								,@ROHM_Model_Name
								,@Pdcd
								,@ASSY_Model_Name
								,@R_Fukuoka_Model_Name
								,@TIRank
								,@rank
								,@TPRank
								,@SUBRank --subRank
								,@Mask --mask
								,@KNo --Kno
								,@MNo_Standard
								,'' --tomson1
								,'' --tomson2
								,@Tomson_Mark_3
								,@Allocation_Date
								,@ORNo
								,@WFLotNo
								,@LotNo_Class
								,@Label_Class
								,@Product_Control_Clas
								,@Standerd_QTY
								,@Qty_Standard_Lsiship -- จำนวนงานของ lot standard ที่หาร reel ลงตัว
								,@op_no_len_value
								,@Out_Out_Flag
								,GETDATE()
								,CURRENT_TIMESTAMP --timestamp_date
								,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
						),
						(					 
								 @lotno_standard
								,@lotno_hasuu
								,'01' --modify 20201218 stockclass 01 change 02
								,@package
								,@ROHM_Model_Name
								,@Pdcd
								,@ASSY_Model_Name
								,@R_Fukuoka_Model_Name
								,@TIRank
								,@rank
								,@TPRank
								,@SUBRank --subrank
								,@Mask --mask
								,@KNo --kno
								--,@MNo_Hasuu --Mno_hasuu
								,@MNo_Hasuu_Value
								,'' --tomson1
								,'' --tomson2
								,@Tomson_Mark_3
								,@Allocation_Date 
								,@ORNo
								,@WFLotNo
								,@LotNo_Class
								,@Label_Class
								,@Product_Control_Clas
								,@Standerd_QTY
								,@qty_lot_hasuu  --จำนวนของ hasuu ที่ส่งค่ามา
								,@op_no_len_value
								,@Out_Out_Flag
								,GETDATE()
								,CURRENT_TIMESTAMP --timestamp_date
								,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
						);

					--insrt into table LSI_SHIP to DB-IS
					INSERT INTO OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[LSI_SHIP](
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
								 @lotno_standard
								,@package
								,@ROHM_Model_Name
								,@ASSY_Model_Name
								,@R_Fukuoka_Model_Name
								,@TIRank
								,@rank
								,@TPRank
								,@SUBRank --sub_rank
								,@Pdcd
								,@Mask --mask
								,@KNo --kno
								,@MNo_Standard
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
								,@lotno_standard --standard_lotno
								,@lotno_hasuu -- hasuu_lotno ตัวที่ 1
								,'' -- hasuu_lotno ตัวที่ 2 ถ้ามี
								,'' -- hasuu_lotno ตัวที่ 3 ถ้ามี
								,@MNo_Standard
								,@MNo_Hasuu_Value -- Mno_hsuu ตัวที่ 1 ถ้ามี
								,'' -- Mno_hsuu ตัวที่ 2 ถ้ามี
								,'' -- Mno_hsuu ตัวที่ 3 ถ้ามี
								,@qty_lot_std -- qty lot standard
								,@qty_lot_hasuu -- qty hasuu_lotno ตัวที่ 1
								,'' -- qty hasuu_lotno ตัวที่ 2
								,'' -- qty hasuu_lotno ตัวที่ 3
								,@Qty_Full_Reel_All -- จำนวนงานทั้งหมดที่พอดี reel
								,@Total -- จำนวนงานทั้งหมด
								,''
								,''
								,@Out_Out_Flag
								,'01' --modify 20201218 stockclass 01 change 02
								,'2'
								,@Allocation_Date
								,'' -- delete_flage
								,@op_no_len_value --opno
								,CURRENT_TIMESTAMP --timestamp_date
								,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
						);

					--insert into DB-IS
					INSERT INTO OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[H_STOCK](
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
							 '01' --modify 20201218 stockclass 01 change 02
							,@Pdcd
							,@lotno_standard
							,@package
							,@ROHM_Model_Name
							,@ASSY_Model_Name
							,@R_Fukuoka_Model_Name
							,@TIRank
							,@rank
							,@TPRank
							,@SUBRank --subrank
							,@Mask --mask
							,@KNo --kno
							,@MNo_Standard
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
							,@Totalhasuu
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
				
						);
			
					--insrt into table WORK_R_DB to DB-IS
					INSERT INTO OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;').[DBLSISHT].[dbo].[WORK_R_DB](
						   [LotNo]
						  ,[Process_No]
						  ,[Process_Date]
						  ,[Process_Time]
						  ,[Back_Process_No]
						  ,[Good_QTY]
						  ,[NG_QTY]
						  ,[NG_QTY1]
						  ,[Cause_Code_of_NG1]
						  ,[NG_QTY2]
						  ,[Cause_Code_of_NG2]
						  ,[NG_QTY3]
						  ,[Cause_Code_of_NG3]
						  ,[NG_QTY4]
						  ,[Cause_Code_of_NG4]
						  ,[Shipment_QTY]
						  ,[OPNo]
						  ,[TERM_ID]
						  ,[TimeStamp_Date]
						  ,[TimeStamp_Time]
						  ,[Send_Flag]
						  ,[Making_Date]
						  ,[Making_Time]
						  ,[SEQNO_SQL10]
					   )
					   VALUES(
						  @lotno_standard
						  ,1001 --process_no --1001 = tg
						  ,CURRENT_TIMESTAMP --Process_Date
						  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --Process_Time
						  ,'0'
						  ,@QtyPass_Standard --จำนวน standard ใน column qty_pass to table : tranlot
						  ,'0' --ng qty
						  ,'0' --ng_qty1
						  ,' '
						  ,'0'
						  ,' '
						  ,'0'
						  ,' '
						  ,'0'
						  ,' '
						  ,'0' --shipment_qty
						  ,@op_no_len_value --opno
						  ,'0' --time_id
						  ,CURRENT_TIMESTAMP --timestamp_date
						  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
						  ,''
						  ,''
						  ,''
						  ,''

					   )

					--insrt into table PACKWORK to DB-IS
					INSERT INTO OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[PACKWORK](
						   [LotNo]
						  ,[Type_Name]
						  ,[ROHM_Model_Name]
						  ,[R_Fukuoka_Model_Name]
						  ,[Rank]
						  ,[TPRank]
						  ,[PDCD]
						  ,[Quantity]
						  ,[ORNo]
						  ,[OPNo]
						  ,[Delete_Flag]
						  ,[Timestamp_Date]
						  ,[Timestamp_time]
						  ,[SEQNO]
					   )
					   VALUES(
						   @lotno_standard
						  ,@Package
						  ,@ROHM_Model_Name
						  ,@R_Fukuoka_Model_Name
						  ,@Rank
						  ,@TPRank
						  ,@Pdcd
						  ,@QtyPass_Standard
						  ,@ORNo
						  ,@op_no_len_value --opno
						  ,''
						  ,CURRENT_TIMESTAMP --timestamp_date
						  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
						  ,''
					   )

					 -- insert into table WH_UKEBA to DB-IS
					INSERT INTO OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[WH_UKEBA](
							   [Record_Class]
							  ,[ROHM_Model_Name]
							  ,[LotNo]
							  ,[OccurDate]
							  ,[R_Fukuoka_Model_Name]
							  ,[Rank]
							  ,[TPRank]
							  ,[RED_BLACK_Flag]
							  ,[QTY]
							  ,[StockQTY]
							  ,[Warehouse_Code]
							  ,[ORNo]
							  ,[OPNO]
							  ,[PROC1]
							  ,[Making_Date_Date]
							  ,[Making_Date_Time]
							  ,[Data__send_Flag]
							  ,[Delete_Flag]
							  ,[TimeStamp_date]
							  ,[TimeStamp_time]
							  ,[SEQNO]
					   )
					   VALUES(
							   '' --RECORD_CLASS
							  ,@ROHM_Model_Name
							  ,@lotno_standard
							  ,CURRENT_TIMESTAMP --OccurDate
							  ,@R_Fukuoka_Model_Name
							  ,@Rank
							  ,@TPRank
							  ,'0' --RED_BLACK_Flag
							  ,@Total
							  ,'0' --STOCK_QTY
							  ,@Pdcd --WAREHOUSECODE
							  ,@ORNo
							  ,@op_no_len_value --OPNO
							  ,'1' --PROC1
							  ,CURRENT_TIMESTAMP --timestamp_date
							  ,'' --Making_Date_Time
							  ,'' --DATA_SEND_FLAG
							  ,'' --DELETE_FLAG
							  ,CURRENT_TIMESTAMP --timestamp_date
							  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
							  ,'' --SEQNO
					   )

					--update dumy_out_flag = 1
					UPDATE DBxDW.TGOG.Temp_H_STOCK
					SET DMY_OUT_Flag = '1'
					,Timestamp_Date = GETDATE()
					WHERE LotNo = @lotno_hasuu

					--update instock = 1 (Location Assing) : Add Query Update Instock of Mix Present
					UPDATE APCSProDB.trans.surpluses
					SET in_stock = '1'
					,updated_at = GETDATE()
					WHERE serial_no = @lotno_hasuu

					--update qty_pass in lot standard Create 2021/06/22
					UPDATE [APCSProDB].[trans].[lots]
					SET 
						[qty_pass] = @qty_lot_std
					WHERE [lot_no] = @lotno_standard

					-- insert and update hasuu to tabel [trans].[surpluses]
					EXEC [StoredProcedureDB].[atom].[sp_set_label_issued_tg_V2] @lot_no = @lotno_standard
					,@qty_hasuu_before = @qty_lot_hasuu
					,@Empno_int_value = @EmpNo_int --Update 2021/03/16

					-- INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records
					EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
					,@sataus_record_class = 1

					--UPDATE COLUMN PDCD IN TABLE : SURPLUSES >> Add Query 2021/05/25 <<
					UPDATE [APCSProDB].[trans].[surpluses]
					SET 
							pdcd = @Pdcd
							,qc_instruction = @Tomson_Mark_3
							,mark_no = @MNo_Standard
							,updated_at = GETDATE()
					WHERE [lot_id] = @Lot_id

					-- update qty_pass to tabel [trans].[lots]
					EXEC [StoredProcedureDB].[atom].[sp_set_tsugitashi_tg] 
					@master_lot_no = @lotno_standard
					,@hasuu_lot_no = @lotno_hasuu
					,@masterqty = @qty_lot_std
					,@hasuuqty = @qty_lot_hasuu
					,@OP_No = @EmpNo_int

					-- INSERT DATA IN TABLE LABEL_HISTORY
					EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @lotno_standard
					,@process_name = 'TP'

					SELECT 'TRUE' AS Status ,'Insert Data Success!!' AS Error_Message_ENG,N'ทำ TG สำเร็จ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
					RETURN

		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS Status ,'Insert Data error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END
	--END
	--ELSE
	--BEGIN
	--	SELECT 'FALSE' AS Status ,'Insert Data error Lot Type !!' AS Error_Message_ENG,N'การทำ TG จะต้องเป็น A Lot mix กัน เท่านั้น !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
	--	RETURN
	--END

END
