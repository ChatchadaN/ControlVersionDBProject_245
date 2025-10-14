-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_alot_cellcon]
	-- Add the parameters for the stored procedure here
	@lotno_standard varchar(10) = ' ',
	@hasuu_lot varchar(10) = ' ',
	@hasuu_qty int,
	@lotno_standard_qty int,
	@empno varchar(6) = ' ',
	@MNo_Hasuu char(10) = ' ',
	@package_loths varchar(10) = '',
	@device_loths varchar(20) = ' '


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Lot_No char(10) = ' '
	DECLARE @Check_Lot_Hasuu char(10) = ' ' --ใช้ check lot hasuu ว่ามีค่าใน allocat หรือเปล่า
	DECLARE @MNo_Standard char(10) = ' '
	DECLARE @Package char(10) = ' '
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
	DECLARE @Chk_WipSate INT
	DECLARE @Chk_QulityState INT
	DECLARE @Chk_ProcessState INT
	DECLARE @Lot_id INT --create 2020/11/23
	DECLARE @datestart as varchar(50) = cast( GETDATE() as date) 
	DECLARE @EmpNo_int INT --update 2021/02/04
	DECLARE @EmpNo_Char char(5) = ' ' --update 2021/02/11

	select @EmpNo_int = CONVERT(INT, @empno) --update 2021/02/04
	select @EmpNo_Char = CONVERT(char(5),@EmpNo_int); --update 2021/02/11


	--update 2021/02/17
	--DECLARE @op_no_len char(5);
	DECLARE @op_no_len_value char(5) = '';

	--select @op_no_len = @EmpNo_Char

	select  @op_no_len_value =  case when LEN(CAST(@EmpNo_Char as char(5))) = 4 then '0' + CAST(@EmpNo_Char as char(5))
			when LEN(CAST(@EmpNo_Char as char(5))) = 3 then '00' + CAST(@EmpNo_Char as char(5))
			when LEN(CAST(@EmpNo_Char as char(5))) = 2 then '000' + CAST(@EmpNo_Char as char(5))
			when LEN(CAST(@EmpNo_Char as char(5))) = 1 then '0000' + CAST(@EmpNo_Char as char(5))
			else CAST(@EmpNo_Char as char(5)) end 

	select @Lot_No = tranlot.[lot_no] 
	,@Lot_id = [tranlot].[id]
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
	,@QtyPass_Standard = tranlot.[qty_pass]
	,@Total = (@lotno_standard_qty + @hasuu_qty)  -- จำนวนงานเดิมที่มีอยู่รวมกับจำนวน hasuu ที่ส่งค่ามา
	,@Totalhasuu = (@lotno_standard_qty + @hasuu_qty)%(allocat.Packing_Standerd_QTY) -- จำนวนงานเดิมที่มีอยู่รวมกับจำนวน hasuu ที่ส่งค่ามาหารจำนวน standard
	,@Standerd_QTY = CAST(allocat.Packing_Standerd_QTY AS char(7)) --edit 2021/01/14
	,@Qty_Full_Reel_All = (allocat.Packing_Standerd_QTY) * ((@lotno_standard_qty + @hasuu_qty)/(allocat.Packing_Standerd_QTY)) -- จำนวนงานเต็ม reel ทั้งหมด
	,@Qty_Standard_Lsiship = ((allocat.Packing_Standerd_QTY) * ((@lotno_standard_qty + @hasuu_qty)/(allocat.Packing_Standerd_QTY)) - @hasuu_qty) 
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
	INNER JOIN [StoredProcedureDB].[dbo].[IS_ALLOCAT] as allocat ON tranlot.lot_no = allocat.LotNo 
	WHERE tranlot.[lot_no] = @lotno_standard
	
	--Get data in tabel IS_H_STOCK
	--select @Rank_hasuu_H_Stock = Rank,@Tomson_Mark_3_lot_hasuu_H_Stock = Tomson_Mark_3 
	--from StoredProcedureDB.dbo.IS_H_STOCK 
	--where DMY_OUT_Flag != '1' and  LotNo = @hasuu_lot

	--Get data in tabel IS_ALLPCAT
	select @Check_Lot_Hasuu = LotNo ,@Tomson_Mark_3_lot_hasuu = Tomson3
	,@Rank_hasuu = Rank 
	from StoredProcedureDB.dbo.IS_ALLOCAT where LotNo = @hasuu_lot

	select @Chk_Fristlot = serial_no from APCSProDB.trans.surpluses where serial_no = @lotno_standard
	-- Check qc stop lot
	select @Chk_WipSate = wip_state from APCSProDB.trans.lots where lot_no = @lotno_standard
	select @Chk_QulityState = quality_state from APCSProDB.trans.lots where lot_no = @lotno_standard
	select @Chk_ProcessState = process_state from APCSProDB.trans.lots where lot_no = @lotno_standard
	--select @Lot_id = id from APCSProDB.trans.lots where lot_no = @hasuu_lot


	--LOG FILE TO STORE Create 2020/12/23 start

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
		,'EXEC [dbo].[tg_sp_set_alot_cellcon] @lotno_standard = ''' + @Lot_No + ''', @hasuu_lot = ''' + @hasuu_lot + ''', @hasuu_qty = ''' + CONVERT (varchar (10), @hasuu_qty) + ''', @lotno_standard_qty = '''+ CONVERT (varchar (10), @lotno_standard_qty) + ''', @empno = ''' + @empno + ''',@MNo_Hasuu = ''' + @MNo_Hasuu + ''',@package_loths = ''' + @package_loths + ''',@device_loths = ''' + @device_loths + ''''
	
	--LOG FILE TO STORE Create 2020/12/23 end


	BEGIN TRY 
	IF @hasuu_qty != 0 
	BEGIN
				--check lotno record null
				IF @Check_Lot_Hasuu = ''
				BEGIN
						--Get data in tabel IS_H_STOCK
						select @Check_Lot_Hasuu = LotNo , @Rank_hasuu = Rank,@Tomson_Mark_3_lot_hasuu = Tomson_Mark_3 
						from StoredProcedureDB.dbo.IS_H_STOCK 
						where DMY_OUT_Flag != '1' and  LotNo = @hasuu_lot

						IF @Check_Lot_Hasuu = '' 
						BEGIN
							SELECT 'FALSE' AS Status ,'SELECT DATA ERROR !!' AS Error_Message_ENG,N'ไม่พบข้อมูลใน tabel allocal และ h_stock' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
							RETURN
						END
				END

				--edit 2020/11/23
				--IF @Chk_Fristlot = ''  
				--BEGIN
					IF @Package = @package_loths AND @ROHM_Model_Name = @device_loths AND @Rank = @Rank_hasuu AND @Tomson_Mark_3 = @Tomson_Mark_3_lot_hasuu
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
							,@hasuu_lot
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
							,@MNo_Hasuu --Mno_hasuu
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
							,@hasuu_qty  --จำนวนของ hasuu ที่ส่งค่ามา
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
							,@hasuu_lot -- hasuu_lotno ตัวที่ 1
							,'' -- hasuu_lotno ตัวที่ 2 ถ้ามี
							,'' -- hasuu_lotno ตัวที่ 3 ถ้ามี
							,@MNo_Standard
							,@MNo_Hasuu -- Mno_hsuu ตัวที่ 1 ถ้ามี
							,'' -- Mno_hsuu ตัวที่ 2 ถ้ามี
							,'' -- Mno_hsuu ตัวที่ 3 ถ้ามี
							,@lotno_standard_qty -- qty lot standard
							,@hasuu_qty -- qty hasuu_lotno ตัวที่ 1
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

					-- insert lotno hasuu in table test_is_h_stock
			
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
				   WHERE LotNo = @hasuu_lot

					--update instock = 1 (Location Assing) : Add Query Update Instock of Mix Present
					UPDATE APCSProDB.trans.surpluses
					SET in_stock = '1'
					,updated_at = GETDATE()
					WHERE serial_no = @hasuu_lot


					--update qty_pass in tranlot
					UPDATE [APCSProDB].[trans].[lots]
					SET 
						  [qty_pass] = @Total
					WHERE [lot_no] = @lotno_standard


					IF @Chk_Fristlot = ''
					BEGIN
						-- insert and update hasuu to tabel [trans].[surpluses]
						EXEC [StoredProcedureDB].[atom].[sp_set_label_issued_tg] @lot_no = @lotno_standard
						,@qty_hasuu_brfore = @hasuu_qty
						,@Empno_int_value = @EmpNo_int --Update 2021/03/16
					END
					ELSE IF @Chk_Fristlot != ''
					BEGIN
						UPDATE [APCSProDB].[trans].[surpluses]
						SET 
							[pcs] = @Totalhasuu
							, [serial_no] = @lot_no
							, [in_stock] = '2'
							, [location_id] = ''
							, [acc_location_id] = ''
							, [updated_at] = GETDATE()
							, [updated_by] = @EmpNo_int --Update 2021/03/16
						WHERE [lot_id] = @Lot_id
					END

					-- INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records
					EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
					,@sataus_record_class = 1

					-- update qty_pass to tabel [trans].[lots]
					EXEC [StoredProcedureDB].[atom].[sp_set_tsugitashi_tg] 
					@master_lot_no = @lotno_standard
					,@hasuu_lot_no = @hasuu_lot
					,@masterqty = @lotno_standard_qty
					,@hasuuqty = @hasuu_qty
					,@OP_No = @EmpNo_int

					--UPDATE COLUMN PDCD IN TABLE : SURPLUSES >> Add Query 2021/05/25 <<
					UPDATE [APCSProDB].[trans].[surpluses]
					SET 
							pdcd = @Pdcd
							,updated_at = GETDATE()
					WHERE [serial_no] = @lotno_standard
			
				END
			ELSE 
			BEGIN
				SELECT 'FALSE' AS Status ,'INSERT DATA ERROR !!' AS Error_Message_ENG,N'เงื่อนไขการ mix ไม่ตรงกัน กรุณาตรวจสอบข้อมูล' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END

				--edit 2020/11/23
				--END
				--ELSE IF @Chk_Fristlot != '' 
				--BEGIN
				--	SELECT 'TRUE' AS Status ,'Insert error !!' AS Error_Message_ENG,N'ไม่สามารถทำ frist lot ซ้ำได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				--RETURN
				--END

	END
	ElSE IF @hasuu_qty = 0
	BEGIN
		--IF (@Chk_WipSate = 10 OR @Chk_WipSate = 70) or (@Chk_QulityState = 0 OR @Chk_QulityState = 4) or (@Chk_ProcessState = 0 OR @Chk_ProcessState = 100)
		--BEGIN
		--IF @Chk_Fristlot = ''
		--	BEGIN
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_label_issue_tg] @lotno_standard = @lotno_standard
				,@empno = @empno

				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
				,@sataus_record_class = 1

				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_lot_combine_records] @lotno = @lotno_standard
				,@sataus_record_class = 1

				--EXEC [StoredProcedureDB].[atom].[sp_set_label_issued_tg] @lot_no = @lotno_standard
		--	END
		--ELSE IF @Chk_Fristlot != ''
		--	BEGIN
		--		SELECT 'TRUE' AS Status ,'Insert error !!' AS Error_Message_ENG,N'ไม่สามารถทำ frist lot ซ้ำได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		--	RETURN
		--	END
		--END
		--BEGIN
		--	SELECT 'FALSE' AS Status ,'INSER ERROR !!' AS Error_Message_ENG,N'lot นี้ถูก stop ไว้ ไม่สามารถทำการ mix ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		--	RETURN
		--END
		
	END
			SELECT 'TRUE' AS Status ,'Success !!' AS Error_Message_ENG,N'บันทึกเรียบร้อย !!' AS Error_Message_THA
			RETURN
	END TRY
	BEGIN CATCH 
			SELECT 'FALSE' AS Status ,'Update error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
	END CATCH

END
