-- =============================================
-- Author:		<Author,,Name : Aomsin>
-- Create date: <Create Date,2021/10/08,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_new_d_lot]
	-- Add the parameters for the stored procedure here
	 @lotno_original varchar(10) = ''
	,@qty_original int = 0
	,@lotno_new_value varchar(10) = ''
	,@emp_no char(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @r int= 0;
	DECLARE @Lot_Master_id int = 0
	DECLARE @Lot_Hasuu_id int = 0
	DECLARE @LotNo varchar(10) =''
	DECLARE @StockClass char(2) ='' 
	DECLARE @Pdcd char(5) =''
	DECLARE @LotNo_H_Stock char(10) =''
	DECLARE @HASU_Stock_QTY int
	DECLARE @Packing_Standerd_QTY int
	DECLARE @Packing_Standerd_QTY_H_Stock int
	DECLARE @Qty_Full_Reel_All int
	DECLARE @Package char(20) = ''
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
	DECLARE @Hasuu_Qty_Before int
	DECLARE @EmpNo_int INT
	DECLARE @op_no_len_value char(5) = '';
	DECLARE @lotno_type char(1) = ''
	DECLARE @user_code_value char(4)
	DECLARE @product_control_class_value char(3)
	DECLARE @product_class_value char(1)
	DECLARE @production_class_value char(1)
	DECLARE @rank_no_value char(6)
	DECLARE @hinsyu_class_value char(1)
	DECLARE @label_class_value char(1)
	DECLARE @Original_lot_front varchar(4) = ''
	DECLARE @Original_lot_back varchar(5) = ''
	DECLARE @Newlot varchar(10) = ''
	--Add Parameter 2021/10/27
	DECLARE @Chk_Wip_State tinyint = 0
    -- Insert statements for procedure here


	--Get Lot Type
	--select @Original_lot_front = SUBSTRING(@lotno_original,1,4)
	--select @Original_lot_back = SUBSTRING(@lotno_original,6,5)
	--select @Newlot = @Original_lot_front + 'D' + @Original_lot_back
	select @Newlot = @lotno_new_value

	select 
	 @Lot_Hasuu_id = lot.id
	,@StockClass = '01' --fix
	,@LotNo_H_Stock = sur.serial_no
	,@Pdcd = sur.pdcd
	,@HASU_Stock_QTY = sur.pcs 
	,@Standerd_QTY = dn.pcs_per_pack
	,@Packing_Standerd_QTY = dn.pcs_per_pack
	,@Packing_Standerd_QTY_H_Stock = dn.pcs_per_pack
	,@Package = pk.short_name
	,@ROHM_Model_Name = dn.name
	,@ASSY_Model_Name = dn.assy_name 
	,@R_Fukuoka_Model_Name = dn.ft_name
	,@TIRank = case when dn.rank is null then '' else dn.rank end
	,@Rank_H_Stock = case when dn.rank is null then '' else dn.rank end
	,@TPRank = case when dn.tp_rank is null then '' else dn.tp_rank end
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
	,@Out_Out_Flag = 'B' --fix
	,@user_code_value = sur.user_code
	,@product_control_class_value = sur.product_control_class
	,@product_class_value = sur.product_class
	,@production_class_value = sur.production_class
	,@rank_no_value = sur.rank_no
	,@hinsyu_class_value = sur.hinsyu_class
	,@label_class_value = sur.label_class
	from APCSProDB.trans.surpluses as sur
	inner join APCSProDB.trans.lots as lot on sur.serial_no = lot.lot_no
	inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_2
	where serial_no = @lotno_original


	select @EmpNo_int = CONVERT(INT, @emp_no)
	select  @op_no_len_value =  case when LEN(CAST(@EmpNo_int as char(5))) = 4 then '0' + CAST(@EmpNo_int as char(5))
			when LEN(CAST(@EmpNo_int as char(5))) = 3 then '00' + CAST(@EmpNo_int as char(5))
			when LEN(CAST(@EmpNo_int as char(5))) = 2 then '000' + CAST(@EmpNo_int as char(5))
			when LEN(CAST(@EmpNo_int as char(5))) = 1 then '0000' + CAST(@EmpNo_int as char(5))
			else CAST(@EmpNo_int as char(5)) end 

	--select  @Newlot,@lotno_hasuu,@ROHM_Model_Name,@ASSY_Model_Name,@qty_hasuu,@emp_no,@EmpNo_int

	--Create D lot in Tranlot
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_d_lot_in_tranlot] 
	 @lotno = @Newlot
	,@device_name = @ROHM_Model_Name
	,@assy_name = @ASSY_Model_Name
	,@qty = @qty_original

	select @Lot_Master_id = id from APCSProDB.trans.lots where lot_no = @Newlot

	--UPDATE WIP SATE IS HASUU
	update APCSProDB.trans.lots 
	set qty_hasuu = @qty_original
	,wip_state = 70
	where lot_no = @Newlot

	---- INSERT DATA TO TABEL SURPLUESE
	INSERT INTO [APCSProDB].[trans].[surpluses]
	( [id]
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
	, [original_lot_id]
	, [user_code]
	, [product_control_class]
	, [product_class]
	, [production_class]
	, [rank_no]
	, [hinsyu_class]
	, [label_class]
	)
	SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
	, @Lot_Master_id AS lot_id
	, @qty_original AS pcs
	, @Newlot AS serial_no
	, '2' AS in_stock
	, '' AS location_id
	, '' AS acc_location_id
	, GETDATE() AS created_at
	, @EmpNo_int AS created_by
	, GETDATE() AS updated_at
	, @EmpNo_int AS updated_by
	, @Pdcd
	, @Tomson_Mark_3
	, 'MX'
	, @Lot_Hasuu_id --Original lot hasuu
	, @user_code_value
	, @product_control_class_value
	, @product_class_value
	, @production_class_value
	, @rank_no_value
	, @hinsyu_class_value
	, @label_class_value
	FROM [APCSProDB].[trans].[surpluses]
	INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'surpluses.id'

	----Update Row In Table tran.number
	set @r = @@ROWCOUNT
	update [APCSProDB].[trans].[numbers]
	set id = id + @r 
	from [APCSProDB].[trans].[numbers]
	where name = 'surpluses.id'

	--INSERT RECORD CLASS TO TABEL surpluse_records
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @Newlot
	,@sataus_record_class = 1
	,@emp_no_int = @EmpNo_int --update 2021/12/07 time : 12.01

	---- INSERT DATA IN TABLE LOT COMBINE
	EXEC [StoredProcedureDB].[atom].[sp_set_mixing_tg] 
	 @lotno0 = @lotno_original
	,@master_lot_no = @Newlot
	,@emp_no_value = @emp_no

	-- INSERT DATA IN TABLE LABEL_HISTORY
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @Newlot
	,@process_name = 'TP'

	--add check wip sate Date : 2021/10/27 Time : 13.37
	select @Chk_Wip_State = wip_state from APCSProDB.trans.lots where lot_no = @Newlot

	IF @Chk_Wip_State != 70
	BEGIN
		--UPDATE WIP SATE IS HASUU
		update APCSProDB.trans.lots 
		set qty_hasuu = @qty_original
		,wip_state = 70
		where lot_no = @Newlot
	END

	--log store 
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
			,'EXEC [dbo].[tg_sp_set_re_surpluses] @lotno_new = ''' + @lotno_new_value + ''',@empno = ''' + @emp_no + ''',@lotno_orginal = ''' + @lotno_original + ''',@qty_original = ''' + CONVERT (varchar (10), @qty_original) + ''',@lotno_new_wip_state = ''' + CONVERT (varchar (10), @Chk_Wip_State) + ''''
			,@lotno_new_value




	--Insert Hasuu Stock In Table : H_Stock at IS
	BEGIN TRY
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
				 '02'
				,@Pdcd
				,@Newlot
				,@Package
				,@ROHM_Model_Name
				,@ASSY_Model_Name
				,@R_Fukuoka_Model_Name
				,@TIRank
				,@Rank_H_Stock
				,@TPRank
				,@SUBRank --subrank
				,@Mask --mask
				,@KNo --kno
				,@MNo
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
				,@qty_original
				,'0'
				,''
				,@Out_Out_Flag --OUT_OUT_FLAG
				,''
				,@op_no_len_value
				,''
				,''
				,GETDATE()
				,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				,CURRENT_TIMESTAMP 
				,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
				
			);
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
			,'EXEC [dbo].[tg_sp_set_re_surpluses] @empno = ''' + @emp_no + ''',@lotno_orginal = ''' + @lotno_original + ''',@qty_original = ''' + CONVERT (varchar (10), @qty_original) + ''',@lotno_new = ''' + @lotno_new_value + ''',@Comment = ''' + N'Insert Hasuu Re Surpluses at H_Stock by IS Error !!' + ''''
			,@lotno_new_value

	END CATCH

	SELECT 'TRUE' AS Status ,CAST(@Newlot as varchar(10)) AS New_lot_value 
	RETURN

END
