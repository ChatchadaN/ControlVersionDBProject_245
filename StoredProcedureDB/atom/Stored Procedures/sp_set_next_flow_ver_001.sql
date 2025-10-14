-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create 20211016,,>
-- Description:	<Description,,Release Lot>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_next_flow_ver_001]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRY 
		IF EXISTS (select id from APCSProDB.trans.lots where lot_no = @lot_no)
			BEGIN
				----------------------------------------1--------------------------------------------------
				DECLARE @lot_id int = (select id from APCSProDB.trans.lots where lot_no = @lot_no)
				--DECLARE @lot_id int = 2
				DECLARE @special_flow_id_update int = NULL
				DECLARE @is_sp_flow int = 0
				DECLARE @step_no int = NULL
				DECLARE @step_flow int = NULL
				DECLARE @step_flow_master int = NULL
				DECLARE @table table (
					special_flow_id int,
					step_no int,
					back_step_no int
				)

				if not exists (select [package_groups].[id]
					from [APCSProDB].[trans].[lots] 
					inner join [APCSProDB].[method].[device_names] on [lots].[act_device_name_id] = [device_names].[id]
					inner join [APCSProDB].[method].[packages] on [device_names].[package_id] = [packages].[id]
					inner join [APCSProDB].[method].[package_groups] on [packages].[package_group_id] = [package_groups].[id]
					where [package_groups].[id] = 35
						and [lots].[id] = @lot_id)
				begin
					-- set data ukebarai
					EXEC [StoredProcedureDB].[trans].[sp_set_ukebarai_data] @lot_id = @lot_id;
				end

				select @step_no = ISNULL(lot_special_flows.step_no,lots.step_no) --as [step_no]
					, @is_sp_flow = lots.is_special_flow
					, @step_flow_master = lots.step_no
				from APCSProDB.trans.lots 
				left join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id 
					and lots.special_flow_id = special_flows.id
					and lots.is_special_flow = 1
				left join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
					and special_flows.step_no = lot_special_flows.step_no
				where lots.id = @lot_id

				--select @is_sp_flow as is_special_flow

				IF (@is_sp_flow = 0)
					BEGIN
						-----------------------------------------------------------------------------------------------------------
						--SELECT top 1 @special_flow_id_update = [special_flow_id]
						--	, @step_flow = [step_no]
						INSERT INTO @table (		
							special_flow_id,
							step_no,
							back_step_no
						)
						SELECT [special_flow_id]
							, [step_no]
							, [back_step_no]
						FROM
						(
							SELECT [table].[step_no]
								, [table].[back_step_no]
								, ISNULL([special_flows].special_flow_id,0) as [special_flow_id]
								, [special_flows].[wip_state]
							FROM (
								SELECT t3.step_no
									, t3.back_step_no
									, ISNULL([device_flows].next_step_no,max([device_flows].next_step_no) over (order by t3.back_step_no)) as [next_step_no]
								FROM (
									SELECT [step_no]
										, [back_step_no]
										, [lot_id]
									FROM (
											SELECT lag([step_no]) over (order by [step_no]) as [step_no]
												, [step_no] as [back_step_no]
												, @lot_id as [lot_id]
											FROM (
												SELECT [device_flows].[step_no]
												FROM [APCSProDB].[method].[device_flows]
												INNER JOIN [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
												WHERE [device_flows].[device_slip_id] = (SELECT device_slip_id FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)	
													AND [device_flows].[is_skipped] = 0
												UNION ALL
												SELECT [lot_special_flows].[step_no]
												FROM [APCSProDB].[trans].[special_flows]
												LEFT JOIN [APCSProDB].[trans].[lot_special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
												WHERE [special_flows].[lot_id] = @lot_id
											) as t1
											UNION ALL
											SELECT max([step_no]) as [step_no]
												, max([step_no]) as [back_step_no]
												, @lot_id as [lot_id]
											FROM (
												SELECT [device_flows].[step_no]
												FROM [APCSProDB].[method].[device_flows]
												INNER JOIN [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
												WHERE [device_flows].[device_slip_id] = (SELECT device_slip_id FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)	
													AND [device_flows].[is_skipped] = 0
												UNION ALL
												SELECT [lot_special_flows].[step_no]
												FROM [APCSProDB].[trans].[special_flows]
												LEFT JOIN [APCSProDB].[trans].[lot_special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
												WHERE [special_flows].[lot_id] = @lot_id
											) as t2
									) as [tsum]
									WHERE [tsum].[step_no] is not null
								) as t3
								left join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = (SELECT device_slip_id FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id)
									AND [device_flows].step_no = t3.step_no
							) as [table]
							left join (
										select lot_special_flows.special_flow_id
											,lot_special_flows.id as lot_special_flows_id
											,lot_special_flows.step_no
											,special_flows.wip_state
										from APCSProDB.trans.lots
										inner join APCSProDB.trans.special_flows on lots.id = special_flows.lot_id
										inner join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
										where lots.id = @lot_id
							) as [special_flows] on [table].step_no = [special_flows].[step_no]
						) as [table]
						WHERE 
							--[table].step_no > @step_no
							--([table].step_no >= @step_no
							--or [table].back_step_no >= @step_no)
							--and 
							[table].[wip_state] = 20
							and [table].[special_flow_id] != 0
						order by [table].[step_no]
						
						DECLARE @id int = NULL

						IF EXISTS (SELECT * from @table where back_step_no = @step_flow_master)
							BEGIN
								SET @id  = (SELECT top 1 special_flow_id from @table where back_step_no = @step_flow_master)
								update [APCSProDB].[trans].[lots]
									set is_special_flow = 1,
										--quality_state = 4,
										special_flow_id = @id
								where id = @lot_id

								--------------------------------------------------------------
								INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
								(	
									[record_at]
									, [record_class]
									, [login_name]
									, [hostname]
									, [appname]
									, [command_text]
									, [lot_no]
								)
								SELECT GETDATE()
									, '4'
									, ORIGINAL_LOGIN()
									, HOST_NAME()
									, APP_NAME()
									, 'EXEC [atom].[sp_set_next_flow] update special flow is now(1) special_flow_id=' + IIF(CAST(IIF(@id is null,-1,@id) as varchar(20)) = -1,'NULL',CAST(IIF(@id is null,-1,@id) as varchar(20)))
									, @lot_no
								--------------------------------------------------------------

								SELECT 'TRUE' AS Status ,'Update special flow now Success !!' AS Error_Message_ENG,N'Update special flow now เรียบร้อย !!' AS Error_Message_THA

							END
						ELSE
							BEGIN
								SET @id  = (SELECT top 1 special_flow_id from @table where step_no >= @step_no order by step_no)
								update [APCSProDB].[trans].[lots]
									set is_special_flow = 0,
										special_flow_id = @id
								where id = @lot_id
								
								--------------------------------------------------------------
								INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
								(	
									[record_at]
									, [record_class]
									, [login_name]
									, [hostname]
									, [appname]
									, [command_text]
									, [lot_no]
								)
								SELECT GETDATE()
									, '4'
									, ORIGINAL_LOGIN()
									, HOST_NAME()
									, APP_NAME()
									, 'EXEC [atom].[sp_set_next_flow] update special flow is after(0) special_flow_id=' + IIF(CAST(IIF(@id is null,-1,@id) as varchar(20)) = -1,'NULL',CAST(IIF(@id is null,-1,@id) as varchar(20)))
									, @lot_no
								--------------------------------------------------------------

								SELECT 'TRUE' AS Status ,'Update special flow after Success !!' AS Error_Message_ENG,N'Update special flow after เรียบร้อย !!' AS Error_Message_THA
							END	
						----------------------------------------------------------------------------------------
					END
				ELSE
					BEGIN
						--------------------------------------------------------------
						INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
						(	
							[record_at]
							, [record_class]
							, [login_name]
							, [hostname]
							, [appname]
							, [command_text]
							, [lot_no]
						)
						SELECT GETDATE()
							, '4'
							, ORIGINAL_LOGIN()
							, HOST_NAME()
							, APP_NAME()
							, 'EXEC [atom].[sp_set_next_flow] not update special flow (1)'
							, @lot_no
						--------------------------------------------------------------
						SELECT 'TRUE' AS Status ,'Not update special flow !!' AS Error_Message_ENG,N'ไม่ update special flow !!' AS Error_Message_THA
					END
				----------------------------------------1--------------------------------------------------
			END
	END TRY
	BEGIN CATCH 
		--------------------------------------------------------------
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		(	
			[record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [command_text]
			, [lot_no]
		)
		SELECT GETDATE()
			, '4'
			, ORIGINAL_LOGIN()
			, HOST_NAME()
			, APP_NAME()
			, 'EXEC [atom].[sp_set_next_flow] error update'
			, @lot_no
		--------------------------------------------------------------
		SELECT 'FALSE' AS Status ,'Update special flow error !!' AS Error_Message_ENG,N'Update ข้อมูล special flow ผิดพลาด !!' AS Error_Message_THA 
		RETURN
	END CATCH

END
