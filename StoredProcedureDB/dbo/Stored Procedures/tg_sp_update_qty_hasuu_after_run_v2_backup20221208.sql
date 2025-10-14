-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [dbo].[tg_sp_update_qty_hasuu_after_run_v2_backup20221208]
	-- Add the parameters for the stored procedure here
	 @standard_lot varchar(10) = ''
	,@hasuu_lot varchar(10) = ''
	,@qty_hasuu_before INT = 0
	,@qty_hasuu_now INT = 0
	,@qty_pass_now INT = 0
	--add parameter 2022/02/01 time : 13.23
	,@is_insp int = 0  --is_insp = 1
	--add parameter 2022/03/01 time : 11.07
	,@is_map varchar(5) = '' --is_map = MAP
	--add parameter 2022/03/04 time : 13.27
	,@is_web_lsms int = 0
	--add parameter 2022/03/23 time : 09.31
	,@qty_shipment_now int = 0
	--add paramter 2022/06/29 time : 09.19
	,@is_instock char(1) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	--call new store create 2022/12/07 Time : 16.56
	------------------------------------------------------------------------------------------------
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_update_qty_hasuu_after_run_v2_new] @standard_lot = @standard_lot
	--,@hasuu_lot = @hasuu_lot
	--,@qty_hasuu_before = @qty_hasuu_before
	--,@qty_hasuu_now = @qty_hasuu_now
	--,@qty_pass_now = @qty_pass_now
	--,@is_insp = @is_insp
	--,@is_map = @is_map
	--,@is_web_lsms = @is_web_lsms
	--,@qty_shipment_now = @qty_shipment_now
	--,@is_instock = @is_instock
	------------------------------------------------------------------------------------------------

	SET NOCOUNT ON;
	DECLARE @lot_id INT = 0
	DECLARE @r int= 0;
	DECLARE @qty_out INT;
	DECLARE @qty_sum INT = 0
	DECLARE @pcs_per_pack int = 0
	--add parameter 2022/02/03 time : 11.20
	DECLARE @pc_instr_code_value int = 0

	SELECT @lot_id = [lots].[id]
	, @qty_out = case when @is_map = 'MAP' then ((device_names.pcs_per_pack) * ((@qty_pass_now)/(device_names.pcs_per_pack))) --add condition date modify : 2022/03/02 time : 08.18
		else ((device_names.pcs_per_pack) * ((@qty_pass_now + @qty_hasuu_before)/(device_names.pcs_per_pack))) end --Update 2021/10/01
	, @pcs_per_pack = device_names.pcs_per_pack
	, @pc_instr_code_value = case when [lots].[pc_instruction_code] is null or [lots].[pc_instruction_code] = '' then 0 else [lots].[pc_instruction_code] end
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	WHERE [lots].[lot_no] = @standard_lot

	--CREATE 2021/10/04 Time : 12.00
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
		,'EXEC [dbo].[tg_sp_update_qty_hasuu_after_run_V2 update qty after lot end] @lotno = ''' + @standard_lot + ''',@qty_hasuu_before = ''' + CONVERT (varchar (10), @qty_hasuu_before) + ''',@qty_hasuu_now = ''' + CONVERT (varchar (10), @qty_hasuu_now) + ''' ,@qty_pass_now = ''' + CONVERT (varchar (10), @qty_pass_now) + ''' ,@is_insp = ''' + CONVERT (varchar (1), @is_insp) + ''' ,@is_map = ''' + @is_map + ''' ,@qty_shipment_now = ''' + CONVERT (varchar (10), @qty_shipment_now) + ''' ,@is_instock = ''' + @is_instock + ''''
		,@standard_lot

	
	IF EXISTS(SELECT * FROM [APCSProDB].[trans].[surpluses] WHERE lot_id = @lot_id)
		BEGIN
			BEGIN TRY  
				IF @qty_hasuu_now = 0
				BEGIN
					UPDATE [APCSProDB].[trans].[surpluses]
					SET 
					  [pcs] = @qty_hasuu_now
					, [in_stock] = '0'
					, [location_id] = NULL
					, [acc_location_id] = NULL
					, [updated_at] = GETDATE()
					, [updated_by] = '1'
					WHERE [serial_no] = @standard_lot

					--INSERT TO TABEL RECORD CLASS 2022/11/10
					EXEC [dbo].[tg_sp_set_surpluse_records] @lotno = @standard_lot,@sataus_record_class = 2

				END
				ELSE
				BEGIN
					-- UPDATE QTY_HASUU
					UPDATE [APCSProDB].[trans].[surpluses]
					SET 
					  [pcs] = @qty_hasuu_now
					--, [in_stock] = '2'  --close query : 2022/03/28 time : 14.07
					, [location_id] = NULL
					, [acc_location_id] = NULL
					, [updated_at] = GETDATE()
					, [updated_by] = '1'
					WHERE [serial_no] = @standard_lot

					--INSERT TO TABEL RECORD CLASS 2022/11/10
					EXEC [dbo].[tg_sp_set_surpluse_records] @lotno = @standard_lot,@sataus_record_class = 2

				END
				
			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'UPDATE ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Update ข้อมูลใน Surplueses ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH  

			--CREATE 2021/04/08
			--UPDATE QTY PASS IN TABLE : TRAN.LOT
			BEGIN TRY  
				IF @pc_instr_code_value = 13 --Check Condition PC_Code is 13 = PC Request (Hasuu) date modify : 2022/02/24 time : 16.42
				BEGIN
					-- UPDATE QTY PASS IN TABLE : TRAN.LOT
					UPDATE APCSProDB.trans.lots 
					SET qty_out = @qty_pass_now
					,qty_hasuu = 0 --change condition update hasuu = 0  2022/08/18 time : 11.27
					where lot_no = @standard_lot
				END
				ELSE IF @pc_instr_code_value = 11 --PC Request Shipment All -->Add Condition 2022/06/17 Time : 10.55
				BEGIN
					UPDATE APCSProDB.trans.lots 
					SET qty_hasuu = (@qty_pass_now)%(@pcs_per_pack) --ต้องคำนวณ hasuu ใหม่โดยนำ pass now มาคิด
					,qty_out = case when @qty_out = 0 then 0 else @qty_out end
					where lot_no = @standard_lot
				END
				ELSE
				BEGIN
					UPDATE APCSProDB.trans.lots 
					SET qty_hasuu = @qty_hasuu_now
					,qty_out = case when @qty_out = 0 then 0 else @qty_out end
					where lot_no = @standard_lot
				END
			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'UPDATE ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Update ข้อมูล จำนวน hasuu ใน Tran.lots ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH  

			--CREATE 2021/10/04 Time : 12.00
			--AUTO UPDATE QTY ON LABEL
			BEGIN TRY
				EXEC [dbo].[tg_sp_set_qty_fristlot_update] @lot_no = @standard_lot,@qty = @qty_sum,@is_inspec_value = @is_insp
			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'UPDATE QTY ON LABEL ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Update ข้อมูล จำนวนงาน ใน Tran.Label_Issue_Record ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH  

			
		END
		ELSE
		BEGIN
			BEGIN TRY 
				-- INSERT DATA HASUU
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
			   , [updated_by])
				--SELECT [nu].[id] - 1 + row_number() over (order by [surpluses].[id]) AS id
				SELECT top(1) [nu].[id] + row_number() over (order by [surpluses].[id]) AS id
				, @lot_id AS lot_id
				, @qty_hasuu_now AS pcs
				, @standard_lot AS serial_no
				, '2' AS in_stock
				, NULL AS location_id
				, NULL AS acc_location_id
				, GETDATE() AS created_at
				, '1' AS created_by
				, GETDATE() AS updated_at
				, '1' AS updated_by
				FROM [APCSProDB].[trans].[surpluses]
				INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'surpluses.id'

				set @r = @@ROWCOUNT
				update [APCSProDB].[trans].[numbers]
				set id = id + @r 
				from [APCSProDB].[trans].[numbers]
				where name = 'surpluses.id'

			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'INSERT ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Insert ข้อมูลเข้า Surpluses ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH  

			BEGIN TRY 
				--INSERT TO TABEL RECORD CLASS
				EXEC [dbo].[tg_sp_set_surpluse_records] @lotno = @standard_lot,@sataus_record_class = 1
			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'INSERT ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Insert ข้อมูลเข้า Surpluses_record ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH  

			--CREATE 2021/04/08
			--UPDATE QTY PASS IN TABLE : TRAN.LOT
			BEGIN TRY  
				IF @pc_instr_code_value = 13 --Check Condition PC_Code is 13 = PC Request (Hasuu) date modify : 2022/02/24 time : 16.42
				BEGIN
					-- UPDATE QTY PASS IN TABLE : TRAN.LOT
					UPDATE APCSProDB.trans.lots 
					SET qty_out = @qty_pass_now
					,qty_hasuu = 0 --change condition update hasuu = 0  2022/08/18 time : 11.27
					where lot_no = @standard_lot
				END
				ELSE IF @pc_instr_code_value = 11 --PC Request Shipment All -->Add Condition 2022/06/17 Time : 10.55
				BEGIN
					UPDATE APCSProDB.trans.lots 
					SET qty_hasuu = (@qty_pass_now)%(@pcs_per_pack) --ต้องคำนวณ hasuu ใหม่โดยนำ pass now มาคิด
					,qty_out = case when @qty_out = 0 then 0 else @qty_out end
					where lot_no = @standard_lot
				END
				ELSE
				BEGIN
					UPDATE APCSProDB.trans.lots 
					SET qty_hasuu = @qty_hasuu_now
					,qty_out = case when @qty_out = 0 then 0 else @qty_out end
					where lot_no = @standard_lot
				END
			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'UPDATE ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Update ข้อมูล จำนวน hasuu ใน Tran.lots ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH  

			--Update in_stock = 0 กรณีงานที่เกิด Machine hang หรือ ng over -->date modify : 2022/06/29 time : 09.25
			IF @is_instock = '0'
			BEGIN
				UPDATE [APCSProDB].[trans].[surpluses]
					SET 
					  [in_stock] =  0
					, [updated_at] = GETDATE()
				WHERE [serial_no] = @standard_lot
			END

			--CREATE 2021/10/04 Time : 12.00
			--AUTO UPDATE QTY ON LABEL
			BEGIN TRY
				EXEC [dbo].[tg_sp_set_qty_fristlot_update] @lot_no = @standard_lot,@qty = @qty_sum,@is_inspec_value = @is_insp
			END TRY
			BEGIN CATCH  
				SELECT 'FALSE' AS Status ,'UPDATE QTY ON LABEL ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ Update ข้อมูล จำนวนงาน ใน Tran.Label_Issue_Record ได้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
			END CATCH
			
		END	
END
