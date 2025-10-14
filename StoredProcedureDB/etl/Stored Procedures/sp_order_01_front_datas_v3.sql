


-- =============================================
-- Author:		<M.Yamamoto>
-- Create date: <20th Feb 2019>
-- Description:	<Insert order datas from front data, and update order_id in lots>
-- =============================================
create PROCEDURE [etl].[sp_order_01_front_datas_v3] (
	@ServerName_APCS NVARCHAR(128) 
    ,@DatabaseName_APCS NVARCHAR(128)
	,@ServerName_APCSPro NVARCHAR(128) 
    ,@DatabaseName_APCSPro NVARCHAR(128)
	,@ServerName_APCSProDWH NVARCHAR(128) 
    ,@DatabaseName_APCSProDWH NVARCHAR(128)
	,@logtext NVARCHAR(max) output
	,@errnum  int output
	,@errline int output
	,@errmsg nvarchar(max) output
	) AS
BEGIN

    ---------------------------------------------------------------------------
	--(1) declare
    ---------------------------------------------------------------------------
	DECLARE @pObjAPCS NVARCHAR(128) = N''
	DECLARE @pObjAPCSPro NVARCHAR(128) = N''
	DECLARE @pObjAPCSProDWH NVARCHAR(128) = N''

	DECLARE @pFunctionName NVARCHAR(128) = N'';
	DECLARE @pStarttime DATETIME;
	DECLARE @pEndTime DATETIME;
	DECLARE @pInputTime varchar(max);

	DECLARE @pRet INT = 0;
	DECLARE @pStepNo INT = 0; 

	DECLARE @pSqlTruncAssyOrder NVARCHAR(4000) = N'';
	DECLARE @pSqlTruncMatAllocate NVARCHAR(4000) = N'';

	DECLARE @pSqlInsAssyOrderTemp NVARCHAR(4000) = N'';
	DECLARE @pSqlInsAssyOrder NVARCHAR(4000) = N'';
	DECLARE @pSqlInsAssyOrderCommon NVARCHAR(4000) = N'';

	DECLARE @pSqlInsMatAllocateTemp NVARCHAR(4000) = N'';
	DECLARE @pSqlInsMatAllocate NVARCHAR(4000) = N'';
	DECLARE @pSqlInsMatAllocateCommon NVARCHAR(4000) = N'';

	DECLARE @pSqlInsLotInfoFront NVARCHAR(4000) = N'';

	DECLARE @pSqlAssyOrder NVARCHAR(4000) = N'';
	DECLARE @pSqlMatAllocate NVARCHAR(4000) = N'';
	DECLARE @pSqlLotInfoFront NVARCHAR(4000) = N'';

	DECLARE @pSqlRowCnt NVARCHAR(4000) = N'';

	DECLARE @pSqlUpdateLots NVARCHAR(4000) = N'';

	DECLARE @pRowCnt INT = 0;
	DECLARE @pIdBefore INT=0;
	DECLARE @pIdAfter INT=0;
   ---------------------------------------------------------------------------
	--(2) connection string
    ---------------------------------------------------------------------------
	-- ''=local
	/*
	BEGIN
		IF RTRIM(@ServerName_APCS_) = '' RETURN 1;
	END;
	*/
	BEGIN
		IF RTRIM(@DatabaseName_APCS) = '' RETURN 1;
	END;
	-- ''=local
	/*
	BEGIN
		IF RTRIM(@ServerName_APCSPro_) = '' RETURN 1;
	END;
	*/
	BEGIN
		IF RTRIM(@DatabaseName_APCSPro) = '' RETURN 1;
	END;
	-- ''=local
	/*
	BEGIN
		IF RTRIM(@ServerName_APCSProDWH_) = '' RETURN 1;
	END;
	*/
	BEGIN
		IF RTRIM(@DatabaseName_APCSProDWH) = '' RETURN 1;
	END;

	BEGIN
		IF RTRIM(@ServerName_APCS) = '' 
			BEGIN
				SET @pObjAPCS = '[' + @DatabaseName_APCS + ']'
			END;
		ELSE
		BEGIN
			SET @pObjAPCS = '[' + @ServerName_APCS + '].[' + @DatabaseName_APCS + ']'
		END;
	END;

	BEGIN
		IF RTRIM(@ServerName_APCSPro) = '' 
			BEGIN
				SET @pObjAPCSPro = '[' + @DatabaseName_APCSPro + ']'
			END;
		ELSE
		BEGIN
			SET @pObjAPCSPro = '[' + @ServerName_APCSPro + '].[' + @DatabaseName_APCSPro + ']'
		END;
	END;

	BEGIN
		IF RTRIM(@ServerName_APCSProDWH) = '' 
			BEGIN
				SET @pObjAPCSProDWH = '[' + @DatabaseName_APCSProDWH + ']'
			END;
		ELSE
		BEGIN
			SET @pObjAPCSProDWH = '[' + @ServerName_APCSProDWH + '].[' + @DatabaseName_APCSProDWH + ']'
		END;
	END;

	---------------------------------------------------------------------------
	--(3) get functionname & time
    ---------------------------------------------------------------------------
	BEGIN TRY
		SELECT @pFunctionName = OBJECT_NAME(@@PROCID);
		SELECT @pStarttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000')) FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
		PRINT '@starttime=' + CASE WHEN @pStarttime IS NULL THEN '' ELSE FORMAT(@pStarttime, 'yyyy-MM-dd HH:mm:ss.fff') END;
		--yyyy/MM/dd HH:mm:ss.ff3
		SELECT @pInputTime = FORMAT(dateadd(hour,-1,GETDATE()), 'yyyy-MM-dd HH:00:00.000');
		SELECT @pEndTime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'));
		PRINT '@endtime=' + FORMAT(@pEndtime, 'yyyy-MM-dd HH:mm:ss.fff');
	END TRY
	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()
		SET @logtext = N'[ERR]';
		SET @logtext = @logtext + ERROR_MESSAGE();
		RETURN -1;
	END CATCH;

	if @pstarttime is not null
		begin
			if @pStarttime = @pEndTime 
				begin
					SET @logtext = @pfunctionname ;
					SET @logtext = @logtext + N' has already finished at this hour(' ;
					SET @logtext = @logtext + convert(varchar,@pEndTime,21);
					SET @logtext = @logtext + N')';
					RETURN 0;
				end;
		end ;

	---------------------------------------------------------------------------
	--(4)make SQL
    ---------------------------------------------------------------------------

-- for truncate table
	BEGIN
		SET @pSqlTruncAssyOrder = N'';
		SET @pSqlTruncAssyOrder = @pSqlTruncAssyOrder + N'truncate table ' + @pObjAPCSProDWH + N'.[dwh].[temp_assy_orders] ';
		--SET @pSqlTruncAssyOrder = @pSqlTruncAssyOrder + N'delete from ' + @pObjAPCSProDWH + N'.[dwh].[temp_assy_orders] ';
		PRINT '@pSqlTruncAssyOrder=' + @pSqlTruncAssyOrder;
	END; -- temp_assy_orders

	BEGIN
		SET @pSqlTruncMatAllocate = N'';
		SET @pSqlTruncMatAllocate = @pSqlTruncMatAllocate + N'truncate table ' + @pObjAPCSProDWH + N'.[dwh].[temp_material_allocates_front] ';
		--SET @pSqlTruncMatAllocate = @pSqlTruncMatAllocate + N'delete from ' + @pObjAPCSProDWH + N'.[dwh].[temp_material_allocates_front] ';
		PRINT '@pSqlTruncMatAllocate=' + @pSqlTruncMatAllocate;
	END; -- temp_material_allocates_front

-- insert into assy_orders  
	
	BEGIN
		SET @pSqlInsAssyOrderTemp = N'';
		SET @pSqlInsAssyOrderTemp = @pSqlInsAssyOrderTemp + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[temp_assy_orders] ';

		SET @pSqlInsAssyOrder = N'';
		SET @pSqlInsAssyOrder = @pSqlInsAssyOrder + N'insert into ' + @pObjAPCSPro + N'.[robin].[assy_orders] ';
	END; -- header

	BEGIN
		SET @pSqlInsAssyOrderCommon = N'';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N'(id ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',order_no ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',suffix ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',device_name ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',assy_name ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',ft_name ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',chip_name ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',package_name ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',rank ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',tp_rank ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',tp_rank_pattern ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',order_category ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',is_updated ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',in_plan_date ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',out_plan_date ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',delivery_plan_date ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',ordered_pcs ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',inputted_pcs ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',process_code ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',in_post_code ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',out_post_code ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',form_code ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',pin_num_code ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',item_code ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',order_issue_category ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',is_manual_allocate ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',order_state ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',revised_state ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',revised_out_plan_date ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',report_state ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',to_report ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',manual_register_state ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',is_all_ship ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',is_out_in ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',created_at ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',created_by ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',updated_at ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N',updated_by ';
		SET @pSqlInsAssyOrderCommon = @pSqlInsAssyOrderCommon + N') ';
	END; -- common temp_assy_orders
	--PRINT '@pSqlInsAssyOrderCommon=' + @pSqlInsAssyOrderCommon;

	BEGIN
		SET @pSqlAssyOrder = N'';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N' select ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	ROW_NUMBER() over(order by t.order_no) as id ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,t.order_no ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as suffix ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,t.device_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,t.assy_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,t.ft_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,t.chip_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,t.packege_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as rank ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as tp_rank ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as tp_rank_pattern ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as order_category ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,0 as is_updated ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,t.in_plan_date ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,t.out_plan_date ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as delivery_plan_date ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,t.ordered_pcs ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as inputted_pcs ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,t.process_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as in_post_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as out_post_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as form_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as pin_num_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as item_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as order_issue_category ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as is_manual_allocate ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,0 as order_state ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as revised_state ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as revised_out_plan_date ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as report_state ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as to_report ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as manual_register_state ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as is_all_ship ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as is_out_in ';
		--date
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,''' + convert(varchar,@pEndTime,21) + N''' as created_at ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as created_by ';
		--data
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,''' + convert(varchar,@pEndTime,21) + N''' as updated_at ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	,null as updated_by ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N' from ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'	( ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'		select ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'			t1.* ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'			,sum(convert(int,t1.THROW_PCS)) over (partition by t1.order_no) / t1.chips ordered_pcs ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'			,rank() over (partition by t1.order_no order by t1.lot_no asc,t1.wafer_lot_no asc,t1.wafer_no asc) as record_rank ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'		from ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'			( ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'				select ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					lot.lot_no ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,den.ORDER_NO as order_no ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,input.ROHM_ORDER_MODEL_NAME_O as device_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,input.ASSY_MODEL_NAME as assy_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,input.FT_MODEL_NAME as ft_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,input.CHIP_MODEL_SHORT_NAME as chip_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,input.FORM_NAME as packege_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,input.FAB_WF_LOT_NO as wafer_lot_no ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,input.WF_NO as wafer_no ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,input.QUANTITY as pcs ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,input.THROW_DATE as in_plan_date ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,input.THROW_NOKI as out_plan_date ';
	    SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,den.THROW_PCS ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,lot.chips ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,rank() over (partition by den.order_no,lot.lot_no order by input.fab_wf_lot_no asc,input.wf_no asc) as lot_record_rank ';
		--SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,sum(convert(int,den.THROW_PCS)) over (partition by den.order_no) ordered_pcs ';
		--SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,sum(convert(int,den.THROW_PCS)) over (partition by den.order_no)/lot.chips as ordered_pcs ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					,den.PROCESS_POST_CODE as process_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'				from ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					( ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'						select ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'							lots.id ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'							,lots.lot_no ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'							,case when (dn.number_of_chips is null) or (dn.number_of_chips = 0) then 1 ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'								else dn.number_of_chips ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'								end as chips ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'						from ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'							' + @pObjAPCSPro + N'.[trans].[lots] lots with (NOLOCK) ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'							inner join ' + @pObjAPCSPro + N'.[method].[device_names] dn with (NOLOCK) ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'								on dn.id = lots.act_device_name_id ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'						where ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'							isnull(lots.order_id,0) = 0 ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'							and dn.is_assy_only in (0,1) ';
		--debug Feb22
		--SET @pSqlAssyOrder = @pSqlAssyOrder + N'							and lots.wip_state=100 ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					) lot ';
		--SET @pSqlAssyOrder = @pSqlAssyOrder + N'					inner join APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT den ';
		--SET @pSqlAssyOrder = @pSqlAssyOrder + N'						on den.LOT_NO_2 = lot.lot_no ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					inner join ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'						( select ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'							* ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'							,rank() over (partition by d.lot_no_2 order by d.update_date desc) as record_rank ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'						  from ';
		--need to change
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'							' + @DatabaseName_APCS + N'.[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] as d ) den ';
		--SET @pSqlAssyOrder = @pSqlAssyOrder + N'							' + @pObjAPCS + N'.[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] d ) den ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'						on den.LOT_NO_2 = lot.lot_no and record_rank = 1 ';
		--debug Feb22
		--SET @pSqlAssyOrder = @pSqlAssyOrder + N'							and den.ORDER_NO = ''9QI02010002'' ';
		--need to change
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'					inner join ' + @pObjAPCSPro + '.[robin].[LOT1_TABLE_INPUT] as input ';
		--SET @pSqlAssyOrder = @pSqlAssyOrder + N'					inner join ' + @pObjAPCS + '.[dbo].[LOT1_TABLE_INPUT] as input ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'						on input.LOT_NO = lot.lot_no ';
		--debug Feb22
		--SET @pSqlAssyOrder = @pSqlAssyOrder + N'							and input.ORDER_NO = ''9QI02010002'' ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'			) as t1 ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N' where t1.lot_record_rank = 1 ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N' ) as t ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N' where t.record_rank = 1 ';
	END; -- select
	PRINT '@pSqlAssyOrder=' + @pSqlAssyOrder;

-- insert into material_allocates_front
	
	BEGIN
		SET @pSqlInsMatAllocateTemp = N'';
		SET @pSqlInsMatAllocateTemp = @pSqlInsMatAllocateTemp + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[temp_material_allocates_front] ';

		SET @pSqlInsMatAllocate = N'';
		SET @pSqlInsMatAllocate = @pSqlInsMatAllocate + N'insert into ' + @pObjAPCSPro + N'.[robin].[material_allocates_front] ';
	END; -- header

	BEGIN
		SET @pSqlInsMatAllocateCommon = N'';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N'(id ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',order_id ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',lot_id ';
		--SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',order_no ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',allocate_order ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',chip_name ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',material_id ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',wafer_lot_no ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',wafer_no ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',pcs ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',number_of_strip ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',wh_code ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',invoice_no ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',allocate_state ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',report_state ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',to_report ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',created_at ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',created_by ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',updated_at ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N',updated_by ';
		SET @pSqlInsMatAllocateCommon = @pSqlInsMatAllocateCommon + N') ';
	END; -- common temp_material_allocates_front
	--PRINT '@pSqlInsMatAllocateCommon=' + @pSqlInsMatAllocateCommon;

	BEGIN
		SET @pSqlMatAllocate = N'';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N' select ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	ROW_NUMBER() over(order by t.order_id) as id ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,t.order_id ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,t.lot_id ';
		--SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,t.order_no ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,t.allocate_order ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,t.chip_name ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,null as material_id ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,t.wafer_lot_no ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,t.wafer_no ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,t.pcs ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,null as number_of_strip ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,null as wh_code ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,null as invoice_no ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,null as allocate_state ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,null as report_state ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,null as to_report ';
		--date
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,''' + convert(varchar,@pEndTime,21) + N''' as created_at ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,null as created_by ';
		--date
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,''' + convert(varchar,@pEndTime,21) + N''' as updated_at ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	,null as updated_by ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N' from ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	( ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'		select ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'			t1.* ';
		-- 04 Mar change
		--SET @pSqlMatAllocate = @pSqlMatAllocate + N'			,rank() over (partition by t1.order_id order by t1.lot_id asc,t1.wafer_lot_no asc,t1.wafer_no asc) as allocate_order ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'			,rank() over (partition by t1.order_id ,t1.lot_id order by t1.wafer_lot_no asc,t1.wafer_no asc) as allocate_order ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'		from ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'			( ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'				select ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'					lot.id as lot_id ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'					,input.ORDER_NO as order_no ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'					,input.ROHM_ORDER_MODEL_NAME_O as device_name ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'					,input.CHIP_MODEL_SHORT_NAME as chip_name ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'					,input.FAB_WF_LOT_NO as wafer_lot_no ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'					,input.WF_NO as wafer_no ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'					,input.QUANTITY as pcs ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'					,o.id as order_id ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'				from ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'					( ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'						select ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'							lots.id ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'							,lots.lot_no ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'						from ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'							' + @pObjAPCSPro + N'.[trans].[lots] lots with (NOLOCK) ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'						where ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'							isnull(lots.order_id,0) = 0 ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'							and lots.wip_state in(0,10,20) ';
		--debug Feb22
		--SET @pSqlMatAllocate = @pSqlMatAllocate + N'							and lots.wip_state=100 ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'					) lot ';
		--need to change
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'				inner join ' + @pObjAPCSPro + '.[robin].[LOT1_TABLE_INPUT] input with (NOLOCK) ';
		--SET @pSqlMatAllocate = @pSqlMatAllocate + N'				inner join ' + @pObjAPCS + N'.[dbo].[LOT1_TABLE_INPUT] input ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'					on input.LOT_NO = lot.lot_no ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'						and not exists (select * from ' + @pObjAPCSPro + '.[robin].[LOT1_TABLE_INPUT] input2 with (NOLOCK) where input2.lot_no = input.lot_no and input2.id > input.id) ';

		SET @pSqlMatAllocate = @pSqlMatAllocate + N'				inner join ' + @pObjAPCSPro + N'.[robin].[assy_orders] o with (NOLOCK) ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'					on o.order_no = input.ORDER_NO ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'			) as t1 ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'	) as t ';

	END; -- select
	PRINT '@pSqlMatAllocate=' + @pSqlMatAllocate;

-- insert into lot_information_front
	
	BEGIN
		SET @pSqlInsLotInfoFront = N'';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N'insert into ' + @pObjAPCSPro + N'.[robin].[lot_information_front] ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N'(lot_id ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',mno ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_row_number_assy ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_1_assy ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_2_assy ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_3_assy ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_4_assy ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_5_assy ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_6_assy ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_row_number_ft ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_1_ft ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_2_ft ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_3_ft ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_4_ft ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_5_ft ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',symbol_6_ft ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',qr_code332 ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N',qr_code252 ';
		SET @pSqlInsLotInfoFront = @pSqlInsLotInfoFront + N') ';
	END;-- header&common lot_information_front
	--PRINT '@pSqlInsLotInfoFront=' + @pSqlInsLotInfoFront;
	
	BEGIN
		SET @pSqlLotInfoFront = N'';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N' select ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	lot.id as lot_id ';
		--SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,lot.lot_no ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.MNO1 as mno ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,case ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		when den.ASSY_SYMBOL_6 <> '''' then 6 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		when den.ASSY_SYMBOL_5 <> '''' then 5 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		when den.ASSY_SYMBOL_4 <> '''' then 4 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		when den.ASSY_SYMBOL_3 <> '''' then 3 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		when den.ASSY_SYMBOL_2 <> '''' then 2 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		when den.ASSY_SYMBOL_1 <> '''' then 1 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		else 0 end as symbol_row_number_assy ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.ASSY_SYMBOL_1 as symbol_1_assy ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.ASSY_SYMBOL_2 as symbol_2_assy ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.ASSY_SYMBOL_3 as symbol_3_assy ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.ASSY_SYMBOL_4 as symbol_4_assy ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.ASSY_SYMBOL_5 as symbol_5_assy ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.ASSY_SYMBOL_6 as symbol_6_assy ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,case  ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		when den.FT_SYMBOL_6 <> '''' then 6 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		when den.FT_SYMBOL_5 <> '''' then 5 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		when den.FT_SYMBOL_4 <> '''' then 4 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		when den.FT_SYMBOL_3 <> '''' then 3 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		when den.FT_SYMBOL_2 <> '''' then 2 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		when den.FT_SYMBOL_1 <> '''' then 1 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		else 0 end as symbol_row_number_ft ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.FT_SYMBOL_1 as symbol_1_ft ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.FT_SYMBOL_2 as symbol_2_ft ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.FT_SYMBOL_3 as symbol_3_ft ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.FT_SYMBOL_4 as symbol_4_ft ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.FT_SYMBOL_5 as symbol_5_ft ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.FT_SYMBOL_6 as symbol_6_ft ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.QR_CODE as qr_code332 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	,den.QR_CODE_2 as qr_code252 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N' from ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	( ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		select ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'			lots.id ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'			,lots.lot_no ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		from ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'			' + @pObjAPCSPro + N'.[trans].[lots] lots with (NOLOCK)';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'			inner join ' + @pObjAPCSPro + N'.[method].[device_names] dn with (NOLOCK)';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'			on dn.id = lots.act_device_name_id ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		where ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'			lots.wip_state <=20 and isnull(lots.order_id,0)=0 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'			and dn.is_assy_only in (0,1) ';
		--debug Feb22
		--SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'							and lots.wip_state=100 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	) lot ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	inner join ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	( '; 
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		select ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'			* ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'			,rank() over (partition by d.lot_no_2 order by d.update_date desc) as record_rank ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		from ';
		--need to change
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		' + @DatabaseName_APCS + '.[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] d) den ';
		--SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'			' + + @pObjAPCS + N'.[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] d ) den ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	on den.LOT_NO_2 = lot.lot_no ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'	and record_rank = 1 ';
		SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'where not exists (select * from ' + @pObjAPCSPro + N'.[robin].[lot_information_front] as f with (NOLOCK) where f.lot_id = lot.id) ';
		--debug Feb22
		--SET @pSqlLotInfoFront = @pSqlLotInfoFront + N'		where den.ORDER_NO = ''9QI02010002'' ';
	END; -- select
	PRINT '@pSqlLotInfoFront=' + @pSqlLotInfoFront;


	BEGIN
		SET @pSqlUpdateLots = N'';
		SET @pSqlUpdateLots = @pSqlUpdateLots + N'update ';
		SET @pSqlUpdateLots = @pSqlUpdateLots + N'	' + @pObjAPCSPro + N'.[trans].[lots] WITH (ROWLOCK) ';  
		SET @pSqlUpdateLots = @pSqlUpdateLots + N'set ';
		SET @pSqlUpdateLots = @pSqlUpdateLots + N'	order_id = al.order_id ';
		SET @pSqlUpdateLots = @pSqlUpdateLots + N'from ';
		SET @pSqlUpdateLots = @pSqlUpdateLots + N'	' + @pObjAPCSPro + N'.[trans].[lots] ';
		SET @pSqlUpdateLots = @pSqlUpdateLots + N'	inner join ' + @pObjAPCSPro + N'.[robin].[material_allocates_front] as al ';
		SET @pSqlUpdateLots = @pSqlUpdateLots + N'	on al.lot_id = lots.id ';
		SET @pSqlUpdateLots = @pSqlUpdateLots + N'where isnull(lots.order_id,0) = 0 ';
	END; -- update
	PRINT '@@pSqlUpdateLots=' + @pSqlUpdateLots;



   ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------

	BEGIN TRY

-- Step1 : for Assy Order

		BEGIN TRANSACTION

			PRINT '-----1-1) truncate temporary (dwh.temp_assy_orders)';
			SET @pStepNo = 1;
			--PRINT @pSqlTruncAssyOrder;
			EXECUTE (@pSqlTruncAssyOrder);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Truncate(temp_assy_orders) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----1-2) temporary ==> dwh.temp_assy_orders';
			SET @pStepNo = 2;
			PRINT '@pSqlInsAssyOrdertemp=' + @pSqlInsAssyOrdertemp;
			PRINT '@pSqlInsAssyOrderCommon=' + @pSqlInsAssyOrderCommon;
			PRINT '@pSqlAssyOrder=' + @pSqlAssyOrder;
			EXECUTE (@pSqlInsAssyOrdertemp + @pSqlInsAssyOrderCommon + @pSqlAssyOrder);
			--SET @pRowCnt = @@ROWCOUNT;

			PRINT '-----1-3) get row count from temp_assy_orders';
			SET @pStepNo = 3;
			SET @pSqlRowCnt = N'';
			SET @pSqlRowCnt = @pSqlRowCnt + N' select @OrdersCnt = count(*) '
			SET @pSqlRowCnt = @pSqlRowCnt + N' from ' +  @pObjAPCSProDWH + N'.[dwh].[temp_assy_orders] with (NOLOCK)'
			EXEC sp_executesql @pSqlRowCnt, N'@OrdersCnt INT OUTPUT', @OrdersCnt=@pRowCnt OUTPUT;
			PRINT 'Count=' + convert(varchar,@pRowCnt);
			SET @logtext = 'Insert(temp_assy_orders) OK : row=';
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

		COMMIT TRANSACTION;
	
	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT <> 0
			BEGIN
				ROLLBACK TRANSACTION;
			END;

		select @errMsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@ErrLine = ERROR_LINE()

		SET @logtext = N'[ERR] ';
		SET @logtext = @logtext + @pFunctionName;
		SET @logtext = @logtext + N'/step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/count:';
		SET @logtext = @logtext + convert(varchar,@pRowCnt);
		SET @logtext = @logtext + N'/num:';
		SET @logtext = @logtext + convert(varchar,@errnum);
		SET @logtext = @logtext + N'/line:';
		SET @logtext = @logtext + convert(varchar,@errline);
		SET @logtext = @logtext + '/msg:';
		SET @logtext = @logtext + @errmsg;
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;


	BEGIN TRY

		PRINT '-----1-4) Check row counts';
		SET @pStepNo = 4;

		if @pRowCnt = 0
			BEGIN
				EXECUTE @pRet = [etl].[sp_update_function_finish_control] @function_name_=@pFunctionName
															, @to_fact_table_ = '', @finished_at_=@pEndTime
															, @errnum = @errnum OUTPUT,@errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;
				IF @pRet<>0
					begin
						SET @logtext = N'@ret<>0 [sp_update_function_finish_control] /ret:' ;
						SET @logtext = @logtext + convert(varchar,@pRet) ;
						SET @logtext = @logtext + N'/func:';
						SET @logtext = @logtext + @pFunctionName;
						SET @logtext = @logtext + N'/fin:';
						SET @logtext = @logtext + convert(varchar,@pEndtime,21);
						SET @logtext = @logtext + N'/step:';
						SET @logtext = @logtext + convert(varchar,@pStepNo);
						SET @logtext = @logtext + N'/num:';
						SET @logtext = @logtext + convert(varchar,@errnum);
						SET @logtext = @logtext + N'/line:';
						SET @logtext = @logtext + convert(varchar,@errline);
						SET @logtext = @logtext + N'/msg:';
						SET @logtext = @logtext + convert(varchar,@errmsg);
						PRINT 'logtext=' + @logtext;
						RETURN -1;
					end;

				-- rowcnt=0 then exit
			
				SET @logtext = @pfunctionname ;
				SET @logtext = @logtext + N' has no additional order data(' ;
				SET @logtext = @logtext + convert(varchar,@pEndTime,21);
				SET @logtext = @logtext + N')';
				PRINT 'logtext=' + @logtext;
				RETURN 0;
			END;

		PRINT '-----1-5) count up id in trans.numbers'
		SET @pStepNo = 5;
		EXECUTE @pRet = [etl].[sp_update_numbers] @servername = @ServerName_APCSPro, @databasename = @DatabaseName_APCSPro
												, @schemaname=N'robin', @name=N'assy_orders.id',@count = @pRowCnt
												, @id_used = @pIdBefore OUTPUT, @id_used_new=@pIdAfter OUTPUT
												, @errnum = @errnum OUTPUT, @errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;
		IF @pRet<>0
			begin
				SET @logtext = N'@ret<>0 [sp_update_numbers] /ret:' ;
				SET @logtext = @logtext + convert(varchar,@pRet) ;
				SET @logtext = @logtext + N'/func:';
				SET @logtext = @logtext + @pFunctionName;
				SET @logtext = @logtext + N'/name:assy_orders.id' ;
				SET @logtext = @logtext + N'/count:';
				SET @logtext = @logtext + convert(varchar,@pRowCnt) ;
				SET @logtext = @logtext + N'/step:';
				SET @logtext = @logtext + convert(varchar,@pStepNo);
				SET @logtext = @logtext + N'/num:';
				SET @logtext = @logtext + convert(varchar,@errnum);
				SET @logtext = @logtext + N'/line:';
				SET @logtext = @logtext + convert(varchar,@errline);
				SET @logtext = @logtext + N'/msg:';
				SET @logtext = @logtext + convert(varchar,@errmsg);
				PRINT 'logtext=' + @logtext;
				return -1;
			end;

	END TRY

	BEGIN CATCH

		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = N'[ERR] ';
		SET @logtext = @logtext + @pFunctionName;
		SET @logtext = @logtext + N'/step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/count:'
		SET @logtext = @logtext + convert(varchar,@pRowCnt);
		SET @logtext = @logtext + N'/num:';
		SET @logtext = @logtext + convert(varchar,@errnum);
		SET @logtext = @logtext + N'/line:';
		SET @logtext = @logtext + convert(varchar,@errline);
		SET @logtext = @logtext + N'/msg:';
		SET @logtext = @logtext + convert(varchar,@errmsg);
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;

	BEGIN TRY

		PRINT '-----1-6) dwh.temp_assy_orders ==> robin.assy_orders'
		SET @pStepNo = 6;

		SET @pSqlAssyOrder = N'';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'select ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'id + ' + convert(varchar,@pIdBefore)  ;
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',order_no ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',suffix ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',device_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',assy_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',ft_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',chip_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',package_name ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',rank ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',tp_rank ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',tp_rank_pattern ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',order_category ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',is_updated ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',in_plan_date ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',out_plan_date ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',delivery_plan_date ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',ordered_pcs ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',inputted_pcs ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',process_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',in_post_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',out_post_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',form_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',pin_num_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',item_code ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',order_issue_category ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',is_manual_allocate ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',order_state ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',revised_state ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',revised_out_plan_date ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',report_state ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',to_report ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',manual_register_state ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',is_all_ship ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',is_out_in ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',created_at ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',created_by ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',updated_at ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N',updated_by ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + N'from ';
		SET @pSqlAssyOrder = @pSqlAssyOrder + @pObjAPCSProDWH + N'.[dwh].[temp_assy_orders] o WITH (NOLOCK) ';  

		--PRINT @pSqlAssyOrder;
		BEGIN TRANSACTION

			PRINT '@pSqlInsAssyOrder=' + @pSqlInsAssyOrder;
			PRINT '@pSqlInsAssyOrderCommon=' + @pSqlInsAssyOrderCommon;
			PRINT '@pSqlAssyOrder=' + @pSqlAssyOrder;
			EXECUTE (@pSqlInsAssyOrder + @pSqlInsAssyOrderCommon + @pSqlAssyOrder);

			--SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Insert(assy_orders) OK : row=';
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			print @logtext;

		COMMIT TRANSACTION;

-- Step2 : for Material Allocates front
		BEGIN TRANSACTION

			PRINT '-----2-1) truncate temporary (dwh.temp_material_allocates_front)';
			SET @pStepNo = 11;
			--PRINT @pSqlTruncMatAllocate;
			EXECUTE (@pSqlTruncMatAllocate);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Truncate(temp_material_allocates_front) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----2-2) temporary ==> dwh.temp_material_allocates_front';
			SET @pStepNo = 12;
			PRINT '@pSqlInsMatAllocatetemp=' + @pSqlInsMatAllocatetemp;
			PRINT '@pSqlInsMatAllocateCommon=' + @pSqlInsMatAllocateCommon;
			PRINT '@pSqlMatAllocate=' + @pSqlMatAllocate;
			EXECUTE (@pSqlInsMatAllocatetemp + @pSqlInsMatAllocateCommon + @pSqlMatAllocate);
			--SET @pRowCnt = @@ROWCOUNT;

			PRINT '-----2-3) get row count from temp_material_allocates_front';
			SET @pStepNo = 13;
			SET @pSqlRowCnt = N'';
			SET @pSqlRowCnt = @pSqlRowCnt + N' select @AllocatesCnt = count(*) '
			SET @pSqlRowCnt = @pSqlRowCnt + N' from ' +  @pObjAPCSProDWH + N'.[dwh].[temp_material_allocates_front] with (NOLOCK)'
			EXEC sp_executesql @pSqlRowCnt, N'@AllocatesCnt INT OUTPUT', @AllocatesCnt=@pRowCnt OUTPUT;
			PRINT 'Count=' + convert(varchar,@pRowCnt);
			SET @logtext = 'Insert(temp_material_allocates_front) OK : row=';
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

		COMMIT TRANSACTION;
	
	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT <> 0
			BEGIN
				ROLLBACK TRANSACTION;
			END;

		select @errMsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@ErrLine = ERROR_LINE()

		SET @logtext = N'[ERR] ';
		SET @logtext = @logtext + @pFunctionName;
		SET @logtext = @logtext + N'/step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/count:';
		SET @logtext = @logtext + convert(varchar,@pRowCnt);
		SET @logtext = @logtext + N'/num:';
		SET @logtext = @logtext + convert(varchar,@errnum);
		SET @logtext = @logtext + N'/line:';
		SET @logtext = @logtext + convert(varchar,@errline);
		SET @logtext = @logtext + '/msg:';
		SET @logtext = @logtext + @errmsg;
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;

	BEGIN TRY

		PRINT '-----2-4) Check row counts';
		SET @pStepNo = 14;

		if @pRowCnt = 0
		
			BEGIN
				EXECUTE @pRet = [etl].[sp_update_function_finish_control] @function_name_=@pFunctionName
															, @to_fact_table_ = '', @finished_at_=@pEndTime
															, @errnum = @errnum OUTPUT,@errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;
				IF @pRet<>0
					begin
						SET @logtext = N'@ret<>0 [sp_update_function_finish_control] /ret:' ;
						SET @logtext = @logtext + convert(varchar,@pRet) ;
						SET @logtext = @logtext + N'/func:';
						SET @logtext = @logtext + @pFunctionName;
						SET @logtext = @logtext + N'/fin:';
						SET @logtext = @logtext + convert(varchar,@pEndtime,21);
						SET @logtext = @logtext + N'/step:';
						SET @logtext = @logtext + convert(varchar,@pStepNo);
						SET @logtext = @logtext + N'/num:';
						SET @logtext = @logtext + convert(varchar,@errnum);
						SET @logtext = @logtext + N'/line:';
						SET @logtext = @logtext + convert(varchar,@errline);
						SET @logtext = @logtext + N'/msg:';
						SET @logtext = @logtext + convert(varchar,@errmsg);
						PRINT 'logtext=' + @logtext;
						RETURN -1;
					end;

				-- rowcnt=0 then exit
			
				SET @logtext = @pfunctionname ;
				SET @logtext = @logtext + N' has no additional material allocates data(' ;
				SET @logtext = @logtext + convert(varchar,@pEndTime,21);
				SET @logtext = @logtext + N')';
				PRINT 'logtext=' + @logtext;
				RETURN 0;


			END;


		PRINT '-----2-5) count up id in trans.numbers'
		SET @pStepNo = 15;
		EXECUTE @pRet = [etl].[sp_update_numbers] @servername = @ServerName_APCSPro, @databasename = @DatabaseName_APCSPro
												, @schemaname=N'robin', @name=N'material_allocates_front.id',@count = @pRowCnt
												, @id_used = @pIdBefore OUTPUT, @id_used_new=@pIdAfter OUTPUT
												, @errnum = @errnum OUTPUT, @errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;
		IF @pRet<>0
			begin
				SET @logtext = N'@ret<>0 [sp_update_numbers] /ret:' ;
				SET @logtext = @logtext + convert(varchar,@pRet) ;
				SET @logtext = @logtext + N'/func:';
				SET @logtext = @logtext + @pFunctionName;
				SET @logtext = @logtext + N'/name:material_allocates_front.id' ;
				SET @logtext = @logtext + N'/count:';
				SET @logtext = @logtext + convert(varchar,@pRowCnt) ;
				SET @logtext = @logtext + N'/step:';
				SET @logtext = @logtext + convert(varchar,@pStepNo);
				SET @logtext = @logtext + N'/num:';
				SET @logtext = @logtext + convert(varchar,@errnum);
				SET @logtext = @logtext + N'/line:';
				SET @logtext = @logtext + convert(varchar,@errline);
				SET @logtext = @logtext + N'/msg:';
				SET @logtext = @logtext + convert(varchar,@errmsg);
				PRINT 'logtext=' + @logtext;
				return -1;
			end;

	END TRY

	BEGIN CATCH

		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = N'[ERR] ';
		SET @logtext = @logtext + @pFunctionName;
		SET @logtext = @logtext + N'/step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/count:'
		SET @logtext = @logtext + convert(varchar,@pRowCnt);
		SET @logtext = @logtext + N'/num:';
		SET @logtext = @logtext + convert(varchar,@errnum);
		SET @logtext = @logtext + N'/line:';
		SET @logtext = @logtext + convert(varchar,@errline);
		SET @logtext = @logtext + N'/msg:';
		SET @logtext = @logtext + convert(varchar,@errmsg);
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;

	BEGIN TRY

		PRINT '-----2-6) dwh.temp_material_allocates_front ==> robin.material_allocates_front'
		SET @pStepNo = 16;

		SET @pSqlMatAllocate = N'';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'select ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'id + ' + convert(varchar,@pIdBefore)  ;
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',order_id ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',lot_id ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',allocate_order ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',chip_name ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',material_id ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',wafer_lot_no ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',wafer_no ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',pcs ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',number_of_strip ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',wh_code ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',invoice_no ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',allocate_state ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',report_state ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',to_report ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',created_at ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',created_by ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',updated_at ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N',updated_by ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + N'from ';
		SET @pSqlMatAllocate = @pSqlMatAllocate + @pObjAPCSProDWH + N'.[dwh].[temp_material_allocates_front] o WITH (NOLOCK) ';  

		--PRINT @pSqlMatAllocate;
		BEGIN TRANSACTION

			PRINT '@pSqlInsMatAllocate=' + @pSqlInsMatAllocate;
			PRINT '@pSqlInsMatAllocateCommon=' + @pSqlInsMatAllocateCommon;
			PRINT '@pSqlMatAllocate=' + @pSqlMatAllocate;
			EXECUTE (@pSqlInsMatAllocate + @pSqlInsMatAllocateCommon + @pSqlMatAllocate);

			--SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Insert(material_allocates_front) OK : row=';
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			print @logtext;


		COMMIT TRANSACTION;


	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT <> 0
			BEGIN
				ROLLBACK TRANSACTION;
			END;

		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = N'[ERR] ';
		SET @logtext = @logtext + @pFunctionName;
		SET @logtext = @logtext + N'/step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/num:';
		SET @logtext = @logtext + convert(varchar,@errnum);
		SET @logtext = @logtext + N'/line:';
		SET @logtext = @logtext + convert(varchar,@errline);
		SET @logtext = @logtext + N'/msg:';
		SET @logtext = @logtext + convert(varchar,@errmsg);
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;

-- Step3 : for lot information front

	BEGIN TRY

		PRINT '-----3-1) robin.lot_information_front'
		SET @pStepNo = 21;

		BEGIN TRANSACTION

			PRINT '@pSqlInsLotInfoFront=' + @pSqlInsLotInfoFront;
			PRINT '@pSqlLotInfoFront=' + @pSqlLotInfoFront;
			EXECUTE (@pSqlInsLotInfoFront + @pSqlLotInfoFront);

			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Insert(lot_information_front) OK : row=';
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			print @logtext;


		COMMIT TRANSACTION;


	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT <> 0
			BEGIN
				ROLLBACK TRANSACTION;
			END;

		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = N'[ERR] ';
		SET @logtext = @logtext + @pFunctionName;
		SET @logtext = @logtext + N'/step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/num:';
		SET @logtext = @logtext + convert(varchar,@errnum);
		SET @logtext = @logtext + N'/line:';
		SET @logtext = @logtext + convert(varchar,@errline);
		SET @logtext = @logtext + N'/msg:';
		SET @logtext = @logtext + convert(varchar,@errmsg);
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;

-- Step4 : for lot information front

 	BEGIN TRY

		BEGIN TRANSACTION;

			PRINT '-----4-1) update(trans.lots)';
			SET @pStepNo = 31;
			--PRINT (@pSqlUpdateLots);
			EXECUTE (@pSqlUpdateLots);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Update(order lots) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----4-2) save the process log';
			SET @pStepNo = 32;
			--PRINT '@functionname=' + @functionname + ' / ' +  '@FromTime=' + format(@FromTime,'yyyy/MM/dd HH:mm:ss.ff3') + ' / ' +  '@ToTime=' + format(@ToTime,'yyyy/MM/dd HH:mm:ss.ff3');
			EXECUTE @pRet = [etl].[sp_update_function_finish_control] @function_name_=@pFunctionName
												, @to_fact_table_ = '', @finished_at_=@pEndTime
												, @errnum = @errnum OUTPUT,@errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;

			IF @pRet<>0
				begin
					IF @@TRANCOUNT <> 0
					BEGIN
						ROLLBACK TRANSACTION;
					END;

					SET @logtext = N'@ret<>0 [sp_update_function_finish_control] /ret:' ;
					SET @logtext = @logtext + convert(varchar,@pRet) ;
					SET @logtext = @logtext + N'/func:';
					SET @logtext = @logtext + @pFunctionName;
					SET @logtext = @logtext + N'/fin:';
					SET @logtext = @logtext + convert(varchar,@pEndtime,21);
					SET @logtext = @logtext + N'/step:';
					SET @logtext = @logtext + convert(varchar,@pStepNo);
					SET @logtext = @logtext + N'/num:';
					SET @logtext = @logtext + convert(varchar,@errnum);
					SET @logtext = @logtext + N'/line:';
					SET @logtext = @logtext + convert(varchar,@errline);
					SET @logtext = @logtext + N'/msg:';
					SET @logtext = @logtext + convert(varchar,@errmsg);
					PRINT 'logtext=' + @logtext;
					RETURN -1;

				END;

		COMMIT TRANSACTION;
	
	END TRY

	BEGIN CATCH
	
		IF @@TRANCOUNT <> 0
			BEGIN
				ROLLBACK TRANSACTION;
			END;

		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = N'[ERR] ';
		SET @logtext = @logtext + @pFunctionName;
		SET @logtext = @logtext + N'/step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/count:';
		SET @logtext = @logtext + convert(varchar,@pRowCnt);
		SET @logtext = @logtext + N'/num:';
		SET @logtext = @logtext + convert(varchar,@errnum);
		SET @logtext = @logtext + N'/line:';
		SET @logtext = @logtext + convert(varchar,@errline);
		SET @logtext = @logtext + '/msg:';
		SET @logtext = @logtext + @errmsg;
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;

	RETURN 0;

END ;

