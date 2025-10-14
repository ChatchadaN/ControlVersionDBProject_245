-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_work_map_status]
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
	SET @CMD_TEXT += N'	' + 'WK.map_state as STATUS, ';
	SET @CMD_TEXT += N'	' + 'LO.process_state as LOT_STATUS, ';
	SET @CMD_TEXT += N'	' + 'LO.quality_state as QC_STATUS ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.works as WK with(nolock) ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.lots as LO with(nolock) on LO.id = WK.lot_id ';
	SET @CMD_TEXT += N'where WK.id = ' + CONVERT(varchar,@WORK_ID) + ' ';
	EXECUTE(@CMD_TEXT)
		
	return @@ROWCOUNT
END
