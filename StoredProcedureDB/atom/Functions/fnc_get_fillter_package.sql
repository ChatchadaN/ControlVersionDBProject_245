CREATE FUNCTION [atom].[fnc_get_fillter_package]()
    RETURNS @table table (
		id int,
		name varchar(30),
		type int,
		group_id int
	)
AS
BEGIN
    insert into @table 
	SELECT [fillter].[id],[fillter].[name],[fillter].[type],[fillter].[group_id]
	FROM (
		SELECT DISTINCT [package_group_id] AS [id],[package_group_name] AS [name],1 AS [type],0 AS [group_id]
		FROM (
			SELECT [packages].[id] AS [package_id]
				, [packages].[name] AS [package_name]
				, [package_groups].[id] AS [package_group_id]
				, [package_groups].[name] AS [package_group_name]
			FROM [APCSProDWH].[wip_control].[monitoring_items]
			INNER JOIN [APCSProDWH].[wip_control].[wip_count_target] ON [monitoring_items].[target_id] = [wip_count_target].[id]
			INNER JOIN [APCSProDB].[method].[packages] ON [wip_count_target].[package_id] = [packages].[id]
			INNER JOIN [APCSProDB].[method].[package_groups] ON [packages].[package_group_id] = [package_groups].[id]
			WHERE ([wip_count_target].[name] LIKE '%MPmc~FL%' OR [wip_count_target].[name] LIKE '%DBmc~MP%' OR [wip_count_target].[name] LIKE '%AUTO4~TP%')
		) AS [package_groups]
		UNION ALL
		SELECT DISTINCT [package_id] AS [id],[package_name] AS [name],2 AS [type],[package_group_id] AS [group_id]
		FROM (
			SELECT [packages].[id] AS [package_id]
				, [packages].[name] AS [package_name]
				, [package_groups].[id] AS [package_group_id]
				, [package_groups].[name] AS [package_group_name]
			FROM [APCSProDWH].[wip_control].[monitoring_items]
			INNER JOIN [APCSProDWH].[wip_control].[wip_count_target] ON [monitoring_items].[target_id] = [wip_count_target].[id]
			INNER JOIN [APCSProDB].[method].[packages] ON [wip_count_target].[package_id] = [packages].[id]
			INNER JOIN [APCSProDB].[method].[package_groups] ON [packages].[package_group_id] = [package_groups].[id]
			WHERE ([wip_count_target].[name] LIKE '%MPmc~FL%' OR [wip_count_target].[name] LIKE '%DBmc~MP%' OR [wip_count_target].[name] LIKE '%AUTO4~TP%')
		) AS [packages]
	) AS [fillter]
	ORDER BY [fillter].[type],[fillter].[name];

    RETURN;
END;