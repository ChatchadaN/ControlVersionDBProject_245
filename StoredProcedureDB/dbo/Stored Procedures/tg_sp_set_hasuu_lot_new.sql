-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_hasuu_lot_new]
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
	DECLARE @Total_All int = 0

	--add parameter get qty for hasuu lot
	DECLARE @hasuu_lot_list VARCHAR(MAX) = ''
	DECLARE @hasuu_lot_qty_list VARCHAR(MAX) = ''

	--add query sum hasuu qty -->create date : 2023/02/09 time : 09.46
	select @Total_All = SUM(pcs) 
	from APCSProDB.trans.surpluses
	where serial_no IN (@lotno0,@lotno1,@lotno2,@lotno3,@lotno4,@lotno5,@lotno6,@lotno7,@lotno8,@lotno9)
	and serial_no <> '' 
	and serial_no is not null

	--Get Hasuu Lot qty <date update : 2023/02/09 time : 10.33>
	select @hasuu_lot_list = COALESCE(IIF(@hasuu_lot_list = '','', @hasuu_lot_list + ','), '') + serial_no
	, @hasuu_lot_qty_list = COALESCE(IIF(@hasuu_lot_qty_list = '','', @hasuu_lot_qty_list+ ','), '') + CAST(pcs AS VARCHAR)
	from APCSProDB.trans.surpluses
	where serial_no IN (@lotno0,@lotno1,@lotno2,@lotno3,@lotno4,@lotno5,@lotno6,@lotno7,@lotno8,@lotno9)
	and serial_no <> '' 
	and serial_no is not null

	select 
	 @StockClass = '01' --fix
	,@LotNo_H_Stock = sur.serial_no
	,@Pdcd = sur.pdcd
	,@HASU_Stock_QTY = sur.pcs 
	,@Standerd_QTY = dn.pcs_per_pack
	,@Packing_Standerd_QTY = dn.pcs_per_pack
	,@Packing_Standerd_QTY_H_Stock = dn.pcs_per_pack
	,@Qty_Full_Reel_All = (dn.pcs_per_pack) * (@Total_All/(dn.pcs_per_pack)) 
	,@ROHM_Model_Name = dn.name
	,@ASSY_Model_Name = dn.assy_name
	,@R_Fukuoka_Model_Name = Fukuoka.R_Fukuoka_Model_Name
	,@TIRank = case when dn.rank is null or dn.rank = '' then '' else dn.rank end
	,@Rank_H_Stock = case when dn.rank is null or dn.rank = '' then '' else dn.rank end
	,@TPRank = case when dn.tp_rank is null or dn.tp_rank = '' then '' else dn.tp_rank end
	,@SUBRank = '' --fix blank
	,@Mask = '' --fix blank
	,@KNo = '' --fix blank
	,@Tomson_Mark_1 = '' --fix blank
	,@Tomson_Mark_2 = '' --fix blank
	,@Tomson_Mark_3 = sur.qc_instruction
	--< edit 20/06/2022 10.00
	,@ORNo = case 
		when SUBSTRING(sur.serial_no,5,1) = 'D' or SUBSTRING(sur.serial_no,5,1) = 'F' then 'NO' 
		else 
			case
				when (allocat.ORNo = '' or allocat.ORNo is null) then '' 
				else allocat.ORNo 
			end
		end --ORNO
	--> edit 20/06/2022 10.00
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
	--left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_2
	left join APCSProDB.method.allocat_temp as allocat on lot.lot_no = allocat.LotNo  --Edit Query 2023/02/01 Time : 16.40
	left join (
		select ROHM_Model_Name
			, ASSY_Model_Name
			, R_Fukuoka_Model_Name
		from APCSProDB.method.allocat_temp
		group by ROHM_Model_Name
			, ASSY_Model_Name
			, R_Fukuoka_Model_Name
	) as Fukuoka on trim(dn.name) = trim(Fukuoka.ROHM_Model_Name)
		and trim(dn.assy_name) = trim(Fukuoka.ASSY_Model_Name)
	where serial_no IN (@lotno0,@lotno1,@lotno2,@lotno3,@lotno4,@lotno5,@lotno6,@lotno7,@lotno8,@lotno9)
	and sur.updated_at  >= (getdate() - 1095)
	and sur.pcs != '0'
	order by SUBSTRING(sur.serial_no,5,1) asc

	select @Hasuu_Qty_Before = (@Total_All) % (@Standerd_QTY)

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

	--update log --> add hasuu lot list and hasuu lot qty list <date update : 2023/02/09 time : 10.33>
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
	, [record_class]
	, [login_name]
	, [hostname]
	, [appname]
	, [command_text]
	, [lot_no])
		SELECT 
		GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [tg_sp_set_hasuu_lot] Get Store @empno = ''' + CAST(@EmpNo_int as varchar(7)) 
			+ ''',@lotno = ''' + @newlotno 
			+ ''',@QtyPass_Form_Web = ''' + CAST(@total_pcs as varchar(7)) 
			+ ''',@QtyPass_Form_Sum_On_Store = ''' + CAST(@Total_All as varchar(7)) 
			+ ''',@Hasuu_lot_list = ''' + @hasuu_lot_list 
			+ ''',@Hasuu_lot_qty_list = ''' + @hasuu_lot_qty_list  + ''''
		,@newlotno

	BEGIN TRY
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
				,@Total_All
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
				,Fukuoka.R_Fukuoka_Model_Name
				,case when dn.rank is null or dn.rank = '' then '' else dn.rank end
				,case when dn.rank is null or dn.rank = '' then '' else dn.rank end
				,case when dn.tp_rank is null or dn.tp_rank = '' then '' else dn.tp_rank end
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
				,case when sur.label_class is null then '' else sur.label_class end
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
			--left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_2
			left join APCSProDB.method.allocat_temp as allocat on lot.lot_no = allocat.LotNo
			left join (
				select ROHM_Model_Name
					, ASSY_Model_Name
					, R_Fukuoka_Model_Name
				from APCSProDB.method.allocat_temp
				group by ROHM_Model_Name
					, ASSY_Model_Name
					, R_Fukuoka_Model_Name
			) as Fukuoka on trim(dn.name) = trim(Fukuoka.ROHM_Model_Name)
				and trim(dn.assy_name) = trim(Fukuoka.ASSY_Model_Name)
			where serial_no IN (@lotno0,@lotno1,@lotno2,@lotno3,@lotno4,@lotno5,@lotno6,@lotno7,@lotno8,@lotno9)
			
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
					,0 -- จำนวนงานทั้งหมดที่พอดี reel ,Shipment_QTY fix data = 0 >>2022/11/30 , Time : 14.35<<
					,@Total_All -- จำนวนงานทั้งหมด
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
				,(@Total_All)%(@Standerd_QTY) --HASU_Stock_QTY
				,@Qty_Full_Reel_All --HASU_WIP_QTY , set qty shipment all reel is not hasuu
				,''
				,@Out_Out_Flag --out_out_flge
				,''
				,@op_no_len_value
				,'1' --DMY_IN_FLAG , fix data = 1 >>2022/11/30 , Time : 13.35<<
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
		   VALUES(
				@newlotno
			  ,1001 --process_no
			  ,CURRENT_TIMESTAMP --Process_Date
			  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --Process_Time
			  ,'0'
			  ,@Total_All --จำนวน standard ใน column qty_pass to table : tranlot
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
		   VALUES(
				@newlotno
			  ,@Package
			  ,@ROHM_Model_Name
			  ,@R_Fukuoka_Model_Name
			  ,@Rank_H_Stock --Rank
			  ,@TPRank
			  ,@Pdcd
			  ,@Total_All
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
		   VALUES(
				   '' --RECORD_CLASS
				  ,@ROHM_Model_Name
				  ,@newlotno
				  ,CURRENT_TIMESTAMP --OccurDate
				  ,@R_Fukuoka_Model_Name
				  ,@Rank_H_Stock --Rank
				  ,@TPRank
				  ,'0' --RED_BLACK_Flag
				  ,@Total_All
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

		--UPDATE InStock = 0 Hasuu Use
		UPDATE APCSProDB.trans.surpluses
		SET in_stock = 0
			,stock_class = '01'  --add update value date modify : 2022/03/10 time : 15.45 --> 01 is hasuu mixing
			,updated_at = GETDATE()
		where serial_no IN (@lotno0,@lotno1,@lotno2,@lotno3,@lotno4,@lotno5,@lotno6,@lotno7,@lotno8,@lotno9)

		BEGIN TRY
				
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_d_lot_in_tranlot] @lotno = @newlotno
				,@device_name = @device
				,@assy_name = @ASSY_Model_Name
				,@qty = @Total_All
				,@production_category_val = 20 --add parameter 2022/04/22 time : 13.32

				-- Set data in Surpluses
				EXEC [StoredProcedureDB].[atom].[sp_set_label_issued_tg] @lot_no = @newlotno
				,@qty_hasuu_brfore = @Hasuu_Qty_Before
				,@Empno_int_value = @EmpNo_int
				,@stock_class = @StockClass  --add value date modify : 2022/03/10 time : 15.45

				-- INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @newlotno
				,@sataus_record_class = 1

				--Update pdcd new d lot 
				UPDATE APCSProDB.trans.surpluses
				SET pdcd = @Pdcd
				,qc_instruction = @Tomson_Mark_3
				,mark_no = 'MX'
				--update column value form table allocat data 2021/09/15 by Aomsin
				,user_code = @User_code
				,product_control_class = @Product_Control_Clas
				,product_class = @ProductClass
				,production_class = @ProductionClass
				,rank_no = @RankNo
				,hinsyu_class = @HINSYU_Class
				,label_class = @Label_Class
				where serial_no = @newlotno


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

				--Create log Date : 2022/01/19 Time : 14.22
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
					,'EXEC [tg_sp_set_hasuu_lot] Set data to APCSPro @empno = ''' + CAST(@EmpNo_int as varchar(7)) 
						+ ''',@lotno = ''' + @newlotno 
						+ ''',@QtyPass = ''' + CAST(@total_pcs as varchar(7)) 
						+ ''',@QtyPass_Form_Sum_On_Store = ''' + CAST(@Total_All as varchar(7))
						+ ''',@Hasuu_lot_list = ''' + @hasuu_lot_list 
						+ ''',@Hasuu_lot_qty_list = ''' + @hasuu_lot_qty_list  + ''''
					,@newlotno

				SELECT 'TRUE' AS Status ,'Insert Success !!' AS Error_Message_ENG,N'บันทึกข้อมูล d_lot_in_tranlot สำเร็จ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
		
		END TRY
		BEGIN CATCH
			SELECT 'FALSE' AS Status ,'Insert error !!' AS Error_Message_ENG,N'บันทึกข้อมูล d_lot_in_tranlot ผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH
	
		SELECT 'TRUE' AS Status ,'Insert Success !!' AS Error_Message_ENG,N'บันทึกข้อมูล d_lot สำเร็จ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN

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
			,'EXEC [tg_sp_set_hasuu_lot] Set data store Error @empno = ''' + CAST(@EmpNo_int as varchar(7)) 
				+ ''',@lotno = ''' + @newlotno 
				+ ''',@QtyPass = ''' + CAST(@total_pcs as varchar(7)) 
				+ ''',@QtyPass_Form_Sum_On_Store = ''' + CAST(@Total_All as varchar(7)) 
				+ ''',@Hasuu_lot_list = ''' + @hasuu_lot_list 
				+ ''',@Hasuu_lot_qty_list = ''' + @hasuu_lot_qty_list  + ''''
			,@newlotno

		SELECT 'FALSE' AS Status ,'Insert error !!' AS Error_Message_ENG,N'บันทึกข้อมูล d_lot ผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH
	
END
