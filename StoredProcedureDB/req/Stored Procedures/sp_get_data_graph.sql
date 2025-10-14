
CREATE PROCEDURE [req].[sp_get_data_graph] 
	 @is_function	int			= 0		--0 : get data all -- 1 : filter by category, application and date -- 2 : filter by date
	,@start_date	date		= null
	,@end_date		date		= null
	,@emp_num		varchar(10)	= null
	,@category_id	int			= NULL
	,@app_id		int			= NULL
	,@groups_id		varchar(10)	= null
AS
BEGIN
	SET NOCOUNT ON;
	
	--IF (@start_date is null and @end_date is null)
	--BEGIN
	--	SET @start_date =  convert(date ,GETDATE())
	--	SET @end_date = convert(date ,GETDATE())
	--	print @start_date
	--	print @end_date
	--END
	declare  @groups_table Table ([id_groups] int)
		insert into @groups_table ([id_groups])
		select CAST(value as int)
		from string_split(@groups_id,',')

	IF (@is_function = 0) --get data all
	BEGIN
		SELECT [item_labels].[val] AS [state]
			,[item_labels].[label_eng] AS [state_name]
			,[item_labels].[color_code]
			,isnull(COUNT(Distinct [orders].[id]),0) AS [count]
			--,SUM(COUNT(CAST([orders].[state] AS INT)))  OVER() AS [totol_count]
		FROM [APCSProDWR].[req].[item_labels] 
		LEFT JOIN [APCSProDWR].[req].[orders] ON [orders].[state] = [item_labels].[val] 
		AND ((CONVERT(DATE, [orders].[requested_at]) BETWEEN convert(date,@start_date) AND convert(date,@end_date)) or (@start_date is null and @end_date is null))
		LEFT JOIN [APCSProDWR].[req].[group_application] ON [orders].[app_id] = [group_application].[application_id]
		LEFT JOIN [APCSProDWR].[req].[groups] ON [group_application].[group_id] = [groups].[id] AND [is_enable] = 1 
		where [item_labels].[name] = 'orders.state'
			and [item_labels].[val] IN (0,1,2,3,4,5)
			--and (@groups_id is null or [groups].[id] in (select [id_groups] from @groups_table))
		GROUP BY [val],[label_eng],[color_code]
		ORDER BY [val]
	END

	ELSE IF (@is_function = 1) --get data page management
	BEGIN
		Declare @emp_category INT, @emp_permission int;
		select @emp_category = [category_id] 
			,@emp_permission = [is_permission]
		From [APCSProDWR].[req].[users]
		inner join [APCSProDWR].[req].[inchanges] on [users].[id] = [inchanges].[inchange_by]
		where [users].[emp_num] = @emp_num

		SELECT [t_main].[state]
				, [t_main].[state_name]
				, [t_main].[color_code]
				, ISNULL([t_data].[count], 0) AS [count]
			FROM (
				SELECT [item_labels].[val] AS [state]
					,[item_labels].[label_eng] AS [state_name]
					,[item_labels].[color_code]
				FROM [APCSProDWR].[req].[item_labels]
				WHERE [item_labels].[name] = 'orders.state'
			) AS [t_main]
			left join (
				SELECT [item_labels].[val] AS [state]
					,[item_labels].[label_eng] AS [state_name]
					,[item_labels].[color_code]
					,isnull(COUNT(Distinct [orders].[id]),0) AS [count]
				FROM [APCSProDWR].[req].[item_labels] 
				LEFT JOIN [APCSProDWR].[req].[orders] ON [orders].[state] = [item_labels].[val] 
					AND ((CONVERT(DATE, [orders].[requested_at]) BETWEEN convert(date,@start_date) AND convert(date,@end_date)) or (@start_date is null and @end_date is null))
					AND [orders].[category_id] LIKE case when (@category_id = 0 or @category_id is null) then '%' else (CAST(@category_id AS varchar(2)) + '%') end 
					AND [orders].[app_id] LIKE case when (@app_id = 0 or @app_id is null) then '%' else (CAST(@app_id AS varchar(2)) + '%') end 
				LEFT JOIN [APCSProDWR].[req].[inchanges] ON [orders].[category_id] = [inchanges].[category_id] 
					AND [orders].[app_id] = [inchanges].[app_id] and [inchanges].[is_defult] = 1
				LEFT JOIN [APCSProDWR].[req].[users] us ON [inchanges].[inchange_by] = us.[id]
				LEFT JOIN [APCSProDWR].[req].[group_application] ON [orders].[app_id] = [group_application].[application_id]
				LEFT JOIN [APCSProDWR].[req].[groups] ON [group_application].[group_id] = [groups].[id] AND [is_enable] = 1 
				where [item_labels].[name] = 'orders.state'
					and [item_labels].[val] IN (0,1,2,3,4,5)
					and (@groups_id is null or [groups].[id] in (select [id_groups] from @groups_table))
				GROUP BY [val],[label_eng],[color_code]
			) as [t_data] ON [t_main].[state] = [t_data].[state]
			ORDER BY [t_main].[state]
	END
END