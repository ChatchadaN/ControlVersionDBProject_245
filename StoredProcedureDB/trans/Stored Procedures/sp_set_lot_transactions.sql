-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_lot_transactions]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE LotTransaction_cur CURSOR FOR
	WITH TableCTE1 AS (
		SELECT [lot_process_records].[id]
			, [lot_process_records].[lot_id]
			, [lot_process_records].[process_id]
			, [lot_process_records].[job_id]
		FROM [APCSProDB].[trans].[lot_process_records]
		WHERE ([recorded_at] BETWEEN DATEADD(MINUTE, -30, GETDATE()) AND GETDATE())
		--WHERE ([recorded_at] BETWEEN '2024-08-02 10:00:00' AND '2024-08-02 10:30:00')
		--WHERE [id] = 162191182
			AND [record_class] = 2
	)
	SELECT * FROM TableCTE1

	DECLARE @id INT
		, @lot_id INT
		, @process_id INT
		, @job_id INT

	OPEN LotTransaction_cur

	FETCH NEXT FROM LotTransaction_cur INTO @id, @lot_id, @process_id, @job_id;

	WHILE @@FETCH_STATUS = 0
	BEGIN
		IF EXISTS (SELECT [id] FROM [APCSProDB].[trans].[lot_extend_records] WHERE [id] = @id)
		BEGIN
			--IF NOT EXISTS (
			--	SELECT [package_groups].[id]
			--	FROM [APCSProDB].[trans].[lots] 
			--	INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
			--	INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
			--	INNER JOIN [APCSProDB].[method].[package_groups] ON [packages].[package_group_id] = [package_groups].[id]
			--	WHERE [package_groups].[id] = 35
			--		AND [lots].[id] = @lot_id
			--)
			--BEGIN
				PRINT CAST(@id AS VARCHAR(10)) + ' Have' 
				MERGE [APCSProDWR].[trans].[lot_transactions] AS [old_data]
				USING ( SELECT [processes].[name] AS [process]
						, [jobs].[name] AS [flow]
						, XMLdata.value('(MCNo)[1]', 'varchar(50)') AS [mc_no]
						, XMLdata.value('(MCType)[1]', 'varchar(50)') AS [mc_type]
						, [lots].[lot_no] AS [lot_no]
						, [packages].[name] AS [package]
						, [device_names].[name] AS [device]
						, CAST(XMLdata.value('(SetupTime)[1]', 'datetimeoffset') AS DATETIME) AS [lot_setup_time]
						, CAST(XMLdata.value('(StartTime)[1]', 'datetimeoffset') AS DATETIME) AS [lot_start_time]
						, CAST(XMLdata.value('(EndTime)[1]', 'datetimeoffset') AS DATETIME) AS [lot_end_time]
						, CAST(XMLdata.value('(CloseTime)[1]', 'datetimeoffset') AS DATETIME) AS [lot_close_time]
						, XMLdata.value('(SetupUserCode)[1]', 'varchar(50)') AS [opno_setup]
						, XMLdata.value('(StartUserCode)[1]', 'varchar(50)') AS [opno_start]
						, XMLdata.value('(EndUserCode)[1]', 'varchar(50)') AS [opno_end]
						, XMLdata.value('(InputQty)[1]', 'varchar(50)') AS [input_qty]
						, XMLdata.value('(GoodQty)[1]', 'varchar(50)') AS [total_good]
						, XMLdata.value('(NgQty)[1]', 'varchar(50)') AS [total_ng]
						, XMLdata.value('(InputAdjustQty)[1]', 'varchar(50)') AS [input_qty_adjust]
						, XMLdata.value('(GoodAdjustQty)[1]', 'varchar(50)') AS [good_adjust]
						, XMLdata.value('(NgAdjustQty)[1]', 'varchar(50)') AS [ng_adjust]
						, XMLdata.value('(CloseUserCode)[1]', 'varchar(50)') AS [op_judgement]
						, XMLdata.value('(OPRate)[1]', 'varchar(100)')  AS [op_rate]
						, XMLdata.value('(AverageRPM)[1]', 'varchar(100)') AS [average_rpm]
						, XMLdata.value('(MTBF)[1]', 'varchar(100)') AS [mtbf]
						, XMLdata.value('(MTTR)[1]', 'varchar(100)') AS [mttr]
						, XMLdata.value('(AlarmTotal)[1]', 'varchar(100)') AS [alarm_total]
						, XMLdata.value('(RunDuration)[1]', 'varchar(100)')  AS [run_time]
						, XMLdata.value('(StopDuration)[1]', 'varchar(100)') AS [stop_time]
						, XMLdata.value('(AlarmDuration)[1]', 'varchar(100)') AS [alarm_time]
						, XMLdata.value('(GLCheck)[1]', 'varchar(100)') AS [gl_check]
						, XMLdata.value('(LotJudgement)[1]', 'varchar(100)') AS [lot_judgement]
						, XMLdata.value('(Remark)[1]', 'varchar(100)') AS [remark]
						, XMLdata.value('(Yield)[1]', 'varchar(50)') AS [final_yield]
						, XMLdata.value('(CarrierInfo/CurrentCarrierNo)[1]', 'varchar(50)') AS [carrier_no]
						, GETDATE() AS [created_at]
						, 1 AS [created_by]
						, NULL AS [updated_at]
						, NULL AS [updated_by]
						, lot_process_records.id AS lot_process_record_id
					FROM (
						SELECT @id AS [id]
							, @lot_id AS [lot_id]
							, @process_id AS [process_id]
							, @job_id AS [job_id]
					) AS [lot_process_records]
					INNER JOIN [APCSProDB].[trans].[lots] ON [lot_process_records].[lot_id] = [lots].[id]
					INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
					INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
					INNER JOIN [APCSProDB].[method].[processes] ON [lot_process_records].[process_id] = [processes].[id]
					INNER JOIN [APCSProDB].[method].[jobs] ON [lot_process_records].[job_id] = [jobs].[id]
					INNER JOIN [APCSProDB].[trans].[lot_extend_records] ON [lot_process_records].[id] = [lot_extend_records].[id]
					OUTER APPLY lot_extend_records.extend_data.nodes('LotDataCommon') AS XTbl(XMLdata)
				) AS [new_data] ON ([old_data].[process] = [new_data].[process] 
					AND [old_data].[flow] = [new_data].[flow]
					AND [old_data].[lot_no] = [new_data].[lot_no]
					AND [old_data].[lot_setup_time] = [new_data].[lot_setup_time]
					AND [old_data].[lot_start_time] = [new_data].[lot_start_time]
					AND [old_data].[lot_end_time] = [new_data].[lot_end_time]
					AND [old_data].[lot_close_time] = [new_data].[lot_close_time])
				WHEN NOT MATCHED BY TARGET  
					THEN INSERT 
					( 
						[process]
						, [flow]
						, [mc_no]
						, [mc_type]
						, [lot_no]
						, [package]
						, [device]
						, [lot_setup_time]
						, [lot_start_time]
						, [lot_end_time]
						, [lot_close_time]
						, [opno_setup]
						, [opno_start]
						, [opno_end]
						, [input_qty]
						, [total_good]
						, [total_ng]
						, [input_qty_adjust]
						, [good_adjust]
						, [ng_adjust]
						, [op_judgement]
						, [op_rate]
						, [average_rpm]
						, [mtbf]
						, [mttr]
						, [alarm_total]
						, [run_time]
						, [stop_time]
						, [alarm_time]
						, [gl_check]
						, [lot_judgement]
						, [remark]
						, [final_yield]
						, [carrier_no]
						, [created_at]
						, [created_by]
						, [updated_at]
						, [updated_by]
						, [lot_process_record_id]
					)
					VALUES  
					( 
						[new_data].[process]
						, [new_data].[flow]
						, [new_data].[mc_no]
						, [new_data].[mc_type]
						, [new_data].[lot_no]
						, [new_data].[package]
						, [new_data].[device]
						, [new_data].[lot_setup_time]
						, [new_data].[lot_start_time]
						, [new_data].[lot_end_time]
						, [new_data].[lot_close_time]
						, [new_data].[opno_setup]
						, [new_data].[opno_start]
						, [new_data].[opno_end]
						, [new_data].[input_qty]
						, [new_data].[total_good]
						, [new_data].[total_ng]
						, [new_data].[input_qty_adjust]
						, [new_data].[good_adjust]
						, [new_data].[ng_adjust]
						, [new_data].[op_judgement]
						, [new_data].[op_rate]
						, [new_data].[average_rpm]
						, [new_data].[mtbf]
						, [new_data].[mttr]
						, [new_data].[alarm_total]
						, [new_data].[run_time]
						, [new_data].[stop_time]
						, [new_data].[alarm_time]
						, [new_data].[gl_check]
						, [new_data].[lot_judgement]
						, [new_data].[remark]
						, [new_data].[final_yield]
						, [new_data].[carrier_no]
						, [new_data].[created_at]
						, [new_data].[created_by]
						, [new_data].[updated_at]
						, [new_data].[updated_by] 
						, [new_data].[lot_process_record_id]
					);
			--END
			--ELSE
			--BEGIN
			--	PRINT CAST(@id AS VARCHAR(10)) + ' OUTSOURCE';
			--END	
		END
		ELSE
		BEGIN
			PRINT CAST(@id AS VARCHAR(10)) + ' NotHave' 
		END
	
		FETCH NEXT FROM LotTransaction_cur INTO @id, @lot_id, @process_id, @job_id;
	END

	CLOSE LotTransaction_cur
	DEALLOCATE LotTransaction_cur
END