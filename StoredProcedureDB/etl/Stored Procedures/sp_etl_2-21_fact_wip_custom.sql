

-- =============================================
-- Author:		<M.Yamamoto>
-- Create date: <26th Apr 2019>
-- Description:	<LOT1_TABLE to fact_wip_custom for Dicing>
-- =============================================
CREATE PROCEDURE [etl].[sp_etl_2-21_fact_wip_custom] (
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
	DECLARE @pObjAPCSPro NVARCHAR(128) = N'APCSProDB'
	DECLARE @pObjAPCSProDWH NVARCHAR(128) = N''

	DECLARE @pFunctionName NVARCHAR(128) = N'';
	DECLARE @pStarttime DATETIME;
	DECLARE @pEndTime DATETIME;
	DECLARE @pInputTime varchar(max);

	DECLARE @pRet INT = 0;
	DECLARE @pStepNo INT = 0; 

	DECLARE @pSqlIns NVARCHAR(4000) = N'';
	DECLARE @pSqlSelect1 NVARCHAR(4000) = N'';
	DECLARE @pSqlSelect2 NVARCHAR(4000) = N'';
	DECLARE @pSqlRowCnt NVARCHAR(4000) = N'';

	DECLARE @pRowCnt INT = 0;
	--DECLARE @pIdBefore INT=0;
	--DECLARE @pIdAfter INT=0;
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
		SELECT @pStarttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000')) FROM [APCSProDWH].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
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

	-- insert into **  

	BEGIN
		SET @pSqlIns = N'';
		SET @pSqlIns = @pSqlIns + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[fact_wip_custom] ';
		SET @psqlIns = @psqlIns + N'(day_id ';
		SET @psqlIns = @psqlIns + N',hour_code ';
		SET @psqlIns = @psqlIns + N',package_group_id ';
		SET @psqlIns = @psqlIns + N',package_id ';
		SET @psqlIns = @psqlIns + N',device_id ';
		SET @psqlIns = @psqlIns + N',assy_name_id ';
		SET @psqlIns = @psqlIns + N',factory_id ';
		SET @psqlIns = @psqlIns + N',product_family_id ';
		SET @psqlIns = @psqlIns + N',location_id ';
		SET @psqlIns = @psqlIns + N',process_id ';
		SET @psqlIns = @psqlIns + N',job_id ';
		SET @psqlIns = @psqlIns + N',delay_state_code ';
		SET @psqlIns = @psqlIns + N',process_state_code ';
		SET @psqlIns = @psqlIns + N',qc_state_code ';
		SET @psqlIns = @psqlIns + N',long_time_state_code ';
		SET @psqlIns = @psqlIns + N',lot_count ';
		SET @psqlIns = @psqlIns + N',pcs ';
		SET @psqlIns = @psqlIns + N',original_process_id ';
		SET @psqlIns = @psqlIns + N',original_job_id ';
		SET @psqlIns = @psqlIns + N',production_category ';
		SET @psqlIns = @psqlIns + N',process_class ';
		SET @psqlIns = @psqlIns + N') ';
	END;

	-- insert into ** select ** 
	BEGIN
		SET @pSqlSelect1 = N'';
		SET @pSqlSelect1 = @pSqlSelect1 + N'select ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	t.day_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.hour_code ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.package_group_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.package_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.device_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.assy_name_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.factory_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.product_family_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.location_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.process_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.job_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.delay_state_code ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.process_state_code ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.qc_state_code ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.long_time_state_code ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,sum(t.lot_count) as lot_count ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,sum(pcs) as pcs ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.original_process_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.original_job_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.production_category ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	,t.process_class ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'from ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'	( ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'		select ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			dim_days.id as day_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,dim_hours.code as hour_code ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,dwh_pkg.package_group_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,l.act_package_id as package_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,dwh_dev.id as device_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,dwh_assy.id as assy_name_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,prd.factory_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,l.product_family_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,NULL as location_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,pj.process_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,pj.job_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,0 as delay_state_code ';
		--SET @pSqlSelect1 = @pSqlSelect1 + N'			,L1.status1 as process_state_code ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,case when L1.status1 = 0 then 0 else 2 end as process_state_code ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,l.quality_state as qc_state_code ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,case when l1.status1 = 0 then ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'					case when datediff(day,in_day.date_value, ''' + convert(varchar,@pEndTime) + N''') > convert(int,config_long_time.val) then 1 ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'					else 0 end ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'				else 0 end as long_time_state_code ';		
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,l.act_process_id as original_process_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,l.act_job_id as original_job_id ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,1 as lot_count ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,l1.prd_piece pcs ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,null as process_class ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'			,case substring(rtrim(l.lot_no),5,1) ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'					when ''A'' then 0 when ''V'' then 1 when ''W'' then 2 when ''X'' then 3 when ''Y'' then 4 ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'					when ''B'' then 10 when ''Q'' then 11 when ''R'' then 12 when ''S'' then 13 when ''T'' then 14 ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'					when ''D'' then 20 ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'					when ''E'' then 30 when ''5'' then 31 when ''6'' then 32 when ''7'' then 33 when ''8'' then 34 ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'					when ''F'' then 40 when ''K'' then 41 when ''L'' then 42 when ''M'' then 43 when ''N'' then 44 ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'					when ''G'' then 50 when ''0'' then 51 when ''1'' then 52 when ''2'' then 53 when ''3'' then 54 ';
		SET @pSqlSelect1 = @pSqlSelect1 + N'					when ''H'' then 60 when ''P'' then 61 when ''U'' then 62 when ''Z'' then 63 when ''4'' then 64 else 0 end as production_category ';

		SET @pSqlSelect1 = @pSqlSelect1 + N'		from ';

		SET @pSqlSelect2 = N'';
		SET @pSqlSelect2 = @pSqlSelect2 + N'			OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ServerName_APCS + N';UID=dbxuser;'').[' + @DatabaseName_APCS + N'].[dbo].[LOT1_TABLE] as L1 ';
		--SET @pSqlSelect2 = @pSqlSelect2 + N'			' + @pobjapcs + N'.[dbo].[LOT1_TABLE] as L1 ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ServerName_APCS + N';UID=dbxuser;'').[' + @DatabaseName_APCS + N'].[dbo].[LOT1_DATA] as L2 ';
		--SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pObjAPCS + N'.[dbo].[LOT1_DATA] as L2 ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on L1.lot_no = L2.[LOT_NO] and L1.[OPE_SEQ] = L2.[OPE_SEQ] ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ServerName_APCS + N';UID=dbxuser;'').[' + @DatabaseName_APCS + N'].[dbo].[LAYER_TABLE] as L3 ';
		--SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pObjAPCS + N'.[dbo].[LAYER_TABLE] as L3 ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on L3.[LAY_NO] = L2.[LAY_NO] ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ServerName_APCS + N';UID=dbxuser;'').[' + @DatabaseName_APCS + N'].[dbo].[LOT1_DATA] as L2_2 ';
		--SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pobjAPCS + N'.[dbo].[LOT1_DATA] as L2_2 ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on L1.lot_no = L2_2.[LOT_NO] and L2_2.[OPE_SEQ] = L1.[OPE_SEQ] + 1 ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ServerName_APCS + N';UID=dbxuser;'').[' + @DatabaseName_APCS + N'].[dbo].[LAYER_TABLE] as L3_2 ';
		--SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pObjAPCS + N'.[dbo].[LAYER_TABLE] as L3_2 ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on L3_2.[LAY_NO] = L2_2.[LAY_NO] ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pObjAPCSPro +N'.[trans].[lots] as l with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on l.lot_no = l1.lot_no ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'						and l.wip_state = 20 ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pObjAPCSProDWH + N'.[dwh].[dim_package_jobs] as pj with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on pj.job_no = l3.lay_no ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'						and pj.package_id = l.act_package_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'						and pj.is_additional_jobs = 1 ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pObjAPCSPro + N'.[method].[device_flows] as f2 with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on f2.device_slip_id = l.device_slip_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'						and f2.step_no >= l.step_no ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pObjAPCSPro + N'.[method].[jobs] as j2 with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on j2.id = f2.job_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'						and j2.job_no = l3_2.lay_no ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pObjAPCSPro + N'.[man].[product_families] as prd with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on prd.id = l.product_family_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pObjAPCSPro + N'.[method].[device_names] as dev with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on dev.id = l.act_device_name_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'						and dev.is_assy_only in (0,1) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pObjAPCSProDWH + N'.[dwh].[dim_packages] as dwh_pkg with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on dwh_pkg.id = l.act_package_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pObjAPCSProDWH + N'.[dwh].[dim_devices] as dwh_dev with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on dwh_dev.id = dev.id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				inner join ' + @pObjAPCSProDWH + N'.[dwh].[dim_assy_device_names] as dwh_assy with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on dwh_assy.id = dev.id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				left outer join ' + @pObjAPCSPro + N'.[trans].[days] in_day with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on in_day.id = l.in_date_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				left outer join ' + @pObjAPCSProDWH + N'.[dwh].[act_settings] as config_long_time with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on config_long_time.name = ''ThresholdOfLongTimeStay''' ;
		SET @pSqlSelect2 = @pSqlSelect2 + N'				left outer join ' + @pObjAPCSProDWH + N'.[dwh].[act_settings] as config_product_code with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on config_product_code.name = ''ProductFamilyCode''' ;
		SET @pSqlSelect2 = @pSqlSelect2 + N'						and rtrim(prd.product_code) = rtrim(config_product_code.val) COLLATE SQL_Latin1_General_CP1_CI_AS ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				left outer join ' + @pObjAPCSProDWH + N'.[dwh].[dim_days] as dim_days with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on dim_days.date_value = convert(date,''' + convert(varchar,@pEndTime) + N''') ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'				left outer join ' + @pObjAPCSProDWH + N'.[dwh].[dim_hours] as dim_hours with (NOLOCK) ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'					on dim_hours.h = DATEPART(hour,''' + convert(varchar,@pEndTime) + N''') ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	) as t ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'group by ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	t.day_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.hour_code ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.package_group_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.package_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.device_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.assy_name_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.factory_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.product_family_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.location_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.process_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.job_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.delay_state_code ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.process_state_code ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.qc_state_code ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.long_time_state_code ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.original_process_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.original_job_id ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.production_category ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.process_class ';
		SET @pSqlSelect2 = @pSqlSelect2 + N'	,t.production_category ';
	END;

   ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------

	BEGIN TRY

		BEGIN TRANSACTION

			PRINT '-----1) dwh.fact_wip_custom';
			SET @pStepNo = 1;
			PRINT '@pSqlIns=' + @pSqlIns;
			PRINT '@pSqlSelect1=' + @pSqlSelect1;
			PRINT '@pSqlSelect2=' + @pSqlSelect2;
			EXECUTE (@pSqlIns + @pSqlSelect1 + @pSqlSelect2);

			SET @pRowCnt = @@ROWCOUNT
			SET @logtext = 'Insert(fact_wip_custom) OK : row=' + convert(varchar,@pRowCnt)
			PRINT @logtext

			PRINT '-----2) save the process log'
			SET @pStepNo = 2;
			EXECUTE @pRet = [etl].[sp_update_function_finish_control] @function_name_=@pFunctionName
															, @to_fact_table_ = 'dwh.fact_wip_custom', @finished_at_=@pEndTime
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

RETURN 0;

END ;


