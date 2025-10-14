-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_scheck_program_by_bass]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(100)
	, @menu int = 1 ---1.History Lot 2.Log Exec 3.Label 4.Special Flow 5.Cac Monitor 6.allocat 7.Log ESL Card  8.Log store 9.Log store jig
	, @datatype int = 0 --menu(1) ---0.trans.lots 1.trans.lot_process_records
	, @db_location int = 1 ---1.APCSProDB 2.DBLSISHT
	, @table_name varchar(50) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	---1.test
	if (@menu = 1) ---1.History Lot
	begin
		------Query History Lot
		if (@datatype = 0)
		begin
			------------------------------( trans.lots )------------------------------
			select [lots].[lot_no]
				, [item_wip].[label_eng] + ' (' + cast([lots].[wip_state] as varchar) + ')' as [wip_state]
				, [item_quality].[label_eng] + ' (' + cast([lots].[quality_state] as varchar) + ')' as [quality_state]
				, case 
					when [lots].[is_special_flow] = 1 then [item_process_sf].[label_eng] + ' (' + cast([special_flows].[process_state] as varchar) + ')'
					else [item_process].[label_eng] + ' (' + cast([lots].[process_state] as varchar) + ')'
				end as [process_state]
				, [device_slips].[device_slip_id]
				, [device_versions].[version_num] as [device_slip_ver]
				, [device_slips].[is_released]
				, [device_names].[name] as [device]
				, [device_names].[assy_name] as [device_assy_name]
				, [device_names].[ft_name] as [ft_device]
				, [packages].[name] as [package]
				, [msl].[Spec] as [MSL_Spec]
				, [msl].[Floor_Life] as [MSL_Floor_Life]
				, [msl].[PPBT] as [MSL_PPBT]
				, case when [lots].[is_special_flow] = 1 then [lot_special_flows].[step_no] ELSE [lots].[step_no] end as [step_no]
				, case when [lots].[is_special_flow] = 1 then [job2].[name] ELSE [jobs].[name] end as [job_name]
				, case when [lots].[is_special_flow] = 1 then [processes2].[name] ELSE [processes].[name] end as [process_name]
				, case 
					when [lots].[is_special_flow] = 1 then 'special_flow now' + ' (' + cast([lots].[is_special_flow] as varchar) + ')' + ', id' + ' (' + cast([lots].[special_flow_id] as varchar) + ')'
					else 
						case 
							when [lots].[special_flow_id] is null then 'not special_flow'
							when [lots].[special_flow_id] = 0 then 'not special_flow'
							else 'special_flow after' + ' (' + cast([lots].[is_special_flow] as varchar) + ')' + ', id' + ' (' + cast([lots].[special_flow_id] as varchar) + ')'
						end
				end as [special_flow]
				, [lots].[production_category]
				, [device_names].[pcs_per_pack]
				, [lots].[qty_pass]
				, [lots].[qty_fail]
				, [lots].[qty_out]
				, [lots].[qty_hasuu]
				, [users].[english_name] + ' (' + cast([users].[emp_num] as varchar) + ')' + ', id' + ' (' + cast([users].[id] as varchar) + ')' as [user_update]
				, 'http://atom/user/details/' + cast(lots.id as varchar) as [link_atom]
			from [APCSProDB].[trans].[lots]
			inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
			inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
			inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
			inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]
			left join [APCSProDB].[method].[mslevel_data] as [msl] on [packages].[name] = [msl].[Product_Name]
			inner join [APCSProDB].[method].[package_groups] on [package_groups].[id] = [packages].[package_group_id]
			inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [lots].[device_slip_id] 
				and [device_flows].[step_no] = [lots].[step_no]
			inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [device_flows].[job_id]
			inner join [APCSProDB].[method].[processes] on [processes].[id] = [jobs].[process_id]
			----------------------------( special_flow )----------------------------
			left join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lots].[special_flow_id] 
			left join [APCSProDB].[trans].[lot_special_flows] on [lot_special_flows].[special_flow_id] = [special_flows].[id] 
				and  [special_flows].[step_no] = [lot_special_flows].[step_no]
			left join [APCSProDB].[method].[jobs] as [job2] on [job2].[id] = [lot_special_flows].[job_id]
			left join [APCSProDB].[method].[processes] as [processes2] on [processes2].[id] = [job2].[process_id]
			----------------------------( special_flow )----------------------------
			left join [APCSProDB].[trans].[item_labels] as [item_wip] on [item_wip].[name] = 'lots.wip_state'
				and [item_wip].[val] = [lots].[wip_state]
			left join [APCSProDB].[trans].[item_labels] as [item_quality] on [item_quality].[name] = 'lots.quality_state'
				and [item_quality].[val] = [lots].[quality_state]
			left join [APCSProDB].[trans].[item_labels] as [item_process] on [item_process].[name] = 'lots.process_state'
				and [item_process].[val] = [lots].[process_state]
			----------------------------( special_flow )----------------------------
			left join [APCSProDB].[trans].[item_labels] as [item_process_sf] on [item_process_sf].[name] = 'lots.process_state'
				and [item_process_sf].[val] = [special_flows].[process_state]
			----------------------------( special_flow )----------------------------
			left join [APCSProDB].[man].[users] on [users].[id] = [lots].[updated_by]
			where [lots].[lot_no] = @lot_no
			------------------------------( trans.lots )------------------------------
		end
		else begin
			------------------------------( trans.lot_process_records )------------------------------
			select format(recorded_at, 'yyyy-MM-dd HH:mm:ss') as [recorded_at]
				, [item_record].[label_eng] + ' (' + cast([lot_process_records].[record_class] as varchar) + ')' as [record_class]
				, [machines].[name] + ' (' + cast([lot_process_records].[machine_id] as varchar) + ')' as [mc_name]
				, ISNULL(lot_process_records.carrier_no,'-') AS carrier_no
				, [item_wip].[label_eng] + ' (' + cast([lot_process_records].[wip_state] as varchar) + ')' as [wip_state]
				, [item_quality].[label_eng] + ' (' + cast([lot_process_records].[quality_state] as varchar) + ')' as [quality_state]
				, [item_process].[label_eng] + ' (' + cast([lot_process_records].[process_state] as varchar) + ')' as [process_state]
				, step_no
				, [jobs].[name] + ' (' + cast([jobs].[id] as varchar) + ')' as [job_name]
				, [processes].[name] + ' (' + cast([processes].[id] as varchar) + ')' as [process_name]
				--, iif([lot_process_records].[special_flow_id] is null
				--	, 'not special_flow'
				--	, cast([lot_process_records].[special_flow_id] as varchar) + iif([lot_process_records].[is_special_flow] = 1,' (now)',' (after)') 
				--) as special_flow_status
				, lot_process_records.qty_in
				, lot_process_records.qty_pass
				, lot_process_records.qty_fail
				, lot_process_records.qty_last_pass
				, lot_process_records.qty_last_fail
				, lot_process_records.qty_pass_step_sum
				, lot_process_records.qty_fail_step_sum
				, lot_process_records.qty_p_nashi
				, lot_process_records.qty_front_ng
				, lot_process_records.qty_marker
				, lot_process_records.qty_combined
				, lot_process_records.qty_hasuu
				, lot_process_records.qty_out
				, lot_process_records.qty_frame_in
				, lot_process_records.qty_frame_pass
				, lot_process_records.qty_frame_fail
				, [users].[english_name] + ' (' + cast([users].[emp_num] as varchar) + ')' + ', id' + ' (' + cast([users].[id] as varchar) + ')' as [operated_by]
			from [APCSProDB].[trans].[lot_process_records]
			inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [lot_process_records].[job_id]
			inner join [APCSProDB].[method].[processes] on [processes].[id] = [jobs].[process_id]
			left join [APCSProDB].[mc].[machines] on [lot_process_records].[machine_id] = [machines].[id]
			left join [APCSProDB].[man].[users] on [lot_process_records].[updated_by] = [users].[id]
			left join [APCSProDB].[trans].[item_labels] as [item_record] on [item_record].[name] = 'lot_process_records.record_class'
				and [item_record].[val] = [lot_process_records].[record_class]
			left join [APCSProDB].[trans].[item_labels] as [item_process] on [item_process].[name] = 'lots.process_state'
				and [item_process].[val] = [lot_process_records].[process_state]
			left join [APCSProDB].[trans].[item_labels] as [item_quality] on [item_quality].[name] = 'lots.quality_state'
				and [item_quality].[val] = [lot_process_records].[quality_state]
			left join [APCSProDB].[trans].[item_labels] as [item_wip] on [item_wip].[name] = 'lots.wip_state'
				and [item_wip].[val] = [lot_process_records].[wip_state]
			where lot_id = (select id from [APCSProDB].[trans].[lots] where [lots].[lot_no] = @lot_no)
			order by [lot_process_records].[id]
			------------------------------( trans.lot_process_records )------------------------------
		end
		------Query History Lot
	end
	else if (@menu = 2) ---2.Log Exec
	begin
		------Query Log Exec Stored
		select [history_id]
			, format([record_at], 'yyyy-MM-dd HH:mm:ss') AS [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [lot_no]
			, [command_text]
		from [StoredProcedureDB].[dbo].[exec_sp_history]
		where [lot_no] = @lot_no
		order by [record_at]
		------Query Log Exec Stored
	end
	else if (@menu = 3) ---3.Label
	begin
		------Query Label Location
		if (@db_location = 1) ---APCSProDB
		begin
			declare @lot_id int = (select id from APCSProDB.trans.lots where lot_no = @lot_no)

			if (@table_name = 'trans.lots')  ---trans.lots
			begin
				--select [lots].[id]
				--	, [lot_no]
				--	, [device_names].[pcs_per_pack]
				--	, [qty_pass]
				--	, [qty_combined]
				--	, [qty_out]
				--	, [qty_hasuu]
				--	, [wip_state]
				--	, [pc_instruction_code]
				--	, [production_category]
				--from [APCSProDB].[trans].[lots]
				--inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
				--inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
				--inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
				--where lot_no = @lot_no

				select [lots].[id]
					, [lots].[lot_no]
					, [device_names].[pcs_per_pack]
					, [qty_pass]
					, [qty_combined]
					, [qty_out]
					, [qty_hasuu]
					, [wip_state]
					, [pc_instruction_code]
					, [production_category]
					, [material_set_id]
					, [ALUMINUM]
					, [INDICATOR]
					, [TOMSON]
					, [SILIGA GEL]
					, [AIR BUBBLE]
					, [SPACER]
					, [TUBE]
					, [TRAY]
					, [mat_use].[is_incoming]
				from [APCSProDB].[trans].[lots]
				inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [lots].[device_slip_id]
				inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
				inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
				left join (
					select [lots].[lot_no]
						, [device_flows].[material_set_id]
						, isnull('[USE]' + space(1) + [ALUMINUM], 'NO USE') as [ALUMINUM]
						, isnull('[USE]' + space(1) + [INDICATOR], 'NO USE') as [INDICATOR]
						, isnull('[USE]' + space(1) + [TOMSON], 'NO USE') as [TOMSON]
						, isnull('[USE]' + space(1) + [SILIGA GEL], 'NO USE') as [SILIGA GEL]
						, isnull('[USE]' + space(1) + [AIR BUBBLE], 'NO USE') as [AIR BUBBLE]
						, isnull('[USE]' + space(1) + [SPACER], 'NO USE') as [SPACER]
						, isnull('[USE]' + space(1) + [TUBE], 'NO USE') as [TUBE]
						, isnull('[USE]' + space(1) + [TRAY], 'NO USE') as [TRAY]
						, isnull([device_names].[is_incoming], 0) as [is_incoming]
					from [APCSProDB].[trans].[lots] 
					inner join [APCSProDB].[method].[device_slips] on [lots].[device_slip_id] = [device_slips].[device_slip_id]
					inner join [APCSProDB].[method].[device_versions] on [device_slips].[device_id] = [device_versions].[device_id]
						and [device_slips].[is_released] = 1 
					inner join [APCSProDB].[method].[device_names] on [device_versions].[device_name_id] = [device_names].[id] 
					inner join [APCSProDB].[method].[packages] on [device_names].[package_id] = [packages].[id] 
					inner join [APCSProDB].[method].[device_flows] on [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
						and [device_flows].[job_id] = 317 
					outer apply (
						select [pvt].*
						from (
							select [details]
								, ( [p].[name] 
									+ space(1)
									+ ':' 
									+ space(1)
									+ cast(cast([use_qty] as int) as varchar(20)) 
									+ space(1)
									+ [il].[label_eng] ) 
								as [mat_name]
							from [APCSProDB].[method].[material_sets] AS [ms] 
							inner join [APCSProDB].[method].[material_set_list] AS [ml] ON [ms].[id] = [ml].[id] 
							inner join [APCSProDB].[material].[productions] AS [p] ON [ml].[material_group_id] = [p].[id] 
							left join [APCSProDB].[method].[item_labels] AS [il] ON [il].[val] = [ml].[use_qty_unit]
								and [il].[name] = 'material_set_list.use_qty_unit'
							where ( [ms].[process_id] = 317 or [ms].[process_id] = 18 ) 
								and [ms].[id] = [device_flows].[material_set_id]
						) as [mat_data]	
						pivot ( 
							max( [mat_name] )
							for [details]
							in (
								[TOMSON]
								, [AIR BUBBLE]
								, [ALUMINUM]
								, [INDICATOR]
								, [SILIGA GEL]
								, [SPACER]
								, [TUBE]
								, [TRAY]
							)
						) as [pvt]
					) as [mat_use]
					where [lot_no] = @lot_no
				) as [mat_use] ON [lots].[lot_no] = [mat_use].[lot_no]
				where [lots].[lot_no] = @lot_no;
			end
			else if (@table_name = 'trans.lot_combine')  ---trans.lot_combine
			begin
				select lot_master.lot_no
					, lot_combine.idx
					, lot_member.lot_no as member_lot_no
					, lot_combine.created_at
					, lot_combine.created_by
					, lot_combine.updated_at
					, lot_combine.updated_by
				from APCSProDB.trans.lots as lot_master
				inner join APCSProDB.trans.lot_combine on lot_master.id = lot_combine.lot_id
				inner join APCSProDB.trans.lots as lot_member on lot_combine.member_lot_id = lot_member.id
				where lot_master.lot_no = @lot_no
			end
			else if (@table_name = 'trans.lot_combine_records')   ---trans.lot_combine_records
			begin
				select *
				from [APCSProDB].[trans].[lot_combine_records] 
				where lot_id = @lot_id
			end
			else if (@table_name = 'trans.surpluses')   ---trans.surpluses
			begin
				select *
				from [APCSProDB].[trans].[surpluses] 
				where serial_no = @lot_no
			end

			else if (@table_name = 'trans.surpluse_records')   ---trans.surpluse_records
			begin
				select *
				from [APCSProDB].[trans].[surpluse_records] 
				where lot_id = @lot_id
			end
			else if (@table_name = 'trans.label_issue_records')   ---trans.label_issue_records
			begin
				select [lot_no]
					, [item_labels].[label_eng] as [type_of_label]
					, [no_reel]
					, [version]
					, [qrcode_detail]
					, [qty]
					, [mno_std]
					, [mno_hasuu]
					, [tomson_3]
					, [op_no]
					, [op_name]
					, [create_at]
					, [update_at]
					, [create_by]
					, [update_by]
				from [APCSProDB].[trans].[label_issue_records]
				left join [APCSProDB].[trans].[item_labels] on [item_labels].[name] = 'label_issue_records.type_of_label'
					and [label_issue_records].[type_of_label] = [item_labels].[val]
				where lot_no = @lot_no
				order by [type_of_label]
			end
			else if (@table_name = 'trans.label_issue_records_hist')   ---trans.label_issue_records_hist
			begin
				select *
				from [APCSProDB].[trans].[label_issue_records_hist] 
				where lot_no = @lot_no
			end
		end
		else begin ---DBLSISHT
			declare @sql NVARCHAR(MAX)

			if (@table_name = 'MIX_HIST')   ---MIX_HIST
			begin
				SET @sql = 'SELECT * FROM OPENROWSET(''SQLNCLI'', ''Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship'',' + 
					'''SELECT * FROM [DBLSISHT].[dbo].[MIX_HIST] '+ 
					'WHERE [HASUU_LotNo] = ''''' + @lot_no + ''''''')';
				exec sp_executesql @sql;
			end
			else if (@table_name = 'LSI_SHIP')   ---LSI_SHIP
			begin
				SET @sql = 'SELECT * FROM OPENROWSET(''SQLNCLI'', ''Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship'',' + 
					'''SELECT * FROM [DBLSISHT].[dbo].[LSI_SHIP] '+ 
					'WHERE [LotNo] = ''''' + @lot_no + ''''''')';
				exec sp_executesql @sql;
			end
			else if (@table_name = 'H_STOCK')   ---H_STOCK
			begin
				SET @sql = 'SELECT * FROM OPENROWSET(''SQLNCLI'', ''Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship'',' + 
					'''SELECT * FROM [DBLSISHT].[dbo].[H_STOCK] '+ 
					'WHERE [LotNo] = ''''' + @lot_no + ''''''')';
				exec sp_executesql @sql;
			end
			else if (@table_name = 'PACKWORK')   ---PACKWORK
			begin
				SET @sql = 'SELECT * FROM OPENROWSET(''SQLNCLI'', ''Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship'',' + 
					'''SELECT * FROM [DBLSISHT].[dbo].[PACKWORK] '+ 
					'WHERE [LotNo] = ''''' + @lot_no + ''''''')';
				exec sp_executesql @sql;
			end
			else if (@table_name = 'WH_UKEBA')   ---WH_UKEBA
			begin
				SET @sql = 'SELECT * FROM OPENROWSET(''SQLNCLI'', ''Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship'',' + 
					'''SELECT * FROM [DBLSISHT].[dbo].[WH_UKEBA] '+ 
					'WHERE [LotNo] = ''''' + @lot_no + ''''''')';
				exec sp_executesql @sql;
			end
			else if (@table_name = 'WORK_R_DB')   ---WORK_R_DB
			begin
				SET @sql = 'SELECT * FROM OPENROWSET(''SQLNCLI'', ''Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship'',' + 
					'''SELECT * FROM [DBLSISHT].[dbo].[WORK_R_DB] '+ 
					'WHERE [LotNo] = ''''' + @lot_no + ''''''')';
				exec sp_executesql @sql;
			end
		end
		------Query Label Location
	end
	else if (@menu = 4) ---4.Special Flow   
	begin
		------Query Special Flow 
		select special_flows.id as [special_flow_id]
			, lot_special_flows.id as [lot_special_flow_id]
			, jobs.name as [job_name]
 			, lot_special_flows.step_no
			, iif(lot_special_flows.id = last_row.lot_special_flow_id,special_flows.back_step_no,lot_special_flows.next_step_no) as [back_step_no]
			, [item_wip].[label_eng] + ' (' + cast([special_flows].[wip_state] as varchar) + ')' as [wip_state]
			, [item_quality].[label_eng] + ' (' + cast([special_flows].[quality_state] as varchar) + ')' as [quality_state]
			, [item_process].[label_eng] + ' (' + cast([special_flows].[process_state] as varchar) + ')' as [process_state]
			, lot_special_flows.recipe
			, lot_special_flows.material_set_id
			, lot_special_flows.jig_set_id
		from APCSProDB.trans.special_flows
		inner join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
		inner join APCSProDB.method.jobs on lot_special_flows.job_id = jobs.id
		cross apply (
			select top 1 sp.id as [special_flow_id]
				, lot_sp.id as [lot_special_flow_id]
				, sp.back_step_no as [next_step_no_master] 
			from APCSProDB.trans.special_flows as [sp]
			inner join APCSProDB.trans.lot_special_flows as [lot_sp] on sp.id = lot_sp.special_flow_id
			where sp.id = special_flows.id
			order by lot_sp.id desc
		) as last_row
		left join [APCSProDB].[trans].[item_labels] as [item_process] on [item_process].[name] = 'lots.process_state'
			and [item_process].[val] = [special_flows].[process_state]
		left join [APCSProDB].[trans].[item_labels] as [item_quality] on [item_quality].[name] = 'lots.quality_state'
			and [item_quality].[val] = [special_flows].[quality_state]
		left join [APCSProDB].[trans].[item_labels] as [item_wip] on [item_wip].[name] = 'lots.wip_state'
			and [item_wip].[val] = [special_flows].[wip_state]
		where special_flows.lot_id = (select id from APCSProDB.trans.lots where lot_no = @lot_no)
		order by lot_special_flows.step_no
		------Query Special Flow 
	end
	else if (@menu = 5) ---5.Cac Monitor  
	begin
		declare @day_condition int = 2

		declare @rohm_date_start datetime = convert(datetime,convert(varchar(10), GETDATE(), 120))
		declare @rohm_date_end datetime = convert(datetime,convert(varchar(10), GETDATE(), 120) + ' 08:00:00')
		declare @date_value varchar(10)
		declare @yesterday_date_value varchar(10)
		declare @day_delay_condition int

		if ((GETDATE() >= @rohm_date_start) AND (GETDATE() < @rohm_date_end))
		begin
			set @date_value = convert(varchar(10), GETDATE() - 1, 120)
			set @yesterday_date_value = convert(varchar(10), GETDATE() - 2, 120)
		end
		else begin
			set @date_value = convert(varchar(10), GETDATE(), 120)
			set @yesterday_date_value = convert(varchar(10), GETDATE() - 1, 120)
		end

		set @day_delay_condition =  (select [daycondition] FROM [APCSProDWH].[cac].[day_delay_condition])

		select [lots].[lot_no] as [lot_no]	
			, DATEDIFF(DAY,[days2].[date_value],@date_value) as [delay_day]
			, [wip_monitor_delay_lot_condition_detail].[status]
			, [wip_monitor_delay_lot_condition_detail].[problem_point]
			, [wip_monitor_delay_lot_condition_detail].[incharge]
			, 0 as [no_movement_day]
			, 'Delay' as [page]
		from [APCSProDB].[trans].[lots]
		inner join [APCSProDB].[trans].[days] as [days1] on [days1].[id] = [lots].[in_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [days2] on [days2].[id] = [lots].[modify_out_plan_date_id]
		left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]
		where [lots].[wip_state] in (20,10,0)
			and DATEDIFF(DAY,[days2].[date_value],@date_value) >= @day_delay_condition
			and (
				[wip_monitor_delay_lot_condition_detail].[status] like '%error%'
				or [wip_monitor_delay_lot_condition_detail].[status] like '%delete%'
				or [wip_monitor_delay_lot_condition_detail].[problem_point] like '%error%'
				or [wip_monitor_delay_lot_condition_detail].[problem_point] like '%delete%'
				or [wip_monitor_delay_lot_condition_detail].[incharge] like '%system%'
				or [wip_monitor_delay_lot_condition_detail].[incharge] like '%jeena%'
			)
		union all
		select [lots].[lot_no] as [lot_no]	
			, DATEDIFF(DAY,[days2].[date_value],@date_value) as [delay_day]
			, [wip_monitor_no_movement_lot_detail].[status]
			, [wip_monitor_no_movement_lot_detail].[problem_point]
			, [wip_monitor_no_movement_lot_detail].[incharge]
			, DATEDIFF(DAY,[lots].[updated_at],GETDATE()) as [no_movement_day]
			, 'Nomovement' as [page]
		from [APCSProDB].[trans].[lots]
		inner join [APCSProDB].[trans].[days] as [days1] on [days1].[id] = [lots].[in_plan_date_id]
		inner join [APCSProDB].[trans].[days] as [days2] on [days2].[id] = [lots].[modify_out_plan_date_id]
		left join [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail] with (NOLOCK) on [wip_monitor_no_movement_lot_detail].[lot_no] = [lots].[lot_no]
		where [lots].[wip_state] in (20,10,0)
			and [days1].[date_value] <= convert(date, getdate())
			and NOT(DATEDIFF(DAY,[days2].[date_value],@date_value) >= @day_delay_condition)
			and DATEDIFF(day,[lots].[updated_at],GETDATE()) >= @day_condition
			and (
				[wip_monitor_no_movement_lot_detail].[status] like '%error%'
				or [wip_monitor_no_movement_lot_detail].[status] like '%delete%'
				or [wip_monitor_no_movement_lot_detail].[problem_point] like '%error%'
				or [wip_monitor_no_movement_lot_detail].[problem_point] like '%delete%'
				or [wip_monitor_no_movement_lot_detail].[incharge] like '%system%'
				or [wip_monitor_no_movement_lot_detail].[incharge] like '%jeena%'
			)
		order by [page],[lots].[lot_no]
	end
	--else if (@menu = 6) ---6.Print Label 
	--begin
	--	if exists (select 1 from [APCSProDB].[trans].[label_issue_records] where [type_of_label] = 2 and [lot_no] = @lot_no)
	--	begin
	--		select 'https://webserv.thematrix.net/ROHMTEST/Atom/LabelFormatV2/GetdataLabel_TP_Process?Lotno=' + @lot_no + '&Type_label=2&Rell_number=0&Shipment_State=FALSE&PCRequest_State=FALSE&HasuuStockIn_State=FALSE' as [link]
	--			, 'TRUE' as [status]
	--	end
	--	else
	--	begin
	--		select '' as [link]
	--			, 'FALSE' as [status]
	--	end
	--end
	else if (@menu = 6) ---5.Cac Monitor  
	begin
		if @table_name = 'allocat'
		begin
			select *
			from APCSProDB.method.allocat
			where LotNo = @lot_no;
		end
		else if @table_name = 'allocat_temp'
		begin
			select *
			from APCSProDB.method.allocat_temp
			where LotNo = @lot_no;
		end
	end
	ELSE IF (@menu = 7) ---7. Log ESL Card
	BEGIN
		SELECT   [history_id]
				,FORMAT([record_at], 'yyyy-MM-dd HH:mm:ss') AS [record_at]
				,[record_class]
				,[login_name]
				,[hostname]
				,[clientname]
				,[appname]
				,[lot_no]
				,[e_slip_id]
				,[medthod_type]
				,[function_name]
				,[link_name]
				,[command_text] 
		FROM [APIStoredProDB].[dbo].[exec_sp_history_eslip]
		WHERE ([lot_no] = @lot_no  OR e_slip_id =   @lot_no )
		ORDER BY [record_at]
	END
	ELSE IF (@menu = 8) ---8.Log store
	BEGIN
		SELECT   [history_id]
				,FORMAT([record_at], 'yyyy-MM-dd HH:mm:ss') AS [record_at]
				,[record_class]
				,[login_name]
				,[hostname] 
				,[appname]
				,[lot_no] 
				,[command_text]
				,jig_id
				,barcode
		FROM StoredProcedureDB.[dbo].[exec_sp_history_jig]
		WHERE ([lot_no] = @lot_no OR barcode = @lot_no or jig_id = @lot_no)
		ORDER BY [record_at]
	END
	 ELSE IF (@menu = 9) ---8.Log store
	BEGIN
		SELECT   [history_id]
				,FORMAT([record_at], 'yyyy-MM-dd HH:mm:ss') AS [record_at]
				,[record_class]
				,[login_name]
				,[hostname] 
				,[appname]
				,[lot_no] 
				,[command_text]
				,jig_id
				,barcode
		FROM APIStoredProDB.[dbo].[exec_sp_history_jig]
		WHERE ([lot_no] = @lot_no OR barcode = @lot_no or jig_id = @lot_no)
		ORDER BY [record_at]
	END
END
