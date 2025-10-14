-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[tg_sp_set_hasuu_A_lot_backup20221208]
	-- Add the parameters for the stored procedure here
	@lotno char(10),
	@empno char(6) = ' ',
	@hasuu_lotno char(10) = ' ',
	@Pdcd char(5) = ' ',
	@MNo_Standard char(10) = ' ',
	@MNo char(10) = ' ',
	@Type_Name char(10) = ' ', 
	@ROHM_Model_Name char(20) = ' ',
	@ASSY_Model_Name char(20) = ' ',
	@R_Fukuoka_Model_Name char(20) = ' ',
	@TIRank char(5) = ' ',
	@TPRank char(5) = ' ',
	@Rank char(5) = ' ',
	@SUBRank char(3) = ' ',
	@Mask char(2) = ' ',
	@KNo char(3) = ' ',
	@Tomson_Mark_1 char(4) = ' ',
	@Tomson_Mark_2 char(4) = ' ',
	@Tomson_Mark_3 char(4) = ' ',
	@ORNo char(12) = ' ',
	@WFLotNo char(20) = ' ',
	@LotNo_Class char(1) = ' ',
	@Product_Control_Clas char(3) = ' ',
	@ProductClass char(1) = ' ',
	@ProductionClass char(1) = ' ',
	@RankNo char(6) = ' ',
	@HINSYU_Class char(1) = ' ',
	@Label_Class char(1) = ' ',
	@Out_Out_Flag char(1) = ' ',
	@QtyPass_Tranlot int = 0,
	@QTY_Lot_Standard int = 0,
	@Hasuu_Stock_QTY int,
	@Total int = 0,
	@Standerd_QTY int = 0,
	@Allocation_Date char(30) = ' '
	

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	--call new store create 2022/12/07 Time : 14.29
	------------------------------------------------------------------------------------------------
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_hasuu_A_lot_new] @lotno = @lotno			
	--,@empno		= @empno				
	--,@hasuu_lotno	= @hasuu_lotno				
	--,@Pdcd	= @Pdcd					
	--,@MNo_Standard	= @MNo_Standard			
	--,@MNo	= @MNo					
	--,@Type_Name		= @Type_Name			
	--,@ROHM_Model_Name	= @ROHM_Model_Name		
	--,@ASSY_Model_Name	= @ASSY_Model_Name	
	--,@R_Fukuoka_Model_Name	= @R_Fukuoka_Model_Name	
	--,@TIRank		= @TIRank				
	--,@TPRank		= @TPRank				
	--,@Rank		= @Rank				
	--,@SUBRank	= @SUBRank				
	--,@Mask		= @Mask				
	--,@KNo		= @KNo				
	--,@Tomson_Mark_1	= @Tomson_Mark_1			
	--,@Tomson_Mark_2	= @Tomson_Mark_2			
	--,@Tomson_Mark_3	= @Tomson_Mark_3			
	--,@ORNo		= @ORNo				
	--,@WFLotNo	= @WFLotNo				
	--,@LotNo_Class	= @LotNo_Class			
	--,@Product_Control_Clas	= @Product_Control_Clas	
	--,@ProductClass	= @ProductClass			
	--,@ProductionClass	= @ProductionClass			
	--,@RankNo		= @RankNo				
	--,@HINSYU_Class	= @HINSYU_Class		
	--,@Label_Class	= @Label_Class			
	--,@Out_Out_Flag	= @Out_Out_Flag		
	--,@QtyPass_Tranlot	= @QtyPass_Tranlot		
	--,@QTY_Lot_Standard	= @QTY_Lot_Standard		
	--,@Hasuu_Stock_QTY	= @Hasuu_Stock_QTY		
	--,@Total				= @Total		
	--,@Standerd_QTY		= @Standerd_QTY		
	--,@Allocation_Date	= @Allocation_Date		
	------------------------------------------------------------------------------------------------

	SET NOCOUNT ON;
	DECLARE @datestart as varchar(50) = cast( GETDATE() as date) 
	--DECLARE @Qty_Full_Reel_All int = (@Standerd_QTY) * ((@QtyPass_Tranlot+@Hasuu_Stock_QTY)/(@Standerd_QTY))
	--DECLARE @Totalhasuu int = SUM(@Hasuu_Stock_QTY)%(@Standerd_QTY)
	DECLARE @Lot_id INT --create 2020/11/23
	DECLARE @Chklottblsiship as varchar(10) = ''
	DECLARE @Chk_Hasuu_Stock_In char(10) = ' '
	DECLARE @r int= 0;
	DECLARE @lot_id_tranlot INT;
	DECLARE @qty_out INT;
	DECLARE @qty_hasuu INT;
	DECLARE @Emp_int INT; --update 2021/02/04
	--add parameter date : 2022/02/02 time : 16.05
	DECLARE @machine_name varchar(15) = ''
	--add parameter date : 2022/12/05 time : 16.00
	DECLARE @Qty_Full_Reel_All int = (@Standerd_QTY) * ((@QtyPass_Tranlot + @Hasuu_Stock_QTY)/(@Standerd_QTY))
	DECLARE @Totalhasuu int = SUM(@Hasuu_Stock_QTY)%(@Standerd_QTY)

    SELECT @Chklottblsiship =  LotNo from DBxDW.TGOG.LSI_SHIP where LotNo = @lotno
	--Search Hasuu in Surpluses
	select @Chk_Hasuu_Stock_In = serial_no from APCSProDB.trans.surpluses where serial_no = @lotno
	select @Lot_id = [id] from APCSProDB.trans.lots where lot_no = @lotno

	select @Emp_int = CONVERT(INT, @empno) --update 2021/02/04

	DECLARE @op_no_len_value char(5) = '';

	select  @op_no_len_value =  case when LEN(CAST(@empno as char(5))) = 4 then '0' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 3 then '00' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 2 then '000' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 1 then '0000' + CAST(@empno as char(5))
			else CAST(@empno as char(5)) end 


	SELECT @lot_id_tranlot = [lots].[id]
	, @qty_out = (([lots].[qty_pass] + @Hasuu_Stock_QTY)/[device_names].[pcs_per_pack])*[device_names].[pcs_per_pack]
	, @qty_hasuu = (@QtyPass_Tranlot + @Hasuu_Stock_QTY)%[device_names].[pcs_per_pack]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	WHERE [lots].[lot_no] = @lotno

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
		,'EXEC [dbo].[tg_sp_set_hasuu_A_lot] @empno = ''' + @empno + ''',@lotno = ''' + @lotno + ''',@QtyPass_Tranlot = ''' + CONVERT (varchar (10), @QtyPass_Tranlot) + ''',@hasuu_lotno = ''' + @hasuu_lotno + ''',@Hasuu_Stock_QTY = ''' + CONVERT (varchar (10), @Hasuu_Stock_QTY) + ''''
		,@lotno

    -- Insert statements for procedure here
	

			--Create 2021/03/19 By : Aomsin
			--Update 2021/03/31 By : Aomsin
			--UPDATE INSTOCK HASUU BEFORE IN TABLE : Surpluse : Instock = 1 is : Location Assing 
			UPDATE APCSProDB.trans.surpluses
			SET in_stock = 0
			,updated_by = 2    --2 = Web TG 
			WHERE serial_no = @hasuu_lotno

			-- INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records >> Date Modify : 2022/07/20 Time : 16.50 <<
			EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @hasuu_lotno
			,@sataus_record_class = 2

			--update qty_pass in tranlot
			UPDATE [APCSProDB].[trans].[lots]
			SET 
				[qty_pass] = @QtyPass_Tranlot  --update 2120/06/22 
			WHERE [lot_no] = @lotno

			-- Check that information is included in the table or not.
			IF @Chk_Hasuu_Stock_In = ''
			BEGIN
				--Edit 2021/03/12 by OOMSIN
				-- insert and update hasuu to tabel [trans].[surpluses]
				EXEC [StoredProcedureDB].[atom].[sp_set_label_issued_tg] @lot_no = @lotno
				,@qty_hasuu_brfore = @Hasuu_Stock_QTY
				,@Empno_int_value = @Emp_int
				,@stock_class = '02'  --update date : 2022/03/10 time : 15.38

			END
			ELSE IF @Chk_Hasuu_Stock_In != ''
			BEGIN
				UPDATE [APCSProDB].[trans].[surpluses]
				SET 
						  [pcs] = @qty_hasuu --change @totalhasuu is @qty_hasuu -->date edit : 2022/01/07
						, [serial_no] = @lotno
						, [in_stock] = '2'
						, [location_id] = NULL
						, [acc_location_id] = NULL
						, [updated_at] = GETDATE()
						, [updated_by] = 2
				WHERE [lot_id] = @Lot_id

				UPDATE [APCSProDB].[trans].[lots]
				SET 
					  [qty_hasuu] = @qty_hasuu
					, [qty_out] = @qty_out
					, [qty_combined] = @Hasuu_Stock_QTY
					--, [wip_state] = '100'
				WHERE [id] = @Lot_id

			END

			-- INSERT RECORD CLASS TO TABLE tg_sp_set_surpluse_records
			EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno
			,@sataus_record_class = 1
			,@emp_no_int = @Emp_int --update 2021/12/07 time : 12.00

			EXEC [StoredProcedureDB].[atom].[sp_set_tsugitashi_tg] 
			 @master_lot_no = @lotno
			,@hasuu_lot_no = @hasuu_lotno
			,@masterqty = @QtyPass_Tranlot
			,@hasuuqty = @Hasuu_Stock_QTY
			,@OP_No = @Emp_int

			BEGIN TRY
				-- CREATE 2021/03/09
				-- INSERT DATA IN TABLE LABEL_HISTORY
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @lotno
				,@process_name = 'TP'
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status ,'INSERT DATA LABEL_HISTORY ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
			END CATCH


			BEGIN TRY
				--Set Record Class = 46 is TG Show on web Atom //Date Create : 2022/02/03 Time : 08.22
				EXEC [StoredProcedureDB].[trans].[sp_set_record_class_lot_process_records]
				@lot_no = @lotno
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
					, 'EXEC [dbo].[tg_sp_set_hasuu_A_lot Create Record Class TG Error] @lotno_standard = ''' + @lotno 
					, @lotno
			END CATCH

			--Set Data To IS Server 2022/12/05 time : 16.00
			BEGIN TRY
				--insert mixhist to IS
				INSERT INTO  [ISDB].[DBLSISHT].[dbo].[MIX_HIST](
				  -- [M_O_No]
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
				  --,[Label_Class]
				  --,[Multi_Class]
				  --,[Product_Control_Clas]
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
					 @lotno
					,@lotno
					,'02' --change stockclass from 01 is 02 date update : 2022/03/10 time : 15.38
					,@Type_Name
					,@ROHM_Model_Name
					,@Pdcd
					,@ASSY_Model_Name
					,@R_Fukuoka_Model_Name
					,@TIRank
					,@rank
					,@TPRank
					,''
					,''
					,''
					,@MNo_Standard
					,''
					,''
					,@Tomson_Mark_3
					,@Allocation_Date
					,@ORNo
					,@WFLotNo
					,''
					,@Standerd_QTY
					,@QTY_Lot_Standard + @Hasuu_Stock_QTY  --total
					,@op_no_len_value 
					,@Out_Out_Flag
					,GETDATE()
					,CURRENT_TIMESTAMP --timestamp_date
					,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
				),
				(
					 @lotno
					,@hasuu_lotno
					,'02' --change stockclass from 01 is 02
					,@Type_Name
					,@ROHM_Model_Name
					,@Pdcd
					,@ASSY_Model_Name
					,@R_Fukuoka_Model_Name
					,@TIRank
					,@rank
					,@TPRank
					,''
					,''
					,''
					,@MNo
					,''
					,''
					,@Tomson_Mark_3
					,@Allocation_Date
					,@ORNo
					,@WFLotNo
					,''
					,@Standerd_QTY
					,@Hasuu_Stock_QTY
					,@op_no_len_value
					,@Out_Out_Flag
					,GETDATE()
					,CURRENT_TIMESTAMP
					,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				);

				--insert into lsi_ship to is
				INSERT INTO  [ISDB].[DBLSISHT].[dbo].[LSI_SHIP](
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
					 @lotno
					,@Type_Name
					,@ROHM_Model_Name
					,@ASSY_Model_Name
					,@R_Fukuoka_Model_Name
					,@TIRank
					,@rank
					,@TPRank
					,'' --sub_rank
					,@Pdcd
					,'' --mask
					,'' --kno
					,@MNo_Standard -- mno_standard
					,@ORNo
					,@Standerd_QTY
					,''
					,''
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
					,@lotno --standard_lotno
					,@hasuu_lotno -- hasuu_lotno ตัวที่ 1
					,'' -- hasuu_lotno ตัวที่ 2 ถ้ามี
					,'' -- hasuu_lotno ตัวที่ 3 ถ้ามี
					,@MNo_Standard -- Mno Standard
					,@MNo -- Mno_hsuu ตัวที่ 1 ถ้ามี
					,'' -- Mno_hsuu ตัวที่ 2 ถ้ามี
					,'' -- Mno_hsuu ตัวที่ 3 ถ้ามี
					,@QTY_Lot_Standard -- qty lot standard
					,@Hasuu_Stock_QTY -- qty hasuu_lotno ตัวที่ 1
					,'' -- qty hasuu_lotno ตัวที่ 2
					,'' -- qty hasuu_lotno ตัวที่ 3
					,@Qty_Full_Reel_All -- จำนวนงานทั้งหมดที่พอดี reel หรือ Shipment_qty 
					--,0 -- จำนวนงานทั้งหมดที่พอดี reel หรือ Shipment_qty , Fix Data is 0 wait edit program apcspro >>2022/11/30 , Time : 13.32<<
					,@Total -- จำนวนงานทั้งหมด
					,''
					,''
					,@Out_Out_Flag
					,'02' --change stockclass from 01 is 02
					,'2'
					,@Allocation_Date --allocate
					,'' -- delete_flage
					,@op_no_len_value
					,CURRENT_TIMESTAMP 
					,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				);

				--insert to table h_stock is
				INSERT INTO  [ISDB].[DBLSISHT].[dbo].[H_STOCK](
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
					 '02' --change stockclass from 01 is 02
					,@Pdcd
					,@lotno
					,@Type_Name
					,@ROHM_Model_Name
					,@ASSY_Model_Name
					,@R_Fukuoka_Model_Name
					,@TIRank
					,@rank
					,@TPRank
					,''
					,''
					,''
					--,@MNo_Standard
					,@MNo_Standard -- Mno Standard
					,@ORNo
					,@Standerd_QTY
					,''
					,''
					,@Tomson_Mark_3
					,@WFLotNo
					,''
					,'' --user_code
					,@Product_Control_Clas
					,@ProductClass
					,@ProductionClass
					,@RankNo
					,@HINSYU_Class
					,@Label_Class
					,@qty_hasuu  --HasuuStockQTY
					,'0' --hasuu_wip_qty
					,''
					,@Out_Out_Flag --out_out_flag
					,''
					,@op_no_len_value
					,'' --DMY_IN_FLAG
					--,'1' --DMY_IN_FLAG , Fix data = 1 wait edit program apcspro >>2022/11/30 , Time : 13.32<<
					,'' --DMY_OUT_FLAG
					,GETDATE()
					,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
					,CURRENT_TIMESTAMP 
					,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				);

				--insrt into table WORK_R_DB to DB-IS
				INSERT INTO  [ISDB].[DBLSISHT].[dbo].[WORK_R_DB](
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
				  @lotno
				  ,1001 --process_no --1001 = tg
				  ,CURRENT_TIMESTAMP --Process_Date
				  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --Process_Time
				  ,'0'
				  ,@QtyPass_Tranlot --จำนวน standard ใน column qty_pass to table : tranlot
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
				INSERT INTO  [ISDB].[DBLSISHT].[dbo].[PACKWORK](
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
				   @lotno
				  ,@Type_Name
				  ,@ROHM_Model_Name
				  ,@R_Fukuoka_Model_Name
				  ,@Rank
				  ,@TPRank
				  ,@Pdcd
				  ,@QtyPass_Tranlot
				  ,@ORNo
				  ,@op_no_len_value --opno
				  ,''
				  ,CURRENT_TIMESTAMP --timestamp_date
				  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
				  ,''
				)

				-- insert into table WH_UKEBA to DB-IS
				INSERT INTO  [ISDB].[DBLSISHT].[dbo].[WH_UKEBA](
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
					,@lotno
					,CURRENT_TIMESTAMP --OccurDate
					,@R_Fukuoka_Model_Name
					,@Rank
					,@TPRank
					,'0' --RED_BLACK_Flag
					,@QTY_Lot_Standard + @Hasuu_Stock_QTY  --total
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

				UPDATE  [ISDB].[DBLSISHT].[dbo].[H_STOCK]
				SET DMY_OUT_Flag = '1'
				,Timestamp_Date = GETDATE()
				WHERE LotNo = @hasuu_lotno

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
					, 'EXEC [dbo].[tg_sp_set_hasuu_A_lot Insert Data TG to IS Server Error] @lotno_standard = ''' + @lotno 
					, @lotno
			END CATCH

END
