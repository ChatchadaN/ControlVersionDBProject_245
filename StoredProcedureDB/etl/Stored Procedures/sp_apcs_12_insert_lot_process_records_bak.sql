


-- =============================================
-- Author:		<M.Yamamoto>
-- Create date: <12th Oct 2018>
-- Description:	<LOT1_TABLE to Lots>
-- =============================================
CREATE PROCEDURE [etl].[sp_apcs_12_insert_lot_process_records_bak] (

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

	DECLARE @pSqlTrunc NVARCHAR(4000) = N'';
	
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
	DECLARE @pStepNum INT = 0; 
	DECLARE @pProcessId INT = 0; 
	DECLARE @pJobId INT = 0; 
	DECLARE @pQtyPass INT = 0;
	DECLARE @pQtyFail INT = 0;
	DECLARE @pQtyLastPass INT = 0;
	DECLARE @pQtyLastFail INT = 0;
	DECLARE @pQtyPassStepSum INT = 0;
	DECLARE @pQtyFailStepSum INT = 0;
	DECLARE @pRecordClass TINYINT = 0;
	DECLARE @pProcessState TINYINT = 0;
	DECLARE @pDayId INT = 0;
	DECLARE @pRecordedAt DATETIME ;
	DECLARE @pMachineId INT = 0;
	DECLARE @pIsLastStepNo INT = 0; --2018-Nov-13 add

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
		--yyyy/MM/dd HH:mm:ss.ff3

		PRINT '-----0) Get StartTime & EndTime';
		SET @pStepNo = 0;
		--12-08 edit
		--SELECT @pStarttime = CONVERT(DATETIME ,FORMAT(finished_at, 'yyyy-MM-dd HH:00:00.000')) FROM [apcsprodwh].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID);
		SELECT @pStarttime = finished_at FROM [APCSProDWH].[dwh].[function_finish_control] WHERE function_name = OBJECT_NAME(@@PROCID);
		--set oldest data 
		SET @pStarttime = ISNULL(@pStarttime,convert(datetime,'2018-01-01 00:00:00.000',21));
		--2019-02-14 ADD
		-- It corresponds to the time lag of each cellcon PC : -60  
		SET @pStarttime = dateadd(minute,-60,CONVERT(DATETIME , FORMAT(@pStarttime,'yyyy-MM-dd HH:mm:00.000')));
		
		PRINT '@pStarttime=' + CASE WHEN @pStarttime IS NULL THEN '' ELSE FORMAT(@pStarttime, 'yyyy-MM-dd HH:mm:ss.fff') END;

		--SELECT @pEndTime = dateadd(m,-1,CONVERT(DATETIME , FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:00.000')));
		
		--2019-02-14 edit
		--SELECT @pEndTime = dateadd(minute,-1,CONVERT(DATETIME , FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:00.000')));
		SELECT @pEndTime = CONVERT(DATETIME , FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:00.000'));
		
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
	SET @pSqlTrunc = N'';
	SET @pSqlTrunc = @pSqlTrunc + N'truncate table ' + @pObjAPCSProDWH + N'.[dwh].[temp_lot_process_records] ';
	--PRINT '@pSqlTrunc=' +@pSqlTrunc;

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
		SET @pSqlInsCommon = @pSqlInsCommon + ',treatment_time ';
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
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'select ';
		--2019-04-19 change
		--SET @pSqlSelTmp1 = @pSqlSelTmp1 + N' ROW_NUMBER() over( order by t3.recorded_at) as id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	ROW_NUMBER() over( order by t3.recorded_at,t3.lot_id,t3.record_class) as id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	,t3.* ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'from ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'	(';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'		select ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			t2.day_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, t2.recorded_at ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, t2.operated_by ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, t2.record_class ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, t2.lot_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, t2.process_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, t2.job_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, t2.step_no ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, case when t2.qty_in = 0 then ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'					case when t2.record_class = 1 then t2.GOOD_PIECES ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							else t2.qty_in end ' ;
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'					else t2.qty_in ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'				end qty_in ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, case when t2.record_class = 1 then 0 else t2.GOOD_PIECES end qty_pass ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, case when t2.record_class = 1 then 0 else t2.BAD_PIECES end qty_fail ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, case when t2.record_class = 1 then 0 else t2.GOOD_PIECES end qty_last_pass ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, case when t2.record_class = 1 then 0 else t2.BAD_PIECES end qty_last_fail ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, case when t2.record_class = 1 then 0 else t2.GOOD_PIECES end qty_pass_step_sum ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, case when t2.record_class = 1 then 0 else t2.BAD_PIECES end qty_fail_step_sum ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null qty_divided ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null qty_hasuu ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null qty_out ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null recipe ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null recipe_version ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, t2.machine_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null position_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null process_job_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, 2 as is_onlined ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null dbx_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, 20 wip_state ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, case when t2.record_class = 1 then 2 else 0 end process_state ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, 0 quality_state ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, 0 first_ins_state ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, 0 final_ins_state ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, 0 is_special_flow ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, 0 special_flow_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, 0 is_temp_devided ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, 0 temp_devided_count ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null container_no ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null extend_data ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null std_time_sum ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null pass_plan_time ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null pass_plan_time_up ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null origin_material_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null treatment_time ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, case when t2.record_class = 1 then ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'					case when t2.pre_finish is null then null ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							else datediff(minute,t2.pre_finish,t2.recorded_at) end ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'					else null ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'					end wait_time ';
		--, t2.recorded_at r2
		--, t2.pre_finish r3
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null qc_comment_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null qc_memo_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, t2.recorded_at created_at ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null created_by ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, t2.recorded_at updated_at ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, null updated_by ';
		-- If we want to update the Lots data, we shoult refer the last_record_rank = 1(latest records for each lot) 
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			, rank() over (partition by t2.lot_id order by t2.recorded_at desc ,t2.record_class desc) as last_record_rank ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'		from ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'			( ';
		-- t2 
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'				select ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'					t1.* ' ;
		/* job_link_flg  
			1:job.job_no = apcs.lay_no 
			2:else
			priority is 1
		*/
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'					, rank() over (partition by t1.lot_id,t1.recorded_at,t1.record_class order by t1.job_link_flg) as rnk '; 
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'					, case when t1.record_class= 1 then ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							isnull(lag(t1.recorded_at) over (partition by t1.lot_id  order by t1.recorded_at,t1.record_class) ,t1.finished_at) ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							else null ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							end pre_finish ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'				from ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'					( ' ;
											-- t1
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'						select ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							day_process.id day_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, apcs.process_time recorded_at ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, man.id operated_by ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, apcs.record_class ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, lots.id lot_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, p.id process_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, job.id job_id ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, flow.step_no ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, lots.qty_in ';
		-- Change start 2018-Dec-05
		--SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, apcs.GOOD_PIECES ';
		--SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, apcs.BAD_PIECES ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, lots.qty_in GOOD_PIECES ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, 0 BAD_PIECES ';
		-- Change end 2018-Dec-05
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, mc.id machine_id ' ;
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, lots.finished_at ' ;
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							, case when job.job_no = apcs.lay_no then 1 else 2 end as job_link_flg ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'						from ' ;
		/* Target data in Lot2_data */
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'							( ' ;
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'								select ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									ld.LOT_NO ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,ld.OPE_SEQ ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,ld.N_OPE_SEQ ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,ld.LAY_NO ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,ld.PLAN_DAY plan_time ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,convert(date,ld.PLAN_DAY,11) PLAN_TIME_DAY ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,ld.process_time ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,convert(date,ld.process_time,11) PROCESS_TIME_DAY ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,ld.MACHINE ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,ld.operator ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,ld.GOOD_PIECES ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,ld.BAD_PIECES ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,ld.record_class ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'									,lay.OPE_NAME ';
		SET @pSqlSelTmp1 = @pSqlSelTmp1 + N'								from ';
	END;
	--PRINT '@pSqlSelTmp1=' + @pSqlSelTmp1;

	-- @pSqlSelTmp2 : for dwh.temp_lot_process_records
	BEGIN
		SET @pSqlSelTmp2 = N'';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'									( ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'										( ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'											select ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												tmp1.LOT_NO as LOT_NO ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp1.OPE_SEQ ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp1.N_OPE_SEQ ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp1.LAY_NO ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp1.PLAN_DAY ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,1 record_class ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp1.REAL_START process_time ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp1.MACHINE ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp1.OPERATOR1 operator ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp1.GOOD_PIECES ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp1.BAD_PIECES ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'											from OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ServerName_APCS + ';UID=dbxuser;'').[' + @DatabaseName_APCS + '].[dbo].[LOT2_DATA] as tmp1 ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'											where tmp1.REAL_start > ''' + convert(varchar,@pStarttime,21) + ''' and tmp1.REAL_start <= ''' + convert(varchar,@pEndTime,21) + ''' ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'										) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'										union all ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'										( ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'											select ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												tmp2.LOT_NO as LOT_NO ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp2.OPE_SEQ ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp2.N_OPE_SEQ ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp2.LAY_NO ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp2.PLAN_DAY ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,2 record_class ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp2.real_day process_time ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp2.MACHINE ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp2.OPERATOR2 operator ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp2.GOOD_PIECES ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												,tmp2.BAD_PIECES ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'											from OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ServerName_APCS + ';UID=dbxuser;'').[' + @DatabaseName_APCS + '].[dbo].[LOT2_DATA] as tmp2 ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'											where tmp2.REAL_DAY > ''' + convert(varchar,@pStarttime,21) + ''' and  tmp2.REAL_DAY <= ''' + convert(varchar,@pEndTime,21) + ''' ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'												and tmp2.REAL_DAY is not null ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'										) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'									) ld ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'									inner join OPENDATASOURCE(''SQLNCLI'', ''Server=' + @ServerName_APCS + ';UID=dbxuser;'').[' + @DatabaseName_APCS + '].[dbo].[LAYER_TABLE] as lay ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'										on ld.LAY_NO = lay.LAY_NO ';
		/* del 2018.10.11
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'									inner join ' + @pObjAPCS + '.WPS.APCS_GROUP_PRO wps with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'										on lay.OPE_NAME = wps.OPE_NAME ';
		*/
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'							) apcs ';
		/*Target master flow data in Lots*/
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'							inner join ' + @pObjAPCSPro + '.trans.lots lots with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'								on apcs.LOT_NO = lots.lot_no ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'									and lots.is_imported = 1 '; -- for APCS
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'							inner join ' + @pObjAPCSPro + '.method.device_flows flow with (NOLOCK) '; --for getting stepno
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'								on lots.device_slip_id = flow.device_slip_id ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'							inner join ' + @pObjAPCSPro + '.method.jobs as job with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'								on job.id = flow.job_id ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'							left outer join ' + @pObjAPCSPro + '.method.processes as p with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'								on p.id = job.process_id ';
		/*link to pro machine master*/
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'							left join ' + @pObjAPCSPro + '.mc.machines mc with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'								on apcs.MACHINE = mc.name ';
		/*link to pro user master*/
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'							left join ' + @pObjAPCSPro + '.man.users man with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'								on apcs.operator = man.emp_num ';
		/*link to pro date master*/
		/* del 2018.10.11
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'							left join ' + @pObjAPCSPro + '.trans.days day_plan with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'								on apcs.PLAN_TIME_DAY = day_plan.date_value ';
		*/
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'							left join ' + @pObjAPCSPro + '.trans.days day_process with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'								on apcs.PROCESS_TIME_DAY = day_process.date_value ';
		/* correspond to dupli ope_name */
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'						where job.job_no = apcs.LAY_NO or job.name = apcs.OPE_NAME ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'					) as t1 ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'				) as t2 '; 
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'			where t2.rnk = 1 ';

		--2019-02-14 ADD start
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'		) as t3 ';
		--2019-06-19 change start
		--SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'		left outer join ' + @pObjAPCSPro + '.trans.lot_process_records rec with (NOLOCK) ';
		--SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'			on t3.day_id = rec.day_id and t3.lot_id = rec.lot_id and t3.recorded_at = rec.recorded_at and t3.record_class = rec.record_class ';
		--SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'			on t3.day_id = rec.day_id and t3.lot_id = rec.lot_id and t3.record_class = rec.record_class ';
		--SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'				and t3.job_id = rec.job_id and abs(datediff(minute,t3.recorded_at,rec.recorded_at)) < 5 ';
		--SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	where rec.id is null ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'	where not exists (select * ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'						from ' + @pObjAPCSPro + '.trans.lot_process_records rec with (NOLOCK) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'						where rec.lot_id = t3.lot_id ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'							and rec.record_class in(1,2,11,12) ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'							and rec.recorded_at = t3.recorded_at ';
		SET @pSqlSelTmp2 = @pSqlSelTmp2 + N'							and rec.job_id = t3.job_id) ';
		--2019-06-19 change end
		--2019-02-14 ADD end
	END;
	--PRINT '@pSqlSelTmp2=' + @pSqlSelTmp2;

	-- @pSqlSelect : for update lots
	BEGIN
		SET @pSqlSelect = N'';
		SET @pSqlSelect = @pSqlSelect + N'select ';
		SET @pSqlSelect = @pSqlSelect + N'		rec.id ';
		SET @pSqlSelect = @pSqlSelect + N'		,rec.lot_id ';
		--2019-Feb-18 Change start
		--SET @pSqlSelect = @pSqlSelect + N'	,rec.step_no ';
		--SET @pSqlSelect = @pSqlSelect + N'	,rec.process_id ';
		--SET @pSqlSelect = @pSqlSelect + N'	,rec.job_id ';
		SET @pSqlSelect = @pSqlSelect + N'		,case when rec.record_class = 2 then df2.step_no else rec.step_no end step_no ';
		SET @pSqlSelect = @pSqlSelect + N'		,case when rec.record_class = 2 then df2.act_process_id else rec.process_id end process_id ';
		SET @pSqlSelect = @pSqlSelect + N'		,case when rec.record_class = 2 then df2.job_id else rec.job_id end job_id ';
		--2019-Feb-18 Change end

		SET @pSqlSelect = @pSqlSelect + N'		,rec.qty_pass ';
		SET @pSqlSelect = @pSqlSelect + N'		,rec.qty_fail ';
		SET @pSqlSelect = @pSqlSelect + N'		,rec.qty_last_pass ';
		SET @pSqlSelect = @pSqlSelect + N'		,rec.qty_last_fail ';
		SET @pSqlSelect = @pSqlSelect + N'		,rec.qty_pass_step_sum ';
		SET @pSqlSelect = @pSqlSelect + N'		,rec.qty_fail_step_sum ';
		SET @pSqlSelect = @pSqlSelect + N'		,rec.record_class ';
		SET @pSqlSelect = @pSqlSelect + N'		,rec.process_state ';
		SET @pSqlSelect = @pSqlSelect + N'		,rec.day_id ';
		SET @pSqlSelect = @pSqlSelect + N'		,rec.recorded_at ';
		SET @pSqlSelect = @pSqlSelect + N'		,rec.machine_id ';
		--2018-Nov-13 Add start
		SET @pSqlSelect = @pSqlSelect + N'		,case when df.step_no = df.next_step_no then 1 else 0 end is_last_step_no ';
		--2018-Nov-13 Add end

		SET @pSqlSelect = @pSqlSelect + N'from ';
		SET @pSqlSelect = @pSqlSelect + N'	' + @pObjAPCSProDWH + N'.[dwh].[temp_lot_process_records] rec WITH (NOLOCK) ';  

		--2018-Nov-13 Add start
		SET @pSqlSelect = @pSqlSelect + N'	inner join ' + @pObjAPCSPro + N'.[trans].[lots] lot with (NOLOCK) ';
		SET @pSqlSelect = @pSqlSelect + N'		on lot.id = rec.lot_id ';
		SET @psqlSelect = @psqlselect + N'	inner join ' + @pObjAPCSPro + N'.[method].[device_flows] df with (NOLOCK) ';
		SET @psqlselect = @psqlselect + N'		on df.device_slip_id = lot.device_slip_id ';
		SET @pSqlSelect = @pSqlSelect + N'			and df.job_id = rec.job_id ';
		--2019-Feb-18 Add start
		SET @pSqlSelect = @pSqlSelect + N'	left outer join APCSProdb.[method].[device_flows] df2 with (NOLOCK) ';
		SET @pSqlSelect = @pSqlSelect + N'		on df2.device_slip_id = lot.device_slip_id ';
		SET @pSqlSelect = @pSqlSelect + N'			and df2.step_no = df.next_step_no ';
		--2019-Feb-18 Add end
		--2018-Nov-13 Add end

		SET @pSqlSelect = @pSqlSelect + N'where rec.last_record_rank = 1';  
	END;
	--PRINT '@pSqlSelect=' + @pSqlSelect;

   ---------------------------------------------------------------------------
	--(5) execute sql
    ---------------------------------------------------------------------------
	BEGIN TRY

		BEGIN TRANSACTION;

			PRINT '-----1) trunc temporary (dwh.temp_lot_process_records)';
			SET @pStepNo = 1;
			--PRINT (@pSqlTrunc);
			EXECUTE (@pSqlTrunc);
			SET @pRowCnt = @@ROWCOUNT;
			SET @logtext = 'Truncate(temp_lot_process_records) OK : row=' ;
			SET @logtext = @logtext + convert(varchar,@pRowCnt);
			PRINT @logtext;

			PRINT '-----2) temporary ==> dwh.temp_lot_process_records';
			SET @pStepNo = 2;
			PRINT '@pSqlInsToTmp=' + @pSqlInsToTmp;	
			PRINT '@pSqlSelTmp1=' + @pSqlSelTmp1;
			PRINT '@pSqlSelTmp2=' + @pSqlSelTmp2;
			EXECUTE (@pSqlInsToTmp + @pSqlInsTmp + @pSqlSelTmp1 + @pSqlSelTmp2);
			--SET @pRowCnt = @@ROWCOUNT;
			PRINT '-----3) Get row counts';
			SET @pStepNo = 3;
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
				SET @logtext = @logtext + N' has no additional lot record data(' ;
				SET @logtext = @logtext + convert(varchar,@pEndTime,21);
				SET @logtext = @logtext + N')';
				PRINT 'logtext=' + @logtext;
				RETURN 0;

			END;

		PRINT '-----5) count up id in trans.numbers'
		SET @pStepNo = 5;

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

		PRINT '-----6) dwh.temp_lot_process_records ==> trans.lot_process_records';
		SET @pStepNo = 6;

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

			PRINT '-----7) save the process log';
			SET @pStepNo = 7;
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

		PRINT '-----8) Get the cursor to update lots ';
		SET @pStepNo = 8;
		SET @pCurCnt = 0;

		EXECUTE ('DECLARE Cur_Latest_History CURSOR FOR ' + @pSqlSelect ) ;
		OPEN Cur_Latest_History;

		FETCH NEXT FROM Cur_Latest_History
		INTO
			@pID
			,@pLotID
			,@pStepNo
			,@pProcessId
			,@pJobId
			,@pQtyPass
			,@pQtyFail
			,@pQtyLastPass
			,@pQtyLastFail
			,@pQtyPassStepSum
			,@pQtyFailStepSum
			,@pRecordClass
			,@pProcessState
			,@pDayId
			,@pRecordedAt
			,@pMachineId
			,@pIsLastStepNo; --2018-Nov-13 Add IsLastStepNo

		BEGIN TRANSACTION;

		WHILE (@@FETCH_STATUS = 0)

			BEGIN
				SET @pCurCnt = @pCurCnt + 1;

				SET @pSqlUpdate = N'';
				SET @pSqlUpdate = @pSqlUpdate + N'update ' + @pObjAPCSPro + N'.[trans].[lots] WITH (ROWLOCK) ';
				SET @pSqlUpdate = @pSqlUpdate + N' SET ';

				if @pStepNo IS not NULL
					SET @pSqlUpdate = @pSqlUpdate + N'		step_no =' + convert(varchar,@pStepNo);	
				else
					SET @pSqlUpdate = @pSqlUpdate + N'		step_no = null';
	
				if @pProcessId is not null
					SET @pSqlUpdate = @pSqlUpdate + N'		,act_process_id =' + convert(varchar,@pProcessId);
				ELSE
					SET @pSqlUpdate = @pSqlUpdate + N'		,act_process_id = null';	
				
				if @pJobId is not null
					SET @pSqlUpdate = @pSqlUpdate + N'		,act_job_id =' + convert(varchar,@pJobId);
				ELSE
					SET @pSqlUpdate = @pSqlUpdate + N'		,act_job_id = null';	

				if @pQtyPass is not null
					SET @pSqlUpdate = @pSqlUpdate + N'		,qty_pass = case when ' + convert(varchar,@pRecordClass) + N' = 2 then ' + convert(varchar,@pQtyPass) + N' else qty_pass end ';
				ELSE
					SET @pSqlUpdate = @pSqlUpdate + N'		,qty_pass = case when ' + convert(varchar,@pRecordClass) + N' = 2 then null else qty_pass end ';	

				if @pQtyFail is not null
					SET @pSqlUpdate = @pSqlUpdate + N'		,qty_fail = case when ' + convert(varchar,@pRecordClass) + N' = 2 then ' + convert(varchar,@pQtyFail) + N' else qty_fail end ';
				ELSE
					SET @pSqlUpdate = @pSqlUpdate + N'		,qty_fail = case when ' + convert(varchar,@pRecordClass) + N' = 2 then null else qty_fail end ';	

				if @pQtyLastPass is not null
					SET @pSqlUpdate = @pSqlUpdate + N'		,qty_last_pass = case when ' + convert(varchar,@pRecordClass) + N' = 2 then ' + convert(varchar,@pQtyLastPass) + N' else qty_last_pass end ';
				ELSE
					SET @pSqlUpdate = @pSqlUpdate + N'		,qty_last_pass = case when ' + convert(varchar,@pRecordClass) + N' = 2 then null else qty_last_pass end ';	
				
				if @pQtyLastFail is not null
					SET @pSqlUpdate = @pSqlUpdate + N'		,qty_last_fail = case when ' + convert(varchar,@pRecordClass) + N' = 2 then ' + convert(varchar,@pQtyLastFail) + N' else qty_last_fail end ';
				ELSE
					SET @pSqlUpdate = @pSqlUpdate + N'		,qty_last_fail = case when ' + convert(varchar,@pRecordClass) + N' = 2 then null else qty_last_pass end ';	

				if @pQtyPassStepSum is not null
					SET @pSqlUpdate = @pSqlUpdate + N'		,qty_pass_step_sum = case when ' + convert(varchar,@pRecordClass) + N' = 2 then ' + convert(varchar,@pQtyPassStepSum) + N' else qty_pass_step_sum end ';
				ELSE
					SET @pSqlUpdate = @pSqlUpdate + N'		,qty_pass_step_sum = case when ' + convert(varchar,@pRecordClass) + N' = 2 then null else qty_pass_step_sum end ';	

				if @pQtyFailStepSum is not null
					SET @pSqlUpdate = @pSqlUpdate + N'		,qty_fail_step_sum = case when ' + convert(varchar,@pRecordClass) + N' = 2 then ' + convert(varchar,@pQtyFailStepSum) + N' else qty_fail_step_sum end ';
				ELSE
					SET @pSqlUpdate = @pSqlUpdate + N'		,qty_fail_step_sum = case when ' + convert(varchar,@pRecordClass) + N' = 2 then null else qty_fail_step_sum end ';	

				SET @pSqlUpdate = @pSqlUpdate + N'		,process_state = case when ' + convert(varchar,@pRecordClass) + N' = 2 then 0 else 2 end ';
				SET @pSqlUpdate = @pSqlUpdate + N'		,finish_date_id = case when ' + convert(varchar,@pRecordClass) + N' = 2 then ' + convert(varchar,@pDayId) + N' else finish_date_id end ';
				SET @pSqlUpdate = @pSqlUpdate + N'		,finished_at = case when ' + convert(varchar,@pRecordClass) + N' = 2 then ''' + convert(varchar,@pRecordedAt,21) + N''' else finished_at end ';

				if @pMachineId is not null
					SET @pSqlUpdate = @pSqlUpdate + N'		,machine_id =' + convert(varchar,@pMachineId);
				ELSE
					SET @pSqlUpdate = @pSqlUpdate + N'		,machine_id = null' ;

				SET @pSqlUpdate = @pSqlUpdate + N'		,updated_at =''' + convert(varchar,@pRecordedAt,21) + '''' ;

				/* 2018-Dec-06 del This treatment moved to other procedure(sp_apcs_04_update_lots_for_shipped_lot)
				--2018-Nov-13 add start
				if (@pIsLastStepNo = 1) 
					BEGIN 
						if (@pRecordClass = 2) 
							BEGIN
								SET @pSqlUpdate = @pSqlUpdate + N'		,wip_state =100' ;
								SET @pSqlUpdate = @pSqlUpdate + N'		,ship_date_id = ' + convert(varchar,@pDayId) ;
								SET @pSqlUpdate = @pSqlUpdate + N'		,ship_at = ''' + convert(varchar,@pRecordedAt,21) + '''' ;
							END;
					END;
				--2018-Nov-13 add end
				*/

				--2019-May-23 add start for DC
				SET @pSqlUpdate = @pSqlUpdate + N'	,wip_state = case when wip_state < 20 then 20 else wip_state end ';
				--2019-May-23 add end for DC

				SET @pSqlUpdate = @pSqlUpdate + N' where id = ' + convert(varchar,@pLotID);

				PRINT 'Row=' + convert(varchar,@pCurCnt) + '/id=' + convert(varchar,@pid) + ' > @pSqlUpdate=' + @pSqlUpdate;
				
				EXECUTE (@pSqlUpdate);
 

				FETCH NEXT FROM Cur_Latest_History
					INTO
						@pID
						,@pLotID
						,@pStepNo
						,@pProcessId
						,@pJobId
						,@pQtyPass
						,@pQtyFail
						,@pQtyLastPass
						,@pQtyLastFail
						,@pQtyPassStepSum
						,@pQtyFailStepSum
						,@pRecordClass
						,@pProcessState
						,@pDayId
						,@pRecordedAt
						,@pMachineId
						,@pIsLastStepNo; --2018-Nov-13 Add IsLastStepNo

			END;
			
		COMMIT TRANSACTION;

		CLOSE Cur_Latest_History;
		DEALLOCATE Cur_Latest_History;

	END TRY

	BEGIN CATCH

		IF @@TRANCOUNT <> 0
			BEGIN
				ROLLBACK TRANSACTION;
			END;

		CLOSE Cur_Latest_History;
		DEALLOCATE Cur_Latest_History;

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

