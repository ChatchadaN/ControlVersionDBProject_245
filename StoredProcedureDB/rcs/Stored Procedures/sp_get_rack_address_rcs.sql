------------------------------ Creater Rule ------------------------------
-- Project Name				: RCS
-- Author Name              : Chatchadaporn N.
-- Written Date             : 2024/07/23
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [rcs].[sp_get_rack_address_rcs]
(		
	@rackName_id int
)
						
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET NOCOUNT ON;	
	DECLARE @Now DATETIME = GETDATE();

	DECLARE @categories_id INT 

	SELECT @categories_id = category 
	FROM APCSProDB.rcs.rack_controls
	WHERE id = @rackName_id
	-----------------------------------------------------------------

	SELECT [LotNo]
		,[JobName]
		,[PkgName]
		,[DevName]
		,[Location_id]
		,[LocationName]
		,[AreaName]
		,[Category_id]
		,[CategoryName]
		,[PatternName]
		,[Rack_controls_id]
		,[RackName]
		,[rack_addresses_id]
		,[Address]
		,[X]
		,[Y]
		,[Depth]
		,[Sequence]
		,[Status]
		,[t1].[label_eng] AS [status_rack]
		,[t1].[color_code] AS [status_color]
		,[UpdateTime]
		,[leadtime_status]
		,[t2].[label_eng] AS [leadtime_label]
		,[t2].[color_code] as [leadtime_color]
		,[is_enable]
		,[updated_at]
		,[is_fifo]
	FROM (
		SELECT 
			ISNULL([rack_addresses].[item], '') AS [LotNo]
			, ISNULL(IIF([lots].[is_special_flow] = 1, [spe_jobs].[name], [mas_jobs].[name]), '') AS [JobName]
			, ISNULL(TRIM([pkg].[name]), '') AS [PkgName]
			, ISNULL(TRIM([dev].[name]), '') AS [DevName]
			, [locations].[id] AS [Location_id]
			, [locations].[name] AS [LocationName]
			, [locations].[address] AS [AreaName]
			, [rack_categories].[id] AS [Category_id]
			, [rack_categories].[name] AS [CategoryName]
			, [rack_categories].[pattern] AS [PatternName]
			, [rack_controls].[id] AS [Rack_controls_id]
			, [rack_controls].[name] AS [RackName]
			, [rack_addresses].[id] AS [rack_addresses_id]
			, CONCAT([rack_addresses].[x], FORMAT(CAST([rack_addresses].[y] AS INT), '00')) AS [Address]
			, [rack_addresses].[X]
			, [rack_addresses].[Y]
			, [rack_addresses].[z] AS [Depth]
			, ROW_NUMBER() OVER (PARTITION BY [rack_controls].[name] ORDER BY [rack_controls].[name], [rack_addresses].[x], CAST([rack_addresses].[y] AS INT)) AS [Sequence]
			, [rack_addresses].[status] AS [Status]
			, ( CASE 
				WHEN [rack_addresses].[item] IS NOT NULL
					THEN CONCAT((DATEDIFF(HOUR, [rack_addresses].[updated_at], @Now))/24, 'D ', 
							(DATEDIFF(HOUR, [rack_addresses].[updated_at], @Now))%24, 'H ', 
							(DATEDIFF(MINUTE, [rack_addresses].[updated_at], @Now))%60, 'M ') 
				ELSE NULL END )
			AS [UpdateTime]
			,( CASE 
				WHEN [rack_addresses].[item] IS NOT NULL
					THEN 
						CASE 
							WHEN DATEDIFF(HOUR,[rack_addresses].[updated_at],GETDATE()) < 12 THEN 1
							WHEN DATEDIFF(HOUR,[rack_addresses].[updated_at],GETDATE()) BETWEEN 12 AND 24 THEN 2
							WHEN DATEDIFF(HOUR,[rack_addresses].[updated_at],GETDATE()) > 24 THEN 3			
						ELSE NULL END
					ELSE NULL
			 END) AS [leadtime_status]
			, [rack_addresses].[is_enable]
			, [rack_addresses].[updated_at]
			, [rack_controls].[is_fifo]
			, IIF([rack_addresses].[item] != '',1,0 ) AS in_rack
		FROM [APCSProDB].[rcs].[rack_addresses]
		INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
		INNER JOIN [APCSProDB].[rcs].[rack_categories] ON [rack_controls].[category] = [rack_categories].[id]
		INNER JOIN [APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
		LEFT JOIN [APCSProDB].[trans].[lots] ON [rack_addresses].[item] = [lots].[lot_no]
		LEFT JOIN [APCSProDB].[method].[packages] AS [pkg] ON [lots].[act_package_id] = [pkg].[id]
		LEFT JOIN [APCSProDB].[method].[device_names] AS [dev] ON [lots].[act_device_name_id] = [dev].[id]
		LEFT JOIN [APCSProDB].[method].[jobs] AS [mas_jobs]	ON [lots].[act_job_id] = [mas_jobs].[id]
		LEFT JOIN [APCSProDB].[trans].[special_flows] AS [spe] ON [lots].[is_special_flow] = 1 
			AND [lots].[special_flow_id] = [spe].[id]
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] AS [lot_spe] ON [spe].[id] = [lot_spe].[special_flow_id] 
			AND [spe].[step_no] = [lot_spe].[step_no]
		LEFT JOIN [APCSProDB].[method].[jobs] AS [spe_jobs] ON [lot_spe].[job_id] = [spe_jobs].[id]
		WHERE
			[rack_controls].[id] =  @rackName_id
	) AS [rack_data]
	INNER JOIN [APCSProDB].[rcs].[item_labels] [t1] ON [rack_data].[Status] = [t1].[val] AND [t1].[name] = 'rack_addresses.status' 
	LEFT JOIN [APCSProDB].[rcs].[item_labels] [t2] ON [rack_data].[leadtime_status] = [t2].[val] AND [t2].[name] = 'leadtime_status' 
	order by in_rack, [updated_at] desc


	----------------------------------------------------------------------------------------------------------------------------------------------
	---- Materials and WAFER
	--IF (@categories_id = 5)
	--BEGIN
	--	PRINT 'Materials and WAFER'
	
	--	SELECT [Item]
	--		,[Detail_1]
	--		,[Detail_2]
	--		,[Detail_3]
	--		,[Location_id]
	--		,[LocationName]
	--		,[AreaName]
	--		,[Category_id]
	--		,[CategoryName]
	--		,[PatternName]
	--		,[Rack_controls_id]
	--		,[RackName]
	--		,[rack_addresses_id]
	--		,[Address]
	--		,[X]
	--		,[Y]
	--		,[Depth]
	--		,[Sequence]
	--		,[Status]
	--		,[t1].[label_eng] AS [status_rack]
	--		,[t1].[color_code] AS [status_color]
	--		,[UpdateTime]
	--		,[leadtime_status]
	--		,[t2].[label_eng] AS [leadtime_label]
	--		,[t2].[color_code] as [leadtime_color]
	--		,[is_enable]
	--		,[updated_at]
	--		,[is_fifo]
	--	FROM (
	--		SELECT 
	--			ISNULL([rack_addresses].[item], '') AS [Item]
			
	--			, ISNULL(IIF(categories.id = 11,TRIM(materials.lot_no),TRIM([categories].[name])),'') AS [Detail_1]
	--			, ISNULL(IIF(categories.id = 11,TRIM(wf_details.seq_no),TRIM([productions].[name])),'') AS [Detail_2]
	--			, IIF(categories.id = 11,TRIM(wf_details.chip_model_name),'') AS [Detail_3]

	--			, [locations].[id] AS [Location_id]
	--			, [locations].[name] AS [LocationName]
	--			, [locations].[address] AS [AreaName]
	--			, [rack_categories].[id] AS [Category_id]
	--			, [rack_categories].[name] AS [CategoryName]
	--			, [rack_categories].[pattern] AS [PatternName]
	--			, [rack_controls].[id] AS [Rack_controls_id]
	--			, [rack_controls].[name] AS [RackName]
	--			, [rack_addresses].[id] AS [rack_addresses_id]
	--			, CONCAT([rack_addresses].[x], FORMAT(CAST([rack_addresses].[y] AS INT), '00')) AS [Address]
	--			, [rack_addresses].[X]
	--			, [rack_addresses].[Y]
	--			, [rack_addresses].[z] AS [Depth]
	--			, ROW_NUMBER() OVER (PARTITION BY [rack_controls].[name] ORDER BY [rack_controls].[name], [rack_addresses].[x], CAST([rack_addresses].[y] AS INT)) AS [Sequence]
	--			, [rack_addresses].[status] AS [Status]
	--			, ( CASE 
	--				WHEN [rack_addresses].[item] IS NOT NULL
	--					THEN CONCAT((DATEDIFF(HOUR, [rack_addresses].[updated_at], @Now))/24, 'D ', 
	--							(DATEDIFF(HOUR, [rack_addresses].[updated_at], @Now))%24, 'H ', 
	--							(DATEDIFF(MINUTE, [rack_addresses].[updated_at], @Now))%60, 'M ') 
	--				ELSE NULL END )
	--			AS [UpdateTime]
	--			,( CASE 
	--				WHEN [rack_addresses].[item] IS NOT NULL
	--					THEN 
	--						CASE 
	--							WHEN DATEDIFF(HOUR,[rack_addresses].[updated_at],GETDATE()) < 12 THEN 1
	--							WHEN DATEDIFF(HOUR,[rack_addresses].[updated_at],GETDATE()) BETWEEN 12 AND 24 THEN 2
	--							WHEN DATEDIFF(HOUR,[rack_addresses].[updated_at],GETDATE()) > 24 THEN 3			
	--						ELSE NULL END
	--					ELSE NULL
	--			 END) AS [leadtime_status]
	--			, [rack_addresses].[is_enable]
	--			, [rack_addresses].[updated_at]
	--			, [rack_controls].[is_fifo]
	--			, IIF([rack_addresses].[item] != '',1,0 ) AS in_rack
	--		FROM [APCSProDB].[rcs].[rack_addresses]
	--		INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
	--		INNER JOIN [APCSProDB].[rcs].[rack_categories] ON [rack_controls].[category] = [rack_categories].[id]
	--		LEFT JOIN [APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]

	--		LEFT JOIN APCSProDB.trans.materials ON rack_addresses.item = materials.barcode
	--		LEFT JOIN APCSProDB.material.productions ON materials.material_production_id = productions.id
	--		LEFT JOIN APCSProDB.material.categories ON productions.category_id = categories.id
	--		LEFT JOIN APCSProDB.trans.wf_details ON materials.id = wf_details.material_id
		
	--		WHERE
	--			[rack_controls].[id] =  @rackName_id

	--	) AS [rack_data]
	--	INNER JOIN [APCSProDB].[rcs].[item_labels] [t1] ON [rack_data].[Status] = [t1].[val] AND [t1].[name] = 'rack_addresses.status' 
	--	LEFT JOIN [APCSProDB].[rcs].[item_labels] [t2] ON [rack_data].[leadtime_status] = [t2].[val] AND [t2].[name] = 'leadtime_status' 
	--	order by in_rack, [updated_at] desc

	--END

	---- JIG
	--ELSE IF (@categories_id = 6)
	--BEGIN
	--	PRINT 'JIG'

	--	SELECT [Item]
	--		,[Detail_1]
	--		,[Detail_2]
	--		,[Detail_3]
	--		,[Location_id]
	--		,[LocationName]
	--		,[AreaName]
	--		,[Category_id]
	--		,[CategoryName]
	--		,[PatternName]
	--		,[Rack_controls_id]
	--		,[RackName]
	--		,[rack_addresses_id]
	--		,[Address]
	--		,[X]
	--		,[Y]
	--		,[Depth]
	--		,[Sequence]
	--		,[Status]
	--		,[t1].[label_eng] AS [status_rack]
	--		,[t1].[color_code] AS [status_color]
	--		,[UpdateTime]
	--		,[leadtime_status]
	--		,[t2].[label_eng] AS [leadtime_label]
	--		,[t2].[color_code] as [leadtime_color]
	--		,[is_enable]
	--		,[updated_at]
	--		,[is_fifo]
	--	FROM (
	--		SELECT 
	--			ISNULL([rack_addresses].[item], '') AS [Item]
			
	--			, ISNULL(TRIM([categories].[name]),'') AS [Detail_1]
	--			, ISNULL(TRIM([productions].[name]),'') AS [Detail_2]
	--			, '' AS [Detail_3]

	--			, [locations].[id] AS [Location_id]
	--			, [locations].[name] AS [LocationName]
	--			, [locations].[address] AS [AreaName]
	--			, [rack_categories].[id] AS [Category_id]
	--			, [rack_categories].[name] AS [CategoryName]
	--			, [rack_categories].[pattern] AS [PatternName]
	--			, [rack_controls].[id] AS [Rack_controls_id]
	--			, [rack_controls].[name] AS [RackName]
	--			, [rack_addresses].[id] AS [rack_addresses_id]
	--			, CONCAT([rack_addresses].[x], FORMAT(CAST([rack_addresses].[y] AS INT), '00')) AS [Address]
	--			, [rack_addresses].[X]
	--			, [rack_addresses].[Y]
	--			, [rack_addresses].[z] AS [Depth]
	--			, ROW_NUMBER() OVER (PARTITION BY [rack_controls].[name] ORDER BY [rack_controls].[name], [rack_addresses].[x], CAST([rack_addresses].[y] AS INT)) AS [Sequence]
	--			, [rack_addresses].[status] AS [Status]
	--			, ( CASE 
	--				WHEN [rack_addresses].[item] IS NOT NULL
	--					THEN CONCAT((DATEDIFF(HOUR, [rack_addresses].[updated_at], @Now))/24, 'D ', 
	--							(DATEDIFF(HOUR, [rack_addresses].[updated_at], @Now))%24, 'H ', 
	--							(DATEDIFF(MINUTE, [rack_addresses].[updated_at], @Now))%60, 'M ') 
	--				ELSE NULL END )
	--			AS [UpdateTime]
	--			,( CASE 
	--				WHEN [rack_addresses].[item] IS NOT NULL
	--					THEN 
	--						CASE 
	--							WHEN DATEDIFF(HOUR,[rack_addresses].[updated_at],GETDATE()) < 12 THEN 1
	--							WHEN DATEDIFF(HOUR,[rack_addresses].[updated_at],GETDATE()) BETWEEN 12 AND 24 THEN 2
	--							WHEN DATEDIFF(HOUR,[rack_addresses].[updated_at],GETDATE()) > 24 THEN 3			
	--						ELSE NULL END
	--					ELSE NULL
	--			 END) AS [leadtime_status]
	--			, [rack_addresses].[is_enable]
	--			, [rack_addresses].[updated_at]
	--			, [rack_controls].[is_fifo]
	--			, IIF([rack_addresses].[item] != '',1,0 ) AS in_rack
	--		FROM [APCSProDB].[rcs].[rack_addresses]
	--		INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
	--		INNER JOIN [APCSProDB].[rcs].[rack_categories] ON [rack_controls].[category] = [rack_categories].[id]
	--		LEFT JOIN [APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]

	--		LEFT JOIN APCSProDB.trans.jigs ON rack_addresses.item = jigs.barcode
	--		LEFT JOIN APCSProDB.jig.productions ON jigs.jig_production_id = productions.id
	--		LEFT JOIN APCSProDB.jig.categories ON productions.category_id = categories.id
		
	--		WHERE
	--			[rack_controls].[id] =  @rackName_id

	--	) AS [rack_data]
	--	INNER JOIN [APCSProDB].[rcs].[item_labels] [t1] ON [rack_data].[Status] = [t1].[val] AND [t1].[name] = 'rack_addresses.status' 
	--	LEFT JOIN [APCSProDB].[rcs].[item_labels] [t2] ON [rack_data].[leadtime_status] = [t2].[val] AND [t2].[name] = 'leadtime_status' 
	--	order by in_rack, [updated_at] desc
	--END

	----LOT : WIP HASUU HOLD
	--ELSE
	--BEGIN
	--	PRINT 'LOTS'

	--	SELECT [LotNo] AS [Item]
	--		,[JobName] AS [Detail_1]
	--		,[PkgName] AS [Detail_2]
	--		,[DevName] AS [Detail_3]
	--		,[Location_id]
	--		,[LocationName]
	--		,[AreaName]
	--		,[Category_id]
	--		,[CategoryName]
	--		,[PatternName]
	--		,[Rack_controls_id]
	--		,[RackName]
	--		,[rack_addresses_id]
	--		,[Address]
	--		,[X]
	--		,[Y]
	--		,[Depth]
	--		,[Sequence]
	--		,[Status]
	--		,[t1].[label_eng] AS [status_rack]
	--		,[t1].[color_code] AS [status_color]
	--		,[UpdateTime]
	--		,[leadtime_status]
	--		,[t2].[label_eng] AS [leadtime_label]
	--		,[t2].[color_code] as [leadtime_color]
	--		,[is_enable]
	--		,[updated_at]
	--		,[is_fifo]
	--	FROM (
	--		SELECT 
	--			ISNULL([rack_addresses].[item], '') AS [LotNo]
	--			, ISNULL(IIF([lots].[is_special_flow] = 1, [spe_jobs].[name], [mas_jobs].[name]), '') AS [JobName]
	--			, ISNULL(TRIM([pkg].[name]), '') AS [PkgName]
	--			, ISNULL(TRIM([dev].[assy_name]), '') AS [DevName]

	--			, [locations].[id] AS [Location_id]
	--			, [locations].[name] AS [LocationName]
	--			, [locations].[address] AS [AreaName]
	--			, [rack_categories].[id] AS [Category_id]
	--			, [rack_categories].[name] AS [CategoryName]
	--			, [rack_categories].[pattern] AS [PatternName]
	--			, [rack_controls].[id] AS [Rack_controls_id]
	--			, [rack_controls].[name] AS [RackName]
	--			, [rack_addresses].[id] AS [rack_addresses_id]
	--			, CONCAT([rack_addresses].[x], FORMAT(CAST([rack_addresses].[y] AS INT), '00')) AS [Address]
	--			, [rack_addresses].[X]
	--			, [rack_addresses].[Y]
	--			, [rack_addresses].[z] AS [Depth]
	--			, ROW_NUMBER() OVER (PARTITION BY [rack_controls].[name] ORDER BY [rack_controls].[name], [rack_addresses].[x], CAST([rack_addresses].[y] AS INT)) AS [Sequence]
	--			, [rack_addresses].[status] AS [Status]
	--			, ( CASE 
	--				WHEN [rack_addresses].[item] IS NOT NULL
	--					THEN CONCAT((DATEDIFF(HOUR, [rack_addresses].[updated_at], @Now))/24, 'D ', 
	--							(DATEDIFF(HOUR, [rack_addresses].[updated_at], @Now))%24, 'H ', 
	--							(DATEDIFF(MINUTE, [rack_addresses].[updated_at], @Now))%60, 'M ') 
	--				ELSE NULL END )
	--			AS [UpdateTime]
	--			,( CASE 
	--				WHEN [rack_addresses].[item] IS NOT NULL
	--					THEN 
	--						CASE 
	--							WHEN DATEDIFF(HOUR,[rack_addresses].[updated_at],GETDATE()) < 12 THEN 1
	--							WHEN DATEDIFF(HOUR,[rack_addresses].[updated_at],GETDATE()) BETWEEN 12 AND 24 THEN 2
	--							WHEN DATEDIFF(HOUR,[rack_addresses].[updated_at],GETDATE()) > 24 THEN 3			
	--						ELSE NULL END
	--					ELSE NULL
	--			 END) AS [leadtime_status]
	--			, [rack_addresses].[is_enable]
	--			, [rack_addresses].[updated_at]
	--			, [rack_controls].[is_fifo]
	--			, IIF([rack_addresses].[item] != '',1,0 ) AS in_rack
	--		FROM [APCSProDB].[rcs].[rack_addresses]
	--		INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
	--		INNER JOIN [APCSProDB].[rcs].[rack_categories] ON [rack_controls].[category] = [rack_categories].[id]
	--		LEFT JOIN [APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]

	--		LEFT JOIN [APCSProDB].[trans].[lots] ON [rack_addresses].[item] = [lots].[lot_no]
	--		LEFT JOIN [APCSProDB].[method].[packages] AS [pkg] ON [lots].[act_package_id] = [pkg].[id]
	--		LEFT JOIN [APCSProDB].[method].[device_names] AS [dev] ON [lots].[act_device_name_id] = [dev].[id]
	--		LEFT JOIN [APCSProDB].[method].[jobs] AS [mas_jobs]	ON [lots].[act_job_id] = [mas_jobs].[id]
	--		LEFT JOIN [APCSProDB].[trans].[special_flows] AS [spe] ON [lots].[is_special_flow] = 1 
	--			AND [lots].[special_flow_id] = [spe].[id]
	--		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] AS [lot_spe] ON [spe].[id] = [lot_spe].[special_flow_id] 
	--			AND [spe].[step_no] = [lot_spe].[step_no]
	--		LEFT JOIN [APCSProDB].[method].[jobs] AS [spe_jobs] ON [lot_spe].[job_id] = [spe_jobs].[id]

	--		WHERE
	--			[rack_controls].[id] =  @rackName_id
	--	) AS [rack_data]
	--	INNER JOIN [APCSProDB].[rcs].[item_labels] [t1] ON [rack_data].[Status] = [t1].[val] AND [t1].[name] = 'rack_addresses.status' 
	--	LEFT JOIN [APCSProDB].[rcs].[item_labels] [t2] ON [rack_data].[leadtime_status] = [t2].[val] AND [t2].[name] = 'leadtime_status' 
	--	order by in_rack, [updated_at] desc
	--END

END