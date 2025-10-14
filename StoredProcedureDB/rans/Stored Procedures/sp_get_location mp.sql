CREATE PROCEDURE [rans].[sp_get_location mp] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	---- Query find location not register
	SELECT [location].[name]
	FROM (
		SELECT [locations].[name] FROM [APCSProDB].[trans].[locations]
		WHERE [locations].[name] LIKE 'MP%' -- find location MP
		GROUP BY [locations].[name]
	) AS [location]
	LEFT JOIN (
		SELECT [locations].[name]
		FROM [APCSProDWH].[rans].[machine_location_settings]
		INNER JOIN [APCSProDB].[trans].[locations] ON [machine_location_settings].[location_id] = [locations].[id]
		GROUP BY [locations].[name]
	) AS [location_used] ON [location].[name] = [location_used].[name]
	WHERE [location_used].[name] IS NULL;
END
