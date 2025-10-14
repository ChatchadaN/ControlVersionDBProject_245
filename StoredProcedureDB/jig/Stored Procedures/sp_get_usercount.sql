-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_usercount]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT 
(SELECT COUNT(APCSProDB.man.users.id) as DBAdmin FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Manage' and roles.name like '%DB%' group by operations.name) as DBAdmin
,(SELECT COUNT(APCSProDB.man.users.id) as DBUser FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Operation' and roles.name like '%DB%' group by operations.name) as DBUser
,(SELECT COUNT(APCSProDB.man.users.id) as DBAdmin FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Manage' and roles.name like '%DC%' group by operations.name) as DCAdmin
,(SELECT COUNT(APCSProDB.man.users.id) as DBUser FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Operation' and roles.name like '%DC%' group by operations.name) as DCUser
,(SELECT COUNT(APCSProDB.man.users.id) as WBAdmin FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Manage' and roles.name like '%WB%' group by operations.name) as WBAdmin
,(SELECT COUNT(APCSProDB.man.users.id) as WBUser FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Operation' and roles.name like '%WB%' group by operations.name) as WBUser
,(SELECT COUNT(APCSProDB.man.users.id) as FTAdmin FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Manage' and roles.name like '%FT%' group by operations.name) as FTAdmin
,(SELECT COUNT(APCSProDB.man.users.id) as FTUser FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Operation' and roles.name like '%FT%' group by operations.name) as FTUser
,(SELECT COUNT(APCSProDB.man.users.id) as TPAdmin FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Manage' and roles.name like '%TP%' group by operations.name) as TPAdmin
,(SELECT COUNT(APCSProDB.man.users.id) as TPUser FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Operation' and roles.name like '%TP%' group by operations.name) as TPUser		
,(SELECT COUNT(APCSProDB.man.users.id) as TCAdmin FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Manage' and roles.name like '%TC%' group by operations.name) as TCAdmin	 
,(SELECT COUNT(APCSProDB.man.users.id) as TCUser FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Operation' and roles.name like '%TC%' group by operations.name) as TCUser
,(SELECT COUNT(APCSProDB.man.users.id) as FLAdmin FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Manage' and roles.name like '%FL%' group by operations.name) as FLAdmin 		
,(SELECT COUNT(APCSProDB.man.users.id) as FLUser FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Operation' and roles.name like '%FL%' group by operations.name) as FLUser 
,(SELECT COUNT(APCSProDB.man.users.id) as FLAdmin FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Manage' and roles.name like '%MP%' group by operations.name) as MPAdmin 		
,(SELECT COUNT(APCSProDB.man.users.id) as FLUser FROM APCSProDB.man.users INNER JOIN
                         APCSProDB.man.user_roles ON APCSProDB.man.users.id = APCSProDB.man.user_roles.user_id INNER JOIN
                         APCSProDB.man.roles ON APCSProDB.man.user_roles.role_id = APCSProDB.man.roles.id INNER JOIN
                         APCSProDB.man.role_permissions ON APCSProDB.man.roles.id = APCSProDB.man.role_permissions.role_id INNER JOIN
                         APCSProDB.man.permissions ON APCSProDB.man.role_permissions.permission_id = APCSProDB.man.permissions.id INNER JOIN
                         APCSProDB.man.permission_operations ON APCSProDB.man.permissions.id = APCSProDB.man.permission_operations.permission_id INNER JOIN
                         APCSProDB.man.operations ON APCSProDB.man.permission_operations.operation_id = APCSProDB.man.operations.id
						 where operations.name = 'JIG-Operation' and roles.name like '%MP%' group by operations.name) as MPUser 						 
END
