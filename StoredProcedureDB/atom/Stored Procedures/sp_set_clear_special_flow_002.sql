-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_clear_special_flow_002]
	-- Add the parameters for the stored procedure here
	@lot_id int,
	@special_id int,
	@lot_special_id int = NULL,
	@flowfon int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-------------------------------27/12/2021 9.33----------------------------------------------------
	--<< log exec
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no])
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [atom].[sp_set_clear_special_flow_v2_new] @lot_id = ''' + ISNULL(CAST(@lot_id AS varchar),'') + ''', @special_id = ''' + ISNULL(CAST(@special_id AS varchar),'') + ''', @lot_special_id = ''' 
			+ ISNULL(CAST(@lot_special_id AS varchar),'') +  ''', @flowfon = ''' + ISNULL(CAST(@flowfon AS varchar),'') +''''
		, (select cast(lot_no as varchar) from [APCSProDB].[trans].[lots] where id = @lot_id)
	-->> log exec

	
	DECLARE @counter int = 0
	DECLARE @run_status varchar(50)
	DECLARE @special_id_now int = 0
	DECLARE @is_special int = 0
	DECLARE @s_stepno int = NULL
	DECLARE @s_process int = NULL
	DECLARE @s_job int = NULL
	DECLARE @s_status int = 0
	DECLARE @special_flow_id_update int = NULL

	-- Insert statements for procedure here
	select @counter = count([special_flows].[id])
	from [APCSProDB].[trans].[lot_special_flows]
	left join
	(
		select [LotDetail].[record_class]
		, [LotDetail].[step_no]
		, [LotDetail].[qty_in]
		, [LotDetail].[qty_pass]
		, [LotDetail].[qty_fail]
		, [LotDetail].[qty_frame_in]
		, [LotDetail].[qty_frame_pass]
		, [LotDetail].[qty_frame_fail]
		, [LotDetail].[machine_id]
		, [LotDetail].[carrier_no]
		, [LotDetail].[next_carrier_no]
		, [LotDetail].[name]
		, [LotDetail].[emp_num]
		, [LotStart].[StartTime]
		, case when ([LotStart].[StartTime] <= [LotEnd].[EndTime]) then cast([LotEnd].[EndTime] as datetime2) end as EndTime
		from
		(
			select [step_no], [machine_id], MAX([id]) as max_id
			from [APCSProDB].[trans].[lot_process_records]
			where [lot_id] = @lot_id
			group by [step_no], [machine_id]
		) as StepFlow
		inner join 
		(
			select [lot_process_records].[id]
			, [lot_process_records].[record_class]
			, [lot_process_records].[step_no]
			, [lot_process_records].[qty_in]
			, [lot_process_records].[qty_pass]
			, [lot_process_records].[qty_fail]
			, [lot_process_records].[qty_frame_in]
			, [lot_process_records].[qty_frame_pass]
			, [lot_process_records].[qty_frame_fail]
			, [lot_process_records].[machine_id]
			, [lot_process_records].[carrier_no]
			, [lot_process_records].[next_carrier_no]
			, [APCSProDB].[mc].[machines].[name]
			, [APCSProDB].[man].[users].[emp_num]
			from [APCSProDB].[trans].[lot_process_records]
			left join [APCSProDB].[mc].[machines] on [lot_process_records].[machine_id] = [machines].[id]
			left join [APCSProDB].[man].[users] on [lot_process_records].[updated_by] = [users].[id] 
			where [lot_id] = @lot_id
		) as LotDetail
		on LotDetail.id = StepFlow.max_id
	
		left join
		(
			select [step_no],[machine_id],MAX([recorded_at]) as StartTime
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('1','31') and [lot_id] = @lot_id
			group by [step_no],[machine_id]
		) as LotStart
		on LotDetail.step_no = LotStart.step_no and LotDetail.machine_id = LotStart.machine_id
	
		left join
		(
			select [step_no],[machine_id],MAX([recorded_at]) as EndTime
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('2','12','32') and [lot_id] = @lot_id
			group by [step_no],[machine_id]
		) as LotEnd
		on LotDetail.step_no = LotEnd.step_no and LotDetail.machine_id = LotEnd.machine_id
	) as LotFlow
	on [lot_special_flows].[step_no] = [LotFlow].[step_no]
	inner join [APCSProDB].[method].[jobs] on [lot_special_flows].[job_id] = [jobs].[id]
	left join [APCSProDB].[trans].[item_labels] as [item_labels1] on [item_labels1].[name] = 'lot_process_records.record_class' and [item_labels1].[val] = [LotFlow].[record_class]
	inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
	where [special_flows].[lot_id] = @lot_id 
	and [special_flows].[id] = @special_id


	select 
		--@run_status = [item_labels1].[label_eng]
		@run_status = [item_labels1].[val]
	from [APCSProDB].[trans].[lot_special_flows]
	left join
	(
		select [LotDetail].[record_class]
		, [LotDetail].[step_no]
		, [LotDetail].[qty_in]
		, [LotDetail].[qty_pass]
		, [LotDetail].[qty_fail]
		, [LotDetail].[qty_frame_in]
		, [LotDetail].[qty_frame_pass]
		, [LotDetail].[qty_frame_fail]
		, [LotDetail].[machine_id]
		, [LotDetail].[carrier_no]
		, [LotDetail].[next_carrier_no]
		, [LotDetail].[name]
		, [LotDetail].[emp_num]
		, [LotStart].[StartTime]
		, case when ([LotStart].[StartTime] <= [LotEnd].[EndTime]) then cast([LotEnd].[EndTime] as datetime2) end as EndTime
		from
		(
			select [step_no], [machine_id], MAX([id]) as max_id
			from [APCSProDB].[trans].[lot_process_records]
			where [lot_id] = @lot_id
			group by [step_no], [machine_id]
		) as StepFlow
		inner join 
		(
			select [lot_process_records].[id]
			, [lot_process_records].[record_class]
			, [lot_process_records].[step_no]
			, [lot_process_records].[qty_in]
			, [lot_process_records].[qty_pass]
			, [lot_process_records].[qty_fail]
			, [lot_process_records].[qty_frame_in]
			, [lot_process_records].[qty_frame_pass]
			, [lot_process_records].[qty_frame_fail]
			, [lot_process_records].[machine_id]
			, [lot_process_records].[carrier_no]
			, [lot_process_records].[next_carrier_no]
			, [APCSProDB].[mc].[machines].[name]
			, [APCSProDB].[man].[users].[emp_num]
			from [APCSProDB].[trans].[lot_process_records]
			left join [APCSProDB].[mc].[machines] on [lot_process_records].[machine_id] = [machines].[id]
			left join [APCSProDB].[man].[users] on [lot_process_records].[updated_by] = [users].[id] 
			where [lot_id] = @lot_id
		) as LotDetail
		on LotDetail.id = StepFlow.max_id
	
		left join
		(
			select [step_no],[machine_id],MAX([recorded_at]) as StartTime
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('1','31') and [lot_id] = @lot_id
			group by [step_no],[machine_id]
		) as LotStart
		on LotDetail.step_no = LotStart.step_no and LotDetail.machine_id = LotStart.machine_id
	
		left join
		(
			select [step_no],[machine_id],MAX([recorded_at]) as EndTime
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('2','12','32') and [lot_id] = @lot_id
			group by [step_no],[machine_id]
		) as LotEnd
		on LotDetail.step_no = LotEnd.step_no and LotDetail.machine_id = LotEnd.machine_id
	) as LotFlow
	on [lot_special_flows].[step_no] = [LotFlow].[step_no]
	inner join [APCSProDB].[method].[jobs] on [lot_special_flows].[job_id] = [jobs].[id]
	left join [APCSProDB].[trans].[item_labels] as [item_labels1] on [item_labels1].[name] = 'lot_process_records.record_class' and [item_labels1].[val] = [LotFlow].[record_class]
	inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
	where [special_flows].[lot_id] = @lot_id 
	and [special_flows].[id] = @special_id
	--where [device_flows].[device_slip_id] = (select device_slip_id from [APCSProDB].[trans].[lots] where [lots].[id] = @lot_id)

	-- 1 sp add by flow_patten_id > 1
	-- 2 sp has been processing
	-- 3 delete success
	IF(@flowfon = 366)
	BEGIN
		IF(@counter != 0)
		BEGIN
			IF(@run_status IS NULL or @run_status = 25 or @run_status = 23 or @run_status = 6 or @run_status = 4)
			BEGIN
				-------------------------(เข้าเงื่อนไขลบ)---------------------------------------
				SELECT @s_stepno = [device_flows].[step_no]
					, @s_process = [device_flows].[act_process_id]
					, @s_job = [device_flows].[job_id]
					, @is_special = [lots].[is_special_flow]
					, @s_status = CASE 
						WHEN 
						(
							SELECT step_no 
							FROM [APCSProDB].[trans].[lot_special_flows] 
							WHERE [lot_special_flows].[special_flow_id] = @special_id 
								AND [lot_special_flows].[id]  = @lot_special_id
						) BETWEEN [lots].[step_no] AND [device_flows].[step_no] THEN 1 --'TRUE'
						ELSE 0 --'FALSE' 
						END --AS [status_step_no]
				FROM (
					SELECT [lots].[special_flow_id]
						, [lots].[is_special_flow]
						, [lots].[device_slip_id]
						, [lots].[step_no]
					FROM [APCSProDB].[trans].[lots]
					WHERE [lots].[id] = @lot_id
				) AS [lots]
				INNER JOIN [APCSProDB].[method].[device_flows] ON [lots].[device_slip_id] = [device_flows].[device_slip_id]
					AND [device_flows].is_skipped != 1
				INNER JOIN [APCSProDB].[trans].[special_flows] ON [lots].[special_flow_id] = [special_flows].[id]
					AND [lots].[is_special_flow] = 1
				WHERE [device_flows].[step_no] = 
				(
					SELECT [device_flows].[next_step_no] 
					FROM [APCSProDB].[method].[device_flows] 
					WHERE [device_flows].[device_slip_id] = [lots].[device_slip_id]
						AND [device_flows].[step_no] = [lots].[step_no]
				);
				-----------------------------(<<< delete lot_process_records)-----------------------------
				DELETE from APCSProDB.trans.lot_process_records
				where lot_id = @lot_id 
					and special_flow_id = @special_id
					and step_no >= (
						SELECT step_no FROM [APCSProDB].[trans].[lot_special_flows] 
						WHERE [lot_special_flows].[special_flow_id] = @special_id 
						AND [lot_special_flows].[id]  = @lot_special_id
					)
				-----------------------------(delete lot_process_records >>>)-----------------------------
				--//////////////////////////////////////////////////////////////////////////////////////////////-
				-----------------------------(<<< delete lot_special_flows)-----------------------------
				DELETE FROM [APCSProDB].[trans].[lot_special_flows]
				WHERE [special_flow_id] = @special_id
				-----------------------------(delete lot_special_flows >>>)-----------------------------
				--//////////////////////////////////////////////////////////////////////////////////////////////-
				-----------------------------(<<< delete special_flows)-----------------------------
				DELETE FROM [APCSProDB].[trans].[special_flows]
				WHERE [id] = @special_id
				-----------------------------(delete special_flows >>>)-----------------------------
				--//////////////////////////////////////////////////////////////////////////////////////////////-
				---------------------------update spid----------2021/12/24----------------------------------------
				SELECT @special_id_now = [special_flow_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id

				IF (@special_id_now = @special_id)
				BEGIN
				
					select top (1) 
							@special_flow_id_update = lot_special_flows.special_flow_id
						--, @step_no = lot_special_flows.step_no
					from APCSProDB.trans.lots
					inner join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
					inner join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
					where lots.id = @lot_id
						and lot_special_flows.step_no >= lots.step_no
						and special_flows.wip_state = 20
						--and (lots.is_special_flow = 0 or lots.is_special_flow is null )
					order by lot_special_flows.step_no asc

					IF (ISNULL(@special_flow_id_update,0) != 0)
					BEGIN
						IF (@s_status = 1 AND @is_special = 1)
						BEGIN
							UPDATE [APCSProDB].[trans].[lots]
							SET [is_special_flow] = 0
								, [special_flow_id] = @special_flow_id_update
								, [quality_state] = 0
								, [step_no] = @s_stepno
								, [act_process_id] = @s_process
								, [act_job_id] = @s_job
							WHERE [id] = @lot_id;

						END
						ELSE
						BEGIN
							UPDATE [APCSProDB].[trans].[lots]
							SET [is_special_flow] = 0
								, [special_flow_id] = @special_flow_id_update
								, [quality_state] = 0
							WHERE [lots].[id] = @lot_id;
						END
					END
					ELSE
					BEGIN
						IF (@s_status = 1 AND @is_special = 1)
						BEGIN
							UPDATE [APCSProDB].[trans].[lots]
							SET [is_special_flow] = 0
								, [special_flow_id] = 0
								, [quality_state] = 0
								, [step_no] = @s_stepno
								, [act_process_id] = @s_process
								, [act_job_id] = @s_job
							WHERE [id] = @lot_id;

						END
						ELSE
						BEGIN
							UPDATE [APCSProDB].[trans].[lots]
							SET [is_special_flow] = 0
								, [special_flow_id] = 0
								, [quality_state] = 0
							WHERE [id] = @lot_id;
						END
										
					END				
				END	
				---------------------------update spid----------2021/12/24----------------------------------------

				SELECT 3 as status_id --OK 1 flow
				-------------------------(เข้าเงื่อนไขลบ)---------------------------------------

			END
			ELSE
			BEGIN
				SELECT 2 as status_id  --Processing 1 flow
			END
		END
		ELSE
		BEGIN
			SELECT 1 as status_id --Multi flow
		END
	END
	ELSE
	BEGIN

		IF (@counter = 1)
		BEGIN
			-------------------------(1)--------------------------
			IF(@run_status IS NULL or @run_status = 25 or @run_status = 4)
			BEGIN
				-------------------------(เข้าเงื่อนไขลบ 25=addflow 4=LotOpened)---------------------------------------
				SELECT @s_stepno = [device_flows].[step_no]
					, @s_process = [device_flows].[act_process_id]
					, @s_job = [device_flows].[job_id]
					, @is_special = [lots].[is_special_flow]
					, @s_status = CASE 
						WHEN 
						(
							SELECT step_no 
							FROM [APCSProDB].[trans].[lot_special_flows] 
							WHERE [lot_special_flows].[special_flow_id] = @special_id 
								AND [lot_special_flows].[id]  = @lot_special_id
						) BETWEEN [lots].[step_no] AND [device_flows].[step_no] THEN 1 --'TRUE'
						ELSE 0 --'FALSE' 
						END --AS [status_step_no]
				FROM (
					SELECT [lots].[special_flow_id]
						, [lots].[is_special_flow]
						, [lots].[device_slip_id]
						, [lots].[step_no]
					FROM [APCSProDB].[trans].[lots]
					WHERE [lots].[id] = @lot_id
				) AS [lots]
				INNER JOIN [APCSProDB].[method].[device_flows] ON [lots].[device_slip_id] = [device_flows].[device_slip_id]
					AND [device_flows].is_skipped != 1
				INNER JOIN [APCSProDB].[trans].[special_flows] ON [lots].[special_flow_id] = [special_flows].[id]
					AND [lots].[is_special_flow] = 1
				WHERE [device_flows].[step_no] = 
				(
					SELECT [device_flows].[next_step_no] 
					FROM [APCSProDB].[method].[device_flows] 
					WHERE [device_flows].[device_slip_id] = [lots].[device_slip_id]
						AND [device_flows].[step_no] = [lots].[step_no]
				);
				-----------------------------(<<< delete lot_process_records)-----------------------------
				DELETE from APCSProDB.trans.lot_process_records
				where lot_id = @lot_id 
					and special_flow_id = @special_id
					and step_no >= (
						SELECT step_no FROM [APCSProDB].[trans].[lot_special_flows] 
						WHERE [lot_special_flows].[special_flow_id] = @special_id 
						AND [lot_special_flows].[id]  = @lot_special_id
					)
				-----------------------------(delete lot_process_records >>>)-----------------------------
				--//////////////////////////////////////////////////////////////////////////////////////////////-
				-----------------------------(<<< delete lot_special_flows)-----------------------------
				DELETE FROM [APCSProDB].[trans].[lot_special_flows]
				WHERE [special_flow_id] = @special_id
				-----------------------------(delete lot_special_flows >>>)-----------------------------
				--//////////////////////////////////////////////////////////////////////////////////////////////-
				-----------------------------(<<< delete special_flows)-----------------------------
				DELETE FROM [APCSProDB].[trans].[special_flows]
				WHERE [id] = @special_id
				-----------------------------(delete special_flows >>>)-----------------------------
				--//////////////////////////////////////////////////////////////////////////////////////////////-
				---------------------------update spid----------2021/12/24----------------------------------------
				SELECT @special_id_now = [special_flow_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id

				IF (@special_id_now = @special_id)
				BEGIN
				
					select top (1) 
							@special_flow_id_update = lot_special_flows.special_flow_id
						--, @step_no = lot_special_flows.step_no
					from APCSProDB.trans.lots
					inner join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
					inner join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
					where lots.id = @lot_id
						and lot_special_flows.step_no >= lots.step_no
						and special_flows.wip_state = 20
						--and (lots.is_special_flow = 0 or lots.is_special_flow is null )
					order by lot_special_flows.step_no asc

					IF (ISNULL(@special_flow_id_update,0) != 0)
					BEGIN
						IF (@s_status = 1 AND @is_special = 1)
						BEGIN
							UPDATE [APCSProDB].[trans].[lots]
							SET [is_special_flow] = 0
								, [special_flow_id] = @special_flow_id_update
								, [quality_state] = 0
								, [step_no] = @s_stepno
								, [act_process_id] = @s_process
								, [act_job_id] = @s_job
							WHERE [id] = @lot_id;

						END
						ELSE
						BEGIN
							UPDATE [APCSProDB].[trans].[lots]
							SET [is_special_flow] = 0
								, [special_flow_id] = @special_flow_id_update
								, [quality_state] = 0
							WHERE [lots].[id] = @lot_id;
						END
					END
					ELSE
					BEGIN
						IF (@s_status = 1 AND @is_special = 1)
						BEGIN
							UPDATE [APCSProDB].[trans].[lots]
							SET [is_special_flow] = 0
								, [special_flow_id] = 0
								, [quality_state] = 0
								, [step_no] = @s_stepno
								, [act_process_id] = @s_process
								, [act_job_id] = @s_job
							WHERE [id] = @lot_id;

						END
						ELSE
						BEGIN
							UPDATE [APCSProDB].[trans].[lots]
							SET [is_special_flow] = 0
								, [special_flow_id] = 0
								, [quality_state] = 0
							WHERE [id] = @lot_id;
						END
										
					END				
				END	
			---------------------------update spid----------2021/12/24----------------------------------------

				SELECT 3 as status_id --OK 1 flow
				-------------------------(เข้าเงื่อนไขลบ 25=addflow 4=LotOpened)---------------------------------------
			END
			ELSE
			BEGIN
				SELECT 2 as status_id --Processing 1 flow
			END
			-------------------------(1)--------------------------
		END
		ELSE
		BEGIN
			-------------------------(2)--------------------------
			IF (@lot_special_id IS NOT NULL)
			BEGIN
				IF(@run_status IS NULL or @run_status = 25 or @run_status = 4)
				BEGIN

					DECLARE @special_flow_id_up INT = NULL;
					DECLARE @step_no_up INT = NULL;
					DECLARE @next_step_no_up INT = NULL;
					DECLARE @step_id_up INT = NULL;
					DECLARE @step_start INT = NULL;
					DECLARE @step_end INT = NULL;
					DECLARE @step_now INT = NULL;
					DECLARE @chkstep_no INT = NULL;

					--CHECK MIN STEP
					SELECT @step_start = min([lot_special_flows].[step_no]) FROM [APCSProDB].[trans].[lot_special_flows] WHERE [lot_special_flows].[special_flow_id] = @special_id;

					SELECT @special_flow_id_up = [special_flows].[id]
						,@step_no_up = [lot_special_flows].[step_no]
						,@next_step_no_up = [next_step_no]
						,@step_id_up = [lot_special_flows].[id]
						,@step_now = [special_flows].[step_no]
					FROM [APCSProDB].[trans].[special_flows]
					INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
					WHERE [lot_id] = @lot_id AND [special_flows].[id] = @special_id AND [lot_special_flows].[id]  = @lot_special_id;

					SET @chkstep_no = @step_no_up;

					--START check delete flow 
					IF (@step_no_up = @step_start)
					BEGIN
					
						SELECT @s_stepno = [device_flows].[step_no]
							, @s_process = [device_flows].[act_process_id]
							, @s_job = [device_flows].[job_id]
							, @is_special = [lots].[is_special_flow]
							, @s_status = CASE 
								WHEN 
								(
									SELECT step_no 
									FROM [APCSProDB].[trans].[lot_special_flows] 
									WHERE [lot_special_flows].[special_flow_id] = @special_id 
										AND [lot_special_flows].[id]  = @lot_special_id
								) BETWEEN [lots].[step_no] AND [device_flows].[step_no] THEN 1 --'TRUE'
								ELSE 0 --'FALSE' 
								END --AS [status_step_no]
						FROM (
							SELECT [lots].[special_flow_id]
								, [lots].[is_special_flow]
								, [lots].[device_slip_id]
								, [lots].[step_no]
							FROM [APCSProDB].[trans].[lots]
							WHERE [lots].[id] = @lot_id
						) AS [lots]
						INNER JOIN [APCSProDB].[method].[device_flows] ON [lots].[device_slip_id] = [device_flows].[device_slip_id]
							AND [device_flows].is_skipped != 1
						INNER JOIN [APCSProDB].[trans].[special_flows] ON [lots].[special_flow_id] = [special_flows].[id]
							AND [lots].[is_special_flow] = 1
						WHERE [device_flows].[step_no] = 
						(
							SELECT [device_flows].[next_step_no] 
							FROM [APCSProDB].[method].[device_flows] 
							WHERE [device_flows].[device_slip_id] = [lots].[device_slip_id]
								AND [device_flows].[step_no] = [lots].[step_no]
						);

						DELETE from APCSProDB.trans.lot_process_records
						where lot_id = @lot_id 
							and special_flow_id = @special_id
							and step_no >= (
								SELECT top 1 step_no FROM [APCSProDB].[trans].[lot_special_flows] 
								WHERE [lot_special_flows].[special_flow_id] = @special_id 
								AND [lot_special_flows].[id]  = @lot_special_id
							)

						DELETE FROM [APCSProDB].[trans].[lot_special_flows]
						WHERE [special_flow_id] = @special_id;
						DELETE FROM [APCSProDB].[trans].[special_flows]
						WHERE [id] = @special_id;

						---------------------------update spid----------2021/12/24----------------------------------------
						SELECT @special_id_now = [special_flow_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id

						IF (@special_id_now = @special_id)
						BEGIN
							select top (1) 
									@special_flow_id_update = lot_special_flows.special_flow_id
								--, @step_no = lot_special_flows.step_no
							from APCSProDB.trans.lots
							inner join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
							inner join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
							where lots.id = @lot_id
								and lot_special_flows.step_no >= lots.step_no
								and special_flows.wip_state = 20
								--and (lots.is_special_flow = 0 or lots.is_special_flow is null )
							order by lot_special_flows.step_no asc

							IF (ISNULL(@special_flow_id_update,0) != 0)
							BEGIN
								IF (@s_status = 1 AND @is_special = 1)
								BEGIN
									UPDATE [APCSProDB].[trans].[lots]
									SET [is_special_flow] = 0
										, [special_flow_id] = @special_flow_id_update
										, [quality_state] = 0
										, [step_no] = @s_stepno
										, [act_process_id] = @s_process
										, [act_job_id] = @s_job
									WHERE [id] = @lot_id;

								END
								ELSE
								BEGIN
									UPDATE [APCSProDB].[trans].[lots]
									SET [is_special_flow] = 0
										, [special_flow_id] = @special_flow_id_update
										, [quality_state] = 0
									WHERE [lots].[id] = @lot_id;
								END
							END
							ELSE
							BEGIN
								IF (@s_status = 1 AND @is_special = 1)
								BEGIN
									UPDATE [APCSProDB].[trans].[lots]
									SET [is_special_flow] = 0
										, [special_flow_id] = 0
										, [quality_state] = 0
										, [step_no] = @s_stepno
										, [act_process_id] = @s_process
										, [act_job_id] = @s_job
									WHERE [id] = @lot_id;

								END
								ELSE
								BEGIN
									UPDATE [APCSProDB].[trans].[lots]
									SET [is_special_flow] = 0
										, [special_flow_id] = 0
										, [quality_state] = 0
									WHERE [id] = @lot_id;
								END
										
							END				
						END	
						---------------------------update spid----------2021/12/24----------------------------------------
					END
					ELSE
					BEGIN

						DELETE from APCSProDB.trans.lot_process_records
						where lot_id = @lot_id 
							and special_flow_id = @special_id
							and step_no >= (
								SELECT top 1 step_no FROM [APCSProDB].[trans].[lot_special_flows] 
								WHERE [lot_special_flows].[special_flow_id] = @special_id 
								AND [lot_special_flows].[id]  = @lot_special_id
							);
												
						SELECT top 1 @special_flow_id_up = [special_flows].[id]
							,@step_no_up = [lot_special_flows].[step_no]
							,@next_step_no_up = [next_step_no]
							,@step_id_up = [lot_special_flows].[id]
						FROM [APCSProDB].[trans].[special_flows]
						INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [lot_id] = @lot_id AND [special_flows].[id] = @special_id AND [lot_special_flows].[step_no] = @step_no_up;
							
						DELETE FROM [APCSProDB].[trans].[lot_special_flows] 
						WHERE [special_flow_id] = @special_id AND [lot_special_flows].[step_no] >= @chkstep_no;

						SELECT top 1 @special_flow_id_up = [special_flows].[id]
							,@step_id_up = [lot_special_flows].[id]
							,@next_step_no_up = [lot_special_flows].[step_no]
						FROM [APCSProDB].[trans].[special_flows]
						INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
						WHERE [lot_id] = @lot_id AND [special_flows].[id] = @special_id AND [next_step_no] = @step_no_up;

						UPDATE [APCSProDB].[trans].[lot_special_flows]
						SET [next_step_no] = @next_step_no_up
						WHERE [id] = @step_id_up;

						IF (@step_now = @chkstep_no)
						BEGIN
							UPDATE [APCSProDB].[trans].[special_flows]
							SET [step_no] = @next_step_no_up
							WHERE [id] = @special_id;
						END
					END
					--END check delete flow 
				
					SELECT 3 as status_id --OK Multi flow

				END
				ELSE
				BEGIN
					SELECT 2 as status_id  --Processing Multi flow
				END
			END
			ELSE
			BEGIN
				SELECT 1 as status_id
			END
			-------------------------(2)--------------------------
		END

	END

END


	
--	DECLARE @counter int = 0
--	DECLARE @run_status varchar(50)
--	DECLARE @special_id_now int = 0
--	-- Insert statements for procedure here
--	select @counter = count([special_flows].[id])
--	from [APCSProDB].[trans].[lot_special_flows]
--	left join
--	(
--		select [LotDetail].[record_class]
--		, [LotDetail].[step_no]
--		, [LotDetail].[qty_in]
--		, [LotDetail].[qty_pass]
--		, [LotDetail].[qty_fail]
--		, [LotDetail].[qty_frame_in]
--		, [LotDetail].[qty_frame_pass]
--		, [LotDetail].[qty_frame_fail]
--		, [LotDetail].[machine_id]
--		, [LotDetail].[carrier_no]
--		, [LotDetail].[next_carrier_no]
--		, [LotDetail].[name]
--		, [LotDetail].[emp_num]
--		, [LotStart].[StartTime]
--		, case when ([LotStart].[StartTime] <= [LotEnd].[EndTime]) then cast([LotEnd].[EndTime] as datetime2) end as EndTime
--		from
--		(
--			select [step_no], [machine_id], MAX([id]) as max_id
--			from [APCSProDB].[trans].[lot_process_records]
--			where [lot_id] = @lot_id
--			group by [step_no], [machine_id]
--		) as StepFlow
--		inner join 
--		(
--			select [lot_process_records].[id]
--			, [lot_process_records].[record_class]
--			, [lot_process_records].[step_no]
--			, [lot_process_records].[qty_in]
--			, [lot_process_records].[qty_pass]
--			, [lot_process_records].[qty_fail]
--			, [lot_process_records].[qty_frame_in]
--			, [lot_process_records].[qty_frame_pass]
--			, [lot_process_records].[qty_frame_fail]
--			, [lot_process_records].[machine_id]
--			, [lot_process_records].[carrier_no]
--			, [lot_process_records].[next_carrier_no]
--			, [APCSProDB].[mc].[machines].[name]
--			, [APCSProDB].[man].[users].[emp_num]
--			from [APCSProDB].[trans].[lot_process_records]
--			left join [APCSProDB].[mc].[machines] on [lot_process_records].[machine_id] = [machines].[id]
--			left join [APCSProDB].[man].[users] on [lot_process_records].[updated_by] = [users].[id] 
--			where [lot_id] = @lot_id
--		) as LotDetail
--		on LotDetail.id = StepFlow.max_id
	
--		left join
--		(
--			select [step_no],[machine_id],MAX([recorded_at]) as StartTime
--			from [APCSProDB].[trans].[lot_process_records]
--			where [record_class] IN ('1','31') and [lot_id] = @lot_id
--			group by [step_no],[machine_id]
--		) as LotStart
--		on LotDetail.step_no = LotStart.step_no and LotDetail.machine_id = LotStart.machine_id
	
--		left join
--		(
--			select [step_no],[machine_id],MAX([recorded_at]) as EndTime
--			from [APCSProDB].[trans].[lot_process_records]
--			where [record_class] IN ('2','12','32') and [lot_id] = @lot_id
--			group by [step_no],[machine_id]
--		) as LotEnd
--		on LotDetail.step_no = LotEnd.step_no and LotDetail.machine_id = LotEnd.machine_id
--	) as LotFlow
--	on [lot_special_flows].[step_no] = [LotFlow].[step_no]
--	inner join [APCSProDB].[method].[jobs] on [lot_special_flows].[job_id] = [jobs].[id]
--	left join [APCSProDB].[trans].[item_labels] as [item_labels1] on [item_labels1].[name] = 'lot_process_records.record_class' and [item_labels1].[val] = [LotFlow].[record_class]
--	inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
--	where [special_flows].[lot_id] = @lot_id 
--	and [special_flows].[id] = @special_id


--	select 
--		--@run_status = [item_labels1].[label_eng]
--		@run_status = [item_labels1].[val]
--	from [APCSProDB].[trans].[lot_special_flows]
--	left join
--	(
--		select [LotDetail].[record_class]
--		, [LotDetail].[step_no]
--		, [LotDetail].[qty_in]
--		, [LotDetail].[qty_pass]
--		, [LotDetail].[qty_fail]
--		, [LotDetail].[qty_frame_in]
--		, [LotDetail].[qty_frame_pass]
--		, [LotDetail].[qty_frame_fail]
--		, [LotDetail].[machine_id]
--		, [LotDetail].[carrier_no]
--		, [LotDetail].[next_carrier_no]
--		, [LotDetail].[name]
--		, [LotDetail].[emp_num]
--		, [LotStart].[StartTime]
--		, case when ([LotStart].[StartTime] <= [LotEnd].[EndTime]) then cast([LotEnd].[EndTime] as datetime2) end as EndTime
--		from
--		(
--			select [step_no], [machine_id], MAX([id]) as max_id
--			from [APCSProDB].[trans].[lot_process_records]
--			where [lot_id] = @lot_id
--			group by [step_no], [machine_id]
--		) as StepFlow
--		inner join 
--		(
--			select [lot_process_records].[id]
--			, [lot_process_records].[record_class]
--			, [lot_process_records].[step_no]
--			, [lot_process_records].[qty_in]
--			, [lot_process_records].[qty_pass]
--			, [lot_process_records].[qty_fail]
--			, [lot_process_records].[qty_frame_in]
--			, [lot_process_records].[qty_frame_pass]
--			, [lot_process_records].[qty_frame_fail]
--			, [lot_process_records].[machine_id]
--			, [lot_process_records].[carrier_no]
--			, [lot_process_records].[next_carrier_no]
--			, [APCSProDB].[mc].[machines].[name]
--			, [APCSProDB].[man].[users].[emp_num]
--			from [APCSProDB].[trans].[lot_process_records]
--			left join [APCSProDB].[mc].[machines] on [lot_process_records].[machine_id] = [machines].[id]
--			left join [APCSProDB].[man].[users] on [lot_process_records].[updated_by] = [users].[id] 
--			where [lot_id] = @lot_id
--		) as LotDetail
--		on LotDetail.id = StepFlow.max_id
	
--		left join
--		(
--			select [step_no],[machine_id],MAX([recorded_at]) as StartTime
--			from [APCSProDB].[trans].[lot_process_records]
--			where [record_class] IN ('1','31') and [lot_id] = @lot_id
--			group by [step_no],[machine_id]
--		) as LotStart
--		on LotDetail.step_no = LotStart.step_no and LotDetail.machine_id = LotStart.machine_id
	
--		left join
--		(
--			select [step_no],[machine_id],MAX([recorded_at]) as EndTime
--			from [APCSProDB].[trans].[lot_process_records]
--			where [record_class] IN ('2','12','32') and [lot_id] = @lot_id
--			group by [step_no],[machine_id]
--		) as LotEnd
--		on LotDetail.step_no = LotEnd.step_no and LotDetail.machine_id = LotEnd.machine_id
--	) as LotFlow
--	on [lot_special_flows].[step_no] = [LotFlow].[step_no]
--	inner join [APCSProDB].[method].[jobs] on [lot_special_flows].[job_id] = [jobs].[id]
--	left join [APCSProDB].[trans].[item_labels] as [item_labels1] on [item_labels1].[name] = 'lot_process_records.record_class' and [item_labels1].[val] = [LotFlow].[record_class]
--	inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
--	where [special_flows].[lot_id] = @lot_id 
--	and [special_flows].[id] = @special_id
--	--where [device_flows].[device_slip_id] = (select device_slip_id from [APCSProDB].[trans].[lots] where [lots].[id] = @lot_id)

--	-- 1 sp add by flow_patten_id > 1
--	-- 2 sp has been processing
--	-- 3 delete success
--	--IF(@flowfon = 366)
--	--	BEGIN
--	--		IF(@counter != 0)
--	--		BEGIN
--	--			IF(@run_status IS NULL or @run_status = 25 or @run_status = 23 or @run_status = 6)
--	--			BEGIN
--	--				SELECT 3 as status_id
--	--				DELETE FROM [APCSProDB].[trans].[lot_special_flows]
--	--				WHERE special_flow_id = @special_id
--	--				DELETE FROM [APCSProDB].[trans].[special_flows]
--	--				WHERE id = @special_id

--	--				SELECT @special_id_now = special_flow_id FROM APCSProDB.trans.lots WHERE [lots].[id] = @lot_id
--	--				IF (@special_id_now = @special_id)
--	--				BEGIN
--	--					UPDATE [APCSProDB].[trans].[lots]
--	--					SET [is_special_flow] = 0
--	--					, [special_flow_id] = 0
--	--					, [quality_state] = 0
--	--					WHERE [id] = @lot_id

--	--				END

--	--			END
--	--			ELSE
--	--			BEGIN
--	--				SELECT 2 as status_id
--	--			END
--	--		END
--	--		ELSE
--	--		BEGIN
--	--			SELECT 1 as status_id
--	--		END
--	--	END
--	--ELSE
--	--	BEGIN
--			IF(@counter = 1)
--				-- Flow = 1 Flow
--				BEGIN
--					IF(@run_status IS NULL or @run_status = 25 or @run_status = 4)
--						BEGIN
							
--							DELETE from APCSProDB.trans.lot_process_records
--							where lot_id = @lot_id 
--								and special_flow_id = @special_id
--								and step_no >= (
--									SELECT step_no FROM [APCSProDB].[trans].[lot_special_flows] 
--									WHERE [lot_special_flows].[special_flow_id] = @special_id 
--									AND [lot_special_flows].[id]  = @lot_special_id
--								)

--							DELETE FROM [APCSProDB].[trans].[lot_special_flows]
--							WHERE [special_flow_id] = @special_id
--							DELETE FROM [APCSProDB].[trans].[special_flows]
--							WHERE [id] = @special_id

--							---------------------------update spid----------2021/12/24----------------------------------------
--							SELECT @special_id_now = [special_flow_id] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id
--							IF (@special_id_now = @special_id)
--							BEGIN
--								DECLARE @special_flow_id_update int = NULL
--								select top (1) 
--										@special_flow_id_update = lot_special_flows.special_flow_id
--									--, @step_no = lot_special_flows.step_no
--								from APCSProDB.trans.lots
--								inner join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
--								inner join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
--								where lots.id = @lot_id
--									and lot_special_flows.step_no >= lots.step_no
--									and special_flows.wip_state = 20
--									--and (lots.is_special_flow = 0 or lots.is_special_flow is null )
--								order by lot_special_flows.step_no asc

--								IF (ISNULL(@special_flow_id_update,0) != 0)
--									BEGIN
--										UPDATE [APCSProDB].[trans].[lots]
--										SET [is_special_flow] = 0
--											, [special_flow_id] = @special_flow_id_update
--											, [quality_state] = 0
--										WHERE [lots].[id] = @lot_id;
--									END
--								ELSE
--									BEGIN
--										UPDATE [APCSProDB].[trans].[lots]
--										SET [is_special_flow] = 0
--											, [special_flow_id] = 0
--											, [quality_state] = 0
--										WHERE [id] = @lot_id;
--									END
--							END	
--							---------------------------update spid----------2021/12/24----------------------------------------

--							SELECT 3 as status_id --OK 1 flow
--						END
--					ELSE
--						BEGIN
--							SELECT 2 as status_id --Processing 1 flow
--						END
--				END
--			ELSE
--				-- Flow > 1 Flow
--				BEGIN
--					IF (@lot_special_id IS NOT NULL)
--						BEGIN
--							IF(@run_status IS NULL or @run_status = 25 or @run_status = 4)
--								BEGIN

--									DECLARE @special_flow_id_up INT = NULL;
--									DECLARE @step_no_up INT = NULL;
--									DECLARE @next_step_no_up INT = NULL;
--									DECLARE @step_id_up INT = NULL;
--									DECLARE @step_start INT = NULL;
--									DECLARE @step_end INT = NULL;
--									DECLARE @step_now INT = NULL;
--									DECLARE @chkstep_no INT = NULL;

--									--CHECK MIN STEP
--									SELECT @step_start = min([lot_special_flows].[step_no]) FROM [APCSProDB].[trans].[lot_special_flows] WHERE [lot_special_flows].[special_flow_id] = @special_id

--									SELECT @special_flow_id_up = [special_flows].[id]
--										,@step_no_up = [lot_special_flows].[step_no]
--										,@next_step_no_up = [next_step_no]
--										,@step_id_up = [lot_special_flows].[id]
--										,@step_now = [special_flows].[step_no]
--									FROM [APCSProDB].[trans].[special_flows]
--									INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
--									WHERE [lot_id] = @lot_id AND [special_flows].[id] = @special_id AND [lot_special_flows].[id]  = @lot_special_id

--									--SELECT @step_start,@step_end,@step_no_up

--									SET @chkstep_no = @step_no_up;

--									--START check delete flow 
--									IF (@step_no_up = @step_start)
--										BEGIN
--											DELETE from APCSProDB.trans.lot_process_records
--											where lot_id = @lot_id 
--												and special_flow_id = @special_id
--												and step_no >= (
--													SELECT step_no FROM [APCSProDB].[trans].[lot_special_flows] 
--													WHERE [lot_special_flows].[special_flow_id] = @special_id 
--													AND [lot_special_flows].[id]  = @lot_special_id
--												)

--											DELETE FROM [APCSProDB].[trans].[lot_special_flows]
--											WHERE [special_flow_id] = @special_id;
--											DELETE FROM [APCSProDB].[trans].[special_flows]
--											WHERE [id] = @special_id;

--											UPDATE [APCSProDB].[trans].[lots]
--											SET [is_special_flow] = 0
--												, [special_flow_id] = 0
--												, [quality_state] = 0
--											WHERE [id] = @lot_id;
--										END
--									ELSE
--										BEGIN
--											DELETE from APCSProDB.trans.lot_process_records
--											where lot_id = @lot_id 
--												and special_flow_id = @special_id
--												and step_no >= (
--													SELECT step_no FROM [APCSProDB].[trans].[lot_special_flows] 
--													WHERE [lot_special_flows].[special_flow_id] = @special_id 
--													AND [lot_special_flows].[id]  = @lot_special_id
--												)

--											SELECT @special_flow_id_up = [special_flows].[id]
--												,@step_no_up = [lot_special_flows].[step_no]
--												,@next_step_no_up = [next_step_no]
--												,@step_id_up = [lot_special_flows].[id]
--											FROM [APCSProDB].[trans].[special_flows]
--											INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
--											WHERE [lot_id] = @lot_id AND [special_flows].[id] = @special_id AND [lot_special_flows].[step_no] = @step_no_up
							
--											DELETE FROM [APCSProDB].[trans].[lot_special_flows] 
--											WHERE [special_flow_id] = @special_id AND [lot_special_flows].[step_no] >= @chkstep_no

--											SELECT @special_flow_id_up = [special_flows].[id]
--												,@step_id_up = [lot_special_flows].[id]
--												,@next_step_no_up = [lot_special_flows].[step_no]
--											FROM [APCSProDB].[trans].[special_flows]
--											INNER JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
--											WHERE [lot_id] = @lot_id AND [special_flows].[id] = @special_id AND [next_step_no] = @step_no_up;

--											UPDATE [APCSProDB].[trans].[lot_special_flows]
--											SET [next_step_no] = @next_step_no_up
--											WHERE [id] = @step_id_up;

--											IF (@step_now = @chkstep_no)
--												BEGIN
--													UPDATE [APCSProDB].[trans].[special_flows]
--													SET [step_no] = @next_step_no_up
--													WHERE [id] = @special_id;
--												END

--											---------------------------update spid----------2021/12/24----------------------------------------
--											SELECT @special_id_now = count([id]) FROM [APCSProDB].[trans].[special_flows] WHERE [special_flows].[lot_id] = @lot_id and [special_flows].[id] = @special_id
--											IF (ISNULL(@special_id_now,0) = 0)
--												BEGIN
--													DECLARE @special_flow_id_update2 int = NULL
--													select top (1) 
--															@special_flow_id_update2 = lot_special_flows.special_flow_id
--														--, @step_no = lot_special_flows.step_no
--													from APCSProDB.trans.lots
--													inner join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
--													inner join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
--													where lots.id = @lot_id
--														and lot_special_flows.step_no >= lots.step_no
--														and special_flows.wip_state = 20
--														--and (lots.is_special_flow = 0 or lots.is_special_flow is null )
--													order by lot_special_flows.step_no asc

--													IF (ISNULL(@special_flow_id_update2,0) != 0)
--														BEGIN
--															UPDATE [APCSProDB].[trans].[lots]
--															SET [is_special_flow] = 0
--																, [special_flow_id] = @special_flow_id_update2
--																, [quality_state] = 0
--															WHERE [lots].[id] = @lot_id;
--														END
--													ELSE
--														BEGIN
--															UPDATE [APCSProDB].[trans].[lots]
--															SET [is_special_flow] = 0
--																, [special_flow_id] = 0
--																, [quality_state] = 0
--															WHERE [id] = @lot_id;
--														END
--												END	
--												---------------------------update spid----------2021/12/24----------------------------------------
--										END
--									--END check delete flow 
--									SELECT 3 as status_id --OK Multi flow

--								END
--							ELSE
--								BEGIN
--									SELECT 2 as status_id  --Processing Multi flow
--								END
--						END
--					ELSE
--						BEGIN
--							SELECT 1 as status_id
--						END
--				END
--END


