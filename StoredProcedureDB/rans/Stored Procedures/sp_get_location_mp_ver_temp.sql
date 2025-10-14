CREATE PROCEDURE [rans].[sp_get_location_mp_ver_temp] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	---- Query find location not register
	
	SELECT [location].[name]
	FROM (
	      SELECT [rack_controls].[name] from [APCSProDB].[rcs].[rack_controls]
		  WHERE [rack_controls].[name] LIKE 'MP%'  -- find location MP
		  GROUP BY [rack_controls].[name]
	     ) AS [location]
	LEFT JOIN (
			SELECT [rack_controls].[name] 
			FROM [APCSProDWH].[rans].[machine_location_settings]
			INNER JOIN [APCSProDB].[rcs].[rack_addresses]
				ON [machine_location_settings].location_id = [rack_addresses].id
			INNER JOIN APCSProDB.rcs.rack_controls 
				ON rack_addresses.rack_control_id = rack_controls.id
			GROUP BY [rack_controls].[name]
	) AS [location_used] ON [location].[name] = [location_used].[name]
	WHERE [location_used].[name] IS NULL;
END
