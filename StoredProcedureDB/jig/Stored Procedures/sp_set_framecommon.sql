-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [jig].[sp_set_framecommon]
	-- Add the parameters for the stored procedure here
	@common_frametype AS VARCHAR(MAX)
	, @frametype AS VARCHAR(MAX)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	INSERT INTO [APCSProDB].[jig].[common_frametypes]
    (frametype, common_frametype, created_at, created_by)
    VALUES(@frametype, @common_frametype, GETDATE(), '1')
END
