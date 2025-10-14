-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,Test New Version >
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_data_pc_request_V3_manual_data_is] 
	-- Add the parameters for the stored procedure here
	 @newlot varchar(10)
	,@new_qty int = 0
	,@out_out_flag char(5) = ''
	,@pdcd_Adjust char(5) = '' --add parameter 2021/07/06
	,@hasuu_qty_After int = 0
	,@lot_hasuu_1 varchar(10) = ''
	,@lot_hasuu_2 varchar(10) = ''
	,@lot_hasuu_3 varchar(10) = ''
	,@lot_hasuu_4 varchar(10) = ''
	,@lot_hasuu_5 varchar(10) = ''
	,@empno char(6) = ''
	
	
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

	--declare @count int = 0;
	--declare @table table
	--(
	--	serial_no char(20),
	--	pcs int,
	--	in_stock tinyint,
	--	transfer_flag tinyint,
	--	transfer_pcs int
	--);

	--set @count = (SELECT count(sur.serial_no)
	--from APCSProDB.trans.surpluses as sur
	--inner join APCSProDB.trans.lots as lot on sur.serial_no = lot.lot_no
	--inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
	--inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	--left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_2
	--where serial_no in(@lot_hasuu_1,@lot_hasuu_2,@lot_hasuu_3,@lot_hasuu_4,@lot_hasuu_5))

	--insert into @table 
	--(
	--	serial_no
	--	,pcs
	--	,in_stock
	--	,transfer_flag
	--	,transfer_pcs
	--)
	--select 
	--	serial_no
	--	,iif(row_number() over(order by pcs desc) = @count,iif(@hasuu_qty_After = 0,pcs,@hasuu_qty_After),pcs) as pcs_test
	--	,iif(row_number() over(order by pcs desc) = @count,iif(@hasuu_qty_After = 0,0,2),0) as instock_val
	--	,iif(row_number() over(order by pcs desc) = @count,iif(@hasuu_qty_After = 0,0,1),0) as tranfer_flag
	--	,iif(row_number() over(order by pcs desc) = @count,pcs - @hasuu_qty_After,pcs) as transfer_pcs
	--from APCSProDB.trans.surpluses 
	--where serial_no in(@lot_hasuu_1,@lot_hasuu_2,@lot_hasuu_3,@lot_hasuu_4,@lot_hasuu_5)

	DECLARE @op_no_len_value char(5) = '';
	select  @op_no_len_value =  case when LEN(CAST(@empno as char(5))) = 4 then '0' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 3 then '00' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 2 then '000' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 1 then '0000' + CAST(@empno as char(5))
			else CAST(@empno as char(5)) end 
   
   --update 2021/09/05
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
		,'EXEC [dbo].[tg_sp_set_data_pc_request_V3_manual_data_is_new_function] @empno = ''' + @empno + ''',@lotno_standard = ''' + @newlot + ''',@lotno_standard_qty = ''' + CONVERT (varchar (10), @new_qty) + ''',@pdcd_adjust = ''' + @pdcd_Adjust + ''',@out_out_flag_adjust = ''' + @out_out_flag + ''''
		,@newlot

    select 
	 @StockClass = '01' --fix
	,@LotNo_H_Stock = TRIM(sur.serial_no)
	,@Package = pk.short_name
	,@Pdcd = sur.pdcd
	,@HASU_Stock_QTY = sur.pcs 
	,@Packing_Standerd_QTY_H_Stock = dn.pcs_per_pack
	,@ROHM_Model_Name = dn.name
	,@ASSY_Model_Name = dn.assy_name
	,@R_Fukuoka_Model_Name = Fukuoka.R_Fukuoka_Model_Name
	--,@R_Fukuoka_Model_Name = ''
	,@TIRank = case when dn.rank is null then '' else dn.rank end
	,@Rank_H_Stock = case when dn.rank is null then '' else dn.rank end
	,@TPRank = case when dn.tp_rank is null then '' else dn.tp_rank end
	,@SUBRank = ''  --fix blank
	,@Mask = ''  --fix blank
	,@KNo = ''  --fix blank
	,@Tomson_Mark_1 = ''  --fix blank
	,@Tomson_Mark_2 = ''  --fix blank
	,@Tomson_Mark_3 = sur.qc_instruction
	,@ORNo = case 
		when SUBSTRING(sur.serial_no,5,1) = 'D' or SUBSTRING(sur.serial_no,5,1) = 'F' then 'NO' 
		else 
			case
				when (allocat.ORNo = '' or allocat.ORNo is null) then '' 
				else allocat.ORNo 
			end
		end
	,@MNo = sur.mark_no
	,@WFLotNo = ''
	,@LotNo_Class = ''
	,@Label_Class = case when sur.label_class is null then '' else sur.label_class end
	,@Product_Control_Clas = case when sur.product_control_class is null then '' else sur.product_control_class end
	,@ProductClass = case when sur.product_class is null then '' else sur.product_class end
	,@ProductionClass = case when sur.production_class is null then '' else sur.production_class end
	,@RankNo = case when sur.rank_no is null then '' else sur.rank_no end
	,@HINSYU_Class = case when sur.hinsyu_class is null then '' else sur.hinsyu_class end
	from APCSProDB.trans.surpluses as sur
	inner join APCSProDB.trans.lots as lot on sur.lot_id = lot.id
	inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	left join APCSProDB.method.allocat_temp as allocat on lot.lot_no = allocat.LotNo  --Edit query 2023/02/01 Time : 16.31
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
	where serial_no = @lot_hasuu_1
	and sur.updated_at  >= (getdate() - 1095)


	----insert data tabel lsi_ship to db-is
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
					 @newlot
					,@package
					,@ROHM_Model_Name
					,@ASSY_Model_Name
					,@R_Fukuoka_Model_Name
					,@TIRank
					,@Rank_H_Stock --Rank
					,@TPRank
					,'' --sub_rank
					,@pdcd_Adjust
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
					,'1'
					,@out_out_flag
					,'01' --stock_class
					,'2'
					,GETDATE()
					,'' -- delete_flage
					,@op_no_len_value
					,CURRENT_TIMESTAMP
					,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			);

	----insert data to tabel h_stock db-is
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
				 '01'
				,@pdcd_Adjust
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



END
