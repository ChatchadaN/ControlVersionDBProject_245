-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Edit Data : 2022/01/13 Time : 14.09 By Aomsin 
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_new_dlot_rework_new_manual]
	-- Add the parameters for the stored procedure here
	 @hasuu_lotno VARCHAR(10) =''
	,@package char(10)
	,@device char(20)
	,@rank char(5)
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
	--DECLARE @Day int 
	--DECLARE @AutoRun int 
	DECLARE @LotNo varchar(10) =''
	DECLARE @StockClass char(2) ='' 
	DECLARE @Pdcd char(5) =''
	DECLARE @LotNo_H_Stock char(10) =''
	DECLARE @HASU_Stock_QTY int
	DECLARE @Packing_Standerd_QTY int
	DECLARE @Packing_Standerd_QTY_H_Stock int
	DECLARE @Qty_Full_Reel_All int
	DECLARE @GetPackageName char(10) =''
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
	--add parameter for get data of interface table date time : 2023/04/13 time : 
	DECLARE @Count_mixhist_IF int = null
	DECLARE @Count_lsiship_IF int = null
	DECLARE @Count_hstock_IF int = null
	DECLARE @Count_work_r_db_IF int = null
	DECLARE @Count_packwork_IF int = null
	DECLARE @Count_wh_ukba_IF int = null
	DECLARE @Count_lot_combine int = null
	DECLARE @Count_surpluses int = null
	DECLARE @Count_label_record int = null
	DECLARE @Lot_Master_id int = 0

	select @EmpNo_int = CONVERT(INT, @empno) 
	select @EmpNo_Char = CONVERT(char(5),@EmpNo_int); 

	------------------------------ Start Get EmpnoId #Modify : 2024/12/26 ------------------------------
	DECLARE @GetEmpno varchar(6) = ''
	DECLARE @EmpnoId int = null
	SELECT @GetEmpno = FORMAT(CAST(@empno AS INT), '000000')
	SELECT @EmpnoId = id FROM [APCSProDB].[man].[users] WHERE [emp_num] = @GetEmpno
	------------------------------ End Get EmpnoId #Modify : 2024/12/26 --------------------------------

	--Check qty : 2023/05/22 9:47
	-------------------------------------------------------------------
	DECLARE @qty_disreel INT

	SELECT @qty_disreel = SUM(CAST(qty AS INT))
	FROM APCSProDB.trans.label_issue_records
	WHERE lot_no = @hasuu_lotno
		AND type_of_label = 0
	GROUP BY type_of_label

	--IF (@total_pcs > @qty_disreel)
	--BEGIN
	--	--Create log Date : 2023/05/22 9:47
	--	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--	(
	--		[record_at]
	--		, [record_class]
	--		, [login_name]
	--		, [hostname]
	--		, [appname]
	--		, [command_text]
	--		, [lot_no]
	--	)
	--	SELECT GETDATE()
	--		, '4'
	--		, ORIGINAL_LOGIN()
	--		, HOST_NAME()
	--		, APP_NAME()
	--		, 'EXEC [tg_sp_new_dlot_rework] QTY greater than Disabled Reel @empno = ''' + @empno 
	--			+ ''',@lotno = ''' + @newlotno 
	--			+ ''',@hasuu_lot = ''' + @hasuu_lotno + '''' 
	--			+ ''',total_pcs = ''' + CAST(@total_pcs AS VARCHAR) 
	--			+ ''',carrier_no_set = ''' + @carrier_no_set + ''''
	--		, @newlotno

	--	SELECT 'FALSE' AS Status 
	--		, 'QTY greater than Disabled Reel !!' AS Error_Message_ENG
	--		, N'QTY มากกว่าจำนวนที่ Disabled Reel !!' AS Error_Message_THA 
	--		, N' กรุณาติดต่อ System' AS Handling
	--	RETURN
	--END
	-------------------------------------------------------------------

	--add log #2024.NOV.29 Time : 13.35 Create By. Aomsin
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		[record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
		SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [tg_sp_new_dlot_rework_new_manual] Access Store @empno = ''' + @empno + ''',@lotno = ''' + @newlotno + ''',@hasuu_lot = ''' + @hasuu_lotno + '''' + ''',total_pcs = ''' + cast(@total_pcs as varchar(7)) + ''''
		,@newlotno

	

	select 
		 @StockClass = '01' --fix
		,@LotNo_H_Stock = sur.serial_no
		,@Pdcd = sur.pdcd
		,@HASU_Stock_QTY = sur.pcs 
		,@Standerd_QTY = dn.pcs_per_pack
		,@Packing_Standerd_QTY = dn.pcs_per_pack
		,@Packing_Standerd_QTY_H_Stock = dn.pcs_per_pack
		,@Qty_Full_Reel_All = (dn.pcs_per_pack) * (@total_pcs/(dn.pcs_per_pack)) 
		,@GetPackageName = pk.short_name  --add data 2023/11/02 time : 15.54 by aomsin
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
	left join APCSProDB.method.allocat_temp as allocat on lot.lot_no = allocat.LotNo --edit query 2023/02/03 Time : 10.36
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
	where serial_no = @hasuu_lotno
	and sur.updated_at  >= (getdate() - 1095)
	order by SUBSTRING(sur.serial_no,5,1) asc


	select @Hasuu_Qty_Before = (@total_pcs) % (@Standerd_QTY)

	DECLARE @op_no_len_value char(5) = '';

	select @op_no_len_value =  case when LEN(CAST(@EmpNo_Char as char(5))) = 4 then '0' + CAST(@EmpNo_Char as char(5))
		when LEN(CAST(@EmpNo_Char as char(5))) = 3 then '00' + CAST(@EmpNo_Char as char(5))
		when LEN(CAST(@EmpNo_Char as char(5))) = 2 then '000' + CAST(@EmpNo_Char as char(5))
		when LEN(CAST(@EmpNo_Char as char(5))) = 1 then '0000' + CAST(@EmpNo_Char as char(5))
			else CAST(@EmpNo_Char as char(5)) end 


			--insert data tabel mixhist to db-is
			INSERT INTO [APCSProDWH].[dbo].[MIX_HIST_IF] (
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
			VALUES 
			(
				 @newlotno
				,@newlotno
				,'01'
				,@GetPackageName
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
			INSERT INTO [APCSProDWH].[dbo].[MIX_HIST_IF] (
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
				,sur.serial_no
				,'01'
				,pk.short_name
				,dn.name
				,sur.PDCD
				,dn.assy_name
				,isnull(Fukuoka.R_Fukuoka_Model_Name,Fukuoka_Hstock.R_Fukuoka_Model_Name) --R_FUKUKA_NAME
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
				,sur.pcs
				,@op_no_len_value
				,'B' --fix
				,GETDATE()
				,CURRENT_TIMESTAMP
			    ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			from APCSProDB.trans.surpluses as sur
			inner join APCSProDB.trans.lots as lot on sur.serial_no = lot.lot_no
			inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
			inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
			left join APCSProDB.method.allocat_temp as allocat on lot.lot_no = allocat.LotNo
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
			where serial_no = @hasuu_lotno
			
			--insert data tabel lsi_ship to db-is
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
			VALUES 
			(
				 @newlotno
				,@GetPackageName
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
				,0 -- จำนวนงานทั้งหมดที่พอดี reel , Shipment_QTY fix data = 0
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
			
			--insert data to tabel h_stock db-is
			INSERT INTO [APCSProDWH].[dbo].[H_STOCK_IF] (
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
			VALUES
			(
				 '01'
				,@Pdcd
				,@newlotno
				,@GetPackageName
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
				,@Qty_Full_Reel_All  --HASUU_WIP_QTY
				,''
				,@Out_Out_Flag --out_out_flge
				,''
				,@op_no_len_value
				,'1' --DMY_IN_FLAG , Fix data = 1
				,'' --DMY_OUT_FLAG
				,GETDATE()
				,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				,CURRENT_TIMESTAMP
				,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			);
			
			--insrt into table WORK_R_DB to DB-IS
			INSERT INTO [APCSProDWH].[dbo].[WORK_R_DB_IF] (
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
		   VALUES
		   (
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
			INSERT INTO [APCSProDWH].[dbo].[PACKWORK_IF] (
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
		   VALUES
		   (
			@newlotno
			,@GetPackageName
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
			INSERT INTO [APCSProDWH].[dbo].[WH_UKEBA_IF] (
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
		   VALUES
		   (
			 '10' --RECORD_CLASS  update : #2024/10/17 time: 11.01 by Aomsin
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


END
