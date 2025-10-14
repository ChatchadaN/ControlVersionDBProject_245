-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_user_info_by_user_code_company_name]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@USER_NO VARCHAR(10),
	@COMPANY_NAME VARCHAR(10),
	@USER_ID INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

	-- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + 'US.id as USER_ID, ';
	SET @CMD_TEXT += N'	' + 'US.emp_num as USER_NO, ';
	SET @CMD_TEXT += N'	' + 'US.name as USERNAME, ';
	SET @CMD_TEXT += N'	' + 'US.password as PASSWORD, ';
	SET @CMD_TEXT += N'	' + 'US.lockout as LOCKOUT, ';
	SET @CMD_TEXT += N'	' + 'case when US.expired_on < GETDATE() then 1 else 0 end as EXPIRED, ';
	SET @CMD_TEXT += N'	' + 'case when US.default_language is null then ''Nothing'' else US.default_language end as LANGUAGE ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.man.users as US with(nolock) ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.man.user_organizations as UO with(nolock) on UO.user_id = US.id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.man.organizations as OG with(nolock) on OG.id = UO.organization_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.man.headquarters as HQ with(nolock) on HQ.id = OG.headquarter_id ';
	SET @CMD_TEXT += N'inner join ' + @DATABASE_NAME + '.man.factories as FC with(nolock) on FC.id = HQ.factory_id ';
	SET @CMD_TEXT += N'where US.emp_num = ''' + @USER_NO + ''' and FC.name = ''' + @COMPANY_NAME + ''' ';
	SET @CMD_TEXT += N'or (' + CONVERT(varchar,@USER_ID) + ' != -1 and US.id = ' + CONVERT(varchar,@USER_ID) + ') ';
	EXECUTE(@CMD_TEXT)
	
	return @@ROWCOUNT
END
