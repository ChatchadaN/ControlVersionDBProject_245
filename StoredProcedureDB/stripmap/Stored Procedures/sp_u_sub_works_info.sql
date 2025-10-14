CREATE PROCEDURE[stripmap].[sp_u_sub_works_info]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@WORK_NO	INT,
	@X			INT,
	@Y			INT,
	@BIN_ID		INT,
	@STEP_NO	INT,
	@RECORD_ID	INT,
	@USER_ID	INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
   	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'update ';
	SET @CMD_TEXT += N'SW SET ';
	SET @CMD_TEXT += N' ' + 'SW.bin_id = ' + CONVERT(varchar,@BIN_ID) + ', ';
	SET @CMD_TEXT += N' ' + 'SW.job_id = DF.job_id, ';
	SET @CMD_TEXT += N' ' + 'SW.bin_id_histories = case when SW.bin_id_histories is null then ''' + CONVERT(varchar,@BIN_ID) + ''' else SW.bin_id_histories + ''|'' + ''' + CONVERT(varchar,@BIN_ID) + ''' end, ';
	SET @CMD_TEXT += N' ' + 'SW.update_record_id_histories = case when SW.update_record_id_histories is null then ''' + CONVERT(varchar,@RECORD_ID) + ''' else SW.update_record_id_histories + ''|'' + ''' + CONVERT(varchar,@RECORD_ID) + ''' end, ';
	SET @CMD_TEXT += N' ' + 'SW.updated_by = ' + CONVERT(varchar,@USER_ID) + ', ';
	SET @CMD_TEXT += N' ' + 'SW.updated_at = GETDATE() ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.sub_works as SW ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.works as WK on WK.id = SW.work_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.lots as LO on LO.id = WK.lot_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.device_flows as DF on DF.device_slip_id = LO.device_slip_id and DF.step_no = ' + CONVERT(varchar,@STEP_NO) + ' ';
    SET @CMD_TEXT += N'WHERE SW.work_id = ' + CONVERT(varchar,@WORK_NO) + ' and SW.x = ' + CONVERT(varchar,@X) + ' and SW.y = ' + CONVERT(varchar,@Y) + ' ';
	EXECUTE(@CMD_TEXT)
	return @@ROWCOUNT
END
