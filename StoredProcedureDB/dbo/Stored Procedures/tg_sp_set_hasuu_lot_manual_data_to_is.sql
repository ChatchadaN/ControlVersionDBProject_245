-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_hasuu_lot_manual_data_to_is]
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
	@total_pcs int = 0,
	@hasuu_tatal int = 0,  
	@empno char(6) = '',
	@newlotno varchar(10)
	
	
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
	,@ROHM_Model_Name = dn.name
	,@ASSY_Model_Name = dn.assy_name
	,@R_Fukuoka_Model_Name = REVERSE(SUBSTRING(REVERSE(dn.name), CHARINDEX('-',  REVERSE(dn.name)) + 1,LEN(dn.name))) 
	,@TIRank = case when dn.rank is null or dn.rank = '' then '' else dn.rank end
	,@Rank_H_Stock = case when dn.rank is null or dn.rank = '' then '' else dn.rank end
	,@TPRank = case when dn.tp_rank is null or dn.tp_rank = '' then '' else dn.tp_rank end
	,@SUBRank = '' --fix blank
	,@Mask = '' --fix blank
	,@KNo = '' --fix blank
	,@Tomson_Mark_1 = '' --fix blank
	,@Tomson_Mark_2 = '' --fix blank
	,@Tomson_Mark_3 = sur.qc_instruction
	,@ORNo = case when SUBSTRING(sur.serial_no,5,1) = 'D' or SUBSTRING(sur.serial_no,5,1) = 'F' then 'NO' else den_pyo.ORDER_NO end
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
	left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_2
	where serial_no IN (@lotno0,@lotno1,@lotno2,@lotno3,@lotno4,@lotno5,@lotno6,@lotno7,@lotno8,@lotno9)
	and sur.updated_at  >= (getdate() - 1095)
	--and sur.pcs != '0'
	order by SUBSTRING(sur.serial_no,5,1) asc

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
		,'EXEC [tg_sp_set_hasuu_lot_manual_data_to_is] Get Store @empno = ''' + CAST(@EmpNo_int as varchar(7)) + ''',@lotno = ''' + @newlotno + ''',@QtyPass = ''' + CAST(@total_pcs as varchar(7)) + ''''
		,@newlotno



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
				,@hasuu_tatal--HASU_Stock_QTY
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
			

END
