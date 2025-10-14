-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_ticket_info]
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
	SET @CMD_TEXT += N'	' + 'DS.device_slip_id as TICKET_ID, ';
	SET @CMD_TEXT += N'	' + 'DN.assy_name + '' Version.'' + CAST(DS.version_num as varchar(3)) as TICKET_NAME, ';
	SET @CMD_TEXT += N'	' + ''''' as PRD_TYPE, PK.name as TYPE_NAME ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.method.device_slips as DS with(nolock) ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.device_versions as DV with(nolock) on DV.device_id = DS.device_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.device_names as DN with(nolock) on DN.id = DV.device_name_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.method.packages as PK with(nolock) on PK.id = DN.package_id ';
	SET @CMD_TEXT += N'where DS.device_slip_id = ' + CONVERT(varchar,@TICKET_ID) + ' ';
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
