-- =============================================
-- Author:		<Author,Yutida P.>
-- Create date: <Create Date, Sep. 25, 2025>
-- Description:	<Description, Migrate data from lot_transactions>
-- =============================================
CREATE PROCEDURE [lds].[sp_set_lot_transactions_to_dwh]
	--@hq_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRY	

		DECLARE @last_lsn binary(10) = 0;
		DECLARE @max_lsn binary(10) = NULL;
		-- DECLARE @server varchar(15);

		-- Get @max_lsn from APCSProDWR.cdc.trans_lot_transactions_CT
		SELECT @max_lsn = MAX(__$start_lsn) 
		FROM APCSProDWR.cdc.trans_lot_transactions_CT
		WHERE __$operation = 2;

		-- Get @LSN from dbo.cdc_lsn_tracker
		SELECT @last_lsn = [last_lsn]
		FROM [APCSProDWR].[dbo].[cdc_lsn_tracker]
		WHERE [table_name] = 'trans.lot_transactions';

		IF ISNULL(@max_lsn,0) <> 0
		BEGIN		
			DECLARE @id int,			
					@process nvarchar(20), 
					@flow nvarchar(20), 
					@mc_no nvarchar(30), 
					@mc_type nvarchar(20), 
					@lot_no char(20), 
					@package char(20), 
					@device char(20), 
					@lot_setup_time datetime, 
					@lot_start_time datetime, 
					@lot_end_time datetime, 
					@lot_close_time datetime, 
					@opno_setup varchar(8), 
					@opno_start varchar(8), 
					@opno_end varchar(8), 
					@input_qty int, 
					@total_good int, 
					@total_ng int, 
					@input_qty_adjust int, 
					@good_adjust int, 
					@ng_adjust int, 
					@op_judgement varchar(8), 
					@op_rate real, 
					@average_rpm real, 
					@mtbf real, 
					@mttr real, 
					@alarm_total real, 
					@run_time real, 
					@stop_time real, 
					@alarm_time real, 
					@gl_check varchar(8), 
					@lot_judgement varchar(20), 
					@remark varchar(100), 
					@final_yield real, 
					@CarrierUnloadNo varchar(20), 
					@CarrierLoadNo varchar(20), 
					@comment nvarchar(255),
					@division_id int,
					@created_at datetime,
					@created_by int,
					@updated_at datetime,
					@updated_by int;

			IF CURSOR_STATUS('global', 'cur_transactions') >= -1
			BEGIN
				CLOSE cur_transactions;
				DEALLOCATE cur_transactions;
			END

			DECLARE cur_transactions CURSOR FOR
			SELECT lot_transactions.[id]
					,lot_transactions.[process]
					,lot_transactions.[flow]
					,lot_transactions.[mc_no]
					,lot_transactions.[mc_type]
					,lot_transactions.[lot_no]
					,lot_transactions.[package]
					,lot_transactions.[device]
					,lot_transactions.[lot_setup_time]
					,lot_transactions.[lot_start_time]
					,lot_transactions.[lot_end_time]
					,lot_transactions.[lot_close_time]
					,lot_transactions.[opno_setup]
					,lot_transactions.[opno_start]
					,lot_transactions.[opno_end]
					,lot_transactions.[input_qty]
					,lot_transactions.[total_good]
					,lot_transactions.[total_ng]
					,lot_transactions.[input_qty_adjust]
					,lot_transactions.[good_adjust]
					,lot_transactions.[ng_adjust]
					,lot_transactions.[op_judgement]
					,lot_transactions.[op_rate]
					,lot_transactions.[average_rpm]
					,lot_transactions.[mtbf]
					,lot_transactions.[mttr]
					,lot_transactions.[alarm_total]
					,lot_transactions.[run_time]
					,lot_transactions.[stop_time]
					,lot_transactions.[alarm_time]
					,lot_transactions.[gl_check]
					,lot_transactions.[lot_judgement]
					,lot_transactions.[remark]
					,lot_transactions.[final_yield]
					,lot_transactions.[CarrierUnloadNo]
					,lot_transactions.[created_at]
					,lot_transactions.[created_by]
					,lot_transactions.[updated_at]
					,lot_transactions.[updated_by]
					,lot_transactions.[CarrierLoadNo]
					,lot_transactions.[comment]
					, divisions.id --42 columns
			FROM APCSProDWR.cdc.trans_lot_transactions_CT lot_transactions
			join DWH.man.employees on lot_transactions.opno_setup = employees.emp_code collate SQL_Latin1_General_CP1_CI_AS
			join DWH.man.employee_organizations on employees.id = employee_organizations.emp_id
			join [DWH].[man].[organizations] on employee_organizations.organization_id = [organizations].id
			JOIN [DWH].[man].divisions on TRIM([organizations].division) = TRIM(divisions.[name])
			WHERE __$operation = 2
			AND __$start_lsn > @last_lsn
			AND   __$start_lsn <= @max_lsn;

			OPEN cur_transactions
			FETCH NEXT FROM cur_transactions 
			INTO @id,@process,@flow,@mc_no,@mc_type,@lot_no,@package,@device,@lot_setup_time
				 ,@lot_start_time,@lot_end_time,@lot_close_time,@opno_setup,@opno_start,@opno_end,@input_qty,@total_good,@total_ng,@input_qty_adjust
				 ,@good_adjust,@ng_adjust,@op_judgement,@op_rate,@average_rpm,@mtbf,@mttr,@alarm_total,@run_time,@stop_time,@alarm_time,@gl_check
				 ,@lot_judgement,@remark,@final_yield,@CarrierUnloadNo,@created_at,@created_by,@updated_at,@updated_by,@CarrierLoadNo,@comment,@division_id
			
			WHILE @@FETCH_STATUS = 0
			BEGIN
				MERGE [DWH].[trans].[lot_transactions] AS target
				USING (
					SELECT  @id AS id, @lot_no AS lot_no, 
							@process AS process, 
							@flow AS flow, 
							@mc_no AS mc_no, 
							@mc_type AS mc_type, 
							@package AS package, 
							@device AS device, 
							@lot_setup_time AS lot_setup_time, 
							@lot_start_time AS lot_start_time, 
							@lot_end_time AS lot_end_time, 
							@lot_close_time AS lot_close_time, 
							@opno_setup AS opno_setup, 
							@opno_start AS opno_start, 
							@opno_end AS opno_end, 
							@input_qty AS input_qty, 
							@total_good AS total_good, 
							@total_ng AS total_ng, 
							@input_qty_adjust AS input_qty_adjust, 
							@good_adjust AS good_adjust, 
							@ng_adjust AS ng_adjust, 
							@op_judgement AS op_judgement, 
							@op_rate AS op_rate, 
							@average_rpm AS average_rpm, 
							@mtbf AS mtbf, 
							@mttr AS mttr, 
							@alarm_total AS alarm_total, 
							@run_time AS run_time, 
							@stop_time AS stop_time, 
							@alarm_time AS alarm_time, 
							@gl_check AS gl_check, 
							@lot_judgement AS lot_judgement, 
							@remark AS remark, 
							@final_yield AS final_yield, 
							@CarrierUnloadNo AS CarrierUnloadNo, 
							@CarrierLoadNo AS CarrierLoadNo, 
							@comment AS comment,
							@division_id AS division_id,
							@created_at AS created_at, @created_by AS created_by, @updated_at AS updated_at, @updated_by AS updated_by
				) AS source
				ON target.lot_transactions_id = source.id AND target.division_id = source.division_id
				WHEN NOT MATCHED BY TARGET THEN
					INSERT (   [process]
							  ,[flow]
							  ,[mc_no]
							  ,[mc_type]
							  ,[lot_no]
							  ,[package]
							  ,[device]
							  ,[lot_setup_time]
							  ,[lot_start_time]
							  ,[lot_end_time]
							  ,[lot_close_time]
							  ,[opno_setup]
							  ,[opno_start]
							  ,[opno_end]
							  ,[input_qty]
							  ,[total_good]
							  ,[total_ng]
							  ,[input_qty_adjust]
							  ,[good_adjust]
							  ,[ng_adjust]
							  ,[op_judgement]
							  ,[op_rate]
							  ,[average_rpm]
							  ,[mtbf]
							  ,[mttr]
							  ,[alarm_total]
							  ,[run_time]
							  ,[stop_time]
							  ,[alarm_time]
							  ,[gl_check]
							  ,[lot_judgement]
							  ,[remark]
							  ,[final_yield]
							  ,[carrier_no]
							  ,[created_at]
							  ,[created_by]
							  ,[updated_at]
							  ,[updated_by]
							  ,[division_id]
							  ,[lot_transactions_id])
					VALUES (   source.[process]
							  ,source.[flow]
							  ,source.[mc_no]
							  ,source.[mc_type]
							  ,source.[lot_no]
							  ,source.[package]
							  ,source.[device]
							  ,source.[lot_setup_time]
							  ,source.[lot_start_time]
							  ,source.[lot_end_time]
							  ,source.[lot_close_time]
							  ,source.[opno_setup]
							  ,source.[opno_start]
							  ,source.[opno_end]
							  ,source.[input_qty]
							  ,source.[total_good]
							  ,source.[total_ng]
							  ,source.[input_qty_adjust]
							  ,source.[good_adjust]
							  ,source.[ng_adjust]
							  ,source.[op_judgement]
							  ,source.[op_rate]
							  ,source.[average_rpm]
							  ,source.[mtbf]
							  ,source.[mttr]
							  ,source.[alarm_total]
							  ,source.[run_time]
							  ,source.[stop_time]
							  ,source.[alarm_time]
							  ,source.[gl_check]
							  ,source.[lot_judgement]
							  ,source.[remark]
							  ,source.[final_yield]
							  ,source.[CarrierUnloadNo]
							  ,source.[created_at]
							  ,source.[created_by]
							  ,source.[updated_at]
							  ,source.[updated_by]
							  ,source.[division_id]
							  ,source.[id]
					);

				FETCH NEXT FROM cur_transactions 
				INTO @id,@process,@flow,@mc_no,@mc_type,@lot_no,@package,@device,@lot_setup_time
					 ,@lot_start_time,@lot_end_time,@lot_close_time,@opno_setup,@opno_start,@opno_end,@input_qty,@total_good,@total_ng,@input_qty_adjust
					 ,@good_adjust,@ng_adjust,@op_judgement,@op_rate,@average_rpm,@mtbf,@mttr,@alarm_total,@run_time ,@stop_time,@alarm_time,@gl_check
					 ,@lot_judgement,@remark,@final_yield,@CarrierUnloadNo,@created_at,@created_by,@updated_at,@updated_by,@CarrierLoadNo,@comment,@division_id

			END

			CLOSE cur_transactions;
			DEALLOCATE cur_transactions;

			-- Update @LSN to dbo.cdc_lsn_tracker
			UPDATE [APCSProDWR].[dbo].[cdc_lsn_tracker]
			SET last_lsn = @max_lsn, last_sync_time = GETDATE()
			WHERE [table_name] = 'trans.lot_transactions';

			PRINT 'Success';
			
		END 

	END TRY
	BEGIN CATCH

		IF CURSOR_STATUS('global', 'cur_transactions') >= -1
		BEGIN
			CLOSE cur_transactions;
			DEALLOCATE cur_transactions;
		END

		PRINT CONCAT('Error: ', ERROR_MESSAGE());

	END CATCH

END