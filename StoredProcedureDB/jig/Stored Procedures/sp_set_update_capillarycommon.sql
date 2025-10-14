-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_set_update_capillarycommon]
	-- Add the parameters for the stored procedure here
	@id AS INT
	, @production_id AS INT
	, @wb_code AS VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	UPDATE [APCSProDB].[jig].[capillary_recipes]
    SET production_id = @production_id, wb_code = @wb_code
    WHERE id = @id
END
