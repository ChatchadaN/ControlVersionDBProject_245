-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_mdm_errors]
	-- Add the parameters for the stored procedure here
	@appName varchar(20) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@appName = '')
	BEGIN
		SELECT * FROM APCSProDB.mdm.errors
		ORDER BY app_name, lang, code
	END
	ELSE
	BEGIN
		SELECT * FROM APCSProDB.mdm.errors WHERE app_name = @appName
		ORDER BY app_name, lang, code
	END
END
