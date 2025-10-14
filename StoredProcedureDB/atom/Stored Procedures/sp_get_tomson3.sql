-- =============================================
CREATE PROCEDURE [atom].[sp_get_tomson3] 
	-- Add the parameters for the stored procedure here
	@status INT = 0, ----#0:wip_list, 1:hasuu_list, 2:change_list
	@lot_no VARCHAR(10) = '%',
	@package_group VARCHAR(20) = '%',
	@package VARCHAR(20) = '%',
	@device VARCHAR(20) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @table_lots TABLE (
		[lot_id] [INT],
		[lot_no] [VARCHAR](10),
		[package_group] [VARCHAR](20),
		[package] [VARCHAR](20),
		[device] [VARCHAR](20),
		[wip_state] [INT],
		[tomson3_before] [CHAR](4),
		[tomson3_after] [CHAR](4),
		[status] [INT]
	);

	IF ( @status = 0 )
	BEGIN
		INSERT INTO @table_lots
		SELECT [lot_id],
			[lot_no],
			[package_group],
			[package],
			[device],
			[wip_state],
			[tomson3_before],
			[tomson3_after],
			[status]
		FROM (
			SELECT [lots].[id] AS [lot_id]
				, [lots].[lot_no]
				, [package_groups].[name] AS [package_group]
				, [packages].[name] AS [package]
				, [device_names].[name] AS [device]
				, [lots].[wip_state]
				, ISNULL( [allocat].[Tomson3], [allocat_temp].[Tomson3] ) AS [tomson3_before]
				, ISNULL( [allocat].[Tomson3], [allocat_temp].[Tomson3] ) AS [tomson3_after]
				, 0 AS [status]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDB].[method].[device_names]  ON [lots].[act_device_name_id] = [device_names].[id]
			INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
			INNER JOIN [APCSProDB].[method].[package_groups] ON [packages].[package_group_id] = [package_groups].[id]
			LEFT JOIN [APCSProDB].[trans].[surpluses] ON [lots].[id] = [surpluses].[lot_id]
			INNER JOIN [APCSProDB].[trans].[days] AS [day_indate] ON [lots].[in_plan_date_id] = [day_indate].[id]
			LEFT JOIN [APCSProDB].[method].[allocat] ON [lots].[lot_no] = [allocat].[LotNo]
			LEFT JOIN [APCSProDB].[method].[allocat_temp] ON [lots].[lot_no] = [allocat_temp].[LotNo]
			LEFT JOIN [APCSProDWH].[tg].[lot_qc_info] ON [lots].[id] = [lot_qc_info].[lot_id]
			WHERE [surpluses].[lot_id] IS NULL
				AND [lot_qc_info].[lot_id] IS NULL
				AND [lots].[wip_state] = 20
				AND [day_indate].[date_value] <= CONVERT(DATE, GETDATE())
				AND [package_groups].[id] NOT IN (35,1)
		) AS [lots]
		WHERE [tomson3_before] IS NOT NULL;
	END
	ELSE IF ( @status = 1 )
	BEGIN
		INSERT INTO @table_lots
		SELECT [lot_id],
			[lot_no],
			[package_group],
			[package],
			[device],
			[wip_state],
			[tomson3_before],
			[tomson3_after],
			[status]
		FROM (
			SELECT  [lots].[id] AS [lot_id]
				, [lots].[lot_no]
				, [package_groups].[name] AS [package_group]
				, [packages].[name] AS [package]
				, [device_names].[name] AS [device]
				, [lots].[wip_state]
				, [surpluses].[qc_instruction] AS [tomson3_before]
				, [surpluses].[qc_instruction] AS [tomson3_after]
				, 1 AS [status]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDB].[method].[device_names]  ON [lots].[act_device_name_id] = [device_names].[id]
			INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
			INNER JOIN [APCSProDB].[method].[package_groups] ON [packages].[package_group_id] = [package_groups].[id]
			INNER JOIN [APCSProDB].[trans].[surpluses] ON [lots].[id] = [surpluses].[lot_id]
			LEFT JOIN [APCSProDWH].[tg].[lot_qc_info] ON [lots].[id] = [lot_qc_info].[lot_id]
			WHERE [surpluses].[in_stock] = 2
				--AND [lots].[wip_state] IN (70,100)
				AND [lots].[wip_state] IN (70,100,20) ---- # recall
				AND [lot_qc_info].[lot_id] IS NULL
		) AS [lots]
		WHERE [tomson3_before] IS NOT NULL;
	END
	ELSE IF ( @status = 2 )
	BEGIN
		INSERT INTO @table_lots
		SELECT [lot_qc_info].[lot_id]
			, [lots].[lot_no]
			, [package_groups].[name] AS [package_group]
			, [packages].[name] AS [package]
			, [device_names].[name] AS [device]
			, [lots].[wip_state]
			, [lot_qc_info].[tomson3_before]
			, [lot_qc_info].[tomson3_after]
			, 2 AS [status]
		FROM [APCSProDWH].[tg].[lot_qc_info]
		INNER JOIN [APCSProDB].[trans].[lots] ON [lot_qc_info].[lot_id] = [lots].[id]
		INNER JOIN [APCSProDB].[method].[device_names]  ON [lots].[act_device_name_id] = [device_names].[id]
		INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
		INNER JOIN [APCSProDB].[method].[package_groups] ON [packages].[package_group_id] = [package_groups].[id];
	END


	SELECT [lot_id],
		[lot_no],
		[package_group],
		[package],
		[device],
		[wip_state],
		[tomson3_before],
		[tomson3_after],
		[status]
	FROM @table_lots
	WHERE [lot_no] LIKE @lot_no + '%'
		AND [package] LIKE @package
		AND [device] LIKE @device
		AND [package_group] LIKE @package_group
	ORDER BY [lot_no] ASC;
 
END
