
CREATE PROCEDURE [etl].[sp_etl_2-01_fact_wip] (@v_ProServerName NVARCHAR(128) = ''
											,@v_ProDatabaseName NVARCHAR(128) = ''
											,@logtext nvarchar(max) output
											,@errnum  INT output
											,@errline INT output
											,@errmsg nvarchar(max) output
) AS
BEGIN
    ---------------------------------------------------------------------------
	--(1) Declare
    ---------------------------------------------------------------------------
	DECLARE @ProServerName NVARCHAR(128) = N'';
	DECLARE @ProDatabaseName NVARCHAR(128) = N'APCSProDB';
	DECLARE @objectname NVARCHAR(128) = '';
	DECLARE @objectnamedwh NVARCHAR(128) = '';
	DECLARE @dot NVARCHAR(1) = '.';
	DECLARE @ret INT = 0;
	DECLARE @sqlHeader NVARCHAR(max) = '';
	DECLARE @sqltmp NVARCHAR(max) = '';
	DECLARE @sqltmpDC NVARCHAR(max) = '';
	DECLARE @sqltmpPreDC NVARCHAR(max) = '';
	DECLARE @sqltmpPrePlan NVARCHAR(max) = '';
	DECLARE @rowcnt INT = 0;

    ---------------------------------------------------------------------------
	--(1) connection string
    ---------------------------------------------------------------------------
		IF isnull(RTRIM(@v_ProServerName),'') = ''
			BEGIN
				SET @ProServerName = '';
			END;
		ELSE
			BEGIN
				SET @ProServerName = '[' + @v_ProServerName + ']';
			END;

		IF RTRIM(@v_ProDatabaseName) = ''
			BEGIN
				SET @ProDatabaseName = '[' + @ProDatabaseName + ']';
			END;
		ELSE
			BEGIN
				SET @ProDatabaseName = '[' + @v_ProDatabaseName + ']';
			END;

		if RTRIM(@ProServerName) = ''
			BEGIN
				set @objectname = @ProDatabaseName + @dot
			END;
		else
			BEGIN
				set @objectname = @ProServerName + @dot + @ProDatabaseName + @dot
			END;

    ---------------------------------------------------------------------------
	--(3) get function_finish_control last_finish
    ---------------------------------------------------------------------------
	DECLARE @functionname NVARCHAR(128) = ''
	DECLARE @starttime DATETIME;
	DECLARE @endtime DATETIME;
	BEGIN TRY
		SELECT @functionname = OBJECT_NAME(@@PROCID);
		SELECT @starttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000'))  FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = @functionname
		PRINT '@starttime=' + CASE WHEN @starttime IS NULL THEN '' ELSE FORMAT(@starttime, 'yyyy-MM-dd HH:mm:ss.fff') END;

		SELECT @endtime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'))
		PRINT '@endtime=' + FORMAT(@endtime, 'yyyy-MM-dd HH:mm:ss.fff');
	END TRY
	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()
		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

	if @starttime is not null
		begin
			if @starttime = @endtime 
				begin
					SET @logtext = @functionname + ' has already finished at this hour.' + convert(varchar,@endtime,21);
					return 0;
				end;
		end ;

    ---------------------------------------------------------------------------
	--(4)SQL Make
    ---------------------------------------------------------------------------
	SET @sqlHeader = N'';
	SET @sqlHeader = @sqlHeader + N'INSERT INTO [apcsprodwh].[dwh].[fact_wip] ';
	SET @sqlHeader = @sqlHeader + N'	(day_id ';
	SET @sqlHeader = @sqlHeader + N'	,hour_code ';
	SET @sqlHeader = @sqlHeader + N'	,package_group_id ';
	SET @sqlHeader = @sqlHeader + N'	,package_id ';
	SET @sqlHeader = @sqlHeader + N'	,device_id ';
	SET @sqlHeader = @sqlHeader + N'	,assy_name_id ';
	SET @sqlHeader = @sqlHeader + N'	,factory_id ';
	SET @sqlHeader = @sqlHeader + N'	,product_family_id ';
	SET @sqlHeader = @sqlHeader + N'	,location_id ';
	SET @sqlHeader = @sqlHeader + N'	,process_id ';
	SET @sqlHeader = @sqlHeader + N'	,job_id ';
	SET @sqlHeader = @sqlHeader + N'	,delay_state_code ';
	SET @sqlHeader = @sqlHeader + N'	,process_state_code ';
	SET @sqlHeader = @sqlHeader + N'	,qc_state_code ';
	SET @sqlHeader = @sqlHeader + N'	,long_time_state_code ';
	SET @sqlHeader = @sqlHeader + N'	,lot_count ';
	SET @sqlHeader = @sqlHeader + N'	,pcs ';
	SET @sqlHeader = @sqlHeader + N'	,process_class ';
	SET @sqlHeader = @sqlHeader + N'	,production_category ';
	SET @sqlHeader = @sqlHeader + N'	,next_process_id ';
	SET @sqlHeader = @sqlHeader + N'	,next_job_id ';
	SET @sqlHeader = @sqlHeader + N'	) ';

	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'SELECT ';
	SET @sqltmp = @sqltmp + N'		t2.id AS day_id';
	SET @sqltmp = @sqltmp + N'		,t3.code AS hour_code ';
	SET @sqltmp = @sqltmp + N'		,t1.package_group_id  ';
	SET @sqltmp = @sqltmp + N'		,t1.package_id ';
	SET @sqltmp = @sqltmp + N'		,t1.device_id ';
	SET @sqltmp = @sqltmp + N'		,t1.assy_name_id ';
	SET @sqltmp = @sqltmp + N'		,t1.factory_id ';
	SET @sqltmp = @sqltmp + N'		,t1.product_family_id ';
	SET @sqltmp = @sqltmp + N'		,t1.location_id ';
	SET @sqltmp = @sqltmp + N'		,t1.process_id ';
	SET @sqltmp = @sqltmp + N'		,t1.job_id ';
	SET @sqltmp = @sqltmp + N'		,t1.delay_state_code ';
	SET @sqltmp = @sqltmp + N'		,t1.process_state_code ';
	SET @sqltmp = @sqltmp + N'		,t1.qc_state_code ';
	SET @sqltmp = @sqltmp + N'		,t1.long_time_state_code ';
	SET @sqltmp = @sqltmp + N'		,sum(lot_count) AS lot_count ';
	SET @sqltmp = @sqltmp + N'		,sum(pcs) AS pcs ';
	SET @sqltmp = @sqltmp + N'		,t1.process_class ';
	SET @sqltmp = @sqltmp + N'		,t1.production_category ';
	SET @sqltmp = @sqltmp + N'		,t1.next_process_id ';
	SET @sqltmp = @sqltmp + N'		,t1.next_job_id ';
	SET @sqltmp = @sqltmp + N'FROM ( ';
	SET @sqltmp = @sqltmp + N'			SELECT ';
	SET @sqltmp = @sqltmp + N'				dwh_pkg.package_group_id AS [package_group_id] ';
	SET @sqltmp = @sqltmp + N'				,trans_lots.act_package_id AS [package_id] ';
	SET @sqltmp = @sqltmp + N'				,dwh_dev.id AS [device_id] ';
	SET @sqltmp = @sqltmp + N'				,dwh_assy.id AS [assy_name_id] ';
	SET @sqltmp = @sqltmp + N'				,man_prd.factory_id AS [factory_id] ';
	SET @sqltmp = @sqltmp + N'				,trans_lots.product_family_id AS [product_family_id] ';
	SET @sqltmp = @sqltmp + N'				,NULL AS [location_id] ';
	SET @sqltmp = @sqltmp + N'				,ISNULL(trans_lots.act_process_id, 0) AS [process_id] ';
	SET @sqltmp = @sqltmp + N'				,ISNULL(trans_lots.act_job_id, 0) AS [job_id] ';
	SET @sqltmp = @sqltmp + N'				,CASE WHEN (trans_lots.pass_plan_time_up IS NOT NULL AND trans_lots.pass_plan_time_up < GETDATE()) THEN 10 ';
	SET @sqltmp = @sqltmp + N'						 ELSE ';
	SET @sqltmp = @sqltmp + N'							 CASE WHEN (trans_lots.pass_plan_time IS NOT NULL AND trans_lots.pass_plan_time < GETDATE()) THEN 1 ';
	SET @sqltmp = @sqltmp + N'								ELSE 0 ';
	SET @sqltmp = @sqltmp + N'								END ';
	SET @sqltmp = @sqltmp + N'						END AS [delay_state_code] ';
	SET @sqltmp = @sqltmp + N'				,trans_lots.process_state AS [process_state_code] ';
	SET @sqltmp = @sqltmp + N'				,trans_lots.quality_state AS [qc_state_code] ';
	SET @sqltmp = @sqltmp + N'				,CASE WHEN trans_lots.finished_at IS NULL THEN 0 ';
	SET @sqltmp = @sqltmp + N'					ELSE ';
	SET @sqltmp = @sqltmp + N'						CASE WHEN ';
	SET @sqltmp = @sqltmp + N'							DATEDIFF(DAY, trans_lots.finished_at, GETDATE()) ';
	SET @sqltmp = @sqltmp + N'								> CONVERT(INT, (SELECT val FROM [apcsprodwh].[dwh].[act_settings] WHERE name = ''ThresholdOfLongTimeStay''  COLLATE SQL_Latin1_General_CP1_CI_AS )) ';
	SET @sqltmp = @sqltmp + N'							THEN 1 ';
	SET @sqltmp = @sqltmp + N'							ELSE 0 ';
	SET @sqltmp = @sqltmp + N'							END ';
	SET @sqltmp = @sqltmp + N'					END AS [long_time_state_code] ';
	SET @sqltmp = @sqltmp + N'				,1 AS [lot_count] ';
	SET @sqltmp = @sqltmp + N'				,ISNULL(trans_lots.qty_pass, 0) AS [pcs] ';
	SET @sqltmp = @sqltmp + N'				,fp.assy_ft_class AS [process_class] ';
	SET @sqltmp = @sqltmp + N'				,case substring(rtrim(trans_lots.lot_no),5,1) ';
	SET @sqltmp = @sqltmp + N'						when ''A'' then 0 when ''V'' then 1 when ''W'' then 2 when ''X'' then 3 when ''Y'' then 4 ';
	SET @sqltmp = @sqltmp + N'						when ''B'' then 10 when ''Q'' then 11 when ''R'' then 12 when ''S'' then 13 when ''T'' then 14 ';
	SET @sqltmp = @sqltmp + N'						when ''D'' then 20 ';
	SET @sqltmp = @sqltmp + N'						when ''E'' then 30 when ''5'' then 31 when ''6'' then 32 when ''7'' then 33 when ''8'' then 34 ';
	SET @sqltmp = @sqltmp + N'						when ''F'' then 40 when ''K'' then 41 when ''L'' then 42 when ''M'' then 43 when ''N'' then 44 ';
	SET @sqltmp = @sqltmp + N'						when ''G'' then 50 when ''0'' then 51 when ''1'' then 52 when ''2'' then 53 when ''3'' then 54 ';
	SET @sqltmp = @sqltmp + N'						when ''H'' then 60 when ''P'' then 61 when ''U'' then 62 when ''Z'' then 63 when ''4'' then 64 else 0 end as [production_category] ';
	SET @sqltmp = @sqltmp + N'				,dfn.act_process_id as next_process_id ';
	SET @sqltmp = @sqltmp + N'				,dfn.job_id as next_job_id ';
	SET @sqltmp = @sqltmp + N'			FROM ' + @objectname + '[trans].[lots] AS trans_lots with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN ' + @objectname + '[man].[product_families] AS man_prd with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON man_prd.id = trans_lots.product_family_id ';
	SET @sqltmp = @sqltmp + N'						AND RTRIM(man_prd.product_code) = RTRIM(( ';
	SET @sqltmp = @sqltmp + N'																	SELECT val ';
	SET @sqltmp = @sqltmp + N'																	FROM [apcsprodwh].[dwh].[act_settings] with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'																	WHERE name = ''ProductFamilyCode''))  COLLATE SQL_Latin1_General_CP1_CI_AS ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN ' + @objectname + '[method].[device_names] AS met_dev with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON met_dev.id = trans_lots.act_device_name_id ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN [apcsprodwh].[dwh].[dim_packages] AS dwh_pkg with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON dwh_pkg.id = trans_lots.act_package_id ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN [apcsprodwh].[dwh].[dim_devices] AS dwh_dev with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON dwh_dev.id = met_dev.id ';
	SET @sqltmp = @sqltmp + N'				INNER JOIN [apcsprodwh].[dwh].[dim_assy_device_names] AS dwh_assy with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON dwh_assy.id = met_dev.id ';
	SET @sqltmp = @sqltmp + N'				inner join [apcsprodb].[method].[device_flow_patterns] AS fp with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					on fp.device_slip_id = trans_lots.device_slip_id ';
	SET @sqltmp = @sqltmp + N'				inner join [apcsprodb].[method].[flow_details] AS f with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					on f.flow_pattern_id = fp.flow_pattern_id  ';
	SET @sqltmp = @sqltmp + N'						and f.job_id = trans_lots.act_job_id ';
	SET @sqltmp = @sqltmp + N'				inner join [apcsprodb].[method].[device_flows] AS df with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					on df.device_slip_id = trans_lots.device_slip_id and df.step_no = trans_lots.step_no ';
	SET @sqltmp = @sqltmp + N'				left outer join [apcsprodb].[method].[device_flows] AS dfn with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					on dfn.device_slip_id = df.device_slip_id and dfn.step_no = df.next_step_no ';
	SET @sqltmp = @sqltmp + N'			WHERE met_dev.is_assy_only in(0,1) ';
	SET @sqltmp = @sqltmp + N'				AND trans_lots.wip_state = 20 ';
	SET @sqltmp = @sqltmp + N'				AND trans_lots.lot_no like ''%V'' ';
	SET @sqltmp = @sqltmp + N'		) AS t1 ';
	SET @sqltmp = @sqltmp + N'		,(SELECT id ';
	SET @sqltmp = @sqltmp + N'			FROM [apcsprodwh].[dwh].[dim_days]  with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'			WHERE date_value = CONVERT(DATE,GETDATE()) ';
	SET @sqltmp = @sqltmp + N'		) AS t2 ';
	SET @sqltmp = @sqltmp + N'		,(SELECT code ';
	SET @sqltmp = @sqltmp + N'			FROM [apcsprodwh].[dwh].[dim_hours]  with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'			WHERE h = DATEPART(HOUR,GETDATE()) ';
	SET @sqltmp = @sqltmp + N'		) AS t3 ';
	SET @sqltmp = @sqltmp + N'GROUP BY ';
	SET @sqltmp = @sqltmp + N'	t2.id ';
	SET @sqltmp = @sqltmp + N'	,t3.code ';
	SET @sqltmp = @sqltmp + N'	,t1.package_group_id ';
	SET @sqltmp = @sqltmp + N'	,t1.package_id ';
	SET @sqltmp = @sqltmp + N'	,t1.device_id ';
	SET @sqltmp = @sqltmp + N'	,t1.assy_name_id ';
	SET @sqltmp = @sqltmp + N'	,t1.factory_id ';
	SET @sqltmp = @sqltmp + N'	,t1.product_family_id ';
	SET @sqltmp = @sqltmp + N'	,t1.location_id ';
	SET @sqltmp = @sqltmp + N'	,t1.process_id ';
	SET @sqltmp = @sqltmp + N'	,t1.job_id ';
	SET @sqltmp = @sqltmp + N'	,t1.delay_state_code ';
	SET @sqltmp = @sqltmp + N'	,t1.process_state_code ';
	SET @sqltmp = @sqltmp + N'	,t1.qc_state_code ';
	SET @sqltmp = @sqltmp + N'	,t1.long_time_state_code ';
	SET @sqltmp = @sqltmp + N'	,t1.process_class ';
	SET @sqltmp = @sqltmp + N'	,t1.production_category ';
	SET @sqltmp = @sqltmp + N'	,t1.next_process_id ';
	SET @sqltmp = @sqltmp + N'	,t1.next_job_id ';



	SET @sqltmpDC = N'';
	SET @sqltmpDC = @sqltmpDC + N'SELECT '; 
	SET @sqltmpDC = @sqltmpDC + N' 		t2.id AS day_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t3.code AS hour_code '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.package_group_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.package_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.device_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.assy_name_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.factory_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.product_family_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.location_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t4.dc_process_id as process_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t4.dc_job_id as job_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.delay_state_code '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.process_state_code '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.qc_state_code '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.long_time_state_code '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,sum(lot_count) AS lot_count '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,sum(pcs) AS pcs '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.process_class '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.production_category '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.next_process_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,t1.next_job_id '; 
	SET @sqltmpDC = @sqltmpDC + N' FROM ( '; 
	SET @sqltmpDC = @sqltmpDC + N' 			SELECT '; 
	SET @sqltmpDC = @sqltmpDC + N' 				dwh_pkg.package_group_id AS [package_group_id] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,trans_lots.act_package_id AS [package_id] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,dwh_dev.id AS [device_id] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,dwh_assy.id AS [assy_name_id] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,man_prd.factory_id AS [factory_id] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,trans_lots.product_family_id AS [product_family_id] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,NULL AS [location_id] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,0 AS [process_id] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,3 AS [job_id] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,0 AS [delay_state_code] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,trans_lots.process_state AS [process_state_code] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,trans_lots.quality_state AS [qc_state_code] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,CASE WHEN trans_lots.finished_at IS NULL THEN 0 '; 
	SET @sqltmpDC = @sqltmpDC + N' 					ELSE '; 
	SET @sqltmpDC = @sqltmpDC + N' 						CASE WHEN '; 
	SET @sqltmpDC = @sqltmpDC + N' 							DATEDIFF(DAY, trans_lots.finished_at, GETDATE()) '; 
	SET @sqltmpDC = @sqltmpDC + N' 								> CONVERT(INT, (SELECT val FROM [apcsprodwh].[dwh].[act_settings] WHERE name = ''ThresholdOfLongTimeStay''  COLLATE SQL_Latin1_General_CP1_CI_AS )) '; 
	SET @sqltmpDC = @sqltmpDC + N' 							THEN 1 '; 
	SET @sqltmpDC = @sqltmpDC + N' 							ELSE 0 '; 
	SET @sqltmpDC = @sqltmpDC + N' 							END '; 
	SET @sqltmpDC = @sqltmpDC + N' 					END AS [long_time_state_code] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,1 AS [lot_count] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,ISNULL(trans_lots.qty_pass, 0) AS [pcs] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,fp.assy_ft_class AS [process_class] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,case substring(rtrim(trans_lots.lot_no),5,1) '; 
	SET @sqltmpDC = @sqltmpDC + N' 						when ''A'' then 0 when ''V'' then 1 when ''W'' then 2 when ''X'' then 3 when ''Y'' then 4 '; 
	SET @sqltmpDC = @sqltmpDC + N' 						when ''B'' then 10 when ''Q'' then 11 when ''R'' then 12 when ''S'' then 13 when ''T'' then 14 '; 
	SET @sqltmpDC = @sqltmpDC + N' 						when ''D'' then 20 '; 
	SET @sqltmpDC = @sqltmpDC + N' 						when ''E'' then 30 when ''5'' then 31 when ''6'' then 32 when ''7'' then 33 when ''8'' then 34 '; 
	SET @sqltmpDC = @sqltmpDC + N' 						when ''F'' then 40 when ''K'' then 41 when ''L'' then 42 when ''M'' then 43 when ''N'' then 44 '; 
	SET @sqltmpDC = @sqltmpDC + N' 						when ''G'' then 50 when ''0'' then 51 when ''1'' then 52 when ''2'' then 53 when ''3'' then 54 '; 
	SET @sqltmpDC = @sqltmpDC + N' 						when ''H'' then 60 when ''P'' then 61 when ''U'' then 62 when ''Z'' then 63 when ''4'' then 64 else 0 end as [production_category] '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,df.act_process_id as next_process_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,df.job_id as next_job_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 				,trans_lots.in_plan_date_id'; 
	SET @sqltmpDC = @sqltmpDC + N' 			FROM ' + @objectname + '[trans].[lots] AS trans_lots with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N' 				INNER JOIN ' + @objectname + '[man].[product_families] AS man_prd with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N' 					ON man_prd.id = trans_lots.product_family_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 						AND RTRIM(man_prd.product_code) = RTRIM(( '; 
	SET @sqltmpDC = @sqltmpDC + N' 																	SELECT val '; 
	SET @sqltmpDC = @sqltmpDC + N' 																	FROM [apcsprodwh].[dwh].[act_settings] with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N' 																	WHERE name = ''ProductFamilyCode''))  COLLATE SQL_Latin1_General_CP1_CI_AS '; 
	SET @sqltmpDC = @sqltmpDC + N' 				INNER JOIN ' + @objectname + '[method].[device_names] AS met_dev with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N' 					ON met_dev.id = trans_lots.act_device_name_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 				INNER JOIN [apcsprodwh].[dwh].[dim_packages] AS dwh_pkg with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N' 					ON dwh_pkg.id = trans_lots.act_package_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 				INNER JOIN [apcsprodwh].[dwh].[dim_devices] AS dwh_dev with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N' 					ON dwh_dev.id = met_dev.id '; 
	SET @sqltmpDC = @sqltmpDC + N' 				INNER JOIN [apcsprodwh].[dwh].[dim_assy_device_names] AS dwh_assy with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N' 					ON dwh_assy.id = met_dev.id '; 
	SET @sqltmpDC = @sqltmpDC + N' 				inner join [apcsprodb].[method].[device_flow_patterns] AS fp with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N' 					on fp.device_slip_id = trans_lots.device_slip_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 				inner join [apcsprodb].[method].[flow_details] AS f with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N' 					on f.flow_pattern_id = fp.flow_pattern_id  '; 
	SET @sqltmpDC = @sqltmpDC + N' 						and f.job_id = trans_lots.act_job_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 				inner join [apcsprodb].[method].[device_flows] AS df with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N' 					on df.device_slip_id = trans_lots.device_slip_id and df.step_no = trans_lots.step_no '; 
	SET @sqltmpDC = @sqltmpDC + N' 			WHERE met_dev.is_assy_only in(0,1) '; 
	SET @sqltmpDC = @sqltmpDC + N' 				AND trans_lots.wip_state = 10'; 
	SET @sqltmpDC = @sqltmpDC + N' 		) AS t1 '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,(SELECT id '; 
	SET @sqltmpDC = @sqltmpDC + N' 			FROM [apcsprodwh].[dwh].[dim_days]  with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N' 			WHERE date_value = CONVERT(DATE,GETDATE()) '; 
	SET @sqltmpDC = @sqltmpDC + N' 		) AS t2 '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,(SELECT code '; 
	SET @sqltmpDC = @sqltmpDC + N' 			FROM [apcsprodwh].[dwh].[dim_hours]  with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N' 			WHERE h = DATEPART(HOUR,GETDATE()) '; 
	SET @sqltmpDC = @sqltmpDC + N' 		) AS t3 '; 
	SET @sqltmpDC = @sqltmpDC + N' 		,(SELECT j.id as dc_job_id,pr.id as dc_process_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 			FROM [apcsprodwh].[dwh].[dim_jobs] as j  with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N'				inner join [apcsprodwh].[dwh].[dim_processes] as pr  with (NOLOCK) '; 
	SET @sqltmpDC = @sqltmpDC + N'					on pr.process_no = j.process_no '; 
	SET @sqltmpDC = @sqltmpDC + N' 			WHERE j.name = ''DC'' '; 
	SET @sqltmpDC = @sqltmpDC + N' 		) AS t4  '; 
	SET @sqltmpDC = @sqltmpDC + N' where t1.in_plan_date_id <= t2.id'; 
	SET @sqltmpDC = @sqltmpDC + N' GROUP BY '; 
	SET @sqltmpDC = @sqltmpDC + N' 	t2.id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t3.code '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.package_group_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.package_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.device_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.assy_name_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.factory_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.product_family_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.location_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.process_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.job_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.delay_state_code '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.process_state_code '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.qc_state_code '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.long_time_state_code '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.process_class '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.production_category '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.next_process_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t1.next_job_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t4.dc_job_id '; 
	SET @sqltmpDC = @sqltmpDC + N' 	,t4.dc_process_id '; 



	SET @sqltmpPreDC = N'';
	SET @sqltmpPreDC = @sqltmpPreDC + N'SELECT '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		t1.day_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.hour_code '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.package_group_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.package_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.device_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.assy_name_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.factory_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.product_family_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.location_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.process_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.job_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.delay_state_code '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.process_state_code '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.qc_state_code '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.long_time_state_code '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,sum(lot_count) AS lot_count '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,sum(pcs) AS pcs '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.process_class '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.production_category '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.next_process_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		,t1.next_job_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' FROM ( '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 			SELECT '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				dwh_pkg.package_group_id AS [package_group_id] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,trans_lots.act_package_id AS [package_id] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,dwh_dev.id AS [device_id] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,dwh_assy.id AS [assy_name_id] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,man_prd.factory_id AS [factory_id] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,trans_lots.product_family_id AS [product_family_id] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,NULL AS [location_id] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,0 AS [process_id] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,0 AS [job_id] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,case when trans_lots.in_plan_date_id < t2.day_id then 1 else 0 end AS [delay_state_code] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,trans_lots.process_state AS [process_state_code] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,trans_lots.quality_state AS [qc_state_code] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,CASE WHEN trans_lots.finished_at IS NULL THEN 0 '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 					ELSE '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 						CASE WHEN '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 							DATEDIFF(DAY, trans_lots.finished_at, GETDATE()) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 								> CONVERT(INT, (SELECT val FROM [apcsprodwh].[dwh].[act_settings] WHERE name = ''ThresholdOfLongTimeStay''  COLLATE SQL_Latin1_General_CP1_CI_AS )) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 							THEN 1 '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 							ELSE 0 '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 							END '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 					END AS [long_time_state_code] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,1 AS [lot_count] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,ISNULL(trans_lots.qty_pass, 0) AS [pcs] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,fp.assy_ft_class AS [process_class] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,case substring(rtrim(trans_lots.lot_no),5,1) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 						when ''A'' then 0 when ''V'' then 1 when ''W'' then 2 when ''X'' then 3 when ''Y'' then 4 '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 						when ''B'' then 10 when ''Q'' then 11 when ''R'' then 12 when ''S'' then 13 when ''T'' then 14 '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 						when ''D'' then 20 '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 						when ''E'' then 30 when ''5'' then 31 when ''6'' then 32 when ''7'' then 33 when ''8'' then 34 '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 						when ''F'' then 40 when ''K'' then 41 when ''L'' then 42 when ''M'' then 43 when ''N'' then 44 '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 						when ''G'' then 50 when ''0'' then 51 when ''1'' then 52 when ''2'' then 53 when ''3'' then 54 '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 						when ''H'' then 60 when ''P'' then 61 when ''U'' then 62 when ''Z'' then 63 when ''4'' then 64 else 0 end as [production_category] '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,df.act_process_id as next_process_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,df.job_id as next_job_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				,trans_lots.in_plan_date_id'; 
	SET @sqltmpPreDC = @sqltmpPreDC + N'				,t2.day_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N'				,t3.hour_code '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N'				,trans_lots.id as lot_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 			FROM ' + @objectname + '[trans].[lots] AS trans_lots with (NOLOCK) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				INNER JOIN ' + @objectname + '[man].[product_families] AS man_prd with (NOLOCK) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 					ON man_prd.id = trans_lots.product_family_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 						AND RTRIM(man_prd.product_code) = RTRIM(( '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 																	SELECT val '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 																	FROM [apcsprodwh].[dwh].[act_settings] with (NOLOCK) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 																	WHERE name = ''ProductFamilyCode''))  COLLATE SQL_Latin1_General_CP1_CI_AS '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				INNER JOIN ' + @objectname + '[method].[device_names] AS met_dev with (NOLOCK) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 					ON met_dev.id = trans_lots.act_device_name_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				INNER JOIN [apcsprodwh].[dwh].[dim_packages] AS dwh_pkg with (NOLOCK) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 					ON dwh_pkg.id = trans_lots.act_package_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				INNER JOIN [apcsprodwh].[dwh].[dim_devices] AS dwh_dev with (NOLOCK) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 					ON dwh_dev.id = met_dev.id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				INNER JOIN [apcsprodwh].[dwh].[dim_assy_device_names] AS dwh_assy with (NOLOCK) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 					ON dwh_assy.id = met_dev.id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				inner join [apcsprodb].[method].[device_flow_patterns] AS fp with (NOLOCK) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 					on fp.device_slip_id = trans_lots.device_slip_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				inner join [apcsprodb].[method].[flow_details] AS f with (NOLOCK) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 					on f.flow_pattern_id = fp.flow_pattern_id  '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 						and f.job_id = trans_lots.act_job_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				inner join [apcsprodb].[method].[device_flows] AS df with (NOLOCK) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 					on df.device_slip_id = trans_lots.device_slip_id and df.step_no = trans_lots.step_no '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				cross join (SELECT id  as day_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 							FROM [apcsprodwh].[dwh].[dim_days]  with (NOLOCK) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 							WHERE date_value = CONVERT(DATE,GETDATE()) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 							) AS t2 '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				cross join (SELECT code as hour_code '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 							FROM [apcsprodwh].[dwh].[dim_hours]  with (NOLOCK) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 							WHERE h = DATEPART(HOUR,GETDATE()) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 							) AS t3 '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 			WHERE met_dev.is_assy_only in(0,1) '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 				and trans_lots.wip_state < 10'; 
	SET @sqltmpPreDC = @sqltmpPreDC + N'				and trans_lots.in_plan_date_id <= t2.day_id'; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 		) AS t1 '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' GROUP BY '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	t1.day_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.hour_code '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.package_group_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.package_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.device_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.assy_name_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.factory_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.product_family_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.location_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.process_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.job_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.delay_state_code '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.process_state_code '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.qc_state_code '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.long_time_state_code '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.process_class '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.production_category '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.next_process_id '; 
	SET @sqltmpPreDC = @sqltmpPreDC + N' 	,t1.next_job_id '; 

	SET @sqltmpPrePlan = N'';
	SET @sqltmpPrePlan = @sqltmpPrePlan + N'SELECT '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		t2.id AS day_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t3.code AS hour_code '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.package_group_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.package_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.device_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.assy_name_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.factory_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.product_family_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.location_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.process_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.job_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.delay_state_code '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.process_state_code '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.qc_state_code '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.long_time_state_code '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,sum(lot_count) AS lot_count '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,sum(pcs) AS pcs '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.process_class '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.production_category '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.next_process_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,t1.next_job_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' FROM ( '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 			SELECT '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				dwh_pkg.package_group_id AS [package_group_id] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,trans_lots.act_package_id AS [package_id] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,dwh_dev.id AS [device_id] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,dwh_assy.id AS [assy_name_id] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,man_prd.factory_id AS [factory_id] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,trans_lots.product_family_id AS [product_family_id] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,NULL AS [location_id] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,-1 AS [process_id] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,-1 AS [job_id] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,0 AS [delay_state_code] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,trans_lots.process_state AS [process_state_code] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,trans_lots.quality_state AS [qc_state_code] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,CASE WHEN trans_lots.finished_at IS NULL THEN 0 '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 					ELSE '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 						CASE WHEN '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 							DATEDIFF(DAY, trans_lots.finished_at, GETDATE()) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 								> CONVERT(INT, (SELECT val FROM [apcsprodwh].[dwh].[act_settings] WHERE name = ''ThresholdOfLongTimeStay''  COLLATE SQL_Latin1_General_CP1_CI_AS )) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 							THEN 1 '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 							ELSE 0 '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 							END '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 					END AS [long_time_state_code] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,1 AS [lot_count] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,ISNULL(trans_lots.qty_pass, 0) AS [pcs] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,fp.assy_ft_class AS [process_class] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,case substring(rtrim(trans_lots.lot_no),5,1) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 						when ''A'' then 0 when ''V'' then 1 when ''W'' then 2 when ''X'' then 3 when ''Y'' then 4 '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 						when ''B'' then 10 when ''Q'' then 11 when ''R'' then 12 when ''S'' then 13 when ''T'' then 14 '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 						when ''D'' then 20 '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 						when ''E'' then 30 when ''5'' then 31 when ''6'' then 32 when ''7'' then 33 when ''8'' then 34 '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 						when ''F'' then 40 when ''K'' then 41 when ''L'' then 42 when ''M'' then 43 when ''N'' then 44 '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 						when ''G'' then 50 when ''0'' then 51 when ''1'' then 52 when ''2'' then 53 when ''3'' then 54 '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 						when ''H'' then 60 when ''P'' then 61 when ''U'' then 62 when ''Z'' then 63 when ''4'' then 64 else 0 end as [production_category] '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,df.act_process_id as next_process_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,df.job_id as next_job_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				,trans_lots.in_plan_date_id'; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 			FROM ' + @objectname + '[trans].[lots] AS trans_lots with (NOLOCK) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				INNER JOIN ' + @objectname + '[man].[product_families] AS man_prd with (NOLOCK) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 					ON man_prd.id = trans_lots.product_family_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 						AND RTRIM(man_prd.product_code) = RTRIM(( '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 																	SELECT val '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 																	FROM [apcsprodwh].[dwh].[act_settings] with (NOLOCK) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 																	WHERE name = ''ProductFamilyCode''))  COLLATE SQL_Latin1_General_CP1_CI_AS '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				INNER JOIN ' + @objectname + '[method].[device_names] AS met_dev with (NOLOCK) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 					ON met_dev.id = trans_lots.act_device_name_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				INNER JOIN [apcsprodwh].[dwh].[dim_packages] AS dwh_pkg with (NOLOCK) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 					ON dwh_pkg.id = trans_lots.act_package_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				INNER JOIN [apcsprodwh].[dwh].[dim_devices] AS dwh_dev with (NOLOCK) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 					ON dwh_dev.id = met_dev.id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				INNER JOIN [apcsprodwh].[dwh].[dim_assy_device_names] AS dwh_assy with (NOLOCK) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 					ON dwh_assy.id = met_dev.id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				inner join [apcsprodb].[method].[device_flow_patterns] AS fp with (NOLOCK) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 					on fp.device_slip_id = trans_lots.device_slip_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				inner join [apcsprodb].[method].[flow_details] AS f with (NOLOCK) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 					on f.flow_pattern_id = fp.flow_pattern_id  '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 						and f.job_id = trans_lots.act_job_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				inner join [apcsprodb].[method].[device_flows] AS df with (NOLOCK) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 					on df.device_slip_id = trans_lots.device_slip_id and df.step_no = trans_lots.step_no '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 			WHERE met_dev.is_assy_only in(0,1) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 				AND trans_lots.wip_state = 0'; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		) AS t1 '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,(SELECT id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 			FROM [apcsprodwh].[dwh].[dim_days]  with (NOLOCK) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 			WHERE date_value = CONVERT(DATE,GETDATE()) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		) AS t2 '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		,(SELECT code '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 			FROM [apcsprodwh].[dwh].[dim_hours]  with (NOLOCK) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 			WHERE h = DATEPART(HOUR,GETDATE()) '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 		) AS t3 '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' where t1.in_plan_date_id > t2.id'; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' GROUP BY '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	t2.id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t3.code '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.package_group_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.package_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.device_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.assy_name_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.factory_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.product_family_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.location_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.process_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.job_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.delay_state_code '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.process_state_code '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.qc_state_code '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.long_time_state_code '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.process_class '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.production_category '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.next_process_id '; 
	SET @sqltmpPrePlan = @sqltmpPrePlan + N' 	,t1.next_job_id '; 



	PRINT '-----------------Header---------------------';
	PRINT @sqlHeader;


	PRINT '-----------------sqltmp-----------------------';
	PRINT @sqltmp;

	PRINT '---------------------sqlDC ------------------';
	PRINT @sqltmpDC;


	PRINT '---------------------sqlPreDC-------------------';
	PRINT @sqltmpPreDC;


	PRINT '---------------------sqlPrePlan-------------------';
	PRINT @sqltmpPrePlan;

    ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------

	BEGIN TRY
		BEGIN TRANSACTION;
		EXECUTE (@sqlHeader + @sqltmp);
		set @rowcnt = @@ROWCOUNT
		set @logtext = '@sqltmp:OK row:' + convert(varchar,@rowcnt)
		print @logtext

		EXECUTE (@sqlHeader + @sqltmpDC);
		set @rowcnt = @@ROWCOUNT
		set @logtext = '@sqltmpDC:OK row:' + convert(varchar,@rowcnt)
		print @logtext


		EXECUTE (@sqlHeader + @sqltmpPreDC);
		set @rowcnt = @@ROWCOUNT
		set @logtext = '@sqltmpPreDC:OK row:' + convert(varchar,@rowcnt)
		print @logtext

		EXECUTE (@sqlHeader + @sqltmpPrePlan);
		set @rowcnt = @@ROWCOUNT
		set @logtext = '@sqltmpPrePlan:OK row:' + convert(varchar,@rowcnt)
		print @logtext

		EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='dwh.fact_wip', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
			IF @ret<>0
				begin
					IF @@TRANCOUNT <> 0
						BEGIN
							ROLLBACK TRANSACTION;
						END;
					SET @logtext = '@ret<>0 [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret) + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg;				
					PRINT 'sp_update_function_finish_control:NG' + convert(varchar,@ret) + @logtext;
					--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
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

		SET @logtext = '[ERR] [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret) + + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg + '/SQL:' + @sqltmp ;
		PRINT 'transaction err ' + @logtext;
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;


	RETURN 0;

END ;
