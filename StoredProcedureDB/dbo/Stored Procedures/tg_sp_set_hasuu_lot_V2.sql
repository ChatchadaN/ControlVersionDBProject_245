-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_hasuu_lot_V2]
	-- Add the parameters for the stored procedure here
	@lotno0 VARCHAR(10) ='',
	@lotno1 VARCHAR(10) ='',
	@lotno2 VARCHAR(10) ='',
	@lotno3 VARCHAR(10)='',
	@lotno4 VARCHAR(10)='',
	@lotno5 VARCHAR(10)='',
	@lotno6 VARCHAR(10)='',
	@lotno7 VARCHAR(10)='',
	@lotno8 VARCHAR(10)='',
	@lotno9 VARCHAR(10)='',
	@package char(10),
	@device char(20),
	@rank char(5),
	@total_pcs int,
	@hasuu_tatal int,  
	@empno char(6) = '',
	@newlotno varchar(10)
	--@Hasuu_Lotno char(10)
	--@standerdqty char(20)
	--@reel_qty varchar(20),
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @comma varchar(1) = ','
	DECLARE @Day int 
	DECLARE @AutoRun int 
	DECLARE @LotNo varchar(10) =''
	DECLARE @StockClass char(2) ='' 
	DECLARE @Pdcd char(5) =''
	DECLARE @LotNo_H_Stock char(10) =''
	DECLARE @HASU_Stock_QTY int
	DECLARE @Rell int
	DECLARE @Packing_Standerd_QTY int
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
	DECLARE @Out_Out_Flag char(1)='' 
	DECLARE @Standerd_QTY int
	DECLARE @datestart as varchar(50) = cast( GETDATE() as date) 
	DECLARE @r int= 0;
	DECLARE @Hasuu_Qty_Before int
	--DECLARE @LotnoNew varchar(10) = ' '

    -- Insert statements for procedure here
	SELECT @Day =  autos.DayOfWeek from DBxDW.TGOG.AutoRunDLot as autos where DayOfWeek = DATEPART(dw,getdate())
	SELECT @AutoRun = autos.AutoRun from DBxDW.TGOG.AutoRunDLot as autos where DayOfWeek = DATEPART(dw,getdate())


	--SELECT @HasuuLotNo = (SELECT right(YEAR(GETDATE()),2)
	--			+ case when len(DATEPART(week, GETDATE())) = 1 then CONCAT('0',DATEPART(week, GETDATE())) 
	--				   else CAST(DATEPART(week, GETDATE()) As varchar ) end 
	--			+ CAST('D' AS varchar) 
	--			+ CAST(DATEPART(dw,getdate()) AS varchar)
	--			+ CAST(AutoRun - 1 As varchar)
	--			+ CAST('V' AS varchar)
	--			FROM DBxDW.TGOG.AutoRunDLot where DayOfWeek = DATEPART(dw,getdate()))

	--GET HASUU STOCK TO SELECT

		SELECT 
		@StockClass = Stock_Class
	   ,@LotNo_H_Stock = LotNo
	   ,@Pdcd = PDCD
	   ,@HASU_Stock_QTY = HASU_Stock_QTY
	   ,@Standerd_QTY = Packing_Standerd_QTY
	   ,@Rell = HASU_Stock_QTY/Packing_Standerd_QTY 
	   ,@Packing_Standerd_QTY = Packing_Standerd_QTY 
	   ,@Packing_Standerd_QTY_H_Stock = Packing_Standerd_QTY
	   ,@Qty_Full_Reel_All = (Packing_Standerd_QTY) * (@total_pcs/(Packing_Standerd_QTY)) 
	   ,@ROHM_Model_Name = ROHM_Model_Name
	   ,@ASSY_Model_Name = ASSY_Model_Name
	   ,@R_Fukuoka_Model_Name = R_Fukuoka_Model_Name
	   ,@TIRank = TIRank
	   ,@Rank_H_Stock = Rank
	   ,@TPRank = TPRank
	   ,@SUBRank = SUBRank
	   ,@Mask = Mask
	   ,@KNo = KNo
	   ,@Tomson_Mark_1 = Tomson_Mark_1
	   ,@Tomson_Mark_2 = Tomson_Mark_2
	   ,@Tomson_Mark_3 = Tomson_Mark_3
	   ,@ORNo = ORNo
	   ,@MNo = MNo
	   ,@WFLotNo = WFLotNo
	   ,@LotNo_Class = LotNo_Class
	   ,@Label_Class = Label_Class
	   ,@Product_Control_Clas = Product_Control_Clas
	   ,@ProductClass = Product_Class
	   ,@ProductionClass = Production_Class
	   ,@RankNo = Rank_No
	   ,@HINSYU_Class = HINSYU_Class
	   ,@Out_Out_Flag = OUT_OUT_FLAG
	   FROM [DBxDW].[TGOG].[Temp_H_STOCK]
       --FROM DBxDW.TGOG.H_STOCK
	   --FROM [StoredProcedureDB].[dbo].[IS_H_STOCK]
	   --WHERE [Type_Name] like @package and [ASSY_Model_Name] like @device and [Rank] like @rank
	   WHERE  LotNo IN (@lotno0,@lotno1,@lotno2,@lotno3,@lotno4,@lotno5,@lotno6,@lotno7,@lotno8,@lotno9)
	   and DMY_OUT_Flag != '1' 
	   and Derivery_Date  >= (getdate() - 1095)
	   and HASU_Stock_QTY != '0'

	   select @Hasuu_Qty_Before = (@total_pcs) % (@Standerd_QTY)

	   DECLARE @EmpNo_int INT --update 2021/03/06
	   DECLARE @EmpNo_Char char(5) = ' ' --update 2021/03/06

	   select @EmpNo_int = CONVERT(INT, @empno) --update 2021/03/06
	   select @EmpNo_Char = CONVERT(char(5),@EmpNo_int); --update 2021/03/06

	   DECLARE @op_no_len_value char(5) = '';

	   select  @op_no_len_value =  case when LEN(CAST(@EmpNo_Char as char(5))) = 4 then '0' + CAST(@EmpNo_Char as char(5))
			when LEN(CAST(@EmpNo_Char as char(5))) = 3 then '00' + CAST(@EmpNo_Char as char(5))
			when LEN(CAST(@EmpNo_Char as char(5))) = 2 then '000' + CAST(@EmpNo_Char as char(5))
			when LEN(CAST(@EmpNo_Char as char(5))) = 1 then '0000' + CAST(@EmpNo_Char as char(5))
			else CAST(@EmpNo_Char as char(5)) end 
	   

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
				@newlotno
				--(SELECT right(YEAR(GETDATE()),2)
				--+ case when len(DATEPART(week, GETDATE())) = 1 then CONCAT('0',DATEPART(week, GETDATE())) 
				--	   else CAST(DATEPART(week, GETDATE()) As varchar ) end 
				--+ CAST('D' AS varchar) 
				--+ CAST(DATEPART(dw,getdate()) AS varchar)
				--+ CAST(AutoRun   As varchar)
				--+ CAST('V' AS varchar)
				--FROM DBxDW.TGOG.AutoRunDLot where DayOfWeek = DATEPART(dw,getdate()))
				,
				@newlotno
				--(SELECT right(YEAR(GETDATE()),2)
				--+ case when len(DATEPART(week, GETDATE())) = 1 then CONCAT('0',DATEPART(week, GETDATE())) 
				--	   else CAST(DATEPART(week, GETDATE()) As varchar ) end 
				--+ CAST('D' AS varchar) 
				--+ CAST(DATEPART(dw,getdate()) AS varchar)
				--+ CAST(AutoRun   As varchar)
				--+ CAST('V' AS varchar)
				--FROM DBxDW.TGOG.AutoRunDLot where DayOfWeek = DATEPART(dw,getdate()))
				--FROM OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[MIX_HIST])
				,'01'
				,@package
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
				,@Packing_Standerd_QTY
				,@total_pcs
				,@op_no_len_value
				,@Out_Out_Flag
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
			  --,[Transfer_Flag]
			  --,[Transfer]
			  ,[OPNo]
			  --,[Theoretical]
			  ,[OUT_OUT_FLAG]
			  ,[MIXD_DATE]
			  ,[TimeStamp_date]
			  ,[TimeStamp_time]
			  )
			SELECT 
				@newlotno
				--(select top(1) HASUU_LotNo from DBxDW.TGOG.MIX_HIST where LotNo = @lotno0 order by MIXD_DATE desc)
				--(select top(1) HASUU_LotNo from OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[MIX_HIST] where LotNo = @lotno0 order by MIXD_DATE desc)
				,LotNo
				,'01'
				,Type_Name
				,ROHM_Model_Name
				,PDCD
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
				,HASU_Stock_QTY
				,@op_no_len_value
				,OUT_OUT_FLAG
				,GETDATE()
				,CURRENT_TIMESTAMP
			    ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			--FROM DBxDW.TGOG.H_STOCK
			FROM [DBxDW].[TGOG].[Temp_H_STOCK]
			WHERE  LotNo IN (@lotno0,@lotno1,@lotno2,@lotno3,@lotno4,@lotno5,@lotno6,@lotno7,@lotno8,@lotno9)
			
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
					 @newlotno
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
					,@Packing_Standerd_QTY
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
					,@newlotno
					,@lotno0 -- hasuu_lotno ตัวที่ 1
					,@lotno1 -- hasuu_lotno ตัวที่ 2 ถ้ามี
					,@lotno2 -- hasuu_lotno ตัวที่ 3 ถ้ามี
					,'MX' -- Mno Standard
					,'' -- Mno_hsuu ตัวที่ 1 ถ้ามี
					,'' -- Mno_hsuu ตัวที่ 2 ถ้ามี
					,'' -- Mno_hsuu ตัวที่ 3 ถ้ามี
					,@Packing_Standerd_QTY -- qty standard reel
					,'' -- qty hasuu_lotno ตัวที่ 1
					,'' -- qty hasuu_lotno ตัวที่ 2
					,'' -- qty hasuu_lotno ตัวที่ 3
					,@Qty_Full_Reel_All -- จำนวนงานทั้งหมดที่พอดี reel
					,@total_pcs -- จำนวนงานทั้งหมด
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
			

			-- update clumn dmy_out_falg
			UPDATE
				DBxDW.TGOG.Temp_H_STOCK
			SET
				DMY_OUT_Flag = '1'
			FROM
				DBxDW.TGOG.Temp_H_STOCK
			WHERE
				--[Type_Name] like @package and [ROHM_Model_Name] like @device and [Rank] like @rank 
				[LotNo] IN (@lotno0,@lotno1,@lotno2,@lotno3,@lotno4,@lotno5,@lotno6,@lotno7,@lotno8,@lotno9)
				and DMY_OUT_Flag != '1'

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
				,@newlotno
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
				,(@total_pcs)%(@Standerd_QTY) --HASU_Stock_QTY
				,'0'
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
				@newlotno
			  ,1001 --process_no
			  ,CURRENT_TIMESTAMP --Process_Date
			  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --Process_Time
			  ,'0'
			  ,@total_pcs --จำนวน standard ใน column qty_pass to table : tranlot
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
				@newlotno
			  ,@Package
			  ,@ROHM_Model_Name
			  ,@R_Fukuoka_Model_Name
			  ,@Rank_H_Stock --Rank
			  ,@TPRank
			  ,@Pdcd
			  ,@total_pcs
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
				  ,@newlotno
				  ,CURRENT_TIMESTAMP --OccurDate
				  ,@R_Fukuoka_Model_Name
				  ,@Rank_H_Stock --Rank
				  ,@TPRank
				  ,'0' --RED_BLACK_Flag
				  ,@total_pcs
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
		   
			--insert hasuu lot to table : temp_h_stock by LSI
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
				,@newlotno
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
				,(@total_pcs)%(@Standerd_QTY) --HASU_Stock_QTY
				,'0'
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

		 BEGIN TRY
				
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_d_lot_in_tranlot] @lotno = @newlotno
				,@device_name = @device
				,@assy_name = @ASSY_Model_Name
				,@qty = @total_pcs

				EXEC [StoredProcedureDB].[atom].[sp_set_label_issued_tg] @lot_no = @newlotno
				,@qty_hasuu_brfore = @Hasuu_Qty_Before
				,@Empno_int_value = @EmpNo_int

				-- INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @newlotno
				,@sataus_record_class = 1

				EXEC [StoredProcedureDB].[atom].[sp_set_mixing_tg] @lotno0 = @lotno0
				,@lotno1 = @lotno1
				,@lotno2 = @lotno2
				,@lotno3 = @lotno3
				,@lotno4 = @lotno4
				,@lotno5 = @lotno5
				,@lotno6 = @lotno6
				,@lotno7 = @lotno7
				,@lotno8 = @lotno8
				,@lotno9 = @lotno9
				,@master_lot_no = @newlotno
				,@emp_no_value = @empno


				-- CREATE 2021/03/15 By Aomsin
				-- INSERT DATA IN TABLE LABEL_HISTORY
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @newlotno
				,@process_name = 'TP'


				SELECT 'TRUE' AS Status ,'Insert error !!' AS Error_Message_ENG,N'บันทึกข้อมูล d_lot_in_tranlot สำเร็จ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
		
		END TRY
		BEGIN CATCH
			SELECT 'FALSE' AS Status ,'Insert error !!' AS Error_Message_ENG,N'บันทึกข้อมูล d_lot_in_tranlot ผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH

END
