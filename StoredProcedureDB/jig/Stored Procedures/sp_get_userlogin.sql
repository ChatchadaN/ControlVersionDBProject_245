-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_userlogin]
	-- Add the parameters for the stored procedure here
	@EMP_ID AS VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT TB_CheckUser.*,(CASE WHEN GroupPermiss = 'JIGAdmin' THEN 'admin' ELSE 'user' END) AS UserType,processes.id as ProcessID 
	,ISNULL( (SELECT  APCSProDB.man.roles.name   FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id 
						 WHERE APCSProDB.man.users.emp_num = @EMP_ID AND APCSProDB.man.roles.name = 'JIGIncharge'),'NotIncharge') AS Incharge
	FROM  (SELECT   APCSProDB.man.users.id as IDUser, APCSProDB.man.users.full_name, APCSProDB.man.users.name as FirstName, APCSProDB.man.users.english_name
					, APCSProDB.man.users.emp_num as ID, APCSProDB.man.roles.name AS GroupRole, APCSProDB.man.permissions.name AS GroupPermiss
					,APCSProDB.man.operations.name AS GroupOP,SUBSTRING(roles.name,3,2) as Process,roles.id as role_id
						 FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id ) AS TB_CheckUser INNER JOIN
 
	APCSProDB.method.processes ON APCSProDB.method.processes.name = TB_CheckUser.Process
						 
	where TB_CheckUser.ID = @EMP_ID and GroupPermiss like 'JIG%' 
	order by role_id desc
END
