------------------------------ Creater Rule ------------------------------
-- Project Name				: RCS
-- Author Name              : Chatchadaporn N.
-- Written Date             : 2024/08/09
-- Database Referd			: StoredProcedureDB
-- Specific Logic           : 
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [rcs].[sp_get_rack_address_by_lot]
(		
	@item			varchar(20)
	, @categories	varchar(20) = NULL
	
)
						
AS
BEGIN	 
	--SET NOCOUNT ON;
	SET NOCOUNT ON;	
	-----------------------------------------------------------------
	--SELECT
	--	[locations].name AS [locations]
	--	, [rack_controls].name AS [rackName]
	--	, [rack_addresses].address AS [Rack_address]
	--FROM [APCSProDB].[rcs].[rack_controls]
	--	INNER JOIN [APCSProDB].[trans].[location_racks] ON [rack_controls].[id] = [location_racks].[rack_control_id]
	--	INNER JOIN [APCSProDB].[trans].[locations] ON [location_racks].[location_id] = [locations].[id]
	--	INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [rack_controls].[id] = [rack_addresses].[rack_control_id]
	--WHERE [rack_addresses].item = @item and category = @categories


	IF(@categories IS NOT NULL)
	BEGIN
		--PRINT '@categories IS NOT NULL'
		SELECT
			[locations].[name] AS [locations]
			, [locations].[address] AS [areaName]
			, [rack_categories].[name] AS [categoryName]
			, [rack_controls].[name] AS [rackName]
			, [rack_addresses].[address] AS [Rack_address]
		FROM [APCSProDB].[rcs].[rack_controls]
			INNER JOIN [APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
			INNER JOIN [APCSProDB].[rcs].[rack_categories] ON [rack_controls].[category] = [rack_categories].[id]
			INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [rack_controls].[id] = [rack_addresses].[rack_control_id]
		WHERE [rack_addresses].item = @item 
		AND category = @categories
	END
	ELSE IF (@categories IS NULL )
	BEGIN
		--PRINT '@categories IS NULL'
		SELECT
			[locations].[name] AS [locations]
			, [locations].[address] AS [areaName]
			, [rack_categories].[name] AS [categoryName]
			, [rack_controls].[name] AS [rackName]
			, [rack_addresses].[address] AS [Rack_address]
			, item
		FROM [APCSProDB].[rcs].[rack_controls]
			INNER JOIN [APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
			INNER JOIN [APCSProDB].[rcs].[rack_categories] ON [rack_controls].[category] = [rack_categories].[id]
			INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [rack_controls].[id] = [rack_addresses].[rack_control_id]
		WHERE [rack_addresses].item = @item
	END
END