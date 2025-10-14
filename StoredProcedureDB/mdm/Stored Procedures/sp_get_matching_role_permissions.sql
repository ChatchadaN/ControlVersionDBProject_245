

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_matching_role_permissions]
	-- Add the parameters for the stored procedure here
	@rolID int = NULL	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
	SELECT [role_id]
		  ,[roles].[name] AS [role_name]
		  ,[permission_id]
		  ,[permissions].[name] AS [permission_name]
		  ,[role_permissions].[created_at]
		  ,[role_permissions].[created_by]
		  ,[role_permissions].[updated_at]
		  ,[role_permissions].[updated_by]
   FROM [APCSProDB].[man].[role_permissions]
   INNER JOIN [APCSProDB].[man].[roles] ON [role_permissions].role_id = [roles].id
   INNER JOIN [APCSProDB].[man].[permissions] ON [role_permissions].permission_id = [permissions].id
   where ([role_id] = @rolID OR ISNULL(@rolID,'') = '')
	END
END
