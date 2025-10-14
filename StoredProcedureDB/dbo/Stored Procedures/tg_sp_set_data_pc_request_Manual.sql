-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_data_pc_request_Manual] 
	-- Add the parameters for the stored procedure here
	 @newlot varchar(10)
	,@lot_hasuu varchar(10)
	,@new_qty int
	,@hasuu_qty int
	,@out_out_flag char(5) = ' '
	,@pdcd_Adjust char(5) = '' --add parameter 2021/07/06
	,@empno char(6) = ' '
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
		,'EXEC [dbo].[tg_sp_set_data_pc_request_Manual] @empno = ''' + @empno + ''',@lotno_standard = ''' + @newlot + ''',@lotno_standard_qty = ''' + CONVERT (varchar (10), @new_qty) + ''',@pdcd_adjust = ''' + @pdcd_Adjust + ''',@out_out_flag_adjust = ''' + @out_out_flag + ''''
		,@newlot

    --Update 2021/10/19 Close Temp_H_Stock
    select 
	 @StockClass = '01'
	,@LotNo_H_Stock = sur.serial_no
	,@Package = pk.short_name
	,@Pdcd = sur.pdcd
	,@HASU_Stock_QTY = sur.pcs 
	,@Packing_Standerd_QTY_H_Stock = dn.pcs_per_pack
	,@ROHM_Model_Name = dn.name
	,@ASSY_Model_Name = dn.assy_name
	,@R_Fukuoka_Model_Name = REVERSE(SUBSTRING(REVERSE(dn.name), CHARINDEX('-',  REVERSE(dn.name)) + 1,LEN(dn.name)))
	,@TIRank = case when dn.rank is null then '' else dn.rank end
	,@Rank_H_Stock = case when dn.rank is null then '' else dn.rank end
	,@TPRank = case when dn.tp_rank is null then '' else dn.tp_rank end
	,@SUBRank = '' --fix blank
	,@Mask = '' --fix blank
	,@KNo = '' --fix blank
	,@Tomson_Mark_1 = '' --fix blank
	,@Tomson_Mark_2 = '' --fix blank
	,@Tomson_Mark_3 = sur.qc_instruction
	,@ORNo = case when SUBSTRING(sur.serial_no,5,1) = 'D' or SUBSTRING(sur.serial_no,5,1) = 'F' then 'NO' 
		else case when den_pyo.ORDER_NO = '' or den_pyo.ORDER_NO is null then '' else den_pyo.ORDER_NO end end
	,@MNo = sur.mark_no
	,@WFLotNo = '' --fix blank
	,@LotNo_Class = '' --fix blank
	,@Label_Class = sur.label_class
	,@Product_Control_Clas = sur.product_control_class
	,@ProductClass = sur.product_class
	,@ProductionClass = sur.production_class
	,@RankNo = sur.rank_no
	,@HINSYU_Class = sur.hinsyu_class
	from APCSProDB.trans.surpluses as sur
	inner join APCSProDB.trans.lots as lot on sur.lot_id = lot.id
	inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
	inner join APCSProDB.method.device_names as dn on lot.act_device_name_id = dn.id
	left join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT as den_pyo on lot.lot_no = den_pyo.LOT_NO_2
	where serial_no = @lot_hasuu
	and sur.in_stock != '0' 
	and sur.updated_at  >= (getdate() - 1095)
	and sur.pcs != '0'
	order by SUBSTRING(sur.serial_no,5,1) asc

	

			--BEGIN TRY
				
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_d_lot_in_tranlot] @lotno = @newlot
				,@device_name = @ROHM_Model_Name
				,@assy_name = @ASSY_Model_Name
				,@qty = @new_qty

				SELECT @lot_id = [lots].[id] from APCSProDB.trans.lots where lot_no = @newlot

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
			
				SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
				, @lot_id AS lot_id
				, @new_qty AS pcs
				, @newlot AS serial_no
				, '2' AS in_stock
				, '' AS location_id
				, '' AS acc_location_id
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
				,@sataus_record_class = 1
				,@emp_no_int = @Emp_int  --update date : 2021/12/07 time : 14.39

				EXEC [StoredProcedureDB].[atom].[sp_set_mixing_tg] @lotno0 = @lot_hasuu
				,@lotno1 = ''
				,@lotno2 = ''
				,@lotno3 = ''
				,@lotno4 = ''
				,@lotno5 = ''
				,@lotno6 = ''
				,@lotno7 = ''
				,@lotno8 = ''
				,@lotno9 = ''
				,@master_lot_no = @newlot
				,@emp_no_value = @empno


				-- CREATE 2021/03/15 By Aomsin
				-- INSERT DATA IN TABLE LABEL_HISTORY
				EXEC [StoredProcedureDB].[dbo].[tg_sp_set_data_label_history_V.3] @lot_no_value = @newlot
				,@process_name = 'TP'


	--Add Function Update PC Instruction Code = 13 (is Hasuu Reel) date : 2022/02/03 time : 10.57
	BEGIN TRY
		UPDATE APCSProDB.trans.lots SET pc_instruction_code = 13 where lot_no = @newlot
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
			, 'EXEC [dbo].[tg_sp_set_data_pc_request_V2 Update PC Instruction Code Error] @lotno_standard = ''' + @newlot 
			, @newlot
	END CATCH
		

END
