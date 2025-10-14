

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_filter]
	-- Add the parameters for the stored procedure here
	  @package			varchar(20) = '%'
	, @device			varchar(20) = '%'
	, @job				varchar(50) = '%'
	, @deviceType		varchar(50) = '%'  
	, @filter			INT  =  NULL
	, @process_id		INT  =  NULL
	
	--1: Package, 2: Device , 3: Job 
						 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets FROM
	-- interfering with SELECT statements.

	SET NOCOUNT ON;	

    -- Insert statements for procedure here
	IF(@filter = 1)
	BEGIN

		SELECT [packages].id  ,  [packages].[name] as [filter_name]
		from APCSProDB.method.device_flows
	inner join APCSProDB.method.device_slips on device_flows.device_slip_id = device_slips.device_slip_id
	inner join APCSProDB.method.device_versions on device_slips.device_id = device_versions.device_id
	inner join APCSProDB.method.device_names on device_versions.device_name_id = device_names.id
	inner join APCSProDB.method.packages on device_names.package_id = packages.id
	inner join APCSProDB.method.jobs on device_flows.job_id = jobs.id
		where (act_process_id = @process_id OR @process_id IS NULL )
		AND [packages].[name] like @package
		and [device_names].ft_name like @device
		 
		group by [packages].[name], [packages].id
		order by  [packages].[name]
	END
	ELSE IF(@filter = 2)
	BEGIN
			SELECT id, filter_name 
			FROM
				(
				 SELECT [device_names].id ,ROW_NUMBER() OVER (
				 PARTITION BY ft_name
				 ORDER BY  [device_names].id
				) row_num
				, [device_names].ft_name as [filter_name]
			FROM   [APCSProDB].[method].[device_names]	
			INNER JOIN APCSProDB.method.packages 
			ON device_names.package_id = packages.id
			WHERE [device_names].ft_name IS NOT NULL 
			AND [device_names].[name] like @device
			AND [packages].[name] like @package
			GROUP BY [device_names].ft_name , [device_names].id 
		) AS T1
		WHERE  row_num = 1 
		ORDER BY   filter_name

		--SELECT 1 AS id,  TRIM([device_names].ft_name )as [filter_name]
		--FROM   [APCSProDB].[method].[device_names]	
		--inner join APCSProDB.method.packages on device_names.package_id = packages.id
		--where [device_names].[name] like @device
		--AND [packages].[name] like @package
		--group by [device_names].ft_name  
		--order by [device_names].ft_name  
	END
	
	ELSE IF(@filter = 3)
	BEGIN
		SELECT id, [filter_name]
		FROM (	SELECT [jobs].id  , [jobs].[name] as [filter_name]
				FROM [APCSProDB].[trans].[lots]						WITH (NOLOCK)
				INNER JOIN [APCSProDB].[method].[device_slips]		WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
				INNER JOIN [APCSProDB].[method].[device_versions]	WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
				INNER JOIN [APCSProDB].[method].[device_names]		WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
				INNER JOIN [APCSProDB].[method].[packages]			WITH (NOLOCK) ON [packages].[id] = [device_names].[package_id]
				INNER JOIN [APCSProDB].[method].[package_groups]	WITH (NOLOCK) ON [package_groups].[id] = [packages].[package_group_id]
				INNER JOIN [APCSProDB].[method].[device_flows]		WITH (NOLOCK) ON [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
				INNER JOIN [APCSProDB].[method].[jobs]				WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
				where   [device_flows].[is_skipped] = 0
					and [jobs].[is_skipped] = 0
				AND [device_names].ft_name LIKE @device
				group by [jobs].[name], [jobs].id  
				union all
				SELECT [jobs].id  ,[jobs].[name] as [filter_name]
				FROM [APCSProDB].[trans].[special_flows]			WITH (NOLOCK) 
				INNER JOIN [APCSProDB].[trans].[lot_special_flows]	WITH (NOLOCK) ON [lot_special_flows].[special_flow_id] = [special_flows].[id] 
				INNER JOIN [APCSProDB].[method].[jobs]				WITH (NOLOCK) ON [jobs].[id] = [lot_special_flows].[job_id]
				group by [jobs].[name] , [jobs].id  
		) as table_jobs
		where [filter_name] is not null
		 
		group by [filter_name],id
		order by [filter_name],id

	END

END
