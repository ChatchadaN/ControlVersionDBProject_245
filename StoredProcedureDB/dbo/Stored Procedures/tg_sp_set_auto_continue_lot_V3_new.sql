-- =============================================
-- Author:		<Author,,Name : Vanatjaya P. (009131)>
-- Create date: <Create Date,,>
-- Last Update: <Last Date,2024.DEC.26 Time : 11.16,>
-- Description:	<Description, Change empno is empno_id>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_auto_continue_lot_V3_new]
	-- Add the parameters for the stored procedure here
	 @lotno_standard varchar(10) = ' '
	,@hasuu_lot varchar(10) = ' '
	,@hasuu_qty int = 0
	,@lotno_standard_qty int = 0
	,@empno varchar(6) = ' '
	,@MNo_Hasuu char(10) = ' '
	,@package_loths varchar(10) = ''
	,@device_loths varchar(20) = ' '
	--add parameter 2021/11/10
	,@process_name varchar(5) = ''
	--add parameter 2022/02/02 time : 09.19
	,@machine_name varchar(15) = ''
	--add parameter 2022/03/16 time : 10.57
	,@machine_id int = 0
	--add parameter 2023/09/11 time : 16.20
	,@continue_lot_mode varchar(1) = ''  --1 is mode continue lot, 0 is not mode continue lot, blank is by pass

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Lot_No char(10) = ' '
	DECLARE @Check_Lot_Hasuu char(10) = ' ' --ใช้ check lot hasuu ว่ามีค่าใน allocat หรือเปล่า
	DECLARE @MNo_Standard char(10) = ' '
	DECLARE @Package char(10) = ' '
	DECLARE @Rank char(5) = ' '
	DECLARE @Rank_hasuu char(5) = ' '
	DECLARE @Rank_hasuu_H_Stock char(5) = ' '
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
	DECLARE @Tomson_Mark_3_lot_hasuu char(4) = ' '
	DECLARE @Tomson_Mark_3_lot_hasuu_H_Stock char(4) = ' '
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
	DECLARE @Chk_Fristlot char(10) = ' '
	DECLARE @Lot_id INT --create 2020/11/23
	DECLARE @datestart as varchar(50) = cast( GETDATE() as date) 
	DECLARE @EmpNo_int INT --update 2021/02/04
	DECLARE @EmpNo_Char char(5) = ' ' --update 2021/02/11
	DECLARE @count_lotid_fristlot int = 0 --update 2021/05/23
	DECLARE @Lot_Type_Hasuu char(1);
	DECLARE @Lot_Type_Standard char(1);
	DECLARE @MNo_Hasuu_Value char(10) = ' '
	DECLARE @Check_lot_label_issue varchar(10) = ''
	DECLARE @Pcs_Per_Pack int = 0 --add parameter 2021/10/21
	DECLARE @Check_in_stock_hasuu_before tinyint = null
	DECLARE @Check_Record_Allocat int = 0
	DECLARE @GetMarknoHasuuLot char(10) = ''
	DECLARE @GetPackageHasuuLot varchar(10) = ''
	DECLARE @GetDeviceHasuuLot varchar(20) = ''
	DECLARE @GetPCCode int = null
	--------------------------------------------------------------
	
	--Add log Access Store : tg_sp_set_auto_continue_lot_V3_new  2023/03/14 time : 08.27
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
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [dbo].[tg_sp_set_auto_continue_lot_V3_Access_Store] @lotno_standard = ''' + @lotno_standard 
		  + ''', @continue_lot_mode = ''' + @continue_lot_mode + ''''
		, @lotno_standard
	
	--add condition check data is date : 2021/12/22 time : 15.49
	DECLARE @check_data_is int = 0
	DECLARE @text varchar(max)
	declare @table table(
	 count_ int
	)

	--- close query 2022/12/21 time : 13.50
	--SET @text = 'SELECT [count] FROM OPENROWSET(''SQLNCLI'',  
 --  ''Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship'',
 --  ''SELECT COUNT(HASUU_LotNo) as [count] FROM [DBLSISHT].[dbo].[MIX_HIST] with (NOLOCK) WHERE HASUU_LotNo = ''''' + @lotno_standard + ''''''')';
	--INSERT INTO @table
	--EXECUTE(@text);
	--- open query 2022/12/21 time : 13.50
	INSERT INTO @table
	SELECT COUNT(HASUU_LotNo) as [count_] FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WHERE HASUU_LotNo = @lotno_standard;

	SET @check_data_is = (select [count_] from @table);
	---------------------------------------------------------------
	select @EmpNo_int = CONVERT(INT, @empno) --update 2021/02/04
	select @EmpNo_Char = CONVERT(char(5),@EmpNo_int); --update 2021/02/11

	--update 2021/02/17
	--DECLARE @op_no_len char(5);
	DECLARE @op_no_len_value char(5) = '';
	select  @op_no_len_value =  case when LEN(CAST(@EmpNo_int as char(5))) = 4 then '0' + CAST(@EmpNo_int as char(5))
			when LEN(CAST(@EmpNo_int as char(5))) = 3 then '00' + CAST(@EmpNo_int as char(5))
			when LEN(CAST(@EmpNo_int as char(5))) = 2 then '000' + CAST(@EmpNo_int as char(5))
			when LEN(CAST(@EmpNo_int as char(5))) = 1 then '0000' + CAST(@EmpNo_int as char(5))
			else CAST(@EmpNo_int as char(5)) end 

	------------------------------ Start Get EmpnoId #Modify : 2024/12/26 ------------------------------
	DECLARE @GetEmpno varchar(6) = ''
	DECLARE @EmpnoId int = null
	SELECT @GetEmpno = FORMAT(CAST(@empno AS INT), '000000')
	SELECT @EmpnoId = id FROM [APCSProDB].[man].[users] WHERE [emp_num] = @GetEmpno
	------------------------------ End Get EmpnoId #Modify : 2024/12/26 --------------------------------

	--Check Hasuu lot is not null but hasuu_qty (hasuu_bofore) is zero (0) give call data hasuu qty form surpluses table >> Date Modify : 2024/06/18 Time : 14.54 by Aomsin support case TP Cellcon <<
	--IF @process_name IN ('TP','MAP')  --Close condition for support TP Cellcon 2024/06/24 time 13.14 by Aomsin
	--BEGIN
	--	IF @hasuu_qty = 0 and @hasuu_lot != ''
	--	BEGIN
	--		SELECT @hasuu_qty = pcs FROM APCSProDB.trans.surpluses where serial_no = @hasuu_lot
			
	--		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--		([record_at]
	--		  , [record_class]
	--		  , [login_name]
	--		  , [hostname]
	--		  , [appname]
	--		  , [command_text] 
	--		  , [lot_no]) 
	--		SELECT GETDATE()
	--			, '4'
	--			, ORIGINAL_LOGIN()
	--			, HOST_NAME()
	--			, APP_NAME()
	--				,'EXEC [dbo].[tg_sp_set_auto_continue_lot_V3 call qty hasuu form surpluses table becuase tp cellcon send hasuu before data is 0] @lotno_standard = ''' + ISNULL(@lotno_standard,'NULL')
	--				+ ''', @hasuu_lot = ''' + ISNULL(@hasuu_lot,'NULL') 
	--				+ ''', @hasuu_qty = ''' + ISNULL(CONVERT (varchar (10), @hasuu_qty),'NULL') 
	--				+ ''', @lotno_standard_qty = '''+ ISNULL(CONVERT(varchar (10), @lotno_standard_qty),'NULL') 
	--				+ ''', @empno = ''' + ISNULL(@empno,'NULL') +  ''''
	--			, @lotno_standard
	--	END
	--END
	
	
	select @Check_Record_Allocat = COUNT(*) from [APCSProDB].[method].[allocat] where LotNo = @lotno_standard
	--Add Condition Check Record in table Allocat --> Update 2022/11/17 Time : 13.01
	IF @Check_Record_Allocat <> 0
	BEGIN
		select @Lot_No = tranlot.[lot_no] 
		,@Lot_id = [tranlot].[id]
		,@Package = allocat.Type_Name
		,@ROHM_Model_Name = allocat.ROHM_Model_Name
		,@ASSY_Model_Name =  allocat.ASSY_Model_Name
		,@R_Fukuoka_Model_Name = allocat.R_Fukuoka_Model_Name
		,@TIRank = allocat.TIRank
		,@Rank = allocat.Rank
		,@TPRank = allocat.TPRank
		,@SUBRank = allocat.SUBRank
		,@Mask = Mask
		,@KNo = KNo
		,@QtyPass_Standard = tranlot.[qty_pass]
		,@Total = (@lotno_standard_qty + @hasuu_qty)  -- จำนวนงานเดิมที่มีอยู่รวมกับจำนวน hasuu ที่ส่งค่ามา
		,@Totalhasuu = (@lotno_standard_qty + @hasuu_qty)%(allocat.Packing_Standerd_QTY) -- จำนวนงานเดิมที่มีอยู่รวมกับจำนวน hasuu ที่ส่งค่ามาหารจำนวน standard --> use current
		,@Standerd_QTY = CAST(allocat.Packing_Standerd_QTY AS char(7)) --edit 2021/01/14  --> use current
		--,@Qty_Full_Reel_All = (allocat.Packing_Standerd_QTY) * ((@lotno_standard_qty + @hasuu_qty)/(allocat.Packing_Standerd_QTY)) -- จำนวนงานเต็ม reel ทั้งหมด --> no use current
		,@Qty_Standard_Lsiship = ((allocat.Packing_Standerd_QTY) * ((@lotno_standard_qty + @hasuu_qty)/(allocat.Packing_Standerd_QTY)) - @hasuu_qty) --> use current
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
		,@Pcs_Per_Pack = device_names.pcs_per_pack --standard_reel type int
		FROM [APCSProDB].[trans].[lots]  as tranlot
		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = tranlot.[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] as device_names  ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] as packages ON [device_names].[package_id]  = [packages].[id]
		INNER JOIN [APCSProDB].[method].[allocat] as allocat ON tranlot.lot_no = allocat.LotNo 
		WHERE tranlot.[lot_no] = @lotno_standard
	END
	ELSE
	BEGIN
		--USE TABLE : allocat_temp
		select @Lot_No = tranlot.[lot_no] 
		,@Lot_id = [tranlot].[id]
		,@Package = allocat.Type_Name
		,@ROHM_Model_Name = allocat.ROHM_Model_Name
		,@ASSY_Model_Name =  allocat.ASSY_Model_Name
		,@R_Fukuoka_Model_Name = allocat.R_Fukuoka_Model_Name
		,@TIRank = allocat.TIRank
		,@Rank = allocat.Rank
		,@TPRank = allocat.TPRank
		,@SUBRank = allocat.SUBRank
		,@Mask = Mask
		,@KNo = KNo
		,@QtyPass_Standard = tranlot.[qty_pass]
		,@Total = (@lotno_standard_qty + @hasuu_qty)  -- จำนวนงานเดิมที่มีอยู่รวมกับจำนวน hasuu ที่ส่งค่ามา
		,@Totalhasuu = (@lotno_standard_qty + @hasuu_qty)%(allocat.Packing_Standerd_QTY) -- จำนวนงานเดิมที่มีอยู่รวมกับจำนวน hasuu ที่ส่งค่ามาหารจำนวน standard  --> use current
		,@Standerd_QTY = CAST(allocat.Packing_Standerd_QTY AS char(7)) --edit 2021/01/14  --> use current
		--,@Qty_Full_Reel_All = (allocat.Packing_Standerd_QTY) * ((@lotno_standard_qty + @hasuu_qty)/(allocat.Packing_Standerd_QTY)) -- จำนวนงานเต็ม reel ทั้งหมด  --> no use current
		,@Qty_Standard_Lsiship = ((allocat.Packing_Standerd_QTY) * ((@lotno_standard_qty + @hasuu_qty)/(allocat.Packing_Standerd_QTY)) - @hasuu_qty) --> use current
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
		,@Pcs_Per_Pack = device_names.pcs_per_pack --standard_reel type int
		FROM [APCSProDB].[trans].[lots]  as tranlot
		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = tranlot.[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] as device_names  ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] as packages ON [device_names].[package_id]  = [packages].[id]
		INNER JOIN [APCSProDB].[method].[allocat_temp] as allocat ON tranlot.lot_no = allocat.LotNo 
		WHERE tranlot.[lot_no] = @lotno_standard
	END

	--Check lot type hasuu if lot type is d-lot to use 'MX' [Add condtion Date : 2021/06/16]
	select @Lot_Type_Hasuu = SUBSTRING(lot_no,5,1) from APCSProDB.trans.lots where lot_no = @hasuu_lot
	select @Lot_Type_Standard = SUBSTRING(lot_no,5,1) 
		,@GetPCCode = pc_instruction_code
	from APCSProDB.trans.lots where lot_no = @lotno_standard

	--Check Fristlot or Continuelot >> Create : 2021/05/23 <<
	select @count_lotid_fristlot =  COUNT(lot_id) from APCSProDB.trans.lot_combine where lot_id = @Lot_id
	
	--Check D-lot >> Create : 2024/02/06 Time : 11.19 by Aomsin << Add Condition Check G,H,B-lot >> Update : 2024/02/27 Time : 13:59 by Aomsin
	IF @Lot_Type_Standard IN ('D','G','E','H','B','F','A')
	BEGIN
		select @count_lotid_fristlot =  COUNT(lot_id) from APCSProDB.trans.lot_combine where lot_id = (select id from APCSProDB.trans.lots where lot_no = @lotno_standard)
	END

	IF @Lot_Type_Standard IN ('D','G','E','H','B') --Add Condition Check G,H,B-lot >> Update : 2024/02/27 Time : 13:59 by Aomsin
	BEGIN
		IF @count_lotid_fristlot > 0
		BEGIN
			SELECT 'TRUE' AS Status ,'There is mixing or tg information now !!' AS Error_Message_ENG,N'มีการทำ Mixing หรือ tg เรียบร้อยแล้ว !!' AS Error_Message_THA ,N'' AS Handling
			RETURN
		END
		ELSE
		BEGIN
			IF @Lot_Type_Standard IN ('G','E','H','B')
			BEGIN
				SELECT 'FALSE' AS Status ,'No data tg and Can not auto tg Type G,E,H,B-lot !!' AS Error_Message_ENG,N'ไม่มีข้อมูลการทำ tg และ ไม่สามารถนำ G,E,H,B-lot มาทำ auto tg ได้ !!' AS Error_Message_THA ,N'กรุณาทำ Mixing หรือ TG ผ่านเว็บ LSMS เท่านั้น !!' AS Handling
				RETURN
			END
			ELSE
			BEGIN
				SELECT 'FALSE' AS Status ,'No data mixing d-lot !!' AS Error_Message_ENG,N'ไม่มีข้อมูลการทำ mixing d-lot !!' AS Error_Message_THA ,N'กรุณาตรวจสอบข้อมูลการ mixing !!' AS Handling
				RETURN
			END
		END
	END

	--Check Sum Qty < Standard ห้ามทำ TG กัน 2022/11/14 Time 09.16
	IF @Total < @Pcs_Per_Pack
	BEGIN
		--add condition check hasuu stock in work (ถ้าเป็น map process จะสามารถทำ hasuu stock in แบบ auto ได้)
		IF @process_name = 'MAP'  --update date : 2023/10/25 time : 14.22 by Aomsin
		BEGIN
			IF @count_lotid_fristlot = 0
			BEGIN
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_hasuu_in_stock_auto] 
				  @lotno_standard = @lotno_standard
				, @lotno_standard_qty = @lotno_standard_qty
				, @empno = @empno
				, @is_process_name = @process_name  

				SELECT 'TRUE' AS Status ,'Auto hasuu stock in is done !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END
			ELSE
			BEGIN
				SELECT 'TRUE' AS Status ,'Have has hasuu stock in is now !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END
		END
		ELSE
		BEGIN
			--Check Machine_id = 1140 (TP-FTTP-02) give Run Test Functio Auto Hasuu Stock In at TP Process Floor.2 >> Modify : 2024/06/07 Time : 10.19 By Aomsin << test close time : 17.14
			IF @process_name = 'FT-TP' --open test 2024/09/09 time : 13.29
			BEGIN
				IF @count_lotid_fristlot = 0
				BEGIN
					EXEC [StoredProcedureDB].[dbo].[tg_sp_set_hasuu_in_stock_auto] 
					  @lotno_standard = @lotno_standard
					, @lotno_standard_qty = @lotno_standard_qty
					, @empno = @empno
					, @is_process_name = @process_name  

					SELECT 'TRUE' AS Status ,'Auto hasuu stock in is done !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA,N' กรุณาติดต่อ System' AS Handling
					RETURN
				END
				ELSE
				BEGIN
					SELECT 'TRUE' AS Status ,'Have has hasuu stock in is now !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA,N' กรุณาติดต่อ System' AS Handling
					RETURN
				END
			END
			ELSE
			BEGIN
				IF @GetPCCode IN (1,11,13) AND @Lot_Type_Standard IN ('A','F') --2025/01/24 time : 14.01 by Aomsin
				BEGIN
					IF @count_lotid_fristlot > 0
					BEGIN
						SELECT 'TRUE' AS Status ,'Have has PC-Request (Sample Lot) From LSMS WEB !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA,N' กรุณาติดต่อ System' AS Handling
						RETURN
					END
					ELSE
					BEGIN
						SELECT 'FALSE' AS Status 
							,'PC-Request ' + @Lot_Type_Standard + ' slip (Sample Lot) ERROR' AS Error_Message_ENG
							,N'ไม่มีข้อมูลการทำ PC-Request ' + @Lot_Type_Standard +' slip (Sample Lot) จาก Web LSMS'  AS Error_Message_THA 
							,N'กรุณาตรวจสอบข้อมูลการทำ PC-Request ด้วยคะ' AS Handling
						RETURN
					END
				END
				ELSE
				BEGIN
					SELECT 'FALSE' AS Status 
						,'MixLot ERROR' AS Error_Message_ENG
						,N'จำนวนงานที่รวมกันไม่ถึง standard reel กรุณาตรวจสอบ Hasuu Lot ก่อนหน้าด้วยคะ'  AS Error_Message_THA 
						,N'กรุณาตรวจสอบข้อมูลการทำ TG ด้วยคะ' AS Handling
					RETURN
				END
			END

			IF @GetPCCode IN (1,11,13) AND @Lot_Type_Standard IN ('A','F')  -->> Add conditon Date Modify 2024/06/14 time : 10.07 by Aomsin <<
			BEGIN
				IF @count_lotid_fristlot > 0
				BEGIN
					SELECT 'TRUE' AS Status ,'Have has PC-Request (Sample Lot) From LSMS WEB !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA,N' กรุณาติดต่อ System' AS Handling
					RETURN
				END
				ELSE
				BEGIN
					SELECT 'FALSE' AS Status 
						,'PC-Request ' + @Lot_Type_Standard + ' slip (Sample Lot) ERROR' AS Error_Message_ENG
						,N'ไม่มีข้อมูลการทำ PC-Request ' + @Lot_Type_Standard +' slip (Sample Lot) จาก Web LSMS'  AS Error_Message_THA 
						,N'กรุณาตรวจสอบข้อมูลการทำ PC-Request ด้วยคะ' AS Handling
					RETURN
				END
			END
			ELSE
			BEGIN
				SELECT 'FALSE' AS Status 
					,'MixLot ERROR' AS Error_Message_ENG
					,N'จำนวนงานที่รวมกันไม่ถึง standard reel กรุณาตรวจสอบ Hasuu Lot ก่อนหน้าด้วยคะ'  AS Error_Message_THA 
					,N'กรุณาตรวจสอบข้อมูลการทำ TG ด้วยคะ' AS Handling
				RETURN
			END
		END
	END

	--Check State Instock of Hasuu Lot 2022/10/19 Time : 10.44
	IF @hasuu_lot <> ' '
	BEGIN
		select @Check_in_stock_hasuu_before = in_stock from [APCSProDB].[trans].[surpluses] where serial_no = @hasuu_lot
		--Check record in surpluses is null --> Add Condition 2022/11/16 Time : 14.22
		IF @Check_in_stock_hasuu_before is null
		BEGIN
			SELECT 'FALSE' AS Status 
				,'MixLot Error Because Hasuu Lot Before is Null' AS Error_Message_ENG
				,N'ไม่พบข้อมูล Lot Hasuu Before : ' + @hasuu_lot + N' ไม่สามารถทำการ mix กันได้'  AS Error_Message_THA 
				,N'กรุณาตรวจสอบข้อมูลของ lot hasuu ก่อนหน้าด้วยคะ !!' AS Handling
			RETURN
		END
		ELSE
		BEGIN
			IF @Check_in_stock_hasuu_before <> 2
			BEGIN
				DECLARE @state_val nvarchar(50) = N''

				select @state_val = case when @Check_in_stock_hasuu_before = 0 then N'Hasuu Lot นี้ถูกใช้งานไปแล้ว !!'
								         when @Check_in_stock_hasuu_before = 1 then N'Hasuu Lot นีกำลังถูกใช้งานอยู่ !!' end

				SELECT 'FALSE' AS Status 
				,'MixLot Error' AS Error_Message_ENG
				,N'Lot Hasuu Before : ' + @hasuu_lot + N' Instock = ' + @state_val + N' ไม่สามารถทำการ mix กันได้'  AS Error_Message_THA 
				,N'กรุณาตรวจสอบข้อมูลของ lot hasuu ก่อนหน้าด้วยคะ !!' AS Handling
				RETURN
			END
		END
	END

	--update 2021/06/18 time 13.08
	---- # condition new 2023.06.28 13.44
	IF (@Lot_Type_Standard = 'B' or @Lot_Type_Hasuu = 'B')
	BEGIN
		SELECT 'FALSE' AS Status ,'MixLot ERROR !!' AS Error_Message_ENG,CONCAT(N'Lot Hasuu Before ',@hasuu_lot,N' และ ',@lotno_standard,N' ไม่สามารถทำการ mix กันได้') AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END
	---- # condition new 2023.06.28 13.44
	ELSE IF @Lot_Type_Standard = 'F' and @Lot_Type_Hasuu = 'D'
	BEGIN
		SELECT 'FALSE' AS Status ,'MixLot ERROR !!' AS Error_Message_ENG,N'Lot Hasuu Before ' + @hasuu_lot + N' และ ' + @lotno_standard + N' ไม่สามารถทำการ mix กันได้'  AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END
	ELSE IF @Lot_Type_Standard = 'A' and @Lot_Type_Hasuu = 'D'
	BEGIN
		SELECT 'FALSE' AS Status ,'MixLot ERROR !!' AS Error_Message_ENG,N'Lot Hasuu Before ' + @hasuu_lot + N' และ ' + @lotno_standard + N' ไม่สามารถทำการ mix กันได้'  AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END
	ELSE IF (@Lot_Type_Standard = 'A' and @Lot_Type_Hasuu = 'F') OR (@Lot_Type_Standard = 'F' and @Lot_Type_Hasuu = 'A')
	BEGIN
		SELECT 'FALSE' AS Status ,'MixLot ERROR !!' AS Error_Message_ENG,N'Lot Hasuu Before ' + @hasuu_lot + N' และ ' + @lotno_standard + N' ไม่สามารถทำการ mix กันได้'  AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END

	--Get Data Hasuu on Allocat
	select @Check_Lot_Hasuu = LotNo ,@Tomson_Mark_3_lot_hasuu = Tomson3
	,@Rank_hasuu = Rank 
	from [APCSProDB].[method].[allocat_temp] where LotNo = @hasuu_lot

	--check surpluses table
	select @Chk_Fristlot = serial_no from APCSProDB.trans.surpluses where serial_no = @lotno_standard
	
	IF @hasuu_lot != ''  -- add condition 2023/01/27 time : 11.24
	BEGIN
		--Get Data of Hasuu Lot , Add Parameter : 2023/01/17 Time : 13.39
		select @GetMarknoHasuuLot = sur.mark_no 
			,@GetPackageHasuuLot = pk.short_name 
			,@GetDeviceHasuuLot = dn.name 
		from APCSProDB.trans.surpluses as sur
		inner join APCSProDB.trans.lots as lot on sur.lot_id = lot.id
		inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
		inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
		where sur.serial_no = @hasuu_lot

		--Add Return Check MarkNo 2023/02/14 Time : 13.53
		--IF @GetMarknoHasuuLot = '' 
		--BEGIN
		--	SELECT 'FALSE' AS Status ,'MarkNo is Null of Lot Hasuu !!' AS Error_Message_ENG,N' ไม่พบข้อมูล MarkNo ของ lot Hasuu' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		--	RETURN
		--END

	END

	--Check Condition mix is type lot hasuu d-lot [Add condtion Date : 2021/06/16]
	IF @Lot_Type_Hasuu = 'D'
	BEGIN
		select @MNo_Hasuu_Value = 'MX'
	END
	ELSE 
	BEGIN
		select @MNo_Hasuu_Value = @GetMarknoHasuuLot
	END

	BEGIN TRY 
	IF @hasuu_qty != 0 
	BEGIN
		--check lotno record data hasuu before on table allocat is null
		IF @Check_Lot_Hasuu = ''
		BEGIN
			--Get data hasuu before in tabel surpluses ,Change get table form H_Stock is Surpluses of APCSPro 2022/11/16 time : 14.38
			select @Check_Lot_Hasuu = serial_no 
				, @Rank_hasuu = dn.rank
				, @Tomson_Mark_3_lot_hasuu = case when qc_instruction is null then '' else qc_instruction end 
			from APCSProDB.trans.surpluses as sur
			inner join APCSProDB.trans.lots as lot on lot.id = sur.lot_id
			inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
			where serial_no = @hasuu_lot

			IF @Check_Lot_Hasuu = '' 
			BEGIN
				SELECT 'FALSE' AS Status ,'SELECT DATA HASUU BEFORE ERROR !!' AS Error_Message_ENG,N' ไม่พบข้อมูลใน tabel allocal และ table Surpluses' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END
		END

		--add condition check condtition mix -->Date Create : 2022/01/20 Time : 16.12
		IF @Package != @GetPackageHasuuLot AND @ROHM_Model_Name != @GetDeviceHasuuLot AND @Rank != @Rank_hasuu AND @Tomson_Mark_3 != @Tomson_Mark_3_lot_hasuu
		BEGIN
			SELECT 'FALSE' AS Status ,'CONDITION MIX ERROR !!' AS Error_Message_ENG,N'เงื่อนไขการ mix ไม่ตรงกัน' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END

		IF @count_lotid_fristlot = 0 --Check Auto TG ??
		BEGIN
			
			IF @Package = @GetPackageHasuuLot AND @ROHM_Model_Name = @GetDeviceHasuuLot AND @Rank = @Rank_hasuu AND @Tomson_Mark_3 = @Tomson_Mark_3_lot_hasuu
				BEGIN

				--#2024/12/26 Time : 10.00 By Aomsin
				--SELECT 'FALSE' AS Status 
				--	,'Close to repair all Auto TG and Print Label systems (during 10.00 - 13.00)' AS Error_Message_ENG
				--	,N'ปิดปรับปรุงระบบ Auto TG และ Print Label ทั้งหมด (ในช่วงเวลา 10.00 - 13.00)' AS Error_Message_THA 
				--	,N' กรุณาติดต่อ System' AS Handling
				--RETURN

				--add condition check data at is Data : 2021/12/22 Time : 15.49
				IF @check_data_is = 0
				BEGIN
					--insrt into to DB-IS
					INSERT INTO [APCSProDWH].[dbo].[MIX_HIST_IF] (
						  --[M_O_No]
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
								 @lotno_standard
								,@lotno_standard
								,'01' --modify 20201218 stockclass 01 change 02,date update 2022/03/10 time : 14.52 stockclass 01 is 02
								,@package
								,@ROHM_Model_Name
								,@Pdcd
								,@ASSY_Model_Name
								,@R_Fukuoka_Model_Name
								,@TIRank
								,@rank
								,@TPRank
								,@SUBRank --subRank
								,@Mask --mask
								,@KNo --Kno
								,@MNo_Standard
								,'' --tomson1
								,'' --tomson2
								,@Tomson_Mark_3
								,@Allocation_Date
								,@ORNo
								,@WFLotNo
								,@LotNo_Class
								,@Label_Class
								,@Product_Control_Clas
								,@Standerd_QTY
								,@Qty_Standard_Lsiship -- จำนวนงานของ lot standard ที่หาร reel ลงตัว
								,@op_no_len_value
								,@Out_Out_Flag
								,GETDATE()
								,CURRENT_TIMESTAMP --timestamp_date
								,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
						),
						(					 
								 @lotno_standard
								,@hasuu_lot
								,'01' --modify 20201218 stockclass 01 change 02,date update 2022/03/10 time : 14.52 stockclass 01 is 02
								,@package
								,@ROHM_Model_Name
								,@Pdcd
								,@ASSY_Model_Name
								,@R_Fukuoka_Model_Name
								,@TIRank
								,@rank
								,@TPRank
								,@SUBRank --subrank
								,@Mask --mask
								,@KNo --kno
								--,@MNo_Hasuu --Mno_hasuu
								,@MNo_Hasuu_Value
								,'' --tomson1
								,'' --tomson2
								,@Tomson_Mark_3
								,@Allocation_Date 
								,@ORNo
								,@WFLotNo
								,@LotNo_Class
								,@Label_Class
								,@Product_Control_Clas
								,@Standerd_QTY
								,@hasuu_qty  --จำนวนของ hasuu ที่ส่งค่ามา
								,@op_no_len_value
								,@Out_Out_Flag
								,GETDATE()
								,CURRENT_TIMESTAMP --timestamp_date
								,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
						);

					--insrt into table LSI_SHIP to DB-IS
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
								 @lotno_standard
								,@package
								,@ROHM_Model_Name
								,@ASSY_Model_Name
								,@R_Fukuoka_Model_Name
								,@TIRank
								,@rank
								,@TPRank
								,@SUBRank --sub_rank
								,@Pdcd
								,@Mask --mask
								,@KNo --kno
								,@MNo_Standard
								,@ORNo
								,@Standerd_QTY
								,'' --tomson_1
								,'' --tomson_2
								,@Tomson_Mark_3
								,@WFLotNo
								,'' --lotno_class
								,'' --user_code
								,@Product_Control_Clas
								,@ProductClass
								,@ProductionClass
								,@RankNo
								,@HINSYU_Class
								,@Label_Class
								,@lotno_standard --standard_lotno
								,@hasuu_lot -- hasuu_lotno ตัวที่ 1
								,'' -- hasuu_lotno ตัวที่ 2 ถ้ามี
								,'' -- hasuu_lotno ตัวที่ 3 ถ้ามี
								,@MNo_Standard
								,@MNo_Hasuu_Value -- Mno_hsuu ตัวที่ 1 ถ้ามี
								,'' -- Mno_hsuu ตัวที่ 2 ถ้ามี
								,'' -- Mno_hsuu ตัวที่ 3 ถ้ามี
								,@lotno_standard_qty -- qty lot standard
								,@hasuu_qty -- qty hasuu_lotno ตัวที่ 1
								,'' -- qty hasuu_lotno ตัวที่ 2
								,'' -- qty hasuu_lotno ตัวที่ 3
								,0 -- จำนวนงานทั้งหมดที่พอดี reel , Shipment_QTY fix data = 0 >>edit date 2022/11/30 , Time : 13.45<<
								,@Total -- จำนวนงานทั้งหมด
								,''
								,''
								,@Out_Out_Flag
								,'01' --modify 20201218 stockclass 01 change 02,date update 2022/03/10 time : 14.52 stockclass 01 is 02
								,'2'
								,@Allocation_Date
								,'' -- delete_flage
								,@op_no_len_value --opno
								,CURRENT_TIMESTAMP --timestamp_date
								,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --timestamp_time
						);

					--insert into DB-IS H_STOCK to DB-IS
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
							 '01' --modify 20201218 stockclass 01 change 02,date update 2022/03/10 time : 14.52 stockclass 01 is 02
							,@Pdcd
							,@lotno_standard
							,@package
							,@ROHM_Model_Name
							,@ASSY_Model_Name
							,@R_Fukuoka_Model_Name
							,@TIRank
							,@rank
							,@TPRank
							,@SUBRank --subrank
							,@Mask --mask
							,@KNo --kno
							,@MNo_Standard
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
							,@Totalhasuu
							,'0'
							,''
							,@Out_Out_Flag --OUT_OUT_FLAG
							,''
							,@op_no_len_value
							,'1'  --DMY_IN_FALG , fix data = 1 >>edit date 2022/11/30 , Time : 13.47<<
							,''  --DMY_OUT_FLAG
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
						  @lotno_standard
						  ,1001 --process_no --1001 = tg
						  ,CURRENT_TIMESTAMP --Process_Date
						  ,DATEDIFF(s, @datestart , CURRENT_TIMESTAMP) --Process_Time
						  ,'0'
						  ,@QtyPass_Standard --จำนวน standard ใน column qty_pass to table : tranlot
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
						   @lotno_standard
						  ,@Package
						  ,@ROHM_Model_Name
						  ,@R_Fukuoka_Model_Name
						  ,@Rank
						  ,@TPRank
						  ,@Pdcd
						  ,@QtyPass_Standard
						  ,@ORNo
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
							   '10' --RECORD_CLASS   update : #2024/10/17 time: 11.14 by Aomsin
							  ,@ROHM_Model_Name
							  ,@lotno_standard
							  ,CURRENT_TIMESTAMP --OccurDate
							  ,@R_Fukuoka_Model_Name
							  ,@Rank
							  ,@TPRank
							  ,'0' --RED_BLACK_Flag
							  ,@Total
							  ,'0' --STOCK_QTY
							  ,@Pdcd --WAREHOUSECODE
							  ,@ORNo
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

				--open support process map Data : 2021/11/10 Time : 09.28
				--add process name FLFTTP data : 2023/07/10 Time : 09.30  flow FLFTTP
				IF @process_name = 'MAP' or @process_name = 'FL' --#close 2025.MAY.22 Time : 09.22 by Aomsin,--#open 2025.MAY.27 Time : 12.17 by Aomsin
				BEGIN
					UPDATE [APCSProDB].[trans].[lots]
					SET [qty_pass] = @lotno_standard_qty
					WHERE [lot_no] = @lotno_standard
				END
				
				IF @Chk_Fristlot = ''
				BEGIN
						-- insert and update hasuu to tabel [trans].[surpluses]
						EXEC [StoredProcedureDB].[atom].[sp_set_label_issued_tg_V2] @lot_no = @lotno_standard
						,@qty_hasuu_before = @hasuu_qty
						,@Empno_int_value = @EmpNo_int 
						,@stock_class = '01'  
						,@machine_id_val = @machine_id  
				END
				ELSE IF @Chk_Fristlot != ''
				BEGIN
					UPDATE [APCSProDB].[trans].[surpluses]
					SET 
						[pcs] = @Totalhasuu
						, [serial_no] = @lot_no
						, [in_stock] = '2'
						, [location_id] = ''
						, [acc_location_id] = ''
						, [updated_at] = GETDATE()
						--, [updated_by] = @EmpNo_int 
						, [updated_by] = @EmpnoId  --new
					WHERE [lot_id] = @Lot_id
				END

				-- INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records update 2021/12/07 Time : 11.54
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
				,@sataus_record_class = 1 
				--,@emp_no_int = @EmpNo_int 
				,@emp_no_int = @EmpnoId  --new 

				-- set data to tabel [trans].[lot_combine]
				EXEC [StoredProcedureDB].[atom].[sp_set_tsugitashi_tg] 
				@master_lot_no = @lotno_standard
				,@hasuu_lot_no = @hasuu_lot
				,@masterqty = @lotno_standard_qty
				,@hasuuqty = @hasuu_qty
				,@OP_No = @EmpNo_int
			

				--move step update hasuu is currently being used give update after tg --> edit 2023/07/26 time : 11.37
				--update instock = 1 (Location Assign) : Add Query Update Instock of Mix Present
				UPDATE APCSProDB.trans.surpluses
				SET in_stock = '1'
					,updated_at = GETDATE()
				WHERE serial_no = @hasuu_lot

				-- INSERT RECORD CLASS TO TABEL tg_sp_set_surpluse_records update 2023/03/08 Time : 16.15
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @hasuu_lot
				,@sataus_record_class = 2 
				--,@emp_no_int = @EmpNo_int 
				,@emp_no_int = @EmpnoId  --new

				--Add Query 2021/10/15 Time : 08.49
				--Update qty_hasuu Lot_hasuu is '0'
				UPDATE [APCSProDB].[trans].[lots]
				SET 
					[qty_hasuu] = 0
				WHERE [lot_no] = @hasuu_lot

				DECLARE @State_Qty_hasuu int = 1
				select  @State_Qty_hasuu = qty_hasuu from [APCSProDB].[trans].[lots] where lot_no = @hasuu_lot

				--Add Function update state lot runtest for FT-TP flow  date : 2023/11/10 time : 08.56  //close condition 2023/07/12 time : 11.43
				--IF @process_name = 'FT-TP'
				--BEGIN
				--	UPDATE [APCSProDB].[trans].[surpluses]
				--	SET 
				--		 [is_test_fttp] = 1
				--		,[updated_at] = GETDATE()
				--		,[updated_by] = @EmpNo_int
				--	WHERE [serial_no] = @lotno_standard

				--	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @lotno_standard
				--	,@sataus_record_class = 2 
				--	,@emp_no_int = @EmpNo_int 
				--END

				BEGIN TRY
					--Set Record Class = 46 is TG Show on web Atom //Date Create : 2022/02/02 Time : 10.35
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
						, 'EXEC [dbo].[tg_sp_set_auto_continue_lot_V3 Create Record Class TG Error] @lotno_standard = ''' + @lotno_standard 
						, @lotno_standard
				END CATCH

				---- # add 2024/07/13 10:50
				DECLARE @newlotid int;
				SELECT @newlotid = [id] 
				FROM [APCSProDB].[trans].[lots]
				WHERE [lot_no] = @lotno_standard;

				EXEC [StoredProcedureDB].[trans].[sp_set_ukebarai_data_ver_003] @lot_id = @newlotid
					, @flag_type = 1;

				--LOG FILE TO STORE Create 2020/12/23 end , Add Parameter qty_lot_hasuu Time : 2021/10/15
				INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				([record_at]
				  , [record_class]
				  , [login_name]
				  , [hostname]
				  , [appname]
				  , [command_text] --update parameter form @Lot_No is @lotno_standard Data : 2021/12/22 Time : 09.34
				  , [lot_no]) --update date 2021/11/19 time : 12.08
				SELECT GETDATE()
					, '4'
					, ORIGINAL_LOGIN()
					, HOST_NAME()
					, APP_NAME()
					, 'EXEC [dbo].[tg_sp_set_auto_continue_lot_V3] @lotno_standard = ''' + ISNULL(@lotno_standard ,'NULL')
						+ ''', @hasuu_lot = ''' + ISNULL(@hasuu_lot ,'NULL')
						+ ''', @hasuu_qty = ''' + ISNULL(CONVERT (varchar (10), @hasuu_qty),'NULL')
						+ ''', @lotno_standard_qty = '''+ ISNULL(CONVERT (varchar (10), @lotno_standard_qty),'NULL') 
						+ ''', @empno = ''' + ISNULL(@empno ,'NULL')
						+ ''', @MNo_Hasuu = ''' + ISNULL(@GetMarknoHasuuLot ,'NULL')
						+ ''', @package_loths = ''' + ISNULL(@GetPackageHasuuLot ,'NULL')
						+ ''', @device_loths = ''' + ISNULL(@GetDeviceHasuuLot ,'NULL')
						+ ''', @qty_lot_hasuu_update = ''' + ISNULL(CONVERT (varchar (5), @State_Qty_hasuu) ,'NULL')
						+ ''', @McName = ''' + ISNULL(@machine_name,'NULL') 
						+ ''', @ProcessName = ''' + @process_name 
						+ ''', @MCId = ''' + ISNULL(CONVERT (varchar (10), @machine_id),'NULL') + ''''
					, @lotno_standard
				END
			ELSE 
			BEGIN
				SELECT 'FALSE' AS Status ,'INSERT DATA ERROR !!' AS Error_Message_ENG,N'เงื่อนไขการ mix ไม่ตรงกัน กรุณาตรวจสอบข้อมูล' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END

		END
		ELSE
		BEGIN
			SELECT 'TRUE' AS Status ,'Function AutoTG Warning!!' AS Error_Message_ENG,N'มีการทำ Auto TG ไปแล้ว !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END

	END
	ElSE IF @hasuu_qty = 0
	BEGIN
		IF @count_lotid_fristlot = 0
			BEGIN
				--LOG FILE TO STORE  Date : 2021/10/19 Time 16.30
				INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
					([record_at]
					  , [record_class]
					  , [login_name]
					  , [hostname]
					  , [appname]
					  , [command_text] 
					  , [lot_no]) 
					SELECT GETDATE()
						, '4'
						, ORIGINAL_LOGIN()
						, HOST_NAME()
						, APP_NAME()
							,'EXEC [dbo].[tg_sp_set_auto_continue_lot_V3] @lotno_standard = ''' + ISNULL(@lotno_standard,'NULL')
							+ ''', @hasuu_lot = ''' + ISNULL(@hasuu_lot,'NULL') 
							+ ''', @hasuu_qty = ''' + ISNULL(CONVERT (varchar (10), @hasuu_qty),'NULL') 
							+ ''', @lotno_standard_qty = '''+ ISNULL(CONVERT(varchar (10), @lotno_standard_qty),'NULL') 
							+ ''', @empno = ''' + ISNULL(@empno,'NULL') 
							+ ''', @MNo_Hasuu = ''' + ISNULL(@GetMarknoHasuuLot,'NULL')
							+ ''', @package_loths = ''' + ISNULL(@GetPackageHasuuLot,'NULL') 
							+ ''', @device_loths = ''' + ISNULL(@GetDeviceHasuuLot ,'NULL')
							+ ''', @McName = ''' + ISNULL(@machine_name ,'NULL')
							+ ''', @ProcessName = ''' + @process_name 
							+ ''', @MCId = ''' + ISNULL(CONVERT(varchar (10), @machine_id),'NULL') +  ''''
						, @lotno_standard

				--Add Condition 2021/10/21 Time : 14.24 check hasuu stock in
				IF @Lot_Type_Standard = 'A' and (@lotno_standard_qty < @Pcs_Per_Pack)
				BEGIN
					SELECT 'FALSE' AS Status ,'Hasuu Stock IN !!' AS Error_Message_ENG,N'จำนวนงานไม่ถึง Reel Standard ไม่สามารถทำ TG-0 ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
					RETURN
				END
				ELSE
				BEGIN
					--#2024/12/26 Time : 10.00 By Aomsin
					--SELECT 'FALSE' AS Status 
					--	,'Close to repair all Auto TG and Print Label systems (during 10.00 - 13.00)' AS Error_Message_ENG
					--	,N'ปิดปรับปรุงระบบ Auto TG และ Print Label ทั้งหมด (ในช่วงเวลา 10.00 - 13.00)' AS Error_Message_THA 
					--	,N' กรุณาติดต่อ System' AS Handling
					--RETURN

					--add process name FLFTTP and MAP data : 2023/07/12 Time : 14.37  flow FLFTTP,MAP by Aomsin
					IF @process_name = 'MAP' --or @process_name = 'FL' --#close 2025.MAY.22 Time : 09.22 by Aomsin
					BEGIN
						UPDATE [APCSProDB].[trans].[lots]
						SET [qty_pass] = @lotno_standard_qty
						WHERE [lot_no] = @lotno_standard
					END

					EXEC [StoredProcedureDB].[dbo].[tg_sp_set_label_issue_tg] @lotno_standard = @lotno_standard
					,@empno = @empno
					,@machine_id_val = @machine_id  --add parameter on datetime : 2023/04/14 time : 13.47

					SELECT 'TRUE' AS Status ,'Frist Lot Success !!' AS Error_Message_ENG,N'บันทึกข้อมูลเรียบร้อย !!' AS Error_Message_THA,N' กรุณาติดต่อ System' AS Handling
					RETURN
				END
				
			END
		ELSE
		BEGIN
			SELECT 'TRUE' AS Status ,'Function Frist Lot Warning!!' AS Error_Message_ENG,N'มีการทำ FristLot ไปแล้ว !!' AS Error_Message_THA ,N'' AS Handling
			RETURN
		END
	END
		SELECT 'TRUE' AS Status ,'Success !!' AS Error_Message_ENG,N'บันทึกเรียบร้อย !!' AS Error_Message_THA,N'' AS Handling
		RETURN
	END TRY
	BEGIN CATCH 
		SELECT 'FALSE' AS Status ,'Update error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH
	
END