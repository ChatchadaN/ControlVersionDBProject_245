-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE[stripmap].[sp_r_bin_matrix_info]
	-- Add the parameters for the stored procedure here
	@DATABASE_NAME NVARCHAR(128),
	@USER_ID int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @CMD_TEXT NVARCHAR(4000) = '';

	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SET @CMD_TEXT  = N'';
	SET @CMD_TEXT += N'select ';
	SET @CMD_TEXT += N'	' + 'BN.bin_matrix_id, ';
	SET @CMD_TEXT += N'	' + 'OP.name as operation_name, ';
	SET @CMD_TEXT += N'	' + 'BN.die_quality_from, ';
	SET @CMD_TEXT += N'	' + 'BN.die_quality_to ';
	SET @CMD_TEXT += N'from ' + @DATABASE_NAME + '.man.users as US with(nolock) ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.man.user_roles as UR with(nolock)on UR.user_id = US.id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.man.roles as RO with(nolock)on RO.id = UR.role_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.man.role_permissions as RP with(nolock)on RP.role_id = UR.role_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.man.permissions as PM with(nolock)on PM.id = RP.permission_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.man.permission_operations as PO with(nolock)on PO.permission_id = RP.permission_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.man.operations as OP with(nolock)on OP.id = PO.operation_id ';
	SET @CMD_TEXT += N'left outer join ' + @DATABASE_NAME + '.mc.bin_matrixes as BN with(nolock)on BN.bin_matrix_id = OP.parameter_1 ';
	SET @CMD_TEXT += N'where US.id = ' + CONVERT(varchar,@USER_ID) + ' ';
	SET @CMD_TEXT += N'order by BN.bin_matrix_id, BN.die_quality_from, BN.die_quality_to ';
	EXECUTE(@CMD_TEXT)

	return @@ROWCOUNT
END
