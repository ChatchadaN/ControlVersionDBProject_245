
CREATE PROCEDURE [etl].[sp_etl_2-06_fact_end] (@v_ProServerName NVARCHAR(128) = ''
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
	DECLARE @sqlins VARCHAR(max) = '';
	DECLARE @sqltmp VARCHAR(max) = '';
	DECLARE @sqltmpSelect VARCHAR(max) = '';
	DECLARE @sqltmp2 VARCHAR(max) = '';
	DECLARE @sqltmp3 VARCHAR(max) = '';

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

SELECT @starttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000')) FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
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
	SET @sqlins = '';
	SET @sqltmp = '';
	set @sqltmpSelect = '';
	SET @sqltmp2 = '';

	SET @sqlins = cast(@sqlins  as varchar(max)) + ' INSERT INTO apcsprodwh.dwh.fact_end ';
	SET @sqlins = cast(@sqlins  as varchar(max)) + '(day_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',hour_code';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',package_group_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',package_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',device_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',assy_name_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',factory_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',product_family_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',lot_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',process_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',job_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',input_pcs';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',pass_pcs';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',[code]';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',machine_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',machine_model_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',std_time';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',wait_time';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',process_time';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',run_time';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',started_at';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',production_category';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',t1.next_process_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ',t1.next_job_id';
	SET @sqlins = cast(@sqlins  as varchar(max)) + ')';

	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ' SELECT ';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ' dwh_days.id AS day_id';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',dwh_hours.code AS hour_code';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.package_group_id';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.package_id';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.device_name_id';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.assy_name_id';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.factory_id';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.product_family_id';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.lot_id';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.process_id';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.job_id';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.input_pcs';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.pass_pcs';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.[code]';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.machine_id';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.machine_model_id';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.std_time';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',isnull(SUM(rec0.wait_time),0) AS wait_time';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',isnull(DATEDIFF(MINUTE, t1.rec1_recorded_at, t1.rec2_recorded_at),0) AS process_time';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',isnull(t1.run_time,0) as run_time ';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',t1.started_at';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',case substring(t1.lot_no,5,1) ';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + '		when ''A'' then 0 when ''V'' then 1 when ''W'' then 2 when ''X'' then 3 when ''Y'' then 4 ';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + '		when ''B'' then 10 when ''Q'' then 11 when ''R'' then 12 when ''S'' then 13 when ''T'' then 14 ';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + '		when ''D'' then 20 ';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + '		when ''E'' then 30 when ''5'' then 31 when ''6'' then 32 when ''7'' then 33 when ''8'' then 34 ';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + '		when ''F'' then 40 when ''K'' then 41 when ''L'' then 42 when ''M'' then 43 when ''N'' then 44 ';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + '		when ''G'' then 50 when ''0'' then 51 when ''1'' then 52 when ''2'' then 53 when ''3'' then 54 ';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + '		when ''H'' then 60 when ''P'' then 61 when ''U'' then 62 when ''Z'' then 63 when ''4'' then 64 else 0 end as production_category ';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',case when t1.job_id = 3 then t1.db_process_id else t1.next_process_id end as next_process_id ';
	SET @sqltmpSelect = cast(@sqltmpSelect as varchar(max)) + ',case when t1.job_id = 3 then t1.db_job_id else t1.next_job_id end as next_job_id ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ' FROM';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '(';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	SELECT ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'CONVERT(DATE, rec2.recorded_at) AS date_value';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',DATEPART(HOUR, rec2.recorded_at) AS h';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',d_pkg.package_group_id AS package_group_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',lots.act_package_id AS package_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',lots.act_device_name_id AS device_name_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',d_assy.id AS assy_name_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',prd.factory_id AS factory_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',lots.product_family_id AS product_family_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec2.lot_id AS lot_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec2.process_id AS process_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec2.job_id AS job_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',isnull(rec1.qty_pass,0) AS input_pcs';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',isnull(rec2.qty_pass,0) AS pass_pcs';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',CASE WHEN devflow.rank_no_last = 1 THEN 2 ELSE CASE WHEN devflow.rank_no_top = 1 THEN 1 ELSE 0 END END AS [code]';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec2.machine_id AS machine_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',mcn.machine_model_id AS machine_model_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',ISNULL(devflow.process_minutes, 0) AS std_time';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',null AS run_time';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec1.recorded_at AS started_at';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec1.recorded_at AS rec1_recorded_at';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec2.recorded_at AS rec2_recorded_at';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec1.id AS rec1_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec2.id AS rec2_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rtrim(lots.lot_no) as lot_no';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',f_next.act_process_id as next_process_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',f_next.job_id as next_job_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',f1.act_process_id as db_process_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',f1.job_id as db_job_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	FROM ' + @objectname + 'trans.lot_process_records AS rec2 with (NOLOCK) ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'INNER JOIN (';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	SELECT ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'rec1base.id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec1base.recorded_at';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec1base.lot_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec1base.job_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',rec1base.qty_pass';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '  FROM (';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	SELECT ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',recorded_at';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',lot_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',job_id';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',qty_pass';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ',RANK() OVER (PARTITION BY lot_id, job_id ORDER BY id) AS rank1';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ' FROM ' + @objectname + 'trans.lot_process_records with (NOLOCK) ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	WHERE record_class = 1 ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'AND process_state IN (2,102)';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + ') AS rec1base ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	WHERE rec1base.rank1 = 1';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	) AS rec1 ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	ON rec1.lot_id = rec2.lot_id ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'AND rec1.job_id = rec2.job_id ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'INNER JOIN ' + @objectname + 'trans.lots AS lots with (NOLOCK) ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	ON lots.id = rec2.lot_id ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	AND lots.id > 6 ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	left outer join APCSProDB.method.device_flows as f with (NOLOCK) ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	on f.device_slip_id = lots.device_slip_id ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	and f.step_no = rec2.step_no ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	and f.step_no <> f.next_step_no ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	left outer join APCSProDB.method.device_flows as f_next with (NOLOCK) ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	on f_next.device_slip_id = lots.device_slip_id ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	and f_next.step_no = f.next_step_no '; 
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	left outer join APCSProDB.method.device_flows as f1 with (NOLOCK) ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	on f1.device_slip_id = lots.device_slip_id ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	and f1.step_no = 100 '; 

	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'INNER JOIN ' + @objectname + 'man.product_families AS prd with (NOLOCK) ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	ON prd.id = lots.product_family_id ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'AND RTRIM(prd.product_code) = RTRIM((';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'SELECT val FROM apcsprodwh.dwh.act_settings with (NOLOCK) WHERE name = ''ProductFamilyCode'')) COLLATE SQL_Latin1_General_CP1_CI_AS ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'INNER JOIN apcsprodwh.dwh.dim_packages AS d_pkg with (NOLOCK) ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	ON d_pkg.id = lots.act_package_id ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'INNER JOIN ' + @objectname + 'method.device_names AS dev with (NOLOCK) ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	ON dev.id = lots.act_device_name_id ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'AND dev.is_assy_only in (0,1) ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'INNER JOIN apcsprodwh.dwh.dim_assy_device_names AS d_assy with (NOLOCK) ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	ON d_assy.id = dev.id ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + 'INNER JOIN ' + @objectname + 'mc.machines AS mcn with (NOLOCK) ';
	SET @sqltmp = cast(@sqltmp as varchar(max)) + '	ON mcn.id = rec2.machine_id ';
	SET @sqltmp3 =									'LEFT OUTER JOIN (';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + '	SELECT ';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + 'step_no';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + ',device_slip_id';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + ',job_id';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + ',process_minutes';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + ',rank_no_top';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + ',rank_no_last';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + '	FROM (';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + '	SELECT ';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + 'step_no';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + ',device_slip_id';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + ',act_process_id';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + ',job_id';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + ',process_minutes';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + ',RANK() OVER (PARTITION BY device_slip_id, act_process_id ORDER BY step_no ) AS rank_no_top';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + ',RANK() OVER (PARTITION BY device_slip_id, act_process_id ORDER BY step_no DESC ) AS rank_no_last';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + '	FROM ' + @objectname + 'method.device_flows with (NOLOCK) ';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + '	WHERE (is_skipped IS NULL OR is_skipped = 0) ';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + 'AND act_process_id IS NOT NULL ';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + '	) AS devdev';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + '	WHERE (rank_no_top = 1 OR rank_no_last = 1) ';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + ') AS devflow ';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + '	ON devflow.device_slip_id = lots.device_slip_id ';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + 'AND devflow.job_id = rec2.job_id ';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + '	WHERE rec2.record_class = 2 and rec2.process_id is not null ';
	BEGIN
IF @starttime IS NOT NULL 
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + 'AND rec2.recorded_at >= ''' + FORMAT(@starttime, 'yyyy-MM-dd HH:mm:ss.fff') + ''' ';
	END
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + 'AND rec2.recorded_at < ''' + FORMAT(@endtime, 'yyyy-MM-dd HH:mm:ss.fff') + ''' ';
	SET @sqltmp3 = cast(@sqltmp3 as varchar(max)) + '	) AS t1 ';

	SET @sqltmp2 =								 'INNER JOIN ' + @objectname + 'trans.lot_process_records AS rec0 with (NOLOCK) ';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + '	ON rec0.id <= t1.rec2_id ';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + 'AND rec0.id >= t1.rec1_id ';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + 'AND rec0.lot_id = t1.lot_id ';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + 'AND rec0.job_id = t1.job_id ';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + 'AND rec0.record_class = 1 ';

	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ' INNER JOIN apcsprodwh.dwh.dim_days AS dwh_days with (NOLOCK) ON dwh_days.date_value = t1.date_value ';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ' INNER JOIN apcsprodwh.dwh.dim_hours AS dwh_hours with (NOLOCK) ON dwh_hours.h = t1.h ';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ' GROUP BY ';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + 'dwh_days.id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',dwh_hours.[code]';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.package_group_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.package_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.device_name_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.assy_name_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.factory_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.product_family_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.lot_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.process_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.job_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.input_pcs';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.pass_pcs';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.[code]';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.machine_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.machine_model_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.std_time';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.run_time';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.started_at';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.rec1_recorded_at';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.rec2_recorded_at';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.lot_no';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.next_process_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.next_job_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.db_process_id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.db_job_id';

	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ' ORDER by ';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + 'dwh_days.id';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',dwh_hours.[code]';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.started_at';
	SET @sqltmp2 = cast(@sqltmp2 as varchar(max)) + ',t1.lot_id';


	PRINT '------------sqlins----------------------------';
	--PRINT convert(nvarchar(max),@sqlins)+convert(nvarchar(max),@sqltmp)+convert(nvarchar(max),@sqltmp2);
	--SET @sqlins = convert(nvarchar(max),@sqlins)+convert(nvarchar(max),@sqltmp)+convert(nvarchar(max),@sqltmp2);
	--SET @sqlins = cast(@sqlins as varchar(max)) + cast(@sqltmp as varchar(max)) + cast(@sqltmp3 as varchar(max)) + cast(@sqltmp2 as varchar(max));
	PRINT @sqlins;
	PRINT '------------sqltmpSelect---------------------------';
	PRINT @sqltmpSelect;
	PRINT '------------sqltmp----------------------------';
	PRINT @sqltmp;
	PRINT '------------sqltmp3----------------------------';
	PRINT @sqltmp3;
	PRINT '------------sqltmp2----------------------------';
	PRINT @sqltmp2;
	SET @sqlins = cast(@sqlins as varchar(max)) + @sqltmpSelect;
	SET @sqlins = cast(@sqlins as varchar(max)) + @sqltmp;
	SET @sqlins = cast(@sqlins as varchar(max)) + @sqltmp3;
	SET @sqlins = cast(@sqlins as varchar(max)) + @sqltmp2;

    ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------

	BEGIN TRY
		BEGIN TRANSACTION;
			--EXECUTE (@sqlins+@sqltmp+@sqltmp2);
			EXECUTE (@sqlins) ;
			set @rowcnt = @@ROWCOUNT
			set @logtext = '@sqltmp:OK row:' + convert(varchar,@rowcnt)
			print @logtext
			EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='dwh.fact_end', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
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

		SET @logtext = '[ERR] [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret) + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg + '/SQL:' + @sqlins ;
		PRINT 'transaction err ' + @logtext;
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;


	RETURN 0;

END ;
