-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create 2021/06/13,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_data_pc_request]
	-- Add the parameters for the stored procedure here
	 @newlot varchar(10)
	,@lot_hasuu varchar(10)
	,@new_qty int
	,@hasuu_qty int
	,@out_out_flag char(5) = ' '
	,@empno char(6) = ' '
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Emp_int INT;
	DECLARE @LotNo varchar(10) =''
	DECLARE @StockClass char(2) ='' 
	DECLARE @Pdcd char(5) =''
	DECLARE @Package char(20) = ''
	DECLARE @LotNo_H_Stock char(10) =''
	DECLARE @HASU_Stock_QTY int
	DECLARE @Packing_Standerd_QTY_H_Stock int
	DECLARE @Qty_Full_Reel_All int
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
	DECLARE @Standerd_QTY int
	DECLARE @datestart as varchar(50) = cast( GETDATE() as date) 
	DECLARE @r int= 0;
	DECLARE @lot_id INT;
    -- Insert statements for procedure here
	select @Emp_int = CONVERT(INT, @empno) --update 2021/02/04

	DECLARE @op_no_len_value char(5) = '';

	select  @op_no_len_value =  case when LEN(CAST(@empno as char(5))) = 4 then '0' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 3 then '00' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 2 then '000' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 1 then '0000' + CAST(@empno as char(5))
			else CAST(@empno as char(5)) end 

	select 
	 @StockClass = Stock_Class
	,@LotNo_H_Stock = sur.serial_no
	,@Package = pk.short_name
	,@Pdcd = h_stock.PDCD
	,@HASU_Stock_QTY = sur.pcs 
	,@Packing_Standerd_QTY_H_Stock = dn.pcs_per_pack
	,@ROHM_Model_Name = dn.name
	,@ASSY_Model_Name = ASSY_Model_Name
	,@R_Fukuoka_Model_Name = R_Fukuoka_Model_Name
	,@TIRank = TIRank
	,@Rank_H_Stock = dn.rank
	,@TPRank = TPRank
	,@SUBRank = SUBRank
	,@Mask = Mask
	,@KNo = KNo
	,@Tomson_Mark_1 = Tomson_Mark_1
	,@Tomson_Mark_2 = Tomson_Mark_2
	,@Tomson_Mark_3 = Tomson_Mark_3
	,@ORNo = ORNo
	,@MNo = h_stock.MNo
	,@WFLotNo = WFLotNo
	,@LotNo_Class = LotNo_Class
	,@Label_Class = Label_Class
	,@Product_Control_Clas = Product_Control_Clas
	,@ProductClass = Product_Class
	,@ProductionClass = Production_Class
	,@RankNo = Rank_No
	,@HINSYU_Class = HINSYU_Class
	,@Out_Out_Flag = OUT_OUT_FLAG
	from APCSProDB.trans.surpluses as sur
	inner join APCSProDB.trans.lots as lot on sur.lot_id = lot.id
	inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	left join [DBxDW].[TGOG].[Temp_H_STOCK] as h_stock on h_stock.LotNo  COLLATE Latin1_General_CI_AS = sur.serial_no COLLATE Latin1_General_CI_AS
	where serial_no = @lot_hasuu
	and sur.in_stock != '0' 
	and sur.updated_at  >= (getdate() - 1095)
	and sur.pcs != '0'
	order by SUBSTRING(sur.serial_no,5,1) asc


			--insert data tabel mixhist to db-is
			INSERT INTO OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[MIX_HIST](
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
				@newlot
				,@newlot
				,'01'
				,@Package
				,@ROHM_Model_Name
				,@Pdcd
				,@ASSY_Model_Name
				,@R_Fukuoka_Model_Name
				,@TIRank
				,@Rank_H_Stock --Rank
				,@TPRank
				,''
				,''
				,''
				,'MX'--@MNo
				,''
				,''
				,@Tomson_Mark_3
				,GETDATE()
				,'NO' --ORNO
				,@WFLotNo
				,@LotNo_Class
				,@Label_Class
				,@Product_Control_Clas
				,@Packing_Standerd_QTY_H_Stock
				,@new_qty
				,@op_no_len_value
				,@out_out_flag
				,GETDATE()
				,CURRENT_TIMESTAMP
			    ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			);

			--insert daTA tabel mixhist lotno select to db-is
			INSERT INTO OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[MIX_HIST] (
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
			  ,[Label_Class]
			  --,[Multi_Class]
			  ,[Product_Control_Clas]
			  ,[Packing_Standerd_QTY]
			  --,[Date_Code]
			  --,[HASUU_Out_Flag]
			  ,[QTY]
			  ,[Transfer_Flag]
			  ,[Transfer]
			  ,[OPNo]
			  --,[Theoretical]
			  ,[OUT_OUT_FLAG]
			  ,[MIXD_DATE]
			  ,[TimeStamp_date]
			  ,[TimeStamp_time]
			  )
			SELECT 
				@newlot
				,sur.serial_no
				,'01'
				,Type_Name
				,ROHM_Model_Name
				,h_stock.PDCD
				,ASSY_Model_Name
				,R_Fukuoka_Model_Name
				,TIRank
				,Rank
				,TPRank
				,'' --sub_rank
				,'' --mask
				,'' --kno
				,MNo
				,''
				,''
				,Tomson_Mark_3
				,GETDATE()
				,'NO' --ORNO
				,WFLotNo
				,'' --lotno_class
				,Label_Class
				,Product_Control_Clas
				,CAST(Packing_Standerd_QTY AS char(7)) AS Packing_Standerd_QTY
				,@new_qty
				,'1'
				,sur.pcs - @new_qty
				,@op_no_len_value
				,@out_out_flag
				,GETDATE()
				,CURRENT_TIMESTAMP
			    ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			from APCSProDB.trans.surpluses as sur
			left join [DBxDW].[TGOG].[Temp_H_STOCK] as h_stock on h_stock.LotNo  COLLATE Latin1_General_CI_AS = sur.serial_no COLLATE Latin1_General_CI_AS
			where serial_no = @lot_hasuu

			--insert data tabel lsi_ship to db-is
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
					 @newlot
					,@package
					,@ROHM_Model_Name
					,@ASSY_Model_Name
					,@R_Fukuoka_Model_Name
					,@TIRank
					,@Rank_H_Stock --Rank
					,@TPRank
					,'' --sub_rank
					,@Pdcd
					,@Mask
					,@KNo
					,'MX'--@MNo
					,'NO' --ORNO
					,@Packing_Standerd_QTY_H_Stock
					,''
					,''
					,@Tomson_Mark_3
					,@WFLotNo
					,'' -- lotno_class
					,'' --user_code
					,@Product_Control_Clas
					,@ProductClass
					,@ProductionClass
					,@RankNo
					,@HINSYU_Class
					,@Label_Class
					,@newlot
					,'' -- hasuu_lotno ตัวที่ 1
					,'' -- hasuu_lotno ตัวที่ 2 ถ้ามี
					,'' -- hasuu_lotno ตัวที่ 3 ถ้ามี
					,'MX' -- Mno Standard
					,'' -- Mno_hsuu ตัวที่ 1 ถ้ามี
					,'' -- Mno_hsuu ตัวที่ 2 ถ้ามี
					,'' -- Mno_hsuu ตัวที่ 3 ถ้ามี
					,@Packing_Standerd_QTY_H_Stock -- qty standard reel
					,'' -- qty hasuu_lotno ตัวที่ 1
					,'' -- qty hasuu_lotno ตัวที่ 2
					,'' -- qty hasuu_lotno ตัวที่ 3
					,@new_qty -- จำนวนงานทั้งหมดที่พอดี reel
					,@new_qty -- จำนวนงานทั้งหมด
					,''
					,''
					,@Out_Out_Flag
					,'01' --stock_class
					,'2'
					,GETDATE()
					,'' -- delete_flage
					,@op_no_len_value
					,CURRENT_TIMESTAMP
					,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			);


			--insert data to tabel h_stock db-is
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
				 '01'
				,@Pdcd
				,@newlot
				,@package
				,@ROHM_Model_Name
				,@ASSY_Model_Name
				,@R_Fukuoka_Model_Name
				,@TIRank
				,@Rank_H_Stock --Rank
				,@TPRank
				,'' --sub_rank
				,'' --mask
				,'' --kno
				,'MX'--@MNo
				,'NO' --ORNO
				,@Packing_Standerd_QTY_H_Stock
				,''
				,''
				,@Tomson_Mark_3
				,@WFLotNo
				,'' --lotno_class
				,@User_code --user_code
				,@Product_Control_Clas
				,@ProductClass
				,@ProductionClass
				,@RankNo
				,@HINSYU_Class
				,@Label_Class
				,'0' --HASU_Stock_QTY
				,@new_qty
				,''
				,@out_out_flag --out_out_flge
				,''
				,@op_no_len_value
				,''
				,'1'
				,GETDATE()
				,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				,CURRENT_TIMESTAMP
				,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			);


			--insert into table WORK_R_DB to DB-IS
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
				@newlot
			  ,1001 --process_no
			  ,CURRENT_TIMESTAMP --Process_Date
			  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --Process_Time
			  ,'0'
			  ,@new_qty --จำนวน standard ใน column qty_pass to table : tranlot
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
		    

			 --insert into table PACKWORK to DB-IS
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
				@newlot
			  ,@Package
			  ,@ROHM_Model_Name
			  ,@R_Fukuoka_Model_Name
			  ,@Rank_H_Stock --Rank
			  ,@TPRank
			  ,@Pdcd
			  ,@new_qty
			  ,'NO' --ORNO
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
				  ,@newlot
				  ,CURRENT_TIMESTAMP --OccurDate
				  ,@R_Fukuoka_Model_Name
				  ,@Rank_H_Stock --Rank
				  ,@TPRank
				  ,'0' --RED_BLACK_Flag
				  ,@new_qty
				  ,'0' --STOCK_QTY
				  ,@Pdcd --WAREHOUSECODE
				  ,'NO' --ORNO
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


		    INSERT INTO DBxDW.TGOG.Temp_H_STOCK(
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
				,@newlot
				,@package
				,@ROHM_Model_Name
				,@ASSY_Model_Name
				,@R_Fukuoka_Model_Name
				,@TIRank
				,@Rank_H_Stock --Rank
				,@TPRank
				,'' --sub_rank
				,'' --mask
				,'' --kno
				,'MX'--@MNo
				,'NO' --ORNO
				,@Packing_Standerd_QTY_H_Stock
				,''
				,''
				,@Tomson_Mark_3
				,@WFLotNo
				,'' --lotno_class
				,@User_code --user_code
				,@Product_Control_Clas
				,@ProductClass
				,@ProductionClass
				,@RankNo
				,@HINSYU_Class
				,@Label_Class
				,'0' --HASU_Stock_QTY
				,@new_qty
				,''
				,@Out_Out_Flag --out_out_flge
				,''
				,@op_no_len_value
				,''
				,''
				,GETDATE()
				,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				,CURRENT_TIMESTAMP
				,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			);

			--BEGIN TRY
				
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_d_lot_in_tranlot] @lotno = @newlot
				,@device_name = @ROHM_Model_Name
				,@assy_name = @ASSY_Model_Name
				,@qty = @new_qty

				--EXEC [StoredProcedureDB].[atom].[sp_set_label_issued_tg] @lot_no = @newlot
				--,@qty_hasuu_brfore = 0
				--,@Empno_int_value = @Emp_int

				SELECT @lot_id = [lots].[id] from APCSProDB.trans.lots where lot_no = @newlot

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
			   , [updated_by])
			
				SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
				, @lot_id AS lot_id
				, @new_qty AS pcs
				, @newlot AS serial_no
				, '2' AS in_stock
				, '' AS location_id
				, '' AS acc_location_id
				, GETDATE() AS created_at
				, @Emp_int AS created_by
				, GETDATE() AS updated_at
				, @Emp_int AS updated_by
				FROM [APCSProDB].[trans].[surpluses]
				INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'surpluses.id'

				set @r = @@ROWCOUNT
				update [APCSProDB].[trans].[numbers]
				set id = id + @r 
				from [APCSProDB].[trans].[numbers]
				where name = 'surpluses.id'

				IF @newlot != ''
				BEGIN
					UPDATE [APCSProDB].[trans].[lots]
					SET 
						  [qty_out] = @new_qty
						, [qty_combined] = 0
					WHERE [lot_no] = @newlot
				END


				-- INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @newlot
				,@sataus_record_class = 1

				--Update pdcd new d lot 
				UPDATE APCSProDB.trans.surpluses
				SET pdcd = @Pdcd
				,mark_no = 'MX'
				,qc_instruction = @Tomson_Mark_3
				where serial_no = @newlot


				EXEC [StoredProcedureDB].[atom].[sp_set_mixing_tg] @lotno0 = @lot_hasuu
				,@lotno1 = ''
				,@lotno2 = ''
				,@lotno3 = ''
				,@lotno4 = ''
				,@lotno5 = ''
				,@lotno6 = ''
				,@lotno7 = ''
				,@lotno8 = ''
				,@lotno9 = ''
				,@master_lot_no = @newlot
				,@emp_no_value = @empno


				-- CREATE 2021/03/15 By Aomsin
				-- INSERT DATA IN TABLE LABEL_HISTORY
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @newlot
				,@process_name = 'TP'


		--		SELECT 'TRUE' AS Status ,'Insert error !!' AS Error_Message_ENG,N'บันทึกข้อมูล d_lot_in_tranlot สำเร็จ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		--		RETURN
		
		--END TRY
		--BEGIN CATCH
		--	SELECT 'FALSE' AS Status ,'Insert error !!' AS Error_Message_ENG,N'บันทึกข้อมูล d_lot_in_tranlot ผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		--	RETURN
		--END CATCH

END
