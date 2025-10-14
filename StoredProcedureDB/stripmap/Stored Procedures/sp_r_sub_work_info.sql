-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_sub_work_info]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@WORK_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + 'SWK.x as X, ';
	SET @CMD_TEXT += N'	' + 'SWK.y as Y, ';
	SET @CMD_TEXT += N'	' + 'case when SWK.update_record_id_histories is null then '''' else SWK.update_record_id_histories end as STACK_HISTORY_ID, ';
	SET @CMD_TEXT += N'	' + 'case when SWK.bin_id_histories is null then '''' else SWK.bin_id_histories end as STACK_BIN_ID, ';
	SET @CMD_TEXT += N'	' + 'SWK.bin_id as CURRENT_BIN_ID ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.works as WK with(nolock) ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.sub_works as SWK with(nolock) on SWK.work_id = WK.id ';
	SET @CMD_TEXT += N'where WK.id = ' + CONVERT(varchar,@WORK_ID) + ' ';
	SET @CMD_TEXT += N'order by SWK.y, SWK.x ';
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
