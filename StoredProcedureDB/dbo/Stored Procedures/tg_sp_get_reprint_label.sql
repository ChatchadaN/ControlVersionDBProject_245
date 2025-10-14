-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_reprint_label]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [dbo].[tg_sp_get_reprint_label] @lotno = ''' + @lotno + ''''
	
	DECLARE @wip_state int = 0
	DECLARE @qty_hasuu int = 0
	DECLARE @version_reel_no int = 0
	--Add Parameter
	DECLARE @aluminum nvarchar(20) = ''
	DECLARE @tube nvarchar(20) = ''
	DECLARE @tray nvarchar(20) = ''
	DECLARE @is_incoming int = null

	-- Insert statements for procedure here
	select @wip_state = wip_state from APCSProDB.trans.lots where lot_no = @lotno
	select @qty_hasuu = qty from APCSProDB.trans.label_issue_records where lot_no = @lotno and type_of_label = 2

	--Get Matrrial Store อยู่ใน Function
	SELECT @aluminum = ALUMINUM
		, @tube = TUBE
		, @tray = TRAY
		, @is_incoming = ISNULL(is_incoming,0)
	FROM [StoredProcedureDB].[atom].[fnc_tg_sp_get_Material] (@lotno) 

	--IF NOT EXISTS (
	--	SELECT [lot_master].[lot_no]
	--	FROM [APCSProDB].[trans].[lot_combine]
	--	INNER JOIN [APCSProDB].[trans].[lots] AS [lot_master] ON [lot_master].[id] = [lot_combine].[lot_id]
	--	INNER JOIN [APCSProDB].[trans].[lots] AS [lot_member] ON [lot_member].[id] = [lot_combine].[member_lot_id]
	--	WHERE [lot_master].[lot_no] = @lotno
	--) AND (
	IF (SELECT COUNT([id]) FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] =  @lotno) = 1
	BEGIN
		SELECT @version_reel_no = [version] 
		FROM [APCSProDB].[trans].[label_issue_records] 
		WHERE [lot_no] = @lotno 
			AND [type_of_label] = 2;

		IF (@wip_state != 200)
		BEGIN
			select Trim(lots.lot_no) as lot_no
				, pk.name as package
				, dn.name as device
				, dn.tp_rank
				, lb_record.customer_device
				, dn.pcs_per_pack
				--, sur.mark_no 
				, lb_record.mno_std as mark_no
				--, (lots.qty_pass + lots.qty_hasuu)/dn.pcs_per_pack As Reel
				--UPDATE GET REEL Date 2021/09/30 Time : 6.30 PM
				, (select Count(no_reel) from APCSProDB.trans.label_issue_records where lot_no = lots.lot_no and type_of_label = 3) as Reel
				, lb_record.qty as qty_total
				--, lots.qty_hasuu
				, @qty_hasuu as qty_hasuu
				, lb_record.msl_label as spec
				, lb_record.floor_life
				, lb_record.ppbt
				, @version_reel_no as reprint_version --add column date : 2021/12/08 time : 11.10
				--Add New Value --> Date Modify : 2022/07/12 Time : 14.29
				, @aluminum as aluminum
				, @tube as tube
				, @tray as tray
				, @is_incoming as is_incoming
				--Add New Value --> Date Modify : 2022/07/14 Time : 15.50
				, ISNULL(lots.production_category,0) as production_category_val
				, ISNULL(item_catgo_code.label_eng,'') as production_category_name
				, ISNULL(lots.pc_instruction_code,0) as pc_instruction_code_val
				, ISNULL(item_pc_code.label_eng,'') as pc_instruction_code_name
			from APCSProDB.trans.lots 
			inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
			inner join APCSProDB.method.device_names as dn on lots.act_device_name_id = dn.id
			left join APCSProDB.trans.surpluses as sur on lots.lot_no = sur.serial_no
			left join APCSProDB.trans.label_issue_records as lb_record on lots.lot_no = lb_record.lot_no
			left join APCSProDB.trans.item_labels as item_pc_code on lots.pc_instruction_code = CAST(item_pc_code.val as int)
				 and item_pc_code.name = 'lots.pc_instruction_code'
			left join APCSProDB.trans.item_labels as item_catgo_code on lots.production_category = CAST(item_catgo_code.val as int) 
				 and item_catgo_code.name = 'lots.production_category'	
			WHERE lots.lot_no = @lotno
				AND lb_record.type_of_label = 2;
		END
	END
	ELSE
	BEGIN
		--add query check version reel of fix reel at 1 data : 2021/12/08 time : 11.10
		select @version_reel_no = version from APCSProDB.trans.label_issue_records where lot_no = @lotno 
		and type_of_label = 3 and no_reel = 1

		IF @wip_state != 200
		BEGIN
			select Trim(lots.lot_no) as lot_no
			, pk.name as package
			, dn.name as device
			, dn.tp_rank
			, lb_record.customer_device
			, dn.pcs_per_pack
			--, sur.mark_no 
			, lb_record.mno_std as mark_no
			--, (lots.qty_pass + lots.qty_hasuu)/dn.pcs_per_pack As Reel
			--UPDATE GET REEL Date 2021/09/30 Time : 6.30 PM
			, (select Count(no_reel) from APCSProDB.trans.label_issue_records where lot_no = lots.lot_no and type_of_label = 3) as Reel
			, lb_record.qty as qty_total
			--, lots.qty_hasuu
			, @qty_hasuu as qty_hasuu
			, lb_record.msl_label as spec
			, lb_record.floor_life
			, lb_record.ppbt
			, @version_reel_no as reprint_version --add column date : 2021/12/08 time : 11.10
			--Add New Value --> Date Modify : 2022/07/12 Time : 14.29
			, @aluminum as aluminum
			, @tube as tube
			, @tray as tray
			, @is_incoming as is_incoming
			--Add New Value --> Date Modify : 2022/07/14 Time : 15.50
			, ISNULL(lots.production_category,0) as production_category_val
			, ISNULL(item_catgo_code.label_eng,'') as production_category_name
			, ISNULL(lots.pc_instruction_code,0) as pc_instruction_code_val
			, ISNULL(item_pc_code.label_eng,'') as pc_instruction_code_name
			from APCSProDB.trans.lots 
			inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
			inner join APCSProDB.method.device_names as dn on lots.act_device_name_id = dn.id
			left join APCSProDB.trans.surpluses as sur on lots.lot_no = sur.serial_no
			left join APCSProDB.trans.label_issue_records as lb_record on lots.lot_no = lb_record.lot_no
			left join APCSProDB.trans.item_labels as item_pc_code on lots.pc_instruction_code = CAST(item_pc_code.val as int)
				 and item_pc_code.name = 'lots.pc_instruction_code'
			left join APCSProDB.trans.item_labels as item_catgo_code on lots.production_category = CAST(item_catgo_code.val as int) 
				 and item_catgo_code.name = 'lots.production_category'	
			where lots.lot_no = @lotno
			and lb_record.type_of_label = 1
		END
	END

	---> ### close 2023-06-29 9.20
	--DECLARE @wip_state int = 0
	--DECLARE @qty_hasuu int = 0
	--DECLARE @version_reel_no int = 0
	----Add Parameter
	--DECLARE @aluminum nvarchar(20) = ''
	--DECLARE @tube nvarchar(20) = ''
	--DECLARE @tray nvarchar(20) = ''
	--DECLARE @is_incoming int = null

	--INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--([record_at]
 --     , [record_class]
 --     , [login_name]
 --     , [hostname]
 --     , [appname]
 --     , [command_text])
	--SELECT GETDATE()
	--	,'4'
	--	,ORIGINAL_LOGIN()
	--	,HOST_NAME()
	--	,APP_NAME()
	--	,'EXEC [dbo].[tg_sp_get_reprint_label] @lotno = ''' + @lotno + ''''

 --   -- Insert statements for procedure here
	--select @wip_state = wip_state from APCSProDB.trans.lots where lot_no = @lotno
	--select @qty_hasuu = qty from APCSProDB.trans.label_issue_records where lot_no = @lotno and type_of_label = 2
	----add query check version reel of fix reel at 1 data : 2021/12/08 time : 11.10
	--select @version_reel_no = version from APCSProDB.trans.label_issue_records where lot_no = @lotno 
	--and type_of_label = 3 and no_reel = 1

	----Get Matrrial Store อยู่ใน Function
	--SELECT @aluminum = ALUMINUM
	--,@tube = TUBE
	--,@tray = TRAY
	--,@is_incoming = ISNULL(is_incoming,0)
	--FROM [StoredProcedureDB].[atom].[fnc_tg_sp_get_Material] (@lotno) 

	--IF @wip_state != 200
	--BEGIN
	--	select Trim(lots.lot_no) as lot_no
	--	,pk.name as package
	--	,dn.name as device
	--	,dn.tp_rank
	--	,lb_record.customer_device
	--	,dn.pcs_per_pack
	--	--,sur.mark_no 
	--	,lb_record.mno_std as mark_no
	--	--,(lots.qty_pass + lots.qty_hasuu)/dn.pcs_per_pack As Reel
	--	--UPDATE GET REEL Date 2021/09/30 Time : 6.30 PM
	--	,(select Count(no_reel) from APCSProDB.trans.label_issue_records where lot_no = lots.lot_no and type_of_label = 3) as Reel
	--	,lb_record.qty as qty_total
	--	--,lots.qty_hasuu
	--	,@qty_hasuu as qty_hasuu
	--	,lb_record.msl_label as spec
	--	,lb_record.floor_life
	--	,lb_record.ppbt
	--	,@version_reel_no as reprint_version --add column date : 2021/12/08 time : 11.10
	--	--Add New Value --> Date Modify : 2022/07/12 Time : 14.29
	--	,@aluminum as aluminum
	--	,@tube as tube
	--	,@tray as tray
	--	,@is_incoming as is_incoming
	--	--Add New Value --> Date Modify : 2022/07/14 Time : 15.50
	--	,ISNULL(lots.production_category,0) as production_category_val
	--	,ISNULL(item_catgo_code.label_eng,'') as production_category_name
	--	,ISNULL(lots.pc_instruction_code,0) as pc_instruction_code_val
	--	,ISNULL(item_pc_code.label_eng,'') as pc_instruction_code_name
	--	from APCSProDB.trans.lots 
	--	inner join APCSProDB.method.packages as pk on lots.act_package_id = pk.id
	--	inner join APCSProDB.method.device_names as dn on lots.act_device_name_id = dn.id
	--	inner join APCSProDB.trans.surpluses as sur on lots.lot_no = sur.serial_no
	--	inner join APCSProDB.trans.label_issue_records as lb_record on lots.lot_no = lb_record.lot_no
	--	left join APCSProDB.trans.item_labels as item_pc_code on lots.pc_instruction_code = CAST(item_pc_code.val as int)
	--		 and item_pc_code.name = 'lots.pc_instruction_code'
	--	left join APCSProDB.trans.item_labels as item_catgo_code on lots.production_category = CAST(item_catgo_code.val as int) 
	--		 and item_catgo_code.name = 'lots.production_category'	
	--	where lots.lot_no = @lotno
	--	and lb_record.type_of_label = 1
	--END
	
END
