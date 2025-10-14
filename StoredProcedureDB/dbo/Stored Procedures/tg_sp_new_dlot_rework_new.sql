-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Edit Data : 2022/01/13 Time : 14.09 By Aomsin 
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_new_dlot_rework_new]
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
		,'EXEC [tg_sp_new_dlot_rework] Access Store @empno = ''' + @empno + ''',@lotno = ''' + @newlotno + ''',@hasuu_lot = ''' + @hasuu_lotno + '''' + ''',total_pcs = ''' + cast(@total_pcs as varchar(7)) + ''''
		,@newlotno

	--Update Qty Hasuu in Surpluses
	UPDATE APCSProDB.trans.surpluses
	--SET pcs = @total_pcs
	SET pcs = IIF(in_stock = 2,(cast(pcs as int) - @total_pcs) + @total_pcs,@total_pcs) --Update QTY : 2023/05/22 9:47
		,updated_at = GETDATE()
	where serial_no = @hasuu_lotno

	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @hasuu_lotno
	,@sataus_record_class = 2
	--,@emp_no_int = @EmpNo_int 
	,@emp_no_int = @EmpnoId  --new

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


	--Create New D-Lot
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_d_lot_in_tranlot] @lotno = @newlotno
	,@device_name = @device
	,@assy_name = @ASSY_Model_Name
	,@qty = @total_pcs
	,@production_category_val = 23  --add parameter 2022/04/22 time : 13.39 (23 = rework)
	,@carrier_no_val = @carrier_no_set --add parameter 2022/05/04 time : 09.30

	select @Lot_Master_id = id from APCSProDB.trans.lots where lot_no = @newlotno

	--Add Condition 2023/04/13 Time : 09.56
	IF @Lot_Master_id > 0
	BEGIN
		BEGIN TRY
			--UPDATE InStock = 0 Hasuu Use
			UPDATE APCSProDB.trans.surpluses
			SET  in_stock = 0
				,transfer_pcs = @total_pcs  --add column 2023/04/05 time : 09.28
				,updated_at = GETDATE()
			where serial_no = @hasuu_lotno

			EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @hasuu_lotno
			,@sataus_record_class = 2
			--,@emp_no_int = @EmpNo_int 
			,@emp_no_int = @EmpnoId  --new

			EXEC [StoredProcedureDB].[atom].[sp_set_label_issued_tg] @lot_no = @newlotno
			,@qty_hasuu_brfore = @Hasuu_Qty_Before
			,@Empno_int_value = @EmpNo_int
			,@stock_class = @StockClass  

			-- INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records
			EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @newlotno
			,@sataus_record_class = 1
			--,@emp_no_int = @EmpNo_int 
			,@emp_no_int = @EmpnoId  --new

			--Update pdcd new d lot //Update Column User_code --> label_class : 2023/02/15 Time : 10.00
			UPDATE APCSProDB.trans.surpluses
			SET [pdcd] = @Pdcd
				, [qc_instruction] = @Tomson_Mark_3
				, [mark_no] = 'MX'
				, [user_code] = @User_code
				, [product_control_class] = @Product_Control_Clas
				, [product_class] = @ProductClass
				, [production_class] = @ProductionClass
				, [rank_no] = @RankNo
				, [hinsyu_class] = @HINSYU_Class
				, [label_class] = @Label_Class
			where serial_no = @newlotno

			--Update Record in table surpluses_record (create 2023/04/05 time : 09.24)
			EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @newlotno
			,@sataus_record_class = 2
			--,@emp_no_int = @EmpNo_int 
			,@emp_no_int = @EmpnoId  --new

			--EXEC [StoredProcedureDB].[atom].[sp_set_mixing_tg] 
			--	 @lotno0 = @hasuu_lotno
			--	,@lotno1 = ''
			--	,@lotno2 = ''
			--	,@lotno3 = ''
			--	,@lotno4 = ''
			--	,@lotno5 = ''
			--	,@lotno6 = ''
			--	,@lotno7 = ''
			--	,@lotno8 = ''
			--	,@lotno9 = ''
			--	,@master_lot_no = @newlotno
			--	,@emp_no_value = @empno

			-- Call new version store set data in lot_combine table  --new 2024/12/26
			EXEC [StoredProcedureDB].[atom].[sp_set_mixing_tg_002] @new_lotno = @newlotno
				, @lot_no = @hasuu_lotno  --(array version)
				, @empid = @EmpnoId
				, @app_type = 1

			-- CREATE 2021/03/15 By Aomsin
			-- INSERT DATA IN TABLE LABEL_HISTORY
			EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @newlotno
			,@process_name = 'TP'

			--Set Record Class = 37 TP Rework //Show Record on web atom of lot original --> date time : 2022/05/09 time : 11.05
			EXEC [StoredProcedureDB].[trans].[sp_set_record_class_lot_process_records]
			 @lot_no = @hasuu_lotno
			,@opno = @empno
			,@record_class = 37

			--Addcondition check Tray and check qty_out for update wip_state is 70 --> Date Modify : 2024/02/15 Time : 11.32 Update by Aomsin  <--
			BEGIN TRY
				DECLARE @qty_out_of_original_lot int = null
				DECLARE @Tray char(7) = ''
				DECLARE @Chk_Wip_Before_update int = null
				DECLARE @Chk_Wip_After_update int = null

				SELECT @qty_out_of_original_lot = qty_out,@Chk_Wip_Before_update = wip_state FROM APCSProDB.trans.lots where lot_no = @hasuu_lotno

				SELECT @Tray = ( CASE WHEN [pvt].[id] IS NULL THEN ''
							WHEN [TRAY] IS NULL THEN 'NO USE' 
							ELSE  'USE' 
						END ) --AS TRAY
					FROM [APCSProDB].[trans].[lots] 
					INNER JOIN [APCSProDB].[method].[device_slips] ON [lots].[device_slip_id] = [device_slips].[device_slip_id]
					INNER JOIN [APCSProDB].[method].[device_versions] ON [device_slips].[device_id] = [device_versions].[device_id]
						AND [device_slips].[is_released] = 1 
					INNER JOIN [APCSProDB].[method].[device_names] ON [device_versions].[device_name_id] = [device_names].[id] 
					INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id] 
					INNER JOIN [APCSProDB].[method].[device_flows] ON [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
					LEFT JOIN (
						SELECT [ms].[id]
							, [ms].[name]
							, [comment]
							, [details]
							, [p].[name] AS [mat_name]
						FROM [APCSProDB].[method].[material_sets] AS [ms]
						INNER JOIN [APCSProDB].[method].[material_set_list] AS [ml] ON [ms].[id] = [ml].[id] 
						INNER JOIN [APCSProDB].[material].[productions] AS [p] ON [ml].[material_group_id] = [p].[id]
						WHERE ([ms].[process_id] = 317 OR [ms].[process_id] = 18)
					) AS [mat]
					PIVOT ( 
						MAX([mat_name])
						FOR [details]
						IN (
							[TUBE],[TRAY]
						)
					) AS [pvt] ON [device_flows].[material_set_id] = [pvt].[id]
					LEFT JOIN (
						SELECT [msl].[id]
							, [msl].[tomson_code]
							, [ib].[reel_count]
						FROM [APCSProDB].[method].[material_set_list] AS [msl]
						LEFT JOIN [APCSProDB].[method].[incoming_boxs] AS [ib] ON [ib].[tomson_code] = [msl].[tomson_code] 
							AND [ib].[idx] = 1
						WHERE [msl].[tomson_code] IS NOT NULL
					) AS [tb] ON [tb].[id] = [pvt].[id]
					LEFT JOIN (
						SELECT  [ms].[id]
							, [ms].[name]
							, [comment]
							, [details]
							, [p].[name] AS [mat_name]
							, CONVERT(VARCHAR(10), CONVERT(INT, [use_qty])) + ' '+ [il].[label_eng] AS [use_qty_tray]
						FROM [APCSProDB].[method].[material_sets] AS [ms] 
						INNER JOIN [APCSProDB].[method].[material_set_list] AS [ml] ON [ms].[id] = [ml].[id] 
						INNER JOIN [APCSProDB].[material].[productions] AS [p] ON [ml].[material_group_id] = [p].[id] 
						LEFT JOIN [APCSProDB].[method].[item_labels] AS [il] ON [il].[val] = [ml].[use_qty_unit]
							AND [il].[name] = 'material_set_list.use_qty_unit'
						where ([ms].[process_id] = 317 OR [ms].[process_id] = 18) 
							AND [details] = 'TRAY'
					) AS [tray_qty] ON [tray_qty].[id] = [pvt].[id]
					LEFT JOIN [APCSProDB].[method].[jobs] AS [job] ON [job].[id] = device_flows.[job_id]
					WHERE [device_flows].[job_id] = 317 
						AND [lot_no] = @hasuu_lotno

				IF @Tray = 'USE'
				BEGIN
					IF @total_pcs >= @qty_out_of_original_lot
					BEGIN
					    IF @hasuu_lotno != ''
						BEGIN
							UPDATE [APCSProDB].[trans].[lots]
							SET  wip_state = 70
								,updated_at = GETDATE()
							where lot_no = @hasuu_lotno
						END
					END
				END

				SELECT @Chk_Wip_After_update = wip_state FROM APCSProDB.trans.lots where lot_no = @hasuu_lotno

				--add log is true
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
					,'EXEC [tg_sp_new_dlot_rework] Function Update wip state of Tray is TRUE  @empno = ''' + @empno + ''',@lotno = ''' + @newlotno + ''',@hasuu_lot = ''' + @hasuu_lotno + '''' + ''',total_pcs = ''' + cast(@total_pcs as varchar(7)) + ''',get_wip_state_before = ''' + cast(ISNULL(@Chk_Wip_Before_update,'null') as varchar(5)) + ''',get_wip_state_after = ''' + cast(ISNULL(@Chk_Wip_After_update,'null') as varchar(5)) + ''',Is_Tray = ''' + @Tray + ''''
					,@hasuu_lotno
			END TRY
			BEGIN CATCH
				--add log is flase
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
					,'EXEC [tg_sp_new_dlot_rework] Function Update wip state of Tray is FLASE  @empno = ''' + @empno + ''',@lotno = ''' + @newlotno + ''',@hasuu_lot = ''' + @hasuu_lotno + '''' + ''',total_pcs = ''' + cast(@total_pcs as varchar(7)) + ''',get_wip_state_before = ''' + cast(ISNULL(@Chk_Wip_Before_update,'null') as varchar(5)) + ''',get_wip_state_after = ''' + cast(ISNULL(@Chk_Wip_After_update,'null') as varchar(5)) + ''',Is_Tray = ''' + @Tray + ''''
					,@hasuu_lotno
			END CATCH

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

			--add function check data in table interface and table apcsproDB
			SELECT @Count_mixhist_IF = COUNT(LotNo) FROM [APCSProDWH].[dbo].[MIX_HIST_IF] where HASUU_LotNo = @newlotno
			SELECT @Count_lsiship_IF = COUNT(LotNo) FROM [APCSProDWH].[dbo].[LSI_SHIP_IF] where LotNo = @newlotno
			SELECT @Count_hstock_IF = COUNT(LotNo) FROM [APCSProDWH].[dbo].[H_STOCK_IF] where LotNo = @newlotno
			SELECT @Count_work_r_db_IF = COUNT(LotNo) FROM [APCSProDWH].[dbo].[WORK_R_DB_IF] where LotNo = @newlotno
			SELECT @Count_packwork_IF = COUNT(LotNo) FROM [APCSProDWH].[dbo].[PACKWORK_IF] where LotNo = @newlotno
			SELECT @Count_wh_ukba_IF = COUNT(LotNo) FROM [APCSProDWH].[dbo].[WH_UKEBA_IF] where LotNo = @newlotno
			--get table ApcsproDB
			SELECT @Count_lot_combine = COUNT(*) FROM APCSProDB.trans.lot_combine where lot_id = @Lot_Master_id
			SELECT @Count_surpluses = COUNT(serial_no) FROM APCSProDB.trans.surpluses where serial_no = @newlotno
			SELECT @Count_label_record =  COUNT(lot_no) FROM APCSProDB.trans.label_issue_records where lot_no = @newlotno

			--Check record data is zero or not  (Date Create 2023/04/13 Time : 09.56)
			IF @Count_mixhist_IF = 0 or @Count_lsiship_IF = 0 or @Count_hstock_IF = 0 or @Count_work_r_db_IF = 0 or @Count_packwork_IF = 0
				or @Count_wh_ukba_IF = 0 or @Count_lot_combine = 0 or @Count_surpluses = 0 or @Count_label_record = 0
			BEGIN
				DECLARE @qty_out_lot_member int = 0 
				DECLARE @qty_pass_new_lot int = 0
				DECLARE @pcs_per_pack int = 0
				DECLARE @lot_id_val int = null
				DECLARE @member_lot_id_val int = null
				DECLARE @production_category_val tinyint = null
				DECLARE @lotno_member varchar(10) = ''

				--Condition Auto Cancel Lot Rework
				select @lot_id_val = id 
				,@qty_pass_new_lot = qty_pass
				,@production_category_val = production_category
				from APCSProDB.trans.lots where lot_no = @newlotno

				--GET DATA LOT_MEMBER_ID
				select @member_lot_id_val = member_lot_id from APCSProDB.trans.lot_combine where lot_id = @lot_id_val

				--GET DETIAL OF LOT_MEMBER_ID
				select @lotno_member = Trim(lots.lot_no)
				,@qty_out_lot_member = lots.qty_out
				,@pcs_per_pack = dn.pcs_per_pack
				from APCSProDB.trans.lots 
				inner join APCSProDB.method.device_names as dn on lots.act_device_name_id = dn.id
				where lots.id = @member_lot_id_val

				IF @lotno_member <> ''
				BEGIN
					--UPDATE TABLE LSI_SHIP_IF of DATA INTERFACE
					UPDATE [APCSProDWH].[dbo].[LSI_SHIP_IF]
					SET Shipment_QTY = (@pcs_per_pack) * ((Good_Product_QTY + @qty_pass_new_lot)/(@pcs_per_pack))  
					,Good_Product_QTY = (Good_Product_QTY + @qty_pass_new_lot)
					where LotNo = @lotno_member

					--UPDATE TABLE WH_UKEBA_IF of DATA INTERFACE
					UPDATE [APCSProDWH].[dbo].[WH_UKEBA_IF]
					SET QTY = (QTY + @qty_pass_new_lot)
					where LotNo = @lotno_member
				END

				--Call Store For Cancel Re-work 
				EXEC [StoredProcedureDB].[dbo].[tg_sp_cancel_mix_lot] @lot_standard = @newlotno
				,@emp_no = @empno

				--Create log Date : 2021/12/22 Time : 09.15
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
					,'EXEC [tg_sp_new_dlot_rework] Auto Cancel Lot Re-Work @empno = ''' + @empno + ''',@lotno = ''' + @newlotno + ''',@hasuu_lot = ''' + @hasuu_lotno + '''' + ''',total_pcs = ''' + cast(@total_pcs as varchar) + ''',carrier_no_set = ''' + @carrier_no_set + ''''
					,@newlotno

				SELECT 'FALSE' AS Status ,'Auto Cancel Lot Re-Work !!' AS Error_Message_ENG,N'ข้อมูลเข้าไม่ครบ Auto Cancel Lot Rework !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END
			ELSE
			BEGIN
				--Create log Date : 2021/12/22 Time : 09.15
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
					,'EXEC [tg_sp_new_dlot_rework] create re-work success @empno = ''' + @empno + ''',@lotno = ''' + @newlotno + ''',@hasuu_lot = ''' + @hasuu_lotno + '''' + ''',total_pcs = ''' + cast(@total_pcs as varchar) + ''',carrier_no_set = ''' + @carrier_no_set + ''''
					,@newlotno

				SELECT 'TRUE' AS Status ,'Insert Success !!' AS Error_Message_ENG,N'บันทึกข้อมูล Lot Rework สำเร็จ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END
		END TRY
		BEGIN CATCH
			--Create log Date : 2021/11/22 Time : 15.42
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
				,'EXEC [tg_sp_new_dlot_rework] Error Mix @empno = ''' + @empno + ''',@lotno = ''' + @newlotno + '''' + ''',total_pcs = ''' + cast(@total_pcs as varchar) + ''',carrier_no_set = ''' + @carrier_no_set + ''''
				,@newlotno

			SELECT 'FALSE' AS Status ,'Insert Error !!' AS Error_Message_ENG,N'บันทึกข้อมูล lot Rework ผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH
	END
	ELSE
	BEGIN
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
			,'EXEC [tg_sp_new_dlot_rework] Not Create lot re-work @empno = ''' + @empno + ''',@lotno = ''' + @newlotno + '''' + ''',total_pcs = ''' + cast(@total_pcs as varchar) + ''',carrier_no_set = ''' + @carrier_no_set + ''''
			,@newlotno

		SELECT 'FALSE' AS Status ,'Not Create lot re-work !!' AS Error_Message_ENG,N'ไม่สามารถสร้าง lot rework ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END

END
