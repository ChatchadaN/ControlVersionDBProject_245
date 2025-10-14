

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_matching_permission_operations]
	-- Add the parameters for the stored procedure here
	 @permission_id   INT	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
	SELECT [permission_operations].[permission_id]
	  ,[permissions].[name] AS [permission_name]
	  ,[permission_operations].[operation_id]
      ,[operations].[name] AS [Operation_name]
	  ,[permission_operations].[created_at]
      ,[permission_operations].[created_by]
      ,[permission_operations].[updated_at]
      ,[permission_operations].[updated_by]
   FROM [APCSProDB].[man].[permission_operations]
   INNER JOIN [APCSProDB].[man].[permissions] ON permission_operations.permission_id = [permissions].id
   INNER JOIN [APCSProDB].[man].[operations] ON permission_operations.operation_id = operations.id
   Where [permission_id] = @permission_id 
	END
END
