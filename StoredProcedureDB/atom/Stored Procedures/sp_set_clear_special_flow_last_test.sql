-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_clear_special_flow_last_test]
	-- Add the parameters for the stored procedure here
	@lot_id int
	, @step_no int
	--, @flowfon int = 0
	, @appname varchar(30) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--<<--------------------------------------------------------------------------
	--- ** log exec
	-->>-------------------------------------------------------------------------
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
		, 'EXEC [atom].[sp_set_clear_special_flow_last_test] @lot_id = ''' + ISNULL(CAST(@lot_id AS varchar),'') 
			+ ''', @step_no = ''' + ISNULL(CAST(@step_no AS varchar),'') 
			+ ''',@appname = ''' + ISNULL(CAST(@appname AS varchar),'')  + ''''
		, (select cast(lot_no as varchar) from [APCSProDB].[trans].[lots] where id = @lot_id);

	INSERT INTO [StoredProcedureDB].[dbo].[exec_spdb_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [storedprocedname]
		, [lot_no]
		, [command_text] )
	SELECT GETDATE() --AS [record_at]
		, 4 AS [record_class]
		, ORIGINAL_LOGIN() --AS [login_name]
		, HOST_NAME() --AS [hostname]
		, APP_NAME() --AS [appname]
		, N'[StoredProcedureDB].[atom].[sp_set_clear_special_flow_last_test]' --AS [storedprocedname]
		, ( SELECT CAST( [lot_no] AS VARCHAR ) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id ) --AS [lot_no]
		, '@lot_id = ' + ISNULL( CAST( @lot_id AS VARCHAR ), 'NULL' ) 
			+ ' ,@step_no = ' + ISNULL( CAST( @step_no AS VARCHAR ), 'NULL' ) 
			+ ' ,@appname = ''' + ISNULL( CAST( @appname AS VARCHAR ), '' ) + ''''; --AS [command_text]
	-----------------------------------------------------------------------------------------------
	--(1) check step no <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<--
	--<<--------------------------------------------------------------------------
	--- ** find step no 
	-->>-------------------------------------------------------------------------
	----------<<< เช็ค step_no ว่าเป็น 0:ไม่เจอ step_no  1:master  2:special
	DECLARE @status_step_no int = 0
	SET @status_step_no = ISNULL
	((select 1 from APCSProDB.method.device_flows 
			where device_slip_id = (select device_slip_id from APCSProDB.trans.lots where lots.id = @lot_id ) and step_no = @step_no and is_skipped != 1
		) ---หา step_no จาก master
		,(
			ISNULL((select 2 from APCSProDB.trans.special_flows left join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
					where special_flows.lot_id = @lot_id and lot_special_flows.step_no = @step_no),0)
		) ---หา step_no จาก special
	)
	---------->>> เช็ค step_no ว่าเป็น  0:ไม่เจอ step_no  1:master  2:special
	--<<--------------------------------------------------------------------------
	--- ** check step no delete or not delete
	-->>-------------------------------------------------------------------------
	----------<<< เช็ค step_no แอดได้ 0:ลบไม่ได้ 1:ลบได้
	DECLARE @status_add_flow int = 0
	SET @status_add_flow = IIF((select IIF(lot_special_flows.step_no is null,lots.step_no,lot_special_flows.step_no) --as [step_no]
		from APCSProDB.trans.lots
		left join APCSProDB.trans.special_flows on lots.is_special_flow = 1
			and lots.special_flow_id = special_flows.id
		left join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
			and special_flows.step_no = lot_special_flows.step_no
		where lots.id = @lot_id) <= @step_no,1,0)
	---------->>> เช็ค step_no แอดได้ 0:ลบไม่ได้ 1:ลบได้
	--(1) check step no <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<--
	-----------------------------------------------------------------------------------------------
	--(2) condition <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<--
	----------<<< เข้าสู่เงื่อนไขเช็คการลบ
	IF (@status_step_no = 2 and @status_add_flow = 1)
	BEGIN

		DECLARE @special_id int = NULL
		DECLARE @ck_special_id int = NULL
		DECLARE @lot_special_id int = NULL
		DECLARE @Count_delete int = 0
		DECLARE @run_status int = NULL
		DECLARE @max_step_no int = NULL
		DECLARE @special_flow_id_update  int = NULL
		DECLARE @s_stepno int = NULL
		DECLARE @s_process int = NULL
		DECLARE @s_job int = NULL

		select @special_id = special_flows.id
			, @lot_special_id = lot_special_flows.id
		from APCSProDB.trans.lots
		left join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
		left join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
		where lots.id = @lot_id
			and lot_special_flows.step_no = @step_no

		select @ck_special_id = special_flows.id
		from APCSProDB.trans.lots
		left join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
			and lots.special_flow_id = special_flows.id
			and lots.is_special_flow = 1
		left join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
			and special_flows.step_no = lot_special_flows.step_no
		where lots.id = @lot_id

		-----------------------------------------------------------------------------------------------
		IF (@special_id = @ck_special_id)
		BEGIN
			-----------------------------------------------------------
			select @run_status = [table].[record_class]
				--, [table].[special_flow_id]
				--, [table].[lot_special_flow_id]
				--, [table].[step_no]
				--, [table].[next_step_no]
			from (
				select [lot_special_flows].[step_no]
					, [lot_special_flows].[next_step_no]
					, [lot_process_records].[recorded_at]
					, [lot_process_records].[record_class]
					, [item_labels].[label_eng]
					, [item_labels].[val]
					, [special_flows].[id] as [special_flow_id]
					, [lot_special_flows].[id] as [lot_special_flow_id]
					, RANK () OVER ( 
						PARTITION BY [lot_process_records].[step_no]
						ORDER BY [lot_process_records].[recorded_at] DESC
					) [rowmax]
				from [APCSProDB].[trans].[lot_special_flows]
				left join [APCSProDB].[trans].[special_flows] on [lot_special_flows].[special_flow_id] = [special_flows].[id]
				left join [APCSProDB].[trans].[lot_process_records] on [special_flows].[lot_id] = [lot_process_records].[lot_id]
					and [lot_special_flows].[step_no] = [lot_process_records].[step_no]
				left join [APCSProDB].[trans].[item_labels] on [item_labels].[name] = 'lot_process_records.record_class' 
					and [item_labels].[val] = [lot_process_records].[record_class] 
				where [special_flows].[lot_id] = @lot_id
			) as [table]
			WHERE [table].[rowmax] = 1
				and [special_flow_id] = @special_id
				and [lot_special_flow_id] = @lot_special_id
			order by [table].[step_no]
			-----------------------------------------------------------

			------------------------@run_status------------------------
			IF (@run_status IS NULL or @run_status = 25 or @run_status = 4)
			BEGIN
				-------------------------------------------------
				select @Count_delete = count(lot_special_flows.special_flow_id) from APCSProDB.trans.lot_special_flows where lot_special_flows.special_flow_id = @special_id

				------------<<< delete step_no ที่ส่งมา
				IF (@Count_delete = 1)
				BEGIN
					--------------------------------------------------------------
					print('flow 1 flow');
					--update [APCSProDB].[trans].[lots]
					--set [lots].[qty_p_nashi] = [special_flows].[qty_p_nashi]
					--	, [lots].[qty_pass] = [special_flows].[qty_pass]
					--	, [lots].[qty_fail] = [special_flows].[qty_fail]
					--	, [lots].[qty_front_ng] = [special_flows].[qty_front_ng]
					--	, [lots].[qty_marker] = [special_flows].[qty_marker]
					--	, [lots].[qty_combined] = [special_flows].[qty_combined]
					--	, [lots].[qty_hasuu] = [special_flows].[qty_hasuu]
					--	, [lots].[qty_out] = [special_flows].[qty_out]
					--	, [lots].[qty_frame_pass] = [special_flows].[qty_frame_pass]
					--	, [lots].[qty_frame_fail] = [special_flows].[qty_frame_fail]
					--from [APCSProDB].[trans].[lots]
					--inner join [APCSProDB].[trans].[special_flows] on [special_flows].[lot_id] = [lots].[id]
					--	and [lots].[is_special_flow] = 1
					--	and [special_flows].[id] = [lots].[special_flow_id]
					--where [lots].[id] = @lot_id;

					------------<<< delete lot_special_flows
					delete from APCSProDB.trans.lot_special_flows 
					where lot_special_flows.special_flow_id = @special_id;
					------------>>> delete lot_special_flows
			
					------------<<< delete special_flows
					delete from APCSProDB.trans.special_flows 
					where special_flows.id = @special_id;
					------------>>> delete special_flows
					--------------------------------------------------------------

					----------<<< update flow sp after
					select top (1) @special_flow_id_update = lot_special_flows.special_flow_id
					from APCSProDB.trans.lots
					inner join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
					inner join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
					where lots.id = @lot_id
						and lot_special_flows.step_no >= lots.step_no
						and special_flows.wip_state = 20
					order by lot_special_flows.step_no asc

					IF (@step_no > (SELECT [lots].[step_no] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id))
					BEGIN
						---------------------------------------------
						SELECT @s_stepno = [device_flows].[step_no]
							, @s_process = [device_flows].[act_process_id]
							, @s_job = [device_flows].[job_id]
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
						WHERE [device_flows].[step_no] = ( 
							SELECT [device_flows].[next_step_no]
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
							WHERE [device_flows].[step_no] = [lots].[step_no]
						)
						---------------------------------------------
					END
					ELSE BEGIN
						---------------------------------------------
						SELECT @s_stepno = [device_flows].[step_no]
							, @s_process = [device_flows].[act_process_id]
							, @s_job = [device_flows].[job_id]
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
						WHERE [device_flows].[step_no] = [lots].[step_no]
						---------------------------------------------
					END

					UPDATE [APCSProDB].[trans].[lots]
					SET [is_special_flow] = 0
						, [special_flow_id] = @special_flow_id_update
						, [quality_state] = 0
						, [step_no] = @s_stepno
						, [act_process_id] = @s_process
						, [act_job_id] = @s_job
					WHERE [id] = @lot_id;
					
					---------->>> update flow sp after
					SELECT 3 as status_id --OK
						, 'TRUE' AS Is_Pass 
						, '' AS Error_Message_ENG
						, '' AS Error_Message_THA 
						, '' AS Handling
				END
				ELSE BEGIN
					--------------------------------------------------------------
					SET @max_step_no = (select max(step_no) from [APCSProDB].[trans].[lot_special_flows] WHERE [special_flow_id] = @special_id)
					----------<<< delete step_no ที่ส่งมา
					delete from APCSProDB.trans.lot_special_flows 
					where lot_special_flows.special_flow_id = @special_id
						and lot_special_flows.id = @lot_special_id;
					----------<<< delete step_no ที่ส่งมา

					update APCSProDB.trans.lot_special_flows
					set step_no = step_no - 1
						, next_step_no = next_step_no - 1
					where lot_special_flows.special_flow_id = @special_id
						and lot_special_flows.step_no > @step_no;

					IF (@step_no = @max_step_no)
					BEGIN
						update APCSProDB.trans.lot_special_flows
						set next_step_no = step_no
						where lot_special_flows.special_flow_id = @special_id
							and lot_special_flows.step_no =  (select max(step_no) from [APCSProDB].[trans].[lot_special_flows] WHERE [special_flow_id] = @special_id);

						IF (@step_no = (select step_no from [APCSProDB].[trans].[special_flows] where id = @special_id))
						BEGIN
							-----------
							----------<<< จบ special_flows
							update APCSProDB.trans.special_flows
								set step_no = (select max(step_no) from [APCSProDB].[trans].[lot_special_flows] WHERE [special_flow_id] = @special_id)
								, exec_state = 1
								, wip_state = 100
							where id = @special_id
							---------->>> จบ special_flows

							print('flow 2 to .. flow');
							update [APCSProDB].[trans].[lots]
							set [lots].[qty_p_nashi] = [special_flows].[qty_p_nashi]
								, [lots].[qty_pass] = [special_flows].[qty_pass]
								, [lots].[qty_fail] = [special_flows].[qty_fail]
								, [lots].[qty_front_ng] = [special_flows].[qty_front_ng]
								, [lots].[qty_marker] = [special_flows].[qty_marker]
								, [lots].[qty_combined] = [special_flows].[qty_combined]
								, [lots].[qty_hasuu] = [special_flows].[qty_hasuu]
								, [lots].[qty_out] = [special_flows].[qty_out]
								, [lots].[qty_frame_pass] = [special_flows].[qty_frame_pass]
								, [lots].[qty_frame_fail] = [special_flows].[qty_frame_fail]
							from [APCSProDB].[trans].[lots]
							inner join [APCSProDB].[trans].[special_flows] on [special_flows].[lot_id] = [lots].[id]
								and [lots].[is_special_flow] = 1
								and [special_flows].[id] = [lots].[special_flow_id]
							where [lots].[id] = @lot_id;

							----------<<< update flow sp after
							select top (1) @special_flow_id_update = lot_special_flows.special_flow_id
							from APCSProDB.trans.lots
							inner join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
							inner join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
							where lots.id = @lot_id
								and lot_special_flows.step_no >= lots.step_no
								and special_flows.wip_state = 20
							order by lot_special_flows.step_no asc

							IF (@step_no > (SELECT [lots].[step_no] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id))
							BEGIN
								---------------------------------------------
								SELECT @s_stepno = [device_flows].[step_no]
									, @s_process = [device_flows].[act_process_id]
									, @s_job = [device_flows].[job_id]
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
								WHERE [device_flows].[step_no] = ( 
									SELECT [device_flows].[next_step_no]
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
									WHERE [device_flows].[step_no] = [lots].[step_no]
								)
								---------------------------------------------
							END
							ELSE BEGIN
								---------------------------------------------
								SELECT @s_stepno = [device_flows].[step_no]
									, @s_process = [device_flows].[act_process_id]
									, @s_job = [device_flows].[job_id]
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
								WHERE [device_flows].[step_no] = [lots].[step_no]
								---------------------------------------------
							END

							UPDATE [APCSProDB].[trans].[lots]
							SET [is_special_flow] = 0
								, [special_flow_id] = @special_flow_id_update
								, [quality_state] = 0
								, [step_no] = @s_stepno
								, [act_process_id] = @s_process
								, [act_job_id] = @s_job
							WHERE [id] = @lot_id;
							---------->>> update flow sp after
							----------
						END
					END
					--------------------------------------------------------------
					SELECT 3 as status_id --OK
						, 'TRUE' AS Is_Pass 
						, '' AS Error_Message_ENG
						, '' AS Error_Message_THA 
						, '' AS Handling
				END
				---------->>> delete step_no ที่ส่งมา

				--------------------------------------------------
			END
			ELSE IF(@run_status = 23 or @run_status = 6) BEGIN
				----------<<< ข้ามการลบ
				IF ((select count(lot_special_flows.id) from APCSProDB.trans.lot_special_flows where special_flow_id = @special_id) > 1)
				BEGIN
					----------------------------------------------------
					----------<<< เปลี่ยน step_no
					update APCSProDB.trans.special_flows
					set step_no = (
						select top 1 next_step_no
						from APCSProDB.trans.lot_special_flows 
						where special_flow_id = @special_id
							and step_no = @step_no
					)
					where id = @special_id
					---------->>> เปลี่ยน step_no
					----------------------------------------------------
				END
				ELSE IF ((select count(lot_special_flows.id) from APCSProDB.trans.lot_special_flows where special_flow_id = @special_id) = 1)  BEGIN
					---------------------------------------------------------
					----------<<< จบ special_flows
					update APCSProDB.trans.special_flows
					set exec_state = 1
						, wip_state = 100
					where id = @special_id
					---------->>> จบ special_flows

					print('flow abnormal end flow');
					update [APCSProDB].[trans].[lots]
					set [lots].[qty_p_nashi] = [special_flows].[qty_p_nashi]
						, [lots].[qty_pass] = [special_flows].[qty_pass]
						, [lots].[qty_fail] = [special_flows].[qty_fail]
						, [lots].[qty_front_ng] = [special_flows].[qty_front_ng]
						, [lots].[qty_marker] = [special_flows].[qty_marker]
						, [lots].[qty_combined] = [special_flows].[qty_combined]
						, [lots].[qty_hasuu] = [special_flows].[qty_hasuu]
						, [lots].[qty_out] = [special_flows].[qty_out]
						, [lots].[qty_frame_pass] = [special_flows].[qty_frame_pass]
						, [lots].[qty_frame_fail] = [special_flows].[qty_frame_fail]
					from [APCSProDB].[trans].[lots]
					inner join [APCSProDB].[trans].[special_flows] on [special_flows].[lot_id] = [lots].[id]
						and [lots].[is_special_flow] = 1
						and [special_flows].[id] = [lots].[special_flow_id]
					where [lots].[id] = @lot_id;

					----------<<< update flow sp after
					select top (1) @special_flow_id_update = lot_special_flows.special_flow_id
					from APCSProDB.trans.lots
					inner join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
					inner join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
					where lots.id = @lot_id
						and lot_special_flows.step_no >= lots.step_no
						and special_flows.wip_state = 20
					order by lot_special_flows.step_no asc

					IF (@step_no > (SELECT [lots].[step_no] FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id))
					BEGIN
						---------------------------------------------
						SELECT @s_stepno = [device_flows].[step_no]
							, @s_process = [device_flows].[act_process_id]
							, @s_job = [device_flows].[job_id]
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
						WHERE [device_flows].[step_no] = ( 
							SELECT [device_flows].[next_step_no]
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
							WHERE [device_flows].[step_no] = [lots].[step_no]
						)
						---------------------------------------------
					END
					ELSE BEGIN
						---------------------------------------------
						SELECT @s_stepno = [device_flows].[step_no]
							, @s_process = [device_flows].[act_process_id]
							, @s_job = [device_flows].[job_id]
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
						WHERE [device_flows].[step_no] = [lots].[step_no]
						---------------------------------------------
					END

					UPDATE [APCSProDB].[trans].[lots]
					SET [is_special_flow] = 0
						, [special_flow_id] = @special_flow_id_update
						, [quality_state] = 0
						, [step_no] = @s_stepno
						, [act_process_id] = @s_process
						, [act_job_id] = @s_job
					WHERE [id] = @lot_id;
					
					---------->>> update flow sp after
					---------------------------------------------------------
				END
				---------->>> ข้ามการลบ
				SELECT 3 as status_id --OK
					, 'TRUE' AS Is_Pass 
					, '' AS Error_Message_ENG
					, '' AS Error_Message_THA 
					, '' AS Handling
			END
			ELSE BEGIN
				SELECT 2 as status_id  --Processing
					, 'FALSE' AS Is_Pass 
					, 'Plase check process_state. !!' AS Error_Message_ENG
					, N'กรุณาตรวจสอบ process_state' AS Error_Message_THA 
					, '' AS Handling
			END
			------------------------@run_status------------------------
		END
		ELSE BEGIN

			select @Count_delete = count(lot_special_flows.special_flow_id) from APCSProDB.trans.lot_special_flows where lot_special_flows.special_flow_id = @special_id
			
			------------<<< delete step_no ที่ส่งมา
			IF (@Count_delete = 1)
			BEGIN
				--------------------------------------------------------------
				------------<<< delete lot_special_flows
				delete from APCSProDB.trans.lot_special_flows 
				where lot_special_flows.special_flow_id = @special_id
				------------>>> delete lot_special_flows
			
				------------<<< delete special_flows
				delete from APCSProDB.trans.special_flows 
				where special_flows.id = @special_id
				------------>>> delete special_flows
				--------------------------------------------------------------
			END
			ELSE BEGIN
				--------------------------------------------------------------
				SET @max_step_no = (select max(step_no) from [APCSProDB].[trans].[lot_special_flows] WHERE [special_flow_id] = @special_id)
				----------<<< delete step_no ที่ส่งมา
				delete from APCSProDB.trans.lot_special_flows 
				where lot_special_flows.special_flow_id = @special_id
					and lot_special_flows.id = @lot_special_id;
				----------<<< delete step_no ที่ส่งมา

				update APCSProDB.trans.lot_special_flows
				set step_no = step_no - 1
					, next_step_no = next_step_no - 1
				where lot_special_flows.special_flow_id = @special_id
					and lot_special_flows.step_no > @step_no;

				IF (@step_no = @max_step_no)
				BEGIN
					update APCSProDB.trans.lot_special_flows
					set next_step_no = step_no
					where lot_special_flows.special_flow_id = @special_id
						and lot_special_flows.step_no =  (select max(step_no) from [APCSProDB].[trans].[lot_special_flows] WHERE [special_flow_id] = @special_id);
				END
				--------------------------------------------------------------
			END
			---------->>> delete step_no ที่ส่งมา

			----------<<< update flow sp after
			select top (1) @special_flow_id_update = lot_special_flows.special_flow_id
			from APCSProDB.trans.lots
			inner join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
			inner join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
			where lots.id = @lot_id
				and lot_special_flows.step_no >= lots.step_no
				and special_flows.wip_state = 20
			order by lot_special_flows.step_no asc

			IF((select is_special_flow from APCSProDB.trans.lots where id = @lot_id) = 0)
			BEGIN
				UPDATE [APCSProDB].[trans].[lots]
				SET [is_special_flow] = 0
					, [special_flow_id] = @special_flow_id_update
					, [quality_state] = 0
				WHERE [lots].[id] = @lot_id;
			END
			---------->>> update flow sp after
			SELECT 3 as status_id --OK
				, 'TRUE' AS Is_Pass 
				, '' AS Error_Message_ENG
				, '' AS Error_Message_THA 
				, '' AS Handling
		END
		-----------------------------------------------------------------------------------------------
	END
	ELSE BEGIN
		SELECT 2 as status_id --ลบไม่ได้
			, 'FALSE' AS Is_Pass 
			, 'Cannot cancel flow. !!' AS Error_Message_ENG
			, N'ไม่สามารถยกเลิก flow ได้ !!' AS Error_Message_THA 
			, '' AS Handling
	END
	---------->>> เข้าสู่เงื่อนไขเช็คการลบ
	--(2) condition <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<--
	-----------------------------------------------------------------------------------------------
END
