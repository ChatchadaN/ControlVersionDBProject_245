

create PROCEDURE [etl].[sp_etlinputcontrol_calc_main_v3_old] 

AS
BEGIN
    ---------------------------------------------------------------------------
	--(1) Declare
    ---------------------------------------------------------------------------
	DECLARE @logtext nvarchar(max);
	DECLARE @errnum  INT ;
	DECLARE @errline INT ;
	DECLARE @errmsg nvarchar(max);

	DECLARE @ret INT = 0;
	DECLARE @sqlCommon NVARCHAR(max) = '';
	DECLARE @sql NVARCHAR(max) = '';
	DECLARE @rowcnt INT = 0;
	declare @partno INT = 1;
	declare @dt datetime ;
	select @dt = GETDATE();

declare @today int
select @today = dy.id from APCSProDB.trans.days as dy with (NOLOCK) 
where dy.date_value = convert(date,getdate())
print @today

declare @wcd int
/* SQL0: APCSProDWH.dwh.act_settings WipCountDays */
select @wcd = isnull(convert(int,a.val),1) from apcsprodwh.dwh.act_settings as a with (NOLOCK) 
where a.name = 'WipCountDays'
print @wcd

    ---------------------------------------------------------------------------
	--(4)SQL make
    ---------------------------------------------------------------------------
/* SQL1:insert history */
BEGIN TRY
		BEGIN TRANSACTION;
		/**********    part:1  *********/
		--select @partno = 1;

		INSERT INTO apcsprodwh.wip_control.monitoring_item_records
				   (id
				   ,monitoring_item_id
				   ,recorded_at
				   ,target_value
				   ,warn_value
				   ,alarm_value
				   ,is_alarmed
				   ,current_value
				   ,occurred_at
				   ,cleared_at)
		select 
				n.id + ROW_NUMBER() over (order by t6.monitoring_item_id) as r_id
				,t6.monitoring_item_id
				,@dt as recorded_at
				,t6.target_value
				,t6.warn_value
				,t6.alarm_value
				/*,t6.current_state*/
				,t6.new_state
				/*,t6.current_value*/
				,t6.new_value
				,case when t6.current_state = t6.new_state 
							then t6.occurred_at 
							else case t6.current_state 
									when 0 then case when t6.new_state =10 then t6.occurred_at else @dt end 
									when 10 then case when t6.new_state = 0 then t6.occurred_at else @dt end 
									else @dt end 
							end as occurred_at 
				,case when t6.current_state = t6.new_state 
							then t6.cleared_at
							else case t6.current_state 
									when 0 then case when t6.new_state =10 then t6.cleared_at else null end 
									when 10 then case when t6.new_state = 0 then t6.cleared_at else null end 
									else case when t6.new_state in(0,10) then @dt else  t6.cleared_at  end 
									end
							end as cleared_at 
		from 
				(
					select 
												t5.monitoring_item_id
												,t5.target_value
												,t5.warn_value
												,t5.alarm_value
												,t5.lcl_value
												,t5.current_state
												,t5.current_value
												,t5.control_unit_type
												,t5.occurred_at
												,t5.cleared_at
												,t5.ratio_type
												,t5.ratio_upper_limit
												,t5.device_name
												,t5.lot_count
												,t5.lot_count_sum
												,t5.lot_pcs
												,t5.lot_pcs_sum
												,t5.lot_process_minutes
												,t5.lot_minutes_sum
												,case t5.control_unit_type 
													when 0
														then case when t5.alarm_value * @wcd < t5.lot_count_sum 
																		then 1 
																		else case when t5.warn_value * @wcd < t5.lot_count_sum 
																						then case when t5.ratio_upper_limit > 0 and t5.lot_count_sum > 0  
																											then case when t5.lot_count *100 /t5.lot_count_sum > t5.ratio_upper_limit then 2 else 10 end 
																											else 10 end 
																						else case when t5.lcl_value > t5.lot_count_sum 
																										then 3 
																										else 0
																										end
																						end 
																		end 
													when 1
														then case when t5.alarm_value * @wcd < (t5.lot_pcs_sum / 1000)
																		then 1 
																		else case when t5.warn_value * @wcd < (t5.lot_pcs_sum / 1000)
																						then case when t5.ratio_upper_limit > 0 and t5.lot_pcs_sum > 0  
																											then case when t5.lot_pcs *100 /t5.lot_pcs_sum > t5.ratio_upper_limit then 2 else 10 end 
																											else 10 end 
																						else case when t5.lcl_value > (t5.lot_pcs_sum / 1000)
																										then 3 
																										else 0
																										end
																						end 
																		end 
													when 2
														then case when t5.alarm_value * @wcd < t5.lot_minutes_sum 
																		then 1 
																		else case when t5.warn_value * @wcd < t5.lot_minutes_sum 
																						then case when t5.ratio_upper_limit > 0 and t5.lot_minutes_sum > 0  
																											then case when t5.lot_process_minutes *100 /t5.lot_minutes_sum > t5.ratio_upper_limit then 2 else 10 end 
																											else 10 end 
																						else case when t5.lcl_value > t5.lot_minutes_sum 
																										then 3 
																										else 0
																										end
																						end 
																		end 

													end as new_state
												,case t5.control_unit_type 
													when 0
														then t5.lot_count_sum 
													when 1
														then (t5.lot_pcs_sum / 1000)
													when 2
														then  t5.lot_minutes_sum
													end as new_value
					from 
							(

								select 
												t4.monitoring_item_id
												,t4.target_value
												,t4.warn_value
												,t4.alarm_value
												,t4.lcl_value
												,t4.current_state
												,t4.current_value
												,t4.control_unit_type
												,t4.occurred_at
												,t4.cleared_at
												,t4.ratio_type
												,t4.ratio_upper_limit
												,t4.device_name
												,t4.lot_count
												,sum(t4.lot_count) over (partition by t4.monitoring_item_id) as lot_count_sum
												,t4.lot_pcs
												,sum(t4.lot_pcs) over (partition by t4.monitoring_item_id) as lot_pcs_sum
												,t4.lot_process_minutes
												,sum(t4.lot_process_minutes) over (partition by t4.monitoring_item_id) as lot_minutes_sum
								from 
										(

											select 
												t3.monitoring_item_id
												,t3.target_value
												,t3.warn_value
												,t3.alarm_value
												,t3.lcl_value
												,t3.current_state
												,t3.current_value
												,t3.control_unit_type
												,t3.occurred_at
												,t3.cleared_at
												/*,t3.job_id*/
												,t3.ratio_type
												,t3.ratio_upper_limit
												/*,t3.package_id*/
												,t3.device_name
												,convert(decimal,count(t3.lot_id)) as lot_count
												,convert(decimal,isnull(sum(t3.qty_pass),0)) as lot_pcs
												,convert(decimal,isnull(sum(convert(decimal,t3.process_minutes) *t3.official_number/ (case when isnull(t3.qty_pass,0) = 0 then t3.official_number else t3.qty_pass end)),0)) as lot_process_minutes
											from 
													(

														select 
														t2.* 
														,l.id as lot_id
														,d.name as device_name
														,d.is_assy_only
														,l.qty_pass
														,f.process_minutes
														,d.official_number
														,case when t2.target_device is null then 1 else case when CHARINDEX(t2.target_device,d.name) = 1 then 1 else 0 end end as check_state
														from 
																(
																	select 
																		t1.monitoring_item_id
																		,t1.target_value
																		,t1.warn_value
																		,t1.alarm_value
																		,t1.lcl_value
																		,t1.is_alarmed as current_state
																		,t1.current_value as current_value 
																		,t1.control_unit_type
																		,t1.occurred_at 
																		,t1.cleared_at
																	/*	,t1.target_package_id */
																		,t1.job_id
																		,t1.ratio_type
																		,t1.ratio_upper_limit
																	/*	,t1.product_group_package_id */
																	/*	,t1.pgd_package_id */
																		,isnull(t1.target_package_id,isnull(t1.product_group_package_id,isnull(t1.pgd_package_id,null))) as package_id
																		,t1.target_device
																	from 
																			(
																				select  
																						   i.id as monitoring_item_id
																						   ,target_value
																						   ,warn_value
																						   ,alarm_value
																						   ,lcl_value
																						   ,is_alarmed
																						   ,current_value
																						   ,i.control_unit_type
																						   ,occurred_at
																						   ,cleared_at
																						   ,t.package_id as target_package_id
																						   ,j.job_id
																						   ,isnull(pg.ratio_type,0) as ratio_type
																						   ,isnull(pg.ratio_upper_limit,0) as ratio_upper_limit
																						   ,g.package_id as product_group_package_id
																						   ,pgd.package_id as pgd_package_id
																						   ,pgd.target_device as target_device
																				from  APCSProDWH.wip_control.monitoring_items as i with (NOLOCK)
																					inner join APCSProDWH.wip_control.wip_count_target as t with (NOLOCK) 
																						on t.id = i.target_id 
																					left outer join APCSProDWH.wip_control.wip_count_jobs as j with (NOLOCK) 
																						on j.wip_count_target_id = t.id 
																					left outer join APCSProDWH.wip_control.wip_count_product_groups as pg with (NOLOCK) 
																						on pg.wip_count_job_id = j.id
																					left outer join APCSProDWH.wip_control.product_groups as g with (NOLOCK) 
																						on g.id = pg.product_group_id
																					left outer join APCSProDWH.wip_control.product_group_details as pgd with (NOLOCK) 
																						on pgd.product_group_id = g.id
																				where isnull(i.is_input_control,0) = 1
																			) as t1
																) as t2
																left outer join APCSProDB.trans.lots as l with (NOLOCK) 
																	on l.act_package_id = t2.package_id 
																		and l.act_job_id = t2.job_id 
																		and substring(l.lot_no,5,1) = 'A' 
																		and l.wip_state <= 20 
																		and l.quality_state not in(3) 
																		and l.process_state not in (2,102) 
																		and isnull(l.is_special_flow,0) = 0 
																		and l.in_plan_date_id <= @today
																left outer join APCSProDB.method.device_names as d with (NOLOCK)
																	on d.id = l.act_device_name_id
																		and d.is_assy_only in(0,1)
																left outer join APCSProDB.method.device_flows as f with (NOLOCK) 
																	on f.device_slip_id = l.device_slip_id 
																		and f.step_no = l.step_no
													) as t3
											where t3.check_state = 1
											group by 
												t3.monitoring_item_id
												,t3.target_value
												,t3.warn_value
												,t3.alarm_value
												,t3.lcl_value
												,t3.current_state
												,t3.current_value
												,t3.control_unit_type
												,t3.occurred_at
												,t3.cleared_at
												/* --,t3.job_id */
												,t3.ratio_type
												,t3.ratio_upper_limit
												/* --,t3.package_id */
												,t3.device_name
				
										) as t4
							) as t5
				) as t6 
				inner join apcsprodwh.wip_control.numbers as n 
					on n.name = 'monitoring_item_records.id' 

		where isnull(t6.current_value,0) <> t6.new_value  or t6.current_state <> t6.new_state
		group by 
				t6.monitoring_item_id
				,t6.target_value
				,t6.warn_value
				,t6.alarm_value
				,t6.current_state
				,t6.new_state
				,t6.current_value
				,t6.new_value
				,t6.occurred_at
				,t6.cleared_at
				,n.id;

		set @rowcnt = @@ROWCOUNT;
		set @logtext = 'INSERT monitoring_item_records  ' + '@partno:1 :[OK] row:' + convert(varchar,@rowcnt);
		print '---- ' + @logtext + ' ---' ;
		
		print '---- 2 ---' ;
		if (@rowcnt > 0)
			begin 
				/* SQL2: update numbers */
				update APCSProDWH.wip_control.numbers 
				set id = id + @rowcnt
				from  APCSProDWH.wip_control.numbers as n with (ROWLOCK)
				where n.name = 'monitoring_item_records.id' ;

				--set @logtext = 'INSERT monitoring_item_records  ' + '@partno:2 :[OK] row:' + convert(varchar,@@ROWCOUNT);
				--set @rowcnt = @@ROWCOUNT;
				--set @logtext = 'INSERT monitoring_item_records  ' + '@partno' + convert(varchar,@partno) + ' :[OK] row:' + convert(varchar,@rowcnt);
				print 'INSERT monitoring_item_records  ' + '@partno:2 :[OK] row:' + convert(varchar,@@ROWCOUNT);
			end
		else 
			begin
				print 'INSERT monitoring_item_records  ' + '@partno:2  no data';
			end

		/**********    part:3  *********/
		--set @partno = 3;
		print '--- 3 ---'

		/* SQL3:update monitoring_item */
update APCSProDWH.wip_control.monitoring_items 
	set is_alarmed = t7.new_state 
		,current_value = t7.new_value 
		,occurred_at = t7.occurred_at 
		,cleared_at = t7.cleared_at 
from APCSProDWH.wip_control.monitoring_items  as i with (ROWLOCK)
	inner join 
	(
		select 
				n.id + ROW_NUMBER() over (order by t6.monitoring_item_id) as r_id
				,t6.monitoring_item_id
				,@dt as recorded_at
				,t6.target_value
				,t6.warn_value
				,t6.alarm_value
				/*,t6.current_state*/
				,t6.new_state
				/*,t6.current_value*/
				,t6.new_value
				,case when t6.current_state = t6.new_state 
							then t6.occurred_at 
							else case t6.current_state 
									when 0 then case when t6.new_state =10 then t6.occurred_at else @dt end 
									when 10 then case when t6.new_state = 0 then t6.occurred_at else @dt end 
									else @dt end 
							end as occurred_at 
				,case when t6.current_state = t6.new_state 
							then t6.cleared_at
							else case t6.current_state 
									when 0 then case when t6.new_state =10 then t6.cleared_at else null end 
									when 10 then case when t6.new_state = 0 then t6.cleared_at else null end 
									else case when t6.new_state in(0,10) then @dt else  t6.cleared_at  end 
									end
							end as cleared_at 
		from 
				(
					select 
												t5.monitoring_item_id
												,t5.target_value
												,t5.warn_value
												,t5.alarm_value
												,t5.lcl_value
												,t5.current_state
												,t5.current_value
												,t5.control_unit_type
												,t5.occurred_at
												,t5.cleared_at
												,t5.ratio_type
												,t5.ratio_upper_limit
												,t5.device_name
												,t5.lot_count
												,t5.lot_count_sum
												,t5.lot_pcs
												,t5.lot_pcs_sum
												,t5.lot_process_minutes
												,t5.lot_minutes_sum
												,case t5.control_unit_type 
													when 0
														then case when t5.alarm_value * @wcd < t5.lot_count_sum 
																		then 1 
																		else case when t5.warn_value * @wcd < t5.lot_count_sum 
																						then case when t5.ratio_upper_limit > 0 and t5.lot_count_sum > 0  
																											then case when t5.lot_count *100 /t5.lot_count_sum > t5.ratio_upper_limit then 2 else 10 end 
																											else 10 end 
																						else case when t5.lcl_value > t5.lot_count_sum 
																										then 3 
																										else 0
																										end
																						end 
																		end 
													when 1
														then case when t5.alarm_value * @wcd < (t5.lot_pcs_sum / 1000)
																		then 1 
																		else case when t5.warn_value * @wcd < (t5.lot_pcs_sum / 1000) 
																						then case when t5.ratio_upper_limit > 0 and t5.lot_pcs_sum > 0  
																											then case when t5.lot_pcs *100 /t5.lot_pcs_sum > t5.ratio_upper_limit then 2 else 10 end 
																											else 10 end 
																						else case when t5.lcl_value > (t5.lot_pcs_sum / 1000)
																										then 3 
																										else 0
																										end
																						end 
																		end 
													when 2
														then case when t5.alarm_value * @wcd < t5.lot_minutes_sum 
																		then 1 
																		else case when t5.warn_value * @wcd < t5.lot_minutes_sum 
																						then case when t5.ratio_upper_limit > 0 and t5.lot_minutes_sum > 0  
																											then case when t5.lot_process_minutes *100 /t5.lot_minutes_sum > t5.ratio_upper_limit then 2 else 10 end 
																											else 10 end 
																						else case when t5.lcl_value > t5.lot_minutes_sum 
																										then 3 
																										else 0
																										end
																						end 
																		end 

													end as new_state
												,case t5.control_unit_type 
													when 0
														then t5.lot_count_sum 
													when 1
														then (t5.lot_pcs_sum / 1000)
													when 2
														then  t5.lot_minutes_sum
													end as new_value
					from 
							(

								select 
												t4.monitoring_item_id
												,t4.target_value
												,t4.warn_value
												,t4.alarm_value
												,t4.lcl_value
												,t4.current_state
												,t4.current_value
												,t4.control_unit_type
												,t4.occurred_at
												,t4.cleared_at
												,t4.ratio_type
												,t4.ratio_upper_limit
												,t4.device_name
												,t4.lot_count
												,sum(t4.lot_count) over (partition by t4.monitoring_item_id) as lot_count_sum
												,t4.lot_pcs
												,sum(t4.lot_pcs) over (partition by t4.monitoring_item_id) as lot_pcs_sum
												,t4.lot_process_minutes
												,sum(t4.lot_process_minutes) over (partition by t4.monitoring_item_id) as lot_minutes_sum
								from 
										(

											select 
												t3.monitoring_item_id
												,t3.target_value
												,t3.warn_value
												,t3.alarm_value
												,t3.lcl_value
												,t3.current_state
												,t3.current_value
												,t3.control_unit_type
												,t3.occurred_at
												,t3.cleared_at
												/*,t3.job_id*/
												,t3.ratio_type
												,t3.ratio_upper_limit
												/*,t3.package_id*/
												,t3.device_name
												,convert(decimal,count(t3.lot_id)) as lot_count
												,convert(decimal,isnull(sum(t3.qty_pass),0)) as lot_pcs
												,convert(decimal,isnull(sum(convert(decimal,t3.process_minutes) *t3.official_number/ (case when isnull(t3.qty_pass,0) = 0 then t3.official_number else t3.qty_pass end)),0)) as lot_process_minutes
											from 
													(

														select 
														t2.* 
														,l.id as lot_id
														,d.name as device_name
														,d.is_assy_only
														,l.qty_pass
														,f.process_minutes
														,d.official_number
														,case when t2.target_device is null then 1 else case when CHARINDEX(t2.target_device,d.name) = 1 then 1 else 0 end end as check_state
														from 
																(
																	select 
																		t1.monitoring_item_id
																		,t1.target_value
																		,t1.warn_value
																		,t1.alarm_value
																		,t1.lcl_value
																		,t1.is_alarmed as current_state
																		,t1.current_value as current_value 
																		,t1.control_unit_type
																		,t1.occurred_at 
																		,t1.cleared_at
																	/*	,t1.target_package_id */
																		,t1.job_id
																		,t1.ratio_type
																		,t1.ratio_upper_limit
																	/*	,t1.product_group_package_id */
																	/*	,t1.pgd_package_id */
																		,isnull(t1.target_package_id,isnull(t1.product_group_package_id,isnull(t1.pgd_package_id,null))) as package_id
																		,t1.target_device
																	from 
																			(
																				select  
																						   i.id as monitoring_item_id
																						   ,target_value
																						   ,warn_value
																						   ,alarm_value
																						   ,lcl_value
																						   ,is_alarmed
																						   ,current_value
																						   ,i.control_unit_type
																						   ,occurred_at
																						   ,cleared_at
																						   ,t.package_id as target_package_id
																						   ,j.job_id
																						   ,isnull(pg.ratio_type,0) as ratio_type
																						   ,isnull(pg.ratio_upper_limit,0) as ratio_upper_limit
																						   ,g.package_id as product_group_package_id
																						   ,pgd.package_id as pgd_package_id
																						   ,pgd.target_device as target_device
																				from  APCSProDWH.wip_control.monitoring_items as i with (NOLOCK) 
																					inner join APCSProDWH.wip_control.wip_count_target as t with (NOLOCK) 
																						on t.id = i.target_id 
																					left outer join APCSProDWH.wip_control.wip_count_jobs as j with (NOLOCK) 
																						on j.wip_count_target_id = t.id 
																					left outer join APCSProDWH.wip_control.wip_count_product_groups as pg with (NOLOCK) 
																						on pg.wip_count_job_id = j.id
																					left outer join APCSProDWH.wip_control.product_groups as g with (NOLOCK) 
																						on g.id = pg.product_group_id
																					left outer join APCSProDWH.wip_control.product_group_details as pgd with (NOLOCK) 
																						on pgd.product_group_id = g.id
																				where isnull(i.is_input_control,0) = 1
																			) as t1
																) as t2
																left outer join APCSProDB.trans.lots as l with (NOLOCK) 
																	on l.act_package_id = t2.package_id 
																		and l.act_job_id = t2.job_id 
																		and substring(l.lot_no,5,1) = 'A' 
																		and l.wip_state <= 20 
																		and l.quality_state not in(3) 
																		and l.process_state not in (2,102) 
																		and isnull(l.is_special_flow,0) = 0 
																		and l.in_plan_date_id <= @today
																left outer join APCSProDB.method.device_names as d with (NOLOCK) 
																	on d.id = l.act_device_name_id
																		and d.is_assy_only in(0,1)
																left outer join APCSProDB.method.device_flows as f with (NOLOCK) 
																	on f.device_slip_id = l.device_slip_id 
																		and f.step_no = l.step_no
													) as t3
											where t3.check_state = 1
											group by 
												t3.monitoring_item_id
												,t3.target_value
												,t3.warn_value
												,t3.alarm_value
												,t3.lcl_value
												,t3.current_state
												,t3.current_value
												,t3.control_unit_type
												,t3.occurred_at
												,t3.cleared_at
												/* --,t3.job_id */
												,t3.ratio_type
												,t3.ratio_upper_limit
												/* --,t3.package_id */
												,t3.device_name
				
										) as t4
							) as t5
				) as t6 
				inner join apcsprodwh.wip_control.numbers as n with (NOLOCK)
					on n.name = 'monitoring_item_records.id' 

		where isnull(t6.current_value,0) <> t6.new_value or t6.current_state <> t6.new_state
		group by 
				t6.monitoring_item_id
				,t6.target_value
				,t6.warn_value
				,t6.alarm_value
				,t6.current_state
				,t6.new_state
				,t6.current_value
				,t6.new_value
				,t6.occurred_at
				,t6.cleared_at
				,n.id
	) as t7
	on t7.monitoring_item_id = i.id 

		set @logtext = 'update monitoring_items  ' + '@partno:3 :[OK] row:' + convert(varchar,@@ROWCOUNT);
		--set @rowcnt = @@ROWCOUNT;
		--set @logtext = 'INSERT monitoring_item_records  ' + '@partno' + convert(varchar,@partno) + ' :[OK] row:' + convert(varchar,@rowcnt);
		print @logtext;


		/**********    part:4  *********/
		set @partno = 4;

/* SQL4:update packages */
/*
update APCSProDB.method.packages 
set is_input_stopped = case when t1.package_id is null then 0 else 1 end 
from APCSProDB.method.packages as p 
	left outer join 
		(
			select isnull(t.package_id,isnull(g.package_id,isnull(pgd.package_id,null))) as package_id 
			from APCSProDWH.wip_control.monitoring_items as i 
				inner join APCSProDWH.wip_control.wip_count_target as t 
					on t.id = i.target_id 
				left outer join APCSProDWH.wip_control.wip_count_jobs as j 
					on j.wip_count_target_id = t.id 
				left outer join APCSProDWH.wip_control.wip_count_product_groups as pg 
					on pg.wip_count_job_id = j.id
				left outer join APCSProDWH.wip_control.product_groups as g 
					on g.id = pg.product_group_id
				left outer join APCSProDWH.wip_control.product_group_details as pgd 
					on pgd.product_group_id = g.id
			where isnull(i.is_input_control,0) = 1 
				and i.is_alarmed = 1
				group by isnull(t.package_id,isnull(g.package_id,isnull(pgd.package_id,null)))
		) as t1 
	on t1.package_id = p.id 
*/




		COMMIT TRANSACTION;

		print 'COMMIT TRANSACTION';
	END TRY

	BEGIN CATCH
		IF @@TRANCOUNT <> 0
			BEGIN
				ROLLBACK TRANSACTION;
			END;
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = '[ERROR] sp_etlinputcontrol_calc_main' +'/ret:' + convert(varchar,@ret)  + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg + '/Part:' + convert(varchar,@partno);
		PRINT @logtext;
		RETURN -1;
	END CATCH;

	RETURN 0;

END ;



