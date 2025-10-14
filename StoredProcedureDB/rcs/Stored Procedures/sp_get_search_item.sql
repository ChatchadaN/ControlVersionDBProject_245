-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_get_search_item]
	-- Add the parameters for the stored procedure here
	--@search varchar(30)
	@categoryId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [rack_control_id] AS [RackId]
	,[item] AS [ItemName]
	,[rack_categories].[name] AS [CategoryName]
	,[locations].[name] AS [LocationName]
	,[locations].[address] AS [AreaName]
	,[rack_controls].[name] AS [RackName]
	,[rack_addresses].[address] AS [AddressName]
	FROM [APCSProDB].[rcs].[rack_addresses]
	INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
	INNER JOIN [APCSProDB].[rcs].[rack_categories] ON [rack_controls].[category] = [rack_categories].[id]
	INNER JOIN [APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
	WHERE [item] IS NOT NULL AND [rack_categories].[id] = @categoryId
	--WHERE [item] LIKE '%' + @search + '%'
END