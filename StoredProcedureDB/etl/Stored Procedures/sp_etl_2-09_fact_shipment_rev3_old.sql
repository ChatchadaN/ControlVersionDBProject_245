

create PROCEDURE [etl].[sp_etl_2-09_fact_shipment_rev3_old] (@v_ProServerName NVARCHAR(128) = ''
											,@v_ProDatabaseName NVARCHAR(128) = ''
											,@v_DwhDatabaseName NVARCHAR(128) = ''
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

		select @starttime = '2020-10-01'
		SELECT @starttime = isnull(dateadd(day,-10,finished_at),'2020-10-01')  FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
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
	SET @sqltmp = @sqltmp + N'insert into ' + @objectnamedwh + '[dwh].[fact_shipment] ';
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
	SET @sqltmp = @sqltmp + N'select '; 
	SET @sqltmp = @sqltmp + N'	t1.day_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.hour_code '; 
	SET @sqltmp = @sqltmp + N'	,t1.package_group_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.package_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.device_name_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.assy_name_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.factory_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.product_family_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.lot_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.qty_in '; 
	SET @sqltmp = @sqltmp + N'	,t1.qty_pass - (t1.qty_pass % t1.pcs_per_pack) as ship '; 
	SET @sqltmp = @sqltmp + N'	,t1.std_time '; 
	SET @sqltmp = @sqltmp + N'	,t1.lead_time '; 
	SET @sqltmp = @sqltmp + N'	,t1.lead_time - sum(DATEDIFF(MINUTE, t1.s_recorded_at, t1.f_recorded_at)) AS wait_time '; 
	SET @sqltmp = @sqltmp + N'	,sum(DATEDIFF(MINUTE, t1.s_recorded_at, t1.f_recorded_at)) AS process_time '; 
	SET @sqltmp = @sqltmp + N'from '; 
	SET @sqltmp = @sqltmp + N'( '; 
	SET @sqltmp = @sqltmp + N'select '; 
	SET @sqltmp = @sqltmp + N'	l.ship_date_id as day_id '; 
	SET @sqltmp = @sqltmp + N'	,l.ship_at '; 
	SET @sqltmp = @sqltmp + N'	,datepart(HOUR,l.ship_at) + 1 as hour_code '; 
	SET @sqltmp = @sqltmp + N'	,p.id as package_id '; 
	SET @sqltmp = @sqltmp + N'	,p.package_group_id '; 
	SET @sqltmp = @sqltmp + N'	,d.id as device_name_id '; 
	SET @sqltmp = @sqltmp + N'	,d.id as assy_name_id '; 
	SET @sqltmp = @sqltmp + N'	,hq.factory_id '; 
	SET @sqltmp = @sqltmp + N'	,p.product_family_id '; 
	SET @sqltmp = @sqltmp + N'	,l.id as lot_id '; 
	SET @sqltmp = @sqltmp + N'	,l.qty_in '; 
	SET @sqltmp = @sqltmp + N'	,l.qty_pass '; 
	SET @sqltmp = @sqltmp + N'	,isnull(d.pcs_per_pack,l.qty_pass) as pcs_per_pack '; 
	SET @sqltmp = @sqltmp + N'	,((l.out_plan_date_id - l.in_plan_date_id) * 24 * 60 ) as std_time '; 
	SET @sqltmp = @sqltmp + N'	,ISNULL(DATEDIFF(MINUTE,l.in_at,l.ship_at), 0) as lead_time '; 
	SET @sqltmp = @sqltmp + N'	,lot_rec_s.step_no '; 
	SET @sqltmp = @sqltmp + N'	,lot_rec_s.recorded_at as s_recorded_at '; 
	SET @sqltmp = @sqltmp + N'	,lot_rec_f.recorded_at as f_recorded_at '; 
	SET @sqltmp = @sqltmp + N'	,rank() over (partition by l.id,lot_rec_s.step_no order by lot_rec_s.id) as s_idx '; 
	SET @sqltmp = @sqltmp + N'	,rank() over (partition by l.id,lot_rec_f.step_no order by lot_rec_f.id desc) as f_idx '; 
	SET @sqltmp = @sqltmp + N'	,l.lot_no '; 
	SET @sqltmp = @sqltmp + N'from ' + @objectname + '[trans].[lots] as l '; 
	SET @sqltmp = @sqltmp + N'	inner join ' + @objectname + '[method].[device_names] as d '; 
	SET @sqltmp = @sqltmp + N'		on d.id = l.act_device_name_id '; 
	SET @sqltmp = @sqltmp + N'			and d.is_assy_only in(0,1) '; 
	SET @sqltmp = @sqltmp + N'	inner join ' + @objectname + '[method].[packages] as p '; 
	SET @sqltmp = @sqltmp + N'		on p.id = d.package_id '; 
	SET @sqltmp = @sqltmp + N'	inner join ' + @objectname + '[man].[product_headquarters] as h '; 
	SET @sqltmp = @sqltmp + N'		on h.product_family_id = p.product_family_id '; 
	SET @sqltmp = @sqltmp + N'	inner join ' + @objectname + '[man].[headquarters] as hq '; 
	SET @sqltmp = @sqltmp + N'		on hq.id = h.headquarter_id '; 
	SET @sqltmp = @sqltmp + N'	inner join ' + @objectname + '[trans].[lot_process_records] AS lot_rec_s with (NOLOCK) '; 
	SET @sqltmp = @sqltmp + N'				ON lot_rec_s.lot_id = l.id '; 
	SET @sqltmp = @sqltmp + N'					and lot_rec_s.record_class = 1 '; 
	SET @sqltmp = @sqltmp + N'	inner join ' + @objectname + '[trans].[lot_process_records] AS lot_rec_f with (NOLOCK) '; 
	SET @sqltmp = @sqltmp + N'		ON lot_rec_f.lot_id = l.id '; 
	SET @sqltmp = @sqltmp + N'			and lot_rec_f.record_class = 2 '; 
	SET @sqltmp = @sqltmp + N'			and lot_rec_f.step_no = lot_rec_s.step_no '; 
	SET @sqltmp = @sqltmp + N'where l.wip_state in(70,100) '; 
	SET @sqltmp = @sqltmp + N'	and l.ship_at >= ''' + convert(varchar,@starttime,21) + ''' and l.ship_at < ''' + convert(varchar,@endtime,21) + ''''; 
	SET @sqltmp = @sqltmp + N'	and not exists (select * from ' + @objectnamedwh + '[dwh].[fact_shipment] as f where f.lot_id = l.id) '; 
	SET @sqltmp = @sqltmp + N') as t1 '; 
	SET @sqltmp = @sqltmp + N'where t1.s_idx = 1 and t1.f_idx = 1 '; 
	SET @sqltmp = @sqltmp + N'group by '; 
	SET @sqltmp = @sqltmp + N'	t1.day_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.ship_at '; 
	SET @sqltmp = @sqltmp + N'	,t1.hour_code '; 
	SET @sqltmp = @sqltmp + N'	,t1.package_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.package_group_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.device_name_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.assy_name_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.factory_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.product_family_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.lot_id '; 
	SET @sqltmp = @sqltmp + N'	,t1.qty_in '; 
	SET @sqltmp = @sqltmp + N'	,t1.qty_pass '; 
	SET @sqltmp = @sqltmp + N'	,t1.std_time '; 
	SET @sqltmp = @sqltmp + N'	,t1.lead_time '; 
	SET @sqltmp = @sqltmp + N'	,t1.lot_no '; 
	SET @sqltmp = @sqltmp + N'	,t1.pcs_per_pack '; 

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
				EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='dwh.fact_shipment', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
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

		SET @logtext = '[ERR] [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret)  + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg +  '/SQL:' + @sqltmp;
		PRINT 'transaction err ' + @logtext;
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

	RETURN 0;

END ;



