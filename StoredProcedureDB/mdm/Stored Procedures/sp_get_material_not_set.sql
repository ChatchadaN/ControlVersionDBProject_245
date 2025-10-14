-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_material_not_set]
	-- Add the parameters for the stored procedure here
	@process_id			AS INT				= NULL ,
	@package_name		AS NVARCHAR(100)	= NULL ,
	@assy_name			AS NVARCHAR(100)	= NULL ,
	@device_name		AS NVARCHAR(100)	= NULL ,
	@device_type		AS NVARCHAR(100)	= NULL 
AS
BEGIN
	SET NOCOUNT ON;

	SELECT    [device_flows].[device_slip_id]  
			, RTRIM(ISNULL([device_flows].[package_name], ''))		AS package_name
			, RTRIM(ISNULL([device_flows].[device_name], ''))		AS device_name
			, RTRIM(ISNULL([device_flows].[assy_name], ''))			AS assy_name
			, RTRIM(ISNULL([device_flows].[device_type_name], ''))  AS device_type_name
			, ISNULL([device_flows].[tp_rank], '')			AS [tp_rank]
			, ISNULL([device_flows].[job_name], '')			AS [job_name]
			, ISNULL([device_flows].[step_no], '')			AS [step_no]
			, ISNULL([device_flows].[job_id], '')			AS [job_id]
			, ISNULL([device_flows].[version_num], '')		AS version_num
			, ISNULL([device_flows].[device_type], '')		AS  [device_type]
			, ISNULL([device_flows].[material_set_id], '') AS [material_id]
			, ISNULL([device_flows].[act_process_id], '') AS [act_process_id]
			, ISNULL([device_flows].process_name, '') AS process_name
			, CASE WHEN  [device_flows].[material_set_id] IS NULL THEN 'blank' ELSE 'wrong' END  AS [status]
		FROM (
			SELECT [device_flows].[id]
				, [device_flows].[act_process_id]
				, [device_flows].[device_slip_id]
				, [device_flows].[step_no]
				, [device_flows].[job_id]
				, [device_slips].[version_num]
				, [device_names].[name] AS [device_name]
				, [device_names].[assy_name]
				, [packages].[name] AS [package_name]
				, [jobs].[name] AS [job_name] 
				, [device_versions].[device_type]
				, [item_labels].[label_eng] AS [device_type_name]
				, [device_flows].[material_set_id]
				, [device_slips].[is_released]
				, RANK () OVER ( PARTITION BY [device_names].[name], [device_names].[assy_name], [device_versions].[device_type]
						ORDER BY [device_names].[name], [device_names].[assy_name], [device_slips].[version_num] DESC ) AS [rank_no]
				, [device_names].[tp_rank]
				, processes.[name]  AS process_name
				, material_sets.id  AS material_set
			FROM [APCSProDB].[method].[device_flows]
			INNER JOIN [APCSProDB].[method].[device_slips] 
			ON [device_flows].[device_slip_id] = [device_slips].[device_slip_id]
			INNER JOIN [APCSProDB].[method].[device_versions]
			ON [device_slips].[device_id] = [device_versions].[device_id]
			INNER JOIN [APCSProDB].[method].[device_names] 
			ON [device_versions].[device_name_id] = [device_names].[id]
			INNER JOIN [APCSProDB].[method].[packages]
			ON [device_names].[package_id] = [packages].[id]
			INNER JOIN [APCSProDB].[method].[jobs] 
			ON [device_flows].[job_id] = [jobs].[id] 
			LEFT JOIN [APCSProDB].[method].[item_labels] 
			ON [item_labels].[name] = 'device_versions.device_type'
			AND [device_versions].[device_type] = [item_labels].[val]
			INNER JOIN APCSProDB.method.processes
			ON [device_flows].act_process_id = processes.id 
			LEFT JOIN [APCSProDB].[method].material_sets
			ON material_sets.name = packages.name 
			AND material_sets.process_id = @process_id  AND is_checking = 1
			WHERE ([packages].[name] = @package_name OR @package_name IS NULL)  
			AND ([device_names].assy_name = @assy_name OR @assy_name  IS NULL)
			AND ([device_names].[name] = @device_name OR @device_name  IS NULL)
			AND ([item_labels].[label_eng] =  @device_type OR @device_type  IS NULL)
			AND	[device_flows].[is_skipped] = 0
			AND [device_slips].[is_released] = 1
		) AS [device_flows]
		WHERE [device_flows].[rank_no] = 1 
		AND (act_process_id =  @process_id  OR IIF(@process_id =0,NULL,@process_id) IS NULL)
		AND ([device_flows].material_set_id != material_set OR  [device_flows].material_set_id IS NULL )
		ORDER BY [device_flows].[package_name]
			, [device_flows].[device_slip_id]
			, [device_flows].[step_no]
			, [device_flows].[version_num]


END
