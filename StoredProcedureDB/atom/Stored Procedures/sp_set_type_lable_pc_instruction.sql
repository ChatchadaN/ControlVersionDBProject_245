-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_type_lable_pc_instruction]	
	-- Add the parameters for the stored procedure here
		@lotno_standard varchar(10) ,
		@lotno_standard_qty INT ,
		@empno VARCHAR(10) ,
		@pc_instruction_val INT,

		@reel  NVARCHAR(MAX) ,
		@Hasuu_qty  INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Lotno_Allocat_Count Int = 0
	DECLARE @Lot_No char(10) = ' '
	DECLARE @Package char(10) = ' '
	DECLARE @ROHM_Model_Name char(20) = ' '
	DECLARE @ASSY_Model_Name char(20) = ' '
	DECLARE @R_Fukuoka_Model_Name char(20) = ' '
	DECLARE @TIRank char(5) = ' '
	DECLARE @Rank char(5) = ' '
	DECLARE @TPRank char(3) = ' '
	DECLARE @SUBRank char(3) = ' '
	DECLARE @Mask char(2) = ' '
	DECLARE @KNo char(3) = ' '
	DECLARE @Out_Out_Flag char(1) = ' '
	DECLARE @Allocation_Date char(30) = ' '
	DECLARE @MNo_Standard char(10) = ' '
	DECLARE @Pdcd char(5) = ' '
	DECLARE @ORNo char(12) = ' '
	DECLARE @Tomson_Mark_1 char(4) = ' '
	DECLARE @Tomson_Mark_2 char(4) = ' '
	DECLARE @Tomson_Mark_3 char(4) = ' '
	DECLARE @WFLotNo char(20) = ' '
	DECLARE @LotNo_Class char(1) = ' '
	DECLARE @Product_Control_Clas char(3) = ' '
	DECLARE @ProductClass char(1) = ' '
	DECLARE @ProductionClass char(1) = ' '
	DECLARE @Label_Class char(1) = ' '
	DECLARE @is_pc_instruction_code int = 0
	DECLARE @pcs_per_pack_int int = 0
	DECLARE @QtyPass_Standard int
	DECLARE @Total int
	DECLARE @Totalhasuu int 
	DECLARE @Standerd_QTY char(7) = ' '
	DECLARE @Qty_Full_Reel_All int
	DECLARE @Qty_Standard_Lsiship int
	DECLARE @Emp_int INT; 
	DECLARE @Lot_Id INT; 
	DECLARE @RankNo char(6) = ' '
	DECLARE @HINSYU_Class char(1) = ' '
	DECLARE @datestart as varchar(50) = cast( GETDATE() as date) 
	DECLARE @User_code char(6) = ' '
	DECLARE @r int= 0;
	
    -- Insert statements for procedure here	
	IF @reel = NULL or @reel = ''
	BEGIN
			-- Update pc_instruction_code
			UPDATE APCSProDB.trans.lots
	        SET pc_instruction_code = @pc_instruction_val	
			,[updated_at] = GETDATE()
	        ,[updated_by] = @empno 
	        WHERE lot_no = @lotno_standard
	
			-- Insert History
			EXEC [StoredProcedureDB].[trans].[sp_set_record_class_lot_process_records] 
				@lot_no  = @lotno_standard
				 , @opno = @empno
				 , @record_class = 121
				 , @mcno = '-1'
	END
	ELSE
	BEGIN
	
	SELECT @Lotno_Allocat_Count = COUNT(*) FROM APCSProDB.method.allocat where LotNo = @lotno_standard
	
		IF @Lotno_Allocat_Count != 0
		BEGIN
				select @Lot_No = [lots].[lot_no] 
				,@Package = [packages].[short_name]
				,@ROHM_Model_Name = [device_names].[name] 
				,@ASSY_Model_Name =  [device_names].[assy_name] 
				--,@R_Fukuoka_Model_Name = REVERSE(SUBSTRING(REVERSE([device_names].[name]), CHARINDEX('-',  REVERSE([device_names].[name])) + 1,LEN([device_names].[name]))) 
				,@R_Fukuoka_Model_Name = allocat.R_Fukuoka_Model_Name --change date : 2022/02/18 time : 11.14
				,@TIRank = case when allocat.TIRank is null then '' else allocat.TIRank end
				,@Rank = case when [device_names].[rank] is null then ''  else [device_names].[rank] end
				,@TPRank = case when [device_names].[tp_rank] is null then ''  else [device_names].[tp_rank] end
				,@SUBRank = allocat.SUBRank
				,@Mask = Mask
				,@KNo = KNo
				,@QtyPass_Standard = [lots].[qty_pass]
				,@Total = @lotno_standard_qty
				
				,@Totalhasuu = @Hasuu_qty
				,@Standerd_QTY = CAST([device_names].[pcs_per_pack] AS char(7))					
				,@Qty_Full_Reel_All = ([device_names].[pcs_per_pack]) * ((@lotno_standard_qty)/([device_names].[pcs_per_pack])) -- จำนวนงานเต็ม reel ทั้งหมด
				,@Qty_Standard_Lsiship =  (([device_names].[pcs_per_pack]) * ((@lotno_standard_qty)/([device_names].[pcs_per_pack]))) 	
		
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
				,@is_pc_instruction_code = case when [lots].[pc_instruction_code] is null or [lots].[pc_instruction_code] = ''  then 0 else [lots].[pc_instruction_code] end
		
				,@pcs_per_pack_int = pcs_per_pack 
				--,@pcs_per_pack_int = case when @is_ajd_qty_standard_tube = 0 then pcs_per_pack else @is_ajd_qty_standard_tube end
				from [APCSProDB].[method].[package_groups] with (NOLOCK) 
					inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[package_group_id] = [package_groups].[id]
					inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[package_id] = [packages].[id]
					inner join [APCSProDB].[trans].[lots] with (NOLOCK) 
						on [lots].[act_device_name_id] = [device_names].[id]
				inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
				inner join [APCSProDB].[method].[allocat] as allocat on allocat.LotNo = @lotno_standard
				where lot_no = @lotno_standard
		END
		ELSE
		BEGIN
			select @Lot_No = [lots].[lot_no] 
				,@Package = [packages].[short_name]
				,@ROHM_Model_Name = [device_names].[name] 
				,@ASSY_Model_Name =  [device_names].[assy_name] 
				--,@R_Fukuoka_Model_Name = REVERSE(SUBSTRING(REVERSE([device_names].[name]), CHARINDEX('-',  REVERSE([device_names].[name])) + 1,LEN([device_names].[name])))
				,@R_Fukuoka_Model_Name = allocat.R_Fukuoka_Model_Name --change date : 2022/02/18 time : 11.14
				,@TIRank = case when allocat.TIRank is null then '' else allocat.TIRank end
				,@Rank = case when [device_names].[rank] is null then ''  else [device_names].[rank] end
				,@TPRank = case when [device_names].[tp_rank] is null then ''  else [device_names].[tp_rank] end
				,@SUBRank = allocat.SUBRank
				,@Mask = Mask
				,@KNo = KNo
				,@QtyPass_Standard = [lots].[qty_pass]
				,@Total = @lotno_standard_qty
			
				,@Totalhasuu = @Hasuu_qty
				,@Standerd_QTY = CAST([device_names].[pcs_per_pack] AS char(7))					
				,@Qty_Full_Reel_All = ([device_names].[pcs_per_pack]) * ((@lotno_standard_qty)/([device_names].[pcs_per_pack])) -- จำนวนงานเต็ม reel ทั้งหมด
				,@Qty_Standard_Lsiship =  (([device_names].[pcs_per_pack]) * ((@lotno_standard_qty)/([device_names].[pcs_per_pack]))) 
				
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
				,@is_pc_instruction_code = case when [lots].[pc_instruction_code] is null or [lots].[pc_instruction_code] = '' then 0 else [lots].[pc_instruction_code] end
				
				,@pcs_per_pack_int =  pcs_per_pack
				--,@pcs_per_pack_int = case when @is_ajd_qty_standard_tube = 0 then pcs_per_pack else @is_ajd_qty_standard_tube end
				from [APCSProDB].[method].[package_groups] with (NOLOCK) 
					inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[package_group_id] = [package_groups].[id]
					inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[package_id] = [packages].[id]
					inner join [APCSProDB].[trans].[lots] with (NOLOCK) 
						on [lots].[act_device_name_id] = [device_names].[id]
				inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
				inner join [APCSProDB].[method].[allocat_temp] as allocat on allocat.LotNo = @lotno_standard
				where lot_no = @lotno_standard
		END
	
		select @Emp_int = CONVERT(INT, @empno) 
		DECLARE @op_no_len_value char(5) = '';
	
		select  @op_no_len_value =  case when LEN(CAST(@empno as char(5))) = 4 then '0' + CAST(@empno as char(5))
				when LEN(CAST(@empno as char(5))) = 3 then '00' + CAST(@empno as char(5))
				when LEN(CAST(@empno as char(5))) = 2 then '000' + CAST(@empno as char(5))
				when LEN(CAST(@empno as char(5))) = 1 then '0000' + CAST(@empno as char(5))
				else CAST(@empno as char(5)) end 
	
		select @Lot_Id = id from APCSProDB.trans.lots where lot_no = @lotno_standard
	
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		([record_at]
	      , [record_class]
	      , [login_name]
	      , [hostname]
	      , [appname]
	      , [command_text]
		  , [lot_no] )
		SELECT GETDATE()
			,'4'
			,ORIGINAL_LOGIN()
			,HOST_NAME()
			,APP_NAME()
			,'[atom].[sp_set_sample_lot_new] @empno = ''' + @empno + ''',@lotno_standard = ''' + @lotno_standard + ''',@lotno_standard_qty = ''' + CONVERT (varchar (10), @lotno_standard_qty) + ''',@PC_Instruction_Code = ''' + CONVERT (varchar (3), @pc_instruction_val) + ''',@reel = '''+ @reel +''',@Hasuu_qty = '''+@Hasuu_qty+''''
			,@lotno_standard
	
	
			----insert into table LSI_SHIP to DB-IS
			--INSERT INTO [APCSProDWH].[dbo].[LSI_SHIP_IF] (
			--	   [LotNo]
			--	  ,[Type_Name]
			--	  ,[ROHM_Model_Name]
			--	  ,[ASSY_Model_Name]
			--	  ,[R_Fukuoka_Model_Name]
			--	  ,[TIRank]
			--	  ,[Rank]
			--	  ,[TPRank]
			--	  ,[SUBRank]
			--	  ,[PDCD]
			--	  ,[Mask]
			--	  ,[KNo]
			--	  ,[MNo]
			--	  ,[ORNo]
			--	  ,[Packing_Standerd_QTY]
			--	  ,[Tomson1]
			--	  ,[Tomson2]
			--	  ,[Tomson3]
			--	  ,[WFLotNo]
			--	  ,[LotNo_Class]
			--	  ,[User_Code]
			--	  ,[Product_Control_Clas]
			--	  ,[Product_Class]
			--	  ,[Production_Class]
			--	  ,[Rank_No]
			--	  ,[HINSYU_Class]
			--	  ,[Label_Class]
			--	  ,[Standard_LotNo]
			--	  ,[Complement_LotNo_1]
			--	  ,[Complement_LotNo_2]
			--	  ,[Complement_LotNo_3]
			--	  ,[Standard_MNo]
			--	  ,[Complement_MNo_1]
			--	  ,[Complement_MNo_2]
			--	  ,[Complement_MNo_3]
			--	  ,[Standerd_QTY]
			--	  ,[Complement_QTY_1]
			--	  ,[Complement_QTY_2]
			--	  ,[Complement_QTY_3]
			--	  ,[Shipment_QTY]
			--	  ,[Good_Product_QTY]
			--	  ,[Used_Fin_Packing_QTY]
			--	  ,[HASUU_Out_Flag]
			--	  ,[OUT_OUT_FLAG]
			--	  ,[Stock_Class]
			--	  ,[Label_Confirm_Class]
			--	  ,[allocation_Date]
			--	  ,[Delete_Flag]
			--	  ,[OPNo]
			--	  ,[Timestamp_Date]
			--	  ,[Timestamp_Time]
			--	 )
			--		VALUES (					
			--			 @lotno_standard
			--			,@Package
			--			,@ROHM_Model_Name
			--			,@ASSY_Model_Name
			--			,@R_Fukuoka_Model_Name
			--			,@TIRank
			--			,@rank
			--			,@TPRank
			--			,@SUBRank --sub_rank
			--			,@Pdcd
			--			,@Mask --mask
			--			,@KNo --kno
			--			,@MNo_Standard
			--			,@ORNo
			--			,@Standerd_QTY
			--			,'' --tomson_1
			--			,'' --tomson_2
			--			,@Tomson_Mark_3
			--			,@WFLotNo
			--			,'' --lotno_class
			--			,'' --user_code
			--			,@Product_Control_Clas
			--			,@ProductClass
			--			,@ProductionClass
			--			,@RankNo
			--			,@HINSYU_Class
			--			,@Label_Class
			--			,@lotno_standard --standard_lotno
			--			,'' -- hasuu_lotno ตัวที่ 1
			--			,'' -- hasuu_lotno ตัวที่ 2 ถ้ามี
			--			,'' -- hasuu_lotno ตัวที่ 3 ถ้ามี
			--			,@MNo_Standard
			--			,'' -- Mno_hsuu ตัวที่ 1 ถ้ามี
			--			,'' -- Mno_hsuu ตัวที่ 2 ถ้ามี
			--			,'' -- Mno_hsuu ตัวที่ 3 ถ้ามี
			--			,@lotno_standard_qty -- qty lot standard
			--			,'' -- qty hasuu_lotno ตัวที่ 1
			--			,'' -- qty hasuu_lotno ตัวที่ 2
			--			,'' -- qty hasuu_lotno ตัวที่ 3
			--			,0 -- จำนวนงานทั้งหมดที่พอดี reel , Shipment_QTY fix = 0  >>2022/11/30 , Time : 15.35<<
			--			,@Total -- จำนวนงานทั้งหมด
			--			,''
			--			,''
			--			,@Out_Out_Flag
			--			,'02'  
			--			,'2'
			--			,@Allocation_Date
			--			,'' -- delete_flage
			--			,@op_no_len_value --opno
			--			,CURRENT_TIMESTAMP --timestamp_date
			--			,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
			--	);
	
				----insrt into table WORK_R_DB to DB-IS
				--INSERT INTO [APCSProDWH].[dbo].[WORK_R_DB_IF] (
				--	   [LotNo]
				--	  ,[Process_No]
				--	  ,[Process_Date]
				--	  ,[Process_Time]
				--	  ,[Back_Process_No]
				--	  ,[Good_QTY]
				--	  ,[NG_QTY]
				--	  ,[NG_QTY1]
				--	  ,[Cause_Code_of_NG1]
				--	  ,[NG_QTY2]
				--	  ,[Cause_Code_of_NG2]
				--	  ,[NG_QTY3]
				--	  ,[Cause_Code_of_NG3]
				--	  ,[NG_QTY4]
				--	  ,[Cause_Code_of_NG4]
				--	  ,[Shipment_QTY]
				--	  ,[OPNo]
				--	  ,[TERM_ID]
				--	  ,[TimeStamp_Date]
				--	  ,[TimeStamp_Time]
				--	  ,[Send_Flag]
				--	  ,[Making_Date]
				--	  ,[Making_Time]
				--	  ,[SEQNO_SQL10]
				--   )
				--   VALUES(
				--	  @lotno_standard
				--	  ,1001 --process_no --1001 = tg
				--	  ,CURRENT_TIMESTAMP --Process_Date
				--	  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --Process_Time
				--	  ,'0'
				--	  ,@lotno_standard_qty --จำนวน standard ใน column qty_pass to table : tranlot
				--	  ,'0' --ng qty
				--	  ,'0' --ng_qty1
				--	  ,' '
				--	  ,'0'
				--	  ,' '
				--	  ,'0'
				--	  ,' '
				--	  ,'0'
				--	  ,' '
				--	  ,'0' --shipment_qty
				--	  ,@op_no_len_value --opno
				--	  ,'0' --time_id
				--	  ,CURRENT_TIMESTAMP --timestamp_date
				--	  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
				--	  ,''
				--	  ,''
				--	  ,''
				--	  ,''
				--   )
	
				----insrt into table PACKWORK to DB-IS
				--INSERT INTO [APCSProDWH].[dbo].[PACKWORK_IF] (
				--	   [LotNo]
				--	  ,[Type_Name]
				--	  ,[ROHM_Model_Name]
				--	  ,[R_Fukuoka_Model_Name]
				--	  ,[Rank]
				--	  ,[TPRank]
				--	  ,[PDCD]
				--	  ,[Quantity]
				--	  ,[ORNo]
				--	  ,[OPNo]
				--	  ,[Delete_Flag]
				--	  ,[Timestamp_Date]
				--	  ,[Timestamp_time]
				--	  ,[SEQNO]
				--   )
				--   VALUES(
				--	   @lotno_standard
				--	  ,@Package
				--	  ,@ROHM_Model_Name
				--	  ,@R_Fukuoka_Model_Name
				--	  ,@Rank
				--	  ,@TPRank
				--	  ,@Pdcd
				--	  ,@lotno_standard_qty --qty
				--	  ,@ORNo
				--	  ,@op_no_len_value --opno
				--	  ,''
				--	  ,CURRENT_TIMESTAMP --timestamp_date
				--	  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
				--	  ,''
				--   )
	
				---- insert into table WH_UKEBA to DB-IS
				--INSERT INTO [APCSProDWH].[dbo].[WH_UKEBA_IF] (
				--		   [Record_Class]
				--		  ,[ROHM_Model_Name]
				--		  ,[LotNo]
				--		  ,[OccurDate]
				--		  ,[R_Fukuoka_Model_Name]
				--		  ,[Rank]
				--		  ,[TPRank]
				--		  ,[RED_BLACK_Flag]
				--		  ,[QTY]
				--		  ,[StockQTY]
				--		  ,[Warehouse_Code]
				--		  ,[ORNo]
				--		  ,[OPNO]
				--		  ,[PROC1]
				--		  ,[Making_Date_Date]
				--		  ,[Making_Date_Time]
				--		  ,[Data__send_Flag]
				--		  ,[Delete_Flag]
				--		  ,[TimeStamp_date]
				--		  ,[TimeStamp_time]
				--		  ,[SEQNO]
				--   )
				--   VALUES(
				--		   '' --RECORD_CLASS
				--		  ,@ROHM_Model_Name
				--		  ,@lotno_standard
				--		  ,CURRENT_TIMESTAMP --OccurDate
				--		  ,@R_Fukuoka_Model_Name
				--		  ,@Rank
				--		  ,@TPRank
				--		  ,'0' --RED_BLACK_Flag
				--		  ,@Total
				--		  ,'0' --STOCK_QTY
				--		  ,@Pdcd --WAREHOUSECODE
				--		  ,@ORNo
				--		  ,@op_no_len_value --OPNO
				--		  ,'1' --PROC1
				--		  ,CURRENT_TIMESTAMP --timestamp_date
				--		  ,'' --Making_Date_Time
				--		  ,'' --DATA_SEND_FLAG
				--		  ,'' --DELETE_FLAG
				--		  ,CURRENT_TIMESTAMP --timestamp_date
				--		  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
				--		  ,'' --SEQNO
				--   )
	
	
			--insert table : surpluse HASUU WIP 70
			BEGIN
			INSERT INTO [APCSProDB].[trans].[surpluses]
	           ([id]
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
			   , [user_code]
			   , [product_control_class]
			   , [product_class]
			   , [production_class]
			   , [rank_no]
			   , [hinsyu_class]
			   , [label_class]
			   , [stock_class]
			   )
				--SELECT [nu].[id] - 1 + row_number() over (order by [surpluses].[id]) AS id
				SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
				, @Lot_Id AS lot_id
				, @lotno_standard_qty AS pcs
				, @lotno_standard AS serial_no
				, '0' AS in_stock --เนื่องจากเป็นงาน shipment hasuu ไปด้วย instock จึงเป็น 0
				, NULL AS location_id
				, NULL AS acc_location_id
				, GETDATE() AS created_at
				, @Emp_int AS created_by
				, GETDATE() AS updated_at
				, @Emp_int AS updated_by
				, @Pdcd
				, @Tomson_Mark_3
				, @MNo_Standard
				, @User_code
				, @Product_Control_Clas
				, @ProductClass
				, @ProductionClass
				, @RankNo
				, @HINSYU_Class
				, @Label_Class
				, '02' --stock class val 02 = TG
				FROM [APCSProDB].[trans].[surpluses]
				INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'surpluses.id'
	
				set @r = @@ROWCOUNT
				update [APCSProDB].[trans].[numbers]
				set id = id + @r 
				from [APCSProDB].[trans].[numbers]
				where name = 'surpluses.id'
			END
	
				-- INSERT Surpluse_records
				BEGIN TRY
					EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
					,@sataus_record_class = 1
					,@emp_no_int = @Emp_int 
				END TRY
				BEGIN CATCH 
					SELECT 'FALSE' AS Is_Pass ,'INSERT DATA SURPLUSE_RECORDS ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
				END CATCH
	
				-- Update pc_instruction_code
				BEGIN TRY
					UPDATE APCSProDB.trans.lots
					SET pc_instruction_code = @pc_instruction_val	
					,[updated_at] = GETDATE()
					,[updated_by] = @empno 
					WHERE lot_no = @lotno_standard
	
					-- Insert History
					EXEC [StoredProcedureDB].[trans].[sp_set_record_class_lot_process_records] 
						@lot_no  = @lotno_standard
						 , @opno = @empno
						 , @record_class = 121
						 , @mcno = '-1'
					END TRY
				BEGIN CATCH 
					SELECT 'FALSE' AS Is_Pass ,'UPDATE DATA pc_instruction_code ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
				END CATCH
	
				-- INSERT lot_combine
				BEGIN TRY
					EXEC [StoredProcedureDB].[atom].[sp_set_tsugitashi_tg] 
					 @master_lot_no = @lotno_standard
					,@hasuu_lot_no = ''
					,@masterqty = @lotno_standard_qty
					,@hasuuqty = 0
					,@OP_No = @Emp_int
				END TRY
				BEGIN CATCH 
					SELECT 'FALSE' AS Is_Pass ,'INSERT DATA LOT_COMBINE ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
				END CATCH
	
				-- INSERT DATA IN TABLE LABEL_HISTORY
				BEGIN TRY
					EXEC [StoredProcedureDB].[atom].[sp_set_label_issus_records] 
					@pc_instruction_code = @pc_instruction_val
					,@updated_by = @empno
					,@lot_no_value = @lotno_standard
					,@reel = @reel
					,@Hasuu_qty = @Hasuu_qty
					,@QTYALL = @lotno_standard_qty
				END TRY
				BEGIN CATCH 
					SELECT 'FALSE' AS Is_Pass ,'INSERT DATA LABEL_HISTORY ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
				END CATCH
	
				-- Return data set lot sample
				--BEGIN TRY
				--	SELECT 'TRUE' AS Status ,'SET DATA LOT SAMPLE SUCCESS !!' AS Error_Message_ENG,N'บันทึกข้อมูลสำเร็จ !!' AS Error_Message_THA 
				--	RETURN
				--END TRY
				--BEGIN CATCH 
				--	SELECT 'FALSE' AS Status ,'SET DATA LOT SAMPLE ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA 
				--	RETURN
				--END CATCH
	
				BEGIN TRY
					SELECT 'TRUE' AS Is_Pass, 'Successed !!' AS Error_Message_ENG, N'บันทึกข้อมูลเรียบร้อย.' AS Error_Message_THA,N' กรุณาติดต่อ System'  AS Handling	
				END TRY
	
				BEGIN CATCH
					ROLLBACK;
					SELECT 'FALSE' AS Is_Pass, 'Update Faild !!' AS Error_Message_ENG, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA,N' กรุณาติดต่อ System'  AS Handling
				END CATCH
	
		END
	END
	