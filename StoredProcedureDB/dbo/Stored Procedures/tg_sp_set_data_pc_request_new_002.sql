-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,Test New Version >
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_data_pc_request_new_002] 
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
	--add parameter for get data of interface table.
	DECLARE @Count_mixhist_IF int = null
	DECLARE @Count_lsiship_IF int = null
	DECLARE @Count_hstock_IF int = null
	DECLARE @Count_packwork_IF int = null
	DECLARE @Count_work_r_db_IF int = null
	DECLARE @Count_wh_ukba_IF int = null
	DECLARE @Count_lot_combine int = null
	DECLARE @Count_surpluses int = null
	DECLARE @Count_label_record int = null

	select @Emp_int = CONVERT(INT, @empno) --update 2021/02/04

	declare @count int = 0;
	declare @table table
	(
		serial_no char(20),
		pcs int,
		in_stock tinyint,
		transfer_flag tinyint,
		transfer_pcs int
	);

	set @count = (
		select count(sur.serial_no)
		from APCSProDB.trans.surpluses as sur
		inner join APCSProDB.trans.lots as lot on sur.serial_no = lot.lot_no
		inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
		inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
		--left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_2  --close 2023/03/01 time : 09.57
		where serial_no in (@lot_hasuu_1,@lot_hasuu_2,@lot_hasuu_3,@lot_hasuu_4,@lot_hasuu_5)
	)

	insert into @table 
		( serial_no
		, pcs
		, in_stock
		, transfer_flag
		, transfer_pcs )
	select serial_no
		, iif(row_number() over(order by pcs asc) = @count,iif(@hasuu_qty_After = 0,pcs,@hasuu_qty_After),pcs) as pcs_test  --change order by form desc is asc //2023/03/01 time : 10.40
		, iif(row_number() over(order by pcs asc) = @count,iif(@hasuu_qty_After = 0,0,2),0) as instock_val
		, iif(row_number() over(order by pcs asc) = @count,iif(@hasuu_qty_After = 0,0,1),0) as tranfer_flag
		, iif(row_number() over(order by pcs asc) = @count,pcs - @hasuu_qty_After,pcs) as transfer_pcs
	from APCSProDB.trans.surpluses 
	where serial_no in(@lot_hasuu_1,@lot_hasuu_2,@lot_hasuu_3,@lot_hasuu_4,@lot_hasuu_5)

	DECLARE @op_no_len_value char(5) = '';
	select  @op_no_len_value =  case when LEN(CAST(@empno as char(5))) = 4 then '0' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 3 then '00' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 2 then '000' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 1 then '0000' + CAST(@empno as char(5))
			else CAST(@empno as char(5)) end  

   DECLARE @OPName   char(20)  = '';
   SELECT @OPName =
	CASE
		WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MR.' THEN LEFT(SUBSTRING([users].name, 5,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		WHEN SUBSTRING(CAST(name as char(20)),1,4) ='MISS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MRS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
    ELSE SUBSTRING(CAST(name as char(20)), 1,LEN([users].name)) END 
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @op_no_len_value

	--update 2021/09/05
	---** log call StoredProcedureDB
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no] )
	SELECT GETDATE()
		, 4
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [dbo].[tg_sp_set_data_pc_request_new_002] @empno = ''' + @empno 
			+ ''',@lotno_standard = ''' + @newlot 
			+ ''',@lotno_standard_qty = ''' + CONVERT (varchar (10), @new_qty) 
			+ ''',@pdcd_adjust = ''' + @pdcd_Adjust 
			+ ''',@out_out_flag_adjust = ''' + @out_out_flag + ''''
		, @newlot

    select @StockClass = '01' --fix
		, @LotNo_H_Stock = TRIM(sur.serial_no)
		, @Package = pk.short_name
		, @Pdcd = sur.pdcd
		, @HASU_Stock_QTY = sur.pcs 
		, @Packing_Standerd_QTY_H_Stock = dn.pcs_per_pack
		, @ROHM_Model_Name = dn.name
		, @ASSY_Model_Name = dn.assy_name
		--, @R_Fukuoka_Model_Name = REVERSE(SUBSTRING(REVERSE(dn.name), CHARINDEX('-',  REVERSE(dn.name)) + 1,LEN(dn.name)))
		, @R_Fukuoka_Model_Name = Fukuoka.R_Fukuoka_Model_Name
		, @TIRank = case when dn.rank is null then '' else dn.rank end
		, @Rank_H_Stock = case when dn.rank is null then '' else dn.rank end
		, @TPRank = case when dn.tp_rank is null then '' else dn.tp_rank end
		, @SUBRank = ''  --fix blank
		, @Mask = ''  --fix blank
		, @KNo = ''  --fix blank
		, @Tomson_Mark_1 = ''  --fix blank
		, @Tomson_Mark_2 = ''  --fix blank
		, @Tomson_Mark_3 = sur.qc_instruction
		--, @ORNo = case when SUBSTRING(sur.serial_no,5,1) = 'D' or SUBSTRING(sur.serial_no,5,1) = 'F' then 'NO' 
		--			else case when den_pyo.ORDER_NO = '' or den_pyo.ORDER_NO is null then '' else den_pyo.ORDER_NO end end
		, @ORNo = case 
			when SUBSTRING(sur.serial_no,5,1) = 'D' or SUBSTRING(sur.serial_no,5,1) = 'F' then 'NO' 
			else 
				case
					when (allocat.ORNo = '' or allocat.ORNo is null) then '' 
					else allocat.ORNo 
				end
			end
		, @MNo = sur.mark_no
		, @WFLotNo = ''
		, @LotNo_Class = ''
		, @Label_Class = sur.label_class
		, @Product_Control_Clas = sur.product_control_class
		, @ProductClass = sur.product_class
		, @ProductionClass = sur.production_class
		, @RankNo = sur.rank_no
		, @HINSYU_Class = sur.hinsyu_class
	from APCSProDB.trans.surpluses as sur
	inner join APCSProDB.trans.lots as lot on sur.lot_id = lot.id
	inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	--left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_2
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

	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_d_lot_in_tranlot] @lotno = @newlot
		, @device_name = @ROHM_Model_Name
		, @assy_name = @ASSY_Model_Name
		, @qty = @new_qty

	SELECT @lot_id = [lots].[id] from APCSProDB.trans.lots where lot_no = @newlot

	IF @lot_id > 0
	BEGIN
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
			, [user_code]
			, [product_control_class]
			, [product_class]
			, [production_class]
			, [rank_no]
			, [hinsyu_class]
			, [label_class]
			, [stock_class] )
		SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
			, @lot_id AS lot_id
			, @new_qty AS pcs
			, @newlot AS serial_no
			--, '2' AS in_stock 
			, '0' AS in_stock  --change in_stock = 0 --> date change : 2022/07/01 time : 09.26
			, NULL AS location_id
			, NULL AS acc_location_id
			, GETDATE() AS created_at
			, @Emp_int AS created_by
			, GETDATE() AS updated_at
			, @Emp_int AS updated_by
			, @pdcd_Adjust
			, @Tomson_Mark_3
			, 'MX'
			, @User_code
			, @Product_Control_Clas
			, @ProductClass
			, @ProductionClass
			, @RankNo
			, @HINSYU_Class
			, @Label_Class
			, @StockClass  --add value date modify : 2022/03/10 time : 14.46
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
			, @sataus_record_class = 1
			, @emp_no_int = @Emp_int  --update date : 2021/12/07 time : 13.42

		EXEC [StoredProcedureDB].[atom].[sp_set_mixing_tg] @lotno0 = @lot_hasuu_1
			, @lotno1 = @lot_hasuu_2
			, @lotno2 = @lot_hasuu_3
			, @lotno3 = @lot_hasuu_4
			, @lotno4 = @lot_hasuu_5
			, @lotno5 = ''
			, @lotno6 = ''
			, @lotno7 = ''
			, @lotno8 = ''
			, @lotno9 = ''
			, @master_lot_no = @newlot
			, @emp_no_value = @empno

		-- INSERT DATA IN TABLE LABEL_HISTORY
		EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @newlot
			, @process_name = 'TP'

		--Add Function Update PC Instruction Code = 13 (is Hasuu Reel) date : 2022/02/03 time : 10.55
		BEGIN TRY
			UPDATE APCSProDB.trans.lots 
			SET pc_instruction_code = case when @new_qty >= @Packing_Standerd_QTY_H_Stock then 1 --1:มากกว่าหรือเท่ากับ Standard : 2023/06/13 time : 13.36  --add condition check qty > packing standard date : 2023/06/07 time : 08.37
										   else  13 end 
			where lot_no = @newlot
		END TRY
		BEGIN CATCH
			---** log error update pc_instruction_code in trans.lots
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, 4
				, ORIGINAL_LOGIN()
				, 'StoredProcedureDB'
				, 'TGSYSTEM'
				, 'EXEC [dbo].[tg_sp_set_data_pc_request_V3_new_function Update PC Instruction Code Error] @lotno_standard = ''' + @newlot 
				, @newlot
		END CATCH

		--query set data to is
		--insert data tabel mixhist to db-is
		INSERT INTO [APCSProDWH].[dbo].[MIX_HIST_IF] 
			( -- [M_O_No]
			--, [FREQ]
			[HASUU_LotNo]
			, [LotNo]
			--,[P_O_No]
			, [Stock_Class]
			, [Type_Name]
			, [ROHM_Model_Name]
			, [PDCD]
			, [ASSY_Model_Name]
			, [R_Fukuoka_Model_Name]
			, [TIRank]
			, [Rank]
			, [TPRank]
			, [SUBRank]
			, [Mask]
			, [KNo]
			, [MNo]
			, [Tomson1]
			, [Tomson2]
			, [Tomson3]
			, [allocation_Date]
			, [ORNo]
			, [WFLotNo]
			--, [User_Code]
			, [LotNo_Class]
			, [Label_Class]
			--, [Multi_Class]
			, [Product_Control_Clas]
			, [Packing_Standerd_QTY]
			--, [Date_Code]
			--, [HASUU_Out_Flag]
			, [QTY]
			--, [Transfer_Flag]
			--, [Transfer]
			, [OPNo]
			--, [Theoretical]
			, [OUT_OUT_FLAG]
			, [MIXD_DATE]
			, [TimeStamp_date]
			, [TimeStamp_time] )
		VALUES (
			@newlot
			, @newlot
			, '01'
			, @Package
			, @ROHM_Model_Name
			, @pdcd_Adjust
			, @ASSY_Model_Name
			, @R_Fukuoka_Model_Name
			, @TIRank
			, @Rank_H_Stock --Rank
			, @TPRank
			, ''
			, ''
			, ''
			, 'MX'--@MNo
			, ''
			, ''
			, @Tomson_Mark_3
			, GETDATE()
			, 'NO' --ORNO
			, @WFLotNo
			, @LotNo_Class
			, @Label_Class
			, @Product_Control_Clas
			, @Packing_Standerd_QTY_H_Stock
			, @new_qty
			, @op_no_len_value
			, @out_out_flag
			, GETDATE()
			, CURRENT_TIMESTAMP
			, DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
		);

		--insert data tabel mixhist lotno select to db-is
		INSERT INTO [APCSProDWH].[dbo].[MIX_HIST_IF] 
			( -- [M_O_No]
			--, [FREQ]
			[HASUU_LotNo]
			, [LotNo]
			--, [P_O_No]
			, [Stock_Class]
			, [Type_Name]
			, [ROHM_Model_Name]
			, [PDCD]
			, [ASSY_Model_Name]
			, [R_Fukuoka_Model_Name]
			, [TIRank]
			, [Rank]
			, [TPRank]
			, [SUBRank]
			, [Mask]
			, [KNo]
			, [MNo]
			, [Tomson1]
			, [Tomson2]
			, [Tomson3]
			, [allocation_Date]
			, [ORNo]
			, [WFLotNo]
			--, [User_Code]
			, [LotNo_Class]
			, [Label_Class]
			--, [Multi_Class]
			, [Product_Control_Clas]
			, [Packing_Standerd_QTY]
			--, [Date_Code]
			--, [HASUU_Out_Flag]
			, [QTY]
			, [Transfer_Flag]
			, [Transfer]
			, [OPNo]
			--, [Theoretical]
			, [OUT_OUT_FLAG]
			, [MIXD_DATE]
			, [TimeStamp_date]
			, [TimeStamp_time] )
		SELECT @newlot
			, sur.serial_no
			, '01'
			, pk.short_name
			, dn.name
			, @pdcd_Adjust
			, dn.assy_name
			, Fukuoka.R_Fukuoka_Model_Name  --R_FUKUKA
			, case when dn.rank is null then '' else dn.rank end
			, case when dn.rank is null then '' else dn.rank end
			, case when dn.tp_rank is null then '' else dn.tp_rank end
			, '' --sub_rank
			, '' --mask
			, '' --kno
			, sur.mark_no
			, ''
			, ''
			, sur.qc_instruction
			, GETDATE()
			--, case when SUBSTRING(sur.serial_no,5,1) = 'D' or SUBSTRING(sur.serial_no,5,1) = 'F' then 'NO' 
			--	else case when den_pyo.ORDER_NO = '' or den_pyo.ORDER_NO is null then '' else den_pyo.ORDER_NO end end --ORNO
			, case 
				when SUBSTRING(sur.serial_no,5,1) = 'D' or SUBSTRING(sur.serial_no,5,1) = 'F' then 'NO' 
				else 
					case
						when (allocat.ORNo = '' or allocat.ORNo is null) then '' 
						else allocat.ORNo 
					end
				end --ORNO
			, '' --fix blank
			, '' --lotno_class
			, case when sur.label_class is null then '' else sur.label_class end  --add condition 2022/08/31 time : 13.41
			, case when sur.product_control_class is null then '' else sur.product_control_class end --add condition 2022/08/31 time : 13.41
			, CAST(dn.pcs_per_pack AS char(7)) AS Packing_Standerd_QTY
			, iif(row_number() over(order by pcs asc) = @count,pcs - @hasuu_qty_After,pcs)  --as QTY
			, iif(row_number() over(order by pcs asc) = @count,CAST(iif(@hasuu_qty_After = 0,'' ,1) as char(1)),CAST('' as char(1))) --as Tranfer_Flag
			, iif(row_number() over(order by pcs asc) = @count,iif(@hasuu_qty_After = 0,pcs,@hasuu_qty_After),0)  --as Tranfer 
			, @op_no_len_value
			, @out_out_flag
			, GETDATE()
			, CURRENT_TIMESTAMP
			, DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
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
		where serial_no in(@lot_hasuu_1,@lot_hasuu_2,@lot_hasuu_3,@lot_hasuu_4,@lot_hasuu_5);

		----insert data tabel lsi_ship to db-is
		INSERT INTO [APCSProDWH].[dbo].[LSI_SHIP_IF] 
			( [LotNo]
			, [Type_Name]
			, [ROHM_Model_Name]
			, [ASSY_Model_Name]
			, [R_Fukuoka_Model_Name]
			, [TIRank]
			, [Rank]
			, [TPRank]
			, [SUBRank]
			, [PDCD]
			, [Mask]
			, [KNo]
			, [MNo]
			, [ORNo]
			, [Packing_Standerd_QTY]
			, [Tomson1]
			, [Tomson2]
			, [Tomson3]
			, [WFLotNo]
			, [LotNo_Class]
			, [User_Code]
			, [Product_Control_Clas]
			, [Product_Class]
			, [Production_Class]
			, [Rank_No]
			, [HINSYU_Class]
			, [Label_Class]
			, [Standard_LotNo]
			, [Complement_LotNo_1]
			, [Complement_LotNo_2]
			, [Complement_LotNo_3]
			, [Standard_MNo]
			, [Complement_MNo_1]
			, [Complement_MNo_2]
			, [Complement_MNo_3]
			, [Standerd_QTY]
			, [Complement_QTY_1]
			, [Complement_QTY_2]
			, [Complement_QTY_3]
			, [Shipment_QTY]
			, [Good_Product_QTY]
			, [Used_Fin_Packing_QTY]
			, [HASUU_Out_Flag]
			, [OUT_OUT_FLAG]
			, [Stock_Class]
			, [Label_Confirm_Class]
			, [allocation_Date]
			, [Delete_Flag]
			, [OPNo]
			, [Timestamp_Date]
			, [Timestamp_Time] )
		VALUES (
			@newlot
			, @package
			, @ROHM_Model_Name
			, @ASSY_Model_Name
			, @R_Fukuoka_Model_Name
			, @TIRank
			, @Rank_H_Stock --Rank
			, @TPRank
			, '' --sub_rank
			, @pdcd_Adjust
			, @Mask
			, @KNo
			, 'MX'--@MNo
			, 'NO' --ORNO
			, @Packing_Standerd_QTY_H_Stock
			, ''
			, ''
			, @Tomson_Mark_3
			, @WFLotNo
			, '' -- lotno_class
			, '' --user_code
			, @Product_Control_Clas
			, @ProductClass
			, @ProductionClass
			, @RankNo
			, @HINSYU_Class
			, @Label_Class
			, @newlot
			, '' -- hasuu_lotno ตัวที่ 1
			, '' -- hasuu_lotno ตัวที่ 2 ถ้ามี
			, '' -- hasuu_lotno ตัวที่ 3 ถ้ามี
			, 'MX' -- Mno Standard
			, '' -- Mno_hsuu ตัวที่ 1 ถ้ามี
			, '' -- Mno_hsuu ตัวที่ 2 ถ้ามี
			, '' -- Mno_hsuu ตัวที่ 3 ถ้ามี
			, @Packing_Standerd_QTY_H_Stock -- qty standard reel
			, '' -- qty hasuu_lotno ตัวที่ 1
			, '' -- qty hasuu_lotno ตัวที่ 2
			, '' -- qty hasuu_lotno ตัวที่ 3
			, 0 -- จำนวนงานทั้งหมดที่พอดี reel, Shipment_QTY fix 0 >>2022/11/30 , Time : 15.00<<
			, @new_qty -- จำนวนงานทั้งหมด
			, ''
			, '1'
			, @out_out_flag
			, '01' --stock_class
			, '2'
			, GETDATE()
			, '' -- delete_flage
			, @op_no_len_value
			, CURRENT_TIMESTAMP
			, DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
		);

		----insert data to tabel h_stock db-is
		INSERT INTO [APCSProDWH].[dbo].[H_STOCK_IF] 
			( [Stock_Class]
			, [PDCD]
			, [LotNo]
			, [Type_Name]
			, [ROHM_Model_Name]
			, [ASSY_Model_Name]
			, [R_Fukuoka_Model_Name]
			, [TIRank]
			, [Rank]
			, [TPRank]
			, [SUBRank]
			, [Mask]
			, [KNo]
			, [MNo]
			, [ORNo]
			, [Packing_Standerd_QTY]
			, [Tomson_Mark_1]
			, [Tomson_Mark_2]
			, [Tomson_Mark_3]
			, [WFLotNo]
			, [LotNo_Class]
			, [User_Code]
			, [Product_Control_Clas]
			, [Product_Class]
			, [Production_Class]
			, [Rank_No]
			, [HINSYU_Class]
			, [Label_Class]
			, [HASU_Stock_QTY]
			, [HASU_WIP_QTY]
			, [HASUU_Working_Flag]
			, [OUT_OUT_FLAG]
			, [Label_Confirm_Class]
			, [OPNo]
			, [DMY_IN__Flag]
			, [DMY_OUT_Flag]
			, [Derivery_Date]
			, [Derivery_Time]
			, [Timestamp_Date]
			, [Timestamp_Time] )
		VALUES (
			'01'
			, @pdcd_Adjust
			, @newlot
			, @package
			, @ROHM_Model_Name
			, @ASSY_Model_Name
			, @R_Fukuoka_Model_Name
			, @TIRank
			, @Rank_H_Stock --Rank
			, @TPRank
			, '' --sub_rank
			, '' --mask
			, '' --kno
			, 'MX'--@MNo
			, 'NO' --ORNO
			, @Packing_Standerd_QTY_H_Stock
			, ''
			, ''
			, @Tomson_Mark_3
			, @WFLotNo
			, '' --lotno_class
			, @User_code --user_code
			, @Product_Control_Clas
			, @ProductClass
			, @ProductionClass
			, @RankNo
			, @HINSYU_Class
			, @Label_Class
			, '0' --HASU_Stock_QTY
			, @new_qty
			, ''
			, @out_out_flag --out_out_flge
			, ''
			, @op_no_len_value
			, ''
			, '1' --DMY_OUT_FLAG
			, GETDATE()
			, DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
			, CURRENT_TIMESTAMP
			, DATEDIFF(s, @datestart , CURRENT_TIMESTAMP)
		);

		----insert into table WORK_R_DB to DB-IS
		INSERT INTO [APCSProDWH].[dbo].[WORK_R_DB_IF] 
			( [LotNo]
			, [Process_No]
			, [Process_Date]
			, [Process_Time]
			, [Back_Process_No]
			, [Good_QTY]
			, [NG_QTY]
			, [NG_QTY1]
			, [Cause_Code_of_NG1]
			, [NG_QTY2]
			, [Cause_Code_of_NG2]
			, [NG_QTY3]
			, [Cause_Code_of_NG3]
			, [NG_QTY4]
			, [Cause_Code_of_NG4]
			, [Shipment_QTY]
			, [OPNo]
			, [TERM_ID]
			, [TimeStamp_Date]
			, [TimeStamp_Time]
			, [Send_Flag]
			, [Making_Date]
			, [Making_Time]
			, [SEQNO_SQL10] )
		VALUES (
			@newlot
			, 1001 --process_no
			, CURRENT_TIMESTAMP --Process_Date
			, DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --Process_Time
			, '0'
			, @new_qty --จำนวน standard ใน column qty_pass to table : tranlot
			, '0' --ng qty
			, '0' --ng_qty1
			, ' '
			, '0'
			, ' '
			, '0'
			, ' '
			, '0'
			, ' '
			, '0' --shipment_qty
			, @op_no_len_value --opno
			, '0' --time_id
			, CURRENT_TIMESTAMP --timestamp_date
			, DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
			, ''
			, ''
			, ''
			, '' 
		);
		
		--insert into table PACKWORK to DB-IS
		INSERT INTO [APCSProDWH].[dbo].[PACKWORK_IF] 
			([LotNo]
			, [Type_Name]
			, [ROHM_Model_Name]
			, [R_Fukuoka_Model_Name]
			, [Rank]
			, [TPRank]
			, [PDCD]
			, [Quantity]
			, [ORNo]
			, [OPNo]
			, [Delete_Flag]
			, [Timestamp_Date]
			, [Timestamp_time]
			, [SEQNO] )
		VALUES (
			@newlot
			, @Package
			, @ROHM_Model_Name
			, @R_Fukuoka_Model_Name
			, @Rank_H_Stock --Rank
			, @TPRank
			, @pdcd_Adjust
			, @new_qty
			, 'NO' --ORNO
			, @op_no_len_value --opno
			, ''
			, CURRENT_TIMESTAMP --timestamp_date
			, DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
			, ''
		);

		-- insert into table WH_UKEBA to DB-IS
		INSERT INTO [APCSProDWH].[dbo].[WH_UKEBA_IF] 
			( [Record_Class]
			, [ROHM_Model_Name]
			, [LotNo]
			, [OccurDate]
			, [R_Fukuoka_Model_Name]
			, [Rank]
			, [TPRank]
			, [RED_BLACK_Flag]
			, [QTY]
			, [StockQTY]
			, [Warehouse_Code]
			, [ORNo]
			, [OPNO]
			, [PROC1]
			, [Making_Date_Date]
			, [Making_Date_Time]
			, [Data__send_Flag]
			, [Delete_Flag]
			, [TimeStamp_date]
			, [TimeStamp_time]
			, [SEQNO] )
		VALUES (
			'' --RECORD_CLASS
			, @ROHM_Model_Name
			, @newlot
			, CURRENT_TIMESTAMP --OccurDate
			, @R_Fukuoka_Model_Name
			, @Rank_H_Stock --Rank
			, @TPRank
			, '0' --RED_BLACK_Flag
			, @new_qty
			, '0' --STOCK_QTY
			, @pdcd_Adjust --WAREHOUSECODE
			, 'NO' --ORNO
			, @op_no_len_value --OPNO
			, '1' --PROC1
			, CURRENT_TIMESTAMP --timestamp_date
			, '' --Making_Date_Time
			, '' --DATA_SEND_FLAG
			, '' --DELETE_FLAG
			, CURRENT_TIMESTAMP --timestamp_date
			, DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
			, '' --SEQNO
		 );

		--update data hasuu in table surpluses
		DECLARE @Count_row_table int = 0
		select @Count_row_table =  COUNT(serial_no) from @table

		IF @Count_row_table != 0
		BEGIN
		    --update at 2023/08/31 time : 08.16 update by Aomsin
			select @lot_hasuu_1 = IIF(@lot_hasuu_1 = '','%',@lot_hasuu_1)
				, @lot_hasuu_2 = IIF(@lot_hasuu_2 = '','%',@lot_hasuu_2)
				, @lot_hasuu_3 = IIF(@lot_hasuu_3 = '','%',@lot_hasuu_3)
				, @lot_hasuu_4 = IIF(@lot_hasuu_4 = '','%',@lot_hasuu_4)
				, @lot_hasuu_5 = IIF(@lot_hasuu_5 = '','%',@lot_hasuu_5)

			update APCSProDB.trans.surpluses 
			set pcs = surpluses2.pcs
				,in_stock = surpluses2.in_stock
				,transfer_flag = surpluses2.transfer_flag
				,transfer_pcs = surpluses2.transfer_pcs
			from APCSProDB.trans.surpluses 
			inner join @table as surpluses2 on surpluses.serial_no = surpluses2.serial_no
			where surpluses.serial_no in(@lot_hasuu_1,@lot_hasuu_2,@lot_hasuu_3,@lot_hasuu_4,@lot_hasuu_5)

			--update data hasuu in tran surpluses_record create date : 2022/01/07 time : 08.56
			INSERT INTO APCSProDB.trans.surpluse_records 
				( recorded_at
				 , operated_by
				 , record_class
				 , surpluse_id
				 , lot_id
				 , pcs
				 , serial_no
				 , in_stock
				 , location_id
				 , acc_location_id
				 , reprint_count
				 , created_at
				 , created_by
				 , updated_at
				 , updated_by
				 , product_code
				 , qc_instruction
				 , mark_no
				 , original_lot_id
				 , machine_id
				 , user_code
				 , product_control_class
				 , product_class
				 , production_class
				 , rank_no
				 , hinsyu_class
				 , label_class
				 , transfer_flag
				 , transfer_pcs )
			SELECT GETDATE() as record_at
				 , @Emp_int as operated_by
				 , 2 as record_class
				 , id as surpluse_id
				 , lot_id
				 , pcs
				 , serial_no
				 , in_stock
				 , location_id
				 , acc_location_id
				 , reprint_count
				 , GETDATE()
				 , created_by
				 , GETDATE()
				 , updated_by
				 , pdcd
				 , qc_instruction
				 , mark_no
				 , original_lot_id
				 , machine_id
				 , user_code
				 , product_control_class
				 , product_class
				 , production_class
				 , rank_no
				 , hinsyu_class
				 , label_class
				 , transfer_flag
				 , transfer_pcs
			from APCSProDB.trans.surpluses 
			where serial_no in (@lot_hasuu_1,@lot_hasuu_2,@lot_hasuu_3,@lot_hasuu_4,@lot_hasuu_5)

			--add query update dmy_out_flag on table H_STOCK_IF  --> To Is Server Update Date : 2023/01/31 Time : 18.15
			UPDATE h_stock 
			SET DMY_OUT_Flag = case when sur.in_stock = 0 then '1' 
									when sur.in_stock = 2 then '' 
									else h_stock.DMY_OUT_Flag end
			FROM APCSProDWH.dbo.H_STOCK_IF as h_stock
			inner join APCSProDB.trans.surpluses as sur on h_stock.LotNo = sur.serial_no
			WHERE h_stock.LotNo in (@lot_hasuu_1,@lot_hasuu_2,@lot_hasuu_3,@lot_hasuu_4,@lot_hasuu_5)

			BEGIN TRY
				--UPDATE QTY ON LABEL ISUUE RECORD FOR WORK HASUU LOT  --> Create 2023/03/22 time : 11.52
				UPDATE rec_label
				SET
					qrcode_detail = CAST(rohm_model_name as varchar(19)) 
							+ CAST(FORMAT(sur.pcs,'000000') as varchar(6)) 
							+ lot_no 
							+ CAST(IIF(VERSION > 9,9,VERSION) AS CHAR(1)) 
							+ FORMAT(CAST(no_reel AS INT),'00')
					, barcode_bottom = CAST(FORMAT(sur.pcs,'000000') as varchar(6)) + ' ' 
							+ CAST(SUBSTRING(lot_no, 1, 4) + ' ' 
							+ SUBSTRING(lot_no, 5, 6) as char(11))
					, qty = sur.pcs
					, update_at = GETDATE()
					, update_by = @Emp_int
					, op_no = @Emp_int
					, operated_by = @Emp_int
					, op_name = @OPName
					, version = version + 1
				from APCSProDB.trans.label_issue_records as rec_label
				inner join APCSProDB.trans.surpluses as sur on rec_label.lot_no = sur.serial_no
				WHERE lot_no in (@lot_hasuu_1,@lot_hasuu_2,@lot_hasuu_3,@lot_hasuu_4,@lot_hasuu_5)
				AND type_of_label = 2

				

				--insert data reprint on label hist  --> Create 2023/03/22 time : 11.52
				INSERT INTO APCSProDB.trans.[label_issue_records_hist] 
					( label_issue_id
					, recorded_at
					, record_class
					, operated_by
					, type_of_label
					, lot_no
					, customer_device
					, rohm_model_name
					, qty
					, barcode_lotno
					, tomson_box
					, tomson_3
					, box_type
					, barcode_bottom
					, mno_std
					, std_qty_before
					, mno_hasuu
					, hasuu_qty_before
					, no_reel
					, qrcode_detail
					, type_label_laterat
					, mno_std_laterat
					, mno_hasuu_laterat
					, barcode_device_detail
					, op_no
					, op_name
					, seq
					, ip_address
					, msl_label
					, floor_life
					, ppbt
					, re_comment
					, version
					, is_logo
					, mc_name
					, barcode_1_mod
					, barcode_2_mod
					, seal
					, create_at
					, create_by
					, update_at
					, update_by )
				SELECT id
					, GETDATE()
					, 2 --fix 2 is update record
					, operated_by
					, type_of_label
					, lot_no
					, customer_device
					, rohm_model_name
					, qty
					, barcode_lotno
					, tomson_box
					, tomson_3
					, box_type
					, barcode_bottom
					, mno_std
					, std_qty_before
					, mno_hasuu
					, hasuu_qty_before
					, no_reel
					, qrcode_detail
					, type_label_laterat
					, mno_std_laterat
					, mno_hasuu_laterat
					, barcode_device_detail
					, op_no
					, op_name
					, seq
					, ip_address
					, msl_label
					, floor_life
					, ppbt
					, re_comment
					, version 
					, is_logo
					, mc_name
					, barcode_1_mod
					, barcode_2_mod
					, seal
					, GETDATE()
					, create_by
					, GETDATE()
					, update_by
				FROM APCSProDB.trans.label_issue_records 
				where lot_no in (@lot_hasuu_1,@lot_hasuu_2,@lot_hasuu_3,@lot_hasuu_4,@lot_hasuu_5)
					and type_of_label = 2
			END TRY
			BEGIN CATCH
				---** log error update label
				INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
					( [record_at]
					, [record_class]
					, [login_name]
					, [hostname]
					, [appname]
					, [command_text]
					, [lot_no] )
				SELECT GETDATE()
					, 4
					, ORIGINAL_LOGIN()
					, HOST_NAME()
					, APP_NAME()
					, 'EXEC [dbo].[tg_sp_set_data_pc_request_new_002 update hasuu qty in label error !!] @empno = ''' + @empno 
						+ ''',@lotno_standard = ''' + @newlot 
						+ ''',@lotno_standard_qty = ''' + CONVERT (varchar (10), @new_qty) 
						+ ''',@pdcd_adjust = ''' + @pdcd_Adjust 
						+ ''',@out_out_flag_adjust = ''' + @out_out_flag + ''''
					, @newlot
			END CATCH

			BEGIN TRY
				--UPDATE QTY HASUU IN TABLE TRAN.LOT  --> Create 2023/03/23 time : 09.58
				UPDATE lot
				SET qty_hasuu =	case when sur.in_stock = 2 then sur.pcs
				            else lot.qty_hasuu end
				from APCSProDB.trans.lots as lot
				inner join APCSProDB.trans.surpluses as sur on lot.id = sur.lot_id
				WHERE lot_no in (@lot_hasuu_1,@lot_hasuu_2,@lot_hasuu_3,@lot_hasuu_4,@lot_hasuu_5)

			END TRY
			BEGIN CATCH
				---** log error update qty_hasuu
				INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
					( [record_at]
					, [record_class]
					, [login_name]
					, [hostname]
					, [appname]
					, [command_text]
					, [lot_no] )
				SELECT GETDATE()
					, 4
					, ORIGINAL_LOGIN()
					, HOST_NAME()
					, APP_NAME()
					, 'EXEC [dbo].[tg_sp_set_data_pc_request_new_002 update hasuu qty in tran.lot error !!] @empno = ''' + @empno 
						+ ''',@lotno_standard = ''' + @newlot 
						+ ''',@lotno_standard_qty = ''' + CONVERT (varchar (10), @new_qty) 
						+ ''',@pdcd_adjust = ''' + @pdcd_Adjust 
						+ ''',@out_out_flag_adjust = ''' + @out_out_flag + ''''
					, @newlot
			END CATCH
		END
		ELSE
		BEGIN
			---** log lot not found in surpluses
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, 4
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'EXEC [dbo].[tg_sp_set_data_pc_request_new_002] @empno = ''' + @empno 
					+ ''',@lotno_standard = ''' + @newlot 
					+ ''',@lotno_standard_qty = ''' + CONVERT (varchar (10), @new_qty) 
					+ ''',@pdcd_adjust = ''' + @pdcd_Adjust 
					+ ''',@out_out_flag_adjust = ''' + @out_out_flag 
					+ '''update data hasuu in surpluses ERROR ''' + ''''
				, @newlot
		END

		--add function check data in table interface and table apcsproDB
		SELECT @Count_mixhist_IF = COUNT(HASUU_LotNo) FROM APCSProDWH.[dbo].[MIX_HIST_IF] where HASUU_LotNo = @newlot
		SELECT @Count_lsiship_IF = COUNT(LotNo) FROM APCSProDWH.[dbo].LSI_SHIP_IF where LotNo = @newlot
		SELECT @Count_hstock_IF = COUNT(LotNo) FROM APCSProDWH.[dbo].H_STOCK_IF where LotNo = @newlot
		SELECT @Count_packwork_IF = COUNT(LotNo) FROM APCSProDWH.[dbo].PACKWORK_IF where LotNo = @newlot
		SELECT @Count_wh_ukba_IF = COUNT(LotNo) FROM APCSProDWH.[dbo].WH_UKEBA_IF where LotNo = @newlot
		SELECT @Count_work_r_db_IF = COUNT(LotNo) FROM APCSProDWH.[dbo].WORK_R_DB_IF where LotNo = @newlot
		--get table ApcsproDB
		SELECT @Count_lot_combine = COUNT(*) FROM APCSProDB.trans.lot_combine where lot_id = @lot_id
		SELECT @Count_surpluses = COUNT(serial_no) FROM APCSProDB.trans.surpluses where serial_no = @newlot
		SELECT @Count_label_record =  COUNT(lot_no) FROM APCSProDB.trans.label_issue_records where lot_no = @newlot

		IF @Count_mixhist_IF = 0 or @Count_lsiship_IF = 0 or @Count_hstock_IF = 0 or @Count_packwork_IF = 0 or  @Count_wh_ukba_IF = 0 or @Count_work_r_db_IF = 0
		   or @Count_lot_combine = 0 or @Count_surpluses = 0 or @Count_label_record = 0
		BEGIN
			---** log error insert data to database
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, 4
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'EXEC [dbo].[tg_sp_set_data_pc_request_new_002 Not Insert a Data --> Error] @lotno_new = ''' + @newlot 
					+ ''',@empno = ''' + @empno + ''''
				, @newlot

			--return status
			SELECT 'FALSE' AS Status 
				, CAST(@Newlot as varchar(10)) AS New_lot_value 
				, 'Insert Data PC Request Error' as Status_Data
			RETURN
		END
		ELSE
		BEGIN
			---** log success insert data to database
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, 4
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'EXEC [dbo].[tg_sp_set_data_pc_request_new_002 Insert a Data PC Request --> Success] @lotno_new = ''' + @newlot 
					+ ''',@empno = ''' + @empno + ''''
				, @newlot

			--return status
			SELECT 'TRUE' AS Status 
				, CAST(@Newlot as varchar(10)) AS New_lot_value 
				, 'Insert Data PC Request Success' as Status_Data
			RETURN
		END
	END
	ELSE
	BEGIN
		--log store 
		---** log error create lot in trans.lots
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no] )
		SELECT GETDATE()
			, 4
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, 'EXEC [dbo].[tg_sp_set_data_pc_request_new_002 Not Create lot pc request] @lotno_new = ''' + @newlot 
				+ ''',@empno = ''' + @empno + ''''
			, @newlot

		SELECT 'FALSE' as Status 
			, CAST(@Newlot as varchar(10)) as New_lot_value 
			, 'Create New Lot Error' as Status_Data
		RETURN
	END
END
