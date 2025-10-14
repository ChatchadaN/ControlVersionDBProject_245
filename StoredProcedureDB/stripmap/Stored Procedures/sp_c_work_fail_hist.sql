-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_c_work_fail_hist]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@WORK_NO	INT,
	@BIN_ID		INT,
	@PCS		INT,
	@RECORD_ID	INT

AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

	-- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'insert ';
	SET @CMD_TEXT += N' ' + @DATABASE_NAME + '.trans.work_fail_records ';
	SET @CMD_TEXT += N'( ';
	SET @CMD_TEXT += N' ' + 'update_record_id, ';
	SET @CMD_TEXT += N' ' + 'work_id, ';
	SET @CMD_TEXT += N' ' + 'job_id, ';
	SET @CMD_TEXT += N' ' + 'fail_bin_id, ';
	SET @CMD_TEXT += N' ' + 'pcs ';
	SET @CMD_TEXT += N') ';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N' ' + CONVERT(varchar,@RECORD_ID) + ', ';
	SET @CMD_TEXT += N' ' + 'WK.id, ';
	SET @CMD_TEXT += N' ' + 'LO.act_job_id, ';
	SET @CMD_TEXT += N' ' + CONVERT(varchar,@BIN_ID) + ', ';
	SET @CMD_TEXT += N' ' + CONVERT(varchar,@PCS) + ' ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.works as WK ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.lots as LO on LO.id = WK.lot_id ';
	SET @CMD_TEXT += N'where WK.id = ' + CONVERT(varchar,@WORK_NO) + ' ';
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
