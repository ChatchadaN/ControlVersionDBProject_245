-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_hasuu_lot_test]
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
	,@ORNo = case when SUBSTRING(sur.serial_no,5,1) = 'D' or SUBSTRING(sur.serial_no,5,1) = 'F' then 'NO' else allocat_temp.ORNo end
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
	left join APCSProDB.method.allocat_temp on lot.lot_no = allocat_temp.LotNo
	where serial_no = @lotno0
	--and sur.updated_at  >= (getdate() - 1095)
	--and sur.pcs != '0'
	--order by SUBSTRING(sur.serial_no,5,1) asc

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
		,'EXEC [tg_sp_set_hasuu_lot_test_by_Aomsin] Get Store @empno = ''' + CAST(@EmpNo_int as varchar(7)) + ''',@lotno = ''' + @newlotno + ''',@QtyPass = ''' + CAST(@total_pcs as varchar(7)) + ''''
		,@newlotno

	BEGIN TRY
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
				,@qty = @total_pcs
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
				--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @newlotno
				--,@process_name = 'TP'

				--Create log Date : 2022/01/19 Time : 14.22
				

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
			,'EXEC [tg_sp_set_hasuu_lot] Set data store Error @empno = ''' + CAST(@EmpNo_int as varchar(7)) + ''',@lotno = ''' + @newlotno + ''',@QtyPass = ''' + CAST(@total_pcs as varchar(7)) + ''''
			,@newlotno

		SELECT 'FALSE' AS Status ,'Insert error !!' AS Error_Message_ENG,N'บันทึกข้อมูล d_lot ผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH
	
END
