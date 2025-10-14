-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_d_lot_v2] 
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @sqlLink NVARCHAR(4000) = '';
	DECLARE @sqlins NVARCHAR(4000) = '';
	declare @r int= 0;

	/* SQL Serverの設定変更可能に */
	SET @sqlLink = '';
	SET @sqlLink = @sqlLink + 'sp_configure ''show advanced options'', 1; ';
	SET @sqlLink = @sqllink + 'reconfigure with override; ';
	PRINT @sqlLink;
	EXECUTE (@sqlLink);

	/* 他サーバーへのアクセス可能にする */
	SET @sqlLink = '';
	SET @sqlLink = @sqlLink + 'sp_configure ''Ad Hoc Distributed Queries'', 1; ';
	SET @sqlLink = @sqllink + 'reconfigure with override; ';
	PRINT @sqlLink;
	EXECUTE (@sqlLink);


	insert into [APCSProDB].[trans].[lots] 
	(
		[id]
		,[lot_no]
		,[product_family_id]
		,[act_package_id]
		,[act_device_name_id]
		,[device_slip_id]
		,[order_id]
		,[step_no]
		,[act_process_id]
		,[act_job_id]
		,[qty_in]
		,[qty_pass]
		,[qty_fail]
		,[qty_last_pass]
		,[qty_last_fail]
		,[qty_pass_step_sum]
		,[qty_fail_step_sum]
		,[qty_divided]
		,[qty_hasuu]
		,[qty_out]
		,[is_exist_work]
		,[in_plan_date_id]
		,[out_plan_date_id]
		,[master_lot_id]
		,[depth]
		,[sequence]
		,[wip_state]
		,[process_state]
		,[quality_state]
		,[first_ins_state]
		,[final_ins_state]
		,[is_special_flow]
		,[special_flow_id]
		,[is_temp_devided]
		,[temp_devided_count]
		,[product_class_id]
		,[priority]
		,[finish_date_id]
		,[finished_at]
		,[in_date_id]
		,[in_at]
		,[ship_date_id]
		,[ship_at]
		,[modify_out_plan_date_id]
		,[start_step_no]
		,[created_at]
	)
select nu.id + row_number() over (order by T4.Hasuu_LotNo) as new_lot_id
	,T4.Hasuu_LotNo
	,t4.product_family_id
	,t4.package_id
	,t4.device_name_id
	,isnull(t4.device_slip_id_dlot, t4.device_slip_id) as device_slip_id
	,t4.order_id
	,isnull(t4.step_no_dlot, t4.step_no) as step_no
	,case when t4.step_no_dlot is null then t4.process_id else t4.process_id_dlot end as process_id
	,isnull(t4.job_id_dlot, t4.job_id) as job_id
	,t4.QTY_IN
	,t4.QTY_PASS
	,t4.qty_fail
	,t4.qty_last_pass
	,t4.qty_last_fail
	,t4.qty_pass_step_sum
	,t4.qty_fail_step_sum
	,t4.qty_divided
	,t4.qty_hasuu
	,t4.qty_out
	,t4.is_exist_work
	,t4.in_plan_date_id
	,t4.out_plan_date_id
	,nu.id + row_number() over (order by t4.Hasuu_LotNo) as master_lot_id
	,t4.depth
	,t4.sequence
	,t4.wip_state
	,t4.process_state
	,t4.quality_state
	,t4.first_ins_state
	,t4.final_ins_state
	,t4.is_special_flow
	,t4.special_flow_id
	,t4.is_temp_devided
	,t4.temp_devided_count
	,t4.product_class_id
	,t4.priority
	,t4.finish_date_id
	,t4.finished_at
	,t4.in_date_id
	,t4.in_at
	,t4.ship_date_id
	,t4.ship_at
	,t4.modify_out_plan_date_id
	,isnull(t4.step_no_dlot, t4.start_step_no) as start_step_no
	,t4.created_at
from (
	select rank() over (partition by t3.HASUU_LotNo order by fd_d.step_no) as step_rank_d
		,t3.*
		,ds_d.device_slip_id as device_slip_id_dlot
		,df_d.step_no as step_no_dlot
		,jb_d.id as job_id_dlot
		,jb_d.process_id as process_id_dlot
	from (
		select *
		from (
				select 
					T1.HASUU_LotNo
					,rank() over (partition by T1.HASUU_LotNo order by df.step_no) as step_rank
					,T1.product_family_id
					,T1.package_id
					,T1.device_name_id
					,ds.device_slip_id
					,null as order_id
					,df.step_no
					,jb.process_id
					,df.job_id
					,T1.QTY_IN
					,T1.QTY_PASS
					,0 as qty_fail
					,0 as qty_last_pass
					,0 as qty_last_fail
					,0 as qty_pass_step_sum
					,0 as qty_fail_step_sum
					,0 as qty_divided
					,0 as qty_hasuu
					,0 as qty_out
					,0 as is_exist_work
					,di.id as in_plan_date_id
					,di.id + 7 as out_plan_date_id
					,0 as depth
					,0 as sequence
					,20 as wip_state
					,0 as process_state
					,0 as quality_state
					,0 as first_ins_state
					,0 as final_ins_state
					,0 as is_special_flow
					,null as special_flow_id
					,0 as is_temp_devided
					,0 as temp_devided_count
					,0 as product_class_id
					,50 as priority
					,null as finish_date_id
					,null as finished_at
					,di.id as in_date_id
					,T1.mixd_date as in_at
					,null as ship_date_id
					,null as ship_at
					,di.id + 7 as modify_out_plan_date_id
					,df.step_no as start_step_no
					,getdate() as created_at
				from (
						select *
						from (
								select t0.*
									,rank() over (partition by hasuu_lotno,rohm_model_name order by assy_model_name) as device_rank
								from (
										select L1.[HASUU_LotNo]
											,pc.product_family_id
											,dn.package_id
											,dn.id as device_name_id
											,sum(L1.[QTY]) as QTY_IN
											,sum(L1.[QTY]) as QTY_PASS
											,L1.[Type_Name]
											,L1.[ROHM_Model_Name]
											,L1.[ASSY_Model_Name]
											,L1.[TIRank]
											,L1.[Rank]
											,L1.[TPRank]
											,L1.[Packing_Standerd_QTY]
											,L1.[MIXD_DATE]
											,L1.[TimeStamp_date]
											,L1.is_oneself
										--from  OPENROWSET('SQLNCLI', 'Data Source = 10.28.1.144;User ID=ship;Password=ship;',
										from OPENROWSET('SQLNCLI', 'Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship', 'select MH.[HASUU_LotNo],MH.LotNo,case when MH.[HASUU_LotNo] = MH.LotNo then 1 else 0 end as is_oneself,MH.QTY,MH.[Type_Name]
																	,MH.[ROHM_Model_Name]
																	,MH.[ASSY_Model_Name]
																	,MH.[TIRank]
																	,MH.[Rank]
																	,MH.[TPRank]
																	,MH.[Packing_Standerd_QTY]
																	,MH.[MIXD_DATE]
																	,MH.[TimeStamp_date]
															from [DBLSISHT].[dbo].[MIX_HIST] as MH with (NOLOCK) 
															where MH.hasuu_lotno like ''2%D%'' 
																and MH.mixd_date > dateadd(DAY,-30,getdate())
															') as L1
											left outer join [APCSProDB].[method].[device_names] as dn with (nolock) on dn.name = L1.ROHM_Model_Name and dn.assy_name = L1.ASSY_MODEL_Name
											left outer join [APCSProDB].[method].[packages] as pc with (nolock) on pc.id = dn.package_id and pc.is_enabled = 1
											left outer join [APCSProDB].[trans].[lots] as l with (nolock) on l.lot_no = l1.hasuu_lotno
										where l.id is null
											--where l.lot_no like '2045D24%'
											--where l.lot_no in ('2045D2486V', '2045D2493V', '2045D2497V')
										group by L1.[HASUU_LotNo]
											,pc.product_family_id
											,dn.package_id
											,L1.[Type_Name]
											,L1.[ROHM_Model_Name]
											,L1.[ASSY_Model_Name]
											,L1.[TIRank]
											,L1.[Rank]
											,L1.[TPRank]
											,L1.[Packing_Standerd_QTY]
											,L1.[MIXD_DATE]
											,L1.[TimeStamp_date]
											,dn.id
											,L1.is_oneself
									) t0
								where t0.is_oneself = 1
							) as t01
						where t01.device_rank = 1
					) as t1
					left outer join [APCSProDB].[method].[device_versions] as dv with (nolock) on dv.device_name_id = t1.device_name_id and dv.device_type = 0
					left outer join [APCSProDB].[method].[device_slips] as ds with (nolock) on ds.device_id = dv.device_id and ds.is_released in (1, 2) 
							and not exists (select * from [APCSProDB].[method].[device_slips] as ds2 with (nolock)
											where ds2.device_id = ds.device_id and ds2.is_released in (1, 2) and ds2.version_num > ds.version_num
											)
					left outer join [APCSProDB].[method].[device_flow_patterns] as dfp with (nolock) on dfp.device_slip_id = ds.device_slip_id and dfp.assy_ft_class = 'P'
					left outer join [APCSProDB].[method].[flow_details] as fd with (nolock) on fd.flow_pattern_id = dfp.flow_pattern_id --and fd.step_no = 1 
					left outer join [APCSProDB].[method].[device_flows] as df with (nolock) on df.device_slip_id = ds.device_slip_id and df.job_id = fd.job_id and isnull(df.is_skipped, 0) <> 1
					left outer join [APCSProDB].[method].[jobs] as jb with (nolock) on jb.id = df.job_id
					left outer join [APCSProDB].[trans].[days] as di with (nolock) on di.date_value = convert(date, t1.mixd_date)
			where df.step_no is not null
			) t2
			where t2.step_rank = 1
		) as t3
		left outer join [APCSProDB].[method].[device_versions] as dv_d with (nolock) on dv_d.device_name_id = t3.device_name_id and dv_d.device_type = 6
		left outer join [APCSProDB].[method].[device_slips] as ds_d with (nolock) on ds_d.device_id = dv_d.device_id and ds_d.is_released in (1, 2) 
					and not exists (
									select *
									from [APCSProDB].[method].[device_slips] as ds2_d with (nolock)
									where ds2_d.device_id = ds_d.device_id and ds2_d.is_released in (1, 2) and ds2_d.version_num > ds_d.version_num
									)
		left outer join [APCSProDB].[method].[device_flow_patterns] as dfp_d with (nolock) on dfp_d.device_slip_id = ds_d.device_slip_id and dfp_d.assy_ft_class = 'D'
		left outer join [APCSProDB].[method].[flow_details] as fd_d with (nolock) on fd_d.flow_pattern_id = dfp_d.flow_pattern_id
		left outer join [APCSProDB].[method].[device_flows] as df_d with (nolock) on df_d.device_slip_id = ds_d.device_slip_id and df_d.job_id = fd_d.job_id and isnull(df_d.is_skipped, 0) <> 1
		left outer join [APCSProDB].[method].[jobs] as jb_d with (nolock) on jb_d.id = df_d.job_id
	) as t4
	left outer join [APCSProDB].[trans].[numbers] as nu with (nolock) on nu.name = 'lots.id'
where t4.step_rank_d = 1

	--
	set @r = @@ROWCOUNT
	update [APCSProDB].[trans].[numbers] 
	set id = id + @r 
	from [APCSProDB].[trans].[numbers] with (ROWLOCK)
	where name = 'lots.id'

	IF @@ERROR <> 0
	GOTO ErrorHandler

	SET NOCOUNT OFF
	RETURN (0)
	ErrorHandler:
	RETURN (@@ERROR)

END
