-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Edit Data : 2022/01/13 Time : 14.09 By Aomsin 
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_new_dlot_recall_is]
	-- Add the parameters for the stored procedure here
	 @hasuu_lotno VARCHAR(10) =''
	,@total_pcs int --qty hasuu all
	,@empno char(6) = ''
	,@newlotno varchar(10)
	,@carrier_no_set varchar(11) = '' --add parameter 2022/05/04 time : 09.30
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
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
    -- Insert statements for procedure here
	DECLARE @EmpNo_int INT 
	DECLARE @EmpNo_Char char(5) = ' ' 
	DECLARE @package char(10) = ''
	DECLARE @device char(20) = ''


	select @EmpNo_int = CONVERT(INT, @empno) 
	select @EmpNo_Char = CONVERT(char(5),@EmpNo_int); 

	--Update Qty Hasuu in Surpluses
	--UPDATE APCSProDB.trans.surpluses
	--SET pcs = @total_pcs
	--	,updated_at = GETDATE()
	--where serial_no = @hasuu_lotno

	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @hasuu_lotno
	,@sataus_record_class = 2
	,@emp_no_int = @EmpNo_int 

	SELECT @Day =  autos.DayOfWeek from DBxDW.TGOG.AutoRunDLot as autos where DayOfWeek = DATEPART(dw,getdate())
	SELECT @AutoRun = autos.AutoRun from DBxDW.TGOG.AutoRunDLot as autos where DayOfWeek = DATEPART(dw,getdate())

	select 
	 @StockClass = '01' --fix
	,@LotNo_H_Stock = sur.serial_no
	,@Pdcd = sur.pdcd
	,@HASU_Stock_QTY = sur.pcs 
	,@Standerd_QTY = dn.pcs_per_pack
	,@Packing_Standerd_QTY = dn.pcs_per_pack
	,@Packing_Standerd_QTY_H_Stock = dn.pcs_per_pack
	,@Qty_Full_Reel_All = (dn.pcs_per_pack) * (@total_pcs/(dn.pcs_per_pack)) 
	,@package = pk.short_name
	,@ROHM_Model_Name = dn.name
	,@ASSY_Model_Name = dn.assy_name 
	--,@R_Fukuoka_Model_Name = case when CHARINDEX('-', dn.ft_name) = 0 then dn.ft_name 
	--		else SUBSTRING(dn.ft_name, 1, CHARINDEX('-', dn.ft_name)-1) end  --old close 2022/08/10
	,@R_Fukuoka_Model_Name = REVERSE(SUBSTRING(REVERSE(dn.name), CHARINDEX('-',  REVERSE(dn.name)) + 1,LEN(dn.name))) 
	,@TIRank = case when dn.rank is null then '' else dn.rank end
	,@Rank_H_Stock = case when dn.rank is null then '' else dn.rank end
	,@TPRank = case when dn.tp_rank is null then '' else dn.tp_rank end
	,@SUBRank = '' --fix blank
	,@Mask = '' --fix blank
	,@KNo = '' --fix blank
	,@Tomson_Mark_1 = '' --fix blank
	,@Tomson_Mark_2 = '' --fix blank
	,@Tomson_Mark_3 = sur.qc_instruction
	,@ORNo = case when SUBSTRING(sur.serial_no,5,1) = 'D' or SUBSTRING(sur.serial_no,5,1) = 'F' then 'NO' else allocat_temp.ORNo end
	,@MNo = sur.mark_no
	,@WFLotNo = '' --fix blank
	,@LotNo_Class = '' --fix blank
	,@Label_Class = case when sur.label_class is null then '' else sur.label_class end
	,@Product_Control_Clas = case when sur.product_control_class is null then '' else sur.product_control_class end
	,@ProductClass = case when sur.product_class is null then '' else sur.product_class end
	,@ProductionClass = case when sur.production_class is null then '' else sur.production_class end
	,@RankNo = case when sur.rank_no is null then '' else sur.rank_no end
	,@HINSYU_Class = case when sur.hinsyu_class is null then '' else sur.hinsyu_class end
	,@Out_Out_Flag = 'B' --fix
	from APCSProDB.trans.surpluses as sur
	inner join APCSProDB.trans.lots as lot on sur.serial_no = lot.lot_no
	inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	left join APCSProDB.method.allocat_temp on lot.lot_no = allocat_temp.LotNo
	where serial_no = @hasuu_lotno
	and sur.updated_at  >= (getdate() - 1095)
	order by SUBSTRING(sur.serial_no,5,1) asc

	select @Hasuu_Qty_Before = (@total_pcs) % (@Standerd_QTY)

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
				,@newlotno
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
			  ,[Transfer_Flag]
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
				,sur.serial_no
				,'01'
				,pk.short_name
				,dn.name
				,sur.PDCD
				,dn.assy_name
				,case when CHARINDEX('-', dn.ft_name) = 0 then dn.ft_name 
						else SUBSTRING(dn.ft_name, 1, CHARINDEX('-', dn.ft_name)-1) end
				,case when dn.rank is null then '' else dn.rank end
				,case when dn.rank is null then '' else dn.rank end
				,case when dn.tp_rank is null then '' else dn.tp_rank end
				,'' --sub_rank
				,'' --mask
				,'' --kno
				,sur.mark_no --Mno
				,''
				,''
				,sur.qc_instruction --tomson_3
				,GETDATE()
				,'NO' --ORNO
				,'' --fix
				,'' --lotno_class
				,case when sur.Label_Class is null then '' else sur.Label_Class end
				,case when sur.product_control_class is null then '' else sur.product_control_class end
				,CAST(dn.pcs_per_pack AS char(7)) AS Packing_Standerd_QTY
				,@total_pcs  --Recall QTY lot old
				,'1'  --fix 1 (tranfer flag)
				,@op_no_len_value
				,'B' --fix
				,GETDATE()
				,CURRENT_TIMESTAMP
			    ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			from APCSProDB.trans.surpluses as sur
			inner join APCSProDB.trans.lots as lot on sur.serial_no = lot.lot_no
			inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
			inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
			--left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_2
			where serial_no = @hasuu_lotno
			
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
					,@hasuu_lotno -- hasuu_lotno ตัวที่ 1
					,'' -- hasuu_lotno ตัวที่ 2 ถ้ามี
					,'' -- hasuu_lotno ตัวที่ 3 ถ้ามี
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
					,''  --label confirm class
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
				,0 --HASU_Stock_QTY fix = 0
				,@Qty_Full_Reel_All --hasuu wip qty 
				,'1' --hasuu working flag  --fix 1
				,@Out_Out_Flag --out_out_flge
				,''
				,@op_no_len_value
				,'1' --DMY IN FLAG fix = 1
				,'' --DMY OUT FLAG
				,GETDATE()
				,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				,CURRENT_TIMESTAMP
				,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			);
			

		--Create log Date : 2021/11/22 Time : 15.42 update : 2021/12/22 Time : 09.15
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
			,'EXEC [tg_sp_new_dlot_recall_is] Set data to IS @empno = ''' + @empno + ''',@lotno = ''' + @newlotno + ''',hasuu_lot = ''' + @hasuu_lotno + '''' + ''',total_pcs = ''' + cast(@total_pcs as varchar) + ''',carrier_no_set = ''' + @carrier_no_set + ''''
			,@newlotno

END
