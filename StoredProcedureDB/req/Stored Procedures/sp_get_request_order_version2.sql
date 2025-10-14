
CREATE PROCEDURE [req].[sp_get_request_order_version2] --edit by far #2025/02/13 09.37
	  @is_function	int				= NULL  --# 0 (Get all data), # 1 (Get data for history status), # 2(Get data for notification)
	, @order_no		varchar(11)		= '%'
	, @groups_id	varchar(10)		= NULL
	, @category_id	int				= NULL
	, @subject_id	int				= NULL
	, @order_status varchar(2)		= NULL
	, @start_date	DATE			= NULL
	, @end_date		DATE			= NULL
	, @emp_num		NVARCHAR(10)	= NULL
	, @app_id		int				= NULL  --add parameter 
	, @page			int				= null	--# 0 dashboard page, # 1 management page #2025/02/20 16.40 far

AS
BEGIN
	SET NOCOUNT ON;
	
	SET @order_no = IIF(@order_no = '','%', @order_no);
	SET @category_id = IIF(@category_id = 0,null  , @category_id);
	SET @subject_id = IIF(@subject_id = 0,null, @subject_id);
	SET @app_id = IIF(@app_id = 0,null, @app_id);

	DECLARE @datetime DATE
	SET @datetime = GETDATE()

	declare  @groups_table Table ([id_groups] int)
	insert into @groups_table ([id_groups])
	select CAST(value as int)
	from string_split(@groups_id,',')

	print @datetime
	IF (@is_function = 0) --Get table data 
	BEGIN
		IF(@page =1)	--management page
		BEGIN
			SELECT [orders].[order_no] 
				, [orders].[problem_request]
				, [groups].[groups_id]
				, [groups].[groups_name]
				, [categories].[id] AS [category_id]
				, [categories].[name] AS [category]
				, [problems].[id] AS [problem_id]
				, [problems].[name] AS [problem] --Subject
				, [applications].[id] AS [application_id]
				, [applications].[name] AS [application]
				, [orders].[other_detail_1] AS [item_1]
				, [orders].[other_detail_2] AS [item_2]
				, [orders].[priority]
				, [orders].[state]
				, [item_labels].[label_eng] AS [state_name]
				, [orders].[problem_solve]
				, [orders].[comment_by_requested] AS  [comment_requested]
				, [orders].[comment_by_system] AS  [comment_by_system]
				, [location_id]
				, [locations].[name] + '-' + [locations].[address] AS [location]
				, [orders].[area]
				, [orders].[file_path]
				, NULL AS [image_1]
				, NULL AS [image_2]
				, NULL AS [image_3]
				, NULL AS [image_4]
				, [users].[id] AS [requested_id]
				, [users].[name] + ' ('+ [users].[emp_num] + ')' AS [requested_by]
				, [us].[name] AS [incharge_by]
				, [orders].[inchange_by] as [handler_id]
				, get_handle.[name] AS [handler_by]
				, [orders].[requested_at]
				, [item_labels].color_code
				, (CASE WHEN [orders].[state] = 3 THEN 0 ELSE DATEDIFF(DAY, [orders].[requested_at], GETDATE()) END) AS [Delays]
				, [orders].[requested_tel]
				, [orders].[solved_at]
			FROM [APCSProDWR].[req].[orders]
			LEFT JOIN [APCSProDWR].[req].[categories] ON [orders].[category_id] = [categories].[id]
			LEFT JOIN [APCSProDWR].[req].[problems] ON [orders].[problem_id] = [problems].[id]
			LEFT JOIN [APCSProDWR].[req].[applications] ON [orders].[app_id] = [applications].[id]
			--LEFT JOIN [APCSProDWR].[req].[images] ON [orders].[id] = [images].[order_id]
			LEFT JOIN [APCSProDWR].[req].[users] ON [orders].[requested_by] = [users].[id]
			LEFT JOIN [APCSProDWR].[req].[item_labels] ON [orders].[state] = [item_labels].[val]
				AND [item_labels].[name] = 'orders.state'
			LEFT JOIN [APCSProDWR].[req].[inchanges] ON [orders].[category_id] = [inchanges].[category_id] 
				AND [orders].[app_id] = [inchanges].[app_id] 
				AND [inchanges].[is_defult] = 1
			LEFT JOIN [APCSProDWR].[req].[users] AS [us] ON [inchanges].[inchange_by] = [us].[id]
			LEFT JOIN [APCSProDWR].[req].[users] AS [get_handle] ON [orders].[inchange_by] = [get_handle].[id]
			LEFT JOIN [APCSProDB].[trans].[locations] ON [locations].[id] = [orders].[location_id] 
				AND [locations].[headquarter_id] = 1
			OUTER APPLY (
				SELECT TOP 1 [groups].[id] as [groups_id]
					, [groups].[name] AS [groups_name]
				FROM [APCSProDWR].[req].[group_application] 
				INNER JOIN [APCSProDWR].[req].[groups] ON [groups].[id] = [group_application].[group_id]
				LEFT JOIN @groups_table AS [tb] ON [groups].[id] = [tb].[id_groups]
				WHERE [group_application].[application_id] = [orders].[app_id]
					AND ([tb].[id_groups] IS NOT NULL OR @groups_id IS NULL)
			) AS [groups]
			WHERE ([orders].[order_no] = @order_no and @order_no is not null) 
				or (([groups].[groups_id] IS NOT NULL OR @groups_id IS NULL)
				AND ([orders].[order_no] = @order_no OR @order_no = '%' OR @order_no IS NULL)
				AND ([categories].[id] = @category_id OR @category_id IS NULL) 
				AND ([problems].[id] = @subject_id OR @subject_id IS NULL)
				AND ([applications].[id] = @app_id OR @app_id IS NULL)
				AND ([orders].[state] = @order_status OR @order_status = '%' OR @order_status IS NULL)
				AND (
					(CONVERT(DATE, [orders].[requested_at]) BETWEEN @start_date AND @end_date) 
					OR (@start_date IS NULL AND @end_date IS NULL)
				))
			ORDER BY [orders].[priority] DESC,[orders].[requested_at] DESC
		END
		ELSE	--dashboard page
		BEGIN
			SELECT [orders].[order_no] 
				, [orders].[problem_request]
				, [groups].[groups_id]
				, [groups].[groups_name]
				, [categories].[id] AS [category_id]
				, [categories].[name] AS [category]
				, [problems].[id] AS [problem_id]
				, [problems].[name] AS [problem] --Subject
				, [applications].[id] AS [application_id]
				, [applications].[name] AS [application]
				, [orders].[other_detail_1] AS [item_1]
				, [orders].[other_detail_2] AS [item_2]
				, [orders].[priority]
				, [orders].[state]
				, [item_labels].[label_eng] AS [state_name]
				, [orders].[problem_solve]
				, [orders].[comment_by_requested] AS  [comment_requested]
				, [orders].[comment_by_system] AS  [comment_by_system]
				, [location_id]
				, [locations].[name] + '-' + [locations].[address] AS [location]
				, [orders].[area]
				, [orders].[file_path]
				, NULL AS [image_1]
				, NULL AS [image_2]
				, NULL AS [image_3]
				, NULL AS [image_4]
				, [users].[id] AS [requested_id]
				, [users].[name] + ' ('+ [users].[emp_num] + ')' AS [requested_by]
				, [us].[name] AS [incharge_by]
				, [orders].[inchange_by] as [handler_id]
				, get_handle.[name] AS [handler_by]
				, [orders].[requested_at]
				, [item_labels].color_code
				, (CASE WHEN [orders].[state] = 3 THEN 0 ELSE DATEDIFF(DAY, [orders].[requested_at], GETDATE()) END) AS [Delays]
				, [orders].[requested_tel]
				, [orders].[solved_at]
			FROM [APCSProDWR].[req].[orders]
			LEFT JOIN [APCSProDWR].[req].[categories] ON [orders].[category_id] = [categories].[id]
			LEFT JOIN [APCSProDWR].[req].[problems] ON [orders].[problem_id] = [problems].[id]
			LEFT JOIN [APCSProDWR].[req].[applications] ON [orders].[app_id] = [applications].[id]
			--LEFT JOIN [APCSProDWR].[req].[images] ON [orders].[id] = [images].[order_id]
			LEFT JOIN [APCSProDWR].[req].[users] ON [orders].[requested_by] = [users].[id]
			LEFT JOIN [APCSProDWR].[req].[item_labels] ON [orders].[state] = [item_labels].[val]
				AND [item_labels].[name] = 'orders.state'
			LEFT JOIN [APCSProDWR].[req].[inchanges] ON [orders].[category_id] = [inchanges].[category_id] 
				AND [orders].[app_id] = [inchanges].[app_id] 
				AND [inchanges].[is_defult] = 1
			LEFT JOIN [APCSProDWR].[req].[users] AS [us] ON [inchanges].[inchange_by] = [us].[id]
			LEFT JOIN [APCSProDWR].[req].[users] AS [get_handle] ON [orders].[inchange_by] = [get_handle].[id]
			LEFT JOIN [APCSProDB].[trans].[locations] ON [locations].[id] = [orders].[location_id] 
				AND [locations].[headquarter_id] = 1
			OUTER APPLY (
				SELECT TOP 1 [groups].[id] as [groups_id]
					, [groups].[name] AS [groups_name]
				FROM [APCSProDWR].[req].[group_application] 
				INNER JOIN [APCSProDWR].[req].[groups] ON [groups].[id] = [group_application].[group_id]
				LEFT JOIN @groups_table AS [tb] ON [groups].[id] = [tb].[id_groups]
				WHERE [group_application].[application_id] = [orders].[app_id]
					AND ([tb].[id_groups] IS NOT NULL OR @groups_id IS NULL)
			) AS [groups]
			WHERE ([orders].[order_no] = @order_no and @order_no is not null) 
				or (([groups].[groups_id] IS NOT NULL OR @groups_id IS NULL)
				AND ([orders].[order_no] = @order_no OR @order_no = '%' OR @order_no IS NULL)
				AND ([categories].[id] = @category_id OR @category_id IS NULL) 
				AND ([problems].[id] = @subject_id OR @subject_id IS NULL)
				AND ([applications].[id] = @app_id OR @app_id IS NULL)
				AND ([orders].[state] = @order_status OR @order_status = '%' OR @order_status IS NULL)
				AND (
					(CONVERT(DATE, [orders].[requested_at]) BETWEEN @start_date AND @end_date) 
					OR (@start_date IS NULL AND @end_date IS NULL)
				))
			ORDER BY [orders].[priority] DESC,[orders].[requested_at] ASC
		END
	END
	
	ELSE IF (@is_function = 1) --Get data for history status
	BEGIN
		SELECT [orders].[order_no] AS [order_no]
			, [orders].[problem_request] AS [problem_request]
			, [categories].[id] AS [category_id]
			, [categories].[name] AS [category]
			, [problems].[id] AS [problem_id]
			, [problems].[name] AS [problem]  --Subject
			, [applications].[id] AS [application_id]
			, [applications].[name] AS [application]
			, [orders].[other_detail_1] AS [item_1]
			, [orders].[other_detail_2] AS [item_2]
			, [orders].[priority]
			, [orders].[state]
			, [item_labels].[label_eng] AS [state_name]
			, [order_records].[state] as [history_state]
			, [orders].[problem_solve]
			, [orders].[comment_by_requested] AS  [comment_requested]
			, [orders].[comment_by_system] AS  [comment_by_system]
			, [order_records].[comment_by_requested] AS [history_comment_by_user]
			, [order_records].[comment_by_system] AS [history_comment_by_system]
			, [orders].[location_id]
			, [locations].[name] + '-' + [locations].[address] AS [location]
			, [orders].[area]
			, [orders].[file_path]
			, [images].[image_1]
			, [images].[image_2]
			, [images].[image_3]
			, [images].[image_4]
			, [users].[id] AS [requested_id]
			, [users].[name] +' ('+ [users].[emp_num] + ')' AS [requested_by]
			, us.[name] AS [incharge_by]
			, [orders].[inchange_by] as [handler_id]
			, get_handle.[name] AS [handler_by]
			, [orders].[requested_at]
			, [item_labels].color_code
			, (CASE WHEN [orders].[state] = 3 THEN 0 ELSE DATEDIFF(DAY, [orders].[requested_at], GETDATE()) END) As Delays
			, [orders].[requested_tel]
			, [orders].[solved_at] 
			, [order_records].[record_at]
			, us_history.[name] as [solved_by]
			, us_history.[is_permission] as [solved_per]
		FROM [APCSProDWR].[req].[orders]
		LEFT JOIN [APCSProDWR].[req].[categories] ON [orders].[category_id] = [categories].[id]
		LEFT JOIN [APCSProDWR].[req].[problems] ON [orders].[problem_id] = [problems].[id]
		LEFT JOIN [APCSProDWR].[req].[applications] ON [orders].[app_id] = [applications].[id]
		LEFT JOIN [APCSProDWR].[req].[images] ON [orders].[id] = [images].[order_id]
		LEFT JOIN [APCSProDWR].[req].[users] ON [orders].[requested_by] = [users].[id]
		LEFT JOIN [APCSProDWR].[req].[item_labels] ON [item_labels].[name] = 'orders.state'
			AND [orders].[state] = [item_labels].[val]
		LEFT JOIN [APCSProDWR].[req].[inchanges] on [orders].[category_id] = [inchanges].[category_id] 
			AND [orders].[app_id] = [inchanges].[app_id] AND [inchanges].[is_defult] = 1
		LEFT JOIN [APCSProDWR].[req].[users] us ON [inchanges].[inchange_by] = us.[id]
		LEFT JOIN [APCSProDWR].[req].[users] get_handle ON [orders].[inchange_by] = get_handle.[id]
		LEFT JOIN [APCSProDB].[trans].[locations] ON [locations].[id] = [orders].[location_id] AND [locations].[headquarter_id] = 1
		Left join [APCSProDWR].[req].[order_records] on [orders].[id] = [order_records].[order_id]
		Left join [APCSProDWR].[req].[users] us_history on [order_records].[solved_by] = us_history.[id]
		WHERE ([orders].[order_no] = @order_no OR @order_no = '%')
		--AND [categories].[id]  LIKE ISNULL(CAST(@category_id AS varchar(2)), '%')
		--AND [problems].[id] LIKE ISNULL(CAST(@subject_id AS varchar(2)), '%')
		--AND [applications].[id] LIKE ISNULL(CAST(@app_id AS varchar(2)), '%')  --new add row
		--AND [orders].[state] LIKE ISNULL(CAST(@order_status AS varchar(2)), '%')
		----AND (CONVERT(DATE, orders.requested_at) BETWEEN ISNULL(@start_date,CONVERT(DATE,@datetime)) AND ISNULL(@end_date,CONVERT(DATE,@datetime)))
		--AND ((CONVERT(DATE, orders.requested_at) BETWEEN @start_date AND @end_date) or (@start_date Is null and @end_date Is null))
		group by [orders].[order_no]
		, [orders].[problem_request]
		, [categories].[id]
		, [categories].[name]
		, [problems].[id]
		, [problems].[name]
		, [applications].[id]
		, [applications].[name]
		, [orders].[other_detail_1]
		, [orders].[other_detail_2]
		, [orders].[priority]
		, [orders].[state]
		, [item_labels].[label_eng]
		, [order_records].[state]
		, [orders].[problem_solve]
		, [orders].[comment_by_requested] 
		, [orders].[comment_by_system]
		, [order_records].[comment_by_requested]
		, [order_records].[comment_by_system]
		, [orders].[location_id]
		, [locations].[name] + '-' + [locations].[address] 
		, [orders].[area]
		, [orders].[file_path]
		, [images].[image_1]
		, [images].[image_2]
		, [images].[image_3]
		, [images].[image_4]
		, [users].[id] 
		, [users].[name] +' ('+ [users].[emp_num] + ')'
		, us.[name] 
		, [orders].[inchange_by] 
		, get_handle.[name] 
		, [orders].[requested_at]
		, [item_labels].color_code
		, [orders].[requested_tel]
		, [orders].[solved_at] 
		, [order_records].[record_at]
		, us_history.[name]
		, us_history.[is_permission]
		order by
		[order_records].[record_at] asc
	END
	ELSE IF (@is_function = 2) --notification
	BEGIN
		Declare @emp_permission INT, @emp_id INT, @emp_category int;
		select @emp_category = [category_id] 
			,@emp_permission = [is_permission]
			,@emp_id = [users].[id]
		From [APCSProDWR].[req].[users]
		left join [APCSProDWR].[req].[inchanges] on [users].[id] = [inchanges].[inchange_by]
		--inner join [APCSProDWR].[req].[item_labels] on [users].[is_permission] = [item_labels].[val]
		where [users].[emp_num] = @emp_num

		if(@emp_permission = 1)
		BEGIN
			SELECT [orders].[order_no] 
				, [orders].[priority]
				, [orders].[state]
				, [item_labels].[label_eng] AS [state_name]
				, [item_labels].[color_code]
				, [users].[id] AS [requested_id]
				, [users].[name] AS [requested_by]
				, [orders].[inchange_by] as [handler_id]
				, us_handle.[name] AS [handler_by]
				,[orders].[category_id]
				,[categories].[name] as [category]
				,[orders].[problem_id] 
				,[problems].[name] as [problem]
				,[orders].[problem_request]
				, [orders].[requested_at]
				--, [orders].[requested_tel]
				--,datediff(minute,orders.requested_at,GETDATE()) as [delays_min]
				,datediff(minute,orders.requested_at,GETDATE()) / 1440 as [delays_d] ---days
				,(datediff(minute,orders.requested_at,GETDATE()) / 60) % 24 as [delays_h] ---hour
				,datediff(minute,orders.requested_at,GETDATE()) % 60 as [delays_m] ---minutes
				, [orders].[solved_at]		--add #2025/02/27 9.38 far
			FROM [APCSProDWR].[req].[orders]
			LEFT JOIN [APCSProDWR].[req].[categories] ON [orders].[category_id] = [categories].[id]
			LEFT JOIN [APCSProDWR].[req].[problems] ON [orders].[problem_id] = [problems].[id]
			LEFT JOIN [APCSProDWR].[req].[applications] ON [orders].[app_id] = [applications].[id]
			LEFT JOIN [APCSProDWR].[req].[images] ON [orders].[id] = [images].[order_id]
			LEFT JOIN [APCSProDWR].[req].[users] ON [orders].[requested_by] = [users].[id]
			LEFT JOIN [APCSProDWR].[req].[item_labels] ON [item_labels].[name] = 'orders.state'
				AND [orders].[state] = [item_labels].[val]
			left join [APCSProDWR].[req].[inchanges] on [orders].[category_id] = [inchanges].[category_id] 
				--And [orders].[app_id] = [inchanges].[app_id] and [inchanges].[is_defult] = 1
			left join [APCSProDWR].[req].[users] us_inchange ON [inchanges].[inchange_by] = us_inchange.[id]
			left join [APCSProDWR].[req].[users] us_handle ON [orders].[inchange_by] = us_handle.[id]
			WHERE 
			([orders].[state] like 0 and [inchanges].[inchange_by] = @emp_id)
			or ([orders].[state] in (0,1,2,5) and [orders].[inchange_by] = @emp_id)		--add #2025/03/07 14.38 far
			group by [orders].[order_no] 
				, [orders].[priority]
				, [orders].[state]
				, [item_labels].[label_eng] 
				, [item_labels].[color_code]
				, [users].[id] 
				, [users].[name] 
				, [orders].[inchange_by] 
				, us_handle.[name] 
				,[orders].[category_id]
				,[categories].[name]
				,[orders].[problem_id] 
				,[problems].[name] 
				,[orders].[problem_request]
				, [orders].[requested_at]
				, [orders].[solved_at]	
			ORDER BY [orders].[priority] DESC, [delays_d],[delays_h],[delays_m] ASC
		END

		if(@emp_permission = 0 or @emp_permission = 2)
		BEGIN
			SELECT [orders].[order_no] 
				, [orders].[priority]
				, [orders].[state]
				, [item_labels].[label_eng] AS [state_name]
				, [item_labels].[color_code]
				, [users].[id] AS [requested_id]
				, [users].[name] AS [requested_by]
				, [orders].[inchange_by] as [handler_id]
				, us_handle.[name] AS [handler_by]
				,[orders].[category_id]
				,[categories].[name] as [category]
				,[orders].[problem_id] 
				,[problems].[name] as [problem]
				,[orders].[problem_request]
				, [orders].[requested_at]
				--, [orders].[requested_tel]
				,datediff(minute,orders.requested_at,GETDATE()) / 1440 as [delays_d] ---days
				,(datediff(minute,orders.requested_at,GETDATE()) / 60) % 24 as [delays_h] ---hour
				,datediff(minute,orders.requested_at,GETDATE()) % 60 as [delays_m] ---minutes
				, [orders].[solved_at]
			FROM [APCSProDWR].[req].[orders]
			LEFT JOIN [APCSProDWR].[req].[categories] ON [orders].[category_id] = [categories].[id]
			LEFT JOIN [APCSProDWR].[req].[problems] ON [orders].[problem_id] = [problems].[id]
			LEFT JOIN [APCSProDWR].[req].[applications] ON [orders].[app_id] = [applications].[id]
			LEFT JOIN [APCSProDWR].[req].[images] ON [orders].[id] = [images].[order_id]
			LEFT JOIN [APCSProDWR].[req].[users] ON [orders].[requested_by] = [users].[id]
			LEFT JOIN [APCSProDWR].[req].[item_labels] ON [item_labels].[name] = 'orders.state'
				AND [orders].[state] = [item_labels].[val]
			left join [APCSProDWR].[req].[inchanges] on [orders].[category_id] = [inchanges].[category_id] 
				And [orders].[app_id] = [inchanges].[app_id] and [inchanges].[is_defult] = 1
			left join [APCSProDWR].[req].[users] us_inchange ON [inchanges].[inchange_by] = us_inchange.[id]
			left join [APCSProDWR].[req].[users] us_handle ON [orders].[inchange_by] = us_handle.[id]
			left join (
				Select order_id , max(record_at) as last_record
				from [APCSProDWR].[req].[order_records]
				group by order_id
			) records on [orders].id = records.order_id
			WHERE 
			[orders].[state] in (1 ,2, 3, 4, 5)
			and [orders].[requested_by] = @emp_id
			ORDER BY records.last_record DESC
		END
	END
	ELSE IF (@is_function = 3) --Get Data show on report #create at 2025/05/06 time : 10.39 by Aomsin
	BEGIN
		SELECT [A2].*
			, [categories].[name] AS [categories_name]
			, [problems].[name] AS [subject_name]
			, [applications].[name] AS [application_name]
			, [orders].[requested_at] AS [request_date]
			, [users].[name] + ' ('+ [users].[emp_num] + ')' AS [requested_by]
			, [locations].[name] + '-' + [locations].[address] AS [location]
			, ISNULL([orders].[area],'')  AS [area]
			, ISNULL([orders].[problem_request],'') AS [problem]
			, ISNULL([orders].[problem_solve],'') AS [solution]
			, ISNULL([orders].[comment_by_system],'') AS [result]
			, '' AS [image_path_1]
			, '' AS [image_path_2]
			, '' AS [image_path_3]
			, '' AS [image_path_4]
		FROM [APCSProDWR].[req].[orders]
		LEFT JOIN [APCSProDWR].[req].[categories] ON [orders].[category_id] = [categories].[id]
		LEFT JOIN [APCSProDWR].[req].[problems] ON [orders].[problem_id] = [problems].[id]
		LEFT JOIN [APCSProDWR].[req].[applications] ON [orders].[app_id] = [applications].[id]
		LEFT JOIN [APCSProDWR].[req].[users] ON [orders].[requested_by] = [users].[id]
		LEFT JOIN [APCSProDWR].[req].[users] AS [get_handle] ON [orders].[inchange_by] = [get_handle].[id]
		LEFT JOIN [APCSProDB].[trans].[locations] ON [locations].[id] = [orders].[location_id] 
			AND [locations].[headquarter_id] = 1
		LEFT JOIN [APCSProDWR].[req].[images] ON [orders].[id] = [images].[order_id]
		CROSS APPLY (
			SELECT [T2].[request_no]
				, MAX(CASE WHEN [T2].[label_eng] = 'Wip' then [request_name_by] end) AS [requestor]
				, MAX(CASE WHEN [T2].[label_eng] = 'Wip' then FORMAT([record_at],'yy.M.dd') end) AS [requestor_at]
				, ISNULL(MAX(CASE WHEN [T2].[label_eng] = 'Do' then [solved_name_by] end),MAX(CASE WHEN [T2].[label_eng] = 'Complete' then [solved_name_by] end)) AS [approve1]
				, ISNULL(MAX(CASE WHEN [T2].[label_eng] = 'Do' then  FORMAT([solved_at],'yy.M.dd') end),MAX(CASE WHEN [T2].[label_eng] = 'Complete' then FORMAT([solved_at],'yy.M.dd') end)) AS [solved_at_1]
				, MAX(CASE WHEN [T2].[label_eng] = 'Complete' then [solved_name_by] end) AS [approve2]
				, MAX(CASE WHEN [T2].[label_eng] = 'Complete' then FORMAT([solved_at],'yy.M.dd') end) AS [solved_at_2]
			FROM (
				SELECT [record].[order_no] AS [request_no]
					, [label_eng]
					, [users].[name] AS [request_name_by]
					, [user_2].[name] AS [solved_name_by]
					, [record].[record_at] 
					, [record].[solved_at] 
				FROM  [APCSProDWR].[req].[order_records] AS [record]
				LEFT JOIN [APCSProDWR].[req].[users] ON [record].[requested_by] = [users].[id]
				LEFT JOIN [APCSProDWR].[req].[users] AS [user_2] ON [record].[solved_by] = [user_2].[id]
				LEFT JOIN [APCSProDWR].[req].[item_labels] ON [record].[state] = [item_labels].[val]
					AND [item_labels].[name] = 'orders.state'
				WHERE [record].[order_no] = [orders].[order_no] 
			) AS [T2]
			GROUP BY [T2].[request_no]
		) AS [A2]
		WHERE [orders].[order_no] = @order_no
	END
END
