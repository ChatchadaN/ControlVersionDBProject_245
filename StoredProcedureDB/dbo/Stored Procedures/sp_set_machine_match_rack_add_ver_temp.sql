-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_machine_match_rack_add_ver_temp] 
	-- Add the parameters for the stored procedure here
	@machine_id AS int,
	@locations_name AS VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [APCSProDWH].[rans].[machine_location_settings]
	(
		[machine_id]
		, [location_id]
		, [created_at]
		, [created_by]
		, [updated_at]
		, [updated_by]
	)
	SELECT @machine_id AS [machine_id]
		, [rack_addresses].[id] AS [location_id]
		, GETDATE() AS [created_at]
		, '' AS [created_by]
		, NULL AS [updated_at]
		, NULL AS [updated_by]
	FROM [APCSProDB].[rcs].[rack_addresses]
    INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
	WHERE [rack_controls].[name] = @locations_name;

END
