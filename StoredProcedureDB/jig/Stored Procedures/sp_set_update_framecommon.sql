-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_set_update_framecommon]
	-- Add the parameters for the stored procedure here
	@id AS INT
	, @common_frametype AS VARCHAR(MAX)
	, @frametype AS VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	UPDATE [APCSProDB].[jig].[common_frametypes]
    SET frametype = @frametype, common_frametype = @common_frametype
    WHERE id = @id
END
