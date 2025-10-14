-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [req].[sp_get_filter]
	-- Add the parameters for the stored procedure here
	@filter			int			= 1 -- 1: categories, 2: subject, 3: inchanges, 4: appname
	,@category_id	int			= null
	,@appname_id	int			= null
	,@groups_id		varchar(10)	= NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	declare  @groups_table Table ([id_groups] int)
	insert into @groups_table ([id_groups])
	select CAST(value as int)
	from string_split(@groups_id,',')

    -- Insert statements for procedure here
	IF(@filter = 1)		--category
	BEGIN
		SELECT [categories].[id] AS [filter_id]
			, [categories].[name] AS [filter_name]
		FROM [APCSProDWR].[req].[categories]
		where [is_enable] = 1 
		ORDER BY (CASE WHEN [categories].[name] = 'Other' THEN 1 ELSE 0 END), [categories].[name] ASC
	END
	IF(@filter = 2)		--subject
	BEGIN
		SELECT [problems].[id] AS [filter_id]
			, [problems].[name] AS [filter_name]
		FROM [APCSProDWR].[req].[problems]
		where [is_enable] = 1
		order by [problems].[name] asc
	END
	IF(@filter = 3)
	BEGIN
		SELECT [inchanges].[category_id] AS [filter_id]
			, [inchanges].[inchange_by] AS [filter_name]
		FROM [APCSProDWR].[req].[inchanges]
		--order by [inchanges].[inchange_by] asc
	END
	IF(@filter = 4)		--application
	BEGIN
		if(@category_id != 0 and @appname_id = 0 )
		Begin
			SELECT [applications].[id] AS [filter_id]
				, [applications].[name] AS [filter_name]
				,[applications].[category_id]
				,[categories].[name] AS [category]
			FROM [APCSProDWR].[req].[applications]
			inner join [APCSProDWR].[req].[categories] on [categories].[id] = [applications].[category_id]
			inner join [APCSProDWR].[req].[group_application] on [applications].[id] = [group_application].[application_id]
			inner join [APCSProDWR].[req].[groups] on [groups].[id] = [group_application].[group_id] and [groups].[is_enable] = 1
			WHERE (@category_id is null or @category_id ='' or @category_id = 0) or ([categories].[id] = @category_id and [applications].[is_enable] = 1 and (@groups_id is null or [groups].[id] in (select [id_groups] from @groups_table))) 
			group by [applications].[id]
				, [applications].[name] 
				,[applications].[category_id]
				,[categories].[name]
			order by 
				case
					when [applications].[name] = 'Other' then 1
					else 0
				end,
			[applications].[name] asc
		end
		else if(@category_id = 0 and @appname_id != 0 )
		Begin
			SELECT [applications].[id] AS [filter_id]
					, [applications].[name] AS [filter_name]
					,[applications].[category_id]
					,[categories].[name] AS [category]
				FROM [APCSProDWR].[req].[applications]
				inner join [APCSProDWR].[req].[categories] on [categories].[id] = [applications].[category_id]
			inner join [APCSProDWR].[req].[group_application] on [applications].[id] = [group_application].[application_id]
			inner join [APCSProDWR].[req].[groups] on [groups].[id] = [group_application].[group_id] and [groups].[is_enable] = 1
				WHERE ([applications].[id] = @appname_id ) and [applications].[is_enable] = 1 and (@groups_id is null or [groups].[id] in (select [id_groups] from @groups_table))
				group by [applications].[id]
				, [applications].[name] 
				,[applications].[category_id]
				,[categories].[name]
				order by 
					case
						when [applications].[name] = 'Other' then 1
						else 0
					end,
				[applications].[name] asc
			End
		else if(@category_id = 0 and @appname_id = 0 )
		Begin
		SELECT [applications].[id] AS [filter_id]
				, [applications].[name] AS [filter_name]
				,[applications].[category_id]
				,[categories].[name] AS [category]
			FROM [APCSProDWR].[req].[applications]
			inner join [APCSProDWR].[req].[categories] on [categories].[id] = [applications].[category_id] 
			inner join [APCSProDWR].[req].[group_application] on [applications].[id] = [group_application].[application_id]
			inner join [APCSProDWR].[req].[groups] on [groups].[id] = [group_application].[group_id] and [groups].[is_enable] = 1
			WHERE ((@groups_id is null or [groups].[id] in (select [id_groups] from @groups_table)) and [applications].[is_enable] = 1) 
			group by [applications].[id]
				, [applications].[name] 
				,[applications].[category_id]
				,[categories].[name]
			order by 
				case
					when [applications].[name] = 'Other' then 1
					else 0
				end,
			[applications].[name] asc
		end
		--else
		--Begin
		--SELECT [applications].[id] AS [filter_id]
		--		, [applications].[name] AS [filter_name]
		--		,[applications].[category_id]
		--		,[categories].[name] AS [category]
		--	FROM [APCSProDWR].[req].[applications]
		--	inner join [APCSProDWR].[req].[categories] on [categories].[id] = [applications].[category_id] --and [applications].[is_enable] = 1
		--	inner join [APCSProDWR].[req].[group_application] on [applications].[id] = [group_application].[application_id]
		--	inner join [APCSProDWR].[req].[groups] on [groups].[id] = [group_application].[group_id] and [groups].[is_enable] = 1
		--	WHERE (@category_id is null and [applications].[is_enable] = 1) or (@category_id =''and [applications].[is_enable] = 1) or (@category_id = 0 and [applications].[is_enable] = 1) or ([categories].[id] = @category_id and [applications].[is_enable] = 1) 
		--	group by [applications].[id]
		--		, [applications].[name] 
		--		,[applications].[category_id]
		--		,[categories].[name]
		--	order by 
		--		case
		--			when [applications].[name] = 'Other' then 1
		--			else 0
		--		end,
		--	[applications].[name] asc
		--end
	END
	IF(@filter = 5)	--machines
	BEGIN
		--SELECT [id] AS [filter_id]
		--	,[name] AS [filter_name]
		--FROM [APCSProDB].[mc].[machines]
		--WHERE [name] <> 'ATOMMOVE'
		--order by [machines].[name] asc

		SELECT DISTINCT 0 AS [filter_id], [MachineNo] COLLATE SQL_Latin1_General_CP1_CI_AS AS [filter_name]
		FROM   [10.29.20.31].[TRProcessControl].[dbo].[MachineProcess]
		UNION ALL
		SELECT 0 AS [filter_id], [name] AS [filter_name]
		FROM  [APCSProDB].[mc].[machines]
		WHERE [name] != 'ATOMMOVE'
		order by [filter_name] asc
	END
	IF(@filter = 6)	 --Status
	BEGIN
		SELECT [val] AS [filter_id]
			,[label_eng] AS [filter_name]
		FROM [APCSProDWR].[req].[item_labels]
		WHERE [name] = 'orders.state'
		order by [item_labels].[label_eng] asc
	END
	IF(@filter = 7)  --Get Location
	BEGIN
		SELECT [locations].[id] AS [filter_id]
			,[locations].[name] + '-' + [locations].[address] AS [filter_name]
		FROM [APCSProDB].[trans].[locations] 
		inner join [APCSProDB].[man].[headquarters] on [locations].[headquarter_id] = [headquarters].[id]
		inner join [APCSProDB].[man].[factories] on [headquarters].[factory_id] = [factories].[id]
		WHERE [headquarter_id] = 1
		ORDER BY [locations].[name] ASC
	END
	IF(@filter = 8)  --Get Handler
	BEGIN
		SELECT [users].[id] AS [filter_id]
			,[users].[name] AS [filter_name]
		FROM [APCSProDWR].[req].[inchanges]
		inner join [APCSProDWR].[req].[users] on [inchanges].[inchange_by] = [users].[id]
		WHERE [inchanges].[category_id] = @category_id
		order by [users].[name] asc
	END
	IF(@filter = 9)  --Get Group 
	BEGIN
		SELECT [groups].[id] AS [filter_id]
			,[groups].[name] AS [filter_name]
		FROM [APCSProDWR].[req].[groups]
		where [groups].[is_enable] = 1
		order by [groups].[name] asc
	END
END