-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_wip_state_memberlot_v2]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	--INSERT LOG EXEC
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
		, 'EXEC [trans].[sp_set_wip_state_memberlot] @lot_no = ''' + @lot_no + ''''
		, @lot_no

	--- start update wip_state lot master
	declare @wip_state int = null
	declare @wip_state_old int = (select wip_state from [APCSProDB].[trans].[lots] where lot_no = @lot_no)

	if not exists( 
		select lot_id,max(created_at) from APCSProDB.trans.lot_combine
		where member_lot_id = (select id from [APCSProDB].[trans].[lots] where lot_no = @lot_no)
		group by lot_id
	) 
		begin
			set @wip_state = 70 
		end
	else
		begin
			set @wip_state = ( select case --start
						when [lot_combine].[wip_state] = 100 or [lot_combine].[wip_state] = 70 then 100
						else 70
					end as [update_wip_state_lot_value]
				from [APCSProDB].[trans].[lots]
				inner join (
					select [lot_com].[lot_id]
					, [lot_mas].[lot_no] as [lot_no]
					, [lot_mas].[wip_state] as [wip_state]
					, [lot_com].[member_lot_id]
					, [lot_mem].[lot_no] as [member_lot_no]
					, [lot_mem].[wip_state] as [member_wip_state]
					from [APCSProDB].[trans].[lot_combine] as [lot_com]
					inner join [APCSProDB].[trans].[lots] as [lot_mas] on [lot_com].[lot_id] = [lot_mas].[id]
					inner join [APCSProDB].[trans].[lots] as [lot_mem] on [lot_com].[member_lot_id] = [lot_mem].[id]
				) as [lot_combine] on [lots].[id] = [lot_combine].[member_lot_id]
				inner join (	
					select lot_id
					from (
						select lot_id,
								 row_number() over(partition by member_lot_id order by created_at desc) as rn
						  from APCSProDB.trans.lot_combine
						  where member_lot_id = (select id from [APCSProDB].[trans].[lots] where lot_no = @lot_no)
					) as T
					where rn = 1
				) as [lot_combine_count] on [lot_combine].[lot_id] = [lot_combine_count].[lot_id]
				where [lot_combine].[member_lot_no] = @lot_no 
			) --end
		end
	
	BEGIN TRY 
		----select @wip_state as [update_wip_state_lot_value]
		update [APCSProDB].[trans].[lots]
			set wip_state = @wip_state
		where lot_no = @lot_no
		----- end update wip_state lot master

		declare @wip_state_new int = (select wip_state from [APCSProDB].[trans].[lots] where lot_no = @lot_no)

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
			, 'EXEC [trans].[sp_set_wip_state_memberlot] @lot_no = ''' + @lot_no + ''' wip_state ' + CAST(@wip_state_old as varchar) + ' --> ' + CAST(@wip_state_new as varchar)
			, @lot_no

		----- start update wip_state lot member  -----
		update [APCSProDB].[trans].[lots]
			set wip_state = [lot_combine].[update_wip]
		from [APCSProDB].[trans].[lots]
		inner join (
			select [lot_com].[lot_id]
				, [lot_mas].[lot_no] as [lot_no]
				, [lot_com].[member_lot_id]
				, [lot_mem].[lot_no] as [member_lot_no]
				, [lot_mem].[wip_state] as [wip_state_lot]
				, case 
					when [lot_mem].[process_state] = 0 and [lot_mem].[quality_state] = 0 then
						case 
							when [lot_mem].[wip_state] = 70 or [lot_mem].[wip_state] = 100 then 100
							else [lot_mem].[wip_state]
						end
					else [lot_mem].[wip_state]
				end as [update_wip]
			from [APCSProDB].[trans].[lot_combine] as [lot_com]
			inner join [APCSProDB].[trans].[lots] as [lot_mas] on [lot_com].[lot_id] = [lot_mas].[id]
			inner join [APCSProDB].[trans].[lots] as [lot_mem] on [lot_com].[member_lot_id] = [lot_mem].[id]
			inner join [APCSProDB].[trans].[surpluses] as [surplus] on [lot_mem].[id] = [surplus].[lot_id]
		) as [lot_combine] on [lots].[id] = [lot_combine].[member_lot_id]
		where [lot_combine].[lot_no] = @lot_no
		--- end update wip_state lot member

		SELECT 'TRUE' AS Is_Pass , '' AS Error_Message_ENG, N'' AS Error_Message_THA, N'' AS Handling
		--RETURN --- 07/03/2022 15.42
	END TRY
	BEGIN CATCH 
		SELECT 'FALSE' AS Is_Pass , 'Update wip error. !!' AS Error_Message_ENG, N'บันทึกข้อมูล wip state ผิดพลาด !!' AS Error_Message_THA, N'กรุณาติดต่อ system' AS Handling
		RETURN
	END CATCH

	--- start update in_stock lot member
	--update [APCSProDB].[trans].[surpluses]
	--	set in_stock = [lot_combine].[update_instock]
	--from [APCSProDB].[trans].[surpluses] as sur
	--inner join (
	--	select [lot_com].[lot_id] 
	--		, [lot_mas].[lot_no] as [lot_no]
	--		, [lot_com].[member_lot_id]
	--		, [lot_mem].[lot_no] as [member_lot_no]
	--		,case when lot_mem.process_state = 0 and lot_mem.quality_state = 0 --ถ้าไม่ hold
	--			  then 
	--				case when lot_com.lot_id = lot_com.member_lot_id 
	--					 then 
	--						case when (select COUNT(member_lot_id) from APCSProDB.trans.lot_combine where member_lot_id = lot_com.member_lot_id) = 1 then 2
	--							 else 0 end
	--				else 0 end
	--		else surplus.in_stock end as update_instock
	--	from [APCSProDB].[trans].[lot_combine] as [lot_com]
	--	inner join [APCSProDB].[trans].[lots] as [lot_mas] on [lot_com].[lot_id] = [lot_mas].[id]
	--	inner join [APCSProDB].[trans].[lots] as [lot_mem] on [lot_com].[member_lot_id] = [lot_mem].[id]
	--	inner join [APCSProDB].[trans].[surpluses] as [surplus] on [lot_mem].[id] = [surplus].[lot_id]
	--) as [lot_combine] on sur.lot_id = [lot_combine].[member_lot_id]
	--where [lot_combine].[lot_no] = @lot_no
	--- end update in_stock lot member






	------------------ver 1
	--- 19/11/2021 11.39
	--INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--	([record_at]
	--	  , [record_class]
	--	  , [login_name]
	--	  , [hostname]
	--	  , [appname]
	--	  , [command_text]
	--	  , [lot_no])
	--SELECT GETDATE()
	--	, '4'
	--	, ORIGINAL_LOGIN()
	--	, HOST_NAME()
	--	, APP_NAME()
	--	--, @lot_no + ' RUN WITH EXEC [trans].[sp_set_wip_state_memberlot] wip_start' + (select cast(wip_state as varchar) from [APCSProDB].[trans].[lots] where lot_no = @lot_no)
	--	, 'EXEC [trans].[sp_set_wip_state_memberlot] @lot_no = ''' + @lot_no + ''' wip_state = ' + (select cast(wip_state as varchar) from [APCSProDB].[trans].[lots] where lot_no = @lot_no) + ' master start'
	--	, @lot_no

	----- start update wip_state lot master
	--declare @wip_state int = null

	
	--if not exists( 
	--	select lot_id,max(created_at) from APCSProDB.trans.lot_combine
	--	where member_lot_id = (select id from [APCSProDB].[trans].[lots] where lot_no = @lot_no)
	--	group by lot_id
	--) 
	--	begin
	--		set @wip_state = 70 
	--	end
	--else
	--	begin
	--		set @wip_state = ( select case --start
	--					when [lot_combine].[wip_state] = 100 or [lot_combine].[wip_state] = 70 then 100
	--					else 70
	--				end as [update_wip_state_lot_value]
	--			from [APCSProDB].[trans].[lots]
	--			inner join (
	--				select [lot_com].[lot_id]
	--				, [lot_mas].[lot_no] as [lot_no]
	--				, [lot_mas].[wip_state] as [wip_state]
	--				, [lot_com].[member_lot_id]
	--				, [lot_mem].[lot_no] as [member_lot_no]
	--				, [lot_mem].[wip_state] as [member_wip_state]
	--				from [APCSProDB].[trans].[lot_combine] as [lot_com]
	--				inner join [APCSProDB].[trans].[lots] as [lot_mas] on [lot_com].[lot_id] = [lot_mas].[id]
	--				inner join [APCSProDB].[trans].[lots] as [lot_mem] on [lot_com].[member_lot_id] = [lot_mem].[id]
	--			) as [lot_combine] on [lots].[id] = [lot_combine].[member_lot_id]
	--			inner join (	
	--				select lot_id
	--				from (
	--					select lot_id,
	--							 row_number() over(partition by member_lot_id order by created_at desc) as rn
	--					  from APCSProDB.trans.lot_combine
	--					  where member_lot_id = (select id from [APCSProDB].[trans].[lots] where lot_no = @lot_no)
	--				) as T
	--				where rn = 1
	--			) as [lot_combine_count] on [lot_combine].[lot_id] = [lot_combine_count].[lot_id]
	--			where [lot_combine].[member_lot_no] = @lot_no 
	--		) --end
	--	end
	
	--BEGIN TRY 
	--	----select @wip_state as [update_wip_state_lot_value]
	--	update [APCSProDB].[trans].[lots]
	--		set wip_state = @wip_state
	--	where lot_no = @lot_no
	--	----- end update wip_state lot master

	--	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--		([record_at]
	--		  , [record_class]
	--		  , [login_name]
	--		  , [hostname]
	--		  , [appname]
	--		  , [command_text]
	--		  , [lot_no])
	--	SELECT GETDATE()
	--		, '4'
	--		, ORIGINAL_LOGIN()
	--		, HOST_NAME()
	--		, APP_NAME()
	--		, 'EXEC [trans].[sp_set_wip_state_memberlot] @lot_no = ''' + @lot_no + ''' wip_state = ' + (select cast(wip_state as varchar) from [APCSProDB].[trans].[lots] where lot_no = @lot_no) + ' master end'
	--		, @lot_no


	--	SELECT 'TRUE' AS Status ,'Update wip Lot master Success !!' AS Error_Message_ENG,N'Update Wip State Lot เรียบร้อย !!' AS Error_Message_THA 
	--	--RETURN --- 07/03/2022 15.42
	--END TRY
	--BEGIN CATCH 
	--	SELECT 'FALSE' AS Status ,'Update wip Lot master error !!' AS Error_Message_ENG,N'Update ข้อมูล wip state ผิดพลาด !!' AS Error_Message_THA 
	--	RETURN
	--END CATCH


	--INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--	([record_at]
	--	  , [record_class]
	--	  , [login_name]
	--	  , [hostname]
	--	  , [appname]
	--	  , [command_text]
	--	  , [lot_no])
	--SELECT GETDATE()
	--	, '4'
	--	, ORIGINAL_LOGIN()
	--	, HOST_NAME()
	--	, APP_NAME()
	--	, 'EXEC [trans].[sp_set_wip_state_memberlot] @lot_no = ' + @lot_no + ' member start'
	--	, @lot_no


	--BEGIN TRY 
	--	----- start update wip_state lot member  -----
	--	update [APCSProDB].[trans].[lots]
	--		set wip_state = [lot_combine].[update_wip]
	--	from [APCSProDB].[trans].[lots]
	--	inner join (
	--		select [lot_com].[lot_id]
	--			, [lot_mas].[lot_no] as [lot_no]
	--			, [lot_com].[member_lot_id]
	--			, [lot_mem].[lot_no] as [member_lot_no]
	--			, [lot_mem].[wip_state] as [wip_state_lot]
	--			, case 
	--				when [lot_mem].[process_state] = 0 and [lot_mem].[quality_state] = 0 then
	--					case 
	--						when [lot_mem].[wip_state] = 70 or [lot_mem].[wip_state] = 100 then 100
	--						else [lot_mem].[wip_state]
	--					end
	--				else [lot_mem].[wip_state]
	--			end as [update_wip]
	--		from [APCSProDB].[trans].[lot_combine] as [lot_com]
	--		inner join [APCSProDB].[trans].[lots] as [lot_mas] on [lot_com].[lot_id] = [lot_mas].[id]
	--		inner join [APCSProDB].[trans].[lots] as [lot_mem] on [lot_com].[member_lot_id] = [lot_mem].[id]
	--		inner join [APCSProDB].[trans].[surpluses] as [surplus] on [lot_mem].[id] = [surplus].[lot_id]
	--	) as [lot_combine] on [lots].[id] = [lot_combine].[member_lot_id]
	--	where [lot_combine].[lot_no] = @lot_no
	--	--- end update wip_state lot member

	--	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--		([record_at]
	--		  , [record_class]
	--		  , [login_name]
	--		  , [hostname]
	--		  , [appname]
	--		  , [command_text]
	--		  , [lot_no])
	--	SELECT GETDATE()
	--		, '4'
	--		, ORIGINAL_LOGIN()
	--		, HOST_NAME()
	--		, APP_NAME()
	--		, 'EXEC [trans].[sp_set_wip_state_memberlot] @lot_no = ' + @lot_no + ' member end'
	--		, @lot_no

	--	SELECT 'TRUE' AS Status ,'Update wip Lot Member Success !!' AS Error_Message_ENG,N'Update Wip State Lot member เรียบร้อย !!' AS Error_Message_THA 
	--	--RETURN --- 07/03/2022 15.42
	--END TRY
	--BEGIN CATCH 
	--	SELECT 'FALSE' AS Status ,'Update wip Lot Member error !!' AS Error_Message_ENG,N'Update ข้อมูล wip state member ผิดพลาด !!' AS Error_Message_THA 
	--	RETURN
	--END CATCH
END
