

CREATE PROCEDURE [etl].[sp_etl_2-09_fact_shipment] (@v_ProServerName NVARCHAR(128) = ''
											,@v_ProDatabaseName NVARCHAR(128) = ''
											,@v_DwhDatabaseName NVARCHAR(128) = ''
											,@v_shiptimemax datetime
											,@logtext nvarchar(max) output
											,@errnum  INT output
											,@errline INT output
											,@errmsg nvarchar(max) output

)AS
BEGIN
    ---------------------------------------------------------------------------
	--(1) Declare
    ---------------------------------------------------------------------------
	DECLARE @ProServerName NVARCHAR(128) = N'';
	DECLARE @ProDatabaseName NVARCHAR(128) = N'APCSProDB';
	DECLARE @DwhDatabaseName NVARCHAR(128) = N'APCSProDwh';
	DECLARE @objectname NVARCHAR(128) = '';
	DECLARE @objectnamedwh NVARCHAR(128) = '';
	DECLARE @dot NVARCHAR(1) = '.';
	DECLARE @ret INT = 0;
	DECLARE @sqltmp NVARCHAR(max) = '';
	DECLARE @rowcnt INT = 0;


	if @v_shiptimemax = null 
		return 0;



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

		IF RTRIM(@v_DwhDatabaseName) = ''
			BEGIN
				SET @DwhDatabaseName = '[' + @DwhDatabaseName + ']';
			END;
		ELSE
			BEGIN
				SET @DwhDatabaseName = '[' + @v_DwhDatabaseName + ']';
			END;


		if RTRIM(@ProServerName) = ''
			BEGIN
				set @objectname = @ProDatabaseName + @dot
				set @objectnamedwh = @DwhDatabaseName + @dot
			END;
		else
			BEGIN
				set @objectname = @ProServerName + @dot + @ProDatabaseName + @dot
				set @objectnamedwh = @ProServerName + @dot + @DwhDatabaseName + @dot
			END;

    ---------------------------------------------------------------------------
	--(2) declare (log)
    ---------------------------------------------------------------------------
	--DECLARE @pathname NVARCHAR(128) = N'\\10.28.32.122\share\SSIS\Log\';
	--DECLARE @logfile NVARCHAR(128) = N'Log' + CONVERT(NVARCHAR(8), FORMAT(GETDATE(), 'yyyyMMdd')) + N'.log';
	--DECLARE @logfilepathname NVARCHAR(256) = CONVERT(NVARCHAR(256), (@pathname + @logfile));
	--DECLARE @errlogfile NVARCHAR(128) = N'ErrorLog' + CONVERT(NVARCHAR(8), FORMAT(GETDATE(), 'yyyyMMdd')) + N'.log';
	--DECLARE @errlogfilepathname NVARCHAR(256) = CONVERT(NVARCHAR(256), (@pathname + @errlogfile));
	--DECLARE @logtext NVARCHAR(2000) = '';

    ---------------------------------------------------------------------------
	--(3) get function_finish_control last_finish
    ---------------------------------------------------------------------------
	DECLARE @functionname NVARCHAR(128) = ''
	DECLARE @starttime DATETIME;
	DECLARE @endtime DATETIME;
	BEGIN TRY
		SELECT @functionname = OBJECT_NAME(@@PROCID);

		SELECT @starttime = isnull(finished_at,'2018-04-01')  FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
		PRINT '@starttime=' + CASE WHEN @starttime IS NULL THEN '' ELSE FORMAT(@starttime, 'yyyy-MM-dd HH:mm:ss.fff') END;

		SELECT @endtime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'))
		PRINT '@endtime=' + FORMAT(@endtime, 'yyyy-MM-dd HH:mm:ss.fff');
	END TRY
	BEGIN CATCH
		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

    ---------------------------------------------------------------------------
	--(4)SQL make
    ---------------------------------------------------------------------------
	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'insert into [apcsprodwh].[dwh].[fact_shipment] ';
	SET @sqltmp = @sqltmp + N'			(day_id ';
	SET @sqltmp = @sqltmp + N'			,hour_code ';
	SET @sqltmp = @sqltmp + N'			,package_group_id ';
	SET @sqltmp = @sqltmp + N'			,package_id ';
	SET @sqltmp = @sqltmp + N'			,device_id ';
	SET @sqltmp = @sqltmp + N'			,assy_name_id ';
	SET @sqltmp = @sqltmp + N'			,factory_id ';
	SET @sqltmp = @sqltmp + N'			,product_family_id ';
	SET @sqltmp = @sqltmp + N'			,lot_id ';
	SET @sqltmp = @sqltmp + N'			,input_pcs ';
	SET @sqltmp = @sqltmp + N'			,pass_pcs ';
	SET @sqltmp = @sqltmp + N'			,std_time ';
	SET @sqltmp = @sqltmp + N'			,lead_time ';
	SET @sqltmp = @sqltmp + N'			,wait_time ';
	SET @sqltmp = @sqltmp + N'			,process_time ';
	SET @sqltmp = @sqltmp + N'			) ';
	SET @sqltmp = @sqltmp + N'	select ';
	SET @sqltmp = @sqltmp + N'		 dwh_days.id AS [1_day_id] ';
	SET @sqltmp = @sqltmp + N'		,dwh_hours.code AS [2_hour_code] ';
	SET @sqltmp = @sqltmp + N'		,t1.[3_package_group_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[4_package_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[5_device_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[6_assy_name_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[7_factory_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[8_product_family_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[9_lot_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[10_input_pcs] ';
	SET @sqltmp = @sqltmp + N'		,t1.[11_pass_pcs] ';
	SET @sqltmp = @sqltmp + N'		,t1.[12_std_time] ';
	SET @sqltmp = @sqltmp + N'		,ISNULL(DATEDIFF(MINUTE,t1.in_at,t1.ship_at), 0) as [13_lead_time] ';
	SET @sqltmp = @sqltmp + N'		,(ISNULL(DATEDIFF(MINUTE,t1.in_at,t1.ship_at), 0) - sum(DATEDIFF(MINUTE, t1.s_recorded_at, t1.f_recorded_at))) AS [14_wait_time] ';
	SET @sqltmp = @sqltmp + N'		,sum(DATEDIFF(MINUTE, t1.s_recorded_at, t1.f_recorded_at)) AS [15_process_time] ';
	SET @sqltmp = @sqltmp + N'	from ( ';
	SET @sqltmp = @sqltmp + N'		select ';
	SET @sqltmp = @sqltmp + N'			 l.ship_at ';
	SET @sqltmp = @sqltmp + N'			,convert(date, l.ship_at) AS date_value ';
	SET @sqltmp = @sqltmp + N'			,isnull(DATEPART(hour, l.ship_at),0) AS h ';
	SET @sqltmp = @sqltmp + N'			,pkg.package_group_id AS [3_package_group_id] ';
	SET @sqltmp = @sqltmp + N'			,l.act_package_id AS [4_package_id] ';
	SET @sqltmp = @sqltmp + N'			,l.act_device_name_id AS [5_device_id] ';
	SET @sqltmp = @sqltmp + N'			,dwh_assy.id AS [6_assy_name_id] ';
	SET @sqltmp = @sqltmp + N'			,prd.factory_id AS [7_factory_id] ';
	SET @sqltmp = @sqltmp + N'			,l.product_family_id AS [8_product_family_id] ';
	SET @sqltmp = @sqltmp + N'			,l.id AS [9_lot_id] ';
	SET @sqltmp = @sqltmp + N'			,ISNULL(l.qty_in, 0) AS [10_input_pcs] ';
	SET @sqltmp = @sqltmp + N'			,ISNULL(l.qty_out, 0) AS [11_pass_pcs] ';
	SET @sqltmp = @sqltmp + N'			,((l.out_plan_date_id - l.in_plan_date_id) * 24 * 60 ) AS [12_std_time] ';
	SET @sqltmp = @sqltmp + N'			,isnull(convert(datetime, l.in_at),dy.date_value) AS in_at';
	SET @sqltmp = @sqltmp + N'			,lot_rec_s.step_no as s_step_no';
	SET @sqltmp = @sqltmp + N'			,lot_rec_s.recorded_at as s_recorded_at';
	SET @sqltmp = @sqltmp + N'			,lot_rec_f.step_no as f_step_no';
	SET @sqltmp = @sqltmp + N'			,lot_rec_f.recorded_at as f_recorded_at';
	SET @sqltmp = @sqltmp + N'			,rank() over (partition by l.id,lot_rec_s.step_no order by lot_rec_s.id) as s_idx';
	SET @sqltmp = @sqltmp + N'			,rank() over (partition by l.id,lot_rec_f.step_no order by lot_rec_f.id desc) as f_idx';
	SET @sqltmp = @sqltmp + N'		from ' + @objectname + '[trans].[lots] AS l with (NOLOCK)';
	SET @sqltmp = @sqltmp + N'			INNER JOIN ' + @objectname + '[man].[product_families] AS prd with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				ON prd.id = l.product_family_id ';
	SET @sqltmp = @sqltmp + N'			INNER JOIN ' + @objectname + '[method].[device_slips] AS slp with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				ON slp.device_slip_id = l.device_slip_id ';
	SET @sqltmp = @sqltmp + N'			INNER JOIN ' + @objectname + '[method].[device_versions] AS vrs with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				ON vrs.device_id = slp.device_id ';
	SET @sqltmp = @sqltmp + N'			INNER JOIN ' + @objectname + '[method].[device_names] AS dev with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				ON dev.id = vrs.device_name_id ';
	SET @sqltmp = @sqltmp + N'					AND dev.is_assy_only = 0 ';
	SET @sqltmp = @sqltmp + N'			INNER JOIN ' + @objectname + '[method].[packages] AS pkg with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				ON pkg.id = dev.package_id ';
	SET @sqltmp = @sqltmp + N'			INNER JOIN ' + @objectnamedwh + '[dwh].[dim_assy_device_names] AS dwh_assy with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				ON dwh_assy.id = dev.id ';
	SET @sqltmp = @sqltmp + N'			left outer join ' + @objectname + '[trans].[days] as dy with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				on dy.id = l.in_date_id ';
	SET @sqltmp = @sqltmp + N'			inner join ' + @objectname + '[trans].[lot_process_records] AS lot_rec_s with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				ON lot_rec_s.lot_id = l.id ';
	SET @sqltmp = @sqltmp + N'					and lot_rec_s.record_class = 1 ';
	SET @sqltmp = @sqltmp + N'			inner join ' + @objectname + '[trans].[lot_process_records] AS lot_rec_f with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'				ON lot_rec_f.lot_id = l.id ';
	SET @sqltmp = @sqltmp + N'					and lot_rec_f.record_class = 2 ';
	SET @sqltmp = @sqltmp + N'					and lot_rec_f.step_no = lot_rec_s.step_no ';
	SET @sqltmp = @sqltmp + N'		WHERE l.ship_at IS NOT NULL ';
	SET @sqltmp = @sqltmp + N'			AND l.ship_at > ''' + convert(varchar,@starttime,21) + '''';
	SET @sqltmp = @sqltmp + N'			AND l.ship_at <= ''' + convert(varchar,@v_shiptimemax,21) + '''';
	SET @sqltmp = @sqltmp + N') AS t1 ';
	SET @sqltmp = @sqltmp + N'	INNER JOIN ' + @objectnamedwh + '[dwh].[dim_days] AS dwh_days with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'		ON dwh_days.date_value = t1.date_value ';
	SET @sqltmp = @sqltmp + N'	INNER JOIN ' + @objectnamedwh + '[dwh].[dim_hours] AS dwh_hours with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'		ON dwh_hours.h = t1.h ';
	SET @sqltmp = @sqltmp + N'where t1.s_idx = 1 and t1.f_idx = 1 ';
	SET @sqltmp = @sqltmp + N'group by';
	SET @sqltmp = @sqltmp + N'		 dwh_days.id';
	SET @sqltmp = @sqltmp + N'		,dwh_hours.code';
	SET @sqltmp = @sqltmp + N'		,t1.[3_package_group_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[4_package_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[5_device_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[6_assy_name_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[7_factory_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[8_product_family_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[9_lot_id] ';
	SET @sqltmp = @sqltmp + N'		,t1.[10_input_pcs] ';
	SET @sqltmp = @sqltmp + N'		,t1.[11_pass_pcs] ';
	SET @sqltmp = @sqltmp + N'		,t1.[12_std_time] ';
	SET @sqltmp = @sqltmp + N'		,t1.in_at';
	SET @sqltmp = @sqltmp + N'		,t1.ship_at';

	PRINT '----------------------------------------';
	PRINT '@sqltmp=' + @sqltmp;

    ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------
	BEGIN TRY
		BEGIN TRANSACTION;
		EXECUTE (@sqltmp);
		set @rowcnt = @@ROWCOUNT
		set @logtext = '@sqltmp:OK row:' + convert(varchar,@rowcnt)
		print @logtext


		if @rowcnt > 0 
			begin
				EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='dwh.fact_shipment', @finished_at_=@v_shiptimemax, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
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

		SET @logtext = '[ERR] [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret)  + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg + '/SQL:' + @sqltmp;
		PRINT 'transaction err ' + @logtext;
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

	RETURN 0;

END ;



