------------------------------ Creater Rule ------------------------------
-- Project Name				: RCS
-- Author Name              : Chatchadaporn N.
-- Written Date             : 2024/07/23
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [rcs].[sp_get_filter_rcs]
(		
	--  @location		varchar(20) = '%'
	--, @categories		varchar(50) = '%'
	--, @filter			INT = 1 

	@LocationName		VARCHAR(20) = '%'
	,@AreaId			INT = 1
	, @CategoryId		INT = 1
	, @FilterId			INT = 5 
	--1: location 2: categories 3:rack 
)
						
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET NOCOUNT ON;	
	SET @LocationName = CASE WHEN @LocationName =  '%' THEN NULL ELSE @LocationName END

	-- TEST Control Version --


	-- Location ---------------------------------------------------------------

	IF(@FilterId = 1)
	BEGIN
		SELECT  DISTINCT
			[name] AS [Name]

		FROM [APCSProDB].[trans].[locations]
		WHERE [locations].[headquarter_id] = '1'
	END

	-- Area ---------------------------------------------------------------

	ELSE IF(@FilterId = 2)
	BEGIN
		SELECT DISTINCT 
			[locations].[id] AS [Id]
			,[locations].[address] AS [Name]
		FROM 
			[APCSProDB].[rcs].[rack_controls]
		INNER JOIN
			[APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
		INNER JOIN 
			[APCSProDB].[rcs].[rack_categories] ON [rack_controls].[category] = [rack_categories].[id]
		WHERE 
			([locations].[name] = @LocationName OR @LocationName IS NULL)
			AND [locations].[headquarter_id] = '1'
	END

	-- Category ---------------------------------------------------------------

	ELSE IF(@FilterId = 3)
	BEGIN
		SELECT DISTINCT
			[rack_categories].[id] AS [Id]
			,[rack_categories].[name] AS [Name]
		FROM 
			[APCSProDB].[rcs].[rack_controls]
		INNER JOIN
			[APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
		INNER JOIN 
			[APCSProDB].[rcs].[rack_categories] ON [rack_controls].[category] = [rack_categories].[id]
		WHERE
			[locations].[id] = @AreaId AND [locations].[headquarter_id] = '1'
	END

	-- Rack ---------------------------------------------------------------

	ELSE IF (@FilterId = 4)
	BEGIN
		SELECT DISTINCT
			[rack_controls].[id] AS [Id]
			,[rack_controls].[name] AS [Name]
		FROM 
			[APCSProDB].[rcs].[rack_controls]
		INNER JOIN
			[APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
		INNER JOIN 
			[APCSProDB].[rcs].[rack_categories] ON [rack_controls].[category] = [rack_categories].[id]
		WHERE
			[locations].[id] = @AreaId AND [rack_categories].[id] = @CategoryId AND [locations].[headquarter_id] = '1' and is_enable ='1'
	END

	-- All ---------------------------------------------------------------

	ELSE IF (@FilterId = 5)
	BEGIN
		SELECT DISTINCT
			[rack_controls].[id] AS [RackId]
			,[locations].[id] AS [LocationId]
			,[locations].[name] AS [LocationName]
			,[locations].[address] AS [AreaName]
			,[rack_categories].[id] AS [CategoryId]
			,[rack_categories].[name] AS [CategoryName]
			,[rack_controls].[name] AS [RackName]
			,ISNULL([max_address].[x], 0) AS [X]
			,ISNULL([max_address].[y], 0) AS [Y]
			,ISNULL([max_address].[z], 0) AS [Z]
			,[rack_controls].[is_fifo] AS [RackTypeId]
			,CASE WHEn ([rack_controls].[is_fifo] = 'TRUE') THEN 'Stack' ELSE 'Normal' END AS [RackTypeName]
			,[rack_controls].[is_enable] AS [IsEnable]
			,[rack_controls].[is_type_control]
		FROM 
			[APCSProDB].[rcs].[rack_controls]
		INNER JOIN
			[APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
		INNER JOIN 
			[APCSProDB].[rcs].[rack_categories] ON [rack_controls].[category] = [rack_categories].[id]
		LEFT JOIN
			(
				SELECT [rack_control_id],
					   COUNT(DISTINCT [x]) AS [x],
					   COUNT(DISTINCT [y]) AS [y],
					   COUNT(DISTINCT [z]) AS [z]
				FROM [APCSProDB].[rcs].[rack_addresses]
				WHERE [is_enable] = '1'
				GROUP BY [rack_control_id]
			) AS [max_address]
			ON [rack_controls].[id] = [max_address].[rack_control_id]

		WHERE
			[locations].[headquarter_id] = '1' 
		ORDER BY
			[rack_controls].[id]
	END
END