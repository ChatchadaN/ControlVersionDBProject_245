-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_rack_unmatch]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT [locations].[name] AS unmatched_racks
		FROM [APCSProDB].[trans].[locations]
		LEFT JOIN APCSProDB.inv.class_locations ON [locations].[name] = class_locations.location_name
		WHERE wh_code != 4
		AND class_locations.location_name IS NULL
		GROUP BY [locations].[name];
	END
END
