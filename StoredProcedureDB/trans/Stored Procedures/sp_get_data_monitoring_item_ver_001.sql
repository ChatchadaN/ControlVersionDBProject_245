-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_data_monitoring_item_ver_001]
	@package_id varchar(10) = '%'
	, @date_start varchar(10)
	, @date_end varchar(10) 
	, @version int = 0
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	--declare @package_id varchar(10) = '246' --'242'544
	--	, @date_start varchar(10) = '2022-07-01'
	--	, @date_end varchar(10) = '2022-07-30'

	IF (@version = 0)
	BEGIN
		declare @tabledata table (
			date_value date
			, items_id int
			, items_name nvarchar (30)
			, current_value decimal(10,2)
			, target_value decimal(10,2)
			, target_value2 decimal(10,2)
		)

		insert into @tabledata
		(
			date_value
			, items_id
			, items_name 
			, current_value
			, target_value
			, target_value2
		)
		select [monitoring_items].[date_value]
			, [monitoring_items].[id]
			, [monitoring_items].[name]
			, [monitoring_item_records].[current_value]
			, [monitoring_item_records].[target_value]
			, [monitoring_items].[target_value] as [target_value2]
		from (
			select [days].[date_value]
				, [monitoring_items].[id]
				, [monitoring_items].[name]
				, [monitoring_items].[package_id]
				, [monitoring_items].[target_value]
			from [APCSProDB].[trans].[days],[APCSProDWH].[wip_control].[monitoring_items]
			where ([days].[date_value] between @date_start and @date_end)
				and ([monitoring_items].[package_id] like @package_id)
				and ([monitoring_items].[is_input_control] = 0)
		) as [monitoring_items]
		left join (
			select [monitoring_item_records].[monitoring_item_id] as [monitoring_item_id]
				, format([monitoring_item_records].[recorded_at], 'yyyy-MM-dd') as [date_value]
				, avg([monitoring_item_records].[current_value]) as [current_value] 
				, avg([monitoring_item_records].[target_value]) as [target_value] 
			from [APCSProDWH].[wip_control].[monitoring_item_records]
			inner join [APCSProDWH].[wip_control].[monitoring_items] on [monitoring_item_records].[monitoring_item_id] = [monitoring_items].[id]
			where [monitoring_item_records].[recorded_at] between @date_start + ' 00:00:00' and @date_end + ' 23:59:59'
				and ([monitoring_items].[package_id] like @package_id)
				and ([monitoring_items].[is_input_control] = 0)
			group by format([monitoring_item_records].[recorded_at], 'yyyy-MM-dd'),[monitoring_item_records].[monitoring_item_id]
		) as [monitoring_item_records] on [monitoring_items].[date_value] = [monitoring_item_records].[date_value]
			and [monitoring_item_records].[monitoring_item_id] = [monitoring_items].[id] 
		where [monitoring_items].[date_value] between @date_start and @date_end
		--order by [monitoring_items].[name],[monitoring_items].[date_value]


		select data1.date_value
			, format(data1.date_value, 'MMdd') as date_value2
			, data1.items_name
			--, data1.current_value as current_value1
			--, data1.target_value as target_value1
			, case 
				when data1.date_value < getdate() then 
					case 
						when data1.current_value IS NULL then isnull(data2.current_value,0)
						else isnull(data1.current_value,0)
					end
				else 0
			end as current_value
			, 'Limit ' + data1.items_name as [items_name_limit]
			, case 
				when data1.date_value < getdate() then 
					case 
						when data1.target_value IS NULL then isnull(data2.target_value,0)
						else isnull(data1.target_value,0)
					end
				else data1.target_value2
			end as target_value
			, DATEDIFF(day,cast(@date_start as date),cast(@date_end as date)) + 1 as count_date
		from @tabledata as data1
		outer apply (
			SELECT TOP 1 data2.current_value
				, data2.target_value
			FROM @tabledata as data2
			WHERE data2.items_id = data1.items_id
				AND data2.date_value <= data1.date_value
				AND data2.current_value IS NOT NULL
			ORDER BY data2.date_value DESC
		) as data2
		ORDER BY data1.items_name,data1.date_value

		--packages
		--select [monitoring_items].[package_id]
		--	, [packages].[name] as [package_name]
		--from (
		--	select [monitoring_items].[package_id]
		--	from [APCSProDWH].[wip_control].[monitoring_items]
		--	where ([monitoring_items].[is_input_control] = 0)
		--	group by [monitoring_items].[package_id]
		--) as [monitoring_items]
		--inner join [APCSProDB].[method].[packages] on [monitoring_items].[package_id] = [packages].[id]
		--order by [packages].[name]
	END
	ELSE IF (@version = 1)
	BEGIN
		------------------------------------------
		--- version 001
		------------------------------------------
		declare @tabledata2 table (
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

		INSERT INTO @tabledata2 
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
				FROM (
					SELECT id,name
					FROM [APCSProDB].[method].[packages]
					WHERE [packages].[id] = @package_id
				) as [master],(
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
				WHERE [packages].[package_group_id] = 33
					AND ([wip_count_target].[name] LIKE '%MPmc~FL%' OR [wip_count_target].[name] LIKE '%DBmc~MP%' OR [wip_count_target].[name] LIKE '%AUTO4~TP%')
			) AS [data_gdic] ON [data_top].[package_id] = [data_gdic].[package_id]
				AND [data_top].[Top_id] = [data_gdic].[Top_id]
			--WHERE [data_top].[package_name] = 'SSOP-B20W'
		) AS [data_head],[APCSProDB].[trans].[days]
		WHERE ([days].[date_value] between @date_start and @date_end)
			AND [data_head].[package_id] = @package_id
		ORDER BY [data_head].[package_name],[data_head].[Top_id],[days].[date_value]
		


		select d_data.top_id 
			, date_value
			, for_date as date_value2
			, package_name
			, 'Act ' + items_name as items_name
			, ISNULL(d_temp.current_value,0) AS current_value
			, 'ALimit ' + items_name as items_name_limit
			, ISNULL(d_temp.target_value,ISNULL([monitoring_items].target_value,0)) AS target_value
			, @date_count as count_date
		from @tabledata2 as d_data
		left join (
			select monitoring_item_id, date ,  AVG(current_value) as current_value, AVG(target_value) as target_value
			from [APCSProDWH].[wip_control].[monitoring_item_records_temp]
			WHERE ([date] between @date_start and @date_end)
			GROUP BY monitoring_item_id, date
		) AS d_temp on d_data.items_id = d_temp.monitoring_item_id
			and d_data.date_value = d_temp.date
		left join [APCSProDWH].[wip_control].[monitoring_items] on d_data.items_id = [monitoring_items].id
		ORDER BY [package_name],[top_id],[date_value]
	END	
	ELSE IF (@version = 2)
	BEGIN
		------------------------------------------
		--- version 002
		------------------------------------------
		declare @tabledata3 table (
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

		insert into @table_hour (
			time
		)
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

		--select @date_count3

		INSERT INTO @tabledata3 
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
				FROM (
					SELECT id,name
					FROM [APCSProDB].[method].[packages]
					WHERE [packages].[id] = @package_id
				) as [master],(
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
				WHERE [packages].[package_group_id] = 33
					AND ([wip_count_target].[name] LIKE '%MPmc~FL%' OR [wip_count_target].[name] LIKE '%DBmc~MP%' OR [wip_count_target].[name] LIKE '%AUTO4~TP%')
			) AS [data_gdic] ON [data_top].[package_id] = [data_gdic].[package_id]
				AND [data_top].[Top_id] = [data_gdic].[Top_id]
			--WHERE [data_top].[package_name] = 'SSOP-B20W'
		) AS [data_head],@table_hour as [days]
		WHERE [data_head].[package_id] = @package_id


		select d_data.top_id 
			, date_value
			, for_date as date_value2
			, package_name
			, 'Act ' + items_name as items_name
			, ISNULL(d_temp.current_value,0) AS current_value
			, 'ALimit ' + items_name as items_name_limit
			, ISNULL(d_temp.target_value,ISNULL([monitoring_items].target_value,0)) AS target_value
			, @date_count3 as count_date
		from @tabledata3 as d_data
		left join (
			select monitoring_item_id, time,  AVG(current_value) as current_value, AVG(target_value) as target_value
			from [APCSProDWH].[wip_control].[monitoring_item_records_temp]
			WHERE ([date] = FORMAT(GETDATE(), 'yyyy-MM-dd'))
			GROUP BY monitoring_item_id, time
		) AS d_temp on d_data.items_id = d_temp.monitoring_item_id
			and d_data.for_date = d_temp.time
		left join [APCSProDWH].[wip_control].[monitoring_items] on d_data.items_id = [monitoring_items].id
		ORDER BY [package_name],[top_id],CAST(for_date AS INT)
	END	
END
