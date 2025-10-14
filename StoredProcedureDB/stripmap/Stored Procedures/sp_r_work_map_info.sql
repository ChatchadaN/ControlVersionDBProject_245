-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_work_map_info]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@WORK_ID INT,
	@START_POINT NVARCHAR(32),
	@START_NUM INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + 'WK.id as WORK_NO, ';
	SET @CMD_TEXT += N'	' + 'SB.x as X, ';
	SET @CMD_TEXT += N'	' + 'SB.y as Y, ';
	SET @CMD_TEXT += N'	' + 'case when ''' + @START_POINT + ''' = ''UpperRight'' or ''' + @START_POINT + ''' = ''LowerRight'' '
	SET @CMD_TEXT += N'	  ' + 'then (DN.strip_column_number + ' + CONVERT(varchar,@START_NUM) + ' - 1) - SB.x else SB.x + ' + CONVERT(varchar,@START_NUM) + ' end as ShowX, ';
	SET @CMD_TEXT += N'	' + 'case when ''' + @START_POINT + ''' = ''LowerRight'' or ''' + @START_POINT + ''' = ''LowerLeft'' '
	SET @CMD_TEXT += N'	  ' + 'then (DN.strip_row_number + ' + CONVERT(varchar,@START_NUM) + ' - 1) - SB.y else SB.y + ' + CONVERT(varchar,@START_NUM) + ' end as ShowY, ';
	SET @CMD_TEXT += N'	' + 'SB.bin_id as BIN_ID, ';
	SET @CMD_TEXT += N'	' + 'case when BD.bin_num is null then -1 else BD.bin_num end as BIN_NO, ';
	SET @CMD_TEXT += N'	' + 'PR.id as LAY_NO, ';
	SET @CMD_TEXT += N'	' + 'SB.is_revised as IS_REVISED ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.trans.works as WK with(nolock) ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.sub_works as SB with(nolock) on SB.work_id = WK.id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.trans.lots as LO with(nolock) on LO.id = WK.lot_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.device_names as DN with(nolock) on DN.id = LO.act_device_name_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.device_flows as DF with(nolock) on DF.device_slip_id = LO.device_slip_id and DF.step_no = LO.step_no ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.jobs as JB with(nolock) on JB.id = DF.job_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.processes as PR with(nolock) on PR.id = JB.process_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.mc.bin_definitions as BD with(nolock) on BD.id = SB.bin_id ';
	SET @CMD_TEXT += N'where WK.id = ' + CONVERT(varchar,@WORK_ID) + ' ';
	SET @CMD_TEXT += N'order by SB.y, SB.x ';
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
