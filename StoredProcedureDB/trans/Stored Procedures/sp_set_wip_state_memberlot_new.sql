-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_wip_state_memberlot_new]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	
	--- 19/11/2021 11.39
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

		
END

--Change Column Is_Pass to Status 2022/10/28 Time : 15.31