-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_user_map_edit_license]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@USER_ID INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select DISTINCT ';
	SET @CMD_TEXT += N'	' + 'OP.name as EDITOR, ';
	SET @CMD_TEXT += N'	' + 'US.is_admin as ADMIN ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.man.users as US with(nolock) ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.man.user_roles as UR with(nolock) on UR.user_id = US.id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.man.role_permissions as RP with(nolock) on RP.role_id = UR.role_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.man.permission_operations as PO with(nolock) on PO.permission_id = RP.permission_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.man.operations as OP with(nolock) on OP.id = PO.operation_id and OP.name = ''MapEditor'' ';
	SET @CMD_TEXT += N'where US.id = ' + CONVERT(varchar,@USER_ID) + ' ';
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
