-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create Date,,20220502>
-- Description:	<Description,,Create recall lot (D lot) assy_ft_class = R>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_recall_lot_in_tranlot]
	-- Add the parameters for the stored procedure here
	@lotno_master varchar(10)
	,@lotno_recall varchar(10)
	,@flow_pattern_id int
	,@qty_out int
	,@empid int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @r int = 0
	,@deviceid int;

	--find deviceid from trans.lots.
	select @deviceid = lots.act_device_name_id from [APCSProDB].[trans].[lots] where lot_no = @lotno_master

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
		,'EXEC [atom].[sp_set_recall_lot_in_tranlot] @new_lotno = ''' + @lotno_recall + ''' @lotno_master =  ''' + @lotno_master + ''' @empid = ''' + CAST(@empid AS VARCHAR) + '''@flow_pattern_id = ''' + CAST(@flow_pattern_id AS VARCHAR) + ''' @qty_out =  ''' + CAST(@qty_out AS VARCHAR) + ''''  --update date : 2021/12/27 time : 8.33
		,@lotno_recall






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
		,[created_by]
		,[external_lot_no]
		,[production_category]
	)
	select 
	nu.id + row_number() over (order by T2.Hasuu_LotNo) as new_lot_id
	,T2.Hasuu_LotNo
	,t2.product_family_id
	,t2.package_id
	,t2.device_name_id
	,t2.device_slip_id
	,t2.order_id
	,t2.step_no as step_no
	,t2.process_id
	,t2.job_id
	,@qty_out as qty_in
	,@qty_out as qty_pass
	,t2.qty_fail
	,t2.qty_last_pass
	,t2.qty_last_fail
	,t2.qty_pass_step_sum
	,t2.qty_fail_step_sum
	,t2.qty_divided
	,t2.qty_hasuu
	,@qty_out as qty_out
	,t2.is_exist_work	
	,t2.in_plan_date_id
	,t2.out_plan_date_id
	,nu.id + row_number() over (order by T2.Hasuu_LotNo) as master_lot_id
	,t2.depth
	,t2.sequence
	,t2.wip_state 
	,t2.process_state
	,t2.quality_state
	,t2.first_ins_state
	,t2.final_ins_state
	,t2.is_special_flow
	,t2.special_flow_id
	,t2.is_temp_devided
	,t2.temp_devided_count
	,t2.product_class_id
	,t2.priority
	,t2.finish_date_id
	,t2.finished_at
	,t2.in_date_id
	,t2.in_at
	,t2.ship_date_id
	,t2.ship_at
	,t2.modify_out_plan_date_id
	,t2.start_step_no as start_step_no
	,t2.created_at
	,@empid as created_by
	,@lotno_master as external_lot_no
	,70
	from
	(
	select
	T1.HASUU_LotNo
	, rank() over (partition by T1.HASUU_LotNo order by df.step_no) as step_rank
	,T1.product_family_id
	,T1.package_id
	,T1.device_name_id
	,ds.device_slip_id
	,null as order_id
	,df.step_no
	,jb.process_id
	,df.job_id
	,0 as qty_fail
	,0 as qty_last_pass
	,0 as qty_last_fail
	,0 as qty_pass_step_sum
	,0 as qty_fail_step_sum
	,0 as qty_divided
	,0 as qty_hasuu
	,0 as is_exist_work	
	,di.id as in_plan_date_id
	,di.id + 15 as out_plan_date_id
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
	,di.id + 15 as modify_out_plan_date_id
	,df.step_no as start_step_no
	,getdate() as created_at
	from 
		(
			select 
			@lotno_recall as Hasuu_lotno
			,pc.product_family_id as product_family_id
			,dn.package_id
			,dn.id as device_name_id
			,pc.name as Type_Name
			,dn.name as Rohm_Model_Name
			,dn.assy_name as Assy_Model_Name
			,dn.rank as Rank
			,dn.tp_rank as TP_Rank
			,dn.pcs_per_pack as Packing_Standard_QTY
			,GETDATE() as MIXD_DATE
			,GETDATE() as Time_Stame_Date
			from [APCSProDB].[method].[device_names] as dn
			left outer join [APCSProDB].[method].[packages] as pc  on pc.id = dn.package_id and pc.is_enabled = 1
			left outer join [APCSProDB].[trans].[lots] as l on l.lot_no = @lotno_recall
			where dn.id = @deviceid and l.id is null
			--where dn.name = @device_name and dn.assy_name = @assy_name and l.id is null
		) as t1
	left outer join [APCSProDB].[method].[device_versions] as dv with (NOLOCK) on dv.device_name_id = t1.device_name_id and dv.device_type = 7 
	left outer join [APCSProDB].[method].[device_slips] as ds with (NOLOCK) on ds.device_id = dv.device_id and ds.is_released in(1,2)
		and not exists 
		(
			select * from [APCSProDB].[method].[device_slips] as ds2 with (NOLOCK) 
			where ds2.device_id = ds.device_id and ds2.is_released  in(1,2) and ds2.version_num > ds.version_num
		)
	left outer join [APCSProDB].[method].[device_flow_patterns] as dfp with (NOLOCK) on dfp.device_slip_id = ds.device_slip_id and dfp.assy_ft_class = 'R'
	left outer join [APCSProDB].[method].[flow_details] as fd with (NOLOCK) on fd.flow_pattern_id = @flow_pattern_id
	left outer join [APCSProDB].[method].[device_flows] as df with (NOLOCK) on df.device_slip_id = ds.device_slip_id and df.job_id = fd.job_id and isnull(df.is_skipped,0) <> 1

	left outer join [APCSProDB].[method].[jobs] as jb with (NOLOCK) on jb.id = df.job_id 
	left outer join [APCSProDB].[trans].[days] as di with (NOLOCK) on di.date_value = convert(date,t1.mixd_date)
	--left outer join [APCSProDB].[trans].[numbers] as nu with (NOLOCK) on nu.name = 'lots.id'

	where 	df.step_no is not null 
	
	) t2
	left outer join [APCSProDB].[trans].[numbers] as nu with (NOLOCK) on nu.name = 'lots.id' 
	where t2.step_rank = 1 
	

	-- Update column lots.id in table test_tg_tran_numbers
	set @r = @@ROWCOUNT
	update APCSProDB.trans.numbers
	set id = id + @r 
	from APCSProDB.trans.numbers
	where name = 'lots.id'


		------------INSERT DATA TO IS-------------------
		
		DECLARE @empnum AS NVARCHAR(6)
		SET @empnum = (SELECT TOP 1 emp_num FROM APCSProDB.man.users WHERE id =  @empid)

		EXEC [StoredProcedureDB].[dbo].[tg_sp_new_dlot_recall_is]
		  @hasuu_lotno = @lotno_master
		, @total_pcs = @qty_out
		, @empno = @empnum
		, @newlotno = @lotno_recall
		 
		-------------------------------


	IF @@ERROR <> 0
	GOTO ErrorHandler

	SET NOCOUNT OFF
	RETURN (0)
	ErrorHandler:
	RETURN (@@ERROR)

END
