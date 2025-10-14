

create PROCEDURE [etl].[sp_etl_1-08_jobs_old] (@v_ProServerName NVARCHAR(128) = ''
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
	DECLARE @sqltmp NVARCHAR(max) = '';
	DECLARE @sqltmp2 NVARCHAR(max) = '';
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
	DECLARE @endtime DATETIME;
	BEGIN TRY
		SELECT @functionname = OBJECT_NAME(@@PROCID);
		SELECT @endtime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'))
	END TRY
	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()
		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

    ---------------------------------------------------------------------------
	--(4)SQL  Make
    ---------------------------------------------------------------------------

	DECLARE @update_flg INT = 0;
	DECLARE @met_id INT;
	DECLARE @met_name NVARCHAR(20);
	DECLARE @met_process_no VARCHAR(10);
	DECLARE @met_job_no VARCHAR(10);
	DECLARE @man_factory_id INT;
	DECLARE @man_product_family_id INT;
	DECLARE @j_is_skipped INT;


	SET @sqltmp = N'';
	SET @sqltmp = @sqltmp + N'SELECT ';
	SET @sqltmp = @sqltmp + N'		t1.met_id ';
	SET @sqltmp = @sqltmp + N'		,t1.met_name ';
	SET @sqltmp = @sqltmp + N'		,t1.met_process_no ';
	SET @sqltmp = @sqltmp + N'		,t1.met_job_no ';
	SET @sqltmp = @sqltmp + N'		,t1.man_factory_id ';
	SET @sqltmp = @sqltmp + N'		,t1.man_product_family_id ';
	SET @sqltmp = @sqltmp + N'		,t1.is_skipped ';
	SET @sqltmp = @sqltmp + N'		,t1.update_flg ';
	SET @sqltmp = @sqltmp + N'FROM ( ';
	SET @sqltmp = @sqltmp + N'			SELECT ';
	SET @sqltmp = @sqltmp + N'				met.id as met_id ';
	SET @sqltmp = @sqltmp + N'				,met.name as met_name ';
	SET @sqltmp = @sqltmp + N'				,met.process_no as met_process_no ';
	SET @sqltmp = @sqltmp + N'				,met.job_no as met_job_no ';
	SET @sqltmp = @sqltmp + N'				,man.factory_id as man_factory_id ';
	SET @sqltmp = @sqltmp + N'				,man.id as man_product_family_id ';
	SET @sqltmp = @sqltmp + N'				,met.is_skipped as is_skipped ';
	SET @sqltmp = @sqltmp + N'				,CASE WHEN (met.id = dwh.id) THEN '; 
	SET @sqltmp = @sqltmp + N'						CASE WHEN (RTRIM(met.name) = RTRIM(dwh.name) COLLATE SQL_Latin1_General_CP1_CI_AS) THEN  ';
	SET @sqltmp = @sqltmp + N'							CASE WHEN RTRIM(isnull(met.process_no,'''')) = RTRIM(isnull(dwh.process_no,'''')) COLLATE SQL_Latin1_General_CP1_CI_AS THEN  ';
	SET @sqltmp = @sqltmp + N'								CASE WHEN RTRIM(isnull(met.job_no,'''')) = RTRIM(isnull(dwh.job_no,'''')) COLLATE SQL_Latin1_General_CP1_CI_AS THEN  ';
	SET @sqltmp = @sqltmp + N'									CASE WHEN isnull(man.factory_id,0) = isnull(dwh.factory_id,0) THEN  ';
	SET @sqltmp = @sqltmp + N'										CASE WHEN isnull(man.id,0) = isnull(dwh.product_family_id,0) THEN  ';
	SET @sqltmp = @sqltmp + N'											CASE WHEN isnull(met.is_skipped,0) = isnull(dwh.is_skipped,0)  ';
	SET @sqltmp = @sqltmp + N'													THEN 0  ';
	SET @sqltmp = @sqltmp + N'													ELSE 2  ';
	SET @sqltmp = @sqltmp + N'													END  ';
	SET @sqltmp = @sqltmp + N'											ELSE 2  ';
	SET @sqltmp = @sqltmp + N'											END  ';
	SET @sqltmp = @sqltmp + N'										ELSE 2  ';
	SET @sqltmp = @sqltmp + N'										END  ';
	SET @sqltmp = @sqltmp + N'									ELSE 2  ';
	SET @sqltmp = @sqltmp + N'									END  ';
	SET @sqltmp = @sqltmp + N'								ELSE 2  ';
	SET @sqltmp = @sqltmp + N'								END  ';
	SET @sqltmp = @sqltmp + N'							ELSE 2  ';
	SET @sqltmp = @sqltmp + N'							END  ';
	SET @sqltmp = @sqltmp + N'						ELSE 1  ';
	SET @sqltmp = @sqltmp + N'						END AS update_flg  ';


	SET @sqltmp = @sqltmp + N'			FROM '; 
	SET @sqltmp = @sqltmp + N'				(select '; 
	SET @sqltmp = @sqltmp + N'						 j.id '; 
	SET @sqltmp = @sqltmp + N'						 ,j.name ';
	SET @sqltmp = @sqltmp + N'						 ,p.id as process_id ';
	SET @sqltmp = @sqltmp + N'						 ,p.process_no ';
	SET @sqltmp = @sqltmp + N'						 ,j.job_no ';
	SET @sqltmp = @sqltmp + N'						 ,j.is_skipped ';
	SET @sqltmp = @sqltmp + N'						 ,pr.factory_id ';
	SET @sqltmp = @sqltmp + N'						 ,j.product_family_id ';
	SET @sqltmp = @sqltmp + N'					from ' + @objectname + 'method.jobs as j with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'						left outer join ' + @objectname + 'method.processes as p with (NOLOCK) '; 
	SET @sqltmp = @sqltmp + N'							on p.id = j.process_id ';
	SET @sqltmp = @sqltmp + N'						left outer join ' + @objectname + 'man.product_families as pr with (NOLOCK) '; 
	SET @sqltmp = @sqltmp + N'							on pr.id = j.product_family_id ';
	SET @sqltmp = @sqltmp + N'					union  '; 
	SET @sqltmp = @sqltmp + N'					select 0 as id,N''PRE_DC'' as name,0 as process_id, ''0011'' as process_no,''0011'' as job_no ,0 as is_skipped, 1 as factory_id,1 as product_family_id ';
	SET @sqltmp = @sqltmp + N'					union ';  
	SET @sqltmp = @sqltmp + N'					select -1 as id,N''PRE_PLAN'' as name,-1 as process_id, ''0010'' as process_no,''0010'' as job_no ,0 as is_skipped, 1 as factory_id,1 as product_family_id ';
	SET @sqltmp = @sqltmp + N'				) as met '; 
	SET @sqltmp = @sqltmp + N'				LEFT OUTER JOIN [apcsprodwh].[dwh].[dim_jobs] AS dwh with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON dwh.id = met.id ';
	SET @sqltmp = @sqltmp + N'				LEFT OUTER JOIN ' + @objectname + '[method].[processes] AS met_p with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON met_p.id = met.process_id ';
	SET @sqltmp = @sqltmp + N'				LEFT OUTER JOIN ' + @objectname + '[man].[product_families] AS man with (NOLOCK) ';
	SET @sqltmp = @sqltmp + N'					ON man.id = met.product_family_id ';
	SET @sqltmp = @sqltmp + N'		) AS t1 ';
	SET @sqltmp = @sqltmp + N'WHERE t1.update_flg > 0 ';

	PRINT '----------------------------------------';
	PRINT @sqltmp;

    ---------------------------------------------------------------------------
	--(5) Open Cur
    ---------------------------------------------------------------------------
	EXECUTE ('DECLARE Cur_jobs CURSOR FOR ' + @sqltmp );
	OPEN Cur_jobs;

	FETCH NEXT FROM Cur_jobs
	INTO
		 @met_id
		,@met_name
		,@met_process_no
		,@met_job_no
		,@man_factory_id
		,@man_product_family_id
		,@j_is_skipped
		,@update_flg;

    ---------------------------------------------------------------------------
	--(6) update
    ---------------------------------------------------------------------------
	BEGIN TRY

		BEGIN TRANSACTION;

		WHILE @@FETCH_STATUS = 0

			BEGIN

				IF @update_flg = 1	--INSERT
					BEGIN
						INSERT INTO [apcsprodwh].[dwh].[dim_jobs]
							(id
							,name
							,process_no
							,job_no
							,factory_id
							,product_family_id
							,is_skipped
							)
						VALUES
							(@met_id
							,@met_name
							,@met_process_no
							,@met_job_no
							,@man_factory_id
							,@man_product_family_id
							,@j_is_skipped
							);
					END;

				ELSE	--UPDATE
					BEGIN
						UPDATE [apcsprodwh].[dwh].[dim_jobs]
						SET    name = @met_name
								,process_no = @met_process_no
								,job_no = @met_job_no
								,factory_id = @man_factory_id
								,product_family_id = @man_product_family_id
								,is_skipped = @j_is_skipped
						WHERE id = @met_id;
					END;
 

				FETCH NEXT FROM Cur_jobs
				INTO
					 @met_id
					,@met_name
					,@met_process_no
					,@met_job_no
					,@man_factory_id
					,@man_product_family_id
					,@j_is_skipped
					,@update_flg;

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

		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

    ---------------------------------------------------------------------------
	--(7)close
    ---------------------------------------------------------------------------
	CLOSE Cur_jobs;
	DEALLOCATE Cur_jobs;

    ---------------------------------------------------------------------------
	--(8)SQL  Make2
    ---------------------------------------------------------------------------
	DECLARE @package_id INT;
	DECLARE @process_id INT;
	DECLARE @process_name NVARCHAR(30);
	DECLARE @process_no VARCHAR(10);
	DECLARE @job_id INT;
	DECLARE @job_name NVARCHAR(30);
	DECLARE @job_no VARCHAR(10);
	DECLARE @is_skipped INT;
	DECLARE @update_flg1 INT = 0;
	DECLARE @update_flg2 INT = 0;

SET @sqltmp2 = N'';
SET @sqltmp2 = @sqltmp2 + N'select  ';
SET @sqltmp2 = @sqltmp2 + N'	pk.id as package_id ';
SET @sqltmp2 = @sqltmp2 + N'	,jp.process_id  as process_id ';
SET @sqltmp2 = @sqltmp2 + N'	,jp.process_no as process_no ';
SET @sqltmp2 = @sqltmp2 + N'	,jp.process_name as process_name ';
SET @sqltmp2 = @sqltmp2 + N'	,jp.job_id  as job_id ';
SET @sqltmp2 = @sqltmp2 + N'	,jp.job_no as job_no ';
SET @sqltmp2 = @sqltmp2 + N'	,jp.job_name as job_name ';
SET @sqltmp2 = @sqltmp2 + N'	,fm.factory_id as man_factory_id  ';
SET @sqltmp2 = @sqltmp2 + N'	,fm.id as man_product_family_id  ';
SET @sqltmp2 = @sqltmp2 + N'	,min(isnull(case when pk.is_enabled = 1 then df.is_skipped else jp.is_skipped end,0)) as is_skipped ';
SET @sqltmp2 = @sqltmp2 + N'	,CASE WHEN (pk.id = pj.package_id)  ';
SET @sqltmp2 = @sqltmp2 + N'			THEN case when (jp.process_id = pj.process_id)  ';
SET @sqltmp2 = @sqltmp2 + N'				THEN case when (jp.job_id = pj.job_id)  ';
SET @sqltmp2 = @sqltmp2 + N'							then CASE WHEN (RTRIM(jp.process_name) = RTRIM(pj.process_name) COLLATE SQL_Latin1_General_CP1_CI_AS)  ';
SET @sqltmp2 = @sqltmp2 + N'										THEN CASE WHEN isnull(RTRIM(jp.process_no),'''') = isnull(RTRIM(pj.process_no),'''') COLLATE SQL_Latin1_General_CP1_CI_AS  ';
SET @sqltmp2 = @sqltmp2 + N'													then CASE WHEN (RTRIM(jp.job_name) = RTRIM(pj.job_name) COLLATE SQL_Latin1_General_CP1_CI_AS)  ';
SET @sqltmp2 = @sqltmp2 + N'																THEN CASE WHEN isnull(RTRIM(jp.job_no),'''') = isnull(RTRIM(pj.job_no),'''') COLLATE SQL_Latin1_General_CP1_CI_AS  ';
SET @sqltmp2 = @sqltmp2 + N'																			THEN CASE WHEN isnull(fm.factory_id,0) = isnull(pj.factory_id,0)  ';
SET @sqltmp2 = @sqltmp2 + N'																						THEN CASE WHEN isnull(fm.id,0) = isnull(pj.product_family_id,0)  ';
SET @sqltmp2 = @sqltmp2 + N'																									THEN 0  ';
SET @sqltmp2 = @sqltmp2 + N'																									ELSE 2  ';
SET @sqltmp2 = @sqltmp2 + N'																									END  ';
SET @sqltmp2 = @sqltmp2 + N'																						ELSE 2  ';
SET @sqltmp2 = @sqltmp2 + N'																						END  ';
SET @sqltmp2 = @sqltmp2 + N'																			ELSE 2  ';
SET @sqltmp2 = @sqltmp2 + N'																			END  ';
SET @sqltmp2 = @sqltmp2 + N'																ELSE 2  ';
SET @sqltmp2 = @sqltmp2 + N'																END  ';
SET @sqltmp2 = @sqltmp2 + N'													ELSE 2  ';
SET @sqltmp2 = @sqltmp2 + N'													END  ';
SET @sqltmp2 = @sqltmp2 + N'										ELSE 2  ';
SET @sqltmp2 = @sqltmp2 + N'										END  ';
SET @sqltmp2 = @sqltmp2 + N'							ELSE 2  ';
SET @sqltmp2 = @sqltmp2 + N'							END  ';
SET @sqltmp2 = @sqltmp2 + N'				ELSE 2  ';
SET @sqltmp2 = @sqltmp2 + N'				END  ';
SET @sqltmp2 = @sqltmp2 + N'			ELSE 1 ';
SET @sqltmp2 = @sqltmp2 + N'			END AS update_flg1  ';
SET @sqltmp2 = @sqltmp2 + N'	,case when min(isnull(case when pk.is_enabled = 1 then df.is_skipped else jp.is_skipped end,0)) <> isnull(pj.is_skipped,0) then 2 else 0 end as update_flg2 ';
SET @sqltmp2 = @sqltmp2 + N'FROM ' + @objectname + 'method.packages as pk with (NOLOCK)  ';
SET @sqltmp2 = @sqltmp2 + N'	inner join ' + @objectname + 'method.device_names as d with (NOLOCK)  ';
SET @sqltmp2 = @sqltmp2 + N'		on d.package_id = pk.id  ';
SET @sqltmp2 = @sqltmp2 + N'			and d.is_assy_only in(0,1)  ';
SET @sqltmp2 = @sqltmp2 + N'	inner join ' + @objectname + 'method.device_versions as dv with (NOLOCK)  ';
SET @sqltmp2 = @sqltmp2 + N'		on dv.device_name_id = d.id  ';
SET @sqltmp2 = @sqltmp2 + N'	inner join ' + @objectname + 'method.device_slips as ds with (NOLOCK)  ';
SET @sqltmp2 = @sqltmp2 + N'		on ds.device_id = dv.device_id  ';
SET @sqltmp2 = @sqltmp2 + N'			and ds.is_released in(1,2) ';
SET @sqltmp2 = @sqltmp2 + N'	inner join ' + @objectname + 'method.device_flows as df with (NOLOCK)  ';
SET @sqltmp2 = @sqltmp2 + N'		on df.device_slip_id = ds.device_slip_id  ';
SET @sqltmp2 = @sqltmp2 + N'	inner join (';
SET @sqltmp2 = @sqltmp2 + N'				select j.id as job_id,j.name as job_name,j.job_no,isnull(j.is_skipped,0) as is_skipped,p.id as process_id,p.process_no as process_no,p.name as process_name,j.product_family_id from ' + @objectname + 'method.jobs AS j with (NOLOCK)  ';
SET @sqltmp2 = @sqltmp2 + N'					left outer join ' + @objectname + 'method.processes AS p with (NOLOCK)  ';
SET @sqltmp2 = @sqltmp2 + N'						on p.id = j.process_id';
SET @sqltmp2 = @sqltmp2 + N'				union all ';
SET @sqltmp2 = @sqltmp2 + N'						select  j.id as job_id,j.name as job_name,j.job_no,isnull(j.is_skipped,0) as is_skipped,p.id as process_id,p.process_no as process_no,p.name as process_name,p.product_family_id from APCSProDWH.dwh.dim_jobs as j with (NOLOCK) ';
SET @sqltmp2 = @sqltmp2 + N'							inner join apcsprodwh.dwh.dim_processes as p with (NOLOCK) ';
SET @sqltmp2 = @sqltmp2 + N'								on p.process_no = j.process_no ';
SET @sqltmp2 = @sqltmp2 + N'						where j.job_no in(''0011'',''0010'')';
SET @sqltmp2 = @sqltmp2 + N'				) as jp';
SET @sqltmp2 = @sqltmp2 + N'				on jp.job_id = df.job_id or jp.job_no in(''0011'',''0010'')';
SET @sqltmp2 = @sqltmp2 + N'	LEFT OUTER JOIN [apcsprodwh].[dwh].[dim_package_jobs] AS pj with (NOLOCK)  ';
SET @sqltmp2 = @sqltmp2 + N'		ON pj.package_id = pk.id  ';
SET @sqltmp2 = @sqltmp2 + N'			and pj.process_id = jp.process_id  ';
SET @sqltmp2 = @sqltmp2 + N'			and pj.job_id = jp.job_id  ';
SET @sqltmp2 = @sqltmp2 + N'	LEFT OUTER JOIN ' + @objectname + '[man].[product_families] AS fm with (NOLOCK)  ';
SET @sqltmp2 = @sqltmp2 + N'		ON fm.id = jp.product_family_id  ';
SET @sqltmp2 = @sqltmp2 + N'where ';
SET @sqltmp2 = @sqltmp2 + N'	exists (select * from ' + @objectname + 'trans.lots as l2 ';
SET @sqltmp2 = @sqltmp2 + N'			where l2.device_slip_id = ds.device_slip_id ';
SET @sqltmp2 = @sqltmp2 + N'					and (l2.wip_state <=20 or (l2.wip_state in(100,101) and dateadd(month,1,l2.ship_at) > getdate())) ';
SET @sqltmp2 = @sqltmp2 + N'					and substring(l2.lot_no,5,1) = ''A'') ';
SET @sqltmp2 = @sqltmp2 + N'group by ';
SET @sqltmp2 = @sqltmp2 + N'	pk.id ';
SET @sqltmp2 = @sqltmp2 + N'	,jp.process_id';
SET @sqltmp2 = @sqltmp2 + N'	,jp.process_no';
SET @sqltmp2 = @sqltmp2 + N'	,jp.process_name';
SET @sqltmp2 = @sqltmp2 + N'	,jp.job_id';
SET @sqltmp2 = @sqltmp2 + N'	,jp.job_no';
SET @sqltmp2 = @sqltmp2 + N'	,jp.job_name';
SET @sqltmp2 = @sqltmp2 + N'	,fm.factory_id ';
SET @sqltmp2 = @sqltmp2 + N'	,fm.id ';
SET @sqltmp2 = @sqltmp2 + N'	,pj.package_id ';
SET @sqltmp2 = @sqltmp2 + N'	,pj.process_no ';
SET @sqltmp2 = @sqltmp2 + N'	,pj.process_id ';
SET @sqltmp2 = @sqltmp2 + N'	,pj.process_name ';
SET @sqltmp2 = @sqltmp2 + N'	,pj.job_id ';
SET @sqltmp2 = @sqltmp2 + N'	,pj.job_no ';
SET @sqltmp2 = @sqltmp2 + N'	,pj.job_name ';
SET @sqltmp2 = @sqltmp2 + N'	,pj.factory_id  ';
SET @sqltmp2 = @sqltmp2 + N'	,pj.product_family_id ';
SET @sqltmp2 = @sqltmp2 + N'	,isnull(pj.is_skipped,0) ';
SET @sqltmp2 = @sqltmp2 + N'	,pk.is_enabled ';
SET @sqltmp2 = @sqltmp2 + N'	,isnull(jp.is_skipped,0) 	';
SET @sqltmp2 = @sqltmp2 + N'order by pk.id,jp.process_no,jp.job_no ';

    ---------------------------------------------------------------------------
	--(9) Open Cur2
    ---------------------------------------------------------------------------
	EXECUTE ('DECLARE Cur_package_jobs CURSOR FOR ' + @sqltmp2 ) ;
	OPEN Cur_package_jobs;

	FETCH NEXT FROM Cur_package_jobs
	INTO
		 @package_id
		,@process_id
		,@process_no
		,@process_name
		,@job_id
		,@job_no
		,@job_name
		,@man_factory_id
		,@man_product_family_id
		,@is_skipped
		,@update_flg1
		,@update_flg2;

    ---------------------------------------------------------------------------
	--(10) update (package_processes)
    ---------------------------------------------------------------------------
	BEGIN TRY
		BEGIN TRANSACTION;

		WHILE @@FETCH_STATUS = 0

			BEGIN
				IF @update_flg1 = 1	--INSERT
						BEGIN
							INSERT INTO [apcsprodwh].[dwh].[dim_package_jobs]
								(package_id
								,process_id
								,process_no
								,process_name
								,job_id
								,job_no
								,job_name
								,factory_id
								,product_family_id
								,is_skipped
								)
							VALUES
								(@package_id
								,@process_id
								,@process_no
								,@process_name
								,@job_id
								,@job_no
								,@job_name
								,@man_factory_id
								,@man_product_family_id
								,@is_skipped
								);
						END;
				ELSE 
					BEGIN
						IF @update_flg2 = 2 or @update_flg1 = 2	--UPDATE
								BEGIN
									UPDATE [apcsprodwh].[dwh].[dim_package_jobs]
									SET    process_name = @process_name
											,process_no = @process_no
											,job_name = @job_name
											,job_no = @job_no
											,factory_id = @man_factory_id
											,product_family_id = @man_product_family_id
											,is_skipped = @is_skipped

									WHERE package_id = @package_id
										and process_id = @process_id
										and job_id = @job_id;
								END;
					END; 

				FETCH NEXT FROM Cur_package_jobs
				INTO
					 @package_id
					,@process_id
					,@process_no
					,@process_name
					,@job_id
					,@job_no
					,@job_name
					,@man_factory_id
					,@man_product_family_id
					,@is_skipped
					,@update_flg1
					,@update_flg2;
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

		SET @logtext = '[ERR]' + ERROR_MESSAGE();
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

    ---------------------------------------------------------------------------
	--(11)close2
    ---------------------------------------------------------------------------
	CLOSE Cur_package_jobs;
	DEALLOCATE Cur_package_jobs;


























	---------------------------------------------------------------------------
	--(8)[sp_update_function_finish_control]
	---------------------------------------------------------------------------
	BEGIN TRY
		EXECUTE @ret = [etl].[sp_update_function_finish_control] @function_name_=@functionname,@to_fact_table_='', @finished_at_=@endtime, @errnum = @errnum output, @errline = @errline output, @errmsg = @errmsg output;
			IF @ret<>0
				begin
					SET @logtext = '@ret<>0 [sp_update_function_finish_control]' +'/ret:' + convert(varchar,@ret) + N'/num:' + convert(varchar,@errnum) + N'/line:' + convert(varchar,@errline) + '/msg:' + @errmsg;				
					PRINT 'sp_update_function_finish_control:NG' + convert(varchar,@ret) + @logtext;
					--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;

					return -1;
				end;
	END TRY
	BEGIN CATCH
		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = '[ERR2]' + @errmsg;
		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;

	RETURN 0;

END;
