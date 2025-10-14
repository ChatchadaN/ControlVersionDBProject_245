-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, update 2022/02/01,time : 16.06>
-- Description:	<Description,use hasuu stock in and pc request sample lot (E,H)  ,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_hasuu_in_stock_nomix_manual]
	-- Add the parameters for the stored procedure here
	@lotno_standard varchar(10) 
	,@lotno_standard_qty int
	,@empno char(6) = ''
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Lot_No char(10) = ' '
	DECLARE @MNo_Standard char(10) = ' '
	DECLARE @Package char(10) = ' '
	DECLARE @Rank char(5) = ' '
	DECLARE @Standerd_QTY char(7) = ' '
	--DECLARE @MNo char(10) = ' '
	DECLARE @ASSY_Model_Name char(20) = ' '
	DECLARE @Hasuu_Stock_QTY int
	DECLARE @QtyPass_Standard int
	DECLARE @Total int
	DECLARE @Reel int
	DECLARE @Totalhasuu int 
	DECLARE @Qty_Full_Reel_All int
	DECLARE @Qty_Standard_Lsiship int
	DECLARE @Stock_Class char(2) = ' '
	DECLARE @Pdcd char(5) = ' '
	DECLARE @ROHM_Model_Name char(20) = ' '
	DECLARE @R_Fukuoka_Model_Name char(20) = ' '
	DECLARE @TIRank char(5) = ' '
	DECLARE @TPRank char(3) = ' '
	DECLARE @SUBRank char(3) = ' '
	DECLARE @Mask char(2) = ' '
	DECLARE @KNo char(3) = ' '
	DECLARE @Tomson_Mark_1 char(4) = ' '
	DECLARE @Tomson_Mark_2 char(4) = ' '
	DECLARE @Tomson_Mark_3 char(4) = ' '
	DECLARE @ORNo char(12) = ' '
	DECLARE @WFLotNo char(20) = ' '
	DECLARE @LotNo_Class char(1) = ' '
	DECLARE @Product_Control_Clas char(3) = ' '
	DECLARE @ProductClass char(1) = ' '
	DECLARE @ProductionClass char(1) = ' '
	DECLARE @RankNo char(6) = ' '
	DECLARE @HINSYU_Class char(1) = ' '
	DECLARE @Label_Class char(1) = ' '
	DECLARE @User_code char(6) = ' '
	DECLARE @Out_Out_Flag char(1) = ' '
	DECLARE @Allocation_Date char(30) = ' '
	DECLARE @datestart as varchar(50) = cast( GETDATE() as date) 
	DECLARE @Emp_int INT; --Add 2021/05/18
	DECLARE @Lot_Id INT; --Add 2021/05/18
	DECLARE @r int= 0;
	DECLARE @check_wip_state tinyint = 0
	--Add Parameter 2021/12/06
	DECLARE @Lotno_Allocat_Count Int = 0
	DECLARE @is_pc_instruction_code int = 0

	SELECT @Lotno_Allocat_Count = COUNT(*) FROM APCSProDB.method.allocat where LotNo = @lotno_standard
	--SELECT @lotno_allocat_temp_count = COUNT(*) FROM APCSProDB.method.allocat_temp where LotNo = @lotno_standard

	--Add Check Contion Date : 2021/12/06 Time : 12.00
	IF @Lotno_Allocat_Count != 0
	BEGIN
		select @Lot_No = [lots].[lot_no] 
		,@Package = [packages].[short_name]
		,@ROHM_Model_Name = [device_names].[name] 
		,@ASSY_Model_Name =  [device_names].[assy_name] 
		,@R_Fukuoka_Model_Name = allocat.R_Fukuoka_Model_Name
		,@TIRank = case when allocat.TIRank is null then '' else allocat.TIRank end
		,@Rank = case when [device_names].[rank] is null then ''  else [device_names].[rank] end
		,@TPRank = case when [device_names].[tp_rank] is null then ''  else [device_names].[tp_rank] end
		,@SUBRank = allocat.SUBRank
		,@Mask = Mask
		,@KNo = KNo
		,@QtyPass_Standard = [lots].[qty_pass]
		,@Total = @lotno_standard_qty
		,@Totalhasuu = (@lotno_standard_qty)%([device_names].[pcs_per_pack]) --จำนวนงาน hasuu
		,@Standerd_QTY = CAST([device_names].[pcs_per_pack] AS char(7))
		,@Qty_Full_Reel_All = ([device_names].[pcs_per_pack]) * ((@lotno_standard_qty)/([device_names].[pcs_per_pack])) -- จำนวนงานเต็ม reel ทั้งหมด
		,@Qty_Standard_Lsiship = (([device_names].[pcs_per_pack]) * ((@lotno_standard_qty)/([device_names].[pcs_per_pack]))) 
		,@Out_Out_Flag =  allocat.OUT_OUT_FLAG
		,@Allocation_Date = allocat.allocation_Date
		,@MNo_Standard = allocat.MNo --mno_standard
		,@Pdcd = allocat.PDCD --PDCD
		,@ORNo = allocat.ORNo --ORNO
		,@Tomson_Mark_1 = allocat.Tomson1
		,@Tomson_Mark_2 = allocat.Tomson2
		,@Tomson_Mark_3 = allocat.Tomson3
		,@WFLotNo = allocat.WFLotNo
		,@Label_Class = allocat.Label_Class
		,@ProductionClass = allocat.Production_Class --production_class
		,@ProductClass = allocat.Product_Class --product_class
		,@Product_Control_Clas = allocat.Product_Control_Cl_1 --product_control_class
		,@is_pc_instruction_code = case when [lots].[pc_instruction_code] is null or [lots].[pc_instruction_code] = ''  then 0 else [lots].[pc_instruction_code] end
		from [APCSProDB].[method].[package_groups] with (NOLOCK) 
			inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[package_group_id] = [package_groups].[id]
			inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[package_id] = [packages].[id]
			inner join [APCSProDB].[trans].[lots] with (NOLOCK) 
				on [lots].[act_device_name_id] = [device_names].[id]
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[allocat] as allocat on allocat.LotNo = @lotno_standard
		where lot_no = @lotno_standard
	END
	ELSE
	BEGIN
		select @Lot_No = [lots].[lot_no] 
		,@Package = [packages].[short_name]
		,@ROHM_Model_Name = [device_names].[name] 
		,@ASSY_Model_Name =  [device_names].[assy_name] 
		,@R_Fukuoka_Model_Name = allocat.R_Fukuoka_Model_Name
		,@TIRank = case when allocat.TIRank is null then '' else allocat.TIRank end
		,@Rank = case when [device_names].[rank] is null then ''  else [device_names].[rank] end
		,@TPRank = case when [device_names].[tp_rank] is null then ''  else [device_names].[tp_rank] end
		,@SUBRank = allocat.SUBRank
		,@Mask = Mask
		,@KNo = KNo
		,@QtyPass_Standard = [lots].[qty_pass]
		,@Total = @lotno_standard_qty
		,@Totalhasuu = (@lotno_standard_qty)%([device_names].[pcs_per_pack]) --จำนวนงาน hasuu
		,@Standerd_QTY = CAST([device_names].[pcs_per_pack] AS char(7))
		,@Qty_Full_Reel_All = ([device_names].[pcs_per_pack]) * ((@lotno_standard_qty)/([device_names].[pcs_per_pack])) -- จำนวนงานเต็ม reel ทั้งหมด
		,@Qty_Standard_Lsiship = (([device_names].[pcs_per_pack]) * ((@lotno_standard_qty)/([device_names].[pcs_per_pack]))) 
		,@Out_Out_Flag =  allocat.OUT_OUT_FLAG
		,@Allocation_Date = allocat.allocation_Date
		,@MNo_Standard = allocat.MNo --mno_standard
		,@Pdcd = allocat.PDCD --PDCD
		,@ORNo = allocat.ORNo --ORNO
		,@Tomson_Mark_1 = allocat.Tomson1
		,@Tomson_Mark_2 = allocat.Tomson2
		,@Tomson_Mark_3 = allocat.Tomson3
		,@WFLotNo = allocat.WFLotNo
		,@Label_Class = allocat.Label_Class
		,@ProductionClass = allocat.Production_Class --production_class
		,@ProductClass = allocat.Product_Class --product_class
		,@Product_Control_Clas = allocat.Product_Control_Cl_1 --product_control_class
		,@is_pc_instruction_code = case when [lots].[pc_instruction_code] is null or [lots].[pc_instruction_code] = '' then 0 else [lots].[pc_instruction_code] end
		from [APCSProDB].[method].[package_groups] with (NOLOCK) 
			inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[package_group_id] = [package_groups].[id]
			inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[package_id] = [packages].[id]
			inner join [APCSProDB].[trans].[lots] with (NOLOCK) 
				on [lots].[act_device_name_id] = [device_names].[id]
		inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[allocat_temp] as allocat on allocat.LotNo = @lotno_standard
		where lot_no = @lotno_standard
	END

    -- Insert statements for procedure here

	select @Emp_int = CONVERT(INT, @empno) --update 2021/02/04

	DECLARE @op_no_len_value char(5) = '';

	select  @op_no_len_value =  case when LEN(CAST(@empno as char(5))) = 4 then '0' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 3 then '00' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 2 then '000' + CAST(@empno as char(5))
			when LEN(CAST(@empno as char(5))) = 1 then '0000' + CAST(@empno as char(5))
			else CAST(@empno as char(5)) end 

	--check status pc_instruction_code if is_pc = 2 do not update wip state is 70 
	IF @is_pc_instruction_code != 2
	BEGIN
		--add query update wip_state Date : 2021/11/05 Time : 12.23
		UPDATE [APCSProDB].[trans].[lots]
		SET wip_state = 70
		WHERE lot_no = @lotno_standard
	END
	

	DECLARE @CheckWipStateValue tinyint = 0
	
	select @Lot_Id = id,@CheckWipStateValue = wip_state from APCSProDB.trans.lots where lot_no = @lotno_standard

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
		,'EXEC [dbo].[tg_sp_set_hasuu_in_stock_nomix] @empno = ''' + @empno + ''',@lotno_standard = ''' + @lotno_standard + ''',@lotno_standard_qty = ''' + CONVERT (varchar (10), @lotno_standard_qty) + ''',@wip_state = ''' + CONVERT (varchar (5), @CheckWipStateValue) + ''''
		,@lotno_standard

	
		--insert table : surpluse
		IF EXISTS(SELECT * FROM [APCSProDB].[trans].[surpluses] WHERE serial_no = @lotno_standard)
		BEGIN
			-- UPDATE HASUU WIP 70
			UPDATE [APCSProDB].[trans].[surpluses]
			SET 
				[pcs] = @lotno_standard_qty
				, [in_stock] = '2'
				, [location_id] = ''
				, [acc_location_id] = ''
				, [updated_at] = GETDATE()
				, [updated_by] = @Emp_int
			WHERE [serial_no] = @lotno_standard

			
		END
		ELSE
		BEGIN
			-- INSERT HASUU WIP 70
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
		   )
			--SELECT [nu].[id] - 1 + row_number() over (order by [surpluses].[id]) AS id
			SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
			, @Lot_Id AS lot_id
			, @lotno_standard_qty AS pcs
			, @lotno_standard AS serial_no
			, '2' AS in_stock
			, '' AS location_id
			, '' AS acc_location_id
			, GETDATE() AS created_at
			, @Emp_int AS created_by
			, GETDATE() AS updated_at
			, @Emp_int AS updated_by
			, @Pdcd
			, @Tomson_Mark_3
			, @MNo_Standard
			, @User_code
			, @Product_Control_Clas
			, @ProductClass
			, @ProductionClass
			, @RankNo
			, @HINSYU_Class
			, @Label_Class
			FROM [APCSProDB].[trans].[surpluses]
			INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'surpluses.id'

			set @r = @@ROWCOUNT
			update [APCSProDB].[trans].[numbers]
			set id = id + @r 
			from [APCSProDB].[trans].[numbers]
			where name = 'surpluses.id'

		END	

		    -- UPDATE 2021/03/30
			-- INSERT RECORD CLASS TO TABLE tg_sp_set_surpluse_records
		    BEGIN TRY
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
				,@sataus_record_class = 1
				,@emp_no_int = @Emp_int --update 2021/12/07 time : 12.00
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status ,'INSERT DATA SURPLUSE_RECORDS ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
			END CATCH

			--check status pc_instruction_code if is_pc = 2 do not update wip state is 70 
			IF @is_pc_instruction_code != 2
			BEGIN
				BEGIN TRY
				UPDATE [APCSProDB].[trans].[lots]
				SET 
						qty_hasuu = @lotno_standard_qty
						,qty_combined = 0
						,qty_out = 0
						,wip_state = 70
				WHERE lot_no = @lotno_standard
				END TRY
				BEGIN CATCH 
					INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
						([record_at]
						, [record_class]
						, [login_name]
						, [hostname]
						, [appname]
						, [command_text]
						, [lot_no]
						)
					SELECT GETDATE()
						, '4'
						, ORIGINAL_LOGIN()
						, 'StoredProcedureDB'
						, 'TGSYSTEM'
						, 'EXEC [dbo].[tg_sp_set_hasuu_in_stock_nomix] @lotno_standard = ''' + @lotno_standard + ''' ERROR UPDATE WIP STATE [APCSProDB].[trans].[lots]'
						, @lotno_standard
				END CATCH
			END
			
			--add condition date modify : 2022/02/11 time : 16.15
			IF @is_pc_instruction_code = 2
			BEGIN
				UPDATE [APCSProDB].[trans].[lots]
				SET 
						qty_hasuu = @lotno_standard_qty
						,qty_combined = 0
						,qty_out = 0
				WHERE lot_no = @lotno_standard
			END

			 -- UPDATE 2021/05/29
			-- INSERT RECORD CLASS TO TABLE lot_combine
			BEGIN TRY
				EXEC [StoredProcedureDB].[atom].[sp_set_tsugitashi_tg] 
				 @master_lot_no = @lotno_standard
				,@hasuu_lot_no = ''
				,@masterqty = @lotno_standard_qty
				,@hasuuqty = 0
				,@OP_No = @Emp_int
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status ,'INSERT DATA LOT_COMBINE ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
			END CATCH

			BEGIN TRY
				-- CREATE 2021/05/29
				-- INSERT DATA IN TABLE LABEL_HISTORY
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @lotno_standard
				,@process_name = 'TP'
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status ,'INSERT DATA LABEL_HISTORY ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
			END CATCH

			--check status pc_instruction_code if is_pc = 2 do not update wip state is 70 
			IF @is_pc_instruction_code != 2
			BEGIN
				--check wip state lot Create : 2021/10/29
				select @check_wip_state = wip_state from APCSProDB.trans.lots where lot_no = @lotno_standard
				IF @check_wip_state != 70
				BEGIN
					UPDATE [APCSProDB].[trans].[lots]
					SET wip_state = 70
					WHERE lot_no = @lotno_standard
				END
			END
			

END
