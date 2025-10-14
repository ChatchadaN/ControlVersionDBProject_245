-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_tg_update_qty_hasuu_after_run_v2_by_testbass]
	-- Add the parameters for the stored procedure here
	 @standard_lot varchar(10) = ''
	, @hasuu_lot varchar(10) = ''
	, @qty_hasuu_before int = 0
	, @qty_hasuu_now int = 0
	, @qty_pass_now int = 0
	, @is_insp int = 0  --is_insp = 1 --add parameter 2022/02/01 time : 13.23
	, @is_map varchar(5) = ''  --is_map = MAP  --add parameter 2022/03/01 time : 11.07
	, @is_web_lsms int = 0  --add parameter 2022/03/04 time : 13.27
	, @qty_shipment_now int = 0  --add parameter 2022/03/23 time : 09.31
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	declare @lot_id int = 0
		, @r int = 0
		, @qty_out int = 0
		, @qty_sum int = 0
		, @pcs_per_pack int = 0
		, @pc_instr_code_value int = 0 --add parameter 2022/02/03 time : 11.20

	------------------------( set parameter data )------------------------
	select @lot_id = [lots].[id]
		, @qty_out = (
			case 
				when @is_map = 'MAP' then ((device_names.pcs_per_pack) * ((@qty_pass_now)/(device_names.pcs_per_pack))) --add condition date modify : 2022/03/02 time : 08.18
				else ((device_names.pcs_per_pack) * ((@qty_pass_now + @qty_hasuu_before)/(device_names.pcs_per_pack))) 
			end --Update 2021/10/01
		) 
		, @pcs_per_pack = device_names.pcs_per_pack
		, @pc_instr_code_value = (
			case 
				when [lots].[pc_instruction_code] is null or [lots].[pc_instruction_code] = '' then 0 
				else [lots].[pc_instruction_code] 
			end
		)
		--GET DATA QTY SUM [qty_shipment + qty_hasuu_now]
		--add check condition pc request date modify : 2022/03/03 time : 10.23
		, @qty_sum = (
			case 
				when @pc_instr_code_value = 13 then @qty_pass_now 
				else (@qty_out + @qty_hasuu_now) 
			end
		)
	from [APCSProDB].[trans].[lots]
	inner join [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
	inner join [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
	inner join [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
	WHERE [lots].[lot_no] = @standard_lot
	------------------------( set parameter data )------------------------

	------------------------( log exec stored procedure )------------------------
	--insert into [StoredProcedureDB].[dbo].[exec_sp_history]
	--(
	--	[record_at]
	--	, [record_class]
	--	, [login_name]
	--	, [hostname]
	--	, [appname]
	--	, [command_text]
	--	, [lot_no]
	--)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [dbo].[tg_sp_update_qty_hasuu_after_run_V2 update qty after lot end] @lotno = ''' + @standard_lot 
			+ ''',@hasuu_lot = ''' + CONVERT (varchar (10), @hasuu_lot) 
			+ ''',@qty_hasuu_before = ''' + CONVERT (varchar (10), @qty_hasuu_before) 
			+ ''',@qty_hasuu_now = ''' + CONVERT (varchar (10), @qty_hasuu_now) 
			+ ''' ,@qty_pass_now = ''' + CONVERT (varchar (10), @qty_pass_now) 
			+ ''' ,@is_insp = ''' + CONVERT (varchar (1), @is_insp) 
			+ ''' ,@is_map = ''' + @is_map
			+ ''' ,@is_web_lsms = ''' + CONVERT (varchar (1), @is_web_lsms)
			+ ''' ,@qty_shipment_now = ''' + CONVERT (varchar (10), @qty_shipment_now) + ''''
		, @standard_lot
	------------------------( log exec stored procedure )------------------------

	------------------------( check data in surpluses )------------------------
	if exists (select * from [APCSProDB].[trans].[surpluses] where lot_id = @lot_id)
	begin
		--------( have data in surpluses )--------
		--------( -1- update hasuu in surpluses  )--------
		begin try
			if @qty_hasuu_now = 0
			begin
				--UPDATE [APCSProDB].[trans].[surpluses]
				--SET 
				--  [pcs] = @qty_hasuu_now
				--, [in_stock] = '0'
				--, [location_id] = ''
				--, [acc_location_id] = ''
				--, [updated_at] = GETDATE()
				--, [updated_by] = '1'
				--WHERE [serial_no] = @standard_lot
				select @qty_hasuu_now as [pcs]
					, '0' as [in_stock]
					, '' as [location_id]
					, '' as [acc_location_id]
					, GETDATE() as [updated_at]
					, '1' as [updated_by]
				from [APCSProDB].[trans].[surpluses] 
				where [serial_no] = @standard_lot
			end
			else begin
				---- UPDATE QTY_HASUU
				--UPDATE [APCSProDB].[trans].[surpluses]
				--SET 
				--  [pcs] = @qty_hasuu_now
				--, [location_id] = ''
				--, [acc_location_id] = ''
				--, [updated_at] = GETDATE()
				--, [updated_by] = '1'
				--WHERE [serial_no] = @standard_lot
				select @qty_hasuu_now as [pcs]
					, [in_stock]
					, '' as [location_id]
					, '' as [acc_location_id]
					, GETDATE() as [updated_at]
					, '1' as [updated_by]
				from [APCSProDB].[trans].[surpluses] 
				where [serial_no] = @standard_lot
			end
		end try
		begin catch
			select 'FALSE' AS Status
				,'UPDATE ERROR !!' AS Error_Message_ENG
				,N'ไม่สามารถ Update ข้อมูลใน Surplueses ได้ !!' AS Error_Message_THA
				,N' กรุณาติดต่อ System' AS Handling
			return
		end catch
		--------( -1- update hasuu in surpluses  )--------
		--------( -2- update qty_hasuu,qty_out in trans.lots  )--------
		begin try
			if @pc_instr_code_value = 13 ---check condition PC_Code is 13 = PC Request (Hasuu)
			begin
				--UPDATE APCSProDB.trans.lots 
				--SET qty_hasuu = @qty_hasuu_now
				--	,qty_out = @qty_pass_now
				--where lot_no = @standard_lot
				select @qty_hasuu_now as [qty_hasuu]
					, @qty_pass_now as [qty_out]
					, @standard_lot as [lot_no]
				from [APCSProDB].[trans].[lots]
				where [lot_no] = @standard_lot
			end
			else begin
				--UPDATE APCSProDB.trans.lots 
				--SET qty_hasuu = @qty_hasuu_now
				--	,qty_out = case when @qty_out = 0 then 0 else @qty_out end
				--where lot_no = @standard_lot
				select @qty_hasuu_now as [qty_hasuu]
					, case when @qty_out = 0 then 0 else @qty_out end as [qty_out]
					, @standard_lot as [lot_no]
				from [APCSProDB].[trans].[lots]
				where [lot_no] = @standard_lot
			end
		end try
		begin catch
			select 'FALSE' AS Status 
				,'UPDATE ERROR !!' AS Error_Message_ENG
				,N'ไม่สามารถ Update ข้อมูล จำนวน hasuu ใน Tran.lots ได้ !!' AS Error_Message_THA 
				,N' กรุณาติดต่อ System' AS Handling
			return
		end catch
		--------( -2- update qty_hasuu,qty_out in trans.lots  )--------
		--------( -3- update qty on label  )--------
		begin try
			--exec [dbo].[tg_sp_set_qty_fristlot_update] @lot_no = @standard_lot,@qty = @qty_sum,@is_inspec_value = @is_insp
			select @standard_lot as [@lot_no], @qty_sum as [@qty] ,@is_insp as [@is_inspec_value]
		end try
		begin catch
			select 'FALSE' AS Status
				,'UPDATE QTY ON LABEL ERROR !!' AS Error_Message_ENG
				,N'ไม่สามารถ Update ข้อมูล จำนวนงาน ใน Tran.Label_Issue_Record ได้ !!' AS Error_Message_THA
				,N' กรุณาติดต่อ System' AS Handling
			return
		end catch
		--------( -3- update on label )--------
		--------( have data in surpluses )--------
	end
	else begin
		--------( no data in surpluses )--------
		--------( -1- insert surpluses,surpluse_records  )--------
		--------------<< surpluses
		begin try
			---- insert data hasuu
			--insert into [APCSProDB].[trans].[surpluses]
			--(
			--	[id]
			--	, [lot_id]
			--	, [pcs]
			--	, [serial_no]
			--	, [in_stock]
			--	, [location_id]
			--	, [acc_location_id]
			--	, [created_at]
			--	, [created_by]
			--	, [updated_at]
			--	, [updated_by]
			--)
			--select [nu].[id] + 1 AS id
			--	, @lot_id AS lot_id
			--	, @qty_hasuu_now AS pcs
			--	, @standard_lot AS serial_no
			--	, '2' AS in_stock
			--	, '' AS location_id
			--	, '' AS acc_location_id
			--	, GETDATE() AS created_at
			--	, '1' AS created_by
			--	, GETDATE() AS updated_at
			--	, '1' AS updated_by
			--from [APCSProDB].[trans].[numbers] AS nu 
			--where [nu].[name] = 'surpluses.id'

			--set @r = @@ROWCOUNT
			--update [APCSProDB].[trans].[numbers]
			--set id = id + @r 
			--where name = 'surpluses.id'

			select [nu].[id] + 1 AS id
				, @lot_id AS lot_id
				, @qty_hasuu_now AS pcs
				, @standard_lot AS serial_no
				, '2' AS in_stock
				, '' AS location_id
				, '' AS acc_location_id
				, GETDATE() AS created_at
				, '1' AS created_by
				, GETDATE() AS updated_at
				, '1' AS updated_by
			from [APCSProDB].[trans].[numbers] AS nu 
			where [nu].[name] = 'surpluses.id'
		end try
		begin catch
			select 'FALSE' AS Status 
				,'INSERT ERROR !!' AS Error_Message_ENG
				,N'ไม่สามารถ Insert ข้อมูลเข้า Surpluses ได้ !!' AS Error_Message_THA
				,N' กรุณาติดต่อ System' AS Handling
			return
		end catch  
		-------------->> surpluses
		--------------<< surpluse_records
		begin try 
			--insert data record hasuu 
			--exec [dbo].[tg_sp_set_surpluse_records] @lotno = @standard_lot,@sataus_record_class = 1
			select @standard_lot as [@lotno],1 as [@sataus_record_class]
		end try
		begin catch  
			select 'FALSE' AS Status
				,'INSERT ERROR !!' AS Error_Message_ENG
				,N'ไม่สามารถ Insert ข้อมูลเข้า Surpluses_record ได้ !!' AS Error_Message_THA
				,N' กรุณาติดต่อ System' AS Handling
			return
		end catch   
		-------------->> surpluse_records
		--------( -1- insert surpluses,surpluse_records  )--------
		--------( -2- update qty_hasuu,qty_out in trans.lots  )--------
		begin try
			if @pc_instr_code_value = 13 ---check condition PC_Code is 13 = PC Request (Hasuu)
			begin
				--UPDATE APCSProDB.trans.lots 
				--SET qty_hasuu = @qty_hasuu_now
				--	,qty_out = @qty_pass_now
				--where lot_no = @standard_lot
				select @qty_hasuu_now as [qty_hasuu]
					, @qty_pass_now as [qty_out]
					, @standard_lot as [lot_no]
				from [APCSProDB].[trans].[lots]
				where [lot_no] = @standard_lot
			end
			else begin
				--UPDATE APCSProDB.trans.lots 
				--SET qty_hasuu = @qty_hasuu_now
				--	,qty_out = case when @qty_out = 0 then 0 else @qty_out end
				--where lot_no = @standard_lot
				select @qty_hasuu_now as [qty_hasuu]
					, case when @qty_out = 0 then 0 else @qty_out end as [qty_out]
					, @standard_lot as [lot_no]
				from [APCSProDB].[trans].[lots]
				where [lot_no] = @standard_lot
			end
		end try
		begin catch
			select 'FALSE' AS Status 
				,'UPDATE ERROR !!' AS Error_Message_ENG
				,N'ไม่สามารถ Update ข้อมูล จำนวน hasuu ใน Tran.lots ได้ !!' AS Error_Message_THA 
				,N' กรุณาติดต่อ System' AS Handling
			return
		end catch
		--------( -2- update qty_hasuu,qty_out in trans.lots  )--------
		--------( -3- update qty on label  )--------
		begin try
			--exec [dbo].[tg_sp_set_qty_fristlot_update] @lot_no = @standard_lot,@qty = @qty_sum,@is_inspec_value = @is_insp
			select @standard_lot as [@lot_no], @qty_sum as [@qty] ,@is_insp as [@is_inspec_value]
		end try
		begin catch
			select 'FALSE' AS Status
				,'UPDATE QTY ON LABEL ERROR !!' AS Error_Message_ENG
				,N'ไม่สามารถ Update ข้อมูล จำนวนงาน ใน Tran.Label_Issue_Record ได้ !!' AS Error_Message_THA
				,N' กรุณาติดต่อ System' AS Handling
			return
		end catch
		--------( -3- update on label )--------
		--------( no data in surpluses )--------
	end
	------------------------( check data in surpluses )------------------------

	------------------------( check data disable all reel )------------------------
	if exists (select 1 from [APCSProDB].[trans].[label_issue_records] where lot_no = @standard_lot and type_of_label in (0,3))
	begin
		if not exists (select 1 from [APCSProDB].[trans].[label_issue_records] where lot_no = @standard_lot and type_of_label = 3)
		begin
			select 70 as [wip_state]
		end
	end
	------------------------( check data disable all reel )------------------------
END
