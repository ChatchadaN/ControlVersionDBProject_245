-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_all_error_message_info]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@APP_NAME NVARCHAR(128)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + 'ER.lang as lang, '
	SET @CMD_TEXT += N'	' + 'ER.code as code, '
	SET @CMD_TEXT += N'	' + 'ER.message as message, '
	SET @CMD_TEXT += N'	' + 'ER.cause as cause, '
	SET @CMD_TEXT += N'	' + 'ER.handling as handling, '
	SET @CMD_TEXT += N'	' + 'ER.information_code as information_code, '
	SET @CMD_TEXT += N'	' + 'ER.importance as importance, '
	SET @CMD_TEXT += N'	' + 'ER.comment as comment '
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME +'.mdm.errors as ER with(nolock) '
	SET @CMD_TEXT += N'where ER.app_name = ''' + @APP_NAME + ''' '
	SET @CMD_TEXT += N'order by ER.lang, ER.code '
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
