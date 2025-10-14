-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_label_issus_records]	
	-- Add the parameters for the stored procedure here
	@pc_instruction_code  INT,
	@updated_by  VARCHAR(10) ,
	@lot_no_value varchar(10) ,
	@reel  NVARCHAR(MAX) ,
	@Hasuu_qty  INT,
	@QTYALL  INT ,

	@i INT = 0 ,
	@reel_num INT = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	 -- SELECT DATA INSERT #TempPC_Request
		DECLARE	@Lotno NVARCHAR(10) = ' ' ;
		DECLARE @OPNo char(10)  = '';
		DECLARE @Customer_Device char(20)  = '';
		DECLARE @Device char(20)  = '';
		--DECLARE @QTY int = 0;
		DECLARE @Tomson_box   char(20)  = '';
		DECLARE @Lotno_subType char(1) = '';
		DECLARE @Tomson_Mark_3_Surpluses char(4) = ' ';
		DECLARE @Tomson_Mark_3 char(4) = ' ';
		DECLARE @Check_Record_Allocat int = 0
		DECLARE @BoxType   char(20)  = '';
		DECLARE @Mno_Standard char(20)  = '';
		DECLARE @qty_lot_standard_before int = 0;
		DECLARE @qty_hasuu_before int = 0;
		DECLARE @Mno_Hasuu char(20)  = '';
		DECLARE @Lotno_hasuu char(10)  = '';
		DECLARE @Lot_id int = 0;
		DECLARE @PC_Code_Value int = 0
		DECLARE @qty_shipment int = 0;
		DECLARE @OPName  char(20)  = '';
		DECLARE @op_no_len_value varchar(10);
		DECLARE @op_no_len varchar(10);
		DECLARE @SPEC  char(20)  = '';
		DECLARE @FLOOR_LIFE   char(20)  = '';
		DECLARE @PPBT   char(20)  = '';
		DECLARE @Shortname char(20)  = '';
		DECLARE @Required_ul_logo int = 0;
		DECLARE @AssyName char(20)  = '';
		--DECLARE @Hasuu_qty int = 0;
		DECLARE @is_std_tube_adjust int = 0
		DECLARE @pcs_per_pack_control int = 0
		DECLARE @Package char(20)  = '';
		DECLARE @Rank char(20)  = '';
		DECLARE @TPRank char(20)  = '';
		DECLARE @Standard int = 0;
		DECLARE @Total int = 0;
		DECLARE @Status_lot char(20) = '';
		DECLARE @convert_mno_value int = 0;
		DECLARE @get_time_value_msl char(5) = '';
		DECLARE @Conut_Row_Data int = 0;
		DECLARE @QTY int = 0;
		DECLARE @reel_num_shipment INT = 0;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY

		-- select data insert @TempPC_REquest --
		select @pcs_per_pack_control = (case when @is_std_tube_adjust = 0 then device_names.pcs_per_pack else @is_std_tube_adjust end)
		from APCSProDB.trans.lots 
		inner join APCSProDB.method.device_names on lots.act_device_name_id = device_names.id
		where lot_no = @lot_no_value
			--Add Condition Check Record on Allocat Table 
		select @Check_Record_Allocat = COUNT(*) from APCSProDB.method.allocat where LotNo = @lot_no_value

		SELECT @Lotno_subType = SUBSTRING(@lot_no_value,5,1)

			--Add Tomson3 or qcInstruction is type D lot
		SELECT @Tomson_Mark_3_Surpluses = case when qc_instruction is null then '' else qc_instruction end from APCSProDB.trans.surpluses where serial_no = @Lotno

			--Add Condition Check Record on Allocat Table Create Date : 2022/11/21 Time : 15.55
		IF @Check_Record_Allocat = 0
		BEGIN
				SELECT @Tomson_Mark_3 = Tomson3 from [APCSProDB].[method].[allocat_temp] where LotNo = @Lotno
			END
		ELSE
			BEGIN
				SELECT @Tomson_Mark_3 = Tomson3 from [APCSProDB].[method].[allocat] where LotNo = @Lotno
		END	

			--lot id
		select @Lot_id = id
		,@PC_Code_Value = case when pc_instruction_code is null then 0 else pc_instruction_code end
		from APCSProDB.trans.lots where lot_no = @lot_no_value

			--lot hasuu
		SELECT @Lotno_hasuu = lots.lot_no from APCSProDB.trans.lot_combine as lot_com
		inner join APCSProDB.trans.lots as lots on lot_com.member_lot_id = lots.id
		where lot_id = @Lot_id

			--chang table form denpyo is allocat_temp
		SELECT @Mno_Standard = MNo from [APCSProDB].[method].[allocat_temp] where LotNo = @lot_no_value
		SELECT @Mno_Hasuu = MNo from [APCSProDB].[method].[allocat_temp] where LotNo = @Lotno_hasuu
			
			--Add qty_lot_standard_before
		SELECT @qty_lot_standard_before = (qty_out - qty_combined) 
		,@qty_hasuu_before = qty_combined
		from APCSProDB.trans.lots where lot_no = @lot_no_value	

		select @Status_lot = case when  lot_id = member_lot_id then 'FRISTLOT' else 'CONTUNUELOT' end
		from APCSProDB.trans.lot_combine where lot_id = @Lot_id

		SELECT @Conut_Row_Data = count(lot_no) FROM [APCSProDB].[trans].[label_issue_records] 
		WHERE lot_no = @lot_no_value and type_of_label in(1,2,3)

			--check logo UL
		SELECT @Required_ul_logo = required_ul_logo FROM [APCSProDB].[method].[device_names] where name = @Device and assy_name = @AssyName
			
			--select data insert @TempPC_REquest
		select @Check_Record_Allocat = COUNT(*) from APCSProDB.method.allocat where LotNo = @lot_no_value
		IF @Check_Record_Allocat = 0
		BEGIN
		select top(1) @Lotno = lot.lot_no
		, @QTY = case when SUBSTRING(lot.lot_no,5,1) = 'D' then lot.qty_pass else qty_out + qty_hasuu end
		, @qty_shipment = lot.qty_out
		, @reel_num = case when [surpluses].[original_lot_id] is not null or [surpluses].[original_lot_id] != 0 then 0 
							else (qty_out + qty_hasuu)/@pcs_per_pack_control end
		, @reel_num_shipment = (lot.qty_out/@pcs_per_pack_control)
		--, @Hasuu_qty = case when [surpluses].[original_lot_id] is not null or [surpluses].[original_lot_id] != 0 then lot.qty_pass 
		--					else (qty_out + qty_hasuu)%(@pcs_per_pack_control) end
		, @Package = [pk].[name]
		, @Shortname = [pk].[short_name]
		, @Device = [dv].[name]
		, @AssyName = [dv].[assy_name]
		, @Customer_Device = (case 
			when (multi_label.USER_Model_Name is null or multi_label.USER_Model_Name = '') then dv.name 
			else 
				case 
					when (multi_label.USER_Model_Name is not null or multi_label.USER_Model_Name != '') 
						and (multi_label.delete_flag = 1) then dv.name 
					else multi_label.USER_Model_Name 
				end
		end)
		, @Rank = case when dv.rank is null then '' else dv.rank end
		, @TPRank = case when dv.tp_rank is null then '' else dv.tp_rank end
		, @Standard = @pcs_per_pack_control
		, @Total = ([qty_out] + [qty_hasuu]) - ([qty_out] + [qty_hasuu])%(@pcs_per_pack_control) 
		, @Tomson_box = [tomson].[tomson_box]
		, @BoxType = [tomson].[tomson_box]
		, @OPNo = [lot_cb].[updated_by]
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
		END
		ELSE
		BEGIN
			select top(1) @Lotno = lot.lot_no
			, @QTY = case when SUBSTRING(lot.lot_no,5,1) = 'D' then lot.qty_pass else qty_out + qty_hasuu end
			, @qty_shipment = lot.qty_out
			--, @Hasuu_qty = case when [surpluses].[original_lot_id] is not null or [surpluses].[original_lot_id] != 0 then lot.qty_pass 
			--					else (qty_out + qty_hasuu)%(@pcs_per_pack_control) end
			, @Package = [pk].[name]
			, @Shortname = [pk].[short_name]
			, @Device = [dv].[name]
			, @AssyName = [dv].[assy_name]
			, @Customer_Device = (case 
				when (multi_label.USER_Model_Name is null or multi_label.USER_Model_Name = '') then dv.name 
				else 
					case 
						when (multi_label.USER_Model_Name is not null or multi_label.USER_Model_Name != '') 
							and (multi_label.delete_flag = 1) then dv.name 
						else multi_label.USER_Model_Name 
					end
			end)
			, @Rank = case when dv.rank is null then '' else dv.rank end
			, @TPRank = case when dv.tp_rank is null then '' else dv.tp_rank end
			, @Standard = @pcs_per_pack_control
			, @Total = ([qty_out] + [qty_hasuu]) - ([qty_out] + [qty_hasuu])%(@pcs_per_pack_control) 
			, @Tomson_box = [tomson].[tomson_box]
			, @BoxType = [tomson].[tomson_box]
			, @OPNo = [lot_cb].[updated_by]
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
		END
			--add check condition empno in process value 
		SELECT @op_no_len = @OPNo 

		SELECT  @op_no_len_value =  case when LEN(CAST(@op_no_len as varchar(10))) = 5 then '0' + CAST(@op_no_len as varchar(10))
				when LEN(CAST(@op_no_len as varchar(10))) = 4 then '00' + CAST(@op_no_len as varchar(10))
				when LEN(CAST(@op_no_len as varchar(10))) = 3 then '000' + CAST(@op_no_len as varchar(10))
				when LEN(CAST(@op_no_len as varchar(10))) = 2 then '0000' + CAST(@op_no_len as varchar(10))
				else CAST(@op_no_len as varchar(10)) end 

		SELECT @OPName =
		CASE
			WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MR.' THEN LEFT(SUBSTRING([users].name, 5,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
			WHEN SUBSTRING(CAST(name as char(20)),1,4) ='MISS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
			WHEN SUBSTRING(CAST(name as char(20)),1,3) ='MRS' THEN LEFT(SUBSTRING([users].name, 6,LEN([users].name)),LEN(SUBSTRING([users].name, 5,LEN([users].name)) ) - 3 )
		ELSE SUBSTRING(CAST(name as char(20)), 1,LEN([users].name)) END 
		FROM [APCSProDB].[man].[users]
		WHERE [users].[emp_num] = @op_no_len_value

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

	--Add Log Date
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
		,'EXEC [atom].[sp_set_label_issus_records] @Lotno = ''' + @Lotno + ''',  @pc_instruction_code = ''' + @pc_instruction_code + ''', @updated_by = ''' + @updated_by + ''', @QTYALL = ''' + @QTYALL + ''',@reel = '''+@reel+''', @Hasuu_qty = '''+ @Hasuu_qty +'''' 
		,@Lotno

	    -- CREATE #TempPC_Request
		--CREATE TABLE #TempPC_Request (
		DECLARE @TempPC_Request TABLE(
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
			,[ip_address][varchar](60) NULL
			,[msl_label]  [varchar](15) NULL
			,[floor_life] [varchar](15) NULL
			,[ppbt] [varchar](15) NULL
			,[re_comment] [varchar](60) NOT NULL
			,[version] [int] NULL
			,[is_logo] [int] NULL
			,[mc_name] [char](15) NULL
			,[barcode_1_mod][varchar](20) NULL
			,[barcode_2_mod][varchar](20) NULL
			,[seal] [varchar](10) NOT NULL
			,[create_at] [datetime] NULL
			,[create_by] [int] NULL
			,[update_at] [datetime] NULL
			,[update_by] [int] NULL
		);

	SET  @reel_num = (SELECT COUNT(*)  FROM STRING_SPLIT(@reel,',') )

	SET  @i = 1;
		--#1
		BEGIN
			INSERT INTO @TempPC_Request
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
				,ip_address
				,msl_label
				,floor_life
				,ppbt
				,re_comment
				,version
				,is_logo
				,mc_name
				,barcode_1_mod
				,barcode_2_mod
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
				,Cast((@QTYALL) as char(20))
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
				,Cast((@QTYALL) as char(20))
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
						when LEN(CAST(@QTYALL as varchar(6))) = 5 then '0' + CAST(@QTYALL as varchar(6))  + CAST(@Lotno as varchar(10)) + 
							case 
								when ((@reel_num + 2) > 9) then '0' + Cast((@reel_num + 2) as char(3)) 
								else '00' + Cast((@reel_num + 2) as char(3)) 
							end
						when LEN(CAST(@QTYALL as varchar(6))) = 4  then '00' + CAST(@QTYALL as varchar(6))  + CAST(@Lotno as varchar(10)) + 
							case 
								when ((@reel_num + 2) > 9) then '0' + Cast((@reel_num + 2) as char(3))
								else '00' + Cast((@reel_num + 2) as char(3)) 
							end
						when LEN(CAST(@QTYALL as varchar(6))) = 3 then '000' + CAST(@QTYALL as varchar(6))  + CAST(@Lotno as varchar(10)) + 
							case 
								when ((@reel_num + 2) > 9) then '0' + Cast((@reel_num + 2) as char(3)) 
								else '00' + Cast((@reel_num + 2) as char(3)) 
							end
						when LEN(CAST(@QTYALL as varchar(6))) = 2 then '0000' + CAST(@QTYALL as varchar(6))  + CAST(@Lotno as varchar(10)) + 
							case 
								when ((@reel_num + 2) > 9) then '0' + Cast((@reel_num + 2) as char(3)) 
								else '00' + Cast((@reel_num + 2) as char(3)) 
							end
						when LEN(CAST(@QTYALL as varchar(6))) = 1 then '00000' + CAST(@QTYALL as varchar(6))  + CAST(@Lotno as varchar(10)) + 
							case 
								when ((@reel_num + 2) > 9) then '0' + Cast((@reel_num + 2) as char(3)) 
								else '00' + Cast((@reel_num + 2) as char(3)) 
							end
						else CAST(@QTYALL as varchar(6)) + CAST(@Lotno as varchar(10)) + 
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
				,''
				,Cast((@SPEC) as varchar(15))
				,Cast((@FLOOR_LIFE) as varchar(15))
				,Cast((@PPBT) as varchar(15))
				,''
				,''
				,Cast((@Required_ul_logo) as varchar(1))
				,''
				,''
				,''
				,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
				,convert(varchar(max),getdate(),121)
				, @OPNo
				,convert(varchar(max),getdate(),121)
				,@OPNo
			)
		END
		--#2
		BEGIN	
			INSERT INTO @TempPC_Request 
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
				,ip_address
				,msl_label
				,floor_life
				,ppbt
				,re_comment
				,version
				,is_logo
				,mc_name
				,barcode_1_mod
				,barcode_2_mod
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
				,''
				,Cast((@SPEC) as varchar(15))
				,Cast((@FLOOR_LIFE) as varchar(15))
				,Cast((@PPBT) as varchar(15))
				,''
				,''
				, Cast((@Required_ul_logo) as varchar(1))
				,''
				,''
				,''
				,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
				,convert(varchar(max),getdate(),121)
				,@OPNo
				,convert(varchar(max),getdate(),121)
				,@OPNo
			)
		END

		WHILE(@i <= @reel_num)		
		--#3	
		BEGIN
			INSERT INTO @TempPC_Request  
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
				,ip_address
				,msl_label
				,floor_life
				,ppbt
				,re_comment
				,version
				,is_logo
				,mc_name
				,barcode_1_mod
				,barcode_2_mod
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
				,3
				,Cast((@Lotno) as char(10))
				,Cast((@Customer_Device) as char(20))
				,Cast((@Device) as char(20))
				--,Cast((@Standard) as char(20))
				,(SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i)
				,Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
				,''
				,case 
					when @Lotno_subType = 'D' then Cast((@Tomson_Mark_3_Surpluses) as char(4)) 
					else Cast((@Tomson_Mark_3) as char(4)) 
				end
				,''
				,case 
					when LEN(CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6))) = 5 then '0' + CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
					when LEN(CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6))) = 4 then '00' + CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
					when LEN(CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6))) = 3 then '000' + CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
					when LEN(CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6))) = 2 then '0000' + CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(11))
					else CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6)) + ' ' + Cast(SUBSTRING(@Lotno, 1, 4) + ' ' + SUBSTRING(@Lotno, 5, 6) as char(10)) 
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
									when @i <= @convert_mno_value then Cast((@Mno_Hasuu) as char(20)) 
									else ' ' 
								end 
						end
				end	
				,''
				--,Cast((@i-2) as char(3))
				,Cast((@i) as char(3))
				,Cast(@Device as varchar(20)) + 
					case 
						when LEN(CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6))) = 5 then '0' + CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6))  + CAST(@Lotno as varchar(10)) + 
							case 
								when (@i > 9) then '0' + Cast((@i) as char(3)) 
								else '00' + Cast((@i) as char(3)) 
							end 
						when LEN(CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6))) = 4 then '00' + CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6))  + CAST(@Lotno as varchar(10)) + 
							case 
								when (@i > 9) then '0' + Cast((@i) as char(3)) 
								else '00' + Cast((@i) as char(3)) 
							end
						when LEN(CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6))) = 3 then '000' + CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6))  + CAST(@Lotno as varchar(10)) + 
							case 
								when (@i > 9) then '0' + Cast((@i) as char(3)) 
								else '00' + Cast((@i) as char(3)) 
							end
						when LEN(CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6))) = 2 then '0000' + CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6))  + CAST(@Lotno as varchar(10)) + 
							case 
								when (@i > 9) then '0' + Cast((@i) as char(3)) 
								else '00' + Cast((@i) as char(3)) 
							end
						else CAST((SELECT value FROM (SELECT ROW_NUMBER() OVER ( ORDER BY  (SELECT 0)) row_num,  *  FROM STRING_SPLIT(@reel,',')) AS TB1
					WHERE row_num = @i) as varchar(6)) + CAST(@Lotno as varchar(10)) + 
							case 
								when (@i > 9) then '0' + Cast((@i) as char(3)) 
								else '00' + Cast((@i) as char(3)) 
							end
					end
				,''
				,''
				,''
				,Cast((@Device) as char(20))
				,@OPNo
				,Cast((@OPName) as char(20))
				,''
				,''
				,Cast((@SPEC) as varchar(15))
				,Cast((@FLOOR_LIFE) as varchar(15))
				,Cast((@PPBT) as varchar(15))
				,''
				,''
				,Cast((@Required_ul_logo) as varchar(1))
				,''
				,''
				,''
				,Cast((SELECT FORMAT(GETDATE(), 'ddMMMyy')) as varchar(10)) --SEAL
				,convert(varchar(max),getdate(),121)
				,@OPNo
				,convert(varchar(max),getdate(),121)
				,@OPNo
			)
			SET @i = @i + 1;
		END
		PRINT 'Done FOR LOOP';

		--SELECT * FROM @TempPC_Request 
		--DROP TABLE @TempPC_Request
	
		-- INSERT label_issue_records and  history		

		IF  @Conut_Row_Data > 0
		BEGIN
			UPDATE [APCSProDB].[trans].[label_issue_records] 
			SET update_at = GETDATE()
			where lot_no = @lot_no_value
			and type_of_label in(1,2,3)
		END
		ELSE
		BEGIN
			--select * from #TempPC_Request;
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
			  ,[ip_address]
			  ,[msl_label]
			  ,[floor_life]
			  ,[ppbt]
			  ,[re_comment]
			  ,[version]
			  ,[is_logo]
			  ,[mc_name]
			  ,[barcode_1_mod]
			  ,[barcode_2_mod]
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
				,ip_address
				,msl_label
				,floor_life
				,ppbt
				,re_comment
				,version
				,is_logo
				,mc_name
				,barcode_1_mod
				,barcode_2_mod
				,seal
				,create_at
				,create_by
				,update_at
				,update_by
				--from #TempPC_Request;
				FROM @TempPC_Request;
		END	
		

		BEGIN
			--insert data reprint on label his
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
				and type_of_label in(1,2,3)
		END

		COMMIT; 

		SELECT 'TRUE' AS Is_Pass, 'Successed !!' AS Error_Message_ENG, N'บันทึกข้อมูลเรียบร้อย.' AS Error_Message_THA,'' AS Handling	
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass, 'Update Faild !!' AS Error_Message_ENG, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA,'' AS Handling
	END CATCH
END
