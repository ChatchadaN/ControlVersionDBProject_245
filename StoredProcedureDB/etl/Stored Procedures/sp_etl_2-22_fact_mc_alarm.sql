



-- =============================================
-- Author:		<M.Yamamoto>
-- Create date: <17th Jun 2019>
-- Description:	<>
-- =============================================
CREATE PROCEDURE [etl].[sp_etl_2-22_fact_mc_alarm] (@ServerName_APCSPro NVARCHAR(128) 
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
	--(1) Declare
    ---------------------------------------------------------------------------

	DECLARE @pObjAPCSPro NVARCHAR(128) = N'APCSProDB'
	DECLARE @pObjAPCSProDWH NVARCHAR(128) = N''

	DECLARE @pFunctionName NVARCHAR(128) = N'';
	DECLARE @pStarttime DATETIME;
	DECLARE @pEndTime DATETIME;

	DECLARE @pRet INT = 0;
	DECLARE @pStepNo INT = 0; 

	DECLARE @pSqlInsOn NVARCHAR(4000) = N'';
	DECLARE @pSqlInsOff NVARCHAR(4000) = N'';
	DECLARE @pSqlInsStart NVARCHAR(4000) = N'';
	

	DECLARE @pSqlRowCnt NVARCHAR(4000) = N'';

	DECLARE @pRowCnt INT = 0;

	---------------------------------------------------------------------------
	--(1) connection string
    ---------------------------------------------------------------------------
	BEGIN
		IF RTRIM(@DatabaseName_APCSPro) = '' RETURN 1;
	END;

	BEGIN
		IF RTRIM(@DatabaseName_APCSProDWH) = '' RETURN 1;
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
	--(3) get function_finish_control last_finish
    ---------------------------------------------------------------------------
	BEGIN TRY
		SELECT @pFunctionName = OBJECT_NAME(@@PROCID);
		SELECT @pStarttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000')) FROM [APCSProDWH].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
		-- 2019-08-30 Add
		SET @pStarttime = ISNULL(@pStarttime,convert(datetime,'2019-08-01 00:00:00.000',21));

		PRINT '@starttime=' + CASE WHEN @pStarttime IS NULL THEN '' ELSE FORMAT(@pStarttime, 'yyyy-MM-dd HH:mm:ss.fff') END;
		--yyyy/MM/dd HH:mm:ss.ff3
		SELECT @pEndTime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'))
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
	--(4)SQL  Make
    ---------------------------------------------------------------------------
	BEGIN
		SET @psqlInsOn = N'';
		SET @psqlInsOn = @psqlInsOn + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[fact_mc_alarm] ';
		SET @psqlInsOn = @psqlInsOn + N'( ';
		SET @psqlInsOn = @psqlInsOn + N'	id ';
		SET @psqlInsOn = @psqlInsOn + N'	,day_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,hour_code ';
		SET @psqlInsOn = @psqlInsOn + N'	,package_group_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,package_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,device_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,assy_name_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,factory_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,product_family_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,process_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,job_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,machine_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,machine_model_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,processing_code ';
		SET @psqlInsOn = @psqlInsOn + N'	,alarm_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,alarm_level ';
		SET @psqlInsOn = @psqlInsOn + N'	,on_at ';
		SET @psqlInsOn = @psqlInsOn + N') ';
		SET @psqlInsOn = @psqlInsOn + N'select ';
		SET @psqlInsOn = @psqlInsOn + N'	t2.id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.day_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.hour_code ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.package_group_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.package_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.device_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.assy_name_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.factory_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.product_family_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.process_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.job_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.machine_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.machine_model_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.processing_code ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.alarm_id ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.alarm_level ';
		SET @psqlInsOn = @psqlInsOn + N'	,t2.alarm_on_at on_at ';
		-- for additional condition of on
		/*
		SET @psqlInsOn = @psqlInsOn + N'	,case when t2.alarm_on_at <= t2.updated_at then ';
		SET @psqlInsOn = @psqlInsOn + N'		case when isnull(dwh_on.id,0) = 0 then 1 ';
		SET @psqlInsOn = @psqlInsOn + N'		else 0 end ';
		SET @psqlInsOn = @psqlInsOn + N'	else 0 end flag_on_add ';
		*/
		-- for add to fact_mc_alarm flag_off_add = 1 and off_id = 0
		/*
		SET @psqlInsOn = @psqlInsOn + N'	,case when t2.alarm_off_at <= t2.updated_at then ';
		SET @psqlInsOn = @psqlInsOn + N'		case when isnull(dwh_off.id,0) = 0 then 1 ';
		SET @psqlInsOn = @psqlInsOn + N'		else 0 end ';
		SET @psqlInsOn = @psqlInsOn + N'	else 0 end flag_off_add ';
		*/
		-- for add to fact_mc_alarm flag_start_add = 1 and start_id = 0
		/*
		SET @psqlInsOn = @psqlInsOn + N'	,case when t2.alarm_off_at <= t2.updated_at then ';
		SET @psqlInsOn = @psqlInsOn + N'		case when isnull(dwh_start.id,0) = 0 then 1 ';
		SET @psqlInsOn = @psqlInsOn + N'		else 0 end ';
		SET @psqlInsOn = @psqlInsOn + N'	else 0 end flag_start_add ';
		*/
		SET @psqlInsOn = @psqlInsOn + N'from ';
		--<<t2
		SET @psqlInsOn = @psqlInsOn + N'( ';
		SET @psqlInsOn = @psqlInsOn + N'	select ';
		SET @psqlInsOn = @psqlInsOn + N'		t1.id ';
		SET @psqlInsOn = @psqlInsOn + N'		,dt.id day_id ';
		SET @psqlInsOn = @psqlInsOn + N'		,hr.code hour_code ';
		SET @psqlInsOn = @psqlInsOn + N'		,pkg.package_group_id ';
		SET @psqlInsOn = @psqlInsOn + N'		,lot.act_package_id package_id ';
		SET @psqlInsOn = @psqlInsOn + N'		,lot.act_device_name_id device_id ';
		SET @psqlInsOn = @psqlInsOn + N'		,lot.act_device_name_id assy_name_id ';
		SET @psqlInsOn = @psqlInsOn + N'		,hq.factory_id ';
		SET @psqlInsOn = @psqlInsOn + N'		,lot.product_family_id ';
		SET @psqlInsOn = @psqlInsOn + N'		,l_rec.process_id ';
		SET @psqlInsOn = @psqlInsOn + N'		,l_rec.job_id ';
		SET @psqlInsOn = @psqlInsOn + N'		,t1.machine_id ';
		SET @psqlInsOn = @psqlInsOn + N'		,t1.machine_model_id ';
		SET @psqlInsOn = @psqlInsOn + N'		,case when t1.lot_id is null then 0 else 1 end processing_code ';
		SET @psqlInsOn = @psqlInsOn + N'		,t1.model_alarm_id  alarm_id ';
		SET @psqlInsOn = @psqlInsOn + N'		,t1.alarm_level ';
		SET @psqlInsOn = @psqlInsOn + N'		,t1.alarm_on_at ';
		SET @psqlInsOn = @psqlInsOn + N'		,t1.alarm_off_at ';
		SET @psqlInsOn = @psqlInsOn + N'		,t1.started_at ';
		SET @psqlInsOn = @psqlInsOn + N'		,t1.updated_at ';
		-- Add start at debug(2019.9.2)
		SET @psqlInsOn = @psqlInsOn + N'		,l_rec.is_onlined ';
		SET @psqlInsOn = @psqlInsOn + N'		,l_rec.recorded_at ';
		-- Add end at debug(2019.9.2)
		-- Modify 2019.9.2
		--SET @psqlInsOn = @psqlInsOn + N'		, rank() over (partition by t1.alarm_on_at,t1.machine_id,t1.model_alarm_id order by l_rec.recorded_at desc) as process_record_rank ';
		SET @psqlInsOn = @psqlInsOn + N'		, rank() over (partition by t1.alarm_on_at,t1.machine_id,t1.model_alarm_id order by l_rec.recorded_at desc,l_rec.is_onlined) as process_record_rank ';
		--<<t1
		SET @psqlInsOn = @psqlInsOn + N'	from ';
		SET @psqlInsOn = @psqlInsOn + N'	( ';
		SET @psqlInsOn = @psqlInsOn + N'		select ';
		SET @psqlInsOn = @psqlInsOn + N'			a_rec.id ';
		SET @psqlInsOn = @psqlInsOn + N'			,a_rec.machine_id ';
		SET @psqlInsOn = @psqlInsOn + N'			,mc.machine_model_id ';
		SET @psqlInsOn = @psqlInsOn + N'			,a_rec.model_alarm_id ';
		SET @psqlInsOn = @psqlInsOn + N'			,ma.alarm_level ';
		SET @psqlInsOn = @psqlInsOn + N'			,a_rec.alarm_on_at ';
		SET @psqlInsOn = @psqlInsOn + N'			,a_lot.lot_id ';
		SET @psqlInsOn = @psqlInsOn + N'			,a_rec.alarm_off_at ';
		SET @psqlInsOn = @psqlInsOn + N'			,a_rec.started_at ';
		-- for debug
		SET @psqlInsOn = @psqlInsOn + N'			,a_rec.updated_at '; --for compare to on/off/start
		SET @psqlInsOn = @psqlInsOn + N'			, rank() over (partition by a_rec.id order by a_lot.lot_id) as lot_record_rank ';
		SET @psqlInsOn = @psqlInsOn + N'		from ';
		SET @psqlInsOn = @psqlInsOn + N'			' + @pObjAPCSPro + N'.[trans].[machine_alarm_records] a_rec with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'			inner join ' + @pObjAPCSPro + N'.[mc].[machines] mc with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'				on mc.id = a_rec.machine_id ';
		SET @psqlInsOn = @psqlInsOn + N'			inner join ' + @pObjAPCSPro + N'.[mc].[model_alarms] ma with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'				on ma.id = a_rec.model_alarm_id ';
		SET @psqlInsOn = @psqlInsOn + N'			inner join ' + @pObjAPCSPro + N'.[mc].[alarm_texts] txt with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'				on txt.alarm_text_id = ma.alarm_text_id ';
		SET @psqlInsOn = @psqlInsOn + N'			left outer join ' + @pObjAPCSPro + N'.[trans].[alarm_lot_records] a_lot with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'				on a_lot.id = a_rec.id ';
		SET @psqlInsOn = @psqlInsOn + N'		where ';
		--SET @psqlInsOn = @psqlInsOn + N'							a_rec.updated_at > ''2019-02-13''';
		SET @psqlInsOn = @psqlInsOn + N'			a_rec.updated_at > ''' + convert(varchar,@pStarttime,21) + ''' and a_rec.updated_at <= ''' + convert(varchar,@pEndTime,21) + '''' ;
		SET @psqlInsOn = @psqlInsOn + N'	) t1 ';
		-->>t1
		SET @psqlInsOn = @psqlInsOn + N'		left outer join ' + @pObjAPCSPro + N'.[trans].[lots] lot with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'			on lot.id = t1.lot_id ';
		SET @psqlInsOn = @psqlInsOn + N'		left outer join ' + @pObjAPCSPro + N'.[trans].[lot_process_records] l_rec with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'			on l_rec.lot_id= t1.lot_id ';
		SET @psqlInsOn = @psqlInsOn + N'				and l_rec.machine_id = t1.machine_id ';
		SET @psqlInsOn = @psqlInsOn + N'				and l_rec.record_class = 1 ';
		SET @psqlInsOn = @psqlInsOn + N'				and l_rec.recorded_at <= t1.alarm_on_at ';
		SET @psqlInsOn = @psqlInsOn + N'		left outer join ' + @pObjAPCSPro + N'.[method].[packages] pkg with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'			on pkg.id = lot.act_package_id ';
		SET @psqlInsOn = @psqlInsOn + N'		left outer join ' + @pObjAPCSPro + N'.[man].[product_headquarters] ph with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'			on ph.product_family_id = lot.product_family_id ';
		SET @psqlInsOn = @psqlInsOn + N'		left outer join ' + @pObjAPCSPro + N'.[man].[headquarters] hq with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'			on hq.id = ph.headquarter_id ';
		SET @psqlInsOn = @psqlInsOn + N'		left join ' + @pObjAPCSProDWH + N'.[dwh].[dim_days] dt with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'			on dt.date_value = format(t1.alarm_on_at,''yyyy-MM-dd'') ';
		SET @psqlInsOn = @psqlInsOn + N'		left join ' + @pObjAPCSProdwh + N'.[dwh].[dim_hours] hr with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'			on hr.h = format(t1.alarm_on_at,''HH'') ';
		SET @psqlInsOn = @psqlInsOn + N'	where ';
		SET @psqlInsOn = @psqlInsOn + N'		t1.lot_record_rank = 1 ';
		SET @psqlInsOn = @psqlInsOn + N') t2 ';
		SET @psqlInsOn = @psqlInsOn + N'	left outer join ' + @pObjAPCSProDWH + N'.[dwh].[fact_mc_alarm] dwh_on with (NOLOCK) ';
		SET @psqlInsOn = @psqlInsOn + N'		on dwh_on.id = t2.id ';
		--SET @psqlInsOn = @psqlInsOn + N'	left outer join ' + @pObjAPCSProDWH + N'.[dwh].[fact_mc_alarm_off] dwh_off with (NOLOCK) ';
		--SET @psqlInsOn = @psqlInsOn + N'		on dwh_off.id = t2.id ';
		--SET @psqlInsOn = @psqlInsOn + N'	left outer join ' + @pObjAPCSProDWH + N'.[dwh].[fact_mc_alarm_start] dwh_start with (NOLOCK) ';
		--SET @psqlInsOn = @psqlInsOn + N'		on dwh_start.id = t2.id ';
		-->>t2
		SET @psqlInsOn = @psqlInsOn + N'where ';
		SET @psqlInsOn = @psqlInsOn + N'	t2.process_record_rank = 1 ';
		
		SET @psqlInsOn = @psqlInsOn + N'	and t2.alarm_on_at <= t2.updated_at ';
		SET @psqlInsOn = @psqlInsOn + N'	and dwh_on.id is null';
	END;

	PRINT '----------------------------------------';
	PRINT N'@psqlInsOn=' + @psqlInsOn;

	BEGIN
		SET @pSqlInsOff = N'';
		SET @pSqlInsOff = @pSqlInsOff + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[fact_mc_alarm_off] ';
		SET @pSqlInsOff = @psqlInsOff + N'( ';
		SET @psqlInsOff = @pSqlInsOff + N'	id ';
		SET @pSqlInsOff = @psqlInsOff + N'	,off_at ';
		SET @psqlInsOff = @pSqlInsOff + N') ';
		SET @psqlInsOff = @pSqlInsOff + N'select ';
		SET @psqlInsOff = @pSqlInsOff + N'	a_rec.id ';
		SET @psqlInsOff = @pSqlInsOff + N'	,a_rec.alarm_off_at ';
		SET @psqlInsOff = @pSqlInsOff + N'from ';
		SET @psqlInsOff = @pSqlInsOff + N'	' + @pObjAPCSPro + N'.[trans].[machine_alarm_records] a_rec with (NOLOCK) ';
		SET @psqlInsOff = @pSqlInsOff + N'	left outer join ' + @pObjAPCSProDWH + N'.[dwh].[fact_mc_alarm_off] dwh_off with (NOLOCK) ';
		SET @psqlInsOff = @pSqlInsOff + N'		on dwh_off.id = a_rec.id ';
		SET @psqlInsOff = @pSqlInsOff + N'where ';
		SET @psqlInsOff = @pSqlInsOff + N'	a_rec.updated_at > ''' +  convert(varchar,@pStarttime,21) + ''' and a_rec.updated_at <= ''' + convert(varchar,@pEndTime,21) + '''' ;
		SET @psqlInsOff = @pSqlInsOff + N'	and a_rec.alarm_off_at is not null ';
		SET @psqlInsOff = @pSqlInsOff + N'	and dwh_off.id is null ';
	END;	

	PRINT '----------------------------------------';
	PRINT @psqlInsOff;

	BEGIN
		SET @pSqlInsStart = N'';
		SET @pSqlInsStart = @pSqlInsStart + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[fact_mc_alarm_start] ';
		SET @pSqlInsStart = @psqlInsStart + N'( ';
		SET @pSqlInsStart = @psqlInsStart + N'	id ';
		SET @pSqlInsStart = @pSqlInsStart + N'	,started_at ';
		SET @pSqlInsStart = @pSqlInsStart + N') ';
		SET @pSqlInsStart = @pSqlInsStart + N'select ';
		SET @pSqlInsStart = @pSqlInsStart + N'	a_rec.id ';
		SET @pSqlInsStart = @pSqlInsStart + N'	,a_rec.started_at ';
		SET @pSqlInsStart = @pSqlInsStart + N'from ';
		SET @pSqlInsStart = @pSqlInsStart + N'	' + @pObjAPCSPro + N'.[trans].[machine_alarm_records] a_rec with (NOLOCK) ';
		SET @pSqlInsStart = @pSqlInsStart + N'	left outer join ' + @pObjAPCSProDWH + N'.[dwh].[fact_mc_alarm_start] dwh_start with (NOLOCK) ';
		SET @pSqlInsStart = @pSqlInsStart + N'		on dwh_start.id = a_rec.id ';
		SET @pSqlInsStart = @pSqlInsStart + N'where ';
		SET @pSqlInsStart = @pSqlInsStart + N'	a_rec.updated_at > ''' +  convert(varchar,@pStarttime,21) + ''' and a_rec.updated_at <= ''' + convert(varchar,@pEndTime,21) + '''' ;
		SET @pSqlInsStart = @pSqlInsStart + N'	and a_rec.started_at is not null ';
		SET @pSqlInsStart = @pSqlInsStart + N'	and dwh_start.id is null ';
	END;	
	
	PRINT '----------------------------------------';
	PRINT @pSqlInsStart;
	
    ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------
	BEGIN TRY

		BEGIN TRANSACTION;

			PRINT '-----1) dwh.fact_mc_alarm';
			SET @pStepNo = 1;
			PRINT N'@psqlInsOn=' + @psqlInsOn;
			EXECUTE (@psqlInsOn);
			--EXECUTE (@psqlInsOn1 + @psqlInsOn2);

			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = N'Insert(fact_mc_alarm) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----2) dwh.fact_mc_alarm_off';
			SET @pStepNo = 2;
			PRINT '@psqlInsOff=' + @psqlInsOff;	
			EXECUTE (@psqlInsOff);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = N'Insert(fact_mc_alarm_off) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----3) dwh.fact_mc_alarm_start';
			SET @pStepNo = 3;
			PRINT '@psqlInsStart=' + @pSqlInsStart ;	
			EXECUTE (@pSqlInsStart);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = N'Insert(fact_mc_alarm_start) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----4) save the process log';
			SET @pStepNo = 4;
			--PRINT '@functionname=' + @functionname + ' / ' +  '@FromTime=' + format(@FromTime,'yyyy/MM/dd HH:mm:ss.ff3') + ' / ' +  '@ToTime=' + format(@ToTime,'yyyy/MM/dd HH:mm:ss.ff3');
			EXECUTE @pRet = [etl].[sp_update_function_finish_control] @function_name_=@pFunctionName
												, @to_fact_table_ = 'dwh.fact_mc_alarm', @finished_at_=@pEndTime
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

