-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_c_works_hist]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@WORK_NO	INT,
	@RECORD_ID	INT,
	@USER_ID	INT

AS
BEGIN

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @DAY_ID INT
	DECLARE @CMD_TEXT NVARCHAR(MAX) = '';
	DECLARE @CMD_PARA NVARCHAR(MAX) = '';

	SET NOCOUNT ON;

	-- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + '@DAY_ID = D.id ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.days as D ';
	SET @CMD_TEXT += N'where D.date_value = CONVERT(DATE,GETDATE()) ';
	
	SET @CMD_PARA = N'@DAY_ID INT OUTPUT';
	EXECUTE sp_executesql @CMD_TEXT, @CMD_PARA, @DAY_ID OUTPUT
	
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'insert ';
	SET @CMD_TEXT += N' ' + @DATABASE_NAME + '.trans.work_update_records ';
	SET @CMD_TEXT += N'( ';
	SET @CMD_TEXT += N' ' + 'id, ';
	SET @CMD_TEXT += N' ' + 'day_id, ';
	SET @CMD_TEXT += N' ' + 'job_id, ';
	SET @CMD_TEXT += N' ' + 'recorded_at, ';
	SET @CMD_TEXT += N' ' + 'record_class, ';
	SET @CMD_TEXT += N' ' + 'work_id, ';
	SET @CMD_TEXT += N' ' + 'use_state, ';
	SET @CMD_TEXT += N' ' + 'map_state ';
	SET @CMD_TEXT += N') ';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N' ' + CONVERT(varchar,@RECORD_ID) + ', ';
	SET @CMD_TEXT += N' ' + CONVERT(varchar,@DAY_ID) + ', ';
	SET @CMD_TEXT += N' ' + 'LO.act_job_id, ';
	SET @CMD_TEXT += N' ' + 'GETDATE(), ';
	SET @CMD_TEXT += N' ' + '101, ';
	SET @CMD_TEXT += N' ' + 'WK.id, ';
	SET @CMD_TEXT += N' ' + 'WK.use_state, ';
	SET @CMD_TEXT += N' ' + 'WK.map_state ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.works as WK ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.lots as LO on LO.id = WK.lot_id ';
	SET @CMD_TEXT += N'where WK.id = ' + CONVERT(varchar,@WORK_NO) + ' ';
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
