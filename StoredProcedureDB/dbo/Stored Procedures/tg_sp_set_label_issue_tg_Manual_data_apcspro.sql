-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,2022/03/15 time : 13.51,update stock class = 01 all table>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_label_issue_tg_Manual_data_apcspro]
	-- Add the parameters for the stored procedure here
	@lotno_standard varchar(10) = '',
	@empno char(6) = ' ' --edit @empno form char 5 is char 6
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Lot_No char(10) = ' '
	DECLARE @hasuu_lot char(10) = ' '
	DECLARE @MNo_Standard char(10) = ' '
	DECLARE @MNo_Hasuu char(10) = ' '
	DECLARE @Package char(10) = ' '
	DECLARE @Rank char(5) = ' '
	DECLARE @Standerd_QTY char(7) = ' '
	DECLARE @ASSY_Model_Name char(20) = ' '
	DECLARE @Hasuu_Stock_QTY int
	DECLARE @QtyPass_Standard int
	DECLARE @Total int
	DECLARE @Reel int
	DECLARE @Totalhasuu int 
	DECLARE @qty_out int
	DECLARE @Qty_Standard_Lsiship int
	DECLARE @hasuu_qty int
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
	DECLARE @Packing_Standerd_QTY int
	DECLARE @datestart as varchar(50) = cast( GETDATE() as date) 
	DECLARE @Hasuu_before int = 0
	DECLARE @Emp_int INT; --update 2021/03/16
	--Add Parameter Date : 2021/12/06 
	DECLARE @Lotno_Allocat_Count Int = 0
	--Add Parameter Date : 2022/02/03 time : 09.10 
	DECLARE @machine_name varchar(15) = ''

	SELECT @Lotno_Allocat_Count = COUNT(*) FROM APCSProDB.method.allocat where LotNo = @lotno_standard

    -- Insert statements for procedure here
	select @Emp_int = CONVERT(INT, @empno) --update 2021/02/04

	DECLARE @op_no_len_value char(5) = '';

	select  @op_no_len_value =  case when LEN(CAST(@Emp_int as char(5))) = 4 then '0' + CAST(@Emp_int as char(5))
			when LEN(CAST(@Emp_int as char(5))) = 3 then '00' + CAST(@Emp_int as char(5))
			when LEN(CAST(@Emp_int as char(5))) = 2 then '000' + CAST(@Emp_int as char(5))
			when LEN(CAST(@Emp_int as char(5))) = 1 then '0000' + CAST(@Emp_int as char(5))
			else CAST(@Emp_int as char(5)) end 


	--check condition data allocat is null มีข้อมูลหรือเปล่า
	IF @Lotno_Allocat_Count != 0
	BEGIN
		select @Lot_No = tranlot.[lot_no] 
		,@Package = allocat.Type_Name
		,@ROHM_Model_Name = allocat.ROHM_Model_Name
		,@ASSY_Model_Name = allocat.ASSY_Model_Name
		,@R_Fukuoka_Model_Name = [allocat].[R_Fukuoka_Model_Name]
		,@QtyPass_Standard = tranlot.[qty_pass]
		,@Totalhasuu = (tranlot.[qty_pass])%([device_names].[pcs_per_pack])  -- จำนวนงานเดิมที่มีอยู่รวมกับจำนวน hasuu ที่ส่งค่ามาหารจำนวน standard
		,@Standerd_QTY = CAST([device_names].[pcs_per_pack] AS char(7)) 
		,@qty_out = (tranlot.[qty_pass]/[device_names].[pcs_per_pack])*[device_names].[pcs_per_pack]  -- จำนวนงานเต็ม reel ทั้งหมด
		,@MNo_Standard = allocat.MNo  --mno_standard
		,@TIRank = allocat.TIRank 
		,@Rank = allocat.rank 
		,@TPRank = allocat.TPRank 
		,@SUBRank = allocat.SUBRank 
		,@Pdcd = allocat.PDCD 
		,@Mask = allocat.Mask 
		,@KNo = allocat.KNo
		,@ORNo = allocat.ORNo 
		,@Packing_Standerd_QTY = case when allocat.Packing_Standerd_QTY is null then '-' 
			else allocat.Packing_Standerd_QTY end  
		,@Tomson_Mark_1 = allocat.Tomson1 
		,@Tomson_Mark_2 = allocat.Tomson2 
		,@Tomson_Mark_3 = allocat.Tomson3 
		,@WFLotNo = allocat.WFLotNo 
		,@LotNo_Class = allocat.LotNo_Class 
		,@User_code = allocat.User_Code 
		,@Product_Control_Clas = allocat.Product_Control_Cl_1 
		,@ProductClass = allocat.Product_Class
		,@ProductionClass = allocat.Production_Class 
		,@RankNo = allocat.Rank_No 
		,@HINSYU_Class = allocat.HINSYU_Class 
		,@Label_Class = allocat.Label_Class 
		,@Out_Out_Flag = allocat.OUT_OUT_FLAG 
		,@Allocation_Date  = allocat.allocation_Date
		FROM [APCSProDB].[trans].[lots]  as tranlot
		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = tranlot.[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] as device_names  ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] as packages ON [device_names].[package_id]  = [packages].[id]
		INNER JOIN APCSProDB.method.allocat as allocat ON tranlot.lot_no = allocat.LotNo 
		WHERE tranlot.[lot_no] = @lotno_standard
	END
	ELSE
	BEGIN
		select @Lot_No = tranlot.[lot_no] 
		,@Package = allocat.Type_Name
		,@ROHM_Model_Name = allocat.ROHM_Model_Name
		,@ASSY_Model_Name = allocat.ASSY_Model_Name
		,@R_Fukuoka_Model_Name = [allocat].[R_Fukuoka_Model_Name]
		,@QtyPass_Standard = tranlot.[qty_pass]
		,@Totalhasuu = (tranlot.[qty_pass])%([device_names].[pcs_per_pack])  -- จำนวนงานเดิมที่มีอยู่รวมกับจำนวน hasuu ที่ส่งค่ามาหารจำนวน standard
		,@Standerd_QTY = CAST([device_names].[pcs_per_pack] AS char(7)) 
		,@qty_out = (tranlot.[qty_pass]/[device_names].[pcs_per_pack])*[device_names].[pcs_per_pack]  -- จำนวนงานเต็ม reel ทั้งหมด
		,@MNo_Standard = allocat.MNo  --mno_standard
		,@TIRank = allocat.TIRank 
		,@Rank = allocat.rank 
		,@TPRank = allocat.TPRank 
		,@SUBRank = allocat.SUBRank 
		,@Pdcd = allocat.PDCD 
		,@Mask = allocat.Mask 
		,@KNo = allocat.KNo
		,@ORNo = allocat.ORNo 
		,@Packing_Standerd_QTY = case when allocat.Packing_Standerd_QTY is null then '-' 
			else allocat.Packing_Standerd_QTY end  
		,@Tomson_Mark_1 = allocat.Tomson1 
		,@Tomson_Mark_2 = allocat.Tomson2 
		,@Tomson_Mark_3 = allocat.Tomson3 
		,@WFLotNo = allocat.WFLotNo 
		,@LotNo_Class = allocat.LotNo_Class 
		,@User_code = allocat.User_Code 
		,@Product_Control_Clas = allocat.Product_Control_Cl_1 
		,@ProductClass = allocat.Product_Class
		,@ProductionClass = allocat.Production_Class 
		,@RankNo = allocat.Rank_No 
		,@HINSYU_Class = allocat.HINSYU_Class 
		,@Label_Class = allocat.Label_Class 
		,@Out_Out_Flag = allocat.OUT_OUT_FLAG 
		,@Allocation_Date  = allocat.allocation_Date
		FROM [APCSProDB].[trans].[lots]  as tranlot
		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = tranlot.[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] as device_names  ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] as packages ON [device_names].[package_id]  = [packages].[id]
		INNER JOIN APCSProDB.method.allocat_temp as allocat ON tranlot.lot_no = allocat.LotNo 
		WHERE tranlot.[lot_no] = @lotno_standard
	END

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
		,'EXEC [dbo].[tg_sp_set_label_issue_tg_Manual_data_apcspro] @empno = ''' + @empno + ''',@lotno_standard = ''' + @lotno_standard + ''',@Total = ''' + CAST(@QtyPass_Standard as varchar(7)) + ''''
		,@lotno_standard


				
			    --INSERT Hasuu TO TABLE tg_sp_set_surpluse
				EXEC [StoredProcedureDB].[atom].[sp_set_label_issued_tg] @lot_no = @lotno_standard
				,@qty_hasuu_brfore = @Hasuu_before
				,@Empno_int_value = @Emp_int
				,@stock_class = '01'  --add parameter date : 2022/03/10 time : 14.42

		    -- UPDATE 2021/03/30
			-- INSERT RECORD CLASS TO TABLE tg_sp_set_surpluse_records
		    BEGIN TRY
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
				,@sataus_record_class = 1
				,@emp_no_int = @Emp_int --update 2021/12/07 time : 11.56
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status ,'INSERT DATA SURPLUSE_RECORDS ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
			END CATCH

		    -- UPDATE 2021/03/30
			-- INSERT RECORD CLASS TO TABLE lot_combine
			BEGIN TRY
				EXEC [StoredProcedureDB].[atom].[sp_set_tsugitashi_tg] 
				 @master_lot_no = @lotno_standard
				,@hasuu_lot_no = ''
				,@masterqty = @QtyPass_Standard
				,@hasuuqty = 0
				,@OP_No = @Emp_int
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status ,'INSERT DATA LOT_COMBINE ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
			END CATCH

			BEGIN TRY
				-- CREATE 2021/03/09
				-- INSERT DATA IN TABLE LABEL_HISTORY
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @lotno_standard
				,@process_name = 'TP'
			END TRY
			BEGIN CATCH 
				SELECT 'FALSE' AS Status ,'INSERT DATA LABEL_HISTORY ERROR !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
			END CATCH

			BEGIN TRY
				--Set Record Class = 46 is TG Show on web Atom //Date Create : 2022/02/03 Time : 09.10
				EXEC [StoredProcedureDB].[trans].[sp_set_record_class_lot_process_records]
				@lot_no = @lotno_standard
				,@opno = @empno
				,@record_class = 46
				,@mcno = @machine_name
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
					, 'EXEC [dbo].[tg_sp_set_label_issue_tg_Manual_data_apcspro Create Record Class TG Error] @lotno_standard = ''' + @lotno_standard 
					, @lotno_standard
			END CATCH

END
