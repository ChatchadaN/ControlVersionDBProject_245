-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_class_match_rack_remove] 
	-- Add the parameters for the stored procedure here
	@classID AS int,
	@locations_name AS VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DELETE [APCSProDB].[inv].[class_locations]
	WHERE class_id = @classID and location_name = @locations_name
END
