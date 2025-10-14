-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_trc_read_user_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [users].[id]
	FROM [APCSProDB].[man].[users]
	INNER JOIN [APCSProDB].[man].[user_roles] ON [user_roles].[user_id] = [users].[id]
	INNER JOIN [APCSProDB].[man].[roles] ON [roles].[id] = [user_roles].[role_id]
	INNER JOIN [APCSProDB].[man].[role_permissions] ON [role_permissions].[role_id] = [roles].[id]
	INNER JOIN [APCSProDB].[man].[permissions] ON [permissions].[id] = [role_permissions].[permission_id]
	INNER JOIN [APCSProDB].[man].[permission_operations] ON [permission_operations].[permission_id] = [permissions].[id]
	INNER JOIN [APCSProDB].[man].[operations] ON [operations].[id] = [permission_operations].[operation_id]
	WHERE [users].[emp_num] = @username
	AND ([operations].[id] = 346 OR [users].[is_admin] = 1))
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
	END
	ELSE
	BEGIN
		SELECT CAST(0 AS BIT) AS [status]
	END
END
