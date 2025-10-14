

-- =============================================
-- Author:		<M.Yamamoto>
-- Create date: <12th Oct 2018>
-- Description:	<update Lots using latest data in temp_lot_process_records>
-- =============================================
CREATE PROCEDURE [etl].[sp_apcs_03_update_lots] (
	@ServerName_APCSPro NVARCHAR(128) 
    ,@DatabaseName_APCSPro NVARCHAR(128)
	,@ServerName_APCSProDWH NVARCHAR(128) 
    ,@DatabaseName_APCSProDWH NVARCHAR(128)
	,@logtext NVARCHAR(max) output
	,@errnum  int output
	,@errline int output
	,@errmsg nvarchar(max) output
	) AS
BEGIN
/*
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
*/

   ---------------------------------------------------------------------------
	--(1)check argument
    ---------------------------------------------------------------------------
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

	DECLARE @pObjAPCSPro NVARCHAR(128) = ''
	DECLARE @pObjAPCSProDWH NVARCHAR(128) = ''

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
	--(2)DECRARE
    ---------------------------------------------------------------------------
	DECLARE @pFunctionName NVARCHAR(128) = N'';
	DECLARE @pEndTime DATETIME;
	DECLARE @pRet INT = 0;
	--DECLARE @pErrNum INT = 0;
	--DECLARE @pErrMsg NVARCHAR(4000) = '';
	--DECLARE @pErrLine INT = 0;
	
	BEGIN TRY
		SELECT @pFunctionName = OBJECT_NAME(@@PROCID);
		--SELECT @endtime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:00:00.000'));
		--yyyy/MM/dd HH:mm:ss.ff3
		/* v10 change
		SELECT @pEndTime = CONVERT(DATETIME , FORMAT(GETDATE(), 'yyyy-MM-dd HH:mm:ss.ff3'));
		*/
		SELECT @pEndTime = dateadd(minute,(-1)*(DATEPART(n,GETDATE()) % 10),convert(datetime,format(GETDATE(),'yyyy-MM-dd HH:mm:00.000')));
	END TRY
	BEGIN CATCH
		SET @logtext = N'[ERR]'
		SET @logtext = @logtext + ERROR_MESSAGE();
		RETURN -1;
	END CATCH;

DECLARE @pSqlSelect NVARCHAR(4000) = '';
	SET @pSqlSelect = N'';
	SET @pSqlSelect = @pSqlSelect + N'select ';
	SET @pSqlSelect = @pSqlSelect + N'	rec.id ';
	SET @pSqlSelect = @pSqlSelect + N'	,rec.lot_id ';
	SET @pSqlSelect = @pSqlSelect + N'	,rec.step_no ';
	SET @pSqlSelect = @pSqlSelect + N'	,rec.process_id ';
	SET @pSqlSelect = @pSqlSelect + N'	,rec.job_id ';
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
	SET @pSqlSelect = @pSqlSelect + N'from ';
	SET @pSqlSelect = @pSqlSelect + N'	' + @pObjAPCSProDWH + N'.[dwh].[temp_lot_process_records] rec WITH (NOLOCK) ';  
	SET @pSqlSelect = @pSqlSelect + N'where rec.last_record_flg = 1';  

	PRINT '----------------------------------------';
	PRINT @pSqlSelect;

	DECLARE @pID BIGINT = 0; 
	DECLARE @pLotID INT = 0;
	DECLARE @pStepNo INT = 0; 
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
	DECLARE @pRowCount INT = 0;
	DECLARE @pSqlUpdate NVARCHAR(4000) = '';
	
   ---------------------------------------------------------------------------
	--(5) Open Cur
    ---------------------------------------------------------------------------
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
		,@pMachineId;
   ---------------------------------------------------------------------------
	--(6) update
    ---------------------------------------------------------------------------

	BEGIN TRY

		BEGIN TRANSACTION;
		WHILE (@@FETCH_STATUS = 0)

			BEGIN
				SET @pRowCount = @pRowCount + 1;

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
				SET @pSqlUpdate = @pSqlUpdate + N' where id = ' + convert(varchar,@pLotID);

				PRINT 'cnt=' + convert(varchar,@prowcount,21) + '> @pSqlUpdate=' + @pSqlUpdate;
				--SET @pStepNo = 2;
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
						,@pMachineId;

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

		SET @logtext = '[ERR]' + @errmsg;

		CLOSE Cur_Latest_History;
		DEALLOCATE Cur_Latest_History;

		--EXECUTE [etl].[sp_output_logfile] @FilePathName_=@errlogfilepathname, @FunctionName_=@FunctionName, @Text_=@logtext;
		RETURN -1;
	END CATCH;


 

	---------------------------------------------------------------------------
	--(7) close
    ---------------------------------------------------------------------------
	CLOSE Cur_Latest_History;
	DEALLOCATE Cur_Latest_History;

RETURN 0;

END;

/*
   ---------------------------------------------------------------------------
	--(3)Main Process
    ---------------------------------------------------------------------------
	BEGIN TRY

		BEGIN TRANSACTION;
			
			PRINT '-----1) truncate temporary (dwh.temp_lots)';
			SET @pStepNo = 1;
			--print (@@pSqlTrunc);
			EXECUTE (@pSqlTrunc);

			PRINT '-----2) temporary ==> dwh.temp_lots';
			SET @pStepNo = 2;
			EXECUTE (@pSqlInsto + @pSqlIns + @pSqlSelect);

			PRINT '-----3) Get row counts';
			SET @pStepNo = 3;
			--PRINT '@sqlCommon=' + @pSqlCommon;
			EXEC sp_executesql @pSqlRowCnt, N'@LotsCnt INT OUTPUT', @LotsCnt=@pAddCount OUTPUT;
			PRINT 'Count=' + convert(varchar,@pAddCount);

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

		SET @logtext = @errMsg;
		SET @logtext = @logtext + N'/step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/count:';
		SET @logtext = @logtext + convert(varchar,@pAddCount);
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;

	BEGIN TRY

		PRINT '-----4) Check row counts';
		SET @pStepNo = 4;
		if @pAddCount = 0

			BEGIN
				EXECUTE @pRet = [etl].[sp_update_function_finish_control] @function_name_=@pFunctionName, @finished_at_=@pEndTime
															, @errnum = @errnum OUTPUT,@errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;
				IF @pRet<>0
					begin
						SET @logtext = N'@ret<>0 [sp_update_function_finish_control] /ret:' ;
						SET @logtext = @logtext + convert(varchar,@pRet) ;
						SET @logtext = @logtext + N'/func:';
						SET @logtext = @logtext + convert(varchar,@pFunctionName);
						SET @logtext = @logtext + N'/fin:';
						SET @logtext = @logtext + convert(varchar,@pEndtime,21);
						SET @logtext = @logtext + N'/step:';
						SET @logtext = @logtext + convert(varchar,@pStepNo);
						PRINT 'logtext=' + @logtext;
						RETURN -1;
					end;
			END;

		PRINT '-----5) count up id in trans.numbers'
		SET @pStepNo = 5;
		EXECUTE @pRet = [etl].[sp_update_numbers] @servername = @ServerName_APCSPro, @databasename = @DatabaseName_APCSPro
												, @schemaname=N'trans', @name=N'lots.id',@count = @pAddCount
												, @id_used = @pIdBefor OUTPUT, @id_used_new=@pIdAfter OUTPUT
												, @errnum = @errnum OUTPUT, @errline = @errline OUTPUT, @errmsg = @errmsg OUTPUT;
		IF @pRet<>0
			begin
				SET @logtext = N'@ret<>0 [sp_update_numbers] /ret:' ;
				SET @logtext = @logtext + convert(varchar,@pRet) ;
				SET @logtext = @logtext + N'/name:lots.id' ;
				SET @logtext = @logtext + N'/count:';
				SET @logtext = @logtext + convert(varchar,@pAddCount) ;
				SET @logtext = @logtext + N'/step:';
				SET @logtext = @logtext + convert(varchar,@pStepNo);
				PRINT 'logtext=' + @logtext;
				return -1;
			end;

	END TRY

	BEGIN CATCH

		select @errmsg = ERROR_MESSAGE()
				,@errnum = ERROR_NUMBER() 
				,@errline = ERROR_LINE()

		SET @logtext = @errMsg;
		SET @logtext = @logtext + N'/step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/count:'
		SET @logtext = @logtext + convert(varchar,@pAddCount);
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;

	BEGIN TRY

		PRINT '-----6) dwh.temp_lots ==> trans.lots'
		SET @pStepNo = 6;
		SET @pSqlInsTo = N'';
		SET @pSqlInsTo = @pSqlInsTo + N'insert into ' + @pObjAPCSPro + N'.[trans].[lots] ';

		SET @pSqlSelect = N'';
		SET @pSqlSelect = @pSqlSelect + N'select ';
		SET @pSqlSelect = @pSqlSelect + N'id + ' + convert(varchar,@pAddCount)  ;
		SET @pSqlSelect = @pSqlSelect + N' ,lot_no ';
		SET @pSqlSelect = @pSqlSelect + N' ,product_family_id ';
		SET @pSqlSelect = @pSqlSelect + N' ,act_package_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,act_device_name_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,device_slip_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,order_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,step_no '; 
		SET @pSqlSelect = @pSqlSelect + N'	,act_process_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,act_job_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,qty_in ';
		SET @pSqlSelect = @pSqlSelect + N'	,qty_pass ';
		SET @pSqlSelect = @pSqlSelect + N'	,qty_fail ';
		SET @pSqlSelect = @pSqlSelect + N'	,qty_last_pass ';
		SET @pSqlSelect = @pSqlSelect + N'	,qty_last_fail ';
		SET @pSqlSelect = @pSqlSelect + N'	,qty_pass_step_sum '; 
		SET @pSqlSelect = @pSqlSelect + N'	,qty_fail_step_sum ';
		SET @pSqlSelect = @pSqlSelect + N'	,qty_divided ';
		SET @pSqlSelect = @pSqlSelect + N'	,qty_hasuu ';
		SET @pSqlSelect = @pSqlSelect + N'	,qty_out ';
		SET @pSqlSelect = @pSqlSelect + N'	,is_exist_work '; 
		SET @pSqlSelect = @pSqlSelect + N'	,in_plan_date_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,out_plan_date_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,master_lot_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,depth ';
		SET @pSqlSelect = @pSqlSelect + N'	,sequence '; 
		SET @pSqlSelect = @pSqlSelect + N'	,wip_state ';
		SET @pSqlSelect = @pSqlSelect + N'	,process_state '; 
		SET @pSqlSelect = @pSqlSelect + N'	,quality_state ';
		SET @pSqlSelect = @pSqlSelect + N'	,first_ins_state ';
		SET @pSqlSelect = @pSqlSelect + N'	,final_ins_state ';
		SET @pSqlSelect = @pSqlSelect + N'	,is_special_flow ';
		SET @pSqlSelect = @pSqlSelect + N'	,special_flow_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,is_temp_devided ';
		SET @pSqlSelect = @pSqlSelect + N'	,temp_devided_count ';
		SET @pSqlSelect = @pSqlSelect + N'	,product_class_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,priority ';
		SET @pSqlSelect = @pSqlSelect + N'	,finish_date_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,finished_at ';
		SET @pSqlSelect = @pSqlSelect + N'	,in_date_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,in_at ';
		SET @pSqlSelect = @pSqlSelect + N'	,ship_date_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,ship_at ';
		SET @pSqlSelect = @pSqlSelect + N'	,modify_out_plan_date_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,modified_at ';
		SET @pSqlSelect = @pSqlSelect + N'	,modified_by ';
		SET @pSqlSelect = @pSqlSelect + N'	,location_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,acc_location_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,machine_id ';
		SET @pSqlSelect = @pSqlSelect + N'	,container_no ';
		SET @pSqlSelect = @pSqlSelect + N'	,std_time_sum '; 
		SET @pSqlSelect = @pSqlSelect + N'	,start_step_no '; --temporary
		SET @pSqlSelect = @pSqlSelect + N'	,m_no '; 
		SET @pSqlSelect = @pSqlSelect + N'	,qc_comment_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,qc_memo_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,pass_plan_time '; 
		SET @pSqlSelect = @pSqlSelect + N'	,pass_plan_time_up '; 
		SET @pSqlSelect = @pSqlSelect + N'	,process_job_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,origin_material_id '; 
		SET @pSqlSelect = @pSqlSelect + N'	,carried_at '; 
		SET @pSqlSelect = @pSqlSelect + N'	,is_imported '; -- for APCS
		SET @pSqlSelect = @pSqlSelect + N'	,created_at '; 
		SET @pSqlSelect = @pSqlSelect + N'	,created_by '; 
		SET @pSqlSelect = @pSqlSelect + N'	,updated_at '; 
		SET @pSqlSelect = @pSqlSelect + N'	,updated_by '; 
		SET @pSqlSelect = @pSqlSelect + N'from ';
		SET @pSqlSelect = @pSqlSelect + @pObjAPCSProDWH + N'.[act].[temp_lots] lt WITH (NOLOCK) ';  

		--PRINT @pSqlSelect;
		BEGIN TRANSACTION

			EXECUTE (@pSqlInsTo + @pSqlIns + @pSqlSelect);

			PRINT '-----7) save the process log'
			SET @pStepNo = 7;
			EXECUTE @pRet = [etl].[sp_update_function_finish_control] @function_name_=@pFunctionName, @finished_at_=@pEndTime
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
					SET @logtext = @logtext + convert(varchar,@pFunctionName);
					SET @logtext = @logtext + N'/fin:';
					SET @logtext = @logtext + convert(varchar,@pEndtime,21);
					SET @logtext = @logtext + N'/step:';
					SET @logtext = @logtext + convert(varchar,@pStepNo);
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

		SET @logtext = @errMsg;
		SET @logtext = @logtext + N'/Step:' ;
		SET @logtext = @logtext + convert(varchar,@pStepNo) ;
		SET @logtext = @logtext + N'/Count:'
		SET @logtext = @logtext + convert(varchar,@pAddCount);
		PRINT '@logtext=' + @logtext;
		RETURN -1;

	END CATCH;

	*/


