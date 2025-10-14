-- =============================================
-- Author:		<Author,,Name : Vanatjaya P. (009131)>
-- Create date: <Create Date,,>
-- Last Update date: <Update Date,2024-11-21, Time : 17.20>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[get_hasuu_data_for_graph] 
	-- Add the parameters for the stored procedure here
	  @is_function int = null --(1 : Get All Package, 2 : Get Package only, 3 : Get Color only)
	, @package_group varchar(20) = ''

AS
BEGIN
    -- Insert statements for procedure here
	 INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	 ([record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text])
	 SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[get_hasuu_data_for_graph]'

	IF @is_function = 2
	BEGIN
		SELECT TOP 15 [table_p].[package_name]
			, SUM(ISNULL([table_p].[hasuu_now], 0)) AS [hasuu_now]
			, SUM(ISNULL([table_p].[hasuu_long], 0)) AS [hasuu_long]
			, SUM(ISNULL([table_p].[unavailable], 0)) AS [unavailable]
		FROM (
			SELECT [package_group_name]
				, [package_name]
				, [device_name] 
				, [qty]
				, [type]
			FROM (
				--hasuu_now
				SELECT [pk_g].[name] as [package_group_name]
					,[pk].[short_name] as [package_name]
					, [dv].[name] as [device_name] 
					, [dv].[rank_value] as [rank]
					, [sur].[qc_instruction] 
					, SUM([sur].[pcs]) as [qty]
					, SUM([sur].[pcs])/([dv].[pcs_per_pack]) as [count_reel]
					, COUNT([sur].[serial_no]) as [count_lot]
					, 'hasuu_now' AS [type]
				FROM [APCSProDB].[trans].[surpluses] as [sur]
				INNER JOIN [APCSProDB].[trans].[lots] as [lot] on [sur].[lot_id] = [lot].[id]
				INNER JOIN (
					SELECT CASE WHEN [dv1].[rank] IS NULL THEN '' ELSE [dv1].[rank] END AS [rank_value],* 
					FROM [APCSProDB].[method].[device_names] AS [dv1]
				) AS [dv] ON [lot].[act_device_name_id] = [dv].[id]
				INNER JOIN [APCSProDB].[method].[packages] AS [pk] ON [dv].[package_id] = [pk].[id]
				INNER JOIN [APCSProDB].[method].[package_groups] AS [pk_g] ON [pk].[package_group_id] = [pk_g].[id]
				LEFT JOIN [APCSProDB].[trans].[locations] AS [locat] ON [sur].[location_id] = [locat].[id]
				WHERE ([sur].[location_id] IS NOT NULL AND [sur].[location_id] != 0)
					AND ([lot].[wip_state] = 20 OR [lot].[wip_state] = 70 OR [lot].[wip_state] = 100)
					AND [lot].[quality_state] = 0
					AND [sur].[in_stock] = 2 
					AND (SUBSTRING([sur].[serial_no],1,2) >= FORMAT(GETDATE(),'yy') - 3 or [sur].[is_ability] = 1) 
					AND SUBSTRING([sur].[serial_no],5,1) !='E' 
					AND (SUBSTRING([sur].[serial_no],5,1) !='G'  
						OR (SUBSTRING([serial_no],5,1) = 'G' and [dv].[name] in ('SV013-HE2           ','SV131-HE2           ','SV014-HE2           ','SV010-HE2           ','BV2HC045EFU-C       ','BV2HD045EFU-CE2     ','BV2HD070EFU-CE2    ','BV2HC045EFU-CE2     ')) 
						)
					AND ([pk_g].[name] = @package_group OR @package_group = '%')
				GROUP BY [pk].[short_name],[dv].[name],[dv].[rank_value],[dv].[pcs_per_pack],[pk_g].[name],[sur].[qc_instruction]
				Having SUM([sur].[pcs]) >= [dv].[pcs_per_pack] 
					and SUM([sur].[pcs])/(NULLIF([dv].[pcs_per_pack], 0)) >= 1
			) AS [hasuu_now]
			UNION ALL
			-- hasuu_long
			SELECT [package_group_name]
				, [package_name]
				, [device_name] 
				, [qty]
				, [type]
			FROM (
				SELECT [pk_g].[name] as [package_group_name]
					, [pk].[short_name] as [package_name]
					, [dv].[name] as [device_name]
					, [dv].[rank_value] as [rank]
					, [sur].[qc_instruction] 
					, SUM([sur].[pcs]) as [qty]
					, SUM([sur].[pcs])/([dv].[pcs_per_pack]) as [count_reel]
					, COUNT([sur].[serial_no]) as [count_lot]
					, 'hasuu_long' AS [type]
				FROM  [APCSProDB].[trans].[surpluses] as sur
				INNER JOIN [APCSProDB].[trans].[lots] as [lot] on [sur].[lot_id] = [lot].[id]
				INNER JOIN (
					SELECT case when [dv1].[rank] is null then '' else [dv1].[rank] end As [rank_value],* 
					FROM [APCSProDB].[method].[device_names] as [dv1]
				) AS [dv] ON [lot].[act_device_name_id] = [dv].[id]
				INNER JOIN [APCSProDB].[method].[packages] as [pk] on [dv].[package_id] = [pk].[id]
				INNER JOIN [APCSProDB].[method].[package_groups] as [pk_g] on [pk].[package_group_id] = [pk_g].[id]
				LEFT JOIN [APCSProDB].[trans].[locations] as [locat] on [sur].[location_id] = [locat].[id]
				WHERE ([sur].[location_id] IS NOT NULL and [sur].[location_id] != 0)
					AND [lot].[quality_state] = 0
					AND [sur].[pcs] != 0
					AND CAST((FORMAT(GETDATE(),'yy')) AS INT) - CAST((SUBSTRING([sur].[serial_no],1,2)) AS INT) >= 3
					AND ([pk_g].[name] = @package_group OR @package_group = '%')
				GROUP BY [pk].[short_name], [dv].[name],[dv].[rank_value], [dv].[pcs_per_pack], [pk_g].[name], [sur].[qc_instruction]
				HAVING SUM([sur].[pcs]) >= [dv].[pcs_per_pack] 
			) AS [hasuu_long]
			UNION ALL
			-- unavailable
			SELECT [package_group_name]
				, [package_name]
				, [device_name] 
				, [qty]
				, [type]
			FROM (
				SELECT [pk_g].[name] as [package_group_name]
					, [pk].[short_name] as [package_name]
					, [dv].[name] as [device_name]
					, SUM([sur].[pcs]) as [QTY]
					, SUM([sur].[pcs])/([dv].[pcs_per_pack]) as [count_reel]
					, COUNT([sur].[serial_no]) as [count_lot]
					, [dv].[pcs_per_pack]
					, 'unavailable' AS [type]
				FROM  [APCSProDB].[trans].[surpluses] as [sur]
				INNER JOIN [APCSProDB].[trans].[lots] as [lot] on [sur].[lot_id] = [lot].[id]
				INNER JOIN (
					SELECT case when [dv1].[rank] is null then '' else [dv1].[rank] end As [rank_value],* 
					FROM [APCSProDB].[method].[device_names] as [dv1]
				) AS [dv] ON [lot].[act_device_name_id] = [dv].[id]
				INNER JOIN [APCSProDB].[method].[packages] as [pk] on [dv].[package_id] = [pk].[id]
				INNER JOIN [APCSProDB].[method].[package_groups] as [pk_g] on [pk].[package_group_id] = [pk_g].[id]
				LEFT JOIN [APCSProDB].[trans].[locations] as [locat] on [sur].[location_id] = [locat].[id]
				WHERE ([sur].[location_id] IS NULL 
					AND [sur].[in_stock] IN (2,3)
					OR [lot].[quality_state] <> 0)
					AND ([pk_g].[name] = @package_group OR @package_group = '%')
				GROUP BY [pk].[short_name],[dv].[name],[dv].[rank_value],[dv].[pcs_per_pack],[pk_g].[name],[sur].[qc_instruction]
				HAVING SUM([sur].[pcs]) < [dv].[pcs_per_pack]
			) AS [unavailable]
		) AS [table_1]
		PIVOT 
		(
			SUM([qty])
			FOR [type] IN ([hasuu_now], [hasuu_long], [unavailable])
		) AS [table_p]
		GROUP BY [package_name]
		ORDER BY [hasuu_now] DESC--, [hasuu_long], [unavailable] DESC
	END
	ELSE IF @is_function = 1
	BEGIN
		DECLARE @datetime DATETIME
		DECLARE @year_now int = 0
		SET @datetime = GETDATE()
		
		SELECT @year_now = (FORMAT(@datetime,'yy'))

		SELECT [master].[package_group_name] AS [PKG]
			, ISNULL([hasuu_now].[QTY_HASUU_NOW], 0) AS [HasuuNow]
			, ISNULL([hasuu_long].[qty_hasuu_long], 0) AS [HasuuLong]
			, ISNULL([unavailable].[Unavailable], 0) AS [Unavailable]
		FROM (
			SELECT 'GDIC' AS [package_group_name]
			UNION
			SELECT 'MAP' AS [package_group_name]
			UNION
			SELECT 'POWER' AS [package_group_name]
			UNION
			SELECT 'QFP' AS [package_group_name]
			UNION
			SELECT 'SMALL' AS [package_group_name]
			UNION
			SELECT 'SOP' AS [package_group_name]   
		) AS [master]
	
		---- now
		LEFT JOIN (
		--	SELECT [HASUU_NOW].[package_group_name]
		--		,SUM([HASUU_NOW].[qty_hasuu_now]) AS QTY_HASUU_NOW
		--	FROM
		--	(
		--		SELECT [pk_g].[name] as [package_group_name]
		--			,[pk].[short_name] as [package_name]
		--			, [dv].[name] as [device_name] 
		--			, SUM([sur].[pcs]) as [qty_hasuu_now]
		--			, SUM([sur].[pcs])/([dv].[pcs_per_pack]) as [count_reel]
		--			, COUNT([sur].[serial_no]) as [count_lot]
		--		FROM [APCSProDB].[trans].[surpluses] as [sur]
		--		INNER JOIN [APCSProDB].[trans].[lots] as [lot] on [sur].[lot_id] = [lot].[id]
		--		INNER JOIN (
		--				select case when [dv1].[rank] is null then '' else [dv1].[rank] end As [rank_value],* 
		--				from [APCSProDB].[method].[device_names] as [dv1]
		--		) as [dv] on [lot].[act_device_name_id] = [dv].[id]
		--		INNER JOIN [APCSProDB].[method].[packages] as [pk] on [dv].[package_id] = [pk].[id]
		--		INNER JOIN [APCSProDB].[method].[package_groups] as [pk_g] on [pk].[package_group_id] = [pk_g].[id]
		--		LEFT JOIN [APCSProDB].[trans].[locations] as [locat] on [sur].[location_id] = [locat].[id]
		--		WHERE ([sur].[location_id] IS NOT NULL and [sur].[location_id] != 0)
		--			AND ([lot].[wip_state] = 20 OR [lot].[wip_state] = 70 or [lot].[wip_state] = 100)
		--			AND [lot].[quality_state] = 0
		--			AND [sur].[in_stock] = 2 
		--			AND (SUBSTRING([sur].[serial_no],1,2) >= (FORMAT(GETDATE(),'yy') - 3) or [sur].[is_ability] = 1) 
		--			AND SUBSTRING([sur].[serial_no],5,1) !='E' 
		--			AND (SUBSTRING([sur].[serial_no],5,1) !='G'  
		--				OR (SUBSTRING([serial_no],5,1) = 'G' and [dv].[name] in ('SV013-HE2           ','SV131-HE2           ','SV014-HE2           ','SV010-HE2           ','BV2HC045EFU-C       ','BV2HD045EFU-CE2     ','BV2HD070EFU-CE2    ','BV2HC045EFU-CE2     ')) 
		--				) 
		--	   GROUP BY [pk].[short_name],[dv].[name],[dv].[rank_value],[dv].[pcs_per_pack],[pk_g].[name],[sur].[qc_instruction]
		--	   Having SUM([sur].[pcs]) >= [dv].[pcs_per_pack] 
		--			and SUM([sur].[pcs])/(NULLIF([dv].[pcs_per_pack], 0)) >= 1
		--	) AS HASUU_NOW
		--	GROUP BY [HASUU_NOW].[package_group_name]
		--) AS [hasuu_now] ON [master].[package_group_name] = [hasuu_now].[package_group_name]

		SELECT [HASUU_NOW].[package_group_name]
				,SUM([HASUU_NOW].[qty_hasuu_now]) AS QTY_HASUU_NOW
			FROM
			(
				SELECT 
				  [pk_g].[name] as [package_group_name]
				, [pk].[short_name] as [package_name]
				, [dn].[name] as [device_name]
				, [dn].[rank] as [rank]
				, [sur].[qc_instruction] 
				, SUM([sur].[pcs]) as [qty_hasuu_now]
				, SUM([sur].[pcs])/([dn].[pcs_per_pack]) as [count_reel]
				, COUNT([sur].[serial_no]) as [count_lot]
			from APCSProDB.trans.surpluses as sur
			left join APCSProDB.trans.lots as tranlot on sur.serial_no  = tranlot.lot_no 
			inner join APCSProDB.method.packages as pk on pk.id = tranlot.act_package_id
			inner join APCSProDB.method.device_names as dn on dn.id = tranlot.act_device_name_id
			inner join APCSProDB.method.package_groups as pk_g on pk.package_group_id = pk_g.id
			left join APCSProDB.trans.locations as locat on locat.id = sur.location_id
			WHERE sur.in_stock = 2
			AND (CAST(@year_now as int) - CAST((SUBSTRING(sur.serial_no,1,2)) as int) <= 3)
			GROUP BY [pk].[short_name],[dn].[name],[dn].[rank],[dn].[pcs_per_pack],[pk_g].[name],[sur].[qc_instruction]
			) AS HASUU_NOW
			GROUP BY [HASUU_NOW].[package_group_name]
		) AS [HASUU_NOW] ON [master].[package_group_name] = [HASUU_NOW].[package_group_name]
		
		--- long
		LEFT JOIN (
		--	SELECT
		--		[Hasuu_Long].[package_group_name]
		--		,SUM([Hasuu_Long].[QTY]) AS [qty_hasuu_long]
		--	FROM
		--	(
		--	SELECT [pk_g].[name] as [package_group_name]
		--		, [pk].[short_name] as [package_name]
		--		, [dv].[name] as [device_name]
		--		, [dv].[rank_value] as [rank]
		--		, [sur].[qc_instruction] 
		--		, SUM([sur].[pcs]) as [QTY]
		--		, SUM([sur].[pcs])/([dv].[pcs_per_pack]) as [count_reel]
		--		, COUNT([sur].[serial_no]) as [count_lot]
		--		   FROM  [APCSProDB].[trans].[surpluses] as sur
		--		   INNER JOIN [APCSProDB].[trans].[lots] as [lot] on [sur].[lot_id] = [lot].[id]
		--		   INNER JOIN (
		--						SELECT case when [dv1].[rank] is null then '' else [dv1].[rank] end As [rank_value],* 
		--						FROM [APCSProDB].[method].[device_names] as [dv1]
		--					  ) AS [dv] ON [lot].[act_device_name_id] = [dv].[id]
		--		   INNER JOIN [APCSProDB].[method].[packages] as [pk] on [dv].[package_id] = [pk].[id]
		--		   INNER JOIN [APCSProDB].[method].[package_groups] as [pk_g] on [pk].[package_group_id] = [pk_g].[id]
		--		   LEFT JOIN [APCSProDB].[trans].[locations] as [locat] on [sur].[location_id] = [locat].[id]
		--		   WHERE ([sur].[location_id] IS NOT NULL and [sur].[location_id] != 0)
		--				and [lot].[quality_state] = 0
		--				and [sur].[pcs] != 0
		--				AND CAST((FORMAT(GETDATE(),'yy')) as int) - CAST((SUBSTRING([sur].[serial_no],1,2)) as int) >= 3
		--		   GROUP BY [pk].[short_name],[dv].[name],[dv].[rank_value],[dv].[pcs_per_pack],[pk_g].[name],[sur].[qc_instruction]
		--		   HAVING SUM([sur].[pcs]) >= [dv].[pcs_per_pack] 
		--	) AS Hasuu_Long
		--	GROUP BY [Hasuu_Long].[package_group_name]
		--) AS [hasuu_long] ON [master].[package_group_name] = [hasuu_long].[package_group_name]
		
		SELECT
				[Hasuu_Long].[package_group_name]
				,SUM([Hasuu_Long].[QTY]) AS [qty_hasuu_long]
			FROM
			(
			SELECT 
				  [pk_g].[name] as [package_group_name]
				, [pk].[short_name] as [package_name]
				, [dn].[name] as [device_name]
				, [dn].[rank] as [rank]
				, [sur].[qc_instruction] 
				, SUM([sur].[pcs]) as [QTY]
				, SUM([sur].[pcs])/([dn].[pcs_per_pack]) as [count_reel]
				, COUNT([sur].[serial_no]) as [count_lot]
			from APCSProDB.trans.surpluses as sur
			left join APCSProDB.trans.lots as tranlot on sur.serial_no  = tranlot.lot_no 
			inner join APCSProDB.method.packages as pk on pk.id = tranlot.act_package_id
			inner join APCSProDB.method.device_names as dn on dn.id = tranlot.act_device_name_id
			inner join APCSProDB.method.package_groups as pk_g on pk.package_group_id = pk_g.id
			left join APCSProDB.trans.locations as locat on locat.id = sur.location_id
			WHERE sur.in_stock = 2
			AND (CAST(@year_now as int) - CAST((SUBSTRING(sur.serial_no,1,2)) as int) > 3)
			GROUP BY [pk].[short_name],[dn].[name],[dn].[rank],[dn].[pcs_per_pack],[pk_g].[name],[sur].[qc_instruction]
			) AS Hasuu_Long
			GROUP BY [Hasuu_Long].[package_group_name]
		) AS [hasuu_long] ON [master].[package_group_name] = [hasuu_long].[package_group_name]

		---- unavailable
		LEFT JOIN (
			SELECT Test.package_group_name
			 ,SUM([Test].[QTY]) AS Unavailable
			FROM
			(
			SELECT [pk_g].[name] as [package_group_name]
				, [pk].[short_name] as [package_name]
				, [dv].[name] as [device_name]
				, SUM([sur].[pcs]) as [QTY]
				, SUM([sur].[pcs])/([dv].[pcs_per_pack]) as [count_reel]
				, COUNT([sur].[serial_no]) as [count_lot]
				, [dv].[pcs_per_pack]
				   FROM  [APCSProDB].[trans].[surpluses] as [sur]
				   INNER JOIN [APCSProDB].[trans].[lots] as [lot] on [sur].[lot_id] = [lot].[id]
				   INNER JOIN (
								SELECT case when [dv1].[rank] is null then '' else [dv1].[rank] end As [rank_value],* 
								FROM [APCSProDB].[method].[device_names] as [dv1]
							  ) AS [dv] ON [lot].[act_device_name_id] = [dv].[id]
				   INNER JOIN [APCSProDB].[method].[packages] as [pk] on [dv].[package_id] = [pk].[id]
				   INNER JOIN [APCSProDB].[method].[package_groups] as [pk_g] on [pk].[package_group_id] = [pk_g].[id]
				   LEFT JOIN [APCSProDB].[trans].[locations] as [locat] on [sur].[location_id] = [locat].[id]
				   WHERE [sur].[location_id] IS NULL 
						AND [sur].[in_stock] IN (2,3)
						OR [lot].[quality_state] <> 0
				   GROUP BY [pk].[short_name],[dv].[name],[dv].[rank_value],[dv].[pcs_per_pack],[pk_g].[name],[sur].[qc_instruction]
				   HAVING SUM([sur].[pcs]) < [dv].[pcs_per_pack]
			) AS Test
			GROUP BY Test.package_group_name
		) AS [unavailable] ON [master].[package_group_name] = [unavailable].[package_group_name]
		WHERE [master].[package_group_name] like @package_group
		ORDER BY [master].[package_group_name] ASC
	END
	ELSE IF @is_function = 3
	BEGIN
		SELECT * FROM [APCSProDWH].[cac].[item_labels] 
		WHERE [name] = 'wip_monitor_detail.surpluses'
	END
END
