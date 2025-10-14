-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_all_bin_info]
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
	SET @CMD_TEXT += N'	' + 'BD.id as BIN_ID, '
	SET @CMD_TEXT += N'	' + 'case when BD.bin_num is null then ''-'' else BD.bin_num end as BIN_NO, '
	SET @CMD_TEXT += N'	' + 'BD.custom_display_color as DEFAULT_COLOR, '
	SET @CMD_TEXT += N'	' + 'BD.bin_description as BIN_DEF, '
	SET @CMD_TEXT += N'	' + 'BD.die_quality as STATUS, '
	SET @CMD_TEXT += N'	' + 'BD.custom_display_color as CUSTOM_COLOR '
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME +'.mc.bin_definitions as BD with(nolock) '
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
