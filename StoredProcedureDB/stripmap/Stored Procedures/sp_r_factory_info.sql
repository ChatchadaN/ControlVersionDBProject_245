-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_factory_info]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + 'FA.id as COMPANY_CODE, ';
	SET @CMD_TEXT += N'	' + 'FA.name as COMPANY_NAME ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.man.factories as FA with(nolock) ';
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
