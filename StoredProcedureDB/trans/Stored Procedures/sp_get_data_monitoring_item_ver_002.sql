-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_data_monitoring_item_ver_002]
	@package_id varchar(10) = '%'
	, @package_group_id varchar(10) = '%'  --'33'
	, @date_start varchar(10) = '2022-08-01'
	, @date_end varchar(10) = '2022-08-31'
	, @function int = 0  --# 0:daily 1:hourly 2:droupdown package
	, @range int = 0 --# Remark 0:blank 1:front 2:middle 3:lear
	, @group varchar(10) = '%'
AS
BEGIN
	SET NOCOUNT ON;

	IF (@function = 0)
	BEGIN
		--------------------------------------------------------------
		----- Remark (0) package master
		--------------------------------------------------------------
		declare @table_package table (
			id int
			, name nvarchar (30)
		)

		IF (@package_id = '%' AND @package_group_id = '%')
		BEGIN
			INSERT INTO @table_package
			SELECT id,name
			FROM [StoredProcedureDB].[atom].[fnc_get_fillter_package] ()
			WHERE type = 2;
		END
		ELSE IF (@package_id != '%' AND @package_group_id = '%')
		BEGIN
			INSERT INTO @table_package
			SELECT id,name
			FROM [StoredProcedureDB].[atom].[fnc_get_fillter_package] ()
			WHERE type = 2
				AND id = @package_id;
		END
		ELSE IF (@package_id = '%' AND @package_group_id != '%')
		BEGIN
			INSERT INTO @table_package
			SELECT id,name
			FROM [StoredProcedureDB].[atom].[fnc_get_fillter_package] ()
			WHERE type = 2
				AND group_id = @package_group_id;
		END
		--------------------------------------------------------------
		----- Remark (1) data_head
		--------------------------------------------------------------
		declare @table_head table (
			date_value date
			, for_date nvarchar (4)
			, items_id int
			, items_name nvarchar (30)
			, top_id int
			, package_id int
			, package_name nvarchar (20)
		)

		declare @date_count int = 0
		set @date_count = DATEDIFF(day,cast(@date_start as date),cast(@date_end as date)) + 1

		INSERT INTO @table_head 
			(date_value
			, for_date
			, items_id
			, items_name
			, top_id
			, package_id
			, package_name)
		SELECT [days].[date_value]
			, FORMAT([days].[date_value], 'MMdd') AS [for_date]
			, [data_head].[monitoring_item_id]
			, [data_head].[Top_name] as [item_name]
			, [data_head].[Top_id]
			, [data_head].[package_id]
			, [data_head].[package_name]
		FROM (
			SELECT [data_top].[package_name]
				, [data_top].[Top_id]
				, [data_top].[Top_name]
				, [data_top].[package_id]
				, [data_gdic].[monitoring_item_id]
			FROM (
				SELECT [master].[id] AS [package_id]
					, [master].[name] AS [package_name]
					, [data_top].[Top_id]
					, [data_top].[Top_name]
				FROM @table_package as [master],(
					SELECT 1 AS [Top_id],'DB_MP' AS [Top_name]
					UNION ALL
					SELECT 2 AS [Top_id],'MP_FL' AS [Top_name]
					UNION ALL
					SELECT 3 AS [Top_id],'A4_TP' AS [Top_name]
				) as [data_top]
			) as [data_top]
			LEFT JOIN (
				SELECT [monitoring_items].[id] as [monitoring_item_id]
					, [packages].[id] as [package_id]
					, [packages].[name] as [package_name]
					, [wip_count_target].[name]
					, CASE
						WHEN [wip_count_target].[name] LIKE '%DBmc~MP%' THEN 'DB_MP'
						WHEN [wip_count_target].[name] LIKE '%MPmc~FL%' THEN 'MP_FL'
						WHEN [wip_count_target].[name] LIKE '%AUTO4~TP%' THEN 'A4_TP'
					END AS [Top_name]
					, CASE
						WHEN [wip_count_target].[name] LIKE '%DBmc~MP%' THEN 1
						WHEN [wip_count_target].[name] LIKE '%MPmc~FL%' THEN 2
						WHEN [wip_count_target].[name] LIKE '%AUTO4~TP%' THEN 3
					END AS [Top_id]
				FROM [APCSProDWH].[wip_control].[monitoring_items]
				INNER JOIN [APCSProDWH].[wip_control].[wip_count_target] ON [monitoring_items].[target_id] = [wip_count_target].[id]
				INNER JOIN [APCSProDB].[method].[packages] ON [wip_count_target].[package_id] = [packages].[id]
					AND ([wip_count_target].[name] LIKE '%MPmc~FL%' OR [wip_count_target].[name] LIKE '%DBmc~MP%' OR [wip_count_target].[name] LIKE '%AUTO4~TP%')
					AND [packages].[id] like @package_id
					AND [packages].[package_group_id] like @package_group_id
			) AS [data_gdic] ON [data_top].[package_id] = [data_gdic].[package_id]
				AND [data_top].[Top_id] = [data_gdic].[Top_id]
		) AS [data_head],[APCSProDB].[trans].[days]
		WHERE ([days].[date_value] between @date_start and @date_end)
			AND [data_head].[package_id] like @package_id
		ORDER BY [data_head].[package_name],[data_head].[Top_id],[days].[date_value]
		--------------------------------------------------------------
		----- Remark (2) data_body
		--------------------------------------------------------------
		declare @table_monitoring_data table (
			monitoring_item_id int
			, date date
			, current_value decimal(10,1)
			, target_value decimal(10,1)
		)

		INSERT INTO @table_monitoring_data
		SELECT monitoring_item_id, date, CAST(AVG([monitoring_item_records_temp].current_value) AS DECIMAL(9,1)) AS current_value, CAST(AVG([monitoring_item_records_temp].alarm_value) AS DECIMAL(9,1)) AS target_value
		FROM [APCSProDWH].[wip_control].[monitoring_item_records_temp]
		INNER JOIN [APCSProDWH].[wip_control].[monitoring_items] ON [monitoring_item_records_temp].[monitoring_item_id] = [monitoring_items].[id]
		INNER JOIN [APCSProDWH].[wip_control].[wip_count_target] ON [monitoring_items].[target_id] = [wip_count_target].[id]
		INNER JOIN [APCSProDB].[method].[packages] ON [wip_count_target].[package_id] = [packages].[id]
			AND ([wip_count_target].[name] LIKE '%MPmc~FL%' OR [wip_count_target].[name] LIKE '%DBmc~MP%' OR [wip_count_target].[name] LIKE '%AUTO4~TP%')
			AND [packages].[id] like @package_id
			AND [packages].[package_group_id] like @package_group_id
		WHERE ([monitoring_item_records_temp].[date] between @date_start and @date_end)
		GROUP BY [monitoring_item_records_temp].monitoring_item_id, [monitoring_item_records_temp].date
		--------------------------------------------------------------
		----- Remark (3) select_data
		--------------------------------------------------------------
		SELECT d_data.top_id 
			, date_value
			, for_date AS date_value2
			, package_name
			, TRIM(package_name) + ' [' + items_name + ']' AS items_name
			, CAST(ISNULL(d_temp.current_value,0) AS DECIMAL(9,1)) AS current_value
			, 'Limit ' + TRIM(package_name) + ' [' + items_name + ']' AS items_name_limit
			, CAST(ISNULL(d_temp.target_value,ISNULL([monitoring_items].alarm_value,0)) AS DECIMAL(9,1)) AS target_value
			, @date_count AS count_date
		FROM @table_head AS d_data
		LEFT JOIN @table_monitoring_data AS d_temp ON d_data.items_id = d_temp.monitoring_item_id
			AND d_data.date_value = d_temp.date
		LEFT JOIN [APCSProDWH].[wip_control].[monitoring_items] ON d_data.items_id = [monitoring_items].id
		WHERE d_data.top_id = @range
			AND d_data.package_id like @package_id
		ORDER BY [package_name],[top_id],[date_value]
	END
	ELSE IF (@function = 1)
	BEGIN
		--------------------------------------------------------------
		----- Remark (0) package master
		--------------------------------------------------------------
		declare @table_packagehour table (
			id int
			, name nvarchar (30)
		)

		IF (@package_id = '%' AND @package_group_id = '%')
		BEGIN
			INSERT INTO @table_packagehour
			SELECT id,name
			FROM [StoredProcedureDB].[atom].[fnc_get_fillter_package] ()
			WHERE type = 2;
		END
		ELSE IF (@package_id != '%' AND @package_group_id = '%')
		BEGIN
			INSERT INTO @table_packagehour
			SELECT id,name
			FROM [StoredProcedureDB].[atom].[fnc_get_fillter_package] ()
			WHERE type = 2
				AND id = @package_id;
		END
		ELSE IF (@package_id = '%' AND @package_group_id != '%')
		BEGIN
			INSERT INTO @table_packagehour
			SELECT id,name
			FROM [StoredProcedureDB].[atom].[fnc_get_fillter_package] ()
			WHERE type = 2
				AND group_id = @package_group_id;
		END
		--------------------------------------------------------------
		----- Remark (1) data_head
		--------------------------------------------------------------
		declare @table_headhour table (
			date_value date
			, for_date nvarchar (2)
			, items_id int
			, items_name nvarchar (30)
			, top_id int
			, package_id int
			, package_name nvarchar (20)
		)

		declare @table_hour table (
			time int
		)

		insert into @table_hour
		select [time]
		FROM (
			select 0 as [time]
			union
			select 1 as [time]
			union
			select 2 as [time]
			union
			select 3 as [time]
			union
			select 4 as [time]
			union
			select 5 as [time]
			union
			select 6 as [time]
			union
			select 7 as [time]
			union
			select 8 as [time]
			union
			select 9 as [time]
			union
			select 10 as [time]
			union
			select 11 as [time]
			union
			select 12 as [time]
			union
			select 13 as [time]
			union
			select 14 as [time]
			union
			select 15 as [time]
			union
			select 16 as [time]
			union
			select 17 as [time]
			union
			select 18 as [time]
			union
			select 19 as [time]
			union
			select 20 as [time]
			union
			select 21 as [time]
			union
			select 22 as [time]
			union
			select 23 as [time]
		) as t1

		declare @date_count3 int = 0
		set @date_count3 = (select count(time) from @table_hour)

		INSERT INTO @table_headhour 
			(date_value
			, for_date
			, items_id
			, items_name
			, top_id
			, package_id
			, package_name)
		SELECT FORMAT(GETDATE(), 'yyyy-MM-dd') AS [date_value]
			, FORMAT([days].[time], '00') AS [for_date]
			, [data_head].[monitoring_item_id]
			, [data_head].[Top_name] as [item_name]
			, [data_head].[Top_id]
			, [data_head].[package_id]
			, [data_head].[package_name]
		FROM (
			SELECT [data_top].[package_name]
				, [data_top].[Top_id]
				, [data_top].[Top_name]
				, [data_top].[package_id]
				, [data_gdic].[monitoring_item_id]
			FROM (
				SELECT [master].[id] AS [package_id]
					, [master].[name] AS [package_name]
					, [data_top].[Top_id]
					, [data_top].[Top_name]
				FROM @table_packagehour as [master],(
					SELECT 1 AS [Top_id],'DB_MP' AS [Top_name]
					UNION ALL
					SELECT 2 AS [Top_id],'MP_FL' AS [Top_name]
					UNION ALL
					SELECT 3 AS [Top_id],'A4_TP' AS [Top_name]
				) as [data_top]
			) as [data_top]
			LEFT JOIN (
				SELECT [monitoring_items].[id] as [monitoring_item_id]
					, [packages].[id] as [package_id]
					, [packages].[name] as [package_name]
					, [wip_count_target].[name]
					, CASE
						WHEN [wip_count_target].[name] LIKE '%DBmc~MP%' THEN 'DB_MP'
						WHEN [wip_count_target].[name] LIKE '%MPmc~FL%' THEN 'MP_FL'
						WHEN [wip_count_target].[name] LIKE '%AUTO4~TP%' THEN 'A4_TP'
					END AS [Top_name]
					, CASE
						WHEN [wip_count_target].[name] LIKE '%DBmc~MP%' THEN 1
						WHEN [wip_count_target].[name] LIKE '%MPmc~FL%' THEN 2
						WHEN [wip_count_target].[name] LIKE '%AUTO4~TP%' THEN 3
					END AS [Top_id]
				FROM [APCSProDWH].[wip_control].[monitoring_items]
				INNER JOIN [APCSProDWH].[wip_control].[wip_count_target] ON [monitoring_items].[target_id] = [wip_count_target].[id]
				INNER JOIN [APCSProDB].[method].[packages] ON [wip_count_target].[package_id] = [packages].[id]
					AND ([wip_count_target].[name] LIKE '%MPmc~FL%' OR [wip_count_target].[name] LIKE '%DBmc~MP%' OR [wip_count_target].[name] LIKE '%AUTO4~TP%')
					AND [packages].[id] like @package_id
					AND [packages].[package_group_id] like @package_group_id
			) AS [data_gdic] ON [data_top].[package_id] = [data_gdic].[package_id]
				AND [data_top].[Top_id] = [data_gdic].[Top_id]
		) AS [data_head],@table_hour as [days]
		WHERE [data_head].[package_id] like @package_id
		ORDER BY [data_head].[package_name],[data_head].[Top_id],CAST([days].[time] AS INT) ASC
		--------------------------------------------------------------
		----- Remark (2) data_body
		--------------------------------------------------------------
		declare @table_monitoring_datahour table (
			monitoring_item_id int
			, time nvarchar(2)
			, current_value decimal(9,1)
			, target_value decimal(9,1)
		)

		INSERT INTO @table_monitoring_datahour
		SELECT monitoring_item_id, [time], CAST(AVG([monitoring_item_records_temp].current_value) AS DECIMAL(9,1)) AS current_value, CAST(AVG([monitoring_item_records_temp].alarm_value) AS DECIMAL(9,1)) AS target_value
		FROM [APCSProDWH].[wip_control].[monitoring_item_records_temp]
		INNER JOIN [APCSProDWH].[wip_control].[monitoring_items] ON [monitoring_item_records_temp].[monitoring_item_id] = [monitoring_items].[id]
		INNER JOIN [APCSProDWH].[wip_control].[wip_count_target] ON [monitoring_items].[target_id] = [wip_count_target].[id]
		INNER JOIN [APCSProDB].[method].[packages] ON [wip_count_target].[package_id] = [packages].[id]
			AND ([wip_count_target].[name] LIKE '%MPmc~FL%' OR [wip_count_target].[name] LIKE '%DBmc~MP%' OR [wip_count_target].[name] LIKE '%AUTO4~TP%')
			AND [packages].[id] like @package_id
			AND [packages].[package_group_id] like @package_group_id
		WHERE ([monitoring_item_records_temp].[date] = FORMAT(GETDATE(), 'yyyy-MM-dd'))
		GROUP BY [monitoring_item_records_temp].monitoring_item_id, [monitoring_item_records_temp].[time]
		--------------------------------------------------------------
		----- Remark (3) select_data
		--------------------------------------------------------------
		SELECT d_data.top_id 
			, date_value
			, for_date AS date_value2
			, package_name
			, TRIM(package_name) + ' [' + items_name + ']' AS items_name
			, CAST(ISNULL(d_temp.current_value,0) AS DECIMAL(9,1)) AS current_value
			, 'Limit ' + TRIM(package_name) + ' [' + items_name + ']' AS items_name_limit
			, CAST(ISNULL(d_temp.target_value,ISNULL([monitoring_items].alarm_value,0)) AS DECIMAL(9,1)) AS target_value
			, @date_count3 AS count_date
		FROM @table_headhour AS d_data
		LEFT JOIN @table_monitoring_datahour AS d_temp ON d_data.items_id = d_temp.monitoring_item_id
			AND d_data.for_date = d_temp.time
		LEFT JOIN [APCSProDWH].[wip_control].[monitoring_items] ON d_data.items_id = [monitoring_items].id
		WHERE d_data.top_id = @range
			AND d_data.package_id like @package_id
		ORDER BY [package_name],[top_id],CAST(for_date AS INT)
	END
	ELSE IF (@function = 2)
	BEGIN
		------------------------------------------------------------
		--- Remark type 1: package_group 2: package
		------------------------------------------------------------
		SELECT [id],[name],[type]
		FROM (
			SELECT DISTINCT [package_group_id] AS [id],[package_group_name] AS [name],1 AS [type]
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
			SELECT DISTINCT [package_id] AS [id],[package_name] AS [name],2 AS [type]
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
		WHERE [fillter].[id] LIKE @package_id
			AND [fillter].[type] LIKE @group
		ORDER BY [fillter].[type],[fillter].[name]
	END
END
