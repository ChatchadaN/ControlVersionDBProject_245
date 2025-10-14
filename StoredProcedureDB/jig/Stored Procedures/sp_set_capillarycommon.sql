-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_set_capillarycommon]
	-- Add the parameters for the stored procedure here
	@production_id AS INT
	, @wb_code AS VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	INSERT INTO APCSProDB.jig.capillary_recipes
    (production_id, wb_code, created_at, created_by)
    VALUES(@production_id, @wb_code, GETDATE(), '1')
END
