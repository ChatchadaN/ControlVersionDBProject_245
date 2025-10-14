
-- =============================================
-- Author:		<Author,009131,Aomsin>
-- Create date: <2023/08/25>
-- Update Data: <2023/11/24> Time : 14.51 Detail : <support new pc request work>
-- Description:	<Label History>
-- =============================================
Create PROCEDURE [dbo].[tg_sp_set_data_label_history_V.3_Backup_20241224]
	-- Add the parameters for the stored procedure here
	 @lot_no_value varchar(10) = ' '
	,@process_name varchar(10) = ' '
	,@emp_no_val char(6) = '' --add parameter use ogi process (date modify --> 2022/02/17 time : 13.40)
	,@is_std_tube_adjust int = 0 --add parameter support work tube shipment manual std tube 2022/06/20 time : 13.32
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

     DECLARE @short_name char(20) = ' '
	 DECLARE @reel_num INT = 0;
	 DECLARE @reel_num_shipment INT = 0;
	 DECLARE @Lotno char(10) = '';
	 DECLARE @Lotno_hasuu char(10)  = '';
	 DECLARE @QTY int = 0;
	 DECLARE @Package char(20)  = '';
	 DECLARE @Shortname char(20)  = '';
	 DECLARE @Device char(20)  = '';
	 DECLARE @AssyName char(20)  = '';
	 DECLARE @Standard int = 0;
	 DECLARE @Total int = 0;
	 DECLARE @qty_hasuu_before int = 0;
	 DECLARE @qty_lot_standard_before int = 0;
	 DECLARE @Mno_Standard char(20)  = '';
	 DECLARE @Mno_Hasuu char(20)  = '';
	 DECLARE @Label_Type int  = 0;
	 DECLARE @Rank char(20)  = '';
	 DECLARE @TPRank char(20)  = '';
	 DECLARE @Customer_Device char(20)  = '';
	 DECLARE @SPEC  char(20)  = '';
	 DECLARE @FLOOR_LIFE   char(20)  = '';
	 DECLARE @PPBT   char(20)  = '';
	 DECLARE @BoxType   char(20)  = '';
	 DECLARE @Tomson_box   char(20)  = '';
	 DECLARE @OPNo   char(10)  = '';
	 DECLARE @OPName   char(20)  = '';
	 DECLARE @Hasuu_qty int = 0;
	 DECLARE @convert_mno_value int = 0;
	 DECLARE @Tomson_Mark_3 char(4) = ' ';
	 DECLARE @Tomson_Mark_3_Surpluses char(4) = ' ';
	 DECLARE @Required_ul_logo int = 0;
	 DECLARE @Lot_id int = 0;
	 DECLARE @Lotno_subType char(1) = '';
	 DECLARE @Status_lot char(20) = '';
	 DECLARE @qty_shipment int = 0;
	 DECLARE @Conut_Row_Data int = 0;
	 --Add Parameter Check Condition Date Get Data Allocat
	 DECLARE @get_time_value char(5) = '';
	 --Add Parameter Check Condition Date Get Data MSL DATA
	 DECLARE @get_time_value_msl char(5) = '';
	 --Add parameter Check Condition PC_Code date modify : 2022/02/25
	 DECLARE @PC_Code_Value int = 0
	 --Add Parameter Count Row Allocat Table : 2022/11/21
	 DECLARE @Check_Record_Allocat int = 0
    -- Insert statements for procedure here
	 DECLARE @Mno_Hasuu_in_sur char(20)  = '';

	--Add parameter new_pcs_per_pack modify : 2022/06/20 time : 13.32
	DECLARE @pcs_per_pack_control int = 0
	DECLARE @qty_hasuu_in_tran_lot  int = 0

	--<< modify : 2022/06/20 add condition date : 2022/06/20 time : 13.32
	select @pcs_per_pack_control = (case when @is_std_tube_adjust = 0 then device_names.pcs_per_pack else @is_std_tube_adjust end)
	from APCSProDB.trans.lots 
	inner join APCSProDB.method.device_names on lots.act_device_name_id = device_names.id
	where lot_no = @lot_no_value
	-->> modify : 2022/06/20

	SELECT @Conut_Row_Data = count(lot_no) FROM [APCSProDB].[trans].[label_issue_records] 
	WHERE lot_no = @lot_no_value and type_of_label in(1,2,3)

	select @Lot_id = id
	,@PC_Code_Value = case when pc_instruction_code is null then 0 else pc_instruction_code end
	from APCSProDB.trans.lots where lot_no = @lot_no_value

	select @Lotno_hasuu = lots.lot_no from APCSProDB.trans.lot_combine as lot_com
	inner join APCSProDB.trans.lots as lots on lot_com.member_lot_id = lots.id
	where lot_id = @Lot_id

	--chang table form denpyo is allocat_temp --> 2023/02/08 time : 11.43
	select @Mno_Standard = MNo from [APCSProDB].[method].[allocat_temp] where LotNo = @lot_no_value
	select @Mno_Hasuu = MNo from [APCSProDB].[method].[allocat_temp] where LotNo = @Lotno_hasuu
	select @Mno_Hasuu_in_sur = mark_no from [APCSProDB].[trans].[surpluses] where serial_no = @Lotno_hasuu
	--add condition check markno of hasuu is blank --> 2023/04/19 time : 15.06
	select @Mno_Hasuu = case when @Mno_Hasuu = '' then @Mno_Hasuu_in_sur 
							 else @Mno_Hasuu end
	--------------------------------------------------------------------------------------------------

	select @Lotno_subType = SUBSTRING(@lot_no_value,5,1)
	--select @Mno_Hasuu = MNo from StoredProcedureDB.dbo.IS_ALLOCAT where LotNo = @Lotno_hasuu

	--Add data Date 2021/04/27
	select @qty_lot_standard_before = (qty_out - qty_combined) 
	,@qty_hasuu_before = qty_combined
	from APCSProDB.trans.lots where lot_no = @lot_no_value

	--Add Condition Check Record on Allocat Table Create Date : 2022/11/21 Time : 15.46
	select @Check_Record_Allocat = COUNT(*) from APCSProDB.method.allocat where LotNo = @lot_no_value
	IF @Check_Record_Allocat = 0
	BEGIN
		---New query 26/04/2022 08.40
		select top(1) @Lotno = lot.lot_no
		, @QTY = case when SUBSTRING(lot.lot_no,5,1) = 'D' then lot.qty_pass else qty_out + qty_hasuu end
		, @qty_shipment = lot.qty_out
		, @reel_num = case when [surpluses].[original_lot_id] is not null or [surpluses].[original_lot_id] != 0 then 0 
							else (qty_out + qty_hasuu)/@pcs_per_pack_control end
		, @reel_num_shipment = (lot.qty_out/@pcs_per_pack_control)
		, @Hasuu_qty = case when [surpluses].[original_lot_id] is not null or [surpluses].[original_lot_id] != 0 then lot.qty_pass 
							else 
								case when @PC_Code_Value = 13 and SUBSTRING(lot.lot_no,5,1) = 'D' then lot.qty_hasuu 
									 when @PC_Code_Value = 13 and SUBSTRING(lot.lot_no,5,1) <> 'D' then lot.qty_out  --add condition for support tube hasuu shipment 2024/02/19 time : 13.26 by Aomsin
									 else (qty_out + qty_hasuu)%(@pcs_per_pack_control) end
							end
		, @Package = [pk].[name]
		, @Shortname = [pk].[short_name]
		, @Device = case when SUBSTRING(lot.lot_no,5,1) = 'E' or (SUBSTRING(lot.lot_no,5,1) = 'F' and pc_instruction_code = 13) then allo_cat.ROHM_Model_Name else [dv].[name] end  --add confition 2023/09/25 time : 08.51, update 2024/01/09 time : 15.06
		, @AssyName = [dv].[assy_name]
		--, @Customer_Device =  case when SUBSTRING(lot.lot_no,5,1) = 'E' or (SUBSTRING(lot.lot_no,5,1) = 'F' and pc_instruction_code = 13) then allo_cat.ROHM_Model_Name   --add confition 2023/09/25 time : 08.51, update 2024/01/09 time : 15.06
		--						else (case 
		--								when (multi_label.USER_Model_Name is null or multi_label.USER_Model_Name = '') then dv.name 
		--								else 
		--									case 
		--										when (multi_label.USER_Model_Name is not null or multi_label.USER_Model_Name != '') 
		--											and (multi_label.delete_flag = 1) then dv.name 
		--										else multi_label.USER_Model_Name 
		--									end
		--								end)
		--						end  --close 2024/07/31 time : 08.40 by Aomsin
		, @Customer_Device = case when SUBSTRING(lot.lot_no,5,1) = 'E' or (SUBSTRING(lot.lot_no,5,1) = 'F' and pc_instruction_code = 13)  --add condition 2024/07/31 time : 08.40 by Aomsin
			   then case when (multi_label.USER_Model_Name is null or multi_label.USER_Model_Name = '') 
						 then allo_cat.ROHM_Model_Name  
						 else (case 
									when (multi_label.USER_Model_Name is not null or multi_label.USER_Model_Name != '') 
										and (multi_label.delete_flag = 1) then allo_cat.ROHM_Model_Name 
									else multi_label.USER_Model_Name 
								end) 
						end
				else (case 
						when (multi_label.USER_Model_Name is null or multi_label.USER_Model_Name = '') then dv.name 
						else 
							case 
								when (multi_label.USER_Model_Name is not null or multi_label.USER_Model_Name != '') 
									and (multi_label.delete_flag = 1) then dv.name 
								else multi_label.USER_Model_Name 
							end
						end)
				end 
		, @Rank = case when dv.rank is null then '' else dv.rank end
		, @TPRank = case when dv.tp_rank is null then '' else dv.tp_rank end
		, @Standard = @pcs_per_pack_control
		, @Total = ([qty_out] + [qty_hasuu]) - ([qty_out] + [qty_hasuu])%(@pcs_per_pack_control) 
		, @Tomson_box = [tomson].[tomson_box]
		, @BoxType = [tomson].[tomson_box]
		, @OPNo = [lot_cb].[updated_by]
		, @qty_hasuu_in_tran_lot = [lot].[qty_hasuu]
		from APCSProDB.trans.lot_combine as lot_cb
		inner join APCSProDB.trans.lots as lot on lot_cb.lot_id = lot.id
		inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
		inner join APCSProDB.method.device_names as dv on lot.act_device_name_id = dv.id
		left join APCSProDB.method.allocat_temp as allo_cat on lot.lot_no = allo_cat.LotNo  --Use allocat_temp Table
		-------<<< Find tomson APCSProDB
		left join 
		(
			select [lots].[id] as [lot_id]
				, [lots].[lot_no]
				, isnull([tomson].[tomson_box],'') as [tomson_box]
			from [APCSProDB].[trans].[lots] 
			inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id] 
			inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id] 
				and [device_slips].[is_released] = 1 
			inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] on [device_names].[package_id] = [packages].[id]
			inner join [APCSProDB].[method].[device_flows] on [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
				and [device_flows].[job_id] = 317 
			left join 
			(
				select [material_sets].[id],[productions].[name] as [tomson_box]
				from [APCSProDB].[method].[material_sets]
				inner join [APCSProDB].[method].[material_set_list] on [material_sets].[id] = [material_set_list].[id]
					and ([material_sets].[process_id] = 317 OR [material_sets].[process_id] = 18)
				inner join [APCSProDB].[material].[productions] on [material_set_list].[material_group_id] = [productions].[id]
					and productions.details = 'TOMSON'
			) as [tomson] on [device_flows].[material_set_id] = [tomson].[id]
		) as [tomson] on [lot_cb].[lot_id] = [tomson].[lot_id]
		------->>> Find tomson APCSProDB
		left join [APCSProDB].[trans].[surpluses] on [lot].[lot_no] = [surpluses].[serial_no] --add join original_lot_id 
		left join APCSProDB.method.multi_labels as multi_label on dv.name COLLATE Latin1_General_CI_AS = multi_label.device_name COLLATE Latin1_General_CI_AS
		where [lot_cb].[lot_id] = @Lot_id
		---New query 26/04/2022 08.40
	END
	ELSE
	BEGIN
		---New query 26/04/2022 08.40
		select top(1) @Lotno = lot.lot_no
		, @QTY = case when SUBSTRING(lot.lot_no,5,1) = 'D' then lot.qty_pass else qty_out + qty_hasuu end
		, @qty_shipment = lot.qty_out
		, @reel_num = case when [surpluses].[original_lot_id] is not null or [surpluses].[original_lot_id] != 0 then 0 
							else (qty_out + qty_hasuu)/@pcs_per_pack_control end
		, @reel_num_shipment = (lot.qty_out/@pcs_per_pack_control)
		, @Hasuu_qty = case when [surpluses].[original_lot_id] is not null or [surpluses].[original_lot_id] != 0 then lot.qty_pass 
							else 
								case when @PC_Code_Value = 13 and SUBSTRING(lot.lot_no,5,1) = 'D' then lot.qty_hasuu 
									 when @PC_Code_Value = 13 and SUBSTRING(lot.lot_no,5,1) <> 'D' then lot.qty_out  --add condition for support tube hasuu shipment 2024/02/19 time : 13.26 by Aomsin
									 else (qty_out + qty_hasuu)%(@pcs_per_pack_control) end
							end
		, @Package = [pk].[name]
		, @Shortname = [pk].[short_name]
		, @Device = case when SUBSTRING(lot.lot_no,5,1) = 'E' or (SUBSTRING(lot.lot_no,5,1) = 'F' and pc_instruction_code = 13) then allo_cat.ROHM_Model_Name else [dv].[name] end  --add confition 2023/09/25 time : 08.51, update 2024/01/09 time : 15.06
		, @AssyName = [dv].[assy_name]
		--, @Customer_Device = case when SUBSTRING(lot.lot_no,5,1) = 'E' or (SUBSTRING(lot.lot_no,5,1) = 'F' and pc_instruction_code = 13) then allo_cat.ROHM_Model_Name   --add confition 2023/09/25 time : 08.51, update 2024/01/09 time : 15.06
		--						else (case 
		--								when (multi_label.USER_Model_Name is null or multi_label.USER_Model_Name = '') then dv.name 
		--								else 
		--									case 
		--										when (multi_label.USER_Model_Name is not null or multi_label.USER_Model_Name != '') 
		--											and (multi_label.delete_flag = 1) then dv.name 
		--										else multi_label.USER_Model_Name 
		--									end
		--								end)
		--						end
		, @Customer_Device = case when SUBSTRING(lot.lot_no,5,1) = 'E' or (SUBSTRING(lot.lot_no,5,1) = 'F' and pc_instruction_code = 13) 
			   then case when (multi_label.USER_Model_Name is null or multi_label.USER_Model_Name = '') 
						 then allo_cat.ROHM_Model_Name  
						 else (case 
									when (multi_label.USER_Model_Name is not null or multi_label.USER_Model_Name != '') 
										and (multi_label.delete_flag = 1) then allo_cat.ROHM_Model_Name 
									else multi_label.USER_Model_Name 
								end) 
						end
				else (case 
						when (multi_label.USER_Model_Name is null or multi_label.USER_Model_Name = '') then dv.name 
						else 
							case 
								when (multi_label.USER_Model_Name is not null or multi_label.USER_Model_Name != '') 
									and (multi_label.delete_flag = 1) then dv.name 
								else multi_label.USER_Model_Name 
							end
						end)
				end 
		, @Rank = case when dv.rank is null then '' else dv.rank end
		, @TPRank = case when dv.tp_rank is null then '' else dv.tp_rank end
		, @Standard = @pcs_per_pack_control
		, @Total = ([qty_out] + [qty_hasuu]) - ([qty_out] + [qty_hasuu])%(@pcs_per_pack_control) 
		, @Tomson_box = [tomson].[tomson_box]
		, @BoxType = [tomson].[tomson_box]
		, @OPNo = [lot_cb].[updated_by]
		, @qty_hasuu_in_tran_lot = [lot].[qty_hasuu]
		from APCSProDB.trans.lot_combine as lot_cb
		inner join APCSProDB.trans.lots as lot on lot_cb.lot_id = lot.id
		inner join APCSProDB.method.packages as pk on lot.act_package_id = pk.id
		inner join APCSProDB.method.device_names as dv on lot.act_device_name_id = dv.id
		left join APCSProDB.method.allocat as allo_cat on lot.lot_no = allo_cat.LotNo --Use allocat Table
		-------<<< Find tomson APCSProDB
		left join 
		(
			select [lots].[id] as [lot_id]
				, [lots].[lot_no]
				, isnull([tomson].[tomson_box],'') as [tomson_box]
			from [APCSProDB].[trans].[lots] 
			inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id] 
			inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id] 
				and [device_slips].[is_released] = 1 
			inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] on [device_names].[package_id] = [packages].[id]
			inner join [APCSProDB].[method].[device_flows] on [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
				and [device_flows].[job_id] = 317 
			left join 
			(
				select [material_sets].[id],[productions].[name] as [tomson_box]
				from [APCSProDB].[method].[material_sets]
				inner join [APCSProDB].[method].[material_set_list] on [material_sets].[id] = [material_set_list].[id]
					and ([material_sets].[process_id] = 317 OR [material_sets].[process_id] = 18)
				inner join [APCSProDB].[material].[productions] on [material_set_list].[material_group_id] = [productions].[id]
					and productions.details = 'TOMSON'
			) as [tomson] on [device_flows].[material_set_id] = [tomson].[id]
		) as [tomson] on [lot_cb].[lot_id] = [tomson].[lot_id]
		------->>> Find tomson APCSProDB
		left join [APCSProDB].[trans].[surpluses] on [lot].[lot_no] = [surpluses].[serial_no] --add join original_lot_id 
		left join APCSProDB.method.multi_labels as multi_label on dv.name COLLATE Latin1_General_CI_AS = multi_label.device_name COLLATE Latin1_General_CI_AS
		where [lot_cb].[lot_id] = @Lot_id
		---New query 26/04/2022 08.40
	END

	--Add Condition Wait Task Run Data MSL Create : 2021/12/03 Time : 09.14 AM
	SELECT @get_time_value_msl =  CONVERT(VARCHAR(5), GETDATE(), 108)
	IF (@get_time_value_msl = '04:45')
	BEGIN
		WAITFOR DELAY '00:00:04'
		--check MSL Data 2021/06/19 
		IF EXISTS(SELECT 1 from APCSProDB.method.mslevel_data where Product_Name = TRIM(@Device))
		BEGIN
			--select 'device' as device
			select @SPEC = Spec
			,@FLOOR_LIFE = Floor_Life
			,@PPBT = PPBT 
			from APCSProDB.method.mslevel_data where Product_Name = TRIM(@Device)
		END
		ELSE
		BEGIN
			--select 'package' as package
			select @SPEC = Spec
			,@FLOOR_LIFE = Floor_Life
			,@PPBT = PPBT 
			from APCSProDB.method.mslevel_data where Product_Name = TRIM(@Shortname)
		END
	END
	ELSE
	BEGIN
		--check MSL Data 2021/06/19 
		IF EXISTS(SELECT 1 from APCSProDB.method.mslevel_data where Product_Name = TRIM(@Device))
		BEGIN
			--select 'device' as device
			select @SPEC = Spec
			,@FLOOR_LIFE = Floor_Life
			,@PPBT = PPBT 
			from APCSProDB.method.mslevel_data where Product_Name = TRIM(@Device)
		END
		ELSE
		BEGIN
			--select 'package' as package
			select @SPEC = Spec
			,@FLOOR_LIFE = Floor_Life
			,@PPBT = PPBT 
			from APCSProDB.method.mslevel_data where Product_Name = TRIM(@Shortname)
		END
	END

	--check logo UL
	SELECT @Required_ul_logo = required_ul_logo FROM [APCSProDB].[method].[device_names] where name = @Device and assy_name = @AssyName

	--Add Condition Check Record on Allocat Table Create Date : 2022/11/21 Time : 15.55
	IF @Check_Record_Allocat = 0
	BEGIN
		select @Tomson_Mark_3 = Tomson3 from [APCSProDB].[method].[allocat_temp] where LotNo = @Lotno
	END
	ELSE
	BEGIN
		select @Tomson_Mark_3 = Tomson3 from [APCSProDB].[method].[allocat] where LotNo = @Lotno
	END

	--Add Tomson3 or qcInstruction is type D lot
	SELECT @Tomson_Mark_3_Surpluses = case when qc_instruction is null then '' else qc_instruction end from APCSProDB.trans.surpluses where serial_no = @Lotno

	DECLARE @op_no_len varchar(10);
	DECLARE @op_no_len_value varchar(10);
	DECLARE @factories_name nvarchar(10) = ''

	--add check condition empno in process value date modify : 2022/02/25 time : 11.15
	SELECT @op_no_len = CASE WHEN @process_name = 'OGI' then @emp_no_val else @OPNo end
	
	--add condition for factories_name check  --> date modify : 2023/04/26 
	SELECT @factories_name = factories.name
	FROM APCSProDB.man.users
	INNER JOIN APCSProDB.man.user_organizations 
		on users.id = user_organizations.user_id
	INNER JOIN APCSProDB.man.organizations 
		on user_organizations.organization_id = organizations.id
	INNER JOIN APCSProDB.man.headquarters 
		on organizations.headquarter_id = headquarters.id
	INNER JOIN APCSProDB.man.factories 
		on headquarters.factory_id = factories.id
	where emp_num = @op_no_len


	--the condition check for support a philiphines 
	IF @factories_name = 'REPI'  
	BEGIN
		SELECT @OPName =
		CASE
			WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MR.' THEN LEFT(SUBSTRING([users].name, 5,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
			WHEN SUBSTRING(CAST(name as char(20)),1,4) ='MISS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
			WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MRS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		ELSE SUBSTRING(CAST(name as char(20)), 1,LEN([users].name)) END 
		FROM [APCSProDB].[man].[users]
		WHERE [users].[emp_num] = @op_no_len
	END
	ELSE
	BEGIN
		SELECT  @op_no_len_value =  case when LEN(CAST(@op_no_len as varchar(10))) = 5 then '0' + CAST(@op_no_len as varchar(10))
			WHEN LEN(CAST(@op_no_len as varchar(10))) = 4 then '00' + CAST(@op_no_len as varchar(10))
			WHEN LEN(CAST(@op_no_len as varchar(10))) = 3 then '000' + CAST(@op_no_len as varchar(10))
			WHEN LEN(CAST(@op_no_len as varchar(10))) = 2 then '0000' + CAST(@op_no_len as varchar(10))
			ELSE CAST(@op_no_len as varchar(10)) end 

		SELECT @OPName =
		CASE
			WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MR.' THEN LEFT(SUBSTRING([users].name, 5,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
			WHEN SUBSTRING(CAST(name as char(20)),1,4) ='MISS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
			WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MRS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		ELSE SUBSTRING(CAST(name as char(20)), 1,LEN([users].name)) END 
		FROM [APCSProDB].[man].[users]
		WHERE [users].[emp_num] = @op_no_len_value
	END

	DECLARE @check_mno_for_reel float = CAST(@qty_hasuu_before as float) / CAST(@Standard as float);
	select @convert_mno_value = CEILING(@check_mno_for_reel) 

	select @Status_lot = case when  lot_id = member_lot_id then 'FRISTLOT' else 'CONTUNUELOT' end
	from APCSProDB.trans.lot_combine where lot_id = @Lot_id

	--Check Data Tray Creater : 2021/10/26
	DECLARE @chk_tp_rank varchar(5) = ''
	DECLARE @chk_universal_tp_rank varchar(5) = ''
	
	--GET Data Tray Creater : 2021/10/26
	DECLARE @count_qty_set_tray int = 0	--count set
	DECLARE @qty_set_tray int = 0 --qty : set such as standard 1000 แต่มี 2 set จะมี set ละ 500
	DECLARE @count_tray int = 0
	DECLARE @check_type_tube int = 0 --NO USE ==> 2, USE ==> 1
	DECLARE @check_type_tray int = 0 --NO USE ==> 2, USE ==> 1
	--Create Parameter Check Mno Label Tray Date : 2021/11/1
	DECLARE @convert_mno_hasuu_tray int = 0

	--IF @chk_tp_rank = '' and @chk_universal_tp_rank = '' --close : 2022/07/19 time : 10.38
	--BEGIN
		SELECT @count_qty_set_tray = REPLACE(ISNULL(tray_qty.use_qty_tray,''),' set','') 
		,@check_type_tube = CASE WHEN pvt.id is null THEN ''
			  WHEN TUBE IS NULL THEN '2' ELSE  '1' END --AS TUBE
		,@check_type_tray = CASE WHEN pvt.id is null THEN ''
			  WHEN TRAY IS NULL THEN '2' ELSE  '1' END --AS TRAY
		FROM APCSProDB.trans.lots 
		INNER JOIN [APCSProDB].method.device_slips ON device_slips.device_slip_id = lots.device_slip_id 
		INNER JOIN [APCSProDB].method.device_versions ON device_versions.device_id = device_slips.device_id 
		AND [APCSProDB].method.device_slips.is_released = 1 
							
		--AND device_versions.device_type = 6 --- comment ถ้าใช้เลข Lot ในการเรียก Store แล้ว
		INNER JOIN [APCSProDB].method.device_names ON [APCSProDB].method.device_names.id = [APCSProDB].method.device_versions.device_name_id 
		INNER JOIN [APCSProDB].method.packages ON [APCSProDB].method.device_names.package_id = [APCSProDB].method.packages.id 
		INNER JOIN [APCSProDB].method.device_flows ON [APCSProDB].method.device_slips.device_slip_id = [APCSProDB].method.device_flows.device_slip_id
		LEFT JOIN  
			(SELECT  ms.id,ms.name,comment,details,p.name as mat_name
			FROM  [APCSProDB].method.material_sets ms 
			INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id INNER JOIN
			[APCSProDB].material.productions p ON ml.material_group_id = p.id 
			where (ms.process_id = 317 OR ms.process_id = 18)
			) mat

			PIVOT ( 
				max(mat_name)
				FOR details
				IN (
				[TUBE],[TRAY]
				)
			) as pvt ON [APCSProDB].method.device_flows.material_set_id = pvt.id

		LEFT JOIN (SELECT msl.id,msl.tomson_code,ib.reel_count FROM APCSProDB.method.material_set_list msl
		LEFT JOIN APCSProDB.method.incoming_boxs ib ON ib.tomson_code = msl.tomson_code AND ib.idx = 1
		WHERE msl.tomson_code IS NOT NULL) AS tb ON tb.id = pvt.id

		LEFT JOIN (SELECT  ms.id,ms.name,comment,details,p.name as mat_name, CONVERT(VARCHAR(10), CONVERT(int, use_qty)) + ' '+ il.label_eng as use_qty_tray 
		FROM [APCSProDB].method.material_sets ms 
		INNER JOIN [APCSProDB].method.material_set_list ml ON ms.id = ml.id 
		INNER JOIN [APCSProDB].material.productions p ON ml.material_group_id = p.id 
		LEFT JOIN APCSProDB.method.item_labels il ON il.val = ml.use_qty_unit and il.name = 'material_set_list.use_qty_unit'
		where (ms.process_id = 317 OR ms.process_id = 18) and details = 'TRAY'
		) AS tray_qty ON tray_qty.id = pvt.id

		--LEFT JOIN StoredProcedureDB.dbo.IS_PACKING_MAT as pack_mat on device_names.name = pack_mat.ROHM_Model_Name  --close : 2022/07/19 time : 10.38
		LEFT JOIN [APCSProDB].[method].[jobs] AS [job] ON [job].[id] = device_flows.[job_id]
		WHERE device_flows.job_id = 317 
		and lot_no = @Lotno
		--ORDER BY packages.name,device_names.name --close : 2022/07/19 time : 10.38

		--Get Condition Tray work Creater : 2021/10/26
		--select @qty_set_tray = case when @count_qty_set_tray = '' then 0 else (@Standard/@count_qty_set_tray) end --close 2024/03/21 time : 09.00 by Aomsin
		select @qty_set_tray = case when @count_qty_set_tray = '' then 0 else IIF(@is_std_tube_adjust <> 0,@Standard,(@Standard/@count_qty_set_tray)) end
		select @count_tray = case when @qty_set_tray = 0 then 0 else (@qty_shipment/@qty_set_tray) end
		
		--Create Check Mno Label Tray Date : 2021/11/1
		DECLARE @check_mno_hasuu_for_tray float = case when @qty_set_tray = 0 then 0 else (CAST(@qty_hasuu_before as float) / CAST(@qty_set_tray as float)) end
		select @convert_mno_hasuu_tray = CEILING(@check_mno_hasuu_for_tray) 

	--Add Log Date : 2021/09/16 
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
		,'EXEC [dbo].[tg_sp_set_data_label_history_V.3_new_version_20240206] @Lotno = ''' + @Lotno + ''', @Process = ''' + @process_name + ''', @Qc_Instruction = ''' + @Tomson_Mark_3 + ''', @emp_no_at_ogi = ''' + @emp_no_val + ''', @qty_shipment = ''' + CONVERT(VARCHAR(6),@qty_shipment) + ''''
		,@Lotno


	DECLARE @i INT = 0;
	DECLARE @Mno_hasuu_value char(10) = ''

	--create #tempDataByOom
	--Edit Function insert data to table form #temptable is Declare table type --> Date Modify : 2022/01/21 Time : 14.35
	DECLARE @tempData TABLE(
	   [recorded_at] [datetime] NOT NULL
      ,[operated_by] [int] NOT NULL
      ,[type_of_label] [int] NOT NULL
      ,[lot_no] [char](10) NOT NULL
      ,[customer_device] [char](20) NOT NULL
      ,[rohm_model_name][char](20) NOT NULL
      ,[qty] [char](20) NOT NULL
      ,[barcode_lotno] [char](20) NOT NULL
      ,[tomson_box] [char](20) NOT NULL
      ,[tomson_3] [char](20) NOT NULL
      ,[box_type] [char](20) NOT NULL
      ,[barcode_bottom] [char](18) NOT NULL
      ,[mno_std] [char](20) NOT NULL
      ,[std_qty_before] [char](20) NOT NULL
      ,[mno_hasuu] [char](20) NOT NULL
      ,[hasuu_qty_before] [char](20) NOT NULL
      ,[no_reel] [char](20) NOT NULL
      ,[qrcode_detail] [char](90) NOT NULL
      ,[type_label_laterat] [char](20) NOT NULL
      ,[mno_std_laterat] [char](20) NOT NULL
      ,[mno_hasuu_laterat] [char](20) NOT NULL
      ,[barcode_device_detail] [char](20) NOT NULL
      ,[op_no] [int] NOT NULL
      ,[op_name] [char](20) NULL
      ,[seq] [int] NULL
      ,[msl_label]  [varchar](15) NULL
      ,[floor_life] [varchar](15) NULL
      ,[ppbt] [varchar](15) NULL
      ,[re_comment] [varchar](60) NOT NULL
      ,[version] [int] NULL
      ,[is_logo] [int] NULL
      ,[mc_name] [char](15) NULL
      ,[seal] [varchar](10) NOT NULL
      ,[create_at] [datetime] NULL
      ,[create_by] [int] NULL
      ,[update_at] [datetime] NULL
      ,[update_by] [int] NULL
	);

	DECLARE @sql varchar(max);
	SET @i = 1;

	IF @process_name = 'TP'
	BEGIN
		print '@PC_Code_Value = ' + CAST(@PC_Code_Value as char(2)) 
		print 'reel num before = ' + CAST(@reel_num as char(2)) 

		IF @PC_Code_Value = 13  --cut off 2023/09/05
		BEGIN
			IF @Lotno_subType = 'D'
			BEGIN
				select @reel_num = 1
			END
		END

		print 'reel num after = ' + CAST(@reel_num as char(2))
		
		WHILE @i <= @reel_num + 2
		BEGIN
		print '@i = ' + CAST(@i as char(2))
		--#1
		IF @i = 1
			BEGIN	
				INSERT INTO @tempData 
				(
					recorded_at
					,operated_by
					,type_of_label
					,lot_no
					,customer_device
					,rohm_model_name
					,qty
					,barcode_lotno
					,tomson_box
					,tomson_3
					,box_type
					,barcode_bottom
					,mno_std
					,std_qty_before
					,mno_hasuu
					,hasuu_qty_before
					,no_reel
					,qrcode_detail
					,type_label_laterat
					,mno_std_laterat
					,mno_hasuu_laterat
					,barcode_device_detail
					,op_no
					,op_name
					,seq,msl_label
					,floor_life
					,ppbt
					,re_comment
					,version
					,is_logo
					,mc_name
					,seal
					,create_at
					,create_by
					,update_at
					,update_by
				) 
				VALUES
				(
					convert(varchar(max),getdate(),121)
					,@OPNo
					,1
					,Cast((@Lotno) as char(10))
					,Cast((@Customer_Device) as char(20))
					,Cast((@Device) as char(20))
					,Cast((@QTY) as char(20))
					,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
					,case 
						when Cast((@Tomson_box) as char(20)) is null or Cast((@Tomson_box) as char(20)) = '' then ' ' 
						else Cast((@Tomson_box) as char(20)) 
					end
					,case 
						when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
						else Cast((@Tomson_Mark_3) as char(4)) 
					end 
					,case 
						when Cast((@BoxType) as char(20)) is null or Cast((@BoxType) as char(20)) = '' then ' ' 
						else Cast((@BoxType) as char(20)) 
					end
					,Cast((@QTY) as char(20))
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
						else Cast((@Mno_Standard) as char(20)) 
					end
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' then CAST((@qty_shipment) as char(20)) 
						else 
							case 
								when @qty_lot_standard_before is null then '0' 
								else CAST((@qty_lot_standard_before) as char(20)) 
							end
					end
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then ' ' 
						else  Cast((@Mno_Hasuu) as char(20)) 
					end
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' then CAST(('0') as char(20)) 
						else 
							case 
								when @qty_hasuu_before is null then '0' 
								else CAST((@qty_hasuu_before) as char(20)) 
							end
					end
					,Cast((2 + @reel_num) as char(3))
					,Cast(@Device as varchar(19)) + 
						case 
							when LEN(CAST(@QTY as varchar(6))) = 5 then '0' + CAST(@QTY as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 2) > 9) then '0' + Cast((@reel_num + 2) as char(3)) 
									else '00' + Cast((@reel_num + 2) as char(3)) 
								end
							when LEN(CAST(@QTY as varchar(6))) = 4  then '00' + CAST(@QTY as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 2) > 9) then '0' + Cast((@reel_num + 2) as char(3))
									else '00' + Cast((@reel_num + 2) as char(3)) 
								end
							when LEN(CAST(@QTY as varchar(6))) = 3 then '000' + CAST(@QTY as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 2) > 9) then '0' + Cast((@reel_num + 2) as char(3)) 
									else '00' + Cast((@reel_num + 2) as char(3)) 
								end
							when LEN(CAST(@QTY as varchar(6))) = 2 then '0000' + CAST(@QTY as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 2) > 9) then '0' + Cast((@reel_num + 2) as char(3)) 
									else '00' + Cast((@reel_num + 2) as char(3)) 
								end
							when LEN(CAST(@QTY as varchar(6))) = 1 then '00000' + CAST(@QTY as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 2) > 9) then '0' + Cast((@reel_num + 2) as char(3)) 
									else '00' + Cast((@reel_num + 2) as char(3)) 
								end
							else CAST(@QTY as varchar(6)) + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num) + 2 > 9) then '0' + Cast((@reel_num + 2) as char(3)) 
									else '00' + Cast((@reel_num + 2) as char(3)) 
								end 
						end
					,''
					,''
					,''
					,''
					,@OPNo
					,Cast((@OPName) as char(20))
					,''
					,Cast((@SPEC) as varchar(15))
					,Cast((@FLOOR_LIFE) as varchar(15))
					,Cast((@PPBT) as varchar(15))
					,''
					,''
					,Cast((@Required_ul_logo) as varchar(1))
					,''
					,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
					,convert(varchar(max),getdate(),121)
					, @OPNo
					,convert(varchar(max),getdate(),121)
					,@OPNo
				)
			END
		--#2
		ELSE IF @i = 2
			BEGIN	
				INSERT INTO @tempData 
				(
					recorded_at
					,operated_by
					,type_of_label
					,lot_no
					,customer_device
					,rohm_model_name
					,qty
					,barcode_lotno
					,tomson_box
					,tomson_3
					,box_type
					,barcode_bottom
					,mno_std
					,std_qty_before
					,mno_hasuu
					,hasuu_qty_before
					,no_reel
					,qrcode_detail
					,type_label_laterat
					,mno_std_laterat
					,mno_hasuu_laterat
					,barcode_device_detail
					,op_no
					,op_name
					,seq,msl_label
					,floor_life
					,ppbt
					,re_comment
					,version
					,is_logo
					,mc_name
					,seal
					,create_at
					,create_by
					,update_at
					,update_by
				) 
				VALUES
				(
					convert(varchar(max),getdate(),121)
					,@OPNo
					,2
					,Cast((@Lotno) as char(10))
					,Cast((@Customer_Device) as char(20))
					,Cast((@Device) as char(20))
					,Cast((@Hasuu_qty) as char(20))
					,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
					,''
					,case 
						when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
						else Cast((@Tomson_Mark_3) as char(4)) 
					end
					,''
					,case 
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 1 then '00000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						else CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
					end
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
						else Cast((@Mno_Standard) as char(20)) 
					end
					,''
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
						else Cast((@Mno_Hasuu) as char(20)) 
					end
					,''
					,Cast((1 + @reel_num) as char(3))
					,Cast(@Device as varchar(19)) + 
						case 
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 1 then '00000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							else CAST(@Hasuu_qty as varchar(6)) + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num) + 1 > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end 
						end
					,''
					,''
					,''
					,Cast((@Device) as char(20))
					,@OPNo
					,Cast((@OPName) as char(20))
					,''
					,Cast((@SPEC) as varchar(15))
					,Cast((@FLOOR_LIFE) as varchar(15))
					,Cast((@PPBT) as varchar(15))
					,''
					,''
					, Cast((@Required_ul_logo) as varchar(1))
					,''
					,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
					,convert(varchar(max),getdate(),121)
					,@OPNo
					,convert(varchar(max),getdate(),121)
					,@OPNo
				)
			END
		--#more then 3
		ELSE
			BEGIN

				IF @PC_Code_Value = 13 --cut off 2023/09/05
				BEGIN
					IF @Lotno_subType = 'D'
					BEGIN
						select @Standard = @qty_shipment
					END
				END
				
				INSERT INTO @tempData 
				(
					recorded_at
					,operated_by
					,type_of_label
					,lot_no
					,customer_device
					,rohm_model_name
					,qty
					,barcode_lotno
					,tomson_box
					,tomson_3
					,box_type
					,barcode_bottom
					,mno_std
					,std_qty_before
					,mno_hasuu
					,hasuu_qty_before
					,no_reel
					,qrcode_detail
					,type_label_laterat
					,mno_std_laterat
					,mno_hasuu_laterat
					,barcode_device_detail
					,op_no
					,op_name
					,seq,msl_label
					,floor_life
					,ppbt
					,re_comment
					,version
					,is_logo
					,mc_name
					,seal
					,create_at
					,create_by
					,update_at
					,update_by
				) 
				VALUES
				(
					convert(varchar(max),getdate(),121)
					,@OPNo
					,IIF(@PC_Code_Value = 13,20,3)
					,Cast((@Lotno) as char(10))
					,Cast((@Customer_Device) as char(20))
					,Cast((@Device) as char(20))
					,Cast((@Standard) as char(20))
					,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
					,''
					,case 
						when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
						else Cast((@Tomson_Mark_3) as char(4)) 
					end
					,''
					,case 
						when LEN(CAST(@Standard as varchar(6))) = 5 then '0' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Standard as varchar(6))) = 4 then '00' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Standard as varchar(6))) = 3 then '000' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Standard as varchar(6))) = 2 then '0000' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Standard as varchar(6))) = 1 then '00000' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))  --add lenght 1 then '00000' date modify : 2024/07/04 time : 08.44 by Aomsin
						else CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
					end
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
						else Cast((@Mno_Standard) as char(20)) 
					end
					,''
					,case 
						when @Status_lot = 'FRISTLOT' then 
							case 
								when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then ' ' 
								else ' ' 
							end
						else 
							case 
								when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then ' ' 
								else 
									case 
										when @i-2 <= @convert_mno_value then Cast((@Mno_Hasuu) as char(20)) 
										else ' ' 
									end 
							end
					end	
					,''
					,Cast((@i-2) as char(3))
					,Cast(@Device as varchar(19)) + 
						case 
							when LEN(CAST(@Standard as varchar(6))) = 5 then '0' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@i-2 > 9) then '0' + Cast((@i-2) as char(3)) 
									else '00' + Cast((@i-2) as char(3)) 
								end 
							when LEN(CAST(@Standard as varchar(6))) = 4 then '00' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@i-2 > 9) then '0' + Cast((@i-2) as char(3)) 
									else '00' + Cast((@i-2) as char(3)) 
								end
							when LEN(CAST(@Standard as varchar(6))) = 3 then '000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@i-2 > 9) then '0' + Cast((@i-2) as char(3)) 
									else '00' + Cast((@i-2) as char(3)) 
								end
							when LEN(CAST(@Standard as varchar(6))) = 2 then '0000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@i-2 > 9) then '0' + Cast((@i-2) as char(3)) 
									else '00' + Cast((@i-2) as char(3)) 
								end
							when LEN(CAST(@Standard as varchar(6))) = 1 then '00000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@i-2 > 9) then '0' + Cast((@i-2) as char(3)) 
									else '00' + Cast((@i-2) as char(3)) 
								end  --add lenght 1 then '00000' date modify : 2024/07/04 time : 08.44 by Aomsin
							else CAST(@Standard as varchar(6)) + CAST(@Lotno as varchar(10)) + 
								case 
									when (@i-2 > 9) then '0' + Cast((@i-2) as char(3)) 
									else '00' + Cast((@i-2) as char(3)) 
								end
						end
					,''
					,''
					,''
					,Cast((@Device) as char(20))
					,@OPNo
					,Cast((@OPName) as char(20))
					,''
					,Cast((@SPEC) as varchar(15))
					,Cast((@FLOOR_LIFE) as varchar(15))
					,Cast((@PPBT) as varchar(15))
					,''
					,''
					,Cast((@Required_ul_logo) as varchar(1))
					,''
					,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
					,convert(varchar(max),getdate(),121)
					,@OPNo
					,convert(varchar(max),getdate(),121)
					,@OPNo
				)
			END
			SET @i = @i + 1;
		END;
		PRINT 'Done FOR LOOP';
	END

	IF @process_name = 'OGI'
	BEGIN
		IF @PC_Code_Value = 13 --Chekc PC_Request type hasuu reel date modify : 2022/02/25 time : 11.15
		BEGIN
			--add condition get data qty_shipment of pc request (support new function pc request be specific d-lot type) cut off 2023/09/05
			IF @Lotno_subType = 'D'
			BEGIN
				select @Hasuu_qty = @qty_shipment
			END
			
			IF @check_type_tray = 1  --update date modify : 2022/08/10 time : 16.17
			BEGIN
				IF (@QTY < @Standard and @QTY > @qty_set_tray)  --add condition : 2022/08/11 time : 08.56
				BEGIN
					--drypack
					INSERT INTO @tempData 
					(
						recorded_at
						,operated_by
						,type_of_label
						,lot_no
						,customer_device
						,rohm_model_name
						,qty
						,barcode_lotno
						,tomson_box
						,tomson_3
						,box_type
						,barcode_bottom
						,mno_std
						,std_qty_before
						,mno_hasuu
						,hasuu_qty_before
						,no_reel
						,qrcode_detail
						,type_label_laterat
						,mno_std_laterat
						,mno_hasuu_laterat
						,barcode_device_detail
						,op_no
						,op_name
						,seq,msl_label
						,floor_life
						,ppbt
						,re_comment
						,version
						,is_logo
						,mc_name
						,seal
						,create_at
						,create_by
						,update_at
						,update_by
					) 
					VALUES
					(
						convert(varchar(max),getdate(),121)
						,@emp_no_val
						,4  --set type label = 5 is drypack tray shipment
						,Cast((@Lotno) as char(10))
						,Cast((@Customer_Device) as char(20))
						,Cast((@Device) as char(20))
						,Cast((@Hasuu_qty) as char(20))
						,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
						,''
						,case 
							when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
							else Cast((@Tomson_Mark_3) as char(4)) 
						end
						,''
						,case 
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 1 then '00000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							else CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
						end
						,case 
							when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
							else Cast((@Mno_Standard) as char(20)) 
						end
						,''
						,case 
							when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
							else Cast((@Mno_Hasuu) as char(20)) 
						end
						,''
						,Cast((1 + @reel_num) as char(3))
						,Cast(@Device as varchar(19)) + 
							case 
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 1 then '00000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								else CAST(@Hasuu_qty as varchar(6)) + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num) + 1 > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end 
							end
						,''
						,''
						,''
						,Cast((@Device) as char(20))
						,@emp_no_val
						,Cast((@OPName) as char(20))
						,''
						,Cast((@SPEC) as varchar(15))
						,Cast((@FLOOR_LIFE) as varchar(15))
						,Cast((@PPBT) as varchar(15))
						,''
						,''
						, Cast((@Required_ul_logo) as varchar(1))
						,''
						,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
						,convert(varchar(max),getdate(),121)
						,@emp_no_val
						,convert(varchar(max),getdate(),121)
						,@emp_no_val
					)
					--Tomson
					INSERT INTO @tempData 
					(
						recorded_at
						,operated_by
						,type_of_label
						,lot_no
						,customer_device
						,rohm_model_name
						,qty
						,barcode_lotno
						,tomson_box
						,tomson_3
						,box_type
						,barcode_bottom
						,mno_std
						,std_qty_before
						,mno_hasuu
						,hasuu_qty_before
						,no_reel
						,qrcode_detail
						,type_label_laterat
						,mno_std_laterat
						,mno_hasuu_laterat
						,barcode_device_detail
						,op_no
						,op_name
						,seq,msl_label
						,floor_life
						,ppbt
						,re_comment
						,version
						,is_logo
						,mc_name
						,seal
						,create_at
						,create_by
						,update_at
						,update_by
					) 
					VALUES
					(
						convert(varchar(max),getdate(),121)
						,@emp_no_val
						,5  --set type label = 5 is tomson tray shipment
						,Cast((@Lotno) as char(10))
						,Cast((@Customer_Device) as char(20))
						,Cast((@Device) as char(20))
						,Cast((@Hasuu_qty) as char(20))
						,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
						,''
						,case 
							when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
							else Cast((@Tomson_Mark_3) as char(4)) 
						end
						,''
						,case 
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 1 then '00000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							else CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
						end
						,case 
							when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
							else Cast((@Mno_Standard) as char(20)) 
						end
						,''
						,case 
							when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
							else Cast((@Mno_Hasuu) as char(20)) 
						end
						,''
						,Cast((1 + @reel_num) as char(3))
						,Cast(@Device as varchar(19)) + 
							case 
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 1 then '00000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								else CAST(@Hasuu_qty as varchar(6)) + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num) + 1 > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end 
							end
						,''
						,''
						,''
						,Cast((@Device) as char(20))
						,@emp_no_val
						,Cast((@OPName) as char(20))
						,''
						,Cast((@SPEC) as varchar(15))
						,Cast((@FLOOR_LIFE) as varchar(15))
						,Cast((@PPBT) as varchar(15))
						,''
						,''
						, Cast((@Required_ul_logo) as varchar(1))
						,''
						,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
						,convert(varchar(max),getdate(),121)
						,@emp_no_val
						,convert(varchar(max),getdate(),121)
						,@emp_no_val
					)

					--Tray Standard Shipment
					DECLARE @iiiitray int
					DECLARE @isettray int
					DECLARE @hasuu_qty_on_tray int
					SET @iiiitray = 1 
					SET @isettray = 1

					--select @iiiitray as iiiitray,@isettray as isettray,@reel_num_shipment as reel_num_shipment,@count_tray as count_tray,@qty_set_tray as qty_set_tray
					WHILE (@iiiitray <= (@isettray * (@count_tray))) 
					BEGIN
						INSERT INTO @tempData 
						(
							recorded_at
							,operated_by
							,type_of_label
							,lot_no
							,customer_device
							,rohm_model_name
							,qty
							,barcode_lotno
							,tomson_box
							,tomson_3
							,box_type
							,barcode_bottom
							,mno_std
							,std_qty_before
							,mno_hasuu
							,hasuu_qty_before
							,no_reel
							,qrcode_detail
							,type_label_laterat
							,mno_std_laterat
							,mno_hasuu_laterat
							,barcode_device_detail
							,op_no
							,op_name
							,seq,msl_label
							,floor_life
							,ppbt
							,re_comment
							,version
							,is_logo
							,mc_name
							,seal
							,create_at
							,create_by
							,update_at
							,update_by
						) 
						VALUES
						(
							convert(varchar(max),getdate(),121)
							,@emp_no_val
							,6 --type_label : TomsonTray
							,Cast((@Lotno) as char(10))
							,Cast((@Customer_Device) as char(20))
							,Cast((@Device) as char(20))
							,Cast((@qty_set_tray) as char(20))
							,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
							,''
							,case 
								when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
								else Cast((@Tomson_Mark_3) as char(4)) 
							end
							,''
							,case 
								when LEN(CAST(@qty_set_tray as varchar(6))) = 5 then '0' + CAST(@qty_set_tray as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
								when LEN(CAST(@qty_set_tray as varchar(6))) = 4 then '00' + CAST(@qty_set_tray as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
								when LEN(CAST(@qty_set_tray as varchar(6))) = 3 then '000' + CAST(@qty_set_tray as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
								when LEN(CAST(@qty_set_tray as varchar(6))) = 2 then '0000' + CAST(@qty_set_tray as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
								else CAST(@qty_set_tray as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
							end
							,case 
								when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
								else Cast((@Mno_Standard) as char(20)) 
							end 
							,''
							,case 
								when @Status_lot = 'FRISTLOT' then 
									case 
										when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then ' ' 
										else ' ' 
									end
								else 
									case 
										when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then ' ' 
										else 
											case 
												when @iiiitray <= @convert_mno_hasuu_tray then Cast((@Mno_Hasuu) as char(20)) 
												else ' ' 
											end 
									end
							end
							,''
							,Cast((@iiiitray) as char(3))
							,Cast(@Device as varchar(19)) + 
								case 
									when LEN(CAST(@qty_set_tray as varchar(6))) = 5 then '0' + CAST(@qty_set_tray as varchar(6))  + CAST(@Lotno as varchar(10)) + 
										case 
											when (@iiiitray > 9) then '0' + Cast((@iiiitray) as char(3)) 
											else '00' + Cast((@iiiitray) as char(3)) 
										end
									when LEN(CAST(@qty_set_tray as varchar(6))) = 4 then '00' + CAST(@qty_set_tray as varchar(6))  + CAST(@Lotno as varchar(10)) + 
										case 
											when (@iiiitray > 9) then '0' + Cast((@iiiitray) as char(3)) 
											else '00' + Cast((@iiiitray) as char(3)) 
										end
									when LEN(CAST(@qty_set_tray as varchar(6))) = 3 then '000' + CAST(@qty_set_tray as varchar(6))  + CAST(@Lotno as varchar(10)) + 
										case 
											when (@iiiitray > 9) then '0' + Cast((@iiiitray) as char(3)) 
											else '00' + Cast((@iiiitray) as char(3)) 
										end
									when LEN(CAST(@qty_set_tray as varchar(6))) = 2 then '0000' + CAST(@qty_set_tray as varchar(6))  + CAST(@Lotno as varchar(10)) + 
										case 
											when (@iiiitray > 9) then '0' + Cast((@iiiitray) as char(3)) 
											else '00' + Cast((@iiiitray) as char(3)) 
										end
									else CAST(@qty_set_tray as varchar(6)) + CAST(@Lotno as varchar(10)) + 
										case 
											when (@iiiitray > 9) then '0' + Cast((@iiiitray) as char(3)) 
											else '00' + Cast((@iiiitray) as char(3)) 
										end 
								end
							,''
							,''
							,''
							,Cast((@Device) as char(20))
							,@emp_no_val
							,Cast((@OPName) as char(20))
							,Cast((@isettray) as varchar(1)) --seq
							,Cast((@SPEC) as varchar(15))
							,Cast((@FLOOR_LIFE) as varchar(15))
							,Cast((@PPBT) as varchar(15)) 
							,''
							,''
							,Cast((@Required_ul_logo) as varchar(1))
							,''
							,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
							,convert(varchar(max),getdate(),121)
							,@emp_no_val
							,convert(varchar(max),getdate(),121)
							,@emp_no_val
						)

						SET @iiiitray = @iiiitray + 1
					END			
					--------------------------------------------------------------------------------
					--record tomson tray hasuu type label = 6 >> Hasuu Tray <<
					select @hasuu_qty_on_tray  = (@Hasuu_qty%@qty_set_tray) 
					select @Hasuu_qty = @hasuu_qty_on_tray
					INSERT INTO @tempData 
						(
						recorded_at
						,operated_by
						,type_of_label
						,lot_no
						,customer_device
						,rohm_model_name
						,qty
						,barcode_lotno
						,tomson_box
						,tomson_3
						,box_type
						,barcode_bottom
						,mno_std
						,std_qty_before
						,mno_hasuu
						,hasuu_qty_before
						,no_reel
						,qrcode_detail
						,type_label_laterat
						,mno_std_laterat
						,mno_hasuu_laterat
						,barcode_device_detail
						,op_no
						,op_name
						,seq
						,msl_label
						,floor_life
						,ppbt
						,re_comment
						,version
						,is_logo
						,mc_name
						,seal
						,create_at
						,create_by
						,update_at
						,update_by
						) 
						SELECT convert(varchar(max),getdate(),121)
						,@emp_no_val
						,6 --type_label : TomsonTray
						,Cast((@Lotno) as char(10))
						,Cast((@Customer_Device) as char(20))
						,Cast((@Device) as char(20))
						,Cast((@Hasuu_qty) as char(20)) ------ qty hasuu shipment
						,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
						,''
						,case 
							when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
							else Cast((@Tomson_Mark_3) as char(4)) 
						end
						,''
						,case 
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							else CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
						end ------ qty #bass
						,case 
							when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
							else Cast((@Mno_Standard) as char(20)) 
						end 
						,'' --qty mno atd
						,'' -- mno_Hasuu
						,'' --qty mno hasuu
						,Cast((max(no_reel) + 1) as char(3))
						,Cast(@Device as varchar(19)) + 
							case 
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((max(no_reel) + 1) > 9) then '0' + Cast(((max(no_reel) + 1)) as char(3)) 
										else '00' + Cast(((max(no_reel) + 1)) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((max(no_reel) + 1) > 9) then '0' + Cast(((max(no_reel) + 1)) as char(3)) 
										else '00' + Cast(((max(no_reel) + 1)) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((max(no_reel) + 1) > 9) then '0' + Cast(((max(no_reel) + 1)) as char(3)) 
										else '00' + Cast(((max(no_reel) + 1)) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((max(no_reel) + 1) > 9) then '0' + Cast(((max(no_reel) + 1)) as char(3)) 
										else '00' + Cast(((max(no_reel) + 1)) as char(3)) 
									end
								else CAST(@Hasuu_qty as varchar(6)) + CAST(@Lotno as varchar(10)) + 
									case 
										when ((max(no_reel) + 1) > 9) then '0' + Cast(((max(no_reel) + 1)) as char(3)) 
										else '00' + Cast(((max(no_reel) + 1)) as char(3)) 
									end 
							end
						,''
						,''
						,''
						,Cast((@Device) as char(20))
						,@emp_no_val
						,Cast((@OPName) as char(20))
						--,Cast((max(seq) + 1) as varchar(1)) --seq
						,case when (@QTY < @Standard) then '1' else Cast((max(seq) + 1) as varchar(1)) end --seq
						,Cast((@SPEC) as varchar(15))
						,Cast((@FLOOR_LIFE) as varchar(15))
						,Cast((@PPBT) as varchar(15)) 
						,''
						,''
						,Cast((@Required_ul_logo) as varchar(1))
						,''
						,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
						,convert(varchar(max),getdate(),121)
						,@emp_no_val
						,convert(varchar(max),getdate(),121)
						,@emp_no_val
						from @tempData as t1
						where type_of_label = 6
						group by type_of_label
				END
				ELSE
				BEGIN
					--Tray Normal
					INSERT INTO @tempData 
					(
						recorded_at
						,operated_by
						,type_of_label
						,lot_no
						,customer_device
						,rohm_model_name
						,qty
						,barcode_lotno
						,tomson_box
						,tomson_3
						,box_type
						,barcode_bottom
						,mno_std
						,std_qty_before
						,mno_hasuu
						,hasuu_qty_before
						,no_reel
						,qrcode_detail
						,type_label_laterat
						,mno_std_laterat
						,mno_hasuu_laterat
						,barcode_device_detail
						,op_no
						,op_name
						,seq,msl_label
						,floor_life
						,ppbt
						,re_comment
						,version
						,is_logo
						,mc_name
						,seal
						,create_at
						,create_by
						,update_at
						,update_by
					) 
					VALUES
					(
						convert(varchar(max),getdate(),121)
						,@emp_no_val
						,21  --set type label = 21 is Hasuu Reel OGI
						,Cast((@Lotno) as char(10))
						,Cast((@Customer_Device) as char(20))
						,Cast((@Device) as char(20))
						,Cast((@Hasuu_qty) as char(20))
						,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
						,''
						,case 
							when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
							else Cast((@Tomson_Mark_3) as char(4)) 
						end
						,''
						,case 
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 1 then '00000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
							else CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
						end
						,case 
							when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
							else Cast((@Mno_Standard) as char(20)) 
						end
						,''
						,case 
							when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
							else Cast((@Mno_Hasuu) as char(20)) 
						end
						,''
						,Cast((1 + @reel_num) as char(3))
						,Cast(@Device as varchar(19)) + 
							case 
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								when LEN(CAST(@Hasuu_qty as varchar(6))) = 1 then '00000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end
								else CAST(@Hasuu_qty as varchar(6)) + CAST(@Lotno as varchar(10)) + 
									case 
										when ((@reel_num) + 1 > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
										else '00' + Cast((@reel_num + 1) as char(3)) 
									end 
							end
						,''
						,''
						,''
						,Cast((@Device) as char(20))
						,@emp_no_val
						,Cast((@OPName) as char(20))
						,''
						,Cast((@SPEC) as varchar(15))
						,Cast((@FLOOR_LIFE) as varchar(15))
						,Cast((@PPBT) as varchar(15))
						,''
						,''
						, Cast((@Required_ul_logo) as varchar(1))
						,''
						,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
						,convert(varchar(max),getdate(),121)
						,@emp_no_val
						,convert(varchar(max),getdate(),121)
						,@emp_no_val
					)
				END
		    END
			ELSE
			BEGIN
				IF @Lotno_subType = 'D'
				BEGIN
					--add condition support pc-request auto run reel number (if qty all = pcs per pack will set no reel start is zero) modify 2024/05/20 time 09.47 by Aomsin
					--update condition check qtyall >= standard reel modify 2024/09/16 time 14.25 by Aomsin
					select @reel_num = case when (@qty_shipment + @qty_hasuu_in_tran_lot) >= @Standard then 0 else @reel_num end
				END

				--Tray Normal
				INSERT INTO @tempData 
				(
					recorded_at
					,operated_by
					,type_of_label
					,lot_no
					,customer_device
					,rohm_model_name
					,qty
					,barcode_lotno
					,tomson_box
					,tomson_3
					,box_type
					,barcode_bottom
					,mno_std
					,std_qty_before
					,mno_hasuu
					,hasuu_qty_before
					,no_reel
					,qrcode_detail
					,type_label_laterat
					,mno_std_laterat
					,mno_hasuu_laterat
					,barcode_device_detail
					,op_no
					,op_name
					,seq,msl_label
					,floor_life
					,ppbt
					,re_comment
					,version
					,is_logo
					,mc_name
					,seal
					,create_at
					,create_by
					,update_at
					,update_by
				) 
				VALUES
				(
					convert(varchar(max),getdate(),121)
					,@emp_no_val
					,21  --set type label = 21 is Hasuu Reel OGI
					,Cast((@Lotno) as char(10))
					,Cast((@Customer_Device) as char(20))
					,Cast((@Device) as char(20))
					,Cast((@Hasuu_qty) as char(20))
					,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
					,''
					,case 
						when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
						else Cast((@Tomson_Mark_3) as char(4)) 
					end
					,''
					,case 
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 1 then '00000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						else CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
					end
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
						else Cast((@Mno_Standard) as char(20)) 
					end
					,''
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
						else Cast((@Mno_Hasuu) as char(20)) 
					end
					,''
					,Cast((1 + @reel_num) as char(3))
					,Cast(@Device as varchar(19)) + 
						case 
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 1 then '00000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							else CAST(@Hasuu_qty as varchar(6)) + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num) + 1 > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end 
						end
					,''
					,''
					,''
					,Cast((@Device) as char(20))
					,@emp_no_val
					,Cast((@OPName) as char(20))
					,''
					,Cast((@SPEC) as varchar(15))
					,Cast((@FLOOR_LIFE) as varchar(15))
					,Cast((@PPBT) as varchar(15))
					,''
					,''
					, Cast((@Required_ul_logo) as varchar(1))
					,''
					,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
					,convert(varchar(max),getdate(),121)
					,@emp_no_val
					,convert(varchar(max),getdate(),121)
					,@emp_no_val
				)
			END
		END
		ELSE
		BEGIN
			DECLARE @ii int
			SET @ii = 1 

			--edit condition check reel count date : 2021/01/10 time : 16.00
			DECLARE @count_reel_all int = 0
			select @count_reel_all = COUNT(type_of_label) 
			from APCSProDB.trans.label_issue_records 
			where lot_no = @Lotno and type_of_label in (0,3)

			DECLARE @last_reel int = 0
			select @last_reel = max(no_reel) from APCSProDB.trans.label_issue_records 
			where lot_no = @Lotno and type_of_label = 3 

			WHILE (@ii <= @count_reel_all )
			BEGIN
				IF NOT EXISTS(SELECT no_reel as reel
				FROM APCSProDB.trans.label_issue_records
				WHERE lot_no = @Lotno
				and type_of_label = 3
				and no_reel = @ii
				)
					BEGIN
					SET @ii = @ii + 1
					CONTINUE
				END

				IF @check_type_tray = 1
				BEGIN
					IF @is_std_tube_adjust <> 0
					BEGIN
						select @Standard = @QTY
					END
				END

				--type_label : DryPack
				INSERT INTO @tempData 
				(
					recorded_at
					,operated_by
					,type_of_label
					,lot_no
					,customer_device
					,rohm_model_name
					,qty
					,barcode_lotno
					,tomson_box
					,tomson_3
					,box_type
					,barcode_bottom
					,mno_std
					,std_qty_before
					,mno_hasuu
					,hasuu_qty_before
					,no_reel
					,qrcode_detail
					,type_label_laterat
					,mno_std_laterat
					,mno_hasuu_laterat
					,barcode_device_detail
					,op_no
					,op_name
					,seq,msl_label
					,floor_life
					,ppbt
					,re_comment
					,version
					,is_logo
					,mc_name
					,seal
					,create_at
					,create_by
					,update_at
					,update_by
				) 
				VALUES
				(
					convert(varchar(max),getdate(),121)
					,@emp_no_val
					,4 --type_label : DryPack
					,Cast((@Lotno) as char(10)) 
					,Cast((@Customer_Device) as char(20))
					,Cast((@Device) as char(20))
					,Cast((@Standard) as char(20))
					,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
					,''
					,case 
						when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
						else Cast((@Tomson_Mark_3) as char(4)) 
					end
					,''
					,case 
						when LEN(CAST(@Standard as varchar(6))) = 5 then '0' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Standard as varchar(6))) = 4 then '00' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Standard as varchar(6))) = 3 then '000' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Standard as varchar(6))) = 2 then '0000' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						else CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
					end
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
						else Cast((@Mno_Standard) as char(20)) 
					end
					,''
					,case 
						when @Status_lot = 'FRISTLOT' then 
							case 
								when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then ' ' 
								else ' ' 
							end
						else 
							case 
								when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then ' ' 
								else 
									case
										when @ii <= @convert_mno_value then Cast((@Mno_Hasuu) as char(20)) 
										else ' ' 
									end 
							end
					end
					,''
					, Cast((@ii) as char(3))
					,Cast(@Device as varchar(19)) + 
						case 
							when LEN(CAST(@Standard as varchar(6))) = 5 then '0' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@ii > 9) then '0' + Cast((@ii) as char(3)) 
									else '00' + Cast((@ii) as char(3)) 
								end
							when LEN(CAST(@Standard as varchar(6))) = 4 then '00' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@ii > 9) then '0' + Cast((@ii) as char(3)) 
									else '00' + Cast((@ii) as char(3)) 
								end
							when LEN(CAST(@Standard as varchar(6))) = 3 then '000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@ii > 9) then '0' + Cast((@ii) as char(3)) 
									else '00' + Cast((@ii) as char(3)) 
								end
							when LEN(CAST(@Standard as varchar(6))) = 2 then '0000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@ii > 9) then '0' + Cast((@ii) as char(3)) 
									else '00' + Cast((@ii) as char(3)) 
								end
							else CAST(@Standard as varchar(6)) + CAST(@Lotno as varchar(10)) + 
								case 
									when (@ii > 9) then '0' + Cast((@ii) as char(3)) 
									else '00' + Cast((@ii) as char(3)) 
								end
						end
					,''
					,''
					,''
					,Cast((@Device) as char(20))
					,@emp_no_val
					,Cast((@OPName) as char(20))
					,''
					,Cast((@SPEC) as varchar(15))
					,Cast((@FLOOR_LIFE) as varchar(15))
					,Cast((@PPBT) as varchar(15))
					,''
					,''
					,Cast((@Required_ul_logo) as varchar(1))
					,''
					,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
					,convert(varchar(max),getdate(),121)
					,@emp_no_val
					,convert(varchar(max),getdate(),121)
					,@emp_no_val
				)
					
				SET @ii = @ii + 1
				PRINT 'Done FOR LOOP';
			END

			DECLARE @iii int
			SET @iii = 1 

			WHILE (@iii <= @count_reel_all )
			BEGIN
				IF NOT EXISTS(SELECT no_reel as reel
				FROM APCSProDB.trans.label_issue_records
				WHERE lot_no = @Lotno
				and type_of_label = 3
				and no_reel = @iii
				)
					BEGIN
					SET @iii = @iii + 1
					CONTINUE
				END	
				
				IF @check_type_tray = 1
				BEGIN
					IF @is_std_tube_adjust <> 0
					BEGIN
						select @Standard = @QTY
					END
				END

				--type_label : Tomson
				INSERT INTO @tempData 
				(
					recorded_at
					,operated_by
					,type_of_label
					,lot_no
					,customer_device
					,rohm_model_name
					,qty
					,barcode_lotno
					,tomson_box
					,tomson_3
					,box_type
					,barcode_bottom
					,mno_std
					,std_qty_before
					,mno_hasuu
					,hasuu_qty_before
					,no_reel
					,qrcode_detail
					,type_label_laterat
					,mno_std_laterat
					,mno_hasuu_laterat
					,barcode_device_detail
					,op_no
					,op_name
					,seq,msl_label
					,floor_life
					,ppbt
					,re_comment
					,version
					,is_logo
					,mc_name
					,seal
					,create_at
					,create_by
					,update_at
					,update_by
				) 
				VALUES
				(
					convert(varchar(max),getdate(),121)
					,@emp_no_val
					,5 --type_label : Tomson
					,Cast((@Lotno) as char(10))
					,Cast((@Customer_Device) as char(20))
					,Cast((@Device) as char(20))
					,Cast((@Standard) as char(20))
					,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
					,''
					,case 
						when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
						else Cast((@Tomson_Mark_3) as char(4))
					end
					,''
					,case 
						when LEN(CAST(@Standard as varchar(6))) = 5 then '0' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Standard as varchar(6))) = 4 then '00' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Standard as varchar(6))) = 3 then '000' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						 when LEN(CAST(@Standard as varchar(6))) = 2 then '0000' + CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						else CAST(@Standard as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
					end
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
						else Cast((@Mno_Standard) as char(20))
					end
					,''
					,case 
						when @Status_lot = 'FRISTLOT' then 
							case 
								when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then ' ' 
								else ' ' 
							end
						else
							case 
								when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then ' ' 
								else 
									case 
										when @iii <= @convert_mno_value then Cast((@Mno_Hasuu) as char(20)) 
										else ' ' 
									end 
							end
					end
					,''
					,Cast((@iii) as char(3))
					,Cast(@Device as varchar(19)) + 
						case 
							when LEN(CAST(@Standard as varchar(6))) = 5 then '0' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@iii > 9) then '0' + Cast((@iii) as char(3)) 
									else '00' + Cast((@iii) as char(3)) 
								end
							when LEN(CAST(@Standard as varchar(6))) = 4 then '00' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@iii > 9) then '0' + Cast((@iii) as char(3)) 
									else '00' + Cast((@iii) as char(3)) 
								end
							when LEN(CAST(@Standard as varchar(6))) = 3 then '000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@iii > 9) then '0' + Cast((@iii) as char(3)) 
									else '00' + Cast((@iii) as char(3)) 
								end
							when LEN(CAST(@Standard as varchar(6))) = 2 then '0000' + CAST(@Standard as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when (@iii > 9) then '0' + Cast((@iii) as char(3)) 
									else '00' + Cast((@iii) as char(3)) 
								end
							else CAST(@Standard as varchar(6)) + CAST(@Lotno as varchar(10)) + 
								case 
									when (@iii > 9) then '0' + Cast((@iii) as char(3)) 
									else '00' + Cast((@iii) as char(3)) 
								end
						end
					,''
					,''
					,''
					,Cast((@Device) as char(20))
					,@emp_no_val
					,Cast((@OPName) as char(20))
					,''
					,Cast((@SPEC) as varchar(15))
					,Cast((@FLOOR_LIFE) as varchar(15))
					,Cast((@PPBT) as varchar(15))
					,''
					,''
					,Cast((@Required_ul_logo) as varchar(1))
					,''
					,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
					,convert(varchar(max),getdate(),121)
					,@emp_no_val
					,convert(varchar(max),getdate(),121)
					,@emp_no_val 
				)
					
				SET @iii = @iii + 1
				PRINT 'Done FOR LOOP';
			END

			--Set Data Tray work Creater : 2021/10/26
			IF @check_type_tray = 1
			BEGIN
				-- add condition : 2022/08/29 time : 11.05 --
				DECLARE @reel_count_tray_normal int = 0
				DECLARE @shipment_qty_tray int = 0
				select @reel_count_tray_normal = COUNT(type_of_label)  from APCSProDB.trans.label_issue_records where lot_no = @Lotno and type_of_label in (0,3)
				select @shipment_qty_tray = (@reel_count_tray_normal * @pcs_per_pack_control)
				select @reel_num_shipment = @reel_count_tray_normal
				select @count_tray = case when @qty_set_tray = 0 then 0 else (@shipment_qty_tray/@qty_set_tray) end
				-- add condition : 2022/08/29 time : 11.05 --

				--Tray Shipment Normal
				DECLARE @iiii int
				DECLARE @iset int
				SET @iiii = 1 
				SET @iset = 1

				WHILE (@iset <= @reel_num_shipment)
				BEGIN
						WHILE (@iiii <= (@iset * (@count_tray/@reel_num_shipment))) 
						BEGIN
							INSERT INTO @tempData 
							(
								recorded_at
								,operated_by
								,type_of_label
								,lot_no
								,customer_device
								,rohm_model_name
								,qty
								,barcode_lotno
								,tomson_box
								,tomson_3
								,box_type
								,barcode_bottom
								,mno_std
								,std_qty_before
								,mno_hasuu
								,hasuu_qty_before
								,no_reel
								,qrcode_detail
								,type_label_laterat
								,mno_std_laterat
								,mno_hasuu_laterat
								,barcode_device_detail
								,op_no
								,op_name
								,seq,msl_label
								,floor_life
								,ppbt
								,re_comment
								,version
								,is_logo
								,mc_name
								,seal
								,create_at
								,create_by
								,update_at
								,update_by
							) 
							VALUES
							(
								convert(varchar(max),getdate(),121)
								,@emp_no_val
								,6 --type_label : TomsonTray
								,Cast((@Lotno) as char(10))
								,Cast((@Customer_Device) as char(20))
								,Cast((@Device) as char(20))
								,Cast((@qty_set_tray) as char(20))
								,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
								,''
								,case 
									when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
									else Cast((@Tomson_Mark_3) as char(4)) 
								end
								,''
								,case 
									when LEN(CAST(@qty_set_tray as varchar(6))) = 5 then '0' + CAST(@qty_set_tray as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
									when LEN(CAST(@qty_set_tray as varchar(6))) = 4 then '00' + CAST(@qty_set_tray as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
									when LEN(CAST(@qty_set_tray as varchar(6))) = 3 then '000' + CAST(@qty_set_tray as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
									when LEN(CAST(@qty_set_tray as varchar(6))) = 2 then '0000' + CAST(@qty_set_tray as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
									else CAST(@qty_set_tray as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
								end
								,case 
									when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
									else Cast((@Mno_Standard) as char(20)) 
								end 
								,''
								,case 
									when @Status_lot = 'FRISTLOT' then 
										case 
											when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then ' ' 
											else ' ' 
										end
									else 
										case 
											when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then ' ' 
											else 
												case 
													when @iiii <= @convert_mno_hasuu_tray then Cast((@Mno_Hasuu) as char(20)) 
													else ' ' 
												end 
										end
								end
								,''
								,Cast((@iiii) as char(3))
								,Cast(@Device as varchar(19)) + 
									case 
										when LEN(CAST(@qty_set_tray as varchar(6))) = 5 then '0' + CAST(@qty_set_tray as varchar(6))  + CAST(@Lotno as varchar(10)) + 
											case 
												when (@iiii > 9) then '0' + Cast((@iiii) as char(3)) 
												else '00' + Cast((@iiii) as char(3)) 
											end
										when LEN(CAST(@qty_set_tray as varchar(6))) = 4 then '00' + CAST(@qty_set_tray as varchar(6))  + CAST(@Lotno as varchar(10)) + 
											case 
												when (@iiii > 9) then '0' + Cast((@iiii) as char(3)) 
												else '00' + Cast((@iiii) as char(3)) 
											end
										when LEN(CAST(@qty_set_tray as varchar(6))) = 3 then '000' + CAST(@qty_set_tray as varchar(6))  + CAST(@Lotno as varchar(10)) + 
											case 
												when (@iiii > 9) then '0' + Cast((@iiii) as char(3)) 
												else '00' + Cast((@iiii) as char(3)) 
											end
										when LEN(CAST(@qty_set_tray as varchar(6))) = 2 then '0000' + CAST(@qty_set_tray as varchar(6))  + CAST(@Lotno as varchar(10)) + 
											case 
												when (@iiii > 9) then '0' + Cast((@iiii) as char(3)) 
												else '00' + Cast((@iiii) as char(3)) 
											end
										else CAST(@qty_set_tray as varchar(6)) + CAST(@Lotno as varchar(10)) + 
											case 
												when (@iiii > 9) then '0' + Cast((@iiii) as char(3)) 
												else '00' + Cast((@iiii) as char(3)) 
											end 
									end
								,''
								,''
								,''
								,Cast((@Device) as char(20))
								,@emp_no_val
								,Cast((@OPName) as char(20))
								,Cast((@iset) as varchar(1)) --seq
								,Cast((@SPEC) as varchar(15))
								,Cast((@FLOOR_LIFE) as varchar(15))
								,Cast((@PPBT) as varchar(15)) 
								,''
								,''
								,Cast((@Required_ul_logo) as varchar(1))
								,''
								,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
								,convert(varchar(max),getdate(),121)
								,@emp_no_val
								,convert(varchar(max),getdate(),121)
								,@emp_no_val
							)

							SET @iiii = @iiii + 1
						END

					SET @iset = @iset + 1
					PRINT 'Done FOR LOOP';
				END
				--------------------------------------------------------------------------------
			END

			--Check PC Request type Shipment All date modify : 2022/02/25 time : 11.15
			IF @PC_Code_Value = 11
			BEGIN
				--งาน Tray Shipment All add type label = 6 >> Tray hasuu << ถ้า Tray เท่า standard จะทำงานที่ Query ชุดด้านบน
				IF @check_type_tray = 1
				BEGIN
					INSERT INTO @tempData 
					(
					recorded_at
					,operated_by
					,type_of_label
					,lot_no
					,customer_device
					,rohm_model_name
					,qty
					,barcode_lotno
					,tomson_box
					,tomson_3
					,box_type
					,barcode_bottom
					,mno_std
					,std_qty_before
					,mno_hasuu
					,hasuu_qty_before
					,no_reel
					,qrcode_detail
					,type_label_laterat
					,mno_std_laterat
					,mno_hasuu_laterat
					,barcode_device_detail
					,op_no
					,op_name
					,seq,msl_label
					,floor_life
					,ppbt
					,re_comment
					,version
					,is_logo
					,mc_name
					,seal
					,create_at
					,create_by
					,update_at
					,update_by
					) 
					SELECT convert(varchar(max),getdate(),121)
					,@emp_no_val
					,6 --type_label : TomsonTray
					,Cast((@Lotno) as char(10))
					,Cast((@Customer_Device) as char(20))
					,Cast((@Device) as char(20))
					,Cast((@Hasuu_qty) as char(20)) ------ qty hasuu shipment
					,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
					,''
					,case 
						when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
						else Cast((@Tomson_Mark_3) as char(4)) 
					end
					,''
					,case 
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						else CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
					end ------ qty #bass
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
						else Cast((@Mno_Standard) as char(20)) 
					end 
					,'' --qty mno atd
					,'' -- mno_Hasuu
					,'' --qty mno hasuu
					,Cast((max(no_reel) + 1) as char(3))
					,Cast(@Device as varchar(19)) + 
						case 
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((max(no_reel) + 1) > 9) then '0' + Cast(((max(no_reel) + 1)) as char(3)) 
									else '00' + Cast(((max(no_reel) + 1)) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((max(no_reel) + 1) > 9) then '0' + Cast(((max(no_reel) + 1)) as char(3)) 
									else '00' + Cast(((max(no_reel) + 1)) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((max(no_reel) + 1) > 9) then '0' + Cast(((max(no_reel) + 1)) as char(3)) 
									else '00' + Cast(((max(no_reel) + 1)) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((max(no_reel) + 1) > 9) then '0' + Cast(((max(no_reel) + 1)) as char(3)) 
									else '00' + Cast(((max(no_reel) + 1)) as char(3)) 
								end
							else CAST(@Hasuu_qty as varchar(6)) + CAST(@Lotno as varchar(10)) + 
								case 
									when ((max(no_reel) + 1) > 9) then '0' + Cast(((max(no_reel) + 1)) as char(3)) 
									else '00' + Cast(((max(no_reel) + 1)) as char(3)) 
								end 
						end
					,''
					,''
					,''
					,Cast((@Device) as char(20))
					,@emp_no_val
					,Cast((@OPName) as char(20))
					--,Cast((max(seq) + 1) as varchar(1)) --seq  close 2024/03/21 time : 09.00 by Aomsin
					,IIF(@is_std_tube_adjust = 0,Cast((max(seq) + 1) as varchar(1)),1)
					,Cast((@SPEC) as varchar(15))
					,Cast((@FLOOR_LIFE) as varchar(15))
					,Cast((@PPBT) as varchar(15)) 
					,''
					,''
					,Cast((@Required_ul_logo) as varchar(1))
					,''
					,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
					,convert(varchar(max),getdate(),121)
					,@emp_no_val
					,convert(varchar(max),getdate(),121)
					,@emp_no_val
					from @tempData as t1
					where type_of_label = 6
					group by type_of_label
				END
				--งานปกติ record tomson type label = 21
				INSERT INTO @tempData 
				(
					recorded_at
					,operated_by
					,type_of_label
					,lot_no
					,customer_device
					,rohm_model_name
					,qty
					,barcode_lotno
					,tomson_box
					,tomson_3
					,box_type
					,barcode_bottom
					,mno_std
					,std_qty_before
					,mno_hasuu
					,hasuu_qty_before
					,no_reel
					,qrcode_detail
					,type_label_laterat
					,mno_std_laterat
					,mno_hasuu_laterat
					,barcode_device_detail
					,op_no
					,op_name
					,seq,msl_label
					,floor_life
					,ppbt
					,re_comment
					,version
					,is_logo
					,mc_name
					,seal
					,create_at
					,create_by
					,update_at
					,update_by
				) 
				VALUES
				(
					convert(varchar(max),getdate(),121)
					,@emp_no_val
					,21  --set type label = 21 is Hasuu Reel OGI
					,Cast((@Lotno) as char(10))
					,Cast((@Customer_Device) as char(20))
					,Cast((@Device) as char(20))
					,Cast((@Hasuu_qty) as char(20))
					,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
					,''
					,case 
						when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
						else Cast((@Tomson_Mark_3) as char(4)) 
					end
					,''
					,case 
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						when LEN(CAST(@Hasuu_qty as varchar(6))) = 1 then '00000' + CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
						else CAST(@Hasuu_qty as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
					end
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
						else Cast((@Mno_Standard) as char(20)) 
					end
					,''
					,case 
						when @Lotno_subType = 'D' or @Lotno_subType = 'F' or @Lotno_subType = 'B' then 'MX' 
						else Cast((@Mno_Hasuu) as char(20)) 
					end
					,''
					,Cast((1 + @reel_num) as char(3))
					,Cast(@Device as varchar(19)) + 
						case 
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 5 then '0' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 4 then '00' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 3 then '000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 2 then '0000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							when LEN(CAST(@Hasuu_qty as varchar(6))) = 1 then '00000' + CAST(@Hasuu_qty as varchar(6))  + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num + 1) > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end
							else CAST(@Hasuu_qty as varchar(6)) + CAST(@Lotno as varchar(10)) + 
								case 
									when ((@reel_num) + 1 > 9) then '0' + Cast((@reel_num + 1) as char(3)) 
									else '00' + Cast((@reel_num + 1) as char(3)) 
								end 
						end
					,''
					,''
					,''
					,Cast((@Device) as char(20))
					,@emp_no_val
					,Cast((@OPName) as char(20))
					,''
					,Cast((@SPEC) as varchar(15))
					,Cast((@FLOOR_LIFE) as varchar(15))
					,Cast((@PPBT) as varchar(15))
					,''
					,''
					, Cast((@Required_ul_logo) as varchar(1))
					,''
					,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
					,convert(varchar(max),getdate(),121)
					,@emp_no_val
					,convert(varchar(max),getdate(),121)
					,@emp_no_val
				)
			END
		END
	END

	--insert into #tempDataByOom
	EXEC(@sql);

	print @sql

	--select * from #tempData;
	--- insert select

	BEGIN TRY 
		IF @process_name = 'TP'
		BEGIN
			IF @Conut_Row_Data > 0
			BEGIN
				UPDATE [APCSProDB].[trans].[label_issue_records] 
				SET update_at = GETDATE()
				where lot_no = @lot_no_value
				and type_of_label in(1,2,3)
			END
			ELSE
			BEGIN
				--select * from #tempData;
				INSERT INTO APCSProDB.trans.label_issue_records
				(
				   [recorded_at]
				  ,[operated_by]
				  ,[type_of_label]
				  ,[lot_no]
				  ,[customer_device]
				  ,[rohm_model_name]
				  ,[qty]
				  ,[barcode_lotno]
				  ,[tomson_box]
				  ,[tomson_3]
				  ,[box_type]
				  ,[barcode_bottom]
				  ,[mno_std]
				  ,[std_qty_before]
				  ,[mno_hasuu]
				  ,[hasuu_qty_before]
				  ,[no_reel]
				  ,[qrcode_detail]
				  ,[type_label_laterat]
				  ,[mno_std_laterat]
				  ,[mno_hasuu_laterat]
				  ,[barcode_device_detail]
				  ,[op_no]
				  ,[op_name]
				  ,[seq]
				  ,[msl_label]
				  ,[floor_life]
				  ,[ppbt]
				  ,[re_comment]
				  ,[version]
				  ,[is_logo]
				  ,[mc_name]
				  ,[seal]
				  ,[create_at]
				  ,[create_by]
				  ,[update_at]
				  ,[update_by]
				)
				select 
					 recorded_at
					,operated_by
					,type_of_label
					,lot_no
					,customer_device
					,rohm_model_name
					,qty
					,barcode_lotno
					,tomson_box
					,tomson_3
					,box_type
					,barcode_bottom
					,mno_std
					,std_qty_before
					,mno_hasuu
					,hasuu_qty_before
					,no_reel
					,qrcode_detail
					,type_label_laterat
					,mno_std_laterat
					,mno_hasuu_laterat
					,barcode_device_detail
					,op_no
					,op_name
					,seq
					,msl_label
					,floor_life
					,ppbt
					,re_comment
					,version
					,is_logo
					,mc_name
					,seal
					,create_at
					,create_by
					,update_at
					,update_by
					--from #tempData;
					from @tempData;

			END
		END
		ELSE IF @process_name = 'OGI'
		BEGIN
			--select * from #tempData;
			INSERT INTO APCSProDB.trans.label_issue_records
			(
			   [recorded_at]
			  ,[operated_by]
			  ,[type_of_label]
			  ,[lot_no]
			  ,[customer_device]
			  ,[rohm_model_name]
			  ,[qty]
			  ,[barcode_lotno]
			  ,[tomson_box]
			  ,[tomson_3]
			  ,[box_type]
			  ,[barcode_bottom]
			  ,[mno_std]
			  ,[std_qty_before]
			  ,[mno_hasuu]
			  ,[hasuu_qty_before]
			  ,[no_reel]
			  ,[qrcode_detail]
			  ,[type_label_laterat]
			  ,[mno_std_laterat]
			  ,[mno_hasuu_laterat]
			  ,[barcode_device_detail]
			  ,[op_no]
			  ,[op_name]
			  ,[seq]
			  ,[msl_label]
			  ,[floor_life]
			  ,[ppbt]
			  ,[re_comment]
			  ,[version]
			  ,[is_logo]
			  ,[mc_name]
			  ,[seal]
			  ,[create_at]
			  ,[create_by]
			  ,[update_at]
			  ,[update_by]
			)
			select 
				 recorded_at
				,operated_by
				,type_of_label
				,lot_no
				,customer_device
				,rohm_model_name
				,qty
				,barcode_lotno
				,tomson_box
				,tomson_3
				,box_type
				,barcode_bottom
				,mno_std
				,std_qty_before
				,mno_hasuu
				,hasuu_qty_before
				,no_reel
				,qrcode_detail
				,type_label_laterat
				,mno_std_laterat
				,mno_hasuu_laterat
				,barcode_device_detail
				,op_no
				,op_name
				,seq
				,msl_label
				,floor_life
				,ppbt
				,re_comment
				,version
				,is_logo
				,mc_name
				,seal
				,create_at
				,create_by
				,update_at
				,update_by
				--from #tempData;
				from @tempData;

			--insert data reprint on label his date modify : 2022/02/18 time : 13.17
			INSERT INTO APCSProDB.trans.[label_issue_records_hist] 
			(
				  label_issue_id
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
				, update_by
				)
				SELECT 
				  id
				, GETDATE()
				, 1 --fix 1
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
				where lot_no = @Lotno 
				and type_of_label in (4,5,6,21)

		END
	--Clear #tempDataByOom
	--DROP TABLE #tempData; --Close Date : 2022/01/21

	END TRY
	BEGIN CATCH 
			SELECT 'FALSE' AS Status ,'Insert Data error !!' AS Error_Message_ENG,N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
			RETURN
	END CATCH
	
END
