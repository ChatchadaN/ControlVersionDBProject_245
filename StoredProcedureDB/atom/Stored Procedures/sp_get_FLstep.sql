-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_FLstep]
	-- Add the parameters for the stored procedure here
	@lot_id int = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

    -- Insert statements for procedure here
	--declare @step_no_now int
	--declare @step_no_FL int
	--declare @checkprocess varchar(20) = NULL

	---- Check step no FL in flow
	--select top 1 @step_no_FL = [device_flows].[step_no]
	--from [APCSProDB].[method].[device_flows]
	--inner join [APCSProDB].[method].[processes] on [device_flows].act_process_id = [processes].[id]
	--inner join [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
	--where [device_flows].[device_slip_id] = (select device_slip_id from [APCSProDB].[trans].[lots] where [lots].[id] = @lot_id)
	--	AND [jobs].[id] in (11,23,87,88,90,92,93,278,347,350,365,394,41)
	--order by step_no
	
	---- Check step no current
	--select @step_no_now = (case when APCSProDB.trans.lots.is_special_flow = 1 then 
	--		(select step_no FROM [APCSProDB].[trans].[special_flows] where id = APCSProDB.trans.lots.special_flow_id) 
	--	   else APCSProDB.trans.lots.step_no 
	-- end ) 
	--from APCSProDB.trans.lots
	--where id = @lot_id

	---- Check process current
	--select top 1 @checkprocess = case when [lots].[is_special_flow] = 1 then [processes2].[name] ELSE [processes].[name] end  --as process
	--from [APCSProDB].[trans].[lots] with (NOLOCK) 
	--inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	--inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
	--inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
	--inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
	--inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
	--inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [lots].[device_slip_id] 
	--	and [device_flows].[step_no] = [lots].[step_no]
	--inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
	--inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
	--left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
	--left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and  [special_flows].step_no = [lot_special_flows].step_no
	--left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
	--left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
	--where [lots].[id] =  @lot_id

	---- Display data
	--select lot_no
	--	--, qty_pass --Good
	--	, (case 
	--			when @step_no_FL > @step_no_now then qty_pass
	--			when @step_no_FL = @step_no_now then qty_pass
	--			when @step_no_FL < @step_no_now then (qty_pass + qty_p_nashi + qty_front_ng) ---qty_pass_step_sum
	--			when @step_no_FL IS NULL then qty_pass
	--			else qty_pass end 
	--		) as [qty_pass]  --Good
	--	, (case 
	--			when @step_no_FL > @step_no_now then qty_frame_pass
	--			when @step_no_FL = @step_no_now then 0
	--			when @step_no_FL < @step_no_now then 0
	--			when @step_no_FL IS NULL then qty_frame_pass
	--			else 0 end 
	--		) as [qty_frame_pass] --Frame Good
	--	--, ISNULL(qty_frame_pass * packages.pcs_per_work, 0) as [GoPiece]
	--	, IIF(ISNULL(qty_frame_pass * packages.pcs_per_work, 0) = 0, [lots].[qty_in], ISNULL(qty_frame_pass * packages.pcs_per_work, 0)) as [GoPiece]
	--	, (CASE 
	--			WHEN ISNULL(qty_frame_pass, 0) <> 0 
	--			THEN ISNULL((qty_frame_pass * packages.pcs_per_work)/qty_frame_pass,0) 
	--			ELSE 0 END
	--		) as [PiecePerFrame]
	--	, (case 
	--			when @step_no_FL > @step_no_now then 'before FL'
	--			when @step_no_FL = @step_no_now then 'FL'
	--			when @step_no_FL < @step_no_now then 'after FL'
	--			when @step_no_FL IS NULL then 'before FL'
	--			else 'after FL'
	--		end ) as [status]
	--	, ([lots].qty_p_nashi + [lots].qty_front_ng) as [os_scrap]
	--	, ([lots].qty_marker) as [marker_scrap]
	--	--,packages.pcs_per_work
	--	, @checkprocess as [process_now]
	--from [APCSProDB].[trans].[lots]
	--inner join [APCSProDB].[method].[packages] on [lots].act_package_id = packages.id
	--where lots.id = @lot_id

	-------------------------------------------------------------------------------------------------
	declare @step_no_now int
	declare @step_no_FL int
	declare @checkprocess varchar(20) = NULL

	-- Check step no FL in flow
	select top 1 @step_no_FL = [device_flows].[step_no]
	from [APCSProDB].[method].[device_flows]
	inner join [APCSProDB].[method].[processes] on [device_flows].act_process_id = [processes].[id]
	inner join [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
	where [device_flows].[device_slip_id] = (select device_slip_id from [APCSProDB].[trans].[lots] where [lots].[id] = @lot_id)
		AND [jobs].[id] in (11,23,87,88,90,92,93,278,347,350,365,394,41)
	order by step_no
	
	-- Check step no current
	select @step_no_now = (case when APCSProDB.trans.lots.is_special_flow = 1 then 
			(select step_no FROM [APCSProDB].[trans].[special_flows] where id = APCSProDB.trans.lots.special_flow_id) 
		   else APCSProDB.trans.lots.step_no 
	 end ) 
	from APCSProDB.trans.lots
	where id = @lot_id

	-- Check process current
	select top 1 @checkprocess = case when [lots].[is_special_flow] = 1 then [processes2].[name] ELSE [processes].[name] end  --as process
	from [APCSProDB].[trans].[lots] with (NOLOCK) 
	inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
	inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
	inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
	inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
	inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
	inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [lots].[device_slip_id] 
		and [device_flows].[step_no] = [lots].[step_no]
	inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
	inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]
	left join [APCSProDB].[trans].[special_flows] with (NOLOCK) on [special_flows].[id] = [lots].[special_flow_id] 
	left join [APCSProDB].[trans].[lot_special_flows] with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] and  [special_flows].step_no = [lot_special_flows].step_no
	left join [APCSProDB].[method].[jobs] as [job2] with (NOLOCK) on [job2].[id] = [lot_special_flows].[job_id]
	left join [APCSProDB].[method].[processes] as [processes2] with (NOLOCK) on [processes2].[id] = [job2].[process_id]
	where [lots].[id] =  @lot_id

	-- Display data
	select lot_no
		--, (ISNULL(qty_pass,0) + ISNULL(qty_p_nashi,0) + ISNULL(qty_front_ng,0)) as [qty_pass]  --Good
		, IIF([lots].[is_special_flow] = 1
			, (ISNULL([special_flows].[qty_pass], 0) + ISNULL([special_flows].[qty_p_nashi], 0) + ISNULL([special_flows].[qty_front_ng], 0))
			, (ISNULL([lots].[qty_pass], 0) + ISNULL([lots].[qty_p_nashi], 0) + ISNULL([lots].[qty_front_ng], 0)) 
		) as [qty_pass]  --Good add new 2024/03/26
		, (case 
				when @step_no_FL IS NULL then 0
				else 
					case 
						when @step_no_FL > @step_no_now then ISNULL([lots].qty_frame_pass,0)
						when @step_no_FL <= @step_no_now then 0
						else 0
					end
			end ) as [qty_frame_pass] --Frame Good
		, IIF(ISNULL([lots].qty_frame_pass * packages.pcs_per_work, 0) = 0, [lots].[qty_in], ISNULL([lots].qty_frame_pass * packages.pcs_per_work, 0)) as [GoPiece]
		, (CASE 
				WHEN ISNULL([lots].qty_frame_pass, 0) <> 0 
				THEN ISNULL(([lots].qty_frame_pass * packages.pcs_per_work)/[lots].qty_frame_pass,0) 
				ELSE 0 END
			) as [PiecePerFrame]
		, (case 
				when @step_no_FL IS NULL then 'after FL'
				else 
					case 
						when @step_no_FL > @step_no_now then 'before FL'
						when @step_no_FL <= @step_no_now then 
							case
								when @step_no_FL = @step_no_now then 'FL'
								else 'after FL'
							end
						else 'after FL' 
					end
			end ) as [status]
		, ([lots].qty_p_nashi + [lots].qty_front_ng) as [os_scrap]
		, ([lots].qty_marker) as [marker_scrap]
		, @checkprocess as [process_now]
	from [APCSProDB].[trans].[lots]
	inner join [APCSProDB].[method].[packages] on [lots].act_package_id = packages.id
	left join [APCSProDB].[trans].[special_flows] on [lots].[id] = [special_flows].[lot_id] -- add new 2024/03/26
		and [lots].[special_flow_id] = [special_flows].[id] -- add new 2024/03/26
		and [lots].[is_special_flow] = 1 -- add new 2024/03/26
	where lots.id = @lot_id
	-------------------------------------------------------------------------------------------------
END
