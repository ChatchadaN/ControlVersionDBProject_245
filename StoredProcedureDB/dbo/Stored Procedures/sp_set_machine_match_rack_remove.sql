-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_machine_match_rack_remove] 
	-- Add the parameters for the stored procedure here
	@machine_id AS int,
	@locations_name AS VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DELETE [mls]
	FROM [APCSProDWH].[rans].[machine_location_settings] AS [mls]
	INNER JOIN [APCSProDB].[trans].[locations] AS [l] ON [mls].[location_id] = [l].[id]
	INNER JOIN [APCSProDB].[mc].[machines] AS [m] ON [mls].[machine_id] = [m].[id]
	WHERE [mls].[machine_id] = @machine_id
		AND [l].[name] = @locations_name;
END
