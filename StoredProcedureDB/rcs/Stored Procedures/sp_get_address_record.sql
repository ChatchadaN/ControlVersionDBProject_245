-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_get_address_record]
	-- Add the parameters for the stored procedure here
	@location VARCHAR(50) = '%'
	, @area_id INT = NULL
	, @rack_id INT = NULL
	, @categories_id INT = NULL
	, @start_time DATETIME = ''
	, @end_time DATETIME = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	--;WITH LatestRecords AS (
	--	SELECT rack_add.item AS [ItemCode]
	--	, rack_categories.[name] AS [CategoryName]
	--	, locations.[name] AS [LocationName]
	--	, locations.[address] AS [AreaName]
	--	, rack_controls.[name] AS [RackName]
	--	, rack_add.[address] AS [AddressName] 

	--	, CASE WHEN rack_add.[status] = 1 THEN rack_add.updated_at END AS [InputDatetime]
	--	, CASE WHEN rack_add.[status] = 0 THEN rack_add.updated_at END AS [OutputDatetime]

	--	, ROW_NUMBER() OVER (PARTITION BY rack_add.item, rack_add.[address] ,rack_add.[status] ORDER BY rack_add.updated_at DESC) AS RowNum
	--	--, ROW_NUMBER() OVER (PARTITION BY rack_add.item, rack_add.[status] ORDER BY rack_add.updated_at DESC) AS RowNum

	--	FROM APCSProDB.rcs.rack_address_records AS rack_add
	--	INNER JOIN APCSProDB.rcs.rack_controls ON rack_add.rack_control_id = rack_controls.id
	--	INNER JOIN APCSProDB.rcs.rack_categories ON rack_controls.category = rack_categories.id
	--	INNER JOIN APCSProDB.trans.locations ON rack_controls.location_id = locations.id
	--	WHERE (@location = '%' OR locations.[name] = @location) 
	--	AND (@area_id IS NULL OR locations.id = @area_id)
	--	AND (@rack_id IS NULL OR rack_controls.id = @rack_id)
	--	AND (@categories_id IS NULL OR rack_categories.id = @categories_id)
	--	AND rack_add.record_at BETWEEN @start_time AND @end_time
	--	AND item IS NOT NULL
	--)

	--SELECT [ItemCode]
	--	, [CategoryName]
	--	, [LocationName]
	--	, [AreaName]
	--	, [RackName]
	--	, [AddressName]
	--	, MAX(InputDatetime) AS [InputDatetimeLatest]
	--	, MAX(OutputDatetime) AS [OutputDatetimeLatest]

	--	-- Calculate TotalDateTime
	--	, CASE 
	--		WHEN MAX(InputDatetime) IS NOT NULL THEN
	--			CAST(DATEDIFF(DAY, MAX(InputDatetime), ISNULL(MAX(OutputDatetime), GETDATE())) AS VARCHAR) + 'D ' +
	--			CAST(DATEDIFF(HOUR, MAX(InputDatetime), ISNULL(MAX(OutputDatetime), GETDATE())) % 24 AS VARCHAR) + 'H ' +
	--			CAST(DATEDIFF(MINUTE, MAX(InputDatetime), ISNULL(MAX(OutputDatetime), GETDATE())) % 60 AS VARCHAR) + 'M'
	--		ELSE NULL
	--	  END AS [TotalDateTime]
	
	--FROM LatestRecords
	--WHERE RowNum = 1
	--GROUP BY 
	--	ItemCode
	--	, CategoryName
	--	, LocationName
	--	, AreaName
	--	, RackName
	--	, AddressName;

	-----------------------------------------------------------------------------------------------------------------------
	--VER 2 03-07-2025
	
	;WITH InputRecords AS (
		SELECT 
			rack_add.item AS [ItemCode],
			rack_add.[address] AS [AddressName],
			rack_categories.[name] AS [CategoryName],
			locations.[name] AS [LocationName],
			locations.[address] AS [AreaName],
			rack_controls.[name] AS [RackName],
			IIF(rack_add.updated_at IS NULL,rack_add.record_at,rack_add.updated_at) AS [InputDatetime],
			ROW_NUMBER() OVER (PARTITION BY rack_add.item, rack_add.[address] ORDER BY rack_add.updated_at DESC) AS RowNum
		FROM APCSProDB.rcs.rack_address_records AS rack_add
		INNER JOIN APCSProDB.rcs.rack_controls ON rack_add.rack_control_id = rack_controls.id
		INNER JOIN APCSProDB.rcs.rack_categories ON rack_controls.category = rack_categories.id
		INNER JOIN APCSProDB.trans.locations ON rack_controls.location_id = locations.id
		WHERE rack_add.status = 1
		  AND item IS NOT NULL
		  AND (@location = '%' OR locations.[name] = @location) 
		  AND (@area_id IS NULL OR locations.id = @area_id)
		  AND (@rack_id IS NULL OR rack_controls.id = @rack_id)
		  AND (@categories_id IS NULL OR rack_categories.id = @categories_id)
	)
	,OutputRecords AS (
		SELECT 
			rack_add.item AS [ItemCode],
			rack_add.[address] AS [AddressName],
			 IIF(rack_add.updated_at IS NULL,rack_add.record_at,rack_add.updated_at) AS [OutputDatetime],
			rack_categories.[name] AS [CategoryName],
			locations.[name] AS [LocationName],
			locations.[address] AS [AreaName],
			rack_controls.[name] AS [RackName],
			ROW_NUMBER() OVER (PARTITION BY rack_add.item, rack_add.[address] ORDER BY rack_add.updated_at DESC) AS RowNum
		FROM APCSProDB.rcs.rack_address_records AS rack_add
		INNER JOIN APCSProDB.rcs.rack_controls ON rack_add.rack_control_id = rack_controls.id
		INNER JOIN APCSProDB.rcs.rack_categories ON rack_controls.category = rack_categories.id
		INNER JOIN APCSProDB.trans.locations ON rack_controls.location_id = locations.id
		WHERE rack_add.status = 0
		  AND item IS NOT NULL
		  AND (@location = '%' OR locations.[name] = @location) 
		  AND (@area_id IS NULL OR locations.id = @area_id)
		  AND (@rack_id IS NULL OR rack_controls.id = @rack_id)
		  AND (@categories_id IS NULL OR rack_categories.id = @categories_id)	  
	)

	SELECT 
		i.ItemCode,
		i.CategoryName,
		i.LocationName,
		i.AreaName,
		i.RackName,
		i.AddressName,
		i.InputDatetime AS [InputDatetimeLatest],
		o.OutputDatetime AS [OutputDatetimeLatest],
		CASE 
			WHEN i.InputDatetime IS NOT NULL THEN
				CAST(DATEDIFF(DAY, i.InputDatetime, ISNULL(o.OutputDatetime, GETDATE())) AS VARCHAR) + 'D ' +
				CAST(DATEDIFF(HOUR, i.InputDatetime, ISNULL(o.OutputDatetime, GETDATE())) % 24 AS VARCHAR) + 'H ' +
				CAST(DATEDIFF(MINUTE, i.InputDatetime, ISNULL(o.OutputDatetime, GETDATE())) % 60 AS VARCHAR) + 'M'
			ELSE NULL
		END AS [TotalDateTime]
	FROM 
		(SELECT * FROM InputRecords WHERE RowNum = 1) AS i
	LEFT JOIN 
		(SELECT * FROM OutputRecords WHERE RowNum = 1) AS o
	ON i.ItemCode = o.ItemCode AND i.AddressName = o.AddressName

	--WHERE i.InputDatetime >= @start_time
	--AND (o.OutputDatetime <= @end_time OR o.OutputDatetime IS NULL)

	WHERE (i.InputDatetime BETWEEN @start_time AND @end_time)
	OR (o.OutputDatetime BETWEEN @start_time AND @end_time)

END
