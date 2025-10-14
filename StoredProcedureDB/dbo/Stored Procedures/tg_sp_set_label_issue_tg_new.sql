-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,2022/03/15 time : 13.51,update stock class = 01 all table>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_label_issue_tg_new]
	-- Add the parameters for the stored procedure here
	 @lotno_standard varchar(10) = ''
	,@empno char(6) = ' ' --edit @empno form char 5 is char 6
	,@machine_id_val int = null

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Lot_No char(10) = ' '
	DECLARE @hasuu_lot char(10) = ' '
	DECLARE @MNo_Standard char(10) = ' '
	DECLARE @MNo_Hasuu char(10) = ' '
	DECLARE @Package char(10) = ' '
	DECLARE @Rank char(5) = ' '
	DECLARE @Standerd_QTY char(7) = ' '
	DECLARE @ASSY_Model_Name char(20) = ' '
	DECLARE @Hasuu_Stock_QTY int
	DECLARE @QtyPass_Standard int
	DECLARE @Total int
	DECLARE @Reel int
	DECLARE @Totalhasuu int 
	DECLARE @qty_out int
	DECLARE @Qty_Standard_Lsiship int
	DECLARE @hasuu_qty int
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
	DECLARE @Packing_Standerd_QTY int
	DECLARE @datestart as varchar(50) = cast( GETDATE() as date) 
	DECLARE @Hasuu_before int = 0
	DECLARE @Emp_int INT; --update 2021/03/16
	--Add Parameter Date : 2021/12/06 
	DECLARE @Lotno_Allocat_Count Int = 0
	--Add Parameter Date : 2022/02/03 time : 09.10 
	DECLARE @machine_name varchar(15) = ''

	SELECT @Lotno_Allocat_Count = COUNT(*) FROM APCSProDB.method.allocat where LotNo = @lotno_standard

    -- Insert statements for procedure here
	SELECT @Emp_int = CONVERT(INT, @empno) --update 2021/02/04

	DECLARE @op_no_len_value char(5) = '';  --insert on data interface only for support Is Database

	SELECT  @op_no_len_value =  case when LEN(CAST(@Emp_int as char(5))) = 4 then '0' + CAST(@Emp_int as char(5))
			when LEN(CAST(@Emp_int as char(5))) = 3 then '00' + CAST(@Emp_int as char(5))
			when LEN(CAST(@Emp_int as char(5))) = 2 then '000' + CAST(@Emp_int as char(5))
			when LEN(CAST(@Emp_int as char(5))) = 1 then '0000' + CAST(@Emp_int as char(5))
			else CAST(@Emp_int as char(5)) end 

	------------------------------------ Start Get EmpId Modify : 2024/12/26 ------------------------------------
	DECLARE @GetEmpno varchar(6) = ''
	DECLARE @EmpnoId int = NULL

	SELECT  @GetEmpno = FORMAT(CAST(@Empno AS INT), '000000')
	SELECT @EmpnoId = id FROM [APCSProDB].[man].[users] WHERE [emp_num] = @GetEmpno
	------------------------------------ End Get EmpId Modify : 2024/12/26 -------------------------------------

	--check condition data allocat is null มีข้อมูลหรือเปล่า
	IF @Lotno_Allocat_Count <> 0
	BEGIN
		select @Lot_No = tranlot.[lot_no] 
		,@Package = allocat.Type_Name
		,@ROHM_Model_Name = allocat.ROHM_Model_Name
		,@ASSY_Model_Name = allocat.ASSY_Model_Name
		,@R_Fukuoka_Model_Name = [allocat].[R_Fukuoka_Model_Name]
		,@QtyPass_Standard = tranlot.[qty_pass]
		,@Totalhasuu = (tranlot.[qty_pass])%([device_names].[pcs_per_pack])  -- จำนวนงานเดิมที่มีอยู่รวมกับจำนวน hasuu ที่ส่งค่ามาหารจำนวน standard
		,@Standerd_QTY = CAST([device_names].[pcs_per_pack] AS char(7)) 
		,@qty_out = (tranlot.[qty_pass]/[device_names].[pcs_per_pack])*[device_names].[pcs_per_pack]  -- จำนวนงานเต็ม reel ทั้งหมด
		,@MNo_Standard = allocat.MNo  --mno_standard
		,@TIRank = allocat.TIRank 
		,@Rank = allocat.rank 
		,@TPRank = allocat.TPRank 
		,@SUBRank = allocat.SUBRank 
		,@Pdcd = allocat.PDCD 
		,@Mask = allocat.Mask 
		,@KNo = allocat.KNo
		,@ORNo = allocat.ORNo 
		,@Packing_Standerd_QTY = case when allocat.Packing_Standerd_QTY is null then '-' 
			else allocat.Packing_Standerd_QTY end  
		,@Tomson_Mark_1 = allocat.Tomson1 
		,@Tomson_Mark_2 = allocat.Tomson2 
		,@Tomson_Mark_3 = allocat.Tomson3 
		,@WFLotNo = allocat.WFLotNo 
		,@LotNo_Class = allocat.LotNo_Class 
		,@User_code = allocat.User_Code 
		,@Product_Control_Clas = allocat.Product_Control_Cl_1 
		,@ProductClass = allocat.Product_Class
		,@ProductionClass = allocat.Production_Class 
		,@RankNo = allocat.Rank_No 
		,@HINSYU_Class = allocat.HINSYU_Class 
		,@Label_Class = allocat.Label_Class 
		,@Out_Out_Flag = allocat.OUT_OUT_FLAG 
		,@Allocation_Date  = allocat.allocation_Date
		FROM [APCSProDB].[trans].[lots]  as tranlot
		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = tranlot.[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] as device_names  ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] as packages ON [device_names].[package_id]  = [packages].[id]
		INNER JOIN APCSProDB.method.allocat as allocat ON tranlot.lot_no = allocat.LotNo 
		WHERE tranlot.[lot_no] = @lotno_standard
	END
	ELSE
	BEGIN
		select @Lot_No = tranlot.[lot_no] 
		,@Package = allocat.Type_Name
		,@ROHM_Model_Name = allocat.ROHM_Model_Name
		,@ASSY_Model_Name = allocat.ASSY_Model_Name
		,@R_Fukuoka_Model_Name = [allocat].[R_Fukuoka_Model_Name]
		,@QtyPass_Standard = tranlot.[qty_pass]
		,@Totalhasuu = (tranlot.[qty_pass])%([device_names].[pcs_per_pack])  -- จำนวนงานเดิมที่มีอยู่รวมกับจำนวน hasuu ที่ส่งค่ามาหารจำนวน standard
		,@Standerd_QTY = CAST([device_names].[pcs_per_pack] AS char(7)) 
		,@qty_out = (tranlot.[qty_pass]/[device_names].[pcs_per_pack])*[device_names].[pcs_per_pack]  -- จำนวนงานเต็ม reel ทั้งหมด
		,@MNo_Standard = allocat.MNo  --mno_standard
		,@TIRank = allocat.TIRank 
		,@Rank = allocat.rank 
		,@TPRank = allocat.TPRank 
		,@SUBRank = allocat.SUBRank 
		,@Pdcd = allocat.PDCD 
		,@Mask = allocat.Mask 
		,@KNo = allocat.KNo
		,@ORNo = allocat.ORNo 
		,@Packing_Standerd_QTY = case when allocat.Packing_Standerd_QTY is null then '-' 
			else allocat.Packing_Standerd_QTY end  
		,@Tomson_Mark_1 = allocat.Tomson1 
		,@Tomson_Mark_2 = allocat.Tomson2 
		,@Tomson_Mark_3 = allocat.Tomson3 
		,@WFLotNo = allocat.WFLotNo 
		,@LotNo_Class = allocat.LotNo_Class 
		,@User_code = allocat.User_Code 
		,@Product_Control_Clas = allocat.Product_Control_Cl_1 
		,@ProductClass = allocat.Product_Class
		,@ProductionClass = allocat.Production_Class 
		,@RankNo = allocat.Rank_No 
		,@HINSYU_Class = allocat.HINSYU_Class 
		,@Label_Class = allocat.Label_Class 
		,@Out_Out_Flag = allocat.OUT_OUT_FLAG 
		,@Allocation_Date  = allocat.allocation_Date
		FROM [APCSProDB].[trans].[lots]  as tranlot
		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = tranlot.[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] as device_names  ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] as packages ON [device_names].[package_id]  = [packages].[id]
		INNER JOIN APCSProDB.method.allocat_temp as allocat ON tranlot.lot_no = allocat.LotNo 
		WHERE tranlot.[lot_no] = @lotno_standard
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
		,'EXEC [dbo].[tg_sp_set_label_issue_tg] @empno = ''' + @empno + ''',@lotno_standard = ''' + @lotno_standard + ''',@Total = ''' + CAST(@QtyPass_Standard as varchar(7)) + ''''
		,@lotno_standard


				INSERT INTO [APCSProDWH].[dbo].[MIX_HIST_IF](
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
					,'01' --edit stockclass form 02 is 01 Date 2021/08/20 ,edit stockclass form 01 is 02 Date 2022/03/10 time : 14.35
					,@Package
					,@ROHM_Model_Name
					,@Pdcd
					,@ASSY_Model_Name
					,@R_Fukuoka_Model_Name
					,@TIRank
					,@Rank
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
					,@qty_out -- จำนวนงานของ lot standard ที่หาร reel ลงตัว
					,@op_no_len_value
					,@Out_Out_Flag
					,GETDATE()
					,CURRENT_TIMESTAMP --timestamp_date
					,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
				);

				--insrt into table LSI_SHIP to DB-IS
				INSERT INTO [APCSProDWH].[dbo].[LSI_SHIP_IF](
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
						,@QtyPass_Standard -- qty lot standard
						,'' -- qty hasuu_lotno ตัวที่ 1
						,'' -- qty hasuu_lotno ตัวที่ 2
						,'' -- qty hasuu_lotno ตัวที่ 3
						,0 -- จำนวนงาน shipment_qty , fix data = 0 >>2022/11/30 , Time : 14.00<<
						,@QtyPass_Standard -- จำนวนงานทั้งหมด
						,''
						,''
						,@Out_Out_Flag
						,'01' --edit stockclass form 01 is 02 Date 2022/03/10 time : 14.35
						,'2'
						,@Allocation_Date
						,'' -- delete_flage
						,@op_no_len_value --opno
						,CURRENT_TIMESTAMP --timestamp_date
						,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
				);

				--insert into DB-IS
				INSERT INTO [APCSProDWH].[dbo].[H_STOCK_IF](
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
					 '01' --edit stockclass form 01 is 02 Date 2022/03/10 time : 14.35
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
					,'1' --DMY_IN_FLAG , Fix data = 1 >>2022/11/30 , Time : 14.00<<
					,'' --DMY_OUT_FLAG
					,GETDATE()
					,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
					,CURRENT_TIMESTAMP 
					,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				
				);

				--insrt into table WORK_R_DB to DB-IS
				INSERT INTO [APCSProDWH].[dbo].[WORK_R_DB_IF](
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
				INSERT INTO [APCSProDWH].[dbo].[PACKWORK_IF](
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
				INSERT INTO [APCSProDWH].[dbo].[WH_UKEBA_IF](
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
					   '10' --RECORD_CLASS  update : #2024/10/17 time: 11.01 by Aomsin
					  ,@ROHM_Model_Name
					  ,@lotno_standard
					  ,CURRENT_TIMESTAMP --OccurDate
					  ,@R_Fukuoka_Model_Name
					  ,@Rank
					  ,@TPRank
					  ,'0' --RED_BLACK_Flag
					  ,@QtyPass_Standard --@Total
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

			    --INSERT Hasuu TO TABLE tg_sp_set_surpluse
				EXEC [StoredProcedureDB].[atom].[sp_set_label_issued_tg] @lot_no = @lotno_standard
				,@qty_hasuu_brfore = @Hasuu_before
				,@Empno_int_value = @Emp_int
				,@stock_class = '01'  
				,@machine_id_val = @machine_id_val

		    -- UPDATE 2021/03/30
			-- INSERT RECORD CLASS TO TABLE tg_sp_set_surpluse_records
		    BEGIN TRY
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
				,@sataus_record_class = 1
				--,@emp_no_int = @Emp_int 
				,@emp_no_int = @EmpnoId --new --new Modify : 2024/12/26
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status ,'INSERT DATA SURPLUSE_RECORDS ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
			END CATCH

		    -- UPDATE 2021/03/30
			-- INSERT RECORD CLASS TO TABLE lot_combine
			BEGIN TRY
				EXEC [StoredProcedureDB].[atom].[sp_set_tsugitashi_tg] 
				 @master_lot_no = @lotno_standard
				,@hasuu_lot_no = ''
				,@masterqty = @QtyPass_Standard
				,@hasuuqty = 0
				,@OP_No = @Emp_int
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status ,'INSERT DATA LOT_COMBINE ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
			END CATCH

			BEGIN TRY
				-- CREATE 2021/03/09
				-- INSERT DATA IN TABLE LABEL_HISTORY
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @lotno_standard
				,@process_name = 'TP'
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status ,'INSERT DATA LABEL_HISTORY ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
			END CATCH

			BEGIN TRY
				--Set Record Class = 46 is TG Show on web Atom //Date Create : 2022/02/03 Time : 09.10
				EXEC [StoredProcedureDB].[trans].[sp_set_record_class_lot_process_records]
				@lot_no = @lotno_standard
				,@opno = @empno
				,@record_class = 46
				,@mcno = @machine_name
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
				SELECT GETDATE()
					, '4'
					, ORIGINAL_LOGIN()
					, 'StoredProcedureDB'
					, 'TGSYSTEM'
					, 'EXEC [dbo].[tg_sp_set_label_issue_tg Create Record Class TG Error] @lotno_standard = ''' + @lotno_standard 
					, @lotno_standard
			END CATCH

END
