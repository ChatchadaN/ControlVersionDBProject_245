CREATE PROCEDURE [rans].[sp_get_machine_compare_location_mp]
	-- Add the parameters for the stored procedure here
	@machine_id VARCHAR(10) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	---- Query find machine compare location
	SELECT [machines].[id] AS [machine_nid]
		, [machines].[name] AS [machine_name]
		, [locations].[name] AS [locations_name]
	FROM [APCSProDWH].[rans].[machine_location_settings]
	INNER JOIN [APCSProDB].[trans].[locations] ON [machine_location_settings].[location_id] = [locations].[id]
	INNER JOIN [APCSProDB].[mc].[machines] ON [machine_location_settings].[machine_id] = [machines].[id]
	WHERE [machines].[id] LIKE @machine_id
	GROUP BY [machines].[id]
		, [machines].[name]
		, [locations].[name];
END
