-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_operation_info]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@TICKET_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + 'DF.device_slip_id as TICKET_ID, ';
	SET @CMD_TEXT += N'	' + 'DF.step_no as OPE_SEQ, ';
	SET @CMD_TEXT += N'	' + 'PR.name as LAYER_NAME, ';
	SET @CMD_TEXT += N'	' + 'JB.name as PROCESS_NAME, ';
	SET @CMD_TEXT += N'	' + '0 as QC_GATE, ';
	SET @CMD_TEXT += N'	' + 'DF.recipe as RECIPE, ';
	SET @CMD_TEXT += N'	' + ''''' as TEST_RECIPE ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.method.device_flows as DF with(nolock) '
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.jobs as JB with(nolock) on JB.id = DF.job_id '
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.processes as PR with(nolock) on PR.id = JB.process_id '
	SET @CMD_TEXT += N'where DF.device_slip_id = ' + CONVERT(varchar,@TICKET_ID) + ' ';
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
