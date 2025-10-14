
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_update_qty_hasuu_after_run_v4] --ตัวจริงต้อง update เป็น V.5
	-- Add the parameters for the stored procedure here
	@standard_lot		varchar(10)  = ''
	,@hasuu_lot			varchar(10)  = ''
	,@qty_hasuu_before	INT			 = 0
	,@qty_hasuu_now		INT			 = 0
	,@qty_pass_now		INT			 = 0
	--,@is_insp			int			 = 0  --is_insp = 1
	--,@is_map			varchar(5)	 = '' --is_map = MAP,FT-TP (ในอนาคตจะเปลี่ยนเป็น is_process)
	--,@is_web_lsms		int			 = 0
	,@qty_shipment_now	int			 = 0
	,@is_instock		char(1)		 = ''
	,@is_process		varchar(10)  = ''--add parameter date : 2025/07/21 time : 13.24
	,@reel_no			varchar(max) = ''
	,@qty_sum_ng		int			 = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lot_id INT = 0
	DECLARE @r int= 0;
	DECLARE @qty_out INT;
	DECLARE @qty_sum INT = 0
	DECLARE @pcs_per_pack int = 0
	--add parameter 2022/02/03 time : 11.20
	DECLARE @pc_instr_code_value int = 0
	DECLARE @InStock_Current int = null
		,@pcs_current int = null
	Declare @qty_insp int = 0

	--Get data instock for save history lot --> date modify 2023/03/23 time : 16.30
	select @InStock_Current = in_stock, @pcs_current = pcs from APCSProDB.trans.surpluses where serial_no = @standard_lot

	SELECT @lot_id = [lots].[id]
		, @qty_out = ((device_names.pcs_per_pack) * ((@qty_pass_now + @qty_hasuu_before)/(device_names.pcs_per_pack))) 
		, @pcs_per_pack = device_names.pcs_per_pack
		, @pc_instr_code_value = case when [lots].[pc_instruction_code] is null or [lots].[pc_instruction_code] = '' then 0 else [lots].[pc_instruction_code] end
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	WHERE [lots].[lot_no] = @standard_lot

	--GET DATA QTY SUM [qty_shipment + qty_hasuu_now]
	--add check condition pc request date modify : 2022/03/03 time : 10.23, Add Condition PC_Code = 11 2022/06/17 time : 10.50
	select @qty_sum = case when @pc_instr_code_value = 13 or @pc_instr_code_value = 11 then @qty_pass_now 
						   else (@qty_out + @qty_hasuu_now) end
	
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
		,'EXEC [dbo].[tg_sp_update_qty_hasuu_after_run_V4 update qty after lot end] @lotno = ''' + @standard_lot 
			+ ''',@qty_hasuu_before = ''' + CONVERT (varchar (10), @qty_hasuu_before) 
			+ ''',@qty_hasuu_now = ''' + CONVERT (varchar (10), @qty_hasuu_now) 
			+ ''' ,@qty_pass_now = ''' + CONVERT (varchar (10), @qty_pass_now) 
			--+ ''' ,@is_insp = ''' + CONVERT (varchar (1), @is_insp) 
			--+ ''' ,@is_map = ''' + @is_map 
			+ ''' ,@qty_shipment_now = ''' + CONVERT (varchar (10), @qty_shipment_now) 
			+ ''' ,@is_instock = ''' + @is_instock 
			+ ''' ,@hasuu_lotno = ''' + @hasuu_lot 
			+ ''' ,@get_instok_current = ''' + ISNULL(CONVERT (varchar (4), @InStock_Current),'NULL')
			+ ''' ,@is_process = ''' + @is_process 
			+ ''' ,@reel_no = ''' + @reel_no 
			+ ''' ,@qty_sum_ng = ''' + CONVERT (varchar (10), @qty_sum_ng ) 
			+ ''''
		,@standard_lot

	DECLARE @get_member_lot_id int = null
	DECLARE @get_member_lotno varchar(10) = ''
	DECLARE @get_type_lot char(1) = ''
	
	IF EXISTS(SELECT * FROM [APCSProDB].[trans].[surpluses] WHERE lot_id = @lot_id)
	BEGIN
		BEGIN TRY  
			print'test lot_id = '+ cast(@lot_id as varchar(10))
			
			IF @qty_hasuu_now = 0
			BEGIN
				UPDATE [APCSProDB].[trans].[surpluses]
				SET 
					  [pcs] = @qty_hasuu_now
					, [in_stock] = 0
					, [updated_at] = GETDATE()
					, [updated_by] = 1  --by system admin
				WHERE [serial_no] = @standard_lot

				--INSERT TO TABEL RECORD CLASS 2022/11/10
				EXEC [dbo].[tg_sp_set_surpluse_records] @lotno = @standard_lot
				,@sataus_record_class = 2
				,@emp_no_int = 1 --by system admin

				--UPDATE QTY_HASUU OF LOT_STD IN TABLE H_STOCK_IF INTERFACE
				--UPDATE [APCSProDWH].[dbo].[H_STOCK_IF]
				--SET  HASU_Stock_QTY = @qty_hasuu_now
				--	,DMY_OUT_Flag = '1'  --add column 2023/04/18 time : 09.22
				--WHERE LotNo = @standard_lot

				--Add Log File in table exec_history  --> Date Modify : 2023/03/23 Time : 16.30
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
					,'EXEC [dbo].[tg_sp_update_qty_hasuu_after_run_V4 update hasuu now in surpluses and qty_hasuu_now == 0] @lotno = ''' + @standard_lot 
						+ ''',@qty_hasuu_before = ''' + CONVERT (varchar (10), @qty_hasuu_before) 
						+ ''',@qty_hasuu_now = ''' + CONVERT (varchar (10), @qty_hasuu_now) 
						+ ''' ,@qty_pass_now = ''' + CONVERT (varchar (10), @qty_pass_now) 
						--+ ''' ,@is_insp = ''' + CONVERT (varchar (1), @is_insp) 
						--+ ''' ,@is_map = ''' + @is_map 
						+ ''' ,@qty_shipment_now = ''' + CONVERT (varchar (10), @qty_shipment_now) 
						+ ''' ,@is_instock = ''' + @is_instock 
						+ ''' ,@hasuu_lotno = ''' + @hasuu_lot 
						+ ''' ,@is_process = ''' + @is_process 
						+ ''' ,@reel_no = ''' + @reel_no 
						+ ''' ,@qty_sum_ng = ''' + CONVERT (varchar (10), @qty_sum_ng )
						+ ''''
					,@standard_lot

			END
			ELSE	--@qty_hasuu_now != 0
			BEGIN
				print '@qty_hasuu_now != 0'
			/*	IF(@is_process = 'INSP')
				Begin
					--select @in_stock_hasuu
					select @qty_insp = (select (COUNT(@reel_no) * @pcs_per_pack) - @qty_sum_ng FROM STRING_SPLIT(@reel_no, ','))
					IF(@InStock_Current = 2 )
					begin
						select @qty_insp += @pcs_current 
					end
				end*/
				-- UPDATE QTY_HASUU
				UPDATE [APCSProDB].[trans].[surpluses]
				SET 
				  [pcs] = @qty_hasuu_now--IIF(@is_process = 'INSP',@qty_insp,@qty_hasuu_now)--
				, [updated_at] = GETDATE()
				, [updated_by] = 1  --by system admin
				WHERE [serial_no] = @standard_lot
				print'UPDATE [APCSProDB].[trans].[surpluses]'

				--INSERT TO TABEL RECORD CLASS 2022/11/10
				EXEC [dbo].[tg_sp_set_surpluse_records] @lotno = @standard_lot
				,@sataus_record_class = 2
				,@emp_no_int = 1 --by system admin


				--UPDATE QTY_HASUU OF LOT_STD IN TABLE H_STOCK_IF INTERFACE
				--UPDATE [APCSProDWH].[dbo].[H_STOCK_IF]
				--SET HASU_Stock_QTY = @qty_hasuu_now
				--WHERE LotNo = @standard_lot

				--Add Log File in table exec_history  --> Date Modify : 2023/03/23 Time : 16.30
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
					,'EXEC [dbo].[tg_sp_update_qty_hasuu_after_run_V4 update hasuu now in surpluses and qty_hasuu_now <> 0] @lotno = ''' + @standard_lot 
						+ ''' ,@qty_hasuu_before = ''' + CONVERT (varchar (10), @qty_hasuu_before) 
						+ ''' ,@qty_hasuu_now = ''' + CONVERT (varchar (10), @qty_hasuu_now) 
						+ ''' ,@qty_pass_now = ''' + CONVERT (varchar (10), @qty_pass_now) 
						--+ ''' ,@is_insp = ''' + CONVERT (varchar (1), @is_insp) 
						--+ ''' ,@is_map = ''' + @is_map 
						+ ''' ,@qty_shipment_now = ''' + CONVERT (varchar (10), @qty_shipment_now) 
						+ ''' ,@is_instock = ''' + @is_instock 
						+ ''' ,@hasuu_lotno = ''' + @hasuu_lot 
						+ ''' ,@is_process = ''' + @is_process 
						+ ''' ,@reel_no = ''' + @reel_no 
						+ ''' ,@qty_sum_ng = ''' + CONVERT (varchar (10), @qty_sum_ng )
						+ ''''
					,@standard_lot

			END
			--END

			--UPDATE DMY_OUT_FLAG = 1 OF HASUU LOT BEFORE IN TABLE H_STOCK_IF INTERFACE
			IF @hasuu_lot != ''
			BEGIN
				--UPDATE [APCSProDWH].[dbo].[H_STOCK_IF]
				--SET DMY_OUT_Flag = '1'
				--WHERE LotNo = @hasuu_lot

				--add query update instock = 0 for hasuu lot date create : 2023/02/01 time : 10.27
				UPDATE [APCSProDB].[trans].[surpluses]
				SET 
				  [in_stock] =  0
				, [updated_at] = GETDATE()
				, [updated_by] = 1  --by system admin
				WHERE [serial_no] = @hasuu_lot

				--INSERT TO TABEL RECORD CLASS 
				EXEC [dbo].[tg_sp_set_surpluse_records] @lotno = @hasuu_lot
				,@sataus_record_class = 2
				,@emp_no_int = 1 --by system admin

			END
			ELSE
			BEGIN
				select @get_type_lot = SUBSTRING(@standard_lot,5,1)
				print 'hasuu_lotno = "" and @get_type_lot = '+ cast( @get_type_lot as varchar(10))

				select top 1 @get_member_lot_id = lot_combine.member_lot_id
				,@get_member_lotno = sur.serial_no
				from APCSProDB.trans.lot_combine 
				inner join APCSProDB.trans.surpluses as sur on lot_combine.member_lot_id = sur.lot_id
				where lot_combine.lot_id = @lot_id 
				order by lot_combine.created_at desc

				IF @get_member_lotno <> '' --Check Lot Member is not blank
				BEGIN
					IF @pc_instr_code_value <> 11 or @pc_instr_code_value <> 13  --Check งาน shipmentall และ งาน shipment แค่ hasuu
					BEGIN
						IF @get_type_lot <> 'D'  --Check type lot
						BEGIN
							IF @lot_id <> @get_member_lot_id  --Check งาน ต้องไม่ใช่งาน Tg-0
							BEGIN
								--UPDATE [APCSProDWH].[dbo].[H_STOCK_IF]
								--SET DMY_OUT_Flag = '1'
								--WHERE LotNo = @get_member_lotno
								select 'UPDATE [APCSProDWH].[dbo].[H_STOCK_IF]'
							END
						END
					END
				END

			END
		END TRY
		BEGIN CATCH  
			SELECT 'FALSE' AS Status 
			,'UPDATE QTY HASUU IN SURPLUSES ERROR !!' AS Error_Message_ENG
			,N'ไม่สามารถ Update ข้อมูลใน Surplueses ได้ !!' AS Error_Message_THA 
			,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH  

		--CREATE 2021/04/08
		--UPDATE QTY PASS IN TABLE : TRAN.LOT
		BEGIN TRY  
			select @get_type_lot = SUBSTRING(@standard_lot,5,1)
			print 'check pc request and @get_type_lot = '+ cast( @get_type_lot as varchar(10))
			IF @pc_instr_code_value IN (13, 1) --Check Condition PC_Code is 13 = PC Request (Hasuu) date modify : 2022/02/24 time : 16.42 ,last update 2024/07/15 time : 14.39
			BEGIN
				print'pc = 13 or 1'
				IF @get_type_lot = 'D' OR @get_type_lot = 'F' 
				BEGIN
					-- UPDATE QTY PASS IN TABLE : TRAN.LOT
					UPDATE APCSProDB.trans.lots 
					SET qty_out = IIF(@is_process = 'INSP',@qty_shipment_now,@qty_pass_now) --add condition support work new pc-request input at flow insp date update : 2022/03/21 time : 15.42 by Aomsin
					,qty_hasuu = IIF(@get_type_lot = 'F', 0, @qty_hasuu_now) --update condition 2025/07/21 09.29 by Aomsin,change condition update hasuu = @qty_pass_now  2023/08/29
					where lot_no = @standard_lot
				END
				ELSE
				BEGIN
					-- UPDATE QTY PASS IN TABLE : TRAN.LOT
					UPDATE APCSProDB.trans.lots 
					SET qty_out = @qty_pass_now
					,qty_hasuu = 0 --change condition update hasuu = 0  2022/08/18 time : 11.27
					where lot_no = @standard_lot
				END
			END
			ELSE IF @pc_instr_code_value = 11 --PC Request Shipment All -->Add Condition 2022/06/17 Time : 10.55
			BEGIN
				print'pc = 11'
				UPDATE APCSProDB.trans.lots 
				SET qty_hasuu = (@qty_pass_now)%(@pcs_per_pack) --ต้องคำนวณ hasuu ใหม่โดยนำ pass now มาคิด
				,qty_out = case when @qty_out = 0 then 0 else @qty_out end
				where lot_no = @standard_lot
			END
			ELSE
			BEGIN
				print'pc != 13,1,11'
				UPDATE APCSProDB.trans.lots 
				SET qty_hasuu = @qty_hasuu_now--IIF(@is_process = 'INSP',@qty_insp,@qty_hasuu_now)--
				,qty_out = case when @qty_out = 0 then 0 else @qty_out end
				where lot_no = @standard_lot
			END
		END TRY
		BEGIN CATCH  
			SELECT 'FALSE' AS Status 
			,'UPDATE ERROR !!' AS Error_Message_ENG
			,N'ไม่สามารถ Update ข้อมูล จำนวน hasuu ใน Tran.lots ได้ !!' AS Error_Message_THA 
			,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH  

		--CREATE 2021/10/04 Time : 12.00
		--AUTO UPDATE QTY ON LABEL
		BEGIN TRY
			print 'exec update record'
			EXEC [dbo].[tg_sp_set_qty_fristlot_update_ver2] --ตัวจริงต้อง update เป็น V.3
			@lot_no = @standard_lot
			,@qty = @qty_sum
			,@is_process = @is_process
			,@reel_no = @reel_no
			,@qty_sum_ng = @qty_sum_ng
		END TRY
		BEGIN CATCH  
			SELECT 'FALSE' AS Status 
			,'UPDATE QTY ON LABEL ERROR !!' AS Error_Message_ENG
			,N'ไม่สามารถ Update ข้อมูล จำนวนงาน ใน Tran.Label_Issue_Record ได้ !!' AS Error_Message_THA 
			,N' กรุณาติดต่อ System' AS Handling
			RETURN
		END CATCH  
	END
	
	--Update in_stock = 0 กรณีงานที่เกิด Machine hang หรือ ng over -->date modify : 2022/06/29 time : 09.25
	IF @is_instock = '0'
	BEGIN
	print'@is_instock = "0"'
		UPDATE [APCSProDB].[trans].[surpluses]
		SET 
			  [in_stock] =  0
			, [updated_at] = GETDATE()
		WHERE [serial_no] = @standard_lot

		--UPDATE DATA IN Is Server Update Date : 2023/01/31 Time : 14.40
		--UPDATE [APCSProDWH].[dbo].[H_STOCK_IF]
		--SET DMY_OUT_Flag = '1'
		--WHERE LotNo = @standard_lot
	END

	IF @is_process = 'FT-TP'   --Add test Auto FT-TP in TP Process F2 #2024/09/09 time : 13.30
	BEGIN
		UPDATE [APCSProDB].[trans].[surpluses]
		SET 
			  [is_test_fttp] = 1
			, [updated_at] = GETDATE()
			, [updated_by] = 1
		WHERE [serial_no] = @standard_lot

		EXEC [StoredProcedureDB].[dbo].[tg_sp_set_surpluse_records] @lotno = @standard_lot
		,@sataus_record_class = 2 
		,@emp_no_int = 1 

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
			,'EXEC [dbo].[tg_sp_update_qty_hasuu_after_run_V4 update flag is_test_fttp on TP] @lotno = ''' + @standard_lot 
				+ ''' ,@qty_hasuu_before = ''' + CONVERT (varchar (10), @qty_hasuu_before) 
				+ ''' ,@qty_hasuu_now = ''' + CONVERT (varchar (10), @qty_hasuu_now) 
				+ ''' ,@qty_pass_now = ''' + CONVERT (varchar (10), @qty_pass_now) 
				--+ ''' ,@is_insp = ''' + CONVERT (varchar (1), @is_insp) 
				--+ ''' ,@is_map = ''' + @is_map 
				+ ''' ,@qty_shipment_now = ''' + CONVERT (varchar (10), @qty_shipment_now) 
				+ ''' ,@is_instock = ''' + @is_instock 
				+ ''' ,@hasuu_lotno = ''' + @hasuu_lot 
				+ ''' ,@is_process = ''' + @is_process 
				+ ''' ,@reel_no = ''' + @reel_no 
				+ ''' ,@qty_sum_ng = ''' + CONVERT (varchar (10), @qty_sum_ng )
				+ ''''
			,@standard_lot
	END
	print 'tg_sp_update_qty_hasuu_after_run_V4'
END
