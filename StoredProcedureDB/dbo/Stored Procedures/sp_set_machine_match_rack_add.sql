-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_machine_match_rack_add] 
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
		, [locations].[id] AS [location_id]
		, GETDATE() AS [created_at]
		, '' AS [created_by]
		, NULL AS [updated_at]
		, NULL AS [updated_by]
	FROM [APCSProDB].[trans].[locations]
	WHERE [locations].[name] = @locations_name;
END
