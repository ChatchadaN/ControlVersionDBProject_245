
-- =============================================
-- Author:		<M.Yamamoto>
-- Create date: <12th Oct 2018>
-- Description:	<LOT1_TABLE to Lots>
-- =============================================
CREATE PROCEDURE [etl].[sp_apcs_01_insert_lots] (
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
	/*DECLARE @pInputTime varchar(max);*/

	DECLARE @pRet INT = 0;
	DECLARE @pStepNo INT = 0; 

	DECLARE @pSqlTrunc NVARCHAR(4000) = N'';
	DECLARE @pSqlInsTo1 NVARCHAR(4000) = N'';
	DECLARE @pSqlInsTo2 NVARCHAR(4000) = N'';
	DECLARE @pSqlIns NVARCHAR(4000) = N'';
	DECLARE @pSqlSelect NVARCHAR(4000) = N'';
	DECLARE @pSqlRowCnt NVARCHAR(4000) = N'';

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
	/* v10 change
		SELECT @pFunctionName = OBJECT_NAME(@@PROCID);
		SELECT @pStarttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000')) FROM [APCSProDWH].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
		PRINT '@starttime=' + CASE WHEN @pStarttime IS NULL THEN '' ELSE FORMAT(@pStarttime, 'yyyy-MM-dd HH:mm:ss.fff') END;
		--yyyy/MM/dd HH:mm:ss.ff3
		SELECT @pInputTime = FORMAT(dateadd(hour,-1,GETDATE()), 'yyyy-MM-dd HH:00:00.000');
		SELECT @pEndTime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'));
		PRINT '@endtime=' + FORMAT(@pEndtime, 'yyyy-MM-dd HH:mm:ss.fff');
	*/
		SELECT @pFunctionName = OBJECT_NAME(@@PROCID);
		SELECT @pStarttime = dateadd(minute,(-1)*(DATEPART(n,finished_at) % 10),convert(datetime,format(finished_at,'yyyy-MM-dd HH:mm:00.000'))) FROM [APCSProDWH].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
		PRINT '@starttime=' + CASE WHEN @pStarttime IS NULL THEN '' ELSE FORMAT(@pStarttime, 'yyyy-MM-dd HH:mm:ss.fff') END;
		--yyyy/MM/dd HH:mm:ss.ff3
		/*SELECT @pInputTime = dateadd(HOUR,-1,dateadd(minute,(-1)*(DATEPART(n,GETDATE()) % 10),convert(datetime,format(GETDATE(),'yyyy-MM-dd HH:mm:00.000'))));*/
		SELECT @pEndTime = dateadd(minute,(-1)*(DATEPART(n,GETDATE()) % 10),convert(datetime,format(GETDATE(),'yyyy-MM-dd HH:mm:00.000')));
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
	SET @pSqlTrunc = N'';
	SET @pSqlTrunc = @pSqlTrunc + N'truncate table ' + @pObjAPCSProDWH + N'.[dwh].[temp_lots] ';
	--PRINT '@pSqlTrunc=' + @pSqlTrunc;

	-- insert into **  
	SET @pSqlInsTo1 = N'';
	SET @pSqlInsTo1 = @pSqlInsTo1 + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[temp_lots] ';
	--PRINT '@pSqlInsTo1=' + @pSqlInsTo1;

	SET @pSqlInsTo2 = N'';
	SET @pSqlInsTo2 = @pSqlInsTo2 + N'insert into ' + @pObjAPCSPro + N'.[trans].[lots] ';
	--PRINT '@pSqlInsTo2=' + @pSqlInsTo2;

	--@pSqlIns
	BEGIN
		SET @pSqlIns = N'';
		SET @psqlIns = @psqlIns + N'(id ';
		SET @psqlIns = @psqlIns + N',lot_no ';
		SET @psqlIns = @psqlIns + N',product_family_id ';
		SET @psqlIns = @psqlIns + N',act_package_id ';
		SET @psqlIns = @psqlIns + N',act_device_name_id ';
		SET @psqlIns = @psqlIns + N',device_slip_id ';
		SET @psqlIns = @psqlIns + N',order_id ';
		SET @psqlIns = @psqlIns + N',step_no ';
		SET @psqlIns = @psqlIns + N',act_process_id ';
		SET @psqlIns = @psqlIns + N',act_job_id ';
		SET @psqlIns = @psqlIns + N',qty_in ';
		SET @psqlIns = @psqlIns + N',qty_pass ';
		SET @psqlIns = @psqlIns + N',qty_fail ';
		SET @psqlIns = @psqlIns + N',qty_last_pass ';
		SET @psqlIns = @psqlIns + N',qty_last_fail ';
		SET @psqlIns = @psqlIns + N',qty_pass_step_sum ';
		SET @psqlIns = @psqlIns + N',qty_fail_step_sum ';
		SET @psqlIns = @psqlIns + N',qty_divided ';
		SET @psqlIns = @psqlIns + N',qty_hasuu ';
		SET @psqlIns = @psqlIns + N',qty_out ';
		SET @psqlIns = @psqlIns + N',is_exist_work ';
		SET @psqlIns = @psqlIns + N',in_plan_date_id ';
		SET @psqlIns = @psqlIns + N',out_plan_date_id ';
		SET @psqlIns = @psqlIns + N',master_lot_id ';
		SET @psqlIns = @psqlIns + N',depth ';
		SET @psqlIns = @psqlIns + N',sequence ';
		SET @psqlIns = @psqlIns + N',wip_state ';
		SET @psqlIns = @psqlIns + N',process_state ';
		SET @psqlIns = @psqlIns + N',quality_state ';
		SET @psqlIns = @psqlIns + N',first_ins_state ';
		SET @psqlIns = @psqlIns + N',final_ins_state ';
		SET @psqlIns = @psqlIns + N',is_special_flow ';
		SET @psqlIns = @psqlIns + N',special_flow_id ';
		SET @psqlIns = @psqlIns + N',is_temp_devided ';
		SET @psqlIns = @psqlIns + N',temp_devided_count ';
		SET @psqlIns = @psqlIns + N',product_class_id ';
		SET @psqlIns = @psqlIns + N',priority ';
		SET @psqlIns = @psqlIns + N',finish_date_id ';
		SET @psqlIns = @psqlIns + N',finished_at ';
		SET @psqlIns = @psqlIns + N',in_date_id ';
		SET @psqlIns = @psqlIns + N',in_at ';
		SET @psqlIns = @psqlIns + N',ship_date_id ';
		SET @psqlIns = @psqlIns + N',ship_at ';
		SET @psqlIns = @psqlIns + N',modify_out_plan_date_id ';
		SET @psqlIns = @psqlIns + N',modified_at ';
		SET @psqlIns = @psqlIns + N',modified_by ';
		SET @psqlIns = @psqlIns + N',location_id ';
		SET @psqlIns = @psqlIns + N',acc_location_id ';
		SET @psqlIns = @psqlIns + N',machine_id ';
		SET @psqlIns = @psqlIns + N',container_no ';
		SET @psqlIns = @psqlIns + N',std_time_sum ';
		SET @psqlIns = @psqlIns + N',start_step_no ';
		SET @psqlIns = @psqlIns + N',m_no ';
		SET @psqlIns = @psqlIns + N',qc_comment_id ';
		SET @psqlIns = @psqlIns + N',qc_memo_id ';
		SET @psqlIns = @psqlIns + N',pass_plan_time ';
		SET @psqlIns = @psqlIns + N',pass_plan_time_up ';
		SET @psqlIns = @psqlIns + N',process_job_id ';	
		SET @psqlIns = @psqlIns + N',origin_material_id ';
		SET @psqlIns = @psqlIns + N',carried_at ';
		SET @psqlIns = @psqlIns + N',is_imported ';
		SET @psqlIns = @psqlIns + N',created_at ';
		SET @psqlIns = @psqlIns + N',created_by ';
		SET @psqlIns = @psqlIns + N',updated_at ';
		SET @psqlIns = @psqlIns + N',updated_by ';
		SET @psqlIns = @psqlIns + N') ';
	END;
	--PRINT '@pSqlIns=' + @pSqlIns;

	-- insert into ** select ** 
	BEGIN
		SET @pSqlSelect = N'';
		SET @pSqlSelect = @pSqlSelect + N'select ';
		SET @pSqlSelect = @pSqlSelect + N'ROW_NUMBER() over( order by lot.lot_no) as id ';
		SET @pSqlSelect = @pSqlSelect + N',lot.LOT_NO ';
		SET @pSqlSelect = @pSqlSelect + N',case when v1.product_family_id is not null then v1.product_family_id ';
		SET @pSqlSelect = @pSqlSelect + N' else v2.product_family_id ';
		SET @pSqlSelect = @pSqlSelect + N'		end as product_family_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,case when v1.package_id is not null then v1.package_id ';
		SET @pSqlSelect = @pSqlSelect + N'		else v2.package_id ';
		SET @pSqlSelect = @pSqlSelect + N'		end as act_package_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,case when v1.device_name_id is not null then v1.device_name_id ';
		SET @pSqlSelect = @pSqlSelect + N'		else v2.device_name_id ';
		SET @pSqlSelect = @pSqlSelect + N'		end as act_device_name_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,case when v1.device_slip_id is not null then v1.device_slip_id ';
		SET @pSqlSelect = @pSqlSelect + N'		else v2.device_slip_id ';
		SET @pSqlSelect = @pSqlSelect + N'		end as device_slip_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,null as order_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,100 as step_no '; --temporary
		SET @pSqlSelect = @pSqlSelect + N'	,case when v1.device_slip_id is not null then v1.process_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	else v2.process_id end as act_process_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,case when v1.device_slip_id is not null then v1.job_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	else v2.job_id end as act_job_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,lot.PRD_PIECE as qty_in ';
		SET @pSqlSelect = @pSqlSelect + N'	,lot.PRD_PIECE as qty_pass ';
		SET @pSqlSelect = @pSqlSelect + N'	,0 As qty_fail ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As qty_last_pass ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As qty_last_fail ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As qty_pass_step_sum '; 
		SET @pSqlSelect = @pSqlSelect + N'	,null As qty_fail_step_sum ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As qty_divided ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As qty_hasuu ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As qty_out ';
		SET @pSqlSelect = @pSqlSelect + N'	,0 As is_exist_work '; 
		SET @pSqlSelect = @pSqlSelect + N'	,in_day.id As in_plan_date_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,out_day.id As out_plan_date_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,0 As master_lot_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,0 As depth ';
		SET @pSqlSelect = @pSqlSelect + N'	,0 As sequence '; 
		--Change start 23.May.2019 for DC
		--SET @pSqlSelect = @pSqlSelect + N'	,20 As wip_state ';
		SET @pSqlSelect = @pSqlSelect + N'	,0 As wip_state ';
		--Change end 23.May.2019 for DC
		SET @pSqlSelect = @pSqlSelect + N'	,0 As process_state '; 
		SET @pSqlSelect = @pSqlSelect + N'	,0 As quality_state ';
		SET @pSqlSelect = @pSqlSelect + N'	,0 As first_ins_state ';
		SET @pSqlSelect = @pSqlSelect + N'	,0 As final_ins_state ';
		SET @pSqlSelect = @pSqlSelect + N'	,0 As is_special_flow ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As special_flow_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,0 As is_temp_devided ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As temp_devided_count ';
		SET @pSqlSelect = @pSqlSelect + N'	,case when v1.device_type is not null then v1.device_type ';
		SET @pSqlSelect = @pSqlSelect + N'		else v2.device_type end As product_class_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,50 As priority ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As finish_date_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As finished_at ';
		SET @pSqlSelect = @pSqlSelect + N'	,in_day.id As in_date_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,lot.IN_DAY As in_at ';
		--SET @pSqlSelect = @pSqlSelect + N'	,''' + @pInputTime + ''' As in_at ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As ship_date_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As ship_at ';
		SET @pSqlSelect = @pSqlSelect + N'	,out_day.id As modify_out_plan_date_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As modified_at ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As modified_by ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As location_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,null As acc_location_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,null As machine_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As container_no ';
		SET @pSqlSelect = @pSqlSelect + N'	,null As std_time_sum '; 
		SET @pSqlSelect = @pSqlSelect + N'	,100 as start_step_no '; --temporary
		SET @pSqlSelect = @pSqlSelect + N'	,null As m_no '; 
		SET @pSqlSelect = @pSqlSelect + N'	,null As qc_comment_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,null As qc_memo_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,null As pass_plan_time '; 
		SET @pSqlSelect = @pSqlSelect + N'	,null As pass_plan_time_up '; 
		SET @pSqlSelect = @pSqlSelect + N'	,null As process_job_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,null As origin_material_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,null As carried_at '; 
		SET @pSqlSelect = @pSqlSelect + N'	,1 As is_imported '; -- for APCS
		SET @pSqlSelect = @pSqlSelect + N'	,lot.IN_DAY As created_at '; 
		SET @pSqlSelect = @pSqlSelect + N'	,null As created_by '; 
		SET @pSqlSelect = @pSqlSelect + N'	,lot.CREATION_DATE As updated_at '; 
		SET @pSqlSelect = @pSqlSelect + N'	,null As updated_by '; 
		SET @pSqlSelect = @pSqlSelect + N'from ';
		SET @pSqlSelect = @pSqlSelect + N'(select ';
		SET @pSqlSelect = @pSqlSelect + N'	t0.* ';
		SET @pSqlSelect = @pSqlSelect + N'	from ';
		SET @pSqlSelect = @pSqlSelect + N'		(select ';
		SET @pSqlSelect = @pSqlSelect + N'			lt1.lot_no ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.PRD_NAME ';
		SET @pSqlSelect = @pSqlSelect + N'			,convert(date,''20''+ lt1.IN_DAY) IN_DAY ';
		SET @pSqlSelect = @pSqlSelect + N'			,convert(date,''20'' + lt1.out_day) OUT_DAY ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.ope_seq ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.PRD_PIECE ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.REAL_DAY ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.MATER_NAME ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.MATER_SNAME ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.Y_LEVEL ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.STATUS1 ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.STATUS2 ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.REAL_start ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.ROHM_ORDER_MODEL_NAME_O ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.ORDER_NO ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.FT_MODEL_NAME ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.TP_RANK ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.WARI_STOCK_KBN ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.WARI_INSTRUCT_KBN ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.FORM_NAME ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.GOOD_PIECES ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.BAD_PIECES ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.CREATION_DATE ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.SEND_FLG ';
		SET @pSqlSelect = @pSqlSelect + N'			,lt1.SEND_DATE ';
		SET @pSqlSelect = @pSqlSelect + N'			,lots.lot_no lot_check ';
		SET @pSqlSelect = @pSqlSelect + N'		from ';
		SET @pSqlSelect = @pSqlSelect + N'			OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ServerName_APCS + ';UID=dbxuser;'').[' + @DatabaseName_APCS + '].[dbo].[LOT1_TABLE] as lt1 ';
		SET @pSqlSelect = @pSqlSelect + N'				left join ' + @pObjAPCSPro + N'.[trans].[lots] lots with (NOLOCK) '; 
		SET @pSqlSelect = @pSqlSelect + N'					on lt1.LOT_NO = lots.lot_no ';
		SET @pSqlSelect = @pSqlSelect + N'		) t0 ';
		SET @pSqlSelect = @pSqlSelect + N'	where ';
		SET @pSqlSelect = @pSqlSelect + N'		t0.lot_check is null ';
		SET @pSqlSelect = @pSqlSelect + N') lot '; 
		SET @pSqlSelect = @pSqlSelect + N'left outer join ' + @pObjAPCSPro + N'.[method].[view_las_data_apcs] v1 with (NOLOCK) ';
		SET @pSqlSelect = @pSqlSelect + N'	on lot.ROHM_ORDER_MODEL_NAME_O = v1.device_name ';
		SET @pSqlSelect = @pSqlSelect + N'		and lot.PRD_NAME = v1.assy_name ';
		SET @pSqlSelect = @pSqlSelect + N'		and lot.FT_MODEL_NAME = v1.ft_name ';
		SET @pSqlSelect = @pSqlSelect + N'		and v1.is_assy_only = 0 ';
		SET @pSqlSelect = @pSqlSelect + N'left outer join ' + @pObjAPCSPro + N'.[method].[view_las_data_apcs] v2 with (NOLOCK) ';
		SET @pSqlSelect = @pSqlSelect + N'	on ((lot.PRD_NAME = v2.device_name) or (v2.device_name like ''%FX'')) ';
		SET @pSqlSelect = @pSqlSelect + N'		and lot.prd_name = v2.assy_name ';
		SET @pSqlSelect = @pSqlSelect + N'		and v2.is_assy_only <> 0 ';
		SET @pSqlSelect = @pSqlSelect + N'left join ' + @pObjAPCSPro + N'.[trans].[days] in_day with (NOLOCK) ';
		SET @pSqlSelect = @pSqlSelect + N'		on lot.IN_DAY = in_day.date_value ';
		SET @pSqlSelect = @pSqlSelect + N'left join ' + @pObjAPCSPro + N'.[trans].[days] out_day with (NOLOCK) ';
		SET @pSqlSelect = @pSqlSelect + N'		on lot.out_DAY = out_day.date_value ';
		SET @pSqlSelect = @pSqlSelect + N'where ';
		SET @pSqlSelect = @pSqlSelect + N'	(v1.device_slip_id is not null or v2.device_slip_id is not null) ';
	END;
	PRINT '@pSqlSelect=' + @pSqlSelect;

   ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------
	BEGIN TRY

		BEGIN TRANSACTION;
			
			PRINT '-----1) truncate temporary (dwh.temp_lots)';
			SET @pStepNo = 1;
			--print (@@pSqlTrunc);
			EXECUTE (@pSqlTrunc);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Truncate(temp_lots) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----2) temporary ==> dwh.temp_lots';
			SET @pStepNo = 2;
			PRINT '@pSqlInsTo1=' + @pSqlInsTo1;
			PRINT '@pSqlIns=' + @pSqlIns;
			PRINT '@pSqlSelect=' + @pSqlSelect;
			EXECUTE (@pSqlInsTo1 + @pSqlIns + @pSqlSelect);
			--SET @pRowCnt = @@ROWCOUNT;
			PRINT '-----3) get row count from temp_lots';
			SET @pStepNo = 3;
			SET @pSqlRowCnt = N'';
			SET @pSqlRowCnt = @pSqlRowCnt + N' select @LotsCnt = count(*) '
			SET @pSqlRowCnt = @pSqlRowCnt + N' from ' +  @pObjAPCSProDWH + N'.[dwh].[temp_lots] with (NOLOCK)'
			EXEC sp_executesql @pSqlRowCnt, N'@LotsCnt INT OUTPUT', @LotsCnt=@pRowCnt OUTPUT;
			PRINT 'Count=' + convert(varchar,@pRowCnt);
			SET @logtext = 'Insert(temp_lots) OK : row=';
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

		PRINT '-----4) Check row counts';
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
				SET @logtext = @logtext + N' has no additional lot data(' ;
				SET @logtext = @logtext + convert(varchar,@pEndTime,21);
				SET @logtext = @logtext + N')';
				PRINT 'logtext=' + @logtext;
				RETURN 0;


			END;


		PRINT '-----5) count up id in trans.numbers'
		SET @pStepNo = 5;
		EXECUTE @pRet = [etl].[sp_update_numbers] @servername = @ServerName_APCSPro, @databasename = @DatabaseName_APCSPro
												, @schemaname=N'trans', @name=N'lots.id',@count = @pRowCnt
												, @id_used = @pIdBefore OUTPUT, @id_used_new=@pIdAfter OUTPUT
												, @errnum = @errnum OUTPUT, @errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;
		IF @pRet<>0
			begin
				SET @logtext = N'@ret<>0 [sp_update_numbers] /ret:' ;
				SET @logtext = @logtext + convert(varchar,@pRet) ;
				SET @logtext = @logtext + N'/func:';
				SET @logtext = @logtext + @pFunctionName;
				SET @logtext = @logtext + N'/name:lots.id' ;
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

		PRINT '-----6) dwh.temp_lots ==> trans.lots'
		SET @pStepNo = 6;

		SET @pSqlSelect = N'';
		SET @pSqlSelect = @pSqlSelect + N'select ';
		SET @pSqlSelect = @pSqlSelect + N'id + ' + convert(varchar,@pIdBefore)  ;
		SET @pSqlSelect = @pSqlSelect + N',lot_no ';
		SET @pSqlSelect = @pSqlSelect + N',product_family_id ';
		SET @pSqlSelect = @pSqlSelect + N',act_package_id ';
		SET @pSqlSelect = @pSqlSelect + N',act_device_name_id ';
		SET @pSqlSelect = @pSqlSelect + N',device_slip_id ';
		SET @pSqlSelect = @pSqlSelect + N',order_id ';
		SET @pSqlSelect = @pSqlSelect + N',step_no '; 
		SET @pSqlSelect = @pSqlSelect + N',act_process_id '; 
		SET @pSqlSelect = @pSqlSelect + N',act_job_id ';
		SET @pSqlSelect = @pSqlSelect + N',qty_in ';
		SET @pSqlSelect = @pSqlSelect + N',qty_pass ';
		SET @pSqlSelect = @pSqlSelect + N',qty_fail ';
		SET @pSqlSelect = @pSqlSelect + N',qty_last_pass ';
		SET @pSqlSelect = @pSqlSelect + N',qty_last_fail ';
		SET @pSqlSelect = @pSqlSelect + N',qty_pass_step_sum '; 
		SET @pSqlSelect = @pSqlSelect + N',qty_fail_step_sum ';
		SET @pSqlSelect = @pSqlSelect + N',qty_divided ';
		SET @pSqlSelect = @pSqlSelect + N',qty_hasuu ';
		SET @pSqlSelect = @pSqlSelect + N',qty_out ';
		SET @pSqlSelect = @pSqlSelect + N',is_exist_work '; 
		SET @pSqlSelect = @pSqlSelect + N',in_plan_date_id ';
		SET @pSqlSelect = @pSqlSelect + N',out_plan_date_id ';
		SET @pSqlSelect = @pSqlSelect + N',master_lot_id ';
		SET @pSqlSelect = @pSqlSelect + N',depth ';
		SET @pSqlSelect = @pSqlSelect + N',sequence '; 
		SET @pSqlSelect = @pSqlSelect + N',wip_state ';
		SET @pSqlSelect = @pSqlSelect + N',process_state '; 
		SET @pSqlSelect = @pSqlSelect + N',quality_state ';
		SET @pSqlSelect = @pSqlSelect + N',first_ins_state ';
		SET @pSqlSelect = @pSqlSelect + N',final_ins_state ';
		SET @pSqlSelect = @pSqlSelect + N',is_special_flow ';
		SET @pSqlSelect = @pSqlSelect + N',special_flow_id ';
		SET @pSqlSelect = @pSqlSelect + N',is_temp_devided ';
		SET @pSqlSelect = @pSqlSelect + N',temp_devided_count ';
		SET @pSqlSelect = @pSqlSelect + N',product_class_id ';
		SET @pSqlSelect = @pSqlSelect + N',priority ';
		SET @pSqlSelect = @pSqlSelect + N',finish_date_id ';
		SET @pSqlSelect = @pSqlSelect + N',finished_at ';
		SET @pSqlSelect = @pSqlSelect + N',in_date_id ';
		SET @pSqlSelect = @pSqlSelect + N',in_at ';
		SET @pSqlSelect = @pSqlSelect + N',ship_date_id ';
		SET @pSqlSelect = @pSqlSelect + N',ship_at ';
		SET @pSqlSelect = @pSqlSelect + N',modify_out_plan_date_id ';
		SET @pSqlSelect = @pSqlSelect + N',modified_at ';
		SET @pSqlSelect = @pSqlSelect + N',modified_by ';
		SET @pSqlSelect = @pSqlSelect + N',location_id '; 
		SET @pSqlSelect = @pSqlSelect + N',acc_location_id '; 
		SET @pSqlSelect = @pSqlSelect + N',machine_id ';
		SET @pSqlSelect = @pSqlSelect + N',container_no ';
		SET @pSqlSelect = @pSqlSelect + N',std_time_sum '; 
		SET @pSqlSelect = @pSqlSelect + N',start_step_no '; --temporary
		SET @pSqlSelect = @pSqlSelect + N',m_no '; 
		SET @pSqlSelect = @pSqlSelect + N',qc_comment_id '; 
		SET @pSqlSelect = @pSqlSelect + N',qc_memo_id '; 
		SET @pSqlSelect = @pSqlSelect + N',pass_plan_time '; 
		SET @pSqlSelect = @pSqlSelect + N',pass_plan_time_up '; 
		SET @pSqlSelect = @pSqlSelect + N',process_job_id '; 
		SET @pSqlSelect = @pSqlSelect + N',origin_material_id '; 
		SET @pSqlSelect = @pSqlSelect + N',carried_at '; 
		SET @pSqlSelect = @pSqlSelect + N',is_imported '; -- for APCS
		SET @pSqlSelect = @pSqlSelect + N',created_at '; 
		SET @pSqlSelect = @pSqlSelect + N',created_by '; 
		SET @pSqlSelect = @pSqlSelect + N',updated_at '; 
		SET @pSqlSelect = @pSqlSelect + N',updated_by '; 
		SET @pSqlSelect = @pSqlSelect + N'from ';
		SET @pSqlSelect = @pSqlSelect + @pObjAPCSProDWH + N'.[dwh].[temp_lots] lt WITH (NOLOCK) ';  

		--PRINT @pSqlSelect;
		BEGIN TRANSACTION

			EXECUTE (@pSqlInsTo2 + @pSqlIns + @pSqlSelect);
			--SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Insert(Lots) OK : row=';
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			print @logtext;

			PRINT '-----7) save the process log'
			SET @pStepNo = 7;
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
					return -1;

				end;

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


RETURN 0;

END ;

