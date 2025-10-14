




-- =============================================
-- Author:		<M.Yamamoto>
-- Create date: <12th Oct 2018>
-- Description:	<LOT1_TABLE to Lots>
-- =============================================
CREATE PROCEDURE [etl].[sp_apcs_02_insert_lot_process_records_dc] (

	@ServerName_APCS NVARCHAR(128) 
    ,@DatabaseName_APCS NVARCHAR(128)
	,@ServerName_APCSPro NVARCHAR(128) 
    ,@DatabaseName_APCSPro NVARCHAR(128)
	,@ServerName_APCSProDWH NVARCHAR(128) 
    ,@DatabaseName_APCSProDWH NVARCHAR(128)
	,@logtext NVARCHAR(max) output
	,@errnum  INT output
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
	
	DECLARE @pRet INT = 0;
	DECLARE @pStepNo INT = 0; 

	DECLARE @pSqlTruncDC NVARCHAR(4000) = N'';
	DECLARE @pSqlTrunc NVARCHAR(4000) = N'';
	-- for dwh.DC_process_records
	DECLARE @pSqlInsDC NVARCHAR(4000) = N'';

	-- for dwh.temp_lot_process_records
	DECLARE @pSqlInsToTmp NVARCHAR(4000) = N'';
	-- for trans.lot_process_records
	DECLARE @pSqlInsToTrans NVARCHAR(4000) = N'';
	
	DECLARE @pSqlInsCommon NVARCHAR(4000) = N'';
	-- for dwh.temp_lot_process_records : @pSqlInsCommon + @pSqlInsTmp
	DECLARE @pSqlInsTmp NVARCHAR(4000) = N''; 
	-- for trans.lot_process_records : @pSqlInsCommon + @@pSqlInsTrans
	DECLARE @pSqlInsTrans NVARCHAR(4000) = N'';

	DECLARE @pSqlSelTmp1 NVARCHAR(4000) = N'';-- for dwh.temp_lot_process_records
	DECLARE @pSqlSelTmp2 NVARCHAR(4000) = N'';-- for dwh.temp_lot_process_records

	DECLARE @pSqlRowCnt NVARCHAR(4000) = N'';

	DECLARE @pSqlSelTrans NVARCHAR(4000) = N'';

	DECLARE @pRowCnt INT = 0;
	DECLARE @pIdBefore INT=0;
	DECLARE @pIdAfter INT=0;

	-- for update lots
	DECLARE @pID INT = 0;
	DECLARE @pLotID INT = 0;
	DECLARE @pRecordClass TINYINT = 0;
	DECLARE @pDayId INT = 0;
	DECLARE @pRecordedAt DATETIME ;
	DECLARE @pWipState TINYINT = 0 ;

	DECLARE @pSqlSelect NVARCHAR(4000) = '';
	DECLARE @pSqlUpdate NVARCHAR(4000) = '';
	DECLARE @pCurCnt INT = 0;

   ---------------------------------------------------------------------------
	--(2) connect string
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
		PRINT '-----0) Get StartTime & EndTime';
		SET @pStepNo = 0;
/* v10 change
		SELECT @pStarttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000')) FROM [APCSProDWH].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
		PRINT '@starttime=' + CASE WHEN @pStarttime IS NULL THEN '' ELSE FORMAT(@pStarttime, 'yyyy-MM-dd HH:mm:ss.fff') END;
		SELECT @pEndTime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'));
		PRINT '@endtime=' + FORMAT(@pEndtime, 'yyyy-MM-dd HH:mm:ss.fff');
*/
		SELECT @pStarttime = dateadd(minute,(-1)*(DATEPART(n,finished_at) % 10),convert(datetime,format(finished_at,'yyyy-MM-dd HH:mm:00.000'))) FROM [APCSProDWH].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID)
		PRINT '@starttime=' + CASE WHEN @pStarttime IS NULL THEN '' ELSE FORMAT(@pStarttime, 'yyyy-MM-dd HH:mm:ss.fff') END;
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
	--(4) make SQL
    ---------------------------------------------------------------------------

	SET @pSqlTruncDC = N'';
	SET @pSqlTruncDC = @pSqlTruncDC + N'truncate table ' + @pObjAPCSProDWH + N'.[dwh].[temp_DC_process_records] ';

	SET @pSqlTrunc = N'';
	SET @pSqlTrunc = @pSqlTrunc + N'truncate table ' + @pObjAPCSProDWH + N'.[dwh].[temp_lot_process_records] ';
	
	BEGIN
		SET @pSqlInsDC = N'';
		SET @pSqlInsDC = @pSqlInsDC + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[temp_DC_process_records] ';
		SET @pSqlInsDC = @pSqlInsDC + N'( ' ;
		SET @pSqlInsDC = @pSqlInsDC + N'	lot_id ' ;
		SET @pSqlInsDC = @pSqlInsDC + N'	,started_at ' ;
		SET @pSqlInsDC = @pSqlInsDC + N'	,finished_at ' ;
		SET @pSqlInsDC = @pSqlInsDC + N'	,started_op ' ;
		SET @pSqlInsDC = @pSqlInsDC + N'	,finished_op ' ;
		SET @pSqlInsDC = @pSqlInsDC + N'	,machine ' ;
		SET @pSqlInsDC = @pSqlInsDC + N'	,qty_pass ' ;
		SET @pSqlInsDC = @pSqlInsDC + N'	,qty_fail ' ;
		SET @pSqlInsDC = @pSqlInsDC + N'	,job_no ' ;
		SET @pSqlInsDC = @pSqlInsDC + N') ';

		SET @pSqlInsDC = @pSqlInsDC + N' select ';
		SET @pSqlInsDC = @pSqlInsDC + N'	lot.id lot_id ';
		--SET @pSqlInsDC = @pSqlInsDC + N'	,lot.lot_no ';
		--SET @pSqlInsDC = @pSqlInsDC + N'	,l.wip_state ';
		SET @pSqlInsDC = @pSqlInsDC + N'	,ld.real_start started_at ';
		SET @pSqlInsDC = @pSqlInsDC + N'	,ld.real_day finished_at ';
		SET @pSqlInsDC = @pSqlInsDC + N'	,ld.operator1 started_op ';
		SET @pSqlInsDC = @pSqlInsDC + N'	,ld.operator2 finished_op ';
		SET @pSqlInsDC = @pSqlInsDC + N'	,ld.machine ';
		SET @pSqlInsDC = @pSqlInsDC + N'	,ld.Good_Pieces qty_pass ';
		SET @pSqlInsDC = @pSqlInsDC + N'	,ld.Bad_Pieces qty_fail ';
		SET @pSqlInsDC = @pSqlInsDC + N'	,pj.job_no ';
		SET @pSqlInsDC = @pSqlInsDC + N' from ';
		SET @pSqlInsDC = @pSqlInsDC + N'	' + @pObjAPCSPro + N'.[trans].[lots] lot with (NOLOCK) ';
		SET @pSqlInsDC = @pSqlInsDC + N'	inner join OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ServerName_APCS + ';UID=dbxuser;'').[' + @DatabaseName_APCS + '].[dbo].[LOT2_DATA] as ld ';
		SET @pSqlInsDC = @pSqlInsDC + N'		on lot.lot_no = ld.[LOT_NO] ';
		SET @pSqlInsDC = @pSqlInsDC + N'	inner join OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ServerName_APCS + ';UID=dbxuser;'').[' + @DatabaseName_APCS + '].[dbo].[LAYER_TABLE] as lay '; 
		SET @pSqlInsDC = @pSqlInsDC + N'		on lay.[LAY_NO] = ld.[LAY_NO] ';
		SET @pSqlInsDC = @pSqlInsDC + N'	inner join ' + @pObjAPCSProDWH + N'.[dwh].[dim_package_jobs] as pj with (NOLOCK) ';
		SET @pSqlInsDC = @pSqlInsDC + N'		on pj.job_no = lay.lay_no ';
		SET @pSqlInsDC = @pSqlInsDC + N'			and pj.package_id = lot.act_package_id ';
		SET @pSqlInsDC = @pSqlInsDC + N'			and pj.is_additional_jobs = 1 ';
		SET @pSqlInsDC = @pSqlInsDC + N' where ';
		SET @pSqlInsDC = @pSqlInsDC + N'	lot.wip_state < 20 ';
		PRINT N'@pSqlInsDC=' + @pSqlInsDC;
	END;

	SET @pSqlInsToTmp = N'';
	SET @pSqlInsToTmp = @pSqlInsToTmp + N'insert into ' + @pObjAPCSProDWH + N'.[dwh].[temp_lot_process_records] ';
	--PRINT '@pSqlInsToTmp=' +@pSqlInsToTmp;

	SET @pSqlInsToTrans = N'';
	SET @pSqlInsToTrans = @pSqlInsToTrans + N'insert into ' + @pObjAPCSPro + N'.[trans].[lot_process_records] ';
	--PRINT '@pSqlInsToTrans=' + @pSqlInsToTrans;

		--@pSqlInsTmp or @pSqlInsTrans using @pSqlInsCommon
	BEGIN
		SET @pSqlInsCommon = N'';
		SET @pSqlInsCommon = @pSqlInsCommon + N'(id ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',day_id ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',recorded_at ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',operated_by ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',record_class ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',lot_id ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',process_id ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',job_id ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',step_no ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',qty_in ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',qty_pass ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',qty_fail ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',qty_last_pass ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',qty_last_fail ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',qty_pass_step_sum ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',qty_fail_step_sum ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',qty_divided ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',qty_hasuu ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',qty_out ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',recipe ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',recipe_version ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',machine_id ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',position_id ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',process_job_id ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',is_onlined ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',dbx_id ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',wip_state ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',process_state ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',quality_state ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',first_ins_state ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',final_ins_state ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',is_special_flow ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',special_flow_id ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',is_temp_devided ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',temp_devided_count ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',container_no ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',extend_data ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',std_time_sum ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',pass_plan_time ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',pass_plan_time_up ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',origin_material_id ';
	-- no existance as of now
		SET @pSqlInsCommon = @pSqlInsCommon + N',treatment_time ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',wait_time ';
	-- no existance as of now
		SET @pSqlInsCommon = @pSqlInsCommon + N',qc_comment_id '; 
		SET @pSqlInsCommon = @pSqlInsCommon + N',qc_memo_id ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',created_at ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',created_by ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',updated_at ';
		SET @pSqlInsCommon = @pSqlInsCommon + N',updated_by ';

	-- for dwh.temp_lot_process_records
		SET @pSqlInsTmp = N'';
		SET @pSqlInsTmp = @pSqlInsTmp + @pSqlInsCommon
		SET @pSqlInsTmp = @pSqlInsTmp + N',last_record_rank '; -- only for temporary table
		SET @pSqlInsTmp = @pSqlInsTmp + N') ';

	-- for trans.lot_process_records
		SET @pSqlInsTrans = N'';
		SET @pSqlInsTrans = @pSqlInsTrans + @pSqlInsCommon
		SET @pSqlInsTrans = @pSqlInsTrans + N') ';
	END;
	--PRINT '@pSqlInsTmp=' + @pSqlInsTmp;
	--PRINT '@pSqlInsTrans=' + @pSqlInsTrans;

	-- @pSqlSelTmp1 : for dwh.temp_lot_process_records
	BEGIN
		SET @pSqlSelTmp1 = N'';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N' select ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	ROW_NUMBER() over( order by t3.recorded_at,t3.lot_id,t3.record_class) as id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, t3.* ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N' from ( ';
		--<<t3
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N' select ';
		--SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	top (10) ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	t2.day_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, t2.recorded_at ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, t2.operated_by ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, t2.record_class ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, t2.lot_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, t2.process_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, t2.job_id ';
		--SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, t2.step_no ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, 1 step_no '; -- fixed value:1
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, case when t2.qty_in = 0 then case when t2.record_class = 1 then t2.GOOD_PIECES else t2.qty_in end else t2.qty_in end qty_in ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, case when t2.record_class = 1 then 0 else t2.GOOD_PIECES end qty_pass ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, case when t2.record_class = 1 then 0 else t2.BAD_PIECES end qty_fail ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, case when t2.record_class = 1 then 0 else t2.GOOD_PIECES end qty_last_pass ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, case when t2.record_class = 1 then 0 else t2.BAD_PIECES end qty_last_fail ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, case when t2.record_class = 1 then 0 else t2.GOOD_PIECES end qty_pass_step_sum ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, case when t2.record_class = 1 then 0 else t2.BAD_PIECES end qty_fail_step_sum ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null qty_divided ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null qty_hasuu ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null qty_out ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null recipe ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null recipe_version ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, t2.machine_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null position_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null process_job_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, 3 as is_onlined ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null dbx_id ';
		-- for DC
		--SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, 20 wip_state ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, case when t2.record_class = 1 then 10 else 20 end wip_state ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, case when t2.record_class = 1 then 2 else 0 end process_state ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, 0 quality_state ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, 0 first_ins_state ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, 0 final_ins_state ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, 0 is_special_flow ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, 0 special_flow_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, 0 is_temp_devided ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, 0 temp_devided_count ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null container_no ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null extend_data ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null std_time_sum ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null pass_plan_time ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null pass_plan_time_up ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null origin_material_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null treatment_time ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, case when t2.record_class = 1 then case when t2.pre_finish is null then null else datediff(minute,t2.pre_finish,t2.recorded_at) end else null end wait_time ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null qc_comment_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null qc_memo_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, t2.recorded_at created_at ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null created_by ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, t2.recorded_at updated_at ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, null updated_by ';
		-- If we want to update the Lots data, we shoult refer the last_record_rank = 1(latest records for each lot) 
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, rank() over (partition by t2.lot_id order by t2.recorded_at desc ,t2.record_class desc) as last_record_rank ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N' from ( ';
		--<<t2
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N' select ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	t1.* ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, rank() over (partition by t1.lot_id,t1.recorded_at,t1.record_class order by t1.job_link_flg) as rnk ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	, case when t1.record_class= 1 then ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'		isnull(lag(t1.recorded_at) over (partition by t1.lot_id  order by t1.recorded_at,t1.record_class) ,t1.created_at) ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'		else null end pre_finish ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N' from ( ';
		--<<t1

		SET @pSqlSelTmp2 = N'';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N' select ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	day_process.id day_id ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, apcs.process_time recorded_at ';
		SET	@pSqlSelTmp2 = @pSqlSelTmp2 + N'	, man.id operated_by ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, apcs.record_class ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, lots.id lot_id ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, pj.process_id ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, pj.job_id ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, lots.qty_in ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, lots.qty_in GOOD_PIECES ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, 0 BAD_PIECES ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, mc.id machine_id ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, lots.created_at ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, 1 job_link_flg ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N' from ( ';
		--<< apcs
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N' select ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	dc1.* ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, 1 record_class ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, dc1.started_at process_time ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, convert(date,dc1.started_at,11) PROCESS_TIME_DAY ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, dc1.started_op operator ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N' from ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	' + @pObjAPCSProDWH + N'.[dwh].[temp_DC_process_records] as dc1 ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N' where ';
		--Change 2019-05-29
		--SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	dc1.finished_at is null ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	dc1.started_at is not null ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'union all ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N' select ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	dc2.* ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, 2 record_class ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, dc2.finished_at process_time ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, convert(date,dc2.finished_at,11) PROCESS_TIME_DAY ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	, dc2.finished_op operator ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N' from ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	' + @pObjAPCSProDWH + N'.[dwh].[temp_DC_process_records] as dc2 ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N' where ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	dc2.finished_at is not null ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N') apcs ';
		-->> apcs
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	inner join ' + @pObjAPCSPro + N'.[trans].[lots] lots with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'		on lots.id = apcs.lot_id ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	inner join ' + @pObjAPCSProDWH + N'.[dwh].[dim_package_jobs] as pj with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'		on pj.job_no = apcs.job_no ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'			and pj.package_id = lots.act_package_id ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'			and pj.is_additional_jobs = 1 ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	left join ' + @pObjAPCSPro + N'.[mc].[machines] mc with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'		on apcs.MACHINE = mc.name ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	left join ' + @pObjAPCSPro + N'.[man].[users] man with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'		on apcs.operator = man.emp_num ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	left join ' + @pObjAPCSPro + N'.[trans].[days] day_process with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'		on apcs.PROCESS_TIME_DAY = day_process.date_value ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N') as t1 ';
		-->> t1
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N') as t2 ';
		-->> t2
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N' where t2.rnk = 1 ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N') as t3 ';
		-->> t3
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	left outer join ' + @pObjAPCSPro + N'.[trans].[lot_process_records] rec with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'		on t3.day_id = rec.day_id ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'			and t3.lot_id = rec.lot_id ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'			and t3.recorded_at = rec.recorded_at ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'			and t3.record_class = rec.record_class ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N' where rec.id is null ';
	END;
	PRINT '@pSqlSelTmp=' + @pSqlSelTmp1 + @pSqlSelTmp2;
	
	-- @pSqlSelect : for update lots
	BEGIN
		SET @pSqlSelect = N'';
		SET @pSqlSelect = @pSqlSelect + N'select ';
		SET @pSqlSelect = @pSqlSelect + N'	rec.id ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.lot_id ';
		/*
		SET @pSqlSelect = @pSqlSelect + N'	,case when rec.record_class = 2 then df2.step_no else rec.step_no end step_no ';
		SET @pSqlSelect = @pSqlSelect + N'	,case when rec.record_class = 2 then df2.act_process_id else rec.process_id end process_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,case when rec.record_class = 2 then df2.job_id else rec.job_id end job_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.qty_pass ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.qty_fail ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.qty_last_pass ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.qty_last_fail ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.qty_pass_step_sum ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.qty_fail_step_sum ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.record_class ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.process_state ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.day_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.recorded_at ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.machine_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,case when df.step_no = df.next_step_no then 1 else 0 end is_last_step_no ';
		*/
		SET @pSqlSelect = @pSqlSelect + N'	,rec.record_class ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.day_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,rec.recorded_at ';
		SET @pSqlSelect = @pSqlSelect + N'	,lot.wip_state ';
		SET @pSqlSelect = @pSqlSelect + N'from ';
		SET @pSqlSelect = @pSqlSelect + N'	' + @pObjAPCSProDWH + N'.[dwh].[temp_lot_process_records] rec WITH (NOLOCK) ';  
		SET @pSqlSelect = @pSqlSelect + N'	inner join ' + @pObjAPCSPro + N'.[trans].[lots] lot with (NOLOCK) ';
		SET @pSqlSelect = @pSqlSelect + N'		on lot.id = rec.lot_id ';
		--for DC
		--SET @pSqlSelect = @pSqlSelect + N'where rec.last_record_rank = 1';  
		SET @pSqlSelect = @pSqlSelect + N'order by rec.id ';
	END;
	--PRINT '@pSqlSelect=' + @pSqlSelect;

    ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------
	BEGIN TRY

	-- for temp_DC_process_records

		BEGIN TRANSACTION;

			PRINT '-----1) trunc temporary (dwh.temp_DC_process_records)';
			SET @pStepNo = 1;
			EXECUTE (@pSqlTruncDC);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Truncate(temp_DC_process_records) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----2) temporary ==> dwh.temp_DC_process_records';
			SET @pStepNo = 2;
			PRINT '@pSqlInsDC=' + @pSqlInsDC;	
			EXECUTE (@pSqlInsDC);
			--SET @pRowCnt = @@ROWCOUNT;
			PRINT '-----3) Get row counts';
			SET @pStepNo = 3;
			SET @pSqlRowCnt = N''
			SET @pSqlRowCnt = @pSqlRowCnt + N' select @RecordsCnt = count(*) '
			SET @pSqlRowCnt = @pSqlRowCnt + N' from ' +  @pObjAPCSProDWH + '.[dwh].[temp_DC_process_records] with (NOLOCK)'
			EXEC sp_executesql @pSqlRowCnt, N'@RecordsCnt INT OUTPUT', @RecordsCnt=@pRowCnt OUTPUT;
			PRINT 'Count=' + convert(varchar,@pRowCnt);
			SET @logtext = 'Insert(temp_DC_process_records) OK : row=';
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

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

					END;

				-- rowcnt=0 then exit
			
				SET @logtext = @pfunctionname ;
				SET @logtext = @logtext + N' has no additional DC record data(' ;
				SET @logtext = @logtext + convert(varchar,@pEndTime,21);
				SET @logtext = @logtext + N')';
				PRINT 'logtext=' + @logtext;
				RETURN 0;

			END;
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

	-- for lot_process_records
	BEGIN TRY

		BEGIN TRANSACTION;

			PRINT '-----5) trunc temporary (dwh.temp_lot_process_records)';
			SET @pStepNo = 5;
			--PRINT (@pSqlTrunc);
			EXECUTE (@pSqlTrunc);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Truncate(temp_lot_process_records) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----6) temporary ==> dwh.temp_lot_process_records';
			SET @pStepNo = 6;
			PRINT '@pSqlInsToTmp=' + @pSqlInsToTmp;	
			PRINT '@pSqlSelTmp1=' + @pSqlSelTmp1;
			PRINT '@pSqlSelTmp2=' + @pSqlSelTmp2;
			EXECUTE (@pSqlInsToTmp + @pSqlInsTmp + @pSqlSelTmp1 + @pSqlSelTmp2);
			--SET @pRowCnt = @@ROWCOUNT;
			PRINT '-----7) Get row counts';
			SET @pStepNo = 7;
			SET @pSqlRowCnt = N''
			SET @pSqlRowCnt = @pSqlRowCnt + N' select @RecordsCnt = count(*) '
			SET @pSqlRowCnt = @pSqlRowCnt + N' from ' +  @pObjAPCSProDWH + '.[dwh].[temp_lot_process_records] with (NOLOCK)'
			EXEC sp_executesql @pSqlRowCnt, N'@RecordsCnt INT OUTPUT', @RecordsCnt=@pRowCnt OUTPUT;
			PRINT 'Count=' + convert(varchar,@pRowCnt);
			SET @logtext = 'Insert(temp_lot_process_records) OK : row=';
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

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

	BEGIN TRY

		PRINT '-----8) Check row counts';
		SET @pStepNo = 8;

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

					END;

				-- rowcnt=0 then exit
			
				SET @logtext = @pfunctionname ;
				SET @logtext = @logtext + N' has no additional lot record data(' ;
				SET @logtext = @logtext + convert(varchar,@pEndTime,21);
				SET @logtext = @logtext + N')';
				PRINT 'logtext=' + @logtext;
				RETURN 0;

			END;

		PRINT '-----9) count up id in trans.numbers'
		SET @pStepNo = 9;

		EXECUTE @pRet = [etl].[sp_update_numbers] @servername = @ServerName_APCSPro ,@databasename = @DatabaseName_APCSPro 
											,@schemaname=N'trans' ,@name=N'lot_process_records.id' ,@count = @pRowCnt
											,@id_used = @pIdBefore OUTPUT ,@id_used_new = @pIdAfter OUTPUT
											,@errnum = @errnum OUTPUT, @errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;
		IF @pRet<>0
			begin
				SET @logtext = N'@ret<>0 [sp_update_numbers] /ret:' ;
				SET @logtext = @logtext + convert(varchar,@pRet) ;
				SET @logtext = @logtext + N'/func:';
				SET @logtext = @logtext + @pFunctionName;
				SET @logtext = @logtext + N'/name:lot_process_records.id' ;
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
				RETURN -1;

			END;

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

		PRINT '-----10) dwh.temp_lot_process_records ==> trans.lot_process_records';
		SET @pStepNo = 10;

		SET @pSqlSelTrans = N'';
		SET @pSqlSelTrans = @pSqlSelTrans + N'select ';
		SET @pSqlSelTrans = @pSqlSelTrans + N' id + ' + convert(varchar,@pIdBefore)  ;
		SET @pSqlSelTrans = @pSqlSelTrans + N',day_id ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',recorded_at ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',operated_by ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',record_class ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',lot_id ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',process_id ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',job_id ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',step_no ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',qty_in ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',qty_pass ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',qty_fail ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',qty_last_pass ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',qty_last_fail ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',qty_pass_step_sum ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',qty_fail_step_sum ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',qty_divided ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',qty_hasuu ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',qty_out ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',recipe ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',recipe_version ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',machine_id ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',position_id ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',process_job_id ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',is_onlined ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',dbx_id ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',wip_state ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',process_state ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',quality_state ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',first_ins_state ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',final_ins_state ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',is_special_flow ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',special_flow_id ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',is_temp_devided ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',temp_devided_count ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',container_no ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',extend_data ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',std_time_sum ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',pass_plan_time ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',pass_plan_time_up ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',origin_material_id ';
	-- no existance as of now
		SET @pSqlSelTrans = @pSqlSelTrans + N',treatment_time ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',wait_time ';
	-- no existance as of now
		SET @pSqlSelTrans = @pSqlSelTrans + N',qc_comment_id '; 
		SET @pSqlSelTrans = @pSqlSelTrans + N',qc_memo_id ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',created_at ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',created_by ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',updated_at ';
		SET @pSqlSelTrans = @pSqlSelTrans + N',updated_by ';
		SET @pSqlSelTrans = @pSqlSelTrans + N'from ';
		SET @pSqlSelTrans = @pSqlSelTrans + @pObjAPCSProDWH + '.[dwh].[temp_lot_process_records] lt WITH (NOLOCK) ';  
		
		BEGIN TRANSACTION;
			PRINT (@pSqlInsToTrans + @pSqlInsTrans + @pSqlSelTrans);
			EXECUTE (@pSqlInsToTrans + @pSqlInsTrans + @pSqlSelTrans);
			--SET @pRowCnt = @@ROWCOUNT;
			--count = tmp_lot_procedd_records
			SET @logtext = 'Insert(lot_procedd_records) OK : row=';
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----11) save the process log';
			SET @pStepNo = 11;
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
		SET @logtext = @logtext + N'/num:';
		SET @logtext = @logtext + convert(varchar,@errnum);
		SET @logtext = @logtext + N'/line:';
		SET @logtext = @logtext + convert(varchar,@errline);
		SET @logtext = @logtext + N'/msg:';
		SET @logtext = @logtext + convert(varchar,@errmsg);
		PRINT '@logtext=' + @logtext;

		RETURN -1;

	END CATCH;

	--update for Lots


	BEGIN TRY

		PRINT '-----12) Get the cursor to update lots ';
		SET @pStepNo = 12;
		SET @pCurCnt = 0;

		EXECUTE ('DECLARE Cur_DC_Record CURSOR FOR ' + @pSqlSelect ) ;
		OPEN Cur_DC_Record;


		FETCH NEXT FROM Cur_DC_Record
		INTO
			@pID
			,@pLotID
			,@pRecordClass
			,@pDayId
			,@pRecordedAt
			,@pWipState

		BEGIN TRANSACTION;

		WHILE (@@FETCH_STATUS = 0)

			BEGIN
				SET @pCurCnt = @pCurCnt + 1;

				SET @pSqlUpdate = N'';
				SET @pSqlUpdate = @pSqlUpdate + N'update ' + @pObjAPCSPro + N'.[trans].[lots] WITH (ROWLOCK) ';
				SET @pSqlUpdate = @pSqlUpdate + N' SET ';

				if (@pwipstate < 20)
					BEGIN
						if (@pRecordClass = 1)
							BEGIN
								SET @pSqlUpdate = @pSqlUpdate + N' wip_state = 10 ';
								SET @pSqlUpdate = @pSqlUpdate + N',in_date_id = ' + convert(varchar,@pDayId) ;
								SET @pSqlUpdate = @pSqlUpdate + N',in_at = ''' + convert(varchar,@pRecordedAt,21) + N'''';
							END;
						if (@pRecordClass = 2)
							BEGIN
								SET @pSqlUpdate = @pSqlUpdate + N' wip_state = 20 ';
								SET @pSqlUpdate = @pSqlUpdate + N',in_date_id = case when in_at is null then ' + convert(varchar,@pDayId) + N' else in_date_id end ';
								SET @pSqlUpdate = @pSqlUpdate + N',in_at = case when in_at is null then ''' + convert(varchar,@pRecordedAt,21) + N''' else in_at end ';
							END;				
					END;
				
				SET @pSqlUpdate = @pSqlUpdate + N' where id = ' + convert(varchar,@pLotID);

				PRINT 'Row=' + convert(varchar,@pCurCnt) + '/id=' + convert(varchar,@pid) + ' > @pSqlUpdate=' + @pSqlUpdate;
				
				EXECUTE (@pSqlUpdate);
 
				FETCH NEXT FROM Cur_DC_Record
					INTO
						@pID
						,@pLotID
						,@pRecordClass
						,@pDayId
						,@pRecordedAt
						,@pWipState

			END;
			
		COMMIT TRANSACTION;

		CLOSE Cur_DC_Record;
		DEALLOCATE Cur_DC_Record;

	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT <> 0
			BEGIN
				ROLLBACK TRANSACTION;
			END;

		CLOSE Cur_DC_Record;
		DEALLOCATE Cur_DC_Record;

		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = N'[ERR] ';
		SET @logtext = @logtext + @pFunctionName;
		SET @logtext = @logtext + N'/step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/row=' ;
		SET @logtext = @logtext + convert(varchar,@pCurCnt) ;
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


