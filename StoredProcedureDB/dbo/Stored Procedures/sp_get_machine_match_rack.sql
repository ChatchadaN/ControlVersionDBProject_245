-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_machine_match_rack] 
	-- Add the parameters for the stored procedure here
	@machine_id AS int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		SELECT [machines].[id] AS [machine_id]
		, [machines].[name] AS [machine_name]
		, [locations].[name] AS [rackName]
		FROM [APCSProDWH].[rans].[machine_location_settings]
		INNER JOIN [APCSProDB].[trans].[locations] ON [machine_location_settings].[location_id] = [locations].[id]
		INNER JOIN [APCSProDB].[mc].[machines] ON [machine_location_settings].[machine_id] = [machines].[id]
		WHERE [machines].[id] = @machine_id 
		GROUP BY [machines].[id]
		, [machines].[name]
		, [locations].[name];

END
