-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_get_rack_testControlVersion]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	---- TEST VERSION Control ----
	---    CHATCHADAPORN N    ----
	---  TEST BATCH : RIST    ----

	SELECT 
		rack_controls.id AS rack_id
		, rack_controls.name AS rack 
		, rack_categories.id AS category_id
		, rack_categories.name AS category
		, rack_controls.location_id
		, locations.name AS [location]
		, locations.address AS [area]
	FROM APCSProDB.rcs.rack_controls
	INNER JOIN APCSProDB.rcs.rack_categories ON rack_controls.category = rack_categories.id
	INNER JOIN APCSProDB.trans.locations ON rack_controls.location_id = locations.id

END