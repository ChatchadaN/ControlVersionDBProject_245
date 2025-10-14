

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_filter]
	-- Add the parameters for the stored procedure here
	  @lot_type			varchar(1)  = '%'
	, @package_group	varchar(20) = '%'
	, @package			varchar(20) = '%'
	, @device			varchar(20) = '%'
	, @process			varchar(50) = '%'
	, @job				varchar(50) = '%'
	, @assyname			varchar(50) = '%'
	, @wafer			varchar(50) = '%'
	, @lotno			varchar(50) = '%'
	, @version			varchar(50) = '%'  
	, @deviceType		varchar(50) = '%'  
	, @filter			int = 1 
						-- 1: Package Group, 2: Package, 3: Device, 4: Process, 5: Lot Type , 6: Job, 7: Status,
						-- 8: Process State, 9: Quality State, 10:wafer, 11:assyname,  12: version,  s 13:device_type
						-- 14:app_name
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

    -- Insert statements for procedure here
	IF(@filter = 1)
	BEGIN
		select TRIM([package_groups].[name]) as [filter_name]
		from [APCSProDB].[trans].[lots]						with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups]	with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		group by TRIM([package_groups].[name])
		order by TRIM([package_groups].[name])

		--select distinct TRIM([package_groups].[name]) as [filter_name]
		--from [APCSProDB].[trans].[lots]						with (NOLOCK)
		--inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		--inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		--inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		--inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		--inner join [APCSProDB].[method].[package_groups]	with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		--inner join [APCSProDB].[method].[device_flows]		with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		--inner join [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		--inner join [APCSProDB].[method].[processes]			with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		----where [package_groups].[name] like @package_group
		----and [packages].[name] like @package
		----and [device_names].[name] like @device
		----and [processes].[name] like @process
		----and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		----and [jobs].[name] like @job
		--order by TRIM([package_groups].[name])
	END
	ELSE IF(@filter = 2)
	BEGIN
		---- close
		--select distinct [packages].[name] as [filter_name]
		--from [APCSProDB].[trans].[lots]						with (NOLOCK)
		--inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		--inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		--inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		--inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		--inner join [APCSProDB].[method].[package_groups]	with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		--inner join [APCSProDB].[method].[device_flows]		with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		--inner join [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		--inner join [APCSProDB].[method].[processes]			with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		--where [packages].[name] like @package
		--and [device_names].[name] like @device
		--and [lots].lot_no like @lotno
		--and [device_names].assy_name like @assyname
		----and [processes].[name] like @process
		----and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		----and [jobs].[name] like @job
		----and [package_groups].[name] like @package_group
		--order by [packages].[name]

		select [packages].[name] as [filter_name]
		from [APCSProDB].[trans].[lots]						with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		where [lots].[lot_no] like @lotno
		and [packages].[name] like @package
		and [device_names].[name] like @device
		and [device_names].[assy_name] like @assyname
		--and [lots].[wip_state] in (0,10,20)
		group by [packages].[name]
		order by [packages].[name]
	END
	ELSE IF(@filter = 3)
	BEGIN
		---- close
		--select distinct [device_names].[name] as [filter_name]
		--from [APCSProDB].[trans].[lots]						with (NOLOCK)
		--inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		--inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		--inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		--inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		--inner join [APCSProDB].[method].[package_groups]	with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		--inner join [APCSProDB].[method].[device_flows]		with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		--inner join [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		--inner join [APCSProDB].[method].[processes]			with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		--where [device_names].[name] like @device
		--and [packages].[name] like @package
		--and [device_names].assy_name like @assyname
		--and [lots].lot_no like @lotno
		----and [processes].[name] like @process
		----and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		----and [jobs].[name] like @job
		----and [package_groups].[name] like @package_group
		--order by [device_names].[name]

		select [device_names].[name] as [filter_name]
		from [APCSProDB].[trans].[lots]						with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		where [device_names].[name] like @device
		and [packages].[name] like @package
		and [device_names].[assy_name] like @assyname
		and [lots].[lot_no] like @lotno
		--and [lots].[wip_state] in (0,10,20)
		group by [device_names].[name]
		order by [device_names].[name]
	END
	ELSE IF(@filter = 4)
	BEGIN
		--select distinct [processes].[name] as [filter_name]
		--from [APCSProDB].[trans].[lots]						with (NOLOCK)
		--inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		--inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		--inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		--inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		--inner join [APCSProDB].[method].[package_groups]	with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		--inner join [APCSProDB].[method].[device_flows]		with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		--inner join [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		--inner join [APCSProDB].[method].[processes]			with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		----where [package_groups].[name] like @package_group
		----and [packages].[name] like @package
		----and [device_names].[name] like @device
		----and [processes].[name] like @process
		----and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		----and [jobs].[name] like @job
		--order by [processes].[name] 

		SELECT [processes].[name] AS [filter_name]
		FROM [APCSProDB].[trans].[lots]						WITH (NOLOCK)
		INNER JOIN [APCSProDB].[method].[device_slips]		WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions]	WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names]		WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages]			WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups]	WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
		INNER JOIN [APCSProDB].[method].[device_flows]		WITH (NOLOCK) ON [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[jobs]				WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
		INNER JOIN [APCSProDB].[method].[processes]			WITH (NOLOCK) ON [processes].[id] = [jobs].[process_id]
		GROUP BY [processes].[name]
		ORDER BY [processes].[name] 
	END
	ELSE IF(@filter = 5)
	BEGIN
		--select distinct SUBSTRING([lots].[lot_no],5,1) as [filter_name]
		--from [APCSProDB].[trans].[lots]						with (NOLOCK)
		--inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		--inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		--inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		--inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		--inner join [APCSProDB].[method].[package_groups]	with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		--inner join [APCSProDB].[method].[device_flows]		with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		--inner join [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		--inner join [APCSProDB].[method].[processes]			with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		----where [package_groups].[name] like @package_group
		----and [packages].[name] like @package
		----and [device_names].[name] like @device
		----and [processes].[name] like @process
		----and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		----and [jobs].[name] like @job
		--order by SUBSTRING([lots].[lot_no],5,1)

		SELECT SUBSTRING([lots].[lot_no],5,1) AS [filter_name]
		FROM [APCSProDB].[trans].[lots]						WITH (NOLOCK) 
		INNER JOIN [APCSProDB].[method].[packages]			WITH (NOLOCK) ON [lots].[act_package_id] = [packages].[id]
		WHERE  [packages].[package_group_id] <> 35 -- <> LAPIS
		GROUP BY SUBSTRING([lots].[lot_no],5,1)
		ORDER BY SUBSTRING([lots].[lot_no],5,1)
	END
	ELSE IF(@filter = 6)
	BEGIN
		select [filter_name]
		from (	select [jobs].[name] as [filter_name]
				from [APCSProDB].[trans].[lots]						with (NOLOCK)
				inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
				inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
				inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
				inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
				inner join [APCSProDB].[method].[package_groups]	with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
				inner join [APCSProDB].[method].[device_flows]		with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
				inner join [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
				where [device_flows].[is_skipped] = 0
					and [jobs].[is_skipped] = 0
				group by [jobs].[name]
				union all
				select [jobs].[name] as [filter_name]
				from [APCSProDB].[trans].[special_flows]			with (NOLOCK) 
				inner join [APCSProDB].[trans].[lot_special_flows]	with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] 
				inner join [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id] = [lot_special_flows].[job_id]
				group by [jobs].[name]
		) as table_jobs
		where [filter_name] is not null
		group by [filter_name]
		order by [filter_name]
		--select distinct [filter_name]
		--from (	select distinct [jobs].[name] as [filter_name]
		--		from [APCSProDB].[trans].[lots]						with (NOLOCK)
		--		INNER JOIN [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		--		INNER JOIN [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		--		INNER JOIN [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		--		INNER JOIN [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		--		INNER JOIN [APCSProDB].[method].[package_groups]	with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		--		INNER JOIN [APCSProDB].[method].[device_flows]		with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		--		INNER JOIN [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		--		INNER JOIN [APCSProDB].[method].[processes]			with (NOLOCK) on [processes].[id] = [jobs].[process_id]

		--		union

		--		select distinct [jobs].[name] as [filter_name]
		--		FROM [APCSProDB].[trans].[special_flows]			with (NOLOCK) 
		--		LEFT JOIN [APCSProDB].[trans].[lot_special_flows]	with (NOLOCK) on [lot_special_flows].[special_flow_id] = [special_flows].[id] 
		--		LEFT JOIN [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id] = [lot_special_flows].[job_id]
		--		LEFT JOIN [APCSProDB].[method].[processes]			with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		--) as table_jobs
		--where [filter_name] is not null
		--order by [filter_name]

		--select distinct [jobs].[name] as [filter_name]
		--from [APCSProDB].[trans].[lots] with (NOLOCK)
		--inner join [APCSProDB].[method].[device_slips] with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		--inner join [APCSProDB].[method].[device_versions] with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		--inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		--inner join [APCSProDB].[method].[packages] with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		--inner join [APCSProDB].[method].[package_groups] with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		--inner join [APCSProDB].[method].[device_flows] with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		--inner join [APCSProDB].[method].[jobs] with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		--inner join [APCSProDB].[method].[processes] with (NOLOCK) on [processes].[id] = [jobs].[process_id]



		--where [package_groups].[name] like @package_group
		--and [packages].[name] like @package
		--and [device_names].[name] like @device
		--and [processes].[name] like @process
		--and SUBSTRING([lots].[lot_no],5,1) like @lot_type
		--and [jobs].[name] like @job
		--order by [jobs].[name]
	END
	ELSE IF(@filter = 7)
	BEGIN
		select 'NORMAL' as [filter_name]
		union all
		select 'DELAY' as [filter_name]
		union all
		select 'ORDER DELAY' as [filter_name]
	END
	ELSE IF(@filter = 8)
	BEGIN
		SELECT [label_eng] as [filter_name]
		FROM [APCSProDB].[trans].[item_labels] with (NOLOCK)
		where name = 'lots.process_state'
	END
	ELSE IF(@filter = 9)
	BEGIN
		SELECT [label_eng] as [filter_name]
		FROM [APCSProDB].[trans].[item_labels] with (NOLOCK)
		where name = 'lots.quality_state'
	END
	ELSE IF(@filter = 10)
	BEGIN
		select [fabwafer].fab_wf_lot_no as [filter_name]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[robin].[lot1_table_input] as [fabwafer] with (NOLOCK) on [fabwafer].lot_no = [lots].lot_no
		inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].assy_name = [fabwafer].assy_model_name
		where [lots].[wip_state] in (0,10,20)
		and [device_names].[name] like @device
		and [device_names].[assy_name] like @assyname
		and [lots].[lot_no] like @lotno
		and [fabwafer].[fab_wf_lot_no] is not null
		group by [fabwafer].[fab_wf_lot_no]
		order by [fabwafer].[fab_wf_lot_no]
		
		---------------------------------------------------------------------
		--select distinct [fabwafer].fab_wf_lot_no	as [filter_name]
		--from [APCSProDB].[trans].[lots]				with (NOLOCK)
		--full outer join [APCSProDB].[robin].[lot1_table_input] as [fabwafer] with (NOLOCK) on [fabwafer].lot_no = [lots].lot_no
		--inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].assy_name = [fabwafer].assy_model_name
		--where [fabwafer].fab_wf_lot_no like @wafer
		--and [device_names].[name] like @device
		--and [device_names].assy_name like @assyname
		--and [lots].lot_no like @lotno
		--and [fabwafer].fab_wf_lot_no is not null
		--and SUBSTRING([fabwafer].[lot_no],1,2) > 20
		--order by [fabwafer].fab_wf_lot_no
		----select distinct [fabwafer].fab_wf_lot_no	as [filter_name]
		----from [APCSProDB].[robin].[lot1_table_input] as [fabwafer]  with (NOLOCK)
		----inner join [APCSProDB].[method].[device_names] with (NOLOCK) on [device_names].assy_name = [fabwafer].assy_model_name
		----where [fabwafer].fab_wf_lot_no like @wafer
		----and [device_names].[name] like  @device
		----and [device_names].assy_name like @assyname
		----and [fabwafer].[lot_no] like @lotno
		----and [fabwafer].fab_wf_lot_no is not null
		----and SUBSTRING([fabwafer].[lot_no],1,2) > 20
		----order by [fabwafer].fab_wf_lot_no
		
	END
	ELSE IF(@filter = 11)
	BEGIN
		select [device_names].[assy_name] as [filter_name]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		where [lots].[wip_state] in (0,10,20)
		and [device_names].[name]		like @device
		and [packages].[name]			like @package	
		and [device_names].assy_name	like @assyname
		and [lots].[lot_no]				like @lotno
		group by [device_names].[assy_name]
		order by [device_names].[assy_name]

		--select distinct [device_names].assy_name as [filter_name]
		--from [APCSProDB].[trans].[lots] with (NOLOCK)
		--inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		--inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		--inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		--inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		--inner join [APCSProDB].[method].[package_groups]	with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		--inner join [APCSProDB].[method].[device_flows]		with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		--inner join [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		--inner join [APCSProDB].[method].[processes]			with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		--where [lots].[wip_state] in (0,10,20)
		--and [device_names].[name]		like @device
		--and [packages].[name]			like @package	
		--and [device_names].assy_name	like @assyname
		--and [lots].lot_no				like @lotno
		--order by [device_names].assy_name
		-------------------------------------------------------------------------
		--select distinct [device_names].assy_name as [filter_name]
		--from [APCSProDB].[trans].[lots] with (NOLOCK)
		--inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		--inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		--inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		--inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		--inner join [APCSProDB].[method].[package_groups]	with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		--inner join [APCSProDB].[method].[device_flows]		with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		--inner join [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		--inner join [APCSProDB].[method].[processes]			with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		--where [device_names].[name]		like @device
		--and [packages].[name]			like @package	
		--and [device_names].assy_name	like @assyname
		--and [lots].lot_no				like @lotno
		--order by [device_names].assy_name
	END
	ELSE IF(@filter = 12)
		BEGIN
		select distinct [device_versions].version_num as [filter_name]
		from [APCSProDB].[trans].[lots]						with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id] = [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id] = [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id] = [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id] = [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups]	with (NOLOCK) on [package_groups].[id] = [packages].[package_group_id]
		inner join [APCSProDB].[method].[device_flows]		with (NOLOCK) on [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
		inner join [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id] = [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes]			with (NOLOCK) on [processes].[id] = [jobs].[process_id]
		where  [device_names].[name]		LIKE @device
		and [packages].[name]				LIKE @package	
		and [device_names].assy_name		LIKE @assyname
		and [device_versions].version_num	LIKE @version
		order by [device_versions].version_num
	END
		ELSE IF(@filter = 13)
		BEGIN
		select distinct item_labels.label_eng as [filter_name]
		from [APCSProDB].[trans].[lots] with (NOLOCK)
		inner join [APCSProDB].[method].[device_slips]		with (NOLOCK) on [device_slips].[device_slip_id]	= [lots].[device_slip_id]
		inner join [APCSProDB].[method].[device_versions]	with (NOLOCK) on [device_versions].[device_id]		= [device_slips].[device_id]
		inner join [APCSProDB].[method].[device_names]		with (NOLOCK) on [device_names].[id]				= [device_versions].[device_name_id]
		inner join [APCSProDB].[method].[packages]			with (NOLOCK) on [packages].[id]					= [device_names].[package_id]
		inner join [APCSProDB].[method].[package_groups]	with (NOLOCK) on [package_groups].[id]				= [packages].[package_group_id]
		inner join [APCSProDB].[method].[device_flows]		with (NOLOCK) on [device_flows].[device_slip_id]	= [device_slips].[device_slip_id]
		inner join [APCSProDB].[method].[jobs]				with (NOLOCK) on [jobs].[id]						= [device_flows].[job_id]
		inner join [APCSProDB].[method].[processes]			with (NOLOCK) on [processes].[id]					= [jobs].[process_id]
		inner join [APCSProDB].[method].[item_labels]		with (NOLOCK) ON item_labels.name					= 'device_versions.device_type' 
																		  AND item_labels.val					= device_versions.device_type
		where 	[device_names].[name]			LIKE @device
		and		[packages].[name]				LIKE @package	
		and		[device_names].assy_name		LIKE @assyname
		and     [device_versions].version_num	LIKE @version
		 
		order by item_labels.label_eng
	END
	ELSE IF(@filter = 14)
	BEGIN
		SELECT 'Andon' as [filter_name]
		UNION ALL
		SELECT 'TRC' as [filter_name]
		UNION ALL
		SELECT 'StopLot' as [filter_name]
		UNION ALL
		SELECT 'OCR' as [filter_name]
	END
END
